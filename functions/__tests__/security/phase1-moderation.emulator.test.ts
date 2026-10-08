/**
 * P1-12 (audit C-11): every user report reaches a moderator.
 *
 * Reports are written EXACTLY as the app writes them (field names copied from
 * the Dart code), then the trigger is invoked with the stored snapshot, against
 * the real Firestore + Auth emulators.
 *
 *   firebase emulators:exec --only firestore,auth --project test-project \
 *     "npx jest --config jest.security.config.js"
 */

import * as fs from 'fs';
import * as path from 'path';
import * as admin from 'firebase-admin';
import functionsTest from 'firebase-functions-test';

const fft = functionsTest({ projectId: process.env.GCLOUD_PROJECT });

import {
  onUserReportQueued,
  onMessageReportQueued,
  onContentReportQueued,
  onModerationQueueResolved,
  classifyReason,
  queueIdFor,
  feedbackNotificationId,
} from '../../src/safety/reportPipeline';
import { submitReport } from '../../src/safety/reportingSystem';
import { takeModerationAction } from '../../src/admin/moderationQueue';
import { onUserReportCreated } from '../../src/safety/reportCountTrigger';

const db = admin.firestore();
const auth = admin.auth();
const ts = () => admin.firestore.Timestamp.fromDate(new Date());
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

// --- invoke triggers with the STORED snapshot (what Firestore would deliver) ---
async function fireCreated(fn: any, col: string, id: string) {
  const snap = await db.collection(col).doc(id).get();
  await (fft.wrap(fn) as any)({ data: snap, params: { reportId: id } });
}
async function fireUpdated(queueId: string, beforeData: any) {
  const before = fft.firestore.makeDocumentSnapshot(beforeData, `moderation_queue/${queueId}`);
  const after = await db.doc(`moderation_queue/${queueId}`).get();
  await (fft.wrap(onModerationQueueResolved) as any)({
    data: fft.makeChange(before, after),
    params: { queueId },
  });
}
const queueItems = async () => (await db.collection('moderation_queue').get()).docs;

// --- report writers: copied field-for-field from the Dart clients ---
/** safety_actions_service.dart reportUser (profile + community via report_block_sheet.dart). */
async function appProfileReport(reporterId: string, reportedUserId: string, reason: string, additionalDetails = 'profile') {
  const ref = db.collection('user_reports').doc();
  await ref.set({
    reportId: ref.id, reporterId, reportedUserId, reason,
    reportedAt: ts(), createdAt: FV.serverTimestamp(), source: 'profile', status: 'pending',
    reviewedBy: null, reviewedAt: null, actionTaken: null, additionalDetails,
  });
  return ref.id;
}
/** chat_remote_datasource.dart reportUser. */
async function appChatUserReport(reporterId: string, reportedUserId: string, reason: string) {
  const ref = db.collection('user_reports').doc();
  await ref.set({
    reportId: ref.id, reporterId, reportedUserId, reason, reportedAt: ts(), status: 'pending',
    reviewedBy: null, reviewedAt: null, actionTaken: null, conversationId: 'conv1', messageId: 'm1',
  });
  return ref.id;
}
/** chat_remote_datasource.dart reportMessage. */
async function appMessageReport(reporterId: string, reportedUserId: string, reason: string) {
  const ref = db.collection('message_reports').doc();
  await ref.set({
    reportId: ref.id, messageId: 'm9', conversationId: 'conv9', messageContent: 'SECRET MESSAGE BODY',
    messageSentAt: ts(), reporterId, reportedUserId, reason, reportedAt: ts(), status: 'pending',
    reviewedBy: null, reviewedAt: null, actionTaken: null,
  });
  return ref.id;
}
/** events_screen.dart report. */
async function appEventReport(reporterId: string) {
  const ref = await db.collection('reports').add({
    type: 'event', eventId: 'ev1', organizerId: 'org1', eventTitle: 'Rooftop party',
    reporterId, reportedAt: ts(), status: 'pending',
  });
  return ref.id;
}
/** user_experiences_repository_impl.dart reportExperience -> remote.report. */
async function appExperienceReport(reporterId: string, reason: string, details?: string) {
  const ref = await db.collection('reports').add({
    type: 'user_experience', experienceId: 'x1', hostId: 'host1', experienceTitle: 'Cooking class',
    reporterId, reason, ...(details ? { details } : {}), reportedAt: ts(), status: 'pending',
  });
  return ref.id;
}
/** user_experiences_repository_impl.dart reportReview -> remote.report. */
async function appReviewReport(reporterId: string) {
  const ref = await db.collection('reports').add({
    type: 'user_experience_review', experienceId: 'x1', reviewAuthorId: 'author1', comment: 'meh',
    reporterId, reportedAt: ts(), status: 'pending',
  });
  return ref.id;
}

beforeEach(async () => {
  await clearAll();
  fetchMock.mockClear();
});
afterAll(() => fft.cleanup());

// ---------------------------------------------------------------------------
describe('P1-12 reason normalization (pure)', () => {
  const KEY_TO_CODE: Record<string, string> = {
    chatReportReasonFakeProfile: 'impersonation',
    chatReportReasonHarassment: 'harassment',
    chatReportReasonInappropriate: 'inappropriate',
    chatReportReasonOther: 'other',
    chatReportReasonPersonalInfo: 'privacy',
    chatReportReasonSpam: 'spam',
    chatReportReasonThreatening: 'threats',
    chatReportReasonUnderage: 'underage',
  };
  const l10nDir = path.join(__dirname, '..', '..', '..', 'lib', 'l10n');
  const arbs = fs.readdirSync(l10nDir).filter((f) => /^app_.*\.arb$/.test(f));

  test('every report-reason string in every app_*.arb maps to its code', () => {
    expect(arbs.length).toBeGreaterThanOrEqual(7);
    let checked = 0;
    for (const f of arbs) {
      const arb = JSON.parse(fs.readFileSync(path.join(l10nDir, f), 'utf8'));
      for (const [key, code] of Object.entries(KEY_TO_CODE)) {
        expect([f, key, classifyReason(arb[key])]).toEqual([f, key, code]);
        checked++;
      }
    }
    expect(checked).toBe(arbs.length * 8);
  });

  test('wire values and free text', () => {
    expect(classifyReason('scam')).toBe('scam');
    expect(classifyReason('off_platform_payment')).toBe('off_platform_payment');
    expect(classifyReason('minorSafety')).toBe('underage');
    expect(classifyReason('hateSpeech')).toBe('hate');
    expect(classifyReason(undefined)).toBe('other');
    expect(classifyReason('he is a pedophile')).toBe('csae');
    expect(classifyReason('scam', 'he sent me child porn')).toBe('csae'); // details escalate to CSAE
    expect(classifyReason('scam', 'dog grooming event, overpriced')).toBe('scam'); // no false P0
  });
});

// ---------------------------------------------------------------------------
describe('P1-12 every report source creates exactly one queue item', () => {
  test('profile report "Underage user" -> P0 critical item, admin alert email (ids only), minor-safety warning', async () => {
    await db.doc('app_config/resend_settings').set({ apiKey: 're_test', senderEmail: 'safety@greengo.test' });
    await db.doc('admin_users/adm1').set({ role: 'admin', email: 'admin@greengo.test' });
    await db.doc('admin_users/support1').set({ role: 'support', email: 'support@greengo.test' });
    await db.doc('app_config/moderation_settings').set({ reportAutoActionsEnabled: true });
    const id = await appProfileReport('alice', 'bob', 'Underage user', 'community:c1; content:post7');
    await fireCreated(onUserReportQueued, 'user_reports', id);

    const items = await queueItems();
    expect(items).toHaveLength(1);
    const q = items[0].data();
    expect(items[0].id).toBe(queueIdFor('user_reports', id));
    expect(q).toMatchObject({
      queueId: items[0].id, itemType: 'userReport', itemId: id, userId: 'bob', status: 'pending',
      priority: 'critical', priorityLevel: 'P0', reasonCode: 'underage', category: 'underage',
      reporterId: 'alice', reportedUserId: 'bob', reason: 'Underage user', slaHours: 24,
      relatedReportIds: [id],
      source: { collection: 'user_reports', docId: id, path: `user_reports/${id}` },
    });
    const dueH = (q.slaDueAt.toMillis() - Date.now()) / 3600_000;
    expect(dueH).toBeGreaterThan(23.9);
    expect(dueH).toBeLessThanOrEqual(24);

    // P0 alert: admin_alerts + in-app notification for admins only + one email, ids only.
    const alert = (await db.doc(`admin_alerts/moderation_p0_${items[0].id}`).get()).data();
    expect(alert).toMatchObject({ type: 'moderation_p0', queueId: items[0].id, emailStatus: 'sent' });
    expect((await db.doc(`notifications/moderation_p0_${items[0].id}_adm1`).get()).exists).toBe(true);
    expect((await db.doc(`notifications/moderation_p0_${items[0].id}_support1`).get()).exists).toBe(false);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0] as any[];
    expect(url).toBe('https://api.resend.com/emails');
    const mail = JSON.parse(init.body);
    expect(mail.to).toEqual(['admin@greengo.test']);
    expect(mail.html).toContain(items[0].id);
    expect(mail.html).not.toMatch(/bob|alice|community:c1|post7/);

    // Shared auto-action from reportingSystem.ts now runs for real reports.
    const warnings = await db.collection('user_warnings').where('userId', '==', 'bob').get();
    expect(warnings.size).toBe(1);
    expect(warnings.docs[0].data().reason).toBe('minorSafety');
  });

  test('chat-user report in Italian maps to harassment / P2', async () => {
    const id = await appChatUserReport('alice', 'bob', 'Molestie o bullismo');
    await fireCreated(onUserReportQueued, 'user_reports', id);
    const items = await queueItems();
    expect(items).toHaveLength(1);
    expect(items[0].data()).toMatchObject({
      reasonCode: 'harassment', priority: 'medium', priorityLevel: 'P2', slaHours: 168,
      contentRef: { type: 'message', id: 'm1', path: 'conversations/conv1/messages/m1' },
    });
    expect((await db.collection('admin_alerts').get()).size).toBe(0);
  });

  test('message report in Portuguese (pt_BR) maps to threats / P1, content kept for moderators', async () => {
    const id = await appMessageReport('alice', 'bob', 'Comportamento ameaçador');
    await fireCreated(onMessageReportQueued, 'message_reports', id);
    const items = await queueItems();
    expect(items).toHaveLength(1);
    expect(items[0].id).toBe(`message_reports__${id}`);
    expect(items[0].data()).toMatchObject({
      itemType: 'messageReport', userId: 'bob', reasonCode: 'threats', priority: 'high', priorityLevel: 'P1',
      slaHours: 48, contentRef: { type: 'message', path: 'conversations/conv9/messages/m9' },
      content: { text: 'SECRET MESSAGE BODY' },
    });
  });

  test('event report (no reason) -> P2 item against the organizer', async () => {
    const id = await appEventReport('alice');
    await fireCreated(onContentReportQueued, 'reports', id);
    const items = await queueItems();
    expect(items).toHaveLength(1);
    expect(items[0].data()).toMatchObject({
      itemType: 'eventReport', userId: 'org1', reasonCode: 'other', priorityLevel: 'P2',
      contentRef: { type: 'event', id: 'ev1', path: 'events/ev1' },
    });
  });

  test('experience + review reports; CSAE words in free-text details escalate to P0', async () => {
    const a = await appExperienceReport('alice', 'scam');
    const b = await appReviewReport('alice');
    const c = await appExperienceReport('carol', 'inappropriate', 'host shares child sexual abuse material');
    for (const id of [a, b, c]) await fireCreated(onContentReportQueued, 'reports', id);
    const byId = Object.fromEntries((await queueItems()).map((d) => [d.data().itemId, d.data()]));
    expect(Object.keys(byId)).toHaveLength(3);
    expect(byId[a]).toMatchObject({ itemType: 'experienceReport', userId: 'host1', reasonCode: 'scam', priorityLevel: 'P2' });
    expect(byId[b]).toMatchObject({ itemType: 'experienceReviewReport', userId: 'author1', reasonCode: 'other' });
    expect(byId[c]).toMatchObject({ reasonCode: 'csae', priority: 'critical', priorityLevel: 'P0' });
    // No Resend config -> alert recorded, email not attempted.
    const alert = (await db.doc(`admin_alerts/moderation_p0_reports__${c}`).get()).data();
    expect(alert?.emailStatus).toBe('not_configured');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  test('re-delivery does not duplicate the item, the alert email or the auto-actions', async () => {
    await db.doc('app_config/resend_settings').set({ apiKey: 're_test' });
    await db.doc('admin_users/adm1').set({ role: 'admin', email: 'admin@greengo.test' });
    await db.doc('app_config/moderation_settings').set({ reportAutoActionsEnabled: true });
    const id = await appProfileReport('alice', 'bob', 'Usuário menor de idade');
    await fireCreated(onUserReportQueued, 'user_reports', id);
    await fireCreated(onUserReportQueued, 'user_reports', id);
    await fireCreated(onUserReportQueued, 'user_reports', id);
    expect(await queueItems()).toHaveLength(1);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect((await db.collection('user_warnings').where('userId', '==', 'bob').get()).size).toBe(1);
  });

  test('reportCountTrigger still counts, alongside the queue trigger', async () => {
    await db.doc('users/bob').set({ reportCount: 0 });
    const id = await appProfileReport('alice', 'bob', 'Spam or scam');
    await fireCreated(onUserReportCreated, 'user_reports', id);
    await fireCreated(onUserReportQueued, 'user_reports', id);
    expect((await db.doc('users/bob').get()).data()?.reportCount).toBe(1);
    expect(await queueItems()).toHaveLength(1);
  });

  test('auto-actions are OFF by default (no settings doc): 10 reports do not restrict', async () => {
    await db.doc('users/carol').set({ accountStatus: 'active' });
    for (let i = 0; i < 9; i++) await appProfileReport(`q${i}`, 'carol', 'Spam or scam');
    const tenth = await appProfileReport('q9', 'carol', 'Spam or scam');
    await fireCreated(onUserReportQueued, 'user_reports', tenth);
    expect((await db.doc('users/carol').get()).data()?.accountStatus).toBe('active');
    expect((await db.doc(`moderation_queue/user_reports__${tenth}`).get()).exists).toBe(true);
  });

  test('10 pending reports auto-restrict the user (shared Point 218 logic); kill switch disables it', async () => {
    await db.doc('users/bob').set({ accountStatus: 'active' });
    await db.doc('app_config/moderation_settings').set({ reportAutoActionsEnabled: true });
    for (let i = 0; i < 9; i++) await appProfileReport(`r${i}`, 'bob', 'Spam or scam');
    const tenth = await appProfileReport('r9', 'bob', 'Spam or scam');
    await fireCreated(onUserReportQueued, 'user_reports', tenth);
    expect((await db.doc('users/bob').get()).data()?.accountStatus).toBe('restricted');
    const blocks = await db.collection('user_blocks').where('blockedUserId', '==', 'bob').get();
    expect(blocks.docs.map((d) => d.data().type)).toEqual(['automatic']);

    await db.doc('app_config/moderation_settings').set({ reportAutoActionsEnabled: false });
    const id = await appProfileReport('x', 'dave', 'Underage user');
    await fireCreated(onUserReportQueued, 'user_reports', id);
    expect((await db.collection('user_warnings').where('userId', '==', 'dave').get()).size).toBe(0);
    expect((await db.doc(`moderation_queue/user_reports__${id}`).get()).exists).toBe(true);
  });

  test('admin-panel createReport (reporterId "admin", own queue item) is not enqueued twice', async () => {
    const ref = await db.collection('reports').add({
      reporterId: 'admin', reportedUserId: 'bob', category: 'spam', description: 'x', status: 'pending',
      priority: 'medium', createdAt: ts(),
    });
    await db.collection('moderation_queue').add({ itemType: 'report', itemId: ref.id, userId: 'bob', status: 'pending' });
    await fireCreated(onContentReportQueued, 'reports', ref.id);
    expect(await queueItems()).toHaveLength(1);
  });

  test('submitReport callable no longer writes its own queue item (trigger owns it): one item total', async () => {
    const res = await (fft.wrap(submitReport) as any)(
      { reportedUserId: 'bob', category: 'harassment', description: 'mean', isAnonymous: true },
      { auth: { uid: 'alice', token: {} } },
    );
    expect(await queueItems()).toHaveLength(0);
    await fireCreated(onUserReportQueued, 'user_reports', res.reportId);
    const items = await queueItems();
    expect(items).toHaveLength(1);
    expect(items[0].data()).toMatchObject({ reasonCode: 'harassment', reporterId: 'anonymous' });
  });
});

// ---------------------------------------------------------------------------
describe('P1-12 reporter feedback on resolution', () => {
  const modCtx = { auth: { uid: 'mod1', token: { moderator: true } } };

  test('takeModerationAction on a message-report item resolves it, updates message_reports, notifies the reporter once', async () => {
    const id = await appMessageReport('alice', 'bob', 'Harassment or bullying');
    await fireCreated(onMessageReportQueued, 'message_reports', id);
    const queueId = queueIdFor('message_reports', id);
    const before = (await db.doc(`moderation_queue/${queueId}`).get()).data();

    const res = await (fft.wrap(takeModerationAction) as any)(
      { queueId, action: 'issueWarning', notes: 'warned' }, modCtx);
    expect(res.success).toBe(true);
    expect((await db.doc(`message_reports/${id}`).get()).data()).toMatchObject({ status: 'resolved', action: 'issueWarning' });
    expect((await db.doc(`moderation_queue/${queueId}`).get()).data()?.status).toBe('resolved');

    await fireUpdated(queueId, before);
    await fireUpdated(queueId, before); // re-delivery
    const notifs = await db.collection('notifications').where('userId', '==', 'alice').get();
    expect(notifs.size).toBe(1);
    const n = notifs.docs[0];
    expect(n.id).toBe(feedbackNotificationId(queueId));
    expect(n.data()).toMatchObject({
      type: 'system', isRead: false, title: 'Your report was reviewed',
      data: { action: 'report_reviewed', outcome: 'action_taken', reportId: id },
    });
    expect(JSON.stringify(n.data())).not.toMatch(/bob|issueWarning|warned/);

    // A later edit of an already-resolved item does not notify again.
    const resolved = (await db.doc(`moderation_queue/${queueId}`).get()).data();
    await db.doc(`moderation_queue/${queueId}`).update({ moderatorNotes: 'edited' });
    await fireUpdated(queueId, resolved);
    expect((await db.collection('notifications').where('userId', '==', 'alice').get()).size).toBe(1);
  });

  test('admin-panel path (status "completed", resolvedAction "dismiss") -> localized "no violation"', async () => {
    await db.doc('users/alice').set({ preferredLanguage: 'it' });
    const id = await appProfileReport('alice', 'bob', 'Spam o truffa');
    await fireCreated(onUserReportQueued, 'user_reports', id);
    const queueId = queueIdFor('user_reports', id);
    const before = (await db.doc(`moderation_queue/${queueId}`).get()).data();
    await db.doc(`moderation_queue/${queueId}`).update({ status: 'inReview', assignedTo: 'mod1' });
    const inReview = (await db.doc(`moderation_queue/${queueId}`).get()).data();
    await fireUpdated(queueId, before); // pending -> inReview: not final
    expect((await db.collection('notifications').get()).size).toBe(0);

    await db.doc(`moderation_queue/${queueId}`).update({ status: 'completed', resolvedAction: 'dismiss', resolvedReason: 'ok' });
    await fireUpdated(queueId, inReview);
    const n = (await db.doc(`notifications/${feedbackNotificationId(queueId)}`).get()).data();
    expect(n).toMatchObject({ userId: 'alice', title: 'La tua segnalazione è stata esaminata', data: { outcome: 'no_violation' } });
  });

  test('anonymous / legacy items never notify', async () => {
    await db.doc('moderation_queue/legacy1').set({ status: 'pending', metadata: { reporterId: 'alice' } });
    const before = (await db.doc('moderation_queue/legacy1').get()).data();
    await db.doc('moderation_queue/legacy1').update({ status: 'resolved', action: 'banUser' });
    await fireUpdated('legacy1', before);
    expect((await db.collection('notifications').get()).size).toBe(0);
  });
});
