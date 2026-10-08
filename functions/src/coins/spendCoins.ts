/**
 * spendCoins: the ONE server-authoritative way to spend coins on a feature
 * (security audit C-03 / H-12).
 *
 * The app used to debit `coinBalances` itself (coin_remote_datasource.dart
 * updateBalance / _debitInTransaction), so a patched client could skip the
 * debit, or write any balance it liked. Now:
 *  - the client names a `featureId` (never a price); the price comes from
 *    FEATURE_PRICES below, and unknown features are refused;
 *  - the debit runs in one Firestore transaction: FIFO over `coinBatches`
 *    (same shape the app parses), `totalCoins`, `spentCoins`, and a
 *    `coinTransactions` debit whose `reason` is a CoinTransactionReason name;
 *  - a client idempotency key (`requestId`) is claimed in
 *    `coin_spend_requests/{uid}_{requestId}` inside the same transaction, so a
 *    retried call never charges twice;
 *  - where the feature's effect is a server-owned profile/event field (profile
 *    boost, incognito, event featuring, business promotion), the effect is
 *    written in the SAME transaction; otherwise the call returns a receipt
 *    `{ok, newBalance, transactionId}` and the app applies the effect.
 *
 * Testers (`profiles.membershipTier` TEST, which rules make server-owned) use
 * every feature free, exactly as the app did client-side; the effect still
 * applies and a zero-cost receipt is recorded.
 */

import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { db, handleError, logInfo, verifyAuth } from '../shared/utils';
import { fifoDraw, refusal, REASON, validRequestId } from './ledger';
import { assertAgeAssured, GatedFeature } from '../safety/ageAssuranceGate';

/**
 * P3-1 age assurance: coin features that reach people discovery or start a
 * private 1:1 message. Refused (before any charge) for users who need strong
 * age assurance and have none (no-op while the flag is off).
 */
export const AGE_GATED_FEATURES: Record<string, GatedFeature> = {
  direct_message: 'messaging',
  superlike: 'messaging',
  grid_view_more: 'discovery',
  discovery_see_more: 'discovery',
};

type EffectKind = 'profileBoost' | 'incognito' | 'travelerPass' | 'eventFeature' | 'businessPromotion';

interface FeatureDef {
  /** CoinTransactionReason enum name written on the debit. */
  reason: string;
  /** Fixed price in coins. */
  price?: number;
  /** Option-priced features: option value -> coins. */
  options?: Record<number, number>;
  /** Unit of `option` for option-priced features. */
  optionUnit?: 'hours' | 'days';
  /** Price is the event's own `price` (events/{relatedId}). */
  eventPrice?: boolean;
  /** relatedId is required (event id for event features). */
  needsRelatedId?: boolean;
  effect?: EffectKind;
  /** eventFeature: extend an active window (true) or restart it from now. */
  extend?: boolean;
}

/**
 * AUTHORITATIVE feature price table. Mirrors the app's constants:
 *  - CoinFeaturePrices (coin_transaction.dart): superLike 10, boost 50, undo 3,
 *    directMessage 50, incognito 30, traveler 100;
 *  - discovery_screen grid "see more" 10; network_discovery kCoinsToSeeMore 15;
 *  - TierEntitlements.ttsCostCoins 5 (1:1 and group chat TTS);
 *  - events_screen kExtraEventCost 50, boost options, kFeatureEventCost 100;
 *  - promotion_service kPromoteDurationOptions (business / event per days).
 * Changing a price here changes what users pay; keep the app labels in sync.
 */
export const FEATURE_PRICES: Record<string, FeatureDef> = {
  superlike: { price: 10, reason: 'superLikePurchase' },
  undo: { price: 3, reason: 'undoPurchase' },
  direct_message: { price: 50, reason: 'directMessagePurchase' },
  grid_view_more: { price: 10, reason: 'featurePurchase' },
  discovery_see_more: { price: 15, reason: 'featurePurchase' },
  boost: { price: 50, reason: 'boostPurchase', effect: 'profileBoost' },
  incognito: { price: 30, reason: 'incognitoPurchase', effect: 'incognito' },
  traveler: { price: 100, reason: 'travelerPurchase', effect: 'travelerPass' },
  tts_listen: { price: 5, reason: 'featurePurchase' },
  tts_listen_group: { price: 5, reason: 'featurePurchase' },
  extra_event: { price: 50, reason: 'featurePurchase' },
  event_rsvp: { eventPrice: true, needsRelatedId: true, reason: 'featurePurchase' },
  event_boost: {
    options: { 1: 50, 6: 100, 12: 150, 24: 200, 72: 500, 168: 1000 },
    optionUnit: 'hours', needsRelatedId: true, effect: 'eventFeature', extend: false,
    reason: 'featurePurchase',
  },
  event_featured: {
    options: { 7: 100, 14: 180, 30: 350 },
    optionUnit: 'days', needsRelatedId: true, effect: 'eventFeature', extend: true,
    reason: 'featurePurchase',
  },
  business_promotion: {
    options: { 7: 250, 14: 450, 30: 800 },
    optionUnit: 'days', effect: 'businessPromotion', reason: 'featurePurchase',
  },
};

/** Spellings the app has used for the same feature. */
const FEATURE_ALIASES: Record<string, string> = {
  super_like: 'superlike',
  directmessage: 'direct_message',
  location_switch: 'traveler',
};

export function resolveFeatureId(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const id = raw.trim().toLowerCase();
  const canonical = FEATURE_ALIASES[id] ?? id;
  return Object.prototype.hasOwnProperty.call(FEATURE_PRICES, canonical) ? canonical : null;
}

const BOOST_MS = 30 * 60 * 1000;
const DAY_MS = 24 * 3600 * 1000;
/** Upper bound on an organizer-set event price, as a sanity guard. */
const MAX_EVENT_PRICE = 100000;

interface SpendCoinsRequest {
  featureId: string;
  requestId: string;
  relatedId?: string;
  option?: number;
}

function millisOf(v: any): number | null {
  if (!v) return null;
  if (typeof v.toMillis === 'function') return v.toMillis();
  if (v instanceof Date) return v.getTime();
  return null;
}

export const spendCoins = onCall<SpendCoinsRequest>(
  { memory: '512MiB', timeoutSeconds: 60 },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const data = request.data || ({} as SpendCoinsRequest);
      const featureId = resolveFeatureId(data.featureId);
      if (!featureId) {
        throw refusal('invalid-argument', REASON.unknownFeature, `Unknown feature: ${String(data.featureId)}`);
      }
      const gated = AGE_GATED_FEATURES[featureId];
      if (gated) await assertAgeAssured(uid, gated);
      if (!validRequestId(data.requestId)) {
        throw new HttpsError('invalid-argument', 'requestId (8-80 chars [A-Za-z0-9_-]) is required');
      }
      const def = FEATURE_PRICES[featureId];
      const relatedId = typeof data.relatedId === 'string' && data.relatedId.length > 0 && data.relatedId.length <= 200
        ? data.relatedId : null;
      if (def.needsRelatedId && !relatedId) {
        throw new HttpsError('invalid-argument', `relatedId is required for ${featureId}`);
      }
      if (relatedId && relatedId.includes('/')) {
        throw new HttpsError('invalid-argument', 'relatedId is invalid');
      }
      let optionPrice: number | null = null;
      if (def.options) {
        const opt = Number(data.option);
        optionPrice = Number.isInteger(opt) ? def.options[opt] ?? null : null;
        if (optionPrice === null) {
          throw new HttpsError('invalid-argument', `Unknown option for ${featureId}: ${String(data.option)}`);
        }
      }

      const requestRef = db.collection('coin_spend_requests').doc(`${uid}_${data.requestId}`);
      const balanceRef = db.collection('coinBalances').doc(uid);
      const profileRef = db.collection('profiles').doc(uid);
      const eventRef = (def.eventPrice || def.effect === 'eventFeature') && relatedId
        ? db.collection('events').doc(relatedId) : null;

      const result = await db.runTransaction(async (tx) => {
        // ---- reads (all before any write) ----
        const prior = await tx.get(requestRef);
        if (prior.exists) {
          const p = prior.data() || {};
          if (p.featureId !== featureId || (p.relatedId ?? null) !== relatedId) {
            throw new HttpsError('invalid-argument', 'requestId was already used for a different purchase');
          }
          const bal = await tx.get(balanceRef);
          return {
            ok: true, success: true, alreadyProcessed: true, featureId,
            charged: p.charged ?? 0,
            transactionId: p.transactionId ?? null,
            newBalance: (bal.data()?.totalCoins as number | undefined) ?? 0,
            effect: p.effect ?? null,
          };
        }
        const balanceSnap = await tx.get(balanceRef);
        const profileSnap = await tx.get(profileRef);
        const eventSnap = eventRef ? await tx.get(eventRef) : null;

        const now = admin.firestore.Timestamp.now();
        const nowMs = now.toMillis();

        // ---- price ----
        let price: number;
        if (def.eventPrice) {
          if (!eventSnap?.exists) throw new HttpsError('not-found', 'Event not found');
          const raw = Number(eventSnap.data()?.price ?? 0);
          price = Number.isFinite(raw) ? Math.round(raw) : 0;
          if (price <= 0) throw new HttpsError('failed-precondition', 'This event is free');
          if (price > MAX_EVENT_PRICE) throw new HttpsError('failed-precondition', 'Event price out of range');
        } else if (optionPrice !== null) {
          price = optionPrice;
        } else {
          price = def.price!;
        }

        // ---- effect preconditions ----
        if (def.effect === 'eventFeature') {
          if (!eventSnap?.exists) throw new HttpsError('not-found', 'Event not found');
          const ev = eventSnap.data() || {};
          const owners = [ev.organizerId, ...(Array.isArray(ev.coOrganizerIds) ? ev.coOrganizerIds : [])];
          if (!owners.includes(uid)) {
            throw new HttpsError('permission-denied', 'Only the event organizer can feature this event');
          }
        }

        const tier = String(profileSnap.data()?.membershipTier ?? '');
        const isTester = tier === 'test' || tier === 'TEST';
        const charge = isTester ? 0 : price;

        const bal = balanceSnap.data() || {};
        const total = (bal.totalCoins as number | undefined) ?? 0;
        if (charge > 0 && total < charge) {
          throw refusal('failed-precondition', REASON.insufficientCoins, 'Not enough coins.',
            { required: charge, available: Math.max(0, total) });
        }

        // ---- effect values ----
        const effect: Record<string, unknown> = {};
        if (def.effect === 'profileBoost') {
          const until = admin.firestore.Timestamp.fromMillis(nowMs + BOOST_MS);
          tx.set(profileRef, { isBoosted: true, boostExpiry: until }, { merge: true });
          effect.boostExpiry = until.toMillis();
        } else if (def.effect === 'incognito') {
          const until = admin.firestore.Timestamp.fromMillis(nowMs + DAY_MS);
          tx.set(profileRef, { isIncognito: true, incognitoExpiry: until }, { merge: true });
          effect.incognitoExpiry = until.toMillis();
        } else if (def.effect === 'travelerPass') {
          // The app picks the destination after paying, so it still writes
          // isTraveler / travelerLocation / travelerExpiry itself. This
          // server-owned pass is what the later rules lockdown checks.
          const until = admin.firestore.Timestamp.fromMillis(nowMs + DAY_MS);
          tx.set(profileRef, { travelerPaidUntil: until }, { merge: true });
          effect.travelerPaidUntil = until.toMillis();
        } else if (def.effect === 'eventFeature') {
          const unitMs = def.optionUnit === 'hours' ? 3600 * 1000 : DAY_MS;
          const current = millisOf(eventSnap!.data()?.featuredUntil);
          const base = def.extend && eventSnap!.data()?.isFeatured === true && current && current > nowMs ? current : nowMs;
          const until = admin.firestore.Timestamp.fromMillis(base + Number(data.option) * unitMs);
          tx.update(eventRef!, { isFeatured: true, featuredUntil: until });
          effect.featuredUntil = until.toMillis();
        } else if (def.effect === 'businessPromotion') {
          const current = millisOf(profileSnap.data()?.businessPromotedUntil);
          const base = current && current > nowMs ? current : nowMs;
          const until = admin.firestore.Timestamp.fromMillis(base + Number(data.option) * DAY_MS);
          tx.set(profileRef, { businessPromotedUntil: until }, { merge: true });
          effect.businessPromotedUntil = until.toMillis();
        }

        // ---- debit ----
        let transactionId: string | null = null;
        let newBalance = total;
        if (charge > 0) {
          const { batches } = fifoDraw(bal.coinBatches, charge);
          newBalance = total - charge;
          tx.set(balanceRef, {
            userId: uid,
            totalCoins: newBalance,
            spentCoins: ((bal.spentCoins as number | undefined) ?? 0) + charge,
            coinBatches: batches,
            lastUpdated: now,
          }, { merge: true });
          const txnRef = db.collection('coinTransactions').doc();
          transactionId = txnRef.id;
          tx.set(txnRef, {
            userId: uid,
            type: 'debit',
            amount: charge,
            balanceAfter: newBalance,
            reason: def.reason,
            relatedId,
            relatedUserId: null,
            metadata: {
              feature: featureId,
              requestId: data.requestId,
              ...(optionPrice !== null ? { option: Number(data.option) } : {}),
              source: 'spendCoins',
            },
            createdAt: now,
          });
        }

        tx.create(requestRef, {
          userId: uid,
          featureId,
          relatedId,
          option: optionPrice !== null ? Number(data.option) : null,
          charged: charge,
          price,
          tester: isTester,
          transactionId,
          effect,
          createdAt: now,
        });

        return {
          ok: true, success: true, alreadyProcessed: false, featureId,
          charged: charge, transactionId, newBalance, effect,
        };
      });

      if (!result.alreadyProcessed) {
        logInfo(`spendCoins ${uid} ${featureId} charged=${result.charged} newBalance=${result.newBalance}`);
      }
      return result;
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      throw handleError(error);
    }
  },
);
