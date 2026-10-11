/**
 * Invite-friends rules (src/referral/referralRules.ts): pure milestone / cap logic.
 */
import {
  INVITEE_BASE_DURATION_MS,
  MILESTONE_DURATION_MS,
  REFERRAL_MILESTONES,
  REFERRER_COIN_REWARD,
  REFERRER_MONTHLY_CAP,
  grantedSet,
  milestonesToGrant,
  nextMilestone,
  referralCoinsFor,
  referralPeriod,
  tierLabel,
} from '../../src/referral/referralRules';

const counts = (ms: { count: number }[]) => ms.map((m) => m.count);

describe('referral rules constants', () => {
  test('owner rules: 1 week Base, 50 coins, 1,000/month, 5/10/20 -> Silver/Gold/Platinum for 30 days', () => {
    expect(INVITEE_BASE_DURATION_MS).toBe(7 * 24 * 3600 * 1000);
    expect(REFERRER_COIN_REWARD).toBe(50);
    expect(REFERRER_MONTHLY_CAP).toBe(1000);
    expect(MILESTONE_DURATION_MS).toBe(30 * 24 * 3600 * 1000);
    expect(REFERRAL_MILESTONES.map((m) => [m.count, m.tier, m.durationMs])).toEqual([
      [5, 'SILVER', MILESTONE_DURATION_MS],
      [10, 'GOLD', MILESTONE_DURATION_MS],
      [20, 'PLATINUM', MILESTONE_DURATION_MS],
    ]);
  });
});

describe('milestonesToGrant', () => {
  test('nothing below the first threshold', () => {
    for (let n = 0; n < 5; n++) expect(milestonesToGrant(n, [])).toEqual([]);
  });

  test('exactly at each threshold grants that milestone', () => {
    expect(counts(milestonesToGrant(5, []))).toEqual([5]);
    expect(counts(milestonesToGrant(10, [5]))).toEqual([10]);
    expect(counts(milestonesToGrant(20, [5, 10]))).toEqual([20]);
  });

  test('already granted milestones are never granted again', () => {
    expect(milestonesToGrant(6, [5])).toEqual([]);
    expect(milestonesToGrant(10, [5, 10])).toEqual([]);
    expect(milestonesToGrant(500, [5, 10, 20])).toEqual([]);
  });

  test('a skipped count (backfill) grants every reached milestone once, ascending', () => {
    expect(counts(milestonesToGrant(12, []))).toEqual([5, 10]);
    expect(counts(milestonesToGrant(25, []))).toEqual([5, 10, 20]);
    expect(counts(milestonesToGrant(25, [10]))).toEqual([5, 20]);
  });

  test('sequential invitations 1..25 grant each milestone exactly once', () => {
    const granted = new Set<number>();
    const all: number[] = [];
    for (let n = 1; n <= 25; n++) {
      for (const m of milestonesToGrant(n, granted)) {
        granted.add(m.count);
        all.push(m.count);
      }
    }
    expect(all).toEqual([5, 10, 20]);
  });

  test('bad input is safe', () => {
    expect(milestonesToGrant(NaN, [])).toEqual([]);
    expect(milestonesToGrant(-3, [])).toEqual([]);
  });
});

describe('referralCoinsFor (monthly cap)', () => {
  test('full reward under the cap, 0 once it would be exceeded (never partial)', () => {
    expect(referralCoinsFor(0)).toBe(50);
    expect(referralCoinsFor(950)).toBe(50);
    expect(referralCoinsFor(1000)).toBe(0);
    expect(referralCoinsFor(980)).toBe(0);
    expect(referralCoinsFor(NaN)).toBe(50);
  });

  test('20 invitations in one month pay exactly 1,000 coins, the 21st pays 0', () => {
    let paid = 0;
    for (let i = 0; i < 21; i++) paid += referralCoinsFor(paid);
    expect(paid).toBe(1000);
  });
});

describe('helpers', () => {
  test('grantedSet keeps integers only', () => {
    expect([...grantedSet([5, '10', 10.5, 20, null])]).toEqual([5, 20]);
    expect(grantedSet(undefined).size).toBe(0);
  });
  test('nextMilestone', () => {
    expect(nextMilestone(0)?.count).toBe(5);
    expect(nextMilestone(7)?.count).toBe(10);
    expect(nextMilestone(20)).toBeNull();
  });
  test('referralPeriod is UTC yyyymm', () => {
    expect(referralPeriod(new Date(Date.UTC(2026, 0, 31, 23, 59)))).toBe('202601');
    expect(referralPeriod(new Date(Date.UTC(2026, 11, 1)))).toBe('202612');
  });
  test('tierLabel', () => {
    expect(tierLabel('PLATINUM')).toBe('Platinum');
  });
});
