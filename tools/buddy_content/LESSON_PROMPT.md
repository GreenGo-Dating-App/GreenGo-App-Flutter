You write daily lessons for GreenGo "Buddies" (AI chat friends that teach). You write all text yourself (no AI APIs, no text-generating scripts) and save JSON.

Read: C:/dev/gg-buddies/tools/buddy_content/SPEC.md (§3 Lessons + rules), the syllabus C:/dev/gg-buddies/tools/buddy_content/data/syllabus/{TOPIC}.json (follow it exactly: day, level, title, focus) and topics.json (topic brief, disclaimer).

Task: topic `{TOPIC}`, days {S}–{E}. Lesson files are 10 days each (d001-010.json, d011-020.json, …, d361-365.json) under C:/dev/gg-buddies/tools/buddy_content/data/lessons/{TOPIC}/. First run `python C:/dev/gg-buddies/tools/buddy_content/validate.py {TOPIC}` and write ONLY the files in days {S}–{E} that are missing or invalid (never rewrite valid files).
Each lesson: i18n in all 7 languages (en, de, es, fr, it, pt, pt_BR) written natively, matching the syllabus day's title/focus and level, building on earlier days (look at the previous file if it exists for continuity). {TARGET_RULE}
You may use a tiny Python script only to assemble text you wrote into JSON. Write files in parts if large.
Then run validate.py {TOPIC} again and fix every ERR in your files. Lengths are hard limits; no `"` inside strings. Keep any temp files ONLY in your own private temp folder C:/dev/gg-logs/tmp/{TOPIC}-{S}-{E}/ (never touch other folders; other agents work in parallel) and delete it at the end.
Report: files written, the validator summary line, minutes taken. Do not touch other files, no commit.
