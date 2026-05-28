/**
 * Coupon-redemption email notifier. Stub — wired to Brevo in the
 * follow-up "coupon_redeemed Brevo trigger" commit.
 */

import { logInfo } from '../shared/utils';

export interface CouponEmailPayload {
  couponCode: string;
  grantSummary: string;
  newEndDate?: string;
}

export async function sendCouponRedeemedEmail(
  uid: string,
  payload: CouponEmailPayload,
): Promise<void> {
  logInfo(
    `sendCouponRedeemedEmail (stub) uid=${uid} code=${payload.couponCode} grant=${payload.grantSummary}`,
  );
}
