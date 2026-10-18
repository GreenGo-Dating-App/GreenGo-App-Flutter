/**
 * One-off backfill (Privacy Policy 8.3 / 8.4): delete the registration ID
 * photos ("a photo of yourself holding your ID document") and business owner
 * ID documents whose review is already DECIDED, plus orphans (no profile /
 * request, never submitted, superseded) older than 7 days, and clear the
 * stored references. Keeps only the minimal record (see
 * src/safety/verificationPhotoRetention.ts). Images still awaiting a review
 * are NEVER deleted.
 *
 * DRY RUN BY DEFAULT: prints counts only (no uid, no path).
 * Resumable: it re-lists Storage on every run (deleted images are simply not
 * there any more), so an interrupted run is resumed by running it again;
 * --start-after <objectName> skips ahead within the FIRST prefix only.
 *
 * Usage (from functions/, after `npm run build`):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/delete-reviewed-id-photos.ts
 *   GCLOUD_PROJECT=<project> STORAGE_BUCKET=<project>.appspot.com \
 *     node scripts/.out/delete-reviewed-id-photos.js [--apply] [--max-pages N] [--start-after NAME]
 */
import * as admin from 'firebase-admin';

const project = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || '';
const bucketName = process.env.STORAGE_BUCKET || (project ? `${project}.appspot.com` : '');
if (!admin.apps.length) admin.initializeApp({ projectId: project || undefined, storageBucket: bucketName || undefined });

// eslint-disable-next-line @typescript-eslint/no-var-requires
const retention = require('../../lib/safety/verificationPhotoRetention');
// eslint-disable-next-line @typescript-eslint/no-var-requires
const { ORPHAN_GRACE_MS } = require('../../lib/safety/verificationPhotoRetentionLogic');

function arg(name: string): string | null {
  const i = process.argv.indexOf(name);
  return i >= 0 && i + 1 < process.argv.length ? process.argv[i + 1] : null;
}

async function main() {
  const apply = process.argv.includes('--apply');
  const maxPages = Number(arg('--max-pages')) || 100000;
  const startAfter = arg('--start-after');
  if (!project || !bucketName) throw new Error('Set GCLOUD_PROJECT (and STORAGE_BUCKET if not <project>.appspot.com).');
  console.log(`project=${project} bucket=${bucketName} mode=${apply ? 'APPLY (deleting)' : 'dry run'}`);

  const fs = admin.firestore();
  const ports = retention.adminPorts(fs, admin.storage().bucket(bucketName));
  const opts = { nowMs: Date.now(), dryRun: !apply, decidedGraceMs: 0, orphanGraceMs: ORPHAN_GRACE_MS, maxPages, pageSize: 500 };
  const passes: Array<{ prefix: string; matchGlob?: string }> = [
    { prefix: 'verifications/' },
    { prefix: 'profiles/', matchGlob: 'profiles/*/verifications/**' }, // pre-P1-4 uploads
    { prefix: 'business_verification/' },
  ];
  const total = retention.emptyStats();
  for (let i = 0; i < passes.length; i++) {
    const s = retention.emptyStats();
    const cursor = await retention.sweepPrefix(ports, passes[i].prefix, i === 0 ? startAfter : null,
      { ...opts, matchGlob: passes[i].matchGlob }, s);
    console.log(`${passes[i].matchGlob ?? passes[i].prefix}: ${JSON.stringify(summary(s))}${cursor ? ` (stopped at page cap; resume with --start-after for this prefix)` : ''}`);
    for (const k of Object.keys(total)) (total as any)[k] += (s as any)[k];
  }
  const dangling = retention.emptyStats();
  await retention.sweepDanglingReferences(fs, ports, opts, dangling);
  console.log(`profiles_private references: ${JSON.stringify({ users: dangling.users, referencesCleared: dangling.danglingCleared })}`);
  console.log(`TOTAL ${JSON.stringify(summary(total))}`);
  if (!apply) console.log('Dry run: nothing was deleted. Re-run with --apply to delete.');
}

function summary(s: any) {
  return {
    objects: s.objects,
    decidedWithImage: s.decided,
    pendingKept: s.pending,
    orphans: s.orphan,
    notYetDue: s.notDue,
    deleted: s.deleted,
    failed: s.failed,
    referencesCleared: s.cleared,
  };
}

main().then(() => process.exit(0), (e) => { console.error(e); process.exit(1); });
