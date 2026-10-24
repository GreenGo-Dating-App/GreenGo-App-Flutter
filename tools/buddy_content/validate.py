"""Validates generated Buddy content against SPEC.md and prints progress.

    python validate.py              # everything, summary + first errors
    python validate.py city_guides  # one topic, all errors

Progress is computed from the files on disk (never from a saved counter), so
an interrupted run resumes exactly where content is missing or invalid.
"""
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).parent
DATA = HERE / 'data'
LANGS = ['en', 'de', 'es', 'fr', 'it', 'pt', 'pt_BR']
TOPICS = json.loads((HERE / 'topics.json').read_text(encoding='utf-8'))
BLOCKS = [(s, min(s + 9, 365)) for s in range(1, 366, 10)]


def block_name(s, e):
    return f'd{s:03d}-{e:03d}.json'


def level_for(topic, d):
    if topic.startswith('practice_'):
        return 'A1' if d <= 90 else 'A2' if d <= 180 else 'B1' if d <= 280 else 'B2'
    return 'beginner' if d <= 120 else 'intermediate' if d <= 250 else 'advanced'


class Errors(list):
    def add(self, where, msg):
        self.append(f'{where}: {msg}')


def text(errs, where, v, maxlen):
    if not isinstance(v, str) or not v.strip():
        errs.add(where, 'missing text')
    elif len(v) > maxlen:
        errs.add(where, f'{len(v)} chars > {maxlen}')
    elif '\n' in v:
        errs.add(where, 'line break')


def load(errs, path):
    try:
        return json.loads(path.read_text(encoding='utf-8'))
    except Exception as e:  # noqa: BLE001
        errs.add(path.name, f'bad JSON: {e}')
        return None


def check_syllabus(topic, errs):
    p = DATA / 'syllabus' / f'{topic}.json'
    if not p.exists():
        return False
    j = load(errs, p)
    if not j:
        return False
    days = j.get('days') or []
    if [x.get('d') for x in days] != list(range(1, 366)):
        errs.add(p.name, 'days must be 1..365 in order')
        return False
    seen = set()
    before = len(errs)
    for x in days:
        w = f'{topic} syllabus d{x["d"]}'
        if x.get('lv') != level_for(topic, x['d']):
            errs.add(w, f'level {x.get("lv")} != {level_for(topic, x["d"])}')
        text(errs, w + ' t', x.get('t'), 60)
        text(errs, w + ' f', x.get('f'), 140)
        if x.get('t') in seen:
            errs.add(w, 'duplicate title')
        seen.add(x.get('t'))
    return len(errs) == before


def check_intro(topic, errs):
    p = DATA / 'intro' / f'{topic}.json'
    if not p.exists():
        return False
    j = load(errs, p)
    if not j:
        return False
    ok = True
    before = len(errs)
    for lang in LANGS:
        bubbles = (j.get('intro') or {}).get(lang)
        if not isinstance(bubbles, list) or len(bubbles) != 2:
            errs.add(f'{topic} intro {lang}', 'needs 2 bubbles')
            ok = False
            continue
        for i, b in enumerate(bubbles):
            text(errs, f'{topic} intro {lang}[{i}]', b, 200)
    return ok and len(errs) == before


def check_block(topic, s, e, errs):
    p = DATA / 'lessons' / topic / block_name(s, e)
    if not p.exists():
        return False
    j = load(errs, p)
    if not j:
        return False
    lessons = j.get('lessons') or []
    if [x.get('d') for x in lessons] != list(range(s, e + 1)):
        errs.add(p.name, f'{topic}: lessons must be days {s}..{e}')
        return False
    before = len(errs)
    for x in lessons:
        w = f'{topic} d{x["d"]}'
        if x.get('lv') != level_for(topic, x['d']):
            errs.add(w, 'wrong level')
        for lang in LANGS:
            v = (x.get('i18n') or {}).get(lang) or {}
            text(errs, f'{w} {lang} t', v.get('t'), 60)
            text(errs, f'{w} {lang} g', v.get('g'), 140)
            pts = v.get('p')
            if not isinstance(pts, list) or len(pts) != 3:
                errs.add(f'{w} {lang} p', 'needs 3 points')
            else:
                for i, pt in enumerate(pts):
                    text(errs, f'{w} {lang} p{i}', pt, 140)
            text(errs, f'{w} {lang} q', v.get('q'), 140)
            text(errs, f'{w} {lang} c', v.get('c'), 140)
        if topic.startswith('practice_'):
            tg = x.get('target') or {}
            vocab = tg.get('vocab')
            if not isinstance(vocab, list) or len(vocab) != 6:
                errs.add(w, 'target.vocab needs 6 items')
            else:
                for i, it in enumerate(vocab):
                    text(errs, f'{w} vocab{i} w', (it or {}).get('w'), 40)
                    text(errs, f'{w} vocab{i} ex', (it or {}).get('ex'), 100)
            text(errs, f'{w} gram', tg.get('gram'), 140)
    return len(errs) == before


def check_questions(topic, errs):
    p = DATA / 'questions' / f'{topic}.json'
    if not p.exists():
        return False
    j = load(errs, p)
    if not j:
        return False
    qs = j.get('questions') or []
    if [q.get('id') for q in qs] != [f'{topic}-{i:03d}' for i in range(1, 101)]:
        errs.add(p.name, 'needs ids 001..100 in order')
        return False
    seen = set()
    before = len(errs)
    for q in qs:
        if q.get('lv') not in ('any', 'beginner', 'intermediate', 'advanced'):
            errs.add(q['id'], 'bad lv')
        for lang in LANGS:
            v = (q.get('i18n') or {}).get(lang)
            text(errs, f'{q["id"]} {lang}', v, 140)
        en = (q.get('i18n') or {}).get('en')
        if en in seen:
            errs.add(q['id'], 'duplicate question')
        seen.add(en)
    return len(errs) == before


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else None
    errs = Errors()
    done = {'syllabus': 0, 'intro': 0, 'questions': 0, 'blocks': 0}
    total_blocks = 0
    missing = []
    for t in TOPICS:
        tid = t['id']
        if only and tid != only:
            continue
        done['syllabus'] += check_syllabus(tid, errs)
        done['intro'] += check_intro(tid, errs)
        done['questions'] += check_questions(tid, errs)
        for s, e in BLOCKS:
            total_blocks += 1
            if check_block(tid, s, e, errs):
                done['blocks'] += 1
            else:
                missing.append(f'{tid}/{block_name(s, e)}')
    n = 1 if only else len(TOPICS)
    print(f"syllabus {done['syllabus']}/{n}  intro {done['intro']}/{n}  questions {done['questions']}/{n}  "
          f"lesson files {done['blocks']}/{total_blocks}  ({done['blocks'] * 10}/{total_blocks * 10} lesson-days approx)")
    shown = errs if only else errs[:40]
    for e in shown:
        print('  ERR', e)
    if len(errs) > len(shown):
        print(f'  ... {len(errs) - len(shown)} more errors')
    return 0 if not errs else 1


if __name__ == '__main__':
    sys.exit(main())
