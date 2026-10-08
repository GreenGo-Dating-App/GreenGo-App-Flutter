/**
 * Server-side coin ledger helpers shared by spendCoins, sendGift, acceptGift,
 * giftCoins and declineGift (security audit C-03 / H-10 / H-11 / H-12).
 *
 * Every helper here writes the EXACT document shape the Flutter client parses
 * (`coin_balance_model.dart` / `coin_transaction_model.dart`):
 *  - coinBalances/{uid}: userId, totalCoins, earnedCoins, purchasedCoins,
 *    giftedCoins, spentCoins, lastUpdated (Timestamp), coinBatches[] with
 *    { batchId, initialCoins, remainingCoins, source, acquiredDate }.
 *  - coinTransactions/{id}: userId, type, amount, balanceAfter, reason (a
 *    CoinTransactionReason enum name), relatedId, relatedUserId, metadata,
 *    createdAt (Timestamp).
 *
 * `totalCoins` is the ONLY balance authority. The client displays
 * max(totalCoins, sum of batches), but batches were client-writable (C-03), so
 * the server never lets a batch sum stand in for real coins.
 */

import { createHash } from 'crypto';
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { db } from '../shared/utils';

type Timestamp = admin.firestore.Timestamp;

/** Gifts of purchased coins younger than this are refused (H-10 fraud: buy -> gift -> refund). */
export const GIFT_PURCHASE_HOLD_MS = 72 * 3600 * 1000;
/** Per-sender gift velocity limits, per UTC day. */
export const GIFT_MAX_PER_DAY = 10;
export const GIFT_MAX_COINS_PER_DAY = 5000;

/** Reason codes returned in HttpsError.details.reason (and as a message prefix). */
export const REASON = {
  insufficientCoins: 'insufficient-coins',
  giftPurchaseHold: 'gift-purchase-hold',
  giftVelocityLimit: 'gift-velocity-limit',
  unknownFeature: 'unknown-feature',
} as const;

/**
 * A refusal the app can recognise. The reason code is in `details.reason` AND
 * leads the message, because the app's repositories flatten errors to text.
 */
export function refusal(
  code: 'failed-precondition' | 'resource-exhausted' | 'invalid-argument' | 'permission-denied' | 'not-found',
  reason: string,
  message: string,
  extra: Record<string, unknown> = {},
): HttpsError {
  return new HttpsError(code, `${reason}: ${message}`, { reason, ...extra });
}

/** One slice of coins taken from one batch by a FIFO debit. */
export interface DrawnSlice {
  /** null = coins not represented by any batch (legacy bare-increment credits). */
  batchId: string | null;
  source: string;
  acquiredDate: Timestamp | null;
  coins: number;
}

function isBatch(b: any): b is { batchId: string; remainingCoins: number; initialCoins?: number; source?: string; acquiredDate?: any } {
  return !!b && typeof b === 'object' && typeof b.remainingCoins === 'number';
}

function toTimestamp(v: any): Timestamp | null {
  if (!v) return null;
  if (v instanceof admin.firestore.Timestamp) return v;
  if (v instanceof Date) return admin.firestore.Timestamp.fromDate(v);
  if (typeof v.toMillis === 'function') return admin.firestore.Timestamp.fromMillis(v.toMillis());
  if (typeof v._seconds === 'number') return new admin.firestore.Timestamp(v._seconds, v._nanoseconds ?? 0);
  return null;
}

/**
 * FIFO debit over `coinBatches`, mirroring the app's `_debitInTransaction`:
 * oldest (array order) first, emptied batches removed. Unreadable entries are
 * kept untouched. Any part of [amount] not covered by batches is reported as
 * an unbatched slice (batchId null).
 */
export function fifoDraw(batches: unknown, amount: number): { batches: any[]; drawn: DrawnSlice[] } {
  const list = Array.isArray(batches) ? batches : [];
  let left = amount;
  const drawn: DrawnSlice[] = [];
  const out: any[] = [];
  for (const raw of list) {
    if (!isBatch(raw)) {
      out.push(raw);
      continue;
    }
    const b = { ...raw };
    if (left > 0 && b.remainingCoins > 0) {
      const take = Math.min(b.remainingCoins, left);
      b.remainingCoins -= take;
      left -= take;
      drawn.push({
        batchId: typeof b.batchId === 'string' ? b.batchId : null,
        source: typeof b.source === 'string' ? b.source : 'reward',
        acquiredDate: toTimestamp(b.acquiredDate),
        coins: take,
      });
    }
    if (b.remainingCoins > 0) out.push(b);
  }
  if (left > 0) drawn.push({ batchId: null, source: 'unbatched', acquiredDate: null, coins: left });
  return { batches: out, drawn };
}

/** Put FIFO-drawn slices back (refund of an escrowed gift): same batch ids, sources and dates. */
export function restoreSlices(batches: unknown, drawn: DrawnSlice[]): any[] {
  const out: any[] = (Array.isArray(batches) ? batches : []).map((b) => (b && typeof b === 'object' ? { ...b } : b));
  for (const s of drawn) {
    if (!s || !(s.coins > 0) || s.batchId === null) continue; // unbatched coins go back to totalCoins only
    const existing = out.find((b) => isBatch(b) && b.batchId === s.batchId);
    if (existing) {
      existing.remainingCoins += s.coins;
      if (typeof existing.initialCoins !== 'number' || existing.initialCoins < existing.remainingCoins) {
        existing.initialCoins = existing.remainingCoins;
      }
    } else {
      out.push({
        batchId: s.batchId,
        initialCoins: s.coins,
        remainingCoins: s.coins,
        source: s.source,
        acquiredDate: s.acquiredDate ?? admin.firestore.Timestamp.now(),
      });
    }
  }
  return out;
}

/** True when any drawn slice is purchased coins younger than the gift hold. */
export function drawsOnHeldPurchase(drawn: DrawnSlice[], nowMs: number): { held: boolean; releaseAtMs: number | null } {
  let releaseAtMs: number | null = null;
  for (const s of drawn) {
    if (s.source !== 'purchase' || !s.acquiredDate) continue;
    const release = s.acquiredDate.toMillis() + GIFT_PURCHASE_HOLD_MS;
    if (release > nowMs) releaseAtMs = Math.max(releaseAtMs ?? 0, release);
  }
  return { held: releaseAtMs !== null, releaseAtMs };
}

export function utcDayKey(ms: number): string {
  const d = new Date(ms);
  return `${d.getUTCFullYear()}${String(d.getUTCMonth() + 1).padStart(2, '0')}${String(d.getUTCDate()).padStart(2, '0')}`;
}

export function velocityRef(uid: string, nowMs: number) {
  return db.collection('gift_velocity').doc(`${uid}_${utcDayKey(nowMs)}`);
}

/** Throws a velocity refusal when one more gift of [amount] would break a daily limit. */
export function checkVelocity(snap: admin.firestore.DocumentSnapshot, amount: number): { count: number; coins: number } {
  const count = (snap.data()?.count as number | undefined) ?? 0;
  const coins = (snap.data()?.coins as number | undefined) ?? 0;
  if (count + 1 > GIFT_MAX_PER_DAY || coins + amount > GIFT_MAX_COINS_PER_DAY) {
    throw refusal('resource-exhausted', REASON.giftVelocityLimit,
      `Daily gift limit reached (${GIFT_MAX_PER_DAY} gifts / ${GIFT_MAX_COINS_PER_DAY} coins per day).`,
      { maxGiftsPerDay: GIFT_MAX_PER_DAY, maxCoinsPerDay: GIFT_MAX_COINS_PER_DAY, giftsToday: count, coinsToday: coins });
  }
  return { count, coins };
}

export interface SenderDebitPlan {
  total: number;
  newTotal: number;
  spent: number;
  batches: any[];
  drawn: DrawnSlice[];
}

/**
 * Plan a sender-side gift debit: balance check (totalCoins only), FIFO draw,
 * and the 72h purchased-coin hold. Throws the matching refusal.
 */
export function planGiftDebit(balance: admin.firestore.DocumentSnapshot, amount: number, nowMs: number): SenderDebitPlan {
  const data = balance.data() || {};
  const total = (data.totalCoins as number | undefined) ?? 0;
  if (total < amount) {
    throw refusal('failed-precondition', REASON.insufficientCoins, 'Not enough coins.', { required: amount, available: Math.max(0, total) });
  }
  const { batches, drawn } = fifoDraw(data.coinBatches, amount);
  const hold = drawsOnHeldPurchase(drawn, nowMs);
  if (hold.held) {
    throw refusal('failed-precondition', REASON.giftPurchaseHold,
      'Purchased coins can be gifted 72 hours after purchase.', { releaseAt: hold.releaseAtMs });
  }
  return { total, newTotal: total - amount, spent: ((data.spentCoins as number | undefined) ?? 0) + amount, batches, drawn };
}

/** Deterministic, Firestore-safe id from parts (idempotency keys). */
export function stableId(...parts: string[]): string {
  return createHash('sha256').update(parts.join('\u0000')).digest('hex').slice(0, 40);
}

/** Validate a client idempotency key (uuid or similar). */
export function validRequestId(v: unknown): v is string {
  return typeof v === 'string' && /^[A-Za-z0-9_-]{8,80}$/.test(v);
}

/** Gift amount bounds: mirrors CoinGiftConstraints in the app. */
export const GIFT_MIN_AMOUNT = 10;
export const GIFT_MAX_AMOUNT = 1000;
export const GIFT_EXPIRY_MS = 7 * 24 * 3600 * 1000;
