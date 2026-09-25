/**
 * payments/stripeReconcile.ts - drift repair through the webhook's code path,
 * payer-email flags (normalised), dry run, resumable cursor. No network.
 */

import * as admin from 'firebase-admin';
import { FakeFirestore, StripeState, emptyStripeState, makeFakeStripe } from '../utils/stripeFakes';
import * as core from '../../src/payments/stripeCore';
import * as rec from '../../src/payments/stripeReconcile';

const NOW = new Date(Date.UTC(2026, 8, 10, 12, 0, 0));
const DAY = 86400;
const T0 = Math.floor(Date.UTC(2026, 8, 1) / 1000);

let db: FakeFirestore;
let state: StripeState;
let stripe: any;
let notified: rec.ReconcileReport[];
const emails: Record<string, string> = { u1: 'jdoe@gmail.com', u2: 'other@example.com' };
const savedCore = { ...core.stripeCoreDeps };
const savedRec = { ...rec.stripeReconcileDeps };

function seedWorld() {
  db.seed('profiles', 'u1', { membershipTier: 'FREE', email: 'jdoe@gmail.com' });
  state.customers.cus_1 = { id: 'cus_1', email: 'jdoe@gmail.com', metadata: { firebaseUserId: 'u1' } };
  // Active, paid Silver subscription whose webhooks were never processed.
  state.subscriptions.sub_1 = {
    id: 'sub_1', customer: 'cus_1', status: 'active', livemode: true, latest_invoice: 'in_1',
    cancel_at_period_end: false, current_period_end: T0 + 30 * DAY, created: T0,
    metadata: { userId: 'u1', productId: '1_month_silver', tier: 'SILVER' },
  };
  state.invoices.in_1 = {
    id: 'in_1', customer: 'cus_1', subscription: 'sub_1', status: 'paid', amount_paid: 999, total: 999,
    currency: 'usd', created: T0, billing_reason: 'subscription_create', livemode: true, charge: 'ch_1',
    customer_email: 'jdoe@gmail.com',
    lines: { data: [{ type: 'subscription', subscription: 'sub_1', quantity: 1, amount: 999,
      period: { start: T0, end: T0 + 30 * DAY }, price: { unit_amount: 999, recurring: { interval: 'month' } } }] },
  };
  // Paid with the same person's gmail, written differently -> NOT a mismatch.
  state.charges.ch_1 = {
    id: 'ch_1', customer: 'cus_1', invoice: 'in_1', amount: 999, currency: 'usd', paid: true,
    status: 'succeeded', refunded: false, livemode: true, created: T0, payment_intent: 'pi_1',
    billing_details: { email: ' J.Doe+stripe@GoogleMail.com ' }, receipt_email: null,
  };
  // Coin purchase paid by someone else's email -> flagged.
  state.sessions.cs_2 = {
    id: 'cs_2', mode: 'payment', status: 'complete', payment_status: 'paid', client_reference_id: 'u1',
    metadata: { userId: 'u1', productId: 'greengo_coins_500', type: 'coins' }, customer: 'cus_1',
    currency: 'usd', amount_total: 399, livemode: true, payment_intent: 'pi_2', created: T0,
    line_items: { data: [{ amount_total: 399, quantity: 1 }] },
  };
  state.charges.ch_2 = {
    id: 'ch_2', customer: 'cus_1', invoice: null, amount: 399, currency: 'usd', paid: true,
    status: 'succeeded', refunded: false, livemode: true, created: T0 + 1, payment_intent: 'pi_2',
    billing_details: { email: 'someone.else@example.com' },
  };
}

beforeEach(() => {
  db = new FakeFirestore();
  state = emptyStripeState();
  stripe = makeFakeStripe(state);
  notified = [];
  core.stripeCoreDeps.db = () => db as any;
  core.stripeCoreDeps.stripe = () => stripe;
  core.stripeCoreDeps.now = () => NOW;
  core.stripeCoreDeps.getUserEmail = async (uid: string) => emails[uid] ?? null;
  core.stripeCoreDeps.downgradeTierNow = async () => null;
  rec.stripeReconcileDeps.notifyAdmins = async (r) => { notified.push(r); };
  seedWorld();
});

afterAll(() => {
  Object.assign(core.stripeCoreDeps, savedCore);
  Object.assign(rec.stripeReconcileDeps, savedRec);
});

describe('(d) reconciliation', () => {
  test('dry run reports the drift and the flags but writes nothing', async () => {
    const r = await rec.runStripeReconciliation({ dryRun: true, trigger: 'test' });
    expect(r.complete).toBe(true);
    expect(r.corrections.map((c) => [c.type, c.result])).toEqual(
      expect.arrayContaining([['missing_grant', 'would_grant'], ['missed_coin_grant', 'would_grant']]),
    );
    expect(r.flags.map((f) => f.id)).toContain('ch_2');
    expect(r.flags.map((f) => f.id)).not.toContain('ch_1');
    expect(r.flagsWouldCreate).toBeGreaterThan(0);
    expect(db.get('profiles', 'u1')?.membershipTier).toBe('FREE');
    expect(db.count('stripe_payment_flags')).toBe(0);
    expect(db.count('stripe_reconciliation_runs')).toBe(0);
    expect(db.count('coinBalances')).toBe(0);
    expect(notified).toHaveLength(0);
  });

  test('a real run fixes drift via the webhook path, flags, reports, notifies - and is idempotent', async () => {
    const r = await rec.runStripeReconciliation({ dryRun: false, trigger: 'test' });
    expect(r.complete).toBe(true);
    const p = db.get('profiles', 'u1')!;
    expect(p.membershipTier).toBe('SILVER');
    expect((p.membershipEndDate as admin.firestore.Timestamp).toMillis())
      .toBe((T0 + 30 * DAY) * 1000 + core.RENEWAL_GRACE_MS);
    expect(db.get('stripe_invoices', 'in_1')?.source).toBe('reconcile');
    expect(db.get('coinBalances', 'u1')?.totalCoins).toBe(500); // missed coin session
    expect(r.corrections.map((c) => c.type)).toEqual(expect.arrayContaining(['missing_grant', 'missed_coin_grant']));

    const flag = db.get('stripe_payment_flags', 'ch_2')!;
    expect(flag).toMatchObject({
      type: 'email_mismatch', uid: 'u1', accountEmail: 'jdoe@gmail.com', status: 'open',
      amount: 399, currency: 'usd', product: 'greengo_coins_500',
    });
    expect(flag.payerEmails).toEqual(['someone.else@example.com', 'jdoe@gmail.com']);
    expect(flag.mismatched).toEqual(['someone.else@example.com']);
    expect(db.get('stripe_payment_flags', 'ch_1')).toBeUndefined();

    expect(db.get('stripe_reconciliation_runs', r.runId)).toMatchObject({ flagsCreated: r.flagsCreated, complete: true });
    expect(notified).toHaveLength(1);

    const again = await rec.runStripeReconciliation({ dryRun: false, trigger: 'test' });
    expect(again.correctionsCount).toBe(0);
    expect(again.flagsCreated).toBe(0);
    expect(notified).toHaveLength(1);
    expect(db.get('coinBalances', 'u1')?.totalCoins).toBe(500);
  });

  test('a Stripe customer paying for several uids and unresolvable payments are flagged', async () => {
    db.seed('profiles', 'u2', { membershipTier: 'FREE', email: 'other@example.com' });
    state.subscriptions.sub_1.metadata.userId = 'u2'; // customer says u1
    state.customers.cus_9 = { id: 'cus_9', email: 'ghost@example.com', metadata: {} };
    state.charges.ch_9 = {
      id: 'ch_9', customer: 'cus_9', invoice: null, amount: 399, currency: 'usd', paid: true,
      status: 'succeeded', livemode: true, created: T0 + 2, payment_intent: 'pi_9', billing_details: {},
    };
    const r = await rec.runStripeReconciliation({ dryRun: false, trigger: 'test' });
    expect(db.get('stripe_payment_flags', 'customer_multiple_uids_cus_1')?.type).toBe('customer_multiple_uids');
    expect(db.get('stripe_payment_flags', 'unresolved_ch_9')?.type).toBe('unresolved_payment');
    expect(db.get('profiles', 'u1')?.membershipTier).toBe('FREE'); // nobody granted on a conflict
    expect(db.get('profiles', 'u2')?.membershipTier).toBe('FREE');
    expect(r.flagsCreated).toBeGreaterThanOrEqual(2);
  });

  test('out of time -> cursor persisted; the next run resumes and completes', async () => {
    const first = await rec.runStripeReconciliation({ dryRun: false, trigger: 'test', budgetMs: -1 });
    expect(first.complete).toBe(false);
    expect(first.nextCursor).toEqual({ phase: 'subscriptions', startingAfter: null });
    expect(db.get('stripe_reconcile_state', 'cursor')?.phase).toBe('subscriptions');
    const second = await rec.runStripeReconciliation({ dryRun: false, trigger: 'test' });
    expect(second.resumedFrom).toEqual({ phase: 'subscriptions', startingAfter: null });
    expect(second.complete).toBe(true);
    expect(db.get('stripe_reconcile_state', 'cursor')?.phase).toBeNull();
  });

  test('never throws: a failing Stripe list is reported as an error', async () => {
    stripe.subscriptions.list = async () => { throw new Error('boom'); };
    const r = await rec.runStripeReconciliation({ dryRun: false, trigger: 'test' });
    expect(r.errors.join(' ')).toContain('boom');
    expect(r.complete).toBe(true);
    expect(notified).toHaveLength(1);
  });

  test('over-entitlement is flagged, never auto-shortened', () => {
    const sub = { ...state.subscriptions.sub_1, latest_invoice: { ...state.invoices.in_1, charge: state.charges.ch_1 } };
    const exp = rec.expectedEntitlement(sub, NOW);
    expect(exp.shouldBeActive).toBe(true);
    const profile = {
      membershipTier: 'SILVER', membershipSource: 'stripe', stripeSubscriptionId: 'sub_1',
      stripeSubscriptionStatus: 'active',
      membershipEndDate: admin.firestore.Timestamp.fromMillis((T0 + 90 * DAY) * 1000),
    };
    expect(rec.entitlementDrift(profile, sub, exp, NOW).map((d) => d.type)).toEqual(['over_entitlement']);
  });

  test('a refunded latest invoice is not an entitlement to restore', () => {
    const sub = { ...state.subscriptions.sub_1, latest_invoice: { ...state.invoices.in_1, charge: { ...state.charges.ch_1, refunded: true } } };
    const exp = rec.expectedEntitlement(sub, NOW);
    expect(exp.shouldBeActive).toBe(false);
    expect(rec.entitlementDrift({ membershipTier: 'FREE' }, sub, exp, NOW)).toEqual([]);
  });
});

describe('email normalisation', () => {
  test.each([
    ['John.Doe@Gmail.com', 'johndoe@gmail.com'],
    ['  j.o.h.n.doe+shop@googlemail.com ', 'johndoe@gmail.com'],
    ['Jane+tag@Example.com', 'jane@example.com'],
    ['jane.doe@example.com', 'jane.doe@example.com'],
    ['', null],
    [null, null],
  ])('%p -> %p', (input, out) => {
    expect(core.normalizeEmail(input)).toBe(out);
  });

  test('mismatch compares normalised payer emails with every account email', () => {
    expect(core.mismatchedPayerEmails(['jdoe@gmail.com'], ['J.DOE@gmail.com', 'jdoe+x@googlemail.com'])).toEqual([]);
    expect(core.mismatchedPayerEmails(['jdoe@gmail.com', null], ['jane.doe@example.com'])).toEqual(['jane.doe@example.com']);
    expect(core.mismatchedPayerEmails([null], [])).toEqual([]);
    // dots are only insignificant on gmail
    expect(core.mismatchedPayerEmails(['jane.doe@example.com'], ['janedoe@example.com'])).toEqual(['janedoe@example.com']);
  });
});
