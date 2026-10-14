/**
 * "Only business accounts can sell" + "becoming a business can't be undone":
 * emulator security tests (real Firestore / Auth emulators, rules applied to
 * client REST writes; callables run through firebase-functions-test).
 *
 *  - profiles: isBusiness is a ONE-WAY upgrade, client-settable only while
 *    holding an active Platinum; never cleared by the client; businessSince
 *    is immutable once stamped; a profile is never CREATED as a business.
 *  - events / ticket types / user_experiences: turning a listing into a PAID
 *    one needs an ACTIVE business account (isBusiness + Platinum); existing
 *    paid listings of other accounts stay readable and editable.
 *  - callables: createTicketCheckout / publishUserExperience /
 *    createUserExperience refuse new paid sales / listings of non-business
 *    accounts with a clear reason.
 *
 *   firebase emulators:exec --config <cfg> --only firestore,auth,storage \
 *     --project test-project "npx jest --config jest.security.config.js"
 */

process.env.STRIPE_SECRET_KEY = 'sk_test_platform_fake';
process.env.STRIPE_CONNECT_WEBHOOK_SECRET = 'whsec_test_connect';
process.env.MP_CLIENT_ID = 'mp-client';
process.env.MP_CLIENT_SECRET = 'mp-secret';
process.env.MP_WEBHOOK_SECRET = 'mp-webhook-secret';
process.env.TICKET_QR_SIGNING_KEY = 'fake'.repeat(10); // test-only value, not a key

import * as admin from 'firebase-admin';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
const fft = functionsTest({ projectId: PROJECT });

import * as tp from '../../src/ticket_payments';
import { ticketDeps } from '../../src/ticket_payments/providers';
import { createUserExperience } from '../../src/user_experiences/createUserExperience';
import { publishUserExperience } from '../../src/user_experiences/safetyCallables';
import { HOST_AGREEMENT_VERSION } from '../../src/user_experiences/safety';
import { reconcileListings } from '../../src/entitlements/downgrade';

const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const HOUR = 3600 * 1000;
const YEAR = 365 * 24 * HOUR;

// Never reach a real provider (the refusals happen before any provider call).
ticketDeps.stripe = () => { throw new Error('stripe must not be called'); };
ticketDeps.fetch = (async () => { throw new Error('fetch must not be called'); }) as any;

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
async function refused(p: Promise<any>): Promise<any> {
  try { await p; } catch (e: any) { return { code: e.code, reason: e.details?.code ?? e.message }; }
  throw new Error('expected a refusal');
}

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
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, toValue(x)])) } };
}
/** PATCH as a signed-in client (rules apply). No mask = full write / create. */
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

const PERSONAL = 'personal01';
const PLAT = 'platinum01'; // Platinum, not (yet) a business
const BIZ = 'business01'; // active business
const LAPSED = 'lapsed01'; // business whose Platinum expired
const BUYER = 'buyer01';
const SILVER_BIZ = 'silverbiz01'; // active Silver business (owner rule 2026-10-14)
const BASE_BIZ = 'basebiz01'; // business that dropped to Base: free listings only

const future = () => TS.fromMillis(Date.now() + YEAR);
const past = () => TS.fromMillis(Date.now() - YEAR);
const idDoc = { ageVerification: { status: 'pending' }, hostAgreementVersion: HOST_AGREEMENT_VERSION };

beforeEach(async () => {
  await clearAll();
  await db.doc(`profiles/${PERSONAL}`).set({ displayName: 'Personal', membershipTier: 'FREE', ...idDoc });
  await db.doc(`profiles/${PLAT}`).set({ displayName: 'Plat', membershipTier: 'PLATINUM', membershipEndDate: future(), ...idDoc });
  await db.doc(`profiles/${BIZ}`).set({
    displayName: 'Biz', isBusiness: true, businessSince: TS.fromMillis(Date.now() - HOUR),
    membershipTier: 'PLATINUM', membershipEndDate: future(), ...idDoc,
  });
  await db.doc(`profiles/${LAPSED}`).set({
    displayName: 'Lapsed', isBusiness: true, membershipTier: 'PLATINUM', membershipEndDate: past(), ...idDoc,
  });
  await db.doc(`profiles/${BUYER}`).set({ displayName: 'Buyer', hasBaseMembership: true, baseMembershipEndDate: future() });
  await db.doc(`profiles/${SILVER_BIZ}`).set({
    displayName: 'SilverBiz', isBusiness: true, membershipTier: 'SILVER', membershipEndDate: future(), ...idDoc,
  });
  await db.doc(`profiles/${BASE_BIZ}`).set({
    displayName: 'BaseBiz', isBusiness: true, membershipTier: 'FREE',
    hasBaseMembership: true, baseMembershipEndDate: future(), ...idDoc,
  });
});
afterAll(() => fft.cleanup());

// ═══════════════════════════════════════════════ profiles

describe('profiles: becoming a business is permanent and needs Silver, Gold or Platinum', () => {
  test('no plan / Base / a lapsed paid tier cannot make itself a business; Silver and Gold can', async () => {
    expect(await clientWrite(PERSONAL, `profiles/${PERSONAL}`, { isBusiness: true }, ['isBusiness'])).toBe(403);
    await db.doc(`profiles/${PERSONAL}`).set({ hasBaseMembership: true, baseMembershipEndDate: future() }, { merge: true });
    expect(await clientWrite(PERSONAL, `profiles/${PERSONAL}`, { isBusiness: true }, ['isBusiness'])).toBe(403);
    for (const tier of ['SILVER', 'GOLD']) {
      const uid = `paid_${tier}`;
      await db.doc(`profiles/${uid}`).set({ displayName: tier, membershipTier: tier, membershipEndDate: future() });
      expect(await clientWrite(uid, `profiles/${uid}`, { isBusiness: true }, ['isBusiness'])).toBe(200);
    }
    // a lapsed Platinum is not enough either
    await db.doc(`profiles/${PLAT}`).set({ membershipEndDate: past() }, { merge: true });
    expect(await clientWrite(PLAT, `profiles/${PLAT}`, { isBusiness: true }, ['isBusiness'])).toBe(403);
  });

  test('an active Platinum may switch ON (with businessSince once) and never back', async () => {
    expect(await clientWrite(PLAT, `profiles/${PLAT}`, { isBusiness: true, businessSince: new Date() },
      ['isBusiness', 'businessSince'])).toBe(200);
    expect((await db.doc(`profiles/${PLAT}`).get()).data()!.isBusiness).toBe(true);
    // No way back: false, or removing the field.
    expect(await clientWrite(PLAT, `profiles/${PLAT}`, { isBusiness: false }, ['isBusiness'])).toBe(403);
    expect(await clientWrite(PLAT, `profiles/${PLAT}`, {}, ['isBusiness'])).toBe(403);
    // businessSince is stamped once.
    expect(await clientWrite(PLAT, `profiles/${PLAT}`, { businessSince: new Date(0) }, ['businessSince'])).toBe(403);
    // Other edits keep working.
    expect(await clientWrite(PLAT, `profiles/${PLAT}`, { bio: 'Hello' }, ['bio'])).toBe(200);
  });

  test('an active or lapsed business can never clear the flag; its other edits still work', async () => {
    expect(await clientWrite(BIZ, `profiles/${BIZ}`, { isBusiness: false }, ['isBusiness'])).toBe(403);
    expect(await clientWrite(LAPSED, `profiles/${LAPSED}`, { isBusiness: false }, ['isBusiness'])).toBe(403);
    expect(await clientWrite(LAPSED, `profiles/${LAPSED}`, { bio: 'Still here', isBusiness: true }, ['bio', 'isBusiness'])).toBe(200);
  });

  test('a profile is never created as a business', async () => {
    expect(await clientWrite('newuser01', 'profiles/newuser01', { displayName: 'New', isBusiness: true })).toBe(403);
    expect(await clientWrite('newuser02', 'profiles/newuser02', { displayName: 'New', isBusiness: false })).toBe(200);
  });
});

// ═══════════════════════════════════════════════ events + ticket types

const ev = (organizerId: string, over: Record<string, any> = {}) => ({
  organizerId, title: 'Rooftop Samba', attendeeCount: 0, maxAttendees: 0,
  // The app always writes an end date (EventModel.toJson); the event rules
  // need it for the ongoing-event cap (audit 2026-10-11).
  startDate: new Date(Date.now() + HOUR), endDate: new Date(Date.now() + 3 * HOUR), ...over,
});

describe('events: paid only by an active business', () => {
  test('create: needs a plan; free with Base, paid only for an active business', async () => {
    // No plan: no event at all (owner rule 2026-10-13).
    expect(await clientWrite(PERSONAL, 'events/f0', ev(PERSONAL, { price: 0 }))).toBe(403);
    await db.doc(`profiles/${PERSONAL}`).set({ hasBaseMembership: true, baseMembershipEndDate: future() }, { merge: true });
    expect(await clientWrite(PERSONAL, 'events/f1', ev(PERSONAL, { price: 0 }))).toBe(200);
    expect(await clientWrite(PERSONAL, 'events/p1', ev(PERSONAL, { price: 10, ticketProvider: 'link' }))).toBe(403);
    // a ticket provider alone makes it paid
    expect(await clientWrite(PERSONAL, 'events/p2', ev(PERSONAL, { ticketProvider: 'stripe' }))).toBe(403);
    expect(await clientWrite(PLAT, 'events/p3', ev(PLAT, { price: 10, ticketProvider: 'link' }))).toBe(403);
    expect(await clientWrite(LAPSED, 'events/p4', ev(LAPSED, { price: 10, ticketProvider: 'link' }))).toBe(403);
    expect(await clientWrite(BIZ, 'events/p5', ev(BIZ, { price: 10, ticketProvider: 'link' }))).toBe(200);
    // Owner rule 2026-10-14: a Silver business sells too; a business on Base never does.
    expect(await clientWrite(SILVER_BIZ, 'events/p6', ev(SILVER_BIZ, { price: 10, ticketProvider: 'link' }))).toBe(200);
    expect(await clientWrite(BASE_BIZ, 'events/p7', ev(BASE_BIZ, { price: 10, ticketProvider: 'link' }))).toBe(403);
    expect(await clientWrite(BASE_BIZ, 'events/f7', ev(BASE_BIZ, { price: 0 }))).toBe(200);
  });

  test('update: a free event cannot be turned paid by a non-business (organizer or co-owner)', async () => {
    await db.doc('events/f1').set(ev(PERSONAL, { price: 0, coOrganizerIds: [BIZ] }));
    expect(await clientWrite(PERSONAL, 'events/f1', { price: 15, ticketProvider: 'link' }, ['price', 'ticketProvider'])).toBe(403);
    // A business co-owner cannot sell on a personal organizer's event either.
    expect(await clientWrite(BIZ, 'events/f1', { price: 15, ticketProvider: 'link' }, ['price', 'ticketProvider'])).toBe(403);
    expect(await clientWrite(PERSONAL, 'events/f1', { title: 'Picnic' }, ['title'])).toBe(200);
    await db.doc('events/b1').set(ev(BIZ, { price: 0 }));
    expect(await clientWrite(BIZ, 'events/b1', { price: 15, ticketProvider: 'stripe' }, ['price', 'ticketProvider'])).toBe(200);
  });

  test('legacy paid event of a non-business: still readable and editable', async () => {
    await db.doc('events/legacy').set(ev(PERSONAL, { price: 20, ticketProvider: 'link', ticketLinkMethod: 'pix' }));
    expect(await clientRead(BUYER, 'events/legacy')).toBe(200);
    expect(await clientWrite(PERSONAL, 'events/legacy', { title: 'Renamed' }, ['title'])).toBe(200);
    // ... and can be made free.
    expect(await clientWrite(PERSONAL, 'events/legacy', { price: 0 }, ['price', 'ticketProvider'])).toBe(200);
  });

  test('ticket types: priced types only for an active business organizer', async () => {
    await db.doc('events/legacy').set(ev(PERSONAL, { price: 20, ticketProvider: 'link' }));
    await db.doc('events/b1').set(ev(BIZ, { price: 20, ticketProvider: 'stripe' }));
    const type = (price: number) => ({ name: 'GA', price, sold: 0, held: 0 });
    expect(await clientWrite(PERSONAL, 'events/legacy/ticket_types/ga', type(1500))).toBe(403);
    expect(await clientWrite(PERSONAL, 'events/legacy/ticket_types/free', type(0))).toBe(200);
    expect(await clientWrite(PERSONAL, 'events/legacy/ticket_types/free', { price: 900 }, ['price'])).toBe(403);
    expect(await clientWrite(BIZ, 'events/b1/ticket_types/ga', type(1500))).toBe(200);
    expect(await clientWrite(BIZ, 'events/b1/ticket_types/ga', { price: 1800 }, ['price'])).toBe(200);
  });
});

// ═══════════════════════════════════════════════ experiences

const experience = (hostId: string, over: Record<string, any> = {}) => ({
  hostId, status: 'draft', title: 'Street food walk',
  description: 'Taste the best pastel and caldo de cana around the old market.',
  category: 'foodDrink', photoUrls: [], included: ['Tastings'], notIncluded: [],
  locationName: 'Mercado Municipal', durationMinutes: 120, languages: ['Portuguese'],
  maxGroupSize: 8, isFree: true, price: 0, currency: null, paymentLink: null, ...over,
});
const paidPatch = { isFree: false, price: 50, currency: 'BRL', paymentMethods: ['online'], paymentProvider: 'stripe' };
const paidMask = Object.keys(paidPatch);

describe('user_experiences: paid only by an active business', () => {
  test('client edit into a paid listing: denied for non-business, allowed for business', async () => {
    await db.doc('user_experiences/xp').set(experience(PERSONAL));
    await db.doc('user_experiences/xl').set(experience(LAPSED));
    await db.doc('user_experiences/xb').set(experience(BIZ));
    expect(await clientWrite(PERSONAL, 'user_experiences/xp', paidPatch, paidMask)).toBe(403);
    expect(await clientWrite(LAPSED, 'user_experiences/xl', paidPatch, paidMask)).toBe(403);
    // A payment link alone takes money too.
    expect(await clientWrite(PERSONAL, 'user_experiences/xp', { paymentLink: { type: 'pix', value: 'k' } }, ['paymentLink'])).toBe(403);
    expect(await clientWrite(PERSONAL, 'user_experiences/xp', { title: 'Street food tour' }, ['title'])).toBe(200);
    expect(await clientWrite(BIZ, 'user_experiences/xb', paidPatch, paidMask)).toBe(200);
  });

  test('legacy paid listing of a non-business: readable by its host and editable', async () => {
    // (editing a published paid listing also needs the approved ID document)
    await db.doc(`profiles/${PERSONAL}`).set({ isAgeVerified: true }, { merge: true });
    await db.doc('user_experiences/old').set(experience(PERSONAL, { ...paidPatch, status: 'published' }));
    expect(await clientRead(BUYER, 'user_experiences/old')).toBe(200);
    expect(await clientWrite(PERSONAL, 'user_experiences/old', { title: 'Old food walk' }, ['title'])).toBe(200);
  });

  test('createUserExperience: needs a plan; paid also needs a business (business_required)', async () => {
    const base = experience('ignored');
    delete (base as any).hostId;
    delete (base as any).status;
    const paid = { ...base, ...paidPatch, mainPhotoUrl: 'https://cdn.example.com/a.jpg' };
    const free = { ...base, mainPhotoUrl: 'https://cdn.example.com/a.jpg' };
    // No plan at all: creating is refused first (owner rule 2026-10-13).
    expect((await refused(call(createUserExperience, paid, PERSONAL))).reason).toBe('base_membership_required');
    expect((await refused(call(createUserExperience, free, PERSONAL))).reason).toBe('base_membership_required');
    expect((await refused(call(createUserExperience, paid, LAPSED))).reason).toBe('base_membership_required');
    expect((await call(createUserExperience, paid, BIZ)).status).toBe('draft');
    // With Base: a paid listing still needs a business; a free one works.
    await db.doc(`profiles/${PERSONAL}`).set({ hasBaseMembership: true, baseMembershipEndDate: future() }, { merge: true });
    expect((await refused(call(createUserExperience, paid, PERSONAL))).reason).toBe('business_required');
    expect((await call(createUserExperience, free, PERSONAL)).status).toBe('draft');
    await db.doc(`profiles/${PERSONAL}`).set({ membershipTier: 'PLATINUM', membershipEndDate: future() }, { merge: true });
    expect((await call(createUserExperience, free, PERSONAL)).status).toBe('draft');
  });

  test('publishUserExperience: a paid draft of a non-business is refused; publish as free works', async () => {
    await db.doc('user_experiences/d1').set(experience(PERSONAL, paidPatch));
    expect((await refused(call(publishUserExperience, { experienceId: 'd1' }, PERSONAL))).reason).toBe('business_required');
    // Free path is not blocked by the business rule (it then needs a date).
    expect((await refused(call(publishUserExperience, { experienceId: 'd1', asFree: true }, PERSONAL))).reason)
      .toBe('dates_required');
  });
});

// ═══════════════════════════════════════════════ sales

describe('new sales of non-business listings are refused with a clear reason', () => {
  test('createTicketCheckout: seller_not_business for a personal / lapsed organizer', async () => {
    // BASE_BIZ: a business that dropped to Base keeps its paid listing
    // visible but sells nothing new (owner rule 2026-10-14).
    for (const org of [PERSONAL, LAPSED, BASE_BIZ]) {
      await db.doc(`payment_accounts/${org}`).set({ uid: org, stripe: { accountId: 'acct_x', chargesEnabled: true, detailsSubmitted: true, status: 'ready', country: 'BR' } });
      await db.doc(`events/e_${org}`).set({
        organizerId: org, title: 'Legacy paid', price: 25, currency: 'R$', maxAttendees: 0, attendeeCount: 0,
        status: 'published', ticketProvider: 'stripe',
        startDate: TS.fromMillis(Date.now() + HOUR), endDate: TS.fromMillis(Date.now() + 4 * HOUR),
      });
      const e = await refused(call(tp.createTicketCheckout, { kind: 'event', id: `e_${org}` }, BUYER));
      expect(e).toEqual({ code: 'failed-precondition', reason: 'seller_not_business' });
    }
    // nothing was held for the refused sales
    expect((await db.doc(`ticket_inventory/event_e_${PERSONAL}`).get()).exists).toBe(false);
  });
});

// ═══════════════════════════════════════════════ plan downgrade (owner rule 2026-10-14)

describe('plan drops hide listings over the new allowance; upgrades restore them', () => {
  const GOLDY = 'goldhost01';
  const mkEvents = async (n: number) => {
    for (let i = 0; i < n; i++) {
      await db.doc(`events/g${i}`).set({
        ...ev(GOLDY, { price: 0 }), status: 'published',
        createdAt: TS.fromMillis(Date.now() - (n - i) * HOUR), // g{n-1} newest
        startDate: TS.fromMillis(Date.now() + HOUR), endDate: TS.fromMillis(Date.now() + 3 * HOUR),
      });
    }
  };
  const mkExperiences = async (n: number) => {
    for (let i = 0; i < n; i++) {
      await db.doc(`user_experiences/x${i}`).set({
        ...experience(GOLDY), status: i % 2 ? 'published' : 'draft',
        createdAt: TS.fromMillis(Date.now() - (n - i) * HOUR),
      });
    }
  };
  const visibleEvents = async () => (await db.collection('events').where('organizerId', '==', GOLDY).get())
    .docs.filter((d) => d.get('hiddenByDowngrade') !== true).map((d) => d.id).sort();
  const visibleExperiences = async () => (await db.collection('user_experiences').where('hostId', '==', GOLDY).get())
    .docs.filter((d) => d.get('hiddenByDowngrade') !== true).map((d) => d.id).sort();
  const setTier = (data: Record<string, any>) => db.doc(`profiles/${GOLDY}`).set(data, { merge: true });

  beforeEach(async () => {
    await db.doc(`profiles/${GOLDY}`).set({ displayName: 'Gold host', membershipTier: 'GOLD', membershipEndDate: future(), ...idDoc });
    await mkEvents(7);
    await mkExperiences(7);
  });

  test('Gold -> Silver keeps the 5 newest; -> Base keeps 1; -> no plan keeps 0; back up restores newest first', async () => {
    expect((await reconcileListings(GOLDY)).eventsHidden).toBe(0);

    await setTier({ membershipTier: 'SILVER' });
    // Dry run (backfill script): counts, writes nothing.
    expect(await reconcileListings(GOLDY, { dryRun: true })).toMatchObject({ eventsHidden: 2, experiencesHidden: 2 });
    expect((await visibleEvents()).length).toBe(7);
    let r = await reconcileListings(GOLDY);
    expect(r).toMatchObject({ eventsHidden: 2, experiencesHidden: 2 });
    expect(await visibleEvents()).toEqual(['g2', 'g3', 'g4', 'g5', 'g6']);
    expect(await visibleExperiences()).toEqual(['x2', 'x3', 'x4', 'x5', 'x6']);
    const hid = (await db.doc('events/g0').get()).data()!;
    expect(hid).toMatchObject({ status: 'draft', hiddenByDowngrade: true, preDowngradeStatus: 'published' });
    const hx = (await db.doc('user_experiences/x1').get()).data()!;
    expect(hx).toMatchObject({ status: 'hidden', hiddenByDowngrade: true, moderation: { reason: 'plan_downgrade', previousStatus: 'published' } });
    // Idempotent.
    expect(await reconcileListings(GOLDY)).toEqual({ eventsHidden: 0, eventsRestored: 0, experiencesHidden: 0, experiencesRestored: 0 });

    await setTier({ membershipTier: 'FREE', hasBaseMembership: true, baseMembershipEndDate: future() });
    await reconcileListings(GOLDY);
    expect(await visibleEvents()).toEqual(['g6']);
    expect(await visibleExperiences()).toEqual(['x6']);

    await setTier({ hasBaseMembership: false });
    await reconcileListings(GOLDY);
    expect(await visibleEvents()).toEqual([]);
    expect(await visibleExperiences()).toEqual([]);

    await setTier({ membershipTier: 'SILVER', membershipEndDate: future() });
    r = await reconcileListings(GOLDY);
    expect(r).toMatchObject({ eventsRestored: 5, experiencesRestored: 5 });
    expect(await visibleEvents()).toEqual(['g2', 'g3', 'g4', 'g5', 'g6']);
    expect((await db.doc('events/g6').get()).data()).toMatchObject({ status: 'published' });
    expect((await db.doc('events/g6').get()).data()!.preDowngradeStatus).toBeUndefined();
    expect((await db.doc('user_experiences/x5').get()).data()).toMatchObject({ status: 'published' });
    expect((await db.doc('user_experiences/x4').get()).data()).toMatchObject({ status: 'draft' });

    await setTier({ membershipTier: 'PLATINUM' });
    await reconcileListings(GOLDY);
    expect((await visibleEvents()).length).toBe(7);
    expect((await visibleExperiences()).length).toBe(7);
  });

  test('the host cannot touch the downgrade fields or re-publish a hidden listing', async () => {
    await setTier({ membershipTier: 'FREE', hasBaseMembership: true, baseMembershipEndDate: future() });
    await reconcileListings(GOLDY);
    expect(await clientWrite(GOLDY, 'events/g0', { status: 'published' }, ['status'])).toBe(403);
    expect(await clientWrite(GOLDY, 'events/g0', { hiddenByDowngrade: false }, ['hiddenByDowngrade'])).toBe(403);
    expect(await clientWrite(GOLDY, 'events/g0', { title: 'Still mine' }, ['title'])).toBe(200);
    expect(await clientWrite(GOLDY, 'events/new1', { ...ev(GOLDY, { price: 0 }), hiddenByDowngrade: true })).toBe(403);
    expect(await clientWrite(GOLDY, 'user_experiences/x0', { status: 'published' }, ['status'])).toBe(403);
    expect(await clientWrite(GOLDY, 'user_experiences/x0', { hiddenByDowngrade: false }, ['hiddenByDowngrade'])).toBe(403);
    // Ticket holders can still open a hidden event by id.
    expect(await clientRead(BUYER, 'events/g0')).toBe(200);
  });

  test('createUserExperience: the cap is active experiences; downgrade-hidden ones free the slot', async () => {
    const free = { ...experience('ignored'), mainPhotoUrl: 'https://cdn.example.com/a.jpg' };
    delete (free as any).hostId;
    delete (free as any).status;
    await db.doc(`user_experience_counts/${GOLDY}`).set({ count: 7 });
    await setTier({ membershipTier: 'FREE', hasBaseMembership: true, baseMembershipEndDate: future() });
    // 7 visible on Base (not reconciled yet): over the cap.
    expect((await refused(call(createUserExperience, free, GOLDY))).reason).toBe('experience_limit');
    await reconcileListings(GOLDY); // 6 hidden, 1 active
    expect((await refused(call(createUserExperience, free, GOLDY))).reason).toBe('experience_limit');
    await db.doc('user_experiences/x6').delete(); // deleting frees the slot
    await db.doc(`user_experience_counts/${GOLDY}`).set({ count: 6 });
    expect((await call(createUserExperience, free, GOLDY)).status).toBe('draft');
  });
});
