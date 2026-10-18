import { planFollowCountMove } from '../followCountsPrivacy';

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
