"""Serve a Godot Web export with the isolation headers required by this build."""

from argparse import ArgumentParser
from email.utils import formatdate
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import webbrowser


class GodotWebHandler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".js": "application/javascript",
        ".pck": "application/octet-stream",
        ".wasm": "application/wasm",
    }

    def send_head(self):
        raw_path = Path(self.translate_path(self.path))
        accepted_encodings = {
            item.split(";", 1)[0].strip()
            for item in self.headers.get("Accept-Encoding", "").split(",")
        }
        if raw_path.is_dir() and (raw_path / "index.html.br").is_file():
            raw_path = raw_path / "index.html"
        brotli_path = raw_path.with_name(raw_path.name + ".br")
        if "br" in accepted_encodings and brotli_path.is_file():
            source = brotli_path.open("rb")
            stat = brotli_path.stat()
            self.send_response(200)
            self.send_header("Content-Type", self.guess_type(str(raw_path)))
            self.send_header("Content-Encoding", "br")
            self.send_header("Content-Length", str(stat.st_size))
            self.send_header("Last-Modified", formatdate(stat.st_mtime, usegmt=True))
            self.end_headers()
            return source
        return super().send_head()

    def end_headers(self) -> None:
        self.send_header("Vary", "Accept-Encoding")
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "cross-origin")
        super().end_headers()


def main() -> None:
    parser = ArgumentParser()
    parser.add_argument("--directory", default="tmp/build/web")
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--open-browser", action="store_true")
    args = parser.parse_args()
    handler = partial(GodotWebHandler, directory=args.directory)
    server = ThreadingHTTPServer(("127.0.0.1", args.port), handler)
    url = f"http://127.0.0.1:{args.port}/index.html"
    print(f"Serving {args.directory} at {url}")
    if args.open_browser:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
