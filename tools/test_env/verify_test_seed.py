#!/usr/bin/env python3
"""Read-only checks of the test seed in greengo-chat-test (ONLY).

* counts of seeded docs,
* the app's nearest-first Discovery read: ProfileGeoScan.near() =
  GeoQuery.queryBounds(lat, lng, r, maxPrecision: 5) ranges on `geohash5`,
  orderBy/startAt/endBefore, limit 40 per range (port of
  lib/core/utils/geo_query.dart + lib/features/profile/data/profile_geo_scan.dart),
  then the client-side visibility rules (DiscoveryVisibility.isVisible),
* the map variant (where showOnMap == true, composite index),
* Businesses mode (isBusiness == true, orderBy businessGeohash),
* nickname search and displayName prefix search,
* the login user's docs, and a password sign-in with the web API key.
"""
from __future__ import annotations

import json
import math
import os
import re
import sys
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fs_rest as F  # noqa: E402

F.guard_project("greengo-chat-test")

B32 = "0123456789bcdefghjkmnpqrstuvwxyz"
BITS = 5
MAX_BITS = 22 * BITS
EARTH_MERID = 40007860
M_PER_DEG_LAT = 110574
EQ_R = 6378137
E2 = 0.00669447819799
EPS = 1e-12


def encode(lat, lng, precision=9):
    idx = bit = 0
    even = True
    out = ""
    la0, la1, lo0, lo1 = -90.0, 90.0, -180.0, 180.0
    while len(out) < precision:
        if even:
            mid = (lo0 + lo1) / 2
            if lng >= mid:
                idx = idx * 2 + 1; lo0 = mid
            else:
                idx *= 2; lo1 = mid
        else:
            mid = (la0 + la1) / 2
            if lat >= mid:
                idx = idx * 2 + 1; la0 = mid
            else:
                idx *= 2; la1 = mid
        even = not even
        bit += 1
        if bit == 5:
            out += B32[idx]; bit = idx = 0
    return out


def m2lng(distance, lat):
    r = math.radians(lat)
    num = math.cos(r) * EQ_R * math.pi / 180
    denom = 1 / math.sqrt(1 - E2 * math.sin(r) ** 2)
    d = num * denom
    if d < EPS:
        return 360 if distance > 0 else 0
    return min(360, distance / d)


def lng_bits(res, lat):
    degs = m2lng(res, lat)
    return max(1, math.log2(360 / degs)) if abs(degs) > 0.000001 else 1


def lat_bits(res):
    return min(math.log2(EARTH_MERID / 2 / res), MAX_BITS)


def wrap(lng):
    if -180 <= lng <= 180:
        return lng
    a = lng + 180
    return (a % 360) - 180 if a > 0 else 180 - (-a % 360)


def bbox_bits(lat, lng, size):
    d = size / M_PER_DEG_LAT
    n, s = min(90.0, lat + d), max(-90.0, lat - d)
    return min(math.floor(lat_bits(size)) * 2, math.floor(lng_bits(size, n)) * 2 - 1,
               math.floor(lng_bits(size, s)) * 2 - 1, MAX_BITS)


def bbox_coords(lat, lng, r):
    d = r / M_PER_DEG_LAT
    n, s = min(90.0, lat + d), max(-90.0, lat - d)
    ld = max(m2lng(r, n), m2lng(r, s))
    return [[lat, lng], [lat, wrap(lng - ld)], [lat, wrap(lng + ld)], [s, lng], [s, wrap(lng - ld)],
            [s, wrap(lng + ld)], [n, lng], [n, wrap(lng - ld)], [n, wrap(lng + ld)]]


def gh_query(gh, bits):
    p = math.ceil(bits / BITS)
    if len(gh) < p:
        return [gh, gh + "~"]
    g = gh[:p]
    base = g[:-1]
    last = B32.index(g[-1])
    sig = bits - len(base) * BITS
    unused = BITS - sig
    start = (last >> unused) << unused
    end = start + (1 << unused)
    if end > 31:
        return [base + B32[start], base + "~"]
    return [base + B32[start], base + B32[end]]


def query_bounds(lat, lng, radius_m, max_precision=22):
    qb = min(max(1, bbox_bits(lat, lng, radius_m)), max_precision * BITS)
    p = math.ceil(qb / BITS)
    out = []
    for c in bbox_coords(lat, lng, radius_m):
        q = gh_query(encode(c[0], c[1], p), qb)
        if q not in out:
            out.append(q)
    return out


def haversine(a, b, c, d):
    r = 6371000.0
    dl, dg = math.radians(c - a), math.radians(d - b)
    x = math.sin(dl / 2) ** 2 + math.cos(math.radians(a)) * math.cos(math.radians(c)) * math.sin(dg / 2) ** 2
    return r * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x))


def geo_scan(lat, lng, radius_km, per_range=40, show_on_map=False, field="geohash5", extra_where=None):
    seen, out = set(), []
    for b in query_bounds(lat, lng, radius_km * 1000, max_precision=5):
        q = {"from": [{"collectionId": "profiles"}],
             "orderBy": [{"field": {"fieldPath": field}, "direction": "ASCENDING"}],
             "startAt": {"values": [{"stringValue": b[0]}], "before": True},
             "endAt": {"values": [{"stringValue": b[1]}], "before": True},
             "limit": per_range}
        filters = []
        if show_on_map:
            filters.append(F.eq("showOnMap", True))
        if extra_where:
            filters.append(extra_where)
        if filters:
            q["where"] = filters[0] if len(filters) == 1 else {"compositeFilter": {"op": "AND", "filters": filters}}
        for d in F.run_query(q):
            if d["name"] not in seen:
                seen.add(d["name"])
                out.append(F.dec_doc(d) | {"_id": d["name"].rsplit("/", 1)[1]})
    return out


def visible(p, viewer_id):
    if p["_id"] == viewer_id or p.get("isAdmin") or p.get("isSupport") or p.get("isBanned"):
        return False
    if (p.get("accountStatus") or "active").lower() in ("suspended", "banned", "deleted", "deletion_pending"):
        return False
    if p.get("isGhostMode"):
        return False
    name = (p.get("displayName") or "").strip().lower()
    if name in ("", "unknown", "unknown user"):
        return False
    loc = p.get("location") or {}
    if not (loc.get("country") or "").strip() or not p.get("approxLocation"):
        return False
    return True


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    res = {}
    seed = F.eq("isTestSeed", True)
    for c in ["profiles", "profiles_private", "nicknames", "users", "consents", "coinBalances", "coinTransactions"]:
        res[f"count.{c}.isTestSeed"] = F.count(c, seed)
    res["count.profiles.total"] = F.count("profiles")
    res["count.profiles.isBusiness"] = F.count("profiles", {"compositeFilter": {"op": "AND", "filters": [seed, F.eq("isBusiness", True)]}})
    res["count.profiles.isTraveler"] = F.count("profiles", {"compositeFilter": {"op": "AND", "filters": [seed, F.eq("isTraveler", True)]}})
    for t in ["FREE", "SILVER", "GOLD", "PLATINUM"]:
        res[f"count.profiles.tier.{t}"] = F.count("profiles", {"compositeFilter": {"op": "AND", "filters": [seed, F.eq("membershipTier", t)]}})

    state = json.load(open("C:/dev/gg-logs/test_seed_state.json", encoding="utf-8"))
    me = state["loginUid"]
    for name, (lat, lng) in {"Sao Paulo (login user home)": (-23.5614, -46.6559), "Rome": (41.9028, 12.4964),
                              "Lisbon": (38.7223, -9.1393), "New York": (40.7128, -74.0060)}.items():
        docs = geo_scan(lat, lng, 200)
        vis = [p for p in docs if visible(p, me)]
        within50 = [p for p in vis if haversine(lat, lng, p["approxLocation"]["lat"], p["approxLocation"]["lng"]) <= 50_000]
        nearest = sorted(vis, key=lambda p: haversine(lat, lng, p["approxLocation"]["lat"], p["approxLocation"]["lng"]))[:3]
        res[f"geo5.{name}"] = {
            "ranges": len(query_bounds(lat, lng, 200_000, 5)), "docs": len(docs), "visible": len(vis),
            "within50km": len(within50), "seeded": sum(1 for p in docs if p.get("isTestSeed")),
            "nearest": [f"{p['displayName']} ({p['location']['city']}, "
                        f"{haversine(lat, lng, p['approxLocation']['lat'], p['approxLocation']['lng']) / 1000:.1f} km)"
                        for p in nearest],
        }
    try:
        m = geo_scan(41.9028, 12.4964, 50, show_on_map=True)
        res["map.Rome.showOnMap(50km)"] = len(m)
    except RuntimeError as e:
        res["map.Rome.showOnMap(50km)"] = f"ERROR {str(e)[:200]}"
    try:
        biz = F.run_query({"from": [{"collectionId": "profiles"}], "where": F.eq("isBusiness", True),
                           "orderBy": [{"field": {"fieldPath": "businessGeohash"}, "direction": "ASCENDING"}], "limit": 100})
        res["businesses.orderBy(businessGeohash)"] = len(biz)
    except RuntimeError as e:
        res["businesses.orderBy(businessGeohash)"] = f"ERROR {str(e)[:200]}"
    any_nick = F.run_query({"from": [{"collectionId": "profiles"}], "where": seed, "limit": 1})[0]
    nick = F.dec_doc(any_nick)["nickname"]
    res["search.nickname==" + nick] = len(F.run_query({"from": [{"collectionId": "profiles"}], "where": F.eq("nickname", nick), "limit": 1}))
    res["search.displayName prefix 'Mar'"] = len(F.run_query({
        "from": [{"collectionId": "profiles"}],
        "orderBy": [{"field": {"fieldPath": "displayName"}, "direction": "ASCENDING"}],
        "startAt": {"values": [{"stringValue": "Mar"}], "before": True},
        "endAt": {"values": [{"stringValue": "Mar\uf8ff"}], "before": False}, "limit": 20}))

    prof = F.get(f"profiles/{me}")
    priv = F.get(f"profiles_private/{me}")
    res["login.profile"] = {k: prof.get(k) for k in ["displayName", "nickname", "isComplete", "accountStatus", "membershipTier",
                                                     "membershipEndDate", "hasBaseMembership", "verificationStatus",
                                                     "isAgeVerified", "geohash5", "approxLocation", "age"]}
    res["login.private"] = {k: priv.get(k) for k in ["location", "geohash", "birthMonthDay", "phone"]}
    u = F.get(f"users/{me}")
    res["login.users"] = {k: u.get(k) for k in ["email", "approvalStatus", "accessDate", "membershipTier"]}
    c = F.get(f"consents/{me}")
    res["login.consents"] = {k: c.get(k) for k in ["ai_processing", "terms", "privacy"]}
    cb = F.get(f"coinBalances/{me}")
    res["login.coinBalances"] = {"totalCoins": cb.get("totalCoins"), "batches": len(cb.get("coinBatches", []))}
    res["login.phone_required marker"] = F.get(f"phone_required/{me}")
    acct = F.request("POST", f"{F.IDT}/accounts:lookup", {"localId": [me]})["users"][0]
    res["login.auth"] = {k: acct.get(k) for k in ["email", "emailVerified", "phoneNumber", "disabled"]}

    # Password sign-in with the public web API key (not printed).
    cfg = open("C:/dev/gg-buddies/build/web/firebase-config.js", encoding="utf-8").read()
    api_key = re.search(r'"apiKey"\s*:\s*"([^"]+)"', cfg).group(1)
    pw = re.search(r"Password:\s*(\S+)", open("C:/dev/gg-logs/test_user_login.txt", encoding="utf-8").read()).group(1)
    req = urllib.request.Request(
        f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api_key}",
        data=json.dumps({"email": state["loginEmail"], "password": pw, "returnSecureToken": True}).encode(),
        headers={"Content-Type": "application/json", "Referer": "https://greengo-chat-test.web.app/"}, method="POST")
    try:
        with urllib.request.urlopen(req, context=F._CTX, timeout=60) as r:
            body = json.loads(r.read())
        import base64

        payload = body["idToken"].split(".")[1]
        claims = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
        res["signInWithPassword"] = {"ok": True, "localId": body["localId"], "registered": body.get("registered"),
                                     "token.email_verified": claims.get("email_verified"),
                                     "token.phone_number": claims.get("phone_number"), "token.aud": claims.get("aud")}
    except urllib.error.HTTPError as e:
        res["signInWithPassword"] = {"ok": False, "status": e.code, "body": e.read().decode()[:300]}

    print(json.dumps(res, ensure_ascii=False, indent=1, default=str))
    return 0 if res["signInWithPassword"].get("ok") else 1


if __name__ == "__main__":
    sys.exit(main())
