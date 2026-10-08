/**
 * Phase 0 security fixes: emulator integration tests.
 *
 * Every attack test reproduces an exploit from the 2026-10-08 audit and must be
 * REFUSED; every "legit" test is a normal app flow that must keep WORKING.
 * Runs against the real Firestore + Auth emulators (no mocks for the database),
 * because several fixes depend on real Firestore behaviour (commit timestamps).
 *
 *   firebase emulators:exec --only firestore,auth --project demo-gg \
 *     "npx jest --config jest.security.config.js"
 */

// Store APIs and outbound email are the only things mocked.
jest.mock('../../src/shared/purchase_verification', () => {
  const actual = jest.requireActual('../../src/shared/purchase_verification');
  return {
    ...actual,
    verifyGooglePlayPurchase: jest.fn(async () => ({ verified: true, transactionId: 'GPA.1' })),
    getGooglePlaySubscriptionExpiry: jest.fn(async () => ({ expiresDateMs: Date.now() + 86400000 })),
  };
});

import * as admin from 'firebase-admin';
import functionsTest from 'firebase-functions-test';

const fft = functionsTest({ projectId: process.env.GCLOUD_PROJECT });

import { declineGift, verifyGooglePlayCoinPurchase } from '../../src/coins';
import { applySignupGrants } from '../../src/coupons/applySignupGrants';
import { redeemReferral } from '../../src/referral/redeemReferral';
import { sendBrevoEmailFunction, updateBrevoEmailTemplate, getBrevoEmailLogs } from '../../src/notifications/brevoEmailService';
import { sendPushNotification } from '../../src/notifications/pushNotifications';
import {
  sendWelcomeEmail,
  cleanupOrphanedAuthUser,
  adminChangeUserPassword,
  sendPasswordResetEmail,
} from '../../src/admin/adminPanelFunctions';
import { playStoreNotifications } from '../../src/subscription/storeNotifications';

const db = admin.firestore();
const auth = admin.auth();

const fetchMock = jest.fn(async () => ({ ok: true, status: 200, text: async () => '{}' }));
(global as any).fetch = fetchMock;

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
  const users = await auth.listUsers(1000);
  if (users.users.length) await auth.deleteUsers(users.users.map((u) => u.uid));
}

async function newUser(uid: string, email: string, createdDaysAgo = 0) {
  if (createdDaysAgo === 0) {
    await auth.createUser({ uid, email, password: 'Passw0rd!x' });
  } else {
    const created = new Date(Date.now() - createdDaysAgo * 86400000).toUTCString();
    const r = await auth.importUsers([{ uid, email, metadata: { creationTime: created, lastSignInTime: created } }]);
    if (r.failureCount) throw new Error(JSON.stringify(r.errors));
  }
}

const v2 = (fn: any) => fft.wrap(fn) as any;
const call = (fn: any, data: any, uid?: string, email?: string) =>
  v2(fn)({ data, auth: uid ? { uid, token: { email } } : undefined });
const v1 = (fn: any, data: any, ctx: any) => (fft.wrap(fn) as any)(data, ctx);
const coins = async (uid: string) => ((await db.doc(`coinBalances/${uid}`).get()).data()?.totalCoins ?? 0);

beforeEach(async () => {
  await clearAll();
  fetchMock.mockClear();
});
afterAll(() => fft.cleanup());

// ---------------------------------------------------------------------------
describe('C-01 declineGift', () => {
  /** Exactly what the app's sendGift does: one transaction, debit + gift. */
  async function appSendGift(sender: string, receiver: string, amount: number) {
    const giftId = `g_${Math.random().toString(36).slice(2)}`;
    await db.runTransaction(async (tx) => {
      const bal = await tx.get(db.doc(`coinBalances/${sender}`));
      const total = bal.data()?.totalCoins ?? 0;
      tx.set(db.doc(`coinBalances/${sender}`), { userId: sender, totalCoins: total - amount }, { merge: true });
      tx.set(db.collection('coinTransactions').doc(), {
        userId: sender, type: 'debit', amount, balanceAfter: total - amount,
        reason: 'giftSent', relatedUserId: receiver, createdAt: admin.firestore.Timestamp.now(),
      });
      tx.set(db.doc(`coinGifts/${giftId}`), {
        senderId: sender, receiverId: receiver, amount, status: 'pending',
        sentAt: admin.firestore.Timestamp.now(),
      });
    });
    return giftId;
  }

  test('LEGIT: genuine gift declined -> sender refunded', async () => {
    await db.doc('coinBalances/alice').set({ userId: 'alice', totalCoins: 500 });
    const giftId = await appSendGift('alice', 'bob', 200);
    expect(await coins('alice')).toBe(300);
    await call(declineGift, { giftId }, 'bob');
    expect(await coins('alice')).toBe(500);
    expect((await db.doc(`coinGifts/${giftId}`).get()).data()?.status).toBe('declined');
  });

  test('ATTACK: forged self-gift mints nothing', async () => {
    await db.doc('coinGifts/x').set({ senderId: 'mallory', receiverId: 'mallory', amount: 1000000, status: 'pending' });
    await call(declineGift, { giftId: 'x' }, 'mallory');
    expect(await coins('mallory')).toBe(0);
    const flags = await db.collection('fraud_flags').get();
    expect(flags.docs[0].data().reason).toBe('self_gift');
  });

  test('ATTACK: forged gift via alt account (no debit) mints nothing', async () => {
    await db.doc('coinGifts/y').set({ senderId: 'mallory', receiverId: 'alt', amount: 500, status: 'pending' });
    await call(declineGift, { giftId: 'y' }, 'alt');
    expect(await coins('mallory')).toBe(0);
  });

  test('ATTACK: re-pending a refunded gift cannot refund twice', async () => {
    await db.doc('coinBalances/alice').set({ userId: 'alice', totalCoins: 500 });
    const giftId = await appSendGift('alice', 'bob', 200);
    await call(declineGift, { giftId }, 'bob');
    await db.doc(`coinGifts/${giftId}`).update({ status: 'pending' }); // allowed by today's rules
    await call(declineGift, { giftId }, 'bob');
    expect(await coins('alice')).toBe(500);
  });
});

// ---------------------------------------------------------------------------
describe('C-02 Google Play coin purchase', () => {
  test('LEGIT: purchase granted once, retry is idempotent', async () => {
    const data = { productId: 'greengo_coins_100', purchaseToken: 'tok1', verificationData: 'tok1' };
    const r1 = await call(verifyGooglePlayCoinPurchase, data, 'u1');
    const r2 = await call(verifyGooglePlayCoinPurchase, data, 'u1');
    expect(r1.coinsAdded).toBeGreaterThan(0);
    expect(r2.alreadyProcessed).toBe(true);
    expect(await coins('u1')).toBe(r1.coinsAdded);
  });

  test('ATTACK: replay with a fresh purchaseToken is refused', async () => {
    await call(verifyGooglePlayCoinPurchase, { productId: 'greengo_coins_100', purchaseToken: 'tok1', verificationData: 'tok1' }, 'u1');
    const before = await coins('u1');
    await expect(call(verifyGooglePlayCoinPurchase,
      { productId: 'greengo_coins_100', purchaseToken: 'random-123', verificationData: 'tok1' }, 'u1'))
      .rejects.toBeTruthy();
    expect(await coins('u1')).toBe(before);
  });
});

// ---------------------------------------------------------------------------
describe('C-04 signup grants', () => {
  const fire = (uid: string, data: any) =>
    v2(applySignupGrants)({
      data: fft.firestore.makeDocumentSnapshot(data, `users/${uid}`),
      params: { userId: uid },
    });

  test('LEGIT: new user gets the 2026 welcome pack once', async () => {
    await newUser('n1', 'n1@example.com');
    await fire('n1', { email: 'n1@example.com' });
    const c = await coins('n1');
    expect(c).toBeGreaterThan(0);
    expect((await db.doc('signup_grants/n1').get()).exists).toBe(true);
  });

  test('ATTACK: clear profile marker + re-create users doc grants nothing more', async () => {
    await newUser('n2', 'n2@example.com');
    await fire('n2', { email: 'n2@example.com' });
    const first = await coins('n2');
    await db.doc('profiles/n2').update({ signupGrantsAppliedAt: admin.firestore.FieldValue.delete() });
    await fire('n2', { email: 'n2@example.com' });
    expect(await coins('n2')).toBe(first);
  });

  test('ATTACK: client-written email cannot claim someone else\'s coupon', async () => {
    await db.doc('coupons/c1').set({
      code: 'VIP', allowedEmail: 'victim@example.com', disabled: false, autoGrantOnSignup: true,
      grants: [{ kind: 'coins', coinAmount: 5000 }],
    });
    await newUser('m1', 'mallory@example.com');
    await fire('m1', { email: 'victim@example.com' });
    expect((await db.doc('coupons/c1/redemptions/m1').get()).exists).toBe(false);
  });

  test('ATTACK: old account (pre-marker) gets no welcome pack', async () => {
    await newUser('old1', 'old1@example.com', 90);
    await fire('old1', { email: 'old1@example.com' });
    expect(await coins('old1')).toBe(0);
  });
});

// ---------------------------------------------------------------------------
describe('C-05 referral', () => {
  beforeEach(async () => {
    await db.doc('referral_codes/ABC123').set({ ownerId: 'ref1' });
  });

  test('LEGIT: new user redeems a code once', async () => {
    await newUser('r1', 'r1@example.com');
    const r = await call(redeemReferral, { code: 'abc123' }, 'r1');
    expect(r.ok).toBe(true);
    expect((await db.doc('referral_redemptions/r1').get()).exists).toBe(true);
  });

  test('ATTACK: deleting redeemedCode does not allow a second redemption', async () => {
    await newUser('r2', 'r2@example.com');
    await call(redeemReferral, { code: 'ABC123' }, 'r2');
    await db.doc('referrals/r2').update({ redeemedCode: admin.firestore.FieldValue.delete() });
    await expect(call(redeemReferral, { code: 'ABC123' }, 'r2')).rejects.toMatchObject({ code: 'already-exists' });
  });

  test('ATTACK: old account cannot redeem', async () => {
    await newUser('r3', 'r3@example.com', 90);
    await expect(call(redeemReferral, { code: 'ABC123' }, 'r3')).rejects.toBeTruthy();
  });
});

// ---------------------------------------------------------------------------
describe('C-09 / H-08 admin-only email and push tools', () => {
  test('ATTACK: normal user cannot rewrite templates / send / read logs', async () => {
    for (const [fn, data] of [
      [updateBrevoEmailTemplate, { trigger: 'welcome', htmlContent: '<a href=evil>' }],
      [sendBrevoEmailFunction, { userId: 'x', overrideEmail: 'v@example.com', templateId: 1 }],
      [getBrevoEmailLogs, {}],
    ] as const) {
      await expect(call(fn, data, 'mallory')).rejects.toMatchObject({ code: 'permission-denied' });
    }
  });

  test('LEGIT: admin panel user passes the admin gate', async () => {
    await db.doc('admin_users/boss').set({ role: 'superAdmin' });
    await call(getBrevoEmailLogs, {}, 'boss').catch((e: any) => {
      expect(e.code).not.toBe('permission-denied');
    });
  });

  test('ATTACK: normal user cannot push to another user over the network', async () => {
    await expect(v1(sendPushNotification, { userId: 'victim', title: 't', body: 'b' },
      { auth: { uid: 'mallory' }, rawRequest: {} })).rejects.toMatchObject({ code: 'permission-denied' });
  });

  test('LEGIT: server-internal bundled push path still works', async () => {
    await db.doc('users/u9').set({ fcmToken: null });
    const r = await v1(sendPushNotification, { userId: 'u9', title: 't', body: 'b' }, { auth: { uid: 'u9' } });
    expect(r).toMatchObject({ success: false, reason: 'No FCM token' });
  });
});

// ---------------------------------------------------------------------------
describe('M-09 / H-28 signup helpers', () => {
  test('LEGIT: welcome email to own address is sent', async () => {
    await db.doc('app_config/resend_settings').set({ apiKey: 're_test' });
    const r = await v1(sendWelcomeEmail, { email: 'Me@Example.com' }, { auth: { uid: 'me', token: { email: 'me@example.com' } } });
    expect(r.emailSent).toBe(true);
  });

  test('ATTACK: welcome email to someone else / without login is not sent', async () => {
    await db.doc('app_config/resend_settings').set({ apiKey: 're_test' });
    const a = await v1(sendWelcomeEmail, { email: 'victim@example.com' }, { auth: { uid: 'm', token: { email: 'm@example.com' } } });
    const b = await v1(sendWelcomeEmail, { email: 'victim@example.com' }, {});
    expect(a.emailSent).toBe(false);
    expect(b.emailSent).toBe(false);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  test('ATTACK: cannot delete an account that is mid-onboarding', async () => {
    await newUser('fresh', 'fresh@example.com');
    const r = await v1(cleanupOrphanedAuthUser, { email: 'fresh@example.com' }, {});
    expect(r.cleaned).toBe(false);
    await expect(auth.getUser('fresh')).resolves.toBeTruthy();
  });

  test('ATTACK: same answer for active account and unknown email (no enumeration)', async () => {
    await newUser('act', 'act@example.com', 5);
    await db.doc('profiles/act').set({ name: 'x' });
    const a = await v1(cleanupOrphanedAuthUser, { email: 'act@example.com' }, {});
    const b = await v1(cleanupOrphanedAuthUser, { email: 'nobody@example.com' }, {});
    expect(a).toEqual(b);
  });

  test('LEGIT: a genuine old orphan is still cleaned so the user can re-register', async () => {
    await newUser('orph', 'orph@example.com', 2);
    const r = await v1(cleanupOrphanedAuthUser, { email: 'orph@example.com' }, {});
    expect(r.cleaned).toBe(true);
  });
});

// ---------------------------------------------------------------------------
describe('H-07 admin panel', () => {
  test('ATTACK: support-role admin cannot change passwords', async () => {
    await db.doc('admin_users/sup').set({ role: 'support' });
    await newUser('victim', 'victim@example.com');
    await expect(v1(adminChangeUserPassword, { userId: 'victim', newPassword: 'NewPass123!' },
      { auth: { uid: 'sup' } })).rejects.toMatchObject({ code: 'permission-denied' });
  });

  test('LEGIT: superAdmin can change a user password', async () => {
    await db.doc('admin_users/boss').set({ role: 'superAdmin' });
    await newUser('u5', 'u5@example.com');
    const r = await v1(adminChangeUserPassword, { userId: 'u5', newPassword: 'NewPass123!' }, { auth: { uid: 'boss' } });
    expect(r.success).toBe(true);
  });

  test('ATTACK: reset link is never returned to the caller', async () => {
    await db.doc('admin_users/boss').set({ role: 'superAdmin' });
    await db.doc('app_config/resend_settings').set({ apiKey: 're_test' });
    await newUser('u6', 'u6@example.com');
    const r = await v1(sendPasswordResetEmail, { email: 'u6@example.com' }, { auth: { uid: 'boss' } });
    expect(r.link).toBeUndefined();
    expect(fetchMock).toHaveBeenCalled(); // the email is actually sent now
  });
});

// ---------------------------------------------------------------------------
describe('H-09 Play RTDN endpoint', () => {
  test('ATTACK: unauthenticated push is rejected', async () => {
    const res: any = { statusCode: 0, status(c: number) { this.statusCode = c; return this; }, send() { return this; } };
    const req: any = { body: { message: { data: Buffer.from('{}').toString('base64') } }, get: () => undefined, headers: {} };
    await (playStoreNotifications as any)(req, res);
    expect(res.statusCode).toBe(401);
  });
});
