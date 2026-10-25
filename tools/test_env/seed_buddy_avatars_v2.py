"""Replaces the Buddy avatars on the TEST project with the GreenGo portrait set
(owner 2026-10-25): every portrait gets a 512 px picture + a 192 px thumbnail
(WebP), uploaded to Storage `buddy_avatars/v2/`; `buddy_avatars/{id}` gets
{url, thumbUrl, label: '', order, active, source}. The old avatars are set
`active: false` (never deleted: existing Buddies keep showing them).

The manifest labels (ethnicity / age) are NOT published: the app shows a
label as the picture's accessibility text.

    python seed_buddy_avatars_v2.py <folder with manifest.json + PNGs> [--apply]
"""
import io
import json
import pathlib
import sys
import uuid

from PIL import Image

import fs_rest

SIZES = {'url': 512, 'thumbUrl': 192}


def webp(src: Image.Image, px: int) -> bytes:
    out = io.BytesIO()
    src.resize((px, px), Image.LANCZOS).save(out, 'WEBP', quality=82, method=6)
    return out.getvalue()


def main():
    fs_rest.guard_project()
    folder = pathlib.Path(sys.argv[1])
    apply = '--apply' in sys.argv
    manifest = json.loads((folder / 'manifest.json').read_text(encoding='utf-8'))
    new_ids = {m['id'] for m in manifest}
    writes, total = [], 0
    for m in manifest:
        img = Image.open(folder / m['file']).convert('RGB')
        doc = {'label': '', 'order': int(m['order']), 'active': bool(m.get('active', True)), 'source': 'GreenGo'}
        for field, px in SIZES.items():
            data = webp(img, px)
            total += len(data)
            path = f"buddy_avatars/v2/{m['id']}_{px}.webp"
            doc[field] = fs_rest.upload_object(path, data, 'image/webp', str(uuid.uuid4())) if apply else path
        writes.append(fs_rest.set_write(f"buddy_avatars/{m['id']}", doc))
        print(m['id'], 'ok')
    old = [d['name'].rsplit('/', 1)[1] for d in fs_rest.list_docs('buddy_avatars', mask=['active'])]
    for oid in old:
        if oid not in new_ids:
            writes.append(fs_rest.set_write(f'buddy_avatars/{oid}', {'active': False}, merge=True))
    print(f'{len(manifest)} portraits, {total / 1e6:.1f} MB of WebP, {len(old) - len(new_ids & set(old))} old avatars deactivated')
    if apply:
        fs_rest.batch_write(writes)
        print('APPLIED')
    else:
        print('DRY RUN (pass --apply)')


if __name__ == '__main__':
    main()
