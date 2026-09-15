#!/usr/bin/env bash
#
# Builds and deploys the pre-production web app to
# https://test-greengo-app.web.app, backed by the greengo-chat-dev project.
#
# The point of pre-production here is that testers can exercise destructive
# flows - deleting an account, spending coins, receiving a granted entitlement -
# without touching real user data. That only holds if EVERY connection points at
# dev, so this script does two things the ordinary build does not:
#
#   1. Builds with --dart-define=FIREBASE_ENV=dev, which selects
#      DevFirebaseOptions (see lib/main.dart).
#   2. Rewrites the push service worker, which is a static file and cannot read
#      a dart-define. Left alone it registers against production, and tester
#      devices would receive production notifications.
#
# Usage:
#   bash tool/deploy_preprod.sh
#
set -euo pipefail

DEV_PROJECT="greengo-chat-dev"
SITE="test-greengo-app"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ ! -f lib/firebase_options_dev.dart ]; then
  echo "ERROR: lib/firebase_options_dev.dart is missing."
  echo "Regenerate it with:"
  echo "  npx firebase apps:sdkconfig WEB <devWebAppId> --project $DEV_PROJECT"
  exit 1
fi

echo "==> Building web bundle against $DEV_PROJECT"
flutter build web --release --dart-define=FIREBASE_ENV=dev

echo "==> Pointing the push service worker at $DEV_PROJECT"
# Pull the dev values straight out of the generated options file, so this can
# never drift from what the app itself was built with.
python3 - <<'PY'
import io, re

opts = io.open('lib/firebase_options_dev.dart', encoding='utf-8').read()
def field(name):
    m = re.search(name + r":\s*'([^']*)'", opts)
    if not m:
        raise SystemExit('could not read %s from firebase_options_dev.dart' % name)
    return m.group(1)

sw_path = 'build/web/firebase-messaging-sw.js'
sw = io.open(sw_path, encoding='utf-8').read()
for key in ('apiKey', 'authDomain', 'projectId', 'storageBucket',
            'messagingSenderId', 'appId'):
    try:
        value = field(key)
    except SystemExit:
        continue
    sw = re.sub(key + r":\s*'[^']*'", "%s: '%s'" % (key, value), sw)
io.open(sw_path, 'w', encoding='utf-8', newline='').write(sw)
print('    service worker now targets', field('projectId'))
PY

echo "==> Verifying the bundle does not talk to production"
if grep -q "greengo-chat\.firebaseapp\.com" build/web/main.dart.js; then
  echo "ERROR: bundle still references the production auth domain. Aborting."
  exit 1
fi
echo "    ok"

echo "==> Deploying to $SITE"
npx firebase deploy --only hosting --config firebase.preprod.json --project "$DEV_PROJECT"

echo ""
echo "Done: https://$SITE.web.app  (project $DEV_PROJECT)"
echo ""
echo "Known production references that remain, and why:"
echo "  - attractions imagery reads the production Storage bucket (read-only,"
echo "    hardcoded in attractions_datasource.dart)"
echo "  - share links use greengo-chat.web.app, which is correct: a test build"
echo "    should not mint links that outlive it"
echo "  - the map style JSON is a static asset served from production hosting"
