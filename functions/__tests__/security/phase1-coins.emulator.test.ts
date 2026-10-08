/**
 * Phase 1 / P1-1 coins: server-authoritative spending and escrow gifts.
 *
 *   C-03 / H-12  spendCoins: server price table (client never sends a price),
 *                unknown features refused, idempotent requestId, FIFO batch
 *                shape, insufficient balance (totalCoins is the authority, a
 *                forged batch sum is not money), server-side effects.
 *   H-11         the Shop "send coins" flow goes through giftCoins (sender
 *                debited AND receiver credited, atomically).
 *   H-10         gifts of purchased coins younger than 72h are refused;
 *                velocity limits (10 gifts / 5,000 coins per sender per day).
 *   sendGift / acceptGift / declineGift escrow round trip, plus the legacy
 *   client-created gift (old app versions) still declines and accepts with
 *   the Phase 0 escrow proof.
 *
 *   firebase emulators:exec --only firestore,auth --project test-project \
 *     "npx jest --config jest.security.config.js"
 */

import * as admin from 'firebase-admin';
import functionsTest from 'firebase-functions-test';

const fft = functionsTest({ projectId: process.env.GCLOUD_PROJECT });

import { spendCoins, sendGift, acceptGift, declineGift, giftCoins } from '../../src/coins';

const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const HOUR = 3600 * 1000;

async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  const project = process.env.GCLOUD_PROJECT;
  if (!host || !/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) {
    throw new Error('Refusing to run: FIRESTORE_EMULATOR_HOST is not a local emulator');
  }
  await new Promise<void>((resolve, reject) => {
    const req = require('http').request(
      { host: host!.split(':')[0], port: Number(host!.split(':')[1]), method: 'DELETE',
        path: `/emulator/v1/projects/${project}/databases/(default)/documents` },
      (res: any) => { res.resume(); res.on('end', resolve); });
    req.on('error', reject);
    req.end();
  });
}

const call = (fn: any, data: any, uid: string) =>
  (fft.wrap(fn) as any)({ data, auth: { uid, token: {} } });

async function refused(p: Promise<any>): Promise<any> {
  try {
    await p;
  } catch (e: any) {
    return e;
  }
  throw new Error('expected the call to be refused');
}

const bal = async (uid: string) => (await db.doc(`coinBalances/${uid}`).get()).data() || {};
const coins = async (uid: string) => (await bal(uid)).totalCoins ?? 0;
const txns = async (uid: string) =>
  (await db.collection('coinTransactions').where('userId', '==', uid).get()).docs.map((d) => d.data());

let seq = 0;
const rid = () => `req_${Date.now()}_${++seq}_abcdef`;

function batch(id: string, coinsLeft: number, source: string, ageMs: number) {
  return {
    batchId: id, initialCoins: coinsLeft, remainingCoins: coinsLeft, source,
    acquiredDate: TS.fromMillis(Date.now() - ageMs),
  };
}

async function seedBalance(uid: string, batches: any[], total?: number) {
  const sum = batches.reduce((s, b) => s + b.remainingCoins, 0);
  await db.doc(`coinBalances/${uid}`).set({
    userId: uid, totalCoins: total ?? sum, earnedCoins: 0, purchasedCoins: 0, giftedCoins: 0,
    spentCoins: 0, lastUpdated: TS.now(), coinBatches: batches,
  });
}

async function profile(uid: string, extra: any = {}) {
  await db.doc(`profiles/${uid}`).set({ userId: uid, displayName: uid, ...extra });
}

beforeEach(async () => {
  await clearAll();
});
afterAll(() => fft.cleanup());

// ---------------------------------------------------------------------------
describe('spendCoins (C-03 / H-12)', () => {
  test('price comes from the server table; a client-sent cost is ignored', async () => {
    await profile('u1');
    await seedBalance('u1', [batch('b1', 100, 'reward', 100 * HOUR)]);
    const r = await call(spendCoins, { featureId: 'superlike', requestId: rid(), cost: 1, price: 1 }, 'u1');
    expect(r.charged).toBe(10);
    expect(r.newBalance).toBe(90);
    expect(await coins('u1')).toBe(90);
  });

  test('option-priced features use the server option table; unknown options are refused', async () => {
    await profile('org');
    await seedBalance('org', [batch('b1', 1000, 'reward', 100 * HOUR)]);
    await db.doc('events/e1').set({ organizerId: 'org', coOrganizerIds: [], price: 0, isFeatured: false });
    const r = await call(spendCoins, { featureId: 'event_boost', requestId: rid(), relatedId: 'e1', option: 6 }, 'org');
    expect(r.charged).toBe(100);
    const ev = (await db.doc('events/e1').get()).data()!;
    expect(ev.isFeatured).toBe(true);
    expect(Math.abs(ev.featuredUntil.toMillis() - (Date.now() + 6 * HOUR))).toBeLessThan(60000);

    const e = await refused(call(spendCoins, { featureId: 'event_boost', requestId: rid(), relatedId: 'e1', option: 5 }, 'org'));
    expect(e.code).toBe('invalid-argument');
    expect(await coins('org')).toBe(900);
  });

  test('event_featured extends an active window; non-owner cannot feature', async () => {
    await profile('org');
    await profile('rando');
    await seedBalance('org', [batch('b1', 1000, 'reward', 100 * HOUR)]);
    await seedBalance('rando', [batch('b1', 1000, 'reward', 100 * HOUR)]);
    const until = Date.now() + 2 * 24 * HOUR;
    await db.doc('events/e2').set({ organizerId: 'org', isFeatured: true, featuredUntil: TS.fromMillis(until), price: 0 });
    const r = await call(spendCoins, { featureId: 'event_featured', requestId: rid(), relatedId: 'e2', option: 14 }, 'org');
    expect(r.charged).toBe(180);
    expect(r.effect.featuredUntil).toBe(until + 14 * 24 * HOUR);

    const e = await refused(call(spendCoins, { featureId: 'event_featured', requestId: rid(), relatedId: 'e2', option: 7 }, 'rando'));
    expect(e.code).toBe('permission-denied');
    expect(await coins('rando')).toBe(1000);
  });

  test('event_rsvp charges the event price stored on the server', async () => {
    await profile('u1');
    await seedBalance('u1', [batch('b1', 100, 'reward', 100 * HOUR)]);
    await db.doc('events/paid').set({ organizerId: 'org', price: 25.4 });
    const r = await call(spendCoins, { featureId: 'event_rsvp', requestId: rid(), relatedId: 'paid' }, 'u1');
    expect(r.charged).toBe(25);
    expect(await coins('u1')).toBe(75);
  });

  test('unknown feature is refused and charges nothing', async () => {
    await profile('u1');
    await seedBalance('u1', [batch('b1', 100, 'reward', 100 * HOUR)]);
    const e = await refused(call(spendCoins, { featureId: 'free_money', requestId: rid() }, 'u1'));
    expect(e.code).toBe('invalid-argument');
    expect(e.details.reason).toBe('unknown-feature');
    expect(await coins('u1')).toBe(100);
    expect(await txns('u1')).toHaveLength(0);
  });

  test('idempotency: a retried requestId never charges twice', async () => {
    await profile('u1');
    await seedBalance('u1', [batch('b1', 100, 'reward', 100 * HOUR)]);
    const id = rid();
    const a = await call(spendCoins, { featureId: 'boost', requestId: id }, 'u1');
    const b = await call(spendCoins, { featureId: 'boost', requestId: id }, 'u1');
    expect(a.alreadyProcessed).toBe(false);
    expect(b.alreadyProcessed).toBe(true);
    expect(b.transactionId).toBe(a.transactionId);
    expect(await coins('u1')).toBe(50);
    expect((await txns('u1')).filter((t) => t.type === 'debit')).toHaveLength(1);
    // Same key for a different purchase is refused.
    const e = await refused(call(spendCoins, { featureId: 'superlike', requestId: id }, 'u1'));
    expect(e.code).toBe('invalid-argument');
    expect(await coins('u1')).toBe(50);
  });

  test('FIFO over coinBatches with the shape the app parses', async () => {
    await profile('u1');
    await seedBalance('u1', [
      batch('old', 5, 'reward', 300 * HOUR),
      batch('mid', 20, 'purchase', 200 * HOUR),
      batch('new', 30, 'allowance', 1 * HOUR),
    ]);
    const r = await call(spendCoins, { featureId: 'superlike', requestId: rid() }, 'u1');
    const b = await bal('u1');
    expect(b.totalCoins).toBe(45);
    expect(b.spentCoins).toBe(10);
    expect(b.userId).toBe('u1');
    expect(b.lastUpdated).toBeInstanceOf(TS);
    expect(b.coinBatches.map((x: any) => [x.batchId, x.remainingCoins, x.source])).toEqual([
      ['mid', 15, 'purchase'],
      ['new', 30, 'allowance'],
    ]);
    expect(b.coinBatches[0].acquiredDate).toBeInstanceOf(TS);
    const t = (await db.doc(`coinTransactions/${r.transactionId}`).get()).data()!;
    expect(t).toMatchObject({
      userId: 'u1', type: 'debit', amount: 10, balanceAfter: 45, reason: 'superLikePurchase',
    });
    expect(t.createdAt).toBeInstanceOf(TS);
    expect(t.metadata.feature).toBe('superlike');
  });

  test('insufficient balance is refused with a reason code; forged batches are not money', async () => {
    await profile('u1');
    await seedBalance('u1', [batch('b', 5, 'reward', 100 * HOUR)]);
    const e = await refused(call(spendCoins, { featureId: 'superlike', requestId: rid() }, 'u1'));
    expect(e.code).toBe('failed-precondition');
    expect(e.details.reason).toBe('insufficient-coins');
    expect(e.message).toMatch(/^insufficient-coins/);
    expect(await coins('u1')).toBe(5);

    // C-03: totalCoins 0 but a client-written batch of 999999.
    await profile('mallory');
    await seedBalance('mallory', [batch('fake', 999999, 'purchase', 100 * HOUR)], 0);
    const e2 = await refused(call(spendCoins, { featureId: 'traveler', requestId: rid() }, 'mallory'));
    expect(e2.details.reason).toBe('insufficient-coins');
  });

  test('server-owned effects are written in the same transaction', async () => {
    await profile('u1');
    await seedBalance('u1', [batch('b', 500, 'reward', 100 * HOUR)]);
    await call(spendCoins, { featureId: 'boost', requestId: rid() }, 'u1');
    await call(spendCoins, { featureId: 'incognito', requestId: rid() }, 'u1');
    await call(spendCoins, { featureId: 'business_promotion', requestId: rid(), option: 7 }, 'u1');
    const p = (await db.doc('profiles/u1').get()).data()!;
    expect(p.isBoosted).toBe(true);
    expect(Math.abs(p.boostExpiry.toMillis() - (Date.now() + 30 * 60000))).toBeLessThan(60000);
    expect(p.isIncognito).toBe(true);
    expect(Math.abs(p.incognitoExpiry.toMillis() - (Date.now() + 24 * HOUR))).toBeLessThan(60000);
    expect(Math.abs(p.businessPromotedUntil.toMillis() - (Date.now() + 7 * 24 * HOUR))).toBeLessThan(60000);
    expect(await coins('u1')).toBe(500 - 50 - 30 - 250);
  });

  test('testers use features free (server-owned tier) but still get the effect', async () => {
    await profile('tester', { membershipTier: 'TEST' });
    const r = await call(spendCoins, { featureId: 'boost', requestId: rid() }, 'tester');
    expect(r.charged).toBe(0);
    expect((await db.doc('profiles/tester').get()).data()!.isBoosted).toBe(true);
    expect(await txns('tester')).toHaveLength(0);
  });
});

// ---------------------------------------------------------------------------
describe('escrow gifts: sendGift / acceptGift / declineGift', () => {
  test('send -> accept: escrow released, receiver credited once', async () => {
    await profile('alice');
    await profile('bob');
    await seedBalance('alice', [batch('a1', 300, 'reward', 100 * HOUR)]);
    const s = await call(sendGift, { receiverId: 'bob', amount: 120, message: 'hi', requestId: rid() }, 'alice');
    expect(await coins('alice')).toBe(180);
    const gift = (await db.doc(`coinGifts/${s.giftId}`).get()).data()!;
    expect(gift).toMatchObject({ senderId: 'alice', receiverId: 'bob', amount: 120, message: 'hi', status: 'pending' });
    expect(gift.sentAt).toBeInstanceOf(TS);
    expect(gift.expiresAt).toBeInstanceOf(TS);
    expect((await db.doc(`gift_escrow/${s.giftId}`).get()).data()!.status).toBe('held');
    expect((await txns('alice')).find((t) => t.reason === 'giftSent')).toMatchObject({ relatedUserId: 'bob', amount: 120 });

    const a = await call(acceptGift, { giftId: s.giftId }, 'bob');
    expect(a.amount).toBe(120);
    const b = await bal('bob');
    expect(b.totalCoins).toBe(120);
    expect(b.giftedCoins).toBe(120);
    expect(b.coinBatches[0]).toMatchObject({ remainingCoins: 120, source: 'gift' });
    expect((await db.doc(`gift_escrow/${s.giftId}`).get()).data()!.status).toBe('released');
    expect((await db.doc(`coinGifts/${s.giftId}`).get()).data()!.status).toBe('accepted');

    // Replays: accept again / decline after accept / sender can't accept.
    expect((await refused(call(acceptGift, { giftId: s.giftId }, 'bob'))).code).toBe('failed-precondition');
    await refused(call(declineGift, { giftId: s.giftId }, 'bob'));
    await db.doc(`coinGifts/${s.giftId}`).update({ status: 'pending' }); // allowed by today's rules
    await refused(call(acceptGift, { giftId: s.giftId }, 'bob'));
    await refused(call(declineGift, { giftId: s.giftId }, 'bob'));
    expect(await coins('bob')).toBe(120);
    expect(await coins('alice')).toBe(180);
  });

  test('send -> decline: the exact batch slices go back to the sender', async () => {
    await profile('alice');
    await profile('bob');
    await seedBalance('alice', [batch('a1', 50, 'reward', 300 * HOUR), batch('a2', 100, 'purchase', 200 * HOUR)]);
    const s = await call(sendGift, { receiverId: 'bob', amount: 80 }, 'alice');
    expect((await bal('alice')).coinBatches.map((b: any) => [b.batchId, b.remainingCoins])).toEqual([['a2', 70]]);
    await call(declineGift, { giftId: s.giftId }, 'bob');
    const a = await bal('alice');
    expect(a.totalCoins).toBe(150);
    expect(a.spentCoins).toBe(0);
    const byId = Object.fromEntries(a.coinBatches.map((b: any) => [b.batchId, b]));
    expect(byId.a1).toMatchObject({ remainingCoins: 50, source: 'reward' });
    expect(byId.a2).toMatchObject({ remainingCoins: 100, source: 'purchase' });
    expect((await db.doc(`gift_escrow/${s.giftId}`).get()).data()!.status).toBe('refunded');
    expect(await coins('bob')).toBe(0);
    // Escrow refunds do not count toward the legacy refund cap ledger.
    expect((await db.collection('gift_refunds').get()).size).toBe(0);
  });

  test('sendGift is idempotent per requestId and validates input', async () => {
    await profile('alice');
    await profile('bob');
    await seedBalance('alice', [batch('a1', 500, 'reward', 100 * HOUR)]);
    const id = rid();
    const a = await call(sendGift, { receiverId: 'bob', amount: 100, requestId: id }, 'alice');
    const b = await call(sendGift, { receiverId: 'bob', amount: 100, requestId: id }, 'alice');
    expect(b.giftId).toBe(a.giftId);
    expect(b.alreadyProcessed).toBe(true);
    expect(await coins('alice')).toBe(400);
    expect((await refused(call(sendGift, { receiverId: 'alice', amount: 100 }, 'alice'))).code).toBe('invalid-argument');
    expect((await refused(call(sendGift, { receiverId: 'bob', amount: 5 }, 'alice'))).code).toBe('invalid-argument');
    expect((await refused(call(sendGift, { receiverId: 'ghost', amount: 50 }, 'alice'))).code).toBe('not-found');
    const e = await refused(call(sendGift, { receiverId: 'bob', amount: 1000 }, 'alice'));
    expect(e.details.reason).toBe('insufficient-coins');
  });

  test('only the receiver can accept', async () => {
    await profile('alice');
    await profile('bob');
    await seedBalance('alice', [batch('a1', 100, 'reward', 100 * HOUR)]);
    const s = await call(sendGift, { receiverId: 'bob', amount: 50 }, 'alice');
    expect((await refused(call(acceptGift, { giftId: s.giftId }, 'alice'))).code).toBe('permission-denied');
    expect(await coins('alice')).toBe(50);
  });
});

// ---------------------------------------------------------------------------
describe('legacy client-created gifts (old app versions)', () => {
  /** Exactly what the OLD app's sendGift does: one transaction, debit + gift. */
  async function legacySendGift(sender: string, receiver: string, amount: number) {
    const giftId = `g_${Math.random().toString(36).slice(2)}`;
    await db.runTransaction(async (tx) => {
      const b = await tx.get(db.doc(`coinBalances/${sender}`));
      const total = b.data()?.totalCoins ?? 0;
      tx.set(db.doc(`coinBalances/${sender}`), { userId: sender, totalCoins: total - amount }, { merge: true });
      tx.set(db.collection('coinTransactions').doc(), {
        userId: sender, type: 'debit', amount, balanceAfter: total - amount,
        reason: 'giftSent', relatedUserId: receiver, createdAt: TS.now(),
      });
      tx.set(db.doc(`coinGifts/${giftId}`), {
        senderId: sender, receiverId: receiver, amount, status: 'pending', sentAt: TS.now(),
      });
    });
    return giftId;
  }

  test('legacy decline still refunds the sender', async () => {
    await db.doc('coinBalances/alice').set({ userId: 'alice', totalCoins: 500 });
    const giftId = await legacySendGift('alice', 'bob', 200);
    await call(declineGift, { giftId }, 'bob');
    expect(await coins('alice')).toBe(500);
    expect((await txns('alice')).find((t) => t.type === 'credit')!.reason).toBe('refund');
  });

  test('legacy accept credits the receiver once, and blocks a later refund', async () => {
    await db.doc('coinBalances/alice').set({ userId: 'alice', totalCoins: 500 });
    const giftId = await legacySendGift('alice', 'bob', 200);
    await call(acceptGift, { giftId }, 'bob');
    expect(await coins('bob')).toBe(200);
    await db.doc(`coinGifts/${giftId}`).update({ status: 'pending' }); // allowed by today's rules
    await call(declineGift, { giftId }, 'bob'); // decline "succeeds" but refund is withheld
    expect(await coins('alice')).toBe(300);
    await db.doc(`coinGifts/${giftId}`).update({ status: 'pending' });
    await refused(call(acceptGift, { giftId }, 'bob'));
    expect(await coins('bob')).toBe(200);
  });

  test('ATTACK: forged gift naming a victim as sender mints nothing on accept', async () => {
    await db.doc('coinGifts/forged').set({ senderId: 'victim', receiverId: 'mallory', amount: 1000, status: 'pending' });
    const e = await refused(call(acceptGift, { giftId: 'forged' }, 'mallory'));
    expect(e.code).toBe('failed-precondition');
    expect(await coins('mallory')).toBe(0);
    const f = await db.collection('fraud_flags').where('type', '==', 'gift_accept_unverified').get();
    expect(f.size).toBe(1);
  });
});

// ---------------------------------------------------------------------------
describe('H-11 Shop send coins via giftCoins', () => {
  test('sender debited AND receiver credited, with parseable ledger + history', async () => {
    await profile('alice');
    await profile('bob');
    await seedBalance('alice', [batch('a1', 300, 'reward', 100 * HOUR)]);
    const r = await call(giftCoins, { receiverId: 'bob', amount: 120, requestId: rid() }, 'alice');
    expect(r.senderNewBalance).toBe(180);
    expect(await coins('alice')).toBe(180);
    expect(await coins('bob')).toBe(120);
    expect((await bal('alice')).coinBatches[0].remainingCoins).toBe(180);
    expect((await bal('bob')).coinBatches[0]).toMatchObject({ remainingCoins: 120, source: 'gift' });
    expect((await txns('alice'))[0]).toMatchObject({ type: 'debit', reason: 'giftSent', relatedUserId: 'bob' });
    expect((await txns('bob'))[0]).toMatchObject({ type: 'credit', reason: 'giftReceived', relatedUserId: 'alice' });
    expect((await db.doc(`coinGifts/${r.giftId}`).get()).data()!.status).toBe('accepted');
  });

  test('insufficient coins is a clear refusal, not an internal error', async () => {
    await profile('alice');
    await profile('bob');
    await seedBalance('alice', [batch('a1', 10, 'reward', 100 * HOUR)]);
    const e = await refused(call(giftCoins, { receiverId: 'bob', amount: 50 }, 'alice'));
    expect(e.code).toBe('failed-precondition');
    expect(e.details.reason).toBe('insufficient-coins');
    expect(await coins('bob')).toBe(0);
  });
});

// ---------------------------------------------------------------------------
describe('H-10 purchased-coin hold and gift velocity', () => {
  test('gifting coins bought < 72h ago is refused on every gift path', async () => {
    await profile('alice');
    await profile('bob');
    await seedBalance('alice', [batch('p1', 500, 'purchase', 1 * HOUR)]);
    for (const [fn, data] of [[sendGift, { receiverId: 'bob', amount: 100 }], [giftCoins, { receiverId: 'bob', amount: 100 }]] as any) {
      const e = await refused(call(fn, data, 'alice'));
      expect(e.code).toBe('failed-precondition');
      expect(e.details.reason).toBe('gift-purchase-hold');
      expect(e.details.releaseAt).toBeGreaterThan(Date.now());
    }
    expect(await coins('alice')).toBe(500);
    // Spending them on a feature is fine.
    await call(spendCoins, { featureId: 'superlike', requestId: rid() }, 'alice');
    expect(await coins('alice')).toBe(490);
  });

  test('FIFO decides: older earned coins can be gifted, fresh purchases cannot', async () => {
    await profile('alice');
    await profile('bob');
    await seedBalance('alice', [batch('e1', 100, 'reward', 500 * HOUR), batch('p1', 500, 'purchase', 1 * HOUR)]);
    await call(giftCoins, { receiverId: 'bob', amount: 100 }, 'alice');
    expect(await coins('bob')).toBe(100);
    const e = await refused(call(giftCoins, { receiverId: 'bob', amount: 10 }, 'alice'));
    expect(e.details.reason).toBe('gift-purchase-hold');
  });

  test('purchases older than 72h can be gifted', async () => {
    await profile('alice');
    await profile('bob');
    await seedBalance('alice', [batch('p1', 500, 'purchase', 73 * HOUR)]);
    await call(sendGift, { receiverId: 'bob', amount: 100 }, 'alice');
    expect(await coins('alice')).toBe(400);
  });

  test('max 10 gifts per sender per day', async () => {
    await profile('alice');
    await profile('bob');
    await seedBalance('alice', [batch('e1', 5000, 'reward', 500 * HOUR)]);
    for (let i = 0; i < 10; i++) {
      await call(i % 2 ? sendGift : giftCoins, { receiverId: 'bob', amount: 10 }, 'alice');
    }
    const e = await refused(call(sendGift, { receiverId: 'bob', amount: 10 }, 'alice'));
    expect(e.code).toBe('resource-exhausted');
    expect(e.details.reason).toBe('gift-velocity-limit');
    expect(await coins('alice')).toBe(4900);
  });

  test('max 5,000 coins per sender per day', async () => {
    await profile('alice');
    await profile('bob');
    await seedBalance('alice', [batch('e1', 9000, 'reward', 500 * HOUR)]);
    await call(giftCoins, { receiverId: 'bob', amount: 4995 }, 'alice');
    const e = await refused(call(giftCoins, { receiverId: 'bob', amount: 10 }, 'alice'));
    expect(e.details.reason).toBe('gift-velocity-limit');
    await call(sendGift, { receiverId: 'bob', amount: 10 }, 'alice').catch(() => undefined);
    expect(await coins('alice')).toBe(9000 - 4995);
  });
});
