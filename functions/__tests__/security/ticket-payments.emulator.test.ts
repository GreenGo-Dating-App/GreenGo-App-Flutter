/**
 * Paid tickets for events + experiences (functions/src/ticket_payments/):
 * emulator integration tests. Real Firestore / Auth / Storage emulators; ONLY
 * the Stripe API and the Mercado Pago HTTP API are faked (ticketDeps).
 *
 * Covers both modes:
 *   instant (Stripe Connect Standard / Mercado Pago): price from the server,
 *     capacity + 30-min hold, webhook signature rejection, idempotent paid,
 *     MP re-fetch mismatch rejected, refund invalidates the QR;
 *   link (organizer confirms): code + method snapshot, buyer cannot
 *     self-confirm, only the organizer confirms / rejects, reject + expiry
 *     release the seat, receipt storage limited to buyer + organizer;
 * plus the closed bypasses (firestore.rules) and free events unchanged.
 *
 *   firebase emulators:exec --config ../firebase.emulators.<you>.json \
 *     --only firestore,auth,storage --project test-project "npx jest --config jest.security.config.js"
 */

process.env.STRIPE_SECRET_KEY = 'sk_test_platform_fake';
process.env.STRIPE_CONNECT_WEBHOOK_SECRET = 'whsec_test_connect';
process.env.MP_CLIENT_ID = 'mp-client';
process.env.MP_CLIENT_SECRET = 'mp-secret';
process.env.MP_WEBHOOK_SECRET = 'mp-webhook-secret';
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
import { handleMercadoPagoWebhook, handleStripeConnectWebhook, stripeVerifier } from '../../src/ticket_payments/webhooks';
import { expireDueOrders, PAYMENT_CODE_RE, remindDueConfirmations } from '../../src/ticket_payments/orders';
import { ticketQrPayload, verifyTicketQr } from '../../src/ticket_payments/tokens';
import { getEventTicketCode, checkInTicket, checkInEventAttendee, eventTicketCode } from '../../src/checkin/eventCheckin';
import { getBookingCheckInCode } from '../../src/experience_bookings/functions';

const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const HOUR = 3600 * 1000;
const KEY = process.env.TICKET_QR_SIGNING_KEY!;

// ─────────────────────────────────────────────── fakes

const stripeCalls: any[] = [];
let sessionSeq = 0;
const fakeStripe: any = {
  accounts: {
    create: jest.fn(async (p: any) => ({ id: 'acct_org', charges_enabled: false, details_submitted: false, payouts_enabled: false, country: 'BR', default_currency: 'brl', metadata: p.metadata })),
    retrieve: jest.fn(async (id: string) => ({ id, charges_enabled: true, details_submitted: true, payouts_enabled: true, country: 'BR', default_currency: 'brl' })),
  },
  accountLinks: { create: jest.fn(async () => ({ url: 'https://connect.stripe.test/onboard' })) },
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

let mpPayment: any = null;
const mpCalls: Array<{ url: string; init: any }> = [];
const fakeFetch = jest.fn(async (url: string, init?: any) => {
  mpCalls.push({ url, init });
  const json = (status: number, b: any) => ({ ok: status < 400, status, text: async () => JSON.stringify(b) }) as any;
  if (url.endsWith('/oauth/token')) {
    return json(200, { access_token: 'APP_USR-org-token', refresh_token: 'TG-refresh', user_id: 777, expires_in: 15552000, live_mode: false, public_key: 'pk' });
  }
  if (url.endsWith('/users/me')) return json(200, { id: 777, site_id: 'MLB', country_id: 'BR' });
  if (url.endsWith('/checkout/preferences')) return json(201, { id: 'pref_1', init_point: 'https://mp.test/checkout/pref_1' });
  if (url.endsWith('/refunds')) return json(201, { id: 9001, status: 'approved' });
  if (url.includes('/v1/payments/search')) return json(200, { results: [] });
  if (url.includes('/v1/payments/')) return mpPayment ? json(200, mpPayment) : json(404, {});
  return json(404, {});
});

ticketDeps.stripe = () => fakeStripe;
ticketDeps.fetch = fakeFetch as any;

// ─────────────────────────────────────────────── helpers

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

const call = (fn: any, data: any, uid: string, token: Record<string, any> = {}) =>
  (fft.wrap(fn) as any)({ data, auth: { uid, token } });
async function refused(p: Promise<any>): Promise<any> {
  try { await p; } catch (e: any) { return { code: e.code, reason: e.details?.code ?? e.message }; }
  throw new Error('expected a refusal');
}

const ORG = 'organizer01';
const BUYER = 'buyer01';
const OTHER = 'buyer02';
const STRANGER = 'stranger01';

async function seedProfiles() {
  await db.doc(`profiles/${ORG}`).set({ displayName: 'Org', paymentLinks: { pix: 'org@pix.example', paypal: 'https://paypal.me/org' } });
  await db.doc(`profiles/${BUYER}`).set({ displayName: 'Buyer', photoUrls: ['https://x/b.jpg'] });
  await db.doc(`profiles/${OTHER}`).set({ displayName: 'Other' });
}
async function connectStripe() {
  await db.doc(`payment_accounts/${ORG}`).set({ uid: ORG, stripe: { accountId: 'acct_org', chargesEnabled: true, detailsSubmitted: true, status: 'ready', country: 'BR' } });
}
async function connectMp() {
  await call(tp.startMercadoPagoOnboarding, {}, ORG); // creates the pending doc
  const { signState } = await import('../../src/ticket_payments/tokens');
  const state = signState(KEY, ORG, Date.now());
  const { handleMpOAuthCallback } = await import('../../src/ticket_payments/accounts');
  const r = await handleMpOAuthCallback({ state, code: 'auth-code' });
  expect(r.status).toBeLessThan(400);
}
async function paidEvent(id: string, over: Record<string, any> = {}) {
  await db.doc(`events/${id}`).set({
    organizerId: ORG, title: 'Rooftop Samba', price: 25, currency: 'R$', maxAttendees: 0, attendeeCount: 0,
    status: 'published', ticketProvider: 'stripe', guestsAllowedPerAttendee: 1,
    startDate: TS.fromMillis(Date.now() + HOUR), endDate: TS.fromMillis(Date.now() + 4 * HOUR), ...over,
  });
}

function stripeEvent(type: string, object: any, account = 'acct_org', id = `evt_${crypto.randomBytes(6).toString('hex')}`) {
  const payload = JSON.stringify({ id, object: 'event', type, account, data: { object } });
  const header = stripeVerifier().webhooks.generateTestHeaderString({ payload, secret: process.env.STRIPE_CONNECT_WEBHOOK_SECRET! });
  return { payload, header };
}
async function stripePaid(orderId: string, amount: number, _sessionId?: string, pi = 'pi_1') {
  const sessionId = (await db.doc(`ticket_orders/${orderId}`).get()).data()!.providerRef.stripeSessionId;
  const ev = stripeEvent('checkout.session.completed', {
    id: sessionId, object: 'checkout.session', payment_status: 'paid', amount_total: amount, currency: 'brl',
    payment_intent: pi, metadata: { orderId, greengo: 'ticket' },
  });
  return handleStripeConnectWebhook(Buffer.from(ev.payload), ev.header);
}

function mpSignature(dataId: string, requestId: string, secret = process.env.MP_WEBHOOK_SECRET!) {
  const ts = String(Date.now());
  const manifest = `id:${dataId};request-id:${requestId};ts:${ts};`;
  return `ts=${ts},v1=${crypto.createHmac('sha256', secret).update(manifest).digest('hex')}`;
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
  if (v instanceof Date) return { timestampValue: v.toISOString() };
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
const realFetch: typeof fetch = (globalThis as any).fetch;

// Storage REST as a client (storage.rules apply).
async function storageUpload(uid: string, path: string, contentType = 'image/jpeg', bytes = 1024): Promise<number> {
  const host = process.env.FIREBASE_STORAGE_EMULATOR_HOST!;
  const B = `gg${crypto.randomBytes(6).toString('hex')}`;
  // Same multipart shape as the Firebase client SDKs (the metadata carries the content type).
  const body = Buffer.concat([
    Buffer.from(`--${B}\r\nContent-Type: application/json; charset=utf-8\r\n\r\n${JSON.stringify({ name: path, contentType })}\r\n--${B}\r\nContent-Type: ${contentType}\r\n\r\n`),
    Buffer.alloc(bytes, 1),
    Buffer.from(`\r\n--${B}--`),
  ]);
  const res = await realFetch(`http://${host}/v0/b/${PROJECT}.appspot.com/o?name=${encodeURIComponent(path)}`, {
    method: 'POST',
    headers: { Authorization: `Firebase ${idToken(uid)}`, 'Content-Type': `multipart/related; boundary=${B}`, 'X-Goog-Upload-Protocol': 'multipart' },
    body,
  });
  await res.text();
  return res.status;
}
async function storageGet(uid: string, path: string): Promise<number> {
  const host = process.env.FIREBASE_STORAGE_EMULATOR_HOST!;
  const res = await realFetch(`http://${host}/v0/b/${PROJECT}.appspot.com/o/${encodeURIComponent(path)}?alt=media`, {
    headers: { Authorization: `Firebase ${idToken(uid)}` },
  });
  await res.text();
  return res.status;
}

beforeEach(async () => {
  await clearAll();
  stripeCalls.length = 0;
  mpCalls.length = 0;
  mpPayment = null;
  await seedProfiles();
});
afterAll(() => fft.cleanup());

// ═══════════════════════════════════════════════ instant mode (Stripe)

describe('instant mode: Stripe Connect direct charge', () => {
  test('price comes from the server-side listing, on the organizer account, with NO platform fee', async () => {
    await connectStripe();
    await paidEvent('e1');
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1', quantity: 2, amount: 1, price: 0.01 }, BUYER);
    expect(r.mode).toBe('instant');
    expect(r.checkoutUrl).toMatch(/^https:\/\/checkout\.stripe\.test\//);
    const o = (await db.doc(`ticket_orders/${r.orderId}`).get()).data()!;
    expect(o).toMatchObject({ unitAmount: 2500, totalAmount: 5000, currency: 'brl', status: 'pending', quantity: 2, buyerId: BUYER, organizerId: ORG });
    const { params, opts } = stripeCalls[0];
    expect(opts.stripeAccount).toBe('acct_org');
    expect(params.line_items[0].price_data.unit_amount).toBe(2500);
    expect(params.line_items[0].quantity).toBe(2);
    // BRL on a Brazilian account: cards (+ Apple/Google Pay) and Pix.
    expect(params.payment_method_types).toEqual(['card', 'pix']);
    expect(params.application_fee_amount).toBeUndefined();
    expect(params.payment_intent_data.application_fee_amount).toBeUndefined();
    expect(params.expires_at * 1000 - Date.now()).toBeGreaterThanOrEqual(30 * 60000);
  });

  test('provider minimum amount is enforced on the server price', async () => {
    await connectStripe();
    await paidEvent('cheap', { price: 0.1, currency: '\$' });
    const e = await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'cheap' }, BUYER));
    expect(e.reason).toBe('amount_below_minimum');
    expect(stripeCalls.length).toBe(0);
    // USD on a BR account: cards only (no Pix).
    await paidEvent('usd', { price: 10, currency: '\$' });
    await call(tp.createTicketCheckout, { kind: 'event', id: 'usd' }, BUYER);
    expect(stripeCalls[0].params.payment_method_types).toEqual(['card']);
    expect(stripeCalls[0].params.line_items[0].price_data).toMatchObject({ currency: 'usd', unit_amount: 1000 });
  });

  test('zero-decimal currency: JPY price goes to Stripe without cents', async () => {
    await connectStripe();
    await paidEvent('yen', { price: 1500, currency: '¥' });
    await call(tp.createTicketCheckout, { kind: 'event', id: 'yen' }, BUYER);
    expect(stripeCalls[0].params.line_items[0].price_data).toMatchObject({ currency: 'jpy', unit_amount: 1500 });
  });

  test('organizer without a ready account cannot sell (no order, no seat held)', async () => {
    await paidEvent('e1');
    const e = await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER));
    expect(e.reason).toBe('organizer_payments_not_ready');
    expect((await db.collection('ticket_orders').get()).size).toBe(0);
  });

  test('capacity: the hold blocks the next buyer; expiry releases the seat', async () => {
    await connectStripe();
    await paidEvent('e1', { maxAttendees: 1 });
    const a = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER);
    const e = await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, OTHER));
    expect(e.reason).toBe('sold_out');
    await db.doc(`ticket_orders/${a.orderId}`).update({ expiresAt: TS.fromMillis(Date.now() - 1000) });
    expect(await expireDueOrders()).toBe(1);
    expect((await db.doc(`ticket_orders/${a.orderId}`).get()).data()!.status).toBe('expired');
    const b = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, OTHER);
    expect(b.orderId).toBeTruthy();
  });

  test('webhook with a bad signature is rejected and changes nothing', async () => {
    await connectStripe();
    await paidEvent('e1');
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER);
    const ev = stripeEvent('checkout.session.completed', { id: 'cs_1', payment_status: 'paid', amount_total: 2500, currency: 'brl', metadata: { orderId: r.orderId, greengo: 'ticket' } });
    const bad = await handleStripeConnectWebhook(Buffer.from(ev.payload), ev.header.replace(/v1=[0-9a-f]+/, 'v1=' + '0'.repeat(64)));
    expect(bad.status).toBe(400);
    const forged = await handleStripeConnectWebhook(Buffer.from(ev.payload.replace('2500', '2501')), ev.header);
    expect(forged.status).toBe(400);
    expect((await db.doc(`ticket_orders/${r.orderId}`).get()).data()!.status).toBe('pending');
    expect((await db.doc(`tickets/${r.orderId}_1`).get()).exists).toBe(false);
  });

  test('QR only after paid; paid is idempotent; amount mismatch is refused', async () => {
    await connectStripe();
    await paidEvent('e1');
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER);
    // Before the webhook: no ticket, no QR.
    expect((await refused(call(getEventTicketCode, { eventId: 'e1' }, BUYER))).reason).toBe('not_going');

    // Wrong amount (e.g. a tampered session) -> never paid.
    const sid = (await db.doc(`ticket_orders/${r.orderId}`).get()).data()!.providerRef.stripeSessionId;
    const mism = stripeEvent('checkout.session.completed', { id: sid, payment_status: 'paid', amount_total: 100, currency: 'brl', payment_intent: 'pi_x', metadata: { orderId: r.orderId, greengo: 'ticket' } });
    await handleStripeConnectWebhook(Buffer.from(mism.payload), mism.header);
    expect((await db.doc(`ticket_orders/${r.orderId}`).get()).data()!.status).toBe('pending');

    // Session from ANOTHER connected account -> ignored.
    const other = stripeEvent('checkout.session.completed', { id: sid, payment_status: 'paid', amount_total: 2500, currency: 'brl', metadata: { orderId: r.orderId, greengo: 'ticket' } }, 'acct_evil');
    await handleStripeConnectWebhook(Buffer.from(other.payload), other.header);
    expect((await db.doc(`ticket_orders/${r.orderId}`).get()).data()!.status).toBe('pending');

    const ok = await stripePaid(r.orderId, 2500, 'cs_1');
    expect(ok.status).toBe(200);
    const again = await stripePaid(r.orderId, 2500, 'cs_1'); // a different event id, same payment
    expect(again.status).toBe(200);
    const o = (await db.doc(`ticket_orders/${r.orderId}`).get()).data()!;
    expect(o.status).toBe('paid');
    const t = (await db.doc(`tickets/${r.orderId}_1`).get()).data()!;
    expect(t.status).toBe('valid');
    expect(verifyTicketQr(KEY, t.qrPayload)).toBe(`${r.orderId}_1`);
    const att = (await db.doc(`events/e1/attendees/${BUYER}`).get()).data()!;
    expect(att).toMatchObject({ status: "going", ticketId: `${r.orderId}_1` });
    expect((await db.doc('events/e1').get()).data()!.attendeeCount).toBe(1);
    expect((await db.doc('ticket_inventory/event_e1').get()).data()!.held).toBe(0);

    const code = await call(getEventTicketCode, { eventId: 'e1' }, BUYER);
    expect(code.qrPayload).toBe(t.qrPayload);
    const notif = await db.collection('notifications').where('userId', '==', BUYER).where('type', '==', 'ticket_ready').get();
    expect(notif.size).toBe(1);
  });

  test('refund webhook invalidates the ticket: the scanner refuses the genuine QR', async () => {
    await connectStripe();
    await paidEvent('e1');
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER);
    await stripePaid(r.orderId, 2500, 'cs_1', 'pi_refund');
    const qr = (await db.doc(`tickets/${r.orderId}_1`).get()).data()!.qrPayload;

    const ref = stripeEvent('charge.refunded', { id: 'ch_1', payment_intent: 'pi_refund', amount: 2500, amount_refunded: 2500, refunded: true });
    expect((await handleStripeConnectWebhook(Buffer.from(ref.payload), ref.header)).status).toBe(200);
    expect((await db.doc(`tickets/${r.orderId}_1`).get()).data()!.status).toBe('refunded');
    expect((await db.doc(`ticket_orders/${r.orderId}`).get()).data()!.status).toBe('refunded');
    expect((await db.doc(`events/e1/attendees/${BUYER}`).get()).exists).toBe(false);
    const e = await refused(call(checkInTicket, { payload: qr, eventId: 'e1' }, ORG));
    expect(e.reason).toBe('ticket_not_valid');
    // The old signed RSVP code for the same person is no ticket either.
    const evCode = `greengo:ev:e1:${BUYER}:${eventTicketCode('x'.repeat(64), 'e1', BUYER)}`;
    expect((await refused(call(checkInEventAttendee, { payload: evCode, eventId: 'e1' }, ORG))).code).toBe('permission-denied');
  });

  test('a valid ticket checks in once at the door; forged QR refused', async () => {
    await connectStripe();
    await paidEvent('e1', { startDate: TS.fromMillis(Date.now() - 10 * 60000) });
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER);
    await stripePaid(r.orderId, 2500, 'cs_1');
    const qr = (await db.doc(`tickets/${r.orderId}_1`).get()).data()!.qrPayload;
    expect((await refused(call(checkInTicket, { payload: ticketQrPayload('wrong-key-wrong-key-wrong-key-12345', r.orderId) }, ORG))).reason).toBe('invalid_code');
    expect((await refused(call(checkInTicket, { payload: qr }, STRANGER))).reason).toBe('not_scanner');
    const ok = await call(checkInTicket, { payload: qr, eventId: 'e1' }, ORG);
    expect(ok.alreadyCheckedIn).toBe(false);
    const again = await call(checkInEventAttendee, { payload: qr, eventId: 'e1' }, ORG);
    expect(again.alreadyCheckedIn).toBe(true);
  });
});

// ═══════════════════════════════════════════════ instant mode (Mercado Pago)

describe('instant mode: Mercado Pago', () => {
  async function mpOrder() {
    await connectMp();
    await paidEvent('e1', { ticketProvider: 'mercadopago' });
    return call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER);
  }

  test('OAuth tokens are stored sealed and never readable by clients; preference excludes boleto/ATM, no fee', async () => {
    const r = await mpOrder();
    const priv = (await db.doc(`payment_accounts_private/${ORG}`).get()).data()!;
    expect(priv.mercadoPago.accessToken).not.toContain('APP_USR');
    expect(await clientRead(ORG, `payment_accounts_private/${ORG}`)).toBe(403);
    expect(await clientRead(ORG, `payment_accounts/${ORG}`)).toBe(200);
    expect(await clientRead(STRANGER, `payment_accounts/${ORG}`)).toBe(403);
    expect(r.checkoutUrl).toBe('https://mp.test/checkout/pref_1');
    const pref = mpCalls.find((c) => c.url.endsWith('/checkout/preferences'))!;
    expect(pref.init.headers.Authorization).toBe('Bearer APP_USR-org-token');
    const body = JSON.parse(pref.init.body);
    expect(body.external_reference).toBe(r.orderId);
    expect(body.items[0]).toMatchObject({ unit_price: 25, quantity: 1, currency_id: 'BRL' });
    expect(body.payment_methods.excluded_payment_types).toEqual([{ id: 'ticket' }, { id: 'atm' }]);
    expect(body.marketplace_fee).toBeUndefined();
    expect(body.purpose).toBeUndefined(); // guest checkout allowed
  });

  test('MP account currency is the only accepted currency (BRL account, USD listing -> refused)', async () => {
    await connectMp();
    expect((await db.doc(`payment_accounts/${ORG}`).get()).data()!.mercadoPago).toMatchObject({ siteId: 'MLB', currency: 'brl' });
    await paidEvent('usd', { ticketProvider: 'mercadopago', currency: '\$' });
    const e = await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'usd' }, BUYER));
    expect(e.reason).toBe('currency_not_supported');
    expect(mpCalls.some((c) => c.url.endsWith('/checkout/preferences'))).toBe(false);
    await paidEvent('tiny', { ticketProvider: 'mercadopago', price: 0.5 });
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'tiny' }, BUYER))).reason).toBe('amount_below_minimum');
  });

  test('bad x-signature -> 401; payment re-fetched: reference / amount mismatch refused; approved -> paid', async () => {
    const r = await mpOrder();
    const q = { o: r.orderId, 'data.id': '123456', type: 'payment' };
    const bad = await handleMercadoPagoWebhook(q, { type: 'payment', data: { id: '123456' } },
      { 'x-signature': mpSignature('123456', 'req-1', 'wrong-secret'), 'x-request-id': 'req-1' });
    expect(bad.status).toBe(401);

    // Body claims approved, but the API says the payment belongs to another order.
    mpPayment = { id: 123456, status: 'approved', external_reference: 'someone_else', transaction_amount: 25, currency_id: 'BRL' };
    await handleMercadoPagoWebhook(q, { action: 'payment.updated', data: { id: '123456' }, status: 'approved' },
      { 'x-signature': mpSignature('123456', 'req-2'), 'x-request-id': 'req-2' });
    expect((await db.doc(`ticket_orders/${r.orderId}`).get()).data()!.status).toBe('pending');

    // Right reference, wrong amount.
    mpPayment = { id: 123456, status: 'approved', external_reference: r.orderId, transaction_amount: 1, currency_id: 'BRL' };
    await handleMercadoPagoWebhook(q, {}, { 'x-signature': mpSignature('123456', 'req-3'), 'x-request-id': 'req-3' });
    expect((await db.doc(`ticket_orders/${r.orderId}`).get()).data()!.status).toBe('pending');

    mpPayment = { id: 123457, status: 'approved', external_reference: r.orderId, transaction_amount: 25, currency_id: 'BRL' };
    const q2 = { ...q, 'data.id': '123457' };
    const ok = await handleMercadoPagoWebhook(q2, {}, { 'x-signature': mpSignature('123457', 'req-4'), 'x-request-id': 'req-4' });
    expect(ok.status).toBe(200);
    expect((await db.doc(`ticket_orders/${r.orderId}`).get()).data()!.status).toBe('paid');
    expect((await db.doc(`tickets/${r.orderId}_1`).get()).data()!.status).toBe('valid');
    // Every decision came from a GET on the payment with the organizer token.
    const gets = mpCalls.filter((c) => /\/v1\/payments\/\d+$/.test(c.url));
    expect(gets.length).toBeGreaterThanOrEqual(3);
    expect(gets.every((c) => c.init.headers.Authorization === 'Bearer APP_USR-org-token')).toBe(true);

    // Chargeback -> ticket invalid.
    mpPayment = { ...mpPayment, status: 'charged_back' };
    await handleMercadoPagoWebhook(q2, {}, { 'x-signature': mpSignature('123457', 'req-5'), 'x-request-id': 'req-5' });
    expect((await db.doc(`tickets/${r.orderId}_1`).get()).data()!.status).toBe('disputed');
  });
});

// ═══════════════════════════════════════════════ link mode (organizer confirms)

describe('link mode: payment link + organizer confirmation', () => {
  async function linkEvent(over: Record<string, any> = {}) {
    await paidEvent('e1', { ticketProvider: 'link', ticketLinkMethod: 'pix', ...over });
  }

  test('order gets a code + method snapshot from the organizer profile; held 24 h; no QR yet', async () => {
    await linkEvent();
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER);
    expect(r.mode).toBe('link');
    expect(r.code).toMatch(PAYMENT_CODE_RE);
    expect(r.payment).toEqual({ method: 'pix', value: 'org@pix.example', instructions: null });
    expect(r.amount).toBe(2500);
    const o = (await db.doc(`ticket_orders/${r.orderId}`).get()).data()!;
    expect(o.status).toBe('pending_payment');
    expect(o.expiresAt.toMillis() - Date.now()).toBeGreaterThan(23 * HOUR);
    expect((await db.doc(`ticket_codes/${r.code}`).get()).data()!.orderId).toBe(r.orderId);
    // Same buyer again: same order (no second hold).
    const again = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER);
    expect(again.orderId).toBe(r.orderId);
    expect((await db.doc('ticket_inventory/event_e1').get()).data()!.held).toBe(1);
    expect((await refused(call(getEventTicketCode, { eventId: 'e1' }, BUYER))).reason).toBe('not_going');
  });

  test('method missing from the organizer profile -> not on sale', async () => {
    await linkEvent({ ticketLinkMethod: 'revolut' });
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER))).reason).toBe('organizer_payments_not_ready');
  });

  test('a pasted Stripe / Mercado Pago link is never a manual method (needs the connected account)', async () => {
    await db.doc(`profiles/${ORG}`).set({ paymentLinks: { stripe: 'https://buy.stripe.com/abc', mercadoPago: 'https://mpago.la/x' } }, { merge: true });
    for (const m of ['stripe', 'mercadoPago']) {
      await linkEvent({ ticketLinkMethod: m });
      expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER))).reason).toBe('organizer_payments_not_ready');
    }
  });

  test('link mode accepts any currency and shows the exact amount', async () => {
    await linkEvent({ price: 12.5, currency: 'CHF' });
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER);
    expect(r).toMatchObject({ amount: 1250, currency: 'chf' });
  });

  test('buyer cannot self-confirm; only the listing organizer confirms; ticket + push follow', async () => {
    await linkEvent();
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER);
    expect((await refused(call(tp.markTicketPaymentSent, { orderId: r.orderId }, OTHER))).code).toBe('not-found');
    const sent = await call(tp.markTicketPaymentSent, { orderId: r.orderId, receiptPath: `ticket_receipts/${r.orderId}/r.jpg` }, BUYER);
    expect(sent.status).toBe('awaiting_confirmation');
    const toOrg = await db.collection('notifications').where('userId', '==', ORG).where('type', '==', 'ticket_payment_to_confirm').get();
    expect(toOrg.size).toBe(1);

    expect((await refused(call(tp.confirmTicketPayment, { orderId: r.orderId }, BUYER))).code).toBe('permission-denied');
    expect((await refused(call(tp.confirmTicketPayment, { orderId: r.orderId }, STRANGER))).code).toBe('permission-denied');
    // Clients cannot write the order directly either.
    expect(await clientWrite(BUYER, `ticket_orders/${r.orderId}`, { status: 'paid' }, ['status'])).toBe(403);
    expect((await db.doc(`ticket_orders/${r.orderId}`).get()).data()!.status).toBe('awaiting_confirmation');
    expect((await db.doc(`tickets/${r.orderId}_1`).get()).exists).toBe(false);

    const c = await call(tp.confirmTicketPayment, { orderIds: [r.orderId] }, ORG);
    expect(c.results[r.orderId]).toBe('paid');
    const t = (await db.doc(`tickets/${r.orderId}_1`).get()).data()!;
    expect(t.status).toBe('valid');
    expect((await db.doc(`events/e1/attendees/${BUYER}`).get()).data()!.status).toBe('going');
    const ready = await db.collection('notifications').where('userId', '==', BUYER).where('type', '==', 'ticket_ready').get();
    expect(ready.size).toBe(1);
    // Ticket readable by the buyer only.
    expect(await clientRead(BUYER, `tickets/${r.orderId}_1`)).toBe(200);
    expect(await clientRead(ORG, `tickets/${r.orderId}_1`)).toBe(403);
    expect(await clientRead(ORG, `ticket_orders/${r.orderId}`)).toBe(200);
    expect(await clientRead(STRANGER, `ticket_orders/${r.orderId}`)).toBe(403);
  });

  test('reject releases the seat and tells the buyer why', async () => {
    await linkEvent({ maxAttendees: 1 });
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER);
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, OTHER))).reason).toBe('sold_out');
    await call(tp.markTicketPaymentSent, { orderId: r.orderId }, BUYER);
    expect((await refused(call(tp.rejectTicketPayment, { orderId: r.orderId, reason: 'no' }, BUYER))).code).toBe('permission-denied');
    await call(tp.rejectTicketPayment, { orderId: r.orderId, reason: 'Not received' }, ORG);
    const o = (await db.doc(`ticket_orders/${r.orderId}`).get()).data()!;
    expect(o).toMatchObject({ status: 'rejected', rejectReason: 'Not received', seatHeld: false });
    expect((await db.doc('ticket_inventory/event_e1').get()).data()!.held).toBe(0);
    const b = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, OTHER);
    expect(b.mode).toBe('link');
  });

  test('expiry releases the seat; organizers get reminders for waiting payments', async () => {
    await linkEvent({ maxAttendees: 1 });
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER);
    await call(tp.markTicketPaymentSent, { orderId: r.orderId }, BUYER);
    await db.doc(`ticket_orders/${r.orderId}`).update({ remindAt: TS.fromMillis(Date.now() - 1000) });
    expect(await remindDueConfirmations()).toBe(1);
    await db.doc(`ticket_orders/${r.orderId}`).update({ expiresAt: TS.fromMillis(Date.now() - 1000) });
    expect(await expireDueOrders()).toBe(1);
    expect((await db.doc(`ticket_orders/${r.orderId}`).get()).data()!.status).toBe('expired');
    expect((await db.doc('ticket_inventory/event_e1').get()).data()!.held).toBe(0);
  });

  test('receipt storage: buyer uploads images only, buyer + organizer read, nobody else', async () => {
    await linkEvent();
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1' }, BUYER);
    const path = `ticket_receipts/${r.orderId}/receipt.jpg`;
    expect(await storageUpload(STRANGER, `ticket_receipts/${r.orderId}/x.jpg`)).toBe(403);
    expect(await storageUpload(BUYER, `ticket_receipts/${r.orderId}/x.pdf`, 'application/pdf')).toBe(403);
    expect(await storageUpload(BUYER, `ticket_receipts/${r.orderId}/big.jpg`, 'image/jpeg', 6 * 1024 * 1024)).toBe(403);
    expect(await storageUpload(BUYER, path)).toBe(200);
    expect(await storageGet(BUYER, path)).toBe(200);
    expect(await storageGet(ORG, path)).toBe(200);
    expect(await storageGet(STRANGER, path)).toBe(403);
  });
});

// ═══════════════════════════════════════════════ experiences

describe('experiences: QR only after paid', () => {
  test('link-mode booking: no QR until the host confirms, then the paid ticket QR', async () => {
    await db.doc('user_experiences/x1').set({ hostId: ORG, title: 'Cooking class', status: 'published', paymentProvider: 'link', paymentLinkMethod: 'paypal' });
    await db.doc('bookings/bk1').set({
      experienceId: 'x1', slotId: 's1', hostId: ORG, guestId: BUYER, guests: 2, status: 'confirmed',
      experienceTitle: 'Cooking class', slotStart: TS.fromMillis(Date.now() + 2 * HOUR), slotEnd: TS.fromMillis(Date.now() + 4 * HOUR),
      price: { unitAmount: 3000, currency: 'eur', totalAmount: 6000 },
      payment: { mode: 'online', provider: 'link', linkMethod: 'paypal', status: 'unpaid', orderId: null },
    });
    expect((await refused(call(getBookingCheckInCode, { bookingId: 'bk1' }, BUYER))).reason).toBe('not_paid');
    const r = await call(tp.createTicketCheckout, { kind: 'experience', id: 'x1', bookingId: 'bk1', quantity: 9 }, BUYER);
    expect(r).toMatchObject({ mode: 'link', amount: 6000, currency: 'eur', payment: { method: 'paypal', value: 'https://paypal.me/org' } });
    await call(tp.confirmTicketPayment, { orderId: r.orderId }, ORG);
    const b = (await db.doc('bookings/bk1').get()).data()!;
    expect(b.payment.status).toBe('paid');
    const code = await call(getBookingCheckInCode, { bookingId: 'bk1' }, BUYER);
    expect(verifyTicketQr(KEY, code.qrPayload)).toBe(`${r.orderId}_1`);
  });
});

// ═══════════════════════════════════════════════ closed bypasses (rules) + free events

describe('firestore.rules: paid events cannot be self-joined; free events unchanged', () => {
  test('client cannot self-mark going / waitlist on a paid event, or touch ticket fields', async () => {
    await paidEvent('e1');
    expect(await clientWrite(BUYER, `events/e1/attendees/${BUYER}`, { userId: BUYER, eventId: 'e1', status: 'going' })).toBe(403);
    expect(await clientWrite(BUYER, `events/e1/attendees/${BUYER}`, { userId: BUYER, eventId: 'e1', status: 'waitlist' })).toBe(403);
    expect(await clientWrite(BUYER, `events/e1/attendees/${BUYER}`, { userId: BUYER, eventId: 'e1', status: 'interested' })).toBe(200);
    expect(await clientWrite(BUYER, `events/e1/attendees/${BUYER}`, { status: 'going' }, ['status'])).toBe(403);
    // Legacy coin-priced event (price > 0, no provider) is paid too.
    await db.doc('events/legacy').set({ organizerId: ORG, price: 10, attendeeCount: 0 });
    expect(await clientWrite(BUYER, `events/legacy/attendees/${BUYER}`, { userId: BUYER, status: 'going' })).toBe(403);
    // Waitlist -> going promotion by anyone: denied on paid events.
    await db.doc(`events/e1/attendees/${OTHER}`).set({ userId: OTHER, status: 'waitlist' });
    expect(await clientWrite(STRANGER, `events/e1/attendees/${OTHER}`, { status: 'going' }, ['status'])).toBe(403);
    // Counters on a paid event are server-owned.
    expect(await clientWrite(STRANGER, 'events/e1', { attendeeCount: 7 }, ['attendeeCount'])).toBe(403);
    expect(await clientWrite(STRANGER, 'events/e1', { viewCount: 5 }, ['viewCount'])).toBe(200);
    // A paid attendee cannot rewrite their ticket / party size.
    await db.doc(`events/e1/attendees/${BUYER}`).set({ userId: BUYER, status: 'going', ticketId: 'o1', guestCount: 0 });
    expect(await clientWrite(BUYER, `events/e1/attendees/${BUYER}`, { guestCount: 1 }, ['guestCount'])).toBe(403);
    expect(await clientWrite(BUYER, `events/e1/attendees/${BUYER}`, { ticketId: 'o2' }, ['ticketId'])).toBe(403);
    expect(await clientWrite(BUYER, `events/e1/attendees/${BUYER}`, { muteNotifications: true }, ['muteNotifications'])).toBe(200);
    // Organizer may comp, never forge a paid ticket.
    expect(await clientWrite(ORG, `events/e1/attendees/${STRANGER}`, { userId: STRANGER, status: 'going' })).toBe(200);
    expect(await clientWrite(ORG, `events/e1/attendees/${OTHER}`, { ticketId: 'fake' }, ['ticketId'])).toBe(403);
  });

  test('free event: self RSVP going, waitlist promotion and counters work as before; signed QR as before', async () => {
    await db.doc('events/free').set({ organizerId: ORG, title: 'Picnic', price: 0, attendeeCount: 0, maxAttendees: 0, startDate: TS.fromMillis(Date.now() + HOUR) });
    expect(await clientWrite(BUYER, `events/free/attendees/${BUYER}`, { userId: BUYER, eventId: 'free', status: 'going', checkedIn: false })).toBe(200);
    expect(await clientWrite(BUYER, 'events/free', { attendeeCount: 1 }, ['attendeeCount'])).toBe(200);
    await db.doc(`events/free/attendees/${OTHER}`).set({ userId: OTHER, status: 'waitlist' });
    expect(await clientWrite(STRANGER, `events/free/attendees/${OTHER}`, { status: 'going' }, ['status'])).toBe(200);
    const code = await call(getEventTicketCode, { eventId: 'free' }, BUYER);
    expect(code.qrPayload).toMatch(/^greengo:ev:free:/);
    // Free events are not for sale.
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'free' }, OTHER))).reason).toBe('not_paid_listing');
  });

  test('legacy unsigned tickets are refused on paid events', async () => {
    await paidEvent('e1', { startDate: TS.fromMillis(Date.now()) });
    await db.doc(`events/e1/attendees/${BUYER}`).set({ userId: BUYER, status: 'going' });
    const legacy = `greengo:${JSON.stringify({ e: 'e1', u: BUYER })}`;
    expect((await refused(call(checkInEventAttendee, { payload: legacy, eventId: 'e1' }, ORG))).reason).toBe('legacy_ticket_rejected');
  });
});

// ═══════════════════════════════════════════════ quantity, per-user limit, per-ticket QR

describe('multiple tickets per purchase + per-user limit', () => {
  test('default limit 4: holds count, concurrent orders cannot exceed it, refund frees the allowance', async () => {
    await connectStripe();
    await paidEvent('e1');
    const a = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1', quantity: 3 }, BUYER);
    // More than the remaining allowance while 3 are held: refused.
    const e = await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'e1', quantity: 5 }, BUYER));
    expect(e.reason).toBe('ticket_limit_reached');
    // Racing devices of another buyer: the counter doc serialises them.
    const both = await Promise.allSettled([
      call(tp.createTicketCheckout, { kind: 'event', id: 'e1', quantity: 3 }, OTHER),
      call(tp.createTicketCheckout, { kind: 'event', id: 'e1', quantity: 3 }, OTHER),
    ]);
    const h = (await db.doc(`ticket_holdings/event_e1_${OTHER}`).get()).data()!;
    expect(h.held).toBeLessThanOrEqual(4);
    expect(both.some((x) => x.status === 'fulfilled')).toBe(true);

    await stripePaid(a.orderId, 7500);
    const tickets = await db.collection('tickets').where('orderId', '==', a.orderId).get();
    expect(tickets.size).toBe(3);
    expect(new Set(tickets.docs.map((d) => d.data().qrPayload)).size).toBe(3);
    expect((await db.doc(`ticket_holdings/event_e1_${BUYER}`).get()).data()).toMatchObject({ held: 0, owned: 3 });
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'e1', quantity: 2 }, BUYER))).reason).toBe('ticket_limit_reached');
    const one = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1', quantity: 1 }, BUYER);
    expect(one.orderId).toBeTruthy();
    await call(tp.cancelTicketOrder, { orderId: one.orderId }, BUYER);

    const ref = stripeEvent('charge.refunded', { id: 'ch_9', payment_intent: 'pi_1', amount: 7500, amount_refunded: 7500, refunded: true });
    await handleStripeConnectWebhook(Buffer.from(ref.payload), ref.header);
    expect((await db.doc(`ticket_holdings/event_e1_${BUYER}`).get()).data()!.owned).toBe(0);
    const after = await db.collection('tickets').where('orderId', '==', a.orderId).get();
    expect(after.docs.every((d) => d.data().status === 'refunded')).toBe(true);
    const again = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1', quantity: 4 }, BUYER);
    expect(again.orderId).toBeTruthy();
  });

  test('quantity above remaining capacity is refused; organizer-set limit and no limit', async () => {
    await connectStripe();
    await paidEvent('cap', { maxAttendees: 3, maxTicketsPerUser: null });
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'cap', quantity: 4 }, BUYER))).reason).toBe('sold_out');
    const ok = await call(tp.createTicketCheckout, { kind: 'event', id: 'cap', quantity: 3 }, BUYER);
    expect(ok.quantity).toBe(3);
    await paidEvent('lim', { maxTicketsPerUser: 1 });
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'lim', quantity: 2 }, BUYER))).reason).toBe('ticket_limit_reached');
  });

  test('each ticket QR is single-use; the buyer party is admitted once', async () => {
    await connectStripe();
    await paidEvent('e1', { startDate: TS.fromMillis(Date.now() - 10 * 60000) });
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'e1', quantity: 2 }, BUYER);
    await stripePaid(r.orderId, 5000);
    const t1 = (await db.doc(`tickets/${r.orderId}_1`).get()).data()!.qrPayload;
    const t2 = (await db.doc(`tickets/${r.orderId}_2`).get()).data()!.qrPayload;
    expect((await call(checkInTicket, { payload: t1, eventId: 'e1' }, ORG)).alreadyCheckedIn).toBe(false);
    expect((await call(checkInTicket, { payload: t1, eventId: 'e1' }, ORG)).alreadyCheckedIn).toBe(true);
    expect((await call(checkInTicket, { payload: t2, eventId: 'e1' }, ORG)).alreadyCheckedIn).toBe(false);
    const att = (await db.doc(`events/e1/attendees/${BUYER}`).get()).data()!;
    expect(att).toMatchObject({ ticketCount: 2, guestCount: 1, checkedIn: true });
    expect((await db.doc('events/e1').get()).data()!.attendeeCount).toBe(2);
  });

  test('checkout payload is built from the listing doc; client values ignored', async () => {
    await connectStripe();
    await paidEvent('e1', { title: 'Samba Night', locationName: 'Lapa', imageUrl: 'https://cdn.example/cover.jpg', timeZone: 'America/Sao_Paulo' });
    await call(tp.createTicketCheckout, {
      kind: 'event', id: 'e1', quantity: 2, title: 'HACK', price: 1, unitAmount: 1, imageUrl: 'https://evil.example/x.png', locale: 'pt-BR',
    }, BUYER, { email: 'buyer@example.com' });
    const p = stripeCalls[0].params;
    const li = p.line_items[0];
    expect(li.quantity).toBe(2);
    expect(li.price_data).toMatchObject({ currency: 'brl', unit_amount: 2500 });
    expect(li.price_data.product_data.name).toBe('Samba Night');
    expect(li.price_data.product_data.description).toContain('Lapa');
    expect(li.price_data.product_data.images).toEqual(['https://cdn.example/cover.jpg']);
    expect(p.customer_email).toBe('buyer@example.com');
    expect(p.locale).toBe('pt-BR');
    expect(p.metadata).toMatchObject({ orderId: expect.any(String), listingKind: 'event', listingId: 'e1' });
    expect(p.payment_intent_data.description).toBe('Samba Night × 2');
    expect(p.payment_intent_data.statement_descriptor_suffix.length).toBeLessThanOrEqual(22);
  });
});

describe('experiences: per_group pricing', () => {
  test('total = groupPrice whatever the party size; ONE group ticket with partySize', async () => {
    await db.doc('user_experiences/g1').set({ hostId: ORG, title: 'Private boat', status: 'published', pricingMode: 'per_group', groupPrice: 40000, maxGroupSize: 8, paymentProvider: 'link', paymentLinkMethod: 'pix' });
    await db.doc('bookings/gb').set({
      experienceId: 'g1', slotId: 's1', hostId: ORG, guestId: BUYER, guests: 6, status: 'confirmed', pricingMode: 'per_group', maxGroupSize: 8,
      experienceTitle: 'Private boat', slotStart: TS.fromMillis(Date.now() + 2 * HOUR), slotEnd: TS.fromMillis(Date.now() + 4 * HOUR),
      price: { unitAmount: 40000, currency: 'brl', totalAmount: 40000 },
      payment: { mode: 'online', provider: 'link', linkMethod: 'pix', status: 'unpaid', orderId: null },
    });
    const r = await call(tp.createTicketCheckout, { kind: 'experience', id: 'g1', bookingId: 'gb', quantity: 6 }, BUYER);
    expect(r).toMatchObject({ amount: 40000, quantity: 1 });
    await call(tp.confirmTicketPayment, { orderId: r.orderId }, ORG);
    const tks = await db.collection('tickets').where('orderId', '==', r.orderId).get();
    expect(tks.size).toBe(1);
    expect(tks.docs[0].data().partySize).toBe(6);
  });
});

// ═══════════════════════════════════════════════ event ticket types

describe('event ticket types', () => {
  async function typedEvent(over: Record<string, any> = {}) {
    await connectStripe();
    await paidEvent('tt', { maxAttendees: 10, maxTicketsPerUser: 10, startDate: TS.fromMillis(Date.now() - 10 * 60000), ...over });
    const types = db.collection('events/tt/ticket_types');
    await types.doc('ga').set({ name: 'General', price: 2000, quantity: null, active: true, sortOrder: 0 });
    await types.doc('vip').set({ name: 'VIP', description: 'Backstage', price: 8000, quantity: 2, maxPerUser: 2, active: true, sortOrder: 1 });
    await types.doc('early').set({ name: 'Early bird', price: 1500, quantity: null, salesEnd: TS.fromMillis(Date.now() - 1000), active: true });
    await types.doc('later').set({ name: 'Last minute', price: 3000, salesStart: TS.fromMillis(Date.now() + HOUR), active: true });
    await types.doc('hidden').set({ name: 'Crew', price: 0, hidden: true, active: true });
  }

  test('multi-type order: total, one Stripe line per type, tickets carry their type', async () => {
    await typedEvent();
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'tt', items: [{ typeId: 'ga', qty: 2 }, { typeId: 'vip', qty: 1 }], price: 1 }, BUYER);
    const o = (await db.doc(`ticket_orders/${r.orderId}`).get()).data()!;
    expect(o).toMatchObject({ totalAmount: 12000, quantity: 3 });
    const li = stripeCalls[0].params.line_items;
    expect(li).toHaveLength(2);
    expect(li[0]).toMatchObject({ quantity: 2, price_data: { unit_amount: 2000 } });
    expect(li[1]).toMatchObject({ quantity: 1, price_data: { unit_amount: 8000 } });
    expect(li[1].price_data.product_data.name).toContain('VIP');
    expect((await db.doc('events/tt/ticket_types/vip').get()).data()!.held).toBe(1);
    await stripePaid(r.orderId, 12000);
    const tickets = (await db.collection('tickets').where('orderId', '==', r.orderId).get()).docs.map((d) => d.data());
    expect(tickets.map((t) => t.ticketTypeName).sort()).toEqual(['General', 'General', 'VIP']);
    expect((await db.doc('events/tt/ticket_types/vip').get()).data()).toMatchObject({ held: 0, sold: 1 });
    const vipQr = tickets.find((t) => t.ticketTypeId === 'vip')!.qrPayload;
    const door = await call(checkInTicket, { payload: vipQr, eventId: 'tt' }, ORG);
    expect(door.ticketTypeName).toBe('VIP');
  });

  test('per-type sold out, per-type limit, sales window, hidden types', async () => {
    await typedEvent();
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'tt', items: [{ typeId: 'vip', qty: 3 }] }, BUYER))).reason).toBe('ticket_type_sold_out');
    await call(tp.createTicketCheckout, { kind: 'event', id: 'tt', items: [{ typeId: 'vip', qty: 2 }] }, OTHER);
    // Last VIPs are held by OTHER: sold out for everyone else.
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'tt', items: [{ typeId: 'vip', qty: 1 }] }, BUYER))).reason).toBe('ticket_type_sold_out');
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'tt', items: [{ typeId: 'early', qty: 1 }] }, BUYER))).reason).toBe('ticket_type_sales_ended');
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'tt', items: [{ typeId: 'later', qty: 1 }] }, BUYER))).reason).toBe('ticket_type_sales_not_started');
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'tt', items: [{ typeId: 'hidden', qty: 1 }] }, BUYER))).reason).toBe('ticket_type_unavailable');
  });

  test('per-type maxPerUser and total capacity across types; concurrency on the last VIP', async () => {
    await typedEvent({ maxAttendees: 3 });
    await db.doc('events/tt/ticket_types/vip').update({ quantity: 1 });
    expect((await refused(call(tp.createTicketCheckout, { kind: 'event', id: 'tt', items: [{ typeId: 'ga', qty: 3 }, { typeId: 'vip', qty: 1 }] }, BUYER))).reason).toBe('sold_out');
    const race = await Promise.allSettled([
      call(tp.createTicketCheckout, { kind: 'event', id: 'tt', items: [{ typeId: 'vip', qty: 1 }] }, BUYER),
      call(tp.createTicketCheckout, { kind: 'event', id: 'tt', items: [{ typeId: 'vip', qty: 1 }] }, OTHER),
    ]);
    expect(race.filter((x) => x.status === 'fulfilled')).toHaveLength(1);
    expect((await db.doc('events/tt/ticket_types/vip').get()).data()!.held).toBe(1);
  });

  test('legacy event without types still sells its single price', async () => {
    await connectStripe();
    await paidEvent('legacy1');
    const r = await call(tp.createTicketCheckout, { kind: 'event', id: 'legacy1', quantity: 1 }, BUYER);
    expect((await db.doc(`ticket_orders/${r.orderId}`).get()).data()).toMatchObject({ totalAmount: 2500, items: null });
  });

  test('clients cannot touch the sale counters of a type', async () => {
    await typedEvent();
    expect(await clientWrite(ORG, 'events/tt/ticket_types/ga', { sold: 0, held: 0, name: 'General', price: 2500 }, ['price'])).toBe(200);
    expect(await clientWrite(ORG, 'events/tt/ticket_types/ga', { sold: 99 }, ['sold'])).toBe(403);
    expect(await clientWrite(STRANGER, 'events/tt/ticket_types/ga', { price: 1 }, ['price'])).toBe(403);
  });
});

// ═══════════════════════════════════════════════ recurring availability + host removals

describe('experiences: recurring availability, per-day prices, host removes booked times', () => {
  const svcMod = () => require('../../src/experience_bookings/service');
  const availMod = () => require('../../src/experience_bookings/functions');
  const DAYMS = 86400000;
  // A Wednesday 10 days ahead, 10:00 in São Paulo (13:00 UTC).
  function nextWeekday(): { date: string; start: number } {
    const d = new Date(Date.now() + 10 * DAYMS);
    const date = d.toISOString().slice(0, 10);
    const start = Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), 13, 0);
    return { date, start };
  }
  async function seedRecurring(over: Record<string, any> = {}) {
    const { date, start } = nextWeekday();
    await db.doc('user_experiences/r1').set({
      hostId: ORG, title: 'Street food walk', status: 'published', price: 50, currency: 'R$', isFree: false,
      paymentMethods: ['online'], paymentProvider: 'link', paymentLinkMethod: 'pix',
      maxGroupSize: 10, durationMinutes: 120,
      weekendPrice: 70,
      availabilityRules: {
        timezone: 'America/Sao_Paulo', windowStart: '10:00', windowEnd: '14:00', durationMinutes: 120,
        weekdays: [1, 2, 3, 4, 5, 6, 7], capacityPerSlot: 3, minNoticeHours: 1, maxAdvanceDays: 60,
      },
      availabilityOverrides: { dayOverrides: { [date]: { priceOverride: 90 } } },
      ...over,
    });
    await db.doc(`profiles/${ORG}`).set({ isAgeVerified: true }, { merge: true });
    for (const u of [BUYER, OTHER, STRANGER]) {
      await db.doc(`profiles/${u}`).set({ displayName: u, ageVerification: { status: 'pending' } }, { merge: true });
    }
    return { date, start };
  }
  const book = (uid: string, start: number, guests: number, rid: string) =>
    call(require('../../src/experience_bookings/functions').createBooking,
      { experienceId: 'r1', slotId: 'recurring', startAt: start, guests, requestId: rid, consentVersion: 1 }, uid);

  test('availability: generated times with remaining capacity and the per-day price', async () => {
    const { date, start } = await seedRecurring();
    const r = await call(availMod().getExperienceAvailability, {
      experienceId: 'r1', from: new Date(start - DAYMS / 2).toISOString(), to: new Date(start + DAYMS / 2).toISOString(),
    }, BUYER);
    expect(r.timezone).toBe('America/Sao_Paulo');
    const day = r.slots.filter((s: any) => s.date === date);
    expect(day.map((s: any) => s.time)).toEqual(['10:00', '12:00']);
    expect(day[0]).toMatchObject({ remaining: 3, unitAmount: 9000, currency: 'brl', priceRule: 'day' });
    expect((await refused(call(availMod().getExperienceAvailability, {
      experienceId: 'r1', from: new Date().toISOString(), to: new Date(Date.now() + 70 * DAYMS).toISOString(),
    }, BUYER))).reason).toBe('range_too_long');
  });

  test('booking a generated time: capacity per slot, outside-availability refused, last seat race', async () => {
    const { start } = await seedRecurring();
    const outside = await refused(book(BUYER, start + 30 * 60000, 1, 'rid-outside-1'));
    expect(outside.reason).toBe('slot_closed');
    const a = await book(BUYER, start, 2, 'rid-a-000001');
    expect(a.status).toBe('requested');
    expect(a.price).toMatchObject({ unitAmount: 9000, totalAmount: 18000 });
    const counter = (await db.doc(`experience_slot_counters/r1_${start}`).get()).data()!;
    expect(counter).toMatchObject({ booked: 2, capacity: 3 });
    const race = await Promise.allSettled([book(OTHER, start, 1, 'rid-b-000001'), book(STRANGER, start, 1, 'rid-c-000001')]);
    expect(race.filter((x) => x.status === 'fulfilled').length).toBeLessThanOrEqual(1);
    expect((await db.doc(`experience_slot_counters/r1_${start}`).get()).data()!.booked).toBeLessThanOrEqual(3);
  });

  test('host removes a booked time: confirm required, then cancel + refund (Stripe on the organizer account) + push', async () => {
    const { date, start } = await seedRecurring({ paymentProvider: 'stripe', paymentLinkMethod: null });
    await connectStripe();
    // A confirmed, PAID in-app booking at that time.
    await db.doc('bookings/rb1').set({
      experienceId: 'r1', slotId: `r_${start}`, counterId: `r1_${start}`, hostId: ORG, guestId: BUYER, guests: 1, status: 'confirmed',
      experienceTitle: 'Street food walk', slotStart: TS.fromMillis(start), slotEnd: TS.fromMillis(start + 2 * HOUR),
      price: { unitAmount: 9000, currency: 'brl', totalAmount: 9000 }, policy: 'moderate',
      payment: { mode: 'online', provider: 'stripe', status: 'paid', orderId: 'ordR1' },
    });
    await db.doc(`experience_slot_counters/r1_${start}`).set({ experienceId: 'r1', startMs: start, booked: 1, capacity: 3 });
    await db.doc('ticket_orders/ordR1').set({
      kind: 'experience', listingId: 'r1', bookingId: 'rb1', buyerId: BUYER, organizerId: ORG, provider: 'stripe',
      status: 'paid', quantity: 1, totalAmount: 9000, currency: 'brl', stripePaymentIntentId: 'pi_rec',
      providerRef: { stripeAccountId: 'acct_org' }, title: 'Street food walk',
    });
    const refunds: any[] = [];
    fakeStripe.refunds = { create: jest.fn(async (p: any, o: any) => { refunds.push({ p, o }); return { id: 're_1' }; }) };
    const closed = { availabilityRules: undefined, overrides: { dayOverrides: { [date]: { closed: true } } } };
    const first = await call(availMod().updateExperienceAvailability, { experienceId: 'r1', ...closed }, ORG);
    expect(first).toMatchObject({ needsConfirm: true, affected: 1 });
    expect((await db.doc('bookings/rb1').get()).data()!.status).toBe('confirmed');
    expect((await refused(call(availMod().updateExperienceAvailability, { experienceId: 'r1', ...closed, confirm: true }, BUYER))).code)
      .toBe('permission-denied');
    const done = await call(availMod().updateExperienceAvailability, { experienceId: 'r1', ...closed, confirm: true }, ORG);
    expect(done).toMatchObject({ needsConfirm: false, cancelledBookings: 1 });
    expect((await db.doc('bookings/rb1').get()).data()).toMatchObject({ status: 'cancelled_by_host', refundDue: { percent: 100 } });
    expect(refunds).toHaveLength(1);
    expect(refunds[0].p).toMatchObject({ payment_intent: 'pi_rec' });
    expect(refunds[0].o).toMatchObject({ stripeAccount: 'acct_org', idempotencyKey: 'gg_refund_ordR1' });
    expect((await db.doc('ticket_orders/ordR1').get()).data()!.refund).toMatchObject({ status: 'requested', providerRefundId: 're_1' });
    expect((await db.doc(`experience_slot_counters/r1_${start}`).get()).data()!.booked).toBe(0);
    const n = await db.collection('notifications').where('userId', '==', BUYER).where('type', '==', 'booking_cancelled').get();
    expect(n.size).toBe(1);
  });

  test('manual-mode paid booking on a removed time -> refund_owed + organizer reminder; MP refund via organizer token', async () => {
    const { date, start } = await seedRecurring();
    for (const [bid, oid, provider] of [['rb2', 'ordL', 'link'], ['rb3', 'ordM', 'mercadopago']] as const) {
      await db.doc(`bookings/${bid}`).set({
        experienceId: 'r1', slotId: `r_${start}`, hostId: ORG, guestId: BUYER, guests: 1, status: 'confirmed',
        slotStart: TS.fromMillis(start), slotEnd: TS.fromMillis(start + 2 * HOUR), policy: 'moderate',
        price: { unitAmount: 9000, currency: 'brl', totalAmount: 9000 },
        payment: { mode: 'online', provider, status: 'paid', orderId: oid },
      });
      await db.doc(`ticket_orders/${oid}`).set({
        kind: 'experience', listingId: 'r1', bookingId: bid, buyerId: BUYER, organizerId: ORG, provider, status: 'paid',
        quantity: 1, totalAmount: 9000, currency: 'brl', mpPaymentId: provider === 'mercadopago' ? '555' : null, title: 'Walk', code: 'GG-ABCDEF',
      });
    }
    await db.doc(`experience_slot_counters/r1_${start}`).set({ experienceId: 'r1', startMs: start, booked: 2, capacity: 3 });
    await connectMp();
    const closed = { overrides: { dayOverrides: { [date]: { closed: true } } }, confirm: true };
    await call(availMod().updateExperienceAvailability, { experienceId: 'r1', ...closed }, ORG);
    expect((await db.doc('ticket_orders/ordL').get()).data()!.refund.status).toBe('refund_owed');
    expect((await db.doc('ticket_orders/ordM').get()).data()!.refund.status).toBe('requested');
    const mp = mpCalls.find((c) => c.url.endsWith('/v1/payments/555/refunds'))!;
    expect(mp.init.headers.Authorization).toBe('Bearer APP_USR-org-token');
    expect(mp.init.headers['X-Idempotency-Key']).toBe('gg_refund_ordM');
    const owed = await db.collection('notifications').where('userId', '==', ORG).where('type', '==', 'ticket_refund_owed').get();
    expect(owed.size).toBe(1);
  });
});
