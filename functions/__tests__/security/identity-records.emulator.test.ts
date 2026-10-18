/**
 * Optional ID-document details (safety/identityRecords.ts) + the verified
 * phone index: identity_records, identity_access_log, identity_rate_limits
 * and phone_index are SERVER ONLY. No client - owner, admin-panel claim or
 * profile admin - may read, list or write them. The callables round trip
 * (submit -> confirm -> reveal with audit) runs against the real emulator.
 *
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "npx jest --config jest.security.config.js identity-records"
 *
 * Run against BOTH rule files (firestore.rules and firestore.additive.rules).
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import { randomBytes } from 'crypto';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
const fft = functionsTest({ projectId: PROJECT });
const db = admin.firestore();

process.env.ID_DATA_KEY = randomBytes(32).toString('base64'); // test-only key

// eslint-disable-next-line @typescript-eslint/no-var-requires
const ir = (): any => require('../../src/safety/identityRecords');

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
function idToken(uid: string, claims: Record<string, any> = {}): string {
  const b = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, firebase: { sign_in_provider: 'password' }, ...claims })}.`;
}
const base = () => `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${PROJECT}/databases/(default)/documents`;
async function clientGet(uid: string, path: string, claims?: Record<string, any>): Promise<number> {
  const res = await fetch(`${base()}/${path}`, { headers: { Authorization: `Bearer ${idToken(uid, claims)}` } });
  await res.text();
  return res.status;
}
async function clientWrite(uid: string, path: string, claims?: Record<string, any>): Promise<number> {
  const res = await fetch(`${base()}/${path}`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${idToken(uid, claims)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: { uid: { stringValue: uid }, status: { stringValue: 'verified' } } }),
  });
  await res.text();
  return res.status;
}
async function clientDelete(uid: string, path: string, claims?: Record<string, any>): Promise<number> {
  const res = await fetch(`${base()}/${path}`, { method: 'DELETE', headers: { Authorization: `Bearer ${idToken(uid, claims)}` } });
  await res.text();
  return res.status;
}
const call = (fn: any, data: any, uid: string) => (fft.wrap(fn) as any)({ data, auth: { uid, token: {} } });

const ADMIN_CLAIMS = { admin: true, isAdmin: true, adminRole: 'superAdmin', role: 'superAdmin' };
const FIELDS = {
  firstName: 'Maria', surname: 'Silva', dateOfBirth: '1990-05-17',
  docType: 'id_card', issuingCountry: 'BR', docNumber: '123456789',
};

beforeEach(async () => {
  await clearAll();
  await db.doc('admin_users/admin1').set({ role: 'superAdmin', isActive: true });
  await db.doc('admin_users/mod1').set({ role: 'moderator', isActive: true });
  await db.doc('profiles_private/u1').set({ email: 'u1@example.com' });
  await db.doc('identity_records/u1').set({ uid: 'u1', status: 'verified' });
  await db.doc('identity_access_log/l1').set({ subjectUid: 'u1' });
  await db.doc('identity_rate_limits/submit_u1').set({ count: 1 });
  await db.doc('phone_index/abc').set({ uid: 'u1' });
});
afterAll(() => fft.cleanup());

const PATHS = ['identity_records/u1', 'identity_access_log/l1', 'identity_rate_limits/submit_u1', 'phone_index/abc'];

describe('rules: server-only identity collections', () => {
  test.each(PATHS)('%s: owner cannot read, write or delete', async (path) => {
    expect(await clientGet('u1', path)).toBe(403);
    expect(await clientWrite('u1', path)).toBe(403);
    expect(await clientDelete('u1', path)).toBe(403);
  });

  test.each(PATHS)('%s: an admin-claim client cannot read, write or delete', async (path) => {
    expect(await clientGet('admin1', path, ADMIN_CLAIMS)).toBe(403);
    expect(await clientWrite('admin1', path, ADMIN_CLAIMS)).toBe(403);
    expect(await clientDelete('admin1', path, ADMIN_CLAIMS)).toBe(403);
  });

  test('lists are refused too', async () => {
    for (const c of ['identity_records', 'identity_access_log', 'phone_index']) {
      expect(await clientGet('admin1', c, ADMIN_CLAIMS)).toBe(403);
    }
  });

  test('legacy: the owner still reads their profiles_private doc', async () => {
    expect(await clientGet('u1', 'profiles_private/u1')).toBe(200);
  });
});

describe('callables against the emulator', () => {
  test('submit -> confirm -> reveal; audit first; no plaintext stored', async () => {
    await db.doc('identity_records/u2').delete();
    await call(ir().submitIdentityDetails, { source: 'registration', fields: FIELDS }, 'u2');
    const pending = (await db.doc('identity_records/u2').get()).data()!;
    expect(pending.status).toBe('pending');
    expect(JSON.stringify(pending)).not.toMatch(/Maria|Silva|123456789/);

    await call(ir().adminConfirmIdentityDetails, { uid: 'u2', decision: 'approve' }, 'mod1');
    const rec = (await db.doc('identity_records/u2').get()).data()!;
    expect(rec).toMatchObject({ status: 'verified', docType: 'id_card', issuingCountry: 'BR', reviewedBy: 'mod1' });

    // A moderator may not reveal.
    await expect(call(ir().adminRevealIdentityRecord,
      { uid: 'u2', legalBasis: 'court_order', reference: 'Proc. 123/2026' }, 'mod1')).rejects.toThrow();
    expect((await db.collection('identity_access_log').where('subjectUid', '==', 'u2').get()).size).toBe(0);

    const out = await call(ir().adminRevealIdentityRecord,
      { uid: 'u2', legalBasis: 'court_order', reference: 'Proc. 123/2026' }, 'admin1');
    expect(out.fields.surname).toBe('Silva');
    const logs = await db.collection('identity_access_log').where('subjectUid', '==', 'u2').get();
    expect(logs.size).toBe(1);
    expect(logs.docs[0].data()).toMatchObject({ adminUid: 'admin1', legalBasis: 'court_order', reference: 'Proc. 123/2026' });
  });
});
