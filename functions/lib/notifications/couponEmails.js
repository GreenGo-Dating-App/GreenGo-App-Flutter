"use strict";
/**
 * Coupon-redemption email notifier.
 *
 * Sends the `coupon_redeemed` Brevo template after a successful
 * redemption. Errors are swallowed by the caller (redeemCoupon)
 * because the redemption itself has already committed — email is
 * best-effort.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendCouponRedeemedEmail = sendCouponRedeemedEmail;
const utils_1 = require("../shared/utils");
const brevoEmailService_1 = require("./brevoEmailService");
async function sendCouponRedeemedEmail(uid, payload) {
    try {
        const variables = {
            couponCode: payload.couponCode,
            grantSummary: payload.grantSummary,
        };
        if (payload.newEndDate) {
            // Human-friendly ISO date (YYYY-MM-DD) is good enough for the template.
            variables.newEndDate = payload.newEndDate.slice(0, 10);
        }
        await (0, brevoEmailService_1.sendBrevoEmail)({
            userId: uid,
            trigger: 'coupon_redeemed',
            variables,
        });
        (0, utils_1.logInfo)(`sendCouponRedeemedEmail uid=${uid} code=${payload.couponCode}`);
    }
    catch (err) {
        (0, utils_1.logError)(`sendCouponRedeemedEmail failed uid=${uid}`, err);
        // Swallow — caller treats this as non-fatal.
    }
}
//# sourceMappingURL=couponEmails.js.map