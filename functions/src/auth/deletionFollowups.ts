/**
 * Account deletion follow-up: cancel the user's WEB (Stripe) subscriptions
 * (audit P2-7, Terms 7.3 / privacy policy).
 *
 * deleteAccountData (./accountDeletion.ts) writes `deletion_followups/{uid}`
 * with the user's Stripe customer id(s) BEFORE stripe_customers / profiles are
 * deleted. This worker cancels every live subscription of those customers
 * IMMEDIATELY (no further renewals, no proration refund: Terms 7.3 - the
 * Membership ends with the account). Store subscriptions (Apple / Google)
 * cannot be cancelled by us; the deletion dialog tells the user to cancel
 * them in the store.
 *
 * The Stripe customer itself is NOT deleted: its invoices/charges are the
 * bookkeeping records we must keep (privacy policy, retention_finance), and
 * a deleted customer would make refunds / disputes impossible to process.
 *
 * Idempotent and retried:
 *   - processDeletionFollowup (Firestore trigger) runs when the doc is
 *     written with stripeStatus absent/'pending'.
 *   - retryDeletionFollowups (every 30 min) picks up docs in 'retry' whose
 *     stripeNextAttemptAt has passed (single-field equality query, bounded).
 *   - A transactional lease (stripeStatus 'processing' + stripeLeaseUntil)
 *     keeps the trigger and the scheduler from running the same doc twice;
 *     cancelling an already-cancelled subscription is treated as success.
 *   - After MAX_ATTEMPTS the doc goes to 'failed' and an admin_alerts row
 *     (type 'deletion_followup_failed', ids only) is written for a human.
 *
 * Only the Stripe part of the follow-up lives here; analytics/crashlytics
 * flags on the same doc are untouched.
 */

import * as admin from 'firebase-admin';
import Stripe from 'stripe';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { defineSecret } from 'firebase-functions/params';
import '../shared/firebaseAdmin';
import { DELETION_FOLLOWUPS } from './accountDeletion';
import { STRIPE_API_VERSION } from '../payments/stripeCore';

export const MAX_ATTEMPTS = 8;
export const LEASE_MS = 5 * 60 * 1000;
export const RETRY_BATCH = 50;
/** Statuses that can still bill or be resumed; everything else is final. */
export const CANCELLABLE_STATUSES: readonly string[] = [
  'active', 'trialing', 'past_due', 'unpaid', 'incomplete', 'paused',
];

export type StripeFollowupStatus =
  | 'pending' | 'processing' | 'retry' | 'done' | 'failed';

export interface StripeLike {
  subscriptions: {
    list(params: Record<string, any>): Promise<{ data: any[]; has_more?: boolean }>;
    cancel(id: string, params?: Record<string, any>): Promise<any>;
    search?(params: Record<string, any>): Promise<{ data: any[] }>;
  };
}

export interface FollowupDeps {
  /** null when the key for that mode is not configured. */
  stripe(testMode: boolean): StripeLike | null;
  now(): Date;
  db(): FirebaseFirestore.Firestore;
}

export interface CancelResult {
  cancelled: string[];
  alreadyEnded: string[];
  skipped: string[]; // e.g. 'test:no_key'
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

/** True when the doc should be (re)processed now. */
export function isDue(d: Record<string, any> | undefined, now: Date): boolean {
  if (!d) return false;
  const st = d.stripeStatus as StripeFollowupStatus | undefined;
  const ms = (v: any): number => (v && typeof v.toMillis === 'function' ? v.toMillis() : 0);
  if (st === undefined || st === 'pending') return true;
  if (st === 'retry') return ms(d.stripeNextAttemptAt) <= now.getTime();
  if (st === 'processing') return ms(d.stripeLeaseUntil) <= now.getTime(); // stale lease
  return false;
}

function isAlreadyEndedError(e: any): boolean {
  const code = String(e?.code || e?.raw?.code || '');
  const msg = String(e?.message || '');
  return code === 'resource_missing' || /canceled subscription|No such subscription/i.test(msg);
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
 * customer that was never mapped). Throws on a real Stripe failure so the
 * caller schedules a retry; partial progress is safe to repeat.
 */
export async function cancelStripeSubscriptions(
  uid: string,
  d: Record<string, any>,
  deps: FollowupDeps,
): Promise<CancelResult> {
  const result: CancelResult = { cancelled: [], alreadyEnded: [], skipped: [] };
  const modes: Array<{ test: boolean; customer: string | null }> = [
    { test: false, customer: typeof d.stripeCustomerId === 'string' ? d.stripeCustomerId : null },
    { test: true, customer: typeof d.stripeTestCustomerId === 'string' ? d.stripeTestCustomerId : null },
  ];
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
    if (!m.test && stripe.subscriptions.search && /^[A-Za-z0-9_-]+$/.test(uid)) {
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
  }
  return result;
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

export const deletionFollowupDeps: FollowupDeps = {
  stripe: stripeFromEnv,
  now: () => new Date(),
  db: () => admin.firestore(),
};

/** Claims the doc (lease) if due. Returns its data, or null. */
async function claim(db: FirebaseFirestore.Firestore, ref: FirebaseFirestore.DocumentReference, now: Date) {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const d = snap.data();
    if (!snap.exists || !isDue(d, now)) return null;
    tx.update(ref, {
      stripeStatus: 'processing',
      stripeLeaseUntil: TS.fromMillis(now.getTime() + LEASE_MS),
    });
    return d as Record<string, any>;
  });
}

/** Processes one follow-up doc. Never throws. */
export async function processStripeFollowup(
  uid: string,
  deps: FollowupDeps = deletionFollowupDeps,
): Promise<StripeFollowupStatus | 'skipped'> {
  const db = deps.db();
  const ref = db.collection(DELETION_FOLLOWUPS).doc(uid);
  const now = deps.now();
  let d: Record<string, any> | null;
  try {
    d = await claim(db, ref, now);
  } catch (e: any) {
    console.error(`[deletionFollowups] claim failed for ${uid}`, e?.message || e);
    return 'skipped';
  }
  if (!d) return 'skipped';
  const attempts = Number(d.stripeAttempts || 0) + 1;
  try {
    const r = await cancelStripeSubscriptions(uid, d, deps);
    await ref.update({
      stripeStatus: 'done',
      stripeAttempts: attempts,
      stripeCancelled: r.cancelled,
      stripeAlreadyEnded: r.alreadyEnded,
      stripeSkipped: r.skipped,
      stripeDoneAt: TS.fromDate(now),
      stripeLastError: admin.firestore.FieldValue.delete(),
      stripeLeaseUntil: admin.firestore.FieldValue.delete(),
      stripeNextAttemptAt: admin.firestore.FieldValue.delete(),
    });
    if (r.cancelled.length) {
      console.log(`[deletionFollowups] ${uid}: cancelled ${r.cancelled.length} Stripe subscription(s)`);
    }
    return 'done';
  } catch (e: any) {
    const error = String(e?.message || e).slice(0, 300);
    const failed = attempts >= MAX_ATTEMPTS;
    console.error(`[deletionFollowups] ${uid}: attempt ${attempts} failed`, error);
    await ref.update({
      stripeStatus: failed ? 'failed' : 'retry',
      stripeAttempts: attempts,
      stripeLastError: error,
      stripeLeaseUntil: admin.firestore.FieldValue.delete(),
      stripeNextAttemptAt: failed
        ? admin.firestore.FieldValue.delete()
        : TS.fromMillis(now.getTime() + retryDelayMs(attempts)),
    }).catch(() => undefined);
    if (failed) {
      // Admin queue: ids only, so a human can cancel in the Stripe dashboard.
      await db.collection('admin_alerts').doc(`deletion_followup_stripe_${uid}`).set({
        type: 'deletion_followup_failed',
        task: 'cancel_stripe_subscriptions',
        followupId: uid,
        stripeCustomerId: d.stripeCustomerId || null,
        stripeTestCustomerId: d.stripeTestCustomerId || null,
        attempts,
        lastError: error,
        status: 'open',
        createdAt: TS.fromDate(now),
      }, { merge: true }).catch((err) => console.error('[deletionFollowups] admin alert failed', err));
    }
    return failed ? 'failed' : 'retry';
  }
}

/** Scheduler body: due 'retry' docs and stale leases, bounded per run. */
export async function retryDueFollowups(deps: FollowupDeps = deletionFollowupDeps): Promise<number> {
  const now = deps.now();
  let n = 0;
  for (const status of ['retry', 'processing', 'pending'] as const) {
    const snap = await deps.db().collection(DELETION_FOLLOWUPS)
      .where('stripeStatus', '==', status).limit(RETRY_BATCH).get();
    for (const doc of snap.docs) {
      if (!isDue(doc.data(), now)) continue;
      await processStripeFollowup(doc.id, deps);
      n++;
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
  { document: `${DELETION_FOLLOWUPS}/{uid}`, memory: '512MiB', timeoutSeconds: 120, secrets: [STRIPE_SECRET_KEY] },
  async (event) => {
    const after = event.data?.after?.data();
    // Cheap pre-check (our own status updates re-fire this trigger).
    if (!after || !isDue(after, new Date())) return;
    await processStripeFollowup(event.params.uid);
  },
);

export const retryDeletionFollowups = onSchedule(
  { schedule: 'every 30 minutes', memory: '512MiB', timeoutSeconds: 300, secrets: [STRIPE_SECRET_KEY] },
  async () => {
    const n = await retryDueFollowups();
    if (n) console.log(`[deletionFollowups] retried ${n} follow-up(s)`);
  },
);
