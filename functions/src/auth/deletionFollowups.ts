/**
 * Account deletion follow-up (audit P2-7, Terms 7.3, privacy policy 15.2 f:
 * "We also ask our providers to delete your data: Stripe deletes your
 * customer record; your analytics and crash data are deleted").
 *
 * deleteAccountData (./accountDeletion.ts) writes `deletion_followups/{uid}`
 * with the user's Stripe customer id(s) BEFORE stripe_customers / profiles are
 * deleted. Two independent tasks, each with its own status / lease / retries:
 *
 *  stripe (stripeStatus ...):
 *   1. cancels every live subscription of those customers IMMEDIATELY (no
 *      further renewals, no proration refund: Terms 7.3), then
 *   2. DELETES the Stripe customer object(s) (customers.del; 2026-10-21, to
 *      match privacy policy 15.2 f). Stripe itself keeps the invoices /
 *      charges / refunds of a deleted customer (they stay in the dashboard
 *      and API for its own legal duties), so the bookkeeping records the tax
 *      law requires are not lost; our own copy is the pseudonymised
 *      retention_finance rows. A refund / dispute of an old charge still works
 *      on the charge / payment intent (it does not need the customer).
 *   Store subscriptions (Apple / Google) cannot be cancelled by us; the
 *   deletion dialog tells the user to cancel them in the store.
 *
 *  analytics (analyticsStatus ...):
 *   1. Firestore per-user analytics docs (ANALYTICS_BY_FIELD / ANALYTICS_BY_ID)
 *   2. BigQuery dataset `greengo_analytics` (analytics/bigQuerySetup.ts):
 *      DELETE the user's rows from the behavioural tables; the financial
 *      analytics tables keep their rows with user_id replaced by the same
 *      pseudonym as retention_finance (privacy policy 15.2 e). A row still in
 *      the streaming buffer cannot be changed by DML yet -> retried later
 *      (backoff up to 12 h; the buffer flushes within ~90 min).
 *   3. GA4 (Google Analytics for Firebase): the app does not set a GA4 user
 *      id, so the only handle is the device's app instance id, which the app
 *      sends with deleteMyAccount. With GA4_USER_DELETION=on the worker files
 *      a User Deletion API request per app instance id. Crashlytics has no
 *      per-user deletion API and the app sets no Crashlytics user id (reports
 *      expire after 90 days): recorded as `crashlytics: 'not_linked'`.
 *
 *  tickets (ticketsStatus ...; privacy policy 15.2 e, 2026-10-21):
 *   the BUYER's ticket orders / tickets / refunds keep their amounts, dates
 *   and ids, but the buyer's account id becomes the retention pseudonym and
 *   names / e-mail / holder names / QR codes are removed; per-buyer counters
 *   and holder-name docs are deleted (./deletionBuyerRecords.ts). Bounded:
 *   when work is left the task goes back to 'pending' without counting an
 *   attempt (the write re-fires the trigger).
 *
 * Idempotent and retried:
 *   - processDeletionFollowup (Firestore trigger) runs each due task.
 *   - retryDeletionFollowups (every 30 min) picks up docs in 'retry' /
 *     'pending' / stale 'processing' (single-field equality query, bounded).
 *   - A transactional lease per task keeps the trigger and the scheduler from
 *     running the same task twice; cancelling an already-cancelled
 *     subscription / deleting a deleted customer counts as success.
 *   - After MAX_ATTEMPTS the task goes to 'failed' and an admin_alerts row
 *     (type 'deletion_followup_failed', ids only) is written for a human.
 */

import * as admin from 'firebase-admin';
import Stripe from 'stripe';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { defineSecret } from 'firebase-functions/params';
import '../shared/firebaseAdmin';
import { DELETION_FOLLOWUPS, retentionUidHash } from './accountDeletion';
import { STRIPE_API_VERSION } from '../payments/stripeCore';
import { BuyerRecordsDeps, buyerRecordsDepsFromEnv, pseudonymiseBuyerRecords } from './deletionBuyerRecords';

export const MAX_ATTEMPTS = 8;
export const LEASE_MS = 5 * 60 * 1000;
export const RETRY_BATCH = 50;
/** Time after which the retry scheduler stops starting new tasks. */
export const SCHEDULER_BUDGET_MS = 300 * 1000;
/** Statuses that can still bill or be resumed; everything else is final. */
export const CANCELLABLE_STATUSES: readonly string[] = [
  'active', 'trialing', 'past_due', 'unpaid', 'incomplete', 'paused',
];

export type StripeFollowupStatus =
  | 'pending' | 'processing' | 'retry' | 'done' | 'failed';
export type FollowupTask = 'stripe' | 'analytics' | 'tickets';
export const TASKS: readonly FollowupTask[] = ['stripe', 'analytics', 'tickets'];

/** A task's work result: fields to store; `more` = bounds hit, run again. */
export const MORE = '__more';

export interface StripeLike {
  subscriptions: {
    list(params: Record<string, any>): Promise<{ data: any[]; has_more?: boolean }>;
    cancel(id: string, params?: Record<string, any>): Promise<any>;
    search?(params: Record<string, any>): Promise<{ data: any[] }>;
  };
  customers?: {
    del(id: string): Promise<any>;
    search?(params: Record<string, any>): Promise<{ data: any[] }>;
  };
}

/** BigQuery (DML jobs only). */
export interface BigQueryLike {
  query(opts: { query: string; params?: Record<string, unknown> }): Promise<unknown>;
}

export interface FollowupDeps {
  /** null when the key for that mode is not configured. */
  stripe(testMode: boolean): StripeLike | null;
  now(): Date;
  db(): FirebaseFirestore.Firestore;
  /** null = BigQuery not available in this environment. */
  bigquery?(): BigQueryLike | null;
  /** GA4 User Deletion API for one app instance id; null when not enabled. */
  ga4DeleteAppInstance?: ((appInstanceId: string) => Promise<void>) | null;
  /** Buyer-side ticket records (task 'tickets'); defaults to the production deps on db()/now(). */
  buyerRecords?(): BuyerRecordsDeps;
}

export interface CancelResult {
  cancelled: string[];
  alreadyEnded: string[];
  skipped: string[]; // e.g. 'test:no_key'
  customersDeleted: string[];
  customersAlreadyDeleted: string[];
}

/** Backoff: 5 min, 15 min, 45 min, ... capped at 12 h. */
export function retryDelayMs(attempts: number): number {
  const base = 5 * 60 * 1000;
  const d = base * Math.pow(3, Math.max(0, attempts - 1));
  return Math.min(d, 12 * 3600 * 1000);
}

/** The subscriptions (deduplicated by id) that must be cancelled. */
export function pickCancellable(subs: any[]): any[] {
  const seen = new Set<string>();
  const out: any[] = [];
  for (const s of subs) {
    if (!s || typeof s.id !== 'string' || seen.has(s.id)) continue;
    seen.add(s.id);
    if (CANCELLABLE_STATUSES.includes(String(s.status))) out.push(s);
  }
  return out;
}

const ms = (v: any): number => (v && typeof v.toMillis === 'function' ? v.toMillis() : 0);

/** True when [task] of the doc should be (re)processed now. */
export function isTaskDue(d: Record<string, any> | undefined, task: FollowupTask, now: Date): boolean {
  if (!d) return false;
  const st = d[`${task}Status`] as StripeFollowupStatus | undefined;
  // Docs written before the analytics task existed have no analyticsStatus:
  // only the Stripe task is implied by an absent status.
  if (st === undefined) return task === 'stripe';
  if (st === 'pending') return true;
  if (st === 'retry') return ms(d[`${task}NextAttemptAt`]) <= now.getTime();
  if (st === 'processing') return ms(d[`${task}LeaseUntil`]) <= now.getTime(); // stale lease
  return false;
}

/** True when the Stripe task should be (re)processed now. */
export function isDue(d: Record<string, any> | undefined, now: Date): boolean {
  return isTaskDue(d, 'stripe', now);
}

function isAlreadyEndedError(e: any): boolean {
  const code = String(e?.code || e?.raw?.code || '');
  const msg = String(e?.message || '');
  return code === 'resource_missing' || /canceled subscription|No such subscription/i.test(msg);
}

function isCustomerGoneError(e: any): boolean {
  const code = String(e?.code || e?.raw?.code || '');
  return code === 'resource_missing' || /No such customer|has been deleted/i.test(String(e?.message || ''));
}

async function listAll(stripe: StripeLike, customer: string): Promise<any[]> {
  const out: any[] = [];
  let starting_after: string | undefined;
  // A customer has a handful of subscriptions; 5 pages is a hard bound.
  for (let page = 0; page < 5; page++) {
    const r = await stripe.subscriptions.list({
      customer, status: 'all', limit: 100, ...(starting_after ? { starting_after } : {}),
    });
    out.push(...r.data);
    if (!r.has_more || r.data.length === 0) break;
    starting_after = r.data[r.data.length - 1].id;
  }
  return out;
}

/**
 * Cancels every live subscription of the user's customers in one mode, plus
 * any subscription whose server-written metadata.userId is the uid (covers a
 * customer that was never mapped), then DELETES the customer objects (the
 * mapped ones, the customers of those subscriptions, and any customer whose
 * metadata.userId is the uid). Throws on a real Stripe failure so the caller
 * schedules a retry; partial progress is safe to repeat.
 */
export async function cancelStripeSubscriptions(
  uid: string,
  d: Record<string, any>,
  deps: FollowupDeps,
): Promise<CancelResult> {
  const result: CancelResult = { cancelled: [], alreadyEnded: [], skipped: [], customersDeleted: [], customersAlreadyDeleted: [] };
  const modes: Array<{ test: boolean; customer: string | null }> = [
    { test: false, customer: typeof d.stripeCustomerId === 'string' ? d.stripeCustomerId : null },
    { test: true, customer: typeof d.stripeTestCustomerId === 'string' ? d.stripeTestCustomerId : null },
  ];
  const searchable = /^[A-Za-z0-9_-]+$/.test(uid);
  for (const m of modes) {
    // Live mode is always checked (metadata search); test mode only when a
    // test customer is known.
    if (m.test && !m.customer) continue;
    const stripe = deps.stripe(m.test);
    if (!stripe) {
      if (m.customer) {
        if (m.test) {
          result.skipped.push('test:no_key');
          continue;
        }
        throw new Error('stripe_not_configured');
      }
      result.skipped.push('live:no_key');
      continue;
    }
    const subs: any[] = [];
    if (m.customer) subs.push(...(await listAll(stripe, m.customer)));
    if (!m.test && stripe.subscriptions.search && searchable) {
      try {
        const r = await stripe.subscriptions.search({ query: `metadata['userId']:'${uid}'`, limit: 100 });
        subs.push(...r.data);
      } catch (e: any) {
        // Search is best-effort (not available in every account/region).
        console.warn(`[deletionFollowups] subscription search failed for ${uid}`, e?.message || e);
      }
    }
    for (const s of pickCancellable(subs)) {
      try {
        await stripe.subscriptions.cancel(s.id, { prorate: false, invoice_now: false });
        result.cancelled.push(s.id);
      } catch (e: any) {
        if (isAlreadyEndedError(e)) result.alreadyEnded.push(s.id);
        else throw e;
      }
    }

    // Privacy policy 15.2 f: "Stripe deletes your customer record".
    if (!stripe.customers) {
      result.skipped.push(`${m.test ? 'test' : 'live'}:customers_api_missing`);
      continue;
    }
    const customers = new Set<string>();
    if (m.customer) customers.add(m.customer);
    for (const s of subs) if (typeof s?.customer === 'string' && s.metadata?.userId === uid) customers.add(s.customer);
    if (!m.test && stripe.customers.search && searchable) {
      try {
        const r = await stripe.customers.search({ query: `metadata['userId']:'${uid}'`, limit: 100 });
        for (const c of r.data) if (typeof c?.id === 'string') customers.add(c.id);
      } catch (e: any) {
        console.warn(`[deletionFollowups] customer search failed for ${uid}`, e?.message || e);
      }
    }
    for (const id of customers) {
      try {
        await stripe.customers.del(id);
        result.customersDeleted.push(id);
      } catch (e: any) {
        if (isCustomerGoneError(e)) result.customersAlreadyDeleted.push(id);
        else throw e;
      }
    }
  }
  return result;
}

// ---------------------------------------------------------------------------
// Analytics
// ---------------------------------------------------------------------------

/** Per-user analytics docs found by a uid field (Firestore). */
export const ANALYTICS_BY_FIELD: ReadonlyArray<[string, string]> = [
  ['analytics_events', 'userId'],
  ['ab_assignments', 'userId'],
  ['ab_test_assignments', 'userId'],
  ['user_sessions', 'userId'],
  ['user_activity', 'userId'],
  ['retention_alerts', 'userId'],
];
/** Per-user analytics docs keyed by the uid (some also in ACCOUNT_DATA_INVENTORY: repeating is harmless). */
export const ANALYTICS_BY_ID: readonly string[] = ['user_stats', 'churn_predictions', 'user_segments', 'user_cohorts'];

export const BQ_DATASET = 'greengo_analytics';
/** Behavioural analytics: the user's rows are deleted. */
export const BQ_DELETE_TABLES: readonly string[] = ['user_events', 'ab_test_results', 'user_cohorts', 'subscription_events'];
/** Financial analytics (privacy policy 15.2 e): rows kept, user_id pseudonymised. */
export const BQ_PSEUDONYMISE_TABLES: readonly string[] = ['revenue_events', 'refund_events', 'tax_records'];

export interface AnalyticsResult {
  firestoreDeleted: number;
  bigQuery: Record<string, string>;
  ga4: Record<string, string>;
  crashlytics: string;
}

/** The DML statements for one user (exported for tests). */
export function bigQueryStatements(uid: string): Array<{ table: string; query: string; params: Record<string, unknown> }> {
  const out: Array<{ table: string; query: string; params: Record<string, unknown> }> = [];
  for (const t of BQ_DELETE_TABLES) {
    out.push({ table: t, query: `DELETE FROM \`${BQ_DATASET}.${t}\` WHERE user_id = @uid`, params: { uid } });
  }
  const pseudonym = retentionUidHash(uid);
  for (const t of BQ_PSEUDONYMISE_TABLES) {
    out.push({
      table: t,
      query: `UPDATE \`${BQ_DATASET}.${t}\` SET user_id = @pseudonym WHERE user_id = @uid`,
      params: { uid, pseudonym },
    });
  }
  return out;
}

export async function deleteAnalyticsData(uid: string, d: Record<string, any>, deps: FollowupDeps): Promise<AnalyticsResult> {
  const db = deps.db();
  const res: AnalyticsResult = { firestoreDeleted: 0, bigQuery: {}, ga4: {}, crashlytics: 'not_linked' };

  for (const [col, field] of ANALYTICS_BY_FIELD) {
    for (let guard = 0; guard < 100; guard++) {
      const snap = await db.collection(col).where(field, '==', uid).limit(300).get();
      if (snap.empty) break;
      const batch = db.batch();
      for (const doc of snap.docs) batch.delete(doc.ref);
      await batch.commit();
      res.firestoreDeleted += snap.size;
      if (snap.size < 300) break;
    }
  }
  for (const col of ANALYTICS_BY_ID) {
    const ref = db.collection(col).doc(uid);
    if ((await ref.get()).exists) {
      await ref.delete();
      res.firestoreDeleted++;
    }
  }

  const bq = deps.bigquery ? deps.bigquery() : null;
  if (!bq) {
    res.bigQuery._ = 'not_available';
  } else {
    let retry = false;
    for (const st of bigQueryStatements(uid)) {
      try {
        await bq.query({ query: st.query, params: st.params });
        res.bigQuery[st.table] = 'done';
      } catch (e: any) {
        const msg = String(e?.message || e);
        if (/Not found: (Table|Dataset)/i.test(msg)) res.bigQuery[st.table] = 'no_table';
        else if (/streaming buffer/i.test(msg)) { res.bigQuery[st.table] = 'streaming_buffer'; retry = true; }
        else throw e;
      }
    }
    // Rows still in the streaming buffer: the whole task is retried later
    // (every statement is idempotent).
    if (retry) throw new Error('bigquery_streaming_buffer');
  }

  const ids: string[] = Array.isArray(d.ga4AppInstanceIds)
    ? d.ga4AppInstanceIds.filter((x: unknown) => typeof x === 'string' && /^[A-Za-z0-9_-]{8,128}$/.test(x)).slice(0, 10)
    : [];
  if (!ids.length) res.ga4._ = 'no_app_instance_id';
  else if (!deps.ga4DeleteAppInstance) res.ga4._ = 'not_enabled';
  else {
    for (const id of ids) {
      await deps.ga4DeleteAppInstance(id);
      res.ga4[id] = 'requested';
    }
  }
  return res;
}

// ---------------------------------------------------------------------------
// Firestore driver
// ---------------------------------------------------------------------------

const TS = admin.firestore.Timestamp;

function stripeFromEnv(testMode: boolean): StripeLike | null {
  const key = process.env[testMode ? 'STRIPE_TEST_SECRET_KEY' : 'STRIPE_SECRET_KEY'] || '';
  if (!key) return null;
  if (testMode !== key.startsWith('sk_test_')) return null; // never mix modes
  return new Stripe(key, { apiVersion: STRIPE_API_VERSION, maxNetworkRetries: 2, timeout: 20000 }) as unknown as StripeLike;
}

let cachedBq: BigQueryLike | null = null;
function bigQueryFromEnv(): BigQueryLike | null {
  if (process.env.FUNCTIONS_EMULATOR === 'true') return null;
  if (!cachedBq) {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const { BigQuery } = require('@google-cloud/bigquery');
    cachedBq = new BigQuery() as BigQueryLike;
  }
  return cachedBq;
}

/**
 * GA4 User Deletion API (Firebase project, app instance id). Needs the
 * functions service account to have the Editor (or Administrator) role on
 * the GA4 property linked to the Firebase project, and GA4_USER_DELETION=on.
 */
async function ga4DeleteFromEnv(appInstanceId: string): Promise<void> {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const { GoogleAuth } = require('google-auth-library');
  const auth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/analytics.user.deletion'] });
  const client = await auth.getClient();
  const project = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || '';
  await client.request({
    url: 'https://www.googleapis.com/analytics/v3/userDeletion/userDeletionRequests:upsert',
    method: 'POST',
    data: { kind: 'analytics#userDeletionRequest', id: { type: 'APP_INSTANCE_ID', userId: appInstanceId }, firebaseProjectId: project },
  });
}

export const deletionFollowupDeps: FollowupDeps = {
  stripe: stripeFromEnv,
  now: () => new Date(),
  db: () => admin.firestore(),
  bigquery: bigQueryFromEnv,
  ga4DeleteAppInstance: process.env.GA4_USER_DELETION === 'on' ? ga4DeleteFromEnv : null,
};

/** Claims [task] of the doc (lease) if due. Returns its data, or null. */
async function claim(db: FirebaseFirestore.Firestore, ref: FirebaseFirestore.DocumentReference, task: FollowupTask, now: Date) {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const d = snap.data();
    if (!snap.exists || !isTaskDue(d, task, now)) return null;
    tx.update(ref, {
      [`${task}Status`]: 'processing',
      [`${task}LeaseUntil`]: TS.fromMillis(now.getTime() + LEASE_MS),
    });
    return d as Record<string, any>;
  });
}

async function runTask(
  uid: string,
  task: FollowupTask,
  work: (d: Record<string, any>) => Promise<Record<string, unknown>>,
  deps: FollowupDeps,
): Promise<StripeFollowupStatus | 'skipped'> {
  const db = deps.db();
  const ref = db.collection(DELETION_FOLLOWUPS).doc(uid);
  const now = deps.now();
  let d: Record<string, any> | null;
  try {
    d = await claim(db, ref, task, now);
  } catch (e: any) {
    console.error(`[deletionFollowups] ${task} claim failed for ${uid}`, e?.message || e);
    return 'skipped';
  }
  if (!d) return 'skipped';
  const attempts = Number(d[`${task}Attempts`] || 0) + 1;
  const del = admin.firestore.FieldValue.delete();
  try {
    const fields = await work(d);
    if (fields[MORE] === true) {
      // Bounded run with work left: back to 'pending' (re-fires the trigger),
      // no attempt counted. Progress lives in the source data itself.
      delete fields[MORE];
      await ref.update({
        ...fields,
        [`${task}Status`]: 'pending',
        [`${task}Passes`]: admin.firestore.FieldValue.increment(1),
        [`${task}LeaseUntil`]: del,
      });
      return 'pending';
    }
    await ref.update({
      [`${task}Status`]: 'done',
      [`${task}Attempts`]: attempts,
      ...fields,
      [`${task}DoneAt`]: TS.fromDate(now),
      [`${task}LastError`]: del,
      [`${task}LeaseUntil`]: del,
      [`${task}NextAttemptAt`]: del,
    });
    return 'done';
  } catch (e: any) {
    const error = String(e?.message || e).slice(0, 300);
    const failed = attempts >= MAX_ATTEMPTS;
    console.error(`[deletionFollowups] ${uid}: ${task} attempt ${attempts} failed`, error);
    await ref.update({
      [`${task}Status`]: failed ? 'failed' : 'retry',
      [`${task}Attempts`]: attempts,
      [`${task}LastError`]: error,
      [`${task}LeaseUntil`]: del,
      [`${task}NextAttemptAt`]: failed ? del : TS.fromMillis(now.getTime() + retryDelayMs(attempts)),
    }).catch(() => undefined);
    if (failed) {
      // Admin queue: ids only, so a human can finish it by hand.
      await db.collection('admin_alerts').doc(`deletion_followup_${task}_${uid}`).set({
        type: 'deletion_followup_failed',
        task: task === 'stripe' ? 'cancel_stripe_subscriptions_delete_customer'
          : task === 'analytics' ? 'delete_analytics_data' : 'pseudonymise_buyer_ticket_records',
        followupId: uid,
        ...(task === 'stripe' ? {
          stripeCustomerId: d.stripeCustomerId || null,
          stripeTestCustomerId: d.stripeTestCustomerId || null,
        } : {}),
        attempts,
        lastError: error,
        status: 'open',
        createdAt: TS.fromDate(now),
      }, { merge: true }).catch((err) => console.error('[deletionFollowups] admin alert failed', err));
    }
    return failed ? 'failed' : 'retry';
  }
}

/** Processes the Stripe task of one follow-up doc. Never throws. */
export async function processStripeFollowup(
  uid: string,
  deps: FollowupDeps = deletionFollowupDeps,
): Promise<StripeFollowupStatus | 'skipped'> {
  return runTask(uid, 'stripe', async (d) => {
    const r = await cancelStripeSubscriptions(uid, d, deps);
    if (r.cancelled.length || r.customersDeleted.length) {
      console.log(`[deletionFollowups] ${uid}: cancelled ${r.cancelled.length} subscription(s), deleted ${r.customersDeleted.length} customer(s)`);
    }
    return {
      stripeCancelled: r.cancelled,
      stripeAlreadyEnded: r.alreadyEnded,
      stripeSkipped: r.skipped,
      stripeCustomersDeleted: r.customersDeleted,
      stripeCustomersAlreadyDeleted: r.customersAlreadyDeleted,
    };
  }, deps);
}

/** Processes the analytics task of one follow-up doc. Never throws. */
export async function processAnalyticsFollowup(
  uid: string,
  deps: FollowupDeps = deletionFollowupDeps,
): Promise<StripeFollowupStatus | 'skipped'> {
  return runTask(uid, 'analytics', async (d) => {
    const r = await deleteAnalyticsData(uid, d, deps);
    return {
      analyticsFirestoreDeleted: r.firestoreDeleted,
      analyticsBigQuery: r.bigQuery,
      analyticsGa4: r.ga4,
      crashlytics: r.crashlytics,
      // The app instance ids are not needed any more.
      ga4AppInstanceIds: admin.firestore.FieldValue.delete(),
    };
  }, deps);
}

/** Processes the buyer ticket-records task of one follow-up doc. Never throws. */
export async function processTicketsFollowup(
  uid: string,
  deps: FollowupDeps = deletionFollowupDeps,
): Promise<StripeFollowupStatus | 'skipped'> {
  return runTask(uid, 'tickets', async (d) => {
    const bdeps = deps.buyerRecords ? deps.buyerRecords() : buyerRecordsDepsFromEnv(deps.db, deps.now);
    const r = await pseudonymiseBuyerRecords(uid, d, bdeps);
    if (r.blocked > 0) throw new Error(`open_orders_pending:${r.blocked}`);
    const { more, blocked, ...counts } = r;
    void blocked;
    return {
      ...(more ? { [MORE]: true } : {}),
      // Counts only (no ids, no personal data).
      [`tickets${more ? 'Progress' : 'Result'}`]: counts,
      // The guest keys are not needed any more once done.
      ...(more ? {} : { ticketGuestKeys: admin.firestore.FieldValue.delete() }),
    };
  }, deps);
}

/** Scheduler body: due 'retry' / 'pending' tasks and stale leases, bounded per run. */
export async function retryDueFollowups(deps: FollowupDeps = deletionFollowupDeps): Promise<number> {
  const now = deps.now();
  const started = Date.now();
  let n = 0;
  for (const task of TASKS) {
    for (const status of ['retry', 'processing', 'pending'] as const) {
      const snap = await deps.db().collection(DELETION_FOLLOWUPS)
        .where(`${task}Status`, '==', status).limit(RETRY_BATCH).get();
      for (const doc of snap.docs) {
        // Stay inside the 540 s schedule timeout (a tickets pass may take
        // up to ~200 s); what is left is picked up by the next run.
        if (Date.now() - started > SCHEDULER_BUDGET_MS) return n;
        if (!isTaskDue(doc.data(), task, now)) continue;
        if (task === 'stripe') await processStripeFollowup(doc.id, deps);
        else if (task === 'analytics') await processAnalyticsFollowup(doc.id, deps);
        else await processTicketsFollowup(doc.id, deps);
        n++;
      }
    }
  }
  return n;
}

// ---------------------------------------------------------------------------
// Cloud Functions
// ---------------------------------------------------------------------------

// Existing Secret Manager secret (web checkout, ticket payments). The test
// key is not bound: test-mode customers are skipped unless the env has it.
const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');

export const processDeletionFollowup = onDocumentWritten(
  { document: `${DELETION_FOLLOWUPS}/{uid}`, memory: '512MiB', timeoutSeconds: 300, secrets: [STRIPE_SECRET_KEY] },
  async (event) => {
    const after = event.data?.after?.data();
    if (!after) return;
    // Cheap pre-check (our own status updates re-fire this trigger).
    const now = new Date();
    if (isTaskDue(after, 'stripe', now)) await processStripeFollowup(event.params.uid);
    if (isTaskDue(after, 'analytics', now)) await processAnalyticsFollowup(event.params.uid);
    if (isTaskDue(after, 'tickets', now)) await processTicketsFollowup(event.params.uid);
  },
);

export const retryDeletionFollowups = onSchedule(
  { schedule: 'every 30 minutes', memory: '512MiB', timeoutSeconds: 540, secrets: [STRIPE_SECRET_KEY] },
  async () => {
    const n = await retryDueFollowups();
    if (n) console.log(`[deletionFollowups] retried ${n} follow-up task(s)`);
  },
);
