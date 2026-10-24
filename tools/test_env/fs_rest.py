"""Minimal Firestore / Identity Toolkit REST helper for the TEST project only.

Uses the caller's gcloud login (`gcloud auth print-access-token`); an owner
token bypasses security rules. HARD GUARD: every URL is built from PROJECT,
which is fixed to greengo-chat-test, and any attempt to point it elsewhere
(env var, argument) aborts the process. Production (`greengo-chat`) is never
reachable from this module.
"""
from __future__ import annotations

import datetime as _dt
import json
import os
import ssl
import subprocess
import sys
import time
import urllib.error
import urllib.request

PROJECT = "greengo-chat-test"
_FORBIDDEN = {"greengo-chat"}


def guard_project(project: str = PROJECT) -> None:
    if project != "greengo-chat-test" or project in _FORBIDDEN:
        sys.exit(f"REFUSING: project '{project}' is not greengo-chat-test")
    for var in ("GCLOUD_PROJECT", "GOOGLE_CLOUD_PROJECT", "FIREBASE_PROJECT"):
        v = os.environ.get(var)
        if v and v != PROJECT:
            sys.exit(f"REFUSING: env {var}={v} differs from {PROJECT}")


guard_project()

BASE = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"
DOC_PREFIX = f"projects/{PROJECT}/databases/(default)/documents"
IDT = f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT}"

# This PC has a TLS-intercepting proxy.
_CTX = ssl.create_default_context()
_CTX.check_hostname = False
_CTX.verify_mode = ssl.CERT_NONE

_token: str | None = None
_token_at = 0.0


def token() -> str:
    global _token, _token_at
    if _token is None or time.time() - _token_at > 40 * 60:
        out = subprocess.run(
            "gcloud auth print-access-token", shell=True, capture_output=True, text=True
        )
        if out.returncode != 0:
            sys.exit("gcloud auth print-access-token failed: " + out.stderr[-400:])
        _token = out.stdout.strip().splitlines()[-1]
        _token_at = time.time()
    return _token


def request(method: str, url: str, body=None, retries: int = 4):
    assert f"/projects/{PROJECT}" in url and "/projects/greengo-chat/" not in url, url
    data = None if body is None else json.dumps(body).encode()
    for attempt in range(retries + 1):
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Authorization", f"Bearer {token()}")
        req.add_header("x-goog-user-project", PROJECT)
        req.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(req, context=_CTX, timeout=120) as r:
                raw = r.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            txt = e.read().decode(errors="replace")
            if e.code in (429, 500, 502, 503, 504) and attempt < retries:
                time.sleep(2 ** attempt)
                continue
            raise RuntimeError(f"HTTP {e.code} {method} {url}: {txt[:800]}") from None
        except urllib.error.URLError:
            if attempt < retries:
                time.sleep(2 ** attempt)
                continue
            raise


# ---------------------------------------------------------------- encoding
class Ts:
    """Timestamp wrapper."""

    def __init__(self, d: _dt.datetime):
        self.d = d if d.tzinfo else d.replace(tzinfo=_dt.timezone.utc)


class Delete:
    """Sentinel: not supported in plain update writes; used by callers."""


def enc(v):
    if v is None:
        return {"nullValue": None}
    if isinstance(v, bool):
        return {"booleanValue": v}
    if isinstance(v, int):
        return {"integerValue": str(v)}
    if isinstance(v, float):
        return {"doubleValue": v}
    if isinstance(v, str):
        return {"stringValue": v}
    if isinstance(v, Ts):
        return {"timestampValue": v.d.astimezone(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")}
    if isinstance(v, _dt.datetime):
        return enc(Ts(v))
    if isinstance(v, (list, tuple)):
        return {"arrayValue": {"values": [enc(x) for x in v]}}
    if isinstance(v, dict):
        return {"mapValue": {"fields": {k: enc(x) for k, x in v.items()}}}
    raise TypeError(f"cannot encode {type(v)}")


def dec(v):
    if "nullValue" in v:
        return None
    for k in ("booleanValue", "stringValue", "doubleValue"):
        if k in v:
            return v[k]
    if "integerValue" in v:
        return int(v["integerValue"])
    if "timestampValue" in v:
        return v["timestampValue"]
    if "arrayValue" in v:
        return [dec(x) for x in v["arrayValue"].get("values", [])]
    if "mapValue" in v:
        return {k: dec(x) for k, x in v["mapValue"].get("fields", {}).items()}
    if "geoPointValue" in v:
        return v["geoPointValue"]
    if "referenceValue" in v:
        return v["referenceValue"]
    return v


def dec_doc(doc: dict) -> dict:
    return {k: dec(x) for k, x in doc.get("fields", {}).items()}


# ---------------------------------------------------------------- docs
def get(path: str):
    try:
        return dec_doc(request("GET", f"{BASE}/{path}"))
    except RuntimeError as e:
        if "HTTP 404" in str(e):
            return None
        raise


def set_write(path: str, data: dict, merge: bool = False) -> dict:
    w = {"update": {"name": f"{DOC_PREFIX}/{path}", "fields": {k: enc(v) for k, v in data.items()}}}
    if merge:
        w["updateMask"] = {"fieldPaths": [_quote(k) for k in data.keys()]}
    return w


def delete_write(path: str) -> dict:
    return {"delete": f"{DOC_PREFIX}/{path}"}


def _quote(k: str) -> str:
    import re

    return k if re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*", k) else "`" + k.replace("`", "\\`") + "`"


def batch_write(writes: list[dict]) -> dict:
    """:batchWrite (non-atomic, max 500). Raises if any write failed."""
    assert len(writes) <= 500
    res = request("POST", f"{BASE}:batchWrite", {"writes": writes})
    bad = [s for s in res.get("status", []) if s.get("code", 0) != 0]
    if bad:
        raise RuntimeError(f"{len(bad)} writes failed, first: {bad[0]}")
    return res


def commit(writes: list[dict]) -> dict:
    assert len(writes) <= 500
    return request("POST", f"{BASE}:commit", {"writes": writes})


def run_query(structured: dict, parent: str = "") -> list[dict]:
    url = f"{BASE}{('/' + parent) if parent else ''}:runQuery"
    res = request("POST", url, {"structuredQuery": structured})
    return [r["document"] for r in res if "document" in r]


def count(collection: str, where: dict | None = None) -> int:
    q = {"from": [{"collectionId": collection}]}
    if where:
        q["where"] = where
    res = request(
        "POST",
        f"{BASE}:runAggregationQuery",
        {"structuredAggregationQuery": {"structuredQuery": q, "aggregations": [{"alias": "n", "count": {}}]}},
    )
    return int(res[0]["result"]["aggregateFields"]["n"]["integerValue"])


def eq(field: str, value) -> dict:
    return {"fieldFilter": {"field": {"fieldPath": field}, "op": "EQUAL", "value": enc(value)}}


# ---------------------------------------------------------------- storage
BUCKET = "greengo-chat-test.firebasestorage.app"
assert BUCKET.startswith(PROJECT + ".")


def _raw(method: str, url: str, data: bytes | None, ctype: str | None, retries: int = 4):
    assert BUCKET in url
    for attempt in range(retries + 1):
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Authorization", f"Bearer {token()}")
        req.add_header("x-goog-user-project", PROJECT)
        if ctype:
            req.add_header("Content-Type", ctype)
        try:
            with urllib.request.urlopen(req, context=_CTX, timeout=120) as r:
                raw = r.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            txt = e.read().decode(errors="replace")
            if e.code == 404 and method == "DELETE":
                return {}
            if e.code in (429, 500, 502, 503, 504) and attempt < retries:
                time.sleep(2 ** attempt)
                continue
            raise RuntimeError(f"HTTP {e.code} {method} {url}: {txt[:500]}") from None


def upload_object(path: str, content: bytes, content_type: str, dl_token: str, extra_meta: dict | None = None) -> str:
    """Uploads to the test bucket; returns the Firebase download URL."""
    import urllib.parse

    meta = {
        "name": path,
        "contentType": content_type,
        "cacheControl": "public, max-age=31536000",
        "metadata": {"firebaseStorageDownloadTokens": dl_token, **(extra_meta or {})},
    }
    boundary = "seedboundary7f3a9c"
    body = (
        f"--{boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n{json.dumps(meta)}\r\n"
        f"--{boundary}\r\nContent-Type: {content_type}\r\n\r\n"
    ).encode() + content + f"\r\n--{boundary}--\r\n".encode()
    url = f"https://storage.googleapis.com/upload/storage/v1/b/{BUCKET}/o?uploadType=multipart"
    _raw("POST", url, body, f"multipart/related; boundary={boundary}")
    return (
        f"https://firebasestorage.googleapis.com/v0/b/{BUCKET}/o/"
        f"{urllib.parse.quote(path, safe='')}?alt=media&token={dl_token}"
    )


def list_objects(prefix: str):
    import urllib.parse

    page = None
    while True:
        url = f"https://storage.googleapis.com/storage/v1/b/{BUCKET}/o?prefix={urllib.parse.quote(prefix)}&fields=items(name),nextPageToken"
        if page:
            url += f"&pageToken={page}"
        res = _raw("GET", url, None, None)
        for it in res.get("items", []):
            yield it["name"]
        page = res.get("nextPageToken")
        if not page:
            return


def delete_object(path: str) -> None:
    import urllib.parse

    _raw("DELETE", f"https://storage.googleapis.com/storage/v1/b/{BUCKET}/o/{urllib.parse.quote(path, safe='')}", None, None)


def list_docs(collection: str, page_size: int = 300, mask: list[str] | None = None):
    token_ = None
    while True:
        url = f"{BASE}/{collection}?pageSize={page_size}"
        if mask:
            url += "".join(f"&mask.fieldPaths={m}" for m in mask)
        if token_:
            url += f"&pageToken={token_}"
        res = request("GET", url)
        for d in res.get("documents", []):
            yield d
        token_ = res.get("nextPageToken")
        if not token_:
            return
