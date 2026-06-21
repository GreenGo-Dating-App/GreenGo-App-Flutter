/**
 * Lightweight coupon validation — used by the registration screen's "Apply"
 * button BEFORE an account exists (so it can't redeem; it only checks the code
 * is real and currently usable). Redemption still happens after signup via
 * redeemCoupon / applySignupGrants, which re-validate authoritatively.
 *
 * Public (no auth) on purpose: at registration there is no signed-in user.
 * Coupon codes are not secrets and redemption still requires an account, so
 * exposing validity here is low-risk.
 */

import { onCall, CallableRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { db, logInfo } from '../shared/utils';
import { effectiveGrants, summariseGrants } from './grants';
import { monitored } from '../shared/monitoring';

interface ValidateCouponRequest {
  code: string;
}

interface ValidateCouponResponse {
  valid: boolean;
  reason?: string; // 'empty' | 'not-found' | 'disabled' | 'expired' | 'max' | 'misconfigured'
  grantSummary?: string;
}

export const validateCoupon = onCall<ValidateCouponRequest>(
  { memory: '512MiB', timeoutSeconds: 15 },
  monitored("validateCoupon", async (request: CallableRequest<ValidateCouponRequest>): Promise<ValidateCouponResponse> => {
    const raw = request.data?.code;
    if (typeof raw !== 'string' || raw.trim().length === 0) {
      return { valid: false, reason: 'empty' };
    }
    const code = raw.trim().toUpperCase();

    const snap = await db.collection('coupons').where('code', '==', code).limit(1).get();
    if (snap.empty) return { valid: false, reason: 'not-found' };

    const c = snap.docs[0].data() as any;
    if (c.disabled) return { valid: false, reason: 'disabled' };

    const now = admin.firestore.Timestamp.now();
    if (c.expiresAt && (c.expiresAt as admin.firestore.Timestamp).toDate() <= now.toDate()) {
      return { valid: false, reason: 'expired' };
    }
    if (c.maxRedemptions != null && (c.redemptionsCount || 0) >= c.maxRedemptions) {
      return { valid: false, reason: 'max' };
    }

    const grants = effectiveGrants(c);
    if (grants.length === 0) return { valid: false, reason: 'misconfigured' };

    logInfo(`validateCoupon: ${code} is valid`);
    return { valid: true, grantSummary: summariseGrants(grants) };
  }),
);
