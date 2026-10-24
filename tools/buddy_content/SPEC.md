# GreenGo Buddies content - generation spec (written by Claude Code, no APIs)

Owner decisions (2026-10-24):
- Every topic (121 sub-categories, `topics.json`) gets a 365-day path.
- Every text exists in all 7 app languages: `en, de, es, fr, it, pt, pt_BR`
  (`pt` = European Portuguese, `pt_BR` = Brazilian Portuguese).
- Language-teacher topics (`practice_*`) also teach real vocabulary in the
  taught language.
- A question bank of 100 questions per topic, in all 7 languages.
- Content is written by Claude Code agents in chunks, saved as JSON files here,
  checked by `validate.py`, then imported by `import_firestore.py`.

All files are UTF-8 JSON. Keys are short on purpose (the database holds ~45k lessons).

## 1. Syllabus - `data/syllabus/<topic>.json`

```json
{"topic": "city_guides", "days": [{"d": 1, "lv": "beginner", "t": "Reading a city map", "f": "How neighbourhoods, landmarks and transport lines appear on a map"}]}
```
- Exactly 365 entries, `d` = 1..365, in order. English only (internal plan).
- `t` <= 60 chars, `f` <= 140 chars, every `t` unique within the topic.
- Levels: `practice_*` topics use CEFR `A1` (days 1-90), `A2` (91-180), `B1` (181-280), `B2` (281-365).
  All other topics: `beginner` (1-120), `intermediate` (121-250), `advanced` (251-365).
- A real progression: basics first, then building on earlier days; every ~30 days a light
  review day. Varied, concrete, practical, fun.

## 2. Intro (the Buddy's first message) - `data/intro/<topic>.json`

```json
{"topic": "city_guides", "intro": {"en": ["...", "..."], "de": ["...", "..."]}}
```
- 2 bubbles per language, each <= 200 chars, complete sentences.
- Spoken by the Buddy: says it will guide the user on a 365-day path for this topic,
  roughly what the path covers (beginner -> advanced), one small lesson a day, and ends with
  ONE friendly question to get to know the user. May use the placeholder `{name}` for the
  Buddy's own name (at most once). Warm, positive, no emojis spam (0-1 emoji).

## 3. Lessons - `data/lessons/<topic>/dNNN-NNN.json` (10 days per file)

Files: `d001-010`, `d011-020`, ..., `d351-360`, `d361-365` (37 files per topic).

```json
{"topic": "city_guides", "lessons": [
  {"d": 1, "lv": "beginner", "i18n": {
    "en": {"t": "Reading a city map", "g": "...", "p": ["...", "...", "..."], "q": "...", "c": "..."},
    "de": {...}, "es": {...}, "fr": {...}, "it": {...}, "pt": {...}, "pt_BR": {...}}}
]}
```
Per language:
- `t` title <= 60 chars; `g` goal (1 sentence) <= 140; `p` exactly 3 key points, each <= 140;
  `q` one practice/conversation question the Buddy asks <= 140; `c` a tiny challenge for
  today <= 140.
- Each language written natively (not word-for-word), same meaning across languages.

`practice_*` topics add, per lesson, the taught-language material (same for every UI language):
```json
"target": {"vocab": [{"w": "la stazione", "ex": "Dov'è la stazione?"}], "gram": "..."}
```
- `vocab`: exactly 6 items; `w` <= 40 chars, `ex` an example sentence <= 100 chars, both IN THE
  TAUGHT LANGUAGE (practice_english -> English, practice_portuguese -> Brazilian Portuguese is
  NOT required: use European/neutral Portuguese), level-appropriate.
- `gram`: the grammar/usage point of the day, <= 140 chars, in the taught language.
- The `i18n` texts explain the lesson in the LEARNER's language (each of the 7).

## 4. Questions - `data/questions/<topic>.json`

```json
{"topic": "city_guides", "questions": [{"id": "city_guides-001", "lv": "any", "i18n": {"en": "...", "de": "...", "es": "...", "fr": "...", "it": "...", "pt": "...", "pt_BR": "..."}}]}
```
- Exactly 100 questions, ids `<topic>-001` .. `<topic>-100`.
- `lv`: `any`, `beginner`, `intermediate` or `advanced` (roughly 40 / 25 / 20 / 15).
- Each <= 140 chars, open questions that make the user talk about themselves and the topic
  (experiences, opinions, plans, preferences), all different.

## Rules for every text
- Positive, warm, encouraging. Never: sex, romance/dating, death, suicide, self-harm,
  violence, horror, drugs, hate, politics, religion debates.
- Health / legal / money topics (`disclaimer` in topics.json): general information only,
  no diagnosis, treatment, legal or investment advice.
- Facts must be correct and timeless (no prices, no "this year", no live events).
  Historical and well-known public figures may be mentioned factually and respectfully.
- No URLs, no markdown, no line breaks inside strings, no `"` inside strings (use quotes
  of the language, e.g. « » „ “ or ' ).
