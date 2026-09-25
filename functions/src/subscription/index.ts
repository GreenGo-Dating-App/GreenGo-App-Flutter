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

import * as crypto from 'crypto';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logInfo, logError, db } from '../shared/utils';
import * as admin from 'firebase-admin';
import { SubscriptionStatus } from '../shared/types';
import {
  verifyGooglePlaySubscription,
  verifyAppStorePurchase,
} from '../shared/purchase_verification';
import {
  TierName,
  computeMembershipExtension,
  grantCoins,
} from '../shared/grants';
import {
  LEGACY_BASIC_STORED_VALUES,
  PAID_TIER_STORED_VALUES,
  USERS_FREE_TIER,
  effectiveTier,
  hasActivePaidTier,
  isPaidTier,
  isProfileAdmin,
  normalizeStoredTier,
  tierDateFromValue,
} from '../shared/effectiveTier';
import { WriteQueue, planBaseExpiry, planTierExpiry } from '../shared/membershipExpiry';

// Product ID → tier and duration mapping.
// `price` is NOT charged anywhere — the stores charge what Play Console / App
// Store Connect say. It is only what gets recorded on `subscriptions.price` and
// `purchases.price`, so revenue reporting reads it. Keep it in sync with the USD
// prices in `payments/stripeCheckout.ts` MEMBERSHIP_PRODUCTS and with the store
// consoles — nothing syncs them automatically.
//
// The Base product's `tier` is never written to `membershipTier`: Base is the
// separate hasBaseMembership/baseMembershipEndDate entitlement.
export const PRODUCT_CONFIG: Record<string, { tier: TierName; durationDays: number; price: number }> = {
  'greengo_base_membership': { tier: 'BASIC', durationDays: 365, price: 4.99 },
  '1_month_silver': { tier: 'SILVER', durationDays: 30, price: 9.99 },
  '1_year_silver': { tier: 'SILVER', durationDays: 365, price: 48.99 },
  '1_month_gold': { tier: 'GOLD', durationDays: 30, price: 19.99 },
  '1_year_gold': { tier: 'GOLD', durationDays: 365, price: 69.99 },
  '1_month_platinum': { tier: 'PLATINUM', durationDays: 30, price: 29.99 },
  '1_year_platinum_membership': { tier: 'PLATINUM', durationDays: 365, price: 89.99 },
};

export const BASE_CATALOG_ID = 'greengo_base_membership';

// Google Play uses bespoke subscription IDs that differ from the canonical
// PRODUCT_CONFIG keys (iOS just adds a `subscription_` prefix). Map Play → canonical.
export const PLAY_TO_CANONICAL: Record<string, string> = {
  'greengo_base_membership': 'greengo_base_membership',
  'silver_premium_monthly': '1_month_silver',
  'greengo_silver_yearly': '1_year_silver',
  'gold_premium_monthly': '1_month_gold',
  'greengo_gold_yearly': '1_year_gold',
  'platinum_vip_monthly': '1_month_platinum',
  'greengo_platinum_yearly': '1_year_platinum_membership',
};

/** Normalize a store product ID (iOS `subscription_` prefix / Play bespoke ID) to the catalog key. */
export function toCatalogId(productId: string): string {
  return PLAY_TO_CANONICAL[productId] ?? productId.replace(/^subscription_/, '');
}

/** Membership idempotency ledger: one doc per (store subscription, billing period). */
const MEMBERSHIP_LEDGER = 'membershipLedger';

function ledgerDocId(raw: string): string {
  return crypto.createHash('sha256').update(raw).digest('hex');
}

// ========== 0. VERIFY PURCHASE (Callable) ==========

export const verifyPurchase = onCall(
  {
    memory: '512MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { userId, platform, productId, purchaseToken, verificationData } = request.data;

    // Validate required fields
    if (!userId || !platform || !productId || !purchaseToken) {
      throw new HttpsError('invalid-argument', 'Missing required fields');
    }

    // Ensure the authenticated user matches the userId
    if (request.auth.uid !== userId) {
      throw new HttpsError('permission-denied', 'User ID mismatch');
    }

    const userEmail = request.auth.token.email || null;

    try {
      logInfo(`Verifying membership purchase for user ${userId} (${userEmail}), product ${productId}, platform ${platform}`);

      const catalogId = toCatalogId(productId);
      const config = PRODUCT_CONFIG[catalogId];
      if (!config) {
        throw new HttpsError('invalid-argument', `Unknown product ID: ${productId}`);
      }
      const isBase = catalogId === BASE_CATALOG_ID;
      const tier = config.tier;
      const durationDays = config.durationDays;
      const durationMs = durationDays * 24 * 60 * 60 * 1000;

      // ── Verify with the store ──
      let verified = false;
      let storeExpired = false;
      let storeRevoked = false;
      // Subscription identity used to match later renewal/expiry notifications.
      // iOS: Apple's originalTransactionId. Android: the subscription purchase token.
      let originalTransactionId: string | undefined;
      let storeExpiryMs: number | undefined;

      if (platform === 'android') {
        if (!verificationData) {
          throw new HttpsError('invalid-argument', 'Missing verificationData for Android purchase');
        }
        const result = await verifyGooglePlaySubscription(verificationData);
        verified = result.verified;
        storeExpired = result.expired === true;
        storeRevoked = result.revoked === true;
        originalTransactionId = verificationData; // Play RTDN matches on purchaseToken
        storeExpiryMs = result.expiresDateMs;
        if (!verified) {
          logError(`Google Play verification failed for ${productId}: ${result.error}`);
        }
        // The token must belong to the product being claimed — otherwise a
        // monthly Silver token could be presented as yearly Platinum.
        if (verified && result.productId && toCatalogId(result.productId) !== catalogId) {
          logError(`Play token product ${result.productId} does not match claimed ${productId}`);
          throw new HttpsError('failed-precondition', 'Purchase does not match product');
        }
      } else if (platform === 'ios') {
        if (!verificationData) {
          throw new HttpsError('invalid-argument', 'Missing verificationData for iOS purchase');
        }
        const appAppleId = parseInt(process.env.APPLE_APP_ID || '0', 10);
        const result = await verifyAppStorePurchase(verificationData, productId, appAppleId);
        verified = result.verified;
        storeExpired = result.expired === true;
        storeRevoked = result.revoked === true;
        originalTransactionId = result.originalTransactionId;
        storeExpiryMs = result.expiresDateMs;
        if (!verified) {
          logError(`App Store verification failed for ${productId}: ${result.error}`);
        }
      } else {
        logError(`Unknown platform: ${platform}`);
        throw new HttpsError('invalid-argument', `Unsupported platform: ${platform}`);
      }

      if (!verified) {
        throw new HttpsError('failed-precondition', 'Purchase verification failed');
      }

      const now = admin.firestore.Timestamp.now();
      const nowDate = now.toDate();

      // ── Expired / revoked store transaction → NEVER grant, write NOTHING ──
      // restorePurchases() replays every historical transaction on each launch;
      // granting on those resurrected lapsed tiers (e.g. Platinum forever).
      if (
        storeExpired ||
        storeRevoked ||
        (storeExpiryMs !== undefined && storeExpiryMs <= nowDate.getTime())
      ) {
        const profileSnap = await db.collection('profiles').doc(userId).get();
        logInfo(
          `verifyPurchase: ${productId} for ${userId} is ${storeRevoked ? 'revoked' : 'expired'} ` +
          `(store expiry ${storeExpiryMs ? new Date(storeExpiryMs).toISOString() : 'n/a'}) — no grant`,
        );
        return {
          verified: true,
          expired: true,
          revoked: storeRevoked,
          productId,
          storeExpiry: storeExpiryMs ? new Date(storeExpiryMs).toISOString() : null,
          tier: effectiveTier(profileSnap.data(), nowDate),
          coinsGranted: 0,
        };
      }

      // CRITICAL: Prevent shared billing account abuse.
      const tokenSnapshot = await db
        .collection('subscriptions')
        .where('purchaseToken', '==', purchaseToken)
        .limit(1)
        .get();

      if (!tokenSnapshot.empty) {
        const existingOwner = tokenSnapshot.docs[0].data().userId;
        if (existingOwner !== userId) {
          logInfo(`Purchase token already belongs to user ${existingOwner}, rejecting for user ${userId}`);
          throw new HttpsError(
            'already-exists',
            'This purchase is already linked to a different account.'
          );
        }
      }

      const purchaseTokenCheck = await db
        .collection('purchases')
        .where('purchaseToken', '==', purchaseToken)
        .limit(1)
        .get();

      if (!purchaseTokenCheck.empty) {
        const purchaseOwner = purchaseTokenCheck.docs[0].data().userId;
        if (purchaseOwner !== userId) {
          throw new HttpsError(
            'already-exists',
            'This purchase is already linked to a different account.'
          );
        }
      }

      // ── Idempotency: one grant per (platform, store subscription, period) ──
      const identity = originalTransactionId || purchaseToken;
      const ledgerKey = `${platform}_${identity}_${storeExpiryMs ?? 'noexp'}`;
      const ledgerRef = db.collection(MEMBERSHIP_LEDGER).doc(ledgerDocId(ledgerKey));
      const bonusRef = db
        .collection(MEMBERSHIP_LEDGER)
        .doc(ledgerDocId(`${platform}_${identity}_base_bonus`));
      const profileRef = db.collection('profiles').doc(userId);
      const userRef = db.collection('users').doc(userId);

      const outcome = await db.runTransaction(async (tx) => {
        // All reads first (Firestore transaction rule).
        const ledgerSnap = await tx.get(ledgerRef);
        const profileSnap = await tx.get(profileRef);
        const userSnap = await tx.get(userRef);
        const bonusSnap = isBase ? await tx.get(bonusRef) : null;
        const profileData = profileSnap.data() || {};

        if (ledgerSnap.exists) {
          const l = ledgerSnap.data() || {};
          if (l.userId && l.userId !== userId) {
            throw new HttpsError('already-exists', 'This purchase is already linked to a different account.');
          }
          return {
            alreadyProcessed: true,
            tier: effectiveTier(profileData, nowDate) as string,
            endDate: tierDateFromValue(isBase ? profileData.baseMembershipEndDate : profileData.membershipEndDate),
            grantBonus: false,
          };
        }

        const profileUpdate: Record<string, any> = { updatedAt: now };
        const userUpdate: Record<string, any> = { updatedAt: now };
        let resultTier: string;
        let resultEnd: Date;
        let grantBonus = false;

        if (isBase) {
          // Base NEVER sets a paid tier. Extend/set the Base fields only.
          const currentBaseEnd = tierDateFromValue(profileData.baseMembershipEndDate);
          let newBaseEnd: Date;
          if (storeExpiryMs !== undefined) {
            const storeEnd = new Date(storeExpiryMs);
            // Never shorten an existing (e.g. coupon-granted) Base period.
            newBaseEnd = currentBaseEnd && currentBaseEnd > storeEnd ? currentBaseEnd : storeEnd;
          } else {
            const start = currentBaseEnd && currentBaseEnd > nowDate ? currentBaseEnd : nowDate;
            newBaseEnd = new Date(start.getTime() + durationMs);
          }
          profileUpdate.hasBaseMembership = true;
          profileUpdate.baseMembershipEndDate = admin.firestore.Timestamp.fromDate(newBaseEnd);
          profileUpdate.baseMembershipSource = 'purchase';

          // Leave an active paid tier alone; otherwise normalise a stale
          // 'BASIC'/expired tier to FREE (TEST and admins untouched).
          const stored = normalizeStoredTier(profileData.membershipTier);
          if (
            !hasActivePaidTier(profileData, nowDate) &&
            stored !== 'TEST' &&
            !isProfileAdmin(profileData) &&
            profileData.membershipTier !== 'FREE'
          ) {
            profileUpdate.membershipTier = 'FREE';
            if (profileData.membershipTier) {
              profileUpdate.previousMembershipTier = String(profileData.membershipTier);
            }
            userUpdate.subscriptionTier = USERS_FREE_TIER;
          }
          resultTier = (profileUpdate.membershipTier as string) ?? effectiveTier(profileData, nowDate);
          resultEnd = newBaseEnd;

          if (bonusSnap && !bonusSnap.exists) {
            tx.create(bonusRef, { userId, platform, identity, kind: 'base_bonus', createdAt: now });
            grantBonus = true;
          }
        } else {
          const currentStored = normalizeStoredTier(profileData.membershipTier);
          const currentEnd = tierDateFromValue(profileData.membershipEndDate);
          const ext = computeMembershipExtension(currentStored, currentEnd, tier, durationMs, nowDate);
          let newEnd: Date;
          if (ext.effectiveTier !== tier) {
            // A HIGHER tier is active: keep it and queue this purchase's time
            // after it (never downgrade an active higher tier).
            newEnd = ext.newEndDate;
          } else if (
            hasActivePaidTier(profileData, nowDate) &&
            currentStored === tier &&
            currentEnd
          ) {
            // Same tier renewal: the store expiry is authoritative, but never
            // shorten remaining (e.g. coupon-granted) time.
            newEnd = storeExpiryMs !== undefined
              ? new Date(Math.max(storeExpiryMs, currentEnd.getTime()))
              : ext.newEndDate;
          } else {
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
        tx.set(db.collection('subscriptions').doc(), {
          userId,
          userEmail,
          tier: recordTier,
          status: SubscriptionStatus.ACTIVE,
          startDate: now,
          endDate: isBase
            ? (profileUpdate.baseMembershipEndDate as admin.firestore.Timestamp)
            : (profileUpdate.membershipEndDate as admin.firestore.Timestamp),
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

        tx.set(db.collection('purchases').doc(), {
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
        await grantCoins(userId, 500, 'membership_bonus', 'Base membership welcome bonus', { productId });
        coinsGranted = 500;
      }

      const endIso = outcome.endDate ? outcome.endDate.toISOString() : null;
      logInfo(
        `Membership purchase verified for user ${userId}: product=${catalogId} tier=${outcome.tier} ` +
        `endDate=${endIso} coins=${coinsGranted}${outcome.alreadyProcessed ? ' (already processed)' : ''}`,
      );

      return {
        verified: true,
        expired: false,
        alreadyProcessed: outcome.alreadyProcessed,
        tier: outcome.tier,
        endDate: endIso,
        ...(isBase ? { baseMembershipEndDate: endIso } : {}),
        coinsGranted,
      };
    } catch (error) {
      logError('Error verifying purchase:', error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError('internal', 'Failed to verify purchase');
    }
  }
);

// ========== 1. CHECK EXPIRING MEMBERSHIPS (Scheduled - Daily 9am) ==========

export const checkExpiringSubscriptions = onSchedule(
  {
    schedule: '0 9 * * *', // Daily at 9 AM UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 300,
  },
  async () => {
    logInfo('Checking for expiring memberships');

    try {
      const threeDaysFromNow = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);

      // Find profiles with membership ending within 3 days
      const snapshot = await db
        .collection('profiles')
        .where('membershipEndDate', '<', admin.firestore.Timestamp.fromDate(threeDaysFromNow))
        .where('membershipEndDate', '>', admin.firestore.Timestamp.now())
        .get();

      logInfo(`Found ${snapshot.size} memberships expiring soon`);

      for (const doc of snapshot.docs) {
        const data = doc.data();
        // Only an active PAID tier can "expire soon" (FREE/'BASIC' profiles keep
        // an old membershipEndDate for history).
        if (!isPaidTier(effectiveTier(data)) || isProfileAdmin(data)) continue;
        const endDate = data.membershipEndDate?.toDate();
        if (!endDate) continue;

        const daysUntilExpiry = Math.ceil(
          (endDate.getTime() - Date.now()) / (24 * 60 * 60 * 1000)
        );

        await db.collection('notifications').add({
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

        logInfo(`Sent expiry reminder to user ${doc.id}`);
      }

      logInfo('Expiring memberships check completed');
    } catch (error) {
      logError('Error checking expiring memberships:', error);
      throw error;
    }
  }
);

// ========== 2. HANDLE EXPIRED MEMBERSHIPS (Scheduled - Hourly) ==========

const EXPIRY_PAGE_SIZE = 200;
/** Stop starting new pages after this long; the next hourly run continues. */
const EXPIRY_TIME_BUDGET_MS = 480_000;

/**
 * Paid tier (SILVER/GOLD/PLATINUM, plus the legacy 'BASIC' the client reads
 * as SILVER) whose membershipEndDate has passed → membershipTier 'FREE'.
 * Never touches the Base membership. Skips TEST and admins. Paginated and
 * idempotent: a downgraded profile no longer matches the query.
 *
 * Index: profiles (membershipTier ASC, membershipEndDate ASC) — already in
 * firestore.indexes.json.
 */
export const handleExpiredMemberships = onSchedule(
  {
    schedule: '0 * * * *', // Every hour
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
  },
  async () => {
    const started = Date.now();
    const now = admin.firestore.Timestamp.now();
    const queue = new WriteQueue();
    let scanned = 0;
    let downgraded = 0;
    let cursor: FirebaseFirestore.QueryDocumentSnapshot | undefined;

    try {
      // eslint-disable-next-line no-constant-condition
      while (true) {
        if (Date.now() - started > EXPIRY_TIME_BUDGET_MS) {
          logInfo('handleExpiredMemberships: time budget reached, continuing next run');
          break;
        }
        let q = db
          .collection('profiles')
          .where('membershipTier', 'in', [...PAID_TIER_STORED_VALUES, ...LEGACY_BASIC_STORED_VALUES])
          .where('membershipEndDate', '<', now)
          .orderBy('membershipEndDate', 'asc')
          .limit(EXPIRY_PAGE_SIZE);
        if (cursor) q = q.startAfter(cursor);
        const snap = await q.get();
        if (snap.empty) break;
        cursor = snap.docs[snap.docs.length - 1];

        for (const doc of snap.docs) {
          scanned++;
          try {
            const removed = await planTierExpiry(doc, queue, { reason: 'expired', now });
            if (removed !== null) {
              downgraded++;
              logInfo(`Downgraded user ${doc.id} from ${removed} to FREE`);
            }
          } catch (e) {
            logError(`handleExpiredMemberships: failed for ${doc.id}`, e);
          }
        }
        await queue.flush();
        if (snap.size < EXPIRY_PAGE_SIZE) break;
      }
      await queue.flush();
      logInfo(`handleExpiredMemberships: scanned=${scanned} downgraded=${downgraded} ops=${queue.committedOps}`);
    } catch (error) {
      logError('Error handling expired memberships:', error);
      throw error;
    }
  }
);

// ========== 3. HANDLE EXPIRED BASE MEMBERSHIPS (Scheduled - Hourly) ==========

/**
 * hasBaseMembership == true && baseMembershipEndDate < now →
 * hasBaseMembership false + baseMembershipExpiredAt. Never touches the tier.
 *
 * Index: profiles (hasBaseMembership ASC, baseMembershipEndDate ASC) — NEW in
 * firestore.indexes.json; deploy it before this function.
 */
export const handleExpiredBaseMemberships = onSchedule(
  {
    schedule: '15 * * * *', // Every hour, offset from the tier job
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
  },
  async () => {
    const started = Date.now();
    const now = admin.firestore.Timestamp.now();
    const queue = new WriteQueue();
    let scanned = 0;
    let expired = 0;
    let cursor: FirebaseFirestore.QueryDocumentSnapshot | undefined;

    try {
      // eslint-disable-next-line no-constant-condition
      while (true) {
        if (Date.now() - started > EXPIRY_TIME_BUDGET_MS) {
          logInfo('handleExpiredBaseMemberships: time budget reached, continuing next run');
          break;
        }
        let q = db
          .collection('profiles')
          .where('hasBaseMembership', '==', true)
          .where('baseMembershipEndDate', '<', now)
          .orderBy('baseMembershipEndDate', 'asc')
          .limit(EXPIRY_PAGE_SIZE);
        if (cursor) q = q.startAfter(cursor);
        const snap = await q.get();
        if (snap.empty) break;
        cursor = snap.docs[snap.docs.length - 1];

        for (const doc of snap.docs) {
          scanned++;
          if (await planBaseExpiry(doc, queue, now)) expired++;
        }
        await queue.flush();
        if (snap.size < EXPIRY_PAGE_SIZE) break;
      }
      await queue.flush();
      logInfo(`handleExpiredBaseMemberships: scanned=${scanned} expired=${expired}`);
    } catch (error) {
      logError('Error handling expired base memberships:', error);
      throw error;
    }
  }
);
