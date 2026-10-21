/**
 * One-off backfill of `events/{id}.paidOrderCount` (2026-10-21, refunds.ts):
 * the number of PAID ticket orders (totalAmount > 0, kind 'event') that are
 * not refunded / disputed. markOrderPaid / markOrderReversed keep it from the
 * deploy on; events that sold tickets BEFORE the deploy have no value, so the
 * rule "no hard delete while paidOrderCount > 0" would not protect them
 * (refundTicketsOnEventCancelled still refunds a hard-deleted event that has
 * not ended, as a backstop).
 *
 * NOT RUN BY ANY DEPLOY. DRY-RUN BY DEFAULT: without --apply it only reads
 * and prints what it would write. Run AFTER the functions deploy (so new
 * sales are counted by the server from then on); it SETS the exact count from
 * the orders, so running it twice is harmless.
 *
 * Reads: ticket_orders where status == 'paid' (single-field index), paged by
 * document id. Writes: one merge per event whose count differs.
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-paid-order-count.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/backfill-paid-order-count.js [--apply]
 */
import * as admin from 'firebase-admin';

/** Paid, positive-amount event orders per event (pure). */
export function countPaidOrders(orders: Array<Record<string, any>>): Map<string, number> {
  const out = new Map<string, number>();
  for (const o of orders) {
    if (o.kind !== 'event' || o.status !== 'paid' || !(Number(o.totalAmount) > 0) || typeof o.listingId !== 'string') continue;
    out.set(o.listingId, (out.get(o.listingId) || 0) + 1);
  }
  return out;
}

async function main(): Promise<void> {
  const apply = process.argv.includes('--apply');
  if (!admin.apps.length) admin.initializeApp();
  const fs = admin.firestore();
  const orders: Array<Record<string, any>> = [];
  let cursor: admin.firestore.QueryDocumentSnapshot | null = null;
  for (;;) {
    let q = fs.collection('ticket_orders').where('status', '==', 'paid')
      .orderBy(admin.firestore.FieldPath.documentId()).limit(500);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.get();
    snap.docs.forEach((d) => orders.push(d.data()));
    if (snap.size < 500) break;
    cursor = snap.docs[snap.docs.length - 1];
  }
  const counts = countPaidOrders(orders);
  console.log(`${orders.length} paid orders, ${counts.size} events with paid orders`);
  let writes = 0;
  for (const [eventId, n] of counts) {
    const ref = fs.collection('events').doc(eventId);
    const ev = (await ref.get()).data();
    if (!ev) { console.log(`  ${eventId}: event missing (skipped)`); continue; }
    if (Number(ev.paidOrderCount) === n) continue;
    console.log(`  ${eventId}: paidOrderCount ${ev.paidOrderCount ?? '(none)'} -> ${n}`);
    if (apply) await ref.set({ paidOrderCount: n }, { merge: true });
    writes++;
  }
  console.log(apply ? `${writes} event(s) updated` : `DRY RUN: ${writes} event(s) would be updated (add --apply)`);
}

if (require.main === module) {
  main().catch((e) => { console.error(e); process.exit(1); });
}
