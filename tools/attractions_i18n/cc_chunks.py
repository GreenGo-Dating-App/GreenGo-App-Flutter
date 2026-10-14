#!/usr/bin/env python3
"""
Translation through Claude Code sub-agents instead of the Batch API (no API
key needed). Same prompts and validation as translate_batch.py; the agents
read chunk files and write their answers next to them.

  python cc_chunks.py make   --kind tpl          # chunks of the pending items
  python cc_chunks.py check  --kind tpl --chunk tpl-r1-0007   # agent self-check
  python cc_chunks.py merge  --kind tpl          # validated answers -> tr/<kind>.jsonl
  python cc_chunks.py status

Layout: build/cc/<kind>/<chunk>.in.json   items to translate
        build/cc/<kind>/<chunk>.out.json  the agent's answer {"items": [...]}
        build/cc/<kind>/merged/           chunks already merged
        build/cc/RULES_<kind>.md          the instructions an agent reads
Resumable from the source: `make` only chunks items that are neither in
tr/<kind>.jsonl nor in an unmerged chunk, so rejected items come back in the
next round by themselves.
"""
import argparse
import json
import sys
from pathlib import Path

from translate_batch import (COMMON, ENTITY_KINDS, GROUP, JOBS, KIND_RULES, LANGS, TR, done_ids, pending,
                             read_jsonl, validate)

CC = Path(__file__).resolve().parent / "build" / "cc"
SIZE = {"tpl": 40, "dict": 60, "country": 30, "state": 40, "city": 150, "cur": 25, "about": 8}


def rules_text(kind):
    rules = KIND_RULES["entity" if kind in ENTITY_KINDS else kind]
    if kind in ENTITY_KINDS:
        shape = ('{"items": [{"id": "<id>", "en": {"name": "...", "in": "...", "of": "..."}, '
                 '"it": {...}, "es": {...}, "pt": {...}, "pt_BR": {...}, "fr": {...}, "de": {...}}]}')
    else:
        shape = ('{"items": [{"id": "<id>", "<lang>": "<translation>", ...}]}  '
                 '(one key per language in the item\'s "targets"; other languages may be omitted)')
    return f"""{COMMON}

{rules}

Output format: a UTF-8 JSON file
{shape}
Every item of the input chunk must appear once with its exact "id". Valid JSON: escape double
quotes inside strings as \\" and never put raw line breaks inside a string.
"""


def chunk_dir(kind):
    d = CC / kind
    (d / "merged").mkdir(parents=True, exist_ok=True)
    return d


def open_chunks(kind):
    return sorted(chunk_dir(kind).glob(f"{kind}-*.in.json"))


def cmd_make(args):
    kind = args.kind
    d = chunk_dir(kind)
    (CC / f"RULES_{kind}.md").write_text(rules_text(kind), encoding="utf-8")
    busy = {x["id"] for p in open_chunks(kind) for x in json.loads(p.read_text(encoding="utf-8"))}
    todo = [x for x in pending(kind) if x["id"] not in busy]
    if args.limit:
        todo = todo[:args.limit]
    rnd = 1 + max([int(p.name.split("-")[1][1:]) for p in d.glob(f"{kind}-r*.json")]
                  + [int(p.name.split("-")[1][1:]) for p in (d / "merged").glob(f"{kind}-r*.json")] + [0])
    size = args.size or SIZE[kind]
    names = []
    for n, i in enumerate(range(0, len(todo), size)):
        name = f"{kind}-r{rnd}-{n:04d}"
        (d / f"{name}.in.json").write_text(json.dumps(todo[i:i + size], ensure_ascii=False, indent=0),
                                           encoding="utf-8")
        names.append(name)
    print(f"{kind}: {len(todo)} items in {len(names)} chunks (round r{rnd})")
    if names:
        print(f"first {names[0]}  last {names[-1]}")


def check_one(kind, name):
    """Returns (good list, problems list)."""
    d = chunk_dir(kind)
    src = json.loads((d / f"{name}.in.json").read_text(encoding="utf-8"))
    out_p = d / f"{name}.out.json"
    if not out_p.exists():
        return [], [f"{name}.out.json missing"]
    try:
        data = json.loads(out_p.read_text(encoding="utf-8"))
        data = data["items"] if isinstance(data, dict) else data
    except Exception as e:  # noqa: BLE001
        return [], [f"invalid JSON: {e}"]
    by_id = {x["id"]: x for x in data if isinstance(x, dict)}
    good, probs = [], []
    for s in src:
        if kind in ENTITY_KINDS:
            s = {**s, "targets": LANGS}
        out = by_id.get(s["id"])
        if out is None:
            probs.append(f"{s['id']}: not returned")
            continue
        tr, why = validate(kind, s, out)
        if tr is None:
            probs.append(f"{s['id']}: {why}")
        else:
            good.append({"id": s["id"], "tr": tr})
    return good, probs


def cmd_check(args):
    good, probs = check_one(args.kind, args.chunk)
    for p in probs:
        print("PROBLEM", p)
    print(f"{args.chunk}: {len(good)} ok, {len(probs)} problems")
    sys.exit(1 if probs else 0)


def cmd_merge(args):
    kind = args.kind
    d = chunk_dir(kind)
    TR.mkdir(parents=True, exist_ok=True)
    done = done_ids(kind)
    total = rej = files = 0
    with open(TR / f"{kind}.jsonl", "a", encoding="utf-8") as f, \
            open(TR / f"{kind}.rejects.jsonl", "a", encoding="utf-8") as log:
        for inp in open_chunks(kind):
            name = inp.name[:-len(".in.json")]
            out = d / f"{name}.out.json"
            if not out.exists():
                continue
            good, probs = check_one(kind, name)
            for g in good:
                if g["id"] not in done:
                    f.write(json.dumps(g, ensure_ascii=False) + "\n")
                    done.add(g["id"])
                    total += 1
            for p in probs:
                log.write(json.dumps({"chunk": name, "reason": p}, ensure_ascii=False) + "\n")
            rej += len(probs)
            files += 1
            inp.replace(d / "merged" / inp.name)
            out.replace(d / "merged" / out.name)
    print(f"{kind}: merged {files} chunks, {total} items accepted, {rej} rejected (back to pending)")


def cmd_status(args):
    for kind in GROUP:
        if not (JOBS / f"{kind}.jsonl").exists():
            continue
        tot = len(read_jsonl(JOBS / f"{kind}.jsonl"))
        d = CC / kind
        ins = list(d.glob(f"{kind}-*.in.json")) if d.exists() else []
        outs = list(d.glob(f"{kind}-*.out.json")) if d.exists() else []
        print(f"{kind:8} done {len(done_ids(kind)):>6}/{tot:<6} open chunks {len(ins):>5}, answered {len(outs):>5}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["make", "check", "merge", "status"])
    ap.add_argument("--kind", choices=list(GROUP))
    ap.add_argument("--chunk")
    ap.add_argument("--size", type=int, default=0)
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()
    if args.cmd != "status" and not args.kind:
        sys.exit("--kind is required")
    {"make": cmd_make, "check": cmd_check, "merge": cmd_merge, "status": cmd_status}[args.cmd](args)


if __name__ == "__main__":
    main()
