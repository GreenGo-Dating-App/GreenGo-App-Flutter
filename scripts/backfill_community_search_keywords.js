#!/usr/bin/env node
/**
 * Backfill communities/{id}.searchKeywords (server-side community search).
 * Runs the SAME logic as the Cloud Function module
 * functions/src/communities/searchKeywords.ts (runCommunitySearchKeywordsBackfill)
 * with a service account, looping until the whole collection is scanned.
 *
 * Idempotent and safe to re-run: it rescans every community and only writes
 * docs whose keywords are missing or stale (e.g. renamed by an old app
 * version). No offset is saved anywhere; an interrupted run is finished by
 * simply running it again.
 *
 * Usage (from the repo root):
 *   cd functions && npm run build && cd ..
 *   set GOOGLE_APPLICATION_CREDENTIALS=<path to service-account.json>   (PowerShell: $env:GOOGLE_APPLICATION_CREDENTIALS="...")
 *   node scripts/backfill_community_search_keywords.js --project <projectId> [--dry-run] [--page-size 400]
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

const { runCommunitySearchKeywordsBackfill } = require(
  path.join(functionsDir, 'lib', 'communities', 'searchKeywords.js'),
);

(async () => {
  const dryRun = process.argv.includes('--dry-run');
  const pageSize = Number(arg('--page-size', '400'));
  const total = { scanned: 0, updated: 0 };
  let startAfter = null;
  for (;;) {
    const r = await runCommunitySearchKeywordsBackfill({
      startAfter,
      pageSize,
      dryRun,
      maxPages: 25,
      firestore: admin.firestore(),
    });
    total.scanned += r.scanned;
    total.updated += r.updated;
    console.log(
      `scanned ${total.scanned}, ${dryRun ? 'would update' : 'updated'} ${total.updated}` +
        (dryRun ? ' (dry run)' : ''),
    );
    if (r.done) break;
    startAfter = r.startAfter;
  }
  console.log('Done.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
