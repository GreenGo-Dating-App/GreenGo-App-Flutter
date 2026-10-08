/**
 * Server-escrow coin gifts (security audit C-03 / H-10 / H-12).
 *
 *   sendGift   - debits the sender (FIFO, same batch shape the app parses) into
 *                `gift_escrow/{giftId}` and creates the pending `coinGifts`
 *                doc the app's CoinGiftModel reads.
 *   acceptGift - the receiver claims the escrow: coins are credited as a
 *                'gift' batch. Legacy gifts created by older apps (client
 *                debit + client gift doc) are accepted only with the same
 *                escrow proof declineGift uses.
 *   declineGift (coins/index.ts) refunds server-escrow gifts directly by
 *                putting the drawn batch slices back.
 *
 * Fraud controls on every gift path (sendGift and the shop's giftCoins):
 *   - coins bought less than 72h ago cannot be gifted (FIFO decides which
 *     batches a gift draws on) -> reason 'gift-purchase-hold';
 *   - at most 10 gifts and 5,000 coins per sender per UTC day
 *     -> reason 'gift-velocity-limit'.
 */

import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { db, handleError, logInfo, verifyAuth } from '../shared/utils';
import {
  checkVelocity,
  DrawnSlice,
  GIFT_EXPIRY_MS,
  GIFT_MAX_AMOUNT,
  GIFT_MIN_AMOUNT,
  planGiftDebit,
  restoreSlices,
  stableId,
  validRequestId,
  velocityRef,
} from './ledger';

interface SendGiftRequest {
  receiverId: string;
  amount: number;
  message?: string;
  /** Optional idempotency key; a retried call returns the same gift. */
  requestId?: string;
}

function giftResponse(giftId: string, g: any, senderNewBalance: number | null, alreadyProcessed: boolean) {
  return {
    success: true,
    alreadyProcessed,
    giftId,
    senderId: g.senderId,
    receiverId: g.receiverId,
    amount: g.amount,
    message: g.message ?? null,
    status: g.status,
    sentAt: g.sentAt?.toMillis?.() ?? null,
    expiresAt: g.expiresAt?.toMillis?.() ?? null,
    senderNewBalance,
  };
}

export const sendGift = onCall<SendGiftRequest>(
  { memory: '512MiB', timeoutSeconds: 60 },
  async (request) => {
    try {
      const senderId = await verifyAuth(request.auth);
      const { receiverId, amount } = request.data || ({} as SendGiftRequest);
      const message = typeof request.data?.message === 'string'
        ? request.data.message.trim().slice(0, 500) : '';

      if (!receiverId || typeof receiverId !== 'string' || receiverId.includes('/')) {
        throw new HttpsError('invalid-argument', 'receiverId is required');
      }
      if (receiverId === senderId) {
        throw new HttpsError('invalid-argument', 'Cannot gift coins to yourself');
      }
      if (!Number.isInteger(amount) || amount < GIFT_MIN_AMOUNT || amount > GIFT_MAX_AMOUNT) {
        throw new HttpsError('invalid-argument',
          `amount must be an integer between ${GIFT_MIN_AMOUNT} and ${GIFT_MAX_AMOUNT}`);
      }
      const requestId = request.data?.requestId;
      if (requestId !== undefined && !validRequestId(requestId)) {
        throw new HttpsError('invalid-argument', 'requestId is invalid');
      }

      const receiverProfile = await db.collection('profiles').doc(receiverId).get();
      if (!receiverProfile.exists) {
        throw new HttpsError('not-found', 'Recipient not found');
      }

      const giftRef = requestId
        ? db.collection('coinGifts').doc(`g_${stableId(senderId, requestId)}`)
        : db.collection('coinGifts').doc();
      const giftId = giftRef.id;
      const escrowRef = db.collection('gift_escrow').doc(giftId);
      const senderRef = db.collection('coinBalances').doc(senderId);

      const result = await db.runTransaction(async (tx) => {
        const nowMs = Date.now();
        const vRef = velocityRef(senderId, nowMs);
        const [escrowSnap, giftSnap, senderSnap, vSnap] = await Promise.all([
          tx.get(escrowRef), tx.get(giftRef), tx.get(senderRef), tx.get(vRef),
        ]);

        if (escrowSnap.exists || giftSnap.exists) {
          // Idempotent retry of the same requestId.
          const g = giftSnap.data() || {};
          if (g.senderId !== senderId || g.receiverId !== receiverId || g.amount !== amount) {
            throw new HttpsError('invalid-argument', 'requestId was already used for a different gift');
          }
          return giftResponse(giftId, g, (senderSnap.data()?.totalCoins as number | undefined) ?? null, true);
        }

        const v = checkVelocity(vSnap, amount);
        const plan = planGiftDebit(senderSnap, amount, nowMs);
        const now = admin.firestore.Timestamp.fromMillis(nowMs);
        const expiresAt = admin.firestore.Timestamp.fromMillis(nowMs + GIFT_EXPIRY_MS);

        tx.set(senderRef, {
          userId: senderId,
          totalCoins: plan.newTotal,
          spentCoins: plan.spent,
          coinBatches: plan.batches,
          lastUpdated: now,
        }, { merge: true });

        const debitRef = db.collection('coinTransactions').doc();
        tx.set(debitRef, {
          userId: senderId,
          type: 'debit',
          amount,
          balanceAfter: plan.newTotal,
          reason: 'giftSent',
          relatedId: giftId,
          relatedUserId: receiverId,
          metadata: { toUserId: receiverId, giftId, source: 'gift_escrow' },
          createdAt: now,
        });

        tx.create(escrowRef, {
          giftId,
          senderId,
          receiverId,
          amount,
          status: 'held',
          drawn: plan.drawn,
          debitTransactionId: debitRef.id,
          createdAt: now,
        });

        const gift = {
          giftId,
          senderId,
          receiverId,
          amount,
          message: message.length > 0 ? message : null,
          status: 'pending',
          sentAt: now,
          receivedAt: null,
          expiresAt,
          escrow: true,
        };
        tx.set(giftRef, gift);

        tx.set(vRef, {
          userId: senderId,
          count: v.count + 1,
          coins: v.coins + amount,
          updatedAt: now,
        }, { merge: true });

        return giftResponse(giftId, gift, plan.newTotal, false);
      });

      if (!result.alreadyProcessed) {
        logInfo(`sendGift ${senderId} -> ${receiverId} amount=${amount} gift=${giftId} (escrow)`);
      }
      return result;
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      throw handleError(error);
    }
  },
);

interface AcceptGiftRequest {
  giftId: string;
}

/**
 * Find the sender's `giftSent` debit that was committed together with a
 * client-created (legacy) gift doc. Mirrors declineGift's escrow proof.
 */
async function legacyEscrowDebitId(gift: any, giftCreateMs: number | undefined): Promise<string | null> {
  if (!gift || gift.senderId === gift.receiverId) return null;
  const amt = gift.amount;
  if (!Number.isInteger(amt) || amt <= 0 || amt > GIFT_MAX_AMOUNT || giftCreateMs === undefined) return null;
  const debits = await db.collection('coinTransactions')
    .where('userId', '==', gift.senderId)
    .where('relatedUserId', '==', gift.receiverId)
    .where('amount', '==', amt)
    .limit(50)
    .get();
  const match = debits.docs.find((d) =>
    d.data().reason === 'giftSent' &&
    d.data().type === 'debit' &&
    d.createTime.toMillis() === giftCreateMs);
  return match ? match.id : null;
}

export const acceptGift = onCall<AcceptGiftRequest>(
  { memory: '512MiB', timeoutSeconds: 60 },
  async (request) => {
    try {
      const receiverId = await verifyAuth(request.auth);
      const giftId = request.data?.giftId;
      if (!giftId || typeof giftId !== 'string' || giftId.includes('/')) {
        throw new HttpsError('invalid-argument', 'giftId is required');
      }

      const giftRef = db.collection('coinGifts').doc(giftId);
      const escrowRef = db.collection('gift_escrow').doc(giftId);

      // Legacy proof is a query, so it runs before the transaction; the
      // transaction then re-checks the gift and claims the debit atomically.
      const [preGift, preEscrow] = await Promise.all([giftRef.get(), escrowRef.get()]);
      let legacyDebitId: string | null = null;
      if (!preEscrow.exists && preGift.exists) {
        legacyDebitId = await legacyEscrowDebitId(preGift.data(), preGift.createTime?.toMillis());
      }

      const receiverRef = db.collection('coinBalances').doc(receiverId);

      const result = await db.runTransaction(async (tx) => {
        const claimRef = legacyDebitId ? db.collection('gift_refunds').doc(legacyDebitId) : null;
        const [giftSnap, escrowSnap, receiverSnap, claimSnap] = await Promise.all([
          tx.get(giftRef), tx.get(escrowRef), tx.get(receiverRef),
          claimRef ? tx.get(claimRef) : Promise.resolve(null),
        ]);
        if (!giftSnap.exists) throw new HttpsError('not-found', 'Gift not found');
        const gift = giftSnap.data() as any;
        if (gift.receiverId !== receiverId) {
          throw new HttpsError('permission-denied', 'Only the gift recipient can accept this gift');
        }
        if (gift.status !== 'pending') {
          throw new HttpsError('failed-precondition', 'Gift is not pending (already accepted or declined)');
        }

        const escrow = escrowSnap.exists ? (escrowSnap.data() as any) : null;
        let amount: number;
        let senderId: string;
        if (escrow) {
          if (escrow.status !== 'held') {
            throw new HttpsError('failed-precondition', 'Gift escrow already settled');
          }
          amount = escrow.amount;
          senderId = escrow.senderId;
        } else {
          // Legacy client-created gift: credit only against a proven,
          // unclaimed sender debit committed with the gift doc.
          if (!claimRef || !legacyDebitId) {
            tx.set(db.collection('fraud_flags').doc(), {
              type: 'gift_accept_unverified', giftId, senderId: gift.senderId ?? null,
              receiverId, amount: gift.amount ?? null,
              createdAt: admin.firestore.FieldValue.serverTimestamp(), reviewed: false,
            });
            return { unverified: true } as const;
          }
          if (claimSnap?.exists) {
            throw new HttpsError('failed-precondition', 'Gift already settled');
          }
          if (gift.senderId !== preGift.data()?.senderId || gift.amount !== preGift.data()?.amount) {
            throw new HttpsError('failed-precondition', 'Gift changed, please retry');
          }
          amount = gift.amount;
          senderId = gift.senderId;
        }

        const now = admin.firestore.Timestamp.now();
        const bal = receiverSnap.data() || {};
        const total = ((bal.totalCoins as number | undefined) ?? 0) + amount;
        const batches = Array.isArray(bal.coinBatches) ? [...bal.coinBatches] : [];
        batches.push({
          batchId: `gift_${giftId}`,
          initialCoins: amount,
          remainingCoins: amount,
          source: 'gift',
          acquiredDate: now,
        });
        tx.set(receiverRef, {
          userId: receiverId,
          totalCoins: total,
          earnedCoins: (bal.earnedCoins as number | undefined) ?? 0,
          purchasedCoins: (bal.purchasedCoins as number | undefined) ?? 0,
          giftedCoins: ((bal.giftedCoins as number | undefined) ?? 0) + amount,
          spentCoins: (bal.spentCoins as number | undefined) ?? 0,
          coinBatches: batches,
          lastUpdated: now,
        }, { merge: true });
        const creditRef = db.collection('coinTransactions').doc();
        tx.set(creditRef, {
          userId: receiverId,
          type: 'credit',
          amount,
          balanceAfter: total,
          reason: 'giftReceived',
          relatedId: giftId,
          relatedUserId: senderId,
          metadata: { fromUserId: senderId, giftId, source: escrow ? 'gift_escrow' : 'gift_legacy' },
          createdAt: now,
        });
        tx.update(giftRef, { status: 'accepted', receivedAt: now });
        if (escrow) {
          tx.update(escrowRef, { status: 'released', settledAt: now, creditTransactionId: creditRef.id });
        } else {
          // One debit backs one settlement: an accept here blocks any later
          // refund of the same debit through declineGift.
          tx.create(claimRef!, {
            kind: 'accept', senderId, receiverId, giftId, amount, createdAt: now,
          });
        }
        return { unverified: false, amount, newBalance: total } as const;
      });

      if (result.unverified) {
        throw new HttpsError('failed-precondition', 'This gift could not be verified');
      }
      logInfo(`acceptGift ${giftId}: credited ${result.amount} to ${receiverId}`);
      return { success: true, giftId, amount: result.amount, newBalance: result.newBalance };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      throw handleError(error);
    }
  },
);

/** Escrow refund for declineGift: restore the drawn slices to the sender. */
export function escrowRefundUpdate(
  senderBalance: admin.firestore.DocumentSnapshot,
  drawn: DrawnSlice[],
  amount: number,
): { newTotal: number; fields: Record<string, unknown> } {
  const bal = senderBalance.data() || {};
  const newTotal = ((bal.totalCoins as number | undefined) ?? 0) + amount;
  return {
    newTotal,
    fields: {
      totalCoins: newTotal,
      spentCoins: Math.max(0, ((bal.spentCoins as number | undefined) ?? 0) - amount),
      refundedCoins: ((bal.refundedCoins as number | undefined) ?? 0) + amount,
      coinBatches: restoreSlices(bal.coinBatches, Array.isArray(drawn) ? drawn : []),
    },
  };
}
