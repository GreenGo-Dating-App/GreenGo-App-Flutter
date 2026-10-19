/**
 * One-off backfill for `profiles/{uid}.businessGeohash` (owner rule
 * 2026-10-19: Discover finds businesses by their BUSINESS ADDRESS). Fills the
 * field for every business written before the triggers
 * mirrorPrivateProfileFields / syncCoarseFromPrivateProfile maintained it,
 * and removes it from former businesses. Logic: src/profiles/businessGeohash.ts.
 *
 * DRY RUN BY DEFAULT: counts what would be written. Pass --apply to write.
 *
 * Idempotent and resumable by re-querying the source (isBusiness == true,
 * then businessGeohash >= '', document-id order): an interrupted run is
 * resumed by running it again; already-correct docs are read but not written.
 * Each write is a per-doc transaction touching ONLY businessGeohash.
 *
 * Run AFTER deploying mirrorPrivateProfileFields + syncCoarseFromPrivateProfile
 * and after the profiles(isBusiness, businessGeohash) index is built.
 *
 * Usage (from functions/, compile first; ts-node is not installed here):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-business-geohash.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/backfill-business-geohash.js [--apply] \
 *     [--page-size 300] [--max-pages N] [--concurrency 10]
 * Against the emulator: set FIRESTORE_EMULATOR_HOST instead of credentials.
 */
import * as admin from 'firebase-admin';
import { runBusinessGeohashBackfill } from '../src/profiles/businessGeohash';

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

async function main() {
  if (!admin.apps.length) admin.initializeApp();
  const dryRun = !process.argv.includes('--apply');
  const started = Date.now();
  const r = await runBusinessGeohashBackfill({
    dryRun,
    pageSize: arg('--page-size') ? Number(arg('--page-size')) : 300,
    maxPages: arg('--max-pages') ? Number(arg('--max-pages')) : undefined,
    concurrency: arg('--concurrency') ? Number(arg('--concurrency')) : 10,
    onPage: (pass, p, lastId) =>
      console.log(`pass=${pass} scanned=${p.scanned} set=${p.set} cleared=${p.cleared} lastId=${lastId}`),
  });
  console.log(`${dryRun ? '[DRY RUN - pass --apply to write] ' : ''}done=${r.done} scanned=${r.scanned} ` +
    `set=${r.set} cleared=${r.cleared} ` +
    `${r.done ? '' : '(stopped at --max-pages; run again to continue) '}` +
    `(${Math.round((Date.now() - started) / 1000)} s)`);
}

main().catch((e) => { console.error(e); process.exit(1); });
