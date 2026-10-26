/**
 * businessGeohash (owner rule 2026-10-19: Discover finds businesses by their
 * BUSINESS ADDRESS). The public profile carries the precision-9 geohash of
 * `businessAddress` while `isBusiness` is true; the profile triggers
 * (mirrorPrivateProfileFields / syncCoarseFromPrivateProfile) compute it as a
 * coarse field. Pure helpers here; the emulator round trip + rules live in
 * __tests__/security/business-geohash.emulator.test.ts.
 */
import * as admin from 'firebase-admin';
import {
  BUSINESS_GEOHASH_FIELD,
  businessGeohashOf,
  coarseInputsChanged,
  coarseUpdates,
  computeCoarse,
  geohashEncode,
  handlePublicProfileWrite,
} from '../../src/profiles/privateProfile';
import { businessGeohashUpdate } from '../../src/profiles/businessGeohash';

const SP: [number, number] = [-23.5505, -46.6333];
const RIO: [number, number] = [-22.9068, -43.1729];
const KEY = 'k'.repeat(32);
const PKEY = 'p'.repeat(32);
const addr = (c: [number, number], address = 'Rua A, 1') =>
  ({ address, latitude: c[0], longitude: c[1], city: 'X', country: 'Brazil', geohash: 'client-value' });
const biz = (c: [number, number], extra: Record<string, any> = {}) =>
  ({ isBusiness: true, businessAddress: addr(c), ...extra });
const DELETE = admin.firestore.FieldValue.delete();

describe('businessGeohashOf', () => {
  test('precision-9 geohash of the storefront address (not the client value)', () => {
    const g = businessGeohashOf(biz(SP));
    expect(g).toBe(geohashEncode(SP[0], SP[1], 9));
    expect(g).toHaveLength(9);
  });

  test('null when not a business, no address, or unusable address', () => {
    expect(businessGeohashOf(undefined)).toBeNull();
    expect(businessGeohashOf({})).toBeNull();
    expect(businessGeohashOf({ isBusiness: false, businessAddress: addr(SP) })).toBeNull();
    expect(businessGeohashOf({ isBusiness: 'true', businessAddress: addr(SP) })).toBeNull();
    expect(businessGeohashOf({ isBusiness: true })).toBeNull();
    expect(businessGeohashOf({ isBusiness: true, businessAddress: null })).toBeNull();
    expect(businessGeohashOf({ isBusiness: true, businessAddress: addr([0, 0]) })).toBeNull();
    expect(businessGeohashOf({ isBusiness: true, businessAddress: addr([91, 1]) })).toBeNull();
    expect(businessGeohashOf({ isBusiness: true, businessAddress: { ...addr(SP), latitude: '1' } })).toBeNull();
    expect(businessGeohashOf({ isBusiness: true, businessAddress: addr(SP, '   ') })).toBeNull();
  });

  test('independent of the owner personal / traveller location', () => {
    const c = computeCoarse('u', biz(SP), { location: { latitude: 41.9, longitude: 12.5 } }, new Date(), KEY, PKEY);
    expect(c.businessGeohash).toBe(geohashEncode(SP[0], SP[1], 9));
    expect(c.geohash5).toBe(geohashEncode(41.9, 12.5, 5));
  });
});

describe('trigger write set (coarseUpdates)', () => {
  test('computes the field for a business with an address', () => {
    const upd = coarseUpdates({ ...biz(SP) }, computeCoarse('u', biz(SP), {}, new Date(), KEY, PKEY));
    expect(upd[BUSINESS_GEOHASH_FIELD]).toBe(geohashEncode(SP[0], SP[1], 9));
  });

  test('moves with the address', () => {
    const stored = { ...biz(RIO), businessGeohash: geohashEncode(SP[0], SP[1], 9) };
    const upd = coarseUpdates(stored, computeCoarse('u', stored, {}, new Date(), KEY, PKEY));
    expect(upd[BUSINESS_GEOHASH_FIELD]).toBe(geohashEncode(RIO[0], RIO[1], 9));
  });

  test('clears it when the profile stops being a business or the address is removed', () => {
    const g = geohashEncode(SP[0], SP[1], 9);
    for (const pub of [
      { ...biz(SP), isBusiness: false, businessGeohash: g },
      { isBusiness: true, businessAddress: null, businessGeohash: g },
    ]) {
      const upd = coarseUpdates(pub, computeCoarse('u', pub, {}, new Date(), KEY, PKEY));
      expect(upd[BUSINESS_GEOHASH_FIELD]).toEqual(DELETE);
    }
  });

  test('no write when unchanged (and no delete when never set)', () => {
    const pub = { ...biz(SP), businessGeohash: geohashEncode(SP[0], SP[1], 9) };
    expect(coarseUpdates(pub, computeCoarse('u', pub, {}, new Date(), KEY, PKEY))[BUSINESS_GEOHASH_FIELD]).toBeUndefined();
    const person = { isBusiness: false };
    expect(coarseUpdates(person, computeCoarse('u', person, {}, new Date(), KEY, PKEY))).not.toHaveProperty(BUSINESS_GEOHASH_FIELD);
  });

  test('backfill update helper: same rules', () => {
    expect(businessGeohashUpdate(biz(SP))).toEqual({ businessGeohash: geohashEncode(SP[0], SP[1], 9) });
    expect(businessGeohashUpdate({ ...biz(SP), businessGeohash: geohashEncode(SP[0], SP[1], 9) })).toBeNull();
    expect(businessGeohashUpdate({ isBusiness: false, businessGeohash: 'x' })).toEqual({ businessGeohash: DELETE });
    expect(businessGeohashUpdate({ isBusiness: false })).toBeNull();
    expect(businessGeohashUpdate(undefined)).toBeNull();
  });
});

describe('trigger inputs (no loops, no reads on unrelated writes)', () => {
  test('isBusiness and address changes are coarse inputs', () => {
    expect(coarseInputsChanged({ isBusiness: false }, { isBusiness: true })).toBe(true);
    expect(coarseInputsChanged(biz(SP), biz(RIO))).toBe(true);
    expect(coarseInputsChanged(biz(SP), { isBusiness: true, businessAddress: null })).toBe(true);
    expect(coarseInputsChanged(biz(SP), { isBusiness: true, businessAddress: addr(SP, 'Rua B, 2') })).toBe(true);
  });

  test('the trigger\'s own businessGeohash write is not an input', () => {
    expect(coarseInputsChanged(biz(SP), { ...biz(SP), businessGeohash: 'abc' })).toBe(false);
    // Nor are unrelated storefront fields.
    expect(coarseInputsChanged(biz(SP), { ...biz(SP), businessName: 'New', isOnline: true })).toBe(false);
  });

  test('handlePublicProfileWrite skips (no read, no write) when no input changed', async () => {
    const fs = {
      runTransaction: jest.fn(),
      collection: jest.fn(() => { throw new Error('must not read'); }),
    } as unknown as admin.firestore.Firestore;
    const before = { ...biz(SP), lastSeen: 1 };
    const after = { ...biz(SP), lastSeen: 2, businessGeohash: geohashEncode(SP[0], SP[1], 9) };
    expect(await handlePublicProfileWrite('u', before, after, { firestore: fs })).toBe('skipped');
    expect((fs as any).runTransaction).not.toHaveBeenCalled();
  });

  test('handlePublicProfileWrite syncs when the address changes', async () => {
    const tx = { getAll: jest.fn(), set: jest.fn(), update: jest.fn() };
    const after = biz(RIO);
    tx.getAll.mockResolvedValue([
      { exists: true, data: () => after },
      { exists: false, data: () => undefined },
    ]);
    const fs = {
      collection: () => ({ doc: (id: string) => ({ id }) }),
      runTransaction: async (fn: any) => fn(tx),
    } as unknown as admin.firestore.Firestore;
    const r = await handlePublicProfileWrite('u', biz(SP), after, { firestore: fs });
    expect(r).toMatchObject({ publicWrites: 1, publicFields: ['businessGeohash'] });
    expect(tx.update).toHaveBeenCalledWith({ id: 'u' }, { businessGeohash: geohashEncode(RIO[0], RIO[1], 9) });
  });
});

describe('Store visibility (owner choice) and businessGeohash', () => {
  it('a store hidden from Discover or fully hidden has no geohash (geo queries never read it)', () => {
    expect(businessGeohashOf(biz(SP, { storeVisibility: 'hidden' }))).toBeNull();
    expect(businessGeohashOf(biz(SP, { storeVisibility: 'off' }))).toBeNull();
    expect(businessGeohashOf(biz(SP, { storeVisibility: 'visible' }))).toBe(geohashEncode(SP[0], SP[1], 9));
    expect(businessGeohashOf(biz(SP, { storeVisibility: 'nonsense' }))).toBe(geohashEncode(SP[0], SP[1], 9));
  });

  it('changing only storeVisibility re-runs the coarse sync, which drops then restores the field', () => {
    const shown = { ...biz(SP), businessGeohash: geohashEncode(SP[0], SP[1], 9) };
    const hidden = { ...shown, storeVisibility: 'hidden' };
    expect(coarseInputsChanged(shown, hidden)).toBe(true);
    expect(businessGeohashUpdate(hidden)).toEqual({ businessGeohash: DELETE });
    const back = { ...biz(SP), storeVisibility: 'visible' };
    expect(businessGeohashUpdate(back)).toEqual({ businessGeohash: geohashEncode(SP[0], SP[1], 9) });
  });
});
