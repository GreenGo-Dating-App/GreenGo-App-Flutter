#!/usr/bin/env python3
"""Seed CONTENT into the GreenGo TEST project (greengo-chat-test ONLY), owned
by the ~2,000 fake people written by seed_test_people.py.

Writes (every doc, incl. subcollection docs, carries isTestSeed: true and
seedBatch: "seed-content-2026-10-24-v1"):

  communities/{id}                 + members/{uid}, messages/{id}
                                   (chat `text`, tips `city_tip`/`language_tip`/
                                   `cultural_fact`, `announcement`)
  events/{id}                      + attendees/{uid}, likes/{uid}
                                   (personal, business "paid-looking", community)
  external_events/{id}             mock Live (ticketmaster) + partner
                                   experiences (viator) for the Events sub-tabs
  event_country_stats/{country}    globe aggregate (its trigger is not deployed
  external_country_stats/{id}      in the test project)
  user_experiences/{id}            + slots/{id}, reviews/{uid}
  user_experience_counts/{hostId}
  bookings/{id}                    free / unpaid only, NEVER a payment orderId
  email_dispatch/{key}             pre-claimed so the booking e-mail trigger
                                   short-circuits as "duplicate" (no e-mail)
  business_ratings/{biz}/ratings/{uid}
  business_followers/{biz}/followers/{tester} + user_business_following mirror
  profiles/{biz} (merge)           storefront extras on existing seeded
                                   business profiles (cover, gallery, links,
                                   rating aggregate, verified badge, promoted)

Invariants respected (functions/src/shared/tierLimits.ts, effectiveTier.ts):
  * every event organizer / experience host has a plan (hasBaseAccess),
    otherwise onEventWrittenUsage deletes the event;
  * at most ONE upcoming event per organizer (Base cap = 1), the tester is
    Platinum (unlimited);
  * one experience per host (Base cap = 1), tester excepted;
  * paid events / experiences only by ACTIVE businesses (isBusiness + Silver+);
  * no ticketProvider on events, bookings `payment.mode` free or online/unpaid
    with orderId null -> no Stripe / Mercado Pago path can be reached;
  * business profiles are never community members unless they own it.

Usage:
  python -I tools/test_env/seed_test_content.py --dry-run
  python -I tools/test_env/seed_test_content.py
"""
from __future__ import annotations

import argparse
import collections
import datetime as dt
import hashlib
import json
import math
import os
import random
import re
import string
import sys
import time
import unicodedata

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fs_rest as F  # noqa: E402  (guards the project on import)
import seed_data as D  # noqa: E402
import seed_content_data as C  # noqa: E402
from seed_test_people import geohash_encode, jitter_point  # noqa: E402

PROJECT = "greengo-chat-test"
F.guard_project(PROJECT)
assert F.PROJECT == "greengo-chat-test" and "greengo-chat-test" in F.BASE
if "/projects/greengo-chat/" in F.BASE:
    sys.exit("REFUSING: production project")

SEED = 20261024
SEED_BATCH = "seed-content-2026-10-24-v1"
PEOPLE_BATCH = "seed-2026-10-23-v1"
MARK = {"isTestSeed": True, "seedBatch": SEED_BATCH}
STATE_FILE = "C:/dev/gg-logs/test_content_state.json"
LOGIN_EMAIL = "tester@greengo-test.dev"

NOW = dt.datetime.now(dt.timezone.utc).replace(microsecond=0)
FOCUS = ["São Paulo", "Rome", "Lisbon", "New York"]
CITY = {c[0]: c for c in D.CITIES}
TZ = {"São Paulo": -3, "Rome": 1, "Lisbon": 0, "New York": -5}

MAX_EVENTS_TOTAL = 200       # owner cap 2026-10-24 (incl. community + external)
MAX_EXPERIENCES = 200

EUROZONE = {"Italy", "Portugal", "Spain", "France", "Germany", "Austria", "Netherlands", "Belgium",
            "Ireland", "Finland", "Greece"}

# ---------------------------------------------------------------------------
ID_ALPHA = string.ascii_letters + string.digits


def auto_id(rng: random.Random, n: int = 20) -> str:
    return "".join(rng.choice(ID_ALPHA) for _ in range(n))


def ts(d: dt.datetime) -> F.Ts:
    return F.Ts(d)


def parse_ts(v) -> dt.datetime | None:
    if not v or not isinstance(v, str):
        return None
    try:
        return dt.datetime.fromisoformat(v.replace("Z", "+00:00"))
    except ValueError:
        return None


def currency_for(country: str):
    if country == "Brazil":
        return "R$", "brl"
    if country in EUROZONE:
        return "€", "eur"
    if country == "United Kingdom":
        return "£", "gbp"
    return "$", "usd"


def tz_offset(city: str, lng: float) -> int:
    return TZ.get(city, int(round(lng / 15.0)))


def local_dt(city: str, lng: float, day: dt.date, hour: int, minute: int = 0) -> dt.datetime:
    off = tz_offset(city, lng)
    return dt.datetime(day.year, day.month, day.day, hour, minute, tzinfo=dt.timezone.utc) - dt.timedelta(hours=off)


# --------------------------------------------------------------- keywords
def event_keywords(title, city, country, location_name, category, tags):
    toks: list[str] = []
    seen = set()

    def add(s):
        if not s:
            return
        for w in re.split(r"[^a-z0-9]+", s.lower()):
            if len(w) >= 2 and w not in seen:
                seen.add(w)
                toks.append(w)

    add(title)
    add(city)
    add(country)
    add(location_name)
    if category.lower() not in seen:
        seen.add(category.lower())
        toks.append(category.lower())
    for t in tags:
        add(t)
    return toks


_FOLD = {}
for _grp, _rep in {"àáâãäåāăą": "a", "çćĉċč": "c", "ďđð": "d", "èéêëēĕėęě": "e", "ĝğġģ": "g", "ĥħ": "h",
                   "ìíîïĩīĭįı": "i", "ĵ": "j", "ķ": "k", "ĺļľŀł": "l", "ñńņňŉ": "n", "òóôõöøōŏő": "o",
                   "ŕŗř": "r", "śŝşšș": "s", "ţťŧț": "t", "ùúûüũūŭůűų": "u", "ŵ": "w", "ýÿŷ": "y",
                   "źżž": "z", "ß": "ss", "æ": "ae", "œ": "oe", "þ": "th"}.items():
    for _ch in _grp:
        _FOLD[_ch] = _rep


def community_keywords(name, city, tags):
    """Port of lib/features/communities/domain/community_search_keywords.dart."""
    out, seen = [], set()
    for src in [name, city, *tags]:
        if not src:
            continue
        low = "".join(ch for ch in src.lower() if not (0x300 <= ord(ch) <= 0x36F))
        low = "".join(_FOLD.get(ch, ch) for ch in low)
        for tok in re.split(r"[^\w]+|_", low):
            if not tok:
                continue
            for i in range(1, min(len(tok), 15) + 1):
                p = tok[:i]
                if p not in seen:
                    seen.add(p)
                    out.append(p)
                    if len(out) >= 100:
                        return out
    return out


def experience_keywords(parts):
    out = []
    for p in parts:
        if not p:
            continue
        for t in re.split(r"[\s!-/:-@\[-`{-~]+", p.lower()):
            if len(t) >= 2 and t not in out:
                out.append(t)
            if len(out) >= 40:
                return out
    return out


# --------------------------------------------------------------- people
class Person:
    __slots__ = ("uid", "name", "photo", "city", "country", "langs", "tier", "eff", "base", "business",
                 "business_active", "biz_name", "biz_addr", "biz_cat", "culture", "is_tester", "raw")

    @property
    def display(self):
        return self.biz_name if self.business and self.biz_name else self.name


def effective_tier(p: dict) -> str:
    t = (p.get("membershipTier") or "FREE").upper()
    if t in ("FREE", "BASIC"):
        return "FREE"
    if t == "TEST":
        return "TEST"
    end = parse_ts(p.get("membershipEndDate"))
    return t if end and end > NOW else "FREE"


def has_base(p: dict) -> bool:
    if effective_tier(p) != "FREE":
        return True
    if p.get("hasBaseMembership") is not True:
        return False
    end = parse_ts(p.get("baseMembershipEndDate"))
    return bool(end and end > NOW)


CITY_CULTURE = {c[0]: c[6] for c in D.CITIES}


def load_people(login_uid: str) -> list[Person]:
    fields = ["userId", "displayName", "photoUrls", "location", "languages", "membershipTier", "membershipEndDate",
              "hasBaseMembership", "baseMembershipEndDate", "isBusiness", "businessName", "businessAddress",
              "businessCategory", "isTestSeed", "seedBatch", "accountStatus", "isBanned", "businessLogoUrl"]
    out = []
    for d in F.list_docs("profiles", mask=fields):
        p = F.dec_doc(d)
        if p.get("seedBatch") != PEOPLE_BATCH or p.get("isTestSeed") is not True:
            continue
        if p.get("accountStatus") != "active" or p.get("isBanned"):
            continue
        x = Person()
        x.uid = d["name"].rsplit("/", 1)[1]
        x.name = p.get("displayName") or "GreenGo"
        x.photo = (p.get("photoUrls") or [None])[0]
        loc = p.get("location") or {}
        x.city = loc.get("city")
        x.country = loc.get("country")
        x.langs = p.get("languages") or []
        x.tier = (p.get("membershipTier") or "FREE").upper()
        x.eff = effective_tier(p)
        x.base = has_base(p)
        x.business = p.get("isBusiness") is True
        x.business_active = x.business and x.eff != "FREE"
        x.biz_name = p.get("businessName")
        x.biz_addr = p.get("businessAddress")
        x.biz_cat = p.get("businessCategory")
        x.culture = CITY_CULTURE.get(x.city, "us")
        x.is_tester = x.uid == login_uid
        x.raw = p
        out.append(x)
    return out


def lang_of(person_or_city) -> str:
    culture = person_or_city if isinstance(person_or_city, str) else person_or_city.culture
    return C.content_lang(D.CULTURES.get(culture, D.CULTURES["us"])[0])


# --------------------------------------------------------------- writer
class Writer:
    def __init__(self, dry: bool, per_call: int = 400, pause: float = 1.2):
        self.dry, self.per_call, self.pause = dry, per_call, pause
        self.buf: list[dict] = []
        self.counts = collections.Counter()
        self.total = 0

    def set(self, path: str, data: dict, merge: bool = False, count_as: str | None = None):
        assert not path.startswith("/") and ".." not in path
        top = path.split("/")[0]
        assert top not in FORBIDDEN_TOP, f"refusing to write {path}"
        self.buf.append(F.set_write(path, data, merge=merge))
        key = count_as or "/".join(path.split("/")[0::2])
        self.counts[key] += 1
        if len(self.buf) >= self.per_call:
            self.flush()

    def flush(self):
        if not self.buf:
            return
        n = len(self.buf)
        if not self.dry:
            F.batch_write(self.buf)
            time.sleep(self.pause)
        self.total += n
        print(f"  wrote {n} (total {self.total})", flush=True)
        self.buf = []


# Never written by this script (production reference data / owner instruction).
FORBIDDEN_TOP = {"app_config", "feature_flags", "environment_config", "membership_config", "legal_documents",
                 "lessons", "flashcard_decks", "vocabulary_words", "vocabulary_sentences", "language_phrases",
                 "daily_phrases", "cultural_quizzes", "seasonal_events", "constellation", "city_coordinates",
                 "translations", "world_map_snapshots", "attractions", "attractions_index", "attractions_lite",
                 "attraction_cities", "attraction_countries", "attraction_name_index", "attraction_taxonomy",
                 "attraction_config", "attraction_stats", "attraction_ratings", "external_events_index"}


# --------------------------------------------------------------- selection
class Pool:
    """Hands out people near a city: same city, then same country, then anyone."""

    def __init__(self, people: list[Person], rng: random.Random):
        self.rng = rng
        self.by_city = collections.defaultdict(list)
        self.by_country = collections.defaultdict(list)
        self.all = people
        for p in people:
            self.by_city[p.city].append(p)
            self.by_country[p.country].append(p)

    def pick(self, city: str, pred, used: set | None = None, prefer_local: float = 1.0):
        country = CITY[city][2] if city in CITY else None
        tiers = [self.by_city.get(city, []), self.by_country.get(country, []), self.all]
        if self.rng.random() > prefer_local:
            tiers = [self.all]
        for tier in tiers:
            cands = [p for p in tier if pred(p) and (used is None or p.uid not in used)]
            if cands:
                c = self.rng.choice(cands)
                if used is not None:
                    used.add(c.uid)
                return c
        return None

    def sample_members(self, city: str, n: int, exclude: set, pred=lambda p: True):
        country = CITY[city][2]
        local = [p for p in self.by_city.get(city, []) if p.uid not in exclude and pred(p)]
        national = [p for p in self.by_country.get(country, []) if p.uid not in exclude and p.city != city and pred(p)]
        world = [p for p in self.all if p.uid not in exclude and p.country != country and pred(p)]
        self.rng.shuffle(local)
        self.rng.shuffle(national)
        self.rng.shuffle(world)
        n_local = min(len(local), int(n * 0.65))
        n_nat = min(len(national), int(n * 0.15))
        chosen = local[:n_local] + national[:n_nat]
        chosen += world[: max(0, n - len(chosen))]
        return chosen[:n]


def city_plan(rng: random.Random, total: int, focus_counts: dict[str, int]):
    """List of city names: fixed counts for the focus cities, rest weighted worldwide."""
    out = []
    for c, n in focus_counts.items():
        out += [c] * n
    others = [c for c in D.CITIES if c[0] not in FOCUS]
    weights = [c[7] for c in others]
    while len(out) < total:
        out.append(rng.choices(others, weights=weights, k=1)[0][0])
    rng.shuffle(out)
    return out


VENUES = {
    "pt_BR": ["Parque Central", "Centro Cultural", "Praça da Matriz", "Mercado Municipal", "Terraço Jardim", "Casa de Cultura"],
    "pt_PT": ["Jardim da Estrela", "Mercado da Ribeira", "Largo do Carmo", "Miradouro Central", "Centro Cultural"],
    "it": ["Piazza del Mercato", "Parco Centrale", "Centro Culturale", "Terrazza Panoramica", "Chiostro Antico"],
    "es": ["Plaza Mayor", "Parque Central", "Mercado de Abastos", "Centro Cultural", "Terraza del Río"],
    "fr": ["Place du Marché", "Parc Central", "Maison des Associations", "Quai des Arts"],
    "de": ["Marktplatz", "Stadtpark", "Kulturzentrum", "Dachterrasse am Fluss"],
    "en": ["Central Park Pavilion", "Riverside Terrace", "Old Town Square", "Community Arts Centre", "Harbour Market Hall",
           "Rooftop Garden"],
}

EVENT_CATEGORY = {"language": "languageExchange", "food": "food", "music": "nightlife", "outdoor": "outdoor",
                  "culture": "arts", "social": "social", "sports": "sports", "wellness": "wellness", "art": "arts",
                  "tech": "other", "photo": "arts", "travel": "travel", "coffee": "social", "wine": "food",
                  "volunteer": "other"}
EXP_CATEGORY = {"food": "foodDrink", "culture": "toursWalks", "music": "workshopsClasses", "outdoor": "natureOutdoors",
                "art": "workshopsClasses", "language": "languageLearning", "photo": "toursWalks", "wine": "foodDrink",
                "wellness": "wellness"}
COMMUNITY_TYPE = {"language": "language_circle", "food": "cultural_interest", "outdoor": "general",
                  "travel": "travel_group", "music": "cultural_interest", "sports": "general", "tech": "study_group",
                  "culture": "cultural_interest", "wellness": "general", "photo": "cultural_interest"}
TIP_TYPES = ["city_tip", "language_tip", "cultural_fact", "other_tip"]


def theme_text(bank: dict, theme: str, lang: str, rng: random.Random, city_local: str):
    opts = bank[theme].get(lang) or bank[theme]["en"]
    title, desc = rng.choice(opts)
    return title.format(city=city_local), desc.format(city=city_local)


def cover(theme: str, rng: random.Random) -> str:
    return C.noto(rng.choice(C.THEME_EMOJI[theme]))


# =========================================================================
def build(people: list[Person], tester: Person, rng: random.Random, w: Writer, state: dict):
    pool = Pool([p for p in people if not p.is_tester], rng)
    by_uid = {p.uid: p for p in people}
    upcoming_org: set[str] = set()   # organizers that already have an ACTIVE event
    exp_hosts: set[str] = set()      # hosts that already have an experience
    summary = collections.Counter()
    ids = collections.defaultdict(list)

    # ------------------------------------------------------------ communities
    comm_cities = city_plan(rng, 80, {"São Paulo": 10, "Rome": 8, "Lisbon": 8, "New York": 8})
    comm_themes = list(C.COMMUNITIES)
    communities = []  # (cid, city, theme, owner, members[list Person], lang)
    used_names = set()
    tester_member_cities = {"São Paulo": 3, "Rome": 1, "Lisbon": 1, "New York": 1}
    tester_owned = False
    for i, city in enumerate(comm_cities):
        c = CITY[city]
        lang = lang_of(c[6])
        for _ in range(10):
            theme = rng.choice(comm_themes)
            name, desc = theme_text(C.COMMUNITIES, theme, lang, rng, c[1])
            if name not in used_names:
                break
        used_names.add(name)
        cid = auto_id(rng)
        # Owner: tester owns one São Paulo community; ~8 owned by active businesses; rest by people with a plan
        if city == "São Paulo" and not tester_owned:
            owner, tester_owned = tester, True
        elif rng.random() < 0.10:
            owner = pool.pick(city, lambda p: p.business_active) or pool.pick(city, lambda p: p.base and not p.business)
        else:
            owner = pool.pick(city, lambda p: p.base and not p.business)
        n_members = int(rng.triangular(10, 200, 28))
        members = pool.sample_members(city, n_members - 1, {owner.uid, tester.uid}, pred=lambda p: not p.business)
        if owner.uid != tester.uid and tester_member_cities.get(city, 0) > 0:
            tester_member_cities[city] -= 1
            members.append(tester)
        communities.append((cid, city, theme, owner, members, lang, name, desc))

    for cid, city, theme, owner, members, lang, name, desc in communities:
        c = CITY[city]
        created = NOW - dt.timedelta(days=rng.randint(20, 240), hours=rng.randint(0, 23))
        all_members = [(owner, "owner")] + [(m, "admin" if j < rng.randint(0, 2) else "member") for j, m in enumerate(members)]
        for m, role in all_members:
            joined = created if role == "owner" else created + dt.timedelta(
                minutes=rng.randint(10, max(11, int((NOW - created).total_seconds() // 60) - 60)))
            w.set(f"communities/{cid}/members/{m.uid}", {
                "userId": m.uid, "displayName": m.display, "photoUrl": m.photo, "role": role,
                "joinedAt": ts(joined), "languages": m.langs, "isLocalGuide": False, "isMuted": False,
                "isBanned": False, "canWriteTips": role != "member" or rng.random() < 0.15,
                "canWriteAnnouncements": role != "member", **MARK})
        # messages: chat + tips + announcements (all inside the newest 50)
        msgs = []
        posters = [owner] + members[:40]
        span_min = 30 * 24 * 60
        n_chat = rng.randint(5, 30)
        for _ in range(n_chat):
            s = rng.choice(posters)
            ml = lang_of(s) if rng.random() < 0.5 else lang
            msgs.append((NOW - dt.timedelta(minutes=rng.randint(5, span_min)), s, "text", rng.choice(C.CHAT.get(ml, C.CHAT["en"]))))
        for _ in range(rng.randint(1, 4)):
            s = rng.choice([owner] + members[:8])
            t, b = rng.choice(C.TIPS.get(lang, C.TIPS["en"]))
            msgs.append((NOW - dt.timedelta(minutes=rng.randint(60, span_min)), s, rng.choice(TIP_TYPES), f"{t}\n{b}"))
        anns = C.ANNOUNCEMENTS.get(lang, C.ANNOUNCEMENTS["en"])
        for k in range(rng.randint(1, 2)):
            t, b = anns[k % len(anns)]
            msgs.append((NOW - dt.timedelta(minutes=rng.randint(60, span_min)), owner, "announcement", f"{t}\n{b}"))
        msgs.sort(key=lambda x: x[0])
        for at, s, typ, content in msgs:
            doc = {"senderId": s.uid, "senderName": s.display, "senderPhotoUrl": s.photo, "content": content,
                   "sentAt": ts(at), "type": typ, **MARK}
            if typ == "announcement":
                doc["fannedOut"] = True  # announcementFanout.ts skips fanned-out docs
            w.set(f"communities/{cid}/messages/{auto_id(rng)}", doc)
            summary["community_messages_" + ("chat" if typ == "text" else "announcement" if typ == "announcement" else "tip")] += 1
        last = msgs[-1]
        preview = last[3] if len(last[3]) <= 100 else last[3][:100] + "..."
        langs = [C.ISO[lang]] + (["en"] if C.ISO[lang] != "en" else []) + (["es"] if rng.random() < 0.2 else [])
        tags = {"language": ["languages", "exchange"], "food": ["food", "restaurants"], "outdoor": ["hiking", "nature"],
                "travel": ["travel", "meetups"], "music": ["music", "concerts"], "sports": ["running", "fitness"],
                "tech": ["coworking", "remote work"], "culture": ["museums", "art"], "wellness": ["yoga", "wellbeing"],
                "photo": ["photography"]}[theme]
        rules = {"pt_BR": "Respeito sempre. Sem spam. Ajude os recém-chegados!", "pt_PT": "Respeito sempre. Sem spam.",
                 "it": "Rispetto sempre. Niente spam. Aiuta i nuovi arrivati!", "es": "Respeto siempre. Nada de spam.",
                 "fr": "Respect toujours. Pas de spam.", "de": "Immer respektvoll. Kein Spam."}.get(
            lang, "Be kind. No spam. Help newcomers feel at home!")
        w.set(f"communities/{cid}", {
            "name": name, "description": desc, "type": "local_guides" if rng.random() < 0.08 else COMMUNITY_TYPE[theme],
            "imageUrl": cover(theme, rng), "coverFocalX": 0.0, "coverFocalY": 0.0, "coverZoom": 1.0,
            "createdByUserId": owner.uid, "createdByName": owner.display, "createdAt": ts(created),
            "memberCount": len(all_members), "languages": langs, "tags": tags, "isPublic": True,
            "city": city, "country": c[2], "lastMessagePreview": preview, "lastActivityAt": ts(last[0]),
            "sponsorId": None, "isSponsored": False, "pinnedPromo": None, "rules": rules, "resourceLinks": [],
            "searchKeywords": community_keywords(name, city, tags), **MARK})
        summary["communities"] += 1
        if owner.is_tester or any(m.is_tester for m in members):
            summary["tester_communities_" + ("owner" if owner.is_tester else "member")] += 1
        summary["community_members"] += len(all_members)
        ids["communities"].append(cid)
    w.flush()

    # ------------------------------------------------------------ events
    def make_event(eid, org: Person, city, theme, start, dur_h, *, community=None, paid=False, past=False):
        c = CITY[city]
        lang = lang_of(c[6])
        title, desc = theme_text(C.EVENTS, theme, lang, rng, c[1])
        lat, lng = jitter_point(rng, c[4], c[5], 6 if city in FOCUS else 8)
        venue = rng.choice(VENUES.get(lang, VENUES["en"]))
        cat = EVENT_CATEGORY[theme]
        tags = [theme] + ([rng.choice(["free", "friends", "international"])] if not paid else ["tickets"])
        cur = currency_for(c[2]) if paid else (None, None)
        price = float(rng.choice([15, 20, 25, 30, 35, 40, 50, 60])) if paid else None
        max_att = rng.choice([15, 20, 25, 30, 40, 50, 80])
        created = min(start, NOW) - dt.timedelta(days=rng.randint(3, 30))
        # attendees (written BEFORE the event doc)
        cands = pool.sample_members(city, rng.randint(2, min(max_att - 1, 35)), {org.uid, tester.uid}) if not community else \
            [m for m in community[4] if m.uid not in (org.uid, tester.uid)][: rng.randint(2, 25)]
        going = 0
        for a in cands:
            status = "going" if rng.random() < 0.8 else "interested"
            going += status == "going"
            w.set(f"events/{eid}/attendees/{a.uid}", attendee_doc(eid, a, status, created))
        tester_status = TESTER_RSVP.get(eid)
        if tester_status:
            going += tester_status == "going"
            w.set(f"events/{eid}/attendees/{tester.uid}", attendee_doc(eid, tester, tester_status, created))
            summary[f"tester_rsvp_{tester_status}_{'past' if past else 'upcoming'}"] += 1
        if org.is_tester:
            summary[f"tester_hosting_{'past' if past else 'upcoming'}"] += 1
        likers = rng.sample(cands, k=min(len(cands), rng.randint(0, 8)))
        for a in likers:
            w.set(f"events/{eid}/likes/{a.uid}", {"userId": a.uid, "createdAt": ts(created + dt.timedelta(hours=rng.randint(1, 48))), **MARK})
        doc = {
            "organizerId": org.uid, "organizerName": org.display, "organizerPhotoUrl": org.photo,
            "title": title, "description": desc, "category": cat, "imageUrl": cover(theme, rng),
            "coverFocalX": 0.0, "coverFocalY": 0.0, "coverZoom": 1.0, "photoUrls": [], "allowedScannerIds": [],
            "coOrganizerIds": [], "startDate": ts(start), "endDate": ts(start + dt.timedelta(hours=dur_h)),
            "locationName": f"{venue}, {c[1]}", "latitude": lat, "longitude": lng, "geohash": geohash_encode(lat, lng, 9),
            "address": None, "maxAttendees": max_att, "price": price, "currency": cur[0], "status": "published",
            "tags": tags, "isVerified": False, "requiresApproval": False, "minAge": None, "maxAge": None,
            "genderPreference": None, "languages": [C.LANG_NAME[lang]] + (["English"] if lang != "en" else []),
            "languagePairs": None, "city": city, "country": c[2], "attendeeCount": going, "likeCount": len(likers),
            "viewCount": rng.randint(going, going * 6 + 10),
            "createdAt": ts(created), "updatedAt": None, "visibility": "public",
            "attendeeListVisibility": "participants", "externalLinks": [], "isFeatured": False, "featuredUntil": None,
            "guestsAllowedPerAttendee": 0, "seriesId": None, "communityId": community[0] if community else None,
            "ticketProvider": None, "ticketLinkMethod": None, "ticketPaymentInstructions": None,
            "currencyCode": cur[1], "maxTicketsPerUser": 4, "guestsAllowed": False, "requireAttendeeNames": False,
            "pricePhases": [], "recurrence": None, "publishAt": None, "ticketTiers": [],
            "searchKeywords": event_keywords(title, city, c[2], f"{venue}, {c[1]}", cat, tags),
            # Trigger idempotency flags: never fan out pushes for seeded events.
            "pushedToCommunity": True, "pushedToFollowers": True, "cityAlertSent": True,
            "reminded24h": True, "reminded6h": True, "remindedStart": True,
            **MARK,
        }
        w.set(f"events/{eid}", doc)
        summary["events_paid_looking" if paid else "events_free"] += 1
        summary["events_past" if past else "events_upcoming"] += 1
        summary["event_attendees"] += len(cands) + (1 if tester_status else 0)
        summary["event_likes"] += len(likers)
        ids["events"].append(eid)
        STATS[c[2]].append(doc | {"id": eid})

    def attendee_doc(eid, a: Person, status, created):
        return {"eventId": eid, "userId": a.uid, "userName": a.display, "userPhotoUrl": a.photo, "status": status,
                "rsvpDate": ts(created + dt.timedelta(hours=rng.randint(1, 72))), "isApproved": True,
                "isInvisible": False, "isAnonymous": False, "muteNotifications": False,
                "visibleToOrganizerOnly": False, "checkedIn": False, "checkedInAt": None, "guestCount": 0,
                "tierId": None, **MARK}

    STATS = collections.defaultdict(list)
    TESTER_RSVP: dict[str, str] = {}

    def start_time(city, past: bool):
        c = CITY[city]
        day = (NOW + dt.timedelta(days=(-rng.randint(3, 60) if past else rng.randint(2, 45)))).date()
        hour = rng.choice([9, 10, 11, 15, 17, 18, 19, 20])
        return local_dt(city, c[5], day, hour, rng.choice([0, 0, 30]))

    N_EXTERNAL_TM, N_EXTERNAL_VIATOR = 30, 20
    N_COMMUNITY_EVENTS = 25
    n_standalone = MAX_EVENTS_TOTAL - N_EXTERNAL_TM - N_EXTERNAL_VIATOR - N_COMMUNITY_EVENTS  # 125

    # community events (organizer = owner; owner must not have another active event)
    ce_comms = [x for x in communities if x[3].base]
    rng.shuffle(ce_comms)
    focus_first = sorted(ce_comms, key=lambda x: x[1] not in FOCUS)
    picked = []
    for x in focus_first:
        if len(picked) >= N_COMMUNITY_EVENTS:
            break
        if x[3].uid in upcoming_org and not x[3].is_tester:
            continue
        picked.append(x)
        upcoming_org.add(x[3].uid)
    tester_comm_events = 0
    for k, x in enumerate(picked):
        cid, city, theme, owner, members = x[:5]
        past = k % 5 == 4
        eid = auto_id(rng)
        if any(m.uid == tester.uid for m in members) and not past and tester_comm_events < 3:
            TESTER_RSVP[eid] = "going"
            tester_comm_events += 1
        ev_theme = theme if theme in C.EVENTS else "social"
        make_event(eid, owner, city, ev_theme, start_time(city, past), rng.choice([2, 3]), community=x, past=past)
        summary["events_community"] += 1
    w.flush()

    # standalone events
    ev_cities = city_plan(rng, n_standalone, {"São Paulo": 22, "Rome": 18, "Lisbon": 18, "New York": 18})
    tester_org_left = {"up": 2, "past": 1}
    tester_rsvp_left = {"São Paulo": 3, "Rome": 1, "Lisbon": 2, "New York": 1}
    for k, city in enumerate(ev_cities):
        past = k % 4 == 3  # ~25 % past
        paid = (not past) and rng.random() < 0.18
        theme = rng.choice(C.THEMES)
        eid = auto_id(rng)
        org = None
        if city == "São Paulo":
            if past and tester_org_left["past"]:
                org, tester_org_left["past"] = tester, tester_org_left["past"] - 1
            elif not past and not paid and tester_org_left["up"]:
                org, tester_org_left["up"] = tester, tester_org_left["up"] - 1
        if org is None:
            if paid:
                org = pool.pick(city, lambda p: p.business_active and p.uid not in upcoming_org)
                if org is None:
                    paid = False
            if org is None:
                if past:
                    org = pool.pick(city, lambda p: p.base and not p.business)
                else:
                    org = pool.pick(city, lambda p: p.base and not p.business and p.uid not in upcoming_org)
        if not past and not org.is_tester:
            upcoming_org.add(org.uid)
        if org.uid != tester.uid:
            if past and city == "São Paulo" and "past_rsvp" not in state:
                TESTER_RSVP[eid], state["past_rsvp"] = "going", 1
            elif not past and tester_rsvp_left.get(city, 0) > 0:
                TESTER_RSVP[eid] = "going" if tester_rsvp_left[city] != 2 else "interested"
                tester_rsvp_left[city] -= 1
        if paid and org.business:
            theme = rng.choice(["food", "music", "wine", "art", "wellness", "culture"])
        make_event(eid, org, city, theme, start_time(city, past), rng.choice([2, 2, 3, 4]), paid=paid, past=past)
    state.pop("past_rsvp", None)
    w.flush()

    # globe aggregate (trigger not deployed in the test project)
    for country, evs in STATS.items():
        pub = [e for e in evs]
        top = sorted(pub, key=lambda e: -e["attendeeCount"])[:3]
        w.set(f"event_country_stats/{country}", {
            "country": country, "count": len(pub),
            "topEvents": [{"id": e["id"], "title": e["title"], "imageUrl": e["imageUrl"],
                           "attendeeCount": e["attendeeCount"], "city": e["city"], "startDate": e["startDate"]} for e in top],
            "updatedAt": ts(NOW), **MARK})
    w.flush()

    # ------------------------------------------------------------ external events (mock)
    ext_country = collections.Counter()
    tm_cities = city_plan(rng, N_EXTERNAL_TM, {"São Paulo": 6, "Rome": 5, "Lisbon": 5, "New York": 6})
    tm_kinds = [("Music", "1f3a4", ["Live: {city} Summer Sounds", "Jazz & Soul Night {city}", "Acoustic Sessions {city}",
                                    "Indie Rock Showcase {city}", "Symphony Under the Stars {city}"]),
                ("Sports", "26bd", ["{city} City Derby", "Basketball Night {city}", "{city} Half Marathon Expo"]),
                ("Arts & Theatre", "1f3ad", ["Comedy Night {city}", "Contemporary Dance {city}", "Musical Gala {city}"])]
    for k, city in enumerate(tm_cities):
        c = CITY[city]
        seg, emo, titles = rng.choice(tm_kinds)
        lat, lng = jitter_point(rng, c[4], c[5], 6)
        day = (NOW + dt.timedelta(days=rng.randint(2, 75))).date()
        cur = currency_for(c[2])[1].upper()
        xid = f"tm_testseed_{k:03d}"
        w.set(f"external_events/{xid}", {
            "source": "ticketmaster", "externalId": f"testseed-{k:03d}",
            "title": rng.choice(titles).format(city=c[1]),
            "description": "Mock event for the GreenGo test environment (fictional).",
            "imageUrl": C.noto(emo), "hasImage": True, "imageIsFallback": False, "category": seg,
            "city": city, "country": c[2], "lat": lat, "lng": lng, "geohash": geohash_encode(lat, lng, 9),
            "fromPrice": float(rng.choice([25, 35, 45, 60, 80, 120])), "currency": cur, "rating": 0, "reviewCount": 0,
            "startDate": day.isoformat(), "bookingUrl": f"https://example.com/greengo-test-seed/{xid}",
            "fetchedAt": ts(NOW), **MARK})
        ext_country[("ticketmaster", c[2])] += 1
        summary["external_events_ticketmaster"] += 1
    vi_cities = city_plan(rng, N_EXTERNAL_VIATOR, {"São Paulo": 4, "Rome": 4, "Lisbon": 4, "New York": 4})
    vi_kinds = [("food_drink", "1f35d", "Food & Wine Tasting Walk in {city}"), ("culture", "1f3db", "Historic Centre and Museum Tour in {city}"),
                ("city_tours", "1f6b2", "Bike Tour of {city} Highlights"), ("nature", "26f0", "Nature Day Trip from {city}"),
                ("cruises", "26f5", "Sunset Boat Cruise in {city}"), ("day_trips", "1f68c", "Full-Day Excursion from {city}")]
    for k, city in enumerate(vi_cities):
        c = CITY[city]
        cat, emo, title = rng.choice(vi_kinds)
        lat, lng = c[4], c[5]
        xid = f"viator_testseed_{k:03d}"
        w.set(f"external_events/{xid}", {
            "source": "viator", "externalId": f"testseed-{k:03d}", "title": title.format(city=city),
            "description": "Mock partner experience for the GreenGo test environment (fictional).",
            "imageUrl": C.noto(emo), "hasImage": True, "category": cat, "city": city, "country": c[2],
            "lat": lat, "lng": lng, "geohash": geohash_encode(lat, lng, 9),
            "fromPrice": float(rng.choice([29, 39, 49, 59, 79, 99])), "currency": currency_for(c[2])[1].upper(),
            "rating": round(rng.uniform(4.2, 4.95), 1), "reviewCount": rng.randint(12, 2400),
            "durationMinutes": rng.choice([90, 120, 180, 240, 480]),
            "bookingUrl": f"https://example.com/greengo-test-seed/{xid}", "fetchedAt": ts(NOW), **MARK})
        ext_country[("viator", c[2])] += 1
        summary["external_events_viator"] += 1
    for (src, country), n in ext_country.items():
        w.set(f"external_country_stats/{src}_{country}", {"source": src, "country": country, "count": n,
                                                          "updatedAt": ts(NOW), **MARK})
    w.flush()

    # ------------------------------------------------------------ experiences
    exp_cities = city_plan(rng, 150, {"São Paulo": 28, "Rome": 24, "Lisbon": 28, "New York": 24})
    assert len(exp_cities) <= MAX_EXPERIENCES
    exp_themes = list(C.EXPERIENCES)
    bookings_for_dispatch = []
    exp_records = []
    tester_hosted = False
    tester_guest_plan = ["confirmed", "confirmed", "requested", "completed", "completed", "cancelled_by_guest"]
    for k, city in enumerate(exp_cities):
        c = CITY[city]
        lang = lang_of(c[6])
        theme = rng.choice(exp_themes)
        paid = rng.random() < 0.22
        host = None
        if city == "São Paulo" and not tester_hosted:
            host, tester_hosted, paid = tester, True, False
        if host is None and paid:
            host = pool.pick(city, lambda p: p.business_active and p.uid not in exp_hosts)
            if host is None:
                paid = False
        if host is None:
            host = pool.pick(city, lambda p: p.base and p.uid not in exp_hosts and not p.business)
        exp_hosts.add(host.uid)
        title, desc = theme_text(C.EXPERIENCES, theme, lang, rng, c[1])
        if len(desc) < 30:
            desc += " " + {"pt_BR": "Venha viver isso comigo!", "pt_PT": "Venha viver isto comigo!", "it": "Vieni a viverlo con me!",
                           "es": "¡Ven a vivirlo conmigo!", "fr": "Venez le vivre avec moi !", "de": "Erlebe es mit mir!"}.get(lang, "Come and enjoy it with me!")
        lat, lng = jitter_point(rng, c[4], c[5], 6)
        venue = rng.choice(VENUES.get(lang, VENUES["en"]))
        cat = EXP_CATEGORY[theme]
        dur = rng.choice([60, 90, 120, 150, 180, 240])
        max_g = rng.choice([4, 6, 8, 10, 12])
        sym, code = currency_for(c[2])
        price = float(rng.choice([25, 35, 45, 55, 70, 90, 120])) if paid else 0.0
        created = NOW - dt.timedelta(days=rng.randint(15, 200))
        xid = auto_id(rng)
        included = {"food": ["Ingredients", "Drinks", "Recipes to take home"], "culture": ["Local guide", "Stories and tips"],
                    "music": ["Instructor", "Water"], "outdoor": ["Guide", "Snack"], "art": ["All materials", "Your finished piece"],
                    "language": ["Coffee", "Conversation practice"], "photo": ["Photo tips", "Route map"],
                    "wine": ["Tastings", "Snacks"], "wellness": ["Mat", "Tea after class"]}[theme]
        doc = {
            "title": title[:80], "description": desc[:2000], "category": cat, "mainPhotoUrl": cover(theme, rng),
            "coverFocalX": 0.0, "coverFocalY": 0.0, "coverZoom": 1.0,
            "photoUrls": [cover(theme, rng) for _ in range(rng.randint(1, 3))],
            "included": included, "notIncluded": ["Transport"] if rng.random() < 0.5 else [],
            "locationName": f"{venue}, {c[1]}", "city": city, "country": c[2], "lat": lat, "lng": lng,
            "geohash": geohash_encode(lat, lng, 9), "meetingPoint": venue, "durationMinutes": dur,
            "languages": [C.LANG_NAME[lang]] + (["English"] if lang != "en" else []),
            "minGroupSize": 1, "maxGroupSize": max_g, "price": price, "currency": sym if paid else None,
            "isFree": not paid, "paymentMethods": ["online"] if paid else [],
            "paymentProvider": "stripe" if paid else None, "paymentLink": None, "paymentLinkMethod": None,
            "paymentInstructions": None, "pricingMode": "per_person", "groupPrice": None, "weekendPrice": None,
            "weekendDays": None, "maxTicketsPerUser": 4, "guestsAllowed": False, "availability": None,
            "requestToBook": True, "cancellationPolicy": rng.choice(["flexible", "moderate", "moderate", "strict"]),
            "cancellationNotes": None, "hostName": host.display, "hostPhotoUrl": host.photo,
            "searchKeywords": experience_keywords([title, city, c[2], cat, f"{venue}, {c[1]}"]),
            "status": "published", "hostId": host.uid, "createdAt": ts(created), "updatedAt": ts(created),
            "ratingSum": 0, "ratingCount": 0, "ratingAvg": 0, "reviewCount": 0,
            "ratingDist": {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}, "viewCount": rng.randint(5, 400),
            "isFeatured": False, "hostRatingCounted": True, **MARK,
        }
        if k % 25 == 0:
            doc["isFeatured"], doc["featuredUntil"] = True, ts(NOW + dt.timedelta(days=rng.randint(5, 25)))
        w.set(f"user_experiences/{xid}", doc)
        w.set(f"user_experience_counts/{host.uid}", {"count": 1 if not host.is_tester else 1, "updatedAt": ts(NOW), **MARK})
        exp_records.append((xid, doc, host, city, paid, price, code, created))
        summary["experiences_paid" if paid else "experiences_free"] += 1
        ids["experiences"].append(xid)
    w.flush()

    # slots + bookings (+ reviews afterwards)
    reviews = []
    for xid, doc, host, city, paid, price, code, created in exp_records:
        c = CITY[city]
        dur = doc["durationMinutes"]
        cap = doc["maxGroupSize"]
        slot_list = []
        for _ in range(rng.randint(3, 6)):  # upcoming windows
            day = (NOW + dt.timedelta(days=rng.randint(2, 40))).date()
            st = local_dt(city, c[5], day, rng.choice([9, 10, 14, 16, 18]))
            slot_list.append(st)
        past_slots = [local_dt(city, c[5], (NOW - dt.timedelta(days=rng.randint(5, 120))).date(), rng.choice([10, 15, 18]))
                      for _ in range(rng.randint(0, 3))]
        slot_ids = {}
        booked = collections.Counter()
        books = []  # (bid, guest, status, slot_start)
        guests_pool = pool.sample_members(city, 12, {host.uid, tester.uid}, pred=lambda p: not p.business)
        gi = 0
        for st in past_slots:
            for _ in range(rng.randint(1, 3)):
                if gi >= len(guests_pool):
                    break
                books.append((guests_pool[gi], "completed", st))
                gi += 1
        for st in slot_list:
            if rng.random() < 0.45 and gi < len(guests_pool):
                books.append((guests_pool[gi], "confirmed", st))
                gi += 1
        if host.is_tester:  # incoming requests for the tester's own listing
            for status in ("requested", "confirmed", "confirmed"):
                if gi < len(guests_pool):
                    books.append((guests_pool[gi], status, rng.choice(slot_list)))
                    gi += 1
        elif tester_guest_plan and city in FOCUS and rng.random() < 0.35:
            status = tester_guest_plan.pop(0)
            st = rng.choice(past_slots) if status == "completed" and past_slots else rng.choice(slot_list)
            if status == "completed" and not past_slots:
                st = local_dt(city, c[5], (NOW - dt.timedelta(days=rng.randint(5, 40))).date(), 10)
                past_slots.append(st)
            books.append((tester, status, st))
        for st in slot_list + past_slots:
            slot_ids[st] = auto_id(rng)
        for guest, status, st in books:
            n_guests = 1 if rng.random() < 0.7 else 2
            if booked[st] + n_guests > cap:
                continue
            if status in ("requested", "confirmed", "completed"):
                booked[st] += n_guests
            bid = "bk_" + hashlib.sha256(f"{guest.uid}:{xid}:{st.isoformat()}:{SEED_BATCH}".encode()).hexdigest()[:28]
            end = st + dt.timedelta(minutes=dur)
            unit = int(round(price * 100))
            bdoc = {
                "experienceId": xid, "slotId": slot_ids[st], "hostId": host.uid, "guestId": guest.uid,
                "guests": n_guests, "status": status, "requestToBook": True, "policy": doc["cancellationPolicy"],
                "experienceTitle": doc["title"][:120], "slotStart": ts(st), "slotEnd": ts(end),
                "price": {"unitAmount": unit, "currency": code if paid else None, "totalAmount": unit * n_guests},
                "priceRule": "base", "pricingMode": "per_person", "maxGroupSize": cap,
                "payment": ({"mode": "online", "provider": "stripe", "status": "unpaid", "orderId": None, "link": None,
                             "guestMarkedPaidAt": None, "hostConfirmedPaidAt": None} if paid else
                            {"mode": "free", "link": None, "guestMarkedPaidAt": None, "hostConfirmedPaidAt": None}),
                "refundDue": None, "cancellation": None, "checkIn": None, "dispute": None,
                "consentVersion": "1", "requestId": f"seed-{bid[3:15]}",
                "createdAt": ts(min(st, NOW) - dt.timedelta(days=rng.randint(2, 20))), "updatedAt": ts(NOW),
                **MARK,
            }
            if status == "requested":
                bdoc["requestExpiresAt"] = ts(min(NOW + dt.timedelta(hours=48), st - dt.timedelta(hours=2)))
            if status in ("confirmed", "completed"):
                bdoc["confirmedAt"] = bdoc["respondedAt"] = bdoc["createdAt"]
            if status == "completed":
                bdoc["completedAt"] = ts(end + dt.timedelta(hours=24))
                bdoc["checkIn"] = {"at": ts(st), "byUid": host.uid}
            if status == "cancelled_by_guest":
                bdoc["cancellation"] = {"by": "guest", "at": ts(NOW - dt.timedelta(days=1)), "reason": "change_of_plans"}
            # Pre-claim the booking e-mail keys of the statuses that send mail
            # (requested / confirmed): emailBookingQrOnConfirm then sees "duplicate".
            for key in () if status not in ("requested", "confirmed") else (f"booking_qr_{bid}", f"booking_request_host_{bid}", f"booking_request_guest_{bid}",
                        f"booking_confirmed_host_{bid}", f"booking_confirmed_guest_{bid}"):
                w.set(f"email_dispatch/{key}", {"status": "skipped", "reason": "test_seed",
                                                "claimedAt": ts(NOW), "expireAt": ts(NOW + dt.timedelta(days=180)), **MARK})
            bookings_for_dispatch.append((bid, bdoc))
            if status == "completed" and (guest.is_tester and len([r for r in reviews if r[1].is_tester]) == 0 or
                                          (not guest.is_tester and rng.random() < 0.8)):
                reviews.append((xid, guest, bid, end, lang_of(guest)))
            summary[f"bookings_{status}"] += 1
            if guest.is_tester:
                summary[f"tester_bookings_{status}"] += 1
        for st, sid in slot_ids.items():
            w.set(f"user_experiences/{xid}/slots/{sid}", {
                "start": ts(st), "end": ts(st + dt.timedelta(minutes=dur)), "capacity": cap,
                "bookedCount": booked[st], "status": "open", "createdAt": ts(created), "updatedAt": ts(NOW), **MARK})
            summary["experience_slots"] += 1
    w.flush()  # dispatch claims + slots BEFORE bookings
    for bid, bdoc in bookings_for_dispatch:
        w.set(f"bookings/{bid}", bdoc)
        ids["bookings"].append(bid)
    w.flush()

    print("waiting 20 s so experience create triggers settle before reviews ...")
    if not w.dry:
        time.sleep(20)
    seen_rev = set()
    for xid, guest, bid, end, rl in reviews:
        if (xid, guest.uid) in seen_rev:
            continue
        seen_rev.add((xid, guest.uid))
        rating = rng.choices([5, 4, 3], weights=[70, 25, 5])[0]
        at = end + dt.timedelta(days=rng.randint(1, 5))
        w.set(f"user_experiences/{xid}/reviews/{guest.uid}", {
            "authorId": guest.uid, "rating": rating, "comment": rng.choice(C.REVIEWS.get(rl, C.REVIEWS["en"])),
            "createdAt": ts(at), "updatedAt": ts(at), "bookingId": bid, "status": "visible", "hostNotified": True, **MARK})
        summary["experience_reviews"] += 1
    w.flush()

    # ------------------------------------------------------------ business storefronts
    businesses = [p for p in people if p.business]
    raters = [p for p in people if not p.business and not p.is_tester]
    promoted = 0
    biz_backup = {}
    for b in businesses:
        cat = b.biz_cat or "Cafe"
        emo = dict(D.BUSINESS_CATEGORIES).get(cat, "1f3ea")
        extra = {"Cafe": ["2615", "1f950", "1f9c1"], "Restaurant": ["1f35d", "1f957", "1f372"], "Bar": ["1f378", "1f37a", "1f377"],
                 "Hotel": ["1f3e8", "1f6cf", "1f305"], "Hostel": ["1f6cf", "1f392", "1f30d"], "Yoga Studio": ["1f9d8", "1f33f"],
                 "Gym": ["1f3cb", "1f4aa"], "Spa": ["1f486", "1f9d6", "1f33f"], "Art Gallery": ["1f5bc", "1f3a8"],
                 "Museum": ["1f3db", "1f5ff"], "Theater": ["1f3ad", "1f3ab"], "Live Music Venue": ["1f3b5", "1f3b8", "1f3b7"],
                 "Barbershop": ["1f488", "2702"], "Bakery": ["1f950", "1f35e", "1f370"]}.get(cat, ["1f3ea"])
        gallery = [C.noto(x) for x in [emo] + extra][:6]
        ratings = rng.sample(raters, k=rng.randint(3, 14))
        stars_sum = 0
        for r in ratings:
            s = rng.choices([5, 4, 3], weights=[65, 28, 7])[0]
            stars_sum += s
            w.set(f"business_ratings/{b.uid}/ratings/{r.uid}", {"stars": s, "updatedAt": ts(NOW - dt.timedelta(days=rng.randint(1, 90))), **MARK})
        summary["business_ratings"] += len(ratings)
        upd = {
            "coverImageUrl": C.noto(rng.choice(extra)), "galleryImages": gallery,
            "storefrontLinks": [f"https://example.com/greengo-test-seed/{b.uid[:10]}"],
            "businessVerified": rng.random() < 0.4, "ratingSum": stars_sum, "ratingCount": len(ratings),
            "businessSince": ts(NOW - dt.timedelta(days=rng.randint(30, 300))),
            "storefrontSeedBatch": SEED_BATCH,
        }
        if b.business_active and promoted < 5 and b.city in FOCUS:
            upd["businessPromotedUntil"] = ts(NOW + dt.timedelta(days=rng.randint(5, 20)))
            promoted += 1
        biz_backup[b.uid] = {k: b.raw.get(k) for k in upd}
        w.set(f"profiles/{b.uid}", upd, merge=True, count_as="profiles(storefront merge)")
        summary["business_storefronts_enriched"] += 1
    # tester follows a few businesses near the focus cities (Stores list)
    near = [b for b in businesses if b.city in FOCUS][:6]
    for b in near:
        w.set(f"business_followers/{b.uid}/followers/{tester.uid}", {"createdAt": ts(NOW), **MARK})
        w.set(f"user_business_following/{tester.uid}/businesses/{b.uid}", {"createdAt": ts(NOW), **MARK})
        summary["tester_follows_business"] += 1
    w.flush()

    state["ids"] = {k: v for k, v in ids.items()}
    state["businessBackup"] = biz_backup
    state["summary"] = dict(summary)
    return summary


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--allow-existing-external", action="store_true",
                    help="write mock external_events even if the collection already has docs")
    args = ap.parse_args()

    found = F.request("POST", f"{F.IDT}/accounts:lookup", {"email": [LOGIN_EMAIL]}).get("users", [])
    if not found:
        sys.exit("login user not found (run seed_test_people.py first)")
    login_uid = found[0]["localId"]
    people = load_people(login_uid)
    tester = next((p for p in people if p.is_tester), None)
    if tester is None:
        sys.exit("tester profile not in the seeded people")
    print(f"people: {len(people)}  with plan: {sum(p.base for p in people)}  active businesses: "
          f"{sum(p.business_active for p in people)}  tester={tester.uid} ({tester.eff})")
    if not args.dry_run and not args.allow_existing_external:
        n = F.count("external_events")
        if n:
            sys.exit(f"external_events already has {n} docs; refusing (use --allow-existing-external)")

    rng = random.Random(SEED)
    w = Writer(args.dry_run)
    state = {"seedBatch": SEED_BATCH, "project": PROJECT, "startedAt": NOW.isoformat(), "loginUid": login_uid}
    summary = build(people, tester, rng, w, state)
    w.flush()
    print("\nSUMMARY:", json.dumps(dict(sorted(summary.items())), indent=1, ensure_ascii=False))
    print("WRITES BY PATH:", json.dumps(dict(sorted(w.counts.items())), indent=1, ensure_ascii=False))
    ev_total = summary["events_free"] + summary["events_paid_looking"] + summary["external_events_ticketmaster"] + \
        summary["external_events_viator"]
    print(f"events incl. external: {ev_total} (cap {MAX_EVENTS_TOTAL}); experiences: "
          f"{summary['experiences_free'] + summary['experiences_paid']} (cap {MAX_EXPERIENCES})")
    assert ev_total <= MAX_EVENTS_TOTAL
    if not args.dry_run:
        state["writes"] = dict(w.counts)
        state["finishedAt"] = dt.datetime.now(dt.timezone.utc).isoformat()
        with open(STATE_FILE, "w", encoding="utf-8") as fh:
            json.dump(state, fh, indent=1, ensure_ascii=False, default=str)
        print(f"state -> {STATE_FILE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
