"""Exports functions/src/buddies/topics.ts -> topics.json (id, group, brief, disclaimer)."""
import json
import pathlib
import re

HERE = pathlib.Path(__file__).parent
src = (HERE / '../../functions/src/buddies/topics.ts').read_text(encoding='utf-8')
BS = chr(92)  # backslash
rx = re.compile(r"t\('(\w+)',\s*'(\w+)',\s*'((?:[^'" + BS * 2 + r"]|" + BS * 2 + r".)*)'(?:,\s*'(\w+)')?\)")
topics = [{'id': m[1], 'group': m[0], 'brief': m[2].replace(BS + "'", "'"), 'disclaimer': m[3] or None}
          for m in rx.findall(src)]
(HERE / 'topics.json').write_text(json.dumps(topics, ensure_ascii=False, indent=1), encoding='utf-8')
print(len(topics), 'topics', sorted({t['group'] for t in topics}))
