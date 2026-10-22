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
  deletedCustomers: string[];
  customerRecords: Record<string, any>;
}

function fakeStripe(subs: any[]): FakeStripe {
  const s: FakeStripe = {
    cancelCalls: [],
    failCancel: false,
    deletedCustomers: [],
    customerRecords: {
      cus_1: { id: 'cus_1', metadata: { userId: 'u1' } },
      cus_9: { id: 'cus_9', metadata: { userId: 'u1' } },
      cus_8: { id: 'cus_8', metadata: { userId: 'u1' } }, // no subscription at all
      cus_2: { id: 'cus_2', metadata: { userId: 'u2' } },
    },
    customers: {
      del: async (id: string) => {
        if (!s.customerRecords[id] || s.customerRecords[id].deleted) {
          const e: any = new Error(`No such customer: '${id}'`);
          e.code = 'resource_missing';
          throw e;
        }
        s.customerRecords[id].deleted = true;
        s.deletedCustomers.push(id);
        return { id, deleted: true };
      },
      search: async (p: any) => {
        const m = /metadata\['userId'\]:'([^']+)'/.exec(p.query);
        return { data: Object.values(s.customerRecords).filter((c: any) => !c.deleted && c.metadata?.userId === m?.[1]) };
      },
    },
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
    // Privacy policy 15.2 f: the customer records are deleted too (mapped,
    // the orphan subscription's customer, and one found by metadata only).
    expect(live.deletedCustomers.sort()).toEqual(['cus_1', 'cus_8', 'cus_9']);
    expect(d.stripeCustomersDeleted.sort()).toEqual(['cus_1', 'cus_8', 'cus_9']);
    expect(live.customerRecords.cus_2.deleted).toBeUndefined();
  });

  test('an already-deleted customer counts as done', async () => {
    live.customerRecords.cus_1.deleted = true;
    db.seed('deletion_followups', 'u1', { stripeCustomerId: 'cus_1', stripeStatus: 'pending' });
    expect(await f.processStripeFollowup('u1', deps)).toBe('done');
    expect(db.get('deletion_followups', 'u1')!.stripeCustomersAlreadyDeleted).toEqual(['cus_1']);
  });

  test('a customer delete failure is retried (subscriptions stay cancelled)', async () => {
    const del = live.customers!.del;
    live.customers!.del = async () => { throw new Error('stripe down'); };
    db.seed('deletion_followups', 'u1', { stripeCustomerId: 'cus_1', stripeStatus: 'pending' });
    expect(await f.processStripeFollowup('u1', deps)).toBe('retry');
    live.customers!.del = del;
    now = new Date(now.getTime() + 60 * 60 * 1000);
    expect(await f.retryDueFollowups(deps)).toBe(1);
    expect(db.get('deletion_followups', 'u1')!.stripeStatus).toBe('done');
    expect(live.deletedCustomers).toContain('cus_1');
  });

  test('idempotent: re-running after a reset cancels nothing new', async () => {
    db.seed('deletion_followups', 'u1', { stripeCustomerId: 'cus_1', stripeStatus: 'pending' });
    await f.processStripeFollowup('u1', deps);
    expect(await f.processStripeFollowup('u1', deps)).toBe('skipped'); // done -> not due
    db.write('deletion_followups', 'u1', { stripeStatus: 'pending' }, true); // second deletion run
    expect(await f.processStripeFollowup('u1', deps)).toBe('done');
    expect(live.cancelCalls).toHaveLength(3);
    expect(live.deletedCustomers.sort()).toEqual(['cus_1', 'cus_8', 'cus_9']); // never twice
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

  test('a held lease blocks a concurrent run (customers untouched)', async () => {
    db.seed('deletion_followups', 'u1', {
      stripeCustomerId: 'cus_1',
      stripeStatus: 'processing',
      stripeLeaseUntil: admin.firestore.Timestamp.fromMillis(NOW.getTime() + 60_000),
    });
    expect(await f.processStripeFollowup('u1', deps)).toBe('skipped');
    expect(live.cancelCalls).toHaveLength(0);
  });
});

describe('processAnalyticsFollowup', () => {
  let bqCalls: Array<{ query: string; params?: Record<string, unknown> }>;
  let bqFail: (q: string) => Error | null;
  let ga4: string[];
  let adeps: f.FollowupDeps;
  beforeEach(() => {
    bqCalls = [];
    bqFail = () => null;
    ga4 = [];
    adeps = {
      ...deps,
      bigquery: () => ({
        query: async (o: any) => { const e = bqFail(o.query); if (e) throw e; bqCalls.push(o); return [[]]; },
      }),
      ga4DeleteAppInstance: async (id: string) => { ga4.push(id); },
    };
    for (const [col, field] of f.ANALYTICS_BY_FIELD) {
      db.seed(col, `${col}_mine`, { [field]: 'u1', x: 1 });
      db.seed(col, `${col}_other`, { [field]: 'u2', x: 1 });
    }
    db.seed('user_stats', 'u1', { a: 1 });
    db.seed('user_stats', 'u2', { a: 1 });
  });

  test('deletes per-user analytics docs, BigQuery rows (financial ones pseudonymised), files GA4 deletion', async () => {
    db.seed('deletion_followups', 'u1', { analytics: true, analyticsStatus: 'pending', ga4AppInstanceIds: ['abcdef0123456789'] });
    expect(await f.processAnalyticsFollowup('u1', adeps)).toBe('done');
    for (const [col] of f.ANALYTICS_BY_FIELD) {
      expect(db.get(col, `${col}_mine`)).toBeUndefined();
      expect(db.get(col, `${col}_other`)).toBeDefined();
    }
    expect(db.get('user_stats', 'u1')).toBeUndefined();
    expect(db.get('user_stats', 'u2')).toBeDefined();
    const del = bqCalls.filter((c) => c.query.startsWith('DELETE'));
    const upd = bqCalls.filter((c) => c.query.startsWith('UPDATE'));
    expect(del.map((c) => c.query)).toEqual(f.BQ_DELETE_TABLES.map((t) => 'DELETE FROM `greengo_analytics.' + t + '` WHERE user_id = @uid'));
    expect(del.every((c) => c.params?.uid === 'u1')).toBe(true);
    expect(upd).toHaveLength(f.BQ_PSEUDONYMISE_TABLES.length);
    expect(upd.every((c) => c.params?.uid === 'u1' && typeof c.params?.pseudonym === 'string' && c.params.pseudonym !== 'u1')).toBe(true);
    expect(ga4).toEqual(['abcdef0123456789']);
    const d = db.get('deletion_followups', 'u1')!;
    expect(d.analyticsStatus).toBe('done');
    expect(d.ga4AppInstanceIds).toBeUndefined();
    expect(d.crashlytics).toBe('not_linked');
  });

  test('rows in the BigQuery streaming buffer -> retried later; a missing table is skipped', async () => {
    db.seed('deletion_followups', 'u1', { analyticsStatus: 'pending' });
    bqFail = (q) => (q.includes('user_events') ? new Error('UPDATE or DELETE statement over table would affect rows in the streaming buffer')
      : (q.includes('tax_records') ? new Error('Not found: Table greengo:greengo_analytics.tax_records') : null));
    expect(await f.processAnalyticsFollowup('u1', adeps)).toBe('retry');
    expect(db.get('deletion_followups', 'u1')!.analyticsLastError).toBe('bigquery_streaming_buffer');
    bqFail = (q) => (q.includes('tax_records') ? new Error('Not found: Table x') : null);
    now = new Date(now.getTime() + 60 * 60 * 1000);
    expect(await f.retryDueFollowups(adeps)).toBe(1);
    const d = db.get('deletion_followups', 'u1')!;
    expect(d.analyticsStatus).toBe('done');
    expect(d.analyticsBigQuery.tax_records).toBe('no_table');
    expect(d.analyticsBigQuery.user_events).toBe('done');
    expect(d.analyticsGa4).toEqual({ _: 'no_app_instance_id' });
  });

  test('GA4 not enabled is recorded, not silently passed', async () => {
    db.seed('deletion_followups', 'u1', { analyticsStatus: 'pending', ga4AppInstanceIds: ['abcdef0123456789'] });
    expect(await f.processAnalyticsFollowup('u1', { ...adeps, ga4DeleteAppInstance: null })).toBe('done');
    expect(db.get('deletion_followups', 'u1')!.analyticsGa4).toEqual({ _: 'not_enabled' });
  });

  test('GA4 deletion goes to the Admin API submitUserDeletion (v3 upsert is retired)', () => {
    expect(f.ga4DeletionRequest('521563225', 'abcdef0123456789')).toEqual({
      url: 'https://analyticsadmin.googleapis.com/v1alpha/properties/521563225:submitUserDeletion',
      method: 'POST',
      data: { appInstanceId: 'abcdef0123456789' },
    });
  });

  test('old follow-up docs (no analyticsStatus) only run the Stripe task', () => {
    expect(f.isTaskDue({ stripeStatus: 'done' }, 'analytics', NOW)).toBe(false);
    expect(f.isTaskDue({}, 'stripe', NOW)).toBe(true);
    expect(f.isTaskDue({ analyticsStatus: 'pending' }, 'analytics', NOW)).toBe(true);
  });
});
