/**
 * claimReward — server-verified one-off / daily coin rewards (P1-9).
 *
 * WHY 1st-gen: production runs a gen1 `claimReward` (deployed from the web
 * repo). Firebase cannot change a function's generation in place, so this is
 * declared with the v1 API to replace the live one without a delete/recreate
 * gap. It runs at 512MB like every function in this codebase (the bundled
 * index.js needs ~200MB just to load).
 *
 * What the live (web-repo) version did and this one keeps:
 *  - input `{ rewardId }`, response `{ success: true, coinsAdded }`;
 *  - the reward table, including `first_message` (25), which only the web copy had;
 *  - writes the REAL camelCase `coinBalances` / `coinTransactions` docs (the app
 *    repo's previous gen2 copy wrote the phantom snake_case `coin_balances`,
 *    which no client reads);
 *  - records a legacy `claimedRewards` doc, which the app's canClaimReward reads.
 *
 * What it fixes:
 *  - eligibility is checked SERVER-SIDE per reward (it used to pay anything);
 *  - dedup is transactional: the claim doc `reward_claims/{uid}_{reward}_{period}`
 *    is created in the same transaction that credits the coins, so two
 *    concurrent calls cannot both pay (the old dedup was a query OUTSIDE the
 *    transaction);
 *  - `daily_login` is once per UTC day (the live copy allowed it once EVER).
 *
 * Also accepts `{ rewardType }` (the app repo's old gen2 input) for
 * compatibility. No current client calls this callable — the Flutter coin
 * datasource credits rewards itself — so the contract is kept for old builds.
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { db, logInfo } from '../shared/utils';

export const REWARD_COINS = {
  first_match: 50,
  complete_profile: 100,
  daily_login: 10,
  week_streak: 50,
  month_streak: 200,
  first_message: 25,
  photo_verification: 75,
  refer_friend: 100,
} as const;

export type RewardId = keyof typeof REWARD_COINS;

/** CoinTransactionReason names the Flutter model parses (coin_transaction.dart). */
const REWARD_REASON: Record<RewardId, string> = {
  first_match: 'firstMatchReward',
  complete_profile: 'completeProfileReward',
  daily_login: 'dailyLoginStreakReward',
  week_streak: 'dailyLoginStreakReward',
  month_streak: 'dailyLoginStreakReward',
  first_message: 'achievementReward',
  photo_verification: 'achievementReward',
  refer_friend: 'referralBonus',
};

const ONE_TIME: ReadonlySet<RewardId> = new Set<RewardId>([
  'first_match', 'complete_profile', 'first_message', 'photo_verification',
]);

const VERIFIED_BADGE_LEVELS = new Set(['photoVerified', 'idVerified', 'fullyVerified']);

function isRewardId(v: unknown): v is RewardId {
  return typeof v === 'string' && Object.prototype.hasOwnProperty.call(REWARD_COINS, v);
}

/** Dedup period: `daily_login` is one per UTC day, everything else once ever. */
export function rewardPeriod(rewardId: RewardId, now: Date): string {
  return rewardId === 'daily_login' ? now.toISOString().slice(0, 10) : 'once';
}

export function rewardClaimId(uid: string, rewardId: RewardId, period: string): string {
  return `${uid}_${rewardId}_${period}`;
}

const nonEmptyString = (v: unknown): boolean => typeof v === 'string' && v.trim().length > 0;
const nonEmptyList = (v: unknown): boolean =>
  Array.isArray(v) && v.some((x) => typeof x === 'string' && x.trim().length > 0);

/**
 * A profile is complete when everything onboarding asks for is filled in AND
 * the optional bio has been written: name, birth date, gender, at least one
 * photo, at least one interest, and a non-empty bio. The client-written
 * `isComplete` flag is deliberately NOT trusted.
 */
export function isProfileComplete(p: Record<string, unknown> | undefined): boolean {
  if (!p) return false;
  return nonEmptyString(p.displayName)
    && p.dateOfBirth != null
    && nonEmptyString(p.gender)
    && nonEmptyList(p.photoUrls)
    && nonEmptyList(p.interests)
    && nonEmptyString(p.bio);
}

function refuse(message: string): never {
  throw new functions.https.HttpsError('failed-precondition', message);
}

/** Server-side eligibility. Throws failed-precondition when not eligible. */
async function assertEligible(uid: string, rewardId: RewardId): Promise<void> {
  switch (rewardId) {
    case 'daily_login':
      // Calling this signed in IS the login; the once-per-UTC-day limit is the
      // transactional claim doc below.
      return;

    case 'complete_profile': {
      const profile = await db.collection('profiles').doc(uid).get();
      if (!isProfileComplete(profile.data())) refuse('Profile is not complete');
      return;
    }

    case 'first_match': {
      const [a, b] = await Promise.all([
        db.collection('matches').where('userId1', '==', uid).limit(1).get(),
        db.collection('matches').where('userId2', '==', uid).limit(1).get(),
      ]);
      if (a.empty && b.empty) refuse('No match yet');
      return;
    }

    case 'first_message': {
      // Collection-group single-field index on messages.senderId exists
      // (firestore.indexes.json fieldOverrides).
      const sent = await db.collectionGroup('messages').where('senderId', '==', uid).limit(1).get();
      if (sent.empty) refuse('No message sent yet');
      return;
    }

    case 'photo_verification': {
      // Only server-owned records count: verification_badges is written by the
      // identity-verification functions (clients are denied by the catch-all
      // rule) and isAgeVerified is rule-protected. profiles.verificationStatus
      // is client-writable, so it is NOT trusted here.
      const [badge, profile] = await Promise.all([
        db.collection('verification_badges').doc(uid).get(),
        db.collection('profiles').doc(uid).get(),
      ]);
      const level = badge.data()?.level;
      const badgeOk = typeof level === 'string' && VERIFIED_BADGE_LEVELS.has(level);
      if (!badgeOk && profile.data()?.isAgeVerified !== true) refuse('Not verified');
      return;
    }

    case 'week_streak':
    case 'month_streak':
      // Login streaks live in `login_streaks`, which the CLIENT writes. There is
      // no server-owned streak record, so a streak cannot be verified: refuse.
      return refuse('Streak rewards cannot be verified server-side');

    case 'refer_friend':
      // Referrals are paid automatically (and capped) by redeemReferral.
      // Paying them here too would double-credit.
      return refuse('Referral rewards are credited automatically');
  }
}

export interface ClaimRewardResult {
  success: true;
  /** Live (web) response field. */
  coinsAdded: number;
  /** App-repo gen2 response fields, kept for compatibility. */
  coinsEarned: number;
  newBalance: number;
  rewardId: RewardId;
  rewardType: RewardId;
}

export async function claimRewardForUser(
  uid: string,
  data: { rewardId?: unknown; rewardType?: unknown } | null | undefined,
  now: Date = new Date(),
): Promise<ClaimRewardResult> {
  const requested = data?.rewardId ?? data?.rewardType;
  if (!isRewardId(requested)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid reward ID');
  }
  const rewardId = requested;
  const coins = REWARD_COINS[rewardId];

  await assertEligible(uid, rewardId);

  const period = rewardPeriod(rewardId, now);
  const claimRef = db.collection('reward_claims').doc(rewardClaimId(uid, rewardId, period));
  const balanceRef = db.collection('coinBalances').doc(uid);
  const txRef = db.collection('coinTransactions').doc();
  const legacyQuery = db.collection('claimedRewards')
    .where('userId', '==', uid)
    .where('rewardId', '==', rewardId)
    .limit(1);

  const newBalance = await db.runTransaction(async (tx) => {
    const claim = await tx.get(claimRef);
    // One-time rewards claimed through the old server copy or the app's own
    // client-side path left a `claimedRewards` doc: honour it.
    const legacy = ONE_TIME.has(rewardId) ? await tx.get(legacyQuery) : null;
    if (claim.exists || (legacy && !legacy.empty)) {
      throw new functions.https.HttpsError('already-exists', 'Reward already claimed');
    }

    const snap = await tx.get(balanceRef);
    const b = snap.data() || {};
    const total = ((b.totalCoins as number | undefined) ?? 0) + coins;
    const ts = admin.firestore.Timestamp.fromDate(now);
    const batches = ((b.coinBatches as unknown[] | undefined) ?? []).slice();
    batches.push({
      batchId: `reward_${rewardId}_${now.getTime()}`,
      initialCoins: coins,
      remainingCoins: coins,
      source: 'reward', // CoinSourceExtension.fromString()
      acquiredDate: ts,
    });

    // Exact shape of grantVerifiedCoinPurchase (coins/index.ts): the client
    // casts userId / lastUpdated non-null. Coins never expire (no expiry field).
    tx.set(balanceRef, {
      userId: uid,
      totalCoins: total,
      earnedCoins: ((b.earnedCoins as number | undefined) ?? 0) + coins,
      purchasedCoins: (b.purchasedCoins as number | undefined) ?? 0,
      giftedCoins: (b.giftedCoins as number | undefined) ?? 0,
      spentCoins: (b.spentCoins as number | undefined) ?? 0,
      coinBatches: batches,
      lastUpdated: ts,
    }, { merge: true });

    tx.set(txRef, {
      userId: uid,
      type: 'credit',
      amount: coins,
      balanceAfter: total,
      reason: REWARD_REASON[rewardId],
      createdAt: ts,
      metadata: { rewardId, period, source: 'reward' },
    });

    tx.create(claimRef, {
      userId: uid,
      rewardId,
      period,
      coins,
      coinTransactionId: txRef.id,
      claimedAt: ts,
    });

    if (ONE_TIME.has(rewardId)) {
      tx.set(db.collection('claimedRewards').doc(), {
        userId: uid,
        rewardId,
        coinAmount: coins,
        claimedAt: ts,
      });
    }
    return total;
  });

  logInfo(`claimReward: ${uid} ${rewardId} (${period}) +${coins}, balance ${newBalance}`);
  return {
    success: true,
    coinsAdded: coins,
    coinsEarned: coins,
    newBalance,
    rewardId,
    rewardType: rewardId,
  };
}

export const claimReward = functions
  .runWith({ memory: '512MB', timeoutSeconds: 60 })
  .https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    try {
      return await claimRewardForUser(uid, data);
    } catch (error) {
      if (error instanceof functions.https.HttpsError) throw error;
      // Never leak internals; the transaction already rolled back.
      functions.logger.error('claimReward failed', { uid, error: String(error) });
      throw new functions.https.HttpsError('internal', 'Could not claim reward');
    }
  });
