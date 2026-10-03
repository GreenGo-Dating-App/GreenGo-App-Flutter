#!/usr/bin/env node
/**
 * Recount profiles/{uid}.followersCount / .followingCount from the follow-edge
 * collections (the source of truth):
 *
 *   followersCount = count() of business_followers/{uid}/followers
 *   followingCount = mirror docs user_business_following/{uid}/businesses/*
 *                    whose canonical edge business_followers/{x}/followers/{uid}
 *                    still exists (a stale mirror is reported, never counted)
 *
 * It also marks every edge it counted with `counted: true`, so that a later
 * unfollow of a legacy edge decrements (onUserFollowDeleted only decrements
 * counted edges) and a still-pending create trigger does not add it twice.
 *
 * Idempotent and resumable BY RESCANNING: it pages the whole `profiles`
 * collection by document id every run and writes only profiles whose stored
 * values differ. No offset is saved anywhere; an interrupted run is finished by
 * running it again. Each profile is re-verified after writing (a follow trigger
 * may land mid-recount) and recomputed up to 3 times until stable.
 *
 * Usage (from the repo root):
 *   set GOOGLE_APPLICATION_CREDENTIALS=<service-account.json>
 *     (PowerShell: $env:GOOGLE_APPLICATION_CREDENTIALS="...")
 *   node scripts/recount_follow_counters.js --project greengo-chat --dry-run
 *   node scripts/recount_follow_counters.js --project greengo-chat
 * Options:
 *   --dry-run              report only, write nothing
 *   --page-size <n>        profiles per page (default 200)
 *   --only <uid>           recount a single profile
 *   --prune-stale-mirrors  delete mirror docs whose canonical edge is gone
 *   --report-orphans       list followers edges whose follower profile is gone
 *                          (checked for followees with <= 2000 followers)
 *   --prune-orphans        INSTEAD of the full recount: delete every follow edge
 *                          (and mirror) whose follower OR followee profile no
 *                          longer exists, then recount the affected live
 *                          profiles. With --dry-run it only lists the edges and
 *                          the counter changes it would make.
 *                          Each orphan edge is first un-flagged (`counted:
 *                          false`) in its own write and only then deleted, so
 *                          onUserFollowDeleted does NOT also decrement — the
 *                          recount sets the absolute value instead (no double
 *                          count). Pages are pruned + recounted one at a time;
 *                          if a run is interrupted, re-run it and then run the
 *                          full recount once (no flags) to be certain.
 *
 * On this PC the corporate TLS proxy may require NODE_TLS_REJECT_UNAUTHORIZED=0.
 */

const path = require('path');

function arg(name, fallback) {
  const i = process.argv.indexOf(name);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}
const flag = (name) => process.argv.includes(name);

const projectId = arg('--project', process.env.GCLOUD_PROJECT);
if (!projectId) {
  console.error('Missing --project <projectId>');
  process.exit(1);
}
process.env.GCLOUD_PROJECT = projectId;
process.env.GOOGLE_CLOUD_PROJECT = projectId;

const admin = require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));
if (!admin.apps.length) admin.initializeApp({ projectId });
const db = admin.firestore();
const FieldPath = admin.firestore.FieldPath;

const dryRun = flag('--dry-run');
const pruneMirrors = flag('--prune-stale-mirrors');
const reportOrphans = flag('--report-orphans');
const pageSize = Math.max(1, Math.min(500, Number(arg('--page-size', '200')) || 200));
const only = arg('--only', null);

const followersCol = (uid) => db.collection('business_followers').doc(uid).collection('followers');
const mirrorCol = (uid) => db.collection('user_business_following').doc(uid).collection('businesses');

const nonNeg = (v) => (typeof v === 'number' && Number.isFinite(v) && v > 0 ? Math.floor(v) : 0);

/** Followers of uid: one count() aggregate. */
async function countFollowers(uid) {
  return (await followersCol(uid).count().get()).data().count;
}

/** Mark uid's uncounted follower edges `counted: true` (only if any exist). */
async function markUncounted(uid, total) {
  if (total === 0) return 0;
  const countedN = (await followersCol(uid).where('counted', '==', true).count().get()).data().count;
  if (countedN >= total) return 0;
  let marked = 0;
  let last = null;
  for (;;) {
    let q = followersCol(uid).orderBy(FieldPath.documentId()).limit(400);
    if (last) q = q.startAfter(last);
    const page = await q.get();
    if (page.empty) break;
    const batch = db.batch();
    let n = 0;
    for (const d of page.docs) {
      if (d.get('counted') !== true) {
        batch.update(d.ref, { counted: true });
        n++;
      }
    }
    if (n && !dryRun) await batch.commit();
    marked += n;
    last = page.docs[page.docs.length - 1];
    if (page.size < 400) break;
  }
  return marked;
}

/** Following of uid: mirror docs whose canonical edge exists. */
async function countFollowing(uid) {
  let live = 0;
  const stale = [];
  let last = null;
  for (;;) {
    let q = mirrorCol(uid).orderBy(FieldPath.documentId()).limit(300);
    if (last) q = q.startAfter(last);
    const page = await q.get();
    if (page.empty) break;
    const edges = await db.getAll(...page.docs.map((m) => followersCol(m.id).doc(uid)));
    edges.forEach((e, i) => (e.exists ? live++ : stale.push(page.docs[i].ref)));
    last = page.docs[page.docs.length - 1];
    if (page.size < 300) break;
  }
  return { live, stale };
}

async function orphanFollowers(uid, total) {
  if (total === 0 || total > 2000) return [];
  const edges = await followersCol(uid).select().get();
  const profiles = await db.getAll(...edges.docs.map((e) => db.collection('profiles').doc(e.id)));
  return profiles.filter((p) => !p.exists).map((p) => p.id);
}

const totals = { scanned: 0, fixed: 0, edgesMarked: 0, staleMirrors: 0, orphans: 0, errors: 0 };

/**
 * [adjust] is subtracted from the computed counts — used by a --prune-orphans
 * dry run to show the values AFTER the (not performed) deletions.
 */
async function recountOne(profileSnap, adjust = { followers: 0, following: 0 }) {
  const uid = profileSnap.id;
  let stored = profileSnap;
  for (let attempt = 1; attempt <= 3; attempt++) {
    const followers = Math.max(0, (await countFollowers(uid)) - adjust.followers);
    const counted = await countFollowing(uid);
    const following = Math.max(0, counted.live - adjust.following);
    const stale = counted.stale;
    if (attempt === 1) {
      totals.edgesMarked += await markUncounted(uid, followers);
      if (stale.length) {
        totals.staleMirrors += stale.length;
        console.log(`  ${uid}: ${stale.length} stale mirror(s)` + (pruneMirrors && !dryRun ? ' — pruned' : ''));
        if (pruneMirrors && !dryRun) {
          for (let i = 0; i < stale.length; i += 400) {
            const b = db.batch();
            stale.slice(i, i + 400).forEach((r) => b.delete(r));
            await b.commit();
          }
        }
      }
      if (reportOrphans) {
        const o = await orphanFollowers(uid, followers);
        if (o.length) {
          totals.orphans += o.length;
          console.log(`  ${uid}: follower edge(s) from deleted accounts: ${o.join(', ')}`);
        }
      }
    }
    const curFollowers = stored.get('followersCount');
    const curFollowing = stored.get('followingCount');
    const same = (cur, want) => cur === want || (cur === undefined && want === 0);
    const ok = same(curFollowers, followers) && same(curFollowing, following);
    if (ok) return;
    if (attempt === 1) {
      console.log(
        `  ${uid}: followersCount ${curFollowers} -> ${followers}, followingCount ${curFollowing} -> ${following}` +
          (dryRun ? ' (dry run)' : ''),
      );
      totals.fixed++;
    }
    if (dryRun) return;
    await stored.ref.update({ followersCount: nonNeg(followers), followingCount: nonNeg(following) });
    // Re-verify: a trigger may have moved an edge while we counted.
    stored = await stored.ref.get();
    if (!stored.exists) return;
  }
  console.warn(`  ${uid}: still changing after 3 attempts — re-run later`);
}

// ── --prune-orphans ─────────────────────────────────────────────────────────

/** Existence of profiles/{id} for many ids (cached across pages). */
const existsCache = new Map();
async function profilesExist(ids) {
  const missing = [...new Set(ids)].filter((id) => !existsCache.has(id));
  for (let i = 0; i < missing.length; i += 300) {
    const chunk = missing.slice(i, i + 300);
    const snaps = await db.getAll(...chunk.map((id) => db.collection('profiles').doc(id)));
    snaps.forEach((p, j) => existsCache.set(chunk[j], p.exists));
  }
  return (id) => existsCache.get(id) === true;
}

/** Commit [ops] (fn(batch) each) in batches of 400. */
async function commitInBatches(ops) {
  for (let i = 0; i < ops.length; i += 400) {
    const b = db.batch();
    ops.slice(i, i + 400).forEach((op) => op(b));
    await b.commit();
  }
}

/** Recount the affected live uids; in a dry run subtract the pending removals. */
async function recountAffected(affected) {
  for (const [uid, adj] of affected) {
    try {
      const s = await db.collection('profiles').doc(uid).get();
      if (!s.exists) continue;
      totals.scanned++;
      await recountOne(s, dryRun ? adj : { followers: 0, following: 0 });
    } catch (e) {
      totals.errors++;
      console.error(`  ${uid}: ${e.message}`);
    }
  }
}

function bump(affected, uid, field) {
  const a = affected.get(uid) || { followers: 0, following: 0 };
  a[field]++;
  affected.set(uid, a);
}

async function pruneOrphans() {
  const prune = { edges: 0, mirrors: 0 };

  // 1) Canonical edges business_followers/{followee}/followers/{follower}.
  let last = null;
  for (;;) {
    let q = db.collectionGroup('followers').orderBy(FieldPath.documentId()).limit(300);
    if (last) q = q.startAfter(last);
    const page = await q.get();
    if (page.empty) break;
    last = page.docs[page.docs.length - 1];
    const edges = page.docs.filter((d) => {
      const parent = d.ref.parent.parent;
      return parent && parent.parent.id === 'business_followers';
    });
    const alive = await profilesExist(edges.flatMap((d) => [d.id, d.ref.parent.parent.id]));
    const orphans = edges.filter((d) => !alive(d.id) || !alive(d.ref.parent.parent.id));
    const affected = new Map();
    for (const d of orphans) {
      const follower = d.id;
      const followee = d.ref.parent.parent.id;
      console.log(
        `  orphan edge ${d.ref.path}` +
          ` (follower ${alive(follower) ? 'ok' : 'GONE'}, followee ${alive(followee) ? 'ok' : 'GONE'})` +
          (dryRun ? ' — would delete' : ' — deleting'),
      );
      if (alive(followee)) bump(affected, followee, 'followers');
      if (alive(follower)) bump(affected, follower, 'following');
    }
    prune.edges += orphans.length;
    if (orphans.length && !dryRun) {
      // Un-flag first (separate commit) so the delete trigger sees an
      // uncounted edge and leaves the counters to the recount below.
      const flagged = orphans.filter((d) => d.get('counted') === true);
      await commitInBatches(flagged.map((d) => (b) => b.update(d.ref, { counted: false })));
      await commitInBatches(
        orphans.flatMap((d) => [
          (b) => b.delete(d.ref),
          (b) =>
            b.delete(
              db.collection('user_business_following').doc(d.id)
                .collection('businesses').doc(d.ref.parent.parent.id),
            ),
        ]),
      );
    }
    await recountAffected(affected);
    if (page.size < 300) break;
  }

  // 2) Mirrors user_business_following/{owner}/businesses/{target} left behind.
  last = null;
  for (;;) {
    let q = db.collectionGroup('businesses').orderBy(FieldPath.documentId()).limit(300);
    if (last) q = q.startAfter(last);
    const page = await q.get();
    if (page.empty) break;
    last = page.docs[page.docs.length - 1];
    const mirrors = page.docs.filter((d) => {
      const parent = d.ref.parent.parent;
      return parent && parent.parent.id === 'user_business_following';
    });
    const alive = await profilesExist(mirrors.flatMap((d) => [d.id, d.ref.parent.parent.id]));
    const orphans = mirrors.filter((d) => !alive(d.id) || !alive(d.ref.parent.parent.id));
    const affected = new Map();
    for (const d of orphans) {
      console.log(`  orphan mirror ${d.ref.path}` + (dryRun ? ' — would delete' : ' — deleting'));
      const owner = d.ref.parent.parent.id;
      if (alive(owner)) affected.set(owner, { followers: 0, following: 0 });
    }
    prune.mirrors += orphans.length;
    if (orphans.length && !dryRun) await commitInBatches(orphans.map((d) => (b) => b.delete(d.ref)));
    await recountAffected(affected);
    if (page.size < 300) break;
  }

  console.log(
    `Orphans: ${prune.edges} edge(s), ${prune.mirrors} mirror(s)` + (dryRun ? ' would be deleted' : ' deleted'),
  );
}

(async () => {
  console.log(`Recount follow counters on ${projectId}` + (dryRun ? ' (DRY RUN)' : ''));
  if (flag('--prune-orphans')) {
    await pruneOrphans();
  } else if (only) {
    const s = await db.collection('profiles').doc(only).get();
    if (!s.exists) throw new Error(`profiles/${only} not found`);
    totals.scanned++;
    await recountOne(s);
  } else {
    let last = null;
    for (;;) {
      let q = db.collection('profiles').orderBy(FieldPath.documentId()).limit(pageSize);
      if (last) q = q.startAfter(last);
      const page = await q.get();
      if (page.empty) break;
      for (const p of page.docs) {
        totals.scanned++;
        try {
          await recountOne(p);
        } catch (e) {
          totals.errors++;
          console.error(`  ${p.id}: ${e.message}`);
        }
      }
      console.log(`scanned ${totals.scanned}, fixed ${totals.fixed}, edges marked ${totals.edgesMarked}`);
      last = page.docs[page.docs.length - 1];
      if (page.size < pageSize) break;
    }
  }
  console.log('Done.', JSON.stringify(totals));
  if (totals.errors) process.exitCode = 2; // re-run to finish the failed profiles
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
