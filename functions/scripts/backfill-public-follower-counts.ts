/**
 * One-off backfill of the PUBLIC follower count (owner decision 2026-10-19:
 * the NUMBER of followers of every user and business is public; who follows,
 * following and stores counts stay private):
 *
 *   follow_counts/{uid}.followersCount  ->  follower_counts_public/{uid}
 *                                          { followersCount, updatedAt }
 *
 * DRY-RUN BY DEFAULT (counts only); pass --apply to write.
 *
 * RUN ORDER: deploy onUserFollowCreated + onUserFollowDeleted first (from
 * then on every follow / unfollow moves both docs in one transaction), then
 * the rules, then run this with --apply. Each account is copied inside a
 * transaction that READS follow_counts/{uid}, so a follow landing mid-run is
 * either fully before (copied) or retries the transaction - the two docs
 * never end up disagreeing.
 *
 * Idempotent: writes only when the public value differs (a 0 count with no
 * public doc writes nothing - a missing doc reads as 0). Never writes
 * following / stores. Pages follow_counts by document id (bounded: --page
 * docs per page, 10 transactions in flight). Resumable: every page prints
 * `cursor=<uid>`; re-run with `--start-after <uid>` to continue (the source
 * is not consumed, so the cursor is the correct resume point; a full re-run
 * is also safe).
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-public-follower-counts.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/backfill-public-follower-counts.js [--apply] [--start-after <uid>] [--page 300] [--max-pages N]
 */
import * as admin from 'firebase-admin';
import { FOLLOW_COUNTS, FOLLOWER_COUNTS_PUBLIC } from '../src/social/followCounters';
import { planPublicFollowerCount } from '../src/social/followCountsPrivacy';

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

export interface PublicFollowerBackfillResult {
  scanned: number;
  writes: number;
  cursor: string | null;
  done: boolean;
}

/** Copies one account; returns true when it wrote (or would write). */
export async function copyOne(
  db: admin.firestore.Firestore,
  uid: string,
  apply: boolean,
): Promise<boolean> {
  return db.runTransaction(async (tx) => {
    const privRef = db.collection(FOLLOW_COUNTS).doc(uid);
    const pubRef = db.collection(FOLLOWER_COUNTS_PUBLIC).doc(uid);
    const [priv, pub] = await tx.getAll(privRef, pubRef);
    const want = planPublicFollowerCount(
      priv.exists ? priv.data() : undefined,
      pub.exists ? pub.data() : undefined,
    );
    if (want === null) return false;
    if (apply) tx.set(pubRef, { followersCount: want, updatedAt: new Date() }, { merge: true });
    return true;
  });
}

export async function runPublicFollowerBackfill(opts: {
  db: admin.firestore.Firestore;
  apply: boolean;
  startAfter?: string;
  pageSize?: number;
  maxPages?: number;
  log?: (s: string) => void;
}): Promise<PublicFollowerBackfillResult> {
  const { db, apply } = opts;
  const pageSize = Math.max(1, Math.min(opts.pageSize ?? 300, 500));
  const log = opts.log ?? ((s: string) => console.log(s));
  const docId = admin.firestore.FieldPath.documentId();
  const res: PublicFollowerBackfillResult = {
    scanned: 0,
    writes: 0,
    cursor: opts.startAfter ?? null,
    done: false,
  };
  for (let pages = 0; opts.maxPages === undefined || pages < opts.maxPages; pages++) {
    let q = db.collection(FOLLOW_COUNTS).orderBy(docId).limit(pageSize);
    if (res.cursor) q = q.startAfter(res.cursor);
    const snap = await q.select().get();
    if (snap.empty) {
      res.done = true;
      break;
    }
    const ids = snap.docs.map((d) => d.id);
    for (let i = 0; i < ids.length; i += 10) {
      const out = await Promise.all(ids.slice(i, i + 10).map((id) => copyOne(db, id, apply)));
      res.writes += out.filter(Boolean).length;
    }
    res.scanned += ids.length;
    res.cursor = ids[ids.length - 1];
    log(`page of ${ids.length}; scanned=${res.scanned} ${apply ? 'written' : 'would write'}=${res.writes} cursor=${res.cursor}`);
    if (snap.size < pageSize) {
      res.done = true;
      break;
    }
  }
  return res;
}

async function main(): Promise<void> {
  const apply = process.argv.includes('--apply');
  const pageSize = Number(arg('--page')) || 300;
  const maxPages = arg('--max-pages') ? Number(arg('--max-pages')) : undefined;
  admin.initializeApp();
  const db = admin.firestore();
  console.log(`backfill-public-follower-counts: ${apply ? 'APPLY' : 'DRY RUN'} project=${process.env.GCLOUD_PROJECT ?? '?'}`);
  const r = await runPublicFollowerBackfill({ db, apply, startAfter: arg('--start-after'), pageSize, maxPages });
  console.log(JSON.stringify(r));
  if (!r.done) console.log(`Not finished: re-run with --start-after ${r.cursor}`);
}

if (require.main === module) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}
