#!/usr/bin/env python3
"""Legal-document change gate.

assets/legal/* (the privacy policy and terms the app shows in-app) must match
tools/security/legal_manifest.json. Any edit, addition or removal of a legal
file fails CI until the manifest is regenerated in the same change, which
makes every legal-text change a deliberate, reviewable step (the diff of
legal_manifest.json shows up in the PR next to the text change).

  python tools/security/check_legal_manifest.py            # verify (CI)
  python tools/security/check_legal_manifest.py --update   # regenerate after a reviewed change

Line endings are normalised (CRLF -> LF) before hashing: git stores these files
with LF but Windows checkouts (core.autocrlf=true) have CRLF, and a pure
line-ending difference is not a content change.
"""
import hashlib
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
LEGAL_DIR = ROOT / "assets" / "legal"
MANIFEST = pathlib.Path(__file__).resolve().parent / "legal_manifest.json"


def digest(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes().replace(b"\r\n", b"\n")).hexdigest()


def current() -> dict:
    return {p.name: digest(p) for p in sorted(LEGAL_DIR.iterdir()) if p.is_file()}


def main(argv) -> int:
    files = current()
    if not files:
        print(f"::error::no files found in {LEGAL_DIR}")
        return 2
    if "--update" in argv:
        MANIFEST.write_text(json.dumps({
            "_comment": "sha256 (CRLF->LF normalised) of assets/legal/*. Regenerate ONLY "
                        "after the legal text change was reviewed: "
                        "python tools/security/check_legal_manifest.py --update",
            "files": files,
        }, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        print(f"Wrote {MANIFEST.relative_to(ROOT)} ({len(files)} files).")
        return 0
    try:
        expected = json.loads(MANIFEST.read_text(encoding="utf-8"))["files"]
    except (OSError, ValueError, KeyError) as e:
        print(f"::error::cannot read {MANIFEST}: {e}")
        return 2
    problems = []
    for name in sorted(set(expected) | set(files)):
        if name not in files:
            problems.append(f"assets/legal/{name}: listed in the manifest but missing")
        elif name not in expected:
            problems.append(f"assets/legal/{name}: new file not in the manifest")
        elif files[name] != expected[name]:
            problems.append(f"assets/legal/{name}: content changed (sha256 {files[name][:12]}..., "
                            f"manifest {expected[name][:12]}...)")
    if problems:
        for p in problems:
            print(f"::error::{p}")
        print("Legal documents changed without a manifest update. If the change was "
              "reviewed and approved, run: python tools/security/check_legal_manifest.py --update "
              "and commit tools/security/legal_manifest.json with it.")
        return 1
    print(f"OK: {len(files)} legal files match the manifest.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
