/**
 * Membership entitlements on the server (audit 2026-10-11):
 *  - shared/effectiveTier.ts: THE server rule for "which tier does this user
 *    have right now" (L4: had no direct unit test);
 *  - shared/tierLimits.ts must equal the app's TierEntitlements (parsed from
 *    lib/core/services/tier_entitlements.dart) - the numbers the app shows
 *    are the numbers the server enforces - and the rules' tierCap* helpers;
 *  - MONTHLY_COINS (M2) = TierEntitlements.monthlyCoins, and the FREE amount
 *    is paid only with an active Base membership.
 */
import * as fs from 'fs';
import * as path from 'path';
import * as admin from 'firebase-admin';
import {
  effectiveTier,
  hasActivePaidTier,
  isBaseMembershipActive,
  isBusinessActive,
  normalizeStoredTier,
  tierDateFromValue,
} from '../../src/shared/effectiveTier';
import {
  FREE_BOOSTS_PER_MONTH,
  MAX_DAILY_CONNECTS,
  MAX_EVENTS,
  MAX_GROUPS,
  hasPrioritySupport,
  monthKeyUtc,
  supportPriorityFor,
  travelModeEnabled,
  travelModeFree,
  utcDayStartMs,
} from '../../src/shared/tierLimits';

jest.mock('firebase-functions/v2/scheduler', () => ({ onSchedule: (_o: any, h: any) => h }));
jest.mock('firebase-functions/v2/https', () => ({
  onRequest: (_o: any, h: any) => h, onCall: (_o: any, h: any) => h, HttpsError: Error,
}));
jest.mock('../../src/shared/grants', () => ({ grantCoins: jest.fn() }));

const TS = admin.firestore.Timestamp;
const NOW = new Date('2026-10-11T12:00:00Z');
const DAY = 86_400_000;
const future = TS.fromMillis(NOW.getTime() + 30 * DAY);
const past = TS.fromMillis(NOW.getTime() - DAY);
const ALL = ['FREE', 'SILVER', 'GOLD', 'PLATINUM', 'TEST'] as const;

describe('effectiveTier (server)', () => {
  test('paid tiers only while the end date is in the future; missing end = FREE', () => {
    expect(effectiveTier({ membershipTier: 'GOLD', membershipEndDate: future }, NOW)).toBe('GOLD');
    expect(effectiveTier({ membershipTier: 'gold', membershipEndDate: future }, NOW)).toBe('GOLD');
    expect(effectiveTier({ membershipTier: 'GOLD', membershipEndDate: past }, NOW)).toBe('FREE');
    expect(effectiveTier({ membershipTier: 'PLATINUM' }, NOW)).toBe('FREE');
  });

  test('TEST stays TEST, admins keep the stored tier, BASIC/BASE/unknown = FREE', () => {
    expect(effectiveTier({ membershipTier: 'TEST' }, NOW)).toBe('TEST');
    expect(effectiveTier({ membershipTier: 'PLATINUM', isAdmin: true }, NOW)).toBe('PLATINUM');
    for (const t of ['BASIC', 'basic', 'BASE', 'FREE', 'whatever', undefined]) {
      expect(effectiveTier({ membershipTier: t, membershipEndDate: future }, NOW)).toBe('FREE');
    }
    expect(effectiveTier(null, NOW)).toBe('FREE');
    expect(normalizeStoredTier(' silver ')).toBe('SILVER');
  });

  test('end-date shapes: Timestamp, Date, millis, ISO string, {_seconds}', () => {
    const ms = NOW.getTime() + DAY;
    for (const v of [TS.fromMillis(ms), new Date(ms), ms, new Date(ms).toISOString(), { _seconds: ms / 1000 }]) {
      expect(tierDateFromValue(v)?.getTime()).toBe(ms);
      expect(effectiveTier({ membershipTier: 'SILVER', membershipEndDate: v }, NOW)).toBe('SILVER');
    }
    expect(tierDateFromValue('not a date')).toBeNull();
  });

  test('Base membership, active paid tier, business', () => {
    expect(isBaseMembershipActive({ hasBaseMembership: true, baseMembershipEndDate: future }, NOW)).toBe(true);
    expect(isBaseMembershipActive({ hasBaseMembership: true, baseMembershipEndDate: past }, NOW)).toBe(false);
    expect(isBaseMembershipActive({ hasBaseMembership: false, baseMembershipEndDate: future }, NOW)).toBe(false);
    expect(hasActivePaidTier({ membershipTier: 'SILVER', membershipEndDate: future }, NOW)).toBe(true);
    expect(hasActivePaidTier({ membershipTier: 'TEST' }, NOW)).toBe(false);
    expect(isBusinessActive({ isBusiness: true, membershipTier: 'PLATINUM', membershipEndDate: future }, NOW)).toBe(true);
    expect(isBusinessActive({ isBusiness: true, membershipTier: 'PLATINUM', membershipEndDate: past }, NOW)).toBe(false);
    expect(isBusinessActive({ isBusiness: true, membershipTier: 'TEST' }, NOW)).toBe(true);
    expect(isBusinessActive({ isBusiness: false, membershipTier: 'PLATINUM', membershipEndDate: future }, NOW)).toBe(false);
  });
});

// ---------------------------------------------------------------------------
const DART = fs.readFileSync(
  path.resolve(__dirname, '../../../lib/core/services/tier_entitlements.dart'), 'utf8');

/** `static const int? _eventsGold = 5;` -> 5, `= null` -> null */
function dartConst(name: string): number | null {
  const m = DART.match(new RegExp(`static const int\\??\\s+${name}\\s*=\\s*(null|\\d+)\\s*;`));
  if (!m) throw new Error(`const ${name} not found in tier_entitlements.dart`);
  return m[1] === 'null' ? null : Number(m[1]);
}
const TIERS = [['FREE', 'Free'], ['SILVER', 'Silver'], ['GOLD', 'Gold'], ['PLATINUM', 'Platinum']] as const;

describe('server caps = app TierEntitlements = rules (no drift)', () => {
  test.each(TIERS)('%s', (srv, dart) => {
    expect(MAX_EVENTS[srv]).toBe(dartConst(`_events${dart}`));
    expect(MAX_GROUPS[srv]).toBe(dartConst(`_groups${dart}`));
    expect(MAX_DAILY_CONNECTS[srv]).toBe(dartConst(`_dailyConnects${dart}`));
    expect(FREE_BOOSTS_PER_MONTH[srv]).toBe(dartConst(`_boostsPerMonth${dart}`));
  });

  test('TEST = Platinum', () => {
    expect(MAX_EVENTS.TEST).toBe(MAX_EVENTS.PLATINUM);
    expect(MAX_GROUPS.TEST).toBe(MAX_GROUPS.PLATINUM);
    expect(MAX_DAILY_CONNECTS.TEST).toBe(MAX_DAILY_CONNECTS.PLATINUM);
    expect(FREE_BOOSTS_PER_MONTH.TEST).toBe(FREE_BOOSTS_PER_MONTH.PLATINUM);
  });

  test('the same caps are written into both rule files', () => {
    const cap = (n: number | null) => (n === null ? -1 : n);
    for (const f of ['firestore.rules', 'firestore.additive.rules']) {
      const rules = fs.readFileSync(path.resolve(__dirname, '../../..', f), 'utf8');
      const body = (fn: string) => {
        const m = rules.match(new RegExp(`function ${fn}\\(r\\) \\{ return ([^;]+);`));
        if (!m) throw new Error(`${fn} missing in ${f}`);
        return m[1];
      };
      expect(body('tierCapConnects')).toBe(
        `r == 0 ? ${cap(MAX_DAILY_CONNECTS.FREE)} : r == 1 ? ${cap(MAX_DAILY_CONNECTS.SILVER)} : r == 2 ? ${cap(MAX_DAILY_CONNECTS.GOLD)} : ${cap(MAX_DAILY_CONNECTS.PLATINUM)}`);
      expect(body('tierCapEvents')).toBe(
        `r == 0 ? ${cap(MAX_EVENTS.FREE)} : r == 1 ? ${cap(MAX_EVENTS.SILVER)} : r == 2 ? ${cap(MAX_EVENTS.GOLD)} : ${cap(MAX_EVENTS.PLATINUM)}`);
      expect(body('tierCapGroups')).toBe(`r == 0 ? ${cap(MAX_GROUPS.FREE)} : -1`);
      expect(MAX_GROUPS.SILVER).toBeNull();
    }
  });

  test('perk flags', () => {
    expect(ALL.map((t) => travelModeEnabled(t))).toEqual([false, true, true, true, true]);
    expect(ALL.map((t) => travelModeFree(t))).toEqual([false, false, false, true, true]);
    expect(ALL.map((t) => hasPrioritySupport(t))).toEqual([false, false, true, true, true]);
    expect(supportPriorityFor('GOLD')).toEqual({ priority: 'high', priorityRank: 2 });
    expect(supportPriorityFor('PLATINUM')).toEqual({ priority: 'high', priorityRank: 2 });
    expect(supportPriorityFor('SILVER')).toEqual({ priority: 'normal', priorityRank: 1 });
    expect(supportPriorityFor('FREE')).toEqual({ priority: 'normal', priorityRank: 1 });
  });

  test('UTC windows', () => {
    expect(monthKeyUtc(new Date('2026-10-31T23:59:59Z'))).toBe('2026-10');
    expect(monthKeyUtc(new Date('2026-11-01T00:00:00Z'))).toBe('2026-11');
    expect(utcDayStartMs(Date.parse('2026-10-11T23:59:59Z'))).toBe(Date.parse('2026-10-11T00:00:00Z'));
  });
});

// ---------------------------------------------------------------------------
describe('monthly coin allowance (M2)', () => {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const { MONTHLY_COINS, allowanceFor } = require('../../src/coins/monthlyAllowance');

  test.each(TIERS)('%s amount = TierEntitlements.monthlyCoins', (srv, dart) => {
    expect(MONTHLY_COINS[srv]).toBe(dartConst(`_monthlyCoins${dart}`));
  });

  test('the new amounts 20 / 300 / 400 / 500 (not the old 100 / 5000 table)', () => {
    expect(MONTHLY_COINS).toEqual({ FREE: 20, SILVER: 300, GOLD: 400, PLATINUM: 500, TEST: 500 });
  });

  test('FREE without an active Base membership gets nothing; an expired paid tier falls back to Base', () => {
    expect(allowanceFor({ membershipTier: 'FREE' }, NOW)).toEqual({ tier: 'FREE', amount: 0 });
    expect(allowanceFor({ hasBaseMembership: true, baseMembershipEndDate: past }, NOW).amount).toBe(0);
    expect(allowanceFor({ hasBaseMembership: true, baseMembershipEndDate: future }, NOW)).toEqual({ tier: 'FREE', amount: 20 });
    expect(allowanceFor({ membershipTier: 'GOLD', membershipEndDate: past }, NOW).amount).toBe(0);
    expect(allowanceFor({
      membershipTier: 'GOLD', membershipEndDate: past, hasBaseMembership: true, baseMembershipEndDate: future,
    }, NOW).amount).toBe(20);
    expect(allowanceFor({ membershipTier: 'PLATINUM', membershipEndDate: future }, NOW)).toEqual({ tier: 'PLATINUM', amount: 500 });
  });
});
