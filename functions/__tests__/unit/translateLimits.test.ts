/**
 * Daily translation allowance by membership (owner rule 2026-10-13):
 * no plan 3k, Base 10k, Silver 25k, Gold 50k, Platinum / TEST 100k characters.
 */
import { TRANSLATE_CHARS_DAILY, translateCharsDailyLimit } from '../../src/shared/tierLimits';

const NOW = new Date('2026-10-13T12:00:00Z');
const future = new Date('2027-10-13T12:00:00Z');
const past = new Date('2026-09-01T12:00:00Z');

test('the allowance grows with the plan', () => {
  expect(TRANSLATE_CHARS_DAILY).toEqual({ NONE: 3000, BASE: 10000, SILVER: 25000, GOLD: 50000, PLATINUM: 100000 });
});

test('each plan gets its own allowance', () => {
  expect(translateCharsDailyLimit({ membershipTier: 'FREE', hasBaseMembership: false }, NOW)).toBe(3000);
  expect(translateCharsDailyLimit(undefined, NOW)).toBe(3000);
  expect(translateCharsDailyLimit({ membershipTier: 'FREE', hasBaseMembership: true, baseMembershipEndDate: future }, NOW)).toBe(10000);
  expect(translateCharsDailyLimit({ membershipTier: 'SILVER', membershipEndDate: future }, NOW)).toBe(25000);
  expect(translateCharsDailyLimit({ membershipTier: 'GOLD', membershipEndDate: future }, NOW)).toBe(50000);
  expect(translateCharsDailyLimit({ membershipTier: 'PLATINUM', membershipEndDate: future }, NOW)).toBe(100000);
});

test('an expired plan falls back to what is still active', () => {
  expect(translateCharsDailyLimit({ membershipTier: 'GOLD', membershipEndDate: past }, NOW)).toBe(3000);
  expect(translateCharsDailyLimit({
    membershipTier: 'GOLD', membershipEndDate: past, hasBaseMembership: true, baseMembershipEndDate: future,
  }, NOW)).toBe(10000);
  expect(translateCharsDailyLimit({ membershipTier: 'FREE', hasBaseMembership: true, baseMembershipEndDate: past }, NOW)).toBe(3000);
});
