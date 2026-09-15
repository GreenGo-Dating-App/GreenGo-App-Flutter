#!/usr/bin/env python3
"""Extract every Firestore QUERY the clients run, with its where-clauses.

firestore_access_inventory.py answers "which collections are touched". That is
not enough: a collection can have a perfectly good rule and still refuse a
query, because Firestore rules are NOT filters. A query is rejected unless its
constraints PROVE every document it could return is readable - even when the
query would have returned nothing at all.

That is the fault that made "Could not start the chat" appear for users who had
a valid membership: conversations were queried by matchId alone, which proves
nothing about who is allowed to see them.

Output feeds tool/audit_query_rules.cjs, which runs each shape against the
deployed rules as a real signed-in user.

Usage:  python3 tool/extract_client_queries.py [--json]
"""

import json
import os
import re
import sys

REPOS = {
    "mobile": os.path.join(os.path.dirname(__file__), "..", "lib"),
    "web": os.path.join(os.path.dirname(__file__), "..", "..",
                        "greengo-app-flutter-web", "lib"),
}

# .collection('x')  ... .where('field', op: ...)  up to the terminating call.
COLL = re.compile(r"\.collection(?:Group)?\('([A-Za-z_][A-Za-z0-9_]*)'\)")
WHERE = re.compile(
    r"\.where\('([A-Za-z_][A-Za-z0-9_.]*)',"
    r"(isEqualTo|isNotEqualTo|arrayContains|arrayContainsAny|whereIn|whereNotIn"
    r"|isGreaterThan|isGreaterThanOrEqualTo|isLessThan|isLessThanOrEqualTo):")


def dart_files(root):
    root = os.path.abspath(root)
    if not os.path.isdir(root):
        return
    for dirpath, _dirs, files in os.walk(root):
        if "generated" in dirpath:
            continue
        for name in files:
            if name.endswith(".dart"):
                yield os.path.join(dirpath, name)


def main():
    found = {}
    for repo, root in REPOS.items():
        for path in dart_files(root):
            try:
                src = open(path, encoding="utf-8").read()
            except OSError:
                continue
            src = re.sub(r"^\s*//.*$", "", src, flags=re.MULTILINE)
            flat = re.sub(r"\s+", "", src)

            # Walk each .collection(...) and collect the .where(...) calls that
            # follow it before the chain is terminated by .get/.snapshots/.doc.
            for m in COLL.finditer(flat):
                coll = m.group(1)
                is_group = flat[m.start():m.start() + 17].startswith(".collectionGroup")
                tail = flat[m.end():m.end() + 600]
                stop = re.search(r"\.(get|snapshots|count|doc)\(", tail)
                segment = tail[:stop.start()] if stop else tail
                wheres = [(w.group(1), w.group(2)) for w in WHERE.finditer(segment)]
                if not wheres:
                    continue          # a plain read, not a query
                key = (coll, is_group, tuple(sorted(wheres)))
                entry = found.setdefault(key, {
                    "collection": coll,
                    "collectionGroup": is_group,
                    "where": [{"field": f, "op": o} for f, o in wheres],
                    "seen": [],
                })
                loc = "%s:%s" % (repo, os.path.relpath(path).replace("\\", "/"))
                if loc not in entry["seen"]:
                    entry["seen"].append(loc)

    out = sorted(found.values(), key=lambda e: (e["collection"], len(e["where"])))
    if "--json" in sys.argv:
        print(json.dumps(out, indent=2))
        return
    print("%d distinct query shapes across both clients\n" % len(out))
    for e in out:
        w = ", ".join("%s %s" % (x["field"], x["op"]) for x in e["where"])
        print("  %s%-28s %s" % ("CG:" if e["collectionGroup"] else "", e["collection"], w))


if __name__ == "__main__":
    main()
