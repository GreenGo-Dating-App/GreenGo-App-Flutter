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
/** Tiers that get nothing: there is no paid month to extend. */
const INELIGIBLE_TIERS = ['FREE', 'free', 'TEST', 'test'];
exports.claimReleaseBonus = (0, https_1.onCall)({ memory: '512MiB' }, async (request) => {
    var _a, _b;
    const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const userRef = utils_1.db.collection('users').doc(uid);
    try {
        // Claim the flag first, in a transaction. Whoever wins goes on to grant;
        // everyone else returns `alreadyClaimed` and writes nothing.
        const claimed = await utils_1.db.runTransaction(async (tx) => {
            var _a;
            const snap = await tx.get(userRef);
            if (!snap.exists)
                return false;
            if (((_a = snap.data()) === null || _a === void 0 ? void 0 : _a.releaseBonusGranted) === true)
                return false;
            tx.set(userRef, { releaseBonusGranted: true }, { merge: true });
            return true;
        });
        if (!claimed) {
            return { granted: false, reason: 'alreadyClaimed' };
        }
        // The user's active membership decides whether there is anything to extend.
        const memberships = await utils_1.db
            .collection('memberships')
            .where('userId', '==', uid)
            .where('isActive', '==', true)
            .orderBy('createdAt', 'desc')
            .limit(1)
            .get();
        if (memberships.empty) {
            return { granted: false, reason: 'noActiveMembership' };
        }
        const membership = memberships.docs[0];
        const data = membership.data();
        const tier = String((_b = data.tier) !== null && _b !== void 0 ? _b : 'FREE');
        if (INELIGIBLE_TIERS.includes(tier)) {
            return { granted: false, reason: 'tierNotEligible' };
        }
        // Extend from the later of "now" and the current end date, so a lapsed
        // membership gets a month from today rather than a month from the past.
        const currentEnd = data.endDate instanceof admin.firestore.Timestamp
            ? data.endDate.toDate()
            : new Date();
        const base = currentEnd > new Date() ? currentEnd : new Date();
        const newEnd = new Date(base);
        newEnd.setMonth(newEnd.getMonth() + 1);
        const newEndTs = admin.firestore.Timestamp.fromDate(newEnd);
        const batch = utils_1.db.batch();
        batch.update(membership.ref, {
            endDate: newEndTs,
            updatedAt: admin.firestore.Timestamp.now(),
        });
        batch.set(utils_1.db.collection('profiles').doc(uid), { membershipEndDate: newEndTs }, { merge: true });
        await batch.commit();
        (0, utils_1.logInfo)(`claimReleaseBonus: granted 1 month to ${uid}, new end ${newEnd.toISOString()}`);
        return { granted: true, newEndDate: newEnd.toISOString() };
    }
    catch (e) {
        (0, utils_1.logError)(`claimReleaseBonus failed for ${uid}`, e);
        // The flag may already be claimed at this point. Releasing it on failure
        // would reopen the double-grant race, so it stays claimed and the user
        // keeps their existing membership unchanged.
        throw new https_1.HttpsError('internal', 'Could not claim the release bonus.');
    }
});
//# sourceMappingURL=claimReleaseBonus.js.map