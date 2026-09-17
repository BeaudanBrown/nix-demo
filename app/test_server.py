import html
import json
import os
import signal
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import urlopen


class ServerTest(unittest.TestCase):
    mode = None

    @classmethod
    def setUpClass(cls):
        cls.workdir = tempfile.TemporaryDirectory(prefix="nix-demo-<tag>-")
        cls.addClassCleanup(cls.workdir.cleanup)
        env = {key: value for key, value in os.environ.items() if key != "DEMO_MODE"}
        if cls.mode is not None:
            env["DEMO_MODE"] = cls.mode
        cls.server = subprocess.Popen(
            [sys.executable, str(Path(__file__).with_name("server.py").resolve())],
            cwd=cls.workdir.name,
            env={
                **env,
                "HOST": "127.0.0.1",
                "PORT": "0",
                "DEMO_MESSAGE": "<script>demo</script>",
            },
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        assert cls.server.stdout is not None
        line = cls.server.stdout.readline().strip()
        if not line.startswith("Nix Demo Web listening on 127.0.0.1:"):
            cls.server.kill()
            stdout, stderr = cls.server.communicate()
            raise RuntimeError(f"Server failed to start: {line}\n{stdout}\n{stderr}")
        cls.url = "http://" + line.split()[-1]

    @classmethod
    def tearDownClass(cls):
        cls.server.send_signal(signal.SIGINT)
        try:
            stdout, stderr = cls.server.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            cls.server.kill()
            cls.server.communicate()
            raise AssertionError("Server did not stop on Ctrl+C")
        if cls.server.returncode != 0:
            raise AssertionError(f"Server exited uncleanly: {stdout}\n{stderr}")

    def get(self, path):
        return urlopen(self.url + path, timeout=5)

    def test_page_layout_and_escaped_directory(self):
        with self.get("/") as response:
            body = response.read().decode()
            self.assertIn("<h1>Yay Nix</h1>", body)
            mode = self.mode or "PROD"
            self.assertIn(f'class="mode {mode}" aria-label="Environment: {mode}">{mode}</p>', body)
            self.assertIn('alt="Nix snowflake logo"', body)
            self.assertIn(html.escape(self.workdir.name), body)
            self.assertNotIn("<tag>", body)
            self.assertLess(body.index("<h1>"), body.index('<img class="logo"'))
            self.assertLess(body.index('<img class="logo"'), body.index('class="value"'))
            self.assertEqual(body.count('<code class="value">'), 2)
            self.assertLess(body.index("Working directory"), body.index("Hostname"))
            self.assertNotIn("Running source", body)
            self.assertNotIn("<footer>", body)
            self.assertNotIn('href="/info"', body)
            self.assertNotIn("&lt;script&gt;demo&lt;/script&gt;", body)
            self.assertNotIn("<script>", body)
            self.assertEqual(response.headers["Cache-Control"], "no-store")

    def test_info(self):
        with self.get("/info?demo=true") as response:
            info = json.load(response)
            self.assertEqual(info["version"], "1.0")
            self.assertEqual(info["mode"], self.mode or "PROD")
            self.assertEqual(info["message"], "<script>demo</script>")
            self.assertTrue(info["hostname"])
            self.assertEqual(info["cwd"], self.workdir.name)
            self.assertEqual(info["source"], str(Path(__file__).with_name("server.py").resolve()))

    def test_logo_is_served_locally(self):
        with self.get("/nix-snowflake.svg") as response:
            self.assertEqual(response.headers.get_content_type(), "image/svg+xml")
            logo = ET.fromstring(response.read())
            self.assertEqual(logo.tag, "{http://www.w3.org/2000/svg}svg")

    def test_health(self):
        with self.get("/health") as response:
            self.assertEqual(response.read(), b"ok\n")

    def test_missing_page(self):
        with self.assertRaises(HTTPError) as error:
            self.get("/missing")
        self.assertEqual(error.exception.code, 404)
        error.exception.close()


class DevServerTest(ServerTest):
    mode = "DEV"


if __name__ == "__main__":
    unittest.main()
