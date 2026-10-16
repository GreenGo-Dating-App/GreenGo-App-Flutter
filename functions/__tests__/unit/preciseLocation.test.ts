/**
 * preciseLocation (owner rule 2026-10-16): with globeDiscoverability 'exact'
 * the public profile carries the discoverable location + a stable per-user
 * offset of at most 100 m; any other setting removes it. Pure helpers only;
 * the trigger round trips run in
 * __tests__/security/privacy-profiles.emulator.test.ts.
 */
import * as admin from 'firebase-admin';
import {
  PRECISE_JITTER_MAX_M,
  PRECISE_JITTER_MIN_M,
  coarseInputsChanged,
  coarseUpdates,
  computeCoarse,
  jitterOffsetMeters,
  preciseLocationFor,
  preciseOffsetMeters,
} from '../../src/profiles/privateProfile';

function dist(a: [number, number], b: [number, number]): number {
  const R = 6371000, r = Math.PI / 180;
  const dLat = (b[0] - a[0]) * r, dLng = (b[1] - a[1]) * r;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(a[0] * r) * Math.cos(b[0] * r) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

const ROME: [number, number] = [41.89893, 12.47311];
const MILAN: [number, number] = [45.46416, 9.19199];
const KEY = 'k'.repeat(32);
const PKEY = 'p'.repeat(32);
const home = (c: [number, number]) => ({ location: { latitude: c[0], longitude: c[1] } });

describe('preciseOffsetMeters', () => {
  test('PRECISE_JITTER_MAX_M is the documented 100 m bound', () => {
    expect(PRECISE_JITTER_MAX_M).toBe(100);
  });

  test('stable per user, different between users, within [min, 100 m)', () => {
    expect(preciseOffsetMeters('user-1', PKEY)).toEqual(preciseOffsetMeters('user-1', PKEY));
    expect(preciseOffsetMeters('user-1', PKEY)).not.toEqual(preciseOffsetMeters('user-2', PKEY));
    for (let i = 0; i < 2000; i++) {
      const o = preciseOffsetMeters(`u${i}`, PKEY);
      const r = Math.hypot(o.north, o.east);
      expect(r).toBeLessThan(PRECISE_JITTER_MAX_M);
      expect(r).toBeGreaterThanOrEqual(PRECISE_JITTER_MIN_M - 1e-9);
    }
  });

  test('independent of the approxLocation offset (different key AND message)', () => {
    // Same key for both: the messages differ, so the outputs still differ.
    for (let i = 0; i < 50; i++) {
      const a = jitterOffsetMeters(`u${i}`, KEY);
      const p = preciseOffsetMeters(`u${i}`, KEY);
      expect(Math.atan2(a.east, a.north)).not.toBeCloseTo(Math.atan2(p.east, p.north), 6);
    }
    // Default keys: also different (derived precise key).
    const a = jitterOffsetMeters('user-1');
    const p = preciseOffsetMeters('user-1');
    expect(Math.atan2(a.east, a.north)).not.toBeCloseTo(Math.atan2(p.east, p.north), 6);
  });

  test('published point is <= 100 m from the stored location, everywhere incl. high latitudes', () => {
    const spots: [number, number][] = [ROME, MILAN, [-33.8688, 151.2093], [64.1466, -21.9426], [78.2232, 15.6267], [0.0001, 179.9995]];
    for (const s of spots) {
      for (let i = 0; i < 300; i++) {
        const p = preciseLocationFor(`u${i}`, s[0], s[1], PKEY);
        expect(dist(s, [p.lat, p.lng])).toBeLessThanOrEqual(PRECISE_JITTER_MAX_M);
      }
    }
  });
});

describe('computeCoarse / coarseUpdates: preciseLocation', () => {
  test('only for globeDiscoverability exact', () => {
    for (const g of [undefined, 'approximate', 'country', 'hidden', 'EXACT']) {
      expect(computeCoarse('u', { globeDiscoverability: g }, home(ROME), new Date(), KEY, PKEY).preciseLocation).toBeNull();
    }
    const c = computeCoarse('u', { globeDiscoverability: 'exact' }, home(ROME), new Date(), KEY, PKEY);
    expect(c.preciseLocation).toEqual(preciseLocationFor('u', ROME[0], ROME[1], PKEY));
    expect(dist(ROME, [c.preciseLocation!.lat, c.preciseLocation!.lng])).toBeLessThanOrEqual(100);
    // The coarse fields are unaffected by the setting.
    const c2 = computeCoarse('u', {}, home(ROME), new Date(), KEY, PKEY);
    expect({ ...c, preciseLocation: null }).toEqual(c2);
  });

  test('no location -> no preciseLocation even when exact', () => {
    expect(computeCoarse('u', { globeDiscoverability: 'exact' }, {}, new Date(), KEY, PKEY).preciseLocation).toBeNull();
  });

  test('traveller mode: follows the active travel location exactly like approxLocation', () => {
    const now = new Date();
    const pub = {
      globeDiscoverability: 'exact', isTraveler: true,
      travelerExpiry: new Date(now.getTime() + 86400000),
    };
    const priv = { ...home(ROME), travelerLocation: { latitude: MILAN[0], longitude: MILAN[1] } };
    const c = computeCoarse('t', pub, priv, now, KEY, PKEY);
    expect(dist(MILAN, [c.preciseLocation!.lat, c.preciseLocation!.lng])).toBeLessThanOrEqual(100);
    const expired = computeCoarse('t', { ...pub, travelerExpiry: new Date(now.getTime() - 1000) }, priv, now, KEY, PKEY);
    expect(dist(ROME, [expired.preciseLocation!.lat, expired.preciseLocation!.lng])).toBeLessThanOrEqual(100);
  });

  test('switching away from exact deletes the stored field; unchanged value writes nothing', () => {
    const stored = { preciseLocation: { lat: 1, lng: 2 } };
    const off = coarseUpdates(stored, computeCoarse('u', { globeDiscoverability: 'approximate' }, home(ROME), new Date(), KEY, PKEY));
    expect(off.preciseLocation).toEqual(admin.firestore.FieldValue.delete());
    const want = computeCoarse('u', { globeDiscoverability: 'exact' }, home(ROME), new Date(), KEY, PKEY);
    const stored2 = Object.fromEntries(Object.entries(want).filter(([, v]) => v !== null));
    const same = coarseUpdates(stored2, want);
    expect(same).toEqual({});
    // Nothing stored and not exact: no delete op either (no useless write).
    const none = coarseUpdates({}, computeCoarse('u', {}, home(ROME), new Date(), KEY, PKEY));
    expect(none.preciseLocation).toBeUndefined();
  });

  test('a globeDiscoverability change is a coarse input; the coarse write itself is not', () => {
    expect(coarseInputsChanged({ globeDiscoverability: 'approximate' }, { globeDiscoverability: 'exact' })).toBe(true);
    expect(coarseInputsChanged({ globeDiscoverability: 'exact' }, { globeDiscoverability: 'hidden' })).toBe(true);
    expect(coarseInputsChanged(
      { globeDiscoverability: 'exact' },
      { globeDiscoverability: 'exact', preciseLocation: { lat: 1, lng: 2 } },
    )).toBe(false);
  });
});
