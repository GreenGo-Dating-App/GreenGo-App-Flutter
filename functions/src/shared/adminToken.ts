/**
 * Shared-secret check for token-guarded admin HTTP endpoints (security
 * Phase 1, L-05).
 *
 * Secrets in the query string (`?token=`) end up in access logs, browser
 * history and proxy logs. Endpoints now ALSO accept the secret in a header:
 *
 *   X-Admin-Token: <secret>          (preferred)
 *   Authorization: Bearer <secret>
 *
 * The query parameter keeps working (existing Cloud Scheduler jobs / scripts)
 * but is DEPRECATED: using it logs a warning (never the value).
 *
 * Every candidate is compared against every accepted secret in constant time
 * (sha256 digests + timingSafeEqual, no early exit on the first match).
 */

import * as crypto from 'crypto';

type ReqLike = {
  query?: Record<string, unknown>;
  headers?: Record<string, unknown>;
  get?: (name: string) => string | undefined;
};

function header(req: ReqLike, name: string): string | undefined {
  const viaGet = typeof req.get === 'function' ? req.get(name) : undefined;
  if (typeof viaGet === 'string' && viaGet) return viaGet;
  const h = req.headers?.[name.toLowerCase()];
  if (typeof h === 'string' && h) return h;
  if (Array.isArray(h) && typeof h[0] === 'string') return h[0];
  return undefined;
}

/** Candidate secrets presented by the request, header ones first. */
export function presentedTokens(req: ReqLike): Array<{ value: string; via: 'header' | 'bearer' | 'query' }> {
  const out: Array<{ value: string; via: 'header' | 'bearer' | 'query' }> = [];
  const x = header(req, 'X-Admin-Token');
  if (x) out.push({ value: x.trim(), via: 'header' });
  const authz = header(req, 'Authorization');
  const m = authz ? /^Bearer\s+(.+)$/i.exec(authz.trim()) : null;
  if (m) out.push({ value: m[1].trim(), via: 'bearer' });
  const q = req.query?.token;
  if (typeof q === 'string' && q) out.push({ value: q, via: 'query' });
  return out.filter((t) => t.value.length > 0 && t.value.length <= 4096);
}

function digest(s: string): Buffer {
  return crypto.createHash('sha256').update(s, 'utf8').digest();
}

/** Constant-time equality of two strings (any lengths). */
export function safeEqual(a: string, b: string): boolean {
  return crypto.timingSafeEqual(digest(a), digest(b)) && a.length === b.length;
}

/**
 * True when the request carries one of `secrets` (empty / unset secrets are
 * ignored, so an unconfigured endpoint never accepts an empty token).
 */
export function adminTokenOk(
  req: ReqLike,
  secrets: Array<string | undefined | null>,
  endpoint: string,
): boolean {
  const accepted = secrets.filter((s): s is string => typeof s === 'string' && s.length > 0);
  if (accepted.length === 0) return false;
  let ok = false;
  let via: string | null = null;
  for (const t of presentedTokens(req)) {
    for (const s of accepted) {
      if (safeEqual(t.value, s) && !ok) {
        ok = true;
        via = t.via;
      }
    }
  }
  if (ok && via === 'query') {
    console.warn(`[${endpoint}] DEPRECATED: admin token passed in the query string; ` +
      'send it in the X-Admin-Token header instead.');
  }
  return ok;
}
