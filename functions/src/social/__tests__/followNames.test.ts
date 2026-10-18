import * as fs from 'fs';
import * as path from 'path';
import {
  FOLLOW_NAME_JOBS,
  FollowNameJob,
  enqueueFollowNameJobIfChanged,
  followNameRound,
  normalizeFollowName,
  profileFollowName,
  stampEdgeNames,
} from '../followNames';
import { makeDb } from './fakeFirestore';

/* eslint-disable @typescript-eslint/no-explicit-any */

describe('normalizeFollowName', () => {
  // Shared fixture: the app's Dart normalizer is tested against the SAME file.
  const fixture = JSON.parse(fs.readFileSync(
    path.join(__dirname, '../../../../test/fixtures/follow_name_normalization.json'), 'utf8'));
  it.each(fixture.cases as Array<[string, string]>)('%j → %j', (raw, want) => {
    expect(normalizeFollowName(raw)).toBe(want);
  });

  it('ignores non-strings and caps the length', () => {
    expect(normalizeFollowName(undefined)).toBe('');
    expect(normalizeFollowName(42 as any)).toBe('');
    expect(normalizeFollowName('a'.repeat(200))).toHaveLength(80);
  });

  it('profileFollowName prefers displayName, else nickname', () => {
    expect(profileFollowName({ displayName: 'Ana', nickname: 'zed' })).toBe('ana');
    expect(profileFollowName({ displayName: '  ', nickname: 'Zé' })).toBe('ze');
    expect(profileFollowName(undefined)).toBe('');
  });
});

function world() {
  const { db, store } = makeDb();
  const follow = (follower: string, followee: string) => {
    store.set(`business_followers/${followee}/followers/${follower}`, { createdAt: 1 });
    store.set(`user_business_following/${follower}/businesses/${followee}`, { createdAt: 1 });
  };
  return { db, store, follow };
}

describe('stampEdgeNames (follow created)', () => {
  it('fills both names, is idempotent and never creates docs', async () => {
    const w = world();
    w.store.set('profiles/a', { displayName: 'Ánna' });
    w.store.set('profiles/b', { nickname: 'Bob' });
    w.follow('a', 'b');
    expect(await stampEdgeNames(w.db, 'b', 'a')).toEqual({ edge: true, mirror: true });
    expect(w.store.get('business_followers/b/followers/a')!.followerNameLower).toBe('anna');
    expect(w.store.get('user_business_following/a/businesses/b')!.followeeNameLower).toBe('bob');
    expect(await stampEdgeNames(w.db, 'b', 'a')).toEqual({ edge: false, mirror: false });

    // Unfollowed meanwhile: nothing is (re)created.
    expect(await stampEdgeNames(w.db, 'b', 'zz')).toEqual({ edge: false, mirror: false });
    expect(w.store.has('business_followers/b/followers/zz')).toBe(false);
  });
});

describe('enqueueFollowNameJobIfChanged', () => {
  it('only enqueues when the searchable name changes on an existing profile', async () => {
    const w = world();
    const go = (b: any, a: any) => enqueueFollowNameJobIfChanged(w.db, 'u', b, a, () => 7);
    expect(await go(undefined, { displayName: 'X' })).toBe(false); // created
    expect(await go({ displayName: 'X' }, undefined)).toBe(false); // deleted
    expect(await go({ displayName: 'X', lastSeen: 1 }, { displayName: 'X', lastSeen: 2 })).toBe(false);
    expect(await go({ displayName: 'Jose' }, { displayName: 'José' })).toBe(false); // same key
    expect(w.store.has(`${FOLLOW_NAME_JOBS}/u`)).toBe(false);
    expect(await go({ displayName: 'Jose' }, { displayName: 'Joana' })).toBe(true);
    expect(w.store.get(`${FOLLOW_NAME_JOBS}/u`)).toEqual({
      name: 'joana', gen: 7, phase: 'following', cursor: null, round: 0,
    });
  });
});

describe('followNameRound (name fan-out)', () => {
  const U = 'u';
  async function setup(nFollowing: number, nFollowers: number) {
    const w = world();
    for (let i = 0; i < nFollowing; i++) w.follow(U, `f${String(i).padStart(3, '0')}`);
    for (let i = 0; i < nFollowers; i++) w.follow(`r${String(i).padStart(3, '0')}`, U);
    // A stale mirror whose canonical edge is gone must not be re-created.
    w.store.set(`user_business_following/${U}/businesses/ghost`, { createdAt: 1 });
    const job: FollowNameJob = { name: 'new name', gen: 1, phase: 'following', cursor: null };
    w.store.set(`${FOLLOW_NAME_JOBS}/${U}`, { ...job });
    return { w, job };
  }

  it('updates every edge in both directions in bounded pages', async () => {
    const { w, job } = await setup(7, 5);
    const r = await followNameRound(w.db, U, job, { deadlineMs: Date.now() + 60_000, pageSize: 3 });
    expect(r.done).toBe(true);
    expect(r.updated).toBe(12);
    for (let i = 0; i < 7; i++) {
      expect(w.store.get(`business_followers/f00${i}/followers/${U}`)!.followerNameLower).toBe('new name');
    }
    for (let i = 0; i < 5; i++) {
      expect(w.store.get(`user_business_following/r00${i}/businesses/${U}`)!.followeeNameLower).toBe('new name');
    }
    expect(w.store.has(`business_followers/ghost/followers/${U}`)).toBe(false);
    // Idempotent: a second run writes nothing.
    const again = await followNameRound(w.db, U, job, { deadlineMs: Date.now() + 60_000, pageSize: 3 });
    expect(again.updated).toBe(0);
  });

  it('stops at the deadline and resumes from the saved cursor', async () => {
    const { w, job } = await setup(7, 5);
    let t = 0;
    const r1 = await followNameRound(w.db, U, job, { deadlineMs: 0, pageSize: 3, nowMs: () => ++t });
    expect(r1.done).toBe(false);
    expect(r1.scanned).toBe(3); // exactly one page per round past the deadline
    let r = r1;
    let rounds = 1;
    while (!r.done) {
      r = await followNameRound(w.db, U, { ...job, phase: r.phase, cursor: r.cursor }, {
        deadlineMs: 0, pageSize: 3, nowMs: () => ++t,
      });
      rounds++;
      expect(rounds).toBeLessThan(20);
    }
    const edges = [...w.store.entries()].filter(([k]) =>
      k.endsWith(`/followers/${U}`) || k.endsWith(`/businesses/${U}`));
    expect(edges).toHaveLength(12);
    edges.forEach(([, v]) => expect(v.followerNameLower ?? v.followeeNameLower).toBe('new name'));
  });

  it('stops when a newer name superseded the job', async () => {
    const { w, job } = await setup(4, 0);
    w.store.set(`${FOLLOW_NAME_JOBS}/${U}`, { ...job, gen: 2, name: 'newer' });
    const r = await followNameRound(w.db, U, job, { deadlineMs: Date.now() + 60_000 });
    expect(r).toMatchObject({ done: false, superseded: true, updated: 0 });
  });
});
