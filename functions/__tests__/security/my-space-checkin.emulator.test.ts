/**
 * My Space check-in checklists — emulator integration tests (real Firestore
 * emulator; rules apply to the REST "client" calls).
 *
 *   setEventAttendeeCheckIn (checkin/manualCheckin.ts): organizer / co-owner
 *     ticks an attendee in or out by hand — same door rules, audited, never a
 *     delegated scanner, never the attendee.
 *   manualCheckInBooking (experience_bookings/service.ts): the HOST ticks a
 *     guest in without the code — audited, unverified meeting.
 *   firestore rules: checkin_audit is server-only; the favorite-communities
 *     list is capped at 50 (may only shrink when above).
 *
 *   firebase emulators:exec --config <emulator config> --only firestore,auth \
 *     --project test-project "npx jest --config jest.security.config.js my-space-checkin"
 */
import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT });
const fft = functionsTest({ projectId: PROJECT });

import { setEventAttendeeCheckIn } from '../../src/checkin/manualCheckin';
import { manualCheckInBooking } from '../../src/experience_bookings/functions';

const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const HOUR = 3600 * 1000;

const ORG = 'org01';
const CO = 'coorg01';
const SCANNER = 'scanner01';
const GUEST = 'guest01';
const OTHER = 'guest02';
const STRANGER = 'stranger01';

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

const call = (fn: any, data: any, uid: string) => (fft.wrap(fn) as any)({ data, auth: { uid, token: {} } });
async function refused(p: Promise<any>): Promise<{ code: string; reason: string }> {
  try { await p; } catch (e: any) { return { code: e.code, reason: e.details?.code ?? e.message }; }
  throw new Error('expected a refusal');
}

// Firestore REST as a signed-in CLIENT (rules apply). The emulator accepts unsigned JWTs.
function idToken(uid: string): string {
  const b = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, firebase: { sign_in_provider: 'password' } })}.`;
}
function toValue(v: any): any {
  if (v === null) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, toValue(x)])) } };
}
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
async function clientRead(uid: string, path: string): Promise<number> {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  const res = await fetch(`http://${host}/v1/projects/${PROJECT}/databases/(default)/documents/${path}`, {
    headers: { Authorization: `Bearer ${idToken(uid)}` },
  });
  await res.text();
  return res.status;
}

async function event(id: string, over: Record<string, any> = {}) {
  await db.doc(`events/${id}`).set({
    organizerId: ORG, coOrganizerIds: [CO], allowedScannerIds: [SCANNER], title: 'Language café',
    status: 'published', price: 0, attendeeCount: 2,
    startDate: TS.fromMillis(Date.now() + HOUR), endDate: TS.fromMillis(Date.now() + 3 * HOUR), ...over,
  });
}
async function attendee(eventId: string, uid: string, over: Record<string, any> = {}) {
  await db.doc(`events/${eventId}/attendees/${uid}`).set({
    userId: uid, eventId, userName: uid, status: 'going', guestCount: 0, ...over,
  });
}
async function audits(): Promise<Record<string, any>[]> {
  return (await db.collection('checkin_audit').get()).docs.map((d) => d.data());
}

beforeEach(async () => {
  await clearAll();
});
afterAll(() => fft.cleanup());

// ═══════════════════════════════════════════════ events

describe('setEventAttendeeCheckIn', () => {
  test('organizer ticks a going attendee in: manual method, audited, unverified meeting; idempotent', async () => {
    await event('e1');
    await attendee('e1', GUEST);
    const r = await call(setEventAttendeeCheckIn, { eventId: 'e1', userId: GUEST, checkedIn: true }, ORG);
    expect(r).toMatchObject({ checkedIn: true, alreadyCheckedIn: false, verified: false, userId: GUEST });
    const a = (await db.doc(`events/e1/attendees/${GUEST}`).get()).data()!;
    expect(a).toMatchObject({ checkedIn: true, checkedInBy: ORG, checkInMethod: 'manual' });
    expect(a.checkedInAt).toBeDefined();
    const log = await audits();
    expect(log).toHaveLength(1);
    expect(log[0]).toMatchObject({ kind: 'event', action: 'check_in', method: 'manual', eventId: 'e1', targetUid: GUEST, byUid: ORG });
    const pair = [ORG, GUEST].sort().join('_');
    const enc = await db.collection(`met_in_person/${pair}/encounters`).get();
    expect(enc.docs.map((d) => d.data().verified)).toEqual([false]);

    const again = await call(setEventAttendeeCheckIn, { eventId: 'e1', userId: GUEST, checkedIn: true }, ORG);
    expect(again.alreadyCheckedIn).toBe(true);
    expect(await audits()).toHaveLength(1);
  });

  test('co-organizer may tick; a delegated scanner, the attendee and strangers may not', async () => {
    await event('e1');
    await attendee('e1', GUEST);
    await attendee('e1', OTHER);
    await call(setEventAttendeeCheckIn, { eventId: 'e1', userId: OTHER, checkedIn: true }, CO);
    expect((await db.doc(`events/e1/attendees/${OTHER}`).get()).data()!.checkedIn).toBe(true);
    for (const uid of [SCANNER, GUEST, STRANGER]) {
      const r = await refused(call(setEventAttendeeCheckIn, { eventId: 'e1', userId: GUEST, checkedIn: true }, uid));
      expect(r).toMatchObject({ code: 'permission-denied', reason: 'not_organizer' });
    }
    expect((await db.doc(`events/e1/attendees/${GUEST}`).get()).data()!.checkedIn).toBeUndefined();
  });

  test('door rules still apply: not going, outside the window, ticketed event without a valid ticket', async () => {
    await event('e1');
    await attendee('e1', GUEST, { status: 'interested' });
    expect((await refused(call(setEventAttendeeCheckIn, { eventId: 'e1', userId: GUEST, checkedIn: true }, ORG))).reason).toBe('not_going');
    expect((await refused(call(setEventAttendeeCheckIn, { eventId: 'e1', userId: STRANGER, checkedIn: true }, ORG))).reason).toBe('not_registered');

    await event('e2', { startDate: TS.fromMillis(Date.now() + 48 * HOUR), endDate: TS.fromMillis(Date.now() + 50 * HOUR) });
    await attendee('e2', GUEST);
    expect((await refused(call(setEventAttendeeCheckIn, { eventId: 'e2', userId: GUEST, checkedIn: true }, ORG))).reason).toBe('outside_checkin_window');

    await event('e3', { price: 20, ticketProvider: 'stripe' });
    await attendee('e3', GUEST, { ticketId: 'nope' });
    expect((await refused(call(setEventAttendeeCheckIn, { eventId: 'e3', userId: GUEST, checkedIn: true }, ORG))).reason).toBe('ticket_required');
    expect(await audits()).toHaveLength(0);
  });

  test('undo clears the check-in fields and is audited', async () => {
    await event('e1');
    await attendee('e1', GUEST, { checkedIn: true, checkedInAt: TS.now(), checkedInBy: SCANNER, checkInMethod: 'signed' });
    const r = await call(setEventAttendeeCheckIn, { eventId: 'e1', userId: GUEST, checkedIn: false }, ORG);
    expect(r).toMatchObject({ checkedIn: false, changed: true });
    const a = (await db.doc(`events/e1/attendees/${GUEST}`).get()).data()!;
    expect(a.checkedIn).toBe(false);
    expect(a.checkedInAt).toBeUndefined();
    expect(a.checkInMethod).toBeUndefined();
    expect((await audits())[0]).toMatchObject({ action: 'undo', previousMethod: 'signed', byUid: ORG });
    // Undo of a not-checked-in attendee: no change, no audit.
    const again = await call(setEventAttendeeCheckIn, { eventId: 'e1', userId: GUEST, checkedIn: false }, ORG);
    expect(again.changed).toBe(false);
    expect(await audits()).toHaveLength(1);
  });

  test('bad input is refused', async () => {
    await event('e1');
    expect((await refused(call(setEventAttendeeCheckIn, { eventId: 'e1', userId: GUEST }, ORG))).reason).toBe('invalid_checked_in');
    expect((await refused(call(setEventAttendeeCheckIn, { eventId: 'e/1', userId: GUEST, checkedIn: true }, ORG))).reason).toBe('invalid_event_id');
    expect((await refused(call(setEventAttendeeCheckIn, { eventId: 'nope', userId: GUEST, checkedIn: true }, ORG))).reason).toBe('event_not_found');
  });

  test('rules: clients still cannot write the check-in fields nor read the audit', async () => {
    await event('e1');
    await attendee('e1', GUEST);
    expect(await clientWrite(ORG, `events/e1/attendees/${GUEST}`, { checkedIn: true }, ['checkedIn'])).toBe(403);
    await call(setEventAttendeeCheckIn, { eventId: 'e1', userId: GUEST, checkedIn: true }, ORG);
    const id = (await db.collection('checkin_audit').limit(1).get()).docs[0].id;
    expect(await clientRead(ORG, `checkin_audit/${id}`)).toBe(403);
    expect(await clientWrite(ORG, 'checkin_audit/forged', { kind: 'event' })).toBe(403);
  });
});

// ═══════════════════════════════════════════════ experience bookings

async function booking(id: string, over: Record<string, any> = {}) {
  await db.doc('user_experiences/x1').set({ hostId: ORG, title: 'Cooking class', status: 'published', allowedScannerIds: [SCANNER] });
  await db.doc(`bookings/${id}`).set({
    experienceId: 'x1', slotId: 's1', hostId: ORG, guestId: GUEST, guests: 1, status: 'confirmed',
    experienceTitle: 'Cooking class', slotStart: TS.fromMillis(Date.now() + HOUR), slotEnd: TS.fromMillis(Date.now() + 3 * HOUR),
    price: { unitAmount: 0, totalAmount: 0 }, payment: { mode: 'free' }, checkIn: null, ...over,
  });
}

describe('manualCheckInBooking', () => {
  test('host ticks the guest in: manual, eligibility, audit, unverified meeting; idempotent', async () => {
    await booking('b1');
    const r = await call(manualCheckInBooking, { bookingId: 'b1' }, ORG);
    expect(r).toMatchObject({ bookingId: 'b1', status: 'confirmed', alreadyCheckedIn: false });
    expect(r.checkedInAt).toBeTruthy();
    const b = (await db.doc('bookings/b1').get()).data()!;
    expect(b.checkIn).toMatchObject({ byUid: ORG, method: 'manual' });
    expect((await db.doc(`user_experiences/x1/review_eligibility/${GUEST}`).get()).exists).toBe(true);
    expect((await audits())[0]).toMatchObject({ kind: 'booking', action: 'check_in', method: 'manual', bookingId: 'b1', targetUid: GUEST, byUid: ORG });
    const pair = [ORG, GUEST].sort().join('_');
    const enc = await db.collection(`met_in_person/${pair}/encounters`).get();
    expect(enc.docs.map((d) => d.data().verified)).toEqual([false]);
    const again = await call(manualCheckInBooking, { bookingId: 'b1' }, ORG);
    expect(again.alreadyCheckedIn).toBe(true);
    expect(await audits()).toHaveLength(1);
  });

  test('only the host: a helper, the guest and strangers are refused', async () => {
    await booking('b1');
    for (const uid of [SCANNER, GUEST, STRANGER]) {
      expect(await refused(call(manualCheckInBooking, { bookingId: 'b1' }, uid))).toMatchObject({ code: 'permission-denied', reason: 'not_host' });
    }
    expect((await db.doc('bookings/b1').get()).data()!.checkIn).toBeNull();
  });

  test('door rules apply: not confirmed, unpaid in-app payment, outside the window', async () => {
    await booking('b1', { status: 'requested' });
    expect((await refused(call(manualCheckInBooking, { bookingId: 'b1' }, ORG))).reason).toBe('not_confirmed');
    await booking('b2', { payment: { mode: 'online', provider: 'stripe', status: 'unpaid' } });
    expect((await refused(call(manualCheckInBooking, { bookingId: 'b2' }, ORG))).reason).toBe('ticket_not_valid');
    await booking('b3', { slotStart: TS.fromMillis(Date.now() + 72 * HOUR), slotEnd: TS.fromMillis(Date.now() + 74 * HOUR) });
    expect((await refused(call(manualCheckInBooking, { bookingId: 'b3' }, ORG))).reason).toBe('outside_checkin_window');
    expect(await audits()).toHaveLength(0);
  });
});

// ═══════════════════════════════════════════════ favorite communities cap

describe('rules: user_favorite_communities', () => {
  const ids = (n: number) => Array.from({ length: n }, (_, i) => `c${i}`);

  test('owner-only, at most 50; a list already above the cap may only shrink', async () => {
    expect(await clientWrite(GUEST, `user_favorite_communities/${GUEST}`, { communityIds: ids(50) })).toBe(200);
    expect(await clientRead(GUEST, `user_favorite_communities/${GUEST}`)).toBe(200);
    expect(await clientRead(OTHER, `user_favorite_communities/${GUEST}`)).toBe(403);
    expect(await clientWrite(OTHER, `user_favorite_communities/${GUEST}`, { communityIds: [] })).toBe(403);
    expect(await clientWrite(GUEST, `user_favorite_communities/${GUEST}`, { communityIds: ids(51) })).toBe(403);
    expect(await clientWrite(OTHER, `user_favorite_communities/${OTHER}`, { communityIds: ids(51) })).toBe(403);
    // Legacy list over the cap (written before it): shrinking is allowed, growing is not.
    await db.doc(`user_favorite_communities/${STRANGER}`).set({ communityIds: ids(60) });
    expect(await clientWrite(STRANGER, `user_favorite_communities/${STRANGER}`, { communityIds: ids(59) })).toBe(200);
    expect(await clientWrite(STRANGER, `user_favorite_communities/${STRANGER}`, { communityIds: ids(61) })).toBe(403);
  });
});
