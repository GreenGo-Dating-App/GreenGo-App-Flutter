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

import { onRequest } from 'firebase-functions/v2/https';
import { OAuth2Client } from 'google-auth-library';
import * as admin from 'firebase-admin';
import { db, logInfo, logError } from '../shared/utils';
import {
  decodeAppStoreNotification,
  getGooglePlaySubscriptionExpiry,
  VoidedPurchase,
} from '../shared/purchase_verification';
import {
  clawbackCoinPurchase,
  findPurchaseLedger,
  ledgerIdFor,
} from '../coins/purchaseClawback';
import { PRODUCT_CONFIG, BASE_CATALOG_ID, toCatalogId } from './index';
import { monitored } from '../shared/monitoring';
import { SubscriptionStatus } from '../shared/types';
import {
  effectiveTier,
  hasActivePaidTier,
  normalizeStoredTier,
  tierDateFromValue,
  tierRank,
} from '../shared/effectiveTier';
import { downgradeTierNow } from '../shared/membershipExpiry';

interface MatchedSub {
  userId: string;
  ref: FirebaseFirestore.DocumentReference;
  data: FirebaseFirestore.DocumentData;
}

/** Find the most recent subscription record for a renewal/expiry key. */
async function findSubscription(key: string): Promise<MatchedSub | null> {
  const snap = await db
    .collection('subscriptions')
    .where('originalTransactionId', '==', key)
    .orderBy('createdAt', 'desc')
    .limit(1)
    .get();
  if (snap.empty) return null;
  const doc = snap.docs[0];
  return { userId: doc.data().userId as string, ref: doc.ref, data: doc.data() };
}

/**
 * Extend entitlement to `expiryMs` for a renewal. Never downgrades a higher
 * active tier (a Gold renewal must not clobber an active Platinum). The Base
 * membership is independent of the VIP tier, so it only touches the base fields.
 */
async function applyRenewal(
  userId: string,
  productId: string,
  expiryMs: number,
): Promise<void> {
  // iOS prefixes `subscription_`; Play uses bespoke IDs → PLAY_TO_CANONICAL.
  const catalogId = toCatalogId(productId);
  const config = PRODUCT_CONFIG[catalogId];
  if (!config) {
    logError(`applyRenewal: unknown productId ${productId}`);
    return;
  }
  if (expiryMs <= Date.now()) {
    logInfo(`applyRenewal: ${productId} for ${userId} already expired — ignoring`);
    return;
  }
  const now = admin.firestore.Timestamp.now();
  const expiry = admin.firestore.Timestamp.fromMillis(expiryMs);
  const profileSnap = await db.collection('profiles').doc(userId).get();
  const profile = profileSnap.data() || {};

  if (catalogId === BASE_CATALOG_ID) {
    // Base membership renews independently of the paid VIP tier. Never
    // shorten a longer existing Base period.
    const currentBaseEnd = tierDateFromValue(profile.baseMembershipEndDate);
    const newEnd = currentBaseEnd && currentBaseEnd.getTime() > expiryMs
      ? admin.firestore.Timestamp.fromDate(currentBaseEnd)
      : expiry;
    await db.collection('profiles').doc(userId).set(
      {
        hasBaseMembership: true,
        baseMembershipEndDate: newEnd,
        baseMembershipSource: 'purchase',
        updatedAt: now,
      },
      { merge: true },
    );
    logInfo(`Renewal: extended BASE membership for ${userId} to ${newEnd.toDate().toISOString()}`);
    return;
  }

  const tier = config.tier;
  const current = effectiveTier(profile);
  // Never downgrade an active, higher tier.
  if (hasActivePaidTier(profile) && tierRank(current) > tierRank(tier)) {
    logInfo(`Renewal for ${userId}: keeping higher active tier ${current} over renewed ${tier}`);
    return;
  }
  // Same tier: never shorten remaining time.
  const currentEnd = tierDateFromValue(profile.membershipEndDate);
  const newEnd =
    normalizeStoredTier(profile.membershipTier) === tier && currentEnd && currentEnd.getTime() > expiryMs
      ? admin.firestore.Timestamp.fromDate(currentEnd)
      : expiry;

  await db.collection('profiles').doc(userId).set(
    { membershipTier: tier, membershipEndDate: newEnd, membershipSource: 'purchase', updatedAt: now },
    { merge: true },
  );
  const userRef = db.collection('users').doc(userId);
  if ((await userRef.get()).exists) {
    await userRef.set(
      { subscriptionTier: tier, membershipEndDate: newEnd, updatedAt: now },
      { merge: true },
    );
  }
  logInfo(`Renewal: ${userId} -> ${tier} until ${newEnd.toDate().toISOString()}`);
}

/** Immediately revoke entitlement (refund / revoke / hard expiry). */
async function revokeEntitlement(userId: string, productId: string | undefined): Promise<void> {
  const now = admin.firestore.Timestamp.now();
  const catalogId = toCatalogId(productId || '');
  if (catalogId === BASE_CATALOG_ID) {
    await db.collection('profiles').doc(userId).set(
      { hasBaseMembership: false, baseMembershipEndDate: now, baseMembershipExpiredAt: now, updatedAt: now },
      { merge: true },
    );
    logInfo(`Revoked BASE membership for ${userId}`);
    return;
  }
  // Only remove the tier this product granted: a refunded Silver must not
  // wipe an active Platinum that came from elsewhere (coupon, other store).
  const config = PRODUCT_CONFIG[catalogId];
  const profileSnap = await db.collection('profiles').doc(userId).get();
  const current = effectiveTier(profileSnap.data());
  if (config && hasActivePaidTier(profileSnap.data()) && tierRank(current) > tierRank(config.tier)) {
    logInfo(`Revoke for ${userId}: keeping higher active tier ${current} (revoked ${config.tier})`);
    return;
  }
  const removed = await downgradeTierNow(userId, 'store_revoked');
  logInfo(`Revoked entitlement for ${userId} (product ${productId}, removed ${removed ?? 'nothing'})`);
}

/** Mark a subscription's auto-renew status (cancel keeps access until expiry). */
async function markSubscription(
  ref: FirebaseFirestore.DocumentReference,
  fields: Record<string, unknown>,
): Promise<void> {
  await ref.set({ ...fields, updatedAt: admin.firestore.Timestamp.now() }, { merge: true });
}

// ========== REFUNDS / CHARGEBACKS (security audit H-10) ==========

/**
 * A Google Play purchase was voided (refund, chargeback, revoke). Shared by
 * the RTDN `voidedPurchaseNotification` and the daily Voided Purchases API
 * poll (pollPlayVoidedPurchases). Idempotent: replays change nothing.
 *   - coin purchase (purchaseLedger match) -> coins clawed back,
 *   - subscription -> entitlement revoked, but only when the voided order is
 *     the subscription's CURRENT period (a refunded past renewal takes
 *     nothing away), confirmed with the Play API.
 * Throws on a transient Play API failure so the caller retries.
 */
export async function processPlayVoidedPurchase(
  v: VoidedPurchase & { productType?: number },
  source: 'rtdn' | 'voided_poll',
): Promise<string> {
  const details = {
    orderId: v.orderId ?? null,
    voidedReason: v.voidedReason ?? null,
    voidedSource: v.voidedSource ?? null,
    refundType: v.refundType ?? null,
    voidedTimeMillis: v.voidedTimeMillis ?? null,
  };

  // productType 1 = subscription; 2 (one-time) or unknown -> try the coin ledger.
  if (v.productType !== 1) {
    const ledgerRef = await findPurchaseLedger({
      purchaseToken: v.purchaseToken,
      transactionId: v.orderId,
    });
    if (ledgerRef) {
      const r = await clawbackCoinPurchase(ledgerRef, {
        store: 'google_play', reason: 'play_voided', source, details,
      });
      return `coins_${r.action}`;
    }
  }

  const match = await findSubscription(v.purchaseToken);
  if (!match) {
    // Bought before the ledger existed, or not ours: queue for review once.
    await db.collection('fraud_flags')
      .doc(`voided_unmatched_${ledgerIdFor(`${v.purchaseToken}|${v.orderId ?? ''}`)}`)
      .set({
        type: 'purchase_refunded_unmatched',
        store: 'google_play',
        source,
        productType: v.productType ?? null,
        ...details,
        createdAt: admin.firestore.Timestamp.now(),
        reviewed: false,
      }, { merge: true });
    return 'unmatched';
  }

  const voided: string[] = Array.isArray(match.data.voidedOrderIds) ? match.data.voidedOrderIds : [];
  const orderKey = v.orderId || v.purchaseToken.slice(0, 64);
  if (voided.includes(orderKey)) return 'subscription_already';

  const exp = await getGooglePlaySubscriptionExpiry(v.purchaseToken);
  if (exp.apiUnavailable || exp.error) {
    throw new Error(`Play API unavailable for voided subscription: ${exp.error || 'not configured'}`);
  }
  const currentPeriod = !v.orderId || !exp.latestOrderId || exp.latestOrderId === v.orderId;
  const now = admin.firestore.Timestamp.now();
  if (currentPeriod) {
    await revokeEntitlement(match.userId, match.data.productId as string);
    await markSubscription(match.ref, { status: SubscriptionStatus.EXPIRED, autoRenewing: false });
  }
  await match.ref.set(
    { voidedOrderIds: admin.firestore.FieldValue.arrayUnion(orderKey), updatedAt: now },
    { merge: true },
  );
  await db.collection('fraud_flags').doc(`refund_sub_${ledgerIdFor(orderKey)}`).set({
    type: 'purchase_refunded',
    store: 'google_play',
    source,
    userId: match.userId,
    productId: match.data.productId ?? null,
    entitlementRevoked: currentPeriod,
    ...details,
    createdAt: now,
    reviewed: false,
  });
  return currentPeriod ? 'subscription_revoked' : 'subscription_past_period';
}

const APPLE_REFUND_TYPES = new Set(['REFUND', 'REVOKE']);

// ========== APP STORE SERVER NOTIFICATIONS V2 ==========

export const appStoreNotificationsV2 = onRequest(
  { memory: '512MiB', timeoutSeconds: 30 },
  monitored("appStoreNotificationsV2", async (req, res) => {
    try {
      const signedPayload = req.body?.signedPayload;
      if (!signedPayload || typeof signedPayload !== 'string') {
        logError('appStoreNotificationsV2: missing signedPayload');
        res.status(400).send('Missing signedPayload');
        return;
      }
      const appAppleId = parseInt(process.env.APPLE_APP_ID || '0', 10);
      const info = await decodeAppStoreNotification(signedPayload, appAppleId);
      logInfo(
        `App Store notification: ${info.notificationType}/${info.subtype || '-'} ` +
        `product=${info.productId} origTxn=${info.originalTransactionId}`,
      );

      // Consumable (coin) refunds: match the coin ledger by transactionId and
      // claw the coins back. Subscriptions fall through to the path below.
      if (APPLE_REFUND_TYPES.has(info.notificationType) && info.transactionId) {
        const ledgerRef = await findPurchaseLedger({ transactionId: info.transactionId });
        if (ledgerRef) {
          const r = await clawbackCoinPurchase(ledgerRef, {
            store: 'app_store',
            reason: info.notificationType === 'REFUND' ? 'apple_refund' : 'apple_revoke',
            source: 'asn_v2',
            details: {
              transactionId: info.transactionId,
              revocationDateMs: info.revocationDateMs ?? null,
              revocationReason: info.revocationReason ?? null,
              environment: info.environment ?? null,
              notificationUUID: info.notificationUUID ?? null,
            },
          });
          logInfo(`App Store ${info.notificationType} for coin transaction: ${r.action}`);
          res.status(200).send('OK');
          return;
        }
      }

      // The customer asked Apple for a refund of a consumable. Apple accepts
      // consumption info for 12h via the App Store Server API (needs an
      // In-App Purchase API key, not configured yet); until then the request
      // is recorded for review and Apple decides without it.
      if (info.notificationType === 'CONSUMPTION_REQUEST') {
        const key = info.transactionId || info.notificationUUID || 'unknown';
        await db.collection('apple_consumption_requests').doc(key).set({
          transactionId: info.transactionId ?? null,
          productId: info.productId ?? null,
          productType: info.productType ?? null,
          environment: info.environment ?? null,
          reason: info.consumptionRequestReason ?? null,
          notificationUUID: info.notificationUUID ?? null,
          receivedAt: admin.firestore.Timestamp.now(),
          responded: false,
        }, { merge: true });
        res.status(200).send('OK');
        return;
      }

      if (info.notificationType === 'REFUND_REVERSED' && info.transactionId) {
        const ledgerRef = await findPurchaseLedger({ transactionId: info.transactionId });
        if (ledgerRef) {
          // Clawed-back coins are not re-credited automatically: review.
          await db.collection('fraud_flags').doc(`refund_reversed_${ledgerRef.id}`).set({
            type: 'refund_reversed',
            store: 'app_store',
            ledgerId: ledgerRef.id,
            transactionId: info.transactionId,
            createdAt: admin.firestore.Timestamp.now(),
            reviewed: false,
          }, { merge: true });
          res.status(200).send('OK');
          return;
        }
      }

      if (!info.originalTransactionId) {
        res.status(200).send('No transaction info'); // ack — nothing to do
        return;
      }
      const match = await findSubscription(info.originalTransactionId);
      if (!match) {
        logInfo(`No subscription record for originalTransactionId ${info.originalTransactionId}`);
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
              status: SubscriptionStatus.ACTIVE,
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
          await markSubscription(match.ref, { status: SubscriptionStatus.EXPIRED, autoRenewing: false });
          break;
        default:
          logInfo(`App Store notification ${info.notificationType} — no action`);
      }

      res.status(200).send('OK');
    } catch (err) {
      logError('appStoreNotificationsV2 error:', err);
      // 500 lets Apple retry on transient failures.
      res.status(500).send('Error');
    }
  }),
);

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
} as const;


// Security audit H-09: this endpoint accepted ANY POST, so a forged
// REVOKED/EXPIRED message with a known purchase token downgraded a paying user.
// Pub/Sub push must be configured with an OIDC token (see RTDN_PUSH_SA); the
// token is verified here before anything is read.
const RTDN_PUSH_SA =
  process.env.RTDN_PUSH_SA || '666632803027-compute@developer.gserviceaccount.com';
const RTDN_AUDIENCES = [
  'https://us-central1-greengo-chat.cloudfunctions.net/playStoreNotifications',
  'https://playstorenotifications-zrx7rexaxa-uc.a.run.app',
];
const oidcClient = new OAuth2Client();

async function isAuthenticPubSubPush(authHeader: string | undefined): Promise<boolean> {
  const m = /^Bearer (.+)$/.exec(authHeader || '');
  if (!m) return false;
  try {
    const ticket = await oidcClient.verifyIdToken({ idToken: m[1], audience: RTDN_AUDIENCES });
    const p = ticket.getPayload();
    return !!p && p.email === RTDN_PUSH_SA && p.email_verified === true;
  } catch {
    return false;
  }
}

export const playStoreNotifications = onRequest(
  { memory: '512MiB', timeoutSeconds: 30 },
  monitored("playStoreNotifications", async (req, res) => {
    try {
      if (!(await isAuthenticPubSubPush(req.get('authorization')))) {
        logError('playStoreNotifications: rejected unauthenticated push');
        res.status(401).send('Unauthorized');
        return;
      }
      // Pub/Sub push delivers the RTDN base64-encoded in message.data.
      const encoded = req.body?.message?.data;
      if (!encoded) {
        res.status(200).send('No message'); // ack non-RTDN pings
        return;
      }
      const decoded = JSON.parse(Buffer.from(encoded, 'base64').toString('utf8'));

      // Refund / chargeback / revoke of a one-time product or subscription.
      const voided = decoded?.voidedPurchaseNotification;
      if (voided?.purchaseToken) {
        const outcome = await processPlayVoidedPurchase({
          purchaseToken: String(voided.purchaseToken),
          orderId: voided.orderId ? String(voided.orderId) : undefined,
          refundType: typeof voided.refundType === 'number' ? voided.refundType : undefined,
          productType: typeof voided.productType === 'number' ? voided.productType : undefined,
          voidedTimeMillis: decoded?.eventTimeMillis ? Number(decoded.eventTimeMillis) : undefined,
        }, 'rtdn');
        logInfo(`Play RTDN voided purchase: ${outcome}`);
        res.status(200).send('OK');
        return;
      }

      const sub = decoded?.subscriptionNotification;
      if (!sub?.purchaseToken) {
        res.status(200).send('Not a subscription notification');
        return;
      }
      const { purchaseToken, notificationType, subscriptionId } = sub;
      logInfo(`Play RTDN: type=${notificationType} product=${subscriptionId}`);

      const match = await findSubscription(purchaseToken);
      if (!match) {
        logInfo(`No subscription record for Play token (RTDN type ${notificationType})`);
        res.status(200).send('Unknown subscription');
        return;
      }

      switch (notificationType) {
        case PLAY.RENEWED:
        case PLAY.RECOVERED:
        case PLAY.RESTARTED:
        case PLAY.PURCHASED: {
          const exp = await getGooglePlaySubscriptionExpiry(purchaseToken);
          const productId = exp.productId || subscriptionId || (match.data.productId as string);
          if (exp.expiresDateMs && productId) {
            await applyRenewal(match.userId, productId, exp.expiresDateMs);
            await markSubscription(match.ref, {
              status: SubscriptionStatus.ACTIVE,
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
        case PLAY.REVOKED: {
          // Never revoke on the message alone: ask Google. If the store still
          // reports a future expiry (or can't be reached), leave access alone;
          // the hourly expiry job downgrades at membershipEndDate anyway.
          const check = await getGooglePlaySubscriptionExpiry(purchaseToken);
          if (!check.expiresDateMs || check.expiresDateMs > Date.now()) {
            logInfo(`Play RTDN type ${notificationType}: not confirmed by Play API — no revoke`);
            break;
          }
          await revokeEntitlement(match.userId, match.data.productId as string);
          await markSubscription(match.ref, { status: SubscriptionStatus.EXPIRED, autoRenewing: false });
          break;
        }
        case PLAY.IN_GRACE_PERIOD:
          // Payment issue; access continues until membershipEndDate, then the
          // hourly expiry job downgrades unless RECOVERED extends it.
          await markSubscription(match.ref, { status: SubscriptionStatus.IN_GRACE_PERIOD });
          break;
        case PLAY.ON_HOLD:
          // Grace is over and payment still failing: Play has suspended access.
          // Status only — membershipEndDate (Play's expiryTime) has passed, so
          // the hourly expiry job downgrades; RECOVERED → applyRenewal restores.
          await markSubscription(match.ref, { status: SubscriptionStatus.ON_HOLD });
          break;
        default:
          logInfo(`Play RTDN type ${notificationType} — no action`);
      }

      res.status(200).send('OK');
    } catch (err) {
      logError('playStoreNotifications error:', err);
      res.status(500).send('Error');
    }
  }),
);
