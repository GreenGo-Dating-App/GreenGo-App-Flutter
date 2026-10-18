/**
 * Event ticket / guest rules (owner request 2026-10-17/18): emulator
 * integration tests. Real Firestore / Auth emulators; only the Stripe API is
 * faked (ticketDeps).
 *
 *   rule 1  plus-ones refused on PAID events (attendee guestCount, event
 *           guestsAllowedPerAttendee)
 *   rule 2  at most 4 paid tickets per buyer per event, across orders (members
 *           and guests per e-mail), released with the seats
 *   rule 3  "Ask for attendee names": required by the server, stored per
 *           ticket + organizer-only attendee_names, removed on refund
 *   rule 4  lowering the capacity below the price phases stops sales
 *   rule 5  free events count places = 1 + plus-ones (capacity 20, one +1 -> 18)
 *
 * Run against BOTH rule files (firestore.rules and firestore.additive.rules):
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "cd functions && npx jest -i __tests__/security/ticket-rules.emulator.test.ts"
 *   (and once more with a firebase config whose firestore.rules points to the additive file)
 */

process.env.STRIPE_SECRET_KEY = 'sk_test_platform_fake';
process.env.STRIPE_CONNECT_WEBHOOK_SECRET = 'whsec_test_connect';
process.env.TICKET_QR_SIGNING_KEY = 'fake'.repeat(10); // test-only value, not a key

import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
const fft = functionsTest({ projectId: PROJECT });

import * as tp from '../../src/ticket_payments';
import { ticketDeps } from '../../src/ticket_payments/providers';
import { handleStripeConnectWebhook, stripeVerifier } from '../../src/ticket_payments/webhooks';
import { createTicketCheckout, markOrderReversed } from '../../src/ticket_payments/orders';
import { GuestBuyer } from '../../src/shared/guestIdentity';

const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const HOUR = 3600 * 1000;

let sessionSeq = 0;
const fakeStripe: any = {
  checkout: {
    sessions: {
      create: jest.fn(async () => {
        sessionSeq += 1;
        return { id: `cs_${sessionSeq}`, url: `https://checkout.stripe.test/cs_${sessionSeq}` };
      }),
      retrieve: jest.fn(async (id: string) => ({ id, payment_status: 'unpaid', metadata: {} })),
      expire: jest.fn(async () => ({})),
    },
  },
};
ticketDeps.stripe = () => fakeStripe;

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
  try { await p; } catch (e: any) { return { code: e.code, reason: e.details?.code ?? e.message, details: e.details }; }
  throw new Error('expected a refusal');
}

const ORG = 'organizer01';
const BUYER = 'buyer01';
const OTHER = 'buyer02';
const THIRD = 'buyer03';

const BILLING_OK = {
  type: 'company', country: 'BR', legalName: 'Org Eventos Ltda', taxId: '11222333000181', taxIdKind: 'cnpj',
  email: 'billing@org.test', address: { street: 'Rua A', number: '1', city: 'São Paulo', state: 'SP', postalCode: '01000-000', country: 'BR' },
};

async function seed() {
  await db.doc(`profiles/${ORG}`).set({
    displayName: 'Org', isBusiness: true, membershipTier: 'PLATINUM',
    membershipEndDate: TS.fromMillis(Date.now() + 365 * 24 * HOUR),
  });
  const base = { hasBaseMembership: true, baseMembershipEndDate: TS.fromMillis(Date.now() + 365 * 24 * HOUR) };
  for (const u of [BUYER, OTHER, THIRD]) await db.doc(`profiles/${u}`).set({ displayName: u, ...base });
  await db.doc(`finance_billing_profiles/${ORG}`).set(BILLING_OK);
  await db.doc(`payment_accounts/${ORG}`).set({
    uid: ORG, stripe: { accountId: 'acct_org', chargesEnabled: true, detailsSubmitted: true, status: 'ready', country: 'BR' },
    feeTrial: { key: null },
  });
}

async function paidEvent(id: string, over: Record<string, any> = {}) {
  await db.doc(`events/${id}`).set({
    organizerId: ORG, title: 'Rooftop Samba', price: 20, currency: 'R$', currencyCode: 'brl',
    maxAttendees: 0, attendeeCount: 0, maxTicketsPerUser: null, visibility: 'public',
    status: 'published', ticketProvider: 'stripe',
    startDate: TS.fromMillis(Date.now() + 24 * HOUR), endDate: TS.fromMillis(Date.now() + 28 * HOUR), ...over,
  });
}
async function freeEvent(id: string, over: Record<string, any> = {}) {
  await db.doc(`events/${id}`).set({
    organizerId: ORG, title: 'Language picnic', price: 0, maxAttendees: 20, attendeeCount: 0,
    guestsAllowedPerAttendee: 2, visibility: 'public', status: 'published',
    startDate: TS.fromMillis(Date.now() + 24 * HOUR), endDate: TS.fromMillis(Date.now() + 28 * HOUR), ...over,
  });
}
const order = async (id: string) => (await db.doc(`ticket_orders/${id}`).get()).data()!;
const ev = async (id: string) => (await db.doc(`events/${id}`).get()).data()!;

function stripeEvent(type: string, object: any) {
  const payload = JSON.stringify({ id: `evt_${crypto.randomBytes(6).toString('hex')}`, object: 'event', type, account: 'acct_org', data: { object } });
  const header = stripeVerifier().webhooks.generateTestHeaderString({ payload, secret: process.env.STRIPE_CONNECT_WEBHOOK_SECRET! });
  return { payload, header };
}
async function stripePaid(orderId: string, pi = `pi_${orderId}`) {
  const o = await order(orderId);
  const e = stripeEvent('checkout.session.completed', {
    id: o.providerRef.stripeSessionId, object: 'checkout.session', payment_status: 'paid', amount_total: o.totalAmount,
    currency: 'brl', payment_intent: pi, metadata: { orderId, greengo: 'ticket' },
  });
  return handleStripeConnectWebhook(Buffer.from(e.payload), e.header);
}

// ───────────────────────────── Firestore REST as a signed-in CLIENT (rules apply)
function idToken(uid: string): string {
  const b = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, firebase: { sign_in_provider: 'password' } })}.`;
}
function toValue(v: any): any {
  if (v === null) return { nullValue: null };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, toValue(x)])) } };
}
const fields = (data: Record<string, any>) => Object.fromEntries(Object.entries(data).map(([k, v]) => [k, toValue(v)]));
const docName = (path: string) => `projects/${PROJECT}/databases/(default)/documents/${path}`;

/** One atomic client write (like a transaction / batch): [{ path, data, mask? }]. */
async function clientCommit(uid: string, writes: Array<{ path: string; data: Record<string, any>; mask?: string[] }>): Promise<number> {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  const res = await fetch(`http://${host}/v1/projects/${PROJECT}/databases/(default)/documents:commit`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      writes: writes.map((w) => ({
        update: { name: docName(w.path), fields: fields(w.data) },
        ...(w.mask ? { updateMask: { fieldPaths: w.mask } } : {}),
      })),
    }),
  });
  await res.text();
  return res.status;
}
async function clientGet(uid: string, path: string): Promise<number> {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  const res = await fetch(`http://${host}/v1/projects/${PROJECT}/databases/(default)/documents/${path}`, {
    headers: { Authorization: `Bearer ${idToken(uid)}` },
  });
  await res.text();
  return res.status;
}

const attendee = (uid: string, eventId: string, over: Record<string, any> = {}) => ({
  eventId, userId: uid, userName: uid, status: 'going', rsvpDate: new Date(), isApproved: true,
  checkedIn: false, guestCount: 0, ...over,
});

beforeEach(async () => {
  await clearAll();
  sessionSeq = 0;
  await seed();
});
afterAll(() => fft.cleanup());

// ─────────────────────────────────────────────────────────── rule 2

describe('rule 2: at most 4 paid tickets per buyer per event', () => {
  test('a 5th ticket is refused across orders (paid + open holds), even with no event limit', async () => {
    await paidEvent('lim');
    const a = await call(tp.createTicketCheckout, { kind: 'event', id: 'lim', quantity: 2 }, BUYER);
    expect((await stripePaid(a.orderId)).status).toBe(200);
    // An open hold of 2 more (a different quantity: a new order, the paid one stays).
    const b = await call(tp.createTicketCheckout, { kind: 'event', id: 'lim', quantity: 2 }, BUYER);
    expect(b.orderId).not.toBe(a.orderId);
    const e = await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'lim', quantity: 3 }, BUYER));
    expect(e).toMatchObject({ code: 'failed-precondition', reason: 'ticket_limit_reached' });
    expect(e.details).toMatchObject({ limit: 4, kind: 'event' });
    // One order of 5 is refused outright; a different buyer is not affected.
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'lim', quantity: 5 }, OTHER))).reason)
      .toBe('ticket_limit_reached');
    await call(tp.createTicketCheckout, { kind: 'event', id: 'lim', quantity: 4 }, OTHER);
    // Cancelling the open order gives the allowance back (released with the seats).
    await call(tp.cancelTicketOrder, { orderId: b.orderId }, BUYER);
    const c = await call(tp.createTicketCheckout, { kind: 'event', id: 'lim', quantity: 2 }, BUYER);
    expect((await order(c.orderId)).quantity).toBe(2);
    expect((await db.doc(`ticket_holdings/event_lim_${BUYER}`).get()).data()).toMatchObject({ owned: 2, held: 2 });
  });

  test('an event limit above 4 is capped; a lower one still applies', async () => {
    await paidEvent('cap10', { maxTicketsPerUser: 10 });
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'cap10', quantity: 5 }, BUYER))).details)
      .toMatchObject({ limit: 4, remaining: 4 });
    await paidEvent('cap2', { maxTicketsPerUser: 2 });
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'cap2', quantity: 3 }, BUYER))).details)
      .toMatchObject({ limit: 2 });
  });

  test('a refund frees the allowance', async () => {
    await paidEvent('ref');
    const a = await call(tp.createTicketCheckout, { kind: 'event', id: 'ref', quantity: 4 }, BUYER);
    await stripePaid(a.orderId);
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'ref', quantity: 1 }, BUYER))).reason).toBe('ticket_limit_reached');
    expect(await markOrderReversed(a.orderId, 'refunded')).toBe(true);
    await call(tp.createTicketCheckout, { kind: 'event', id: 'ref', quantity: 4 }, BUYER);
  });

  test('guests (no account): 4 per e-mail per event', async () => {
    await paidEvent('gst', { guestsAllowed: true });
    const guest: GuestBuyer = { firstName: 'Gia', lastName: 'Rossi', returnUrl: (r, o) => `https://greengo-chat.web.app/guest/done/${o}?r=${r}` };
    const key = `guest_${'a'.repeat(40)}`;
    const first = await createTicketCheckout(key, { kind: 'event', id: 'gst', quantity: 3, platform: 'web' }, 'gia@x.test', guest);
    expect((await stripePaid(String(first.orderId))).status).toBe(200);
    // 3 paid with this e-mail: a 2nd order of 2 would make 5.
    const e = await refused(createTicketCheckout(key, { kind: 'event', id: 'gst', quantity: 2, platform: 'web' }, 'gia@x.test', guest));
    expect(e.reason).toBe('ticket_limit_reached');
    await createTicketCheckout(key, { kind: 'event', id: 'gst', quantity: 1, platform: 'web' }, 'gia@x.test', guest);
    // Another e-mail (another guest key) is independent.
    await createTicketCheckout(`guest_${'b'.repeat(40)}`, { kind: 'event', id: 'gst', quantity: 4, platform: 'web' }, 'bo@x.test', guest);
  });
});

// ─────────────────────────────────────────────────────────── rule 3

describe('rule 3: attendee names', () => {
  const two = [{ firstName: 'Ana', lastName: 'Lima' }, { firstName: 'João', lastName: 'Silva' }];

  test('required by the server when the event asks for them', async () => {
    await paidEvent('nm', { requireAttendeeNames: true });
    for (const attendees of [undefined, [], two.slice(0, 1), [two[0], { firstName: ' ', lastName: 'X' }], [two[0], { firstName: 'A'.repeat(51), lastName: 'X' }]]) {
      const e = await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'nm', quantity: 2, ...(attendees ? { attendees } : {}) }, BUYER));
      expect(e).toMatchObject({ code: 'invalid-argument', reason: 'attendee_names_required' });
    }
    // Events that do not ask ignore the names.
    await paidEvent('nn');
    const r0 = await call(tp.createTicketCheckout, { kind: 'event', id: 'nn', quantity: 2, attendees: two }, BUYER);
    expect((await order(r0.orderId)).attendeeNames).toBeNull();
  });

  test('stored per ticket and for the organizer only; removed on refund', async () => {
    await paidEvent('nm2', { requireAttendeeNames: true });
    const r = await call(tp.createTicketCheckout, {
      kind: 'event', id: 'nm2', quantity: 2, attendees: [{ firstName: '  Ana ', lastName: 'Lima' }, two[1]],
    }, BUYER);
    expect((await order(r.orderId)).attendeeNames).toEqual(two);
    await stripePaid(r.orderId);
    const tickets = (await db.collection('tickets').where('orderId', '==', r.orderId).get()).docs.map((d) => d.data())
      .sort((a, b) => a.index - b.index);
    expect(tickets.map((t) => t.attendeeName)).toEqual(['Ana Lima', 'João Silva']);
    expect(tickets[1]).toMatchObject({ attendeeFirstName: 'João', attendeeLastName: 'Silva' });
    const names = (await db.doc(`events/nm2/attendee_names/${BUYER}`).get()).data()!;
    expect(names.names.map((x: any) => `${x.firstName} ${x.lastName}`)).toEqual(['Ana Lima', 'João Silva']);
    // Privacy: the buyer and the organizer read them; another attendee / a stranger cannot; nobody writes.
    expect(await clientGet(BUYER, `events/nm2/attendee_names/${BUYER}`)).toBe(200);
    expect(await clientGet(ORG, `events/nm2/attendee_names/${BUYER}`)).toBe(200);
    expect(await clientGet(OTHER, `events/nm2/attendee_names/${BUYER}`)).toBe(403);
    expect(await clientCommit(BUYER, [{ path: `events/nm2/attendee_names/${BUYER}`, data: { names: [] } }])).toBe(403);
    // A second order adds its holders; a refund removes only its own.
    const r2 = await call(tp.createTicketCheckout, { kind: 'event', id: 'nm2', quantity: 1, attendees: [{ firstName: 'Bia', lastName: 'Reis' }] }, BUYER);
    await stripePaid(r2.orderId);
    expect((await db.doc(`events/nm2/attendee_names/${BUYER}`).get()).data()!.names).toHaveLength(3);
    await markOrderReversed(r.orderId, 'refunded');
    expect((await db.doc(`events/nm2/attendee_names/${BUYER}`).get()).data()!.names.map((x: any) => x.firstName)).toEqual(['Bia']);
    await markOrderReversed(r2.orderId, 'refunded');
    expect((await db.doc(`events/nm2/attendee_names/${BUYER}`).get()).exists).toBe(false);
  });

  test('the organizer setting is a bool', async () => {
    await paidEvent('nb');
    expect(await clientCommit(ORG, [{ path: 'events/nb', data: { requireAttendeeNames: true }, mask: ['requireAttendeeNames'] }])).toBe(200);
    expect(await clientCommit(ORG, [{ path: 'events/nb', data: { requireAttendeeNames: 'yes' }, mask: ['requireAttendeeNames'] }])).toBe(403);
  });
});

// ─────────────────────────────────────────────────────────── rule 1

describe('rule 1: no plus-ones on paid events', () => {
  test('a client attendee doc with guests on a paid event is refused', async () => {
    await paidEvent('po', { guestsAllowedPerAttendee: 2 });
    // Server-written buyer (2 tickets: guestCount 1 = a paid seat, not a plus-one).
    await db.doc(`events/po/attendees/${BUYER}`).set(attendee(BUYER, 'po', { guestCount: 1, ticketCount: 2 }));
    expect(await clientCommit(BUYER, [{ path: `events/po/attendees/${BUYER}`, data: { guestCount: 3 }, mask: ['guestCount'] }])).toBe(403);
    expect(await clientCommit(OTHER, [{ path: `events/po/attendees/${OTHER}`, data: attendee(OTHER, 'po', { status: 'interested', guestCount: 1 }) }])).toBe(403);
    expect(await clientCommit(ORG, [{ path: `events/po/attendees/${THIRD}`, data: attendee(THIRD, 'po', { guestCount: 1 }) }])).toBe(403);
    // Unrelated edits of the buyer's own doc still work (guestCount unchanged).
    expect(await clientCommit(BUYER, [{ path: `events/po/attendees/${BUYER}`, data: { muteNotifications: true }, mask: ['muteNotifications'] }])).toBe(200);
  });

  test('the organizer cannot set plus-ones on a paid event (older values stay editable)', async () => {
    await paidEvent('pe', { guestsAllowedPerAttendee: 2 }); // created before the rule
    expect(await clientCommit(ORG, [{ path: 'events/pe', data: { title: 'New title' }, mask: ['title'] }])).toBe(200);
    expect(await clientCommit(ORG, [{ path: 'events/pe', data: { guestsAllowedPerAttendee: 3 }, mask: ['guestsAllowedPerAttendee'] }])).toBe(403);
    expect(await clientCommit(ORG, [{ path: 'events/pe', data: { guestsAllowedPerAttendee: 0 }, mask: ['guestsAllowedPerAttendee'] }])).toBe(200);
    // A free event with plus-ones turning paid must drop them.
    await freeEvent('fp');
    expect(await clientCommit(ORG, [{ path: 'events/fp', data: { price: 20, currency: 'R$', currencyCode: 'brl', ticketProvider: 'stripe' }, mask: ['price', 'currency', 'currencyCode', 'ticketProvider'] }])).toBe(403);
    expect(await clientCommit(ORG, [{ path: 'events/fp', data: { price: 20, currency: 'R$', currencyCode: 'brl', ticketProvider: 'stripe', guestsAllowedPerAttendee: 0 }, mask: ['price', 'currency', 'currencyCode', 'ticketProvider', 'guestsAllowedPerAttendee'] }])).toBe(200);
  });
});

// ─────────────────────────────────────────────────────────── rule 5

describe('rule 5: free events count places (1 + plus-ones)', () => {
  test('capacity 20 with one +1 RSVP leaves 18; the counter must move with the plus-ones', async () => {
    await freeEvent('fr');
    // Join (the app's transaction: attendee + counter).
    expect(await clientCommit(BUYER, [
      { path: `events/fr/attendees/${BUYER}`, data: attendee(BUYER, 'fr') },
      { path: 'events/fr', data: { attendeeCount: 1 }, mask: ['attendeeCount'] },
    ])).toBe(200);
    // +1 without moving the counter: refused.
    expect(await clientCommit(BUYER, [{ path: `events/fr/attendees/${BUYER}`, data: { guestCount: 1 }, mask: ['guestCount'] }])).toBe(403);
    // +1 with the counter moving by exactly 1: accepted -> 2 places taken, 18 left.
    expect(await clientCommit(BUYER, [
      { path: `events/fr/attendees/${BUYER}`, data: { guestCount: 1 }, mask: ['guestCount'] },
      { path: 'events/fr', data: { attendeeCount: 2 }, mask: ['attendeeCount'] },
    ])).toBe(200);
    const e = await ev('fr');
    expect(e.maxAttendees - e.attendeeCount).toBe(18);
    // Wrong delta, or more plus-ones than the organizer allows: refused.
    expect(await clientCommit(BUYER, [
      { path: `events/fr/attendees/${BUYER}`, data: { guestCount: 2 }, mask: ['guestCount'] },
      { path: 'events/fr', data: { attendeeCount: 2 }, mask: ['attendeeCount'] },
    ])).toBe(403);
    expect(await clientCommit(BUYER, [
      { path: `events/fr/attendees/${BUYER}`, data: { guestCount: 3 }, mask: ['guestCount'] },
      { path: 'events/fr', data: { attendeeCount: 4 }, mask: ['attendeeCount'] },
    ])).toBe(403);
    // Fewer plus-ones give the places back.
    expect(await clientCommit(BUYER, [
      { path: `events/fr/attendees/${BUYER}`, data: { guestCount: 0 }, mask: ['guestCount'] },
      { path: 'events/fr', data: { attendeeCount: 1 }, mask: ['attendeeCount'] },
    ])).toBe(200);
  });

  test('capacity edge: plus-ones and joins never go past the capacity', async () => {
    await freeEvent('edge', { maxAttendees: 3, attendeeCount: 2, guestsAllowedPerAttendee: 5 });
    await db.doc(`events/edge/attendees/${BUYER}`).set(attendee(BUYER, 'edge', { guestCount: 1 }));
    // 2 taken of 3: +1 more fits (3/3), +2 does not.
    expect(await clientCommit(BUYER, [
      { path: `events/edge/attendees/${BUYER}`, data: { guestCount: 3 }, mask: ['guestCount'] },
      { path: 'events/edge', data: { attendeeCount: 4 }, mask: ['attendeeCount'] },
    ])).toBe(403);
    expect(await clientCommit(BUYER, [
      { path: `events/edge/attendees/${BUYER}`, data: { guestCount: 2 }, mask: ['guestCount'] },
      { path: 'events/edge', data: { attendeeCount: 3 }, mask: ['attendeeCount'] },
    ])).toBe(200);
    // Full: another member cannot join as going (waitlist is fine).
    expect(await clientCommit(OTHER, [
      { path: `events/edge/attendees/${OTHER}`, data: attendee(OTHER, 'edge') },
      { path: 'events/edge', data: { attendeeCount: 4 }, mask: ['attendeeCount'] },
    ])).toBe(403);
    expect(await clientCommit(OTHER, [{ path: `events/edge/attendees/${OTHER}`, data: attendee(OTHER, 'edge', { status: 'waitlist' }) }])).toBe(200);
    // Promotion: only when the counter (updated in the same write) stays within the capacity.
    expect(await clientCommit(THIRD, [
      { path: `events/edge/attendees/${OTHER}`, data: { status: 'going' }, mask: ['status'] },
      { path: 'events/edge', data: { attendeeCount: 4 }, mask: ['attendeeCount'] },
    ])).toBe(403);
    expect(await clientCommit(BUYER, [
      { path: `events/edge/attendees/${BUYER}`, data: { guestCount: 1 }, mask: ['guestCount'] },
      { path: 'events/edge', data: { attendeeCount: 2 }, mask: ['attendeeCount'] },
    ])).toBe(200);
    expect(await clientCommit(THIRD, [
      { path: `events/edge/attendees/${OTHER}`, data: { status: 'going' }, mask: ['status'] },
      { path: 'events/edge', data: { attendeeCount: 3 }, mask: ['attendeeCount'] },
    ])).toBe(200);
  });

  test('the organizer roster and unlimited events are not capped', async () => {
    await freeEvent('unl', { maxAttendees: 0, attendeeCount: 50 });
    expect(await clientCommit(BUYER, [
      { path: `events/unl/attendees/${BUYER}`, data: attendee(BUYER, 'unl') },
      { path: 'events/unl', data: { attendeeCount: 51 }, mask: ['attendeeCount'] },
    ])).toBe(200);
    await freeEvent('org', { maxAttendees: 1, attendeeCount: 1 });
    expect(await clientCommit(ORG, [{ path: `events/org/attendees/${OTHER}`, data: attendee(OTHER, 'org') }])).toBe(200);
  });
});

// ─────────────────────────────────────────────────────────── rule 4

describe('rule 4: capacity vs price phases', () => {
  const PHASES = [
    { id: 'eb', nameKey: 'earlyBird', price: 20, quantity: 3 },
    { id: 'rg', nameKey: 'regular', price: 30, quantity: 4 },
  ];
  test('lowering the capacity below the phases total pauses the sales', async () => {
    await paidEvent('ph', { pricePhases: PHASES, maxAttendees: 7 });
    await call(tp.createTicketCheckout, { kind: 'event', id: 'ph', quantity: 1 }, BUYER);
    // The organizer writes the event directly (rules only check the phase shape).
    expect(await clientCommit(ORG, [{ path: 'events/ph', data: { maxAttendees: 5 }, mask: ['maxAttendees'] }])).toBe(200);
    const e = await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'ph', quantity: 1 }, OTHER));
    expect(e).toMatchObject({ code: 'failed-precondition', reason: 'price_phases_invalid' });
    expect(e.details.reason).toBe('phases_exceed_capacity');
    // Back to a capacity that holds every phase: on sale again.
    await db.doc('events/ph').update({ maxAttendees: 8 });
    await call(tp.createTicketCheckout, { kind: 'event', id: 'ph', quantity: 1 }, OTHER);
  });
});
