"use strict";
/**
 * Stripe Checkout for Web Payments
 * Creates Stripe Checkout sessions for coin packages and memberships
 * Handles Stripe webhooks to credit coins/memberships in Firestore
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.stripeWebhook = exports.createStripeCheckoutSession = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const stripe_1 = __importDefault(require("stripe"));
const db = admin.firestore();
// Initialize Stripe with secret key from environment variable
// Set via: firebase functions:secrets:set STRIPE_SECRET_KEY
function getStripe() {
    const secretKey = process.env.STRIPE_SECRET_KEY || '';
    if (!secretKey) {
        throw new Error('STRIPE_SECRET_KEY not configured. Set it via Firebase Console > Functions > Environment variables, ' +
            'or use: firebase functions:secrets:set STRIPE_SECRET_KEY');
    }
    return new stripe_1.default(secretKey);
}
// Coin package definitions (must match Flutter CoinPackages)
// Prices: USD cents, EUR cents, BRL centavos
const COIN_PACKAGES = {
    'greengo_coins_100': { coins: 100, priceUsd: 99, priceEur: 99, priceBrl: 590, name: 'Starter - 100 Coins' },
    'greengo_coins_500': { coins: 500, priceUsd: 399, priceEur: 399, priceBrl: 1990, name: 'Popular - 500 Coins' },
    'greengo_coins_1000': { coins: 1000, priceUsd: 699, priceEur: 699, priceBrl: 3490, name: 'Value - 1,000 Coins' },
    'greengo_coins_5000': { coins: 5000, priceUsd: 2999, priceEur: 2999, priceBrl: 14990, name: 'Premium - 5,000 Coins' },
};
// Membership definitions
const MEMBERSHIP_PRODUCTS = {
    'greengo_base_membership': { name: 'Base Membership (1 Year)', priceUsd: 999, priceEur: 999, priceBrl: 4990, durationDays: 365, tier: 'BASE' },
    '1_month_silver': { name: 'Silver Membership (1 Month)', priceUsd: 999, priceEur: 999, priceBrl: 4990, durationDays: 30, tier: 'SILVER' },
    '1_month_gold': { name: 'Gold Membership (1 Month)', priceUsd: 1999, priceEur: 1999, priceBrl: 9990, durationDays: 30, tier: 'GOLD' },
    '1_month_platinum': { name: 'Platinum Membership (1 Month)', priceUsd: 2999, priceEur: 2999, priceBrl: 14990, durationDays: 30, tier: 'PLATINUM' },
    '1_year_silver': { name: 'Silver Membership (1 Year)', priceUsd: 4899, priceEur: 4899, priceBrl: 24990, durationDays: 365, tier: 'SILVER' },
    '1_year_gold': { name: 'Gold Membership (1 Year)', priceUsd: 6999, priceEur: 6999, priceBrl: 34990, durationDays: 365, tier: 'GOLD' },
    '1_year_platinum_membership': { name: 'Platinum Membership (1 Year)', priceUsd: 8999, priceEur: 8999, priceBrl: 44990, durationDays: 365, tier: 'PLATINUM' },
};
// European countries (ISO 3166-1 alpha-2)
const EU_COUNTRIES = new Set([
    'AT', 'AUSTRIA', 'BE', 'BELGIUM', 'BG', 'BULGARIA', 'HR', 'CROATIA',
    'CY', 'CYPRUS', 'CZ', 'CZECH REPUBLIC', 'CZECHIA', 'DK', 'DENMARK',
    'EE', 'ESTONIA', 'FI', 'FINLAND', 'FR', 'FRANCE', 'DE', 'GERMANY',
    'GR', 'GREECE', 'HU', 'HUNGARY', 'IE', 'IRELAND', 'IT', 'ITALY',
    'LV', 'LATVIA', 'LT', 'LITHUANIA', 'LU', 'LUXEMBOURG', 'MT', 'MALTA',
    'NL', 'NETHERLANDS', 'PL', 'POLAND', 'PT', 'PORTUGAL', 'RO', 'ROMANIA',
    'SK', 'SLOVAKIA', 'SI', 'SLOVENIA', 'ES', 'SPAIN', 'SE', 'SWEDEN',
    'NO', 'NORWAY', 'IS', 'ICELAND', 'CH', 'SWITZERLAND', 'LI', 'LIECHTENSTEIN',
    'GB', 'UNITED KINGDOM', 'UK',
]);
/**
 * Create a Stripe Checkout Session for web purchases
 * Called from Flutter web via Firebase Cloud Functions
 */
exports.createStripeCheckoutSession = functions
    .runWith({ secrets: ['STRIPE_SECRET_KEY'] })
    .https.onCall(async (data, context) => {
    // Require authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated to make a purchase');
    }
    const userId = context.auth.uid;
    const productId = data.productId;
    const successUrl = data.successUrl;
    const cancelUrl = data.cancelUrl;
    const userCountry = (data.userCountry || '').toUpperCase();
    if (!productId || !successUrl || !cancelUrl) {
        throw new functions.https.HttpsError('invalid-argument', 'productId, successUrl, and cancelUrl are required');
    }
    // Determine if coin package or membership
    const coinPackage = COIN_PACKAGES[productId];
    const membership = MEMBERSHIP_PRODUCTS[productId];
    if (!coinPackage && !membership) {
        throw new functions.https.HttpsError('invalid-argument', `Unknown product: ${productId}`);
    }
    const product = coinPackage || membership;
    const name = product.name;
    // Currency and payment methods based on user location
    const isBrazil = userCountry === 'BR' || userCountry === 'BRAZIL';
    const isEurope = EU_COUNTRIES.has(userCountry);
    let currency;
    let priceInCents;
    let paymentMethods;
    if (isBrazil) {
        currency = 'brl';
        priceInCents = product.priceBrl;
        paymentMethods = ['card'];
    }
    else if (isEurope) {
        currency = 'eur';
        priceInCents = product.priceEur;
        paymentMethods = ['card'];
    }
    else {
        currency = 'usd';
        priceInCents = product.priceUsd;
        paymentMethods = ['card'];
    }
    try {
        const stripe = getStripe();
        const session = await stripe.checkout.sessions.create({
            payment_method_types: paymentMethods,
            line_items: [
                {
                    price_data: {
                        currency: currency,
                        product_data: {
                            name: name,
                            description: coinPackage
                                ? `${coinPackage.coins} GreenGo Coins`
                                : `${membership.tier} Membership`,
                        },
                        unit_amount: priceInCents,
                    },
                    quantity: 1,
                },
            ],
            mode: 'payment',
            success_url: successUrl,
            cancel_url: cancelUrl,
            client_reference_id: userId,
            metadata: {
                userId: userId,
                productId: productId,
                type: coinPackage ? 'coins' : 'membership',
            },
        });
        return { sessionId: session.id, url: session.url };
    }
    catch (error) {
        console.error('Stripe checkout session creation failed:', error);
        throw new functions.https.HttpsError('internal', `Failed to create checkout session: ${error.message}`);
    }
});
/**
 * Stripe Webhook Handler
 * Processes completed payments and credits coins/memberships
 */
exports.stripeWebhook = functions
    .runWith({ secrets: ['STRIPE_SECRET_KEY', 'STRIPE_WEBHOOK_SECRET'] })
    .https.onRequest(async (req, res) => {
    // Set CORS headers for preflight
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type, stripe-signature');
    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }
    if (req.method !== 'POST') {
        res.status(405).send('Method not allowed');
        return;
    }
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || '';
    let event;
    try {
        const stripe = getStripe();
        if (webhookSecret) {
            const signature = req.headers['stripe-signature'];
            // Firebase Cloud Functions v1 provides rawBody on the request object
            const payload = req.rawBody || Buffer.from(JSON.stringify(req.body));
            event = stripe.webhooks.constructEvent(payload, signature, webhookSecret);
        }
        else {
            // In development, accept without signature verification
            event = req.body;
            console.warn('⚠️ Stripe webhook signature verification skipped (no webhook secret configured)');
        }
    }
    catch (error) {
        console.error('Webhook signature verification failed:', error.message);
        res.status(400).send(`Webhook Error: ${error.message}`);
        return;
    }
    // Handle the event
    if (event.type === 'checkout.session.completed') {
        const session = event.data.object;
        await handleCompletedCheckout(session);
    }
    res.status(200).json({ received: true });
});
/**
 * Process a completed Stripe Checkout session
 */
async function handleCompletedCheckout(session) {
    var _a, _b, _c;
    const userId = ((_a = session.metadata) === null || _a === void 0 ? void 0 : _a.userId) || session.client_reference_id;
    const productId = (_b = session.metadata) === null || _b === void 0 ? void 0 : _b.productId;
    const type = (_c = session.metadata) === null || _c === void 0 ? void 0 : _c.type;
    if (!userId || !productId) {
        console.error('Missing userId or productId in checkout session metadata');
        return;
    }
    // Check if this session was already processed (idempotency)
    const existingOrder = await db.collection('stripe_orders')
        .where('sessionId', '==', session.id)
        .limit(1)
        .get();
    if (!existingOrder.empty) {
        console.log(`Session ${session.id} already processed, skipping`);
        return;
    }
    // Record the order
    const now = admin.firestore.Timestamp.now();
    await db.collection('stripe_orders').add({
        sessionId: session.id,
        userId: userId,
        productId: productId,
        type: type,
        amount: session.amount_total,
        currency: session.currency,
        status: 'completed',
        createdAt: now,
    });
    if (type === 'coins') {
        await creditCoins(userId, productId, session.id);
    }
    else if (type === 'membership') {
        await activateMembership(userId, productId, session.id);
    }
}
/**
 * Credit coins to user after successful Stripe payment
 */
async function creditCoins(userId, productId, sessionId) {
    const coinPackage = COIN_PACKAGES[productId];
    if (!coinPackage) {
        console.error(`Unknown coin package: ${productId}`);
        return;
    }
    const coins = coinPackage.coins;
    const now = admin.firestore.Timestamp.now();
    const expirationDate = admin.firestore.Timestamp.fromDate(new Date(Date.now() + 365 * 24 * 60 * 60 * 1000));
    const balanceRef = db.collection('coinBalances').doc(userId);
    const batchEntry = {
        batchId: `stripe_${sessionId}`,
        initialCoins: coins,
        remainingCoins: coins,
        source: 'purchase',
        acquiredDate: now,
        expirationDate: expirationDate,
    };
    const balanceDoc = await balanceRef.get();
    if (balanceDoc.exists) {
        await balanceRef.update({
            totalCoins: admin.firestore.FieldValue.increment(coins),
            purchasedCoins: admin.firestore.FieldValue.increment(coins),
            lastUpdated: now,
            coinBatches: admin.firestore.FieldValue.arrayUnion(batchEntry),
        });
    }
    else {
        await balanceRef.set({
            userId: userId,
            totalCoins: coins,
            purchasedCoins: coins,
            earnedCoins: 0,
            giftedCoins: 0,
            spentCoins: 0,
            lastUpdated: now,
            coinBatches: [batchEntry],
        });
    }
    // Record transaction
    await db.collection('coinTransactions').add({
        userId: userId,
        type: 'credit',
        amount: coins,
        reason: 'coinPurchase',
        description: `Purchased ${coins} coins via Stripe`,
        createdAt: now,
        metadata: {
            productId: productId,
            platform: 'web',
            stripeSessionId: sessionId,
        },
    });
    console.log(`✅ Credited ${coins} coins to user ${userId} via Stripe`);
}
/**
 * Activate membership after successful Stripe payment
 */
async function activateMembership(userId, productId, sessionId) {
    var _a, _b;
    const membership = MEMBERSHIP_PRODUCTS[productId];
    if (!membership) {
        console.error(`Unknown membership product: ${productId}`);
        return;
    }
    const now = new Date();
    const profileRef = db.collection('profiles').doc(userId);
    const profileDoc = await profileRef.get();
    // Compute end date — extend from current end date if active
    let endDate;
    if (profileDoc.exists) {
        const data = profileDoc.data();
        const currentEndTs = productId === 'greengo_base_membership'
            ? (_a = data === null || data === void 0 ? void 0 : data.baseMembershipEndDate) === null || _a === void 0 ? void 0 : _a.toDate()
            : (_b = data === null || data === void 0 ? void 0 : data.membershipEndDate) === null || _b === void 0 ? void 0 : _b.toDate();
        if (currentEndTs && currentEndTs > now) {
            endDate = new Date(currentEndTs.getTime() + membership.durationDays * 24 * 60 * 60 * 1000);
        }
        else {
            endDate = new Date(now.getTime() + membership.durationDays * 24 * 60 * 60 * 1000);
        }
    }
    else {
        endDate = new Date(now.getTime() + membership.durationDays * 24 * 60 * 60 * 1000);
    }
    const endTimestamp = admin.firestore.Timestamp.fromDate(endDate);
    if (productId === 'greengo_base_membership') {
        // Base membership
        await profileRef.set({
            hasBaseMembership: true,
            baseMembershipEndDate: endTimestamp,
        }, { merge: true });
        // Grant 500 bonus coins
        const balanceRef = db.collection('coinBalances').doc(userId);
        const batchEntry = {
            batchId: `membership_${Date.now()}`,
            initialCoins: 500,
            remainingCoins: 500,
            source: 'reward',
            acquiredDate: admin.firestore.Timestamp.now(),
            expirationDate: endTimestamp,
        };
        const balanceDoc = await balanceRef.get();
        if (balanceDoc.exists) {
            await balanceRef.update({
                totalCoins: admin.firestore.FieldValue.increment(500),
                earnedCoins: admin.firestore.FieldValue.increment(500),
                lastUpdated: admin.firestore.Timestamp.now(),
                coinBatches: admin.firestore.FieldValue.arrayUnion(batchEntry),
            });
        }
        else {
            await balanceRef.set({
                userId: userId,
                totalCoins: 500,
                earnedCoins: 500,
                purchasedCoins: 0,
                giftedCoins: 0,
                spentCoins: 0,
                lastUpdated: admin.firestore.Timestamp.now(),
                coinBatches: [batchEntry],
            });
        }
    }
    else {
        // Tier membership (Silver/Gold/Platinum)
        await profileRef.set({
            membershipTier: membership.tier,
            membershipEndDate: endTimestamp,
            membershipProductId: productId,
        }, { merge: true });
    }
    // Record purchase
    await db.collection('membership_purchases').doc(sessionId).set({
        userId: userId,
        productId: productId,
        tier: membership.tier,
        purchaseId: sessionId,
        platform: 'web',
        purchasedAt: admin.firestore.Timestamp.now(),
        endDate: endTimestamp,
    });
    console.log(`✅ Activated ${membership.tier} membership for user ${userId} via Stripe (expires ${endDate.toISOString()})`);
}
//# sourceMappingURL=stripeCheckout.js.map