"use strict";
/**
 * Multi-grant coupon types and normalisation helper.
 *
 * A coupon can carry an array of independent grants — e.g. coins + base
 * membership + a tier — so a single promo bundle can deliver multiple
 * entitlements in one redemption. Legacy single-type coupons (no `grants`
 * field) are normalised to a one-element grant list by `effectiveGrants`,
 * so the rest of the codebase only deals with the array shape.
 *
 * Distinct from `../shared/grants.ts`, which holds the helpers that
 * actually apply a grant to a profile / coin balance.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.summariseGrants = exports.hasBaseGrant = exports.effectiveGrants = exports.validateGrant = exports.VALID_DURATIONS_DAYS = void 0;
const grants_1 = require("../shared/grants");
exports.VALID_DURATIONS_DAYS = [7, 14, 30, 60, 90, 180, 365];
/** Throws a descriptive Error if the grant is malformed. */
function validateGrant(g, index = 0) {
    const prefix = `grants[${index}]`;
    if (!g || typeof g !== 'object') {
        throw new Error(`${prefix}: must be an object`);
    }
    if (g.kind !== 'coins' && g.kind !== 'membership' && g.kind !== 'base_membership') {
        throw new Error(`${prefix}.kind: must be one of coins / membership / base_membership`);
    }
    if (g.kind === 'membership') {
        if (!g.tier || !(g.tier in grants_1.TIER_RANK)) {
            throw new Error(`${prefix}.tier: membership grant requires a valid tier`);
        }
        if (typeof g.durationDays !== 'number' ||
            !exports.VALID_DURATIONS_DAYS.includes(g.durationDays)) {
            throw new Error(`${prefix}.durationDays: must be one of ${exports.VALID_DURATIONS_DAYS.join(', ')}`);
        }
    }
    else if (g.kind === 'base_membership') {
        if (typeof g.durationDays !== 'number' ||
            !exports.VALID_DURATIONS_DAYS.includes(g.durationDays)) {
            throw new Error(`${prefix}.durationDays: must be one of ${exports.VALID_DURATIONS_DAYS.join(', ')}`);
        }
    }
    else if (g.kind === 'coins') {
        if (typeof g.coinAmount !== 'number' || g.coinAmount <= 0) {
            throw new Error(`${prefix}.coinAmount: coin grant requires a positive amount`);
        }
    }
}
exports.validateGrant = validateGrant;
/**
 * Returns the grants this coupon should apply.
 * - If `coupon.grants` is a non-empty array, use it as-is.
 * - Otherwise build a one-element grant from the legacy fields so the
 *   loop in callers works uniformly.
 *
 * Accepts the raw Firestore doc data — callers pass `couponSnap.data()`.
 */
function effectiveGrants(coupon) {
    if (Array.isArray(coupon === null || coupon === void 0 ? void 0 : coupon.grants) && coupon.grants.length > 0) {
        return coupon.grants;
    }
    // Legacy fallback
    const type = coupon === null || coupon === void 0 ? void 0 : coupon.type;
    if (type === 'membership') {
        return [
            {
                kind: 'membership',
                tier: coupon.tier,
                durationDays: Number(coupon.durationDays) || 0,
            },
        ];
    }
    if (type === 'base_membership') {
        return [
            {
                kind: 'base_membership',
                durationDays: Number(coupon.durationDays) || 0,
            },
        ];
    }
    if (type === 'coins') {
        return [
            {
                kind: 'coins',
                coinAmount: Number(coupon.coinAmount) || 0,
            },
        ];
    }
    return [];
}
exports.effectiveGrants = effectiveGrants;
/** True if the coupon's effective grants include at least one base_membership entry. */
function hasBaseGrant(coupon) {
    return effectiveGrants(coupon).some((g) => g.kind === 'base_membership');
}
exports.hasBaseGrant = hasBaseGrant;
/** Builds a human-readable summary like "GOLD +30d · BASE +90d · +500 coins". */
function summariseGrants(grants) {
    const parts = [];
    for (const g of grants) {
        if (g.kind === 'membership') {
            parts.push(`${g.tier} +${g.durationDays}d`);
        }
        else if (g.kind === 'base_membership') {
            parts.push(`BASE +${g.durationDays}d`);
        }
        else if (g.kind === 'coins') {
            parts.push(`+${g.coinAmount} coins`);
        }
    }
    return parts.join(' · ');
}
exports.summariseGrants = summariseGrants;
//# sourceMappingURL=grants.js.map