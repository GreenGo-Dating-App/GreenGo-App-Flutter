/**
 * Secure server-side coupon redemption.
 *
 * Atomically:
 *  - Looks up the coupon by code.
 *  - Validates: not disabled, not expired, redemptions left, email gate (if any),
 *    not already redeemed by this user.
 *  - Applies every grant in the coupon (a coupon can carry coins + base +
 *    a tier as a bundle) using the never-downgrade extension rule per grant.
 *  - Writes the redemption record and increments the per-coupon counter
 *    (once per redemption, regardless of how many grants are in the bundle).
 *
 * All in a single Firestore transaction so concurrent attempts can't over-
 * redeem a capped coupon or double-grant the same user.
 */

import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { db, logInfo, logError } from '../shared/utils';
import { TierName, computeMembershipExtension } from '../shared/grants';
import { Grant, effectiveGrants, summariseGrants } from './grants';
import { monitored } from '../shared/monitoring';

const COIN_EXPIRATION_DAYS = 365;

interface RedeemCouponRequest {
  code: string;
}

interface RedeemCouponResponse {
  ok: true;
  type: string; // legacy field — derived from the first grant for older clients
  tier?: TierName;
  coinAmount?: number;
  durationDays: number;
  effectiveTier?: TierName;
  newEndDate?: string;
  grantSummary: string;
  grants: Grant[];
}

export const redeemCoupon = onCall<RedeemCouponRequest>(
  { memory: '512MiB', timeoutSeconds: 30 },
  monitored("redeemCoupon", async (request: CallableRequest<RedeemCouponRequest>): Promise<RedeemCouponResponse> => {
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
        const coupon = couponQuery.docs[0].data() as any;

        // ── Validate coupon state ──
        if (coupon.disabled) {
          throw new HttpsError('failed-precondition', 'This coupon is no longer active');
        }
        const now = admin.firestore.Timestamp.now();
        if (coupon.expiresAt && (coupon.expiresAt as admin.firestore.Timestamp).toDate() <= now.toDate()) {
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
          const allowed = String(coupon.allowedEmail).toLowerCase();
          if (!userEmail || userEmail !== allowed) {
            throw new HttpsError('permission-denied', 'This coupon is restricted to a different account');
          }
        }

        const grants = effectiveGrants(coupon);
        if (grants.length === 0) {
          throw new HttpsError('failed-precondition', 'Coupon is misconfigured: no grants');
        }

        // ── Reject if this user already redeemed this coupon ──
        const redemptionRef = couponRef.collection('redemptions').doc(uid);
        const profileRef = db.collection('profiles').doc(uid);
        const userRef = db.collection('users').doc(uid);
        const balanceRef = db.collection('coinBalances').doc(uid);

        // ── All reads up-front (Firestore tx rule) ──
        const needsProfile = grants.some(
          (g) => g.kind === 'membership' || g.kind === 'base_membership',
        );
        const needsBalance = grants.some((g) => g.kind === 'coins');

        const existingRedemption = await tx.get(redemptionRef);
        if (existingRedemption.exists) {
          throw new HttpsError('already-exists', 'You have already redeemed this coupon');
        }

        const profileSnap = needsProfile ? await tx.get(profileRef) : null;
        const balanceSnap = needsBalance ? await tx.get(balanceRef) : null;

        // ── Accumulate updates across the grant list ──
        const profileUpdate: Record<string, any> = {};
        const userUpdate: Record<string, any> = {};
        let runningTier: string = (profileSnap?.data()?.membershipTier as string) || 'BASIC';
        let runningTierEnd: Date | null =
          (profileSnap?.data()?.membershipEndDate as admin.firestore.Timestamp | undefined)?.toDate() ??
          null;
        let runningBaseEnd: Date | null =
          (profileSnap?.data()?.baseMembershipEndDate as admin.firestore.Timestamp | undefined)?.toDate() ??
          null;

        const balanceData = balanceSnap?.exists ? (balanceSnap.data() as any) : {};
        let runningBalance: number = (balanceData?.totalCoins as number) || 0;
        const coinBatches: any[] = (balanceData?.coinBatches as any[]) || [];
        let totalCoinsGranted = 0;
        let firstMembershipExt: { effectiveTier: TierName; newEndDate: Date } | null = null;
        let firstCoinAmount: number | undefined;
        let firstDurationDays: number | undefined;
        let firstTier: TierName | undefined;

        for (const g of grants) {
          if (g.kind === 'membership' && g.tier && g.durationDays) {
            const ext = computeMembershipExtension(
              runningTier,
              runningTierEnd,
              g.tier,
              g.durationDays * 24 * 60 * 60 * 1000,
              now.toDate(),
            );
            runningTier = ext.effectiveTier;
            runningTierEnd = ext.newEndDate;
            profileUpdate.membershipTier = ext.effectiveTier;
            profileUpdate.membershipStartDate = now;
            profileUpdate.membershipEndDate = ext.newEndTimestamp;
            userUpdate.subscriptionTier = ext.effectiveTier;
            userUpdate.membershipEndDate = ext.newEndTimestamp;
            if (!firstMembershipExt) {
              firstMembershipExt = { effectiveTier: ext.effectiveTier, newEndDate: ext.newEndDate };
              firstTier = g.tier;
              firstDurationDays ??= g.durationDays;
            }
          } else if (g.kind === 'base_membership' && g.durationDays) {
            const baseStart =
              runningBaseEnd && runningBaseEnd > now.toDate() ? runningBaseEnd : now.toDate();
            const newBaseEnd = new Date(baseStart.getTime() + g.durationDays * 24 * 60 * 60 * 1000);
            runningBaseEnd = newBaseEnd;
            profileUpdate.hasBaseMembership = true;
            profileUpdate.baseMembershipEndDate = admin.firestore.Timestamp.fromDate(newBaseEnd);
            firstDurationDays ??= g.durationDays;
          } else if (g.kind === 'coins' && g.coinAmount) {
            const amount = g.coinAmount;
            const expirationDate = new Date();
            expirationDate.setDate(expirationDate.getDate() + COIN_EXPIRATION_DAYS);
            coinBatches.push({
              batchId: db.collection('temp').doc().id,
              initialCoins: amount,
              remainingCoins: amount,
              source: 'coupon',
              acquiredDate: now,
              expirationDate: admin.firestore.Timestamp.fromDate(expirationDate),
            });
            runningBalance += amount;
            totalCoinsGranted += amount;
            firstCoinAmount ??= amount;
          } else {
            throw new HttpsError(
              'failed-precondition',
              `Coupon is misconfigured: invalid grant ${JSON.stringify(g)}`,
            );
          }
        }

        // ── Write profile + user (single set per ref) ──
        if (Object.keys(profileUpdate).length > 0) {
          profileUpdate.updatedAt = now;
          tx.set(profileRef, profileUpdate, { merge: true });
        }
        if (Object.keys(userUpdate).length > 0) {
          userUpdate.updatedAt = now;
          tx.set(userRef, userUpdate, { merge: true });
        }

        // ── Write coin balance + a single aggregate transaction record ──
        if (totalCoinsGranted > 0) {
          tx.set(
            balanceRef,
            {
              userId: uid,
              totalCoins: runningBalance,
              earnedCoins: balanceData?.earnedCoins || 0,
              purchasedCoins: balanceData?.purchasedCoins || 0,
              giftedCoins: balanceData?.giftedCoins || 0,
              spentCoins: balanceData?.spentCoins || 0,
              lastUpdated: now,
              coinBatches,
            },
            { merge: true },
          );
          const txnRef = db.collection('coinTransactions').doc();
          tx.set(txnRef, {
            userId: uid,
            type: 'credit',
            amount: totalCoinsGranted,
            balanceAfter: runningBalance,
            reason: 'coupon',
            metadata: { couponId: couponRef.id, couponCode: coupon.code, source: 'coupon' },
            createdAt: now,
          });
        }

        const grantSummary = summariseGrants(grants);

        // ── Write redemption record + bump counter (one per coupon redemption) ──
        tx.set(redemptionRef, {
          redeemedAt: now,
          userEmail,
          grantSummary,
          couponCode: coupon.code,
        });
        tx.update(couponRef, {
          redemptionsCount: admin.firestore.FieldValue.increment(1),
          lastRedeemedAt: now,
        });

        // ── Build backward-compatible response ──
        const response: RedeemCouponResponse = {
          ok: true,
          type: (coupon.type as string) || grants[0].kind,
          durationDays: firstDurationDays ?? 0,
          grantSummary,
          grants,
        };
        if (firstTier) response.tier = firstTier;
        if (firstCoinAmount !== undefined) response.coinAmount = firstCoinAmount;
        if (firstMembershipExt) {
          response.effectiveTier = firstMembershipExt.effectiveTier;
          response.newEndDate = firstMembershipExt.newEndDate.toISOString();
        }

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
  }),
);
