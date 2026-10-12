# Common rules for every dataset job (GreenGo chat)

GreenGo is a cross-cultural discovery and language-exchange app (NOT a dating app). Texts are shown
to people chatting across languages and cultures.

## Languages
Every item has `text` with EXACTLY these 7 keys: `en`, `it`, `es`, `pt`, `pt_BR`, `fr`, `de`.
- `pt` = European Portuguese (Portugal: "tu", "estás", "autocarro", "pequeno-almoço", "telemóvel").
- `pt_BR` = Brazilian Portuguese ("você", "ônibus", "café da manhã", "celular"). They must differ where usage differs.
- Natural, idiomatic, native-quality phrasing in each language (not word-for-word). Correct accents and
  special letters (é, à, ñ, ç, ã, õ, ü, ß, œ). Informal-friendly register ("tu"/"du"/"tú") unless the
  item is clearly formal.
- Keep proper names as they are commonly written in each language (Roma / Rome / Rom; Lisboa / Lisbon / Lissabon).

## Content rules
- Respectful, inclusive, safe for all adults; no politics, religion-bashing, stereotypes, sexual content,
  alcohol/drug encouragement, or romance/flirting (not a dating app).
- No invented facts. If unsure, choose another item.
- No duplicates or near-duplicates within your file.
- Plain text only: no emojis, no markdown, no numbering, no surrounding quotes.

## Tools
WebFetch may not be loaded yet: call ToolSearch with query "select:WebFetch" first. To read a wiki page's
exact text (not a summary) use Bash with curl, e.g.
`curl -sk "https://en.wikiquote.org/w/index.php?title=Seneca_the_Younger&action=raw"` (raw wikitext) or
`curl -sk "https://en.wikipedia.org/w/index.php?title=Culture_of_Italy&action=raw"`. Add
`-A "GreenGoDatasetBuilder/1.0"`; if you get HTTP 429, wait 10 s and retry.

Write helper scripts in your own temp folder, never inside the repo.

## Output
Write ONE JSON file with the Write tool at the path given in your job (valid JSON, UTF-8, escape inner
double quotes). Rewrite the whole file every ~25 items so nothing is lost. When done, re-read the file,
check the count and that every item has all 7 language keys, then reply with just: the count written and
anything you could not do.
