#!/usr/bin/env bash
# Build the GreenGo web app with the git-ignored Firebase web config.
# Usage: tools/web/build_web.sh [extra flutter build web args]
set -euo pipefail
cd "$(dirname "$0")/../.."
python tools/web/generate_firebase_config.py
flutter build web --release "$@"
test -s build/web/firebase-config.js || { echo "ERROR: build/web/firebase-config.js missing"; exit 1; }
grep -q '"apiKey"' build/web/firebase-config.js || { echo "ERROR: firebase-config.js has no apiKey"; exit 1; }
echo "OK: build/web ready ($(cat build/web/version.json))"
