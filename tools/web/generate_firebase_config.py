"""Generate web/firebase-config.js (git-ignored) from lib/firebase_options.dart.

The Firebase web config must reach the browser (the push service worker needs
it), but we keep it out of git: firebase_options.dart is git-ignored too, so
both come from the developer machine / CI secret store at build time.

Usage: python tools/web/generate_firebase_config.py   (exit 1 if not possible)
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / 'lib' / 'firebase_options.dart'
OUT = ROOT / 'web' / 'firebase-config.js'
FIELDS = {'apiKey': 'apiKey', 'authDomain': 'authDomain', 'projectId': 'projectId',
          'messagingSenderId': 'messagingSenderId', 'appId': 'appId'}

if not SRC.exists():
    sys.exit(f'ERROR: {SRC} not found (restore it from the credentials store).')
block = re.search(r'FirebaseOptions\s+web\s*=\s*FirebaseOptions\((.*?)\);', SRC.read_text(encoding='utf-8'), re.S)
if not block:
    sys.exit('ERROR: no `web` FirebaseOptions block in firebase_options.dart.')
cfg = {}
for js_key, dart_key in FIELDS.items():
    m = re.search(dart_key + r"\s*:\s*'([^']*)'", block.group(1))
    if not m or not m.group(1):
        sys.exit(f'ERROR: `{dart_key}` missing in the web FirebaseOptions block.')
    cfg[js_key] = m.group(1)
OUT.write_text('// GENERATED at build time by tools/web/generate_firebase_config.py - do not commit.\n'
               'self.GREENGO_FIREBASE_CONFIG = ' + json.dumps(cfg, indent=2) + ';\n', encoding='utf-8', newline='\n')
print(f'wrote {OUT.relative_to(ROOT)}')
