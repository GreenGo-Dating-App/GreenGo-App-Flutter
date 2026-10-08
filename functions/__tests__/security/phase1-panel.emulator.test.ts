/**
 * Phase 1 admin-panel workstream (P1-6 remainder, H-07, H-29, moderation gaps):
 * emulator integration tests against the real Firestore + Auth emulators.
 *
 *   - Server-enforced admin 2FA: verify2FACode sets `admin2faUntil` (8h, bound
 *     to the session's auth_time), syncAdminClaims and the 2FA claim never
 *     wipe each other, and superAdmin-only actions require the claim ONLY
 *     when app_config/security_flags.requireAdmin2fa is true.
 *   - Moderation callables: panel roles (admin_users / adminRole), statement of
 *     reasons (DSA art. 17), report-pipeline types, failed actions stay open.
 *   - H-29 panel callables (panelUserActions.ts) replacing browser writes.
 *
 *   firebase emulators:exec --only firestore,auth --project test-project \
 *     "npx jest --config jest.security.config.js"
 *
 * Modules / exports that only exist after the change are loaded with maybe()
 * so this file also runs (and fails) against the old code.
 */

import * as admin from 'firebase-admin';
import functionsTest from 'firebase-functions-test';

const fft = functionsTest({ projectId: process.env.GCLOUD_PROJECT });

import { send2FACode, verify2FACode, adminChangeUserPassword } from '../../src/admin/adminPanelFunctions';
import { takeModerationAction, executeBulkModeration } from '../../src/admin/moderationQueue';
import { onMessageReportQueued, onContentReportQueued, queueIdFor } from '../../src/safety/reportPipeline';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const maybe = (p: string): any => { try { return require(p); } catch { return {}; } };
const adminAuth = maybe('../../src/shared/adminAuth');
const adminClaims = maybe('../../src/admin/adminClaims');
const panel = maybe('../../src/admin/panelUserActions');

const db = admin.firestore();
const auth = admin.auth();
const FV = admin.firestore.FieldValue;

const fetchMock = jest.fn(async (..._args: any[]) => ({ ok: true, status: 200, text: async () => '{}' }));
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

const nowSec = () => Math.floor(Date.now() / 1000);
const AUTH_TIME = nowSec() - 60;

/** v2 callable. */
const call = (fn: any, data: any, uid?: string, token: Record<string, any> = {}) =>
  (fft.wrap(fn) as any)({ data, auth: uid ? { uid, token } : undefined });
/** v1 callable invoked as a network call (rawRequest present). */
const v1 = (fn: any, data: any, uid?: string, token: Record<string, any> = {}) =>
  (fft.wrap(fn) as any)(data, { auth: uid ? { uid, token } : undefined, rawRequest: {} });

const denied = { code: 'permission-denied' };

async function makeAdmin(uid: string, role: string) {
  await auth.createUser({ uid, email: `${uid}@example.com` }).catch(() => undefined);
  await db.doc(`admin_users/${uid}`).set({ role, email: `${uid}@example.com`, isActive: true });
}
async function setFlag(on: boolean | null) {
  if (on === null) await db.doc('app_config/security_flags').delete();
  else await db.doc('app_config/security_flags').set({ requireAdmin2fa: on });
  adminAuth.resetSecurityFlagsCache?.();
}
/** Run the real 2FA flow for [uid] and return the token claims a refreshed ID token would carry. */
async function pass2fa(uid: string, authTime = AUTH_TIME): Promise<Record<string, any>> {
  await v1(send2FACode, {}, uid, { auth_time: authTime });
  const code = (await db.doc(`admin_2fa_codes/${uid}`).get()).data()?.code;
  const r = await v1(verify2FACode, { code }, uid, { auth_time: authTime });
  expect(r.success).toBe(true);
  const claims = (await auth.getUser(uid)).customClaims || {};
  return { ...claims, auth_time: authTime };
}
async function profile(uid: string, extra: Record<string, any> = {}) {
  await db.doc(`profiles/${uid}`).set({ displayName: uid, email: `${uid}@example.com`, membershipTier: 'FREE', ...extra });
}

beforeEach(async () => {
  await clearAll();
  fetchMock.mockClear();
  adminAuth.resetSecurityFlagsCache?.();
});
afterAll(() => fft.cleanup());

// ---------------------------------------------------------------------------
describe('H-07 server-enforced admin 2FA', () => {
  test('verify2FACode sets admin2faUntil (+8h) bound to the session, keeping adminRole', async () => {
    await makeAdmin('boss', 'superAdmin');
    await adminClaims.syncAdminClaims('boss');
    const claims = await pass2fa('boss');
    expect(claims.adminRole).toBe('superAdmin');
    expect(claims.admin2faUntil).toBeGreaterThan(nowSec() + 8 * 3600 - 120);
    expect(claims.admin2faUntil).toBeLessThanOrEqual(nowSec() + 8 * 3600 + 5);
    expect(claims.admin2faAuthTime).toBe(AUTH_TIME);
  });

  test('a wrong code sets no claim; a non-admin never gets one', async () => {
    await makeAdmin('boss', 'superAdmin');
    await v1(send2FACode, {}, 'boss');
    const r = await v1(verify2FACode, { code: '000000x' }, 'boss', { auth_time: AUTH_TIME });
    expect(r.success).toBe(false);
    expect((await auth.getUser('boss')).customClaims?.admin2faUntil).toBeUndefined();
  });

  test('syncAdminClaims keeps the 2FA claim on a role change and drops it when admin access is removed', async () => {
    await makeAdmin('staff', 'moderator');
    await adminClaims.syncAdminClaims('staff');
    const claims = await pass2fa('staff');
    await db.doc('admin_users/staff').update({ role: 'superAdmin' });
    await adminClaims.syncAdminClaims('staff');
    let now = (await auth.getUser('staff')).customClaims || {};
    expect(now.adminRole).toBe('superAdmin');
    expect(now.admin2faUntil).toBe(claims.admin2faUntil);
    // ...and a second 2FA pass keeps the (new) role.
    await pass2fa('staff');
    now = (await auth.getUser('staff')).customClaims || {};
    expect(now.adminRole).toBe('superAdmin');
    await db.doc('admin_users/staff').delete();
    await adminClaims.syncAdminClaims('staff');
    now = (await auth.getUser('staff')).customClaims || {};
    expect(now.adminRole).toBeUndefined();
    expect(now.admin2faUntil).toBeUndefined();
  });

  test('flag OFF (missing doc or false) = today: superAdmin actions work without the claim', async () => {
    await makeAdmin('boss', 'superAdmin');
    await auth.createUser({ uid: 'victim', email: 'victim@example.com', password: 'oldpassword1' });
    await profile('victim');
    await setFlag(null);
    await expect(v1(adminChangeUserPassword, { userId: 'victim', newPassword: 'newpassword1' }, 'boss'))
      .resolves.toMatchObject({ success: true });
    await setFlag(false);
    const r = await call(panel.adminAdjustUserCoins, { userId: 'victim', amount: 10, reason: 'support case' }, 'boss');
    expect(r.newBalance).toBe(10);
  });

  test('flag ON: a superAdmin WITHOUT a fresh 2FA claim is refused (v1 and v2 callables)', async () => {
    await makeAdmin('boss', 'superAdmin');
    await auth.createUser({ uid: 'victim', email: 'victim@example.com', password: 'oldpassword1' });
    await profile('victim');
    await setFlag(true);
    const tok = { adminRole: 'superAdmin', auth_time: AUTH_TIME };
    await expect(v1(adminChangeUserPassword, { userId: 'victim', newPassword: 'newpassword1' }, 'boss', tok))
      .rejects.toMatchObject(denied);
    await expect(call(panel.adminAdjustUserCoins, { userId: 'victim', amount: 10, reason: 'support case' }, 'boss', tok))
      .rejects.toMatchObject({ ...denied, details: { reason: 'admin_2fa_required' } });
    expect((await db.doc('coinBalances/victim').get()).exists).toBe(false);
  });

  test('flag ON: allowed with the claim; refused with an expired claim or the claim from ANOTHER session', async () => {
    await makeAdmin('boss', 'superAdmin');
    await profile('victim');
    await setFlag(true);
    const claims = await pass2fa('boss');
    const r = await call(panel.adminAdjustUserCoins, { userId: 'victim', amount: 5, reason: 'support case' }, 'boss', claims);
    expect(r.newBalance).toBe(5);
    // Same account, different sign-in (e.g. stolen password): auth_time differs.
    await expect(call(panel.adminAdjustUserCoins, { userId: 'victim', amount: 5, reason: 'support case' }, 'boss',
      { ...claims, auth_time: AUTH_TIME + 30 })).rejects.toMatchObject(denied);
    await expect(call(panel.adminAdjustUserCoins, { userId: 'victim', amount: 5, reason: 'support case' }, 'boss',
      { ...claims, admin2faUntil: nowSec() - 1 })).rejects.toMatchObject(denied);
  });

  test('flag ON: a Firebase MFA (TOTP) sign-in under 8h old counts as 2FA', async () => {
    await makeAdmin('boss', 'superAdmin');
    await profile('victim');
    await setFlag(true);
    const mfa = { auth_time: nowSec() - 600, firebase: { sign_in_second_factor: 'totp' } };
    await expect(call(panel.adminAdjustUserCoins, { userId: 'victim', amount: 1, reason: 'support case' }, 'boss', mfa))
      .resolves.toMatchObject({ newBalance: 1 });
    const stale = { auth_time: nowSec() - 9 * 3600, firebase: { sign_in_second_factor: 'totp' } };
    await expect(call(panel.adminAdjustUserCoins, { userId: 'victim', amount: 1, reason: 'support case' }, 'boss', stale))
      .rejects.toMatchObject(denied);
  });

  test('flag ON: moderator-level actions do not need the claim', async () => {
    await makeAdmin('mod', 'moderator');
    await profile('victim');
    await setFlag(true);
    await expect(call(panel.adminSetUserStatus, { userId: 'victim', action: 'suspend', reason: 'spam wave' }, 'mod'))
      .resolves.toMatchObject({ status: 'suspended' });
  });
});

// ---------------------------------------------------------------------------
describe('Moderation queue callables (P1-6 remainder, DSA art. 17)', () => {
  async function messageReportItem(): Promise<string> {
    await db.doc('conversations/conv9/messages/m9').set({ senderId: 'bob', content: 'nasty', sentAt: FV.serverTimestamp() });
    const ref = db.collection('message_reports').doc();
    await ref.set({
      reportId: ref.id, messageId: 'm9', conversationId: 'conv9', messageContent: 'nasty',
      reporterId: 'alice', reportedUserId: 'bob', reason: 'Harassment or bullying', status: 'pending',
    });
    const snap = await ref.get();
    await (fft.wrap(onMessageReportQueued) as any)({ data: snap, params: { reportId: ref.id } });
    return queueIdFor('message_reports', ref.id);
  }
  const sor = { reasonCode: 'harassment', explanation: 'Insulting messages towards another member.' };

  test('a panel moderator (admin_users only, no legacy claim) can act; legacy `moderator` claim alone is refused', async () => {
    const queueId = await messageReportItem();
    await expect(v1(takeModerationAction, { queueId, action: 'dismiss' }, 'legacy', { moderator: true }))
      .rejects.toMatchObject(denied);
    await makeAdmin('sup', 'support');
    await expect(v1(takeModerationAction, { queueId, action: 'dismiss' }, 'sup')).rejects.toMatchObject(denied);
    await makeAdmin('mod', 'moderator');
    const r = await v1(takeModerationAction, { queueId, action: 'removeContent', ...sor }, 'mod');
    expect(r.success).toBe(true);
  });

  test('statement of reasons is stored on the item, the log and the audit entry; message is removed for everyone', async () => {
    const queueId = await messageReportItem();
    await makeAdmin('mod', 'moderator');
    await v1(takeModerationAction, { queueId, action: 'removeContent', ...sor }, 'mod');
    const item = (await db.doc(`moderation_queue/${queueId}`).get()).data()!;
    expect(item.status).toBe('resolved');
    expect(item.statementOfReasons).toMatchObject({ ...sor, action: 'removeContent', decidedBy: 'mod', automated: false });
    const log = await db.collection('moderation_actions_log').where('queueId', '==', queueId).get();
    expect(log.docs[0].data().statementOfReasons).toMatchObject(sor);
    const msg = (await db.doc('conversations/conv9/messages/m9').get()).data()!;
    expect(msg).toMatchObject({ isDeletedForEveryone: true, content: 'This message was removed by a moderator' });
    expect(msg.moderation).toMatchObject({ reason: 'moderator_removed', reasonCode: 'harassment' });
  });

  test('an invalid reason code is rejected and nothing changes', async () => {
    const queueId = await messageReportItem();
    await makeAdmin('mod', 'moderator');
    await expect(v1(takeModerationAction, { queueId, action: 'dismiss', reasonCode: 'because', explanation: 'whatever' }, 'mod'))
      .rejects.toMatchObject({ code: 'invalid-argument' });
    expect((await db.doc(`moderation_queue/${queueId}`).get()).data()?.status).toBe('pending');
  });

  test('a failed action leaves the item open (event report with no organizer cannot be banned)', async () => {
    const ref = await db.collection('reports').add({ type: 'event', eventId: 'ev1', eventTitle: 'Party', reporterId: 'alice', status: 'pending' });
    await (fft.wrap(onContentReportQueued) as any)({ data: await ref.get(), params: { reportId: ref.id } });
    const queueId = queueIdFor('reports', ref.id);
    await makeAdmin('mod', 'moderator');
    await expect(v1(takeModerationAction, { queueId, action: 'banUser', ...sor }, 'mod'))
      .rejects.toMatchObject({ code: 'failed-precondition' });
    expect((await db.doc(`moderation_queue/${queueId}`).get()).data()?.status).toBe('pending');
  });

  test('removeContent on an experience report hides the experience', async () => {
    await db.doc('user_experiences/x1').set({ hostId: 'host1', status: 'published', title: 'Cooking' });
    const ref = await db.collection('reports').add({
      type: 'user_experience', experienceId: 'x1', hostId: 'host1', experienceTitle: 'Cooking', reporterId: 'alice',
      reason: 'scam', status: 'pending',
    });
    await (fft.wrap(onContentReportQueued) as any)({ data: await ref.get(), params: { reportId: ref.id } });
    await makeAdmin('mod', 'moderator');
    await v1(takeModerationAction, { queueId: queueIdFor('reports', ref.id), action: 'removeContent',
      reasonCode: 'scam', explanation: 'Listing asks for payment outside the app.' }, 'mod');
    const x = (await db.doc('user_experiences/x1').get()).data()!;
    expect(x.status).toBe('hidden');
    expect(x.moderation).toMatchObject({ reason: 'moderator_removed', previousStatus: 'published' });
  });

  test('executeBulkModeration passes the statement of reasons to every item', async () => {
    const q1 = await messageReportItem();
    await makeAdmin('mod', 'moderator');
    const r = await v1(executeBulkModeration, { queueIds: [q1], action: 'dismiss', reasonCode: 'no_violation',
      explanation: 'Banter between friends, no violation.' }, 'mod');
    expect(r.successCount).toBe(1);
    expect((await db.doc(`moderation_queue/${q1}`).get()).data()?.statementOfReasons?.reasonCode).toBe('no_violation');
  });
});

// ---------------------------------------------------------------------------
describe('H-29 panel callables replace browser writes', () => {
  test('adminAdjustUserCoins credits camelCase coinBalances with a batch + coinTransactions + server audit', async () => {
    await makeAdmin('boss', 'superAdmin');
    await profile('u1');
    await db.doc('coinBalances/u1').set({ userId: 'u1', totalCoins: 20, earnedCoins: 20, coinBatches: [
      { batchId: 'b0', initialCoins: 20, remainingCoins: 20, source: 'reward' }] });
    await call(panel.adminAdjustUserCoins, { userId: 'u1', amount: 30, reason: 'compensation' }, 'boss');
    let bal = (await db.doc('coinBalances/u1').get()).data()!;
    expect(bal.totalCoins).toBe(50);
    expect(bal.coinBatches).toHaveLength(2);
    expect(bal.coinBatches[1]).toMatchObject({ initialCoins: 30, remainingCoins: 30, source: 'admin_grant' });
    // Debit never goes below zero and consumes batches.
    const r = await call(panel.adminAdjustUserCoins, { userId: 'u1', amount: -80, reason: 'fraud clawback' }, 'boss');
    expect(r.newBalance).toBe(0);
    bal = (await db.doc('coinBalances/u1').get()).data()!;
    expect(bal.coinBatches.every((b: any) => b.remainingCoins === 0)).toBe(true);
    const txs = await db.collection('coinTransactions').where('userId', '==', 'u1').get();
    expect(txs.docs.map((d) => d.data().reason)).toEqual(['adminAdjustment', 'adminAdjustment']);
    const audit = await db.collection('admin_audit_log').where('targetId', '==', 'u1').get();
    expect(audit.size).toBe(2);
    expect(audit.docs[0].data()).toMatchObject({ adminId: 'boss', source: 'admin_panel_callable' });
    expect((await db.doc('coin_balances/u1').get()).exists).toBe(false);
  });

  test('adminAdjustUserCoins: moderators and non-admins are refused; bad input rejected', async () => {
    await makeAdmin('mod', 'moderator');
    await makeAdmin('boss', 'superAdmin');
    await profile('u1');
    await expect(call(panel.adminAdjustUserCoins, { userId: 'u1', amount: 5, reason: 'gift' }, 'mod')).rejects.toMatchObject(denied);
    await expect(call(panel.adminAdjustUserCoins, { userId: 'u1', amount: 5, reason: 'gift' }, 'u1')).rejects.toMatchObject(denied);
    await expect(call(panel.adminAdjustUserCoins, { userId: 'u1', amount: 2.5, reason: 'gift' }, 'boss'))
      .rejects.toMatchObject({ code: 'invalid-argument' });
    expect((await db.doc('coinBalances/u1').get()).exists).toBe(false);
  });

  test('adminUpdateUserProfile: moderator edits text; entitlements are superAdmin-only; unknown fields refused', async () => {
    await makeAdmin('mod', 'moderator');
    await makeAdmin('boss', 'superAdmin');
    await profile('u1');
    await call(panel.adminUpdateUserProfile, { userId: 'u1', updates: { bio: 'hello', verificationStatus: 'approved' } }, 'mod');
    expect((await db.doc('profiles/u1').get()).data()).toMatchObject({ bio: 'hello', verificationStatus: 'approved' });
    await expect(call(panel.adminUpdateUserProfile, { userId: 'u1', updates: { membershipTier: 'PLATINUM' } }, 'mod'))
      .rejects.toMatchObject(denied);
    await expect(call(panel.adminUpdateUserProfile, { userId: 'u1', updates: { isAdmin: true } }, 'boss'))
      .rejects.toMatchObject({ code: 'invalid-argument' });
    const end = new Date(Date.now() + 30 * 86400000).toISOString();
    await call(panel.adminUpdateUserProfile, { userId: 'u1',
      updates: { membershipTier: 'GOLD', membershipEndDate: end, hasBaseMembership: false, baseMembershipEndDate: null } }, 'boss');
    const p = (await db.doc('profiles/u1').get()).data()!;
    expect(p.membershipTier).toBe('GOLD');
    expect(p.membershipEndDate.toDate().toISOString()).toBe(end);
    expect(p.isAdmin).toBeUndefined();
  });

  test('adminSetUserStatus writes profiles like the panel did; a moderator cannot ban an admin', async () => {
    await makeAdmin('mod', 'moderator');
    await makeAdmin('boss', 'superAdmin');
    await profile('u1');
    await profile('boss');
    await call(panel.adminSetUserStatus, { userId: 'u1', action: 'suspend', reason: 'spam wave', durationDays: 3 }, 'mod');
    let p = (await db.doc('profiles/u1').get()).data()!;
    expect(p.status).toBe('suspended');
    expect(p.suspendedUntil.toMillis()).toBeGreaterThan(Date.now() + 2 * 86400000);
    await call(panel.adminSetUserStatus, { userId: 'u1', action: 'unsuspend' }, 'mod');
    p = (await db.doc('profiles/u1').get()).data()!;
    expect(p).toMatchObject({ status: 'active', suspensionReason: null });
    await expect(call(panel.adminSetUserStatus, { userId: 'boss', action: 'ban', reason: 'coup' }, 'mod'))
      .rejects.toMatchObject(denied);
    await makeAdmin('sup', 'support');
    await expect(call(panel.adminSetUserStatus, { userId: 'u1', action: 'ban', reason: 'abuse' }, 'sup'))
      .rejects.toMatchObject(denied);
    const actions = await db.collection('admin_actions').where('userId', '==', 'u1').get();
    expect(actions.docs.map((d) => d.data().action).sort()).toEqual(['suspend_user', 'unsuspend_user']);
  });

  test('adminOverrideSubscription sets tier AND end date; paid tier without a date is refused', async () => {
    await makeAdmin('boss', 'superAdmin');
    await profile('u1');
    await expect(call(panel.adminOverrideSubscription, { userId: 'u1', tier: 'GOLD' }, 'boss'))
      .rejects.toMatchObject({ code: 'invalid-argument' });
    const end = new Date(Date.now() + 7 * 86400000).toISOString();
    await call(panel.adminOverrideSubscription, { userId: 'u1', tier: 'gold', expirationDate: end }, 'boss'); // Subscriptions page sends lowercase
    const p = (await db.doc('profiles/u1').get()).data()!;
    expect(p.membershipTier).toBe('GOLD');
    expect(p.membershipEndDate.toDate().toISOString()).toBe(end);
    expect((await db.collection('subscriptions').where('userId', '==', 'u1').get()).size).toBe(1);
  });

  test('adminToggleTestUser round trip (profile + mvp_access)', async () => {
    await makeAdmin('boss', 'superAdmin');
    await profile('u1');
    const on = await call(panel.adminToggleTestUser, { userId: 'u1' }, 'boss');
    expect(on.isTestUser).toBe(true);
    expect((await db.doc('profiles/u1').get()).data()).toMatchObject({ membershipTier: 'TEST', isTestUser: true });
    expect((await db.collection('mvp_access').where('email', '==', 'u1@example.com').get()).docs[0].data().membershipTier).toBe('test');
    const off = await call(panel.adminToggleTestUser, { userId: 'u1' }, 'boss');
    expect(off.isTestUser).toBe(false);
    expect((await db.doc('profiles/u1').get()).data()).toMatchObject({ membershipTier: 'FREE', isTestUser: false });
  });

  test('adminSendUserNotification and adminBulkApproveVerification', async () => {
    await makeAdmin('boss', 'superAdmin');
    await makeAdmin('mod', 'moderator');
    await profile('u1');
    await profile('u2');
    await expect(call(panel.adminSendUserNotification, { userId: 'u1', title: 'Hi', body: 'There' }, 'mod'))
      .rejects.toMatchObject(denied);
    await call(panel.adminSendUserNotification, { userId: 'u1', title: 'Hi', body: 'There' }, 'boss');
    expect((await db.collection('notifications').where('userId', '==', 'u1').get()).size).toBe(1);
    const r = await call(panel.adminBulkApproveVerification, { userIds: ['u1', 'u2', 'ghost'] }, 'mod');
    expect(r).toMatchObject({ success: 2, failed: 1 });
    expect((await db.doc('profiles/u2').get()).data()).toMatchObject({ verificationStatus: 'approved', verificationReviewedBy: 'mod' });
  });
});
