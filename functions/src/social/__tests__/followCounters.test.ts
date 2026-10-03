import {
  clampCount,
  countEdge,
  uncountEdge,
  FollowCounterDeps,
  UNCOUNT_MARKERS,
} from '../followCounters';

import { Doc, increment, makeDb } from './fakeFirestore';

/* eslint-disable @typescript-eslint/no-explicit-any */

const A = 'alice'; // follower
const B = 'bob'; // followee
const edgePath = `business_followers/${B}/followers/${A}`;

function setup(profiles: Record<string, Doc> = { [A]: {}, [B]: {} }) {
  const { db, store } = makeDb();
  for (const [id, d] of Object.entries(profiles)) store.set(`profiles/${id}`, { ...d });
  const deps: FollowCounterDeps = { db, increment, now: () => new Date('2026-10-03T12:00:00Z') };
  const follow = () => store.set(edgePath, { createdAt: 1 });
  /** Client unfollow: returns the deleted snapshot's `counted` flag. */
  const unfollow = () => {
    const was = store.get(edgePath)?.counted === true;
    store.delete(edgePath);
    return was;
  };
  const counts = () => ({
    followers: store.get(`profiles/${B}`)?.followersCount,
    following: store.get(`profiles/${A}`)?.followingCount,
  });
  return { deps, store, follow, unfollow, counts };
}

describe('clampCount', () => {
  it('never returns a negative or non-integer value', () => {
    expect(clampCount(-3)).toBe(0);
    expect(clampCount(undefined)).toBe(0);
    expect(clampCount(NaN)).toBe(0);
    expect(clampCount('7')).toBe(7);
    expect(clampCount(4.9)).toBe(4);
  });
});

describe('follow / unfollow counters', () => {
  it('follow increments BOTH sides; unfollow decrements BOTH sides', async () => {
    const t = setup();
    t.follow();
    expect(await countEdge(t.deps, B, A)).toBe(true);
    expect(t.counts()).toEqual({ followers: 1, following: 1 });

    const was = t.unfollow();
    expect(await uncountEdge(t.deps, 'evt-del-1', B, A, was)).toBe(true);
    expect(t.counts()).toEqual({ followers: 0, following: 0 });
  });

  it('a duplicated create event counts once', async () => {
    const t = setup();
    t.follow();
    await countEdge(t.deps, B, A);
    expect(await countEdge(t.deps, B, A)).toBe(false);
    expect(t.counts()).toEqual({ followers: 1, following: 1 });
  });

  it('a retried delete event decrements once', async () => {
    const t = setup();
    t.follow();
    await countEdge(t.deps, B, A);
    const was = t.unfollow();
    expect(await uncountEdge(t.deps, 'evt-del', B, A, was)).toBe(true);
    expect(await uncountEdge(t.deps, 'evt-del', B, A, was)).toBe(false);
    expect(t.counts()).toEqual({ followers: 0, following: 0 });
    expect(t.store.has(`${UNCOUNT_MARKERS}/evt-del`)).toBe(true);
  });

  it('an edge deleted before it was counted never moves the counters', async () => {
    const t = setup({ [A]: { followingCount: 2 }, [B]: { followersCount: 5 } });
    t.follow();
    const was = t.unfollow(); // unfollow lands before the (cold) create trigger
    expect(await countEdge(t.deps, B, A)).toBe(false); // edge already gone
    expect(await uncountEdge(t.deps, 'evt', B, A, was)).toBe(false);
    expect(t.counts()).toEqual({ followers: 5, following: 2 });
  });

  it('rapid follow → unfollow → follow ends at exactly one, whatever the event order', async () => {
    const t = setup();
    t.follow(); // edge #1
    const was1 = t.unfollow(); // before create #1 ran → uncounted
    t.follow(); // edge #2
    // create #1 is delivered late and counts the CURRENT edge (#2) …
    expect(await countEdge(t.deps, B, A)).toBe(true);
    // … so create #2 finds it already counted.
    expect(await countEdge(t.deps, B, A)).toBe(false);
    expect(await uncountEdge(t.deps, 'del-1', B, A, was1)).toBe(false);
    expect(t.counts()).toEqual({ followers: 1, following: 1 });
  });

  it('follow (counted) → unfollow → follow with the delete delivered last', async () => {
    const t = setup();
    t.follow();
    await countEdge(t.deps, B, A);
    const was1 = t.unfollow();
    t.follow();
    await countEdge(t.deps, B, A); // create #2
    expect(t.counts()).toEqual({ followers: 2, following: 2 });
    await uncountEdge(t.deps, 'del-1', B, A, was1); // late delete #1
    expect(t.counts()).toEqual({ followers: 1, following: 1 });
  });

  it('never goes below zero on drifted data', async () => {
    const t = setup({ [A]: { followingCount: 0 }, [B]: {} });
    t.store.set(edgePath, { createdAt: 1, counted: true }); // counted before the counters existed
    const was = t.unfollow();
    expect(await uncountEdge(t.deps, 'evt', B, A, was)).toBe(true);
    expect(t.counts()).toEqual({ followers: 0, following: 0 });
  });

  it('skips a deleted account instead of resurrecting its profile', async () => {
    const t = setup({ [B]: {} }); // follower profile gone
    t.follow();
    expect(await countEdge(t.deps, B, A)).toBe(true);
    expect(t.store.has(`profiles/${A}`)).toBe(false);
    expect(t.counts().followers).toBe(1);
    const was = t.unfollow();
    await uncountEdge(t.deps, 'evt', B, A, was);
    expect(t.store.has(`profiles/${A}`)).toBe(false);
    expect(t.counts().followers).toBe(0);
  });
});
