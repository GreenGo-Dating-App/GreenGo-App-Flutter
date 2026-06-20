"use strict";
/**
 * Store server notifications for AUTO-RENEWABLE SUBSCRIPTIONS.
 *
 * Initial purchases are handled by `verifyPurchase` (./index.ts). These two
 * HTTP endpoints keep entitlement in sync for everything that happens AFTER the
 * first purchase — silent renewals, cancellations, refunds, revocations — which
 * the client never sees:
 *   - appStoreNotificationsV2  ← App Store Server Notifications V2
 *   - playStoreNotifications   ← Google Play Real-time Developer Notifications (Pub/Sub push)
 *
 * Matching: both look up the user in the `subscriptions` collection by
 * `originalTransactionId` (Apple originalTransactionId / Play purchaseToken),
 * which `verifyPurchase` stores at first purchase.
 *
 * ⚠️ Requires sandbox testing before production reliance. Inert until the store
 * notification URLs are pointed at these endpoints (see ICloud/Play setup doc).
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
exports.playStoreNotifications = exports.appStoreNotificationsV2 = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("../shared/utils");
const purchase_verification_1 = require("../shared/purchase_verification");
const index_1 = require("./index");
const TIER_RANK = { BASIC: 0, SILVER: 1, GOLD: 2, PLATINUM: 3 };
const BASE_PRODUCT_ID = 'greengo_base_membership';
/** Find the most recent subscription record for a renewal/expiry key. */
async function findSubscription(key) {
    const snap = await utils_1.db
        .collection('subscriptions')
        .where('originalTransactionId', '==', key)
        .orderBy('createdAt', 'desc')
        .limit(1)
        .get();
    if (snap.empty)
        return null;
    const doc = snap.docs[0];
    return { userId: doc.data().userId, ref: doc.ref, data: doc.data() };
}
/**
 * Extend entitlement to `expiryMs` for a renewal. Never downgrades a higher
 * active tier (a Gold renewal must not clobber an active Platinum). The Base
 * membership is independent of the VIP tier, so it only touches the base fields.
 */
async function applyRenewal(userId, productId, expiryMs) {
    var _a, _b, _c, _d, _e;
    // iOS subscription IDs are prefixed `subscription_`; normalize to catalog key.
    const catalogId = productId.replace(/^subscription_/, '');
    const config = index_1.PRODUCT_CONFIG[catalogId];
    if (!config) {
        (0, utils_1.logError)(`applyRenewal: unknown productId ${productId}`);
        return;
    }
    const now = admin.firestore.Timestamp.now();
    const expiry = admin.firestore.Timestamp.fromMillis(expiryMs);
    if (catalogId === BASE_PRODUCT_ID) {
        // Base membership renews independently of the paid VIP tier.
        await utils_1.db.collection('profiles').doc(userId).set({ hasBaseMembership: true, baseMembershipEndDate: expiry, updatedAt: now }, { merge: true });
        (0, utils_1.logInfo)(`Renewal: extended BASE membership for ${userId} to ${expiry.toDate().toISOString()}`);
        return;
    }
    const tier = config.tier;
    const profileSnap = await utils_1.db.collection('profiles').doc(userId).get();
    const currentTier = ((_a = profileSnap.data()) === null || _a === void 0 ? void 0 : _a.membershipTier) || 'BASIC';
    const currentEnd = (_c = (_b = profileSnap.data()) === null || _b === void 0 ? void 0 : _b.membershipEndDate) === null || _c === void 0 ? void 0 : _c.toDate();
    const currentActive = currentEnd ? currentEnd.getTime() > Date.now() : false;
    // Never downgrade an active, higher tier.
    if (currentActive && ((_d = TIER_RANK[currentTier]) !== null && _d !== void 0 ? _d : 0) > ((_e = TIER_RANK[tier]) !== null && _e !== void 0 ? _e : 0)) {
        (0, utils_1.logInfo)(`Renewal for ${userId}: keeping higher active tier ${currentTier} over renewed ${tier}`);
        return;
    }
    await utils_1.db.collection('profiles').doc(userId).set({ membershipTier: tier, membershipEndDate: expiry, updatedAt: now }, { merge: true });
    await utils_1.db.collection('users').doc(userId).set({ subscriptionTier: tier, membershipEndDate: expiry, updatedAt: now }, { merge: true });
    (0, utils_1.logInfo)(`Renewal: ${userId} -> ${tier} until ${expiry.toDate().toISOString()}`);
}
/** Immediately revoke entitlement (refund / revoke / hard expiry). */
async function revokeEntitlement(userId, productId) {
    const now = admin.firestore.Timestamp.now();
    const catalogId = (productId || '').replace(/^subscription_/, '');
    if (catalogId === BASE_PRODUCT_ID) {
        await utils_1.db.collection('profiles').doc(userId).set({ hasBaseMembership: false, baseMembershipEndDate: now, updatedAt: now }, { merge: true });
        return;
    }
    await utils_1.db.collection('profiles').doc(userId).set({ membershipTier: 'BASIC', updatedAt: now }, { merge: true });
    await utils_1.db.collection('users').doc(userId).set({ subscriptionTier: 'BASIC', updatedAt: now }, { merge: true });
    (0, utils_1.logInfo)(`Revoked entitlement for ${userId} (product ${productId})`);
}
/** Mark a subscription's auto-renew status (cancel keeps access until expiry). */
async function markSubscription(ref, fields) {
    await ref.set(Object.assign(Object.assign({}, fields), { updatedAt: admin.firestore.Timestamp.now() }), { merge: true });
}
// ========== APP STORE SERVER NOTIFICATIONS V2 ==========
exports.appStoreNotificationsV2 = (0, https_1.onRequest)({ memory: '512MiB', timeoutSeconds: 30 }, async (req, res) => {
    var _a;
    try {
        const signedPayload = (_a = req.body) === null || _a === void 0 ? void 0 : _a.signedPayload;
        if (!signedPayload || typeof signedPayload !== 'string') {
            (0, utils_1.logError)('appStoreNotificationsV2: missing signedPayload');
            res.status(400).send('Missing signedPayload');
            return;
        }
        const appAppleId = parseInt(process.env.APPLE_APP_ID || '0', 10);
        const info = await (0, purchase_verification_1.decodeAppStoreNotification)(signedPayload, appAppleId);
        (0, utils_1.logInfo)(`App Store notification: ${info.notificationType}/${info.subtype || '-'} ` +
            `product=${info.productId} origTxn=${info.originalTransactionId}`);
        if (!info.originalTransactionId) {
            res.status(200).send('No transaction info'); // ack — nothing to do
            return;
        }
        const match = await findSubscription(info.originalTransactionId);
        if (!match) {
            (0, utils_1.logInfo)(`No subscription record for originalTransactionId ${info.originalTransactionId}`);
            res.status(200).send('Unknown subscription'); // ack to avoid retries
            return;
        }
        switch (info.notificationType) {
            case 'DID_RENEW':
            case 'SUBSCRIBED':
            case 'OFFER_REDEEMED':
                if (info.productId && info.expiresDateMs) {
                    await applyRenewal(match.userId, info.productId, info.expiresDateMs);
                    await markSubscription(match.ref, {
                        status: 'ACTIVE',
                        autoRenewing: true,
                        storeExpiryDate: admin.firestore.Timestamp.fromMillis(info.expiresDateMs),
                        endDate: admin.firestore.Timestamp.fromMillis(info.expiresDateMs),
                    });
                }
                break;
            case 'DID_CHANGE_RENEWAL_STATUS':
                // AUTO_RENEW_DISABLED subtype = user turned off renewal; keep access
                // until expiry, just record intent.
                await markSubscription(match.ref, {
                    autoRenewing: info.subtype !== 'AUTO_RENEW_DISABLED',
                });
                break;
            case 'EXPIRED':
            case 'GRACE_PERIOD_EXPIRED':
            case 'REVOKE':
            case 'REFUND':
                await revokeEntitlement(match.userId, info.productId);
                await markSubscription(match.ref, { status: 'EXPIRED', autoRenewing: false });
                break;
            default:
                (0, utils_1.logInfo)(`App Store notification ${info.notificationType} — no action`);
        }
        res.status(200).send('OK');
    }
    catch (err) {
        (0, utils_1.logError)('appStoreNotificationsV2 error:', err);
        // 500 lets Apple retry on transient failures.
        res.status(500).send('Error');
    }
});
// ========== GOOGLE PLAY REAL-TIME DEVELOPER NOTIFICATIONS ==========
// RTDN subscriptionNotification.notificationType values
const PLAY = {
    RECOVERED: 1,
    RENEWED: 2,
    CANCELED: 3,
    PURCHASED: 4,
    ON_HOLD: 5,
    IN_GRACE_PERIOD: 6,
    RESTARTED: 7,
    REVOKED: 12,
    EXPIRED: 13,
};
exports.playStoreNotifications = (0, https_1.onRequest)({ memory: '512MiB', timeoutSeconds: 30 }, async (req, res) => {
    var _a, _b;
    try {
        // Pub/Sub push delivers the RTDN base64-encoded in message.data.
        const encoded = (_b = (_a = req.body) === null || _a === void 0 ? void 0 : _a.message) === null || _b === void 0 ? void 0 : _b.data;
        if (!encoded) {
            res.status(200).send('No message'); // ack non-RTDN pings
            return;
        }
        const decoded = JSON.parse(Buffer.from(encoded, 'base64').toString('utf8'));
        const sub = decoded === null || decoded === void 0 ? void 0 : decoded.subscriptionNotification;
        if (!(sub === null || sub === void 0 ? void 0 : sub.purchaseToken)) {
            res.status(200).send('Not a subscription notification');
            return;
        }
        const { purchaseToken, notificationType, subscriptionId } = sub;
        (0, utils_1.logInfo)(`Play RTDN: type=${notificationType} product=${subscriptionId}`);
        const match = await findSubscription(purchaseToken);
        if (!match) {
            (0, utils_1.logInfo)(`No subscription record for Play token (RTDN type ${notificationType})`);
            res.status(200).send('Unknown subscription');
            return;
        }
        switch (notificationType) {
            case PLAY.RENEWED:
            case PLAY.RECOVERED:
            case PLAY.RESTARTED:
            case PLAY.PURCHASED: {
                const exp = await (0, purchase_verification_1.getGooglePlaySubscriptionExpiry)(purchaseToken);
                const productId = exp.productId || subscriptionId || match.data.productId;
                if (exp.expiresDateMs && productId) {
                    await applyRenewal(match.userId, productId, exp.expiresDateMs);
                    await markSubscription(match.ref, {
                        status: 'ACTIVE',
                        autoRenewing: true,
                        storeExpiryDate: admin.firestore.Timestamp.fromMillis(exp.expiresDateMs),
                        endDate: admin.firestore.Timestamp.fromMillis(exp.expiresDateMs),
                    });
                }
                break;
            }
            case PLAY.CANCELED:
                await markSubscription(match.ref, { autoRenewing: false }); // keep until expiry
                break;
            case PLAY.EXPIRED:
            case PLAY.REVOKED:
                await revokeEntitlement(match.userId, match.data.productId);
                await markSubscription(match.ref, { status: 'EXPIRED', autoRenewing: false });
                break;
            case PLAY.ON_HOLD:
            case PLAY.IN_GRACE_PERIOD:
                // Payment issue; keep access during grace, just flag it.
                await markSubscription(match.ref, { status: 'GRACE' });
                break;
            default:
                (0, utils_1.logInfo)(`Play RTDN type ${notificationType} — no action`);
        }
        res.status(200).send('OK');
    }
    catch (err) {
        (0, utils_1.logError)('playStoreNotifications error:', err);
        res.status(500).send('Error');
    }
});
//# sourceMappingURL=storeNotifications.js.map