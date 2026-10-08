/**
 * P3-5 security-event alert triggers: fire once per event, carry no personal
 * data, and cap fraud-flag bursts. Emulator only (Firestore).
 */
import functionsTest from 'firebase-functions-test';

const fft = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
import {
  alertOnAdminAudit, alertOnAdminUsersChange, alertOnFraudFlag, alertOnModerationP0,
} from '../../src/security/securityEventAlerts';

import { db } from '../../src/shared/utils';
const fetchMock = jest.fn(async (_url: any, _init?: any) => ({ ok: true, status: 200, text: async () => '{}' }));
(global as any).fetch = fetchMock;
const FULL_UID = 'Zq9xUserUidThatMustNotLeak123';
const EMAIL = 'victim.person@example.com';

async function clear() {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  if (!/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) throw new Error('not an emulator');
  await new Promise<void>((res, rej) => {
    const r = require('http').request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE',
      path: `/emulator/v1/projects/${process.env.GCLOUD_PROJECT}/databases/(default)/documents` }, (x: any) => { x.resume(); x.on('end', res); });
    r.on('error', rej); r.end();
  });
}
const created = (fn: any, path: string, data: any, params: any) =>
  fn.run({ data: fft.firestore.makeDocumentSnapshot(data, path), params });
const written = (fn: any, path: string, before: any, after: any, params: any) =>
  fn.run({
    data: {
      before: before ? fft.firestore.makeDocumentSnapshot(before, path) : { data: () => undefined, exists: false },
      after: after ? fft.firestore.makeDocumentSnapshot(after, path) : { data: () => undefined, exists: false },
    },
    params,
  });
const bodies = () => fetchMock.mock.calls.map((c) => JSON.parse((c[1] as any).body));

beforeEach(async () => {
  await clear();
  fetchMock.mockClear();
  await db.doc('app_config/resend_settings').set({ apiKey: 're_test', senderEmail: 'alerts@greengo.test' });
});
afterAll(() => fft.cleanup());

test('ID-document view by an admin -> one SENSITIVE alert, no personal data', async () => {
  await created(alertOnAdminAudit, 'admin_audit_log/a1',
    { adminId: 'adminUid999999', adminEmail: EMAIL, action: 'view_id_document', targetType: 'user', targetId: FULL_UID }, { id: 'a1' });
  expect(fetchMock).toHaveBeenCalledTimes(1);
  const b = bodies()[0];
  expect(b.subject).toContain('SENSITIVE admin action: view_id_document');
  expect(b.to).toEqual(['info@greengochat.com', 'greengochat.com@gmail.com']);
  const all = JSON.stringify(b);
  expect(all).not.toContain(FULL_UID);
  expect(all).not.toContain(EMAIL);
});

test('admin role change alerts; unrelated admin_users edits do not', async () => {
  await written(alertOnAdminUsersChange, 'admin_users/u1', null, { role: 'superAdmin' }, { uid: 'u1' });
  await written(alertOnAdminUsersChange, 'admin_users/u1', { role: 'support' }, { role: 'superAdmin' }, { uid: 'u1' });
  await written(alertOnAdminUsersChange, 'admin_users/u1', { role: 'superAdmin', lastLogin: 1 }, { role: 'superAdmin', lastLogin: 2 }, { uid: 'u1' });
  expect(fetchMock).toHaveBeenCalledTimes(2);
  expect(bodies()[1].subject).toContain('support -> superAdmin');
});

test('fraud flags alert, then cap at 30/hour with one burst notice', async () => {
  for (let i = 0; i < 33; i++) {
    await created(alertOnFraudFlag, `fraud_flags/f${i}`, { type: 'purchase_refunded', userId: FULL_UID }, { id: `f${i}` });
  }
  const subjects = bodies().map((b) => b.subject);
  expect(subjects.filter((s) => s.includes('fraud flag: purchase_refunded'))).toHaveLength(30);
  expect(subjects.filter((s) => s.includes('BURST'))).toHaveLength(1);
  expect(JSON.stringify(bodies())).not.toContain(FULL_UID);
});

test('P0 child-safety admin alert is forwarded; other admin_alerts are not', async () => {
  await created(alertOnModerationP0, 'admin_alerts/x1', { type: 'moderation_p0', queueId: 'user_reports__abcdefgh' }, { id: 'x1' });
  await created(alertOnModerationP0, 'admin_alerts/x2', { type: 'something_else' }, { id: 'x2' });
  expect(fetchMock).toHaveBeenCalledTimes(1);
  expect(bodies()[0].subject).toContain('P0 child-safety');
});

test('no Resend key -> no email, no crash', async () => {
  await db.doc('app_config/resend_settings').delete();
  await created(alertOnAdminAudit, 'admin_audit_log/a2', { action: 'delete_user', adminId: 'x', targetId: 'y' }, { id: 'a2' });
  expect(fetchMock).not.toHaveBeenCalled();
});
