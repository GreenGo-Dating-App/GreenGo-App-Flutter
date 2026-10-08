/**
 * Account deletion entry points (audit H-15 / P1-10).
 *
 *  - requestAccountDeletion (HTTP POST, public): the greengochat.com
 *    "Delete account" page. Body `{ email, password }` (JSON). The password is
 *    IGNORED and never logged or stored: checking it here would turn this
 *    endpoint into an unauthenticated password oracle. Proof of ownership is a
 *    single-use link mailed to the address on the Auth account. The answer is
 *    identical whether or not the account exists (no enumeration).
 *    Signed-in mode: if the caller sends a Firebase ID token (`Authorization:
 *    Bearer <idToken>` or body `idToken`) with a recent sign-in (auth_time within
 *    10 min), that IS the proof, and the account is deleted immediately.
 *
 *  - confirmAccountDeletion (HTTP): the link in that email.
 *      GET  ?token=...  -> validates the token and shows a confirm button
 *                          (no side effect: mail scanners / link previewers GET
 *                          links automatically and must not delete accounts).
 *      POST token=...   -> validates, marks the token used, runs the deletion.
 *
 *  - deleteMyAccount (callable, for the app): authenticated + recent sign-in.
 *    Returns { success: true } only after everything is gone; Auth user last.
 *
 * All three run the single routine in accountDeletion.ts.
 */

import { onRequest, onCall, Request } from 'firebase-functions/v2/https';
import type { Response } from 'express';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import '../shared/firebaseAdmin';
import { AppError, handleError } from '../shared/utils';
import { monitored } from '../shared/monitoring';
import { maskEmail, sendResendEmail } from '../shared/resendEmail';
import { deleteAccountCompletely } from './accountDeletion';

const db = () => admin.firestore();

export const DELETION_REQUESTS = 'deletion_requests';
export const DELETION_RATE_LIMITS = 'deletion_rate_limits';

/** Link lifetime. */
export const TOKEN_TTL_MS = 24 * 60 * 60 * 1000;
/** "Recent login" window for deleteMyAccount and the signed-in web mode. */
export const RECENT_AUTH_SECONDS = 10 * 60;
/** Per-hour limits. Counted BEFORE the account lookup, so they leak nothing. */
export const RATE_LIMITS = { email: 3, ip: 5 };
const RATE_WINDOW_MS = 60 * 60 * 1000;
/** Every POST answer takes at least this long (blunts timing enumeration). */
const minResponseMs = () => Number(process.env.DELETION_MIN_RESPONSE_MS ?? 800);

export const ALLOWED_ORIGINS = new Set([
  'https://greengochat.com',
  'https://www.greengochat.com',
  'http://localhost:3000',
  'http://localhost:5173',
  'http://127.0.0.1:3000',
]);

/** Public base URL of the deployed functions (for the link in the email). */
function confirmUrl(token: string): string {
  const base =
    process.env.DELETION_CONFIRM_BASE_URL ||
    `https://us-central1-${process.env.GCLOUD_PROJECT || 'greengo-chat'}.cloudfunctions.net`;
  return `${base.replace(/\/+$/, '')}/confirmAccountDeletion?token=${encodeURIComponent(token)}`;
}

/** Body of every successful POST, account or no account. */
export const GENERIC_RESPONSE = {
  success: true,
  status: 'email_sent_if_account_exists',
  message:
    'If an account exists for this email, we have sent a link to confirm the deletion. ' +
    'The link expires in 24 hours.',
};

export const sha256 = (s: string) => crypto.createHash('sha256').update(s).digest('hex');
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
const normaliseEmail = (e: unknown) => String(e ?? '').trim().toLowerCase();
const EMAIL_RE = /^[^\s@]{1,64}@[^\s@]{1,255}\.[^\s@]{2,}$/;

function clientIp(req: Request): string {
  // req.ip is set by the Cloud Functions front end; XFF only as a fallback.
  const xff = String(req.headers['x-forwarded-for'] || '').split(',')[0].trim();
  return req.ip || xff || 'unknown';
}

/** Applies CORS; returns false (and has answered) when the request must stop. */
function cors(req: Request, res: Response): boolean {
  const origin = req.headers.origin as string | undefined;
  if (origin) {
    if (!ALLOWED_ORIGINS.has(origin)) {
      res.status(403).json({ success: false, error: 'Origin not allowed' });
      return false;
    }
    res.set('Access-Control-Allow-Origin', origin);
    res.set('Vary', 'Origin');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.set('Access-Control-Max-Age', '3600');
  }
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return false;
  }
  return true;
}

/**
 * Fixed-window counter in Firestore. Returns false when over the limit.
 * Keys are hashed, so the collection holds no raw emails or IPs; `expireAt`
 * is there for a Firestore TTL policy.
 */
export async function hitRateLimit(kind: 'email' | 'ip', value: string, limit: number): Promise<boolean> {
  const ref = db().collection(DELETION_RATE_LIMITS).doc(sha256(`${kind}:${value}`));
  const now = Date.now();
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const d = snap.data();
    const fresh = !d || now - (d.windowStartMs ?? 0) >= RATE_WINDOW_MS;
    const count = fresh ? 1 : (d!.count ?? 0) + 1;
    tx.set(ref, {
      kind,
      windowStartMs: fresh ? now : d!.windowStartMs,
      count,
      expireAt: admin.firestore.Timestamp.fromMillis(now + 2 * RATE_WINDOW_MS),
    });
    return count <= limit;
  });
}

function bearer(req: Request): string | undefined {
  const h = String(req.headers.authorization || '');
  if (h.startsWith('Bearer ')) return h.slice(7).trim();
  const b = (req.body && typeof req.body === 'object') ? req.body.idToken : undefined;
  return typeof b === 'string' && b ? b : undefined;
}

function isRecent(authTimeSeconds: unknown): boolean {
  const t = Number(authTimeSeconds);
  return Number.isFinite(t) && Date.now() / 1000 - t <= RECENT_AUTH_SECONDS;
}

function confirmationEmailHtml(link: string): string {
  return `<!DOCTYPE html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="font-family:Helvetica,Arial,sans-serif;background:#0A0A0A;color:#fff;padding:32px">
<div style="max-width:520px;margin:0 auto;background:#1A1A1A;border-radius:16px;padding:32px;border:1px solid #2A2A2A">
<h2 style="margin-top:0">Confirm your GreenGo account deletion</h2>
<p>We received a request to permanently delete the GreenGo account linked to this email address.</p>
<p>If this was you, open the link below and confirm. It expires in 24 hours and works once.</p>
<p style="text-align:center;margin:28px 0"><a href="${link}" style="background:#D4AF37;color:#0A0A0A;font-weight:bold;padding:14px 32px;border-radius:12px;text-decoration:none">Review and delete my account</a></p>
<p style="color:#999;font-size:12px;word-break:break-all">${link}</p>
<hr style="border:none;border-top:1px solid #2A2A2A">
<p style="color:#bbb;font-size:13px">Recebemos um pedido para excluir permanentemente a conta GreenGo associada a este email. Se foi voc&ecirc;, abra o link acima e confirme (v&aacute;lido por 24 horas, uso &uacute;nico).</p>
<p style="color:#999;font-size:13px">If you did not ask for this, ignore this email: nothing will happen to your account.</p>
</div></body></html>`;
}

// ---------------------------------------------------------------------------
// requestAccountDeletion
// ---------------------------------------------------------------------------

export async function handleRequestAccountDeletion(req: Request, res: Response): Promise<void> {
  if (!cors(req, res)) return;
  if (req.method !== 'POST') {
    res.status(405).json({ success: false, error: 'Method not allowed' });
    return;
  }
  const started = Date.now();
  const finish = async (status: number, body: Record<string, unknown>) => {
    const wait = minResponseMs() - (Date.now() - started);
    if (wait > 0) await sleep(wait);
    res.status(status).json(body);
  };

  try {
    const body = (req.body && typeof req.body === 'object') ? req.body : {};

    // --- Signed-in mode: a fresh ID token is proof enough. -----------------
    const idToken = bearer(req);
    if (idToken) {
      let decoded: admin.auth.DecodedIdToken;
      try {
        decoded = await admin.auth().verifyIdToken(idToken, true);
      } catch {
        await finish(401, { success: false, error: 'Your session has expired. Please sign in again.' });
        return;
      }
      if (!isRecent(decoded.auth_time)) {
        await finish(401, {
          success: false,
          code: 'REQUIRES_RECENT_LOGIN',
          error: 'Please sign in again (within the last 10 minutes) to delete your account.',
        });
        return;
      }
      if (!(await hitRateLimit('ip', clientIp(req), RATE_LIMITS.ip))) {
        await finish(429, { success: false, error: 'Too many requests. Please try again later.' });
        return;
      }
      await deleteAccountCompletely(decoded.uid, { source: 'web_id_token' });
      await finish(200, { success: true, status: 'deleted', message: 'Your account has been deleted.' });
      return;
    }

    // --- Email mode. ---------------------------------------------------------
    const email = normaliseEmail(body.email);
    if (!EMAIL_RE.test(email)) {
      await finish(400, { success: false, error: 'Please enter a valid email address.' });
      return;
    }
    // Both limits are counted before we know whether the account exists.
    const ipOk = await hitRateLimit('ip', clientIp(req), RATE_LIMITS.ip);
    const emailOk = await hitRateLimit('email', email, RATE_LIMITS.email);
    if (!ipOk || !emailOk) {
      await finish(429, { success: false, error: 'Too many requests. Please try again later.' });
      return;
    }

    let user: admin.auth.UserRecord | null = null;
    try {
      user = await admin.auth().getUserByEmail(email);
    } catch (e: any) {
      if (e?.code !== 'auth/user-not-found') throw e;
    }

    if (user) {
      const token = crypto.randomBytes(32).toString('base64url');
      const now = Date.now();
      await db().collection(DELETION_REQUESTS).doc(sha256(token)).set({
        uid: user.uid,
        used: false,
        createdAt: admin.firestore.Timestamp.fromMillis(now),
        expiresAt: admin.firestore.Timestamp.fromMillis(now + TOKEN_TTL_MS),
        // For a Firestore TTL policy (cleans unused requests).
        expireAt: admin.firestore.Timestamp.fromMillis(now + 7 * TOKEN_TTL_MS),
      });
      const sent = await sendResendEmail(
        email,
        'Confirm your GreenGo account deletion',
        confirmationEmailHtml(confirmUrl(token)),
      );
      console.log(`requestAccountDeletion: link issued for ${maskEmail(email)} (emailSent=${sent.emailSent})`);
    } else {
      console.log(`requestAccountDeletion: no account for ${maskEmail(email)}`);
    }
    await finish(200, GENERIC_RESPONSE);
  } catch (e: any) {
    console.error('requestAccountDeletion failed', e?.message || e);
    await finish(500, {
      success: false,
      error: 'We could not process the request. Please try again or contact info@greengochat.com.',
    });
  }
}

export const requestAccountDeletion = onRequest(
  { memory: '512MiB', timeoutSeconds: 540, maxInstances: 20 },
  monitored('requestAccountDeletion', handleRequestAccountDeletion),
);

// ---------------------------------------------------------------------------
// confirmAccountDeletion
// ---------------------------------------------------------------------------

function page(title: string, body: string): string {
  return `<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="robots" content="noindex"><title>${title}</title>
<style>body{font-family:Helvetica,Arial,sans-serif;background:#0A0A0A;color:#fff;margin:0;padding:24px}
.c{max-width:520px;margin:40px auto;background:#1A1A1A;border:1px solid #2A2A2A;border-radius:16px;padding:32px}
button{background:#c0392b;color:#fff;border:0;border-radius:12px;padding:14px 28px;font-size:16px;font-weight:bold;cursor:pointer}
a{color:#D4AF37}</style></head><body><div class="c"><h1>${title}</h1>${body}</div></body></html>`;
}

const INVALID_PAGE = page(
  'Link not valid',
  '<p>This deletion link is invalid, has expired, or has already been used.</p>' +
    '<p>You can request a new one at <a href="https://greengochat.com/delete-account">greengochat.com</a>.</p>',
);

type TokenState = { ok: true; ref: FirebaseFirestore.DocumentReference; uid: string } | { ok: false };

async function lookupToken(token: unknown): Promise<TokenState> {
  if (typeof token !== 'string' || token.length < 20 || token.length > 200) return { ok: false };
  const ref = db().collection(DELETION_REQUESTS).doc(sha256(token));
  const snap = await ref.get();
  const d = snap.data();
  if (!d || d.used === true || !d.uid) return { ok: false };
  if ((d.expiresAt?.toMillis?.() ?? 0) <= Date.now()) return { ok: false };
  return { ok: true, ref, uid: d.uid };
}

export async function handleConfirmAccountDeletion(req: Request, res: Response): Promise<void> {
  res.set('Cache-Control', 'no-store');
  res.set('Referrer-Policy', 'no-referrer');
  res.set('X-Frame-Options', 'DENY');
  res.set('Content-Security-Policy', "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'");
  try {
    if (req.method === 'GET') {
      const token = req.query.token;
      const st = await lookupToken(token);
      if (!st.ok) {
        res.status(410).type('html').send(INVALID_PAGE);
        return;
      }
      const safe = encodeURIComponent(String(token));
      res.status(200).type('html').send(page(
        'Delete your GreenGo account?',
        '<p>This permanently deletes your GreenGo account, profile, photos, matches and messages. ' +
          'It cannot be undone. Remaining coins and active subscriptions are lost.</p>' +
          '<p>Cancel any App Store / Google Play subscription in the store as well.</p>' +
          `<form method="POST" action="?token=${safe}"><input type="hidden" name="token" value="${safe}">` +
          '<button type="submit">Permanently delete my account</button></form>',
      ));
      return;
    }
    if (req.method !== 'POST') {
      res.status(405).type('html').send(page('Not allowed', '<p>Method not allowed.</p>'));
      return;
    }

    const raw = (req.body && typeof req.body === 'object' && req.body.token) || req.query.token;
    const token = typeof raw === 'string' ? decodeURIComponent(raw) : raw;
    if (typeof token !== 'string') {
      res.status(410).type('html').send(INVALID_PAGE);
      return;
    }
    const ref = db().collection(DELETION_REQUESTS).doc(sha256(token));

    // Claim the token atomically: only one request can ever run with it.
    const uid = await db().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const d = snap.data();
      if (!d || d.used === true || !d.uid) return null;
      if ((d.expiresAt?.toMillis?.() ?? 0) <= Date.now()) return null;
      tx.update(ref, { used: true, usedAt: admin.firestore.Timestamp.now() });
      return d.uid as string;
    });
    if (!uid) {
      res.status(410).type('html').send(INVALID_PAGE);
      return;
    }

    try {
      await deleteAccountCompletely(uid, { source: 'web_email_link' });
    } catch (e: any) {
      // Account left intact (Auth is deleted last). Release the token so the
      // user can retry within its lifetime.
      console.error(`confirmAccountDeletion: deletion failed for ${uid}`, e?.message || e);
      await ref.update({ used: false, lastFailureAt: admin.firestore.Timestamp.now() }).catch(() => undefined);
      res.status(500).type('html').send(page(
        'Something went wrong',
        '<p>We could not finish deleting your account. Nothing was lost; please open the link again in a few minutes, ' +
          'or contact <a href="mailto:info@greengochat.com">info@greengochat.com</a>.</p>',
      ));
      return;
    }
    res.status(200).type('html').send(page(
      'Account deleted',
      '<p>Your GreenGo account and its data have been deleted.</p>' +
        '<p>Records we must keep by law (payment records) are retained without your profile, as described in our privacy policy.</p>',
    ));
  } catch (e: any) {
    console.error('confirmAccountDeletion failed', e?.message || e);
    res.status(500).type('html').send(page('Something went wrong', '<p>Please try again later.</p>'));
  }
}

export const confirmAccountDeletion = onRequest(
  { memory: '512MiB', timeoutSeconds: 540, maxInstances: 20 },
  monitored('confirmAccountDeletion', handleConfirmAccountDeletion),
);

// ---------------------------------------------------------------------------
// deleteMyAccount (callable, app)
// ---------------------------------------------------------------------------

export const deleteMyAccount = onCall(
  { memory: '512MiB', timeoutSeconds: 540 },
  monitored('deleteMyAccount', async (request: any) => {
    try {
      const uid = request.auth?.uid;
      if (!uid) throw new AppError('UNAUTHENTICATED', 'User must be authenticated', 401);
      if (!isRecent(request.auth?.token?.auth_time)) {
        throw new AppError(
          'REQUIRES_RECENT_LOGIN',
          'Please sign in again to delete your account.',
          401,
          { reason: 'REQUIRES_RECENT_LOGIN', maxAgeSeconds: RECENT_AUTH_SECONDS },
        );
      }
      await deleteAccountCompletely(uid, { source: 'app_callable' });
      return { success: true };
    } catch (e) {
      if (e instanceof AppError) throw handleError(e);
      throw handleError(
        new AppError('DELETION_FAILED', 'Account deletion did not complete; your account was not deleted. Please try again.', 500),
      );
    }
  }),
);
