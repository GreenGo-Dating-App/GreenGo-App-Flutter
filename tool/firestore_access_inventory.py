#!/usr/bin/env python3
"""Inventory of every Firestore path the CLIENT touches.

Written after a rules deploy took the app down with a grey screen after login.
The rules were derived from reading the code; two whole categories were missed -
five collections nobody had listed, and every collectionGroup query, which the
old catch-all had been permitting implicitly.

So the inventory is generated rather than reasoned about. It feeds two things:

  * the rules - every path here needs one, or the app breaks
  * tool/rules_client_access_test.cjs - which asserts exactly that

Only the Flutter clients are scanned. Cloud Functions use the Admin SDK, which
bypasses rules entirely, so a collection only functions touch needs no rule.

Usage:
  python3 tool/firestore_access_inventory.py [--json]
"""

import json
import os
import re
import sys

REPOS = [
    os.path.join(os.path.dirname(__file__), "..", "lib"),
    os.path.join(os.path.dirname(__file__), "..", "..", "greengo-app-flutter-web", "lib"),
]

COLLECTION = re.compile(r"\.collection\(\s*'([A-Za-z_][A-Za-z0-9_]*)'\s*\)")
COLLECTION_GROUP = re.compile(r"\.collectionGroup\(\s*'([A-Za-z_][A-Za-z0-9_]*)'\s*\)")
# `.collection('a').doc(x).collection('b')` - a subcollection of a.
CHAIN = re.compile(
    r"\.collection\(\s*'([A-Za-z_][A-Za-z0-9_]*)'\s*\)\s*"
    r"\.doc\([^)]*\)\s*"
    r"\.collection\(\s*'([A-Za-z_][A-Za-z0-9_]*)'\s*\)"
)


def dart_files():
    for root in REPOS:
        root = os.path.abspath(root)
        if not os.path.isdir(root):
            continue
        for dirpath, _dirnames, filenames in os.walk(root):
            if "generated" in dirpath:
                continue
            for name in filenames:
                if name.endswith(".dart"):
                    yield os.path.join(dirpath, name)


def main():
    top = set()
    groups = set()
    subs = set()

    for path in dart_files():
        try:
            src = open(path, encoding="utf-8").read()
        except OSError:
            continue
        # Strip line comments so a commented-out call is not counted.
        src = re.sub(r"^\s*//.*$", "", src, flags=re.MULTILINE)
        # Whitespace and newlines break the chain regex; flatten first.
        flat = re.sub(r"\s+", "", src)

        for m in CHAIN.finditer(flat):
            subs.add((m.group(1), m.group(2)))
        for m in COLLECTION.finditer(flat):
            top.add(m.group(1))
        for m in COLLECTION_GROUP.finditer(flat):
            groups.add(m.group(1))

    # A name only ever seen as the child half of a chain is a subcollection,
    # not a root collection.
    children = {child for _parent, child in subs}
    parents = {parent for parent, _child in subs}
    roots = sorted((top - children) | parents)

    result = {
        "rootCollections": roots,
        "subcollections": sorted("%s/{id}/%s" % (p, c) for p, c in subs),
        "collectionGroups": sorted(groups),
    }

    if "--json" in sys.argv:
        print(json.dumps(result, indent=2))
        return

    print("ROOT COLLECTIONS (%d)" % len(result["rootCollections"]))
    for c in result["rootCollections"]:
        print("  " + c)
    print("\nSUBCOLLECTIONS (%d)" % len(result["subcollections"]))
    for c in result["subcollections"]:
        print("  " + c)
    print("\nCOLLECTION GROUP QUERIES (%d)" % len(result["collectionGroups"]))
    for c in result["collectionGroups"]:
        print("  " + c)
    print("\nEvery one of these needs a matching rule. A collectionGroup query")
    print("needs `match /{path=**}/<name>/{id}` specifically - a root match on")
    print("the same name does NOT satisfy it.")


if __name__ == "__main__":
    main()
