r"""Tiny static server for the mock OA page + captcha images.

Serves <repo>\tools\test-assets\ on http://127.0.0.1:8001

Usage (run in a separate terminal):
  & <repo>\.venv\Scripts\python.exe <repo>\tools\mock_oa_server.py

Stop with Ctrl+C.
"""
import http.server
import os
import socketserver
import sys

ROOT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "tools",
    "test-assets",
)
PORT = 8001
os.chdir(ROOT)


class Handler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, fmt, *args):
        sys.stderr.write("[mock] " + (fmt % args) + "\n")


def serve_forever():
    with socketserver.TCPServer(("127.0.0.1", PORT), Handler) as httpd:
        sys.stderr.write(f"[mock] serving {ROOT} on http://127.0.0.1:{PORT}\n")
        sys.stderr.write(f"[mock] open http://127.0.0.1:{PORT}/test-oa.html in a browser\n")
        httpd.serve_forever()


if __name__ == "__main__":
    serve_forever()
