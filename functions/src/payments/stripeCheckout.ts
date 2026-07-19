/**
 * Stripe Checkout for Web Payments
 *
 * Web has no in-app-purchase plugin, so coin packages and memberships are sold
 * through Stripe Checkout (hosted page). The Flutter web client calls
 * `createStripeCheckoutSession` to get a redirect URL, the user pays on Stripe,
 * and `stripeWebhook` credits coins / activates membership in Firestore. The
 * client polls `stripe_orders` to learn when the purchase landed.
 *
 * Secrets (set once):
 *   firebase functions:secrets:set STRIPE_SECRET_KEY
 *   firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
 */
import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';

const db = admin.firestore();

function getStripe(): Stripe {
  const secretKey = process.env.STRIPE_SECRET_KEY || '';
  if (!secretKey) {
    throw new Error(
      'STRIPE_SECRET_KEY not configured. Set it via: ' +
        'firebase functions:secrets:set STRIPE_SECRET_KEY',
    );
  }
  return new Stripe(secretKey);
}

interface ProductDef {
  name: string;
  priceUsd: number; // cents
  priceEur: number; // cents
  priceBrl: number; // centavos
}

interface CoinPackageDef extends ProductDef {
  coins: number;
}

interface MembershipDef extends ProductDef {
  durationDays: number;
  tier: string;
}

// Coin package definitions (must match Flutter CoinPackages).
const COIN_PACKAGES: Record<string, CoinPackageDef> = {
  greengo_coins_100: { coins: 100, priceUsd: 99, priceEur: 99, priceBrl: 590, name: 'Starter - 100 Coins' },
  greengo_coins_500: { coins: 500, priceUsd: 399, priceEur: 399, priceBrl: 1990, name: 'Popular - 500 Coins' },
  greengo_coins_1000: { coins: 1000, priceUsd: 699, priceEur: 699, priceBrl: 3490, name: 'Value - 1,000 Coins' },
  greengo_coins_5000: { coins: 5000, priceUsd: 2999, priceEur: 2999, priceBrl: 14990, name: 'Premium - 5,000 Coins' },
};

// Membership definitions.
const MEMBERSHIP_PRODUCTS: Record<string, MembershipDef> = {
  greengo_base_membership: { name: 'Base Membership (1 Year)', priceUsd: 999, priceEur: 999, priceBrl: 4990, durationDays: 365, tier: 'BASE' },
  '1_month_silver': { name: 'Silver Membership (1 Month)', priceUsd: 999, priceEur: 999, priceBrl: 4990, durationDays: 30, tier: 'SILVER' },
  '1_month_gold': { name: 'Gold Membership (1 Month)', priceUsd: 1999, priceEur: 1999, priceBrl: 9990, durationDays: 30, tier: 'GOLD' },
  '1_month_platinum': { name: 'Platinum Membership (1 Month)', priceUsd: 2999, priceEur: 2999, priceBrl: 14990, durationDays: 30, tier: 'PLATINUM' },
  '1_year_silver': { name: 'Silver Membership (1 Year)', priceUsd: 4899, priceEur: 4899, priceBrl: 24990, durationDays: 365, tier: 'SILVER' },
  '1_year_gold': { name: 'Gold Membership (1 Year)', priceUsd: 6999, priceEur: 6999, priceBrl: 34990, durationDays: 365, tier: 'GOLD' },
  '1_year_platinum_membership': { name: 'Platinum Membership (1 Year)', priceUsd: 8999, priceEur: 8999, priceBrl: 44990, durationDays: 365, tier: 'PLATINUM' },
};

// European countries (ISO 3166-1 alpha-2 + a few names) → charged in EUR.
const EU_COUNTRIES = new Set<string>([
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

// Accept both the English ("Brazil") and Portuguese ("Brasil") spellings.
const BRAZIL_NAMES = new Set<string>(['BR', 'BRA', 'BRAZIL', 'BRASIL']);

/**
 * Create a Stripe Checkout Session for a web purchase. Called from Flutter web.
 */
export const createStripeCheckoutSession = functions
  .runWith({ secrets: ['STRIPE_SECRET_KEY'] })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to make a purchase',
      );
    }
    const userId = context.auth.uid;
    const productId: string = data.productId;
    const successUrl: string = data.successUrl;
    const cancelUrl: string = data.cancelUrl;
    const userCountry: string = (data.userCountry || '').toUpperCase();

    if (!productId || !successUrl || !cancelUrl) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'productId, successUrl, and cancelUrl are required',
      );
    }

    const coinPackage = COIN_PACKAGES[productId];
    const membership = MEMBERSHIP_PRODUCTS[productId];
    if (!coinPackage && !membership) {
      throw new functions.https.HttpsError('invalid-argument', `Unknown product: ${productId}`);
    }
    const product: ProductDef = coinPackage || membership;
    const name = product.name;

    // Currency by user location.
    const isBrazil = BRAZIL_NAMES.has(userCountry);
    const isEurope = EU_COUNTRIES.has(userCountry);
    let currency: string;
    let priceInCents: number;
    if (isBrazil) {
      currency = 'brl';
      priceInCents = product.priceBrl;
    } else if (isEurope) {
      currency = 'eur';
      priceInCents = product.priceEur;
    } else {
      currency = 'usd';
      priceInCents = product.priceUsd;
    }

    try {
      const stripe = getStripe();
      const session = await stripe.checkout.sessions.create({
        payment_method_types: ['card'],
        line_items: [
          {
            price_data: {
              currency,
              product_data: {
                name,
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
          userId,
          productId,
          type: coinPackage ? 'coins' : 'membership',
        },
      });
      return { sessionId: session.id, url: session.url };
    } catch (error: any) {
      console.error('Stripe checkout session creation failed:', error);
      throw new functions.https.HttpsError(
        'internal',
        `Failed to create checkout session: ${error.message}`,
      );
    }
  });

/**
 * Stripe Webhook — credits coins / activates membership on completed payment.
 */
export const stripeWebhook = functions
  .runWith({ secrets: ['STRIPE_SECRET_KEY', 'STRIPE_WEBHOOK_SECRET'] })
  .https.onRequest(async (req, res) => {
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
    // C6: FAIL CLOSED. Never process an unsigned body — without the webhook
    // secret anyone could POST a fake "checkout.session.completed" and self-grant
    // coins/membership.
    if (!webhookSecret) {
      console.error('STRIPE_WEBHOOK_SECRET not configured — rejecting webhook (no unsigned processing)');
      res.status(500).send('Webhook not configured');
      return;
    }
    let event: Stripe.Event;
    try {
      const stripe = getStripe();
      const signature = req.headers['stripe-signature'] as string;
      const payload = (req as any).rawBody || Buffer.from(JSON.stringify(req.body));
      event = stripe.webhooks.constructEvent(payload, signature, webhookSecret);
    } catch (error: any) {
      console.error('Webhook signature verification failed:', error.message);
      res.status(400).send(`Webhook Error: ${error.message}`);
      return;
    }

    if (event.type === 'checkout.session.completed') {
      await handleCompletedCheckout(event.data.object as Stripe.Checkout.Session);
    }
    res.status(200).json({ received: true });
  });

async function handleCompletedCheckout(session: Stripe.Checkout.Session): Promise<void> {
  const userId = session.metadata?.userId || session.client_reference_id;
  const productId = session.metadata?.productId;
  const type = session.metadata?.type;
  if (!userId || !productId) {
    console.error('Missing userId or productId in checkout session metadata');
    return;
  }

  // Idempotency — skip if this session was already processed.
  const existingOrder = await db
    .collection('stripe_orders')
    .where('sessionId', '==', session.id)
    .limit(1)
    .get();
  if (!existingOrder.empty) {
    console.log(`Session ${session.id} already processed, skipping`);
    return;
  }

  const now = admin.firestore.Timestamp.now();
  await db.collection('stripe_orders').add({
    sessionId: session.id,
    userId,
    productId,
    type,
    amount: session.amount_total,
    currency: session.currency,
    status: 'completed',
    createdAt: now,
  });

  if (type === 'coins') {
    await creditCoins(userId, productId, session.id);
  } else if (type === 'membership') {
    await activateMembership(userId, productId, session.id);
  }
}

async function creditCoins(userId: string, productId: string, sessionId: string): Promise<void> {
  const coinPackage = COIN_PACKAGES[productId];
  if (!coinPackage) {
    console.error(`Unknown coin package: ${productId}`);
    return;
  }
  const coins = coinPackage.coins;
  const now = admin.firestore.Timestamp.now();
  const expirationDate = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
  );
  const balanceRef = db.collection('coinBalances').doc(userId);
  const batchEntry = {
    batchId: `stripe_${sessionId}`,
    initialCoins: coins,
    remainingCoins: coins,
    source: 'purchase',
    acquiredDate: now,
    expirationDate,
  };
  const balanceDoc = await balanceRef.get();
  if (balanceDoc.exists) {
    await balanceRef.update({
      totalCoins: admin.firestore.FieldValue.increment(coins),
      purchasedCoins: admin.firestore.FieldValue.increment(coins),
      lastUpdated: now,
      coinBatches: admin.firestore.FieldValue.arrayUnion(batchEntry),
    });
  } else {
    await balanceRef.set({
      userId,
      totalCoins: coins,
      purchasedCoins: coins,
      earnedCoins: 0,
      giftedCoins: 0,
      spentCoins: 0,
      lastUpdated: now,
      coinBatches: [batchEntry],
    });
  }

  await db.collection('coinTransactions').add({
    userId,
    type: 'credit',
    amount: coins,
    reason: 'coinPurchase',
    description: `Purchased ${coins} coins via Stripe`,
    createdAt: now,
    metadata: { productId, platform: 'web', stripeSessionId: sessionId },
  });
  console.log(`✅ Credited ${coins} coins to user ${userId} via Stripe`);
}

async function activateMembership(userId: string, productId: string, sessionId: string): Promise<void> {
  const membership = MEMBERSHIP_PRODUCTS[productId];
  if (!membership) {
    console.error(`Unknown membership product: ${productId}`);
    return;
  }
  const now = new Date();
  const profileRef = db.collection('profiles').doc(userId);
  const profileDoc = await profileRef.get();

  // Extend from current end date if still active, else start now.
  let endDate: Date;
  if (profileDoc.exists) {
    const dataDoc = profileDoc.data();
    const currentEndTs =
      productId === 'greengo_base_membership'
        ? dataDoc?.baseMembershipEndDate?.toDate()
        : dataDoc?.membershipEndDate?.toDate();
    if (currentEndTs && currentEndTs > now) {
      endDate = new Date(currentEndTs.getTime() + membership.durationDays * 24 * 60 * 60 * 1000);
    } else {
      endDate = new Date(now.getTime() + membership.durationDays * 24 * 60 * 60 * 1000);
    }
  } else {
    endDate = new Date(now.getTime() + membership.durationDays * 24 * 60 * 60 * 1000);
  }
  const endTimestamp = admin.firestore.Timestamp.fromDate(endDate);

  if (productId === 'greengo_base_membership') {
    await profileRef.set(
      { hasBaseMembership: true, baseMembershipEndDate: endTimestamp },
      { merge: true },
    );
    // Grant 500 bonus coins with the base membership.
    const balanceRef = db.collection('coinBalances').doc(userId);
    const batchEntry = {
      batchId: `membership_${sessionId}`,
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
    } else {
      await balanceRef.set({
        userId,
        totalCoins: 500,
        earnedCoins: 500,
        purchasedCoins: 0,
        giftedCoins: 0,
        spentCoins: 0,
        lastUpdated: admin.firestore.Timestamp.now(),
        coinBatches: [batchEntry],
      });
    }
  } else {
    await profileRef.set(
      {
        membershipTier: membership.tier,
        membershipEndDate: endTimestamp,
        membershipProductId: productId,
      },
      { merge: true },
    );
  }

  await db.collection('membership_purchases').doc(sessionId).set({
    userId,
    productId,
    tier: membership.tier,
    purchaseId: sessionId,
    platform: 'web',
    purchasedAt: admin.firestore.Timestamp.now(),
    endDate: endTimestamp,
  });
  console.log(
    `✅ Activated ${membership.tier} membership for user ${userId} via Stripe (expires ${endDate.toISOString()})`,
  );
}
