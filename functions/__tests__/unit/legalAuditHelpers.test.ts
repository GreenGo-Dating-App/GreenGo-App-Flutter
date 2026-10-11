/**
 * Pure helpers of the 2026-10 legal-audit fixes (no emulator needed).
 */
import { poolMembersWithoutOrientation, savedSearchUpdate, TARGET_NAMES } from '../../scripts/purge-sexual-orientation';
import { dropRemovedFields } from '../../src/auth/dataExport';
import { accessLogExpiry, cleanIp, requestIp } from '../../src/auth/accessLogs';
import { coarse, parseGoogle, parseNominatim, validCoordinates } from '../../src/location/reverseGeocodeCoarse';

describe('purge-sexual-orientation helpers', () => {
  test('pool members lose only sexualOrientation; null when nothing to do', () => {
    expect(poolMembersWithoutOrientation({ members: [{ userId: 'a', sexualOrientation: 'x', age: 3 }, { userId: 'b' }] }))
      .toEqual([{ userId: 'a', age: 3 }, { userId: 'b' }]);
    expect(poolMembersWithoutOrientation({ members: [{ userId: 'b' }] })).toBeNull();
    expect(poolMembersWithoutOrientation({})).toBeNull();
    expect(poolMembersWithoutOrientation(undefined)).toBeNull();
  });

  test('saved search update only when the removed filter is present (even empty)', () => {
    expect(savedSearchUpdate({ preferences: { preferredOrientations: [] } }))
      .toHaveProperty(['preferences.preferredOrientations']);
    expect(savedSearchUpdate({ preferences: { minAge: 18 } })).toBeNull();
    expect(savedSearchUpdate({})).toBeNull();
  });

  test('every target is named', () => {
    expect(TARGET_NAMES).toEqual(['profiles', 'profiles_private', 'users', 'users.matchPreferences', 'saved_searches', 'candidate_pools']);
  });
});

describe('dataExport.dropRemovedFields', () => {
  test('removes the fields at any depth and keeps everything else', () => {
    expect(dropRemovedFields({
      a: 1, sexualOrientation: 'x',
      matchPreferences: { minAge: 18, preferredOrientations: ['x'] },
      list: [{ sexualOrientation: 'y', b: 2 }],
    })).toEqual({ a: 1, matchPreferences: { minAge: 18 }, list: [{ b: 2 }] });
  });
});

describe('access log helpers', () => {
  test('expireAt is 6 calendar months + 1 day (end-of-month safe)', () => {
    expect(accessLogExpiry(new Date('2026-10-09T12:00:00Z')).toISOString()).toBe('2027-04-10T12:00:00.000Z');
    expect(accessLogExpiry(new Date('2026-08-31T00:00:00Z')).toISOString()).toBe('2027-03-01T00:00:00.000Z');
  });

  test('IP parsing: last valid X-Forwarded-For hop, mapped IPv4, garbage rejected', () => {
    expect(requestIp({ headers: { 'x-forwarded-for': 'evil, 203.0.113.9' } })).toBe('203.0.113.9');
    expect(requestIp({ headers: { 'x-forwarded-for': '203.0.113.9, junk' } })).toBe('203.0.113.9');
    expect(requestIp({ headers: {}, ip: '::ffff:10.1.2.3' })).toBe('10.1.2.3');
    expect(requestIp({ headers: {}, ip: '2001:DB8::1' })).toBe('2001:db8::1');
    expect(requestIp(undefined)).toBeNull();
    expect(cleanIp('<script>')).toBeNull();
    expect(cleanIp('1.2.3.4:5678')).toBeNull();
  });
});

describe('reverseGeocodeCoarse helpers', () => {
  test('rounding and validation', () => {
    expect(coarse(38.722301)).toBe(38.72);
    expect(coarse(-9.139337)).toBe(-9.14);
    expect(validCoordinates(1, 2)).toBe(true);
    expect(validCoordinates(91, 2)).toBe(false);
    expect(validCoordinates('1', 2)).toBe(false);
    expect(validCoordinates(NaN, 2)).toBe(false);
  });

  test('provider parsing', () => {
    expect(parseNominatim({ address: { town: 'Sintra', country: 'Portugal' } })).toEqual({ city: 'Sintra', country: 'Portugal' });
    expect(parseNominatim({})).toBeNull();
    expect(parseGoogle({
      status: 'OK',
      results: [{ address_components: [
        { long_name: 'Lisbon', types: ['locality'] },
        { long_name: 'Portugal', types: ['country'] },
      ] }],
    })).toEqual({ city: 'Lisbon', country: 'Portugal' });
    expect(parseGoogle({ status: 'ZERO_RESULTS', results: [] })).toBeNull();
  });
});
