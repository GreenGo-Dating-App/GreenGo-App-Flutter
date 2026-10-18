/**
 * Searchable names on follow edges — server-only, so a followers / following
 * list can be PREFIX-searched across the WHOLE list (millions of rows) with
 * one ordered, bounded query per page instead of scanning loaded rows.
 *
 * Fields (written ONLY by server code; the rules refuse them from clients):
 *   - `business_followers/{followee}/followers/{follower}.followerNameLower`
 *       the FOLLOWER's normalized display name (searched on a Followers tab)
 *   - `user_business_following/{follower}/businesses/{followee}.followeeNameLower`
 *       the FOLLOWEE's normalized display name (searched on a Following tab)
 *
 * The followee / follower is the PARENT PATH of each doc, so the app's search
 *   col.orderBy('<field>').startAt([q]).endAt([q + '']).limit(20)
 * runs inside ONE subcollection and is served by Firestore's automatic
 * single-field index (no composite index is needed — or even allowed, a
 * composite index must have at least two fields).
 *
 * Writers:
 *   1. onUserFollowCreated → [stampEdgeNames] (clients create edges with
 *      `createdAt` only; the trigger fills both names right after).
 *   2. Display-name change → [enqueueFollowNameJobIfChanged] (called from the
 *      existing profiles/{uid} trigger mirrorPrivateProfileFields, so hot
 *      profile writes that do not change the name cost no extra invocation
 *      and no read) → `follow_name_jobs/{uid}` → onFollowNameJob runs
 *      [followNameRound] pages under a deadline and re-fires itself until the
 *      fan-out is done. Bounded: <= NAME_PAGE edges per batch (< 500 writes),
 *      idempotent (skips docs already carrying the name, never creates a doc).
 *   3. scripts/backfill-follow-names.ts for edges that predate this.
 *
 * MUST stay in sync with the app's `normalizeFollowName`
 * (lib/core/utils/follow_name_normalizer.dart).
 */

/* eslint-disable @typescript-eslint/no-explicit-any */

export const FOLLOWER_NAME_FIELD = 'followerNameLower';
export const FOLLOWEE_NAME_FIELD = 'followeeNameLower';
export const FOLLOW_NAME_JOBS = 'follow_name_jobs';

/** Edges per fan-out page (one batch; one write per edge, < 500). */
export const NAME_PAGE = 400;

/** Stored names are capped (a prefix search never needs more). */
const MAX_NAME_LEN = 80;

/**
 * Lowercase, accents stripped (NFD, drop U+0300–U+036F, NFC again so Hangul /
 * kana re-compose), trimmed, inner whitespace collapsed, capped.
 */
export function normalizeFollowName(raw: unknown): string {
  if (typeof raw !== 'string') return '';
  const s = raw
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .normalize('NFC')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
  return Array.from(s).slice(0, MAX_NAME_LEN).join('').trim();
}

/**
 * The searchable name of a profile: displayName, else nickname (the same
 * precedence the app's UserBrief uses, without the '@'). '' when unknown.
 */
export function profileFollowName(data: Record<string, any> | undefined | null): string {
  if (!data) return '';
  const dn = normalizeFollowName(data.displayName);
  if (dn) return dn;
  return normalizeFollowName(data.nickname);
}

export function followersCol(db: any, uid: string) {
  return db.collection('business_followers').doc(uid).collection('followers');
}
export function followingCol(db: any, uid: string) {
  return db.collection('user_business_following').doc(uid).collection('businesses');
}

/**
 * Fill both searchable names of ONE edge (+ its mirror). Idempotent; never
 * creates a doc (an edge/mirror deleted meanwhile is skipped). Two profile
 * reads in one getAll.
 */
export async function stampEdgeNames(
  db: any,
  followeeId: string,
  followerId: string,
): Promise<{ edge: boolean; mirror: boolean }> {
  const out = { edge: false, mirror: false };
  if (!followeeId || !followerId) return out;
  const edgeRef = followersCol(db, followeeId).doc(followerId);
  const mirrorRef = followingCol(db, followerId).doc(followeeId);
  const [followee, follower, edge, mirror] = await db.getAll(
    db.collection('profiles').doc(followeeId),
    db.collection('profiles').doc(followerId),
    edgeRef,
    mirrorRef,
  );
  const followerName = profileFollowName(follower.exists ? follower.data() : undefined);
  const followeeName = profileFollowName(followee.exists ? followee.data() : undefined);
  const w = db.batch();
  if (edge.exists && edge.get(FOLLOWER_NAME_FIELD) !== followerName) {
    w.update(edgeRef, { [FOLLOWER_NAME_FIELD]: followerName });
    out.edge = true;
  }
  if (mirror.exists && mirror.get(FOLLOWEE_NAME_FIELD) !== followeeName) {
    w.update(mirrorRef, { [FOLLOWEE_NAME_FIELD]: followeeName });
    out.mirror = true;
  }
  if (out.edge || out.mirror) {
    try {
      await w.commit();
    } catch (e: any) {
      // NOT_FOUND: an unfollow raced us — nothing to stamp.
      if (e?.code !== 5 && !/NOT_FOUND/.test(String(e?.message ?? e))) throw e;
      return { edge: false, mirror: false };
    }
  }
  return out;
}

/**
 * Called on every profiles/{uid} write. Exits WITHOUT a read unless the
 * searchable name actually changed on an existing (not new, not deleted)
 * profile; then (re)starts the fan-out job. Overwriting the job doc resets
 * it to the newest name — a run for an older name stops at its next page.
 */
export async function enqueueFollowNameJobIfChanged(
  db: any,
  uid: string,
  before: Record<string, any> | undefined,
  after: Record<string, any> | undefined,
  now: () => number = () => Date.now(),
): Promise<boolean> {
  if (!uid || !before || !after) return false;
  const next = profileFollowName(after);
  if (profileFollowName(before) === next) return false;
  await db.collection(FOLLOW_NAME_JOBS).doc(uid).set({
    name: next,
    gen: now(),
    phase: 'following',
    cursor: null,
    round: 0,
  });
  return true;
}

export interface FollowNameJob {
  name: string;
  gen: number;
  phase: 'following' | 'followers';
  cursor: string | null;
  round?: number;
}

export interface FollowNameRoundResult {
  done: boolean;
  /** The job was superseded by a newer name (this run stopped). */
  superseded: boolean;
  updated: number;
  scanned: number;
  phase: 'following' | 'followers';
  cursor: string | null;
}

/**
 * One bounded round of the name fan-out for [uid]:
 *   phase 'following': uid's mirror list → the canonical edges
 *     business_followers/{x}/followers/{uid}.followerNameLower
 *   phase 'followers': uid's followers → their mirrors
 *     user_business_following/{f}/businesses/{uid}.followeeNameLower
 * Pages by document id from the saved cursor (the source is NOT consumed,
 * so a cursor is the right resume point). Before each page it re-reads the
 * job and stops if a newer name superseded it.
 */
export async function followNameRound(
  db: any,
  uid: string,
  job: FollowNameJob,
  opts: { deadlineMs: number; pageSize?: number; nowMs?: () => number },
): Promise<FollowNameRoundResult> {
  const pageSize = Math.max(1, Math.min(opts.pageSize ?? NAME_PAGE, NAME_PAGE));
  const now = opts.nowMs ?? (() => Date.now());
  let phase = job.phase;
  let cursor = job.cursor;
  const res = (done: boolean, superseded = false): FollowNameRoundResult => ({
    done, superseded, updated, scanned, phase, cursor,
  });
  let updated = 0;
  let scanned = 0;
  let worked = false;
  const jobRef = db.collection(FOLLOW_NAME_JOBS).doc(uid);

  for (;;) {
    if (worked && now() > opts.deadlineMs) return res(false);
    const cur = await jobRef.get();
    if (!cur.exists || cur.get('gen') !== job.gen) return res(false, true);
    worked = true;

    const src = phase === 'following' ? followingCol(db, uid) : followersCol(db, uid);
    let q = src.orderBy('__name__').limit(pageSize);
    if (cursor) q = q.startAfter(cursor);
    const page = await q.get();
    scanned += page.size;

    if (page.size > 0) {
      const targets = page.docs.map((d: any) =>
        phase === 'following'
          ? followersCol(db, d.id).doc(uid) // edge where uid is the follower
          : followingCol(db, d.id).doc(uid), // mirror where uid is the followee
      );
      const field = phase === 'following' ? FOLLOWER_NAME_FIELD : FOLLOWEE_NAME_FIELD;
      const snaps = await db.getAll(...targets);
      const w = db.batch();
      let n = 0;
      snaps.forEach((s: any, i: number) => {
        // Never create: a missing edge/mirror (stale side) is skipped.
        if (!s.exists || s.get(field) === job.name) return;
        w.update(targets[i], { [field]: job.name });
        n++;
      });
      if (n > 0) {
        await w.commit();
        updated += n;
      }
      cursor = page.docs[page.docs.length - 1].id;
    }

    if (page.size < pageSize) {
      if (phase === 'following') {
        phase = 'followers';
        cursor = null;
        continue;
      }
      return res(true);
    }
  }
}
