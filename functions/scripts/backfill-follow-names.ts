/**
 * One-off backfill of the searchable follow-edge names (src/social/followNames.ts)
 * for edges created before onUserFollowCreated stamped them:
 *   business_followers/{followee}/followers/{follower}.followerNameLower
 *   user_business_following/{follower}/businesses/{followee}.followeeNameLower
 *
 * DRY-RUN BY DEFAULT (counts only); pass --apply to write. Run AFTER
 * onUserFollowCreated / onFollowNameJob / mirrorPrivateProfileFields are
 * deployed, so edges created or renamed meanwhile are kept fresh by them.
 * Idempotent (only writes values that differ; never creates a doc).
 *
 * Pages the `followers` collection group by document path (bounded: --page
 * edges per batch, <= 2 writes each). Resumable: every page prints
 * `cursor=<path>`; re-run with `--start-after <path>` to continue. The source
 * is not consumed, so a cursor is the correct resume point.
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-follow-names.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/backfill-follow-names.js [--apply] [--start-after <path>] [--page 200] [--max-pages N]
 */
import * as admin from 'firebase-admin';
import {
  FOLLOWEE_NAME_FIELD,
  FOLLOWER_NAME_FIELD,
  profileFollowName,
} from '../src/social/followNames';

/* eslint-disable @typescript-eslint/no-explicit-any */

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

export interface BackfillResult {
  scanned: number;
  edgeWrites: number;
  mirrorWrites: number;
  cursor: string | null;
  done: boolean;
}

export async function runFollowNameBackfill(opts: {
  db: admin.firestore.Firestore;
  apply: boolean;
  startAfter?: string;
  pageSize?: number;
  maxPages?: number;
  log?: (s: string) => void;
}): Promise<BackfillResult> {
  const { db, apply } = opts;
  const pageSize = Math.max(1, Math.min(opts.pageSize ?? 200, 240));
  const log = opts.log ?? ((s: string) => console.log(s));
  const res: BackfillResult = { scanned: 0, edgeWrites: 0, mirrorWrites: 0, cursor: opts.startAfter ?? null, done: false };
  // Small per-run cache: popular followees appear on many pages.
  const names = new Map<string, string>();

  for (let pages = 0; opts.maxPages === undefined || pages < opts.maxPages; pages++) {
    let q = db.collectionGroup('followers').orderBy(admin.firestore.FieldPath.documentId()).limit(pageSize);
    if (res.cursor) q = q.startAfter(res.cursor);
    const page = await q.get();
    if (page.empty) {
      res.done = true;
      break;
    }
    res.scanned += page.size;

    const edges = page.docs.filter((d) => d.ref.parent.parent?.parent.id === 'business_followers');
    const need = new Set<string>();
    for (const d of edges) {
      for (const id of [d.id, d.ref.parent.parent!.id]) if (!names.has(id)) need.add(id);
    }
    if (need.size) {
      const snaps = await db.getAll(...[...need].map((id) => db.collection('profiles').doc(id)));
      snaps.forEach((s) => names.set(s.id, profileFollowName(s.exists ? s.data() : undefined)));
    }
    const mirrors = edges.length
      ? await db.getAll(...edges.map((d) =>
        db.collection('user_business_following').doc(d.id).collection('businesses').doc(d.ref.parent.parent!.id)))
      : [];

    const batch = db.batch();
    let writes = 0;
    edges.forEach((d, i) => {
      const followerName = names.get(d.id) ?? '';
      const followeeName = names.get(d.ref.parent.parent!.id) ?? '';
      if (d.get(FOLLOWER_NAME_FIELD) !== followerName) {
        batch.update(d.ref, { [FOLLOWER_NAME_FIELD]: followerName });
        res.edgeWrites++;
        writes++;
      }
      const m = mirrors[i];
      if (m.exists && m.get(FOLLOWEE_NAME_FIELD) !== followeeName) {
        batch.update(m.ref, { [FOLLOWEE_NAME_FIELD]: followeeName });
        res.mirrorWrites++;
        writes++;
      }
    });
    if (apply && writes > 0) await batch.commit();
    if (names.size > 20000) names.clear();

    res.cursor = page.docs[page.docs.length - 1].ref.path;
    log(`page=${pages + 1} scanned=${res.scanned} edgeWrites=${res.edgeWrites} mirrorWrites=${res.mirrorWrites} cursor=${res.cursor}`);
    if (page.size < pageSize) {
      res.done = true;
      break;
    }
  }
  return res;
}

async function main() {
  if (!admin.apps.length) admin.initializeApp();
  const apply = process.argv.includes('--apply');
  const page = arg('--page');
  const maxPages = arg('--max-pages');
  const r = await runFollowNameBackfill({
    db: admin.firestore(),
    apply,
    startAfter: arg('--start-after'),
    pageSize: page ? Number(page) : undefined,
    maxPages: maxPages ? Number(maxPages) : undefined,
  });
  console.log(`${apply ? 'APPLIED' : '[DRY RUN - pass --apply to write]'} scanned=${r.scanned} ` +
    `edgeWrites=${r.edgeWrites} mirrorWrites=${r.mirrorWrites} done=${r.done} cursor=${r.cursor}`);
  if (!r.done) console.log(`Resume with: --start-after ${r.cursor}`);
}

if (require.main === module) main().catch((e) => { console.error(e); process.exit(1); });
