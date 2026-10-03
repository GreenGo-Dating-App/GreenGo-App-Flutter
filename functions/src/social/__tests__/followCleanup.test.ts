import { FollowCounterDeps, countEdge, uncountEdge } from '../followCounters';
import { enqueueFollowGraphCleanup, removeFollowGraphRound, FOLLOW_CLEANUP_JOBS } from '../followCleanup';
import { increment, makeDb } from './fakeFirestore';

/* eslint-disable @typescript-eslint/no-explicit-any */

const D = 'deleted';

function world() {
  const { db, store, onDelete } = makeDb();
  const deps: FollowCounterDeps = { db, increment };
  const pending: Promise<unknown>[] = [];
  let evt = 0;
  // Simulate onUserFollowDeleted firing for every canonical edge delete.
  onDelete((path, old) => {
    const m = /^business_followers\/([^/]+)\/followers\/([^/]+)$/.exec(path);
    if (m) pending.push(uncountEdge(deps, `evt-${++evt}`, m[1], m[2], old.counted === true));
  });
  const triggers = async () => {
    while (pending.length) await pending.shift();
  };
  const profile = (uid: string, d: Record<string, any> = {}) => store.set(`profiles/${uid}`, d);
  /** follower → followee, counted by the create trigger unless [legacy]. */
  const follow = async (follower: string, followee: string, legacy = false) => {
    store.set(`business_followers/${followee}/followers/${follower}`, { createdAt: 1 });
    store.set(`user_business_following/${follower}/businesses/${followee}`, { createdAt: 1 });
    if (!legacy) await countEdge(deps, followee, follower);
  };
  const get = (uid: string, f: string) => store.get(`profiles/${uid}`)?.[f];
  const graphPaths = () =>
    [...store.keys()].filter((k) => k.startsWith('business_followers/') || k.startsWith('user_business_following/'));
  return { db, store, deps, triggers, profile, follow, get, graphPaths };
}

async function setupDeletedAccount() {
  const w = world();
  for (const u of [D, 'a', 'b', 'c', 'e']) w.profile(u);
  w.store.set('profiles/a', { followerCount: 1 });
  w.store.set('profiles/b', { followerCount: 1 });
  await w.follow(D, 'a'); // D follows a, b
  await w.follow(D, 'b');
  await w.follow('c', D); // c follows D (counted)
  await w.follow('e', D, true); // e follows D (legacy, never counted)
  await w.follow('c', 'a'); // unrelated edge that must survive
  w.store.delete(`profiles/${D}`); // the account is deleted
  return w;
}

describe('removeFollowGraphRound (account deletion)', () => {
  it('removes every edge in both directions and adjusts the other side once', async () => {
    const w = await setupDeletedAccount();
    expect(w.get('a', 'followersCount')).toBe(2);
    expect(w.get('c', 'followingCount')).toBe(2);

    const r = await removeFollowGraphRound(w.deps, D, { deadlineMs: Date.now() + 60_000 });
    await w.triggers();

    expect(r).toEqual({ done: true, asFollower: 2, asFollowee: 2 });
    // Only the unrelated c → a edge (and its mirror) remain.
    expect(w.graphPaths().sort()).toEqual([
      'business_followers/a/followers/c',
      'user_business_following/c/businesses/a',
    ]);
    expect(w.get('a', 'followersCount')).toBe(1); // lost D, kept c
    expect(w.get('b', 'followersCount')).toBe(0);
    expect(w.get('c', 'followingCount')).toBe(1); // stopped following D
    expect(w.get('e', 'followingCount')).toBeUndefined(); // legacy edge: never counted
    expect(w.get('a', 'followerCount')).toBe(0); // legacy field
    expect(w.store.has(`profiles/${D}`)).toBe(false); // never resurrected
  });

  it('is idempotent: a second run changes nothing', async () => {
    const w = await setupDeletedAccount();
    await removeFollowGraphRound(w.deps, D, { deadlineMs: Date.now() + 60_000 });
    await w.triggers();
    const snapshot = JSON.stringify([...w.store.entries()].filter(([k]) => !k.startsWith('follow_counter_events')));
    const r = await removeFollowGraphRound(w.deps, D, { deadlineMs: Date.now() + 60_000 });
    await w.triggers();
    expect(r).toEqual({ done: true, asFollower: 0, asFollowee: 0 });
    expect(JSON.stringify([...w.store.entries()].filter(([k]) => !k.startsWith('follow_counter_events')))).toBe(snapshot);
  });

  it('works in bounded pages and resumes by re-querying', async () => {
    const w = await setupDeletedAccount();
    let clock = 0;
    const nowMs = () => clock++;
    // Deadline allows exactly one page per round.
    const r1 = await removeFollowGraphRound(w.deps, D, { deadlineMs: 0, pageSize: 1, nowMs });
    expect(r1.done).toBe(false);
    let rounds = 1;
    for (let r = r1; !r.done; rounds++) {
      clock = 0;
      r = await removeFollowGraphRound(w.deps, D, { deadlineMs: 0, pageSize: 1, nowMs });
    }
    await w.triggers();
    expect(rounds).toBeGreaterThan(2);
    expect(w.graphPaths()).toHaveLength(2);
    expect(w.get('a', 'followersCount')).toBe(1);
    expect(w.get('c', 'followingCount')).toBe(1);
  });

  it('a followee whose profile is already gone does not abort the batch', async () => {
    const w = await setupDeletedAccount();
    w.store.delete('profiles/b'); // b deleted too
    const r = await removeFollowGraphRound(w.deps, D, { deadlineMs: Date.now() + 60_000 });
    await w.triggers();
    expect(r.done).toBe(true);
    expect(w.store.has('business_followers/b/followers/deleted')).toBe(false);
    expect(w.store.has('profiles/b')).toBe(false);
  });

  it('enqueue creates one job per uid', async () => {
    const w = world();
    await enqueueFollowGraphCleanup(w.db, D);
    await enqueueFollowGraphCleanup(w.db, D); // second path (auth trigger) → no-op
    expect(w.store.get(`${FOLLOW_CLEANUP_JOBS}/${D}`)?.round).toBe(0);
  });
});
