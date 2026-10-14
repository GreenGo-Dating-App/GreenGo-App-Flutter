/**
 * One-off cleanup: personal payment links are no longer accepted (owner rule
 * 2026-10-14). The app no longer shows or edits them and the rules refuse
 * new values; this removes the data that is left:
 *   profiles/{uid}           paymentLinks, paymentLinksExpireAt
 *   profiles_private/{uid}   paymentLinksHidden, paymentLinksHiddenAt
 * (the old visibility hook moved a lapsed tier's links to the private doc).
 *
 * NOT RUN BY ANY DEPLOY. DRY-RUN BY DEFAULT: without --apply it only runs READ
 * queries and prints counts; no write API is reachable without the flag.
 *
 * Do NOT run while a legacy link ticket order or link experience booking is
 * still open (ticket_orders status pending_payment / awaiting_confirmation
 * with provider 'link'): createTicketCheckout reads the organizer's
 * paymentLinks to snapshot the method for a legacy experience booking. Check
 * first (read-only):
 *   ticket_orders where provider == 'link' and status in
 *   ['pending_payment', 'awaiting_confirmation']
 * The script prints that count and refuses --apply while it is > 0 unless
 * --ignore-open-link-orders is given.
 *
 * Candidates come from indexed queries (one range query per provider key on
 * the map subfields, automatic single-field indexes), never a scan of every
 * profile. Each pass re-queries the SOURCE (the queries consume themselves
 * once applied), so an interrupted run is resumed by simply running again.
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/clear-payment-links.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/clear-payment-links.js [--apply] [--page-size 300]
 */
import * as admin from 'firebase-admin';

/** PaymentMethod keys the app used to write (lib/.../payment_links.dart, removed). */
export const PAYMENT_LINK_KEYS = ['pix', 'mercadoPago', 'picPay', 'paypal', 'venmo', 'cashApp',
  'revolut', 'wise', 'monzo', 'kofi', 'stripe'] as const;

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

/** Doc ids of [collection] with any non-empty `<mapField>.<key>`, plus docs carrying [markerField]. */
export async function findCandidates(
  fs: admin.firestore.Firestore,
  collection: string,
  mapField: string,
  markerField: string,
  pageSize: number,
): Promise<Set<string>> {
  const ids = new Set<string>();
  const fields = [...PAYMENT_LINK_KEYS.map((k) => `${mapField}.${k}`)];
  for (const field of fields) {
    let cursor: admin.firestore.QueryDocumentSnapshot | null = null;
    for (;;) {
      let q = fs.collection(collection).where(field, '>', '').orderBy(field).limit(pageSize);
      if (cursor) q = q.startAfter(cursor);
      const snap = await q.get();
      snap.docs.forEach((d) => ids.add(d.id));
      if (snap.size < pageSize) break;
      cursor = snap.docs[snap.docs.length - 1];
    }
  }
  // orderBy on a field only returns docs that have it (timestamps, any value).
  let cursor: admin.firestore.QueryDocumentSnapshot | null = null;
  for (;;) {
    let q = fs.collection(collection).orderBy(markerField).limit(pageSize);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.get();
    snap.docs.forEach((d) => ids.add(d.id));
    if (snap.size < pageSize) break;
    cursor = snap.docs[snap.docs.length - 1];
  }
  return ids;
}

export async function openLinkOrders(fs: admin.firestore.Firestore): Promise<number> {
  const snap = await fs.collection('ticket_orders')
    .where('provider', '==', 'link')
    .where('status', 'in', ['pending_payment', 'awaiting_confirmation'])
    .count().get();
  return snap.data().count;
}

export async function run(fs: admin.firestore.Firestore, apply: boolean, pageSize = 300, ignoreOpen = false) {
  const open = await openLinkOrders(fs);
  const pub = await findCandidates(fs, 'profiles', 'paymentLinks', 'paymentLinksExpireAt', pageSize);
  const priv = await findCandidates(fs, 'profiles_private', 'paymentLinksHidden', 'paymentLinksHiddenAt', pageSize);
  const counts = {
    mode: apply ? 'APPLY' : 'DRY-RUN',
    openLinkOrders: open,
    publicProfiles: pub.size,
    privateProfiles: priv.size,
    cleared: { public: 0, private: 0, failed: 0 },
  };
  if (!apply) return counts;
  if (open > 0 && !ignoreOpen) {
    throw new Error(`${open} legacy link order(s) still open: wait for them to close or pass --ignore-open-link-orders`);
  }
  const del = admin.firestore.FieldValue.delete();
  const jobs: Array<[string, string, Record<string, unknown>]> = [
    ...[...pub].map((id) => ['profiles', id, { paymentLinks: del, paymentLinksExpireAt: del }] as [string, string, Record<string, unknown>]),
    ...[...priv].map((id) => ['profiles_private', id, { paymentLinksHidden: del, paymentLinksHiddenAt: del }] as [string, string, Record<string, unknown>]),
  ];
  for (let i = 0; i < jobs.length; i += 400) {
    const batch = fs.batch();
    const slice = jobs.slice(i, i + 400);
    for (const [col, id, patch] of slice) batch.update(fs.collection(col).doc(id), patch);
    try {
      await batch.commit();
      for (const [col] of slice) {
        if (col === 'profiles') counts.cleared.public++;
        else counts.cleared.private++;
      }
    } catch (e: any) {
      counts.cleared.failed += slice.length;
      console.error(`batch ${i / 400} failed: ${e?.message || e}`);
    }
  }
  return counts;
}

if (require.main === module) {
  const apply = process.argv.includes('--apply');
  const ignoreOpen = process.argv.includes('--ignore-open-link-orders');
  const pageSize = Math.min(Number(arg('--page-size') || 300), 500);
  if (!admin.apps.length) admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'greengo-chat' });
  run(admin.firestore(), apply, pageSize, ignoreOpen)
    .then((c) => {
      console.log(JSON.stringify(c, null, 2));
      process.exit(0);
    })
    .catch((e) => {
      console.error(e);
      process.exit(1);
    });
}
