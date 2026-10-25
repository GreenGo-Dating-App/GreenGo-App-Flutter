/**
 * One-off backfill of the followed-store search / filter fields and place
 * facets (src/social/followStores.ts) for mirrors created before
 * onUserFollowCreated stamped them:
 *   user_business_following/{follower}/businesses/{store}
 *     .storeNameLower / .storeCategory / .storeCountry / .storeCityLower
 *   user_store_places/{follower}/countries|cities/{id}.n
 *
 * DRY-RUN BY DEFAULT (counts only); pass --apply to write. Run AFTER
 * onUserFollowCreated / onFollowStoreJob / onFollowedStoreRemoved /
 * mirrorPrivateProfileFields are deployed, so mirrors created, removed or
 * re-placed meanwhile are kept exact by them. Idempotent: each page is ONE
 * transaction that re-reads the mirrors and only writes values that differ
 * (facets move with the mirror fields, so a re-run never double-counts);
 * never creates a mirror.
 *
 * Pages the `businesses` collection group by document path (only
 * `user_business_following/{uid}/businesses` docs are touched; bounded:
 * --page <= 80 mirrors per transaction). Resumable: every page prints
 * `cursor=<path>`; re-run with `--start-after <path>`. The source is not
 * consumed, so a cursor is the correct resume point.
 *
 * PROJECT GUARD: `--project <id>` is required and must match any
 * GCLOUD_PROJECT / GOOGLE_CLOUD_PROJECT in the environment. Production
 * (`greengo-chat`) is refused unless `--production` is also passed.
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-store-fields.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json \
 *     node scripts/.out/scripts/backfill-store-fields.js --project greengo-chat-test \
 *     [--apply] [--start-after <path>] [--page 80] [--max-pages N]
 */
import * as admin from 'firebase-admin';
import {
  STORE_PAGE,
  StoreFieldValues,
  applyStoreFieldsPage,
  mirrorNeedsStoreFields,
} from '../src/social/followStores';

/* eslint-disable @typescript-eslint/no-explicit-any */

const PRODUCTION = 'greengo-chat';

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

/** The project to run against, or a reason to refuse. */
export function resolveProject(
  argv: string[],
  env: Record<string, string | undefined>,
): { project: string } | { refuse: string } {
  const i = argv.indexOf('--project');
  const project = i >= 0 ? (argv[i + 1] ?? '').trim() : '';
  if (!project || project.startsWith('--')) return { refuse: '--project <id> is required' };
  for (const v of ['GCLOUD_PROJECT', 'GOOGLE_CLOUD_PROJECT']) {
    if (env[v] && env[v] !== project) return { refuse: `env ${v}=${env[v]} differs from --project ${project}` };
  }
  if (project === PRODUCTION && !argv.includes('--production')) {
    return { refuse: `${PRODUCTION} is production: pass --production too` };
  }
  return { project };
}

export interface StoreBackfillResult {
  scanned: number;
  mirrorWrites: number;
  cursor: string | null;
  done: boolean;
}

export async function runStoreFieldsBackfill(opts: {
  db: admin.firestore.Firestore;
  fv: StoreFieldValues;
  apply: boolean;
  startAfter?: string;
  pageSize?: number;
  maxPages?: number;
  log?: (s: string) => void;
}): Promise<StoreBackfillResult> {
  const { db, apply } = opts;
  const pageSize = Math.max(1, Math.min(opts.pageSize ?? STORE_PAGE, STORE_PAGE));
  const log = opts.log ?? ((s: string) => console.log(s));
  const res: StoreBackfillResult = { scanned: 0, mirrorWrites: 0, cursor: opts.startAfter ?? null, done: false };
  // Small per-run cache: popular stores appear on many pages.
  const profiles = new Map<string, Record<string, any> | null>();

  for (let pages = 0; opts.maxPages === undefined || pages < opts.maxPages; pages++) {
    let q = db.collectionGroup('businesses').orderBy(admin.firestore.FieldPath.documentId()).limit(pageSize);
    if (res.cursor) q = q.startAfter(res.cursor);
    const page = await q.get();
    if (page.empty) {
      res.done = true;
      break;
    }
    res.scanned += page.size;

    const mirrors = page.docs.filter((d) => d.ref.parent.parent?.parent.id === 'user_business_following');
    const need = [...new Set(mirrors.map((d) => d.id))].filter((id) => !profiles.has(id));
    if (need.length) {
      const snaps = await db.getAll(...need.map((id) => db.collection('profiles').doc(id)));
      snaps.forEach((s) => profiles.set(s.id, s.exists ? (s.data() as Record<string, any>) : null));
    }
    const rows = mirrors
      .map((d) => ({ followerId: d.ref.parent.parent!.id, followeeId: d.id, followee: profiles.get(d.id) ?? null, data: d.data() }))
      .filter((r) => mirrorNeedsStoreFields(r.data, r.followee));
    if (apply) {
      res.mirrorWrites += await applyStoreFieldsPage(db, opts.fv, rows);
    } else {
      res.mirrorWrites += rows.length;
    }
    if (profiles.size > 20000) profiles.clear();

    res.cursor = page.docs[page.docs.length - 1].ref.path;
    log(`page=${pages + 1} scanned=${res.scanned} mirrorWrites=${res.mirrorWrites} cursor=${res.cursor}`);
    if (page.size < pageSize) {
      res.done = true;
      break;
    }
  }
  return res;
}

async function main() {
  const p = resolveProject(process.argv, process.env);
  if ('refuse' in p) {
    console.error(`REFUSING: ${p.refuse}`);
    process.exit(2);
  }
  if (!admin.apps.length) admin.initializeApp({ projectId: p.project });
  const apply = process.argv.includes('--apply');
  const page = arg('--page');
  const maxPages = arg('--max-pages');
  const FieldValue = admin.firestore.FieldValue;
  const r = await runStoreFieldsBackfill({
    db: admin.firestore(),
    fv: { increment: (n) => FieldValue.increment(n), delete: () => FieldValue.delete() },
    apply,
    startAfter: arg('--start-after'),
    pageSize: page ? Number(page) : undefined,
    maxPages: maxPages ? Number(maxPages) : undefined,
  });
  console.log(`[${p.project}] ${apply ? 'APPLIED' : '[DRY RUN - pass --apply to write]'} scanned=${r.scanned} ` +
    `mirrorWrites=${r.mirrorWrites} done=${r.done} cursor=${r.cursor}`);
  if (!r.done) console.log(`Resume with: --start-after ${r.cursor}`);
}

if (require.main === module) main().catch((e) => { console.error(e); process.exit(1); });
