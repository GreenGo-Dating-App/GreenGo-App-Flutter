"""Hotfix test: `users/{uid}/{userSub=**}` also matched users/{uid} itself (a rules
v2 recursive wildcard matches zero segments), so the owner could set role:'admin'
and pass isAdmin(). Dependency-free (Firestore emulator REST + unsigned tokens).
Run against BOTH rules files:
  firebase emulators:exec --config <cfg whose firestore.rules = file> --only firestore \
    --project demo-gg "python __tests__/security/users_escalation_rules_emulator.py"
"""
import base64, json, os, time, urllib.request, urllib.error

HOST = os.environ.get('FIRESTORE_EMULATOR_HOST', '127.0.0.1:8080').replace('0.0.0.0', '127.0.0.1')
PROJECT = os.environ.get('GCLOUD_PROJECT', 'demo-gg')
BASE = f'http://{HOST}/v1/projects/{PROJECT}/databases/(default)/documents'


def token(uid):
    b = lambda o: base64.urlsafe_b64encode(json.dumps(o).encode()).rstrip(b'=').decode()
    now = int(time.time())
    return b({'alg': 'none', 'typ': 'JWT'}) + '.' + b({
        'sub': uid, 'user_id': uid, 'iat': now, 'exp': now + 3600, 'auth_time': now,
        'aud': PROJECT, 'iss': f'https://securetoken.google.com/{PROJECT}',
        'email': f'{uid}@example.com', 'email_verified': True,
        'firebase': {'sign_in_provider': 'password', 'identities': {}}}) + '.'


def req(method, path, uid=None, body=None, query=''):
    r = urllib.request.Request(f'{BASE}/{path}{query}', method=method,
                               data=json.dumps(body).encode() if body is not None else None,
                               headers={'Content-Type': 'application/json',
                                        'Authorization': 'Bearer ' + (token(uid) if uid else 'owner')})
    try:
        with urllib.request.urlopen(r) as resp:
            return resp.status, json.load(resp)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:120]


def fields(**kv):
    return {'fields': {k: ({'stringValue': v} if isinstance(v, str) else {'integerValue': str(v)}) for k, v in kv.items()}}


results = []
def expect(kind, name, status):
    ok = (status == 200) if kind == 'LEGIT' else (status == 403)
    results.append(('PASS' if ok else 'FAIL', kind, f'{name} (HTTP {status})'))


req('PATCH', 'users/alice', body=fields(displayName='Alice', role='user'))  # seed as admin
expect('ATTACK', 'owner sets role admin (update)',
       req('PATCH', 'users/alice', 'alice', fields(role='admin'), '?updateMask.fieldPaths=role&currentDocument.exists=true')[0])
expect('ATTACK', 'owner sets isAdmin',
       req('PATCH', 'users/alice', 'alice', {'fields': {'isAdmin': {'booleanValue': True}}}, '?updateMask.fieldPaths=isAdmin')[0])
expect('ATTACK', 'another user writes alice subcollection',
       req('PATCH', 'users/alice/starred_messages/m2', 'bob', fields(x=1))[0])
expect('LEGIT', 'owner reads own user doc', req('GET', 'users/alice', 'alice')[0])
expect('LEGIT', 'owner writes own subcollection', req('PATCH', 'users/alice/starred_messages/m1', 'alice', fields(x=1))[0])
expect('LEGIT', 'owner writes nested subcollection', req('PATCH', 'users/alice/flashcard_decks/d1/cards/c1', 'alice', fields(x=1))[0])
expect('LEGIT', 'owner reads own subcollection', req('GET', 'users/alice/starred_messages/m1', 'alice')[0])
role = req('GET', 'users/alice')[1]['fields']['role']['stringValue']
results.append(('PASS' if role == 'user' else 'FAIL', 'CHECK', f'stored role still "user" (got {role})'))

for r in results:
    print(*r)
fail = sum(r[0] == 'FAIL' for r in results)
print(f'{fail} FAILED' if fail else f'ALL {len(results)} PASSED')
raise SystemExit(1 if fail else 0)
