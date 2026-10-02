#!/usr/bin/env node
/**
 * Backfill external_events/{id}.hasImage — true when the doc's imageUrl is a
 * usable picture (non-empty absolute http(s) URL, not a placeholder
 * generator). Runs the SAME predicate the ingesters stamp on new docs
 * (functions/src/external_events/image.ts → isUsableImageUrl), which mirrors
 * the app's client-side rule (lib/core/utils/display_image.dart).
 *
 * The app does NOT read this field yet (its client-side predicate is the
 * source of truth); it only makes a future server-side
 * `where('hasImage', '==', true)` possible once every doc carries it.
 *
 * Idempotent and safe to re-run: it rescans and only writes docs whose stored
 * hasImage is missing/wrong. No offset is saved anywhere; an interrupted run is
 * finished by simply running it again.
 *
 * Usage (from the repo root):
 *   cd functions && npm run build && cd ..
 *   set GOOGLE_APPLICATION_CREDENTIALS=<path to service-account.json>   (PowerShell: $env:GOOGLE_APPLICATION_CREDENTIALS="...")
 *   node scripts/backfill_external_events_has_image.js --project <projectId> [--source ticketmaster] [--dry-run] [--page-size 400]
 *
 * On this PC the corporate TLS proxy may require NODE_TLS_REJECT_UNAUTHORIZED=0.
 */

const path = require('path');

function arg(name, fallback) {
  const i = process.argv.indexOf(name);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}

const projectId = arg('--project', process.env.GCLOUD_PROJECT);
if (!projectId) {
  console.error('Missing --project <projectId>');
  process.exit(1);
}
process.env.GCLOUD_PROJECT = projectId;
process.env.GOOGLE_CLOUD_PROJECT = projectId;

const functionsDir = path.join(__dirname, '..', 'functions');
const admin = require(path.join(functionsDir, 'node_modules', 'firebase-admin'));
if (!admin.apps.length) admin.initializeApp({ projectId });

const { isUsableImageUrl } = require(
  path.join(functionsDir, 'lib', 'external_events', 'image.js'),
);

(async () => {
  const dryRun = process.argv.includes('--dry-run');
  const pageSize = Math.min(Math.max(Number(arg('--page-size', '400')), 1), 500);
  const source = arg('--source', null);
  const db = admin.firestore();
  const total = { scanned: 0, updated: 0, withImage: 0, withoutImage: 0 };
  let cursor = null;
  for (;;) {
    let q = db.collection('external_events');
    if (source) q = q.where('source', '==', source);
    q = q.orderBy(admin.firestore.FieldPath.documentId()).limit(pageSize);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.get();
    if (snap.empty) break;

    const batch = db.batch();
    let ops = 0;
    for (const doc of snap.docs) {
      const data = doc.data();
      const want = isUsableImageUrl(data.imageUrl);
      if (want) total.withImage++;
      else total.withoutImage++;
      if (data.hasImage !== want) {
        batch.update(doc.ref, { hasImage: want });
        ops++;
      }
    }
    if (ops > 0 && !dryRun) await batch.commit();
    total.scanned += snap.size;
    total.updated += ops;
    console.log(
      `scanned ${total.scanned}, ${dryRun ? 'would update' : 'updated'} ${total.updated} ` +
        `(with image ${total.withImage}, without ${total.withoutImage})`,
    );
    cursor = snap.docs[snap.docs.length - 1];
    if (snap.size < pageSize) break;
  }
  console.log('Done.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
