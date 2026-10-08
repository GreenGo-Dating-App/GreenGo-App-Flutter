/**
 * Phase 1 / P1-5 payment integrity: emulator integration tests.
 *
 *   H-10  refunds / chargebacks claw back coins (Play RTDN voided notification,
 *         Play Voided Purchases API poll, Apple REFUND for consumables) and
 *         revoke refunded subscription time (current period only).
 *   M-12  a refunded/revoked Apple transaction is never credited.
 *   M-11  a Play receipt bought by another account (obfuscatedAccountId) is refused.
 *   H-13  sandbox / license-tester grants are GRANTED but flagged for non-admins.
 *
 * Real Firestore + Auth emulators; only the store APIs and the Pub/Sub OIDC
 * verifier are mocked.
 *
 *   firebase emulators:exec --only firestore,auth --project test-project \
 *     "npx jest --config jest.security.config.js"
 */

const PUSH_SA = '666632803027-compute@developer.gserviceaccount.com';

jest.mock('google-auth-library', () => {
  const actual = jest.requireActual('google-auth-library');
  return {
    ...actual,
    OAuth2Client: jest.fn().mockImplementation(() => ({
      verifyIdToken: jest.fn(async ({ idToken }: any) => {
        if (idToken !== 'valid-pubsub-oidc') throw new Error('bad token');
        return { getPayload: () => ({ email: PUSH_SA, email_verified: true }) };
      }),
    })),
  };
});

jest.mock('../../src/shared/purchase_verification', () => {
  const actual = jest.requireActual('../../src/shared/purchase_verification');
  return {
    ...actual,
    verifyGooglePlayPurchase: jest.fn(),
    verifyAppStorePurchase: jest.fn(),
    decodeAppStoreNotification: jest.fn(),
    getGooglePlaySubscriptionExpiry: jest.fn(),
    listGooglePlayVoidedPurchases: jest.fn(),
  };
});

import * as admin from 'firebase-admin';
import functionsTest from 'firebase-functions-test';
import * as pv from '../../src/shared/purchase_verification';

const fft = functionsTest({ projectId: process.env.GCLOUD_PROJECT });

import { verifyGooglePlayCoinPurchase, verifyAppStoreCoinPurchase } from '../../src/coins';
import { playStoreNotifications, appStoreNotificationsV2 } from '../../src/subscription/storeNotifications';
import { runPlayVoidedPurchasesPoll } from '../../src/subscription/voidedPurchasesPoll';
import { ledgerIdFor } from '../../src/coins/purchaseClawback';

const db = admin.firestore();
const m = {
  play: pv.verifyGooglePlayPurchase as jest.Mock,
  apple: pv.verifyAppStorePurchase as jest.Mock,
  decode: pv.decodeAppStoreNotification as jest.Mock,
  subExpiry: pv.getGooglePlaySubscriptionExpiry as jest.Mock,
  voided: pv.listGooglePlayVoidedPurchases as jest.Mock,
};

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
const coins = async (uid: string) => ((await db.doc(`coinBalances/${uid}`).get()).data()?.totalCoins ?? 0);
const batchSum = async (uid: string) =>
  (((await db.doc(`coinBalances/${uid}`).get()).data()?.coinBatches ?? []) as any[])
    .reduce((s, b) => s + (b.remainingCoins ?? 0), 0);
/** What the app shows: CoinBalance.availableCoins = max(totalCoins, sum of batches). */
const available = async (uid: string) => Math.max(await coins(uid), await batchSum(uid));
const debits = async (uid: string) =>
  (await db.collection('coinTransactions').where('userId', '==', uid).where('type', '==', 'debit').get()).docs;
const flags = async (type: string) =>
  (await db.collection('fraud_flags').where('type', '==', type).get()).docs.map((d) => d.data());

function fakeRes() {
  return {
    statusCode: 0, body: undefined as any,
    status(c: number) { this.statusCode = c; return this; },
    send(b?: any) { this.body = b; if (!this.statusCode) this.statusCode = 200; return this; },
  };
}

async function rtdn(payload: any) {
  const res = fakeRes();
  const req: any = {
    body: { message: { data: Buffer.from(JSON.stringify(payload)).toString('base64') } },
    get: (h: string) => (h.toLowerCase() === 'authorization' ? 'Bearer valid-pubsub-oidc' : undefined),
    headers: { authorization: 'Bearer valid-pubsub-oidc' },
  };
  await (playStoreNotifications as any)(req, res);
  return res;
}

async function asn(info: any) {
  m.decode.mockResolvedValueOnce(info);
  const res = fakeRes();
  await (appStoreNotificationsV2 as any)({ body: { signedPayload: 'jws' }, get: () => undefined, headers: {} }, res);
  return res;
}

const playOk = (over: any = {}) => ({ verified: true, transactionId: 'GPA.1', environment: 'PRODUCTION', ...over });

async function buyPlay(uid: string, token: string, over: any = {}, productId = 'greengo_coins_100') {
  m.play.mockResolvedValueOnce(playOk(over));
  return call(verifyGooglePlayCoinPurchase, { productId, purchaseToken: token, verificationData: token }, uid);
}

async function buyApple(uid: string, txId: string, over: any = {}, productId = 'greengo_coins_500') {
  m.apple.mockResolvedValueOnce({
    verified: true, revoked: false, expired: false, productId, transactionId: txId,
    originalTransactionId: txId, environment: 'PRODUCTION', ...over,
  });
  return call(verifyAppStoreCoinPurchase, { productId, purchaseToken: 'jws', verificationData: 'jws' }, uid);
}

beforeEach(async () => {
  await clearAll();
  Object.values(m).forEach((f) => f.mockReset());
  process.env.APPLE_APP_ID = '123456';
});
afterAll(() => fft.cleanup());

// ---------------------------------------------------------------------------
describe('H-10 Google Play refund clawback', () => {
  test('ATTACK: voided RTDN claws the coins back once; replay does not debit twice', async () => {
    await buyPlay('u1', 'tokV', { transactionId: 'GPA.V' });
    expect(await available('u1')).toBe(100);

    const msg = { version: '1.0', packageName: 'com.greengochat.greengochatapp', eventTimeMillis: String(Date.now()),
      voidedPurchaseNotification: { purchaseToken: 'tokV', orderId: 'GPA.V', productType: 2, refundType: 1 } };
    expect((await rtdn(msg)).statusCode).toBe(200);
    expect(await coins('u1')).toBe(0);
    expect(await available('u1')).toBe(0);

    expect((await rtdn(msg)).statusCode).toBe(200); // Pub/Sub redelivery
    expect(await coins('u1')).toBe(0);
    const d = await debits('u1');
    expect(d).toHaveLength(1);
    expect(d[0].data()).toMatchObject({ amount: 100, reason: 'refundClawback', balanceAfter: 0 });
    const ledger = (await db.doc(`purchaseLedger/${ledgerIdFor('tokV')}`).get()).data()!;
    expect(ledger.revokedAt).toBeTruthy();
    expect(ledger.revokeReason).toBe('play_voided');
    expect(await flags('purchase_refunded')).toHaveLength(1);
  });

  test('ATTACK: spend-then-refund leaves a negative balance (debt), not free coins', async () => {
    await buyPlay('u2', 'tokS', { transactionId: 'GPA.S' });
    // The app spends 80 coins: totalCoins and the batch go down to 20.
    const ref = db.doc('coinBalances/u2');
    const b = (await ref.get()).data()!;
    await ref.update({ totalCoins: 20, coinBatches: b.coinBatches.map((x: any) => ({ ...x, remainingCoins: 20 })) });
    await rtdn({ voidedPurchaseNotification: { purchaseToken: 'tokS', orderId: 'GPA.S', productType: 2, refundType: 1 } });
    expect(await coins('u2')).toBe(-80);
    expect(await available('u2')).toBe(0);
    expect((await flags('purchase_refunded'))[0]).toMatchObject({ negativeBalance: true, coins: 100 });
  });

  test('ATTACK: Voided Purchases API poll claws back (matched by orderId) and is idempotent with the RTDN', async () => {
    await buyPlay('u3', 'tokP', { transactionId: 'GPA.P' });
    await buyPlay('u3', 'tokKeep', { transactionId: 'GPA.K' });
    expect(await coins('u3')).toBe(200);
    const voidedAt = Date.now() - 3600_000;
    // The poll sees a different token spelling but the same Play orderId.
    m.voided.mockResolvedValue({ items: [{ purchaseToken: 'tokP-as-listed', orderId: 'GPA.P', voidedTimeMillis: voidedAt }] });

    const r1 = await runPlayVoidedPurchasesPoll();
    expect(r1.outcomes).toEqual({ coins_clawed_back: 1 });
    expect(await coins('u3')).toBe(100);

    const r2 = await runPlayVoidedPurchasesPoll();
    expect(r2.outcomes).toEqual({ coins_already: 1 });
    await rtdn({ voidedPurchaseNotification: { purchaseToken: 'tokP', orderId: 'GPA.P', productType: 2, refundType: 1 } });
    expect(await coins('u3')).toBe(100);
    expect(await debits('u3')).toHaveLength(1);

    const cursor = (await db.doc('play_voided_purchases_state/cursor').get()).data()!;
    expect(cursor.lastVoidedTimeMillis).toBe(voidedAt);
    // Second run started from the cursor (minus overlap), not 30 days back.
    const start2 = m.voided.mock.calls[1][0];
    expect(start2).toBeGreaterThan(Date.now() - 3 * 86400_000);
  });

  test('voided subscription: current period revokes Base, a past renewal does not', async () => {
    const future = admin.firestore.Timestamp.fromMillis(Date.now() + 200 * 86400_000);
    await db.doc('profiles/s1').set({ hasBaseMembership: true, baseMembershipEndDate: future, membershipTier: 'FREE' });
    await db.doc('subscriptions/sub1').set({ userId: 's1', originalTransactionId: 'subTok',
      productId: 'greengo_base_membership', createdAt: admin.firestore.Timestamp.now(), status: 'active' });

    // Refund of last year's order: current period untouched.
    m.subExpiry.mockResolvedValue({ expiresDateMs: future.toMillis(), latestOrderId: 'GPA.SUB..1' });
    await rtdn({ voidedPurchaseNotification: { purchaseToken: 'subTok', orderId: 'GPA.SUB..0', productType: 1, refundType: 1 } });
    expect((await db.doc('profiles/s1').get()).data()!.hasBaseMembership).toBe(true);

    // Refund of the current period: Base ends now.
    await rtdn({ voidedPurchaseNotification: { purchaseToken: 'subTok', orderId: 'GPA.SUB..1', productType: 1, refundType: 1 } });
    expect((await db.doc('profiles/s1').get()).data()!.hasBaseMembership).toBe(false);
    expect((await db.doc('subscriptions/sub1').get()).data()!.voidedOrderIds).toEqual(['GPA.SUB..0', 'GPA.SUB..1']);
  });

  test('ATTACK: forged voided notification without the Pub/Sub OIDC token is rejected', async () => {
    await buyPlay('u4', 'tokF', { transactionId: 'GPA.F' });
    const res = fakeRes();
    await (playStoreNotifications as any)({
      body: { message: { data: Buffer.from(JSON.stringify({ voidedPurchaseNotification: { purchaseToken: 'tokF' } })).toString('base64') } },
      get: () => undefined, headers: {},
    }, res);
    expect(res.statusCode).toBe(401);
    expect(await coins('u4')).toBe(100);
  });
});

// ---------------------------------------------------------------------------
describe('H-10 / M-12 App Store', () => {
  test('ATTACK: REFUND of a consumable claws the coins back (once)', async () => {
    await buyApple('a1', '2000001');
    expect(await coins('a1')).toBe(500);
    const refund = { notificationType: 'REFUND', productId: 'greengo_coins_500', transactionId: '2000001',
      originalTransactionId: '2000001', productType: 'Consumable', environment: 'PRODUCTION', revocationDateMs: Date.now() };
    const res = await asn(refund);
    expect(res.statusCode).toBe(200);
    expect(res.body).toBe('OK');
    expect(await coins('a1')).toBe(0);
    await asn(refund); // Apple retry
    expect(await coins('a1')).toBe(0);
    expect(await debits('a1')).toHaveLength(1);
    expect((await db.doc(`purchaseLedger/${ledgerIdFor('2000001')}`).get()).data()!.revokeReason).toBe('apple_refund');
  });

  test('ATTACK: a refunded/revoked transaction is never credited', async () => {
    await expect(buyApple('a2', '2000002', { revoked: true })).rejects.toBeTruthy();
    expect(await coins('a2')).toBe(0);
    expect((await db.doc(`purchaseLedger/${ledgerIdFor('2000002')}`).get()).exists).toBe(false);
  });

  test('CONSUMPTION_REQUEST is recorded and acknowledged', async () => {
    const res = await asn({ notificationType: 'CONSUMPTION_REQUEST', transactionId: '2000003',
      productId: 'greengo_coins_100', consumptionRequestReason: 'UNINTENDED_PURCHASE' });
    expect(res.statusCode).toBe(200);
    expect((await db.doc('apple_consumption_requests/2000003').get()).data()).toMatchObject({ responded: false, reason: 'UNINTENDED_PURCHASE' });
  });
});

// ---------------------------------------------------------------------------
describe('H-13 sandbox purchases are granted but flagged', () => {
  test('sandbox Apple grant to a normal user: granted + flagged', async () => {
    const r = await buyApple('t1', '3000001', { environment: 'SANDBOX' });
    expect(r.coinsAdded).toBe(500);
    expect((await db.doc(`purchaseLedger/${ledgerIdFor('3000001')}`).get()).data()!.environment).toBe('SANDBOX');
    expect(await flags('sandbox_purchase_non_admin')).toEqual([expect.objectContaining({ userId: 't1', platform: 'ios' })]);
  });

  test('Play license-tester grant to a normal user: granted + flagged', async () => {
    const r = await buyPlay('t2', 'tokT', { purchaseType: 0, environment: 'SANDBOX' });
    expect(r.coinsAdded).toBe(100);
    expect((await db.doc(`purchaseLedger/${ledgerIdFor('tokT')}`).get()).data()!.purchaseType).toBe(0);
    expect(await flags('sandbox_purchase_non_admin')).toHaveLength(1);
  });

  test('sandbox grant to an admin (App Review / QA account): granted, not flagged', async () => {
    await db.doc('admin_users/qa').set({ role: 'admin' });
    const r = await buyApple('qa', '3000002', { environment: 'SANDBOX' });
    expect(r.coinsAdded).toBe(500);
    expect(await flags('sandbox_purchase_non_admin')).toHaveLength(0);
  });
});

// ---------------------------------------------------------------------------
describe('M-11 Play account binding', () => {
  test('ATTACK: receipt bought by another account is refused', async () => {
    await expect(buyPlay('thief', 'tokA', { obfuscatedAccountId: 'victim' }))
      .rejects.toMatchObject({ code: 'permission-denied' });
    expect(await coins('thief')).toBe(0);
    expect(await flags('purchase_account_mismatch')).toHaveLength(1);
  });

  test('LEGIT: receipt carrying the buyer uid (what the app sends) is granted', async () => {
    const r = await buyPlay('buyer', 'tokB', { obfuscatedAccountId: 'buyer' });
    expect(r.coinsAdded).toBe(100);
    expect((await db.doc(`purchaseLedger/${ledgerIdFor('tokB')}`).get()).data()!.obfuscatedAccountId).toBe('buyer');
  });
});

// ---------------------------------------------------------------------------
describe('LEGIT purchases are unaffected', () => {
  test('production Play + Apple purchases: credited once, no flags, ledger complete', async () => {
    const p = await buyPlay('l1', 'tokL', { transactionId: 'GPA.L' }, 'greengo_coins_1000');
    const a = await buyApple('l1', '4000001');
    const again = await buyApple('l1', '4000001');
    expect(p.coinsAdded).toBe(1000);
    expect(a.coinsAdded).toBe(500);
    expect(again.alreadyProcessed).toBe(true);
    expect(await coins('l1')).toBe(1500);
    expect((await db.collection('fraud_flags').get()).size).toBe(0);
    expect((await db.doc(`purchaseLedger/${ledgerIdFor('tokL')}`).get()).data()).toMatchObject({
      userId: 'l1', productId: 'greengo_coins_1000', platform: 'android', coins: 1000,
      transactionId: 'GPA.L', environment: 'PRODUCTION',
    });
  });

  test('subscription RTDN / unknown Apple notifications still behave as before', async () => {
    expect((await rtdn({ subscriptionNotification: { purchaseToken: 'nope', notificationType: 2 } })).body)
      .toBe('Unknown subscription');
    expect((await asn({ notificationType: 'REFUND', transactionId: '999', originalTransactionId: '999' })).body)
      .toBe('Unknown subscription');
  });
});
