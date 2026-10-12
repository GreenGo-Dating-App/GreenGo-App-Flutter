# Jobs: ice-breakers, suggested sentences, cultural tips

Read COMMON.md first (same folder). Your job message gives the kind, the topics/countries and the output path.

## Ice-breakers (job message: kind=icebreakers, 2 topics, 50 per topic = 100 items)
Friendly conversation openers someone can send to a new contact from another country/language. Open
questions that invite a story, curious and light: "What's a dish from your hometown everyone should try
once?" Mix lengths (most 6-18 words). Not personal-intrusive (no age, salary, relationship status, looks).
`id`: "ib-<topic>-<nnn>", `topic` = the topic key given.

## Suggested sentences (kind=sentences, 2 topics, 50 per topic = 100 items)
Ready-to-send useful sentences for a chat between language partners in that situation, from simple to more
advanced. `level` = CEFR of the English sentence: about 30% A1, 30% A2, 25% B1, 15% B2. Practical and
reusable ("Could you say that more slowly, please?", "Let's meet at the main square at 6.").
`id`: "ss-<topic>-<nnn>".

## Cultural tips (kind=tips, 3 countries, 30 per country)
Practical, accurate etiquette and culture tips a visitor or chat partner would value, specific to that
country (not generic travel advice). Cover these categories, 1-3 tips each, 30 total per country:
greetings, conversation, dining, tipping, gifts, dress, religion_sites, gestures, punctuality, public_behavior,
transport, language, festivals, family, money, photography, nightlife, nature, safety, local_pride.
Each tip one or two sentences, max ~220 characters in English, factual and respectful (no stereotypes;
phrase as "It is common to...", "Many people..."). Use the Wikipedia articles "Culture of <country>" and
"Etiquette in <region>" (WebFetch) to verify; don't invent laws or numbers.
All 7 languages must say the SAME thing (if you shorten the English, shorten every language).
Output is a JSON OBJECT keyed by ISO2: {"IT": [ ...30 items... ], "FR": [...], ...}.
`id`: "ct-<ISO2>-<nn>", `category` = one of the keys above.
