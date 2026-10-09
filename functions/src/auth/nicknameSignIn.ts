/**
 * Nickname sign-in (INC-2026-001 residual: nickname -> email exposure).
 *
 * Before: `nicknames/{nick}` stored `{email, uid}` and was readable by anyone
 * (`allow get: if true`), because the app resolved nickname -> email on the
 * client and then called signInWithEmailAndPassword. Anyone who knew a
 * nickname could read the account email.
 *
 * Now the client sends `{nickname, password}` to this callable. The server:
 *   1. rate-limits per IP hash and per nickname (hashed keys, counted BEFORE
 *      any lookup, so the limit answers the same for existing and unknown
 *      nicknames);
 *   2. resolves nickname -> uid (nicknames/{nick}, else profiles.nickname)
 *      and takes the email from the Auth user record (never from Firestore);
 *   3. verifies the password with the Identity Toolkit REST API
 *      (accounts:signInWithPassword), which also enforces Firebase's own
 *      disabled-user and brute-force protections;
 *   4. returns a Firebase CUSTOM TOKEN for that uid; the client calls
 *      signInWithCustomToken.
 *
 * Unknown nickname and wrong password give the SAME error ("Invalid
 * credentials") after the same minimum delay: no account enumeration.
 * Accounts with a second factor (TOTP / phone MFA) are never signed in here:
 * the answer is MFA_REQUIRED (only after the password was verified) and the
 * app asks the user to sign in with their email, where the MFA flow runs.
 * Disabled Auth users get USER_DISABLED (same as email sign-in). Banned /
 * age_blocked accounts sign in exactly as they do with email: the app's
 * post-sign-in gating (accountStatus) is unchanged.
 *
 * The password is never logged, stored, or echoed in an error.
 *
 * Config: the Identity Toolkit key comes from env `FIREBASE_WEB_API_KEY`
 * (functions/.env, gitignored), else `app_config/api_keys.firebase_web_api_key`.
 * If the key is HTTP-referrer restricted, `NICKNAME_SIGNIN_REFERER` (default
 * https://greengo-chat.web.app/) is sent as the Referer.
 *
 * Deploy: signInWithNickname
 */

import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import '../shared/firebaseAdmin';
import { getServerKey } from '../ai/aiGateway';

const db = () => admin.firestore();

export const NICKNAME_SIGNIN_LIMITS = 'nickname_signin_limits';
export const WINDOW_MS = 15 * 60 * 1000;
/** Failed attempts per nickname per window before it is locked. */
export const NICKNAME_FAIL_LIMIT = 5;
/** Attempts (any outcome) per IP per window. */
export const IP_ATTEMPT_LIMIT = 20;

/** Every failed answer takes at least this long (blunts timing enumeration). */
const minFailMs = () => Number(process.env.NICKNAME_SIGNIN_MIN_RESPONSE_MS ?? 700);

export const INVALID_CREDENTIALS = 'Invalid credentials';
export const TOO_MANY = 'Too many requests. Please try again later';

const sha256 = (s: string) => crypto.createHash('sha256').update(s, 'utf8').digest('hex');
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

/** '@Foo_Bar ' -> 'foo_bar'. Null for anything that cannot be a nickname. */
export function normaliseNickname(v: unknown): string | null {
  if (typeof v !== 'string') return null;
  let s = v.trim();
  if (s.startsWith('@')) s = s.slice(1);
  s = s.toLowerCase();
  if (s.length < 1 || s.length > 40 || s.includes('@') || s.includes('/')) return null;
  if (!/^[a-z0-9_.]+$/.test(s)) return null;
  return s;
}

function clientIp(request: CallableRequest<any>): string {
  const req: any = request.rawRequest;
  const xff = String(req?.headers?.['x-forwarded-for'] || '').split(',')[0].trim();
  return req?.ip || xff || 'unknown';
}

const limitRef = (kind: 'ip' | 'nick', value: string) =>
  db().collection(NICKNAME_SIGNIN_LIMITS).doc(sha256(`${kind}:${value}`));

/** Counts one attempt for the IP. False when over the limit. */
async function hitIpLimit(ip: string, now = Date.now()): Promise<boolean> {
  const ref = limitRef('ip', ip);
  return db().runTransaction(async (tx) => {
    const d = (await tx.get(ref)).data();
    const fresh = !d || now - (d.windowStartMs ?? 0) >= WINDOW_MS;
    const count = fresh ? 1 : (d!.count ?? 0) + 1;
    tx.set(ref, {
      kind: 'ip',
      windowStartMs: fresh ? now : d!.windowStartMs,
      count,
      expireAt: admin.firestore.Timestamp.fromMillis(now + 2 * WINDOW_MS),
    });
    return count <= IP_ATTEMPT_LIMIT;
  });
}

/** True when the nickname is locked (too many failures in this window). */
async function nicknameLocked(nick: string, now = Date.now()): Promise<boolean> {
  const d = (await limitRef('nick', nick).get()).data();
  if (!d || now - (d.windowStartMs ?? 0) >= WINDOW_MS) return false;
  return (d.failures ?? 0) >= NICKNAME_FAIL_LIMIT;
}

async function recordNicknameFailure(nick: string, now = Date.now()): Promise<void> {
  const ref = limitRef('nick', nick);
  await db().runTransaction(async (tx) => {
    const d = (await tx.get(ref)).data();
    const fresh = !d || now - (d.windowStartMs ?? 0) >= WINDOW_MS;
    tx.set(ref, {
      kind: 'nick',
      windowStartMs: fresh ? now : d!.windowStartMs,
      failures: fresh ? 1 : (d!.failures ?? 0) + 1,
      expireAt: admin.firestore.Timestamp.fromMillis(now + 2 * WINDOW_MS),
    });
  });
}

/** nickname -> uid: the nicknames mapping first, then profiles.nickname. */
export async function resolveNicknameUid(nick: string): Promise<string | null> {
  const m = await db().collection('nicknames').doc(nick).get();
  const mapped = m.data()?.uid;
  if (typeof mapped === 'string' && mapped) return mapped;
  const q = await db().collection('profiles').where('nickname', '==', nick).limit(2).get();
  // Ambiguous (legacy duplicates): refuse rather than guess.
  return q.size === 1 ? q.docs[0].id : null;
}

export type PasswordCheck =
  | { ok: true; localId: string; mfa: boolean }
  | { ok: false; reason: 'INVALID' | 'DISABLED' | 'THROTTLED' | 'UNAVAILABLE' };

function identityToolkitUrl(apiKey: string): string {
  const emu = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const base = emu
    ? `http://${emu}/identitytoolkit.googleapis.com`
    : 'https://identitytoolkit.googleapis.com';
  return `${base}/v1/accounts:signInWithPassword?key=${encodeURIComponent(apiKey)}`;
}

/** Verifies email+password with Identity Toolkit. Never logs the password. */
export async function verifyPassword(email: string, password: string): Promise<PasswordCheck> {
  const apiKey = process.env.FIREBASE_AUTH_EMULATOR_HOST
    ? 'emulator-key'
    : await getServerKey('FIREBASE_WEB_API_KEY', 'firebase_web_api_key');
  if (!apiKey) {
    console.error('signInWithNickname: FIREBASE_WEB_API_KEY is not configured');
    return { ok: false, reason: 'UNAVAILABLE' };
  }
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), 10_000);
  let status = 0;
  let body: any = null;
  try {
    const res: any = await fetch(identityToolkitUrl(apiKey), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Referer: process.env.NICKNAME_SIGNIN_REFERER || 'https://greengo-chat.web.app/',
      },
      // returnSecureToken false: we only need the verdict, not a session.
      body: JSON.stringify({ email, password, returnSecureToken: false }),
      signal: ctrl.signal,
    });
    status = Number(res.status) || 0;
    try { body = await res.json(); } catch { body = null; }
  } catch (e: any) {
    console.error('signInWithNickname: identity toolkit unreachable:', e?.name || 'error');
    return { ok: false, reason: 'UNAVAILABLE' };
  } finally {
    clearTimeout(t);
  }

  if (status >= 200 && status < 300 && body && typeof body.localId === 'string') {
    return { ok: true, localId: body.localId, mfa: !!body.mfaPendingCredential };
  }
  const msg = String(body?.error?.message ?? '');
  if (msg.startsWith('USER_DISABLED')) return { ok: false, reason: 'DISABLED' };
  if (msg.startsWith('TOO_MANY_ATTEMPTS')) return { ok: false, reason: 'THROTTLED' };
  if (/^(INVALID_PASSWORD|EMAIL_NOT_FOUND|INVALID_LOGIN_CREDENTIALS|INVALID_EMAIL|MISSING_PASSWORD)/.test(msg)) {
    return { ok: false, reason: 'INVALID' };
  }
  // Key / config problems (API_KEY_INVALID, referrer blocked, ...): log the
  // code only, so ops can fix it; the user sees "unavailable".
  console.error(`signInWithNickname: identity toolkit error ${status} ${msg.split(' ')[0] || '(none)'}`);
  return { ok: false, reason: 'UNAVAILABLE' };
}

export async function handleSignInWithNickname(request: CallableRequest<any>): Promise<{ token: string }> {
  const started = Date.now();
  const fail = async (code: 'unauthenticated' | 'resource-exhausted' | 'permission-denied' | 'failed-precondition' | 'unavailable',
    message: string, reason: string): Promise<never> => {
    const wait = minFailMs() - (Date.now() - started);
    if (wait > 0) await sleep(wait);
    throw new HttpsError(code, message, { code: reason });
  };

  const data = request.data ?? {};
  const nick = normaliseNickname(data.nickname);
  const password = data.password;
  if (typeof password !== 'string' || password.length === 0 || password.length > 4096) {
    return fail('unauthenticated', INVALID_CREDENTIALS, 'INVALID_CREDENTIALS');
  }

  if (!(await hitIpLimit(sha256(clientIp(request))))) {
    return fail('resource-exhausted', TOO_MANY, 'RATE_LIMITED');
  }
  if (!nick) return fail('unauthenticated', INVALID_CREDENTIALS, 'INVALID_CREDENTIALS');
  if (await nicknameLocked(nick)) return fail('resource-exhausted', TOO_MANY, 'RATE_LIMITED');

  const failInvalid = async (): Promise<never> => {
    await recordNicknameFailure(nick);
    return fail('unauthenticated', INVALID_CREDENTIALS, 'INVALID_CREDENTIALS');
  };

  const uid = await resolveNicknameUid(nick);
  if (!uid) return failInvalid();
  let user: admin.auth.UserRecord;
  try {
    user = await admin.auth().getUser(uid);
  } catch {
    return failInvalid();
  }
  const hasPasswordProvider = user.providerData.some((p) => p.providerId === 'password');
  if (!user.email || !hasPasswordProvider) return failInvalid();

  const check = await verifyPassword(user.email, password);
  if ('reason' in check) {
    if (check.reason === 'INVALID') return failInvalid();
    if (check.reason === 'DISABLED') return fail('permission-denied', 'This account has been disabled', 'USER_DISABLED');
    if (check.reason === 'THROTTLED') return fail('resource-exhausted', TOO_MANY, 'RATE_LIMITED');
    return fail('unavailable', 'Sign-in is temporarily unavailable. Please use your email.', 'UNAVAILABLE');
  }
  if (check.localId !== uid) return failInvalid();

  // Password verified from here on.
  await limitRef('nick', nick).delete().catch(() => undefined);
  if (user.disabled) return fail('permission-denied', 'This account has been disabled', 'USER_DISABLED');
  const enrolled = user.multiFactor?.enrolledFactors?.length ?? 0;
  if (check.mfa || enrolled > 0) {
    return fail('failed-precondition', 'MFA_REQUIRED: sign in with your email address', 'MFA_REQUIRED');
  }

  const token = await admin.auth().createCustomToken(uid);
  return { token };
}

export const signInWithNickname = onCall(
  { memory: '512MiB', timeoutSeconds: 30 },
  async (request: CallableRequest<any>) => {
    try {
      return await handleSignInWithNickname(request);
    } catch (e: any) {
      if (e instanceof HttpsError) throw e;
      // Never forward the raw error (it could carry request data).
      console.error('signInWithNickname failed:', e?.code || e?.name || 'error');
      throw new HttpsError('internal', 'Sign-in failed. Please try again.');
    }
  },
);
