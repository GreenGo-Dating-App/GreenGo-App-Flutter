# -*- coding: utf-8 -*-
"""Stamp the entrypoint size into build/web/index.html after a web build.

The boot screen shows a real progress bar while main.dart.js streams in, which
means it needs the total size before the download starts. The server cannot
supply it: Firebase serves main.dart.js Brotli-encoded with chunked transfer,
so there is no Content-Length. Fetching a side-car manifest works but adds a
round trip that can lose the race against the download it is meant to describe.

So the number is written straight into the HTML instead, replacing the
`/*GG_BOOT_BYTES*/` placeholder. It is the DECOMPRESSED size, which is exactly
what a streaming `fetch` reader yields, so the bar and the label agree.

Usage:
    flutter build web --release && python tools/stamp_boot_size.py
"""
import io
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
WEB = os.path.join(os.path.dirname(HERE), "build", "web")

ENTRYPOINT = "main.dart.js"
PLACEHOLDER = re.compile(r"var total = \d+; /\*GG_BOOT_BYTES\*/")


def main():
    entry = os.path.join(WEB, ENTRYPOINT)
    index = os.path.join(WEB, "index.html")
    for path in (entry, index):
        if not os.path.exists(path):
            print("missing %s - run `flutter build web` first" % path)
            return 1

    size = os.path.getsize(entry)
    html = io.open(index, encoding="utf-8").read()
    if not PLACEHOLDER.search(html):
        print("placeholder /*GG_BOOT_BYTES*/ not found in build/web/index.html")
        return 1

    html = PLACEHOLDER.sub("var total = %d; /*GG_BOOT_BYTES*/" % size, html)
    io.open(index, "w", encoding="utf-8", newline="\n").write(html)

    # A stale side-car from an earlier scheme would only confuse things.
    stale = os.path.join(WEB, "boot_manifest.json")
    if os.path.exists(stale):
        os.remove(stale)
        print("removed stale boot_manifest.json")

    print("stamped %s = %d bytes (%.1f MB decompressed) into index.html"
          % (ENTRYPOINT, size, size / 1048576.0))
    return 0


if __name__ == "__main__":
    sys.exit(main())
