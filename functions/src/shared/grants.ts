/**
 * Shared entitlement helpers used by purchase verification and coupon redemption.
 * Centralises tier extension rules and coin granting so paid and promo flows stay in sync.
 */

import * as admin from 'firebase-admin';
import { db, logInfo } from './utils';

export type TierName = 'BASIC' | 'SILVER' | 'GOLD' | 'PLATINUM';

export const TIER_RANK: Record<TierName, number> = {
  BASIC: 0,
  SILVER: 1,
  GOLD: 2,
  PLATINUM: 3,
};

export interface MembershipExtensionResult {
  effectiveTier: TierName;
  newEndDate: Date;
  newEndTimestamp: admin.firestore.Timestamp;
}

/**
 * Pure tier-extension rule (no IO). Never downgrades an active higher tier.
 * - If user has an active membership with a higher rank than `requestedTier`,
 *   the existing tier is preserved and the end date is pushed by `durationMs`.
 * - If `requestedTier` is same or higher rank, the user moves to `requestedTier`
 *   and the end date is pushed by `durationMs` from the later of now or current end.
 * - If user has no active membership (or it has expired), start from `now`.
 */
export function computeMembershipExtension(
  currentTier: TierName | string | undefined | null,
  currentEndDate: Date | null,
  requestedTier: TierName,
  durationMs: number,
  now: Date = new Date(),
): MembershipExtensionResult {
  const isActive = currentEndDate !== null && currentEndDate > now;
  let effectiveTier: TierName = requestedTier;
  let baseDate: Date = now;

  if (isActive) {
    const currentRank = TIER_RANK[(currentTier as TierName)] ?? 0;
    const requestedRank = TIER_RANK[requestedTier] ?? 0;
    effectiveTier = requestedRank >= currentRank ? requestedTier : ((currentTier as TierName) || requestedTier);
    baseDate = currentEndDate as Date;
  }

  const newEndDate = new Date(baseDate.getTime() + durationMs);
  return {
    effectiveTier,
    newEndDate,
    newEndTimestamp: admin.firestore.Timestamp.fromDate(newEndDate),
  };
}

/**
 * Grants or extends a paid membership tier (SILVER / GOLD / PLATINUM).
 * Applies the never-downgrade extension rule. Updates `profiles/{uid}` and `users/{uid}`.
 * Returns the effective tier + new end date so callers can record audit data.
 */
export async function grantMembership(
  uid: string,
  requestedTier: TierName,
  durationMs: number,
): Promise<MembershipExtensionResult> {
  const profileSnap = await db.collection('profiles').doc(uid).get();
  const profileData = profileSnap.data() || {};
  const currentTier = (profileData.membershipTier as string) || 'BASIC';
  const currentEndTimestamp = profileData.membershipEndDate as admin.firestore.Timestamp | undefined;
  const currentEndDate = currentEndTimestamp ? currentEndTimestamp.toDate() : null;

  const now = admin.firestore.Timestamp.now();
  const result = computeMembershipExtension(currentTier, currentEndDate, requestedTier, durationMs, now.toDate());

  await db.collection('profiles').doc(uid).update({
    membershipTier: result.effectiveTier,
    membershipStartDate: now,
    membershipEndDate: result.newEndTimestamp,
    updatedAt: now,
  });

  await db.collection('users').doc(uid).update({
    subscriptionTier: result.effectiveTier,
    membershipEndDate: result.newEndTimestamp,
    updatedAt: now,
  });

  logInfo(`grantMembership uid=${uid} tier=${result.effectiveTier} endDate=${result.newEndDate.toISOString()}`);
  return result;
}

/**
 * Grants or extends the BASE membership flag (hasBaseMembership + baseMembershipEndDate).
 * Independent of the tier system — a user may have BASE active and any tier active simultaneously.
 * Extends the existing baseMembershipEndDate if still in the future, otherwise starts from now.
 */
export async function grantBaseMembership(
  uid: string,
  durationMs: number,
): Promise<{ newEndDate: Date; newEndTimestamp: admin.firestore.Timestamp }> {
  const profileSnap = await db.collection('profiles').doc(uid).get();
  const profileData = profileSnap.data() || {};
  const currentEndTimestamp = profileData.baseMembershipEndDate as admin.firestore.Timestamp | undefined;
  const currentEndDate = currentEndTimestamp ? currentEndTimestamp.toDate() : null;
  const now = admin.firestore.Timestamp.now();
  const nowDate = now.toDate();

  const baseDate = currentEndDate && currentEndDate > nowDate ? currentEndDate : nowDate;
  const newEndDate = new Date(baseDate.getTime() + durationMs);
  const newEndTimestamp = admin.firestore.Timestamp.fromDate(newEndDate);

  await db.collection('profiles').doc(uid).update({
    hasBaseMembership: true,
    baseMembershipEndDate: newEndTimestamp,
    updatedAt: now,
  });

  logInfo(`grantBaseMembership uid=${uid} endDate=${newEndDate.toISOString()}`);
  return { newEndDate, newEndTimestamp };
}

/**
 * Credits coins to a user's balance. Uses the embedded `coinBatches` array shape
 * that `processExpiredCoins` reads, so granted coins are subject to the normal
 * 365-day expiration rules.
 *
 * `source` is one of: 'purchase' | 'reward' | 'allowance' | 'coupon' | 'membership_bonus'
 * `reason` is a free-text reason recorded on the coinTransactions doc.
 */
export async function grantCoins(
  uid: string,
  amount: number,
  source: string,
  reason: string,
  metadata: Record<string, any> = {},
): Promise<void> {
  if (amount <= 0) return;

  const COIN_EXPIRATION_DAYS = 365;

  await db.runTransaction(async (transaction) => {
    const balanceRef = db.collection('coinBalances').doc(uid);
    const balanceDoc = await transaction.get(balanceRef);

    let currentBalance = 0;
    let earnedCoins = 0;
    let purchasedCoins = 0;
    let giftedCoins = 0;
    let spentCoins = 0;
    let coinBatches: any[] = [];

    if (balanceDoc.exists) {
      const data = balanceDoc.data() as any;
      currentBalance = data.totalCoins || 0;
      earnedCoins = data.earnedCoins || 0;
      purchasedCoins = data.purchasedCoins || 0;
      giftedCoins = data.giftedCoins || 0;
      spentCoins = data.spentCoins || 0;
      coinBatches = data.coinBatches || [];
    }

    const now = admin.firestore.Timestamp.now();
    const expirationDate = new Date();
    expirationDate.setDate(expirationDate.getDate() + COIN_EXPIRATION_DAYS);

    const batchId = db.collection('temp').doc().id;
    coinBatches.push({
      batchId,
      initialCoins: amount,
      remainingCoins: amount,
      source,
      acquiredDate: now,
      expirationDate: admin.firestore.Timestamp.fromDate(expirationDate),
    });

    transaction.set(balanceRef, {
      userId: uid,
      totalCoins: currentBalance + amount,
      earnedCoins: source === 'reward' || source === 'allowance' ? earnedCoins + amount : earnedCoins,
      purchasedCoins: source === 'purchase' ? purchasedCoins + amount : purchasedCoins,
      giftedCoins,
      spentCoins,
      lastUpdated: now,
      coinBatches,
    }, { merge: true });

    const transactionRef = db.collection('coinTransactions').doc();
    transaction.set(transactionRef, {
      userId: uid,
      type: 'credit',
      amount,
      balanceAfter: currentBalance + amount,
      reason,
      metadata: { source, ...metadata },
      createdAt: now,
    });
  });

  logInfo(`grantCoins uid=${uid} amount=${amount} source=${source} reason=${reason}`);
}
