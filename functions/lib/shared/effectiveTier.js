"use strict";
/**
 * THE single server-side rule for "which membership tier is this user entitled
 * to right now". Mirrors the client's `lib/core/services/effective_tier.dart`.
 *
 * Source of truth is `profiles/{uid}`:
 *   - `membershipTier`    'PLATINUM' | 'GOLD' | 'SILVER' | 'BASIC' | 'FREE' | 'TEST'
 *   - `membershipEndDate` when the paid tier stops
 *   - `hasBaseMembership` + `baseMembershipEndDate`: the SEPARATE Base plan
 *
 * Mirrors (`users/{uid}.subscriptionTier`, `memberships/*`, `subscriptions/*`)
 * drift, and `memberships/*` is client-writable, so NO server decision may be
 * based on them.
 *
 * Rules:
 *   - TEST stays TEST (internal testers).
 *   - Admins (`profiles.isAdmin === true`, which the rules forbid the owner to
 *     set) keep their stored SILVER/GOLD/PLATINUM regardless of end date.
 *   - SILVER / GOLD / PLATINUM are active only while `membershipEndDate` is
 *     after `now`. A MISSING end date means NOT active: no server writer grants
 *     a paid tier without an end date (audited: grants.ts, redeemCoupon.ts,
 *     applySignupGrants.ts, redeemReferral.ts, grantEntitlement.ts,
 *     stripeCheckout.ts, subscription/index.ts, storeNotifications.ts all
 *     write one). There is deliberately no "lifetime" flag: any new profile
 *     field would be client-writable under the current profile rules.
 *   - 'BASIC' / 'BASE' / 'FREE' / unknown → FREE. Base is tracked by
 *     [isBaseMembershipActive], never by the tier.
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
exports.USERS_FREE_TIER = exports.BASE_PRODUCT_IDS = exports.EFFECTIVE_TIER_RANK = exports.LEGACY_BASIC_STORED_VALUES = exports.PAID_TIER_STORED_VALUES = exports.PAID_TIERS = void 0;
exports.isPaidTier = isPaidTier;
exports.normalizeStoredTier = normalizeStoredTier;
exports.tierDateFromValue = tierDateFromValue;
exports.isProfileAdmin = isProfileAdmin;
exports.effectiveTier = effectiveTier;
exports.hasActivePaidTier = hasActivePaidTier;
exports.isBaseMembershipActive = isBaseMembershipActive;
exports.tierRank = tierRank;
exports.isBaseProductId = isBaseProductId;
const admin = __importStar(require("firebase-admin"));
exports.PAID_TIERS = ['SILVER', 'GOLD', 'PLATINUM'];
/** Stored spellings that mean a paid tier (queries must match raw values). */
exports.PAID_TIER_STORED_VALUES = [
    'SILVER', 'GOLD', 'PLATINUM', 'silver', 'gold', 'platinum',
];
/** Stored spellings of the legacy 'BASIC' tier (read by the client as SILVER). */
exports.LEGACY_BASIC_STORED_VALUES = ['BASIC', 'basic', 'BASE', 'base'];
/** Rank used for "never downgrade an active higher tier". FREE/TEST = 0. */
exports.EFFECTIVE_TIER_RANK = {
    FREE: 0,
    SILVER: 1,
    GOLD: 2,
    PLATINUM: 3,
};
/** Base-membership product ids (canonical, iOS-prefixed). */
exports.BASE_PRODUCT_IDS = [
    'greengo_base_membership',
    'subscription_greengo_base_membership',
];
/** `users/{uid}.subscriptionTier` value written when a paid tier ends. */
exports.USERS_FREE_TIER = 'free';
function isPaidTier(tier) {
    return typeof tier === 'string' && exports.PAID_TIERS.includes(tier.toUpperCase());
}
/** Normalises a stored tier string to its canonical upper-case form. */
function normalizeStoredTier(raw) {
    const v = typeof raw === 'string' ? raw.trim().toUpperCase() : '';
    switch (v) {
        case 'SILVER':
        case 'GOLD':
        case 'PLATINUM':
        case 'TEST':
            return v;
        case 'BASIC':
        case 'BASE':
            return 'BASIC';
        default:
            return 'FREE';
    }
}
/** Firestore value (Timestamp / Date / millis / ISO string / {_seconds}) → Date. */
function tierDateFromValue(v) {
    var _a;
    if (v === null || v === undefined)
        return null;
    if (v instanceof admin.firestore.Timestamp)
        return v.toDate();
    if (v instanceof Date)
        return isNaN(v.getTime()) ? null : v;
    if (typeof v === 'number')
        return new Date(v);
    if (typeof v === 'string') {
        const d = new Date(v);
        return isNaN(d.getTime()) ? null : d;
    }
    if (typeof v === 'object') {
        const o = v;
        if (typeof o.toDate === 'function')
            return o.toDate();
        const secs = (_a = o._seconds) !== null && _a !== void 0 ? _a : o.seconds;
        if (typeof secs === 'number')
            return new Date(secs * 1000);
    }
    return null;
}
function isProfileAdmin(profile) {
    return (profile === null || profile === void 0 ? void 0 : profile.isAdmin) === true;
}
/** The tier `profile` is entitled to at `now`. See the file header for the rules. */
function effectiveTier(profile, now = new Date()) {
    if (!profile)
        return 'FREE';
    const stored = normalizeStoredTier(profile.membershipTier);
    if (stored === 'TEST')
        return 'TEST';
    if (stored === 'FREE' || stored === 'BASIC')
        return 'FREE';
    if (isProfileAdmin(profile))
        return stored;
    const end = tierDateFromValue(profile.membershipEndDate);
    if (!end)
        return 'FREE';
    return end.getTime() > now.getTime() ? stored : 'FREE';
}
/** True when `profile` currently holds an ACTIVE SILVER/GOLD/PLATINUM with a future end date. */
function hasActivePaidTier(profile, now = new Date()) {
    if (!profile)
        return false;
    const stored = normalizeStoredTier(profile.membershipTier);
    if (!isPaidTier(stored))
        return false;
    const end = tierDateFromValue(profile.membershipEndDate);
    return !!end && end.getTime() > now.getTime();
}
/** Base membership: `hasBaseMembership` AND a future `baseMembershipEndDate`. */
function isBaseMembershipActive(profile, now = new Date()) {
    if (!profile || profile.hasBaseMembership !== true)
        return false;
    const end = tierDateFromValue(profile.baseMembershipEndDate);
    return !!end && end.getTime() > now.getTime();
}
function tierRank(tier) {
    var _a;
    const t = typeof tier === 'string' ? tier.toUpperCase() : '';
    return (_a = exports.EFFECTIVE_TIER_RANK[t]) !== null && _a !== void 0 ? _a : 0;
}
function isBaseProductId(productId) {
    return typeof productId === 'string' && exports.BASE_PRODUCT_IDS.includes(productId);
}
//# sourceMappingURL=effectiveTier.js.map