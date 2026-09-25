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
const monitoring_1 = require("../shared/monitoring");
const types_1 = require("../shared/types");
const effectiveTier_1 = require("../shared/effectiveTier");
const membershipExpiry_1 = require("../shared/membershipExpiry");
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
    // iOS prefixes `subscription_`; Play uses bespoke IDs → PLAY_TO_CANONICAL.
    const catalogId = (0, index_1.toCatalogId)(productId);
    const config = index_1.PRODUCT_CONFIG[catalogId];
    if (!config) {
        (0, utils_1.logError)(`applyRenewal: unknown productId ${productId}`);
        return;
    }
    if (expiryMs <= Date.now()) {
        (0, utils_1.logInfo)(`applyRenewal: ${productId} for ${userId} already expired — ignoring`);
        return;
    }
    const now = admin.firestore.Timestamp.now();
    const expiry = admin.firestore.Timestamp.fromMillis(expiryMs);
    const profileSnap = await utils_1.db.collection('profiles').doc(userId).get();
    const profile = profileSnap.data() || {};
    if (catalogId === index_1.BASE_CATALOG_ID) {
        // Base membership renews independently of the paid VIP tier. Never
        // shorten a longer existing Base period.
        const currentBaseEnd = (0, effectiveTier_1.tierDateFromValue)(profile.baseMembershipEndDate);
        const newEnd = currentBaseEnd && currentBaseEnd.getTime() > expiryMs
            ? admin.firestore.Timestamp.fromDate(currentBaseEnd)
            : expiry;
        await utils_1.db.collection('profiles').doc(userId).set({
            hasBaseMembership: true,
            baseMembershipEndDate: newEnd,
            baseMembershipSource: 'purchase',
            updatedAt: now,
        }, { merge: true });
        (0, utils_1.logInfo)(`Renewal: extended BASE membership for ${userId} to ${newEnd.toDate().toISOString()}`);
        return;
    }
    const tier = config.tier;
    const current = (0, effectiveTier_1.effectiveTier)(profile);
    // Never downgrade an active, higher tier.
    if ((0, effectiveTier_1.hasActivePaidTier)(profile) && (0, effectiveTier_1.tierRank)(current) > (0, effectiveTier_1.tierRank)(tier)) {
        (0, utils_1.logInfo)(`Renewal for ${userId}: keeping higher active tier ${current} over renewed ${tier}`);
        return;
    }
    // Same tier: never shorten remaining time.
    const currentEnd = (0, effectiveTier_1.tierDateFromValue)(profile.membershipEndDate);
    const newEnd = (0, effectiveTier_1.normalizeStoredTier)(profile.membershipTier) === tier && currentEnd && currentEnd.getTime() > expiryMs
        ? admin.firestore.Timestamp.fromDate(currentEnd)
        : expiry;
    await utils_1.db.collection('profiles').doc(userId).set({ membershipTier: tier, membershipEndDate: newEnd, membershipSource: 'purchase', updatedAt: now }, { merge: true });
    const userRef = utils_1.db.collection('users').doc(userId);
    if ((await userRef.get()).exists) {
        await userRef.set({ subscriptionTier: tier, membershipEndDate: newEnd, updatedAt: now }, { merge: true });
    }
    (0, utils_1.logInfo)(`Renewal: ${userId} -> ${tier} until ${newEnd.toDate().toISOString()}`);
}
/** Immediately revoke entitlement (refund / revoke / hard expiry). */
async function revokeEntitlement(userId, productId) {
    const now = admin.firestore.Timestamp.now();
    const catalogId = (0, index_1.toCatalogId)(productId || '');
    if (catalogId === index_1.BASE_CATALOG_ID) {
        await utils_1.db.collection('profiles').doc(userId).set({ hasBaseMembership: false, baseMembershipEndDate: now, baseMembershipExpiredAt: now, updatedAt: now }, { merge: true });
        (0, utils_1.logInfo)(`Revoked BASE membership for ${userId}`);
        return;
    }
    // Only remove the tier this product granted: a refunded Silver must not
    // wipe an active Platinum that came from elsewhere (coupon, other store).
    const config = index_1.PRODUCT_CONFIG[catalogId];
    const profileSnap = await utils_1.db.collection('profiles').doc(userId).get();
    const current = (0, effectiveTier_1.effectiveTier)(profileSnap.data());
    if (config && (0, effectiveTier_1.hasActivePaidTier)(profileSnap.data()) && (0, effectiveTier_1.tierRank)(current) > (0, effectiveTier_1.tierRank)(config.tier)) {
        (0, utils_1.logInfo)(`Revoke for ${userId}: keeping higher active tier ${current} (revoked ${config.tier})`);
        return;
    }
    const removed = await (0, membershipExpiry_1.downgradeTierNow)(userId, 'store_revoked');
    (0, utils_1.logInfo)(`Revoked entitlement for ${userId} (product ${productId}, removed ${removed !== null && removed !== void 0 ? removed : 'nothing'})`);
}
/** Mark a subscription's auto-renew status (cancel keeps access until expiry). */
async function markSubscription(ref, fields) {
    await ref.set(Object.assign(Object.assign({}, fields), { updatedAt: admin.firestore.Timestamp.now() }), { merge: true });
}
// ========== APP STORE SERVER NOTIFICATIONS V2 ==========
exports.appStoreNotificationsV2 = (0, https_1.onRequest)({ memory: '512MiB', timeoutSeconds: 30 }, (0, monitoring_1.monitored)("appStoreNotificationsV2", async (req, res) => {
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
                        status: types_1.SubscriptionStatus.ACTIVE,
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
                await markSubscription(match.ref, { status: types_1.SubscriptionStatus.EXPIRED, autoRenewing: false });
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
}));
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
exports.playStoreNotifications = (0, https_1.onRequest)({ memory: '512MiB', timeoutSeconds: 30 }, (0, monitoring_1.monitored)("playStoreNotifications", async (req, res) => {
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
                        status: types_1.SubscriptionStatus.ACTIVE,
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
                await markSubscription(match.ref, { status: types_1.SubscriptionStatus.EXPIRED, autoRenewing: false });
                break;
            case PLAY.IN_GRACE_PERIOD:
                // Payment issue; access continues until membershipEndDate, then the
                // hourly expiry job downgrades unless RECOVERED extends it.
                await markSubscription(match.ref, { status: types_1.SubscriptionStatus.IN_GRACE_PERIOD });
                break;
            case PLAY.ON_HOLD:
                // Grace is over and payment still failing: Play has suspended access.
                // Status only — membershipEndDate (Play's expiryTime) has passed, so
                // the hourly expiry job downgrades; RECOVERED → applyRenewal restores.
                await markSubscription(match.ref, { status: types_1.SubscriptionStatus.ON_HOLD });
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
}));
//# sourceMappingURL=storeNotifications.js.map