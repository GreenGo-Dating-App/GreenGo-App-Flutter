"use strict";
/**
 * Direct entitlement grants — the replacement for coupon codes.
 *
 * v4.0.0 removed every code-redemption surface from the app, because App Store
 * Guideline 3.1.1 forbids unlocking paid functionality by any mechanism other
 * than In-App Purchase. A code the user types is exactly that mechanism.
 *
 * What Apple has never objected to is a developer GRANTING an entitlement
 * server-side: comped accounts, press accounts, partner deals, win-back gifts.
 * Nothing is redeemed in the app, there is no input to find, and the reviewer
 * sees no unlock path — because there isn't one.
 *
 * So the coupon ENGINE survives and the coupon CODE does not. This callable
 * drives the same `grants.ts` helpers the coupon system used (never-downgrade
 * extension, duration whitelist, camelCase `coinBalances` shape), just with an
 * admin choosing the recipient instead of a code choosing itself.
 *
 * Every grant writes an audit record naming the admin who made it, and a
 * notification so the recipient finds out. A silent gift is a wasted one.
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
exports.listEntitlementGrants = exports.grantEntitlement = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("../shared/utils");
const grants_1 = require("../coupons/grants");
const grants_2 = require("../shared/grants");
/** Hard ceiling on a single fan-out, so a mis-click cannot gift the world. */
const MAX_RECIPIENTS = 500;
async function resolveRecipients(req) {
    var _a;
    if (req.userIds && req.userIds.length > 0) {
        if (req.userIds.length > MAX_RECIPIENTS) {
            throw new https_1.HttpsError('invalid-argument', `At most ${MAX_RECIPIENTS} recipients per grant.`);
        }
        return req.userIds;
    }
    const segment = req.segment;
    if (!segment) {
        throw new https_1.HttpsError('invalid-argument', 'Provide userIds or a segment.');
    }
    let q = utils_1.db.collection('profiles');
    if (segment.tier)
        q = q.where('membershipTier', '==', segment.tier);
    if (segment.country)
        q = q.where('country', '==', segment.country);
    if (segment.signedUpAfter) {
        q = q.where('createdAt', '>=', admin.firestore.Timestamp.fromDate(new Date(segment.signedUpAfter)));
    }
    const limit = Math.min((_a = segment.limit) !== null && _a !== void 0 ? _a : MAX_RECIPIENTS, MAX_RECIPIENTS);
    const snap = await q.limit(limit).get();
    return snap.docs.map((d) => d.id);
}
async function applyGrantsToUser(uid, grants) {
    for (const g of grants) {
        if (g.kind === 'membership' && g.tier && g.durationDays) {
            await (0, grants_2.grantMembership)(uid, g.tier, g.durationDays * 24 * 60 * 60 * 1000);
        }
        else if (g.kind === 'base_membership' && g.durationDays) {
            // grantBaseMembership takes milliseconds, not days.
            await (0, grants_2.grantBaseMembership)(uid, g.durationDays * 24 * 60 * 60 * 1000, 'admin_grant');
        }
        else if (g.kind === 'coins' && g.coinAmount) {
            await (0, grants_2.grantCoins)(uid, g.coinAmount, 'admin_grant', 'Gift from GreenGo');
        }
    }
}
exports.grantEntitlement = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 300 }, async (request) => {
    var _a, _b, _c, _d;
    const adminUid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!adminUid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const adminDoc = await utils_1.db.collection('users').doc(adminUid).get();
    if (!((_b = adminDoc.data()) === null || _b === void 0 ? void 0 : _b.isAdmin)) {
        throw new https_1.HttpsError('permission-denied', 'Admin only.');
    }
    const data = request.data;
    const grants = (_c = data === null || data === void 0 ? void 0 : data.grants) !== null && _c !== void 0 ? _c : [];
    if (!Array.isArray(grants) || grants.length === 0) {
        throw new https_1.HttpsError('invalid-argument', 'At least one grant is required.');
    }
    // Same validation the coupon path used, so a grant cannot express anything
    // a coupon could not.
    grants.forEach((g, i) => {
        try {
            (0, grants_1.validateGrant)(g, i);
        }
        catch (e) {
            throw new https_1.HttpsError('invalid-argument', e.message);
        }
    });
    const recipients = await resolveRecipients(data);
    if (recipients.length === 0) {
        return { granted: 0, failed: 0, summary: (0, grants_1.summariseGrants)(grants) };
    }
    const summary = (0, grants_1.summariseGrants)(grants);
    const batchId = utils_1.db.collection('temp').doc().id;
    let granted = 0;
    const failed = [];
    for (const uid of recipients) {
        try {
            await applyGrantsToUser(uid, grants);
            // Tell the recipient. The app already renders a dismissible banner for
            // server-applied grants; this reuses that surface rather than adding a
            // second notion of "you were given something".
            await utils_1.db.collection('notifications').add({
                userId: uid,
                type: 'gift_received',
                title: 'A gift from GreenGo',
                body: summary,
                createdAt: admin.firestore.Timestamp.now(),
                read: false,
            });
            granted += 1;
        }
        catch (e) {
            failed.push(uid);
            (0, utils_1.logError)(`grantEntitlement: failed for ${uid}`, e);
        }
    }
    await utils_1.db.collection('entitlement_grants').doc(batchId).set({
        batchId,
        grantedBy: adminUid,
        grantedAt: admin.firestore.Timestamp.now(),
        grants,
        summary,
        note: (_d = data.note) !== null && _d !== void 0 ? _d : null,
        recipientCount: recipients.length,
        grantedCount: granted,
        failedCount: failed.length,
        failedUserIds: failed.slice(0, 50),
        // Recipients are recorded for the audit trail, capped so one batch
        // cannot produce a document too large to read back.
        recipients: recipients.slice(0, MAX_RECIPIENTS),
    });
    (0, utils_1.logInfo)(`grantEntitlement: ${adminUid} granted "${summary}" to ${granted}/${recipients.length}`);
    return { granted, failed: failed.length, summary, batchId };
});
/** Recent grant batches, for the admin panel's history table. */
exports.listEntitlementGrants = (0, https_1.onCall)(
// 512MiB, not 256: this project's index.js loads ~274 functions and needs
// roughly 200MB RSS before any handler runs, so a 256MiB function is
// OOM-killed on cold start - silently, taking its invocation with it.
{ memory: '512MiB' }, async (request) => {
    var _a, _b;
    const adminUid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!adminUid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const adminDoc = await utils_1.db.collection('users').doc(adminUid).get();
    if (!((_b = adminDoc.data()) === null || _b === void 0 ? void 0 : _b.isAdmin)) {
        throw new https_1.HttpsError('permission-denied', 'Admin only.');
    }
    const snap = await utils_1.db
        .collection('entitlement_grants')
        .orderBy('grantedAt', 'desc')
        .limit(100)
        .get();
    return {
        grants: snap.docs.map((d) => {
            var _a, _b, _c, _d, _e, _f, _g;
            const g = d.data();
            return {
                batchId: d.id,
                grantedBy: g.grantedBy,
                grantedAt: (_c = (_b = (_a = g.grantedAt) === null || _a === void 0 ? void 0 : _a.toDate()) === null || _b === void 0 ? void 0 : _b.toISOString()) !== null && _c !== void 0 ? _c : null,
                summary: g.summary,
                note: (_d = g.note) !== null && _d !== void 0 ? _d : null,
                recipientCount: (_e = g.recipientCount) !== null && _e !== void 0 ? _e : 0,
                grantedCount: (_f = g.grantedCount) !== null && _f !== void 0 ? _f : 0,
                failedCount: (_g = g.failedCount) !== null && _g !== void 0 ? _g : 0,
            };
        }),
    };
});
//# sourceMappingURL=grantEntitlement.js.map