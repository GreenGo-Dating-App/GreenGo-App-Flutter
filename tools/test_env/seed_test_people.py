#!/usr/bin/env python3
"""Seed the GreenGo TEST project (greengo-chat-test ONLY) with:

  1. one fully onboarded login user (Platinum, ~5,000 coins, AI consent v3,
     Terms/Privacy accepted, verified phone + e-mail), and
  2. ~2,000 fake people around the world that appear in Discovery, Network,
     search and the map exactly like real users.

Every document written carries `isTestSeed: true` and `seedBatch`, so
`cleanup_test_seed.py` can remove all of it later.

Writes mirror what the real app + server write:
  profiles/{uid}          public profile (ProfileModel.toJson ->
                          publicSafeProfileJson: no exact coordinates, no DOB)
                          + the server-computed coarse fields
                          (geohash5, approxLocation, age, preciseLocation,
                          businessGeohash; functions/src/profiles/privateProfile.ts)
  profiles_private/{uid}  exact location, 9-char geohash, dateOfBirth,
                          birthMonthDay (privateProfileWrite + syncProfile)
  nicknames/{nick}        {uid, nickname, createdAt} (nickname sign-in / search)
  login user only:        users/{uid}, consents/{uid}, coinBalances/{uid},
                          coinTransactions/{id}, Firebase Auth account.

Photos are illustrated (Google Noto Emoji people, Apache-2.0) served from
jsDelivr: CORS `*`, immutable, no rate limit. DiceBear's PNG API was tested
and returns HTTP 429 for bursts of ~15+ requests (the app precaches many
images), and the test bucket has no CORS config, so Storage URLs would not
render on Flutter web.

Usage:
  python -I tools/test_env/seed_test_people.py --dry-run
  python -I tools/test_env/seed_test_people.py [--count 2000] [--skip-login-user]
"""
from __future__ import annotations

import argparse
import concurrent.futures as cf
import datetime as dt
import hashlib
import hmac
import json
import math
import os
import random
import secrets
import string
import struct
import sys
import time
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fs_rest as F  # noqa: E402  (guards the project on import)
import seed_data as D  # noqa: E402

PROJECT = "greengo-chat-test"
F.guard_project(PROJECT)

SEED = 20261023
SEED_BATCH = "seed-2026-10-23-v1"
LOGIN_EMAIL = "tester@greengo-test.dev"
LOGIN_NICK = "tester"
LOGIN_PHONE = "+12025550142"  # 202-555-01xx is reserved for fiction
CREDS_FILE = "C:/dev/gg-logs/test_user_login.txt"
STATE_FILE = "C:/dev/gg-logs/test_seed_state.json"

NOW = dt.datetime.now(dt.timezone.utc).replace(microsecond=0)
MARK = {"isTestSeed": True, "seedBatch": SEED_BATCH}

# Terms / privacy / AI consent versions (lib/core/constants/legal_versions.dart,
# functions/src/shared/legalVersions.ts, ai consent v3).
TERMS_VERSION = "5.3.4"
PRIVACY_VERSION = "5.3.2"
AI_CONSENT_VERSION = 3

# ---------------------------------------------------------------------------
# Server coarse fields (port of functions/src/profiles/privateProfile.ts)
# ---------------------------------------------------------------------------
BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz"
DEFAULT_JITTER_KEY = "greengo-approx-location-v1"
JITTER_MAX_M = 1495
M_PER_DEG_LAT = 111_320
PRECISE_MIN, PRECISE_RADIUS = 20, 98


def geohash_encode(lat: float, lng: float, precision: int = 9) -> str:
    idx = bit = 0
    even = True
    out = ""
    lat_min, lat_max, lng_min, lng_max = -90.0, 90.0, -180.0, 180.0
    while len(out) < precision:
        if even:
            mid = (lng_min + lng_max) / 2
            if lng >= mid:
                idx = idx * 2 + 1
                lng_min = mid
            else:
                idx *= 2
                lng_max = mid
        else:
            mid = (lat_min + lat_max) / 2
            if lat >= mid:
                idx = idx * 2 + 1
                lat_min = mid
            else:
                idx *= 2
                lat_max = mid
        even = not even
        bit += 1
        if bit == 5:
            out += BASE32[idx]
            bit = idx = 0
    return out


def geohash_bounds(h: str):
    even = True
    lat_min, lat_max, lng_min, lng_max = -90.0, 90.0, -180.0, 180.0
    for ch in h:
        v = BASE32.index(ch)
        for n in range(4, -1, -1):
            b = (v >> n) & 1
            if even:
                mid = (lng_min + lng_max) / 2
                if b:
                    lng_min = mid
                else:
                    lng_max = mid
            else:
                mid = (lat_min + lat_max) / 2
                if b:
                    lat_min = mid
                else:
                    lat_max = mid
            even = not even
    return lat_min, lat_max, lng_min, lng_max


def _round5(x: float) -> float:  # JS Math.round semantics
    return math.floor(x * 1e5 + 0.5) / 1e5


def _u32pair(key: str, msg: str):
    h = hmac.new(key.encode(), msg.encode(), hashlib.sha256).digest()
    return struct.unpack(">I", h[0:4])[0] / 0x1_0000_0000, struct.unpack(">I", h[4:8])[0] / 0x1_0000_0000


def approx_location(uid: str, lat: float, lng: float):
    g5 = geohash_encode(lat, lng, 5)
    a, b, c, d = geohash_bounds(g5)
    c_lat, c_lng = (a + b) / 2, (c + d) / 2
    u1, u2 = _u32pair(DEFAULT_JITTER_KEY, f"approx-location:{uid}")
    r = JITTER_MAX_M * math.sqrt(u2)
    th = 2 * math.pi * u1
    north, east = r * math.cos(th), r * math.sin(th)
    a_lat = max(-89.99999, min(89.99999, c_lat + north / M_PER_DEG_LAT))
    cos = max(math.cos(math.radians(c_lat)), 1e-6)
    a_lng = c_lng + east / (M_PER_DEG_LAT * cos)
    if a_lng > 180:
        a_lng -= 360
    if a_lng < -180:
        a_lng += 360
    return g5, {"lat": _round5(a_lat), "lng": _round5(a_lng)}


def precise_location(uid: str, lat: float, lng: float):
    key = hmac.new(DEFAULT_JITTER_KEY.encode(), b"greengo-precise-location-key", hashlib.sha256).hexdigest()
    u1, u2 = _u32pair(key, f"precise-location:v1:{uid}")
    r = math.sqrt(PRECISE_MIN ** 2 + u2 * (PRECISE_RADIUS ** 2 - PRECISE_MIN ** 2))
    th = 2 * math.pi * u1
    p_lat = max(-89.99999, min(89.99999, lat + r * math.cos(th) / M_PER_DEG_LAT))
    cos = max(math.cos(math.radians(lat)), 1e-6)
    p_lng = lng + r * math.sin(th) / (M_PER_DEG_LAT * cos)
    return {"lat": _round5(p_lat), "lng": _round5(p_lng)}


def age_from(dob: dt.datetime, now: dt.datetime = NOW) -> int:
    age = now.year - dob.year
    if (now.month, now.day) < (dob.month, dob.day):
        age -= 1
    return age


# ---------------------------------------------------------------------------
# Generation helpers
# ---------------------------------------------------------------------------
ID_ALPHABET = string.ascii_letters + string.digits


def fs_id(rng: random.Random) -> str:
    """Firestore-auto-id-shaped (28 alnum) so ids interleave with real users."""
    return "".join(rng.choice(ID_ALPHABET) for _ in range(28))


def jitter_point(rng: random.Random, lat: float, lng: float, max_km: float):
    r = max_km * 1000 * math.sqrt(rng.random())
    th = 2 * math.pi * rng.random()
    d_lat = r * math.cos(th) / M_PER_DEG_LAT
    d_lng = r * math.sin(th) / (M_PER_DEG_LAT * max(math.cos(math.radians(lat)), 1e-6))
    return round(lat + d_lat, 6), round(lng + d_lng, 6)


def pick_age(rng: random.Random) -> int:
    # Skewed to 22-38, full range 18-65.
    a = int(round(rng.triangular(18, 65, 28)))
    return max(18, min(65, a))


def dob_for_age(rng: random.Random, age: int) -> dt.datetime:
    # A date making the person exactly `age` today.
    days_into_year = rng.randint(1, 364)
    last_bday = NOW - dt.timedelta(days=days_into_year)
    try:
        d = last_bday.replace(year=last_bday.year - age)
    except ValueError:  # Feb 29
        d = last_bday.replace(year=last_bday.year - age, day=28)
    return dt.datetime(d.year, d.month, d.day, tzinfo=dt.timezone.utc)


def weighted(rng: random.Random, items, weights):
    return rng.choices(items, weights=weights, k=1)[0]


class AvatarPool:
    """Verified Noto Emoji people avatars by (gender bucket, tone)."""

    def __init__(self, cache_path: str):
        self.cache_path = cache_path
        self.ok: list[tuple] = []

    def load(self):
        if os.path.exists(self.cache_path):
            with open(self.cache_path, encoding="utf-8") as fh:
                self.ok = [tuple(x) for x in json.load(fh)]
            return
        cands = D.avatar_candidates()

        import ssl

        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        def head(c):
            req = urllib.request.Request(D.noto_url(c[3]), method="HEAD")
            for _ in range(3):
                try:
                    with urllib.request.urlopen(req, context=ctx, timeout=30) as r:
                        return c if r.status == 200 else None
                except urllib.error.HTTPError as e:
                    if e.code == 404:
                        return None
                except Exception:
                    time.sleep(1)
            return None

        with cf.ThreadPoolExecutor(16) as ex:
            self.ok = [c for c in ex.map(head, cands) if c]
        os.makedirs(os.path.dirname(self.cache_path), exist_ok=True)
        with open(self.cache_path, "w", encoding="utf-8") as fh:
            json.dump(self.ok, fh)

    def photos(self, rng: random.Random, gender: str, tone_w, age: int, culture: str, n: int) -> list[str]:
        g = {"Male": "m", "Female": "f"}.get(gender, "x")
        if rng.random() < 0.05:
            tone = -1  # classic yellow
        else:
            tone = weighted(rng, list(range(5)), [w + 1e-9 for w in tone_w])
        pool = [c for c in self.ok if c[0] == g and c[1] == tone]
        if not pool:
            pool = [c for c in self.ok if c[0] == g] or self.ok

        def score(c):
            v = c[2]
            if age >= 55:
                return 6 if (v == "older" or v in D.OLD_HAIR) else 1
            if v == "older":
                return 0.05
            if v in D.OLD_HAIR:
                return 0.3
            if v == "turban":
                return 4 if culture in ("in", "in_en") else 0.05
            if v == "headscarf":
                return 3 if culture in ("ae", "eg", "ma", "id", "tr", "sn") else 0.1
            if v == "blond":
                return 2 if culture in ("se", "dk", "no", "fi", "nl", "de", "pl", "uk", "us", "au", "ca") else 0.2
            if v == "base":
                return 3
            return 1

        weights = [score(c) for c in pool]
        chosen: list[str] = []
        for _ in range(n * 4):
            c = rng.choices(pool, weights=weights, k=1)[0]
            u = D.noto_url(c[3])
            if u not in chosen:
                chosen.append(u)
            if len(chosen) == n:
                break
        return chosen


# ---------------------------------------------------------------------------
# Person builder
# ---------------------------------------------------------------------------
def build_person(rng, uid, city, exact, culture_key, pool: AvatarPool, nick_taken: set, opts):
    name_c = culture_key if culture_key in D.NAMES else "us"
    bio_lang, langs, tones = D.CULTURES[culture_key]
    males, females, surnames = D.NAMES[name_c]
    gender = weighted(rng, ["Male", "Female", "Non-binary", "Other"], [47, 47, 4, 2])
    first = rng.choice(males if gender == "Male" else females if gender == "Female" else males + females)
    last = rng.choice(surnames)
    display = f"{first} {last}"
    age = pick_age(rng)
    dob = dob_for_age(rng, age)

    base_nick = "".join(ch for ch in (first.split()[0] + last.split()[-1][:1]).lower() if ch.isascii() and ch.isalnum())
    if len(base_nick) < 3:
        base_nick = "user"
    while True:
        nick = f"{base_nick}{rng.randint(10, 9999)}"
        if nick not in nick_taken:
            nick_taken.add(nick)
            break

    # Languages: native + 0-3 more (English very common).
    spoken = [langs[0]]
    for l in langs[1:]:
        if rng.random() < (0.75 if l == "English" else 0.3):
            spoken.append(l)
    if rng.random() < 0.15:
        extra = rng.choice(["English", "Spanish", "French", "Italian", "German", "Portuguese", "Japanese", "Korean", "Arabic", "Chinese"])
        if extra not in spoken:
            spoken.append(extra)
    preferred = [l for l in ["English", "Spanish", "French", "Italian", "German", "Portuguese", "Japanese"] if l not in spoken]
    preferred = rng.sample(preferred, k=min(len(preferred), rng.randint(1, 2)))

    interests = rng.sample(D.INTERESTS, k=rng.randint(3, 7))
    openers, closers = D.BIOS[bio_lang]
    bio = rng.choice(openers).format(city=city[1])
    if rng.random() < 0.8:
        bio += ("" if bio_lang in ("zh", "zh_hant", "ja") else " ") + rng.choice(closers)

    created = NOW - dt.timedelta(days=rng.randint(1, 300), minutes=rng.randint(0, 1439))
    updated = created + dt.timedelta(days=rng.randint(0, max(0, (NOW - created).days)))
    online = rng.random() < 0.10
    last_seen = NOW - (dt.timedelta(minutes=rng.randint(0, 4)) if online else dt.timedelta(minutes=rng.randint(10, 60 * 24 * 20)))

    # Membership mix (effective tier needs a future membershipEndDate).
    is_business = opts.get("business", False)
    tier = weighted(rng, ["FREE", "SILVER", "GOLD", "PLATINUM"], [75, 12, 8, 5])
    if is_business and tier == "FREE":
        tier = weighted(rng, ["SILVER", "GOLD", "PLATINUM"], [60, 30, 10])  # business = Silver+
    m_start = m_end = None
    if tier != "FREE":
        m_end = NOW + dt.timedelta(days=rng.randint(10, 330))
        m_start = m_end - dt.timedelta(days=rng.choice([30, 90, 365]))
    has_base = tier != "FREE" or rng.random() < 0.2
    base_end = (m_end if tier != "FREE" else NOW + dt.timedelta(days=rng.randint(3, 30))) if has_base else None
    base_src = ("included_in_tier" if tier != "FREE" else "welcome_2026") if has_base else None

    # Travellers: discoverable location is the travel location.
    traveler = opts.get("traveler")
    travel_loc_pub = travel_exact = None
    traveler_expiry = None
    if traveler:
        tcity = traveler
        travel_exact = jitter_point(rng, tcity[4], tcity[5], 8)
        travel_loc_pub = {
            "city": tcity[0], "country": tcity[2], "countryLower": tcity[2].lower(),
            "displayAddress": f"{tcity[0]}, {tcity[2]}",
        }
        traveler_expiry = NOW + dt.timedelta(days=rng.randint(3, 20))
    disc_lat, disc_lng = travel_exact if travel_exact else exact

    globe = weighted(rng, ["approximate", "exact", "country", "hidden"], [80, 10, 7, 3])
    g5, approx = approx_location(uid, disc_lat, disc_lng)
    photos_n = weighted(rng, [1, 2, 3], [45, 35, 20])
    photos = pool.photos(rng, gender, tones, age, culture_key, photos_n)
    id_verified = rng.random() < 0.25
    verified_at = created + dt.timedelta(minutes=rng.randint(2, 30))

    pub = {
        "userId": uid,
        "displayName": display,
        "nickname": nick,
        "nicknameLower": nick,
        "gender": gender,
        "accountStatus": "active",
        "isBoosted": False, "boostExpiry": None,
        "isIncognito": False, "incognitoExpiry": None,
        "isGhostMode": False,
        "isTraveler": bool(traveler),
        "travelerExpiry": F.Ts(traveler_expiry) if traveler_expiry else None,
        "travelerLocation": travel_loc_pub,
        "photoUrls": photos,
        "bio": bio,
        "interests": interests,
        "location": {
            "city": city[0], "country": city[2], "countryLower": city[2].lower(),
            "displayAddress": f"{city[0]}, {city[2]}",
        },
        "languages": spoken,
        "voiceRecordingUrl": None,
        "personalityTraits": None,
        "education": rng.choice(D.EDUCATION) if rng.random() < 0.6 else None,
        "occupation": rng.choice(D.OCCUPATIONS) if rng.random() < 0.7 else None,
        "lookingFor": rng.choice(D.LOOKING_FOR) if rng.random() < 0.7 else None,
        "height": None, "weight": None,
        "createdAt": F.Ts(created), "updatedAt": F.Ts(updated),
        "isComplete": True,
        "verificationStatus": "approved",
        "verificationMethod": "phone",
        "verificationRejectionReason": None,
        "verificationSubmittedAt": F.Ts(created),
        "verificationReviewedAt": F.Ts(verified_at),
        "verificationReviewedBy": None,
        "isAdmin": False, "isSupport": False, "is2FAEnabled": False,
        "socialLinks": None,
        "membershipTier": tier,
        "membershipStartDate": F.Ts(m_start) if m_start else None,
        "membershipEndDate": F.Ts(m_end) if m_end else None,
        "hasBaseMembership": has_base,
        "baseMembershipSource": base_src,
        "baseMembershipEndDate": F.Ts(base_end) if base_end else None,
        "isOnline": online,
        "lastSeen": F.Ts(last_seen),
        "preferredLanguages": preferred,
        "nativeLanguage": spoken[0],
        "travelPreference": rng.choice(D.TRAVEL_PREFS),
        "primaryOrigin": city[3],
        "secondaryOrigin": None,
        "isLocalGuide": (not traveler) and rng.random() < 0.06,
        "videoProfileUrl": None, "hasVideoProfile": False,
        "showOnMap": True,
        "globeDiscoverability": globe,
        "completedSafetyModules": [],
        "signupGrantsApplied": [], "signupGrantsAppliedAt": None,
        "isBusiness": False,
        "businessName": None, "businessLegalName": None, "businessWhatsapp": None,
        "businessAddress": None, "businessCategory": None, "businessVerified": False,
        "galleryImages": [], "openingHours": [], "storefrontBio": None, "storefrontLinks": [],
        "coverImageUrl": None, "coverFocalX": 0.5, "coverFocalY": 0.5, "coverZoom": 1.0,
        "businessLogoUrl": None,
        "isBanned": False,
        # Server-computed coarse fields (privateProfile.ts computeCoarse).
        "geohash5": g5,
        "approxLocation": approx,
        "age": age,
        **MARK,
    }
    pub["localGuideCity"] = city[0] if pub["isLocalGuide"] else None
    if globe == "exact":
        pub["preciseLocation"] = precise_location(uid, disc_lat, disc_lng)
    if id_verified:
        pub.update({"isAgeVerified": True, "idVerifiedVia": "registration_review", "idVerifiedAt": F.Ts(verified_at)})

    if is_business:
        cat, emoji = rng.choice(D.BUSINESS_CATEGORIES)
        bname = f"{rng.choice([last, first, city[0]])} {rng.choice(D.BUSINESS_NAME_PARTS[cat])}"
        b_lat, b_lng = jitter_point(rng, city[4], city[5], 4)
        addr = f"{rng.randint(1, 250)} {rng.choice(D.STREETS)}, {city[0]}"
        logo = D.noto_url(emoji)
        pub.update({
            "isBusiness": True,
            "businessName": bname,
            "businessLegalName": f"{bname} Ltd",
            "businessCategory": cat,
            "businessAddress": {
                "address": addr, "latitude": b_lat, "longitude": b_lng,
                "city": city[0], "country": city[2], "geohash": geohash_encode(b_lat, b_lng),
            },
            "businessGeohash": geohash_encode(b_lat, b_lng, 9),
            "storefrontBio": D.STOREFRONT_BIOS.get(bio_lang, D.STOREFRONT_BIOS["en"]),
            "openingHours": [
                {"weekday": wd, "open": "09:00", "close": "22:00" if cat in ("Bar", "Restaurant", "Live Music Venue") else "18:00",
                 "isClosed": wd == 7}
                for wd in range(1, 8)
            ],
            "businessLogoUrl": logo,
            "photoUrls": [logo] + photos[:1],
            "isLocalGuide": False, "localGuideCity": None,
        })

    priv = {
        "location": {"latitude": exact[0], "longitude": exact[1]},
        "geohash": geohash_encode(disc_lat, disc_lng, 9),
        "dateOfBirth": F.Ts(dob),
        "birthMonthDay": f"{dob.month:02d}-{dob.day:02d}",
        "updatedAt": F.Ts(updated),
        **MARK,
    }
    if travel_exact:
        priv["travelerLocation"] = {"latitude": travel_exact[0], "longitude": travel_exact[1]}
    nick_doc = {"uid": uid, "nickname": nick, "createdAt": F.Ts(created), **MARK}
    return pub, priv, nick_doc


def generate_people(count: int, pool: AvatarPool):
    rng = random.Random(SEED)
    by_name = {c[0]: c for c in D.CITIES}
    nick_taken: set[str] = {LOGIN_NICK}
    people = []
    seen_ids: set[str] = set()

    def new_id():
        while True:
            i = fs_id(rng)
            if i not in seen_ids:
                seen_ids.add(i)
                return i

    plan = []
    for cname, n, radius in D.CLUSTERS:
        plan += [(by_name[cname], radius)] * n
    rest = count - len(plan)
    weights = [c[7] for c in D.CITIES]
    for _ in range(rest):
        c = rng.choices(D.CITIES, weights=weights, k=1)[0]
        plan.append((c, 12.0))
    rng.shuffle(plan)

    n_business = max(1, round(count * 0.02))
    business_idx = set(rng.sample(range(len(plan)), n_business))
    traveler_idx = set(rng.sample([i for i in range(len(plan)) if i not in business_idx], round(count * 0.04)))

    for i, (city, radius) in enumerate(plan):
        uid = new_id()
        exact = jitter_point(rng, city[4], city[5], radius)
        opts = {"business": i in business_idx}
        if i in traveler_idx:
            opts["traveler"] = rng.choice([c for c in D.CITIES if c[0] != city[0]])
        people.append(build_person(rng, uid, city, exact, city[6], pool, nick_taken, opts))
    return people


# ---------------------------------------------------------------------------
# Login user
# ---------------------------------------------------------------------------
def gen_password() -> str:
    alphabet = string.ascii_letters + string.digits
    core = "".join(secrets.choice(alphabet) for _ in range(14))
    return f"Gg{core}!7#"  # upper, lower, digit, special (validators.dart)


def ensure_auth_user(password: str | None):
    """Creates (or finds) the Auth account. Returns (uid, password, created)."""
    found = F.request("POST", f"{F.IDT}/accounts:lookup", {"email": [LOGIN_EMAIL]}).get("users", [])
    if found:
        return found[0]["localId"], None, False
    assert password
    res = F.request("POST", f"{F.IDT}/accounts", {
        "email": LOGIN_EMAIL, "password": password, "emailVerified": True,
        "displayName": "Tester GreenGo", "phoneNumber": LOGIN_PHONE,
    })
    return res["localId"], password, True


def login_user_writes(uid: str):
    created = NOW
    end = NOW + dt.timedelta(days=365)
    city = next(c for c in D.CITIES if c[0] == "São Paulo")
    exact = (-23.5614, -46.6559)  # Av. Paulista area
    g5, approx = approx_location(uid, *exact)
    dob = dt.datetime(1992, 5, 14, tzinfo=dt.timezone.utc)
    photo = D.noto_url("1f9d1_1f3fd_200d_1f4bb")
    pub = {
        "userId": uid, "displayName": "Tester GreenGo", "nickname": LOGIN_NICK, "nicknameLower": LOGIN_NICK,
        "gender": "Other", "accountStatus": "active",
        "isBoosted": False, "boostExpiry": None, "isIncognito": False, "incognitoExpiry": None,
        "isGhostMode": False, "isTraveler": False, "travelerExpiry": None, "travelerLocation": None,
        "photoUrls": [photo], "bio": "Conta de teste da equipe GreenGo. Test account of the GreenGo team.",
        "interests": ["Travel", "Languages", "Coffee", "Photography", "Food"],
        "location": {"city": city[0], "country": city[2], "countryLower": city[2].lower(),
                     "displayAddress": f"{city[0]}, {city[2]}"},
        "languages": ["Portuguese (Brazil)", "English", "Spanish", "Italian"],
        "voiceRecordingUrl": None, "personalityTraits": None, "education": None,
        "occupation": "QA Tester", "lookingFor": "Testing every feature", "height": None, "weight": None,
        "createdAt": F.Ts(created), "updatedAt": F.Ts(created), "isComplete": True,
        "verificationStatus": "approved", "verificationMethod": "phone", "verificationRejectionReason": None,
        "verificationSubmittedAt": F.Ts(created), "verificationReviewedAt": F.Ts(created),
        "verificationReviewedBy": None, "isAdmin": False, "isSupport": False, "is2FAEnabled": False,
        "socialLinks": None,
        "membershipTier": "PLATINUM", "membershipStartDate": F.Ts(created), "membershipEndDate": F.Ts(end),
        "membershipSource": "admin_override",
        "hasBaseMembership": True, "baseMembershipSource": "included_in_tier",
        "baseMembershipStartDate": F.Ts(created), "baseMembershipEndDate": F.Ts(end),
        "isOnline": False, "lastSeen": F.Ts(created),
        "preferredLanguages": ["French", "German"], "nativeLanguage": "Portuguese (Brazil)",
        "travelPreference": "both", "primaryOrigin": "BR", "secondaryOrigin": None,
        "isLocalGuide": False, "localGuideCity": None, "videoProfileUrl": None, "hasVideoProfile": False,
        "showOnMap": True, "globeDiscoverability": "approximate", "completedSafetyModules": [],
        "signupGrantsApplied": [], "signupGrantsAppliedAt": None,
        "isBusiness": False, "businessName": None, "businessLegalName": None, "businessWhatsapp": None,
        "businessAddress": None, "businessCategory": None, "businessVerified": False,
        "galleryImages": [], "openingHours": [], "storefrontBio": None, "storefrontLinks": [],
        "coverImageUrl": None, "coverFocalX": 0.5, "coverFocalY": 0.5, "coverZoom": 1.0,
        "businessLogoUrl": None, "isBanned": False,
        "isAgeVerified": True, "idVerifiedVia": "registration_review", "idVerifiedAt": F.Ts(created),
        "geohash5": g5, "approxLocation": approx, "age": age_from(dob),
        **MARK,
    }
    priv = {
        "location": {"latitude": exact[0], "longitude": exact[1]},
        "geohash": geohash_encode(*exact, 9), "dateOfBirth": F.Ts(dob), "birthMonthDay": "05-14",
        "email": LOGIN_EMAIL, "verificationPhone": LOGIN_PHONE, "phone": LOGIN_PHONE,
        "phoneVerifiedAt": F.Ts(created), "updatedAt": F.Ts(created), **MARK,
    }
    # users/{uid}: created WITHOUT `email` first (onUserCreatedSendWelcome only
    # mails when the CREATED doc has an email), then patched below.
    users_create = {
        "locale": "pt", "approvalStatus": "approved", "approvedAt": F.Ts(created), "approvedBy": "test_seed",
        "accessDate": F.Ts(dt.datetime(2026, 4, 14, tzinfo=dt.timezone.utc)),
        "membershipTier": "platinum", "subscriptionTier": "platinum",
        "subscriptionExpiryDate": F.Ts(end), "baseMembershipExpiryDate": F.Ts(end),
        "notificationsEnabled": False, "hasEarlyAccess": False, "isAdmin": False,
        "displayName": "Tester GreenGo", "createdAt": F.Ts(created), **MARK,
    }
    consent_at = F.Ts(created)

    def c(version, doc_version=None):
        d = {"accepted": True, "version": version, "locale": "pt-BR", "at": consent_at}
        if doc_version:
            d["docVersion"] = doc_version
        return d

    consents = {
        "ai_processing": c(AI_CONSENT_VERSION),
        "terms": c(1, TERMS_VERSION),
        "privacy": c(1, PRIVACY_VERSION),
        "updatedAt": consent_at,
        **MARK,
    }
    coins = 5000
    tx_id = f"seed_{SEED_BATCH}_{uid}"
    balance = {
        "userId": uid, "totalCoins": coins, "earnedCoins": 0, "purchasedCoins": 0, "giftedCoins": 0,
        "spentCoins": 0, "lastUpdated": F.Ts(created),
        "coinBatches": [{"batchId": f"admin_{int(created.timestamp() * 1000)}_{tx_id}", "initialCoins": coins,
                         "remainingCoins": coins, "source": "promotion", "acquiredDate": F.Ts(created)}],
        **MARK,
    }
    tx = {"userId": uid, "type": "credit", "amount": coins, "balanceAfter": coins, "reason": "adminAdjustment",
          "createdAt": F.Ts(created), "metadata": {"note": "Test seed grant", "adjustedBy": "test_seed",
                                                    "requestedAmount": coins}, **MARK}
    nick = {"uid": uid, "nickname": LOGIN_NICK, "createdAt": F.Ts(created), **MARK}
    return [
        F.set_write(f"users/{uid}", users_create),
        F.set_write(f"profiles/{uid}", pub),
        F.set_write(f"profiles_private/{uid}", priv),
        F.set_write(f"consents/{uid}", consents),
        F.set_write(f"coinBalances/{uid}", balance),
        F.set_write(f"coinTransactions/{tx_id}", tx),
        F.set_write(f"nicknames/{LOGIN_NICK}", nick),
    ]


# ---------------------------------------------------------------------------
def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=2000)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--skip-login-user", action="store_true")
    ap.add_argument("--skip-people", action="store_true")
    ap.add_argument("--per-commit", type=int, default=150, help="people per commit (3 writes each)")
    ap.add_argument("--pause", type=float, default=1.5, help="seconds between commits")
    args = ap.parse_args()

    pool = AvatarPool("C:/dev/gg-logs/noto_avatar_pool.json")
    pool.load()
    print(f"avatar pool: {len(pool.ok)} verified Noto Emoji people images")

    people = [] if args.skip_people else generate_people(args.count, pool)
    if people:
        from collections import Counter

        print(f"generated {len(people)} people; countries:",
              Counter(p[0]['location']['country'] for p in people).most_common(12))
        print("tiers:", Counter(p[0]['membershipTier'] for p in people),
              "business:", sum(p[0]['isBusiness'] for p in people),
              "travelers:", sum(p[0]['isTraveler'] for p in people))
    if args.dry_run:
        print(json.dumps({k: (v.d.isoformat() if isinstance(v, F.Ts) else v) for k, v in people[0][0].items()},
                         ensure_ascii=False, indent=1, default=str)[:4000])
        return 0

    counts = {"profiles": 0, "profiles_private": 0, "nicknames": 0}
    state = {"seedBatch": SEED_BATCH, "project": PROJECT}

    if not args.skip_login_user:
        uid, password, created = ensure_auth_user(gen_password())
        print(f"login user uid={uid} ({'created' if created else 'already existed'})")
        F.commit(login_user_writes(uid))
        time.sleep(3)
        # Now add the e-mail to users/{uid} (update: no welcome-mail trigger).
        F.commit([F.set_write(f"users/{uid}", {"email": LOGIN_EMAIL}, merge=True)])
        for k in ("users", "profiles", "profiles_private", "consents", "coinBalances", "coinTransactions", "nicknames"):
            counts[k] = counts.get(k, 0) + 1
        state["loginUid"] = uid
        state["loginEmail"] = LOGIN_EMAIL
        if password:
            os.makedirs(os.path.dirname(CREDS_FILE), exist_ok=True)
            with open(CREDS_FILE, "w", encoding="utf-8") as fh:
                fh.write(
                    "GreenGo TEST project login (greengo-chat-test ONLY)\n"
                    "App: https://greengo-chat-test.web.app\n"
                    f"Email:    {LOGIN_EMAIL}\nPassword: {password}\nNickname: {LOGIN_NICK}\n"
                    f"UID:      {uid}\nPhone (Auth, fictional): {LOGIN_PHONE}\n"
                    f"Seed batch: {SEED_BATCH}\nCreated: {NOW.isoformat()}\n"
                )
            print(f"credentials written to {CREDS_FILE}")

    for i in range(0, len(people), args.per_commit):
        chunk = people[i:i + args.per_commit]
        writes = []
        for pub, priv, nick in chunk:
            u = pub["userId"]
            writes.append(F.set_write(f"profiles/{u}", pub))
            writes.append(F.set_write(f"profiles_private/{u}", priv))
            writes.append(F.set_write(f"nicknames/{nick['nickname']}", nick))
        F.commit(writes)
        counts["profiles"] += len(chunk)
        counts["profiles_private"] += len(chunk)
        counts["nicknames"] += len(chunk)
        print(f"  committed people {i + 1}-{i + len(chunk)}")
        time.sleep(args.pause)

    state["counts"] = counts
    state["finishedAt"] = dt.datetime.now(dt.timezone.utc).isoformat()
    with open(STATE_FILE, "w", encoding="utf-8") as fh:
        json.dump(state, fh, indent=1)
    print("DONE", json.dumps(counts))
    return 0


if __name__ == "__main__":
    sys.exit(main())
