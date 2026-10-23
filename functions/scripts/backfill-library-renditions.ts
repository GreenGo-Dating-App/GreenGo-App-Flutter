/**
 * One-off backfill of the "My pictures" thumbnail + reduced copy
 * (library_renditions/{uid}/{itemId}_thumb.jpg / _1280.jpg) for approved
 * items recorded before the moderation trigger started writing them
 * (2026-10-23). Logic: src/safety/mediaLibrary.ts (makeRenditions).
 *
 * Only APPROVED items without a mediumUrl are touched; held / rejected items
 * never get copies. The item keeps its original `url`; the app shows
 * `thumbUrl` in the grid and reuses `mediumUrl`.
 *
 * DRY RUN BY DEFAULT: counts what would be written. Pass --apply to write.
 * Resumable by re-running: the source is re-queried every run and items that
 * already have a mediumUrl are skipped (no saved offset).
 *
 * Usage (from functions/, compile first; ts-node is not installed here):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-library-renditions.ts
 *   GCLOUD_PROJECT=greengo-chat node scripts/.out/scripts/backfill-library-renditions.js \
 *     [--apply] [--uid <uid>] [--concurrency 4]
 */
import * as admin from 'firebase-admin';
import {
  LIBRARY_ITEMS, MEDIA_LIBRARY, mediaLibraryDeps,
} from '../src/safety/mediaLibrary';

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

async function main() {
  if (!admin.apps.length) admin.initializeApp();
  const apply = process.argv.includes('--apply');
  const concurrency = Math.max(1, Number(arg('--concurrency') || 4));
  const db = admin.firestore();
  const owners = arg('--uid')
    ? [db.collection(MEDIA_LIBRARY).doc(arg('--uid')!)]
    : await db.collection(MEDIA_LIBRARY).listDocuments();
  const totals = { owners: owners.length, approved: 0, done: 0, todo: 0, written: 0, failed: 0 };

  for (const owner of owners) {
    const snap = await owner.collection(LIBRARY_ITEMS).where('status', '==', 'approved').get();
    const todo = snap.docs.filter((d) => {
      totals.approved++;
      const x = d.data();
      if (x.mediumUrl) { totals.done++; return false; }
      return typeof x.path === 'string' && typeof x.bucket === 'string';
    });
    totals.todo += todo.length;
    if (!apply) continue;
    for (let i = 0; i < todo.length; i += concurrency) {
      await Promise.all(todo.slice(i, i + concurrency).map(async (d) => {
        const x = d.data();
        try {
          const r = await mediaLibraryDeps.makeRenditions(x.bucket, x.path, owner.id);
          // The item may have been held or removed meanwhile: only fill it
          // while it is still the same approved generation.
          await db.runTransaction(async (t) => {
            const cur = (await t.get(d.ref)).data();
            if (!cur || cur.status !== 'approved' || String(cur.generation) !== String(x.generation)) {
              throw new Error('item changed');
            }
            t.update(d.ref, { ...r });
          });
          totals.written++;
        } catch (e) {
          totals.failed++;
          await mediaLibraryDeps.deleteRenditions(x.bucket, owner.id, d.id).catch(() => undefined);
          console.error(`failed ${d.ref.path}: ${(e as Error).message}`);
        }
      }));
    }
    console.log(`${owner.id}: ${todo.length} to do`);
  }
  console.log(`${apply ? 'APPLIED' : 'DRY RUN'}`, JSON.stringify(totals));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
