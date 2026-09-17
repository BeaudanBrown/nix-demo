"""Exercise the real slide's Ctrl+E handoff in a PTY (Linux/macOS).

Run from the repository root with Python and Presenterm on PATH:
    python scripts/test-presenterm-handoff.py
    python scripts/test-presenterm-handoff.py 'nix build'

Checks that shell streams reach the terminal, output/cursor are visible, and Ctrl+C
followed by Ctrl+D returns to the slides without reporting a snippet error.
"""

import os
import pty
import select
import signal
import subprocess
import sys
import tempfile
import time
from pathlib import Path

slide_title = sys.argv[1] if len(sys.argv) > 1 else 'nix develop'
slide = next(s for s in Path('slides.md').read_text().split('<!-- end_slide -->') if f'# {slide_title}\n' in s)
with tempfile.TemporaryDirectory() as tmp:
    path = Path(tmp) / 'slide.md'
    path.write_text(slide)
    pid, fd = pty.fork()
    if pid == 0:
        os.environ['TERM'] = 'xterm-256color'
        os.execvp('bash', ['bash', '-c', f'stty rows 40 cols 140; exec presenterm -x --image-protocol ascii-blocks {path}'])
    output = bytearray()
    def pump(seconds):
        until = time.monotonic() + seconds
        while time.monotonic() < until:
            if select.select([fd], [], [], .05)[0]:
                try:
                    chunk = os.read(fd, 65536)
                except OSError:
                    return
                output.extend(chunk)
                if b'\x1b[5n' in chunk:
                    os.write(fd, b'\x1b[0n')
                if b'\x1b[6n' in chunk:
                    os.write(fd, b'\x1b[1;1R')
                if b'\x1b[c' in chunk:
                    os.write(fd, b'\x1b[?1;2c')
    try:
        pump(1)
        os.write(fd, b' ')
        pump(.3)
        os.write(fd, b'\x05')
        pump(1)
        os.write(fd, b"test -t 0 && test -t 1 && test -t 2 && printf 'HANDOFF_%s\\n' OK\n")
        pump(2)
        visible = b'HANDOFF_OK' in output
        cursor_visible = output.rfind(b'\x1b[?25h') > output.rfind(b'\x1b[?25l')
        os.write(fd, b'\x03')
        pump(.2)
        os.write(fd, b'\x04')
        pump(.5)
        os.write(fd, b'q')
        pump(.3)
        returned = output.rfind(slide_title.encode()) > output.find(b'HANDOFF_OK')
        failed = b'failed to run snippet' in output
        startup_error = b'complete: command not found' in output
        print('All shell streams use TTY and output visible before exit:', visible)
        print('Cursor visible during shell:', cursor_visible)
        print('Returned to slide:', returned)
        print('Presenterm reported snippet error:', failed)
        print('Shell startup error:', startup_error)
        if not visible or not cursor_visible or not returned or failed or startup_error:
            print(output.decode(errors='replace'))
            sys.exit(1)
    finally:
        # Kill descendants before the PTY parent if a broken handoff left them running.
        subprocess.run(['pkill', '-TERM', '-P', str(pid)], check=False)
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        os.waitpid(pid, 0)
        os.close(fd)
