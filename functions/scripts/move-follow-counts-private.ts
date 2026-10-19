/**
 * Moves the follower / following counters OFF the public profiles/{uid} into
 * the owner-only follow_counts/{uid} (owner rule 2026-10-17: counts are
 * visible only to the account itself - users AND businesses).
 * DRY-RUN BY DEFAULT: pass --apply to write.
 *
 * RUN ORDER (coordinator):
 *   1. deploy the functions onUserFollowCreated + onUserFollowDeleted
 *      (+ backfillFollowCounts) - from then on the counters are written ONLY
 *      to follow_counts/{uid};
 *   2. deploy the rules (follow_counts owner-only, follow lists owner-only);
 *   3. run THIS script with --apply right after (the app shows
 *      private + legacy public until it ran, so the order is not critical,
 *      but other users can read the public values until they are deleted).
 *
 * Per account, ONE transaction: follow_counts.X = public.X + follow_counts.X
 * (the private doc only holds the changes since step 1), then the public
 * followersCount / followingCount AND the legacy client-written followerCount
 * are deleted. Because the add and the delete commit together, every public
 * value is added exactly once; re-running finds nothing left.
 *
 * Source query per field: profiles ordered by that field (automatic
 * single-field index; only docs that HAVE the field are returned), paged by a
 * document cursor. In --apply mode a pass is repeated (max 5) until a pass
 * finds nothing, so a doc that gained a legacy field mid-run is not missed.
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/move-follow-counts-private.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/move-follow-counts-private.js [--apply] [--page-size 300]
 *
 * PHASE 2 (same run): `storesCount` backfill - the number of BUSINESS
 * accounts a user follows (own-profile "Stores" column). For every business
 * profile (where isBusiness == true, paged by id) its follower edges are
 * paged by id and each counted edge without the `countedStore` flag is
 * counted ONCE (flag + increment in one transaction, countStoreEdge). New
 * follows are counted by the follow trigger itself. Re-runnable.
 *
 * Afterwards, optionally: node scripts/recount_follow_counters.js --project greengo-chat
 * (recomputes follow_counts from the edges).
 */
import * as admin from 'firebase-admin';
import {
  FOLLOW_COUNTS,
  FOLLOWER_COUNTS_PUBLIC,
  FollowCounterDeps,
  STORE_COUNTED_FLAG,
  countStoreEdge,
} from '../src/social/followCounters';
import {
  PUBLIC_FOLLOW_COUNT_FIELDS,
  planFollowCountMove,
} from '../src/social/followCountsPrivacy';

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

/** Moves one account; returns the public fields it removed (or would remove). */
export async function moveOne(
  fs: admin.firestore.Firestore,
  uid: string,
  apply: boolean,
): Promise<string[]> {
  return fs.runTransaction(async (tx) => {
    const pubRef = fs.collection('profiles').doc(uid);
    const privRef = fs.collection(FOLLOW_COUNTS).doc(uid);
    const [pubSnap, privSnap] = await tx.getAll(pubRef, privRef);
    if (!pubSnap.exists) return [];
    const plan = planFollowCountMove(pubSnap.data(), privSnap.exists ? privSnap.data() : undefined);
    if (!plan.publicDelete.length) return [];
    if (apply) {
      if (Object.keys(plan.privateSet).length) tx.set(privRef, plan.privateSet, { merge: true });
      // Public follower count (owner decision 2026-10-19): kept equal to the
      // private followersCount in the same transaction (never following).
      if (plan.privateSet.followersCount !== undefined) {
        tx.set(
          fs.collection(FOLLOWER_COUNTS_PUBLIC).doc(uid),
          { followersCount: plan.privateSet.followersCount, updatedAt: new Date() },
          { merge: true },
        );
      }
      const del: Record<string, admin.firestore.FieldValue> = {};
      for (const f of plan.publicDelete) del[f] = admin.firestore.FieldValue.delete();
      tx.update(pubRef, del);
    }
    return plan.publicDelete;
  });
}

async function onePass(
  fs: admin.firestore.Firestore,
  apply: boolean,
  pageSize: number,
  counts: Record<string, number>,
): Promise<number> {
  const seen = new Set<string>();
  let moved = 0;
  for (const field of PUBLIC_FOLLOW_COUNT_FIELDS) {
    let cursor: admin.firestore.QueryDocumentSnapshot | null = null;
    for (;;) {
      let q = fs.collection('profiles').orderBy(field).limit(pageSize);
      if (cursor) q = q.startAfter(cursor);
      const snap = await q.select(field).get();
      if (snap.empty) break;
      const ids = snap.docs.map((d) => d.id).filter((id) => !seen.has(id));
      ids.forEach((id) => seen.add(id));
      for (let i = 0; i < ids.length; i += 10) {
        const res = await Promise.all(ids.slice(i, i + 10).map((id) => moveOne(fs, id, apply)));
        for (const fields of res) {
          if (fields.length) moved++;
          for (const f of fields) counts[f] = (counts[f] ?? 0) + 1;
        }
      }
      cursor = snap.docs[snap.docs.length - 1];
      console.log(`[${field}] page of ${snap.size}; ${apply ? 'moved' : 'would move'} so far=${moved}`);
      if (snap.size < pageSize) break;
    }
  }
  return moved;
}

/** Phase 2: count legacy business-follow edges into storesCount. */
export async function backfillStoresCount(
  fs: admin.firestore.Firestore,
  apply: boolean,
  pageSize = 300,
): Promise<{ businesses: number; edges: number; counted: number }> {
  const deps: FollowCounterDeps = { db: fs, increment: (n) => admin.firestore.FieldValue.increment(n) };
  const docId = admin.firestore.FieldPath.documentId();
  const out = { businesses: 0, edges: 0, counted: 0 };
  let bizCursor: string | null = null;
  for (;;) {
    let bq = fs.collection('profiles').where('isBusiness', '==', true).orderBy(docId).limit(pageSize);
    if (bizCursor) bq = bq.startAfter(bizCursor);
    const biz = await bq.select().get();
    if (biz.empty) break;
    for (const b of biz.docs) {
      out.businesses++;
      let edgeCursor: string | null = null;
      for (;;) {
        let eq = fs.collection('business_followers').doc(b.id).collection('followers')
          .orderBy(docId).limit(400);
        if (edgeCursor) eq = eq.startAfter(edgeCursor);
        const edges = await eq.get();
        if (edges.empty) break;
        const todo = edges.docs.filter((e) => e.get('counted') === true && e.get(STORE_COUNTED_FLAG) !== true);
        out.edges += todo.length;
        if (apply) {
          for (let i = 0; i < todo.length; i += 10) {
            const res = await Promise.all(todo.slice(i, i + 10).map((e) => countStoreEdge(deps, b.id, e.id)));
            out.counted += res.filter(Boolean).length;
          }
        }
        edgeCursor = edges.docs[edges.docs.length - 1].id;
        if (edges.size < 400) break;
      }
    }
    bizCursor = biz.docs[biz.docs.length - 1].id;
    console.log(`[stores] businesses=${out.businesses} edges=${out.edges} counted=${out.counted}`);
    if (biz.size < pageSize) break;
  }
  return out;
}

async function main() {
  if (!admin.apps.length) admin.initializeApp();
  const fs = admin.firestore();
  const apply = process.argv.includes('--apply');
  const pageSize = Math.min(Number(arg('--page-size') ?? 300), 400);
  const counts: Record<string, number> = {};
  let total = 0;
  for (let pass = 1; pass <= (apply ? 5 : 1); pass++) {
    const n = await onePass(fs, apply, pageSize, counts);
    total += n;
    console.log(`pass ${pass}: ${apply ? 'moved' : 'would move'} ${n} profile(s)`);
    if (n === 0) break;
  }
  console.log(`${apply ? 'APPLIED' : '[DRY RUN - pass --apply to write]'} profiles=${total}`);
  console.log(JSON.stringify(counts, null, 2));
  const stores = await backfillStoresCount(fs, apply, pageSize);
  console.log(`[stores] ${apply ? 'APPLIED' : 'DRY RUN'} ${JSON.stringify(stores)}`);
}

if (require.main === module) main().catch((e) => { console.error(e); process.exit(1); });
