"use strict";
/**
 * Secure server-side REFERRAL redemption.
 *
 * Called (by the new user) after onboarding. Given the referrer's code:
 *  - Resolves the code owner; rejects self-referral and a user redeeming more
 *    than one code (single-redemption guard on referrals/{newUid}).
 *  - ALWAYS grants the NEW user 1 month of Platinum.
 *  - Credits the REFERRER +100 coins, enforcing a 1000-coins/month cap per
 *    referrer via referralMonthlyGrants/{ownerId}_{yyyymm}.
 *
 * The single-redemption claim and the monthly-cap increment are each done in a
 * transaction so concurrent redemptions can't double-grant or exceed the cap.
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
exports.redeemReferral = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("../shared/utils");
const grants_1 = require("../shared/grants");
const monitoring_1 = require("../shared/monitoring");
const REFERRER_COIN_REWARD = 100;
const REFERRER_MONTHLY_CAP = 1000;
const PLATINUM_DURATION_MS = 30 * 24 * 60 * 60 * 1000; // 1 month
exports.redeemReferral = (0, https_1.onCall)({ memory: '256MiB', timeoutSeconds: 30 }, (0, monitoring_1.monitored)('redeemReferral', async (request) => {
    var _a;
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'You must be signed in to redeem a referral');
    }
    const newUid = request.auth.uid;
    const raw = (_a = request.data) === null || _a === void 0 ? void 0 : _a.code;
    if (typeof raw !== 'string' || raw.trim().length === 0) {
        throw new https_1.HttpsError('invalid-argument', 'Referral code is required');
    }
    const code = raw.trim().toUpperCase();
    // 1) Resolve the referrer + atomically claim the single redemption for this
    //    new user (also rejects self-referral and re-use of a second code).
    let ownerId;
    try {
        ownerId = await utils_1.db.runTransaction(async (tx) => {
            const codeSnap = await tx.get(utils_1.db.collection('referral_codes').doc(code));
            if (!codeSnap.exists) {
                throw new https_1.HttpsError('not-found', 'Referral code not found');
            }
            const owner = codeSnap.data().ownerId;
            if (!owner || owner === newUid) {
                throw new https_1.HttpsError('failed-precondition', 'You cannot use your own referral code');
            }
            const myRef = utils_1.db.collection('referrals').doc(newUid);
            const mySnap = await tx.get(myRef);
            const existing = mySnap.exists ? mySnap.data().redeemedCode : null;
            if (existing) {
                throw new https_1.HttpsError('already-exists', 'You have already used a referral code');
            }
            tx.set(myRef, {
                redeemedCode: code,
                redeemedFrom: owner,
                redeemedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
            return owner;
        });
    }
    catch (e) {
        if (e instanceof https_1.HttpsError)
            throw e;
        (0, utils_1.logError)('redeemReferral: validation/claim failed', e);
        throw new https_1.HttpsError('internal', 'Could not redeem referral');
    }
    // 2) The NEW user always receives 1 month of Platinum.
    let membershipGranted = false;
    try {
        await (0, grants_1.grantMembership)(newUid, 'PLATINUM', PLATINUM_DURATION_MS);
        membershipGranted = true;
    }
    catch (e) {
        (0, utils_1.logError)('redeemReferral: grantMembership failed', e);
    }
    // 3) The REFERRER earns +100 coins, capped at 1000/month.
    let referrerCredited = false;
    try {
        const now = new Date();
        const period = `${now.getUTCFullYear()}${String(now.getUTCMonth() + 1).padStart(2, '0')}`;
        const capRef = utils_1.db.collection('referralMonthlyGrants').doc(`${ownerId}_${period}`);
        const underCap = await utils_1.db.runTransaction(async (tx) => {
            const snap = await tx.get(capRef);
            const already = snap.exists ? (snap.data().coins || 0) : 0;
            if (already + REFERRER_COIN_REWARD > REFERRER_MONTHLY_CAP) {
                return false;
            }
            tx.set(capRef, {
                ownerId,
                period,
                coins: already + REFERRER_COIN_REWARD,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
            return true;
        });
        if (underCap) {
            await (0, grants_1.grantCoins)(ownerId, REFERRER_COIN_REWARD, 'reward', 'referralBonus', {
                referredUser: newUid,
                code,
            });
            await utils_1.db.collection('referrals').doc(ownerId).set({
                invitedCount: admin.firestore.FieldValue.increment(1),
                coinsEarned: admin.firestore.FieldValue.increment(REFERRER_COIN_REWARD),
            }, { merge: true });
            referrerCredited = true;
        }
    }
    catch (e) {
        (0, utils_1.logError)('redeemReferral: referrer credit failed', e);
    }
    (0, utils_1.logInfo)(`redeemReferral newUid=${newUid} owner=${ownerId} membership=${membershipGranted} coins=${referrerCredited}`);
    return { ok: true, referrerCredited, membershipGranted };
}));
//# sourceMappingURL=redeemReferral.js.map