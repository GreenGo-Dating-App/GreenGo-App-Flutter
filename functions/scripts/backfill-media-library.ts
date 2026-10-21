/**
 * One-off backfill of "My pictures" (media_library/{uid}/items/{itemId}) for
 * images uploaded BEFORE moderateUploadedImage started recording the library
 * (2026-10-21). Logic and owner rules: src/safety/mediaLibrary.ts.
 *
 * WHAT COUNTS AS APPROVED: every image object still at its original path
 * under profiles/, communities/, chat_images/, group_media/. Held images
 * were moved to quarantine/ (and hash-list blocks to safety_holds/), so what
 * is left in place passed moderation - or predates it (uploads before the
 * Storage trigger existed were never checked; they are already live where
 * they are, the library only makes them reusable).
 * Skipped: private-album uploads (visibility=private), voice/video/
 * verification folders, chat images without uploaderId, non-images.
 * width/height/hasFace are left null (no download per object); the face rule
 * computes hasFace on demand when a picture becomes a main photo.
 *
 * DRY RUN BY DEFAULT: counts what would be written. Pass --apply to write.
 * Idempotent: an existing item is never overwritten. Resumable: the source
 * (the bucket listing) is not consumed, each page prints its nextPageToken;
 * re-run with --page-token <token> (or simply from the start: existing items
 * are skipped).
 *
 * Usage (from functions/, compile first; ts-node is not installed here):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-media-library.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/backfill-media-library.js [--apply] \
 *     [--prefix profiles/] [--page-size 500] [--max-pages N] [--page-token T] \
 *     [--bucket greengo-chat.appspot.com]
 * Against the emulators: set FIRESTORE_EMULATOR_HOST / FIREBASE_STORAGE_EMULATOR_HOST.
 */
import * as admin from 'firebase-admin';
import {
  downloadUrlFor, firstToken, libraryItemId, libraryTarget, LIBRARY_ITEMS, MEDIA_LIBRARY,
} from '../src/safety/mediaLibrary';

const PREFIXES = ['profiles/', 'communities/', 'chat_images/', 'group_media/'];
const IMAGE = /\.(jpe?g|png|webp|heic|heif|bmp|gif)$/i;

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

async function main() {
  if (!admin.apps.length) admin.initializeApp();
  const dryRun = !process.argv.includes('--apply');
  const bucket = arg('--bucket') ? admin.storage().bucket(arg('--bucket')) : admin.storage().bucket();
  const prefixes = arg('--prefix') ? [arg('--prefix')!] : PREFIXES;
  const pageSize = Number(arg('--page-size') || 500);
  const maxPages = arg('--max-pages') ? Number(arg('--max-pages')) : Infinity;
  const db = admin.firestore();
  const writer = dryRun ? null : db.bulkWriter();
  const totals = { scanned: 0, eligible: 0, existing: 0, written: 0, skipped: 0 };
  let pages = 0;

  for (const prefix of prefixes) {
    let pageToken: string | undefined = prefix === prefixes[0] ? arg('--page-token') : undefined;
    do {
      if (pages >= maxPages) break;
      const [files, next] = await bucket.getFiles({ prefix, maxResults: pageSize, pageToken, autoPaginate: false });
      pages++;
      const refs: Array<{ ref: FirebaseFirestore.DocumentReference; data: Record<string, unknown> }> = [];
      for (const f of files) {
        totals.scanned++;
        const md = f.metadata as Record<string, any>;
        const path = f.name;
        const contentType = String(md.contentType || '');
        if (!contentType.startsWith('image/') && !IMAGE.test(path)) { totals.skipped++; continue; }
        if (/\/(voice|chat_voice|chat_videos|verifications)\//.test('/' + path)) { totals.skipped++; continue; }
        const custom = (md.metadata || {}) as Record<string, string>;
        const target = libraryTarget(path, custom);
        const token = firstToken(custom);
        if (!target || !token) { totals.skipped++; continue; }
        totals.eligible++;
        const created = admin.firestore.Timestamp.fromDate(new Date(md.timeCreated || Date.now()));
        refs.push({
          ref: db.collection(MEDIA_LIBRARY).doc(target.uid).collection(LIBRARY_ITEMS).doc(libraryItemId(path)),
          data: {
            path, bucket: bucket.name, usage: target.usage, contentType: contentType || null,
            generation: String(md.generation ?? '0'), status: 'approved', reasons: [], reasonCode: null,
            url: downloadUrlFor(bucket.name, path, token), thumbUrl: null, width: null, height: null,
            hasFace: null, reviewable: false, createdAt: created, approvedAt: created,
            updatedAt: admin.firestore.Timestamp.now(), backfilled: true,
          },
        });
      }
      // Existing items are never touched (one batched read per page).
      const snaps = refs.length ? await db.getAll(...refs.map((r) => r.ref)) : [];
      snaps.forEach((s, i) => {
        if (s.exists) { totals.existing++; return; }
        totals.written++;
        if (writer) writer.create(refs[i].ref, refs[i].data).catch((e) => {
          if (e?.code !== 6) console.error(`write failed ${refs[i].ref.path}:`, e?.message || e);
        });
      });
      if (writer) await writer.flush();
      pageToken = (next as { pageToken?: string } | null)?.pageToken;
      console.log(`prefix=${prefix} page=${pages} scanned=${totals.scanned} eligible=${totals.eligible} ` +
        `existing=${totals.existing} ${dryRun ? 'wouldWrite' : 'written'}=${totals.written} nextPageToken=${pageToken ?? '-'}`);
    } while (pageToken);
  }
  if (writer) await writer.close();
  console.log(`${dryRun ? '[DRY RUN - pass --apply to write] ' : ''}${JSON.stringify(totals)}` +
    (pages >= maxPages ? ' (stopped at --max-pages; re-run with the last nextPageToken)' : ''));
}

main().catch((e) => { console.error(e); process.exit(1); });
