/**
 * Owner rule (2026-10-26): every event has a real place on the map
 * (firestore.rules eventPlaceOk(): latitude / longitude, not 0,0). The app
 * refuses first (CreateEventScreen geocodes or map-picks before saving).
 * An edit that leaves the place exactly as it was never blocks an unrelated
 * change of an older event without coordinates.
 *
 *   firebase emulators:exec --only firestore --project test-project  *     "npx jest --config jest.security.config.js event-place"
 */
import * as admin from 'firebase-admin';
import * as http from 'http';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const DAY = 24 * 3600 * 1000;
const future = (ms: number) => new Date(Date.now() + ms);

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
/** A client write (PATCH = create or update) as `uid`, through the rules. */
async function clientWrite(uid: string, path: string, data: Record<string, any>, mask?: string[]): Promise<number> {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  const q = mask ? '?' + mask.map((m) => `updateMask.fieldPaths=${encodeURIComponent(m)}`).join('&') : '';
  const res = await fetch(`http://${host}/v1/projects/${PROJECT}/databases/(default)/documents/${path}${q}`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, toValue(v)])) }),
  });
  await res.text();
  return res.status;
}

const ORG = 'org01';
const CO = 'co01';
const OK = 200;
const DENIED = 403;

const baseEvent = () => ({
  organizerId: ORG, latitude: 41.15, longitude: -8.61,
  title: 'Picnic in the park',
  description: 'Bring food to share. Meet at 18:30 on 12/10/2026, gate 3.',
  locationName: 'Parque Ibirapuera',
  languagePairs: 'PT-EN',
  price: 0,
  status: 'published',
  startDate: future(DAY),
  endDate: future(DAY + 3 * 3600 * 1000),
});

beforeEach(async () => {
  await clearAll();
  // Creating events needs a plan (owner rule 2026-10-13): the organizer has Base.
  await db.doc(`profiles/${ORG}`).set({ displayName: 'Org', membershipTier: 'FREE', isAgeVerified: true,
    hasBaseMembership: true, baseMembershipEndDate: future(365 * DAY) });
  await db.doc(`profiles/${CO}`).set({ displayName: 'Co', membershipTier: 'FREE', isAgeVerified: true });
});

const noPlace = () => {
  const { latitude: _a, longitude: _b, ...rest } = baseEvent() as Record<string, any>;
  return rest;
};

describe('create', () => {
  test('an event with coordinates is allowed', async () => {
    expect(await clientWrite(ORG, 'events/e1', baseEvent())).toBe(OK);
  });
  test('an event without coordinates is refused', async () => {
    expect(await clientWrite(ORG, 'events/e1', noPlace())).toBe(DENIED);
  });
  test.each([
    ['0,0', { latitude: 0, longitude: 0 }],
    ['latitude out of range', { latitude: 95, longitude: 10 }],
    ['longitude out of range', { latitude: 10, longitude: 190 }],
    ['text instead of numbers', { latitude: '41.15', longitude: '-8.61' }],
    ['null', { latitude: null, longitude: null }],
  ])('coordinates %s are refused', async (_label, coords) => {
    expect(await clientWrite(ORG, 'events/e1', { ...baseEvent(), ...coords })).toBe(DENIED);
  });
});

describe('update', () => {
  test('an older event without coordinates stays editable while its place is unchanged', async () => {
    await db.doc('events/old').set(noPlace());
    expect(await clientWrite(ORG, 'events/old', { ...noPlace(), title: 'Picnic, new title' })).toBe(OK);
  });
  test('changing the place of an older event needs coordinates', async () => {
    await db.doc('events/old').set(noPlace());
    expect(await clientWrite(ORG, 'events/old', { ...noPlace(), locationName: 'Parque Villa-Lobos' })).toBe(DENIED);
    expect(await clientWrite(ORG, 'events/old',
      { ...noPlace(), locationName: 'Parque Villa-Lobos', latitude: -23.55, longitude: -46.72 })).toBe(OK);
  });
  test('removing the coordinates of an event is refused', async () => {
    await db.doc('events/e1').set(baseEvent());
    expect(await clientWrite(ORG, 'events/e1', noPlace())).toBe(DENIED);
  });
});
