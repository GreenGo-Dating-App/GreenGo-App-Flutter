#!/usr/bin/env bash
# TEST PROJECT ONLY: prints the pending admin-panel 2FA code for an admin.
#
# greengo-chat-test has no e-mail provider (no Resend key), so send2FACode
# stores the code in admin_2fa_codes/{uid} without mailing it. This reads it
# with YOUR gcloud login (project owner / Firestore access needed), so it is
# no bypass for anyone else. Refuses to run against any other project.
#
# Usage: bash tools/test_env/get_admin_2fa_code.sh <admin-email>
set -euo pipefail
PROJECT=greengo-chat-test
EMAIL=${1:?usage: get_admin_2fa_code.sh <admin-email>}
TOKEN=$(gcloud auth print-access-token)
H=(-H "Authorization: Bearer $TOKEN" -H "x-goog-user-project: $PROJECT" -H "Content-Type: application/json")
ADMIN_UID=$(curl -sk -X POST "https://identitytoolkit.googleapis.com/v1/projects/$PROJECT/accounts:lookup" "${H[@]}" \
  -d "{\"email\":[\"$EMAIL\"]}" | python -c "import json,sys;u=json.load(sys.stdin).get('users',[]);print(u[0]['localId'] if u else '')")
[ -n "$ADMIN_UID" ] || { echo "No user $EMAIL in $PROJECT"; exit 1; }
curl -sk "https://firestore.googleapis.com/v1/projects/$PROJECT/databases/(default)/documents/admin_2fa_codes/$ADMIN_UID" "${H[@]}" \
  | python -c "import json,sys;d=json.load(sys.stdin).get('fields');print('2FA code:', d['code']['stringValue'], ' (expires', d['expiresAt']['timestampValue']+')') if d else print('No pending code: click Sign in on the admin panel first.')"
