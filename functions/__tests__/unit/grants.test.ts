/**
 * Unit tests for the pure tier-extension rule used by both purchase
 * verification and coupon redemption. No IO — verifies the never-downgrade
 * invariant and the date math for every combination of (currentTier,
 * isActive, requestedTier).
 */

// Mock firebase-admin BEFORE importing the helpers (they reference Timestamp).
jest.mock('firebase-admin', () => {
  const firestoreFn: any = () => ({
    collection: () => ({}),
  });
  firestoreFn.Timestamp = {
    fromDate: (d: Date) => ({ toDate: () => d, toMillis: () => d.getTime() }),
    now: () => ({ toDate: () => new Date(), toMillis: () => Date.now() }),
  };
  firestoreFn.FieldValue = { increment: (n: number) => n, serverTimestamp: () => 'ts' };
  return {
    apps: [{ name: '[DEFAULT]' }], // pretend Admin is already initialized
    initializeApp: jest.fn(),
    firestore: firestoreFn,
    storage: () => ({ bucket: () => ({}) }),
    auth: () => ({}),
  };
});

import { computeMembershipExtension, TIER_RANK, TierName } from '../../src/shared/grants';
import {
  effectiveGrants,
  summariseGrants,
  hasBaseGrant,
  validateGrant,
  Grant,
} from '../../src/coupons/grants';

const DAY = 24 * 60 * 60 * 1000;

describe('computeMembershipExtension — tier-no-downgrade rule', () => {
  const now = new Date('2026-06-01T00:00:00Z');

  it('starts from now when the user has no active membership', () => {
    const r = computeMembershipExtension('BASIC', null, 'SILVER', 30 * DAY, now);
    expect(r.effectiveTier).toBe('SILVER');
    expect(r.newEndDate.getTime()).toBe(now.getTime() + 30 * DAY);
  });

  it('starts from now when the existing membership has expired', () => {
    const past = new Date(now.getTime() - 5 * DAY);
    const r = computeMembershipExtension('GOLD', past, 'SILVER', 30 * DAY, now);
    expect(r.effectiveTier).toBe('SILVER');
    expect(r.newEndDate.getTime()).toBe(now.getTime() + 30 * DAY);
  });

  it('upgrades the tier when a higher tier is redeemed while a lower tier is active', () => {
    const future = new Date(now.getTime() + 10 * DAY);
    const r = computeMembershipExtension('SILVER', future, 'GOLD', 30 * DAY, now);
    expect(r.effectiveTier).toBe('GOLD');
    expect(r.newEndDate.getTime()).toBe(future.getTime() + 30 * DAY);
  });

  it('keeps the higher tier and extends end date when a LOWER tier coupon is redeemed', () => {
    const future = new Date(now.getTime() + 10 * DAY);
    const r = computeMembershipExtension('GOLD', future, 'SILVER', 30 * DAY, now);
    expect(r.effectiveTier).toBe('GOLD'); // critical: no downgrade
    expect(r.newEndDate.getTime()).toBe(future.getTime() + 30 * DAY);
  });

  it('extends from the current end when the same tier is redeemed', () => {
    const future = new Date(now.getTime() + 10 * DAY);
    const r = computeMembershipExtension('PLATINUM', future, 'PLATINUM', 7 * DAY, now);
    expect(r.effectiveTier).toBe('PLATINUM');
    expect(r.newEndDate.getTime()).toBe(future.getTime() + 7 * DAY);
  });

  it('treats unknown current tier as BASIC for the rank comparison', () => {
    const future = new Date(now.getTime() + 10 * DAY);
    const r = computeMembershipExtension('UNKNOWN' as TierName, future, 'SILVER', 30 * DAY, now);
    expect(r.effectiveTier).toBe('SILVER');
  });

  it('orders tiers by rank: BASIC < SILVER < GOLD < PLATINUM', () => {
    expect(TIER_RANK.BASIC).toBeLessThan(TIER_RANK.SILVER);
    expect(TIER_RANK.SILVER).toBeLessThan(TIER_RANK.GOLD);
    expect(TIER_RANK.GOLD).toBeLessThan(TIER_RANK.PLATINUM);
  });
});

describe('effectiveGrants — legacy fallback + bundle pass-through', () => {
  it('returns the grants array unchanged when non-empty', () => {
    const grants: Grant[] = [
      { kind: 'coins', coinAmount: 100 },
      { kind: 'membership', tier: 'GOLD', durationDays: 30 },
    ];
    expect(effectiveGrants({ grants })).toEqual(grants);
  });

  it('falls back to a single membership grant when only legacy fields are set', () => {
    const out = effectiveGrants({
      type: 'membership',
      tier: 'SILVER',
      durationDays: 30,
    });
    expect(out).toHaveLength(1);
    expect(out[0]).toEqual({ kind: 'membership', tier: 'SILVER', durationDays: 30 });
  });

  it('falls back to a single coins grant for legacy coin coupons', () => {
    const out = effectiveGrants({ type: 'coins', coinAmount: 500 });
    expect(out).toEqual([{ kind: 'coins', coinAmount: 500 }]);
  });

  it('returns [] when the coupon has neither grants nor a known type', () => {
    expect(effectiveGrants({})).toEqual([]);
    expect(effectiveGrants({ grants: [] })).toEqual([]);
  });
});

describe('summariseGrants — human-readable format', () => {
  it('joins all grants with " · "', () => {
    const out = summariseGrants([
      { kind: 'membership', tier: 'GOLD', durationDays: 30 },
      { kind: 'base_membership', durationDays: 90 },
      { kind: 'coins', coinAmount: 500 },
    ]);
    expect(out).toBe('GOLD +30d · BASE +90d · +500 coins');
  });

  it('handles a single grant', () => {
    expect(summariseGrants([{ kind: 'coins', coinAmount: 100 }])).toBe('+100 coins');
  });
});

describe('hasBaseGrant', () => {
  it('detects an explicit base grant in a bundle', () => {
    expect(
      hasBaseGrant({
        grants: [
          { kind: 'coins', coinAmount: 100 },
          { kind: 'base_membership', durationDays: 30 },
        ],
      }),
    ).toBe(true);
  });
  it('returns false for a membership-only bundle', () => {
    expect(
      hasBaseGrant({
        grants: [{ kind: 'membership', tier: 'GOLD', durationDays: 30 }],
      }),
    ).toBe(false);
  });
  it('returns false for a legacy membership coupon (legacy fallback path)', () => {
    expect(hasBaseGrant({ type: 'membership', tier: 'GOLD', durationDays: 30 })).toBe(false);
  });
  it('returns true for a legacy base_membership coupon (legacy fallback path)', () => {
    expect(hasBaseGrant({ type: 'base_membership', durationDays: 30 })).toBe(true);
  });
});

describe('validateGrant — rejects malformed grants', () => {
  it('rejects unknown kind', () => {
    expect(() => validateGrant({ kind: 'wat' as any })).toThrow(/kind/);
  });
  it('rejects membership grant without tier', () => {
    expect(() => validateGrant({ kind: 'membership', durationDays: 30 } as any)).toThrow(/tier/);
  });
  it('rejects membership grant with unsupported durationDays', () => {
    expect(() =>
      validateGrant({ kind: 'membership', tier: 'GOLD', durationDays: 45 }),
    ).toThrow(/durationDays/);
  });
  it('rejects base_membership grant without durationDays', () => {
    expect(() => validateGrant({ kind: 'base_membership' } as any)).toThrow(/durationDays/);
  });
  it('rejects coins grant with non-positive amount', () => {
    expect(() => validateGrant({ kind: 'coins', coinAmount: 0 })).toThrow(/positive/);
    expect(() => validateGrant({ kind: 'coins', coinAmount: -1 })).toThrow(/positive/);
  });
  it('accepts well-formed grants of every kind', () => {
    expect(() => validateGrant({ kind: 'coins', coinAmount: 100 })).not.toThrow();
    expect(() => validateGrant({ kind: 'base_membership', durationDays: 30 })).not.toThrow();
    expect(() =>
      validateGrant({ kind: 'membership', tier: 'PLATINUM', durationDays: 365 }),
    ).not.toThrow();
  });
});
