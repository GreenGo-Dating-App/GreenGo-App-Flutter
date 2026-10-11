/**
 * Secure server-side REFERRAL redemption (invite-friends programme).
 *
 * Called by the NEW user with the inviter's code. Rules live in
 * ./referralRules.ts:
 *  - Rejects self-referral, a user redeeming more than one code (server-only
 *    single-redemption claim in referral_redemptions/{newUid}) and accounts
 *    older than REDEEM_WINDOW_DAYS.
 *  - The NEW user gets 1 week of BASE membership (hasBaseMembership flag).
 *  - The INVITER earns +50 coins per invitation, capped at 1,000 coins per
 *    calendar month (UTC) via referralMonthlyGrants/{ownerId}_{yyyymm}.
 *  - EVERY invitation counts toward the inviter's lifetime milestones
 *    (5 -> 1 month Silver, 10 -> Gold, 20 -> Platinum), coins capped or not.
 *
 * Counting is server-authoritative and exactly-once: the redemption claim, the
 * inviter's counter in server-only referral_stats/{ownerId}, the monthly cap
 * and the milestone claims are all written in ONE transaction. Two invitations
 * arriving together (e.g. both at count 4) conflict on referral_stats, one is
 * retried, and each milestone lands in exactly one transaction.
 * `referrals/{uid}` (client-readable) only MIRRORS the counters for old app
 * versions; nothing is decided from it.
 */

import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { db, logInfo, logError } from '../shared/utils';
import { grantBaseMembership, grantCoins, grantMembership } from '../shared/grants';
import { monitored } from '../shared/monitoring';
import { lt } from '../shared/i18n';
import { emitNotification } from '../notifications/notifyHelpers';
import {
  INVITEE_BASE_DURATION_MS,
  REFERRER_MONTHLY_CAP,
  ReferralMilestone,
  grantedSet,
  milestonesToGrant,
  referralCoinsFor,
  referralPeriod,
  tierLabel,
} from './referralRules';

interface RedeemReferralRequest {
  code: string;
}

interface RedeemReferralResponse {
  ok: true;
  /** The inviter received coins for this invitation (false when capped). */
  referrerCredited: boolean;
  /** The new user received their 1-week Base membership. */
  membershipGranted: boolean;
}

/** Matches the onboarding flow: a referral is redeemed right after signup. */
const REDEEM_WINDOW_DAYS = 30;

/** Server-only stats doc of an inviter (see firestore rules: owner read-only). */
export const REFERRAL_STATS_COLLECTION = 'referral_stats';

interface ClaimResult {
  ownerId: string;
  invitedCount: number;
  coins: number;
  milestones: ReferralMilestone[];
}

/**
 * Grants each claimed milestone and tells the inviter. A failed grant is kept
 * claimed (it may have partially applied) and recorded in `milestonesFailed`
 * for functions/scripts/backfill-referral-stats.ts to retry.
 */
async function deliverMilestones(ownerId: string, milestones: ReferralMilestone[]): Promise<void> {
  for (const m of milestones) {
    try {
      await grantMembership(ownerId, m.tier, m.durationMs);
    } catch (e) {
      logError(`redeemReferral: milestone ${m.count} grant failed owner=${ownerId}`, e as any);
      await db.collection(REFERRAL_STATS_COLLECTION).doc(ownerId).set({
        milestonesFailed: admin.firestore.FieldValue.arrayUnion(m.count),
      }, { merge: true }).catch(() => undefined);
      continue;
    }
    await notifyMilestone(ownerId, m);
  }
}

export async function notifyMilestone(ownerId: string, m: ReferralMilestone): Promise<void> {
  try {
    await emitNotification({
      recipientId: ownerId,
      type: 'referral_milestone',
      title: lt('srvReferralMilestoneTitle'),
      body: lt('srvReferralMilestoneBody', { count: m.count, tier: tierLabel(m.tier) }),
      data: { type: 'referral_milestone', milestone: String(m.count), tier: m.tier },
    });
  } catch (e) {
    logError('redeemReferral: milestone notification failed', e as any);
  }
}

export const redeemReferral = onCall<RedeemReferralRequest>(
  { memory: '512MiB', timeoutSeconds: 60 },
  monitored('redeemReferral', async (request: CallableRequest<RedeemReferralRequest>): Promise<RedeemReferralResponse> => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'You must be signed in to redeem a referral');
    }
    const newUid = request.auth.uid;

    const raw = request.data?.code;
    if (typeof raw !== 'string' || raw.trim().length === 0) {
      throw new HttpsError('invalid-argument', 'Referral code is required');
    }
    const code = raw.trim().toUpperCase();

    // Security audit C-05: referrals/{uid} is client-writable, so its
    // `redeemedCode` alone was a guard the user could delete and redeem again.
    // The authoritative claim lives in server-only `referral_redemptions/{uid}`,
    // and only accounts created within REDEEM_WINDOW_DAYS may redeem.
    try {
      const authUser = await admin.auth().getUser(newUid);
      const createdMs = Date.parse(authUser.metadata.creationTime);
      if (Number.isFinite(createdMs) &&
          Date.now() - createdMs > REDEEM_WINDOW_DAYS * 24 * 3600 * 1000) {
        throw new HttpsError('failed-precondition', 'Referral codes can only be used by new accounts');
      }
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      logError('redeemReferral: auth lookup failed', e as any);
      throw new HttpsError('internal', 'Could not redeem referral');
    }

    // 1) ONE transaction: claim the single redemption for this new user
    //    (rejects self-referral and a second code), count the invitation in
    //    the inviter's server-only stats, apply the monthly coin cap and claim
    //    any milestone just reached.
    let claim: ClaimResult;
    try {
      claim = await db.runTransaction(async (tx): Promise<ClaimResult> => {
        const claimRef = db.collection('referral_redemptions').doc(newUid);
        const claimSnap = await tx.get(claimRef);
        if (claimSnap.exists) {
          throw new HttpsError('already-exists', 'You have already used a referral code');
        }
        const codeSnap = await tx.get(db.collection('referral_codes').doc(code));
        if (!codeSnap.exists) {
          throw new HttpsError('not-found', 'Referral code not found');
        }
        const owner = (codeSnap.data() as any).ownerId as string;
        if (!owner || owner === newUid) {
          throw new HttpsError('failed-precondition', 'You cannot use your own referral code');
        }
        const myRef = db.collection('referrals').doc(newUid);
        const mySnap = await tx.get(myRef);
        const existing = mySnap.exists ? (mySnap.data() as any).redeemedCode : null;
        if (existing) {
          throw new HttpsError('already-exists', 'You have already used a referral code');
        }

        const now = new Date();
        const period = referralPeriod(now);
        const capRef = db.collection('referralMonthlyGrants').doc(`${owner}_${period}`);
        const statsRef = db.collection(REFERRAL_STATS_COLLECTION).doc(owner);
        const [capSnap, statsSnap] = await Promise.all([tx.get(capRef), tx.get(statsRef)]);

        const capAlready = capSnap.exists ? Number((capSnap.data() as any).coins) || 0 : 0;
        const coins = referralCoinsFor(capAlready);
        const stats = statsSnap.exists ? (statsSnap.data() as any) : {};
        const invitedCount = (Number(stats.invitedCount) || 0) + 1;
        const granted = grantedSet(stats.milestonesGranted);
        const milestones = milestonesToGrant(invitedCount, granted);
        for (const m of milestones) granted.add(m.count);

        const ts = admin.firestore.FieldValue.serverTimestamp();
        tx.set(myRef, { redeemedCode: code, redeemedFrom: owner, redeemedAt: ts }, { merge: true });
        tx.create(claimRef, {
          code,
          ownerId: owner,
          redeemedAt: ts,
          coinsAwarded: coins,
          inviteNumber: invitedCount,
        });
        tx.set(statsRef, {
          ownerId: owner,
          invitedCount,
          coinsEarned: (Number(stats.coinsEarned) || 0) + coins,
          milestonesGranted: [...granted].sort((a, b) => a - b),
          updatedAt: ts,
        }, { merge: true });
        if (coins > 0) {
          tx.set(capRef, { ownerId: owner, period, coins: capAlready + coins, updatedAt: ts }, { merge: true });
        }
        return { ownerId: owner, invitedCount, coins, milestones };
      });
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      logError('redeemReferral: validation/claim failed', e as any);
      throw new HttpsError('internal', 'Could not redeem referral');
    }
    const { ownerId, invitedCount, coins, milestones } = claim;

    // 2) The NEW user receives 1 week of Base membership.
    let membershipGranted = false;
    try {
      await grantBaseMembership(newUid, INVITEE_BASE_DURATION_MS, 'referral');
      membershipGranted = true;
      await emitNotification({
        recipientId: newUid,
        type: 'referral_welcome',
        title: lt('srvReferralWelcomeTitle'),
        body: lt('srvReferralWelcomeBody'),
        data: { type: 'referral_welcome' },
      });
    } catch (e) {
      logError('redeemReferral: invitee Base grant/notification failed', e as any);
    }

    // 3) The INVITER: coins (when under the monthly cap) + display mirror.
    let referrerCredited = false;
    try {
      if (coins > 0) {
        await grantCoins(ownerId, coins, 'reward', 'referralBonus', { referredUser: newUid, code });
        referrerCredited = true;
      }
      // Display-only mirror for app versions that read referrals/{uid}.
      await db.collection('referrals').doc(ownerId).set({
        invitedCount: admin.firestore.FieldValue.increment(1),
        coinsEarned: admin.firestore.FieldValue.increment(coins),
      }, { merge: true });
      await emitNotification({
        recipientId: ownerId,
        type: 'referral_reward',
        title: lt('srvReferralFriendJoinedTitle'),
        body: coins > 0
          ? lt('srvReferralCoinsBody', { amount: coins })
          : lt('srvReferralCapReachedBody', { cap: REFERRER_MONTHLY_CAP }),
        data: { type: 'referral_reward', amount: String(coins), invitedCount: String(invitedCount) },
      });
    } catch (e) {
      logError('redeemReferral: referrer credit failed', e as any);
    }

    // 4) Milestones claimed in the transaction above.
    if (milestones.length) await deliverMilestones(ownerId, milestones);

    logInfo(`redeemReferral newUid=${newUid} owner=${ownerId} count=${invitedCount} base=${membershipGranted} coins=${coins} milestones=${milestones.map((m) => m.count).join(',')}`);
    return { ok: true, referrerCredited, membershipGranted };
  }),
);
