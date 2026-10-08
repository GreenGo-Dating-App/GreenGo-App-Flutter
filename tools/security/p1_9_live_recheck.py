"""P1-9 pre-deploy re-check (READ-ONLY against production).

Run immediately before deploying the P1-9 function list from this repo:

    python -I tools/security/p1_9_live_recheck.py [--names a,b,c]

For every function in p1_9_live_baseline.json it downloads the LIVE deployed
source zip (gcloud storage cat; nothing is written to GCP) and compares:

  * the function's module file  -> must equal `liveSha1`   (else ABORT)
  * the whole src/**/*.ts tree   -> should equal `srcTreeSha1` (else WARN:
    redeployed since the analysis, but this module is unchanged)

ABORT means someone deployed a different version of that module after the
2026-10-08 analysis (typically from the web repo or another branch). Do NOT
deploy that function: re-diff the new live module against this repo first.

Exit code: 0 = all OK/WARN, 1 = at least one ABORT, 2 = tool error.
"""
import argparse
import hashlib
import io
import json
import pathlib
import re
import subprocess
import sys
import zipfile

GC = r'C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd'
PROJECT = 'greengo-chat'
V2B = 'gs://gcf-v2-sources-666632803027-us-central1'
V1B = 'gs://gcf-sources-666632803027-us-central1'
BASE = pathlib.Path(__file__).with_name('p1_9_live_baseline.json')


def gs(*args):
    return subprocess.run([GC, 'storage', *args, '--project', PROJECT], capture_output=True)


def zip_url(name, platform):
    if platform == 'gcfv2':
        return f'{V2B}/{name}/function-source.zip'
    out = gs('ls', f'{V1B}/{name}-*/version-*/function-source.zip').stdout.decode().split()
    urls = [u for u in out if u.endswith('.zip')]
    if not urls:
        return None
    return max(urls, key=lambda u: int(re.search(r'version-(\d+)', u).group(1)))


def tree_sha(z):
    h = hashlib.sha1()
    for n in sorted(x for x in z.namelist() if x.startswith('src/') and x.endswith('.ts')):
        h.update(n.encode() + b'\0' + z.read(n).replace(b'\r', b'') + b'\0')
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--names', help='comma-separated subset')
    args = ap.parse_args()
    base = json.loads(BASE.read_text(encoding='utf-8'))
    names = args.names.split(',') if args.names else sorted(base)
    aborts = 0
    for n in names:
        b = base.get(n)
        if not b:
            print(f'ABORT {n}: not in baseline'); aborts += 1; continue
        url = zip_url(n, b['platform'])
        r = gs('cat', url) if url else None
        if not r or r.returncode != 0:
            print(f'ABORT {n}: could not download live source'); aborts += 1; continue
        z = zipfile.ZipFile(io.BytesIO(r.stdout))
        if b['module'] not in z.namelist():
            print(f'ABORT {n}: {b["module"]} missing from live zip'); aborts += 1; continue
        mod = hashlib.sha1(z.read(b['module']).replace(b'\r', b'')).hexdigest()
        if mod != b['liveSha1']:
            print(f'ABORT {n}: live {b["module"]} changed since analysis ({mod[:8]} != {b["liveSha1"][:8]})')
            aborts += 1
        elif tree_sha(z) != b['srcTreeSha1']:
            print(f'WARN  {n}: redeployed since analysis, module unchanged')
        else:
            print(f'OK    {n}')
    print(f'\n{len(names) - aborts} ok/warn, {aborts} ABORT')
    return 1 if aborts else 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Exception as e:  # noqa: BLE001
        print('tool error:', e); sys.exit(2)
