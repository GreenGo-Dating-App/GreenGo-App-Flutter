"""Imports validated Buddy content into Firestore (TEST project only, via fs_rest).

    python import_firestore.py                # every topic whose content is complete + valid
    python import_firestore.py city_guides    # one topic (may be partial: imports what is valid)

Layout (server-only collections, read by Cloud Functions):
  buddy_courses/<topic>    {topic, group, days: [{d, lv, t}] x365, intro: {lang: [b1, b2]}, lessonsReady}
  buddy_lessons/<topic>_<ddd>  {topic, d, lv, i18n, target?}
  buddy_questions/<topic>  {topic, questions: [{id, lv, i18n}] x100}

Idempotent: re-running overwrites the same document ids. Only files that pass
validate.py's checks are written.
"""
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).parent
sys.path.insert(0, str(HERE.parent / 'test_env'))
import fs_rest  # noqa: E402  (hard-guarded to greengo-chat-test)
import validate as V  # noqa: E402

fs_rest.guard_project()


def flush(writes):
    for i in range(0, len(writes), 400):
        fs_rest.batch_write(writes[i:i + 400])
    writes.clear()


def import_topic(t):
    tid = t['id']
    errs = V.Errors()
    writes = []
    n_lessons = 0
    ready = 0  # contiguous days from day 1: the Buddy's path length
    for s, e in V.BLOCKS:
        if not V.check_block(tid, s, e, errs):
            continue
        if ready == s - 1:
            ready = e
        j = json.loads((V.DATA / 'lessons' / tid / V.block_name(s, e)).read_text(encoding='utf-8'))
        for x in j['lessons']:
            doc = {'topic': tid, 'd': x['d'], 'lv': x['lv'], 'i18n': x['i18n']}
            if 'target' in x:
                doc['target'] = x['target']
            writes.append(fs_rest.set_write(f'buddy_lessons/{tid}_{x["d"]:03d}', doc))
            n_lessons += 1
    course = {'topic': tid, 'group': t['group'], 'lessonsReady': ready}
    if V.check_syllabus(tid, errs):
        syl = json.loads((V.DATA / 'syllabus' / f'{tid}.json').read_text(encoding='utf-8'))
        course['days'] = [{'d': x['d'], 'lv': x['lv'], 't': x['t']} for x in syl['days']]
    if V.check_intro(tid, errs):
        course['intro'] = json.loads((V.DATA / 'intro' / f'{tid}.json').read_text(encoding='utf-8'))['intro']
    if 'days' in course or 'intro' in course or n_lessons:
        writes.append(fs_rest.set_write(f'buddy_courses/{tid}', course))
    if V.check_questions(tid, errs):
        q = json.loads((V.DATA / 'questions' / f'{tid}.json').read_text(encoding='utf-8'))
        writes.append(fs_rest.set_write(f'buddy_questions/{tid}', {'topic': tid, 'questions': q['questions']}))
    n = len(writes)
    flush(writes)
    print(f'{tid}: {n} docs ({n_lessons} lessons){"  ERRORS: " + str(len(errs)) if errs else ""}')


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else None
    for t in V.TOPICS:
        if not only or t['id'] == only:
            import_topic(t)


if __name__ == '__main__':
    main()
