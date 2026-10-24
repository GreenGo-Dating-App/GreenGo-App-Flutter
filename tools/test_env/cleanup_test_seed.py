#!/usr/bin/env python3
"""Remove everything seed_test_people.py wrote to greengo-chat-test (ONLY).

Finds the seeded accounts by `profiles.isTestSeed == true` (optionally one
`--batch`), then deletes, per seeded uid:
  * profiles, profiles_private, users, consents (+ subcollections),
    coinBalances, phone_required, signup_grants, age_gate,
    world_map_snapshots (+ chunks)
  * nicknames/{nick} of each seeded profile
  * docs that reference a seeded uid and may have been created while the
    owner used the test app or by scheduled jobs: coinTransactions,
    coinAllowanceGrants, notifications (userId), swipes (userId /
    targetUserId), matches and conversations (userId1 / userId2), with
    their subcollections (messages ...)
  * every remaining doc carrying the marker in the seeded collections
  * the login user's Firebase Auth account (tester@greengo-test.dev), only
    if its profile is a seeded one.

Dry run by default (prints counts). Pass --apply to delete.

  python -I tools/test_env/cleanup_test_seed.py            # dry run
  python -I tools/test_env/cleanup_test_seed.py --apply
"""
from __future__ import annotations

import argparse
import concurrent.futures as cf
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fs_rest as F  # noqa: E402  (guards the project on import)

F.guard_project("greengo-chat-test")

LOGIN_EMAIL = "tester@greengo-test.dev"
MARKED_COLLECTIONS = ["profiles", "profiles_private", "nicknames", "users", "consents",
                      "coinBalances", "coinTransactions"]
PER_UID_DOCS = ["profiles", "profiles_private", "users", "consents", "coinBalances", "phone_required",
                "signup_grants", "age_gate", "world_map_snapshots"]
REFERENCING = [("coinTransactions", "userId"), ("coinAllowanceGrants", "userId"), ("notifications", "userId"),
               ("swipes", "userId"), ("swipes", "targetUserId"), ("matches", "userId1"), ("matches", "userId2"),
               ("conversations", "userId1"), ("conversations", "userId2")]


def rel(name: str) -> str:
    return name.split("/documents/", 1)[1]


def marker_where(batch: str | None):
    if not batch:
        return F.eq("isTestSeed", True)
    return {"compositeFilter": {"op": "AND", "filters": [F.eq("isTestSeed", True), F.eq("seedBatch", batch)]}}


def query_all(collection: str, where: dict, select: list[str] | None = None) -> list[dict]:
    out, last = [], None
    while True:
        q = {"from": [{"collectionId": collection}], "where": where,
             "orderBy": [{"field": {"fieldPath": "__name__"}, "direction": "ASCENDING"}], "limit": 500}
        if select is not None:
            q["select"] = {"fields": [{"fieldPath": f} for f in select]}
        if last:
            q["startAt"] = {"values": [{"referenceValue": last}], "before": False}
        docs = F.run_query(q)
        out += docs
        if len(docs) < 500:
            return out
        last = docs[-1]["name"]


def subdocs(path: str) -> list[str]:
    """All descendant document paths of `path` (recursive)."""
    try:
        cols = F.request("POST", f"{F.BASE}/{path}:listCollectionIds", {"pageSize": 100}).get("collectionIds", [])
    except RuntimeError:
        return []
    found = []
    for c in cols:
        for d in F.list_docs(f"{path}/{c}", mask=["__name__"]):
            p = rel(d["name"])
            found += subdocs(p)
            found.append(p)
    return found


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="actually delete (default: dry run)")
    ap.add_argument("--batch", help="only this seedBatch")
    ap.add_argument("--keep-auth", action="store_true", help="do not delete the login Auth account")
    args = ap.parse_args()

    where = marker_where(args.batch)
    seeded = query_all("profiles", where, select=["nickname"])
    uids = [rel(d["name"]).split("/", 1)[1] for d in seeded]
    nicks = [F.dec_doc(d).get("nickname") for d in seeded]
    print(f"seeded profiles: {len(uids)}")

    targets: set[str] = set()
    for u in uids:
        for c in PER_UID_DOCS:
            targets.add(f"{c}/{u}")
    for n in nicks:
        if isinstance(n, str) and n and "/" not in n:
            targets.add(f"nicknames/{n}")

    # Marker docs in every collection the seed writes.
    for c in MARKED_COLLECTIONS:
        docs = query_all(c, where, select=["__name__"])
        targets.update(rel(d["name"]) for d in docs)
        print(f"  marker docs in {c}: {len(docs)}")

    # Docs referencing a seeded uid (owner activity / scheduled jobs).
    chunks = [uids[i:i + 30] for i in range(0, len(uids), 30)]

    def ref_query(args_):
        coll, field, chunk = args_
        w = {"fieldFilter": {"field": {"fieldPath": field}, "op": "IN",
                             "value": {"arrayValue": {"values": [{"stringValue": x} for x in chunk]}}}}
        try:
            return [rel(d["name"]) for d in query_all(coll, w, select=["__name__"])]
        except RuntimeError as e:
            print(f"  warn: {coll}.{field}: {str(e)[:160]}")
            return []

    jobs = [(c, f, ch) for c, f in REFERENCING for ch in chunks]
    with cf.ThreadPoolExecutor(8) as ex:
        ref_docs = [p for res in ex.map(ref_query, jobs) for p in res]
    print(f"  referencing docs: {len(ref_docs)}")
    targets.update(ref_docs)

    # Subcollections of the docs that can have them.
    parents = [t for t in targets if t.split("/")[0] in ("consents", "world_map_snapshots", "conversations", "matches", "profiles")]
    with cf.ThreadPoolExecutor(8) as ex:
        for res in ex.map(subdocs, parents):
            targets.update(res)

    # Only paths that exist matter for the count; deletes of missing docs are no-ops.
    by_coll: dict[str, int] = {}
    for t in targets:
        by_coll[t.split("/")[0]] = by_coll.get(t.split("/")[0], 0) + 1
    print("delete candidates by top-level collection (includes non-existent per-uid ids):", dict(sorted(by_coll.items())))

    auth_uid = None
    found = F.request("POST", f"{F.IDT}/accounts:lookup", {"email": [LOGIN_EMAIL]}).get("users", [])
    if found and found[0]["localId"] in uids:
        auth_uid = found[0]["localId"]
        print(f"login Auth account {LOGIN_EMAIL} uid={auth_uid} (seeded)")

    if not args.apply:
        print("DRY RUN - nothing deleted. Re-run with --apply.")
        return 0

    paths = sorted(targets, key=lambda p: -p.count("/"))  # children first
    for i in range(0, len(paths), 500):
        F.batch_write([F.delete_write(p) for p in paths[i:i + 500]])
        print(f"  deleted {min(i + 500, len(paths))}/{len(paths)}")
    if auth_uid and not args.keep_auth:
        F.request("POST", f"{F.IDT}/accounts:delete", {"localId": auth_uid})
        print("  deleted Auth account")
    left = F.count("profiles", where)
    print(f"DONE. seeded profiles left: {left}")
    return 0 if left == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
