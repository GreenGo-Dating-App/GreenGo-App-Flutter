/**
 * Membership expiry primitives shared by the hourly expiry jobs, the store
 * notification handlers, the Stripe webhook and the one-off migration.
 *
 * Paid tier (SILVER/GOLD/PLATINUM) and Base membership are INDEPENDENT:
 *   - a paid tier ending sets `membershipTier: 'FREE'` and never touches
 *     `hasBaseMembership` / `baseMembershipEndDate`;
 *   - a Base membership ending sets `hasBaseMembership: false` and never
 *     touches the tier.
 *
 * `membershipEndDate` is kept for history; `membershipExpiredAt` and
 * `previousMembershipTier` record the downgrade. Every write is idempotent:
 * re-running on an already-downgraded profile is a no-op (the planner skips
 * it), and the expiry notification has a deterministic id.
 */

import * as admin from 'firebase-admin';
import { db, logError } from './utils';
import {
  USERS_FREE_TIER,
  effectiveTier,
  isBaseProductId,
  isProfileAdmin,
  normalizeStoredTier,
  tierDateFromValue,
} from './effectiveTier';

/** Max operations per WriteBatch (Firestore hard limit is 500). */
export const MAX_BATCH_OPS = 400;

/** Subscription statuses that still claim an entitlement (both casings in prod). */
const LIVE_SUBSCRIPTION_STATUSES = [
  'active', 'ACTIVE', 'in_grace_period', 'GRACE', 'on_hold',
];

/**
 * Buffers writes and commits them in batches of at most [MAX_BATCH_OPS].
 * Call [flush] at the end.
 */
export class WriteQueue {
  private batch: FirebaseFirestore.WriteBatch;
  private ops = 0;
  committedOps = 0;

  constructor(private readonly firestore: FirebaseFirestore.Firestore = db) {
    this.batch = firestore.batch();
  }

  async set(
    ref: FirebaseFirestore.DocumentReference,
    data: FirebaseFirestore.DocumentData,
    merge = true,
  ): Promise<void> {
    if (merge) this.batch.set(ref, data, { merge: true });
    else this.batch.set(ref, data);
    await this.bump();
  }

  async update(
    ref: FirebaseFirestore.DocumentReference,
    data: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData>,
  ): Promise<void> {
    this.batch.update(ref, data);
    await this.bump();
  }

  private async bump(): Promise<void> {
    this.ops++;
    if (this.ops >= MAX_BATCH_OPS) await this.flush();
  }

  async flush(): Promise<void> {
    if (this.ops === 0) return;
    const b = this.batch;
    const n = this.ops;
    this.batch = this.firestore.batch();
    this.ops = 0;
    await b.commit();
    this.committedOps += n;
  }
}

export interface TierExpiryOptions {
  /** Why: 'expired' (end date passed), 'store_revoked', 'stripe_deleted', 'migration'. */
  reason: string;
  now?: admin.firestore.Timestamp;
  /** Add the in-app "Membership Expired" notification (default true). */
  notify?: boolean;
  /**
   * Also require the stored end date to be in the past (default true). The
   * store-revocation / Stripe-deletion paths pass false: the entitlement ends
   * NOW even though the stored end date is still in the future.
   */
  requirePastEndDate?: boolean;
}

/**
 * Plans (enqueues) the downgrade of one profile's PAID tier to FREE:
 *   profiles/{uid}: membershipTier 'FREE', membershipExpiredAt, previousMembershipTier
 *   users/{uid}:    subscriptionTier 'free', membershipEndDate (mirror; only if the doc exists)
 *   memberships where userId==uid && isActive → isActive false
 *   subscriptions (non-Base) still 'active'/'ACTIVE'/grace whose endDate passed → 'expired'
 *   notifications/membership_expired_{uid}_{endMillis} (deterministic → idempotent)
 *
 * Returns the tier that was removed, or null when nothing had to change
 * (already FREE, TEST, admin, or still active).
 */
export async function planTierExpiry(
  profileSnap: FirebaseFirestore.DocumentSnapshot,
  queue: WriteQueue,
  opts: TierExpiryOptions,
): Promise<string | null> {
  const data = profileSnap.data();
  if (!data) return null;
  const uid = profileSnap.id;
  const now = opts.now ?? admin.firestore.Timestamp.now();
  const nowDate = now.toDate();

  const stored = normalizeStoredTier(data.membershipTier);
  // TEST testers and admins keep their stored tier (same as the client).
  if (stored === 'TEST' || isProfileAdmin(data)) return null;
  // Already FREE (only the raw value 'FREE' counts; 'free'/'BASIC' get normalised).
  if (data.membershipTier === 'FREE') return null;

  const requirePast = opts.requirePastEndDate !== false;
  if (requirePast && effectiveTier(data, nowDate) !== 'FREE') return null;

  const endDate = tierDateFromValue(data.membershipEndDate);

  await queue.set(profileSnap.ref, {
    membershipTier: 'FREE',
    previousMembershipTier: String(data.membershipTier ?? ''),
    membershipExpiredAt: now,
    membershipExpiryReason: opts.reason,
    updatedAt: now,
  });

  // Mirrors: never used for decisions, but keep them from contradicting the profile.
  const userRef = db.collection('users').doc(uid);
  const [userSnap, activeMemberships, liveSubs] = await Promise.all([
    userRef.get(),
    db.collection('memberships')
      .where('userId', '==', uid)
      .where('isActive', '==', true)
      .get(),
    db.collection('subscriptions')
      .where('userId', '==', uid)
      .where('status', 'in', LIVE_SUBSCRIPTION_STATUSES)
      .get(),
  ]);

  if (userSnap.exists) {
    await queue.set(userRef, {
      subscriptionTier: USERS_FREE_TIER,
      membershipEndDate: endDate ? admin.firestore.Timestamp.fromDate(endDate) : null,
      updatedAt: now,
    });
  }

  for (const m of activeMemberships.docs) {
    await queue.set(m.ref, { isActive: false, expiredAt: now, updatedAt: now });
  }

  for (const s of liveSubs.docs) {
    const sd = s.data();
    if (isBaseProductId(sd.productId) || String(sd.tier || '').toUpperCase() === 'BASE') continue;
    const subEnd = tierDateFromValue(sd.endDate ?? sd.storeExpiryDate ?? sd.expirationDate);
    // A still-running store/Stripe period on this record means the profile
    // was ended early (refund/revoke) — the caller decides that; for the
    // plain expiry path only records whose own period is over are closed.
    if (requirePast && subEnd && subEnd.getTime() > nowDate.getTime()) continue;
    await queue.set(s.ref, { status: 'expired', updatedAt: now });
  }

  // Legacy 'BASIC' was never a paid tier the user bought: normalise silently.
  if (opts.notify !== false && stored !== 'BASIC') {
    const key = `${uid}_${endDate ? endDate.getTime() : 'noend'}`;
    await queue.set(
      db.collection('notifications').doc(`membership_expired_${key}`),
      {
        userId: uid,
        type: 'membership_expired',
        title: 'Membership Expired',
        body: 'Your membership has expired. Purchase a new membership to restore premium features.',
        data: { previousTier: String(data.membershipTier ?? '') },
        read: false,
        sent: false,
        createdAt: now,
      },
      false,
    );
  }

  return String(data.membershipTier ?? '');
}

/**
 * Plans the expiry of a profile's Base membership: hasBaseMembership false +
 * baseMembershipExpiredAt. Never touches the tier. Returns true when a write
 * was enqueued.
 */
export async function planBaseExpiry(
  profileSnap: FirebaseFirestore.DocumentSnapshot,
  queue: WriteQueue,
  now: admin.firestore.Timestamp = admin.firestore.Timestamp.now(),
): Promise<boolean> {
  const data = profileSnap.data();
  if (!data || data.hasBaseMembership !== true) return false;
  const end = tierDateFromValue(data.baseMembershipEndDate);
  if (end && end.getTime() > now.toMillis()) return false; // still active
  await queue.set(profileSnap.ref, {
    hasBaseMembership: false,
    baseMembershipExpiredAt: now,
    updatedAt: now,
  });
  return true;
}

/**
 * Immediately downgrades one user's paid tier (store refund/revoke, Stripe
 * subscription deleted). Returns the removed tier or null.
 */
export async function downgradeTierNow(
  uid: string,
  reason: string,
  notify = true,
): Promise<string | null> {
  const snap = await db.collection('profiles').doc(uid).get();
  if (!snap.exists) return null;
  const queue = new WriteQueue();
  try {
    const removed = await planTierExpiry(snap, queue, {
      reason,
      notify,
      requirePastEndDate: false,
    });
    await queue.flush();
    return removed;
  } catch (e) {
    logError(`downgradeTierNow failed for ${uid}`, e);
    throw e;
  }
}
