/**
 * Phase 1 (Wave 1) server hardening: emulator integration tests.
 *
 * ATTACK tests reproduce an audit finding and must be REFUSED; LEGIT tests are
 * normal app / admin-panel flows that must keep WORKING. Real Firestore + Auth
 * emulators, no database mocks. Only outbound HTTP (Anthropic) and the Speech
 * client are mocked.
 *
 *   firebase emulators:exec --only firestore,auth --project test-project \
 *     "npx jest --config jest.security.config.js"
 *
 * Modules that only exist after the fix are loaded with `maybe()` so this file
 * also runs against pre-fix code (where those tests must fail).
 */

jest.mock('@google-cloud/speech', () => ({
  SpeechClient: jest.fn().mockImplementation(() => ({
    recognize: jest.fn(async () => [{ results: [] }]),
    longRunningRecognize: jest.fn(),
  })),
}));

import * as admin from 'firebase-admin';
import functionsTest from 'firebase-functions-test';

const fft = functionsTest({ projectId: process.env.GCLOUD_PROJECT });

import { getAgeVerificationDetails, reviewAgeVerification } from '../../src/safety/ageAssurance';
import { grantEntitlement } from '../../src/admin/grantEntitlement';
import { getPendingUsers } from '../../src/admin/mvp_access';
import { backfillProfileGeohash } from '../../src/discovery/profileGeohash';
import { adminDeleteUser, processAISupportMessage } from '../../src/admin/adminPanelFunctions';
import { grantXP, trackChallengeProgress } from '../../src/gamification/gamificationManager';
import { transcribeAudio, batchTranscribe } from '../../src/media/voiceTranscription';
import { submitSharedTranslations } from '../../src/messaging/submitSharedTranslations';
import { sharedTranslationId } from '../../src/messaging/sharedTranslations';
import { runMembershipTierMigrationNow } from '../../src/subscription/membershipMigration';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const maybe = (p: string): any => { try { return require(p); } catch { return {}; } };
const adminClaims = maybe('../../src/admin/adminClaims');
const adminToken = maybe('../../src/shared/adminToken');
const redactMod = maybe('../../src/shared/redact');

const db = admin.firestore();
const auth = admin.auth();

const fetchMock = jest.fn(async (..._args: any[]) => ({
  ok: true, status: 200,
  json: async () => ({ content: [{ text: 'Hello from the assistant' }] }),
  text: async () => '{}',
}));
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

/** Auth user created `createdDaysAgo` days ago (import keeps the metadata). */
async function authUser(uid: string, opts: { createdDaysAgo?: number; emailVerified?: boolean } = {}) {
  const created = new Date(Date.now() - (opts.createdDaysAgo ?? 0) * 86400000).toUTCString();
  const r = await auth.importUsers([{
    uid, email: `${uid}@example.com`, emailVerified: opts.emailVerified ?? false,
    metadata: { creationTime: created, lastSignInTime: created },
  }]);
  if (r.failureCount) throw new Error(JSON.stringify(r.errors));
}

const v2 = (fn: any) => fft.wrap(fn) as any;
const call = (fn: any, data: any, uid?: string, token: Record<string, any> = {}) =>
  v2(fn)({ data, auth: uid ? { uid, token } : undefined });
/** v1 callable invoked as a NETWORK call (rawRequest present). */
const v1 = (fn: any, data: any, uid?: string, token: Record<string, any> = {}) =>
  (fft.wrap(fn) as any)(data, { auth: uid ? { uid, token } : undefined, rawRequest: {} });

const denied = { code: 'permission-denied' };

beforeEach(async () => {
  await clearAll();
  fetchMock.mockClear();
});
afterAll(() => fft.cleanup());

// ---------------------------------------------------------------------------
describe('P1-6 central admin authorization', () => {
  test('ATTACK: moderator (even with users.isAdmin) cannot view ID documents', async () => {
    await db.doc('admin_users/mod').set({ role: 'moderator' });
    await db.doc('users/mod').set({ isAdmin: true });
    await expect(call(getAgeVerificationDetails, { userId: 'victim' }, 'mod')).rejects.toMatchObject(denied);
  });

  test('ATTACK: users.isAdmin / profiles.isAdmin / users.role without an admin_users doc are denied', async () => {
    await db.doc('users/fake').set({ isAdmin: true, role: 'admin' });
    await db.doc('profiles/fake').set({ isAdmin: true });
    await db.doc('admins/fake').set({ permissions: ['deleteUsers'] });
    await expect(call(getAgeVerificationDetails, { userId: 'victim' }, 'fake')).rejects.toMatchObject(denied);
    await expect(call(grantEntitlement, { userIds: ['fake'], grants: [{ kind: 'coins', coinAmount: 1 }] }, 'fake'))
      .rejects.toMatchObject(denied);
    await expect(call(getPendingUsers, {}, 'fake')).rejects.toMatchObject(denied);
    await expect(call(backfillProfileGeohash, {}, 'fake')).rejects.toMatchObject(denied);
  });

  test('ATTACK: a forged/stale superAdmin claim without the admin_users doc cannot view ID documents', async () => {
    await expect(call(getAgeVerificationDetails, { userId: 'victim' }, 'ghost', { adminRole: 'superAdmin' }))
      .rejects.toMatchObject(denied);
  });

  test('ATTACK: deactivated admin is denied', async () => {
    await db.doc('admin_users/old').set({ role: 'superAdmin', isActive: false });
    await expect(call(getAgeVerificationDetails, { userId: 'victim' }, 'old')).rejects.toMatchObject(denied);
  });

  test('ATTACK: support-role admin cannot delete users', async () => {
    await db.doc('admin_users/sup').set({ role: 'support' });
    await authUser('victim');
    await expect(v1(adminDeleteUser, { userId: 'victim' }, 'sup')).rejects.toMatchObject(denied);
    await expect(auth.getUser('victim')).resolves.toBeTruthy();
  });

  test('LEGIT: superAdmin (admin_users doc only) can view ID documents and list pending users', async () => {
    await db.doc('admin_users/boss').set({ role: 'superAdmin' });
    await authUser('victim');
    const r = await call(getAgeVerificationDetails, { userId: 'victim' }, 'boss');
    expect(r.userId).toBe('victim');
    const p = await call(getPendingUsers, {}, 'boss');
    expect(p).toBeTruthy();
  });

  test('LEGIT: moderator may take moderation decisions', async () => {
    await db.doc('admin_users/mod').set({ role: 'moderator' });
    await call(reviewAgeVerification, { userId: 'nobody', approve: false, reason: 'x' }, 'mod')
      .catch((e: any) => expect(e.code).not.toBe('permission-denied'));
  });

  test('LEGIT: adminRole claim is synced from admin_users and removed with it', async () => {
    expect(typeof adminClaims.syncAdminClaims).toBe('function');
    await authUser('staff');
    await db.doc('admin_users/staff').set({ role: 'moderator' });
    await adminClaims.syncAdminClaims('staff');
    expect((await auth.getUser('staff')).customClaims?.adminRole).toBe('moderator');
    await db.doc('admin_users/staff').delete();
    await adminClaims.syncAdminClaims('staff');
    expect((await auth.getUser('staff')).customClaims?.adminRole).toBeUndefined();
  });

  test('ATTACK: only a superAdmin can resync all admin claims', async () => {
    expect(adminClaims.resyncAllAdminClaims).toBeDefined();
    await db.doc('admin_users/mod').set({ role: 'moderator' });
    await expect(call(adminClaims.resyncAllAdminClaims, {}, 'mod')).rejects.toMatchObject(denied);
    await db.doc('admin_users/boss').set({ role: 'superAdmin' });
    await authUser('boss');
    const r = await call(adminClaims.resyncAllAdminClaims, {}, 'boss');
    expect(r.total).toBe(2);
  });
});

// ---------------------------------------------------------------------------
describe('L-04 gamification callables bind to the caller', () => {
  test('ATTACK: grantXP for another uid is denied and writes nothing', async () => {
    await expect(v1(grantXP, { userId: 'victim', xpAmount: 100000, reason: 'x' }, 'mallory'))
      .rejects.toMatchObject(denied);
    expect((await db.doc('user_levels/victim').get()).exists).toBe(false);
  });

  test('ATTACK: path-injection ids are rejected', async () => {
    await expect(v1(trackChallengeProgress, { challengeId: '../users/x', incrementBy: 1 }, 'u1'))
      .rejects.toMatchObject({ code: 'invalid-argument' });
  });

  test('LEGIT: grantXP for yourself (app sends its own userId) still works', async () => {
    const r = await v1(grantXP, { userId: 'u1', xpAmount: 50, reason: 'welcome_bonus' }, 'u1');
    expect(r.totalXP).toBe(50);
    expect((await db.doc('user_levels/u1').get()).data()?.totalXP).toBe(50);
  });
});

// ---------------------------------------------------------------------------
describe('H-14 voice transcription', () => {
  beforeEach(async () => {
    await db.doc('conversations/c1').set({ userId1: 'alice', userId2: 'bob', matchId: 'm1' });
  });

  test('ATTACK: batchTranscribe of a conversation you are not in is denied', async () => {
    await expect(v1(batchTranscribe, { conversationId: 'c1', limit: 5 }, 'mallory')).rejects.toMatchObject(denied);
  });

  test('ATTACK: transcribeAudio of a conversation you are not in is denied', async () => {
    await expect(v1(transcribeAudio, { audioUrl: 'chat_voice/m1/abc.m4a' }, 'mallory')).rejects.toMatchObject(denied);
  });

  test('ATTACK: transcribeAudio of a non-chat bucket path is refused', async () => {
    await expect(v1(transcribeAudio, { audioUrl: 'age_verification/victim/id.jpg' }, 'alice'))
      .rejects.toMatchObject({ code: 'invalid-argument' });
  });

  test('ATTACK: batch limit is capped at 20 and each message must belong to the conversation', async () => {
    const batch = db.batch();
    for (let i = 0; i < 25; i++) {
      batch.set(db.doc(`conversations/c1/messages/v${i}`), {
        type: 'voice_note', content: `age_verification/victim/${i}.jpg`, metadata: { transcription: null },
      });
    }
    await batch.commit();
    const r = await v1(batchTranscribe, { conversationId: 'c1', limit: 1000 }, 'alice');
    expect(r.processed).toBe(20);
    expect(r.results.every((x: any) => x.success === false)).toBe(true);
    const day = new Date().toISOString().slice(0, 10);
    expect((await db.doc(`transcription_quota/alice_${day}`).get()).data()?.count).toBe(20);
  });

  test('LEGIT: a participant can batch-transcribe their own conversation', async () => {
    const r = await v1(batchTranscribe, { conversationId: 'c1' }, 'bob');
    expect(r).toMatchObject({ success: true, processed: 0 });
  });
});

// ---------------------------------------------------------------------------
describe('M-06 shared translation consensus', () => {
  const TEXT = 'The old harbour hosts a fish market every Sunday morning.';
  const IT = 'Il vecchio porto ospita un mercato del pesce ogni domenica mattina.';
  const shared = async () => (await db.doc(`translations/${sharedTranslationId('it', TEXT)}`).get()).exists;
  const vote = (uid: string) => call(submitSharedTranslations, { target: 'it', items: [{ text: TEXT, translation: IT }] }, uid);

  beforeEach(async () => {
    for (const u of ['q1', 'q2', 'q3']) await authUser(u, { createdDaysAgo: 30, emailVerified: true });
    await authUser('fresh', { createdDaysAgo: 0, emailVerified: true });
    await authUser('unverified', { createdDaysAgo: 30, emailVerified: false });
    for (const u of ['q1', 'q2', 'q3', 'fresh', 'unverified']) await db.doc(`users/${u}`).set({ accountStatus: 'active' });
  });

  test('ATTACK: two accounts agreeing is not enough', async () => {
    await vote('q1');
    await vote('q2');
    expect(await shared()).toBe(false);
  });

  test('ATTACK: new or unverified accounts do not count towards consensus', async () => {
    await vote('fresh');
    await vote('unverified');
    await vote('q1');
    expect(await shared()).toBe(false);
  });

  test('LEGIT: three qualified accounts agreeing share the translation (same response shape)', async () => {
    await vote('q1');
    await vote('q2');
    const r = await vote('q3');
    expect(r).toMatchObject({ accepted: 1, shared: 1, rejected: 0, existing: 0 });
    expect(await shared()).toBe(true);
  });
});

// ---------------------------------------------------------------------------
describe('H-04 AI support replies', () => {
  const fire = (id: string, data: any) =>
    (fft.wrap(processAISupportMessage) as any)(
      fft.firestore.makeDocumentSnapshot(data, `support_messages/${id}`), { params: { messageId: id } });

  beforeEach(async () => {
    await db.doc('environment_config/production').set({
      aiAgent: { enabled: true, claudeApiKey: 'sk-test', escalateAfterMessages: 50, includeUserProfile: true },
    });
    await db.doc('support_chats/s1').set({ userId: 'u1' });
    await db.doc('profiles/u1').set({ displayName: 'Maria Rossi', membershipTier: 'gold', email: 'maria@example.com' });
  });

  test('LEGIT: first user message gets one AI reply, with contact details scrubbed', async () => {
    const msg = { conversationId: 's1', senderId: 'u1', senderType: 'user',
      content: 'Mail me at maria@example.com or call +39 333 123 4567, I live at 45.4642, 9.1900' };
    await db.doc('support_messages/a').set(msg);
    await fire('a', msg);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const body = String((fetchMock.mock.calls[0] as any[])[1].body);
    expect(body).not.toContain('maria@example.com');
    expect(body).not.toContain('333 123 4567');
    expect(body).not.toContain('45.4642');
    expect(body).not.toContain('Rossi');
  });

  test('ATTACK: rapid follow-up messages do not each trigger a model call', async () => {
    for (const id of ['a', 'b', 'c']) {
      const msg = { conversationId: 's1', senderId: 'u1', senderType: 'user', content: `hi ${id}` };
      await db.doc(`support_messages/${id}`).set(msg);
      await fire(id, msg);
    }
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  test('ATTACK: daily AI budget is enforced', async () => {
    const day = new Date().toISOString().slice(0, 10);
    await db.doc('ai_support_rate/u1').set({ day, count: 20, lastAtMs: 0 });
    const msg = { conversationId: 's1', senderId: 'u1', senderType: 'user', content: 'hello' };
    await fire('d', msg);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  test('ATTACK: messages not from the chat owner, or not senderType user, are ignored', async () => {
    await fire('x', { conversationId: 's1', senderId: 'mallory', senderType: 'user', content: 'hi' });
    await fire('y', { conversationId: 's1', senderId: 'u1', senderType: 'admin', content: 'hi' });
    expect(fetchMock).not.toHaveBeenCalled();
  });
});

// ---------------------------------------------------------------------------
describe('L-05 admin token in header', () => {
  const res = () => {
    const r: any = { statusCode: 200, body: undefined };
    r.status = (c: number) => { r.statusCode = c; return r; };
    r.json = (b: any) => { r.body = b; return r; };
    r.send = (b: any) => { r.body = b; return r; };
    return r;
  };
  const req = (headers: Record<string, string>, query: Record<string, string> = {}) => ({
    method: 'GET', query, headers, body: {},
    get: (n: string) => headers[n.toLowerCase()],
  });

  beforeAll(() => { process.env.MEMBERSHIP_MIGRATION_TOKEN = 'migration-secret-123'; });
  afterAll(() => { delete process.env.MEMBERSHIP_MIGRATION_TOKEN; });

  test('LEGIT: X-Admin-Token header is accepted', async () => {
    const r = res();
    await (runMembershipTierMigrationNow as any)(req({ 'x-admin-token': 'migration-secret-123' }), r);
    expect(r.statusCode).toBe(200);
  });

  test('LEGIT: Authorization Bearer header is accepted', async () => {
    const r = res();
    await (runMembershipTierMigrationNow as any)(req({ authorization: 'Bearer migration-secret-123' }), r);
    expect(r.statusCode).toBe(200);
  });

  test('LEGIT: deprecated ?token= still works (existing jobs)', async () => {
    const r = res();
    await (runMembershipTierMigrationNow as any)(req({}, { token: 'migration-secret-123' }), r);
    expect(r.statusCode).toBe(200);
  });

  test('ATTACK: wrong or missing token is refused', async () => {
    for (const rq of [req({ 'x-admin-token': 'nope' }), req({}, { token: 'migration-secret-12' }), req({})]) {
      const r = res();
      await (runMembershipTierMigrationNow as any)(rq, r);
      expect(r.statusCode).toBe(403);
    }
  });

  test('unit: adminTokenOk ignores unset secrets', () => {
    expect(adminToken.adminTokenOk(req({ 'x-admin-token': '' }), [undefined, ''], 't')).toBe(false);
    expect(adminToken.adminTokenOk(req({ 'x-admin-token': 'k' }), [undefined, 'k'], 't')).toBe(true);
  });
});

// ---------------------------------------------------------------------------
describe('L-07 redact', () => {
  test('emails and tokens are masked', () => {
    expect(redactMod.redact('sent to alice@example.com ok')).toBe('sent to a***@example.com ok');
    expect(redactMod.redactToken('SECRETCODE')).toBe('SECR…');
  });
});
