"""Upload the Buddy avatar images to Storage and register them in Firestore `buddy_avatars`.

Images: Google Noto Emoji animals / characters (Apache-2.0, illustrations, never photos of
real people), 512px PNG, copied into OUR bucket (`buddy_avatars/<id>.png`) with a Firebase
download token, so the app never depends on a third-party host.

Usage: python -I tools/test_env/seed_buddy_avatars.py greengo-chat-test
       (production needs --i-mean-production as a second argument)
Uses the caller's gcloud credentials (project owner). Idempotent: re-running updates docs.
"""
import json, ssl, subprocess, sys, tempfile, urllib.parse, urllib.request, uuid
from pathlib import Path

PROJECT = sys.argv[1] if len(sys.argv) > 1 else ''
if PROJECT not in ('greengo-chat-test', 'greengo-chat'):
    sys.exit('usage: seed_buddy_avatars.py <greengo-chat-test|greengo-chat>')
if PROJECT == 'greengo-chat' and '--i-mean-production' not in sys.argv:
    sys.exit('refusing to write production without --i-mean-production')
BUCKET = f'{PROJECT}.firebasestorage.app'
ctx = ssl.create_default_context(); ctx.check_hostname = False; ctx.verify_mode = ssl.CERT_NONE

AVATARS = [  # id, label, Noto codepoint
    ('fox', 'Fox', '1f98a'), ('panda', 'Panda', '1f43c'), ('cat', 'Cat', '1f431'), ('dog', 'Dog', '1f436'),
    ('owl', 'Owl', '1f989'), ('rabbit', 'Rabbit', '1f430'), ('bear', 'Bear', '1f43b'), ('koala', 'Koala', '1f428'),
    ('lion', 'Lion', '1f981'), ('tiger', 'Tiger', '1f42f'), ('penguin', 'Penguin', '1f427'), ('frog', 'Frog', '1f438'),
    ('monkey', 'Monkey', '1f435'), ('unicorn', 'Unicorn', '1f984'), ('dragon', 'Dragon', '1f432'), ('octopus', 'Octopus', '1f419'),
    ('turtle', 'Turtle', '1f422'), ('dolphin', 'Dolphin', '1f42c'), ('robot', 'Robot', '1f916'), ('alien', 'Alien', '1f47d'),
    ('hamster', 'Hamster', '1f439'), ('hedgehog', 'Hedgehog', '1f994'), ('parrot', 'Parrot', '1f99c'), ('otter', 'Otter', '1f9a6'),
]
SRC = 'https://cdn.jsdelivr.net/gh/googlefonts/noto-emoji@v2.047/png/512/emoji_u{cp}.png'


def gcloud(*args) -> str:
    return subprocess.run(['gcloud', *args], capture_output=True, text=True, check=True, shell=(sys.platform == 'win32')).stdout.strip()


token = gcloud('auth', 'print-access-token')
H = {'Authorization': f'Bearer {token}', 'x-goog-user-project': PROJECT, 'Content-Type': 'application/json'}


def upload(local: Path, name: str) -> str:
    """Upload via the GCS JSON API with a Firebase download token; returns the download URL."""
    dl_token = str(uuid.uuid4())
    meta = {'name': name, 'contentType': 'image/png', 'cacheControl': 'public, max-age=31536000',
            'metadata': {'firebaseStorageDownloadTokens': dl_token, 'source': 'noto-emoji (Apache-2.0)'}}
    boundary = 'ggboundary' + uuid.uuid4().hex
    body = (f'--{boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n{json.dumps(meta)}\r\n'
            f'--{boundary}\r\nContent-Type: image/png\r\n\r\n').encode() + local.read_bytes() + f'\r\n--{boundary}--'.encode()
    req = urllib.request.Request(
        f'https://storage.googleapis.com/upload/storage/v1/b/{BUCKET}/o?uploadType=multipart', body,
        {'Authorization': H['Authorization'], 'x-goog-user-project': PROJECT, 'Content-Type': f'multipart/related; boundary={boundary}'})
    urllib.request.urlopen(req, context=ctx, timeout=60).read()
    return f'https://firebasestorage.googleapis.com/v0/b/{BUCKET}/o/{urllib.parse.quote(name, safe="")}?alt=media&token={dl_token}'


def set_doc(doc_id: str, fields: dict):
    def val(v):
        if isinstance(v, bool): return {'booleanValue': v}
        if isinstance(v, int): return {'integerValue': str(v)}
        return {'stringValue': str(v)}
    body = json.dumps({'fields': {k: val(v) for k, v in fields.items()}}).encode()
    req = urllib.request.Request(
        f'https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents/buddy_avatars/{doc_id}',
        body, H, method='PATCH')
    urllib.request.urlopen(req, context=ctx, timeout=60).read()


with tempfile.TemporaryDirectory() as tmp:
    for order, (aid, label, cp) in enumerate(AVATARS):
        local = Path(tmp) / f'{aid}.png'
        local.write_bytes(urllib.request.urlopen(SRC.format(cp=cp), context=ctx, timeout=60).read())
        url = upload(local, f'buddy_avatars/{aid}.png')
        set_doc(aid, {'url': url, 'label': label, 'order': order, 'active': True, 'source': 'Noto Emoji (Apache-2.0)'})
        print(f'{order:2} {aid:10} ok')
print(f'{len(AVATARS)} avatars in {PROJECT}/buddy_avatars')
