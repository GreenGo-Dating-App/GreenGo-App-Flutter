/**
 * verifyPurchase (store path) end to end against the Firestore emulator, with
 * the STORE verification mocked (audit 2026-10-11, L4: the main store path had
 * no automated test, and integration PAY-05 could not fail).
 *
 *   purchase verified by the store -> profiles.membershipTier + end date from
 *   the store expiry; idempotent replay; expired / revoked / mismatched
 *   products never grant; one store token cannot serve two accounts; Base
 *   sets the Base fields (never a paid tier) plus the 500-coin bonus once.
 *
 *   firebase emulators:exec --only firestore,auth --project test-project \
 *     "npx jest --config jest.security.config.js verify-purchase"
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const store: { play: any; apple: any } = { play: null, apple: null };
jest.mock('../../src/shared/purchase_verification', () => ({
  verifyGooglePlaySubscription: jest.fn(async () => store.play),
  verifyAppStorePurchase: jest.fn(async () => store.apple),
}));

const fft = functionsTest({ projectId: process.env.GCLOUD_PROJECT });

import { verifyPurchase } from '../../src/subscription';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
const db = admin.firestore();
const DAY = 86_400_000;

async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  if (!/^(localhost|127\.0\.0\.1)/.test(host)) throw new Error('Refusing: not a local emulator');
  await new Promise<void>((resolve, reject) => {
    const req = http.request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE',
      path: `/emulator/v1/projects/${PROJECT}/databases/(default)/documents` }, (res) => { res.resume(); res.on('end', resolve); });
    req.on('error', reject);
    req.end();
  });
}

const call = (data: any, uid: string) =>
  (fft.wrap(verifyPurchase) as any)({ data, auth: { uid, token: {} } });
async function refused(p: Promise<any>): Promise<any> {
  try { await p; } catch (e: any) { return e; }
  throw new Error('expected the call to be refused');
}
const profile = async (uid: string) => (await db.doc(`profiles/${uid}`).get()).data() || {};
const android = (uid: string, productId: string, token: string) => ({
  userId: uid, platform: 'android', productId, purchaseToken: token, verificationData: token,
});

beforeEach(async () => {
  await clearAll();
  await db.doc('profiles/buyer').set({ userId: 'buyer', membershipTier: 'FREE' });
  await db.doc('profiles/other').set({ userId: 'other', membershipTier: 'FREE' });
  store.play = null;
  store.apple = null;
});
afterAll(() => fft.cleanup());

describe('verifyPurchase (store path, mocked store verification)', () => {
  test('a verified Gold purchase sets the tier and the store expiry; a replay grants nothing more', async () => {
    const expiry = Date.now() + 30 * DAY;
    store.play = { verified: true, productId: 'gold_premium_monthly', expiresDateMs: expiry };
    const r = await call(android('buyer', 'gold_premium_monthly', 'tok-gold-1'), 'buyer');
    expect(r).toMatchObject({ verified: true, expired: false, alreadyProcessed: false, tier: 'GOLD', coinsGranted: 0 });
    let p = await profile('buyer');
    expect(p.membershipTier).toBe('GOLD');
    expect(p.membershipEndDate.toMillis()).toBe(expiry);
    expect(p.membershipSource).toBe('purchase');
    expect((await db.collection('membershipLedger').get()).size).toBe(1);

    const again = await call(android('buyer', 'gold_premium_monthly', 'tok-gold-1'), 'buyer');
    expect(again.alreadyProcessed).toBe(true);
    expect((await db.collection('membershipLedger').get()).size).toBe(1);
    expect((await db.collection('subscriptions').get()).size).toBe(1);
    p = await profile('buyer');
    expect(p.membershipEndDate.toMillis()).toBe(expiry);
  });

  test('expired / revoked store transactions never grant and write nothing', async () => {
    store.play = { verified: true, productId: 'platinum_vip_monthly', expiresDateMs: Date.now() - DAY };
    const r = await call(android('buyer', 'platinum_vip_monthly', 'tok-old'), 'buyer');
    expect(r).toMatchObject({ verified: true, expired: true, tier: 'FREE' });
    store.play = { verified: true, revoked: true, productId: 'platinum_vip_monthly', expiresDateMs: Date.now() + DAY };
    const r2 = await call(android('buyer', 'platinum_vip_monthly', 'tok-revoked'), 'buyer');
    expect(r2.revoked).toBe(true);
    expect((await profile('buyer')).membershipTier).toBe('FREE');
    expect((await db.collection('membershipLedger').get()).size).toBe(0);
  });

  test('a failed verification or a token of another product is refused', async () => {
    store.play = { verified: false, error: 'bad token' };
    expect((await refused(call(android('buyer', 'gold_premium_monthly', 'tok-x'), 'buyer'))).code).toBe('failed-precondition');
    // A monthly Silver token presented as yearly Platinum.
    store.play = { verified: true, productId: 'silver_premium_monthly', expiresDateMs: Date.now() + 30 * DAY };
    expect((await refused(call(android('buyer', 'greengo_platinum_yearly', 'tok-s'), 'buyer'))).code).toBe('failed-precondition');
    expect((await profile('buyer')).membershipTier).toBe('FREE');
  });

  test('one store purchase cannot be claimed by a second account, nor for someone else', async () => {
    store.play = { verified: true, productId: 'gold_premium_monthly', expiresDateMs: Date.now() + 30 * DAY };
    await call(android('buyer', 'gold_premium_monthly', 'tok-shared'), 'buyer');
    expect((await refused(call(android('other', 'gold_premium_monthly', 'tok-shared'), 'other'))).code).toBe('already-exists');
    expect((await profile('other')).membershipTier).toBe('FREE');
    expect((await refused(call(android('other', 'gold_premium_monthly', 'tok-2'), 'buyer'))).code).toBe('permission-denied');
  });

  test('Base sets the Base membership (never a paid tier) and the 500-coin bonus once', async () => {
    const expiry = Date.now() + 365 * DAY;
    store.play = { verified: true, productId: 'greengo_base_membership', expiresDateMs: expiry };
    const r = await call(android('buyer', 'greengo_base_membership', 'tok-base'), 'buyer');
    expect(r.coinsGranted).toBe(500);
    const p = await profile('buyer');
    expect(p.hasBaseMembership).toBe(true);
    expect(p.baseMembershipEndDate.toMillis()).toBe(expiry);
    expect(p.membershipTier).toBe('FREE');
    expect((await db.doc('coinBalances/buyer').get()).data()?.totalCoins).toBe(500);
    // Renewal (next period) of the same subscription: no second bonus.
    store.play = { verified: true, productId: 'greengo_base_membership', expiresDateMs: expiry + 365 * DAY };
    const r2 = await call(android('buyer', 'greengo_base_membership', 'tok-base'), 'buyer');
    expect(r2.coinsGranted).toBe(0);
    expect((await db.doc('coinBalances/buyer').get()).data()?.totalCoins).toBe(500);
  });

  test('a purchase never downgrades an active higher tier', async () => {
    const platEnd = Date.now() + 60 * DAY;
    await db.doc('profiles/buyer').set({
      membershipTier: 'PLATINUM', membershipEndDate: admin.firestore.Timestamp.fromMillis(platEnd),
    }, { merge: true });
    store.play = { verified: true, productId: 'silver_premium_monthly', expiresDateMs: Date.now() + 30 * DAY };
    const r = await call(android('buyer', 'silver_premium_monthly', 'tok-silver'), 'buyer');
    expect(r.tier).toBe('PLATINUM');
    const p = await profile('buyer');
    expect(p.membershipTier).toBe('PLATINUM');
    expect(p.membershipEndDate.toMillis()).toBeGreaterThanOrEqual(platEnd);
  });
});
