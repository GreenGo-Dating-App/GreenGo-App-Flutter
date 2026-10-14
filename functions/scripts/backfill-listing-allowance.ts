/**
 * One-off backfill for "plan dropped -> listings over the allowance are
 * hidden" (owner rule 2026-10-14). DRY-RUN BY DEFAULT. Idempotent.
 *
 * onProfileListingAllowanceChanged only reacts to FUTURE plan changes. Hosts
 * whose plan already dropped before it was deployed (e.g. an ex-Gold now on
 * Base with 7 published experiences, or anyone with more active listings
 * than the new caps: Base 1, Silver 5, Gold 10, no plan 0) are brought in
 * line here by running the same reconcileListings() for every host that has
 * an ongoing event or any experience.
 *
 * Run AFTER the functions (onProfileListingAllowanceChanged,
 * onEventWrittenUsage) and the rules are deployed. The dry run prints how
 * many listings WOULD be hidden / restored per host - review it with the
 * owner before --apply (hiding is reversible: upgrading restores them).
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-listing-allowance.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/backfill-listing-allowance.js [--apply]
 */
import * as admin from 'firebase-admin';

if (!admin.apps.length) admin.initializeApp();

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { reconcileListings } = require('../src/entitlements/downgrade');

const PAGE = 500;

async function main() {
  const db = admin.firestore();
  const apply = process.argv.includes('--apply');
  const hosts = new Set<string>();
  const add = (v: unknown) => {
    if (typeof v === 'string' && v && !v.includes('/')) hosts.add(v);
  };

  // ---- organizers of ongoing events
  let last: admin.firestore.QueryDocumentSnapshot | undefined;
  for (;;) {
    let q = db.collection('events')
      .where('endDate', '>', admin.firestore.Timestamp.now())
      .orderBy('endDate')
      .select('organizerId')
      .limit(PAGE);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    for (const d of snap.docs) add(d.get('organizerId'));
    if (snap.size < PAGE) break;
    last = snap.docs[snap.docs.length - 1];
  }

  // ---- experience hosts
  last = undefined;
  for (;;) {
    let q = db.collection('user_experiences')
      .orderBy(admin.firestore.FieldPath.documentId())
      .select('hostId')
      .limit(PAGE);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    for (const d of snap.docs) add(d.get('hostId'));
    if (snap.size < PAGE) break;
    last = snap.docs[snap.docs.length - 1];
  }

  const total = { hosts: hosts.size, changedHosts: 0, eventsHidden: 0, eventsRestored: 0, experiencesHidden: 0, experiencesRestored: 0 };
  for (const uid of hosts) {
    const r = await reconcileListings(uid, { dryRun: !apply });
    const changed = r.eventsHidden + r.eventsRestored + r.experiencesHidden + r.experiencesRestored;
    if (!changed) continue;
    total.changedHosts++;
    total.eventsHidden += r.eventsHidden;
    total.eventsRestored += r.eventsRestored;
    total.experiencesHidden += r.experiencesHidden;
    total.experiencesRestored += r.experiencesRestored;
    console.log(`${uid} ${JSON.stringify(r)}`);
  }
  console.log(`${apply ? 'APPLIED' : '[DRY RUN - pass --apply to write]'} ${JSON.stringify(total)}`);
}

if (require.main === module) main().catch((e) => { console.error(e); process.exit(1); });
