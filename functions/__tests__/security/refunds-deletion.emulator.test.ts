/**
 * Seller-cancelled refunds + account-deletion blockers (2026-10-21):
 * emulator integration + rules. Real Firestore / Auth / Storage emulators;
 * only the Stripe API is faked (ticketDeps), pushes / e-mails are captured.
 *
 *   - a paid event cannot be hard-deleted by its organiser while it has
 *     paid, unrefunded orders (server-only paidOrderCount); cancelling it
 *     refunds every paid order IN FULL on the connected account
 *     (refund_application_fee), invalidates the tickets, releases the
 *     counters, and the event can't be re-opened (ticketRefundsAt);
 *   - the refund outbox / batch docs and the order refund fields are
 *     server-only;
 *   - refund_proofs/{orderId}/{file}: the seller only, once, image / PDF
 *     <= 10 MB, only while the refund failed; seller + staff read;
 *   - every account-deletion entry point refuses while paid, unrefunded
 *     sales exist (deleteMyAccount, requestAccountDeletion signed-in,
 *     confirmAccountDeletion GET + POST), getDeletionBlockers lists them,
 *     and deletion works again once they are refunded.
 *
 * Run against BOTH rule files (firestore.rules and firestore.additive.rules):
 *   firebase emulators:exec --only firestore,auth,storage --project test-project \
 *     "cd functions && npx jest -i --config jest.security.config.js __tests__/security/refunds-deletion.emulator.test.ts"
 *   (and once more with a firebase config whose firestore.rules points to the additive file)
 */

process.env.STRIPE_SECRET_KEY = 'sk_test_platform_fake';
process.env.STRIPE_CONNECT_WEBHOOK_SECRET = 'whsec_test_connect';
process.env.TICKET_QR_SIGNING_KEY = 'fake'.repeat(10); // test-only value, not a key
process.env.DELETION_MIN_RESPONSE_MS = '0';

import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import * as http from 'http';
import functionsTest from 'firebase-functions-test';

const PROJECT = process.env.GCLOUD_PROJECT || 'test-project';
if (!admin.apps.length) admin.initializeApp({ projectId: PROJECT, storageBucket: `${PROJECT}.appspot.com` });
const fft = functionsTest({ projectId: PROJECT });

import { ticketDeps } from '../../src/ticket_payments/providers';
import { handleStripeConnectWebhook, stripeVerifier } from '../../src/ticket_payments/webhooks';
import { createTicketCheckout } from '../../src/ticket_payments/orders';
import * as R from '../../src/ticket_payments/refunds';
import * as ep from '../../src/auth/accountDeletionEndpoints';

const db = admin.firestore();
const TS = admin.firestore.Timestamp;
const HOUR = 3600 * 1000;
const realFetch: typeof fetch = (globalThis as any).fetch;

const refundCalls: any[] = [];
let sessionSeq = 0;
const fakeStripe: any = {
  checkout: {
    sessions: {
      create: jest.fn(async () => { sessionSeq += 1; return { id: `cs_${sessionSeq}`, url: `https://checkout.stripe.test/cs_${sessionSeq}` }; }),
      retrieve: jest.fn(async (id: string) => ({ id, payment_status: 'unpaid', metadata: {} })),
      expire: jest.fn(async () => ({})),
    },
  },
  refunds: {
    create: jest.fn(async (params: any, opts: any) => { refundCalls.push({ params, opts }); return { id: `re_${refundCalls.length}` }; }),
  },
};
ticketDeps.stripe = () => fakeStripe;

const pushes: R.RefundNotice[] = [];
const mails: string[] = [];
R.refundDeps.notify = async (p) => { pushes.push(p); };
R.refundDeps.email = async (kind, orderId) => { mails.push(`${kind}:${orderId}`); };

async function clearAll() {
  const host = process.env.FIRESTORE_EMULATOR_HOST!;
  if (!/^(localhost|127\.0\.0\.1|0\.0\.0\.0)/.test(host)) throw new Error('Refusing: not a local emulator');
  await new Promise<void>((resolve, reject) => {
    const req = http.request({ host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'DELETE',
      path: `/emulator/v1/projects/${PROJECT}/databases/(default)/documents` }, (res) => { res.resume(); res.on('end', resolve); });
    req.on('error', reject);
    req.end();
  });
  const users = await admin.auth().listUsers(1000);
  if (users.users.length) await admin.auth().deleteUsers(users.users.map((u) => u.uid));
}

const ORG = 'organizer01';
const BUYER = 'buyer01';
const STRANGER = 'stranger01';

async function seed() {
  await db.doc(`profiles/${ORG}`).set({
    displayName: 'Org', isBusiness: true, membershipTier: 'PLATINUM',
    membershipEndDate: TS.fromMillis(Date.now() + 365 * 24 * HOUR),
  });
  await db.doc(`profiles/${BUYER}`).set({ displayName: 'Buyer', hasBaseMembership: true, baseMembershipEndDate: TS.fromMillis(Date.now() + 365 * 24 * HOUR) });
  await db.doc(`finance_billing_profiles/${ORG}`).set({
    type: 'company', country: 'BR', legalName: 'Org Eventos Ltda', taxId: '11222333000181', taxIdKind: 'cnpj',
    email: 'billing@org.test', address: { street: 'Rua A', number: '1', city: 'São Paulo', state: 'SP', postalCode: '01000-000', country: 'BR' },
  });
  await db.doc(`payment_accounts/${ORG}`).set({
    uid: ORG, stripe: { accountId: 'acct_org', chargesEnabled: true, detailsSubmitted: true, status: 'ready', country: 'BR' },
    feeTrial: { key: null },
  });
}

const PHASES = [
  { id: 'eb', nameKey: 'earlyBird', price: 20, quantity: 2 },
  { id: 'rg', nameKey: 'regular', price: 30, quantity: 3 },
];
async function paidEvent(id: string, over: Record<string, any> = {}) {
  await db.doc(`events/${id}`).set({
    organizerId: ORG, title: 'Rooftop Samba', description: 'Music', price: 20, currency: 'R$', currencyCode: 'brl',
    maxAttendees: 0, attendeeCount: 0, maxTicketsPerUser: null,
    status: 'published', ticketProvider: 'stripe', pricePhases: PHASES,
    startDate: TS.fromMillis(Date.now() + 24 * HOUR), endDate: TS.fromMillis(Date.now() + 28 * HOUR), ...over,
  });
}

function stripeEvent(type: string, object: any) {
  const payload = JSON.stringify({ id: `evt_${crypto.randomBytes(6).toString('hex')}`, object: 'event', type, account: 'acct_org', data: { object } });
  const header = stripeVerifier().webhooks.generateTestHeaderString({ payload, secret: process.env.STRIPE_CONNECT_WEBHOOK_SECRET! });
  return { payload, header };
}
async function buyAndPay(eventId: string, quantity = 2, pi = 'pi_1'): Promise<string> {
  const r: any = await createTicketCheckout(BUYER, { kind: 'event', id: eventId, quantity }, 'buyer@example.com');
  const o = (await db.doc(`ticket_orders/${r.orderId}`).get()).data()!;
  const ev = stripeEvent('checkout.session.completed', {
    id: o.providerRef.stripeSessionId, object: 'checkout.session', payment_status: 'paid', amount_total: o.totalAmount,
    currency: 'brl', payment_intent: pi, metadata: { orderId: r.orderId, greengo: 'ticket' },
  });
  await handleStripeConnectWebhook(Buffer.from(ev.payload), ev.header);
  return r.orderId;
}

// Firestore / Storage REST as a signed-in CLIENT (rules apply).
function idToken(uid: string, claims: Record<string, unknown> = {}): string {
  const b = (o: any) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  return `${b({ alg: 'none', typ: 'JWT' })}.${b({ iss: `https://securetoken.google.com/${PROJECT}`, aud: PROJECT, auth_time: now, user_id: uid, sub: uid, iat: now, exp: now + 3600, phone_number: '+351910000000', firebase: { sign_in_provider: 'password' }, ...claims })}.`;
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
const fsUrl = (path: string) => `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${PROJECT}/databases/(default)/documents/${path}`;
async function clientWrite(uid: string, path: string, data: Record<string, any>, mask?: string[]): Promise<number> {
  const q = mask ? '?' + mask.map((m) => `updateMask.fieldPaths=${encodeURIComponent(m)}`).join('&') : '';
  const res = await realFetch(fsUrl(path) + q, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${idToken(uid)}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, toValue(v)])) }),
  });
  await res.text();
  return res.status;
}
async function clientDelete(uid: string, path: string): Promise<number> {
  const res = await realFetch(fsUrl(path), { method: 'DELETE', headers: { Authorization: `Bearer ${idToken(uid)}` } });
  await res.text();
  return res.status;
}
async function clientRead(uid: string, path: string): Promise<number> {
  const res = await realFetch(fsUrl(path), { headers: { Authorization: `Bearer ${idToken(uid)}` } });
  await res.text();
  return res.status;
}
async function storageUpload(uid: string, path: string, contentType = 'application/pdf', bytes = 1024, claims: Record<string, unknown> = {}): Promise<number> {
  const host = process.env.FIREBASE_STORAGE_EMULATOR_HOST!;
  const B = `gg${crypto.randomBytes(6).toString('hex')}`;
  const body = Buffer.concat([
    Buffer.from(`--${B}\r\nContent-Type: application/json; charset=utf-8\r\n\r\n${JSON.stringify({ name: path, contentType })}\r\n--${B}\r\nContent-Type: ${contentType}\r\n\r\n`),
    Buffer.alloc(bytes, 1),
    Buffer.from(`\r\n--${B}--`),
  ]);
  const res = await realFetch(`http://${host}/v0/b/${PROJECT}.appspot.com/o?name=${encodeURIComponent(path)}`, {
    method: 'POST',
    headers: { Authorization: `Firebase ${idToken(uid, claims)}`, 'Content-Type': `multipart/related; boundary=${B}`, 'X-Goog-Upload-Protocol': 'multipart' },
    body,
  });
  await res.text();
  return res.status;
}
async function storageGet(uid: string, path: string, claims: Record<string, unknown> = {}): Promise<number> {
  const host = process.env.FIREBASE_STORAGE_EMULATOR_HOST!;
  const res = await realFetch(`http://${host}/v0/b/${PROJECT}.appspot.com/o/${encodeURIComponent(path)}?alt=media`, {
    headers: { Authorization: `Firebase ${idToken(uid, claims)}` },
  });
  await res.text();
  return res.status;
}

function mockRes() {
  const r: any = {
    statusCode: 0, headers: {} as Record<string, string>, body: undefined,
    status(c: number) { this.statusCode = c; return this; },
    json(b: any) { this.body = b; return this; },
    send(b: any) { this.body = b; return this; },
    set(k: string, v: string) { this.headers[k.toLowerCase()] = v; return this; },
    type(t: string) { this.headers['content-type'] = t; return this; },
    setHeader(k: string, v: string) { this.headers[k.toLowerCase()] = v; return this; },
    end() { return this; },
  };
  return r;
}
function mockReq(o: { method?: string; body?: any; query?: any; headers?: any } = {}) {
  return { method: o.method ?? 'POST', headers: { ...(o.headers || {}) }, body: o.body ?? {}, query: o.query ?? {}, ip: '203.0.113.7', get: () => undefined } as any;
}
async function idTokenFor(uid: string): Promise<string> {
  const custom = await admin.auth().createCustomToken(uid);
  const host = process.env.FIREBASE_AUTH_EMULATOR_HOST!;
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ token: custom, returnSecureToken: true });
    const req = http.request({
      host: host.split(':')[0], port: Number(host.split(':')[1]), method: 'POST',
      path: '/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    }, (r) => {
      let s = '';
      r.on('data', (c) => (s += c));
      r.on('end', () => { try { resolve(JSON.parse(s).idToken); } catch (e) { reject(e); } });
    });
    req.on('error', reject);
    req.end(body);
  });
}
const v2call = (fn: any, data: any, authCtx?: any) => (fft.wrap(fn) as any)({ data, auth: authCtx });

beforeEach(async () => {
  await clearAll();
  refundCalls.length = 0;
  pushes.length = 0;
  mails.length = 0;
  await seed();
});
afterAll(() => fft.cleanup());

// ═══════════════════════════════════════════════ events

describe('paid event: no hard delete with sales; cancel = automatic full refunds', () => {
  test('end to end', async () => {
    await paidEvent('e1');
    const orderId = await buyAndPay('e1', 2);
    let ev = (await db.doc('events/e1').get()).data()!;
    expect(ev.paidOrderCount).toBe(1);
    expect(ev.attendeeCount).toBe(2);

    // The organiser cannot delete it, nor reset the server counter.
    expect(await clientDelete(ORG, 'events/e1')).toBe(403);
    expect(await clientWrite(ORG, 'events/e1', { paidOrderCount: 0 }, ['paidOrderCount'])).toBe(403);
    expect(await clientWrite(ORG, 'events/e1', { ticketRefundsAt: new Date() }, ['ticketRefundsAt'])).toBe(403);

    // Cancelling is allowed; the trigger body enqueues, the worker refunds.
    const before = ev;
    expect(await clientWrite(ORG, 'events/e1', { status: 'cancelled' }, ['status'])).toBe(200);
    const after = (await db.doc('events/e1').get()).data()!;
    expect(R.eventRefundAction(before, after, Date.now())).toBe('event_cancelled');
    const r = await R.enqueueEventRefunds('e1', after, 'event_cancelled');
    expect(r).toEqual({ paid: 1, enqueued: 1, closedOpen: 0 });
    expect(await R.processRefund(orderId)).toBe('refunded');

    // Stripe: full refund ON the connected account, fee returned, idempotent key.
    expect(refundCalls).toHaveLength(1);
    expect(refundCalls[0].params).toMatchObject({ payment_intent: 'pi_1', refund_application_fee: true });
    expect(refundCalls[0].params.amount).toBeUndefined(); // whole charge
    expect(refundCalls[0].opts).toEqual({ stripeAccount: 'acct_org', idempotencyKey: `gg_refund_${orderId}` });

    const o = (await db.doc(`ticket_orders/${orderId}`).get()).data()!;
    expect(o.status).toBe('refunded');
    expect(o.refund).toMatchObject({ status: 'requested', reason: 'event_cancelled' });
    for (const tid of o.ticketIds) expect((await db.doc(`tickets/${tid}`).get()).data()!.status).toBe('refunded');
    const inv = (await db.doc('ticket_inventory/event_e1').get()).data() || {};
    expect(inv.phaseSold?.eb ?? 0).toBe(0);
    ev = (await db.doc('events/e1').get()).data()!;
    expect(ev.paidOrderCount).toBe(0);
    expect(ev.attendeeCount).toBe(0);
    expect(ev.ticketRefundsAt).toBeTruthy();
    expect((await db.doc(`ticket_holdings/event_e1_${BUYER}`).get()).data()!.owned).toBe(0);
    expect(pushes.some((p) => p.recipientId === BUYER && p.type === 'ticket_refund_started')).toBe(true);
    expect(pushes.some((p) => p.recipientId === ORG && p.type === 'ticket_refund_summary')).toBe(true);
    expect(mails).toEqual([`started:${orderId}`]);

    // Re-trigger: no second refund.
    await R.enqueueEventRefunds('e1', after, 'event_cancelled');
    await R.sweepDueRefunds();
    expect(refundCalls).toHaveLength(1);

    // Refunds started: the event can't be re-opened; other edits still work.
    expect(await clientWrite(ORG, 'events/e1', { status: 'published' }, ['status'])).toBe(403);
    expect(await clientWrite(ORG, 'events/e1', { description: 'Cancelled, sorry' }, ['description'])).toBe(200);
    // Every order refunded: deleting is allowed again.
    expect(await clientDelete(ORG, 'events/e1')).toBe(200);
  });

  test('a paid event WITHOUT sales can still be deleted', async () => {
    await paidEvent('e2');
    expect(await clientDelete(ORG, 'events/e2')).toBe(200);
  });

  test('a co-owner cannot write the server fields either', async () => {
    await paidEvent('e3', { coOrganizerIds: ['coowner1'], paidOrderCount: 2 });
    expect(await clientWrite('coowner1', 'events/e3', { paidOrderCount: 0 }, ['paidOrderCount'])).toBe(403);
    expect(await clientWrite('coowner1', 'events/e3', { description: 'ok' }, ['description'])).toBe(200);
  });

  test('refund outbox, batches and order refund fields are server-only', async () => {
    await paidEvent('e4');
    const orderId = await buyAndPay('e4', 1);
    await db.doc('events/e4').update({ status: 'cancelled' });
    await R.enqueueEventRefunds('e4', (await db.doc('events/e4').get()).data()!, 'event_cancelled');
    for (const uid of [ORG, BUYER, STRANGER]) {
      expect(await clientRead(uid, `ticket_refunds/${orderId}`)).toBe(403);
      expect(await clientRead(uid, 'ticket_refund_batches/event_e4')).toBe(403);
      expect(await clientWrite(uid, `ticket_refunds/${orderId}`, { status: 'refunded' })).toBe(403);
    }
    expect(await clientWrite(ORG, `ticket_orders/${orderId}`, { refund: { status: 'refunded_manually' } }, ['refund'])).toBe(403);
    expect(await clientWrite(BUYER, `ticket_orders/${orderId}`, { status: 'refunded' }, ['status'])).toBe(403);
    // The buyer and the organiser can still read the order (refund status mirror).
    expect(await clientRead(BUYER, `ticket_orders/${orderId}`)).toBe(200);
    expect(await clientRead(ORG, `ticket_orders/${orderId}`)).toBe(200);
  });
});

// ═══════════════════════════════════════════════ manual refund proof storage

describe('refund_proofs storage', () => {
  async function failedOrder(id: string, status = 'refund_failed') {
    await db.doc(`ticket_orders/${id}`).set({
      kind: 'event', listingId: 'e9', organizerId: ORG, buyerId: BUYER, status: 'paid', provider: 'stripe',
      totalAmount: 5000, currency: 'brl', refund: { status },
    });
  }

  test('seller only, image / PDF <= 10 MB, once, only while the refund failed; seller + staff read', async () => {
    const id = `o${crypto.randomBytes(4).toString('hex')}`;
    await failedOrder(id);
    const p = `refund_proofs/${id}/proof.pdf`;
    expect(await storageUpload(STRANGER, p)).toBe(403);
    expect(await storageUpload(BUYER, p)).toBe(403);
    expect(await storageUpload(ORG, `refund_proofs/${id}/x.txt`, 'text/plain')).toBe(403);
    expect(await storageUpload(ORG, `refund_proofs/${id}/big.pdf`, 'application/pdf', 11 * 1024 * 1024)).toBe(403);
    expect(await storageUpload(ORG, p)).toBe(200);
    expect(await storageUpload(ORG, p)).toBe(403); // written once
    expect(await storageUpload(ORG, `refund_proofs/${id}/photo.jpg`, 'image/jpeg')).toBe(200);
    expect(await storageGet(ORG, p)).toBe(200);
    expect(await storageGet(STRANGER, p)).toBe(403);
    expect(await storageGet(BUYER, p)).toBe(403);
    expect(await storageGet('staff01', p, { adminRole: 'support' })).toBe(200);
  });

  test('no upload while the refund is not failed', async () => {
    const id = `o${crypto.randomBytes(4).toString('hex')}`;
    await failedOrder(id, 'requested');
    expect(await storageUpload(ORG, `refund_proofs/${id}/proof.pdf`)).toBe(403);
  });
});

// ═══════════════════════════════════════════════ account deletion blockers

describe('account deletion is refused while paid sales are not refunded', () => {
  async function orgWithSale(): Promise<string> {
    await admin.auth().createUser({ uid: ORG, email: 'org@example.com', password: 'Passw0rd!x' });
    await paidEvent('d1');
    return buyAndPay('d1', 1);
  }

  test('getDeletionBlockers + every entry point refuses; nothing is deleted', async () => {
    const orderId = await orgWithSale();
    const g = await v2call(ep.getDeletionBlockers, {}, { uid: ORG, token: {} });
    expect(g.blocked).toBe(true);
    expect(g.blockers[0]).toMatchObject({ kind: 'event', listingId: 'd1', paidOrders: 1 });

    // App callable.
    await expect(v2call(ep.deleteMyAccount, {}, { uid: ORG, token: { auth_time: Math.floor(Date.now() / 1000) - 30 } }))
      .rejects.toMatchObject({ code: 'failed-precondition', details: { code: 'deletion_blocked_paid_orders' } });

    // Website, signed-in mode.
    const tok = await idTokenFor(ORG);
    const res1 = mockRes();
    await ep.handleRequestAccountDeletion(mockReq({ headers: { authorization: `Bearer ${tok}`, origin: 'https://greengochat.com' } }), res1);
    expect(res1.statusCode).toBe(409);
    expect(res1.body.code).toBe('deletion_blocked_paid_orders');

    // Website, e-mail link: GET shows the list, POST refuses and gives the link back.
    const token = crypto.randomBytes(32).toString('base64url');
    await db.doc(`deletion_requests/${ep.sha256(token)}`).set({
      uid: ORG, used: false, createdAt: TS.now(), expiresAt: TS.fromMillis(Date.now() + HOUR),
    });
    const get = mockRes();
    await ep.handleConfirmAccountDeletion(mockReq({ method: 'GET', query: { token } }), get);
    expect(get.statusCode).toBe(409);
    expect(get.body).toContain('Rooftop Samba');
    expect(get.body).not.toContain('<form');
    const post = mockRes();
    await ep.handleConfirmAccountDeletion(mockReq({ method: 'POST', body: { token } }), post);
    expect(post.statusCode).toBe(409);
    expect((await db.doc(`deletion_requests/${ep.sha256(token)}`).get()).data()!.used).toBe(false);

    expect((await admin.auth().getUser(ORG)).uid).toBe(ORG);
    expect((await db.doc(`profiles/${ORG}`).get()).exists).toBe(true);
    expect((await db.doc(`ticket_orders/${orderId}`).get()).data()!.status).toBe('paid');
  });

  test('once the event is cancelled and refunded, nothing blocks any more', async () => {
    const orderId = await orgWithSale();
    await db.doc('events/d1').update({ status: 'cancelled' });
    await R.enqueueEventRefunds('d1', (await db.doc('events/d1').get()).data()!, 'event_cancelled');
    // Refund in progress: still blocked.
    let g = await v2call(ep.getDeletionBlockers, {}, { uid: ORG, token: {} });
    expect(g.blockers[0]).toMatchObject({ refundsInProgress: 1 });
    await R.processRefund(orderId);
    g = await v2call(ep.getDeletionBlockers, {}, { uid: ORG, token: {} });
    expect(g).toEqual({ blocked: false, code: null, blockers: [] });
  });

  test('a failed refund keeps blocking until an admin accepts the proof', async () => {
    const orderId = await orgWithSale();
    await db.doc('events/d1').update({ status: 'cancelled' });
    await R.enqueueEventRefunds('d1', (await db.doc('events/d1').get()).data()!, 'event_cancelled');
    fakeStripe.refunds.create.mockImplementationOnce(async () => {
      const e: any = new Error('insufficient'); e.code = 'balance_insufficient'; e.type = 'StripeInvalidRequestError'; throw e;
    });
    expect(await R.processRefund(orderId)).toBe('refund_failed');
    let g = await v2call(ep.getDeletionBlockers, {}, { uid: ORG, token: {} });
    expect(g.blockers[0]).toMatchObject({ failedRefunds: 1, actionOrders: [{ orderId, status: 'refund_failed' }] });

    expect(await storageUpload(ORG, `refund_proofs/${orderId}/pix.pdf`)).toBe(200);
    await R.submitManualRefundProof(ORG, { orderId, proofPath: `refund_proofs/${orderId}/pix.pdf` });
    g = await v2call(ep.getDeletionBlockers, {}, { uid: ORG, token: {} });
    expect(g.blockers[0]).toMatchObject({ pendingReview: 1 });

    // Admin review goes through the callable (superAdmin only).
    const { adminReviewManualRefund } = require('../../src/ticket_payments');
    await expect(v2call(adminReviewManualRefund, { orderId, approve: true }, { uid: STRANGER, token: {} }))
      .rejects.toMatchObject({ code: 'permission-denied' });
    await db.doc('admin_users/super1').set({ role: 'superAdmin' });
    const r = await v2call(adminReviewManualRefund, { orderId, approve: true }, { uid: 'super1', token: {} });
    expect(r.status).toBe('refunded_manually');
    expect((await db.doc(`ticket_orders/${orderId}`).get()).data()!.status).toBe('refunded');
    g = await v2call(ep.getDeletionBlockers, {}, { uid: ORG, token: {} });
    expect(g.blocked).toBe(false);
  });
});
