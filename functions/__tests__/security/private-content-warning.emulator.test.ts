/**
 * Private-content warning acknowledgement (proof) against the emulators:
 *  - acknowledgePrivateContentWarning: auth required, input validation,
 *    writes an append-only record with a SERVER timestamp, request IP / user
 *    agent and the sha256 of the displayed text; bounded per version
 *  - Firestore rules (run once with firestore.additive.rules, which
 *    production runs, and once with firestore.rules): the owner reads their
 *    own records; nobody (owner included) can create, alter or delete one;
 *    other users cannot read them.
 */
import functionsTest from 'firebase-functions-test';
import * as admin from 'firebase-admin';
import * as http from 'http';

const fft = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
import {
  acknowledgePrivateContentWarning,
  warningTextHash,
  MAX_ACKS_PER_VERSION,
} from '../../src/legal/privateContentWarning';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
const db = admin.firestore();
const OWNER = 'owner01';
const STRANGER = 'stranger01';
const TEXT = 'Private photos are shared with you personally. Taking screenshots or screen recordings, '
  + 'saving, sharing, forwarding or publishing them without consent is forbidden.';

async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  if (!/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) throw new Error('Refusing: not a local emulator');
  await new Promise<void>((resolve, reject) => {
    const req = http.request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE',
      path: `/emulator/v1/projects/${PROJECT}/databases/(default)/documents` }, (res) => { res.resume(); res.on('end', resolve); });
    req.on('error', reject);
    req.end();
  });
}

const valid = (over: Record<string, unknown> = {}) => ({
  warningVersion: 'pcw-1', text: TEXT, locale: 'pt_BR', platform: 'android', appVersion: '4.6.0+190', ...over,
});
const rawRequest = { ip: '203.0.113.7', headers: { 'user-agent': 'GreenGo/4.6.0 (Android 15)' } };
const call = (data: any, uid?: string, raw: any = rawRequest) =>
  (fft.wrap(acknowledgePrivateContentWarning) as any)({ data, auth: uid ? { uid, token: {} } : undefined, rawRequest: raw });

async function expectCode(p: Promise<unknown>, code: string, message?: RegExp) {
  await expect(p).rejects.toMatchObject({ code });
  if (message) await expect(p).rejects.toThrow(message);
}

// ---- REST as a real client (rules apply) ---------------------------------
function idToken(uid: string): string {
  const b = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, firebase: { sign_in_provider: 'password' } })}.`;
}
const base = () => `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${PROJECT}/databases/(default)/documents`;
async function rest(uid: string, method: string, path: string, body?: any): Promise<number> {
  const res = await fetch(`${base()}/${path}`, {
    method,
    headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  await res.text();
  return res.status;
}
/** The query the app runs on a new device. */
async function queryOwn(uid: string, ownerUid: string): Promise<number> {
  const res = await fetch(`${base()}/legal_acknowledgements/${ownerUid}:runQuery`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ structuredQuery: {
      from: [{ collectionId: 'items' }],
      where: { fieldFilter: { field: { fieldPath: 'warningVersion' }, op: 'EQUAL', value: { stringValue: 'pcw-1' } } },
      limit: 1,
    } }),
  });
  const json = await res.json();
  if (res.status !== 200) return res.status;
  if (Array.isArray(json) && json.some((r: any) => r.error)) return 403;
  return 200;
}
const fields = { warningVersion: { stringValue: 'pcw-1' }, acceptedAt: { timestampValue: '2020-01-01T00:00:00Z' } };

beforeEach(clearAll);
afterAll(() => fft.cleanup());

describe('acknowledgePrivateContentWarning', () => {
  test('requires sign-in', async () => {
    await expectCode(call(valid()), 'unauthenticated');
  });

  test('rejects unknown versions, missing / short text and bad locales', async () => {
    await expectCode(call(valid({ warningVersion: 'pcw-0' }), OWNER), 'invalid-argument', /invalid_warning_version/);
    await expectCode(call(valid({ warningVersion: undefined }), OWNER), 'invalid-argument', /invalid_warning_version/);
    await expectCode(call(valid({ text: 'ok' }), OWNER), 'invalid-argument', /invalid_text/);
    await expectCode(call(valid({ text: 'x'.repeat(20001) }), OWNER), 'invalid-argument', /invalid_text/);
    await expectCode(call(valid({ locale: '../../etc' }), OWNER), 'invalid-argument', /invalid_locale/);
    const all = await db.collection(`legal_acknowledgements/${OWNER}/items`).get();
    expect(all.size).toBe(0);
  });

  test('writes the proof record with a server timestamp, request IP / UA and the text hash', async () => {
    const before = Date.now();
    const r = await call(valid(), OWNER);
    expect(r).toMatchObject({ ok: true, warningVersion: 'pcw-1', recorded: true });
    const snap = await db.doc(`legal_acknowledgements/${OWNER}/items/${r.ackId}`).get();
    const d = snap.data()!;
    expect(d).toMatchObject({
      kind: 'private_content_warning', uid: OWNER, warningVersion: 'pcw-1', termsVersion: '5.1.0', locale: 'pt_BR', platform: 'android',
      appVersion: '4.6.0+190', ip: '203.0.113.7', userAgent: 'GreenGo/4.6.0 (Android 15)', textLength: TEXT.length,
    });
    expect(d.textHash).toBe(warningTextHash('pcw-1', TEXT));
    expect(d.textHash).toMatch(/^[0-9a-f]{64}$/);
    expect(d.acceptedAt).toBeInstanceOf(admin.firestore.Timestamp);
    expect(d.acceptedAt.toMillis()).toBeGreaterThanOrEqual(before - 5000);
    // A client-supplied "acceptedAt" or "uid" is never trusted.
    const r2 = await call(valid({ acceptedAt: '1999-01-01', uid: STRANGER, platform: 'evil' }), OWNER, null);
    const d2 = (await db.doc(`legal_acknowledgements/${OWNER}/items/${r2.ackId}`).get()).data()!;
    expect(d2.uid).toBe(OWNER);
    expect(d2.platform).toBe('unknown');
    expect(d2.acceptedAt).toBeInstanceOf(admin.firestore.Timestamp);
    expect(d2.ip).toBeNull();
    // Different text -> different hash (the hash pins the exact wording).
    expect(warningTextHash('pcw-1', TEXT + '.')).not.toBe(d.textHash);
  });

  test('bounded per user and version', async () => {
    const items = db.collection(`legal_acknowledgements/${OWNER}/items`);
    const batch = db.batch();
    for (let i = 0; i < MAX_ACKS_PER_VERSION; i++) batch.set(items.doc(), { warningVersion: 'pcw-1' });
    await batch.commit();
    const r = await call(valid(), OWNER);
    expect(r).toMatchObject({ ok: true, recorded: false });
    expect((await items.get()).size).toBe(MAX_ACKS_PER_VERSION);
  });
});

describe('Firestore rules: legal_acknowledgements', () => {
  let ackId: string;
  beforeEach(async () => {
    ackId = (await call(valid(), OWNER)).ackId;
  });

  test('owner can read their own records (get + the app query)', async () => {
    expect(await rest(OWNER, 'GET', `legal_acknowledgements/${OWNER}/items/${ackId}`)).toBe(200);
    expect(await queryOwn(OWNER, OWNER)).toBe(200);
  });

  test('other users cannot read them', async () => {
    expect(await rest(STRANGER, 'GET', `legal_acknowledgements/${OWNER}/items/${ackId}`)).toBe(403);
    expect(await queryOwn(STRANGER, OWNER)).toBe(403);
    expect(await rest(STRANGER, 'GET', `legal_acknowledgements/${OWNER}`)).toBe(403);
  });

  test('no client can create, alter or delete a record (owner included)', async () => {
    // create
    expect(await rest(OWNER, 'POST', `legal_acknowledgements/${OWNER}/items`, { fields })).toBe(403);
    expect(await rest(OWNER, 'PATCH', `legal_acknowledgements/${OWNER}/items/forged`, { fields })).toBe(403);
    expect(await rest(OWNER, 'PATCH', `legal_acknowledgements/${OWNER}`, { fields })).toBe(403);
    expect(await rest(STRANGER, 'PATCH', `legal_acknowledgements/${STRANGER}/items/x`, { fields })).toBe(403);
    // alter
    expect(await rest(OWNER, 'PATCH', `legal_acknowledgements/${OWNER}/items/${ackId}?updateMask.fieldPaths=acceptedAt`,
      { fields: { acceptedAt: fields.acceptedAt } })).toBe(403);
    expect(await rest(STRANGER, 'PATCH', `legal_acknowledgements/${OWNER}/items/${ackId}`, { fields })).toBe(403);
    // delete
    expect(await rest(OWNER, 'DELETE', `legal_acknowledgements/${OWNER}/items/${ackId}`)).toBe(403);
    expect(await rest(STRANGER, 'DELETE', `legal_acknowledgements/${OWNER}/items/${ackId}`)).toBe(403);
    // still there, unchanged
    const d = (await db.doc(`legal_acknowledgements/${OWNER}/items/${ackId}`).get()).data()!;
    expect(d.warningVersion).toBe('pcw-1');
    expect(d.acceptedAt.toDate().getUTCFullYear()).toBeGreaterThan(2020);
    expect(await db.doc(`legal_acknowledgements/${OWNER}/items/forged`).get().then((s) => s.exists)).toBe(false);
  });

});
