/**
 * Coupon-redemption email notifier.
 *
 * Sends the `coupon_redeemed` Brevo template after a successful
 * redemption. Errors are swallowed by the caller (redeemCoupon)
 * because the redemption itself has already committed — email is
 * best-effort.
 */

import { logInfo, logError } from '../shared/utils';
import { sendBrevoEmail } from './brevoEmailService';

export interface CouponEmailPayload {
  couponCode: string;
  grantSummary: string;
  newEndDate?: string;
}

export async function sendCouponRedeemedEmail(
  uid: string,
  payload: CouponEmailPayload,
): Promise<void> {
  try {
    const variables: Record<string, any> = {
      couponCode: payload.couponCode,
      grantSummary: payload.grantSummary,
    };
    if (payload.newEndDate) {
      // Human-friendly ISO date (YYYY-MM-DD) is good enough for the template.
      variables.newEndDate = payload.newEndDate.slice(0, 10);
    }
    await sendBrevoEmail({
      userId: uid,
      trigger: 'coupon_redeemed',
      variables,
    });
    logInfo(`sendCouponRedeemedEmail uid=${uid} code=${payload.couponCode}`);
  } catch (err) {
    logError(`sendCouponRedeemedEmail failed uid=${uid}`, err);
    // Swallow — caller treats this as non-fatal.
  }
}
