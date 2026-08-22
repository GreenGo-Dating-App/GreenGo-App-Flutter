# -*- coding: utf-8 -*-
"""Cache-bust the PWA icon URLs.

firebase.json serves every PNG with `Cache-Control: max-age=31536000` and no
revalidation, so replacing the artwork behind the same filenames is invisible
to anyone who has already loaded the site -- their browser will not ask again
for a year. The bytes on the server were correct; the URLs were not.

Appending a content hash to each reference fixes that: manifest.json and
index.html are both served no-cache, so the new URLs are picked up on the next
load and fetched fresh.
"""
import hashlib
import io
import json
import os
import re

ROOT = r"C:\Users\Software Engineering\Desktop\Projects\GreenGo"
REPOS = ["greengo-app-flutter-web", "GreenGo-App-Flutter"]

ICON_RE = re.compile(r'(icons/Icon-[A-Za-z0-9\-]+\.png|favicon\.png)(\?v=[0-9a-f]+)?')
# The optional group means an already-stamped URL is re-stamped, not doubled.


def digest(path):
    with open(path, "rb") as fh:
        return hashlib.sha256(fh.read()).hexdigest()[:8]


for repo in REPOS:
    web = os.path.join(ROOT, repo, "web")
    hashes = {}

    def stamp(match):
        name = match.group(1)
        path = os.path.join(web, name.replace("/", os.sep))
        if not os.path.exists(path):
            return match.group(0)
        if name not in hashes:
            hashes[name] = digest(path)
        return "%s?v=%s" % (name, hashes[name])

    # manifest.json -- rewrite the icon src values
    mpath = os.path.join(web, "manifest.json")
    m = io.open(mpath, encoding="utf-8").read()
    json.loads(m)
    m2 = ICON_RE.sub(stamp, m)
    json.loads(m2)
    io.open(mpath, "w", encoding="utf-8", newline="\n").write(m2)

    # index.html -- apple-touch-icon, favicon, boot-screen logo
    ipath = os.path.join(web, "index.html")
    h = io.open(ipath, encoding="utf-8").read()
    h2 = ICON_RE.sub(stamp, h)
    io.open(ipath, "w", encoding="utf-8", newline="\n").write(h2)

    print("%s: versioned %d icon URLs" % (repo, len(hashes)))
    for name, d in sorted(hashes.items()):
        print("   %-28s ?v=%s" % (name, d))
