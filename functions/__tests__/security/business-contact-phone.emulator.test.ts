/**
 * Optional business contact number (owner rule 2026-10-17):
 *
 *   profiles_private/{uid}.businessContactPhone   the number (owner only),
 *       E.164 '^\+[1-9][0-9]{6,14}$', any country, landline allowed;
 *   profiles/{uid}.businessContactPhone           public mirror, allowed ONLY
 *       while profiles/{uid}.showBusinessPhone == true;
 *   profiles/{uid}.showBusinessPhone              bool.
 * Rules: businessContactPhoneOk() / privateProfileShapeOk() in
 * firestore.additive.rules AND firestore.rules.
 *
 *   firebase emulators:exec --only firestore,auth --project test-project \
 *     "npx jest --config jest.security.config.js business-contact-phone"
 */
import * as admin from 'firebase-admin';
import * as http from 'http';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const DAY = 24 * 3600 * 1000;

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
function idToken(uid: string): string {
  const b = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, phone_number: '+351910000000', firebase: { sign_in_provider: 'password' } })}.`;
}
function toValue(v: any): any {
  if (v === null) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, toValue(x)])) } };
}
/** A client PATCH as `uid` (rules apply), masked to `mask`. */
async function clientWrite(uid: string, path: string, data: Record<string, any>, mask: string[]): Promise<number> {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  const q = '?' + mask.map((m) => `updateMask.fieldPaths=${encodeURIComponent(m)}`).join('&');
  const res = await fetch(`http://${host}/v1/projects/${PROJECT}/databases/(default)/documents/${path}${q}`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, toValue(v)])) }),
  });
  await res.text();
  return res.status;
}
async function clientRead(uid: string, path: string): Promise<number> {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  const res = await fetch(`http://${host}/v1/projects/${PROJECT}/databases/(default)/documents/${path}`, {
    headers: { Authorization: `Bearer ${idToken(uid)}` },
  });
  await res.text();
  return res.status;
}

const BIZ = 'bizphone01';
const OTHER = 'other01';
const FIELDS = ['businessContactPhone', 'showBusinessPhone'];

beforeEach(async () => {
  await clearAll();
  const future = TS.fromMillis(Date.now() + 365 * DAY);
  await db.doc(`profiles/${BIZ}`).set({
    displayName: 'Biz', isBusiness: true, membershipTier: 'SILVER', membershipEndDate: future,
  });
  await db.doc(`profiles/${OTHER}`).set({ displayName: 'Other' });
});

describe('private business contact number', () => {
  test('owner stores a valid number (any country, landline) privately', async () => {
    expect(await clientWrite(BIZ, `profiles_private/${BIZ}`, { businessContactPhone: '+390212345678' }, ['businessContactPhone'])).toBe(200);
    expect(await clientWrite(BIZ, `profiles_private/${BIZ}`, { businessContactPhone: '+912212345678' }, ['businessContactPhone'])).toBe(200);
    expect(await clientWrite(BIZ, `profiles_private/${BIZ}`, { businessContactPhone: null }, ['businessContactPhone'])).toBe(200);
  });

  test('invalid formats are rejected', async () => {
    for (const bad of ['0212345678', '+0212345678', '+12345', '+1234567890123456', '+39 02 1234', 'call me']) {
      expect(await clientWrite(BIZ, `profiles_private/${BIZ}`, { businessContactPhone: bad }, ['businessContactPhone'])).toBe(403);
    }
    expect(await clientWrite(BIZ, `profiles_private/${BIZ}`, { businessContactPhone: 390212345678 }, ['businessContactPhone'])).toBe(403);
  });

  test('another user can neither write nor read it', async () => {
    expect(await clientWrite(OTHER, `profiles_private/${BIZ}`, { businessContactPhone: '+390212345678' }, ['businessContactPhone'])).toBe(403);
    await db.doc(`profiles_private/${BIZ}`).set({ businessContactPhone: '+390212345678' });
    expect(await clientRead(OTHER, `profiles_private/${BIZ}`)).toBe(403);
  });
});

describe('public storefront mirror', () => {
  test('allowed only with showBusinessPhone == true', async () => {
    expect(await clientWrite(BIZ, `profiles/${BIZ}`, { businessContactPhone: '+390212345678', showBusinessPhone: true }, FIELDS)).toBe(200);
    // Switch off while keeping the mirror: rejected; off + cleared: allowed.
    expect(await clientWrite(BIZ, `profiles/${BIZ}`, { businessContactPhone: '+390212345678', showBusinessPhone: false }, FIELDS)).toBe(403);
    expect(await clientWrite(BIZ, `profiles/${BIZ}`, { businessContactPhone: null, showBusinessPhone: false }, FIELDS)).toBe(200);
  });

  test('mirror without the switch is rejected', async () => {
    expect(await clientWrite(BIZ, `profiles/${BIZ}`, { businessContactPhone: '+390212345678' }, ['businessContactPhone'])).toBe(403);
  });

  test('invalid public format / non-bool switch rejected', async () => {
    expect(await clientWrite(BIZ, `profiles/${BIZ}`, { businessContactPhone: '02 1234 5678', showBusinessPhone: true }, FIELDS)).toBe(403);
    expect(await clientWrite(BIZ, `profiles/${BIZ}`, { showBusinessPhone: 'yes' }, ['showBusinessPhone'])).toBe(403);
  });

  test('another user cannot set it on someone else', async () => {
    expect(await clientWrite(OTHER, `profiles/${BIZ}`, { businessContactPhone: '+390212345678', showBusinessPhone: true }, FIELDS)).toBe(403);
  });

  test('unrelated profile edits are unaffected', async () => {
    expect(await clientWrite(BIZ, `profiles/${BIZ}`, { displayName: 'Biz 2' }, ['displayName'])).toBe(200);
  });
});
