/**
 * auth/deletionFollowups.ts - account deletion cancels the user's web
 * (Stripe) subscriptions: idempotent, retried with backoff, admin alert after
 * MAX_ATTEMPTS. No network (fake Stripe + FakeFirestore).
 */

import * as admin from 'firebase-admin';
import { FakeFirestore } from '../utils/stripeFakes';
import * as f from '../../src/auth/deletionFollowups';

const NOW = new Date(Date.UTC(2026, 9, 16, 12, 0, 0));

interface FakeStripe extends f.StripeLike {
  cancelCalls: string[];
  failCancel: boolean;
}

function fakeStripe(subs: any[]): FakeStripe {
  const s: FakeStripe = {
    cancelCalls: [],
    failCancel: false,
    subscriptions: {
      list: async (p: any) => ({ data: subs.filter((x) => x.customer === p.customer), has_more: false }),
      search: async (p: any) => {
        const m = /metadata\['userId'\]:'([^']+)'/.exec(p.query);
        return { data: subs.filter((x) => x.metadata?.userId === m?.[1]) };
      },
      cancel: async (id: string) => {
        if (s.failCancel) throw new Error('stripe down');
        const sub = subs.find((x) => x.id === id);
        if (!sub || sub.status === 'canceled') {
          const e: any = new Error('No such subscription');
          e.code = 'resource_missing';
          throw e;
        }
        s.cancelCalls.push(id);
        sub.status = 'canceled';
        return sub;
      },
    },
  };
  return s;
}

let db: FakeFirestore;
let live: FakeStripe;
let now: Date;
let deps: f.FollowupDeps;

beforeEach(() => {
  db = new FakeFirestore();
  now = NOW;
  live = fakeStripe([
    { id: 'sub_active', customer: 'cus_1', status: 'active', metadata: { userId: 'u1' } },
    { id: 'sub_trial', customer: 'cus_1', status: 'trialing', metadata: { userId: 'u1' } },
    { id: 'sub_old', customer: 'cus_1', status: 'canceled', metadata: { userId: 'u1' } },
    // Unmapped customer, found through metadata search.
    { id: 'sub_orphan', customer: 'cus_9', status: 'past_due', metadata: { userId: 'u1' } },
    { id: 'sub_other', customer: 'cus_2', status: 'active', metadata: { userId: 'u2' } },
  ]);
  deps = { stripe: (test) => (test ? null : live), now: () => now, db: () => db as any };
});

describe('pure helpers', () => {
  test('pickCancellable keeps live statuses and dedupes', () => {
    const r = f.pickCancellable([
      { id: 'a', status: 'active' }, { id: 'a', status: 'active' }, { id: 'b', status: 'canceled' },
      { id: 'c', status: 'incomplete_expired' }, { id: 'd', status: 'past_due' }, null,
    ]);
    expect(r.map((x) => x.id)).toEqual(['a', 'd']);
  });

  test('retryDelayMs grows and is capped at 12h', () => {
    expect(f.retryDelayMs(1)).toBe(5 * 60 * 1000);
    expect(f.retryDelayMs(2)).toBe(15 * 60 * 1000);
    expect(f.retryDelayMs(20)).toBe(12 * 3600 * 1000);
  });

  test('isDue', () => {
    const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
    expect(f.isDue({}, NOW)).toBe(true);
    expect(f.isDue({ stripeStatus: 'pending' }, NOW)).toBe(true);
    expect(f.isDue({ stripeStatus: 'done' }, NOW)).toBe(false);
    expect(f.isDue({ stripeStatus: 'failed' }, NOW)).toBe(false);
    expect(f.isDue({ stripeStatus: 'retry', stripeNextAttemptAt: ts(NOW.getTime() + 1) }, NOW)).toBe(false);
    expect(f.isDue({ stripeStatus: 'retry', stripeNextAttemptAt: ts(NOW.getTime() - 1) }, NOW)).toBe(true);
    expect(f.isDue({ stripeStatus: 'processing', stripeLeaseUntil: ts(NOW.getTime() + 1000) }, NOW)).toBe(false);
    expect(f.isDue({ stripeStatus: 'processing', stripeLeaseUntil: ts(NOW.getTime() - 1000) }, NOW)).toBe(true);
    expect(f.isDue(undefined, NOW)).toBe(false);
  });
});

describe('processStripeFollowup', () => {
  test('cancels every live subscription of the user (mapped + metadata), nothing else', async () => {
    db.seed('deletion_followups', 'u1', { stripeCustomerId: 'cus_1', stripe: true, stripeStatus: 'pending' });
    expect(await f.processStripeFollowup('u1', deps)).toBe('done');
    expect(live.cancelCalls.sort()).toEqual(['sub_active', 'sub_orphan', 'sub_trial']);
    const d = db.get('deletion_followups', 'u1')!;
    expect(d.stripeStatus).toBe('done');
    expect(d.stripeAttempts).toBe(1);
    expect(d.stripeCancelled.sort()).toEqual(['sub_active', 'sub_orphan', 'sub_trial']);
  });

  test('idempotent: re-running after a reset cancels nothing new', async () => {
    db.seed('deletion_followups', 'u1', { stripeCustomerId: 'cus_1', stripeStatus: 'pending' });
    await f.processStripeFollowup('u1', deps);
    expect(await f.processStripeFollowup('u1', deps)).toBe('skipped'); // done -> not due
    db.write('deletion_followups', 'u1', { stripeStatus: 'pending' }, true); // second deletion run
    expect(await f.processStripeFollowup('u1', deps)).toBe('done');
    expect(live.cancelCalls).toHaveLength(3);
  });

  test('a failure is retried with backoff, then alerts the admins', async () => {
    db.seed('deletion_followups', 'u1', { stripeCustomerId: 'cus_1', stripeStatus: 'pending' });
    live.failCancel = true;
    expect(await f.processStripeFollowup('u1', deps)).toBe('retry');
    let d = db.get('deletion_followups', 'u1')!;
    expect(d.stripeAttempts).toBe(1);
    expect(d.stripeNextAttemptAt.toMillis()).toBe(NOW.getTime() + f.retryDelayMs(1));
    // Not due yet: the scheduler skips it.
    expect(await f.retryDueFollowups(deps)).toBe(0);

    for (let i = 2; i <= f.MAX_ATTEMPTS; i++) {
      now = new Date(now.getTime() + 13 * 3600 * 1000);
      expect(await f.retryDueFollowups(deps)).toBe(1);
    }
    d = db.get('deletion_followups', 'u1')!;
    expect(d.stripeStatus).toBe('failed');
    expect(d.stripeAttempts).toBe(f.MAX_ATTEMPTS);
    const alert = db.get('admin_alerts', 'deletion_followup_stripe_u1')!;
    expect(alert.type).toBe('deletion_followup_failed');
    expect(alert.stripeCustomerId).toBe('cus_1');
    // Failed docs are not retried automatically any more.
    now = new Date(now.getTime() + 13 * 3600 * 1000);
    expect(await f.retryDueFollowups(deps)).toBe(0);
  });

  test('recovers after a transient failure', async () => {
    db.seed('deletion_followups', 'u1', { stripeCustomerId: 'cus_1', stripeStatus: 'pending' });
    live.failCancel = true;
    await f.processStripeFollowup('u1', deps);
    live.failCancel = false;
    now = new Date(now.getTime() + 60 * 60 * 1000);
    expect(await f.retryDueFollowups(deps)).toBe(1);
    expect(db.get('deletion_followups', 'u1')!.stripeStatus).toBe('done');
    expect(db.count('admin_alerts')).toBe(0);
  });

  test('a live customer without a configured key is retried, a test customer is skipped', async () => {
    db.seed('deletion_followups', 'u1', { stripeCustomerId: 'cus_1', stripeStatus: 'pending' });
    const noKey: f.FollowupDeps = { ...deps, stripe: () => null };
    expect(await f.processStripeFollowup('u1', noKey)).toBe('retry');

    db.seed('deletion_followups', 'u3', { stripeTestCustomerId: 'cus_t', stripeStatus: 'pending' });
    expect(await f.processStripeFollowup('u3', deps)).toBe('done');
    expect(db.get('deletion_followups', 'u3')!.stripeSkipped).toEqual(['test:no_key']);
  });

  test('a held lease blocks a concurrent run', async () => {
    db.seed('deletion_followups', 'u1', {
      stripeCustomerId: 'cus_1',
      stripeStatus: 'processing',
      stripeLeaseUntil: admin.firestore.Timestamp.fromMillis(NOW.getTime() + 60_000),
    });
    expect(await f.processStripeFollowup('u1', deps)).toBe('skipped');
    expect(live.cancelCalls).toHaveLength(0);
  });
});
