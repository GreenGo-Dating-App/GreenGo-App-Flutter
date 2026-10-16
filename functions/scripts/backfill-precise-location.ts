/**
 * One-off backfill for `preciseLocation` (owner rule 2026-10-16: with globe
 * discoverability 'exact', others see position and distance accurate to
 * about 100 m). Computes the field for every profiles/{uid} whose
 * globeDiscoverability is ALREADY 'exact'; afterwards the triggers
 * mirrorPrivateProfileFields / syncCoarseFromPrivateProfile keep it in step.
 *
 * DRY RUN BY DEFAULT: counts what would be written. Pass --apply to write.
 *
 * Resumable by re-querying the source (equality query on
 * globeDiscoverability, document-id order): an interrupted run is resumed by
 * running it again; already-correct docs are read but not written.
 * `--start-after <uid>` only skips ahead to save reads.
 *
 * Run AFTER deploying mirrorPrivateProfileFields + syncCoarseFromPrivateProfile.
 *
 * Usage (from functions/, compile first; ts-node is not installed here):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-precise-location.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/backfill-precise-location.js [--apply] \
 *     [--page-size 300] [--start-after <uid>] [--max-pages N]
 * Against the emulator: set FIRESTORE_EMULATOR_HOST instead of credentials.
 */
import * as admin from 'firebase-admin';
import { runPreciseLocationBackfill } from '../src/profiles/privateProfileTriggers';

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

async function main() {
  if (!admin.apps.length) admin.initializeApp();
  const dryRun = !process.argv.includes('--apply');
  const started = Date.now();
  const r = await runPreciseLocationBackfill({
    dryRun,
    startAfter: arg('--start-after') ?? null,
    pageSize: arg('--page-size') ? Number(arg('--page-size')) : 300,
    maxPages: arg('--max-pages') ? Number(arg('--max-pages')) : undefined,
    onPage: (p) => console.log(`scanned=${p.scanned} publicWrites=${p.publicWrites} lastId=${p.startAfter}`),
  });
  console.log(`${dryRun ? '[DRY RUN - pass --apply to write] ' : ''}done=${r.done} scanned=${r.scanned} ` +
    `publicWrites=${r.publicWrites} ` +
    `${r.done ? '' : `continue with --start-after ${r.startAfter} `}(${Math.round((Date.now() - started) / 1000)} s)`);
}

main().catch((e) => { console.error(e); process.exit(1); });
