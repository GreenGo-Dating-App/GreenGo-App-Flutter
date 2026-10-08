/**
 * P1-9 reconciliation (app repo = single source of truth): emulator tests.
 *
 * claimReward replaces the live gen1 web-repo copy. It must:
 *  - stay 1st-gen @512MB so it can be deployed IN PLACE over the gen1 function;
 *  - keep the live contract ({ rewardId } -> { success, coinsAdded }) and the
 *    web-only `first_message` reward;
 *  - write the REAL camelCase coinBalances / coinTransactions (never the phantom
 *    snake_case coin_balances);
 *  - check eligibility server-side and dedup transactionally.
 *
 * Plus the reconciled runtime settings: onPresenceUpdate / sendScheduledMessages
 * at 512MB, the sendScheduledMessages composite index, computeDailyUserStats
 * exported from the app repo.
 *
 *   firebase emulators:exec --only firestore,auth --project test-project \
 *     "npx jest --config jest.security.config.js"
 *
 * Modules that only exist after the fix are loaded with `maybe()` so this file
 * also runs against pre-fix code (where these tests must fail).
 */

import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';
import functionsTest from 'firebase-functions-test';

const fft = functionsTest({ projectId: process.env.GCLOUD_PROJECT });

// eslint-disable-next-line @typescript-eslint/no-var-requires
const maybe = (p: string): any => { try { return require(p); } catch { return {}; } };
const coins = maybe('../../src/coins');
const rewardMod = maybe('../../src/coins/claimReward');
const presence = maybe('../../src/presence/onPresenceUpdate');
const scheduled = maybe('../../src/messaging/scheduledMessages');
const gamification = maybe('../../src/gamification');

const db = admin.firestore();
const auth = admin.auth();

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

/** v1 callable invoked as a NETWORK call (rawRequest present). */
const v1 = (fn: any, data: any, uid?: string) =>
  (fft.wrap(fn) as any)(data, { auth: uid ? { uid, token: {} } : undefined, rawRequest: {} });
const claim = (data: any, uid?: string) => v1(coins.claimReward, data, uid);

const COMPLETE_PROFILE = {
  displayName: 'Ana', dateOfBirth: admin.firestore.Timestamp.fromDate(new Date('1995-01-01')),
  gender: 'female', photoUrls: ['https://x/p.jpg'], interests: ['travel'], bio: 'Hello there',
  isComplete: true,
};

async function balance(uid: string) {
  return (await db.doc(`coinBalances/${uid}`).get()).data();
}

beforeEach(async () => { await clearAll(); });
afterAll(() => fft.cleanup());

// ---------------------------------------------------------------------------
describe('P1-9 claimReward: deployable in place over the live gen1 function', () => {
  test('is a 1st-gen callable at 512MB', () => {
    const ep = coins.claimReward?.__endpoint;
    expect(ep?.platform).toBe('gcfv1');
    expect(ep?.availableMemoryMb).toBe(512);
    expect(ep?.callableTrigger).toBeTruthy();
  });

  test('ATTACK: unauthenticated call is refused', async () => {
    await expect(claim({ rewardId: 'daily_login' })).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  test('ATTACK: unknown reward id is refused', async () => {
    await expect(claim({ rewardId: 'free_money' }, 'u1')).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});

describe('P1-9 claimReward: writes the shape the app parses', () => {
  test('LEGIT: complete_profile credits camelCase coinBalances + coinTransactions, live response shape', async () => {
    await db.doc('profiles/u1').set(COMPLETE_PROFILE);
    await db.doc('coinBalances/u1').set({
      userId: 'u1', totalCoins: 20, earnedCoins: 0, purchasedCoins: 20, giftedCoins: 0, spentCoins: 0,
      coinBatches: [{ batchId: 'b0', initialCoins: 20, remainingCoins: 20, source: 'purchase',
        acquiredDate: admin.firestore.Timestamp.now() }],
      lastUpdated: admin.firestore.Timestamp.now(),
    });

    const r = await claim({ rewardId: 'complete_profile' }, 'u1');
    expect(r).toMatchObject({ success: true, coinsAdded: 100, newBalance: 120 });

    const b = await balance('u1');
    expect(b).toMatchObject({ userId: 'u1', totalCoins: 120, earnedCoins: 100, purchasedCoins: 20,
      giftedCoins: 0, spentCoins: 0 });
    expect(b!.lastUpdated).toBeInstanceOf(admin.firestore.Timestamp);
    expect(b!.coinBatches).toHaveLength(2);
    const batch = b!.coinBatches[1];
    expect(batch).toMatchObject({ initialCoins: 100, remainingCoins: 100, source: 'reward' });
    expect(batch.acquiredDate).toBeInstanceOf(admin.firestore.Timestamp);
    expect(batch.expirationDate).toBeUndefined(); // coins never expire

    const txs = await db.collection('coinTransactions').where('userId', '==', 'u1').get();
    expect(txs.size).toBe(1);
    const t = txs.docs[0].data();
    expect(t).toMatchObject({ type: 'credit', amount: 100, balanceAfter: 120, reason: 'completeProfileReward' });
    expect(t.createdAt).toBeInstanceOf(admin.firestore.Timestamp);

    // Never the phantom snake_case collections.
    expect((await db.doc('coin_balances/u1').get()).exists).toBe(false);
    expect((await db.collection('coin_transactions').get()).size).toBe(0);

    // Transactional dedup record + legacy record the app's canClaimReward reads.
    expect((await db.doc('reward_claims/u1_complete_profile_once').get()).data())
      .toMatchObject({ userId: 'u1', rewardId: 'complete_profile', coins: 100 });
    const legacy = await db.collection('claimedRewards').where('userId', '==', 'u1').get();
    expect(legacy.docs.map((d) => d.get('rewardId'))).toEqual(['complete_profile']);
  });

  test('LEGIT: old gen2 input { rewardType } still works', async () => {
    const r = await claim({ rewardType: 'daily_login' }, 'u1');
    expect(r).toMatchObject({ success: true, coinsAdded: 10, coinsEarned: 10, rewardType: 'daily_login' });
    expect((await balance('u1'))!.totalCoins).toBe(10);
  });
});

describe('P1-9 claimReward: server-side eligibility', () => {
  test('ATTACK: complete_profile with an incomplete profile (client isComplete flag set) is refused', async () => {
    await db.doc('profiles/u1').set({ ...COMPLETE_PROFILE, bio: '', isComplete: true });
    await expect(claim({ rewardId: 'complete_profile' }, 'u1')).rejects.toMatchObject({ code: 'failed-precondition' });
    expect(await balance('u1')).toBeUndefined();
  });

  test('ATTACK/LEGIT: first_match needs a match the caller is part of', async () => {
    await expect(claim({ rewardId: 'first_match' }, 'u1')).rejects.toMatchObject({ code: 'failed-precondition' });
    await db.doc('matches/m1').set({ userId1: 'other', userId2: 'u1', isActive: true });
    await expect(claim({ rewardId: 'first_match' }, 'u1')).resolves.toMatchObject({ coinsAdded: 50 });
  });

  test('ATTACK/LEGIT: first_message (web-only reward, ported) needs a sent message', async () => {
    await db.doc('conversations/c1/messages/x').set({ senderId: 'other', text: 'hi' });
    await expect(claim({ rewardId: 'first_message' }, 'u1')).rejects.toMatchObject({ code: 'failed-precondition' });
    await db.doc('conversations/c1/messages/y').set({ senderId: 'u1', text: 'hello' });
    await expect(claim({ rewardId: 'first_message' }, 'u1')).resolves.toMatchObject({ coinsAdded: 25 });
  });

  test('ATTACK: photo_verification is not paid on the client-writable verificationStatus', async () => {
    await db.doc('profiles/u1').set({ ...COMPLETE_PROFILE, verificationStatus: 'approved', isVerified: true });
    await expect(claim({ rewardId: 'photo_verification' }, 'u1')).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  test('LEGIT: photo_verification with a server-written verification badge', async () => {
    await db.doc('verification_badges/u1').set({ userId: 'u1', level: 'photoVerified' });
    await expect(claim({ rewardId: 'photo_verification' }, 'u1')).resolves.toMatchObject({ coinsAdded: 75 });
  });

  test('ATTACK: streak rewards (client-written streak data) and refer_friend (paid by redeemReferral) are refused', async () => {
    await db.doc('login_streaks/u1').set({ currentStreak: 400, longestStreak: 400 });
    for (const rewardId of ['week_streak', 'month_streak', 'refer_friend']) {
      await expect(claim({ rewardId }, 'u1')).rejects.toMatchObject({ code: 'failed-precondition' });
    }
    expect(await balance('u1')).toBeUndefined();
  });
});

describe('P1-9 claimReward: dedup', () => {
  test('ATTACK: a one-time reward cannot be claimed twice', async () => {
    await db.doc('profiles/u1').set(COMPLETE_PROFILE);
    await claim({ rewardId: 'complete_profile' }, 'u1');
    await expect(claim({ rewardId: 'complete_profile' }, 'u1')).rejects.toMatchObject({ code: 'already-exists' });
    expect((await balance('u1'))!.totalCoins).toBe(100);
  });

  test('ATTACK: a reward already claimed on the legacy path (claimedRewards) is not paid again', async () => {
    await db.doc('profiles/u1').set(COMPLETE_PROFILE);
    await db.collection('claimedRewards').add({ userId: 'u1', rewardId: 'complete_profile', coinAmount: 100,
      claimedAt: admin.firestore.Timestamp.now() });
    await expect(claim({ rewardId: 'complete_profile' }, 'u1')).rejects.toMatchObject({ code: 'already-exists' });
  });

  test('ATTACK: 6 concurrent daily_login claims pay exactly once', async () => {
    const results = await Promise.allSettled(Array.from({ length: 6 }, () => claim({ rewardId: 'daily_login' }, 'u1')));
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
    expect((await balance('u1'))!.totalCoins).toBe(10);
    expect((await db.collection('coinTransactions').where('userId', '==', 'u1').get()).size).toBe(1);
  });

  test('LEGIT: daily_login is once per UTC day, again the next day', async () => {
    const day1 = new Date('2026-10-08T23:59:00Z');
    const day2 = new Date('2026-10-09T00:01:00Z');
    await rewardMod.claimRewardForUser('u1', { rewardId: 'daily_login' }, day1);
    await expect(rewardMod.claimRewardForUser('u1', { rewardId: 'daily_login' }, day1))
      .rejects.toMatchObject({ code: 'already-exists' });
    await expect(rewardMod.claimRewardForUser('u1', { rewardId: 'daily_login' }, day2))
      .resolves.toMatchObject({ coinsAdded: 10, newBalance: 20 });
    expect((await db.doc('reward_claims/u1_daily_login_2026-10-09').get()).exists).toBe(true);
  });
});

// ---------------------------------------------------------------------------
describe('P1-9 reconciled runtime settings', () => {
  test('onPresenceUpdate runs at 512MiB (was OOM-killed at 256MiB)', () => {
    expect(presence.onPresenceUpdate?.__endpoint?.availableMemoryMb).toBe(512);
  });

  test('sendScheduledMessages runs at 512MB and its query has a composite index', () => {
    expect(scheduled.sendScheduledMessages?.__endpoint?.availableMemoryMb).toBe(512);
    const idx = JSON.parse(fs.readFileSync(path.join(__dirname, '../../../firestore.indexes.json'), 'utf8'));
    const fields = (i: any) => i.fields.map((f: any) => `${f.fieldPath}:${f.order}`).join(',');
    const found = idx.indexes.some((i: any) => i.collectionGroup === 'messages'
      && i.queryScope === 'COLLECTION_GROUP'
      && fields(i) === 'isScheduled:ASCENDING,status:ASCENDING,scheduledFor:ASCENDING');
    expect(found).toBe(true);
  });

  test('computeDailyUserStats is exported by the app repo (was web-only)', () => {
    expect(gamification.computeDailyUserStats?.__endpoint?.scheduleTrigger).toBeTruthy();
    const index = fs.readFileSync(path.join(__dirname, '../../src/index.ts'), 'utf8');
    expect(index).toMatch(/export \{ computeDailyUserStats \} from '\.\/gamification'/);
  });
});
