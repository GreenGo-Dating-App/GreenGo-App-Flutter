/**
 * Secure server-side REFERRAL redemption.
 *
 * Called (by the new user) after onboarding. Given the referrer's code:
 *  - Resolves the code owner; rejects self-referral and a user redeeming more
 *    than one code (single-redemption guard on referrals/{newUid}).
 *  - ALWAYS grants the NEW user 1 month of Platinum.
 *  - Credits the REFERRER +100 coins, enforcing a 1000-coins/month cap per
 *    referrer via referralMonthlyGrants/{ownerId}_{yyyymm}.
 *
 * The single-redemption claim and the monthly-cap increment are each done in a
 * transaction so concurrent redemptions can't double-grant or exceed the cap.
 */

import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { db, logInfo, logError } from '../shared/utils';
import { grantCoins, grantMembership } from '../shared/grants';
import { monitored } from '../shared/monitoring';

interface RedeemReferralRequest {
  code: string;
}

interface RedeemReferralResponse {
  ok: true;
  referrerCredited: boolean;
  membershipGranted: boolean;
}

const REFERRER_COIN_REWARD = 100;
const REFERRER_MONTHLY_CAP = 1000;
const PLATINUM_DURATION_MS = 30 * 24 * 60 * 60 * 1000; // 1 month

export const redeemReferral = onCall<RedeemReferralRequest>(
  { memory: '256MiB', timeoutSeconds: 30 },
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

    // 1) Resolve the referrer + atomically claim the single redemption for this
    //    new user (also rejects self-referral and re-use of a second code).
    let ownerId: string;
    try {
      ownerId = await db.runTransaction(async (tx) => {
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
        tx.set(myRef, {
          redeemedCode: code,
          redeemedFrom: owner,
          redeemedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        return owner;
      });
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      logError('redeemReferral: validation/claim failed', e as any);
      throw new HttpsError('internal', 'Could not redeem referral');
    }

    // 2) The NEW user always receives 1 month of Platinum.
    let membershipGranted = false;
    try {
      await grantMembership(newUid, 'PLATINUM', PLATINUM_DURATION_MS);
      membershipGranted = true;
    } catch (e) {
      logError('redeemReferral: grantMembership failed', e as any);
    }

    // 3) The REFERRER earns +100 coins, capped at 1000/month.
    let referrerCredited = false;
    try {
      const now = new Date();
      const period = `${now.getUTCFullYear()}${String(now.getUTCMonth() + 1).padStart(2, '0')}`;
      const capRef = db.collection('referralMonthlyGrants').doc(`${ownerId}_${period}`);

      const underCap = await db.runTransaction(async (tx) => {
        const snap = await tx.get(capRef);
        const already = snap.exists ? ((snap.data() as any).coins || 0) : 0;
        if (already + REFERRER_COIN_REWARD > REFERRER_MONTHLY_CAP) {
          return false;
        }
        tx.set(capRef, {
          ownerId,
          period,
          coins: already + REFERRER_COIN_REWARD,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        return true;
      });

      if (underCap) {
        await grantCoins(ownerId, REFERRER_COIN_REWARD, 'reward', 'referralBonus', {
          referredUser: newUid,
          code,
        });
        await db.collection('referrals').doc(ownerId).set({
          invitedCount: admin.firestore.FieldValue.increment(1),
          coinsEarned: admin.firestore.FieldValue.increment(REFERRER_COIN_REWARD),
        }, { merge: true });
        referrerCredited = true;
      }
    } catch (e) {
      logError('redeemReferral: referrer credit failed', e as any);
    }

    logInfo(`redeemReferral newUid=${newUid} owner=${ownerId} membership=${membershipGranted} coins=${referrerCredited}`);
    return { ok: true, referrerCredited, membershipGranted };
  }),
);
