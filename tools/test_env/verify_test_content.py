#!/usr/bin/env python3
"""Run the app's own Firestore queries (REST) against greengo-chat-test and
print real counts for the content written by seed_test_content.py.
Read-only. Exit 1 if a core check returns nothing."""
from __future__ import annotations

import datetime as dt
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fs_rest as F  # noqa: E402
from seed_test_people import geohash_encode  # noqa: E402

F.guard_project("greengo-chat-test")
SEED_BATCH = "seed-content-2026-10-24-v1"
NOW = dt.datetime.now(dt.timezone.utc)
CITIES = {"São Paulo": (-23.5614, -46.6559), "Rome": (41.9028, 12.4964), "Lisbon": (38.7223, -9.1393),
          "New York": (40.7128, -74.0060)}
results: dict[str, object] = {}
failures: list[str] = []


def enc(v):
    return F.enc(v)


def f_(field, op, value):
    return {"fieldFilter": {"field": {"fieldPath": field}, "op": op, "value": enc(value)}}


def and_(*fs):
    return {"compositeFilter": {"op": "AND", "filters": list(fs)}}


def q(coll, where=None, order=None, limit=None, parent="", cg=False, start=None, end=None):
    s = {"from": [{"collectionId": coll, "allDescendants": cg}]}
    if where:
        s["where"] = where
    if order:
        s["orderBy"] = [{"field": {"fieldPath": f}, "direction": d} for f, d in order]
    if start is not None:
        s["startAt"] = {"values": [enc(start)], "before": True}
    if end is not None:
        s["endAt"] = {"values": [enc(end)], "before": True}
    if limit:
        s["limit"] = limit
    return [F.dec_doc(d) | {"_id": d["name"].rsplit("/", 1)[1], "_name": d["name"]} for d in F.run_query(s, parent)]


def km(a, b):
    la1, lo1, la2, lo2 = map(math.radians, (*a, *b))
    h = math.sin((la2 - la1) / 2) ** 2 + math.cos(la1) * math.cos(la2) * math.sin((lo2 - lo1) / 2) ** 2
    return 12742 * math.asin(math.sqrt(h))


def ts_of(v):
    return dt.datetime.fromisoformat(v.replace("Z", "+00:00")) if isinstance(v, str) else None


def record(name, value, core=True):
    results[name] = value
    n = value if isinstance(value, int) else len(value) if isinstance(value, (list, dict)) else 1
    flag = "" if (n or not core) else "   <-- EMPTY"
    print(f"{name}: {value}{flag}")
    if core and not n:
        failures.append(name)


def geo_scan(coll, base_filters, center, radius_km, lat_key, lng_key, prec=3):
    """Geohash-range scan like GeoRingScanner (cells of the centre + neighbours)."""
    lat, lng = center
    cells = set()
    for dlat in (-1.2, 0, 1.2):
        for dlng in (-1.5, 0, 1.5):
            cells.add(geohash_encode(lat + dlat, lng + dlng, prec))
    out = {}
    for c in cells:
        docs = q(coll, where=and_(*base_filters) if len(base_filters) > 1 else base_filters[0],
                 order=[("geohash" if coll != "profiles" else "businessGeohash", "ASCENDING")], limit=100,
                 start=c, end=c + "~")
        for d in docs:
            dl, dg = d.get(lat_key), d.get(lng_key)
            if isinstance(dl, dict):  # businessAddress
                dl, dg = dl.get("latitude"), dl.get("longitude")
            if dl is None:
                continue
            if km((lat, lng), (dl, dg)) <= radius_km:
                out[d["_id"]] = d
    return list(out.values())


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    found = F.request("POST", f"{F.IDT}/accounts:lookup", {"email": ["tester@greengo-test.dev"]}).get("users", [])
    tester = found[0]["localId"]
    mark = and_(f_("isTestSeed", "EQUAL", True), f_("seedBatch", "EQUAL", SEED_BATCH))

    print("== counts (marker) ==")
    for c in ["communities", "events", "external_events", "user_experiences", "bookings", "event_country_stats",
              "external_country_stats", "user_experience_counts", "email_dispatch"]:
        record(f"count {c}", F.count(c, mark))
    record("events total in collection", F.count("events"))
    record("user_experiences hidden by moderation", F.count("user_experiences", and_(f_("seedBatch", "EQUAL", SEED_BATCH), f_("status", "EQUAL", "hidden"))), core=False)

    print("\n== Events tab ==")
    live = {"fieldFilter": {"field": {"fieldPath": "status"}, "op": "IN",
                            "value": {"arrayValue": {"values": [enc("published"), enc("scheduled")]}}}}
    for city, center in CITIES.items():
        near = [e for e in geo_scan("events", [live], center, 100, "latitude", "longitude")
                if ts_of(e["endDate"]) >= NOW and e.get("visibility") == "public" and e.get("imageUrl")]
        record(f"events nearby (geohash rings, <=100 km, upcoming) {city}", len(near))
    up = q("events", where=and_(live, f_("startDate", "GREATER_THAN_OR_EQUAL", NOW)), order=[("startDate", "ASCENDING")], limit=200)
    record("events upcoming (status in live, startDate>=now, orderBy startDate)", len(up))
    up_sp = q("events", where=and_(live, f_("city", "EQUAL", "São Paulo"), f_("startDate", "GREATER_THAN_OR_EQUAL", NOW)),
              order=[("startDate", "ASCENDING")], limit=100)
    record("events upcoming city==São Paulo", len(up_sp))
    cat = q("events", where=and_(live, f_("category", "EQUAL", "food"), f_("startDate", "GREATER_THAN_OR_EQUAL", NOW)),
            order=[("startDate", "ASCENDING")], limit=100)
    record("events upcoming category==food", len(cat))
    for kw in ("yoga", "samba", "paulo", "lisboa"):
        record(f"events search '{kw}'", len(q("events", where=f_("searchKeywords", "ARRAY_CONTAINS", kw), limit=50)), core=kw in ("yoga", "paulo"))
    mine = q("events", where=f_("organizerId", "EQUAL", tester), order=[("startDate", "ASCENDING")], limit=100)
    record("tester hosting (organizerId==tester)", len(mine))
    going = q("attendees", cg=True, where=and_(f_("userId", "EQUAL", tester), f_("status", "EQUAL", "going")), limit=500)
    record("tester going (collectionGroup attendees)", len(going))
    paid = [e for e in up if (e.get("price") or 0) > 0]
    record("upcoming paid-looking events (price>0, ticketProvider null)", len(paid))
    record("events with ticketProvider set (must be 0)", len([e for e in up if e.get("ticketProvider")]), core=False)
    glob = q("event_country_stats", order=[("count", "DESCENDING")], limit=300)
    record("globe event_country_stats countries", len(glob))
    for src in ("ticketmaster", "viator"):
        near = geo_scan("external_events", [f_("source", "EQUAL", src)], CITIES["São Paulo"], 150, "lat", "lng")
        record(f"external_events {src} near São Paulo", len(near))
        bydate = q("external_events", where=f_("source", "EQUAL", src),
                   order=[("startDate" if src == "ticketmaster" else "rating", "ASCENDING" if src == "ticketmaster" else "DESCENDING")], limit=24)
        record(f"external_events {src} feed (orderBy {'startDate' if src == 'ticketmaster' else 'rating'})", len(bydate))

    print("\n== Communities ==")
    pub = q("communities", where=f_("isPublic", "EQUAL", True), order=[("lastActivityAt", "DESCENDING")], limit=50)
    record("discover isPublic orderBy lastActivityAt (limit 50)", len(pub))
    for city in CITIES:
        record(f"discover city=={city}", len(q("communities", where=and_(f_("isPublic", "EQUAL", True), f_("city", "EQUAL", city)),
                                              order=[("lastActivityAt", "DESCENDING")], limit=20)))
    for lang in ("pt", "it", "en"):
        record(f"discover languages contains '{lang}'", len(q("communities", where=and_(f_("isPublic", "EQUAL", True), f_("languages", "ARRAY_CONTAINS", lang)),
                                                             order=[("lastActivityAt", "DESCENDING")], limit=20)))
    for kw in ("lisb", "troca", "runners"):
        record(f"search '{kw}' (searchKeywords, orderBy memberCount)", len(q("communities", where=and_(f_("isPublic", "EQUAL", True), f_("searchKeywords", "ARRAY_CONTAINS", kw)),
                                                                          order=[("memberCount", "DESCENDING")], limit=20)))
    joined = q("members", cg=True, where=f_("userId", "EQUAL", tester), limit=100)
    record("tester joined (collectionGroup members userId==tester)", len(joined))
    owned = q("communities", where=f_("createdByUserId", "EQUAL", tester))
    record("tester my communities (createdByUserId)", len(owned))
    c0 = pub[0]
    cpath = c0["_name"].split("/documents/", 1)[1]
    msgs = q("messages", parent=cpath, order=[("sentAt", "DESCENDING")], limit=50)
    tips = q("messages", parent=cpath, where={"fieldFilter": {"field": {"fieldPath": "type"}, "op": "IN", "value": {"arrayValue": {"values": [enc(t) for t in ["language_tip", "cultural_fact", "city_tip", "other_tip"]]}}}},
             order=[("sentAt", "DESCENDING")], limit=50)
    mem = q("members", parent=cpath, order=[("joinedAt", "ASCENDING")], limit=50)
    record(f"community '{c0['name']}' messages (live 50)", len(msgs))
    record(f"community '{c0['name']}' announcements in newest 50", len([m for m in msgs if m["type"] == "announcement"]))
    record(f"community '{c0['name']}' tips", len(tips))
    record(f"community '{c0['name']}' members page / memberCount", f"{len(mem)} / {c0['memberCount']}")
    cev = 0
    for c in pub[:50]:
        cev += len(q("events", where=f_("communityId", "EQUAL", c["_id"]), limit=100))
    record("community events (communityId==) across 50 newest communities", cev)

    print("\n== Experiences ==")
    pubx = f_("status", "EQUAL", "published")
    feed = q("user_experiences", where=pubx, order=[("createdAt", "DESCENDING")], limit=20)
    record("experiences feed (published, createdAt desc, limit 20)", len(feed))
    for city, center in CITIES.items():
        record(f"experiences nearby {city} (<=50 km)", len(geo_scan("user_experiences", [pubx], center, 50, "lat", "lng")))
    record("experiences category==foodDrink", len(q("user_experiences", where=and_(pubx, f_("category", "EQUAL", "foodDrink")), order=[("createdAt", "DESCENDING")], limit=20)))
    record("experiences search 'lisbon'", len(q("user_experiences", where=and_(pubx, f_("searchKeywords", "ARRAY_CONTAINS", "lisbon")), order=[("createdAt", "DESCENDING")], limit=20)))
    top = q("user_experiences", where=pubx, order=[("ratingCount", "DESCENDING")], limit=40)
    rated = [x for x in top if (x.get("ratingCount") or 0) > 0]
    record("experiences with trigger-computed ratings (top 40 by ratingCount)", len(rated))
    if rated:
        x = rated[0]
        revs = q("reviews", parent=f"user_experiences/{x['_id']}", where=f_("status", "EQUAL", "visible"), order=[("createdAt", "DESCENDING")], limit=10)
        slots = q("slots", parent=f"user_experiences/{x['_id']}", where=f_("start", "GREATER_THAN_OR_EQUAL", NOW), order=[("start", "ASCENDING")], limit=30)
        record(f"  '{x['title']}' ratingAvg/ratingCount", f"{x.get('ratingAvg')} / {x.get('ratingCount')}")
        record("  its visible reviews", len(revs))
        record("  its upcoming slots", len(slots))
    featured = q("user_experiences", where=and_(pubx, f_("isFeatured", "EQUAL", True), f_("featuredUntil", "GREATER_THAN", NOW)), order=[("featuredUntil", "DESCENDING")], limit=20)
    record("explore featured experiences", len(featured))
    cut = NOW - dt.timedelta(hours=12)
    g_up = q("bookings", where=and_(f_("guestId", "EQUAL", tester), f_("slotStart", "GREATER_THAN_OR_EQUAL", cut)), order=[("slotStart", "ASCENDING")], limit=20)
    g_past = q("bookings", where=and_(f_("guestId", "EQUAL", tester), f_("slotStart", "LESS_THAN", cut)), order=[("slotStart", "DESCENDING")], limit=20)
    h_up = q("bookings", where=and_(f_("hostId", "EQUAL", tester), f_("slotStart", "GREATER_THAN_OR_EQUAL", cut)), order=[("slotStart", "ASCENDING")], limit=20)
    record("tester My bookings upcoming", [b["status"] for b in g_up])
    record("tester My bookings past", [b["status"] for b in g_past])
    record("tester hosting: incoming bookings upcoming", [b["status"] for b in h_up])
    record("tester hosted experiences (hostId==tester)", len(q("user_experiences", where=f_("hostId", "EQUAL", tester), order=[("createdAt", "DESCENDING")])))
    record("bookings with a payment orderId (must be 0)", len([b for b in q("bookings", where=mark, limit=1000) if (b.get("payment") or {}).get("orderId")]), core=False)

    print("\n== Network businesses ==")
    biz = geo_scan("profiles", [f_("isBusiness", "EQUAL", True)], CITIES["São Paulo"], 50, "businessAddress", None)
    record("businesses near São Paulo (isBusiness + businessGeohash rings)", len(biz))
    enriched = q("profiles", where=f_("storefrontSeedBatch", "EQUAL", SEED_BATCH), limit=100)
    record("business storefronts enriched", len(enriched))
    record("business_ratings docs on first storefront", len(q("ratings", parent=f"business_ratings/{enriched[0]['_id']}")) if enriched else 0)
    record("tester follows (user_business_following)", len(q("businesses", parent=f"user_business_following/{tester}")))

    print("\nFAILED (empty) checks:", failures or "none")
    with open("C:/dev/gg-logs/verify_test_content.json", "w", encoding="utf-8") as fh:
        json.dump(results, fh, indent=1, ensure_ascii=False, default=str)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
