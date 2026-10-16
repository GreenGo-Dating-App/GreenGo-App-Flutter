/**
 * Terms sections 17-18 (DSA arts. 17, 20, 23): statements of reasons, appeals
 * and their resolution, repeat offenders, abusive reporters, the Vision hold
 * and the web appeal page. Real Firestore + Auth + Storage emulators; only
 * Vision and outbound fetch (Resend) are stubbed.
 *
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "cd functions && npx jest -i --config jest.security.config.js terms-appeals"
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) {
  admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
}
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
process.env.RESEND_API_KEY = 'test-resend-key';
process.env.TICKET_QR_SIGNING_KEY = 'emulator-test-signing-key-0123456789abcdef012345';

const fft = functionsTest({ projectId: PROJECT });
const db = admin.firestore();
const auth = admin.auth();
const bucket = () => admin.storage().bucket();
const TS = admin.firestore.Timestamp;

jest.mock('@google-cloud/vision', () => {
  class ImageAnnotatorClient {
    annotateImage = async () => [(global as any).__visionAnnotate ?? {}];
  }
  return { __esModule: true, default: { ImageAnnotatorClient }, ImageAnnotatorClient };
});

const fetchMock = jest.fn(async (..._args: any[]) => ({
  ok: true, status: 200, statusText: 'OK', json: async () => ({ id: 'mail-1' }), text: async () => '{}',
}));
(global as any).fetch = fetchMock;

/* eslint-disable @typescript-eslint/no-var-requires */
const mq = () => require('../../src/admin/moderationQueue');
const pipeline = () => require('../../src/safety/reportPipeline');
const reporting = () => require('../../src/safety/reportingSystem');
const appeals = () => require('../../src/safety/appealResolution');
const decisions = () => require('../../src/safety/moderationDecisions');
const standing = () => require('../../src/safety/reporterStanding');
const page = () => require('../../src/safety/appealPage');
const users = () => require('../../src/admin/userManagement');
/* eslint-enable @typescript-eslint/no-var-requires */

const v1 = (fn: any, data: any, uid?: string, token: Record<string, any> = {}) =>
  (fft.wrap(fn) as any)(data, { auth: uid ? { uid, token } : undefined, rawRequest: {} });
const MOD = { adminRole: 'moderator' };

function emulatorDelete(path: string) {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  return new Promise<void>((resolve, reject) => {
    const r = http.request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE', path },
      (res) => { res.resume(); res.on('end', resolve); });
    r.on('error', reject);
    r.end();
  });
}
async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host || !/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) throw new Error('Not a local emulator');
  await emulatorDelete(`/emulator/v1/projects/${PROJECT}/databases/(default)/documents`);
  const list = await auth.listUsers(1000);
  if (list.users.length) await auth.deleteUsers(list.users.map((u) => u.uid));
  if (process.env.FIREBASE_STORAGE_EMULATOR_HOST) await bucket().deleteFiles({ force: true }).catch(() => undefined);
}

async function member(uid: string) {
  await auth.createUser({ uid, email: `${uid}@example.com` }).catch(() => undefined);
  await db.doc(`users/${uid}`).set({ accountStatus: 'active', preferredLanguage: 'en' });
  await db.doc(`profiles/${uid}`).set({ status: 'active' });
}
async function moderators() {
  for (const m of ['mod1', 'mod2']) await db.doc(`admin_users/${m}`).set({ role: 'moderator', email: `${m}@greengo.test` });
}

let n = 0;
/** A message report alice -> bob, enqueued by the real pipeline trigger. */
async function messageReport(reporter = 'alice', author = 'bob', text = 'you idiot', reason = 'Harassment or bullying') {
  n++;
  const conv = `conv${n}`;
  await db.doc(`conversations/${conv}/messages/m${n}`).set({ senderId: author, content: text, type: 'text' });
  const ref = await db.collection('message_reports').add({
    reporterId: reporter, reportedUserId: author, conversationId: conv, messageId: `m${n}`,
    reason, messageContent: text, createdAt: TS.now(),
  });
  await (fft.wrap(pipeline().onMessageReportQueued) as any)({ data: await ref.get(), params: { reportId: ref.id } });
  return { queueId: pipeline().queueIdFor('message_reports', ref.id), path: `conversations/${conv}/messages/m${n}` };
}
async function fireResolved(queueId: string, beforeData: any) {
  const before = fft.firestore.makeDocumentSnapshot(beforeData, `moderation_queue/${queueId}`);
  const after = await db.doc(`moderation_queue/${queueId}`).get();
  await (fft.wrap(pipeline().onModerationQueueResolved) as any)({ data: fft.makeChange(before, after), params: { queueId } });
}
const sentEmails = () => fetchMock.mock.calls
  .filter((c) => String(c[0]).includes('api.resend.com'))
  .map((c) => JSON.parse((c[1] as any).body));

beforeEach(async () => {
  await clearAll();
  fetchMock.mockClear();
  decisions().resetAppealKey();
  await moderators();
  await member('alice');
  await member('bob');
});
afterAll(() => fft.cleanup());

// ===========================================================================
describe('statement of reasons (Terms 18.3)', () => {
  test('ban: decision with content + automated flag + effects; in-app AND email with a signed appeal link', async () => {
    const { queueId } = await messageReport();
    await v1(mq().takeModerationAction, { queueId, action: 'banUser', reasonCode: 'harassment', explanation: 'Repeated insults.' }, 'mod1', MOD);

    expect((await auth.getUser('bob')).disabled).toBe(true);
    const d = (await db.doc(`moderation_decisions/${queueId}`).get()).data()!;
    expect(d).toMatchObject({
      userId: 'bob', action: 'banUser', decidedBy: 'mod1', automated: false, appealable: true,
      contentRef: { type: 'message', excerpt: 'you idiot' },
    });
    expect(d.effects.map((e: any) => e.type)).toEqual(['ban', 'strike']);
    const note = (await db.doc(`notifications/moderation_decision_${queueId}`).get()).data()!;
    expect(note.data).toMatchObject({ contentType: 'message', contentExcerpt: 'you idiot', automated: 'false' });

    const mails = sentEmails();
    expect(mails).toHaveLength(1);
    expect(mails[0].to).toEqual(['bob@example.com']);
    expect(mails[0].html).toContain('moderationAppeal?d=');
    expect(mails[0].html).toContain('you idiot');
  });

  test('keyword-screen items are marked automated', async () => {
    await require('../../src/safety/autoTextModeration').screenChatMessage('group', 'g1', 'mm', 'groups/g1/messages/mm', { senderId: 'bob', content: 'I will kill you' });
    await db.doc('groups/g1/messages/mm').set({ senderId: 'bob', content: 'I will kill you' });
    const queueId = (await db.collection('moderation_queue').get()).docs[0].id;
    await v1(mq().takeModerationAction, { queueId, action: 'removeContent', reasonCode: 'threats', explanation: 'Threat.' }, 'mod1', MOD);
    const d = (await db.doc(`moderation_decisions/${queueId}`).get()).data()!;
    expect(d).toMatchObject({ automated: true, automatedDetection: 'keyword', automatedDecision: false });
  });

  test('suspendUserAccount / banUserAccount (user management) also produce decision + notice', async () => {
    const r = await v1(users().suspendUserAccount, { userId: 'bob', reason: 'Spam in events.', durationDays: 3 }, 'mod1', MOD);
    const d = (await db.doc(`moderation_decisions/${r.decisionId}`).get()).data()!;
    expect(d).toMatchObject({ action: 'suspendUser', userId: 'bob', decidedBy: 'mod1' });
    expect((await db.doc(`notifications/moderation_decision_${r.decisionId}`).get()).exists).toBe(true);
    const b = await v1(users().banUserAccount, { userId: 'alice', reason: 'Fraud.' }, 'mod1', MOD);
    expect((await db.doc(`moderation_decisions/${b.decisionId}`).get()).data()).toMatchObject({ action: 'banUser' });
    expect(sentEmails().map((m) => m.to[0]).sort()).toEqual(['alice@example.com', 'bob@example.com']);
  });
});

// ===========================================================================
describe('appeal resolution (Terms 18.4 b-c)', () => {
  test('the original decider is refused; another moderator overturns: ban lifted, Auth re-enabled, strike revoked, user told', async () => {
    const { queueId } = await messageReport();
    await v1(mq().takeModerationAction, { queueId, action: 'banUser', reasonCode: 'harassment', explanation: 'Insults.' }, 'mod1', MOD);
    const { appealId } = await v1(reporting().submitAppeal, { decisionId: queueId, appealReason: 'It was a quote from a film.' }, 'bob');

    await expect(v1(appeals().resolveModerationAppeal, { appealId, outcome: 'overturned', explanation: 'Quote.' }, 'mod1', MOD))
      .rejects.toMatchObject({ code: 'permission-denied' });
    expect((await db.doc(`report_appeals/${appealId}`).get()).data()?.status).toBe('pending');

    const r = await v1(appeals().resolveModerationAppeal,
      { appealId, outcome: 'overturned', explanation: 'It was a film quote, not an insult.' }, 'mod2', MOD);
    expect(r.outcome).toBe('overturned');
    expect((await auth.getUser('bob')).disabled).toBe(false);
    expect((await db.doc('users/bob').get()).data()?.accountStatus).toBe('active');
    const strikes = await db.collection('user_strikes').where('userId', '==', 'bob').get();
    expect(strikes.docs.every((s) => s.data().revoked === true)).toBe(true);
    expect((await db.doc(`moderation_decisions/${queueId}`).get()).data()).toMatchObject({
      appealStatus: 'overturned', appealOutcome: { outcome: 'overturned', resolvedBy: 'mod2' },
    });
    expect((await db.doc(`report_appeals/${appealId}`).get()).data()).toMatchObject({ status: 'resolved', decision: 'overturned', reviewedBy: 'mod2' });
    expect((await db.doc(`moderation_queue/appeal__${queueId}`).get()).data()).toMatchObject({ status: 'resolved', action: 'appeal_overturned' });
    const note = (await db.doc(`notifications/appeal_outcome_${appealId}`).get()).data()!;
    expect(note.data).toMatchObject({ action: 'moderation_decision', appealOutcome: 'overturned', appealExplanation: 'It was a film quote, not an insult.' });
    expect(sentEmails().some((m) => /outcome of your appeal/.test(m.subject))).toBe(true);
  });

  test('appeal queue item via takeModerationAction: approve restores a removed message; dismiss upholds', async () => {
    const a = await messageReport('alice', 'bob', 'original text one');
    await v1(mq().takeModerationAction, { queueId: a.queueId, action: 'removeContent', reasonCode: 'harassment', explanation: 'Insult.' }, 'mod1', MOD);
    expect((await db.doc(a.path).get()).data()?.isDeletedForEveryone).toBe(true);
    await v1(reporting().submitAppeal, { decisionId: a.queueId, appealReason: 'Please look at the context.' }, 'bob');
    await v1(mq().takeModerationAction, { queueId: `appeal__${a.queueId}`, action: 'approve', reasonCode: 'no_violation', explanation: 'Context shows banter.' }, 'mod2', MOD);
    const msg = (await db.doc(a.path).get()).data()!;
    expect(msg.content).toBe('original text one');
    expect(msg.isDeletedForEveryone).toBeUndefined();
    expect(msg.moderation).toBeUndefined();

    const b = await messageReport('alice', 'bob', 'second text');
    await v1(mq().takeModerationAction, { queueId: b.queueId, action: 'removeContent', reasonCode: 'harassment', explanation: 'Insult.' }, 'mod1', MOD);
    await v1(reporting().submitAppeal, { decisionId: b.queueId, appealReason: 'Please look again at it.' }, 'bob');
    await v1(mq().takeModerationAction, { queueId: `appeal__${b.queueId}`, action: 'dismiss', reasonCode: 'harassment', explanation: 'Clearly insulting.' }, 'mod2', MOD);
    expect((await db.doc(`moderation_decisions/${b.queueId}`).get()).data()?.appealStatus).toBe('upheld');
    expect((await db.doc(b.path).get()).data()?.isDeletedForEveryone).toBe(true);
  });

  test('partial overturn: ban replaced by a 3-day suspension', async () => {
    const { queueId } = await messageReport();
    await v1(mq().takeModerationAction, { queueId, action: 'banUser', reasonCode: 'harassment', explanation: 'Insults.' }, 'mod1', MOD);
    const { appealId } = await v1(reporting().submitAppeal, { decisionId: queueId, appealReason: 'A ban is too harsh for this.' }, 'bob');
    await v1(appeals().resolveModerationAppeal, {
      appealId, outcome: 'partially_overturned', explanation: 'A ban is disproportionate; 3-day suspension instead.',
      replacementAction: 'suspendUser', durationDays: 3,
    }, 'mod2', MOD);
    expect((await auth.getUser('bob')).disabled).toBe(false);
    expect((await db.doc('users/bob').get()).data()).toMatchObject({ accountStatus: 'suspended', suspensionDecisionId: `${queueId}__appeal` });
    expect((await db.doc(`moderation_decisions/${queueId}__appeal`).get()).data()).toMatchObject({ action: 'suspendUser', appealable: false });
  });
});

// ===========================================================================
describe('reporter appeals a decision not to act (Terms 18.4 a)', () => {
  test('dismissed report -> appealable notice; overturn re-opens the report for a different moderator', async () => {
    const { queueId } = await messageReport();
    const before = (await db.doc(`moderation_queue/${queueId}`).get()).data();
    await v1(mq().takeModerationAction, { queueId, action: 'dismiss', reasonCode: 'no_violation', explanation: 'Banter, no violation.' }, 'mod1', MOD);
    await fireResolved(queueId, before);

    const note = (await db.doc(`notifications/report_reviewed_${queueId}`).get()).data()!;
    expect(note.data).toMatchObject({ action: 'report_reviewed', outcome: 'no_violation', decisionId: `nr__${queueId}`, role: 'reporter', appealable: 'true' });
    expect(note.data.reportedUserId).toBeUndefined();
    const d = (await db.doc(`moderation_decisions/nr__${queueId}`).get()).data()!;
    expect(d).toMatchObject({ userId: 'alice', role: 'reporter', action: 'noAction', decidedBy: 'mod1', explanation: 'Banter, no violation.' });

    // The reported user cannot appeal the reporter's decision.
    await expect(v1(reporting().submitAppeal, { decisionId: `nr__${queueId}`, appealReason: 'I want to appeal too.' }, 'bob'))
      .rejects.toMatchObject({ code: 'permission-denied' });
    const { appealId } = await v1(reporting().submitAppeal, { decisionId: `nr__${queueId}`, appealReason: 'He threatened me, see the context.' }, 'alice');
    await expect(v1(mq().takeModerationAction, { queueId: `appeal__nr__${queueId}`, action: 'approve', reasonCode: 'other', explanation: 'Re-review.' }, 'mod1', MOD))
      .rejects.toMatchObject({ code: 'permission-denied' });
    await v1(mq().takeModerationAction, { queueId: `appeal__nr__${queueId}`, action: 'approve', reasonCode: 'other', explanation: 'Context needs another look.' }, 'mod2', MOD);

    const q = (await db.doc(`moderation_queue/${queueId}`).get()).data()!;
    expect(q).toMatchObject({ status: 'pending', reopenedByAppealId: appealId });
    expect(q.excludedReviewers).toContain('mod1');
    await expect(v1(mq().takeModerationAction, { queueId, action: 'banUser', reasonCode: 'threats', explanation: 'Threat.' }, 'mod1', MOD))
      .rejects.toMatchObject({ code: 'permission-denied' });
    expect((await db.doc(`notifications/appeal_outcome_${appealId}`).get()).data()?.data).toMatchObject({ appealOutcome: 'report_reopened' });
  });
});

// ===========================================================================
describe('repeat offenders (Terms 18.6)', () => {
  test('3rd violation within 12 months after a warning suspends the account, with its own decision', async () => {
    const ids: string[] = [];
    for (let i = 0; i < 3; i++) {
      const { queueId } = await messageReport('alice', 'bob', `insult ${i}`);
      ids.push(queueId);
      const r = await v1(mq().takeModerationAction, { queueId, action: 'issueWarning', reasonCode: 'harassment', explanation: `Insult number ${i}.` }, 'mod1', MOD);
      if (i < 2) {
        expect(r.escalation).toEqual({ escalated: false });
        expect((await db.doc('users/bob').get()).data()?.accountStatus).toBe('active');
      } else {
        expect(r.escalation).toMatchObject({ escalated: true, days: 7 });
      }
    }
    expect((await db.doc('users/bob').get()).data()).toMatchObject({ accountStatus: 'suspended', suspensionDecisionId: `${ids[2]}__escalation` });
    expect((await db.doc(`moderation_decisions/${ids[2]}__escalation`).get()).data())
      .toMatchObject({ action: 'suspendUser', reasonCode: 'repeat_violations', appealable: true });
  });
});

// ===========================================================================
describe('abusive reporters (Terms 18.6 / DSA art. 23)', () => {
  async function seedDismissed(uid: string, count: number, atMs: number) {
    const batch = db.batch();
    for (let i = 0; i < count; i++) {
      batch.set(db.collection('moderation_queue').doc(), {
        reporterId: uid, createdAt: TS.fromMillis(atMs + i), status: 'resolved', action: 'dismiss',
        source: { collection: 'user_reports' },
      });
    }
    await batch.commit();
  }

  test('warning first, then a moderator suspends report processing; P0 reports still processed', async () => {
    await member('carol');
    const t0 = Date.now() - 3 * 86_400_000;
    await seedDismissed('carol', 10, t0);
    expect(await standing().checkAbusiveReporter('carol', t0 + 1000)).toBe('warn');
    const warnings = await db.collection('moderation_decisions').where('userId', '==', 'carol').get();
    expect(warnings.docs[0].data()).toMatchObject({ action: 'reporterWarning', reasonCode: 'unfounded_reports', appealable: true });

    await seedDismissed('carol', 5, t0 + 2000);
    expect(await standing().checkAbusiveReporter('carol', t0 + 5000)).toBe('review');
    const item = (await db.collection('moderation_queue').where('itemType', '==', 'reporterAbuse').get()).docs[0];
    await v1(mq().takeModerationAction, { queueId: item.id, action: 'suspendReporting', reasonCode: 'other', explanation: 'Mass false reports against one user.' }, 'mod1', MOD);
    expect(await standing().isReportingSuspended('carol')).toBe(true);
    expect((await db.doc(`moderation_decisions/${item.id}`).get()).data())
      .toMatchObject({ action: 'suspendReporting', reasonCode: 'unfounded_reports', userId: 'carol' });

    const spam = await db.collection('user_reports').add({ reporterId: 'carol', reportedUserId: 'bob', reason: 'Spam or scam' });
    await (fft.wrap(pipeline().onUserReportQueued) as any)({ data: await spam.get(), params: { reportId: spam.id } });
    expect((await db.doc(`moderation_queue/user_reports__${spam.id}`).get()).data()).toMatchObject({ status: 'reporter_suspended', priority: 'low' });

    const p0 = await db.collection('user_reports').add({ reporterId: 'carol', reportedUserId: 'bob', reason: 'Underage user' });
    await (fft.wrap(pipeline().onUserReportQueued) as any)({ data: await p0.get(), params: { reportId: p0.id } });
    expect((await db.doc(`moderation_queue/user_reports__${p0.id}`).get()).data()?.status).toBe('pending');
  });
});

// ===========================================================================
describe('web appeal page (banned users)', () => {
  test('invalid link refused; valid link shows the form and files a web appeal', async () => {
    const { queueId } = await messageReport();
    await v1(mq().takeModerationAction, { queueId, action: 'banUser', reasonCode: 'harassment', explanation: 'Insults.' }, 'mod1', MOD);
    const bad = await page().appealPageGet({ d: queueId, s: 'x'.repeat(43) }, 'en');
    expect(bad.status).toBe(400);

    const link = new URL(await decisions().appealLinkFor(queueId, 'bob', 'en'));
    const s = link.searchParams.get('s')!;
    const ok = await page().appealPageGet({ d: queueId, s }, 'en');
    expect(ok.status).toBe(200);
    expect(ok.html).toContain('name="reason"');
    expect(ok.html).toContain('Account banned');

    const short = await page().appealPagePost({ d: queueId, s, reason: 'no' }, 'en');
    expect(short.status).toBe(400);
    const posted = await page().appealPagePost({ d: queueId, s, reason: 'I was hacked, it was not me.' }, 'en');
    expect(posted.status).toBe(200);
    const ap = await db.collection('report_appeals').where('decisionId', '==', queueId).get();
    expect(ap.docs[0].data()).toMatchObject({ userId: 'bob', channel: 'web', status: 'pending' });
    const again = await page().appealPageGet({ d: queueId, s }, 'en');
    expect(again.html).not.toContain('name="reason"');
  });
});

// ===========================================================================
describe('Vision hold is restorable (Terms 17.1 b)', () => {
  const put = (path: string) =>
    bucket().file(path).save(Buffer.from('img'), { contentType: 'image/jpeg', resumable: false, metadata: { metadata: { userId: 'bob' } } });
  const exists = async (path: string) => (await bucket().file(path).exists())[0];

  test('quarantine -> automated decision + notice; moderator approve restores the original path; the restored copy is not re-screened', async () => {
    if (!process.env.FIREBASE_STORAGE_EMULATOR_HOST) return;
    // firebase-functions-test overwrote FIREBASE_CONFIG (no bucket).
    process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
    const { moderateUploadedImage } = require('../../src/safety/moderateUploadedImage');
    const path = 'profiles/bob/photos/beach.jpg';
    await put(path);
    const [meta] = await bucket().file(path).getMetadata();
    (global as any).__visionAnnotate = { safeSearchAnnotation: { adult: 'VERY_LIKELY' }, labelAnnotations: [] };
    await (moderateUploadedImage as any).run({
      data: { name: path, bucket: `${PROJECT}.appspot.com`, contentType: 'image/jpeg', metadata: { userId: 'bob' }, generation: meta.generation },
    });
    expect(await exists(path)).toBe(false);
    const queueId = `image__profiles~bob~photos~beach.jpg__${meta.generation}`;
    const item = (await db.doc(`moderation_queue/${queueId}`).get()).data()!;
    expect(item).toMatchObject({ itemType: 'quarantinedImage', status: 'pending', reasonCode: 'sexual_content' });
    expect((await db.doc(`moderation_decisions/${queueId}`).get()).data()).toMatchObject({
      userId: 'bob', action: 'removeContent', automated: true, automatedDetection: 'vision', automatedDecision: true,
      contentRef: { type: 'photo', id: 'beach.jpg' },
    });

    await v1(mq().takeModerationAction, { queueId, action: 'approve', reasonCode: 'no_violation', explanation: 'A beach photo, no nudity.' }, 'mod1', MOD);
    expect(await exists(path)).toBe(true);
    expect(await exists(`quarantine/${path}`)).toBe(false);
    expect((await db.doc(`moderation_decisions/${queueId}`).get()).data()?.appealStatus).toBe('overturned');
    expect((await db.doc(`notifications/decision_reversed_${queueId}`).get()).exists).toBe(true);

    const [restored] = await bucket().file(path).getMetadata();
    await (moderateUploadedImage as any).run({
      data: { name: path, bucket: `${PROJECT}.appspot.com`, contentType: 'image/jpeg', metadata: { userId: 'bob' }, generation: restored.generation },
    });
    expect(await exists(path)).toBe(true);
  });
});

// ===========================================================================
describe('rules: decisions, appeals, backups and reporter standing are server-only', () => {
  function req(method: string, hostEnv: string, path: string, body?: unknown, token?: string): Promise<{ status: number; json: any }> {
    const host = process.env[hostEnv]!;
    return new Promise((resolve, reject) => {
      const r = http.request({
        host: host.split(':')[0], port: Number(host.split(':')[1]), method, path,
        headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      }, (res) => {
        let data = '';
        res.on('data', (c) => { data += c; });
        res.on('end', () => resolve({ status: res.statusCode || 0, json: data ? JSON.parse(data) : null }));
      });
      r.on('error', reject);
      if (body) r.write(JSON.stringify(body));
      r.end();
    });
  }

  test('the affected user cannot read or write their own decision / appeal docs directly', async () => {
    const signUp = await req('POST', 'FIREBASE_AUTH_EMULATOR_HOST', '/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake',
      { email: 'dave@example.com', password: 'secret123', returnSecureToken: true });
    const token = signUp.json.idToken as string;
    const uid = signUp.json.localId as string;
    await db.doc('moderation_decisions/dx').set({ userId: uid, action: 'banUser' });
    await db.doc('report_appeals/ax').set({ userId: uid });
    await db.doc('moderation_content_backups/bx').set({ path: 'x' });
    await db.doc(`reporter_standing/${uid}`).set({ userId: uid });
    const base = `/v1/projects/${PROJECT}/databases/(default)/documents`;
    // Positive control (the check can fail): the user's own notification IS readable.
    await db.doc('notifications/nx').set({ userId: uid, type: 'system' });
    expect((await req('GET', 'FIRESTORE_EMULATOR_HOST', `${base}/notifications/nx`, undefined, token)).status).toBe(200);
    for (const p of ['moderation_decisions/dx', 'report_appeals/ax', 'moderation_content_backups/bx', `reporter_standing/${uid}`]) {
      expect((await req('GET', 'FIRESTORE_EMULATOR_HOST', `${base}/${p}`, undefined, token)).status).toBe(403);
    }
    const write = await req('PATCH', 'FIRESTORE_EMULATOR_HOST', `${base}/reporter_standing/${uid}`,
      { fields: { suspendedUntil: { nullValue: null } } }, token);
    expect(write.status).toBe(403);
  });
});

describe('no notice where the law forbids it (Terms 18.3)', () => {
  test('a CSAE decision is recorded but the suspect gets no notice, email or appeal', async () => {
    const created = await decisions().createModerationDecision({
      decisionId: 'csae1', userId: 'bob', action: 'banUser', reasonCode: 'csae', explanation: 'x', decidedBy: 'mod1',
    });
    expect(created).toBe(true);
    expect((await db.doc('moderation_decisions/csae1').get()).data()).toMatchObject({ appealable: false, noticeWithheld: 'csae_law_enforcement' });
    expect((await db.doc('notifications/moderation_decision_csae1').get()).exists).toBe(false);
    expect(sentEmails()).toHaveLength(0);
  });
});
