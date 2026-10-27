/**
 * Mandatory verified phone (owner rule 2026-10-17), against the emulator.
 * Run against BOTH rule files (firestore.rules and firestore.additive.rules):
 *
 *   NODE_TLS_REJECT_UNAUTHORIZED=0 firebase emulators:exec --config <cfg> \
 *     --only firestore,auth,storage --project test-project \
 *     "cd functions && npx jest --config jest.security.config.js -i phone-verification"
 *
 * Owner decision 2026-10-17 (final): ONLY accounts created on/after 16 Oct
 * 2026 need the phone. Rules: phoneOk() = phone_number claim, or no
 * server-only marker phone_required/{uid} (written for new accounts by
 * onAuthUserCreatedPhoneRequired). Callables: the Auth creation time.
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
const fft = functionsTest({ projectId: PROJECT });

import * as tp from '../../src/ticket_payments';
import { createBooking } from '../../src/experience_bookings/functions';
import { createUserExperience } from '../../src/user_experiences/createUserExperience';
import { checkPhoneAllowed, recordVerifiedPhone, retirePhoneIndexForDeletion } from '../../src/safety/phoneVerification';
import { phoneHash } from '../../src/safety/phoneIndexLogic';

const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const DAY = 24 * 3600 * 1000;
const future = (ms = 30 * DAY) => TS.fromMillis(Date.now() + ms);
const PHONE = '+351910000000';

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
function idToken(uid: string, phone: string | null): string {
  const b = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const claims: Record<string, any> = { iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now,
    user_id: uid, sub: uid, iat: now, exp: now + 3600, firebase: { sign_in_provider: 'password' } };
  if (phone) claims.phone_number = phone;
  return `${b({ alg: 'none', typ: 'JWT' })}.${b(claims)}.`;
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
async function clientWrite(uid: string, phone: string | null, path: string, data: Record<string, any>, mask?: string[]): Promise<number> {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  const q = mask ? '?' + mask.map((m) => `updateMask.fieldPaths=${encodeURIComponent(m)}`).join('&') : '';
  const res = await fetch(`http://${host}/v1/projects/${PROJECT}/databases/(default)/documents/${path}${q}`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${idToken(uid, phone)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, toValue(v)])) }),
  });
  await res.text();
  return res.status;
}
async function clientGet(uid: string, path: string): Promise<number> {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  const res = await fetch(`http://${host}/v1/projects/${PROJECT}/databases/(default)/documents/${path}`, {
    headers: { Authorization: `Bearer ${idToken(uid, PHONE)}` },
  });
  await res.text();
  return res.status;
}
const call = (fn: any, data: any, uid: string, token: Record<string, any>) =>
  (fft.wrap(fn) as any)({ data, auth: { uid, token } });
async function outcome(p: Promise<any>): Promise<string> {
  try { await p; return 'ok'; } catch (e: any) { return e.details?.code ?? e.message ?? String(e); }
}
async function ensureAuthUser(uid: string, phoneNumber?: string) {
  try { await admin.auth().deleteUser(uid); } catch { /* none */ }
  await admin.auth().createUser({ uid, ...(phoneNumber ? { phoneNumber } : {}) });
}

const BASE = 'phbase01';
beforeEach(async () => {
  await clearAll();
  await db.doc(`profiles/${BASE}`).set({ displayName: 'Base', hasBaseMembership: true, baseMembershipEndDate: future() });
  await db.doc('profiles/org01').set({ displayName: 'Org', membershipTier: 'FREE' });
  await db.doc('events/ev1').set({
    organizerId: 'org01', latitude: 41.15, longitude: -8.61, title: 'Picnic', price: 0, attendeeCount: 0, maxAttendees: 0, status: 'published',
    startDate: future(DAY), endDate: future(DAY + 3 * 3600 * 1000),
  });
});
afterAll(() => fft.cleanup());

const markNew = (uid: string) => db.doc(`phone_required/${uid}`).set({ createdAtMs: Date.now(), reason: 'new_account' });

describe('rules: RSVP needs the phone claim for NEW accounts only', () => {
  const rsvp = (phone: string | null) =>
    clientWrite(BASE, phone, `events/ev1/attendees/${BASE}`, { userId: BASE, eventId: 'ev1', status: 'going', checkedIn: false });

  test('old account (no marker): allowed without a phone, forever', async () => {
    expect(await rsvp(null)).toBe(200);
  });
  test('new account without the claim: denied; with the claim: allowed', async () => {
    await markNew(BASE);
    expect(await rsvp(null)).toBe(403);
    expect(await rsvp(PHONE)).toBe(200);
  });
  test("'interested' is never gated (legacy flow unaffected)", async () => {
    expect(await clientWrite(BASE, null, `events/ev1/attendees/${BASE}`,
      { userId: BASE, eventId: 'ev1', status: 'interested', checkedIn: false })).toBe(200);
  });
});

describe('rules: turning on a business account needs the phone claim', () => {
  beforeEach(async () => {
    await db.doc(`profiles/${BASE}`).set({ displayName: 'Biz', membershipTier: 'SILVER', membershipEndDate: future(), isBusiness: false });
  });
  const enable = (phone: string | null) =>
    clientWrite(BASE, phone, `profiles/${BASE}`, { isBusiness: true }, ['isBusiness']);
  test('old account: allowed without a phone', async () => {
    expect(await enable(null)).toBe(200);
  });
  test('new account: needs the claim', async () => {
    await markNew(BASE);
    expect(await enable(null)).toBe(403);
    expect(await enable(PHONE)).toBe(200);
  });
  test('business verification request: phone is the only identity requirement (no document)', async () => {
    expect(await clientWrite(BASE, PHONE, `business_verification_requests/${BASE}`,
      { status: 'pending', businessName: 'Biz', ownerName: 'Ana', phoneNumber: PHONE, phoneVerified: true })).toBe(200);
  });
});

describe('rules: server-only phone_index', () => {
  test('clients can neither read nor write phone_index / phone_required', async () => {
    await db.doc('phone_index/abc').set({ uid: BASE });
    expect(await clientGet(BASE, 'phone_index/abc')).toBe(403);
    expect(await clientWrite(BASE, PHONE, 'phone_index/abc', { uid: BASE })).toBe(403);
    await markNew(BASE);
    expect(await clientGet(BASE, `phone_required/${BASE}`)).toBe(403);
    expect(await clientWrite(BASE, PHONE, `phone_required/${BASE}`, { reason: 'x' })).toBe(403);
  });
  test('owner cannot write the verified phone into profiles_private', async () => {
    expect(await clientWrite(BASE, PHONE, `profiles_private/${BASE}`, { phone: '+15550000000' })).toBe(403);
  });
});

describe('callables: new accounts (created on/after 16 Oct 2026) need the phone', () => {
  const NEWU = 'phnew01';
  beforeEach(async () => {
    await ensureAuthUser(NEWU);
    await db.doc(`profiles/${NEWU}`).set({ displayName: 'New', hasBaseMembership: true, baseMembershipEndDate: future() });
  });

  test('createBooking: refused without, passes the phone check with the claim', async () => {
    expect(await outcome(call(createBooking, { experienceId: 'x1', guests: 1 }, NEWU, {}))).toBe('phone_verification_required');
    expect(await outcome(call(createBooking, { experienceId: 'x1', guests: 1 }, NEWU, { phone_number: PHONE })))
      .not.toBe('phone_verification_required');
  });
  test('createTicketCheckout (event): refused without; paying an existing booking is not gated', async () => {
    expect(await outcome(call(tp.createTicketCheckout, { kind: 'event', id: 'ev1' }, NEWU, {}))).toBe('phone_verification_required');
    expect(await outcome(call(tp.createTicketCheckout, { kind: 'experience', id: 'b1' }, NEWU, {})))
      .not.toBe('phone_verification_required');
  });
  test('createUserExperience: refused without the phone', async () => {
    expect(await outcome(call(createUserExperience, { title: 'Walk' }, NEWU, {}))).toBe('phone_verification_required');
  });
  test('account unknown to Auth (old-account path) is never blocked by the phone rule', async () => {
    const r = await outcome(call(createBooking, { experienceId: 'x1', guests: 1 }, 'phlegacy01', {}));
    expect(r).not.toBe('phone_verification_required');
  });
});

describe('phone index: one number per account, banned numbers remembered', () => {
  test('record -> in use for others -> banned after deletion of a banned account', async () => {
    await ensureAuthUser('pha01', PHONE);
    expect(await outcome(call(recordVerifiedPhone, {}, 'pha01', { phone_number: PHONE }))).toBe('ok');
    const priv = (await db.doc('profiles_private/pha01').get()).data()!;
    expect(priv.phone).toBe(PHONE);
    expect((await db.doc(`phone_index/${phoneHash(PHONE)}`).get()).get('uid')).toBe('pha01');

    const inUse = await call(checkPhoneAllowed, { phone: PHONE }, 'phb01', {});
    expect(inUse).toEqual({ allowed: false, reason: 'phone_in_use' });
    expect(await call(checkPhoneAllowed, { phone: PHONE }, 'pha01', {})).toEqual({ allowed: true });

    await db.doc('users/pha01').set({ banned: true });
    expect(await retirePhoneIndexForDeletion('pha01')).toBe('banned');
    const idx = (await db.doc(`phone_index/${phoneHash(PHONE)}`).get()).data()!;
    expect(idx.banned).toBe(true);
    expect(idx.uid).toBeNull();
    // Privacy Policy: kept 5 years after the deletion.
    expect(idx.retainUntil.toMillis()).toBeGreaterThan(Date.now() + 4.9 * 365 * DAY);
    expect(await call(checkPhoneAllowed, { phone: PHONE }, 'phc01', {})).toEqual({ allowed: false, reason: 'phone_banned' });
  });
  test('a non-banned deletion frees the number', async () => {
    await ensureAuthUser('phd01', '+351910000001');
    await call(recordVerifiedPhone, {}, 'phd01', {});
    expect(await retirePhoneIndexForDeletion('phd01')).toBe('removed');
    expect(await call(checkPhoneAllowed, { phone: '+351910000001' }, 'phe01', {})).toEqual({ allowed: true });
  });
  test('unsupported countries are refused before any SMS', async () => {
    expect(await call(checkPhoneAllowed, { phone: '+919876543210' }, 'phf01', {}))
      .toEqual({ allowed: false, reason: 'unsupported_country' });
    expect(await call(checkPhoneAllowed, { phone: '+79161234567' }, 'phf01', {}))
      .toEqual({ allowed: false, reason: 'unsupported_country' });
  });
});
