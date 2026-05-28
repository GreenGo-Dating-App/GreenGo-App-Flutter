/**
 * Secure server-side coupon redemption.
 *
 * Atomically:
 *  - Looks up the coupon by code.
 *  - Validates: not disabled, not expired, redemptions left, email gate (if any),
 *    not already redeemed by this user.
 *  - Applies the grant (membership tier extension, base membership flag, or coins)
 *    using the never-downgrade extension rule.
 *  - Writes the redemption record and increments the counter.
 *
 * All in a single Firestore transaction so concurrent attempts can't over-redeem
 * a capped coupon or double-grant the same user.
 */

import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { db, logInfo, logError } from '../shared/utils';
import { TierName, computeMembershipExtension } from '../shared/grants';

const COIN_EXPIRATION_DAYS = 365;

type CouponType = 'membership' | 'base_membership' | 'coins';

interface CouponDoc {
  code: string;
  type: CouponType;
  tier: TierName | null;
  coinAmount: number | null;
  durationDays: number;
  maxRedemptions: number | null;
  redemptionsCount: number;
  expiresAt: admin.firestore.Timestamp | null;
  allowedEmail: string | null;
  disabled: boolean;
}

interface RedeemCouponRequest {
  code: string;
}

interface RedeemCouponResponse {
  ok: true;
  type: CouponType;
  tier?: TierName;
  coinAmount?: number;
  durationDays: number;
  effectiveTier?: TierName;
  newEndDate?: string;
  grantSummary: string;
}

export const redeemCoupon = onCall<RedeemCouponRequest>(
  { memory: '256MiB', timeoutSeconds: 30 },
  async (request: CallableRequest<RedeemCouponRequest>): Promise<RedeemCouponResponse> => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'You must be signed in to redeem a coupon');
    }
    const uid = request.auth.uid;
    const userEmail: string | null = request.auth.token.email
      ? String(request.auth.token.email).toLowerCase()
      : null;

    const raw = request.data?.code;
    if (typeof raw !== 'string' || raw.trim().length === 0) {
      throw new HttpsError('invalid-argument', 'Coupon code is required');
    }
    const code = raw.trim().toUpperCase();

    try {
      const result = await db.runTransaction(async (tx) => {
        // ── Look up coupon by code (case-insensitive — stored uppercase) ──
        const couponQuery = await tx.get(
          db.collection('coupons').where('code', '==', code).limit(1),
        );
        if (couponQuery.empty) {
          throw new HttpsError('not-found', 'Coupon code not found');
        }
        const couponRef = couponQuery.docs[0].ref;
        const coupon = couponQuery.docs[0].data() as CouponDoc;

        // ── Validate coupon state ──
        if (coupon.disabled) {
          throw new HttpsError('failed-precondition', 'This coupon is no longer active');
        }
        const now = admin.firestore.Timestamp.now();
        if (coupon.expiresAt && coupon.expiresAt.toDate() <= now.toDate()) {
          throw new HttpsError('failed-precondition', 'This coupon has expired');
        }
        if (
          coupon.maxRedemptions !== null &&
          coupon.maxRedemptions !== undefined &&
          (coupon.redemptionsCount || 0) >= coupon.maxRedemptions
        ) {
          throw new HttpsError('failed-precondition', 'This coupon has reached its redemption limit');
        }
        if (coupon.allowedEmail) {
          const allowed = coupon.allowedEmail.toLowerCase();
          if (!userEmail || userEmail !== allowed) {
            throw new HttpsError('permission-denied', 'This coupon is restricted to a different account');
          }
        }

        // ── Reject if this user already redeemed this coupon ──
        const redemptionRef = couponRef.collection('redemptions').doc(uid);
        const existingRedemption = await tx.get(redemptionRef);
        if (existingRedemption.exists) {
          throw new HttpsError('already-exists', 'You have already redeemed this coupon');
        }

        const durationMs = coupon.durationDays * 24 * 60 * 60 * 1000;
        const profileRef = db.collection('profiles').doc(uid);
        const userRef = db.collection('users').doc(uid);
        const balanceRef = db.collection('coinBalances').doc(uid);

        let grantSummary = '';
        const response: RedeemCouponResponse = {
          ok: true,
          type: coupon.type,
          durationDays: coupon.durationDays,
          grantSummary: '',
        };

        if (coupon.type === 'membership') {
          if (!coupon.tier) {
            throw new HttpsError('failed-precondition', 'Coupon is misconfigured: missing tier');
          }
          // Read profile inside the transaction (all reads must come before writes)
          const profileSnap = await tx.get(profileRef);
          const profileData = profileSnap.data() || {};
          const currentTier = (profileData.membershipTier as string) || 'BASIC';
          const currentEndTs = profileData.membershipEndDate as admin.firestore.Timestamp | undefined;
          const currentEndDate = currentEndTs ? currentEndTs.toDate() : null;

          const extension = computeMembershipExtension(
            currentTier,
            currentEndDate,
            coupon.tier,
            durationMs,
            now.toDate(),
          );

          tx.set(
            profileRef,
            {
              membershipTier: extension.effectiveTier,
              membershipStartDate: now,
              membershipEndDate: extension.newEndTimestamp,
              updatedAt: now,
            },
            { merge: true },
          );
          tx.set(
            userRef,
            {
              subscriptionTier: extension.effectiveTier,
              membershipEndDate: extension.newEndTimestamp,
              updatedAt: now,
            },
            { merge: true },
          );

          grantSummary = `${extension.effectiveTier} +${coupon.durationDays}d`;
          response.tier = coupon.tier;
          response.effectiveTier = extension.effectiveTier;
          response.newEndDate = extension.newEndDate.toISOString();
        } else if (coupon.type === 'base_membership') {
          const profileSnap = await tx.get(profileRef);
          const profileData = profileSnap.data() || {};
          const currentEndTs = profileData.baseMembershipEndDate as admin.firestore.Timestamp | undefined;
          const currentEndDate = currentEndTs ? currentEndTs.toDate() : null;
          const baseStart =
            currentEndDate && currentEndDate > now.toDate() ? currentEndDate : now.toDate();
          const newEndDate = new Date(baseStart.getTime() + durationMs);
          const newEndTimestamp = admin.firestore.Timestamp.fromDate(newEndDate);

          tx.set(
            profileRef,
            {
              hasBaseMembership: true,
              baseMembershipEndDate: newEndTimestamp,
              updatedAt: now,
            },
            { merge: true },
          );

          grantSummary = `BASE +${coupon.durationDays}d`;
          response.newEndDate = newEndDate.toISOString();
        } else if (coupon.type === 'coins') {
          const amount = coupon.coinAmount || 0;
          if (amount <= 0) {
            throw new HttpsError('failed-precondition', 'Coupon is misconfigured: missing coin amount');
          }
          const balanceSnap = await tx.get(balanceRef);
          let currentBalance = 0;
          let earnedCoins = 0;
          let purchasedCoins = 0;
          let giftedCoins = 0;
          let spentCoins = 0;
          let coinBatches: any[] = [];
          if (balanceSnap.exists) {
            const data = balanceSnap.data() as any;
            currentBalance = data.totalCoins || 0;
            earnedCoins = data.earnedCoins || 0;
            purchasedCoins = data.purchasedCoins || 0;
            giftedCoins = data.giftedCoins || 0;
            spentCoins = data.spentCoins || 0;
            coinBatches = data.coinBatches || [];
          }
          const expirationDate = new Date();
          expirationDate.setDate(expirationDate.getDate() + COIN_EXPIRATION_DAYS);
          const batchId = db.collection('temp').doc().id;
          coinBatches.push({
            batchId,
            initialCoins: amount,
            remainingCoins: amount,
            source: 'coupon',
            acquiredDate: now,
            expirationDate: admin.firestore.Timestamp.fromDate(expirationDate),
          });

          tx.set(
            balanceRef,
            {
              userId: uid,
              totalCoins: currentBalance + amount,
              earnedCoins,
              purchasedCoins,
              giftedCoins,
              spentCoins,
              lastUpdated: now,
              coinBatches,
            },
            { merge: true },
          );

          const transactionRef = db.collection('coinTransactions').doc();
          tx.set(transactionRef, {
            userId: uid,
            type: 'credit',
            amount,
            balanceAfter: currentBalance + amount,
            reason: 'coupon',
            metadata: { couponId: couponRef.id, couponCode: coupon.code, source: 'coupon' },
            createdAt: now,
          });

          grantSummary = `+${amount} coins`;
          response.coinAmount = amount;
        } else {
          throw new HttpsError('failed-precondition', `Unknown coupon type: ${coupon.type}`);
        }

        // ── Write redemption record + increment counter ──
        tx.set(redemptionRef, {
          redeemedAt: now,
          userEmail: userEmail,
          grantSummary,
          couponCode: coupon.code,
        });
        tx.update(couponRef, {
          redemptionsCount: admin.firestore.FieldValue.increment(1),
          lastRedeemedAt: now,
        });

        response.grantSummary = grantSummary;
        logInfo(`redeemCoupon uid=${uid} couponId=${couponRef.id} code=${coupon.code} grant=${grantSummary}`);
        return response;
      });

      // Best-effort post-commit email — non-fatal.
      try {
        const { sendCouponRedeemedEmail } = await import('../notifications/couponEmails');
        await sendCouponRedeemedEmail(uid, {
          couponCode: code,
          grantSummary: result.grantSummary,
          newEndDate: result.newEndDate,
        });
      } catch (emailErr) {
        logError(`redeemCoupon: email notify failed for uid=${uid}`, emailErr);
      }

      return result;
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      logError(`redeemCoupon failed uid=${uid}`, err);
      throw new HttpsError('internal', 'Failed to redeem coupon');
    }
  },
);
