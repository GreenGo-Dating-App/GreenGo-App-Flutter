#!/usr/bin/env python3
"""npm audit gate for functions/ (production dependencies only).

  * CRITICAL advisories  -> FAIL, unless the advisory is listed in
    npm_audit_allowlist.json with a reason and an expiry date that has not
    passed. Expired entries fail again, so an exception can't be forgotten.
  * HIGH advisories      -> reported as warnings only (non-blocking for now;
    see docs/security/ci.md for why and when to tighten).

  python tools/security/npm_audit_gate.py                 # runs npm audit in functions/
  python tools/security/npm_audit_gate.py audit.json      # or reads a saved `npm audit --json`
Exit: 0 ok, 1 blocking advisory, 2 audit could not run / unparsable.
"""
import datetime
import json
import pathlib
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
FUNCTIONS = HERE.parents[1] / "functions"
ALLOWLIST = HERE / "npm_audit_allowlist.json"


def load_audit(argv):
    if len(argv) > 1:
        return json.loads(pathlib.Path(argv[1]).read_text(encoding="utf-8"))
    # npm exits non-zero when it finds anything; the JSON is what matters.
    out = subprocess.run("npm audit --omit=dev --json", cwd=FUNCTIONS, shell=True,
                         capture_output=True, text=True).stdout
    return json.loads(out)


def advisories(audit):
    """Unique advisory objects (dicts in `via`), keyed by GHSA url."""
    seen = {}
    for pkg, v in audit.get("vulnerabilities", {}).items():
        for via in v.get("via", []):
            if isinstance(via, dict) and via.get("url"):
                a = seen.setdefault(via["url"], dict(via, packages=set()))
                a["packages"].add(pkg)
    return list(seen.values())


def main(argv):
    try:
        audit = load_audit(argv)
        meta = audit["metadata"]["vulnerabilities"]
    except Exception as e:  # noqa: BLE001 - any failure means "could not audit"
        print(f"::error::npm audit did not produce a usable report: {e}")
        return 2
    allow = json.loads(ALLOWLIST.read_text(encoding="utf-8")).get("advisories", {})
    today = datetime.date.today()
    print(f"npm audit (prod deps): {meta}")
    blocking, warned = [], []
    for a in sorted(advisories(audit), key=lambda x: x["url"]):
        label = f"{a['severity'].upper()} {', '.join(sorted(a['packages']))}: {a.get('title')} ({a['url']})"
        if a["severity"] == "critical":
            ghsa = a["url"].rsplit("/", 1)[-1]
            entry = allow.get(ghsa)
            if entry and datetime.date.fromisoformat(entry["expires"]) >= today:
                print(f"::warning::ALLOWLISTED until {entry['expires']}: {label} - {entry['reason']}")
            else:
                why = f" (allowlist entry EXPIRED {entry['expires']})" if entry else ""
                blocking.append(label + why)
        elif a["severity"] == "high":
            warned.append(label)
    for w in warned:
        print(f"::warning::{w}")
    for b in blocking:
        print(f"::error::{b}")
    if blocking:
        print(f"{len(blocking)} blocking critical advisory(ies). Fix them (usually "
              "`npm update <pkg>` in functions/, lockfile only) or add a reviewed, "
              "expiring entry to tools/security/npm_audit_allowlist.json.")
        return 1
    print(f"OK: no unapproved critical advisories ({len(warned)} high reported, non-blocking).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
