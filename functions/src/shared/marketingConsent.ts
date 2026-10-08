/**
 * Marketing opt-in (P2-5b/c).
 *
 * E-mail: marketing / engagement e-mail (weekly digests, re-engagement,
 * streak reminders, offers ...) goes ONLY to users with an explicit recorded
 * opt-in: `consents/{uid}.marketing_email.accepted === true`, written by the
 * `recordConsent` callable (signup checkbox, privacy settings toggle) and set
 * back to false by the unsubscribe link. There was no opt-in record before
 * P2-5, so every existing user defaults to NOT opted in.
 *
 * Push: the `marketing` notification category (notification_preferences
 * /{uid}.categories.marketing), default OFF — see notifications/prefs.ts.
 */
import * as admin from 'firebase-admin';
import { createHmac, timingSafeEqual } from 'crypto';
import './firebaseAdmin';

export const MARKETING_EMAIL_CONSENT = 'marketing_email';

const db = () => admin.firestore();

/** True when the consent record is an explicit, current opt-in. */
export function isMarketingOptIn(consentsDoc: Record<string, any> | undefined | null): boolean {
  return consentsDoc?.[MARKETING_EMAIL_CONSENT]?.accepted === true;
}

/** One user. Fail-CLOSED: on a read error nobody gets marketing mail. */
export async function hasMarketingEmailOptIn(uid: string): Promise<boolean> {
  if (!uid) return false;
  try {
    return isMarketingOptIn((await db().collection('consents').doc(uid).get()).data());
  } catch {
    return false;
  }
}

/**
 * Batched (getAll, chunks of 300): the subset of [uids] that opted in.
 * Fail-CLOSED per chunk.
 */
export async function filterMarketingEmailOptIns(uids: string[]): Promise<Set<string>> {
  const out = new Set<string>();
  const unique = [...new Set(uids.filter((u) => typeof u === 'string' && u))];
  const CHUNK = 300;
  for (let i = 0; i < unique.length; i += CHUNK) {
    const slice = unique.slice(i, i + CHUNK);
    try {
      const snaps = await db().getAll(...slice.map((u) => db().collection('consents').doc(u)));
      snaps.forEach((s, idx) => {
        if (isMarketingOptIn(s.data())) out.add(slice[idx]);
      });
    } catch {
      /* fail closed */
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Unsubscribe link

/**
 * Secret for the unsubscribe-link HMAC. There is deliberately NO hard-coded
 * production fallback (this repo is public: a known fallback would let anyone
 * forge unsubscribe links for any user). Tests and the local emulator get a
 * throwaway secret; a deployed function without UNSUBSCRIBE_SECRET or
 * RETENTION_SALT refuses to create or accept links.
 */
function unsubscribeSecret(): string | null {
  const configured = process.env.UNSUBSCRIBE_SECRET || process.env.RETENTION_SALT;
  if (configured) return configured;
  if (process.env.JEST_WORKER_ID || process.env.FUNCTIONS_EMULATOR === 'true') {
    return 'local-test-only-unsubscribe-secret';
  }
  console.error('[marketingConsent] UNSUBSCRIBE_SECRET / RETENTION_SALT not set: unsubscribe links disabled');
  return null;
}

/** Stateless token for the unsubscribe link: HMAC(secret, uid), 32 hex chars. */
export function unsubscribeToken(uid: string): string {
  const secret = unsubscribeSecret();
  if (!secret) throw new Error('unsubscribe secret not configured');
  return createHmac('sha256', secret).update(`unsubscribe:${uid}`).digest('hex').slice(0, 32);
}

export function verifyUnsubscribeToken(uid: string, token: string): boolean {
  if (typeof uid !== 'string' || !uid || typeof token !== 'string' || token.length !== 32) return false;
  if (!unsubscribeSecret()) return false;
  const want = Buffer.from(unsubscribeToken(uid));
  const got = Buffer.from(token);
  return want.length === got.length && timingSafeEqual(want, got);
}

/**
 * Public unsubscribe URL. Default: the `unsubscribeMarketing` function URL,
 * which works as soon as the function is deployed. UNSUBSCRIBE_BASE_URL can
 * point it at a branded path instead (e.g. a greengochat.com redirect).
 */
export function unsubscribeUrl(uid: string): string {
  const project = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || 'greengo-chat';
  const base = process.env.UNSUBSCRIBE_BASE_URL ||
    `https://us-central1-${project}.cloudfunctions.net/unsubscribeMarketing`;
  return `${base}?u=${encodeURIComponent(uid)}&t=${unsubscribeToken(uid)}`;
}

export const PRIVACY_POLICY_URL = 'https://greengochat.com/privacy-policy';

/** Records an opt-out (unsubscribe link / List-Unsubscribe one-click). */
export async function recordMarketingOptOut(uid: string, source: string): Promise<void> {
  const at = admin.firestore.Timestamp.now();
  const ref = db().collection('consents').doc(uid);
  const batch = db().batch();
  batch.set(ref.collection('events').doc(), {
    type: MARKETING_EMAIL_CONSENT, version: 1, accepted: false, locale: null, platform: source, at,
  });
  batch.set(ref, {
    [MARKETING_EMAIL_CONSENT]: { accepted: false, version: 1, locale: null, at, source },
    updatedAt: at,
  }, { merge: true });
  await batch.commit();
}
