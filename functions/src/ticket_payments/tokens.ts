/**
 * Ticket payments — crypto helpers (pure, no Firestore).
 *
 *  - QR ticket token: `greengo:tk:{ticketId}:{sig}`, sig = 22 chars base64url of
 *    HMAC-SHA256(TICKET_QR_SIGNING_KEY, "tk:v1:{ticketId}"). Opaque, cannot be
 *    forged without the key; NOT revocable by itself, so the door re-checks
 *    tickets/{id}.status on every scan (refunded / disputed = invalid).
 *  - OAuth state for Mercado Pago: `{uid}.{nonce}.{expMs}.{sig}`.
 *  - AES-256-GCM sealing of the organizer's MP tokens at rest.
 */
import * as crypto from 'crypto';

export const TICKET_QR_PREFIX = 'greengo:tk:';
const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

function hmac(key: string, msg: string): Buffer {
  return crypto.createHmac('sha256', key).update(msg).digest();
}

function safeEq(a: string, b: string): boolean {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && crypto.timingSafeEqual(x, y);
}

export function ticketSignature(key: string, ticketId: string): string {
  return hmac(key, `tk:v1:${ticketId}`).toString('base64url').slice(0, 22);
}

export function ticketQrPayload(key: string, ticketId: string): string {
  return `${TICKET_QR_PREFIX}${ticketId}:${ticketSignature(key, ticketId)}`;
}

/** Parses + verifies a scanned ticket; returns the ticketId or null. */
export function verifyTicketQr(key: string, raw: unknown): string | null {
  if (typeof raw !== 'string' || !key) return null;
  const s = raw.trim();
  if (!s.startsWith(TICKET_QR_PREFIX)) return null;
  const rest = s.slice(TICKET_QR_PREFIX.length);
  const i = rest.lastIndexOf(':');
  if (i <= 0) return null;
  const id = rest.slice(0, i);
  const sig = rest.slice(i + 1);
  if (!ID_RE.test(id)) return null;
  return safeEq(sig, ticketSignature(key, id)) ? id : null;
}

export function isTicketQr(raw: unknown): boolean {
  return typeof raw === 'string' && raw.trim().startsWith(TICKET_QR_PREFIX);
}

// ─────────────────────────────────────────────── OAuth state

export function signState(key: string, uid: string, nowMs: number, ttlMs = 30 * 60 * 1000): string {
  const nonce = crypto.randomBytes(9).toString('base64url');
  const exp = String(nowMs + ttlMs);
  const body = `${uid}.${nonce}.${exp}`;
  return `${body}.${hmac(key, `mpstate:${body}`).toString('base64url')}`;
}

export function verifyState(key: string, state: unknown, nowMs: number): string | null {
  if (typeof state !== 'string' || !key) return null;
  const parts = state.split('.');
  if (parts.length !== 4) return null;
  const [uid, nonce, exp, sig] = parts;
  if (!ID_RE.test(uid) || !nonce) return null;
  const body = `${uid}.${nonce}.${exp}`;
  if (!safeEq(sig, hmac(key, `mpstate:${body}`).toString('base64url'))) return null;
  const e = Number(exp);
  if (!Number.isFinite(e) || nowMs > e) return null;
  return uid;
}

// ─────────────────────────────────────────────── token sealing

function sealKey(primary: string, fallback: string): Buffer {
  const material = primary || fallback;
  if (!material) throw new Error('no encryption key');
  return Buffer.from(crypto.hkdfSync('sha256', material, 'greengo-ticket-payments', 'mp-token-seal-v1', 32));
}

/** AES-256-GCM: "v1.{iv}.{tag}.{ciphertext}" (base64url). */
export function seal(plain: string, primary: string, fallback: string): string {
  const iv = crypto.randomBytes(12);
  const c = crypto.createCipheriv('aes-256-gcm', sealKey(primary, fallback), iv);
  const ct = Buffer.concat([c.update(plain, 'utf8'), c.final()]);
  return ['v1', iv.toString('base64url'), c.getAuthTag().toString('base64url'), ct.toString('base64url')].join('.');
}

export function unseal(sealed: string, primary: string, fallback: string): string {
  const [v, iv, tag, ct] = String(sealed).split('.');
  if (v !== 'v1' || !iv || !tag || ct === undefined) throw new Error('bad sealed value');
  const d = crypto.createDecipheriv('aes-256-gcm', sealKey(primary, fallback), Buffer.from(iv, 'base64url'));
  d.setAuthTag(Buffer.from(tag, 'base64url'));
  return Buffer.concat([d.update(Buffer.from(ct, 'base64url')), d.final()]).toString('utf8');
}

// ─────────────────────────────────────────────── Mercado Pago webhook signature

/**
 * MP `x-signature: ts=...,v1=...`; manifest `id:{data.id};request-id:{x-request-id};ts:{ts};`
 * (data.id lower-cased when alphanumeric; parts with no value are omitted).
 */
export function verifyMpSignature(
  secret: string,
  xSignature: unknown,
  xRequestId: unknown,
  dataId: unknown,
): boolean {
  if (!secret || typeof xSignature !== 'string') return false;
  let ts = '';
  let v1 = '';
  for (const part of xSignature.split(',')) {
    const [k, v] = part.split('=').map((x) => (x || '').trim());
    if (k === 'ts') ts = v;
    if (k === 'v1') v1 = v;
  }
  if (!ts || !v1) return false;
  let manifest = '';
  if (dataId !== undefined && dataId !== null && String(dataId) !== '') {
    const id = String(dataId);
    manifest += `id:${/^[a-z0-9]+$/i.test(id) ? id.toLowerCase() : id};`;
  }
  if (typeof xRequestId === 'string' && xRequestId) manifest += `request-id:${xRequestId};`;
  manifest += `ts:${ts};`;
  const want = crypto.createHmac('sha256', secret).update(manifest).digest('hex');
  return safeEq(v1.toLowerCase(), want);
}
