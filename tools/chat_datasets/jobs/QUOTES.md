# Job: phrase-of-the-day quotes (100 per job)

Read COMMON.md first (same folder).

Your job number N and your 10 authors (or proverb cultures) are listed in QUOTES_ASSIGN.md.
Write 100 quotes: about 10 per author (if an author has fewer reliable quotes, take more from the others
in your group).

Rules:
- VERBATIM: copy each quote exactly as printed on Wikiquote (read the raw wikitext with curl, see
  COMMON.md). Never paraphrase or shorten mid-sentence. The build script re-checks every quote against
  the page and drops any that do not match.
- For authors who wrote in Italian, Spanish, Portuguese, French or German, ALSO use the Wikiquote in
  that language (it./es./pt./fr./de.wikiquote.org): it has many more sourced quotes with the original
  wording. Put that page in `source` and use its original text for the matching language key.
- ONLY quotes that appear in the SOURCED section of the author's Wikiquote page (English, or the author's language)
  (https://en.wikiquote.org/wiki/<Author>). Never use sections "Disputed", "Misattributed", "Attributed",
  "Quotes about ...". WebFetch the Wikiquote page; if it fails try the author's full name / variant title.
- All authors here died before 1956 (public domain). Do not add other authors.
- Prefer short, wise, inspiring or witty lines (max ~220 characters in English), good as a "phrase of the
  day" for language learners. Skip lines that are offensive, outdated in a hurtful way, or need context.
- `origLang`: ISO 639-1 code of the language the author wrote it in (la, grc, it, fr, de, en, es, pt, ru,
  zh, ja, fa, ar, sa ...).
- Translations: if the original language is one of the 7 app languages, that language's text MUST be the
  original wording (as given on Wikiquote, which often prints the original next to the English). For the
  other languages translate faithfully and naturally; use a well-known standard translation if you know it
  confidently, otherwise your own.
- `died`: year of death (negative for BC, e.g. -399 for Socrates).
- Proverb groups (job 30): `author` = "Italian proverb" / "Japanese proverb" etc., `died` = null,
  `source` = the Wikiquote proverbs page you used (e.g. https://en.wikiquote.org/wiki/Italian_proverbs).

Output: tools/chat_datasets/parts/quotes_<N>.json (full path given in the job message).
id format: "q-<NN>-<nnn>" (NN = job number 2 digits, nnn = 001..100).
