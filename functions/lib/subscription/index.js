"use strict";
/**
 * Membership Service
 * Cloud Functions for membership purchases (store auto-renewable subscriptions)
 * and membership expiry.
 *
 * Two INDEPENDENT entitlements live on `profiles/{uid}`:
 *   - paid tier:  membershipTier (SILVER/GOLD/PLATINUM) + membershipEndDate
 *   - Base plan:  hasBaseMembership + baseMembershipEndDate
 * Every tier decision goes through shared/effectiveTier.ts.
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
exports.handleExpiredBaseMemberships = exports.handleExpiredMemberships = exports.checkExpiringSubscriptions = exports.verifyPurchase = exports.PLAY_TO_CANONICAL = exports.BASE_CATALOG_ID = exports.PRODUCT_CONFIG = void 0;
exports.toCatalogId = toCatalogId;
const crypto = __importStar(require("crypto"));
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const utils_1 = require("../shared/utils");
const admin = __importStar(require("firebase-admin"));
const types_1 = require("../shared/types");
const purchase_verification_1 = require("../shared/purchase_verification");
const grants_1 = require("../shared/grants");
const effectiveTier_1 = require("../shared/effectiveTier");
const membershipExpiry_1 = require("../shared/membershipExpiry");
// Product ID → tier and duration mapping.
// `price` is NOT charged anywhere — the stores charge what Play Console / App
// Store Connect say. It is only what gets recorded on `subscriptions.price` and
// `purchases.price`, so revenue reporting reads it. Keep it in sync with the USD
// prices in `payments/stripeCheckout.ts` MEMBERSHIP_PRODUCTS and with the store
// consoles — nothing syncs them automatically.
//
// The Base product's `tier` is never written to `membershipTier`: Base is the
// separate hasBaseMembership/baseMembershipEndDate entitlement.
exports.PRODUCT_CONFIG = {
    'greengo_base_membership': { tier: 'BASIC', durationDays: 365, price: 4.99 },
    '1_month_silver': { tier: 'SILVER', durationDays: 30, price: 9.99 },
    '1_year_silver': { tier: 'SILVER', durationDays: 365, price: 48.99 },
    '1_month_gold': { tier: 'GOLD', durationDays: 30, price: 19.99 },
    '1_year_gold': { tier: 'GOLD', durationDays: 365, price: 69.99 },
    '1_month_platinum': { tier: 'PLATINUM', durationDays: 30, price: 29.99 },
    '1_year_platinum_membership': { tier: 'PLATINUM', durationDays: 365, price: 89.99 },
};
exports.BASE_CATALOG_ID = 'greengo_base_membership';
// Google Play uses bespoke subscription IDs that differ from the canonical
// PRODUCT_CONFIG keys (iOS just adds a `subscription_` prefix). Map Play → canonical.
exports.PLAY_TO_CANONICAL = {
    'greengo_base_membership': 'greengo_base_membership',
    'silver_premium_monthly': '1_month_silver',
    'greengo_silver_yearly': '1_year_silver',
    'gold_premium_monthly': '1_month_gold',
    'greengo_gold_yearly': '1_year_gold',
    'platinum_vip_monthly': '1_month_platinum',
    'greengo_platinum_yearly': '1_year_platinum_membership',
};
/** Normalize a store product ID (iOS `subscription_` prefix / Play bespoke ID) to the catalog key. */
function toCatalogId(productId) {
    var _a;
    return (_a = exports.PLAY_TO_CANONICAL[productId]) !== null && _a !== void 0 ? _a : productId.replace(/^subscription_/, '');
}
/** Membership idempotency ledger: one doc per (store subscription, billing period). */
const MEMBERSHIP_LEDGER = 'membershipLedger';
function ledgerDocId(raw) {
    return crypto.createHash('sha256').update(raw).digest('hex');
}
// ========== 0. VERIFY PURCHASE (Callable) ==========
exports.verifyPurchase = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 30,
}, async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId, platform, productId, purchaseToken, verificationData } = request.data;
    // Validate required fields
    if (!userId || !platform || !productId || !purchaseToken) {
        throw new https_1.HttpsError('invalid-argument', 'Missing required fields');
    }
    // Ensure the authenticated user matches the userId
    if (request.auth.uid !== userId) {
        throw new https_1.HttpsError('permission-denied', 'User ID mismatch');
    }
    const userEmail = request.auth.token.email || null;
    try {
        (0, utils_1.logInfo)(`Verifying membership purchase for user ${userId} (${userEmail}), product ${productId}, platform ${platform}`);
        const catalogId = toCatalogId(productId);
        const config = exports.PRODUCT_CONFIG[catalogId];
        if (!config) {
            throw new https_1.HttpsError('invalid-argument', `Unknown product ID: ${productId}`);
        }
        const isBase = catalogId === exports.BASE_CATALOG_ID;
        const tier = config.tier;
        const durationDays = config.durationDays;
        const durationMs = durationDays * 24 * 60 * 60 * 1000;
        // ── Verify with the store ──
        let verified = false;
        let storeExpired = false;
        let storeRevoked = false;
        // Subscription identity used to match later renewal/expiry notifications.
        // iOS: Apple's originalTransactionId. Android: the subscription purchase token.
        let originalTransactionId;
        let storeExpiryMs;
        if (platform === 'android') {
            if (!verificationData) {
                throw new https_1.HttpsError('invalid-argument', 'Missing verificationData for Android purchase');
            }
            const result = await (0, purchase_verification_1.verifyGooglePlaySubscription)(verificationData);
            verified = result.verified;
            storeExpired = result.expired === true;
            storeRevoked = result.revoked === true;
            originalTransactionId = verificationData; // Play RTDN matches on purchaseToken
            storeExpiryMs = result.expiresDateMs;
            if (!verified) {
                (0, utils_1.logError)(`Google Play verification failed for ${productId}: ${result.error}`);
            }
            // The token must belong to the product being claimed — otherwise a
            // monthly Silver token could be presented as yearly Platinum.
            if (verified && result.productId && toCatalogId(result.productId) !== catalogId) {
                (0, utils_1.logError)(`Play token product ${result.productId} does not match claimed ${productId}`);
                throw new https_1.HttpsError('failed-precondition', 'Purchase does not match product');
            }
        }
        else if (platform === 'ios') {
            if (!verificationData) {
                throw new https_1.HttpsError('invalid-argument', 'Missing verificationData for iOS purchase');
            }
            const appAppleId = parseInt(process.env.APPLE_APP_ID || '0', 10);
            const result = await (0, purchase_verification_1.verifyAppStorePurchase)(verificationData, productId, appAppleId);
            verified = result.verified;
            storeExpired = result.expired === true;
            storeRevoked = result.revoked === true;
            originalTransactionId = result.originalTransactionId;
            storeExpiryMs = result.expiresDateMs;
            if (!verified) {
                (0, utils_1.logError)(`App Store verification failed for ${productId}: ${result.error}`);
            }
        }
        else {
            (0, utils_1.logError)(`Unknown platform: ${platform}`);
            throw new https_1.HttpsError('invalid-argument', `Unsupported platform: ${platform}`);
        }
        if (!verified) {
            throw new https_1.HttpsError('failed-precondition', 'Purchase verification failed');
        }
        const now = admin.firestore.Timestamp.now();
        const nowDate = now.toDate();
        // ── Expired / revoked store transaction → NEVER grant, write NOTHING ──
        // restorePurchases() replays every historical transaction on each launch;
        // granting on those resurrected lapsed tiers (e.g. Platinum forever).
        if (storeExpired ||
            storeRevoked ||
            (storeExpiryMs !== undefined && storeExpiryMs <= nowDate.getTime())) {
            const profileSnap = await utils_1.db.collection('profiles').doc(userId).get();
            (0, utils_1.logInfo)(`verifyPurchase: ${productId} for ${userId} is ${storeRevoked ? 'revoked' : 'expired'} ` +
                `(store expiry ${storeExpiryMs ? new Date(storeExpiryMs).toISOString() : 'n/a'}) — no grant`);
            return {
                verified: true,
                expired: true,
                revoked: storeRevoked,
                productId,
                storeExpiry: storeExpiryMs ? new Date(storeExpiryMs).toISOString() : null,
                tier: (0, effectiveTier_1.effectiveTier)(profileSnap.data(), nowDate),
                coinsGranted: 0,
            };
        }
        // CRITICAL: Prevent shared billing account abuse.
        const tokenSnapshot = await utils_1.db
            .collection('subscriptions')
            .where('purchaseToken', '==', purchaseToken)
            .limit(1)
            .get();
        if (!tokenSnapshot.empty) {
            const existingOwner = tokenSnapshot.docs[0].data().userId;
            if (existingOwner !== userId) {
                (0, utils_1.logInfo)(`Purchase token already belongs to user ${existingOwner}, rejecting for user ${userId}`);
                throw new https_1.HttpsError('already-exists', 'This purchase is already linked to a different account.');
            }
        }
        const purchaseTokenCheck = await utils_1.db
            .collection('purchases')
            .where('purchaseToken', '==', purchaseToken)
            .limit(1)
            .get();
        if (!purchaseTokenCheck.empty) {
            const purchaseOwner = purchaseTokenCheck.docs[0].data().userId;
            if (purchaseOwner !== userId) {
                throw new https_1.HttpsError('already-exists', 'This purchase is already linked to a different account.');
            }
        }
        // ── Idempotency: one grant per (platform, store subscription, period) ──
        const identity = originalTransactionId || purchaseToken;
        const ledgerKey = `${platform}_${identity}_${storeExpiryMs !== null && storeExpiryMs !== void 0 ? storeExpiryMs : 'noexp'}`;
        const ledgerRef = utils_1.db.collection(MEMBERSHIP_LEDGER).doc(ledgerDocId(ledgerKey));
        const bonusRef = utils_1.db
            .collection(MEMBERSHIP_LEDGER)
            .doc(ledgerDocId(`${platform}_${identity}_base_bonus`));
        const profileRef = utils_1.db.collection('profiles').doc(userId);
        const userRef = utils_1.db.collection('users').doc(userId);
        const outcome = await utils_1.db.runTransaction(async (tx) => {
            var _a;
            // All reads first (Firestore transaction rule).
            const ledgerSnap = await tx.get(ledgerRef);
            const profileSnap = await tx.get(profileRef);
            const userSnap = await tx.get(userRef);
            const bonusSnap = isBase ? await tx.get(bonusRef) : null;
            const profileData = profileSnap.data() || {};
            if (ledgerSnap.exists) {
                const l = ledgerSnap.data() || {};
                if (l.userId && l.userId !== userId) {
                    throw new https_1.HttpsError('already-exists', 'This purchase is already linked to a different account.');
                }
                return {
                    alreadyProcessed: true,
                    tier: (0, effectiveTier_1.effectiveTier)(profileData, nowDate),
                    endDate: (0, effectiveTier_1.tierDateFromValue)(isBase ? profileData.baseMembershipEndDate : profileData.membershipEndDate),
                    grantBonus: false,
                };
            }
            const profileUpdate = { updatedAt: now };
            const userUpdate = { updatedAt: now };
            let resultTier;
            let resultEnd;
            let grantBonus = false;
            if (isBase) {
                // Base NEVER sets a paid tier. Extend/set the Base fields only.
                const currentBaseEnd = (0, effectiveTier_1.tierDateFromValue)(profileData.baseMembershipEndDate);
                let newBaseEnd;
                if (storeExpiryMs !== undefined) {
                    const storeEnd = new Date(storeExpiryMs);
                    // Never shorten an existing (e.g. coupon-granted) Base period.
                    newBaseEnd = currentBaseEnd && currentBaseEnd > storeEnd ? currentBaseEnd : storeEnd;
                }
                else {
                    const start = currentBaseEnd && currentBaseEnd > nowDate ? currentBaseEnd : nowDate;
                    newBaseEnd = new Date(start.getTime() + durationMs);
                }
                profileUpdate.hasBaseMembership = true;
                profileUpdate.baseMembershipEndDate = admin.firestore.Timestamp.fromDate(newBaseEnd);
                profileUpdate.baseMembershipSource = 'purchase';
                // Leave an active paid tier alone; otherwise normalise a stale
                // 'BASIC'/expired tier to FREE (TEST and admins untouched).
                const stored = (0, effectiveTier_1.normalizeStoredTier)(profileData.membershipTier);
                if (!(0, effectiveTier_1.hasActivePaidTier)(profileData, nowDate) &&
                    stored !== 'TEST' &&
                    !(0, effectiveTier_1.isProfileAdmin)(profileData) &&
                    profileData.membershipTier !== 'FREE') {
                    profileUpdate.membershipTier = 'FREE';
                    if (profileData.membershipTier) {
                        profileUpdate.previousMembershipTier = String(profileData.membershipTier);
                    }
                    userUpdate.subscriptionTier = effectiveTier_1.USERS_FREE_TIER;
                }
                resultTier = (_a = profileUpdate.membershipTier) !== null && _a !== void 0 ? _a : (0, effectiveTier_1.effectiveTier)(profileData, nowDate);
                resultEnd = newBaseEnd;
                if (bonusSnap && !bonusSnap.exists) {
                    tx.create(bonusRef, { userId, platform, identity, kind: 'base_bonus', createdAt: now });
                    grantBonus = true;
                }
            }
            else {
                const currentStored = (0, effectiveTier_1.normalizeStoredTier)(profileData.membershipTier);
                const currentEnd = (0, effectiveTier_1.tierDateFromValue)(profileData.membershipEndDate);
                const ext = (0, grants_1.computeMembershipExtension)(currentStored, currentEnd, tier, durationMs, nowDate);
                let newEnd;
                if (ext.effectiveTier !== tier) {
                    // A HIGHER tier is active: keep it and queue this purchase's time
                    // after it (never downgrade an active higher tier).
                    newEnd = ext.newEndDate;
                }
                else if ((0, effectiveTier_1.hasActivePaidTier)(profileData, nowDate) &&
                    currentStored === tier &&
                    currentEnd) {
                    // Same tier renewal: the store expiry is authoritative, but never
                    // shorten remaining (e.g. coupon-granted) time.
                    newEnd = storeExpiryMs !== undefined
                        ? new Date(Math.max(storeExpiryMs, currentEnd.getTime()))
                        : ext.newEndDate;
                }
                else {
                    // New purchase / upgrade / re-purchase after expiry.
                    newEnd = storeExpiryMs !== undefined ? new Date(storeExpiryMs) : ext.newEndDate;
                }
                const endTs = admin.firestore.Timestamp.fromDate(newEnd);
                profileUpdate.membershipTier = ext.effectiveTier;
                profileUpdate.membershipEndDate = endTs;
                profileUpdate.membershipStartDate = now;
                profileUpdate.membershipSource = 'purchase';
                userUpdate.subscriptionTier = ext.effectiveTier;
                userUpdate.membershipEndDate = endTs;
                resultTier = ext.effectiveTier;
                resultEnd = newEnd;
            }
            const storeExpiryTs = storeExpiryMs !== undefined
                ? admin.firestore.Timestamp.fromMillis(storeExpiryMs)
                : null;
            const recordTier = isBase ? 'BASE' : tier;
            tx.create(ledgerRef, {
                userId,
                platform,
                productId,
                identity,
                storeExpiryDate: storeExpiryTs,
                createdAt: now,
            });
            // `originalTransactionId` is the stable key store renewal/expiry
            // notifications carry (Apple originalTransactionId / Play purchaseToken).
            tx.set(utils_1.db.collection('subscriptions').doc(), {
                userId,
                userEmail,
                tier: recordTier,
                status: types_1.SubscriptionStatus.ACTIVE,
                startDate: now,
                endDate: isBase
                    ? profileUpdate.baseMembershipEndDate
                    : profileUpdate.membershipEndDate,
                durationDays,
                platform,
                purchaseToken,
                transactionId: purchaseToken,
                orderId: purchaseToken,
                originalTransactionId: identity,
                storeExpiryDate: storeExpiryTs,
                productId,
                price: config.price,
                currency: 'USD',
                autoRenewing: true,
                createdAt: now,
            });
            tx.set(utils_1.db.collection('purchases').doc(), {
                userId,
                userEmail,
                type: 'membership',
                status: 'completed',
                productId,
                tier: recordTier,
                price: config.price,
                currency: 'USD',
                platform,
                purchaseToken,
                transactionId: purchaseToken,
                durationDays,
                purchaseDate: now,
                verifiedAt: now,
                verificationMethod: 'cloud_function',
            });
            tx.set(profileRef, profileUpdate, { merge: true });
            if (userSnap.exists && Object.keys(userUpdate).length > 1) {
                tx.set(userRef, userUpdate, { merge: true });
            }
            return { alreadyProcessed: false, tier: resultTier, endDate: resultEnd, grantBonus };
        });
        // ── 500 coin welcome bonus, once per Base subscription ──
        let coinsGranted = 0;
        if (outcome.grantBonus) {
            await (0, grants_1.grantCoins)(userId, 500, 'membership_bonus', 'Base membership welcome bonus', { productId });
            coinsGranted = 500;
        }
        const endIso = outcome.endDate ? outcome.endDate.toISOString() : null;
        (0, utils_1.logInfo)(`Membership purchase verified for user ${userId}: product=${catalogId} tier=${outcome.tier} ` +
            `endDate=${endIso} coins=${coinsGranted}${outcome.alreadyProcessed ? ' (already processed)' : ''}`);
        return Object.assign(Object.assign({ verified: true, expired: false, alreadyProcessed: outcome.alreadyProcessed, tier: outcome.tier, endDate: endIso }, (isBase ? { baseMembershipEndDate: endIso } : {})), { coinsGranted });
    }
    catch (error) {
        (0, utils_1.logError)('Error verifying purchase:', error);
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        throw new https_1.HttpsError('internal', 'Failed to verify purchase');
    }
});
// ========== 1. CHECK EXPIRING MEMBERSHIPS (Scheduled - Daily 9am) ==========
exports.checkExpiringSubscriptions = (0, scheduler_1.onSchedule)({
    schedule: '0 9 * * *', // Daily at 9 AM UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 300,
}, async () => {
    var _a;
    (0, utils_1.logInfo)('Checking for expiring memberships');
    try {
        const threeDaysFromNow = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
        // Find profiles with membership ending within 3 days
        const snapshot = await utils_1.db
            .collection('profiles')
            .where('membershipEndDate', '<', admin.firestore.Timestamp.fromDate(threeDaysFromNow))
            .where('membershipEndDate', '>', admin.firestore.Timestamp.now())
            .get();
        (0, utils_1.logInfo)(`Found ${snapshot.size} memberships expiring soon`);
        for (const doc of snapshot.docs) {
            const data = doc.data();
            // Only an active PAID tier can "expire soon" (FREE/'BASIC' profiles keep
            // an old membershipEndDate for history).
            if (!(0, effectiveTier_1.isPaidTier)((0, effectiveTier_1.effectiveTier)(data)) || (0, effectiveTier_1.isProfileAdmin)(data))
                continue;
            const endDate = (_a = data.membershipEndDate) === null || _a === void 0 ? void 0 : _a.toDate();
            if (!endDate)
                continue;
            const daysUntilExpiry = Math.ceil((endDate.getTime() - Date.now()) / (24 * 60 * 60 * 1000));
            await utils_1.db.collection('notifications').add({
                userId: doc.id,
                type: 'membership_expiring',
                title: 'Membership Expiring Soon',
                body: `Your ${data.membershipTier || 'membership'} expires in ${daysUntilExpiry} day${daysUntilExpiry !== 1 ? 's' : ''}. Extend now to keep your premium features!`,
                data: {
                    tier: data.membershipTier,
                    expiresAt: endDate.toISOString(),
                },
                read: false,
                sent: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            (0, utils_1.logInfo)(`Sent expiry reminder to user ${doc.id}`);
        }
        (0, utils_1.logInfo)('Expiring memberships check completed');
    }
    catch (error) {
        (0, utils_1.logError)('Error checking expiring memberships:', error);
        throw error;
    }
});
// ========== 2. HANDLE EXPIRED MEMBERSHIPS (Scheduled - Hourly) ==========
const EXPIRY_PAGE_SIZE = 200;
/** Stop starting new pages after this long; the next hourly run continues. */
const EXPIRY_TIME_BUDGET_MS = 480000;
/**
 * Paid tier (SILVER/GOLD/PLATINUM, plus the legacy 'BASIC' the client reads
 * as SILVER) whose membershipEndDate has passed → membershipTier 'FREE'.
 * Never touches the Base membership. Skips TEST and admins. Paginated and
 * idempotent: a downgraded profile no longer matches the query.
 *
 * Index: profiles (membershipTier ASC, membershipEndDate ASC) — already in
 * firestore.indexes.json.
 */
exports.handleExpiredMemberships = (0, scheduler_1.onSchedule)({
    schedule: '0 * * * *', // Every hour
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
}, async () => {
    const started = Date.now();
    const now = admin.firestore.Timestamp.now();
    const queue = new membershipExpiry_1.WriteQueue();
    let scanned = 0;
    let downgraded = 0;
    let cursor;
    try {
        // eslint-disable-next-line no-constant-condition
        while (true) {
            if (Date.now() - started > EXPIRY_TIME_BUDGET_MS) {
                (0, utils_1.logInfo)('handleExpiredMemberships: time budget reached, continuing next run');
                break;
            }
            let q = utils_1.db
                .collection('profiles')
                .where('membershipTier', 'in', [...effectiveTier_1.PAID_TIER_STORED_VALUES, ...effectiveTier_1.LEGACY_BASIC_STORED_VALUES])
                .where('membershipEndDate', '<', now)
                .orderBy('membershipEndDate', 'asc')
                .limit(EXPIRY_PAGE_SIZE);
            if (cursor)
                q = q.startAfter(cursor);
            const snap = await q.get();
            if (snap.empty)
                break;
            cursor = snap.docs[snap.docs.length - 1];
            for (const doc of snap.docs) {
                scanned++;
                try {
                    const removed = await (0, membershipExpiry_1.planTierExpiry)(doc, queue, { reason: 'expired', now });
                    if (removed !== null) {
                        downgraded++;
                        (0, utils_1.logInfo)(`Downgraded user ${doc.id} from ${removed} to FREE`);
                    }
                }
                catch (e) {
                    (0, utils_1.logError)(`handleExpiredMemberships: failed for ${doc.id}`, e);
                }
            }
            await queue.flush();
            if (snap.size < EXPIRY_PAGE_SIZE)
                break;
        }
        await queue.flush();
        (0, utils_1.logInfo)(`handleExpiredMemberships: scanned=${scanned} downgraded=${downgraded} ops=${queue.committedOps}`);
    }
    catch (error) {
        (0, utils_1.logError)('Error handling expired memberships:', error);
        throw error;
    }
});
// ========== 3. HANDLE EXPIRED BASE MEMBERSHIPS (Scheduled - Hourly) ==========
/**
 * hasBaseMembership == true && baseMembershipEndDate < now →
 * hasBaseMembership false + baseMembershipExpiredAt. Never touches the tier.
 *
 * Index: profiles (hasBaseMembership ASC, baseMembershipEndDate ASC) — NEW in
 * firestore.indexes.json; deploy it before this function.
 */
exports.handleExpiredBaseMemberships = (0, scheduler_1.onSchedule)({
    schedule: '15 * * * *', // Every hour, offset from the tier job
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
}, async () => {
    const started = Date.now();
    const now = admin.firestore.Timestamp.now();
    const queue = new membershipExpiry_1.WriteQueue();
    let scanned = 0;
    let expired = 0;
    let cursor;
    try {
        // eslint-disable-next-line no-constant-condition
        while (true) {
            if (Date.now() - started > EXPIRY_TIME_BUDGET_MS) {
                (0, utils_1.logInfo)('handleExpiredBaseMemberships: time budget reached, continuing next run');
                break;
            }
            let q = utils_1.db
                .collection('profiles')
                .where('hasBaseMembership', '==', true)
                .where('baseMembershipEndDate', '<', now)
                .orderBy('baseMembershipEndDate', 'asc')
                .limit(EXPIRY_PAGE_SIZE);
            if (cursor)
                q = q.startAfter(cursor);
            const snap = await q.get();
            if (snap.empty)
                break;
            cursor = snap.docs[snap.docs.length - 1];
            for (const doc of snap.docs) {
                scanned++;
                if (await (0, membershipExpiry_1.planBaseExpiry)(doc, queue, now))
                    expired++;
            }
            await queue.flush();
            if (snap.size < EXPIRY_PAGE_SIZE)
                break;
        }
        await queue.flush();
        (0, utils_1.logInfo)(`handleExpiredBaseMemberships: scanned=${scanned} expired=${expired}`);
    }
    catch (error) {
        (0, utils_1.logError)('Error handling expired base memberships:', error);
        throw error;
    }
});
//# sourceMappingURL=index.js.map