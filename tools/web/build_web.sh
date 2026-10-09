#!/usr/bin/env bash
# Build the GreenGo web app with the git-ignored Firebase web config.
# Usage: tools/web/build_web.sh [extra flutter build web args]
#
# Privacy (GDPR/LGPD): the built app must not make visitors' browsers fetch
# engine files from Google. --no-web-resources-cdn serves CanvasKit from this
# origin (build/web/canvaskit) instead of www.gstatic.com/flutter-canvaskit,
# and web/index.html points the engine's fallback fonts at /gfonts/s/ (the
# fontFallbackProxy function behind a Firebase Hosting rewrite) instead of
# fonts.gstatic.com. The checks below fail the build if either regresses.
set -euo pipefail
cd "$(dirname "$0")/../.."
python tools/web/generate_firebase_config.py
flutter build web --release --no-web-resources-cdn "$@"
test -s build/web/firebase-config.js || { echo "ERROR: build/web/firebase-config.js missing"; exit 1; }
grep -q '"apiKey"' build/web/firebase-config.js || { echo "ERROR: firebase-config.js has no apiKey"; exit 1; }

# -- self-hosted engine resources ------------------------------------------
fail() { echo "ERROR: $*"; exit 1; }
test -s build/web/canvaskit/canvaskit.wasm || fail "build/web/canvaskit/canvaskit.wasm missing (CanvasKit must be served locally)"
grep -q '"useLocalCanvasKit":true' build/web/flutter_bootstrap.js \
  || fail "flutter_bootstrap.js lacks useLocalCanvasKit:true -- build without --no-web-resources-cdn would load CanvasKit from www.gstatic.com"
grep -q "canvasKitBaseUrl: 'canvaskit/'" build/web/index.html \
  || fail "index.html engine config lost canvasKitBaseUrl: 'canvaskit/'"
grep -q "fontFallbackBaseUrl: '/gfonts/s/'" build/web/index.html \
  || fail "index.html engine config lost fontFallbackBaseUrl: '/gfonts/s/' (fallback fonts would come from fonts.gstatic.com)"
# No page, bootstrap or config file may point at the Google CDNs. The inlined
# flutter.js loader carries the CanvasKit CDN URL only as its built-in default
# (`...!b.useLocalCanvasKit?f("https://www.gstatic.com/flutter-canvaskit",...)`),
# which useLocalCanvasKit + canvasKitBaseUrl above override, so that one
# expression is blanked before searching. (main.dart.js likewise keeps
# fonts.gstatic.com only as the engine default that fontFallbackBaseUrl overrides.)
cdn_refs=$(find build/web -type f \( -name '*.html' -o -name '*.json' -o -name '*.css' \
    -o -name '*.webmanifest' -o -name 'flutter_bootstrap.js' -o -name 'flutter.js' \) -print0 \
  | xargs -0 perl -0ne 's/!\w+\.useLocalCanvasKit\?[\w\$]+\("https:\/\/www\.gstatic\.com\/flutter-canvaskit"//g;
      print "$ARGV\n" if m{www\.gstatic\.com/flutter-canvaskit|fonts\.gstatic\.com|fonts\.googleapis\.com}')
if [ -n "$cdn_refs" ]; then
  echo "$cdn_refs"
  fail "the files above reference Google font/CanvasKit CDNs"
fi
echo "OK: build/web ready ($(cat build/web/version.json))"
