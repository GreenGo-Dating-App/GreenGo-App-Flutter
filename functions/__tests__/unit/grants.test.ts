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
