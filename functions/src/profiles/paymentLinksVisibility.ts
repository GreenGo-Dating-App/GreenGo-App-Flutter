/**
 * Personal payment links visibility (owner rule 2026-10-12).
 *
 *   "Business has automatic payment through Stripe or Mercado Pago. Silver,
 *    Gold and Platinum have payment links in Account settings. That is
 *    visible only when the tier is Silver, Gold or Platinum."
 *
 * `profiles/{uid}.paymentLinks` (Pix, PayPal, Mercado Pago link, Wise, ...)
 * is allowed and VISIBLE only while the owner's EFFECTIVE tier
 * (shared/effectiveTier.ts: membershipTier + membershipEndDate, TEST and
 * admins included) is SILVER / GOLD / PLATINUM / TEST.
 *
 * `profiles/{uid}` is readable by every signed-in user, so the links of a
 * user who is no longer eligible must leave the public document:
 *
 *   hide     not eligible + public links  ->  links MOVED to
 *            profiles_private/{uid}.paymentLinksHidden (owner + admin only),
 *            public `paymentLinks` and `paymentLinksExpireAt` deleted.
 *   restore  eligible + hidden links      ->  hidden links merged back under
 *            the public ones (public wins), hidden copy deleted.
 *   expiry   eligible + public links      ->  `paymentLinksExpireAt` =
 *            membershipEndDate (absent for TEST / admins, who never lapse).
 *            The scheduled sweep finds lapsed owners with ONE indexed range
 *            query on that field (single-field index, automatic) instead of
 *            scanning profiles.
 *
 * Writes:
 *   - mirrorPrivateProfileFields (profiles/{uid} onWrite) calls
 *     [handlePaymentLinksProfileWrite] for every event. It decides from the
 *     event data alone and returns WITHOUT any read for the hot-path writes
 *     (presence, counters, ...); only a hide, an expiry fix or a tier change
 *     of an eligible user runs the transaction. Every tier writer (grants.ts
 *     grantMembership, verifyPurchase, Stripe webhooks, store notifications,
 *     redeemCoupon, referral / signup grants, admin panel, the hourly
 *     handleExpiredMemberships downgrade, the client self-heal downgrade)
 *     writes `profiles/{uid}`, so this one trigger covers them all.
 *   - sweepExpiredPaymentLinks (scheduled) catches the time-based lapse
 *     before handleExpiredMemberships rewrites the tier.
 *
 * Idempotent and race-safe: [syncPaymentLinksVisibility] re-reads both
 * documents inside a transaction and only writes values that differ, so the
 * write it makes re-triggers the function once and that run is a no-op.
 * Links are never deleted by the server: they are moved, then moved back.
 */

import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { effectiveTier, isProfileAdmin, normalizeStoredTier, tierDateFromValue } from '../shared/effectiveTier';

export const PAYMENT_LINKS_FIELD = 'paymentLinks';
export const PAYMENT_LINKS_HIDDEN_FIELD = 'paymentLinksHidden';
export const PAYMENT_LINKS_HIDDEN_AT_FIELD = 'paymentLinksHiddenAt';
export const PAYMENT_LINKS_EXPIRE_FIELD = 'paymentLinksExpireAt';
const PRIVATE_PROFILES = 'profiles_private';

/** Max length of one stored link value (orders.ts snapshots cap at 300 too). */
const MAX_VALUE_LEN = 300;
/** Max entries kept from a links map (PaymentMethod has 11). */
const MAX_ENTRIES = 30;

export type LinksMap = Record<string, string>;

/** The non-empty string entries of a stored links map, or null when there are none. */
export function cleanLinks(raw: unknown): LinksMap | null {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return null;
  const out: LinksMap = {};
  let n = 0;
  for (const [k, v] of Object.entries(raw as Record<string, unknown>)) {
    if (typeof v !== 'string') continue;
    const t = v.trim();
    if (!t || t.length > MAX_VALUE_LEN) continue;
    out[k] = t;
    if (++n >= MAX_ENTRIES) break;
  }
  return n > 0 ? out : null;
}

/** May this profile hold / show payment links right now? Paid tier or TEST. */
export function paymentLinksEligible(
  profile: Record<string, any> | null | undefined,
  now: Date = new Date(),
): boolean {
  return effectiveTier(profile, now) !== 'FREE';
}

/**
 * The `paymentLinksExpireAt` the public profile should carry: the paid tier's
 * end date while eligible links are shown, null otherwise (and for TEST /
 * admins, whose tier never lapses by date).
 */
export function desiredExpireAt(
  profile: Record<string, any> | null | undefined,
  now: Date = new Date(),
): admin.firestore.Timestamp | null {
  if (!profile || !cleanLinks(profile[PAYMENT_LINKS_FIELD])) return null;
  if (!paymentLinksEligible(profile, now)) return null;
  if (normalizeStoredTier(profile.membershipTier) === 'TEST' || isProfileAdmin(profile)) return null;
  const end = tierDateFromValue(profile.membershipEndDate);
  return end ? admin.firestore.Timestamp.fromDate(end) : null;
}

function sameInstant(a: unknown, b: admin.firestore.Timestamp | null): boolean {
  const da = tierDateFromValue(a);
  if (!da || !b) return !da && !b;
  return da.getTime() === b.toMillis();
}

const TIER_FIELDS = ['membershipTier', 'membershipEndDate', 'isAdmin'];

function tierFieldsChanged(before: Record<string, any> | undefined, after: Record<string, any>): boolean {
  if (!before) return true;
  return TIER_FIELDS.some((f) => {
    const a = before[f];
    const b = after[f];
    if (a instanceof admin.firestore.Timestamp && b instanceof admin.firestore.Timestamp) return !a.isEqual(b);
    const da = f === 'membershipEndDate' ? tierDateFromValue(a)?.getTime() ?? null : a ?? null;
    const db = f === 'membershipEndDate' ? tierDateFromValue(b)?.getTime() ?? null : b ?? null;
    return da !== db;
  });
}

/**
 * Pure decision on one profiles/{uid} write event: does the transactional
 * sync have to run? false for every write that cannot change visibility, so
 * the hot path makes no read at all.
 */
export function needsPaymentLinksSync(
  before: Record<string, any> | undefined,
  after: Record<string, any> | undefined,
  now: Date = new Date(),
): boolean {
  if (!after) return false;
  const hasLinks = !!cleanLinks(after[PAYMENT_LINKS_FIELD]);
  const eligible = paymentLinksEligible(after, now);
  // Links on display for someone who is not eligible: hide.
  if (hasLinks && !eligible) return true;
  // Stale / missing / tampered expiry marker.
  if (!sameInstant(after[PAYMENT_LINKS_EXPIRE_FIELD], desiredExpireAt(after, now))) return true;
  // Became (or stayed) eligible through a tier change: hidden links may be waiting.
  if (eligible && tierFieldsChanged(before, after)) return true;
  return false;
}

export type SyncOutcome = 'hidden' | 'restored' | 'expiry_updated' | 'noop' | 'missing';

/**
 * THE transactional visibility sync for one user. Safe to call any time, any
 * number of times, concurrently: it re-reads both documents and writes only
 * differences.
 */
export async function syncPaymentLinksVisibility(
  uid: string,
  opts: { firestore?: admin.firestore.Firestore; now?: Date } = {},
): Promise<SyncOutcome> {
  const fs = opts.firestore ?? admin.firestore();
  const now = opts.now ?? new Date();
  const pubRef = fs.collection('profiles').doc(uid);
  const privRef = fs.collection(PRIVATE_PROFILES).doc(uid);
  const del = admin.firestore.FieldValue.delete();

  return fs.runTransaction(async (tx) => {
    const [pubSnap, privSnap] = await Promise.all([tx.get(pubRef), tx.get(privRef)]);
    if (!pubSnap.exists) return 'missing';
    const pub = pubSnap.data() || {};
    const priv = privSnap.exists ? privSnap.data() || {} : {};
    const links = cleanLinks(pub[PAYMENT_LINKS_FIELD]);
    const hidden = cleanLinks(priv[PAYMENT_LINKS_HIDDEN_FIELD]);
    const eligible = paymentLinksEligible(pub, now);

    if (!eligible) {
      if (links) {
        // Public wins over an older hidden copy for the same provider.
        tx.set(privRef, {
          [PAYMENT_LINKS_HIDDEN_FIELD]: { ...(hidden || {}), ...links },
          [PAYMENT_LINKS_HIDDEN_AT_FIELD]: admin.firestore.Timestamp.fromDate(now),
        }, { merge: true });
        tx.update(pubRef, { [PAYMENT_LINKS_FIELD]: del, [PAYMENT_LINKS_EXPIRE_FIELD]: del });
        return 'hidden';
      }
      if (PAYMENT_LINKS_EXPIRE_FIELD in pub) {
        tx.update(pubRef, { [PAYMENT_LINKS_EXPIRE_FIELD]: del });
        return 'expiry_updated';
      }
      return 'noop';
    }

    // Eligible.
    if (hidden) {
      const merged = { ...hidden, ...(links || {}) };
      const expireAt = desiredExpireAt({ ...pub, [PAYMENT_LINKS_FIELD]: merged }, now);
      tx.update(pubRef, {
        [PAYMENT_LINKS_FIELD]: merged,
        [PAYMENT_LINKS_EXPIRE_FIELD]: expireAt ?? del,
      });
      tx.update(privRef, { [PAYMENT_LINKS_HIDDEN_FIELD]: del, [PAYMENT_LINKS_HIDDEN_AT_FIELD]: del });
      return 'restored';
    }
    const expireAt = desiredExpireAt(pub, now);
    if (!sameInstant(pub[PAYMENT_LINKS_EXPIRE_FIELD], expireAt)
        || (!expireAt && PAYMENT_LINKS_EXPIRE_FIELD in pub)) {
      tx.update(pubRef, { [PAYMENT_LINKS_EXPIRE_FIELD]: expireAt ?? del });
      return 'expiry_updated';
    }
    return 'noop';
  });
}

/** Body of the profiles/{uid} onWrite hook (called by mirrorPrivateProfileFields). */
export async function handlePaymentLinksProfileWrite(
  uid: string,
  before: Record<string, any> | undefined,
  after: Record<string, any> | undefined,
  opts: { firestore?: admin.firestore.Firestore; now?: Date } = {},
): Promise<SyncOutcome | 'skipped'> {
  if (!needsPaymentLinksSync(before, after, opts.now)) return 'skipped';
  return syncPaymentLinksVisibility(uid, opts);
}

/**
 * Scheduled sweep: every public profile whose `paymentLinksExpireAt` passed.
 * The query CONSUMES its queue (each sync deletes or moves the marker into
 * the future), so it re-queries from the start instead of paging with a
 * cursor; a doc that somehow did not move is skipped by id to guarantee
 * progress. Bounded by [timeBudgetMs].
 */
export async function runPaymentLinksSweep(
  opts: { firestore?: admin.firestore.Firestore; now?: Date; pageSize?: number; timeBudgetMs?: number } = {},
): Promise<{ scanned: number; hidden: number; updated: number; failed: number }> {
  const fs = opts.firestore ?? admin.firestore();
  const now = opts.now ?? new Date();
  const pageSize = Math.min(opts.pageSize ?? 200, 400);
  const budget = opts.timeBudgetMs ?? 8 * 60 * 1000;
  const started = Date.now();
  const seen = new Set<string>();
  const r = { scanned: 0, hidden: 0, updated: 0, failed: 0 };
  let cursor: admin.firestore.QueryDocumentSnapshot | null = null;

  while (Date.now() - started < budget) {
    let q = fs.collection('profiles')
      .where(PAYMENT_LINKS_EXPIRE_FIELD, '<=', admin.firestore.Timestamp.fromDate(now))
      .orderBy(PAYMENT_LINKS_EXPIRE_FIELD, 'asc')
      .limit(pageSize);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.get();
    if (snap.empty) break;
    let progressed = false;
    for (const d of snap.docs) {
      if (seen.has(d.id)) continue;
      seen.add(d.id);
      progressed = true;
      r.scanned++;
      try {
        const out = await syncPaymentLinksVisibility(d.id, { firestore: fs, now });
        if (out === 'hidden') r.hidden++;
        else if (out === 'expiry_updated' || out === 'restored') r.updated++;
      } catch (e: any) {
        r.failed++;
        console.error(`sweepExpiredPaymentLinks: ${d.id} failed: ${e?.message || e}`);
      }
    }
    // Normally the processed docs left the range, so re-query from the start;
    // a page made only of already-seen docs (failed / did not move) is paged
    // past instead, so the loop always ends.
    if (progressed) {
      cursor = null;
    } else {
      if (snap.size < pageSize) break;
      cursor = snap.docs[snap.docs.length - 1];
    }
  }
  return r;
}
