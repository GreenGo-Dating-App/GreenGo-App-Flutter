"""Collects end-to-end test results as the browser produces them.

`flutter drive -d chrome` is not a usable reporting channel for a failing web
suite: `integrationDriver` prints its failure details — which are empty on web
— and exits before it ever calls the response-data callback. So each test
posts its own result here instead, and this writes them to a JSON file plus
the console as they arrive.

    python tool/e2e_sink.py            # listens on 127.0.0.1:8123
    python tool/e2e_sink.py --report   # prints the summary and exits

Results land in `build/e2e_results.json`.
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
from http.server import BaseHTTPRequestHandler, HTTPServer

RESULTS = pathlib.Path("build/e2e_results.json")


def load() -> dict:
    if RESULTS.exists():
        try:
            return json.loads(RESULTS.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return {}
    return {}


def save(data: dict) -> None:
    RESULTS.parent.mkdir(parents=True, exist_ok=True)
    RESULTS.write_text(json.dumps(data, indent=1), encoding="utf-8")


class Handler(BaseHTTPRequestHandler):
    def _cors(self) -> None:
        # The test app is served from a different origin than this sink.
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")

    def do_OPTIONS(self):  # noqa: N802 - BaseHTTPRequestHandler naming
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_POST(self):  # noqa: N802
        length = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(length).decode("utf-8", "replace")
        try:
            result = json.loads(raw)
        except json.JSONDecodeError:
            result = {"test": "<unparseable>", "status": "failed", "error": raw}

        data = load()
        data[result.get("test", "<unnamed>")] = result
        save(data)

        mark = "PASS" if result.get("status") == "passed" else "FAIL"
        print(f"  {mark}  {result.get('test')}", flush=True)
        if result.get("error"):
            for line in str(result["error"]).splitlines()[:6]:
                print(f"        {line}", flush=True)

        self.send_response(200)
        self._cors()
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, *args):  # silence the default request logging
        pass


def report() -> int:
    data = load()
    if not data:
        print("no results recorded")
        return 1
    passed = [k for k, v in data.items() if v.get("status") == "passed"]
    failed = [k for k, v in data.items() if v.get("status") != "passed"]
    print(f"=== {len(passed)} passed, {len(failed)} failed ===\n")
    for name in sorted(failed):
        print(f"FAIL  {name}")
        err = str(data[name].get("error", "")).strip()
        for line in err.splitlines()[:8]:
            print(f"      {line}")
        print()
    for name in sorted(passed):
        print(f"PASS  {name}")
    return len(failed)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--port", type=int, default=8123)
    ap.add_argument("--report", action="store_true", help="print results and exit")
    ap.add_argument("--reset", action="store_true", help="clear recorded results")
    args = ap.parse_args()

    if args.reset:
        if RESULTS.exists():
            os.remove(RESULTS)
        print("results cleared")
        return 0
    if args.report:
        return report()

    print(f"e2e sink listening on 127.0.0.1:{args.port} -> {RESULTS}")
    HTTPServer(("127.0.0.1", args.port), Handler).serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
