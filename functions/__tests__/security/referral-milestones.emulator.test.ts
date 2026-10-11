/**
 * Invite-friends programme (redeemReferral + referral_stats + backfill).
 *
 * Runs against the real Firestore + Auth emulators (transactions and rules are
 * real):
 *   firebase emulators:exec --only firestore,auth --project test-project \
 *     "npx jest --config jest.security.config.js referral-milestones"
 *
 * Owner rules under test:
 *  - invited user: 1 week of BASE (not Platinum);
 *  - inviter: +50 coins per invitation, max 1,000/month, and EVERY invitation
 *    counts toward milestones even when coins are capped;
 *  - milestones 5 -> Silver, 10 -> Gold, 20 -> Platinum (1 month), each once,
 *    including concurrent redemptions;
 *  - anti-abuse guards unchanged; referral_stats is server-only, owner-readable.
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const fft = functionsTest({ projectId: PROJECT });
const db = admin.firestore();
const auth = admin.auth();

const fetchMock = jest.fn(async () => ({ ok: true, status: 200, text: async () => '{}', json: async () => ({}) }));

// eslint-disable-next-line @typescript-eslint/no-var-requires
const mod = () => require('../../src/referral/redeemReferral');
const backfill = () => require('../../src/referral/referralBackfill');

const DAY = 86400000;
const OWNER = 'owner0000000000000000000001';
const CODE = 'GGA234';

function emulatorDelete(path: string) {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  return new Promise<void>((resolve, reject) => {
    const req = http.request(
      { host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE', path },
      (res) => { res.resume(); res.on('end', resolve); });
    req.on('error', reject);
    req.end();
  });
}

async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host || !/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) {
    throw new Error('Refusing to run: FIRESTORE_EMULATOR_HOST is not a local emulator');
  }
  await emulatorDelete(`/emulator/v1/projects/${PROJECT}/databases/(default)/documents`);
  const users = await auth.listUsers(1000);
  if (users.users.length) await auth.deleteUsers(users.users.map((u) => u.uid));
}

/** An app user: Auth account (createdDaysAgo old) + profiles + users docs. */
async function appUser(uid: string, createdDaysAgo = 0, profile: Record<string, any> = {}) {
  const email = `${uid.toLowerCase()}@example.com`;
  if (createdDaysAgo === 0) {
    await auth.createUser({ uid, email, password: 'Passw0rd!x' });
  } else {
    const created = new Date(Date.now() - createdDaysAgo * DAY).toUTCString();
    const r = await auth.importUsers([{ uid, email, metadata: { creationTime: created, lastSignInTime: created } }]);
    if (r.failureCount) throw new Error(JSON.stringify(r.errors));
  }
  await db.doc(`profiles/${uid}`).set({ userId: uid, displayName: uid, membershipTier: 'FREE', ...profile });
  await db.doc(`users/${uid}`).set({ subscriptionTier: 'free' });
}

const redeem = (uid: string, code = CODE) =>
  (fft.wrap(mod().redeemReferral) as any)({ data: { code }, auth: { uid, token: {} } });

const coins = async (uid: string) => ((await db.doc(`coinBalances/${uid}`).get()).data()?.totalCoins ?? 0);
const stats = async (uid = OWNER) => (await db.doc(`referral_stats/${uid}`).get()).data();
const profile = async (uid: string) => (await db.doc(`profiles/${uid}`).get()).data()!;
const notifs = async (uid: string, type: string) =>
  (await db.collection('notifications').where('userId', '==', uid).where('type', '==', type).get()).docs.map((d) => d.data());
const period = () => {
  const n = new Date();
  return `${n.getUTCFullYear()}${String(n.getUTCMonth() + 1).padStart(2, '0')}`;
};
const daysFromNow = (ts: admin.firestore.Timestamp) => (ts.toMillis() - Date.now()) / DAY;

/** Seeds `n` past redemptions for OWNER directly (as earlier versions wrote them). */
async function seedRedemptions(owner: string, n: number, prefix = 'old') {
  const batch = db.batch();
  for (let i = 0; i < n; i++) {
    batch.set(db.doc(`referral_redemptions/${prefix}${owner.slice(0, 6)}${i}`), {
      code: CODE, ownerId: owner, redeemedAt: admin.firestore.Timestamp.now(),
    });
  }
  await batch.commit();
}

let originalFetch: any;
beforeAll(() => {
  originalFetch = (global as any).fetch;
  (global as any).fetch = fetchMock;
});
afterAll(() => {
  (global as any).fetch = originalFetch;
  fft.cleanup();
});

beforeEach(async () => {
  await clearAll();
  await appUser(OWNER, 200);
  await db.doc(`referral_codes/${CODE}`).set({ ownerId: OWNER });
  await db.doc(`referrals/${OWNER}`).set({ code: CODE, invitedCount: 0, coinsEarned: 0 });
});

// ---------------------------------------------------------------------------
describe('rewards', () => {
  test('LEGIT: invitee gets 7 days of BASE (not Platinum); inviter +50 coins; both notified', async () => {
    await appUser('inv1');
    const r = await redeem('inv1');
    expect(r).toEqual({ ok: true, referrerCredited: true, membershipGranted: true });

    const p = await profile('inv1');
    expect(p.hasBaseMembership).toBe(true);
    expect(p.baseMembershipSource).toBe('referral');
    expect(daysFromNow(p.baseMembershipEndDate)).toBeGreaterThan(6.9);
    expect(daysFromNow(p.baseMembershipEndDate)).toBeLessThan(7.1);
    expect(p.membershipTier).toBe('FREE'); // no paid tier for the invitee
    expect(p.membershipEndDate).toBeUndefined();

    expect(await coins(OWNER)).toBe(50);
    expect(await stats()).toMatchObject({ invitedCount: 1, coinsEarned: 50, milestonesGranted: [] });
    expect((await db.doc(`referrals/${OWNER}`).get()).data()).toMatchObject({ invitedCount: 1, coinsEarned: 50 });
    expect((await db.doc('referral_redemptions/inv1').get()).data()).toMatchObject({ ownerId: OWNER, coinsAwarded: 50, inviteNumber: 1 });

    const welcome = await notifs('inv1', 'referral_welcome');
    expect(welcome).toHaveLength(1);
    expect(welcome[0]).toMatchObject({ titleKey: 'srvReferralWelcomeTitle', bodyKey: 'srvReferralWelcomeBody' });
    const reward = await notifs(OWNER, 'referral_reward');
    expect(reward).toHaveLength(1);
    expect(reward[0]).toMatchObject({ bodyKey: 'srvReferralCoinsBody', params: { amount: 50 } });
  });

  test('CAP: at 1,000 coins this month no coins are paid, but the invitation still counts', async () => {
    await db.doc(`referralMonthlyGrants/${OWNER}_${period()}`).set({ ownerId: OWNER, period: period(), coins: 1000 });
    await db.doc(`referral_stats/${OWNER}`).set({ invitedCount: 4, coinsEarned: 1000, milestonesGranted: [] });
    await appUser('inv1');
    const r = await redeem('inv1');
    expect(r.referrerCredited).toBe(false);
    expect(await coins(OWNER)).toBe(0);
    // Old bug: invitedCount only moved when coins were paid. Now 4 -> 5 and
    // the Silver milestone is granted although coins are capped.
    expect(await stats()).toMatchObject({ invitedCount: 5, coinsEarned: 1000, milestonesGranted: [5] });
    expect((await profile(OWNER)).membershipTier).toBe('SILVER');
    expect((await notifs(OWNER, 'referral_reward'))[0]).toMatchObject({ bodyKey: 'srvReferralCapReachedBody', params: { cap: 1000 } });
    expect((await db.doc(`referralMonthlyGrants/${OWNER}_${period()}`).get()).data()?.coins).toBe(1000);
  });

  test('CAP: an invitation that would exceed 1,000 this month pays nothing (never partial)', async () => {
    await db.doc(`referralMonthlyGrants/${OWNER}_${period()}`).set({ ownerId: OWNER, period: period(), coins: 950 });
    await appUser('inv1');
    await appUser('inv2');
    await redeem('inv1');
    await redeem('inv2');
    expect(await coins(OWNER)).toBe(50);
    expect(await stats()).toMatchObject({ invitedCount: 2, coinsEarned: 50 });
  });
});

// ---------------------------------------------------------------------------
describe('milestones', () => {
  test('5 -> Silver, 10 -> Gold, 20 -> Platinum, each exactly once', async () => {
    const tierAt: Record<number, string> = {};
    for (let i = 1; i <= 21; i++) {
      await appUser(`m${i}`);
      await redeem(`m${i}`);
      if ([4, 5, 9, 10, 19, 20, 21].includes(i)) tierAt[i] = (await profile(OWNER)).membershipTier;
    }
    expect(tierAt).toEqual({ 4: 'FREE', 5: 'SILVER', 9: 'SILVER', 10: 'GOLD', 19: 'GOLD', 20: 'PLATINUM', 21: 'PLATINUM' });
    const s = await stats();
    expect(s).toMatchObject({ invitedCount: 21, milestonesGranted: [5, 10, 20] });
    // 20 paid invitations hit the 1,000 cap; the 21st counted without coins.
    expect(s!.coinsEarned).toBe(1000);
    expect(await coins(OWNER)).toBe(1000);
    const ms = await notifs(OWNER, 'referral_milestone');
    expect(ms.map((n) => n.params.count).sort((a: number, b: number) => a - b)).toEqual([5, 10, 20]);
    // Stacked: 30 days Silver, then Gold and Platinum each pushed 30 days further.
    const end = daysFromNow((await profile(OWNER)).membershipEndDate);
    expect(end).toBeGreaterThan(89);
    expect(end).toBeLessThan(91);
  }, 120000);

  test('CONCURRENT: two invitations arriving at count 4 grant Silver exactly once', async () => {
    await db.doc(`referral_stats/${OWNER}`).set({ invitedCount: 4, coinsEarned: 200, milestonesGranted: [] });
    await appUser('c1');
    await appUser('c2');
    await Promise.all([redeem('c1'), redeem('c2')]);
    expect(await stats()).toMatchObject({ invitedCount: 6, coinsEarned: 300, milestonesGranted: [5] });
    expect(await notifs(OWNER, 'referral_milestone')).toHaveLength(1);
    const p = await profile(OWNER);
    expect(p.membershipTier).toBe('SILVER');
    // Granted once: ~30 days, not 60.
    expect(daysFromNow(p.membershipEndDate)).toBeLessThan(31);
  });

  test('CONCURRENT: six invitations racing from count 3 count all six and grant Silver once', async () => {
    await db.doc(`referral_stats/${OWNER}`).set({ invitedCount: 3, coinsEarned: 0, milestonesGranted: [] });
    const ids = ['r1', 'r2', 'r3', 'r4', 'r5', 'r6'];
    for (const id of ids) await appUser(id);
    await Promise.all(ids.map((id) => redeem(id)));
    expect(await stats()).toMatchObject({ invitedCount: 9, milestonesGranted: [5] });
    expect(await notifs(OWNER, 'referral_milestone')).toHaveLength(1);
    expect(daysFromNow((await profile(OWNER)).membershipEndDate)).toBeLessThan(31);
    const nums = (await db.collection('referral_redemptions').where('ownerId', '==', OWNER).get()).docs
      .map((d) => d.data().inviteNumber).sort((a, b) => a - b);
    expect(nums).toEqual([4, 5, 6, 7, 8, 9]);
  });

  test('STACKING: an active higher tier is never downgraded; time is added', async () => {
    const end = admin.firestore.Timestamp.fromMillis(Date.now() + 10 * DAY);
    await db.doc(`profiles/${OWNER}`).update({ membershipTier: 'PLATINUM', membershipEndDate: end });
    await db.doc(`referral_stats/${OWNER}`).set({ invitedCount: 4, coinsEarned: 0, milestonesGranted: [] });
    await appUser('s1');
    await redeem('s1');
    const p = await profile(OWNER);
    expect(p.membershipTier).toBe('PLATINUM');
    expect(daysFromNow(p.membershipEndDate)).toBeGreaterThan(39.9);
  });
});

// ---------------------------------------------------------------------------
describe('anti-abuse (unchanged guards)', () => {
  test('ATTACK: self-referral is rejected and counts nothing', async () => {
    const young = 'selfuser00000000000000000001';
    await appUser(young);
    await db.doc('referral_codes/SELF23').set({ ownerId: young });
    await expect(redeem(young, 'SELF23')).rejects.toMatchObject({ code: 'failed-precondition' });
    expect(await stats(young)).toBeUndefined();
  });

  test('ATTACK: a second code (even after deleting the client mirror) is rejected', async () => {
    await appUser('inv1');
    await db.doc('referral_codes/OTHER2').set({ ownerId: 'otherowner' });
    await redeem('inv1');
    await expect(redeem('inv1', 'OTHER2')).rejects.toMatchObject({ code: 'already-exists' });
    await db.doc('referrals/inv1').update({ redeemedCode: admin.firestore.FieldValue.delete() });
    await expect(redeem('inv1')).rejects.toMatchObject({ code: 'already-exists' });
    expect(await stats()).toMatchObject({ invitedCount: 1 });
    expect(await stats('otherowner')).toBeUndefined();
    expect((await profile('inv1')).baseMembershipEndDate.toMillis()).toBeLessThan(Date.now() + 7.1 * DAY);
  });

  test('ATTACK: an old account cannot redeem', async () => {
    await appUser('old1', 90);
    await expect(redeem('old1')).rejects.toMatchObject({ code: 'failed-precondition' });
    expect(await stats()).toBeUndefined();
    expect((await profile('old1')).hasBaseMembership).toBeUndefined();
  });

  test('ATTACK: unknown code / unauthenticated', async () => {
    await appUser('inv1');
    await expect(redeem('inv1', 'NOPE99')).rejects.toMatchObject({ code: 'not-found' });
    await expect((fft.wrap(mod().redeemReferral) as any)({ data: { code: CODE } }))
      .rejects.toMatchObject({ code: 'unauthenticated' });
  });
});

// ---------------------------------------------------------------------------
describe('referral_stats rules (real client requests)', () => {
  function idToken(uid: string): string {
    const b = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
    const now = Math.floor(Date.now() / 1000);
    return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, firebase: { sign_in_provider: 'password' } })}.`;
  }
  const host = () => process.env.FIRESTORE_EMULATOR_HOST!.replace(/^(localhost|0.0.0.0):/, "127.0.0.1:");
  const base = () => `http://${host()}/v1/projects/${PROJECT}/databases/(default)/documents`;
  const doFetch = (...a: any[]) => (originalFetch as any)(...a);
  async function read(uid: string, path: string) {
    const res = await doFetch(`${base()}/${path}`, { headers: { Authorization: `Bearer ${idToken(uid)}` } });
    await res.text();
    return res.status;
  }
  async function write(uid: string, path: string, fields: Record<string, any>) {
    const res = await doFetch(`${base()}/${path}`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ fields }),
    });
    await res.text();
    return res.status;
  }

  beforeEach(async () => {
    await db.doc(`referral_stats/${OWNER}`).set({ invitedCount: 3, coinsEarned: 150, milestonesGranted: [] });
  });

  test('LEGIT: owner reads their own stats', async () => {
    expect(await read(OWNER, `referral_stats/${OWNER}`)).toBe(200);
  });
  test('ATTACK: another user cannot read them', async () => {
    expect(await read('stranger', `referral_stats/${OWNER}`)).toBe(403);
  });
  test('ATTACK: owner cannot raise their own count (update) or create a fresh doc', async () => {
    expect(await write(OWNER, `referral_stats/${OWNER}`, { invitedCount: { integerValue: '20' } })).toBe(403);
    expect(await write('fresh', 'referral_stats/fresh', { invitedCount: { integerValue: '20' } })).toBe(403);
    expect((await stats())!.invitedCount).toBe(3);
  });
});

// ---------------------------------------------------------------------------
describe('backfill (scripts/backfill-referral-stats.ts)', () => {
  const B = 'ownerB00000000000000000000002';

  beforeEach(async () => {
    await appUser(B, 200);
    await seedRedemptions(OWNER, 12, 'a');
    await seedRedemptions(B, 3, 'b');
  });

  test('DRY RUN reports what it would grant and writes nothing', async () => {
    const r = await backfill().runReferralStatsBackfill({ apply: false });
    expect(r.redemptionsScanned).toBe(15);
    expect(r.owners).toBe(2);
    const a = r.plans.find((p: any) => p.ownerId === OWNER);
    expect(a.invitedCount).toBe(12);
    expect(a.toGrant.map((g: any) => [g.count, g.predictedTier])).toEqual([[5, 'SILVER'], [10, 'GOLD']]);
    expect(r.plans.find((p: any) => p.ownerId === B).toGrant).toEqual([]);
    expect(r.grants).toEqual({ 5: 1, 10: 1, 20: 0 });
    expect(await stats()).toBeUndefined();
    expect(await stats(B)).toBeUndefined();
    expect((await profile(OWNER)).membershipTier).toBe('FREE');
  });

  test('APPLY grants reached milestones once, initialises counts; a re-run grants nothing', async () => {
    const r1 = await backfill().runReferralStatsBackfill({ apply: true });
    expect(r1.grants).toEqual({ 5: 1, 10: 1, 20: 0 });
    expect(r1.failures).toEqual([]);
    expect(await stats()).toMatchObject({ invitedCount: 12, milestonesGranted: [5, 10] });
    expect(await stats(B)).toMatchObject({ invitedCount: 3, milestonesGranted: [] });
    expect((await profile(OWNER)).membershipTier).toBe('GOLD');
    expect(await notifs(OWNER, 'referral_milestone')).toHaveLength(2);

    const r2 = await backfill().runReferralStatsBackfill({ apply: true });
    expect(r2.grants).toEqual({ 5: 0, 10: 0, 20: 0 });
    expect(await notifs(OWNER, 'referral_milestone')).toHaveLength(2);

    // Live redemptions continue from the backfilled count.
    for (let i = 0; i < 8; i++) { await appUser(`post${i}`); await redeem(`post${i}`); }
    expect(await stats()).toMatchObject({ invitedCount: 20, milestonesGranted: [5, 10, 20] });
    expect((await profile(OWNER)).membershipTier).toBe('PLATINUM');
  }, 120000);

  test('the dry-run guard blocks every Firestore write path', async () => {
    const fsNs: any = admin.firestore;
    const protos: [any, string[]][] = [
      [fsNs.DocumentReference.prototype, ['set', 'update', 'create', 'delete']],
      [fsNs.CollectionReference.prototype, ['add']],
      [fsNs.WriteBatch.prototype, ['commit', 'set', 'update', 'create', 'delete']],
      [fsNs.Transaction.prototype, ['set', 'update', 'create', 'delete']],
      [fsNs.Firestore.prototype, ['runTransaction', 'bulkWriter', 'recursiveDelete', 'batch']],
    ];
    const saved = protos.map(([p, ns]) => ns.map((n) => [p, n, p[n]] as const)).flat();
    try {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      require('../../scripts/backfill-referral-stats').installReadOnlyGuard();
      expect(() => db.doc('x/y').set({ a: 1 })).toThrow(/READ-ONLY/);
      expect(() => db.collection('x').add({ a: 1 })).toThrow(/READ-ONLY/);
      expect(() => db.batch()).toThrow(/READ-ONLY/);
      expect(() => db.runTransaction(async () => 1)).toThrow(/READ-ONLY/);
      // Reads still work, and the whole dry run completes under the guard.
      const r = await backfill().runReferralStatsBackfill({ apply: false });
      expect(r.grants).toEqual({ 5: 1, 10: 1, 20: 0 });
    } finally {
      for (const [p, n, f] of saved) p[n] = f;
    }
    expect(await stats()).toBeUndefined();
  });
});
