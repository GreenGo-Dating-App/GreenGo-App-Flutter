# Chat offline datasets

Static content the chat uses offline (no AI call at runtime). Every text exists in
all 7 app locales: `en`, `it`, `es`, `pt` (European Portuguese), `pt_BR`
(Brazilian Portuguese), `fr`, `de`.

| file (built) | what | size |
|---|---|---|
| `quotes` | phrase of the day: 3,000 verified quotes by public-domain authors (died before 1956) or traditional proverbs | 3,000 |
| `icebreakers` | conversation openers by topic | 1,000 |
| `sentences` | useful sentences by situation, with a CEFR level | 2,000 |
| `cultural_tips` | etiquette / culture tips per country (the 85 published attraction countries) | 30 per country |
| `keywords` | attraction + city names (all 7 languages, from Wikidata) for chat highlighting | score > 70 |

`parts/` holds the raw outputs of the research jobs (one JSON per job, see
`jobs/*.md`); `build_chat_datasets.js` validates and merges them into versioned
files that are uploaded to Firebase Storage and downloaded once by the app
(`lib/core/services/chat_datasets/`).

## Part formats

quotes_<n>.json - JSON array:
```json
[{"id": "q-07-001", "author": "Seneca", "died": 65, "origLang": "la",
  "source": "https://en.wikiquote.org/wiki/Seneca_the_Younger",
  "text": {"en": "...", "it": "...", "es": "...", "pt": "...", "pt_BR": "...", "fr": "...", "de": "..."}}]
```
icebreakers_<n>.json / sentences_<n>.json - JSON array:
```json
[{"id": "ib-travel-001", "topic": "travel", "text": {"en": "...", "...": "..."}}]
[{"id": "ss-greetings-001", "topic": "greetings", "level": "A1", "text": {"en": "...", "...": "..."}}]
```
tips_<n>.json - JSON object keyed by ISO2:
```json
{"IT": [{"id": "ct-IT-01", "category": "dining", "text": {"en": "...", "...": "..."}}]}
```

## Status (2026-10-12)
Final build: quotes 3,265 (verbatim-verified against Wikiquote), icebreakers 997, sentences 2,011,
cultural tips 2,550 (85 countries x 30), keywords 63,494 aliases (7,689 attractions, 4,645 cities,
84 countries). Cultural tips are partly from model knowledge where Wikipedia's culture articles are
silent on etiquette (tipping, transport, emergency numbers): worth a native spot-check.

## Licences
- `freq/*_50k.txt`: FrequencyWords by Hermit Dave (github.com/hermitdave/FrequencyWords), content
  CC BY-SA 4.0 (derived from OpenSubtitles). The app's difficulty badge uses the derived `freq.json`,
  which is therefore CC BY-SA 4.0 - credit it in the app's open-source / data licences page.
- Quotes: public-domain authors (died before 1956) and traditional proverbs; source = Wikiquote page.
- Keyword names: Wikidata labels/aliases (CC0).

Rebuild: `node tools/chat_datasets/build_keywords.js --project greengo-chat` then
`node tools/chat_datasets/build_chat_datasets.js --verify-quotes [--upload --project greengo-chat]`.
