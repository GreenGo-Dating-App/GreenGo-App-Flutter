/**
 * Ticket price phases (functions/src/ticket_payments/pricePhases.ts + the
 * order lifecycle in orders.ts): emulator integration tests. Real Firestore /
 * Auth emulators; only the Stripe API is faked (ticketDeps).
 *
 *   concurrent buyers cannot oversell a phase, orders spanning phases (lines +
 *   per-ticket fee + Stripe line items + tickets), release on cancel / expiry
 *   / refund, late payment, server-side price (old apps), price_changed,
 *   editing after sales, all phases sold out, and the rules: clients cannot
 *   write the counters, phase shape + order checked on the event doc.
 *
 * Run against BOTH rule files (firestore.rules and firestore.additive.rules):
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "cd functions && npx jest -i __tests__/security/ticket-price-phases.emulator.test.ts"
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
import { expireDueOrders } from '../../src/ticket_payments/orders';
import { feePerTicket } from '../../src/ticket_payments/fees';

const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const HOUR = 3600 * 1000;

const stripeCalls: any[] = [];
let sessionSeq = 0;
const fakeStripe: any = {
  checkout: {
    sessions: {
      create: jest.fn(async (params: any, opts: any) => {
        stripeCalls.push({ params, opts });
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
const STRANGER = 'stranger01';

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
  // Stripe ready; the trial already decided (none), so the PLATINUM rule
  // applies and the fee differs per phase price.
  await db.doc(`payment_accounts/${ORG}`).set({
    uid: ORG, stripe: { accountId: 'acct_org', chargesEnabled: true, detailsSubmitted: true, status: 'ready', country: 'BR' },
    feeTrial: { key: null },
  });
}

const PHASES = [
  { id: 'eb', nameKey: 'earlyBird', price: 20, quantity: 2 },
  { id: 'rg', nameKey: 'regular', price: 30, quantity: 3 },
  { id: 'lt', nameKey: 'late', price: 40, quantity: 2 },
];
async function phasedEvent(id: string, over: Record<string, any> = {}) {
  await db.doc(`events/${id}`).set({
    organizerId: ORG, latitude: 41.15, longitude: -8.61, title: 'Rooftop Samba', price: 20, currency: 'R$', currencyCode: 'brl',
    maxAttendees: 0, attendeeCount: 0, maxTicketsPerUser: null,
    status: 'published', ticketProvider: 'stripe', pricePhases: PHASES,
    startDate: TS.fromMillis(Date.now() + 24 * HOUR), endDate: TS.fromMillis(Date.now() + 28 * HOUR), ...over,
  });
}
const inv = async (id: string) => (await db.doc(`ticket_inventory/event_${id}`).get()).data() || {};
const order = async (id: string) => (await db.doc(`ticket_orders/${id}`).get()).data()!;

function stripeEvent(type: string, object: any) {
  const payload = JSON.stringify({ id: `evt_${crypto.randomBytes(6).toString('hex')}`, object: 'event', type, account: 'acct_org', data: { object } });
  const header = stripeVerifier().webhooks.generateTestHeaderString({ payload, secret: process.env.STRIPE_CONNECT_WEBHOOK_SECRET! });
  return { payload, header };
}
async function stripePaid(orderId: string, pi = 'pi_1') {
  const o = await order(orderId);
  const ev = stripeEvent('checkout.session.completed', {
    id: o.providerRef.stripeSessionId, object: 'checkout.session', payment_status: 'paid', amount_total: o.totalAmount,
    currency: 'brl', payment_intent: pi, metadata: { orderId, greengo: 'ticket' },
  });
  return handleStripeConnectWebhook(Buffer.from(ev.payload), ev.header);
}

// Firestore REST as a signed-in CLIENT (rules apply).
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
async function clientGet(uid: string, path: string): Promise<number> {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  const res = await fetch(`http://${host}/v1/projects/${PROJECT}/databases/(default)/documents/${path}`, {
    headers: { Authorization: `Bearer ${idToken(uid)}` },
  });
  await res.text();
  return res.status;
}

beforeEach(async () => {
  await clearAll();
  stripeCalls.length = 0;
  await seed();
});
afterAll(() => fft.cleanup());

describe('selling by price phase', () => {
  test('an order spanning phases: each ticket at its phase, fee per ticket, Stripe lines, tickets, event price follows', async () => {
    await phasedEvent('pp');
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'pp', quantity: 3, expectedTotal: 2 * 2000 + 3000 }, BUYER);
    expect(r.mode).toBe('instant');
    const o = await order(r.orderId);
    expect(o.phaseLines).toEqual([
      { phaseId: 'eb', nameKey: 'earlyBird', unitAmount: 2000, quantity: 2 },
      { phaseId: 'rg', nameKey: 'regular', unitAmount: 3000, quantity: 1 },
    ]);
    const fEb = feePerTicket('platinum', 2000, 'brl')!;
    const fRg = feePerTicket('platinum', 3000, 'brl')!;
    expect(o).toMatchObject({
      quantity: 3, ticketSubtotal: 7000, totalAmount: 7000, feeTotal: 2 * fEb + fRg, feePerTicket: null,
      hostNet: 7000 - 2 * fEb - fRg, feeRuleApplied: 'platinum', items: null,
    });
    expect(o.feeLines).toEqual([{ phaseId: 'eb', unitFee: fEb, quantity: 2 }, { phaseId: 'rg', unitFee: fRg, quantity: 1 }]);
    // Stripe: one line per phase, the fee kept from the host's charge.
    const p = stripeCalls[0].params;
    expect(p.line_items.map((x: any) => [x.price_data.unit_amount, x.quantity])).toEqual([[2000, 2], [3000, 1]]);
    expect(p.line_items[0].price_data.product_data.name).toContain('Early bird');
    expect(p.payment_intent_data.application_fee_amount).toBe(2 * fEb + fRg);
    // Reserved per phase; the doc's price (old apps) moved on to the current phase.
    expect((await inv('pp')).phaseSold).toEqual({ eb: 2, rg: 1 });
    expect((await inv('pp')).phaseLocks).toEqual({ eb: 2000, rg: 3000 });
    expect((await db.doc('events/pp').get()).data()!.price).toBe(30);

    expect((await stripePaid(r.orderId)).status).toBe(200);
    const tickets = (await db.collection('tickets').where('orderId', '==', r.orderId).get()).docs.map((d) => d.data())
      .sort((a, b) => a.index - b.index);
    expect(tickets.map((t) => [t.pricePhaseId, t.pricePhaseNameKey, t.unitAmount])).toEqual([
      ['eb', 'earlyBird', 2000], ['eb', 'earlyBird', 2000], ['rg', 'regular', 3000],
    ]);
    // Paid tickets stay counted.
    expect((await inv('pp')).phaseSold).toEqual({ eb: 2, rg: 1 });
  });

  test('concurrent buyers cannot oversell a phase (two transactions)', async () => {
    await phasedEvent('race', { pricePhases: [{ id: 'eb', nameKey: 'earlyBird', price: 20, quantity: 1 }] });
    const both = await Promise.allSettled([
      call(tp.createTicketCheckout, { kind: 'event', id: 'race', quantity: 1 }, BUYER),
      call(tp.createTicketCheckout, { kind: 'event', id: 'race', quantity: 1 }, OTHER),
    ]);
    expect(both.filter((x) => x.status === 'fulfilled')).toHaveLength(1);
    const no = both.find((x) => x.status === 'rejected') as PromiseRejectedResult;
    expect(no.reason.details?.code).toBe('sold_out');
    expect((await inv('race')).phaseSold).toEqual({ eb: 1 });
  });

  test('racing buyers across two phases each get a different phase, never more than the stock', async () => {
    await phasedEvent('race2', {
      pricePhases: [{ id: 'eb', nameKey: 'earlyBird', price: 20, quantity: 1 }, { id: 'rg', nameKey: 'regular', price: 30, quantity: 1 }],
    });
    const all = await Promise.allSettled([BUYER, OTHER, THIRD].map((u) => call(tp.createTicketCheckout, { kind: 'event', id: 'race2' }, u)));
    expect(all.filter((x) => x.status === 'fulfilled')).toHaveLength(2);
    expect((await inv('race2')).phaseSold).toEqual({ eb: 1, rg: 1 });
    const lines = (await db.collection('ticket_orders').where('listingId', '==', 'race2').get()).docs
      .filter((d) => d.data().status !== 'cancelled').map((d) => d.data().phaseLines[0].phaseId).sort();
    expect(lines).toEqual(['eb', 'rg']);
  });

  test('every phase sold out = sold out for ticket sales (capacity still an extra limit)', async () => {
    await phasedEvent('so', { pricePhases: [{ id: 'eb', nameKey: 'earlyBird', price: 20, quantity: 2 }] });
    await call(tp.createTicketCheckout, { kind: 'event', id: 'so', quantity: 2 }, BUYER);
    const e = await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'so', quantity: 1 }, OTHER));
    expect(e).toMatchObject({ code: 'resource-exhausted', reason: 'sold_out' });
    expect(e.details.remaining).toBe(0);
    // Capacity below the phase stock still limits.
    await phasedEvent('cap', { maxAttendees: 7, attendeeCount: 6 });
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'cap', quantity: 2 }, OTHER))).reason).toBe('sold_out');
  });

  test('cancel and expiry give the phase tickets back (the early bird price returns)', async () => {
    await phasedEvent('rel');
    const a = await call(tp.createTicketCheckout, { kind: 'event', id: 'rel', quantity: 2 }, BUYER);
    const b = await call(tp.createTicketCheckout, { kind: 'event', id: 'rel', quantity: 1 }, OTHER);
    expect((await order(b.orderId)).phaseLines[0].phaseId).toBe('rg');
    await call(tp.cancelTicketOrder, { orderId: a.orderId }, BUYER);
    expect((await inv('rel')).phaseSold).toEqual({ eb: 0, rg: 1 });
    // The next buyer gets the early bird again.
    const c = await call(tp.createTicketCheckout, { kind: 'event', id: 'rel', quantity: 1 }, THIRD);
    expect((await order(c.orderId)).phaseLines).toEqual([{ phaseId: 'eb', nameKey: 'earlyBird', unitAmount: 2000, quantity: 1 }]);
    await db.doc(`ticket_orders/${c.orderId}`).update({ expiresAt: TS.fromMillis(Date.now() - 1000) });
    await db.doc(`ticket_orders/${b.orderId}`).update({ expiresAt: TS.fromMillis(Date.now() - 1000) });
    expect(await expireDueOrders()).toBe(2);
    expect((await inv('rel')).phaseSold).toEqual({ eb: 0, rg: 0 });
    // Closing twice never releases twice.
    await call(tp.cancelTicketOrder, { orderId: c.orderId }, THIRD);
    expect((await inv('rel')).phaseSold).toEqual({ eb: 0, rg: 0 });
  });

  test('a superseded order of the same buyer releases its phase tickets in the same transaction', async () => {
    await phasedEvent('sup', { pricePhases: [{ id: 'eb', nameKey: 'earlyBird', price: 20, quantity: 2 }, ...PHASES.slice(1)] });
    await call(tp.createTicketCheckout, { kind: 'event', id: 'sup', quantity: 2 }, BUYER);
    const again = await call(tp.createTicketCheckout, { kind: 'event', id: 'sup', quantity: 1 }, BUYER);
    expect((await order(again.orderId)).phaseLines).toEqual([{ phaseId: 'eb', nameKey: 'earlyBird', unitAmount: 2000, quantity: 1 }]);
    expect((await inv('sup')).phaseSold).toEqual({ eb: 1 });
  });

  test('refund of a paid order frees its phase tickets; a late payment counts them again', async () => {
    await phasedEvent('rf');
    const a = await call(tp.createTicketCheckout, { kind: 'event', id: 'rf', quantity: 2 }, BUYER);
    await stripePaid(a.orderId, 'pi_rf');
    const ev = stripeEvent('charge.refunded', { id: 'ch_rf', payment_intent: 'pi_rf', amount: 4000, amount_refunded: 4000, refunded: true });
    expect((await handleStripeConnectWebhook(Buffer.from(ev.payload), ev.header)).status).toBe(200);
    expect((await order(a.orderId)).status).toBe('refunded');
    expect((await inv('rf')).phaseSold).toEqual({ eb: 0 });

    const b = await call(tp.createTicketCheckout, { kind: 'event', id: 'rf', quantity: 1 }, OTHER);
    await db.doc(`ticket_orders/${b.orderId}`).update({ expiresAt: TS.fromMillis(Date.now() - 1000) });
    await expireDueOrders();
    expect((await inv('rf')).phaseSold).toEqual({ eb: 0 });
    await stripePaid(b.orderId, 'pi_late');
    expect((await order(b.orderId)).status).toBe('paid');
    expect((await inv('rf')).phaseSold).toEqual({ eb: 1 });
  });
});

describe('the server decides the price', () => {
  test('an old app (no expectedTotal) showing a stale base price pays the current phase price', async () => {
    await phasedEvent('old', { price: 5 });
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'old', quantity: 1 }, BUYER);
    expect((await order(r.orderId)).totalAmount).toBe(2000);
  });

  test('price_changed when the phase moved on since the buyer looked; the retry with the new total works', async () => {
    await phasedEvent('pc');
    await call(tp.createTicketCheckout, { kind: 'event', id: 'pc', quantity: 2 }, OTHER);
    const e = await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'pc', quantity: 1, expectedTotal: 2000 }, BUYER));
    expect(e).toMatchObject({ code: 'failed-precondition', reason: 'price_changed' });
    expect(e.details).toMatchObject({ total: 3000, currency: 'brl', quantity: 1 });
    expect(e.details.lines).toEqual([{ phaseId: 'rg', nameKey: 'regular', unitAmount: 3000, quantity: 1 }]);
    expect((await db.collection('ticket_orders').where('buyerId', '==', BUYER).get()).size).toBe(0);
    const ok = await call(tp.createTicketCheckout, { kind: 'event', id: 'pc', quantity: 1, expectedTotal: 3000 }, BUYER);
    expect(ok.amount).toBe(3000);
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'pc', expectedTotal: 'x' }, BUYER))).reason)
      .toBe('invalid_expected_total');
  });

  test('editing after sales: a sold phase cannot be repriced / removed / shrunk; never sold from an invalid setup', async () => {
    await phasedEvent('ed');
    await call(tp.createTicketCheckout, { kind: 'event', id: 'ed', quantity: 1 }, OTHER);
    const tryWith = async (pricePhases: any[]) => {
      await db.doc('events/ed').update({ pricePhases });
      return refused(call(tp.createTicketCheckout, { kind: 'event', id: 'ed', quantity: 1 }, BUYER));
    };
    expect((await tryWith([{ ...PHASES[0], price: 25 }, ...PHASES.slice(1)])).details.reason).toBe('phase_with_sales_price_changed');
    expect((await tryWith(PHASES.slice(1))).details.reason).toBe('phase_with_sales_removed');
    expect((await tryWith([{ ...PHASES[0], quantity: 0 }, ...PHASES.slice(1)])).details.reason).toBe('invalid_phase_quantity');
    expect((await tryWith([PHASES[1], PHASES[0]])).details.reason).toBe('phase_prices_not_increasing');
    // A new phase may not go before a phase that has sold.
    expect((await tryWith([{ id: 'nw', nameKey: 'superEarlyBird', price: 15, quantity: 1 }, ...PHASES])).details.reason)
      .toBe('phase_inserted_before_sold');
    // Over the capacity.
    await db.doc('events/ed').update({ maxAttendees: 5 });
    expect((await tryWith(PHASES)).details.reason).toBe('phases_exceed_capacity');
    await db.doc('events/ed').update({ maxAttendees: 0 });
    // Allowed: an unsold phase edited, a new one added after the last.
    await db.doc('events/ed').update({
      pricePhases: [PHASES[0], { ...PHASES[1], price: 35, quantity: 9 }, PHASES[2], { id: 'dr', nameKey: 'door', price: 60, quantity: 5 }],
    });
    const ok = await call(tp.createTicketCheckout, { kind: 'event', id: 'ed', quantity: 1 }, BUYER);
    expect(ok.amount).toBe(2000);
  });
});

describe('rules', () => {
  test('clients cannot write the counters; signed-in users may read one inventory doc', async () => {
    await phasedEvent('ru');
    await call(tp.createTicketCheckout, { kind: 'event', id: 'ru', quantity: 1 }, BUYER);
    for (const uid of [ORG, BUYER, STRANGER]) {
      expect(await clientWrite(uid, 'ticket_inventory/event_ru', { phaseSold: { eb: 0 } }, ['phaseSold'])).toBe(403);
      expect(await clientWrite(uid, 'ticket_inventory/event_new', { phaseSold: { eb: 0 } })).toBe(403);
    }
    expect(await clientGet(STRANGER, 'ticket_inventory/event_ru')).toBe(200);
    // No listing of the whole collection.
    expect(await clientGet(STRANGER, 'ticket_inventory')).not.toBe(200);
  });

  test('the organizer edits the phases only with a valid shape and increasing prices', async () => {
    await phasedEvent('re');
    expect(await clientWrite(ORG, 'events/re', { pricePhases: [...PHASES, { id: 'dr', nameKey: 'door', price: 50, quantity: 1 }] }, ['pricePhases'])).toBe(200);
    expect(await clientWrite(ORG, 'events/re', { pricePhases: [PHASES[1], PHASES[0]] }, ['pricePhases'])).toBe(403);
    expect(await clientWrite(ORG, 'events/re', { pricePhases: [{ ...PHASES[0], price: 1001 }] }, ['pricePhases'])).toBe(403);
    expect(await clientWrite(ORG, 'events/re', { pricePhases: [{ ...PHASES[0], quantity: 0 }] }, ['pricePhases'])).toBe(403);
    expect(await clientWrite(ORG, 'events/re', { pricePhases: [{ ...PHASES[0], nameKey: 'vip' }] }, ['pricePhases'])).toBe(403);
    expect(await clientWrite(ORG, 'events/re', { pricePhases: [{ ...PHASES[0], sold: 3 }] }, ['pricePhases'])).toBe(403);
    expect(await clientWrite(ORG, 'events/re', { pricePhases: [] }, ['pricePhases'])).toBe(200);
    expect(await clientWrite(STRANGER, 'events/re', { pricePhases: PHASES }, ['pricePhases'])).toBe(403);
  });
});
