#!/usr/bin/env node
/**
 * Backfill profiles/{uid}.geohash (discoverable location) for nearest-first
 * Discovery / Explore Map queries. Runs the SAME logic as the admin callable
 * `backfillProfileGeohash` (functions/src/discovery/profileGeohash.ts), but
 * with a service account, looping until the whole collection is scanned.
 *
 * Idempotent and safe to re-run: it rescans and only writes docs whose stored
 * geohash is missing/wrong. No offset is saved anywhere; an interrupted run is
 * finished by simply running it again.
 *
 * Usage (from the repo root):
 *   cd functions && npm run build && cd ..
 *   set GOOGLE_APPLICATION_CREDENTIALS=<path to service-account.json>   (PowerShell: $env:GOOGLE_APPLICATION_CREDENTIALS="...")
 *   node scripts/backfill_profile_geohash.js --project <projectId> [--dry-run] [--page-size 400]
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

const { runProfileGeohashBackfill } = require(
  path.join(functionsDir, 'lib', 'discovery', 'profileGeohash.js'),
);

(async () => {
  const dryRun = process.argv.includes('--dry-run');
  const pageSize = Number(arg('--page-size', '400'));
  const total = { scanned: 0, updated: 0, cleared: 0 };
  let startAfter = null;
  for (;;) {
    const r = await runProfileGeohashBackfill({ startAfter, pageSize, dryRun, maxPages: 25 });
    total.scanned += r.scanned;
    total.updated += r.updated;
    total.cleared += r.cleared;
    console.log(
      `scanned ${total.scanned}, updated ${total.updated}, cleared ${total.cleared}` +
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
