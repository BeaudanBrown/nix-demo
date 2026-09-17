"""A deliberately small, standard-library-only web app for the Nix demos."""

import html
import json
import os
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from string import Template
from urllib.parse import urlsplit


APP_DIR = Path(__file__).resolve().parent


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        info = {
            "version": "1.0",
            "mode": "DEV" if os.environ.get("DEMO_MODE") == "DEV" else "PROD",
            "message": os.environ.get("DEMO_MESSAGE", "Hello from the development shell"),
            "hostname": socket.gethostname(),
            "cwd": str(Path.cwd()),
            "source": str(Path(__file__).resolve()),
        }
        route = urlsplit(self.path).path
        if route == "/health":
            self.respond(200, "text/plain", "ok\n")
        elif route == "/info":
            self.respond(200, "application/json", json.dumps(info, indent=2) + "\n")
        elif route == "/nix-snowflake.svg":
            self.respond(
                200,
                "image/svg+xml",
                (APP_DIR / "static/nix-snowflake.svg").read_text(encoding="utf-8"),
            )
        elif route == "/":
            page = Template((APP_DIR / "index.html").read_text(encoding="utf-8"))
            self.respond(
                200,
                "text/html",
                page.substitute({key: html.escape(value) for key, value in info.items()}),
            )
        else:
            self.respond(404, "text/plain", "Not found\n")

    def respond(self, status, content_type, text):
        body = text.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", f"{content_type}; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)


def main():
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", "8000"))
    with ThreadingHTTPServer((host, port), Handler) as server:
        print(f"Nix Demo Web listening on {host}:{server.server_port}", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
