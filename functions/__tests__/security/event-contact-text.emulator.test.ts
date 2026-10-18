/**
 * Owner rule (2026-10-12): no e-mail address or phone number in a community
 * event's own text (title, description, languagePairs, locationName).
 * firestore.rules eventTextOk() - the app refuses first
 * (ContactInfoDetector.hasEmailOrPhone in CreateEventScreen).
 * A field that is NOT changed never blocks an unrelated edit of an older event.
 *
 *   firebase emulators:exec --only firestore --project test-project \
 *     "npx jest --config jest.security.config.js event-contact-text"
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
  organizerId: ORG,
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

describe('create', () => {
  test('clean event text is allowed', async () => {
    expect(await clientWrite(ORG, 'events/e1', baseEvent())).toBe(OK);
  });

  const BAD: Array<[string, string]> = [
    ['title', 'Picnic - info maria@gmail.com'],
    ['description', 'Questions?\nCall +55 (11) 98765-4321'],
    ['description', 'whatsapp 11987654321'],
    ['locationName', 'Ask at 06 1234 5678'],
    ['languagePairs', 'PT-EN write to a.b@c.io'],
  ];
  test.each(BAD)('%s with contact info is refused', async (field, text) => {
    expect(await clientWrite(ORG, 'events/e1', { ...baseEvent(), [field]: text })).toBe(DENIED);
  });
});

describe('update', () => {
  beforeEach(async () => {
    await db.doc('events/e1').set({ ...baseEvent(), startDate: TS.fromDate(future(DAY)),
      endDate: TS.fromDate(future(DAY + 3 * 3600 * 1000)), coOrganizerIds: [CO] });
  });

  test('organizer cannot add a phone to the description', async () => {
    expect(await clientWrite(ORG, 'events/e1', { description: 'call 11987654321' }, ['description'])).toBe(DENIED);
  });

  test('co-organizer cannot add an e-mail to the title', async () => {
    expect(await clientWrite(CO, 'events/e1', { title: 'mail me x@y.com' }, ['title'])).toBe(DENIED);
  });

  test('a clean edit is allowed', async () => {
    expect(await clientWrite(ORG, 'events/e1', { title: 'Big picnic' }, ['title'])).toBe(OK);
  });

  test('older event with contact text: unrelated edits still work', async () => {
    await db.doc('events/e1').update({ description: 'legacy: call 11987654321' });
    expect(await clientWrite(ORG, 'events/e1', { title: 'Renamed' }, ['title'])).toBe(OK);
    // ...but re-saving NEW contact text is refused.
    expect(await clientWrite(ORG, 'events/e1', { description: 'now x@y.com' }, ['description'])).toBe(DENIED);
  });

  test('others bumping viewCount are unaffected', async () => {
    await db.doc('events/e1').update({ description: 'legacy: call 11987654321', viewCount: 0 });
    expect(await clientWrite('someone', 'events/e1', { viewCount: 1 }, ['viewCount'])).toBe(OK);
  });
});
