/**
 * Account deletion follow-up task 'tickets' (owner decision 2026-10-21,
 * privacy policy 15.2 e: "Purchase and payment records are kept for the
 * period the tax and accounting laws require (see section 14). We first
 * remove your name, email and account id from them and replace the id with a
 * code that cannot identify you without additional information.").
 *
 * The BUYER side of ticket purchases (events + experiences). For every record
 * of the deleted user - found by the uid AND, when the account's e-mail was
 * verified, by the guest key of that e-mail (shared-link guest purchases the
 * buyer chat already links to the account, entitlements/listingChat.ts):
 *
 *   ticket_orders  buyerId -> pseudonym (retentionUidHash: the SAME code as
 *                  retention_finance.uidHash and the BigQuery financial rows,
 *                  so the organiser's records and reports still group by
 *                  buyer); attendeeNames -> null; guest / guestName removed;
 *                  receiptPath -> null (the buyer's receipt image is deleted);
 *                  buyerDeleted: true, buyerDeletedAt. Open (unpaid) orders
 *                  are closed first ('cancelled', cancelReason
 *                  'account_deleted'), which releases the held seats.
 *   tickets        buyerId -> pseudonym; attendeeName / FirstName / LastName
 *                  -> null; qrPayload removed; a 'valid' ticket of an
 *                  upcoming event -> status 'void' (voidReason
 *                  'account_deleted'): the QR can never be scanned.
 *   ticket_refunds buyerId -> pseudonym, buyerDeleted.
 *   admin_alerts   (ticket_refund_failed_*) buyerId -> pseudonym.
 *   ticket_holdings  per-buyer counters: DELETED.
 *   events/{id}/attendee_names/{buyer}  ticket holder names: DELETED.
 *   guest key only: guest_contacts/{key} (the e-mail) DELETED, the guest's
 *                  attendee docs DELETED (seats released), guest bookings:
 *                  guestId -> 'deleted_user', guest / guestName removed.
 *
 * KEPT (tax / accounting): amounts, currency, fees, host net, quantity, ticket
 * types / phases, dates, order / ticket / booking / event ids, organizer id,
 * provider references, status and refund status. Every other string equal to
 * the uid / guest key anywhere in those documents is replaced by the pseudonym.
 *
 * Idempotent and resumable: every step re-queries its source (a processed
 * document no longer matches `buyerId == uid`), no offsets are saved. Bounded:
 * at most MAX_PAGES pages of PAGE docs per collection per run and a deadline;
 * when work is left the task goes back to 'pending' (re-fires the trigger)
 * without counting an attempt. An order that is still open after the close
 * attempt is left alone and the task is retried with backoff.
 */

import * as admin from 'firebase-admin';
import { isGuestKey, GUEST_CONTACTS } from '../shared/guestIdentity';
import { retentionUidHash, TOMBSTONE } from './accountDeletion';

export const PAGE = 100;
export const MAX_PAGES = 20;
export const DEADLINE_MS = 200 * 1000;
/** A ticket whose event started more than this long ago is past (status kept). */
export const UPCOMING_GRACE_MS = 12 * 3600 * 1000;
export const OPEN_ORDER_STATUSES: readonly string[] = ['creating', 'pending', 'pending_payment', 'awaiting_confirmation'];

/** Buyer-side collections: the pseudonymised ones and the deleted counters. */
export const PSEUDONYMISED: ReadonlyArray<{ collection: string; field: string }> = [
  { collection: 'ticket_orders', field: 'buyerId' },
  { collection: 'tickets', field: 'buyerId' },
  { collection: 'ticket_refunds', field: 'buyerId' },
  { collection: 'admin_alerts', field: 'buyerId' },
];
export const DELETED: ReadonlyArray<{ collection: string; field: string }> = [
  { collection: 'ticket_holdings', field: 'uid' },
];

export interface BuyerRecordsDeps {
  db(): FirebaseFirestore.Firestore;
  now(): Date;
  /** Closes an OPEN order (seat released, provider session expired). */
  closeOpenOrder(orderId: string): Promise<void>;
  /** Deletes a Storage object (missing = fine). */
  deleteFile(path: string): Promise<void>;
}

export interface BuyerRecordsResult {
  orders: number;
  tickets: number;
  ticketsVoided: number;
  refunds: number;
  alerts: number;
  openOrdersClosed: number;
  holdingsDeleted: number;
  attendeeNamesDeleted: number;
  receiptsDeleted: number;
  guestKeys: number;
  guestContactsDeleted: number;
  guestAttendeesDeleted: number;
  guestBookings: number;
  /** Work left over (bounds hit): run again. */
  more: boolean;
  /** Open orders that could not be closed yet: retry later. */
  blocked: number;
}

/** The pseudonym of [uid] (same as retention_finance.uidHash / BigQuery). */
export const buyerPseudonym = (uid: string): string => retentionUidHash(uid);

const ms = (v: any): number | null => {
  if (v && typeof v.toMillis === 'function') return v.toMillis();
  if (v instanceof Date) return v.getTime();
  if (typeof v === 'number' && Number.isFinite(v)) return v;
  return null;
};

function isPlain(v: any): boolean {
  return !!v && typeof v === 'object' && !Array.isArray(v) && Object.getPrototypeOf(v) === Object.prototype;
}

/** Deep copy of [v] with every string / map key equal to one of [ids] replaced by [to]. */
export function replaceIds(v: any, ids: ReadonlySet<string>, to: string): any {
  if (typeof v === 'string') return ids.has(v) ? to : v;
  if (Array.isArray(v)) return v.map((x) => replaceIds(x, ids, to));
  if (isPlain(v)) {
    const out: Record<string, any> = {};
    for (const [k, x] of Object.entries(v)) out[ids.has(k) ? to : k] = replaceIds(x, ids, to);
    return out;
  }
  return v; // Timestamps, GeoPoints, refs, numbers, booleans, null
}

/**
 * Buyer personal data that may sit on any buyer-side record: set to null when
 * present (guest / guestName are removed). The QR token is removed too.
 */
export const BUYER_PII_FIELDS: readonly string[] = [
  'attendeeNames', 'attendeeName', 'attendeeFirstName', 'attendeeLastName',
  'buyerName', 'buyerEmail', 'buyerPhone', 'email', 'phone', 'displayName', 'receiptPath',
];
const BUYER_PII_REMOVED: readonly string[] = ['guest', 'guestName', 'qrPayload'];

/** Common part: ids -> pseudonym, PII cleared, deletion marker (pure). */
export function pseudonymiseRecord(r: Record<string, any>, ids: ReadonlySet<string>, pseudonym: string, nowMs: number): Record<string, any> {
  const out = replaceIds(r, ids, pseudonym);
  for (const f of BUYER_PII_FIELDS) if (f in out) out[f] = null;
  for (const f of BUYER_PII_REMOVED) delete out[f];
  out.buyerDeleted = true;
  out.buyerDeletedAt = admin.firestore.Timestamp.fromMillis(nowMs);
  return out;
}

/** The order after pseudonymisation (pure; exported for tests). */
export function pseudonymiseOrder(o: Record<string, any>, ids: ReadonlySet<string>, pseudonym: string, nowMs: number): Record<string, any> {
  const out = pseudonymiseRecord(o, ids, pseudonym, nowMs);
  out.buyerId = pseudonym;
  return out;
}

/** The ticket after pseudonymisation (pure; exported for tests). */
export function pseudonymiseTicket(t: Record<string, any>, ids: ReadonlySet<string>, pseudonym: string, nowMs: number): Record<string, any> {
  const out = pseudonymiseRecord(t, ids, pseudonym, nowMs);
  out.buyerId = pseudonym;
  out.attendeeName = null;
  out.attendeeFirstName = null;
  out.attendeeLastName = null;
  const start = ms(t.startsAt);
  const upcoming = start === null || start + UPCOMING_GRACE_MS > nowMs;
  if (t.status === 'valid' && upcoming) {
    out.status = 'void';
    out.voidReason = 'account_deleted';
    out.voidedAt = admin.firestore.Timestamp.fromMillis(nowMs);
  }
  return out;
}

/** The subjects of a deletion: the uid + valid guest keys stored on the follow-up doc. */
export function subjectsOf(uid: string, d: Record<string, any> | undefined): string[] {
  const keys = Array.isArray(d?.ticketGuestKeys) ? d!.ticketGuestKeys.filter(isGuestKey).slice(0, 5) : [];
  return [uid, ...keys.filter((k: string) => k !== uid)];
}

/**
 * Pseudonymises / deletes the buyer-side ticket records of [uid] (see the
 * header). Throws on a Firestore error (the caller retries).
 */
export async function pseudonymiseBuyerRecords(
  uid: string,
  d: Record<string, any> | undefined,
  deps: BuyerRecordsDeps,
): Promise<BuyerRecordsResult> {
  const db = deps.db();
  const started = Date.now();
  const nowMs = deps.now().getTime();
  const pseudonym = buyerPseudonym(uid);
  const subjects = subjectsOf(uid, d);
  const ids = new Set(subjects);
  const res: BuyerRecordsResult = {
    orders: 0, tickets: 0, ticketsVoided: 0, refunds: 0, alerts: 0, openOrdersClosed: 0, holdingsDeleted: 0,
    attendeeNamesDeleted: 0, receiptsDeleted: 0, guestKeys: subjects.length - 1, guestContactsDeleted: 0,
    guestAttendeesDeleted: 0, guestBookings: 0, more: false, blocked: 0,
  };
  const outOfTime = () => Date.now() - started > DEADLINE_MS;

  /**
   * Re-queries `field == subject` page by page and hands each page to [each],
   * which returns how many docs it took out of the query. Stops when the
   * source is empty, a page makes no progress (blocked docs), or the bounds
   * are hit (res.more).
   */
  const drain = async (
    q: () => FirebaseFirestore.Query,
    each: (docs: FirebaseFirestore.QueryDocumentSnapshot[]) => Promise<number>,
  ) => {
    for (let page = 0; ; page++) {
      if (page >= MAX_PAGES || outOfTime()) { res.more = true; return; }
      const snap = await q().limit(PAGE).get();
      if (snap.empty) return;
      const done = await each(snap.docs);
      if (snap.size < PAGE || done === 0) return;
    }
  };

  const deleteDoc = async (ref: FirebaseFirestore.DocumentReference): Promise<boolean> => {
    const s = await ref.get();
    if (!s.exists) return false;
    await ref.delete();
    return true;
  };

  for (const id of subjects) {
    const guest = id !== uid;

    // 1. Orders (open ones closed first; holdings + holder names of each).
    await drain(() => db.collection('ticket_orders').where('buyerId', '==', id), async (docs) => {
      let done = 0;
      for (const doc of docs) {
        let o = doc.data();
        if (OPEN_ORDER_STATUSES.includes(String(o.status))) {
          await deps.closeOpenOrder(doc.id);
          o = (await doc.ref.get()).data() || o;
          if (OPEN_ORDER_STATUSES.includes(String(o.status))) { res.blocked++; continue; }
          res.openOrdersClosed++;
        }
        if (typeof o.listingId === 'string' && o.listingId && !o.listingId.includes('/')) {
          if (o.kind === 'event' && await deleteDoc(db.collection('events').doc(o.listingId).collection('attendee_names').doc(id))) {
            res.attendeeNamesDeleted++;
          }
          if (await deleteDoc(db.collection('ticket_holdings').doc(`${o.kind}_${o.listingId}_${id}`))) res.holdingsDeleted++;
        }
        if (typeof o.receiptPath === 'string' && o.receiptPath.startsWith(`ticket_receipts/${doc.id}/`)) {
          await deps.deleteFile(o.receiptPath);
          res.receiptsDeleted++;
        }
        const wrote = await db.runTransaction(async (tx) => {
          const cur = await tx.get(doc.ref);
          const c = cur.data();
          if (!c || c.buyerId !== id || OPEN_ORDER_STATUSES.includes(String(c.status))) return false;
          tx.set(doc.ref, pseudonymiseOrder(c, ids, pseudonym, nowMs));
          return true;
        });
        if (wrote) { res.orders++; done++; } else res.blocked++;
      }
      return done;
    });

    // 2. Tickets (QR removed; upcoming valid tickets voided).
    await drain(() => db.collection('tickets').where('buyerId', '==', id), async (docs) => {
      const b = db.batch();
      for (const doc of docs) {
        const t = doc.data();
        const out = pseudonymiseTicket(t, ids, pseudonym, nowMs);
        if (out.status === 'void' && t.status !== 'void') res.ticketsVoided++;
        b.set(doc.ref, out);
      }
      await b.commit();
      res.tickets += docs.length;
      return docs.length;
    });

    // 3. Refund outbox rows and admin alerts.
    for (const [col, key] of [['ticket_refunds', 'refunds'], ['admin_alerts', 'alerts']] as const) {
      await drain(() => db.collection(col).where('buyerId', '==', id), async (docs) => {
        let done = 0;
        for (const doc of docs) {
          const wrote = await db.runTransaction(async (tx) => {
            const cur = await tx.get(doc.ref);
            const c = cur.data();
            if (!c || c.buyerId !== id) return false;
            tx.set(doc.ref, pseudonymiseRecord(c, ids, pseudonym, nowMs));
            return true;
          });
          if (wrote) { res[key]++; done++; }
        }
        return done;
      });
    }

    // 4. Per-buyer counters left over (orders already gone / never existed).
    await drain(() => db.collection('ticket_holdings').where('uid', '==', id), async (docs) => {
      const b = db.batch();
      docs.forEach((x) => b.delete(x.ref));
      await b.commit();
      res.holdingsDeleted += docs.length;
      return docs.length;
    });

    if (!guest) continue;

    // 5. Guest key of the account's verified e-mail: contact, roster, bookings.
    if (await deleteDoc(db.collection(GUEST_CONTACTS).doc(id))) res.guestContactsDeleted++;
    await drain(() => db.collectionGroup('attendees').where('userId', '==', id), async (docs) => {
      for (const doc of docs) {
        // events/{eventId}/attendees/{key} -> events/{eventId}
        const segs = doc.ref.path.split('/');
        const parent = segs.length >= 4 ? db.doc(segs.slice(0, -2).join('/')) : null;
        await db.runTransaction(async (tx) => {
          const cur = await tx.get(doc.ref);
          if (!cur.exists) return;
          const p = parent ? await tx.get(parent) : null;
          const a = cur.data() || {};
          const seats = a.status === 'going' ? 1 + Math.max(0, Math.floor(Number(a.guestCount) || 0)) : 0;
          tx.delete(doc.ref);
          if (p?.exists && seats > 0) {
            tx.update(parent!, { attendeeCount: Math.max(0, (Number(p.data()?.attendeeCount) || 0) - seats) });
          }
        });
        res.guestAttendeesDeleted++;
      }
      return docs.length;
    });
    await drain(() => db.collection('bookings').where('guestId', '==', id), async (docs) => {
      for (const doc of docs) {
        await db.runTransaction(async (tx) => {
          const cur = await tx.get(doc.ref);
          const c = cur.data();
          if (!c || c.guestId !== id) return;
          const out = replaceIds(c, new Set([id]), TOMBSTONE);
          delete out.guest;
          delete out.guestName;
          out.participantDeletedAt = admin.firestore.Timestamp.fromMillis(nowMs);
          tx.set(doc.ref, out);
        });
        res.guestBookings++;
      }
      return docs.length;
    });
  }
  return res;
}

/** Production dependencies (lazy imports: orders.ts is heavy). */
export function buyerRecordsDepsFromEnv(db: () => FirebaseFirestore.Firestore, now: () => Date): BuyerRecordsDeps {
  return {
    db,
    now,
    closeOpenOrder: async (orderId: string) => {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const orders = require('../ticket_payments/orders');
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const cfg = require('../ticket_payments/config');
      const before = (await db().collection('ticket_orders').doc(orderId).get()).data();
      await orders.closeOrder(orderId, 'cancelled', { cancelReason: 'account_deleted' });
      // A Stripe Checkout session left open could still be paid: expire it.
      const ref = before?.providerRef || {};
      if (before?.provider === 'stripe' && ref.stripeSessionId && cfg.stripeConfigured()) {
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        const providers = require('../ticket_payments/providers');
        await providers.stripeExpireSession(ref.stripeAccountId, ref.stripeSessionId).catch(() => undefined);
      }
    },
    deleteFile: async (path: string) => {
      await admin.storage().bucket().file(path).delete({ ignoreNotFound: true });
    },
  };
}
