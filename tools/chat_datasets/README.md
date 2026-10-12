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
