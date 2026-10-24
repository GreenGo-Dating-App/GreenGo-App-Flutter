#!/usr/bin/env python3
"""Remove everything seed_test_content.py wrote to greengo-chat-test (ONLY).

Finds the top-level docs by `seedBatch == "seed-content-2026-10-24-v1"` (and
`isTestSeed == true`), then deletes every descendant document of each parent
(subcollections are enumerated with listCollectionIds, no collection-group
index needed), children first. Order matters because of deployed triggers:

  1. bookings            (before experiences: onBookableExperienceDeleted would
                          otherwise cancel future bookings and push guests)
  2. user_experiences    + slots / reviews / replies ... ; then the
                          trigger-written user_experience_agg_events markers
  3. events              + attendees / likes / messages ...
  4. communities         + members / messages / join_requests
  5. external_events, external_country_stats, event_country_stats,
     user_experience_counts, email_dispatch (marker docs)
  6. business_ratings/{biz}/ratings/* and the tester's business follow edges
     carrying the marker
  7. storefront fields merged into seeded business profiles are restored from
     C:/dev/gg-logs/test_content_state.json (or reset to the people-seed
     defaults) - the profiles themselves belong to cleanup_test_seed.py.

Dry run by default (prints counts). Pass --apply to delete.

  python -I tools/test_env/cleanup_test_content.py            # dry run
  python -I tools/test_env/cleanup_test_content.py --apply
"""
from __future__ import annotations

import argparse
import concurrent.futures as cf
import json
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fs_rest as F  # noqa: E402  (guards the project on import)

F.guard_project("greengo-chat-test")
assert "/projects/greengo-chat-test/" in F.BASE

SEED_BATCH = "seed-content-2026-10-24-v1"
STATE_FILE = "C:/dev/gg-logs/test_content_state.json"
STOREFRONT_FIELDS = ["coverImageUrl", "galleryImages", "storefrontLinks", "businessVerified", "ratingSum",
                     "ratingCount", "businessSince", "businessPromotedUntil", "storefrontSeedBatch"]
PEOPLE_DEFAULTS = {"coverImageUrl": None, "galleryImages": [], "storefrontLinks": [], "businessVerified": False}
# Parents in deletion order.
PARENTS = ["bookings", "user_experiences", "events", "communities"]
LEAVES = ["external_events", "external_country_stats", "event_country_stats", "user_experience_counts",
          "email_dispatch"]
# Never touched by this script.
FORBIDDEN = {"attractions", "translations", "world_map_snapshots", "app_config", "external_events_index"}


def rel(name: str) -> str:
    return name.split("/documents/", 1)[1]


def marker_where():
    return {"compositeFilter": {"op": "AND", "filters": [F.eq("isTestSeed", True), F.eq("seedBatch", SEED_BATCH)]}}


def query_all(collection: str, where: dict, select: list[str] | None = None, parent: str = "") -> list[dict]:
    out, last = [], None
    while True:
        q = {"from": [{"collectionId": collection}], "where": where,
             "orderBy": [{"field": {"fieldPath": "__name__"}, "direction": "ASCENDING"}], "limit": 500}
        if select is not None:
            q["select"] = {"fields": [{"fieldPath": f} for f in select]}
        if last:
            q["startAt"] = {"values": [{"referenceValue": last}], "before": False}
        docs = F.run_query(q, parent)
        out += docs
        if len(docs) < 500:
            return out
        last = docs[-1]["name"]


def subdocs(path: str) -> list[str]:
    """All descendant document paths of `path` (recursive, deepest first)."""
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


def delete_paths(paths: list[str], apply: bool, label: str):
    for p in paths:
        assert p.split("/")[0] not in FORBIDDEN, p
    if not apply:
        return
    for i in range(0, len(paths), 450):
        F.batch_write([F.delete_write(p) for p in paths[i:i + 450]])
        print(f"  {label}: deleted {min(i + 450, len(paths))}/{len(paths)}", flush=True)
        time.sleep(0.8)


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="actually delete (default: dry run)")
    args = ap.parse_args()
    where = marker_where()
    totals = {}

    exp_ids = []
    for coll in PARENTS:
        tops = [rel(d["name"]) for d in query_all(coll, where, select=["__name__"])]
        if coll == "user_experiences":
            exp_ids = [t.split("/", 1)[1] for t in tops]
        kids: list[str] = []
        with cf.ThreadPoolExecutor(8) as ex:
            for res in ex.map(subdocs, tops):
                kids += res
        totals[coll] = len(tops)
        totals[coll + " (subcollection docs)"] = len(kids)
        print(f"{coll}: {len(tops)} docs, {len(kids)} subcollection docs")
        delete_paths(kids, args.apply, coll + " children")
        delete_paths(tops, args.apply, coll)
        if coll == "user_experiences" and exp_ids:
            if args.apply:
                time.sleep(15)  # let the delete triggers write their agg markers first
            markers = []
            for i in range(0, len(exp_ids), 30):
                w = {"fieldFilter": {"field": {"fieldPath": "experienceId"}, "op": "IN",
                                     "value": {"arrayValue": {"values": [{"stringValue": x} for x in exp_ids[i:i + 30]]}}}}
                try:
                    markers += [rel(d["name"]) for d in query_all("user_experience_agg_events", w, select=["__name__"])]
                except RuntimeError as e:
                    print("  warn agg markers:", str(e)[:160])
            totals["user_experience_agg_events (trigger markers)"] = len(markers)
            print(f"user_experience_agg_events markers: {len(markers)}")
            delete_paths(markers, args.apply, "agg markers")

    for coll in LEAVES:
        docs = [rel(d["name"]) for d in query_all(coll, where, select=["__name__"])]
        totals[coll] = len(docs)
        print(f"{coll}: {len(docs)}")
        delete_paths(docs, args.apply, coll)

    # Business ratings / follow edges + storefront restore.
    bizs = [rel(d["name"]).split("/", 1)[1] for d in
            query_all("profiles", F.eq("storefrontSeedBatch", SEED_BATCH), select=["__name__"])]
    edge_paths = []
    for b in bizs:
        for sub in (f"business_ratings/{b}/ratings", f"business_followers/{b}/followers"):
            for d in F.list_docs(sub):
                if F.dec_doc(d).get("seedBatch") == SEED_BATCH:
                    edge_paths.append(rel(d["name"]))
    state = {}
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE, encoding="utf-8") as fh:
            state = json.load(fh)
    login = state.get("loginUid")
    if login:
        for d in F.list_docs(f"user_business_following/{login}/businesses"):
            if F.dec_doc(d).get("seedBatch") == SEED_BATCH:
                edge_paths.append(rel(d["name"]))
    totals["business ratings + follow edges"] = len(edge_paths)
    totals["business profiles to restore"] = len(bizs)
    print(f"business ratings + follow edges: {len(edge_paths)}; storefront profiles to restore: {len(bizs)}")
    delete_paths(edge_paths, args.apply, "business edges")
    if args.apply and bizs:
        backup = state.get("businessBackup", {})
        writes = []
        for b in bizs:
            old = backup.get(b, {})
            data = {}
            for k in STOREFRONT_FIELDS:
                if k == "storefrontSeedBatch":
                    continue
                v = old.get(k, PEOPLE_DEFAULTS.get(k))
                if v is not None or k in PEOPLE_DEFAULTS:
                    data[k] = v
            w = {"update": {"name": f"{F.DOC_PREFIX}/profiles/{b}", "fields": {k: F.enc(v) for k, v in data.items()}},
                 "updateMask": {"fieldPaths": STOREFRONT_FIELDS},  # fields absent from `data` are removed
                 "currentDocument": {"exists": True}}
            writes.append(w)
        for i in range(0, len(writes), 400):
            F.batch_write(writes[i:i + 400])
        print(f"  restored storefront fields on {len(writes)} profiles")

    print("TOTALS:", json.dumps(totals, indent=1))
    if not args.apply:
        print("DRY RUN - nothing deleted. Re-run with --apply.")
        return 0
    left = sum(F.count(c, where) for c in PARENTS + LEAVES)
    print(f"DONE. marker docs left in top-level collections: {left}")
    return 0 if left == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
