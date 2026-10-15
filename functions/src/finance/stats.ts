/**
 * Sales stats + per-order seller fee invoices from ticket_orders writes.
 *
 * applyOrderFinance() is the ONE code path for a paid / reversed order, used
 * by the onTicketOrderFinance trigger and by the admin backfill. Counting is
 * idempotent per order through finance_order_marks/{orderId}
 * ({ paidCounted, reversalCounted }, written in the same transaction as the
 * increments), so trigger retries and re-running the backfill never double count.
 *
 * Increments (FieldValue.increment, O(1) per order; no scans at any scale):
 *   business_stats/{organizerId}               totals.{cur}.*  + lastSaleAt
 *   business_stats/{organizerId}/months/{yyyymm} byCurrency.{cur}.*  (statements
 *                                              + monthly seller fee invoices)
 *   admin_stats_daily/{yyyy-mm-dd}             byCurrency.{cur}.*, byKind.{kind}.*
 * Test orders (buyer or organizer is a test user) touch ONLY
 * business_stats/{organizerId}/months_test/{yyyymm}, so production totals stay
 * clean while test sellers still get TEST statements + TEST fee invoices.
 *
 * The fee is owed by the SELLER: per-order invoices ('per_order' mode) are
 * issued to the organizer; in 'monthly' mode nothing is issued here (see
 * ./statements.ts).
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { FCOL, createDocument, creditDocument, isTestUid, loadSettings, partyFor, processDocument } from './invoices';
import { OrderTransition, dayKey, feeInvoiceFromOrder, listingKey, monthKey, orderAmounts } from './model';

const db = () => admin.firestore();
const inc = (n: number) => admin.firestore.FieldValue.increment(n);

export const feeInvoiceId = (orderId: string) => `fee_${orderId}`;
export const feeCreditId = (orderId: string) => `cn_${orderId}`;

function toDate(v: any, fallback: Date): Date {
  if (v && typeof v.toDate === 'function') return v.toDate();
  if (v instanceof Date) return v;
  return fallback;
}

export interface ApplyResult { counted: boolean; isTest: boolean; invoiceId: string | null; creditId: string | null }

export async function applyOrderFinance(
  orderId: string,
  o: any,
  transition: Exclude<OrderTransition, null>,
  opts: { issueDocuments?: boolean; actor?: string } = {},
): Promise<ApplyResult> {
  const amounts = orderAmounts(o);
  const out: ApplyResult = { counted: false, isTest: false, invoiceId: null, creditId: null };
  if (!amounts || !o?.organizerId) return out;
  const isTest = (await isTestUid(o.buyerId)) || (await isTestUid(o.organizerId));
  out.isTest = isTest;
  const now = new Date();
  const at = transition === 'paid' ? toDate(o.paidAt, now) : now;
  const cur = amounts.currency;
  const kind = o.kind === 'experience' ? 'experience' : 'event';

  const markRef = db().collection(FCOL.marks).doc(orderId);
  const bizRef = db().collection(FCOL.businessStats).doc(String(o.organizerId));
  const monthRef = bizRef.collection(isTest ? 'months_test' : 'months').doc(monthKey(at));
  const dayRef = db().collection(FCOL.daily).doc(dayKey(at));

  out.counted = await db().runTransaction(async (tx) => {
    const m = (await tx.get(markRef)).data() || {};
    if (transition === 'paid' && m.paidCounted) return false;
    if (transition === 'reversed' && (m.reversalCounted || !m.paidCounted)) return false;
    const t = admin.firestore.Timestamp.fromDate(now);
    tx.set(markRef, {
      orderId, isTest, organizerId: o.organizerId, currency: cur,
      ...(transition === 'paid' ? { paidCounted: true, paidCountedAt: t } : { reversalCounted: true, reversalCountedAt: t }),
    }, { merge: true });

    const money = transition === 'paid'
      ? { gross: inc(amounts.gross), fees: inc(amounts.fees), buyerTotal: inc(amounts.buyerTotal), orders: inc(1), tickets: inc(amounts.tickets) }
      // refundedBuyer = what the buyer got back (totalAmount: ticket price on
      // seller-pays orders, price + fee on legacy buyer-pays orders).
      : { refunds: inc(amounts.gross), refundedFees: inc(amounts.fees), refundedBuyer: inc(amounts.buyerTotal), refundedOrders: inc(1) };
    // Per event / experience (one entry per listing and currency): the seller's
    // monthly fee invoice and statement list every listing that earned money.
    const lk = listingKey(kind, String(o.listingId || o.bookingId || 'unknown'), cur);
    const listing = {
      listingId: String(o.listingId || ''), kind, currency: cur, title: String(o.title || '').slice(0, 200), ...money,
    };
    tx.set(monthRef, {
      organizerId: o.organizerId, month: monthKey(at), byCurrency: { [cur]: money }, byListing: { [lk]: listing }, updatedAt: t,
    }, { merge: true });
    if (isTest) return true;

    tx.set(bizRef, {
      organizerId: o.organizerId, totals: { [cur]: money }, updatedAt: t,
      ...(transition === 'paid' ? { lastSaleAt: admin.firestore.Timestamp.fromDate(at), orderCounts: { [kind]: inc(1) } } : {}),
    }, { merge: true });
    tx.set(dayRef, {
      date: dayKey(at), byCurrency: { [cur]: money },
      ...(transition === 'paid' ? { byKind: { [kind]: { orders: inc(1), tickets: inc(amounts.tickets) } } } : {}),
      updatedAt: t,
    }, { merge: true });
    return true;
  });

  if (opts.issueDocuments === false) return out;
  const st = await loadSettings();
  if (st.sellerFeeInvoicing !== 'per_order') return out;
  if (transition === 'paid' && st.autoIssueFeeInvoices) {
    const seller = await partyFor(String(o.organizerId));
    const draft = feeInvoiceFromOrder(st, orderId, o, seller, isTest);
    if (draft) {
      const { invoice } = await createDocument(feeInvoiceId(orderId), draft, st, opts.actor || 'system');
      out.invoiceId = invoice.id;
      // Not e-mailed now: the 2nd-of-month batch sends every invoice of the month with the statement.
      await processDocument(invoice.id, { email: false });
    }
  }
  if (transition === 'reversed' && st.autoCreditNotes) {
    const exists = (await db().collection(FCOL.invoices).doc(feeInvoiceId(orderId)).get()).exists;
    if (exists) {
      const cn = await creditDocument(
        feeInvoiceId(orderId), feeCreditId(orderId),
        o.status === 'disputed' ? 'dispute' : 'refund', opts.actor || 'system',
      );
      out.creditId = cn?.id || null;
    }
  }
  return out;
}
