"""Job queue for the content waves. State of the WORK comes from the files on
disk (validate.py checks); wave_state.json only remembers which jobs are
currently handed to an agent, so nothing is skipped after an interruption.

    python jobs.py next 4        # hand out the next 4 jobs (marks them running)
    python jobs.py done <job>    # an agent finished (or died): free the job
    python jobs.py status        # running jobs + overall progress

Jobs:
    plan:<a>,<b>        syllabus + intro + questions for topics a and b
    lessons:<topic>:<s>-<e>    lesson files for days s..e (60-day chunks)
"""
import json
import pathlib
import sys

import validate as V

HERE = pathlib.Path(__file__).parent
STATE = HERE / 'wave_state.json'
CHUNKS = [(1, 60), (61, 120), (121, 180), (181, 240), (241, 300), (301, 365)]


def load_state():
    try:
        s = json.loads(STATE.read_text(encoding='utf-8'))
    except Exception:  # noqa: BLE001
        s = {}
    s.setdefault('running', [])
    return s


def save_state(s):
    STATE.write_text(json.dumps({'running': s['running']}, indent=1), encoding='utf-8')


def plan_done(tid):
    e = V.Errors()
    return V.check_syllabus(tid, e) and V.check_intro(tid, e) and V.check_questions(tid, e)


def chunk_done(tid, s, e):
    errs = V.Errors()
    return all(V.check_block(tid, a, b, errs) for a, b in V.BLOCKS if a >= s and b <= e)


def pending(state):
    running = set(state['running'])
    busy_topics = {j.split(':')[1] for j in running if j.startswith('lessons:')}
    plan_busy = {t for j in running if j.startswith('plan:') for t in j[5:].split(',')}
    lessons = []
    # Lessons for topics whose plan is ready (one chunk per topic at a time).
    for t in V.TOPICS:
        tid = t['id']
        if tid in plan_busy or tid in busy_topics:
            continue
        e = V.Errors()
        if not V.check_syllabus(tid, e):
            continue
        for s, en in CHUNKS:
            if not chunk_done(tid, s, en):
                lessons.append(f'lessons:{tid}:{s}-{en}')
                break
    # Plans, two topics per job.
    todo = [t['id'] for t in V.TOPICS if t['id'] not in plan_busy and not plan_done(t['id'])]
    plans = ['plan:' + ','.join(todo[i:i + 2]) for i in range(0, len(todo), 2)]
    # Alternate so every topic gets its intro + questions early while lessons progress.
    out = []
    for i in range(max(len(plans), len(lessons))):
        out += plans[i:i + 1] + lessons[i:i + 1]
    return out


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'status'
    s = load_state()
    if cmd == 'next':
        n = int(sys.argv[2]) if len(sys.argv) > 2 else 1
        jobs = pending(s)[:n]
        s['running'] += jobs
        save_state(s)
        print('\n'.join(jobs))
    elif cmd == 'balanced':
        # One job keeping ~half the agents on plans while plans remain.
        p = pending(s)
        plans_running = sum(j.startswith('plan:') for j in s['running'])
        want_plan = plans_running < 5
        pick = next((j for j in p if j.startswith('plan:') == want_plan), p[0] if p else None)
        if pick:
            s['running'].append(pick)
            save_state(s)
            print(pick)
    elif cmd == 'done':
        s['running'] = [j for j in s['running'] if j not in sys.argv[2:]]
        save_state(s)
        print('running:', len(s['running']))
    else:
        print('running:', *s['running'], sep='\n  ')
        p = pending(s)
        print('pending jobs (next 5):', p[:5], f'... {len(p)} total')
        V.main.__globals__['sys'].argv = ['validate.py']
        V.main()


if __name__ == '__main__':
    main()
