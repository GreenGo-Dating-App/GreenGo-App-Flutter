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
import * as admin from 'firebase-admin';
import { db, logInfo, logError } from '../shared/utils';
import { TierName } from '../shared/grants';
import {
  decodeAppStoreNotification,
  getGooglePlaySubscriptionExpiry,
} from '../shared/purchase_verification';
import { PRODUCT_CONFIG } from './index';
import { monitored } from '../shared/monitoring';

const TIER_RANK: Record<string, number> = { BASIC: 0, SILVER: 1, GOLD: 2, PLATINUM: 3 };
const BASE_PRODUCT_ID = 'greengo_base_membership';

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
  // iOS subscription IDs are prefixed `subscription_`; normalize to catalog key.
  const catalogId = productId.replace(/^subscription_/, '');
  const config = PRODUCT_CONFIG[catalogId];
  if (!config) {
    logError(`applyRenewal: unknown productId ${productId}`);
    return;
  }
  const now = admin.firestore.Timestamp.now();
  const expiry = admin.firestore.Timestamp.fromMillis(expiryMs);

  if (catalogId === BASE_PRODUCT_ID) {
    // Base membership renews independently of the paid VIP tier.
    await db.collection('profiles').doc(userId).set(
      { hasBaseMembership: true, baseMembershipEndDate: expiry, updatedAt: now },
      { merge: true },
    );
    logInfo(`Renewal: extended BASE membership for ${userId} to ${expiry.toDate().toISOString()}`);
    return;
  }

  const tier = config.tier;
  const profileSnap = await db.collection('profiles').doc(userId).get();
  const currentTier = (profileSnap.data()?.membershipTier as string) || 'BASIC';
  const currentEnd = (profileSnap.data()?.membershipEndDate as admin.firestore.Timestamp | undefined)
    ?.toDate();
  const currentActive = currentEnd ? currentEnd.getTime() > Date.now() : false;

  // Never downgrade an active, higher tier.
  if (currentActive && (TIER_RANK[currentTier] ?? 0) > (TIER_RANK[tier] ?? 0)) {
    logInfo(
      `Renewal for ${userId}: keeping higher active tier ${currentTier} over renewed ${tier}`,
    );
    return;
  }

  await db.collection('profiles').doc(userId).set(
    { membershipTier: tier, membershipEndDate: expiry, updatedAt: now },
    { merge: true },
  );
  await db.collection('users').doc(userId).set(
    { subscriptionTier: tier, membershipEndDate: expiry, updatedAt: now },
    { merge: true },
  );
  logInfo(`Renewal: ${userId} -> ${tier} until ${expiry.toDate().toISOString()}`);
}

/** Immediately revoke entitlement (refund / revoke / hard expiry). */
async function revokeEntitlement(userId: string, productId: string | undefined): Promise<void> {
  const now = admin.firestore.Timestamp.now();
  const catalogId = (productId || '').replace(/^subscription_/, '');
  if (catalogId === BASE_PRODUCT_ID) {
    await db.collection('profiles').doc(userId).set(
      { hasBaseMembership: false, baseMembershipEndDate: now, updatedAt: now },
      { merge: true },
    );
    return;
  }
  await db.collection('profiles').doc(userId).set(
    { membershipTier: 'BASIC', updatedAt: now },
    { merge: true },
  );
  await db.collection('users').doc(userId).set(
    { subscriptionTier: 'BASIC', updatedAt: now },
    { merge: true },
  );
  logInfo(`Revoked entitlement for ${userId} (product ${productId})`);
}

/** Mark a subscription's auto-renew status (cancel keeps access until expiry). */
async function markSubscription(
  ref: FirebaseFirestore.DocumentReference,
  fields: Record<string, unknown>,
): Promise<void> {
  await ref.set({ ...fields, updatedAt: admin.firestore.Timestamp.now() }, { merge: true });
}

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

export const playStoreNotifications = onRequest(
  { memory: '512MiB', timeoutSeconds: 30 },
  monitored("playStoreNotifications", async (req, res) => {
    try {
      // Pub/Sub push delivers the RTDN base64-encoded in message.data.
      const encoded = req.body?.message?.data;
      if (!encoded) {
        res.status(200).send('No message'); // ack non-RTDN pings
        return;
      }
      const decoded = JSON.parse(Buffer.from(encoded, 'base64').toString('utf8'));
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
          await revokeEntitlement(match.userId, match.data.productId as string);
          await markSubscription(match.ref, { status: 'EXPIRED', autoRenewing: false });
          break;
        case PLAY.ON_HOLD:
        case PLAY.IN_GRACE_PERIOD:
          // Payment issue; keep access during grace, just flag it.
          await markSubscription(match.ref, { status: 'GRACE' });
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
