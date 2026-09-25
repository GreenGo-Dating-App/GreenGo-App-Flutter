"use strict";
/**
 * One free month, granted once per user after the release date.
 *
 * This used to run entirely on the client: it read the membership, computed a
 * new end date, and wrote `profiles/{uid}.membershipEndDate` itself. That only
 * worked because the profile rules let a user write their own entitlement
 * fields - which is the same permission that let anyone award themselves
 * Platinum outright. Closing that hole necessarily breaks any client-side
 * grant, so the grant moves here.
 *
 * Moving it server-side also fixes two things the client version could not:
 *
 *   - "once per user" was enforced by reading a flag and then writing it, with
 *     no transaction. Two launches racing each other both saw `false` and both
 *     granted a month. This claims the flag inside a transaction, so a second
 *     caller loses.
 *   - the caller chose their own new end date. Now the server computes it.
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
exports.claimReleaseBonus = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("../shared/utils");
const effectiveTier_1 = require("../shared/effectiveTier");
/**
 * Eligibility comes from `profiles/{uid}` (the entitlement source of truth),
 * NOT from `memberships/*`, which the client can write: an ACTIVE paid tier
 * (SILVER/GOLD/PLATINUM with membershipEndDate > now) is required. FREE,
 * legacy 'BASIC', TEST and expired tiers get nothing — extending an expired
 * tier's end date would revive it.
 */
exports.claimReleaseBonus = (0, https_1.onCall)({ memory: '512MiB' }, async (request) => {
    var _a;
    const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const userRef = utils_1.db.collection('users').doc(uid);
    const profileRef = utils_1.db.collection('profiles').doc(uid);
    try {
        const result = await utils_1.db.runTransaction(async (tx) => {
            var _a;
            const userSnap = await tx.get(userRef);
            const profileSnap = await tx.get(profileRef);
            if (!userSnap.exists)
                return { granted: false, reason: 'alreadyClaimed' };
            if (((_a = userSnap.data()) === null || _a === void 0 ? void 0 : _a.releaseBonusGranted) === true) {
                return { granted: false, reason: 'alreadyClaimed' };
            }
            tx.set(userRef, { releaseBonusGranted: true }, { merge: true });
            const profile = profileSnap.data();
            const now = new Date();
            if (!(0, effectiveTier_1.hasActivePaidTier)(profile, now)) {
                const stored = (0, effectiveTier_1.normalizeStoredTier)(profile === null || profile === void 0 ? void 0 : profile.membershipTier);
                return {
                    granted: false,
                    reason: stored === 'FREE' || stored === 'BASIC' || stored === 'TEST'
                        ? 'tierNotEligible'
                        : 'noActiveMembership',
                };
            }
            // Active paid tier: push its (future) end date by one month.
            const currentEnd = (0, effectiveTier_1.tierDateFromValue)(profile.membershipEndDate);
            const newEnd = new Date(currentEnd);
            newEnd.setMonth(newEnd.getMonth() + 1);
            const newEndTs = admin.firestore.Timestamp.fromDate(newEnd);
            const nowTs = admin.firestore.Timestamp.now();
            tx.set(profileRef, { membershipEndDate: newEndTs, updatedAt: nowTs }, { merge: true });
            tx.set(userRef, { membershipEndDate: newEndTs, updatedAt: nowTs }, { merge: true });
            return { granted: true, newEndDate: newEnd.toISOString() };
        });
        if (!result.granted)
            return result;
        // Display mirror only (never read for decisions): keep the active
        // memberships doc's endDate in step with the profile.
        try {
            const memberships = await utils_1.db
                .collection('memberships')
                .where('userId', '==', uid)
                .where('isActive', '==', true)
                .orderBy('createdAt', 'desc')
                .limit(1)
                .get();
            if (!memberships.empty) {
                await memberships.docs[0].ref.update({
                    endDate: admin.firestore.Timestamp.fromDate(new Date(result.newEndDate)),
                    updatedAt: admin.firestore.Timestamp.now(),
                });
            }
        }
        catch (e) {
            (0, utils_1.logError)(`claimReleaseBonus: memberships mirror update failed for ${uid}`, e);
        }
        (0, utils_1.logInfo)(`claimReleaseBonus: granted 1 month to ${uid}, new end ${result.newEndDate}`);
        return result;
    }
    catch (e) {
        (0, utils_1.logError)(`claimReleaseBonus failed for ${uid}`, e);
        // A failed transaction wrote nothing, so the claim is not spent.
        throw new https_1.HttpsError('internal', 'Could not claim the release bonus.');
    }
});
//# sourceMappingURL=claimReleaseBonus.js.map