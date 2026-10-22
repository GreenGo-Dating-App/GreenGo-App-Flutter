/**
 * Account deletion is refused while the user still SELLS something that is
 * paid and not refunded (owner rule 2026-10-21): an upcoming or ongoing
 * event / experience with paid orders, or any refund of theirs that is not
 * settled (in progress, failed, proof under review). Completed listings
 * whose orders are settled never block.
 *
 * Checked FIRST by every deletion entry point that can still refuse
 * (deleteMyAccount, requestAccountDeletion signed-in mode,
 * confirmAccountDeletion GET + POST) through deleteAccountCompletely, and
 * exposed to the app as getDeletionBlockers (the Delete account flow lists
 * the items with "Cancel & refund"). The Auth onDelete trigger cannot refuse
 * (the Auth user is already gone): it is reached only from the console /
 * admin panel / old app versions.
 *
 * Bounded, indexed queries (firestore.indexes.json):
 *   ticket_orders  organizerId ==, status == 'paid', startsAt >= now - 2 days
 *                  (composite organizerId, status, startsAt), limit 500
 *   ticket_refunds organizerId ==, status in UNSETTLED
 *                  (composite organizerId, status), limit 200
 * Experiences are covered by their orders (kind 'experience': every paid
 * booking has one).
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { COL } from '../ticket_payments/config';
import { REFUNDS, UNSETTLED, eventStillRefundable } from '../ticket_payments/refunds';
import { msOf } from '../ticket_payments/orders';

export const DELETION_BLOCKED = 'deletion_blocked_paid_orders';
/**
 * Deletion requested while blockers exist (Apple 5.1.1(v), 2026-10-22):
 * `scheduled_account_deletions/{uid}`, server-only, owner may read
 * (./scheduledDeletion.ts). Lives here so accountDeletion.ts can clear it
 * without an import cycle.
 */
export const SCHEDULED_DELETIONS = 'scheduled_account_deletions';
/** Profile accountStatus while a scheduled deletion waits (hidden everywhere). */
export const DELETION_PENDING_STATUS = 'deletion_pending';

/** A deletion request that has not been cancelled (the seller can't sell). */
export function isClosingRecord(d: Record<string, any> | undefined | null): boolean {
  return !!d && (d.status === 'waiting_refunds' || d.status === 'deleting' || d.status === 'failed');
}
/** An order whose start is older than this is past for sure (ongoing events are checked on the event). */
const ONGOING_WINDOW_MS = 2 * 24 * 3600 * 1000;
const ORDER_LIMIT = 500;
const REFUND_LIMIT = 200;

export interface BlockerOrder {
  orderId: string;
  /** 'paid' (not refunded yet) or the refund status (refund_failed, ...). */
  status: string;
}

export interface DeletionBlocker {
  kind: 'event' | 'experience';
  listingId: string;
  title: string;
  startsAt: string | null;
  /** Paid orders that are not refunded (incl. those with a refund running / failed). */
  paidOrders: number;
  refundsInProgress: number;
  failedRefunds: number;
  pendingReview: number;
  /** Experience bookings the host can cancel (full refund). */
  bookingIds: string[];
  /** Orders that need the seller (refund_failed / under review), max 50. */
  actionOrders: BlockerOrder[];
}

export interface BlockerDeps {
  db(): FirebaseFirestore.Firestore;
  now(): number;
}

export const blockerDeps: BlockerDeps = { db: () => admin.firestore(), now: () => Date.now() };

export class DeletionBlockedError extends Error {
  readonly code = DELETION_BLOCKED;
  constructor(public readonly blockers: DeletionBlocker[]) {
    super(`account deletion blocked: ${blockers.length} listing(s) with paid, unrefunded orders`);
  }
}

function iso(v: unknown): string | null {
  const ms = msOf(v);
  return ms === null ? null : new Date(ms).toISOString();
}

export async function computeDeletionBlockers(uid: string, deps: BlockerDeps = blockerDeps): Promise<DeletionBlocker[]> {
  const db = deps.db();
  const now = deps.now();
  const [orders, refunds] = await Promise.all([
    db.collection(COL.orders)
      .where('organizerId', '==', uid)
      .where('status', '==', 'paid')
      .where('startsAt', '>=', admin.firestore.Timestamp.fromMillis(now - ONGOING_WINDOW_MS))
      .limit(ORDER_LIMIT)
      .get(),
    db.collection(REFUNDS)
      .where('organizerId', '==', uid)
      .where('status', 'in', [...UNSETTLED])
      .limit(REFUND_LIMIT)
      .get(),
  ]);

  const byListing = new Map<string, DeletionBlocker>();
  const entry = (kind: 'event' | 'experience', listingId: string, title: string, startsAt: unknown): DeletionBlocker => {
    const k = `${kind}:${listingId}`;
    let b = byListing.get(k);
    if (!b) {
      b = {
        kind, listingId, title: String(title || '').slice(0, 200), startsAt: iso(startsAt),
        paidOrders: 0, refundsInProgress: 0, failedRefunds: 0, pendingReview: 0, bookingIds: [], actionOrders: [],
      };
      byListing.set(k, b);
    }
    return b;
  };

  // Listing state, read once per listing.
  const eventCache = new Map<string, Record<string, any> | undefined>();
  const bookingCache = new Map<string, Record<string, any> | undefined>();
  const eventOf = async (id: string) => {
    if (!eventCache.has(id)) eventCache.set(id, (await db.collection('events').doc(id).get()).data());
    return eventCache.get(id);
  };
  const bookingOf = async (id: string) => {
    if (!bookingCache.has(id)) bookingCache.set(id, (await db.collection('bookings').doc(id).get()).data());
    return bookingCache.get(id);
  };

  const refundRows = new Map(refunds.docs.map((d) => [d.id, d.data()]));
  const counted = new Set<string>();

  for (const d of orders.docs) {
    const o = d.data();
    const kind = o.kind === 'experience' ? 'experience' : 'event';
    if (kind === 'event') {
      const ev = await eventOf(String(o.listingId));
      // Upcoming / ongoing (a cancelled event keeps blocking until refunded).
      if (!ev || !eventStillRefundable(ev, now)) {
        if (!refundRows.has(d.id)) continue;
      }
      const b = entry('event', String(o.listingId), ev?.title ?? o.title, ev?.startDate ?? o.startsAt);
      b.paidOrders++;
    } else {
      const bk = o.bookingId ? await bookingOf(String(o.bookingId)) : undefined;
      const end = msOf(bk?.slotEnd) ?? ((msOf(o.startsAt) ?? 0) + 6 * 3600 * 1000);
      const active = bk && bk.status !== 'completed' && end > now;
      if (!active && !refundRows.has(d.id)) continue;
      const b = entry('experience', String(o.listingId), bk?.experienceTitle ?? o.title, o.startsAt);
      b.paidOrders++;
      if (active && o.bookingId && bk?.status === 'confirmed' && !b.bookingIds.includes(String(o.bookingId))) {
        b.bookingIds.push(String(o.bookingId));
      }
    }
    counted.add(d.id);
  }

  for (const [orderId, r] of refundRows) {
    const kind = r.kind === 'experience' ? 'experience' : 'event';
    const b = entry(kind, String(r.listingId), r.title, null);
    if (!counted.has(orderId)) b.paidOrders++;
    if (r.status === 'refund_failed') b.failedRefunds++;
    else if (r.status === 'manual_refund_pending_review') b.pendingReview++;
    else b.refundsInProgress++;
    if ((r.status === 'refund_failed' || r.status === 'manual_refund_pending_review') && b.actionOrders.length < 50) {
      b.actionOrders.push({ orderId, status: String(r.status) });
    }
  }
  return [...byListing.values()].sort((a, b) => String(a.startsAt ?? '').localeCompare(String(b.startsAt ?? '')));
}

/** Throws DeletionBlockedError when [uid] still has paid, unrefunded sales. */
export async function assertNoDeletionBlockers(uid: string, deps: BlockerDeps = blockerDeps): Promise<void> {
  const blockers = await computeDeletionBlockers(uid, deps);
  if (blockers.length) throw new DeletionBlockedError(blockers);
}
