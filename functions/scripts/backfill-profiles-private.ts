/**
 * Backfill for the private profile split (audit C-07 / C-10, plan P1-4).
 *
 * For every profiles/{uid}: fills profiles_private/{uid} with the sensitive
 * fields it is still missing (never overwrites: a user on the new app writes
 * ONLY to private, so its public copy may be stale) and writes the public
 * coarse fields geohash5 / approxLocation / age where they differ.
 *
 * RESUMABLE BY RE-QUERYING THE SOURCE, not by a saved offset: every run scans
 * `profiles` in document-id order and recomputes each doc; docs that are
 * already correct are read but not written. An interrupted run is resumed by
 * running it again (from scratch is always correct). `--start-after <uid>`
 * only skips ahead to save reads; the last id is printed after each page.
 *
 * Run AFTER deploying mirrorPrivateProfileFields + syncCoarseFromPrivateProfile
 * (so nothing written during the scan is missed).
 *
 * Usage (from functions/, ts-node is not installed here, so compile first):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-profiles-private.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/backfill-profiles-private.js [--dry-run] \
 *     [--page-size 300] [--start-after <uid>] [--max-pages N]
 * Against the emulator: set FIRESTORE_EMULATOR_HOST instead of credentials.
 */
import * as admin from 'firebase-admin';
import { runPrivateProfileBackfill } from '../src/profiles/privateProfileTriggers';

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

async function main() {
  if (!admin.apps.length) admin.initializeApp();
  const dryRun = process.argv.includes('--dry-run');
  const started = Date.now();
  const r = await runPrivateProfileBackfill({
    dryRun,
    startAfter: arg('--start-after') ?? null,
    pageSize: arg('--page-size') ? Number(arg('--page-size')) : 300,
    maxPages: arg('--max-pages') ? Number(arg('--max-pages')) : undefined,
    onPage: (p) => console.log(
      `scanned=${p.scanned} privateWrites=${p.privateWrites} publicWrites=${p.publicWrites} lastId=${p.startAfter}`),
  });
  console.log(`${dryRun ? '[DRY RUN] ' : ''}done=${r.done} scanned=${r.scanned} ` +
    `privateWrites=${r.privateWrites} publicWrites=${r.publicWrites} ` +
    `${r.done ? '' : `continue with --start-after ${r.startAfter} `}(${Math.round((Date.now() - started) / 1000)} s)`);
}

main().catch((e) => { console.error(e); process.exit(1); });
