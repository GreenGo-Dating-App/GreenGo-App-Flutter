#!/usr/bin/env python3
"""
Translates the job files written by `build_i18n.js --step jobs` with Claude
Sonnet 5.5 through the Message Batches API (50% price), validates every item
and appends the good ones to build/tr/<kind>.jsonl.

Resumable: a submit only sends items that are NOT yet in build/tr/<kind>.jsonl
(re-read every time - never a saved offset), so re-running submit after a
collect retries exactly the rejected / failed items.

  python translate_batch.py submit  --kind tpl [--limit N]
  python translate_batch.py collect              # every finished batch
  python translate_batch.py status
  python translate_batch.py sync    --kind tpl --limit 40   # pilot, no batch
Kinds: tpl dict country state city cur about
Needs ANTHROPIC_API_KEY (or --key-file with an ANTHROPIC_API_KEY= line).
"""
import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

import anthropic

MODEL = "claude-sonnet-5-5"
HERE = Path(__file__).resolve().parent
BUILD = HERE / "build"
JOBS = BUILD / "jobs"
TR = BUILD / "tr"
BATCHES = BUILD / "batches.json"
LANGS = ["en", "it", "es", "pt", "pt_BR", "fr", "de"]
ENTITY_KINDS = {"country", "state"}

# Items per request: keeps every response well under max_tokens.
GROUP = {"tpl": 40, "dict": 60, "country": 30, "state": 40, "city": 120, "cur": 20, "about": 10}
# Templates and place names are reused thousands of times: let the model think.
THINK = {"tpl", "dict", "country", "state"}

LANG_NOTES = """Target languages (JSON keys):
- en: English (only requested when the source is in another language)
- it: Italian
- es: Spanish (neutral, understood in Spain and Latin America)
- pt: European Portuguese (Portugal: "autocarro", "comboio", European spelling)
- pt_BR: Brazilian Portuguese (Brazil: "ônibus", "trem", Brazilian spelling)
- fr: French
- de: German"""

COMMON = f"""You translate travel-guide content for GreenGo, a cultural discovery app, into the languages its users read.

{LANG_NOTES}

Rules for every item:
- Translate meaning, not words: the result must read as if written natively by a travel editor in that language.
- Never add, drop or invent facts. Keep every number, year, measurement, price and time exactly as given.
- Proper names: use the established name in the target language when one exists (Rome -> Roma, Munich -> Monaco di Baviera / Múnich / Munique / Munique / Munich / München, Colosseum -> Colosseo / Coliseo / Coliseu / Colisée / Kolosseum). Otherwise keep the original name. Never invent a translation for a name.
- "pt" and "pt_BR" are written separately: European vs Brazilian Portuguese.
- Fill ONLY the languages listed in the item's "targets"; return "" for every other language.
- Return every item you were given, with its exact "id"."""

KIND_RULES = {
    "tpl": """These items are SENTENCE TEMPLATES. They are filled in later for tens of thousands of attractions, so each placeholder must survive exactly:
  {N} = the attraction's name, {C} = city, {S} = region/state/province, {K} = country.
- Keep every placeholder of the source, the same number of times. Do not translate or alter the braces.
- Countries and regions need a preposition/article that depends on the place (it: "in Italia" / "negli Stati Uniti"; fr: "en France" / "au Japon"; de: "in der Schweiz"; pt: "no Brasil"). So whenever the sentence says "in {K}" use {in_K}, and for "of {K}" / "{K}'s" use {of_K}; same for regions: {in_S}, {of_S}. Use bare {K} / {S} only where the plain name works (subject, list, after a comma).
- {N} can be a masculine, feminine or plural name: phrase the sentence so nothing has to agree with {N} in gender or number (avoid adjectives/participles referring to {N}; restructure, e.g. it "{N} è uno dei luoghi più..." is fine, "{N} è famosa" is not).
- Do not put an article before {N}, {C} or bare {K}/{S}.
- Fragments (truncated text ending in "...", list items like "Standout collections") stay fragments; keep a trailing "..." if present.""",
    "dict": """These items are short values of fixed fields (opening hours, best season, visit duration, accessibility, safety, visitor numbers, photography tips). Translate them as concise UI values in the same style (e.g. "Open 24 hours", "Half day", "Spring & Autumn (Apr-Jun, Sep-Oct)"): translate month abbreviations, keep times (08:00-18:00) and number formats like "2M" as they are.""",
    "city": """These items are CITY/TOWN NAMES; "ctx" gives the region and country. Most places have no different name in other languages: then return the name unchanged. Change it only for a well-established exonym (Munich, Florence, Lisbon, Cologne, Venice, Seville, Warsaw...). Never translate the meaning of a name, never transliterate differently, never invent.""",
    "cur": """These items are short curiosities (fun facts) about the attraction named in "ctx". Translate each one faithfully and engagingly.""",
    "about": """These items are the "What is it?" text of an attraction (named in "ctx"): the lead of its Wikipedia article in the language given by "src". Translate it into each language in "targets" in a neutral encyclopedic tone. Keep it as one paragraph; no notes, no source mentions.""",
    "entity": """These items are COUNTRY or REGION names (ctx says which). For every language return three forms:
  name: the name as used in that language ("Stati Uniti", "Baviera", "Île-de-France");
  in:   the natural phrase meaning "in <place>" ("negli Stati Uniti", "in Baviera", "en Île-de-France", "aux États-Unis", "in den USA", "na Baviera", "nos Estados Unidos");
  of:   the natural phrase meaning "of <place>" as in "the capital of <place>" ("degli Stati Uniti", "della Baviera", "des États-Unis", "der USA", "von Bayern", "da Baviera", "dos Estados Unidos").
Use the established exonym when one exists; otherwise keep the name. Fill ALL seven languages (en too).""",
}


def schema(kind):
    if kind in ENTITY_KINDS:
        form = {"type": "object", "properties": {k: {"type": "string"} for k in ("name", "in", "of")},
                "required": ["name", "in", "of"], "additionalProperties": False}
        props = {"id": {"type": "string"}, **{l: form for l in LANGS}}
    else:
        props = {"id": {"type": "string"}, **{l: {"type": "string"} for l in LANGS}}
    item = {"type": "object", "properties": props, "required": list(props), "additionalProperties": False}
    return {"type": "object", "properties": {"items": {"type": "array", "items": item}},
            "required": ["items"], "additionalProperties": False}


def system(kind):
    rules = KIND_RULES["entity" if kind in ENTITY_KINDS else kind]
    return [{"type": "text", "text": f"{COMMON}\n\n{rules}", "cache_control": {"type": "ephemeral"}}]


def params(kind, items):
    msg = ("Translate these items. Output JSON only, matching the schema.\n\n"
           + json.dumps([{k: v for k, v in x.items()} for x in items], ensure_ascii=False))
    p = {
        "model": MODEL,
        "max_tokens": 32000,
        "system": system(kind),
        "messages": [{"role": "user", "content": msg}],
        "output_config": {"effort": "high" if kind in THINK else "medium",
                          "format": {"type": "json_schema", "schema": schema(kind)}},
    }
    if kind not in THINK:
        p["thinking"] = {"type": "between_tools"}
    return p


# ------------------------------------------------------------------ files

def read_jsonl(p):
    if not p.exists():
        return []
    with open(p, encoding="utf-8") as f:
        return [json.loads(l) for l in f if l.strip()]


def done_ids(kind):
    return {x["id"] for x in read_jsonl(TR / f"{kind}.jsonl")}


def pending(kind, limit=0):
    done = done_ids(kind)
    todo = [x for x in read_jsonl(JOBS / f"{kind}.jsonl") if x["id"] not in done]
    if kind in ENTITY_KINDS:
        for x in todo:
            x["targets"] = LANGS
    return todo[:limit] if limit else todo


def load_batches():
    return json.loads(BATCHES.read_text(encoding="utf-8")) if BATCHES.exists() else []


def save_batches(b):
    BATCHES.write_text(json.dumps(b, indent=1), encoding="utf-8")


# ------------------------------------------------------------- validation

PH = re.compile(r"\{(in_|of_)?([NCSK])\}")
STRAY = re.compile(r"[{}]")


def ph_base(text):
    return sorted(m.group(2) for m in PH.finditer(text))


def validate(kind, src, out):
    """Returns (clean translation dict, None) or (None, reason)."""
    res = {}
    for lang in src["targets"]:
        v = out.get(lang)
        if kind in ENTITY_KINDS:
            if not isinstance(v, dict) or not all(isinstance(v.get(k), str) and v[k].strip() for k in ("name", "in", "of")):
                return None, f"{lang}: missing form"
            res[lang] = {k: v[k].strip() for k in ("name", "in", "of")}
            continue
        if not isinstance(v, str) or not v.strip():
            return None, f"{lang}: empty"
        v = v.strip()
        if kind == "tpl":
            if ph_base(v) != ph_base(src["text"]):
                return None, f"{lang}: placeholders {ph_base(v)} != {ph_base(src['text'])}"
            bad = [m.group(0) for m in PH.finditer(v) if m.group(1) and m.group(2) in "NC"]
            if bad or STRAY.search(PH.sub("", v)):
                return None, f"{lang}: bad placeholder in {v!r}"
        elif STRAY.search(v) and not STRAY.search(src["text"]):
            return None, f"{lang}: stray brace"
        n = len(src["text"])
        if n >= 40 and not (0.45 <= len(v) / n <= 2.6):
            return None, f"{lang}: length ratio {len(v) / n:.2f}"
        res[lang] = v
    return res, None


def accept(kind, items, text, log):
    """Parses one response, appends valid items. Returns count accepted."""
    try:
        data = json.loads(text)["items"]
    except Exception as e:  # noqa: BLE001 - any malformed response = retry later
        log.write(json.dumps({"ids": [x["id"] for x in items], "reason": f"json: {e}"}) + "\n")
        return 0
    by_id = {x["id"]: x for x in items}
    good = 0
    with open(TR / f"{kind}.jsonl", "a", encoding="utf-8") as f:
        for out in data:
            src = by_id.pop(out.get("id"), None)
            if src is None:
                continue
            tr, why = validate(kind, src, out)
            if tr is None:
                log.write(json.dumps({"id": src["id"], "reason": why}, ensure_ascii=False) + "\n")
                continue
            f.write(json.dumps({"id": src["id"], "tr": tr}, ensure_ascii=False) + "\n")
            good += 1
    for missing in by_id:
        log.write(json.dumps({"id": missing, "reason": "not returned"}) + "\n")
    return good


# --------------------------------------------------------------- commands

def client(args):
    if args.key_file and not os.environ.get("ANTHROPIC_API_KEY"):
        for line in Path(args.key_file).read_text(encoding="utf-8").splitlines():
            if line.strip().startswith("ANTHROPIC_API_KEY="):
                os.environ["ANTHROPIC_API_KEY"] = line.split("=", 1)[1].strip()
    return anthropic.Anthropic()


def groups(kind, todo):
    g = GROUP[kind]
    return [todo[i:i + g] for i in range(0, len(todo), g)]


def cmd_submit(args):
    c = client(args)
    TR.mkdir(parents=True, exist_ok=True)
    open_ids = {i for b in load_batches() if b["kind"] == args.kind and not b.get("collected") for i in b["ids"]}
    todo = [x for x in pending(args.kind, args.limit) if x["id"] not in open_ids]
    if not todo:
        print(f"{args.kind}: nothing to submit")
        return
    stamp = int(time.time())
    chunks = [(f"{args.kind}-{stamp}-{n}", ch) for n, ch in enumerate(groups(args.kind, todo))]
    batches = load_batches()
    for i in range(0, len(chunks), 5000):  # stays far below the 256 MB / 100k limits
        part = chunks[i:i + 5000]
        b = c.messages.batches.create(requests=[{"custom_id": cid, "params": params(args.kind, ch)} for cid, ch in part])
        grp = {cid: [x["id"] for x in ch] for cid, ch in part}
        batches.append({"id": b.id, "kind": args.kind, "requests": len(part),
                        "ids": [i for v in grp.values() for i in v], "groups": grp,
                        "created": time.strftime("%Y-%m-%dT%H:%M:%S")})
        save_batches(batches)
        print(f"submitted {b.id}: {args.kind} {len(part)} requests")
    print(f"{args.kind}: {len(todo)} items in {len(chunks)} requests")


def cmd_collect(args):
    c = client(args)
    TR.mkdir(parents=True, exist_ok=True)
    batches = load_batches()
    jobs_cache = {}
    for b in batches:
        if b.get("collected"):
            continue
        info = c.messages.batches.retrieve(b["id"])
        if info.processing_status != "ended":
            rc = info.request_counts
            print(f"{b['id']} {b['kind']}: {info.processing_status} (processing {rc.processing}, done {rc.succeeded})")
            continue
        kind = b["kind"]
        if kind not in jobs_cache:
            jobs_cache[kind] = {x["id"]: x for x in pending(kind)}
        src = jobs_cache[kind]
        good = bad = 0
        usage = {"in": 0, "out": 0, "cache": 0}
        with open(TR / f"{kind}.rejects.jsonl", "a", encoding="utf-8") as log:
            for r in c.messages.batches.results(b["id"]):
                items = [src[i] for i in b["groups"].get(r.custom_id, []) if i in src]
                if r.result.type != "succeeded":
                    bad += len(items)
                    log.write(json.dumps({"ids": [x["id"] for x in items], "reason": r.result.type}) + "\n")
                    continue
                msg = r.result.message
                usage["in"] += msg.usage.input_tokens
                usage["out"] += msg.usage.output_tokens
                usage["cache"] += msg.usage.cache_read_input_tokens or 0
                if msg.stop_reason != "end_turn":
                    bad += len(items)
                    log.write(json.dumps({"ids": [x["id"] for x in items], "reason": f"stop {msg.stop_reason}"}) + "\n")
                    continue
                text = next((blk.text for blk in msg.content if blk.type == "text"), "")
                g = accept(kind, items, text, log)
                good += g
                bad += len(items) - g
        b["collected"] = True
        b["result"] = {"good": good, "bad": bad, **usage}
        save_batches(batches)
        print(f"{b['id']} {kind}: accepted {good}, rejected {bad}, tokens {usage}")


def cmd_status(args):
    for kind in GROUP:
        total = len(read_jsonl(JOBS / f"{kind}.jsonl"))
        print(f"{kind:8} done {len(done_ids(kind)):>6} / {total}")
    for b in load_batches():
        print(b["id"], b["kind"], b["requests"], "collected" if b.get("collected") else "open", b.get("result", ""))


def cmd_sync(args):
    """Pilot: same requests, sent directly (full price) so the output can be read at once."""
    c = client(args)
    TR.mkdir(parents=True, exist_ok=True)
    todo = pending(args.kind, args.limit or GROUP[args.kind])
    with open(TR / f"{args.kind}.rejects.jsonl", "a", encoding="utf-8") as log:
        for chunk in groups(args.kind, todo):
            with c.messages.stream(**params(args.kind, chunk)) as s:
                msg = s.get_final_message()
            if msg.stop_reason != "end_turn":
                print("stop:", msg.stop_reason)
                continue
            text = next((blk.text for blk in msg.content if blk.type == "text"), "")
            g = accept(args.kind, chunk, text, log)
            print(f"{args.kind}: accepted {g}/{len(chunk)}  usage in={msg.usage.input_tokens} "
                  f"out={msg.usage.output_tokens} cache_read={msg.usage.cache_read_input_tokens}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["submit", "collect", "status", "sync"])
    ap.add_argument("--kind", choices=list(GROUP))
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--key-file", default=os.environ.get("GREENGO_CREDENTIALS"))
    args = ap.parse_args()
    if args.cmd in ("submit", "sync") and not args.kind:
        sys.exit("--kind is required")
    {"submit": cmd_submit, "collect": cmd_collect, "status": cmd_status, "sync": cmd_sync}[args.cmd](args)


if __name__ == "__main__":
    main()
