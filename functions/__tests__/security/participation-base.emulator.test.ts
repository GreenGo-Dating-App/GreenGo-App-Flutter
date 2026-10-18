/**
 * Owner rule (2026-10-11): "to participate in an event or experience, the
 * user must have the Base membership". An ACTIVE Silver / Gold / Platinum
 * (or TEST) counts too - the same "Base or better" rule as 1:1 messaging
 * (P-H2): rules baseAccess() / canParticipate(), server hasBaseAccess() +
 * shared/participation.ts, app Profile.isBaseMembershipActive.
 *
 * Gated: RSVP going / waitlist on someone else's event (client write),
 * waitlist promotion into a seat, booking consents, createTicketCheckout
 * (events), createBooking (experiences, free ones included).
 * NOT gated: 'interested', cancelling, organizers on their own event (own
 * attendance + comps), existing attendees editing their RSVP flags.
 *
 *   firebase emulators:exec --config ../firebase.emulators.<you>.json \
 *     --only firestore,auth,storage --project test-project \
 *     "npx jest --config jest.security.config.js participation-base"
 */
process.env.TICKET_QR_SIGNING_KEY = process.env.TICKET_QR_SIGNING_KEY || 'fake'.repeat(10); // test-only

import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
const fft = functionsTest({ projectId: PROJECT });

import * as tp from '../../src/ticket_payments';
import { createBooking } from '../../src/experience_bookings/functions';
import { hasBaseAccess } from '../../src/shared/effectiveTier';
import { canParticipate } from '../../src/shared/participation';

const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const HOUR = 3600 * 1000;
const DAY = 24 * HOUR;
const future = (ms = 30 * DAY) => TS.fromMillis(Date.now() + ms);
const past = (ms = DAY) => TS.fromMillis(Date.now() - ms);

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
async function clientDelete(uid: string, path: string): Promise<number> {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  const res = await fetch(`http://${host}/v1/projects/${PROJECT}/databases/(default)/documents/${path}`, {
    method: 'DELETE', headers: { Authorization: `Bearer ${idToken(uid)}` },
  });
  await res.text();
  return res.status;
}

const call = (fn: any, data: any, uid: string) => (fft.wrap(fn) as any)({ data, auth: { uid, token: {} } });
async function refused(p: Promise<any>): Promise<{ code: string; reason: string }> {
  try { await p; } catch (e: any) { return { code: e.code, reason: e.details?.code ?? e.message }; }
  throw new Error('expected a refusal');
}

const ORG = 'org01'; // organizer, FREE tier, no Base
const FREE = 'free01';
const BASE = 'base01';
const BASE_EXPIRED = 'baseold01';
const SILVER = 'silver01';
const GOLD = 'gold01';
const PLAT = 'plat01';
const TESTER = 'tester01';
const EXPIRED = 'expired01'; // Gold that ended, no Base
const STRANGER = 'stranger01'; // Base member who cancels and promotes

const PROFILES: Record<string, Record<string, any>> = {
  [ORG]: { displayName: 'Org', membershipTier: 'FREE' },
  [FREE]: { displayName: 'Free', membershipTier: 'FREE' },
  [BASE]: { displayName: 'Base', hasBaseMembership: true, baseMembershipEndDate: future() },
  [BASE_EXPIRED]: { displayName: 'Base old', hasBaseMembership: true, baseMembershipEndDate: past() },
  [SILVER]: { displayName: 'Silver', membershipTier: 'SILVER', membershipEndDate: future() },
  [GOLD]: { displayName: 'Gold', membershipTier: 'GOLD', membershipEndDate: future() },
  [PLAT]: { displayName: 'Plat', membershipTier: 'PLATINUM', membershipEndDate: future() },
  [TESTER]: { displayName: 'Tester', membershipTier: 'TEST' },
  [EXPIRED]: { displayName: 'Expired', membershipTier: 'GOLD', membershipEndDate: past() },
  [STRANGER]: { displayName: 'Stranger', hasBaseMembership: true, baseMembershipEndDate: future() },
};
const ELIGIBLE = [BASE, SILVER, GOLD, PLAT, TESTER];
const INELIGIBLE = [FREE, BASE_EXPIRED, EXPIRED];

async function seed() {
  await clearAll();
  for (const [uid, p] of Object.entries(PROFILES)) {
    await db.doc(`profiles/${uid}`).set({ ...p, isAgeVerified: true });
  }
  await db.doc('events/ev1').set({
    organizerId: ORG, title: 'Picnic', price: 0, attendeeCount: 0, maxAttendees: 0, status: 'published',
    startDate: future(DAY), endDate: future(DAY + 3 * HOUR),
  });
}
const rsvp = (uid: string, status: string) =>
  clientWrite(uid, `events/ev1/attendees/${uid}`, { userId: uid, eventId: 'ev1', status, checkedIn: false });

beforeEach(seed);
afterAll(() => fft.cleanup());

describe('server helper = rules predicate', () => {
  test('hasBaseAccess / canParticipate per profile', () => {
    for (const uid of ELIGIBLE) expect([uid, canParticipate(PROFILES[uid])]).toEqual([uid, true]);
    for (const uid of INELIGIBLE) expect([uid, canParticipate(PROFILES[uid])]).toEqual([uid, false]);
    expect(hasBaseAccess(null)).toBe(false);
  });
});

describe('firestore rules: events/{id}/attendees', () => {
  test('free / expired users cannot go or join the waitlist; interested is still allowed', async () => {
    for (const uid of INELIGIBLE) {
      expect([uid, await rsvp(uid, 'going')]).toEqual([uid, 403]);
      expect([uid, await rsvp(uid, 'waitlist')]).toEqual([uid, 403]);
      expect([uid, await rsvp(uid, 'interested')]).toEqual([uid, 200]);
      // ...and cannot upgrade an existing 'interested' RSVP either
      expect([uid, await clientWrite(uid, `events/ev1/attendees/${uid}`, { status: 'going' }, ['status'])]).toEqual([uid, 403]);
      // unknown statuses fail closed
      expect([uid, await rsvp(uid, 'attending')]).toEqual([uid, 403]);
      expect([uid, await rsvp(uid, 'notGoing')]).toEqual([uid, 200]);
    }
  });

  test('Base, Silver, Gold, Platinum and TEST can go and join the waitlist', async () => {
    for (const uid of ELIGIBLE) {
      expect([uid, await rsvp(uid, 'waitlist')]).toEqual([uid, 200]);
      expect([uid, await rsvp(uid, 'going')]).toEqual([uid, 200]);
    }
  });

  test('organizer (free tier) is unaffected on their own event: own attendance and comps', async () => {
    expect(await rsvp(ORG, 'going')).toBe(200);
    expect(await clientWrite(ORG, `events/ev1/attendees/${FREE}`, { userId: FREE, status: 'going' })).toBe(200);
    // co-owner too
    await db.doc('events/ev1').set({ coOrganizerIds: [EXPIRED] }, { merge: true });
    expect(await rsvp(EXPIRED, 'going')).toBe(200);
  });

  test('existing attendees are not removed: flag edits allowed, cancelling allowed', async () => {
    await db.doc(`events/ev1/attendees/${FREE}`).set({ userId: FREE, status: 'going', checkedIn: false });
    expect(await clientWrite(FREE, `events/ev1/attendees/${FREE}`, { muteNotifications: true }, ['muteNotifications'])).toBe(200);
    // the join transaction re-saves the same status
    expect(await rsvp(FREE, 'going')).toBe(200);
    expect(await clientDelete(FREE, `events/ev1/attendees/${FREE}`)).toBe(200);
    // and the counters keep working
    expect(await clientWrite(FREE, 'events/ev1', { attendeeCount: 0 }, ['attendeeCount'])).toBe(200);
  });

  test('waitlist promotion only promotes eligible users', async () => {
    await db.doc(`events/ev1/attendees/${FREE}`).set({ userId: FREE, status: 'waitlist' });
    await db.doc(`events/ev1/attendees/${BASE}`).set({ userId: BASE, status: 'waitlist' });
    expect(await clientWrite(STRANGER, `events/ev1/attendees/${FREE}`, { status: 'going' }, ['status'])).toBe(403);
    // nor can the waitlisted free user promote themselves
    expect(await clientWrite(FREE, `events/ev1/attendees/${FREE}`, { status: 'going' }, ['status'])).toBe(403);
    expect(await clientWrite(STRANGER, `events/ev1/attendees/${BASE}`, { status: 'going' }, ['status'])).toBe(200);
  });
});

describe('firestore rules: experience booking consents', () => {
  test('free user cannot record a booking consent; Base can', async () => {
    await db.doc('user_experiences/x1').set({ hostId: ORG, status: 'published', title: 'Walk' });
    const consent = (uid: string) => clientWrite(uid, `user_experiences/x1/booking_consents/${uid}`, {
      policy: 'flexible', version: 1, experienceId: 'x1', method: 'cash',
    });
    // acceptedAt must equal request.time: use a commit with a server transform
    const host = process.env.FIRESTORE_EMULATOR_HOST!;
    const base = `projects/${PROJECT}/databases/(default)/documents`;
    const commit = async (uid: string) => {
      const res = await fetch(`http://${host}/v1/${base}:commit`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ writes: [{
          update: { name: `${base}/user_experiences/x1/booking_consents/${uid}`, fields: {
            policy: toValue('flexible'), version: toValue(1), experienceId: toValue('x1'), method: toValue('cash') } },
          updateTransforms: [{ fieldPath: 'acceptedAt', setToServerValue: 'REQUEST_TIME' }],
          currentDocument: { exists: false },
        }] }),
      });
      await res.text();
      return res.status;
    };
    expect(await consent(FREE)).toBe(403); // (also missing acceptedAt)
    expect(await commit(FREE)).toBe(403);
    expect(await commit(EXPIRED)).toBe(403);
    expect(await commit(BASE)).toBe(200);
    expect(await commit(SILVER)).toBe(200);
  });
});

describe('callables', () => {
  async function freeTypeEvent() {
    await db.doc('events/tix').set({
      organizerId: ORG, title: 'Open day', price: 0, currency: 'R$', currencyCode: 'BRL', attendeeCount: 0, maxAttendees: 0,
      status: 'published', ticketProvider: 'link', startDate: future(DAY), endDate: future(DAY + 3 * HOUR),
    });
    await db.doc('events/tix/ticket_types/free').set({ name: 'Free entry', price: 0, quantity: null, active: true, sortOrder: 0 });
  }
  const claim = (uid: string) => call(tp.createTicketCheckout, { kind: 'event', id: 'tix', items: [{ typeId: 'free', qty: 1 }] }, uid);

  test('createTicketCheckout: free / expired refused with base_membership_required; nothing held', async () => {
    await freeTypeEvent();
    for (const uid of INELIGIBLE) {
      expect([uid, await refused(claim(uid))]).toEqual([uid, { code: 'failed-precondition', reason: 'base_membership_required' }]);
    }
    expect((await db.collection('ticket_orders').get()).size).toBe(0);
    expect((await db.doc('events/tix/ticket_types/free').get()).data()!.held ?? 0).toBe(0);
  });

  test('createTicketCheckout: Base and paid tiers can claim; the organizer still gets own_listing', async () => {
    await freeTypeEvent();
    for (const uid of [BASE, SILVER, PLAT]) {
      const r = await claim(uid);
      expect([uid, typeof r.orderId]).toEqual([uid, 'string']);
    }
    expect(await refused(claim(ORG))).toEqual({ code: 'failed-precondition', reason: 'own_listing' });
  });

  async function freeExperience() {
    await db.doc('user_experiences/xp').set({
      hostId: ORG, status: 'published', title: 'City walk', isFree: true, price: 0, maxGroupSize: 10,
      cancellationPolicy: 'flexible', durationMinutes: 60,
    });
    await db.doc('user_experiences/xp/slots/s1').set({
      start: future(5 * DAY), end: future(5 * DAY + 3 * HOUR), capacity: 10, bookedCount: 0, status: 'open',
    });
  }
  let seq = 0;
  const book = (uid: string) => call(createBooking, {
    experienceId: 'xp', slotId: 's1', guests: 1, requestId: `req_part_${Date.now()}_${++seq}`, consentVersion: 'v1',
  }, uid);

  test('createBooking: free experience still needs Base; Base / Gold can book', async () => {
    await freeExperience();
    for (const uid of INELIGIBLE) {
      expect([uid, await refused(book(uid))]).toEqual([uid, { code: 'failed-precondition', reason: 'base_membership_required' }]);
    }
    expect((await db.collection('bookings').get()).size).toBe(0);
    const r = await book(BASE);
    expect(r.status).toBeDefined();
    expect((await db.collection('bookings').where('guestId', '==', BASE).get()).size).toBe(1);
  });
});
