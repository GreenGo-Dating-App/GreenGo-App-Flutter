import { planFollowCountMove, planPublicFollowerCount } from '../followCountsPrivacy';

describe('planFollowCountMove (public follow counts -> follow_counts)', () => {
  it('folds the public value into the post-deploy private delta and deletes the public fields', () => {
    expect(
      planFollowCountMove(
        { name: 'x', followersCount: 120, followingCount: 7, followerCount: 3 },
        { followersCount: 2, followingCount: -1 },
      ),
    ).toEqual({
      privateSet: { followersCount: 122, followingCount: 6 },
      publicDelete: ['followersCount', 'followingCount', 'followerCount'],
    });
  });

  it('creates the private values when there is no private doc yet', () => {
    expect(planFollowCountMove({ followersCount: 5 }, undefined)).toEqual({
      privateSet: { followersCount: 5 },
      publicDelete: ['followersCount'],
    });
  });

  it('drops the legacy client followerCount without copying it', () => {
    expect(planFollowCountMove({ followerCount: 9 }, { followersCount: 1 })).toEqual({
      privateSet: {},
      publicDelete: ['followerCount'],
    });
  });

  it('is a no-op once the public profile carries nothing (re-run safe)', () => {
    expect(planFollowCountMove({ name: 'x' }, { followersCount: 4 })).toEqual({
      privateSet: {},
      publicDelete: [],
    });
  });

  it('never produces a negative or fractional counter', () => {
    expect(planFollowCountMove({ followersCount: -4, followingCount: 2.7 }, { followersCount: 1 }))
      .toEqual({
        privateSet: { followersCount: 0, followingCount: 2 },
        publicDelete: ['followersCount', 'followingCount'],
      });
  });
});

describe('planPublicFollowerCount (follow_counts -> follower_counts_public)', () => {
  it('copies the private followersCount, idempotently', () => {
    expect(planPublicFollowerCount({ followersCount: 7, followingCount: 3, storesCount: 1 }, undefined)).toBe(7);
    expect(planPublicFollowerCount({ followersCount: 7 }, { followersCount: 7 })).toBeNull();
    expect(planPublicFollowerCount({ followersCount: 7 }, { followersCount: 2 })).toBe(7);
  });
  it('0 / missing / negative / junk never create a doc, but fix a stale one', () => {
    expect(planPublicFollowerCount({ followingCount: 4 }, undefined)).toBeNull();
    expect(planPublicFollowerCount({ followersCount: -2 }, undefined)).toBeNull();
    expect(planPublicFollowerCount({ followersCount: 'x' }, undefined)).toBeNull();
    expect(planPublicFollowerCount(undefined, { followersCount: 3 })).toBe(0);
    expect(planPublicFollowerCount({ followersCount: 2.9 }, undefined)).toBe(2);
  });
});
