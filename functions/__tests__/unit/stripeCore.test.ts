/**
 * payments/stripeCore.ts - webhook dedupe, paid-period entitlement,
 * refund / dispute revocation. Mocked Stripe + in-memory Firestore; the
 * webhook signatures are REAL (generated and verified offline).
 */

import Stripe from 'stripe';
import * as admin from 'firebase-admin';
import {
  FakeFirestore,
  StripeState,
  emptyStripeState,
  fakeRes,
  makeFakeStripe,
} from '../utils/stripeFakes';
import * as core from '../../src/payments/stripeCore';

const NOW = new Date(Date.UTC(2026, 8, 10, 12, 0, 0));
const DAY = 86400;
const T0 = Math.floor(Date.UTC(2026, 8, 1) / 1000);
const WHSEC = 'whsec_unit_test_secret';
const GRACE_MS = core.RENEWAL_GRACE_MS;

let db: FakeFirestore;
let state: StripeState;
let stripe: any;
let downgrades: Array<{ uid: string; reason: string }>;
const emails: Record<string, string> = { u1: 'jdoe@gmail.com', u2: 'other@example.com' };
const savedDeps = { ...core.stripeCoreDeps };

const signer = new Stripe('sk_test_signer', { apiVersion: core.STRIPE_API_VERSION }).webhooks;

function evt(id: string, type: string, object: any, livemode = true) {
  return { id, object: 'event', type, livemode, data: { object } };
}

function signed(event: any, secret = WHSEC) {
  const payload = JSON.stringify(event);
  const header = signer.generateTestHeaderString({ payload, secret });
  return { method: 'POST', headers: { 'stripe-signature': header }, rawBody: Buffer.from(payload) };
}

async function deliver(event: any) {
  const res = fakeRes();
  await core.handleStripeWebhookHttp(signed(event), res);
  return res;
}

function seedUser(uid = 'u1', cus = 'cus_1') {
  db.seed('profiles', uid, { membershipTier: 'FREE', email: emails[uid] });
  state.customers[cus] = { id: cus, email: emails[uid], metadata: { firebaseUserId: uid } };
}

function seedSub(opts: {
  subId?: string; productId?: string; tier?: string; uid?: string; cus?: string;
  invId?: string; chId?: string; start?: number; days?: number; unit?: number; paid?: number;
  reason?: string; status?: string; replaces?: string; trialEnd?: number; interval?: string;
} = {}) {
  const o = {
    subId: 'sub_1', productId: '1_month_silver', tier: 'SILVER', uid: 'u1', cus: 'cus_1',
    invId: 'in_1', chId: 'ch_1', start: T0, days: 30, unit: 999, reason: 'subscription_create',
    status: 'active', ...opts,
  };
  const paid = opts.paid ?? o.unit;
  const end = o.start + o.days * DAY;
  state.subscriptions[o.subId] = {
    id: o.subId, object: 'subscription', customer: o.cus, status: o.status, livemode: true,
    cancel_at_period_end: false, current_period_end: end, latest_invoice: o.invId, created: o.start,
    ...(o.trialEnd ? { trial_end: o.trialEnd } : {}),
    metadata: {
      userId: o.uid, productId: o.productId, tier: o.tier,
      ...(o.replaces ? { replacesSubscriptionId: o.replaces } : {}),
    },
  };
  addInvoice({ ...o, paid, end });
}

function addInvoice(o: any) {
  const end = o.end ?? o.start + o.days * DAY;
  state.invoices[o.invId] = {
    id: o.invId, object: 'invoice', customer: o.cus ?? 'cus_1', subscription: o.subId ?? 'sub_1',
    status: 'paid', amount_paid: o.paid, total: o.paid, currency: 'usd', created: o.start,
    billing_reason: o.reason, livemode: true, charge: o.paid > 0 ? o.chId : null,
    customer_email: emails[o.uid ?? 'u1'],
    lines: { data: [{
      type: 'subscription', subscription: o.subId ?? 'sub_1', proration: false, quantity: 1,
      amount: o.unit, period: { start: o.start, end },
      price: { unit_amount: o.unit, currency: 'usd', recurring: { interval: o.interval ?? (o.days >= 365 ? 'year' : 'month') } },
    }] },
  };
  if (o.paid > 0) {
    state.charges[o.chId] = {
      id: o.chId, object: 'charge', customer: o.cus ?? 'cus_1', invoice: o.invId, amount: o.paid,
      amount_refunded: 0, currency: 'usd', paid: true, status: 'succeeded', refunded: false,
      disputed: false, livemode: true, created: o.start, payment_intent: `pi_${o.chId}`,
      billing_details: { email: emails[o.uid ?? 'u1'] },
    };
  }
}

function seedCoinSession(id = 'cs_1', opts: { amount?: number; payment_status?: string; uid?: string } = {}) {
  const amount = opts.amount ?? 399;
  state.sessions[id] = {
    id, object: 'checkout.session', mode: 'payment', status: 'complete',
    payment_status: opts.payment_status ?? 'paid', client_reference_id: opts.uid ?? 'u1',
    metadata: { userId: opts.uid ?? 'u1', productId: 'greengo_coins_500', type: 'coins' },
    customer: 'cus_1', currency: 'usd', amount_total: amount, livemode: true,
    payment_intent: `pi_${id}`, created: T0, line_items: { data: [{ amount_total: amount, quantity: 1 }] },
  };
}

const endOf = (uid: string, field = 'membershipEndDate') =>
  (db.get('profiles', uid)?.[field] as admin.firestore.Timestamp | undefined)?.toMillis();

beforeEach(() => {
  db = new FakeFirestore();
  state = emptyStripeState();
  stripe = makeFakeStripe(state);
  downgrades = [];
  core.stripeCoreDeps.db = () => db as any;
  core.stripeCoreDeps.stripe = () => stripe;
  core.stripeCoreDeps.now = () => NOW;
  core.stripeCoreDeps.getUserEmail = async (uid: string) => emails[uid] ?? null;
  core.stripeCoreDeps.downgradeTierNow = async (uid: string, reason: string) => {
    downgrades.push({ uid, reason });
    db.write('profiles', uid, { membershipTier: 'FREE', membershipExpiryReason: reason }, true);
    return 'SILVER';
  };
  process.env.STRIPE_WEBHOOK_SECRET = WHSEC;
  delete process.env.STRIPE_TEST_WEBHOOK_SECRET;
  seedUser('u1', 'cus_1');
});

afterAll(() => {
  Object.assign(core.stripeCoreDeps, savedDeps);
});

// ---------------------------------------------------------------------------
describe('(a) webhook signature + dedupe', () => {
  test('the same event delivered concurrently and again grants coins exactly once', async () => {
    seedCoinSession('cs_1');
    const e = evt('evt_1', 'checkout.session.completed', { id: 'cs_1' });
    const [r1, r2] = [fakeRes(), fakeRes()];
    await Promise.all([
      core.handleStripeWebhookHttp(signed(e), r1),
      core.handleStripeWebhookHttp(signed(e), r2),
    ]);
    expect([r1.statusCode, r2.statusCode].sort()).toEqual([200, 409]);
    const r3 = await deliver(e);
    expect(r3.statusCode).toBe(200);
    expect(r3.body).toMatchObject({ duplicate: true });

    expect(db.get('coinBalances', 'u1')?.totalCoins).toBe(500);
    expect(db.get('coinBalances', 'u1')?.coinBatches).toHaveLength(1);
    expect(db.count('coinTransactions')).toBe(1);
    expect(db.get('stripe_events', 'evt_1')?.status).toBe('done');
    expect(db.get('stripe_orders', 'cs_1')?.status).toBe('completed');
  });

  test('different events for the same paid session still grant once', async () => {
    seedCoinSession('cs_1');
    await deliver(evt('evt_a', 'checkout.session.completed', { id: 'cs_1' }));
    await deliver(evt('evt_b', 'checkout.session.async_payment_succeeded', { id: 'cs_1' }));
    expect(db.get('coinBalances', 'u1')?.totalCoins).toBe(500);
  });

  test('an existing balance is incremented, not replaced', async () => {
    db.seed('coinBalances', 'u1', { userId: 'u1', totalCoins: 40, purchasedCoins: 10, coinBatches: [{ batchId: 'old' }] });
    seedCoinSession('cs_1');
    await deliver(evt('evt_1', 'checkout.session.completed', { id: 'cs_1' }));
    expect(db.get('coinBalances', 'u1')).toMatchObject({ totalCoins: 540, purchasedCoins: 510 });
    expect(db.get('coinBalances', 'u1')?.coinBatches).toHaveLength(2);
  });

  test('missing / invalid signatures are rejected; no secret fails closed', async () => {
    seedCoinSession('cs_1');
    const e = evt('evt_1', 'checkout.session.completed', { id: 'cs_1' });
    const noSig = fakeRes();
    await core.handleStripeWebhookHttp({ method: 'POST', headers: {}, rawBody: Buffer.from(JSON.stringify(e)) }, noSig);
    expect(noSig.statusCode).toBe(400);

    const bad = fakeRes();
    await core.handleStripeWebhookHttp(signed(e, 'whsec_attacker'), bad);
    expect(bad.statusCode).toBe(400);

    delete process.env.STRIPE_WEBHOOK_SECRET;
    const closed = fakeRes();
    await core.handleStripeWebhookHttp(signed(e), closed);
    expect(closed.statusCode).toBe(500);
    expect(db.get('coinBalances', 'u1')).toBeUndefined();
  });

  test('several live secrets (two endpoints) are all accepted', async () => {
    process.env.STRIPE_WEBHOOK_SECRET = `whsec_other, ${WHSEC}`;
    seedCoinSession('cs_1');
    const r = await deliver(evt('evt_1', 'checkout.session.completed', { id: 'cs_1' }));
    expect(r.statusCode).toBe(200);
    expect(db.get('coinBalances', 'u1')?.totalCoins).toBe(500);
  });

  test('a failed delivery answers 500, and the retry grants once', async () => {
    seedCoinSession('cs_1');
    const realRetrieve = stripe.checkout.sessions.retrieve;
    stripe.checkout.sessions.retrieve = async () => { throw new Error('stripe down'); };
    const e = evt('evt_1', 'checkout.session.completed', { id: 'cs_1' });
    const r1 = await deliver(e);
    expect(r1.statusCode).toBe(500);
    expect(db.get('stripe_events', 'evt_1')?.status).toBe('failed');

    stripe.checkout.sessions.retrieve = realRetrieve;
    expect((await deliver(e)).statusCode).toBe(200);
    expect((await deliver(e)).body).toMatchObject({ duplicate: true });
    expect(db.get('coinBalances', 'u1')?.totalCoins).toBe(500);
  });

  test('an unpaid (async / PIX pending) session grants nothing', async () => {
    seedCoinSession('cs_1', { payment_status: 'unpaid' });
    await deliver(evt('evt_1', 'checkout.session.completed', { id: 'cs_1' }));
    expect(db.get('coinBalances', 'u1')).toBeUndefined();
  });

  test('an amount that does not match the price table grants nothing and is flagged', async () => {
    seedCoinSession('cs_1', { amount: 1 });
    await deliver(evt('evt_1', 'checkout.session.completed', { id: 'cs_1' }));
    expect(db.get('coinBalances', 'u1')).toBeUndefined();
    expect(db.all('stripe_payment_flags').map(([, f]) => f.type)).toContain('amount_mismatch');
  });

  test('client_reference_id must match the session uid', async () => {
    seedCoinSession('cs_1');
    state.sessions.cs_1.client_reference_id = 'u2';
    await deliver(evt('evt_1', 'checkout.session.completed', { id: 'cs_1' }));
    expect(db.get('coinBalances', 'u1')).toBeUndefined();
    expect(db.get('coinBalances', 'u2')).toBeUndefined();
  });

  test('a test-mode event signed with the live secret is ignored', async () => {
    seedCoinSession('cs_1');
    const r = await deliver(evt('evt_1', 'checkout.session.completed', { id: 'cs_1' }, false));
    expect(r.body).toMatchObject({ ignored: 'livemode_mismatch' });
    expect(db.get('coinBalances', 'u1')).toBeUndefined();
  });
});

// ---------------------------------------------------------------------------
describe('(b) membership lasts exactly the paid period', () => {
  test('invoice.paid sets the end to the paid line period end + grace, not now + 30 days', async () => {
    seedSub();
    await deliver(evt('evt_1', 'invoice.paid', { id: 'in_1' }));
    const p = db.get('profiles', 'u1')!;
    expect(p.membershipTier).toBe('SILVER');
    expect(endOf('u1')).toBe((T0 + 30 * DAY) * 1000 + GRACE_MS);
    expect(endOf('u1')).not.toBe(NOW.getTime() + 30 * DAY * 1000);
    expect(p.stripeSubscriptionId).toBe('sub_1');
    expect(p.membershipSource).toBe('stripe');
    expect(db.get('stripe_invoices', 'in_1')?.status).toBe('applied');
  });

  test('a renewal extends only on its own paid invoice, once', async () => {
    seedSub();
    await deliver(evt('evt_1', 'invoice.paid', { id: 'in_1' }));
    addInvoice({ invId: 'in_2', chId: 'ch_2', start: T0 + 30 * DAY, days: 30, unit: 999, paid: 999, reason: 'subscription_cycle' });
    await deliver(evt('evt_2', 'invoice.paid', { id: 'in_2' }));
    await deliver(evt('evt_2b', 'invoice.paid', { id: 'in_2' })); // other endpoint / resend
    expect(endOf('u1')).toBe((T0 + 60 * DAY) * 1000 + GRACE_MS);
  });

  test('subscription.updated and invoice.payment_failed never extend', async () => {
    seedSub();
    await deliver(evt('evt_1', 'invoice.paid', { id: 'in_1' }));
    const before = endOf('u1');
    state.subscriptions.sub_1.current_period_end = T0 + 60 * DAY; // period rolled, not paid
    state.subscriptions.sub_1.status = 'past_due';
    await deliver(evt('evt_2', 'customer.subscription.updated', { id: 'sub_1' }));
    addInvoice({ invId: 'in_2', chId: 'ch_2', start: T0 + 30 * DAY, days: 30, unit: 999, paid: 999, reason: 'subscription_cycle' });
    state.invoices.in_2.status = 'open';
    await deliver(evt('evt_3', 'invoice.payment_failed', { id: 'in_2' }));
    expect(endOf('u1')).toBe(before);
    expect(db.get('profiles', 'u1')?.stripeSubscriptionStatus).toBe('past_due');
  });

  test('an invoice priced off the table grants nothing and is flagged', async () => {
    seedSub({ unit: 1, paid: 1 });
    await deliver(evt('evt_1', 'invoice.paid', { id: 'in_1' }));
    expect(db.get('profiles', 'u1')?.membershipTier).toBe('FREE');
    expect(db.all('stripe_payment_flags').map(([, f]) => f.reason)).toContain('amount_mismatch');
  });

  test('subscription metadata uid disagreeing with the customer grants nobody', async () => {
    seedUser('u2', 'cus_2');
    seedSub({ uid: 'u2' }); // sub says u2, customer cus_1 says u1
    await deliver(evt('evt_1', 'invoice.paid', { id: 'in_1' }));
    expect(db.get('profiles', 'u1')?.membershipTier).toBe('FREE');
    expect(db.get('profiles', 'u2')?.membershipTier).toBe('FREE');
    expect(db.all('stripe_payment_flags').map(([, f]) => f.type)).toContain('customer_multiple_uids');
  });

  test('a client-written profiles.stripeCustomerId cannot redirect a payment', async () => {
    seedUser('u2', 'cus_2');
    db.write('profiles', 'u2', { stripeCustomerId: 'cus_1' }, true); // attacker copies victim's id
    seedSub();
    await deliver(evt('evt_1', 'invoice.paid', { id: 'in_1' }));
    expect(db.get('profiles', 'u1')?.membershipTier).toBe('SILVER');
    expect(db.get('profiles', 'u2')?.membershipTier).toBe('FREE');
  });

  test('cancellation trims the end back to the paid period end (no grace)', async () => {
    seedSub();
    await deliver(evt('evt_1', 'invoice.paid', { id: 'in_1' }));
    state.subscriptions.sub_1.status = 'canceled';
    await deliver(evt('evt_2', 'customer.subscription.deleted', { id: 'sub_1' }));
    expect(endOf('u1')).toBe((T0 + 30 * DAY) * 1000);
    expect(db.get('profiles', 'u1')?.stripeSubscriptionId).toBeUndefined();
    expect(downgrades).toHaveLength(0); // still inside the paid period
  });

  test('upgrade: old subscription is cancelled only after the new one is paid', async () => {
    seedSub();
    await deliver(evt('evt_1', 'invoice.paid', { id: 'in_1' }));
    seedSub({ subId: 'sub_2', productId: '1_month_gold', tier: 'GOLD', invId: 'in_g', chId: 'ch_g',
      start: T0 + 5 * DAY, unit: 1799, replaces: 'sub_1' }); // 10% upgrade discount of 1999
    // Before the new invoice is paid nothing happened to the old plan.
    expect(stripe.calls.cancel).toHaveLength(0);
    await deliver(evt('evt_2', 'invoice.paid', { id: 'in_g' }));
    expect(stripe.calls.cancel).toEqual([{ id: 'sub_1', params: { prorate: true, invoice_now: true } }]);
    expect(db.get('profiles', 'u1')?.membershipTier).toBe('GOLD');
    expect(endOf('u1')).toBe((T0 + 35 * DAY) * 1000 + GRACE_MS);
    // The replaced subscription's deletion is ignored.
    await deliver(evt('evt_3', 'customer.subscription.deleted', { id: 'sub_1' }));
    expect(db.get('profiles', 'u1')?.membershipTier).toBe('GOLD');
    expect(db.get('profiles', 'u1')?.stripeSubscriptionId).toBe('sub_2');
  });

  test('Base: $0 trial grants the trial only, bonus coins on the first real payment, once', async () => {
    const trialEnd = T0 + 7 * DAY;
    seedSub({ subId: 'sub_b', productId: 'greengo_base_membership', tier: 'BASE', invId: 'in_t',
      chId: 'ch_t', days: 7, unit: 499, paid: 0, trialEnd, status: 'trialing', interval: 'year' });
    await deliver(evt('evt_1', 'invoice.paid', { id: 'in_t' }));
    let p = db.get('profiles', 'u1')!;
    expect(p.hasBaseMembership).toBe(true);
    expect(endOf('u1', 'baseMembershipEndDate')).toBe(trialEnd * 1000 + GRACE_MS);
    expect(p.membershipTier).toBe('FREE'); // Base never touches the tier
    expect(db.get('coinBalances', 'u1')).toBeUndefined();

    addInvoice({ invId: 'in_b1', chId: 'ch_b1', subId: 'sub_b', start: trialEnd, days: 365, unit: 499, paid: 499, reason: 'subscription_cycle' });
    await deliver(evt('evt_2', 'invoice.paid', { id: 'in_b1' }));
    expect(db.get('coinBalances', 'u1')?.totalCoins).toBe(500);
    addInvoice({ invId: 'in_b2', chId: 'ch_b2', subId: 'sub_b', start: trialEnd + 365 * DAY, days: 365, unit: 499, paid: 499, reason: 'subscription_cycle' });
    await deliver(evt('evt_3', 'invoice.paid', { id: 'in_b2' }));
    expect(db.get('coinBalances', 'u1')?.totalCoins).toBe(500);
    p = db.get('profiles', 'u1')!;
    expect(endOf('u1', 'baseMembershipEndDate')).toBe((trialEnd + 730 * DAY) * 1000 + GRACE_MS);
    expect(db.get('stripe_customers', 'u1')).toMatchObject({ baseTrialUsed: true });
  });

  test('a $0 invoice that is not a trial grants nothing', async () => {
    seedSub({ paid: 0 });
    await deliver(evt('evt_1', 'invoice.paid', { id: 'in_1' }));
    expect(db.get('profiles', 'u1')?.membershipTier).toBe('FREE');
  });
});

// ---------------------------------------------------------------------------
describe('(c) refunds and disputes end the membership now', () => {
  test('full refund of the running period ends the tier now, once', async () => {
    seedSub();
    await deliver(evt('evt_1', 'invoice.paid', { id: 'in_1' }));
    state.charges.ch_1.refunded = true;
    state.charges.ch_1.amount_refunded = 999;
    await deliver(evt('evt_2', 'charge.refunded', { id: 'ch_1' }));
    expect(endOf('u1')).toBe(NOW.getTime());
    expect(downgrades).toEqual([{ uid: 'u1', reason: 'stripe_refund' }]);
    expect(db.get('stripe_revocations', 'refund_ch_1')).toMatchObject({ action: 'tier_ended', kind: 'refund' });
    await deliver(evt('evt_3', 'charge.refunded', { id: 'ch_1' }));
    expect(downgrades).toHaveLength(1);
    // A late invoice.paid replay for the refunded invoice does not re-grant.
    db.remove('stripe_invoices', 'in_1');
    await deliver(evt('evt_4', 'invoice.paid', { id: 'in_1' }));
    expect(db.get('profiles', 'u1')?.membershipTier).toBe('FREE');
  });

  test('partial refund changes nothing', async () => {
    seedSub();
    await deliver(evt('evt_1', 'invoice.paid', { id: 'in_1' }));
    state.charges.ch_1.amount_refunded = 100;
    const before = endOf('u1');
    await deliver(evt('evt_2', 'charge.refunded', { id: 'ch_1' }));
    expect(endOf('u1')).toBe(before);
    expect(downgrades).toHaveLength(0);
  });

  test('refund of a period that already ended changes nothing', async () => {
    seedSub({ start: T0 - 60 * DAY });
    await deliver(evt('evt_1', 'invoice.paid', { id: 'in_1' }));
    state.charges.ch_1.refunded = true;
    await deliver(evt('evt_2', 'charge.refunded', { id: 'ch_1' }));
    expect(downgrades).toHaveLength(0);
    expect(db.get('stripe_revocations', 'refund_ch_1')?.reason).toBe('past_period');
  });

  test('dispute ends Base now and cancels the subscription', async () => {
    seedSub({ subId: 'sub_b', productId: 'greengo_base_membership', tier: 'BASE', invId: 'in_b',
      chId: 'ch_b', days: 365, unit: 499 });
    await deliver(evt('evt_1', 'invoice.paid', { id: 'in_b' }));
    expect(db.get('profiles', 'u1')?.hasBaseMembership).toBe(true);
    await deliver(evt('evt_2', 'charge.dispute.created', { id: 'dp_1', charge: 'ch_b' }));
    const p = db.get('profiles', 'u1')!;
    expect(p.hasBaseMembership).toBe(false);
    expect(endOf('u1', 'baseMembershipEndDate')).toBe(NOW.getTime());
    expect(stripe.calls.cancel.map((c: any) => c.id)).toEqual(['sub_b']);
    expect(db.get('stripe_revocations', 'dispute_dp_1')?.action).toBe('base_ended');
  });

  test('a refunded coin purchase is flagged for review', async () => {
    seedCoinSession('cs_1');
    await deliver(evt('evt_1', 'checkout.session.completed', { id: 'cs_1' }));
    state.charges.ch_c = {
      id: 'ch_c', customer: 'cus_1', invoice: null, amount: 399, amount_refunded: 399, refunded: true,
      currency: 'usd', payment_intent: 'pi_cs_1', livemode: true,
    };
    await deliver(evt('evt_2', 'charge.refunded', { id: 'ch_c' }));
    expect(db.get('stripe_payment_flags', 'coin_refund_ch_c')).toMatchObject({ type: 'coin_refund', uid: 'u1', status: 'open' });
  });
});

// ---------------------------------------------------------------------------
describe('pure helpers', () => {
  test('allowed membership amounts include list price and upgrade discounts only', () => {
    expect(core.allowedMembershipAmounts('1_month_gold', 'usd').sort()).toEqual([1799, 1999]);
    expect(core.allowedMembershipAmounts('1_month_platinum', 'usd').sort()).toEqual([2549, 2699, 2999]);
    expect(core.allowedMembershipAmounts('1_month_silver', 'jpy')).toEqual([]);
    expect(core.allowedMembershipAmounts('nope', 'usd')).toEqual([]);
  });

  test('invoice subscription id is read across API versions', () => {
    expect(core.invoiceSubscriptionId({ subscription: 'sub_a' })).toBe('sub_a');
    expect(core.invoiceSubscriptionId({ parent: { subscription_details: { subscription: 'sub_b' } } })).toBe('sub_b');
    expect(core.invoiceSubscriptionId({ lines: { data: [{ parent: { subscription_item_details: { subscription: 'sub_c' } } }] } })).toBe('sub_c');
  });
});
