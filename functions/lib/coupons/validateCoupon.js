"use strict";
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
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateCoupon = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("../shared/utils");
const grants_1 = require("./grants");
const monitoring_1 = require("../shared/monitoring");
exports.validateCoupon = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 15 }, (0, monitoring_1.monitored)("validateCoupon", async (request) => {
    var _a;
    const raw = (_a = request.data) === null || _a === void 0 ? void 0 : _a.code;
    if (typeof raw !== 'string' || raw.trim().length === 0) {
        return { valid: false, reason: 'empty' };
    }
    const code = raw.trim().toUpperCase();
    const snap = await utils_1.db.collection('coupons').where('code', '==', code).limit(1).get();
    if (snap.empty)
        return { valid: false, reason: 'not-found' };
    const c = snap.docs[0].data();
    if (c.disabled)
        return { valid: false, reason: 'disabled' };
    const now = admin.firestore.Timestamp.now();
    if (c.expiresAt && c.expiresAt.toDate() <= now.toDate()) {
        return { valid: false, reason: 'expired' };
    }
    if (c.maxRedemptions != null && (c.redemptionsCount || 0) >= c.maxRedemptions) {
        return { valid: false, reason: 'max' };
    }
    const grants = (0, grants_1.effectiveGrants)(c);
    if (grants.length === 0)
        return { valid: false, reason: 'misconfigured' };
    (0, utils_1.logInfo)(`validateCoupon: ${code} is valid`);
    return { valid: true, grantSummary: (0, grants_1.summariseGrants)(grants) };
}));
//# sourceMappingURL=validateCoupon.js.map