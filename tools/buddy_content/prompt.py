"""Prints the agent prompt for a job from jobs.py (plan:a,b or lessons:topic:s-e)."""
import pathlib
import sys

HERE = pathlib.Path(__file__).parent

PLAN = """You write educational content for GreenGo "Buddies" (AI chat friends in a cross-cultural app). You write all the text yourself (no AI APIs, no scripts that generate text) and save JSON files.

Read first: C:/dev/gg-buddies/tools/buddy_content/SPEC.md (exact formats + rules) and C:/dev/gg-buddies/tools/buddy_content/topics.json (topic briefs).

Topics: {TOPICS}.
For EACH topic create (paths under C:/dev/gg-buddies/tools/buddy_content/), skipping files that already validate:
1. data/syllabus/<topic>.json - spec section 1: a genuinely good, varied, progressive 365-day curriculum fitting the topic brief (practice_* = real CEFR A1-B2 course of that language).
2. data/intro/<topic>.json - spec section 2, all 7 languages, native quality.
3. data/questions/<topic>.json - spec section 4, 100 questions x 7 languages, native quality.
Large files: write them in parts (a tiny Python script may only assemble/convert text you wrote). You write every text.
Then run `python C:/dev/gg-buddies/tools/buddy_content/validate.py <topic>` for each topic and fix every ERR for syllabus/intro/questions (missing lesson files are expected - ignore). Lengths are hard limits. Keep temp files ONLY in your own private folder C:/dev/gg-logs/tmp/plan-{SLUG}/ (other agents work in parallel: never touch other folders) and delete it at the end.
Do not touch other files, do not commit. Report: files written + the validator summary line per topic."""

TARGET = ("This is a practice_* topic: every lesson also has `target` {{vocab: exactly 6 {LANG} words/phrases with {LANG} "
          "example sentences, gram: the day's {LANG} grammar/usage point written in {LANG}}}, level-appropriate; the i18n "
          "texts explain it to a learner who speaks that language.")
NO_TARGET = 'No `target` field (only practice_* topics have it). Concrete, correct, timeless facts; practical and fun.'
LANG = {'practice_english': 'English', 'practice_italian': 'Italian', 'practice_spanish': 'Spanish',
        'practice_french': 'French', 'practice_german': 'German', 'practice_portuguese': 'Portuguese'}


def main():
    job = sys.argv[1]
    if job.startswith('plan:'):
        print(PLAN.replace('{TOPICS}', ', '.join(f'`{t}`' for t in job[5:].split(','))).replace('{SLUG}', job[5:].replace(',', '-')))
        return
    _, topic, rng = job.split(':')
    s, e = rng.split('-')
    rule = TARGET.replace('{LANG}', LANG[topic]).replace('{{', '{').replace('}}', '}') if topic in LANG else NO_TARGET
    t = (HERE / 'LESSON_PROMPT.md').read_text(encoding='utf-8')
    print(t.replace('{TOPIC}', topic).replace('{S}', s).replace('{E}', e).replace('{TARGET_RULE}', rule))


if __name__ == '__main__':
    main()
