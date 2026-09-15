"use strict";
/**
 * What a given email will receive when it registers.
 *
 * The registration form calls this once the email is entered, so the user is
 * told what is waiting for them BEFORE they commit to signing up:
 *
 *   "This account has PLATINUM for 30 days plus 3 months of Base membership,
 *    added automatically from today."
 *
 * Two kinds of answer:
 *
 *   PRE-REGISTRATION  the email is on the allowlist (a `coupons` document with
 *                     allowedEmail == this address). The exact tier and
 *                     durations come from that coupon's grants.
 *   DEFAULT 2026      everyone else registering during 2026 gets the standard
 *                     welcome pack: one month of Base membership and 100 coins.
 *
 * This is DESCRIPTIVE ONLY. It grants nothing and writes nothing. The actual
 * entitlement is applied server-side by applySignupGrants when the account is
 * created, so a forged or replayed call to this endpoint cannot obtain
 * anything - the worst it can do is make the form show the wrong promise.
 *
 * ── On the enumeration risk ───────────────────────────────────────────────
 * An unauthenticated endpoint that answers "yes, this address is on the
 * allowlist" is an oracle: someone could walk a list of addresses and learn
 * which are pre-registered. That is why:
 *
 *   - it returns ONLY the offer, never whether an account exists, never a
 *     name, a coupon code, or anything else about the person;
 *   - it is rate limited per caller, so the list cannot be walked at speed;
 *   - an unknown address gets the same shaped answer as a known one (the 2026
 *     default), so a single probe does not cleanly distinguish the two.
 *
 * It is a deliberate, bounded trade for the signup experience that was asked
 * for. `validateCoupon` - which leaked whether an arbitrary CODE was valid and
 * granted nothing in return - was removed for being a worse version of this.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkPreRegistrationOffer = exports.DEFAULT_2026_OFFER = void 0;
exports.isWithin2026 = isWithin2026;
exports.resolveOffer = resolveOffer;
const https_1 = require("firebase-functions/v2/https");
const utils_1 = require("../shared/utils");
const grants_1 = require("./grants");
const monitoring_1 = require("../shared/monitoring");
/** The standard welcome pack for anyone not on the allowlist, during 2026. */
exports.DEFAULT_2026_OFFER = {
    baseMembershipDays: 30, // one month
    coins: 100,
};
/** Is `when` inside the 2026 promotional window? */
function isWithin2026(when) {
    return when.getUTCFullYear() === 2026;
}
/**
 * Reads the offer for an email without granting anything.
 * Exported so applySignupGrants can use the SAME default, rather than two
 * copies of "100 coins and 30 days" drifting apart.
 */
async function resolveOffer(email, now = new Date()) {
    const clean = email.toLowerCase().trim();
    const snap = await utils_1.db
        .collection('coupons')
        .where('allowedEmail', '==', clean)
        .where('disabled', '==', false)
        .get();
    let tier;
    let membershipDays = 0;
    let baseDays = 0;
    let coins = 0;
    for (const doc of snap.docs) {
        const c = doc.data();
        // An expired or fully-redeemed coupon promises nothing.
        if (c.expiresAt && c.expiresAt.toDate() <= now)
            continue;
        if (c.maxRedemptions != null && (c.redemptionsCount || 0) >= c.maxRedemptions)
            continue;
        for (const g of (0, grants_1.effectiveGrants)(c)) {
            if (g.kind === 'membership' && g.tier && g.durationDays) {
                // Several coupons on one address: advertise the best tier and the
                // longest run of it, which is what the grant logic also settles on.
                if (!tier || (g.durationDays || 0) > membershipDays) {
                    tier = g.tier;
                    membershipDays = Math.max(membershipDays, g.durationDays);
                }
            }
            else if (g.kind === 'base_membership' && g.durationDays) {
                baseDays += g.durationDays;
            }
            else if (g.kind === 'coins' && g.coinAmount) {
                coins += g.coinAmount;
            }
        }
    }
    if (tier || baseDays > 0 || coins > 0) {
        // A membership grant with no explicit base grant earns a matching base
        // membership as a bonus - the same rule applySignupGrants applies, mirrored
        // here so the promise on screen matches what actually lands.
        if (tier && baseDays === 0)
            baseDays = membershipDays;
        return {
            kind: 'preRegistration',
            tier,
            membershipDays: membershipDays || undefined,
            baseMembershipDays: baseDays || undefined,
            coins: coins || undefined,
        };
    }
    if (isWithin2026(now)) {
        return {
            kind: 'default2026',
            baseMembershipDays: exports.DEFAULT_2026_OFFER.baseMembershipDays,
            coins: exports.DEFAULT_2026_OFFER.coins,
        };
    }
    return { kind: 'none' };
}
// ── Rate limiting ────────────────────────────────────────────────────────────
// In-memory and therefore per-instance: it does not stop a determined attacker
// spread across cold starts, but it does stop a list being walked from one
// machine at speed, which is the realistic abuse. A Firestore counter would be
// exact and would also add a write to every keystroke-triggered lookup.
const RATE_WINDOW_MS = 60000;
const RATE_MAX = 20;
const hits = new Map();
function rateLimited(key) {
    const now = Date.now();
    const recent = (hits.get(key) || []).filter((t) => now - t < RATE_WINDOW_MS);
    recent.push(now);
    hits.set(key, recent);
    if (hits.size > 5000)
        hits.clear(); // crude bound; this is a cache, not a ledger
    return recent.length > RATE_MAX;
}
exports.checkPreRegistrationOffer = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 15 }, (0, monitoring_1.monitored)('checkPreRegistrationOffer', async (request) => {
    var _a, _b, _c;
    const email = String(((_a = request.data) === null || _a === void 0 ? void 0 : _a.email) || '').toLowerCase().trim();
    if (!email || !email.includes('@') || email.length > 254) {
        throw new https_1.HttpsError('invalid-argument', 'A valid email is required');
    }
    const caller = ((_b = request.rawRequest) === null || _b === void 0 ? void 0 : _b.ip) || ((_c = request.auth) === null || _c === void 0 ? void 0 : _c.uid) || 'anonymous';
    if (rateLimited(caller)) {
        throw new https_1.HttpsError('resource-exhausted', 'Too many lookups, try again shortly');
    }
    const offer = await resolveOffer(email);
    (0, utils_1.logInfo)(`checkPreRegistrationOffer: ${offer.kind} for ${email}`);
    // Deliberately nothing else in the response - no coupon code, no name, no
    // hint about whether an account already exists.
    return offer;
}));
//# sourceMappingURL=preRegistrationOffer.js.map