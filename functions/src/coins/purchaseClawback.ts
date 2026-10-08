/**
 * Refund / chargeback clawback for store coin purchases (security audit H-10),
 * plus review flags for sandbox / test-account grants (H-13).
 *
 * Every verified coin grant claims `purchaseLedger/{sha256(key)}` (key = Play
 * purchase token, or Apple transactionId) in the same transaction that credits
 * the coins (see grantVerifiedCoinPurchase in ./index.ts). A refund takes the
 * granted amount back exactly once per ledger entry:
 *   - coinBalances/{uid}.totalCoins -= coins (may go NEGATIVE: the coins were
 *     already spent, and the debt is settled by the next credit),
 *   - purchasedCoins -= coins (floored at 0),
 *   - coinBatches remainders are reduced (the grant's own batch first, then
 *     oldest first) because the client shows max(totalCoins, sum of batches),
 *   - a coinTransactions debit, reason 'refundClawback',
 *   - ledger.revokedAt / revokeReason (the idempotency marker),
 *   - fraud_flags/refund_{ledgerId} {type: 'purchase_refunded'} for review.
 *
 * Client contract: `reason: 'refundClawback'` is not (yet) a value of the
 * app's CoinTransactionReason enum; its parser falls back to featurePurchase
 * (no crash) and renders "Used N coins for {metadata.feature}", so
 * metadata.feature carries a readable label.
 */

import { createHash } from 'crypto';
import * as admin from 'firebase-admin';
import { db, logInfo, logError } from '../shared/utils';

export const ledgerIdFor = (key: string): string =>
  createHash('sha256').update(key).digest('hex');

export type ClawbackStore = 'google_play' | 'app_store';

export interface ClawbackInfo {
  store: ClawbackStore;
  /** Machine-readable cause, e.g. 'play_voided', 'apple_refund', 'apple_revoke'. */
  reason: string;
  /** Which path saw it: 'rtdn' | 'voided_poll' | 'asn_v2'. */
  source: string;
  details?: Record<string, unknown>;
}

export interface ClawbackResult {
  action: 'clawed_back' | 'already' | 'not_found';
  ledgerId?: string;
  userId?: string;
  coins?: number;
  balanceAfter?: number;
}

/**
 * The ledger entry of a store coin purchase: by hashed purchase token / Apple
 * transactionId (the doc id), else by the stored store transaction id
 * (Play orderId / Apple transactionId).
 */
export async function findPurchaseLedger(keys: {
  purchaseToken?: string | null;
  transactionId?: string | null;
}): Promise<FirebaseFirestore.DocumentReference | null> {
  for (const k of [keys.purchaseToken, keys.transactionId]) {
    if (!k) continue;
    const ref = db.collection('purchaseLedger').doc(ledgerIdFor(k));
    if ((await ref.get()).exists) return ref;
  }
  if (keys.transactionId) {
    const q = await db
      .collection('purchaseLedger')
      .where('transactionId', '==', keys.transactionId)
      .limit(1)
      .get();
    if (!q.empty) return q.docs[0].ref;
  }
  return null;
}

/** Remove `amount` from batch remainders: `preferBatchId` first, then oldest first. */
export function deductFromBatches(
  batches: any[],
  amount: number,
  preferBatchId?: string | null,
): any[] {
  const out = batches.map((b) => (b && typeof b === 'object' ? { ...b } : b));
  let left = amount;
  const order = out
    .map((b, i) => ({ b, i }))
    .filter(({ b }) => b && typeof b.remainingCoins === 'number' && b.remainingCoins > 0)
    .sort((x, y) => {
      if (preferBatchId && x.b.batchId === preferBatchId) return -1;
      if (preferBatchId && y.b.batchId === preferBatchId) return 1;
      return x.i - y.i;
    });
  for (const { b } of order) {
    if (left <= 0) break;
    const take = Math.min(b.remainingCoins, left);
    b.remainingCoins -= take;
    left -= take;
  }
  return out;
}

/** Take back the coins of one refunded store purchase. Idempotent per ledger entry. */
export async function clawbackCoinPurchase(
  ledgerRef: FirebaseFirestore.DocumentReference,
  info: ClawbackInfo,
): Promise<ClawbackResult> {
  const ledgerId = ledgerRef.id;
  const result = await db.runTransaction(async (tx): Promise<ClawbackResult> => {
    const ledgerSnap = await tx.get(ledgerRef);
    if (!ledgerSnap.exists) return { action: 'not_found', ledgerId };
    const ledger = ledgerSnap.data() || {};
    const uid = ledger.userId as string;
    if (ledger.revokedAt) return { action: 'already', ledgerId, userId: uid };

    const coins = typeof ledger.coins === 'number' && ledger.coins > 0 ? ledger.coins : 0;
    const grantTxRef = ledger.coinTransactionId
      ? db.collection('coinTransactions').doc(String(ledger.coinTransactionId))
      : null;
    const grantTx = grantTxRef ? await tx.get(grantTxRef) : null;
    const balanceRef = db.collection('coinBalances').doc(uid);
    const balanceSnap = await tx.get(balanceRef);
    const bal = balanceSnap.data() || {};

    const now = admin.firestore.Timestamp.now();
    const total = ((bal.totalCoins as number | undefined) ?? 0) - coins;
    const purchased = Math.max(0, ((bal.purchasedCoins as number | undefined) ?? 0) - coins);
    const batches = deductFromBatches(
      Array.isArray(bal.coinBatches) ? bal.coinBatches : [],
      coins,
      grantTx?.data()?.batchId ?? null,
    );
    const debitRef = db.collection('coinTransactions').doc();

    if (coins > 0) {
      tx.set(
        balanceRef,
        {
          userId: uid,
          totalCoins: total,
          purchasedCoins: purchased,
          coinBatches: batches,
          lastUpdated: now,
        },
        { merge: true },
      );
      tx.set(debitRef, {
        userId: uid,
        type: 'debit',
        amount: coins,
        balanceAfter: total,
        reason: 'refundClawback',
        createdAt: now,
        relatedId: ledgerId,
        metadata: {
          feature: 'refunded purchase', // rendered by the client's fallback text
          productId: ledger.productId ?? null,
          store: info.store,
          refundReason: info.reason,
        },
      });
    }
    tx.update(ledgerRef, {
      revokedAt: now,
      revokeReason: info.reason,
      revokeSource: info.source,
      coinsClawedBack: coins,
      clawbackTransactionId: coins > 0 ? debitRef.id : null,
    });
    tx.set(db.collection('fraud_flags').doc(`refund_${ledgerId}`), {
      type: 'purchase_refunded',
      userId: uid,
      productId: ledger.productId ?? null,
      platform: ledger.platform ?? null,
      store: info.store,
      reason: info.reason,
      source: info.source,
      ledgerId,
      storeTransactionId: ledger.transactionId ?? null,
      coins,
      balanceAfter: coins > 0 ? total : (bal.totalCoins ?? 0),
      negativeBalance: coins > 0 && total < 0,
      details: info.details ?? null,
      createdAt: now,
      reviewed: false,
    });
    return { action: 'clawed_back', ledgerId, userId: uid, coins, balanceAfter: total };
  });

  if (result.action === 'clawed_back') {
    logInfo(
      `Refund clawback: ${result.coins} coins from ${result.userId} ` +
      `(${info.store}/${info.reason}, ledger ${ledgerId}), balance now ${result.balanceAfter}`,
    );
  }
  return result;
}

/**
 * H-13: sandbox / license-tester purchases are still granted (Apple App Review
 * buys in the sandbox), but a grant to anyone who is not an admin is queued
 * for review. Best effort: never fails the purchase.
 */
export async function flagSandboxGrantIfNeeded(params: {
  uid: string;
  ledgerId: string;
  productId: string;
  platform: 'android' | 'ios';
  coins: number;
  environment?: string;
  purchaseType?: number;
}): Promise<boolean> {
  const sandbox = params.environment === 'SANDBOX' || params.purchaseType === 0;
  if (!sandbox) return false;
  try {
    if ((await db.collection('admin_users').doc(params.uid).get()).exists) return false;
    await db.collection('fraud_flags').doc(`sandbox_${params.ledgerId}`).set({
      type: 'sandbox_purchase_non_admin',
      userId: params.uid,
      productId: params.productId,
      platform: params.platform,
      coins: params.coins,
      environment: params.environment ?? null,
      purchaseType: params.purchaseType ?? null,
      ledgerId: params.ledgerId,
      createdAt: admin.firestore.Timestamp.now(),
      reviewed: false,
    });
    logInfo(`Sandbox/test coin grant to non-admin ${params.uid} flagged for review`);
    return true;
  } catch (e) {
    logError('flagSandboxGrantIfNeeded failed (grant unaffected)', e);
    return false;
  }
}
