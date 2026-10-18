/**
 * Mandatory verified phone (owner rule 2026-10-17): HMAC index, allowlist,
 * banned-number block, timing rule, experience ID-optional rule.
 */
jest.mock('../../src/shared/firebaseAdmin', () => ({}));
jest.mock('firebase-admin', () => ({
  firestore: Object.assign(() => ({}), { FieldValue: {}, Timestamp: class Timestamp {} }),
  auth: () => ({ getUser: jest.fn() }),
}));

import { decidePhone, phoneHash, tokenHasPhone } from '../../src/safety/phoneIndexLogic';
import { isPhoneNumberSupported, PHONE_VERIFICATION_COUNTRIES } from '../../src/shared/phoneCountries';
import {
  assertPhoneVerified,
  identityRequirementMet,
  phoneRequiredFor,
  PHONE_VERIFICATION_REQUIRED,
} from '../../src/shared/participation';
import { createBlockReason, publishBlockReason } from '../../src/user_experiences/safety';
import {
  bannedPhoneRetainUntil,
  isBannedAccount,
  phoneRequiredMarker,
  runBannedPhoneSweep,
  takeCheck,
} from '../../src/safety/phoneVerification';

const KEY = 'test-phone-index-key-0123456789';

describe('phone index HMAC', () => {
  test('stable, keyed, never the number itself', () => {
    const h = phoneHash('+351912345678', KEY);
    expect(h).toMatch(/^[0-9a-f]{64}$/);
    expect(h).toBe(phoneHash('+351912345678', KEY));
    expect(h).not.toBe(phoneHash('+351912345678', KEY + 'x'));
    expect(h).not.toContain('351912345678');
  });
  test('rejects non-E.164 input', () => {
    expect(() => phoneHash('912345678', KEY)).toThrow('not_e164');
  });
  test('fallback key is derived when PHONE_INDEX_KEY is unset', () => {
    delete process.env.PHONE_INDEX_KEY;
    const a = phoneHash('+351912345678');
    process.env.PHONE_INDEX_KEY = KEY;
    const b = phoneHash('+351912345678');
    delete process.env.PHONE_INDEX_KEY;
    expect(a).not.toBe(b);
  });
});

describe('decidePhone', () => {
  test('allowlist', () => {
    expect(decidePhone('u1', '+351912345678', null)).toEqual({ allowed: true });
    expect(decidePhone('u1', '+919876543210', null)).toEqual({ allowed: false, reason: 'unsupported_country' });
    expect(decidePhone('u1', 'abc', null)).toEqual({ allowed: false, reason: 'invalid_number' });
  });
  test('banned number is blocked for everyone', () => {
    expect(decidePhone('u1', '+351912345678', { banned: true, uid: null }))
      .toEqual({ allowed: false, reason: 'phone_banned' });
  });
  test('number of another live account is in use; own number is fine', () => {
    expect(decidePhone('u2', '+351912345678', { uid: 'u1' })).toEqual({ allowed: false, reason: 'phone_in_use' });
    expect(decidePhone('u1', '+351912345678', { uid: 'u1' })).toEqual({ allowed: true });
  });
  test('token claim', () => {
    expect(tokenHasPhone({ phone_number: '+351912345678' })).toBe(true);
    expect(tokenHasPhone({})).toBe(false);
    expect(tokenHasPhone(null)).toBe(false);
  });
});

describe('country list', () => {
  test('53 countries, no RU/BY', () => {
    expect(PHONE_VERIFICATION_COUNTRIES.length).toBe(53);
    const iso = PHONE_VERIFICATION_COUNTRIES.map(([c]) => c);
    expect(iso).not.toContain('RU');
    expect(iso).not.toContain('BY');
    expect(isPhoneNumberSupported('+18765550123')).toBe(false); // Jamaica (+1)
    expect(isPhoneNumberSupported('+14155550123')).toBe(true);
  });
});

describe('isBannedAccount', () => {
  test('banned shapes, suspension is not a ban', () => {
    expect(isBannedAccount({ banned: true }, null)).toBe(true);
    expect(isBannedAccount(null, { isBanned: true })).toBe(true);
    expect(isBannedAccount(null, { status: 'banned' })).toBe(true);
    expect(isBannedAccount({ accountStatus: 'suspended' }, null)).toBe(false);
    expect(isBannedAccount({}, {})).toBe(false);
  });
});

describe('checkPhoneAllowed rate limit', () => {
  test('10 per hour per uid', () => {
    const t = 1_000_000;
    for (let i = 0; i < 10; i++) expect(takeCheck('rl1', t)).toBe(true);
    expect(takeCheck('rl1', t)).toBe(false);
    expect(takeCheck('rl1', t + 3600_001)).toBe(true);
  });
});

describe('only accounts created on/after 16 Oct 2026 need the phone', () => {
  const legacy = Date.UTC(2026, 4, 1);
  const fresh = Date.UTC(2026, 9, 16, 0, 0, 1);
  const created = (ms: number | null) => async () => ms;
  test('phoneRequiredFor', () => {
    expect(phoneRequiredFor(legacy)).toBe(false);
    expect(phoneRequiredFor(Date.UTC(2026, 9, 15, 23, 59))).toBe(false);
    expect(phoneRequiredFor(Date.UTC(2026, 9, 16))).toBe(true);
    expect(phoneRequiredFor(fresh)).toBe(true);
    expect(phoneRequiredFor(null)).toBe(false);
  });
  test('assertPhoneVerified: old accounts never blocked, new accounts blocked without phone', async () => {
    await expect(assertPhoneVerified({ phone_number: '+351912345678' }, 'u', created(fresh))).resolves.toBeUndefined();
    await expect(assertPhoneVerified({}, 'u', created(legacy))).resolves.toBeUndefined();
    await expect(assertPhoneVerified({}, 'u', created(null))).resolves.toBeUndefined();
    await expect(assertPhoneVerified({}, 'u', created(fresh)))
      .rejects.toMatchObject({ details: { code: PHONE_VERIFICATION_REQUIRED } });
  });
  test('identityRequirementMet', async () => {
    expect(await identityRequirementMet({}, 'u', created(legacy))).toBe(true);
    expect(await identityRequirementMet({}, 'u', created(fresh))).toBe(false);
    expect(await identityRequirementMet({ phone_number: '+351912345678' }, 'u', created(fresh))).toBe(true);
  });
  test('new-account marker', () => {
    expect(phoneRequiredMarker(fresh)).toEqual({ createdAtMs: fresh, reason: 'new_account' });
    expect(phoneRequiredMarker(legacy)).toBeNull();
  });
});

describe('experiences: ID document optional, verified phone satisfies it', () => {
  test('create', () => {
    expect(createBlockReason({})).toBe('id_document_required');
    expect(createBlockReason({}, { phoneVerified: true })).toBeNull();
    expect(createBlockReason({ isBanned: true }, { phoneVerified: true })).toBe('host_banned');
  });
  test('publish paid', () => {
    const profile = { hostAgreementVersion: 1, isBusiness: true, membershipTier: 'GOLD',
      membershipEndDate: Date.now() + 86400000, hostRatingCount: 5 };
    const experience = { isFree: false, paymentMethods: ['online'], paymentProvider: 'stripe' };
    expect(publishBlockReason({ profile, experience, otherPublishedPaid: 0 })).toBe('id_document_required');
    expect(publishBlockReason({ profile, experience, otherPublishedPaid: 0, phoneVerified: true })).toBeNull();
  });
});

describe('banned phone hashes: kept 5 years, then swept', () => {
  test('retainUntil = deletion + 5 years', () => {
    expect(bannedPhoneRetainUntil(Date.UTC(2026, 9, 17, 10))).toBe(Date.UTC(2031, 9, 17, 10));
  });
  test('sweep deletes only expired entries, paged and bounded', async () => {
    const now = Date.UTC(2031, 9, 18);
    const store = new Map<string, number>();
    for (let i = 0; i < 7; i++) store.set(`old${i}`, bannedPhoneRetainUntil(Date.UTC(2026, 9, 17)));
    store.set('young', bannedPhoneRetainUntil(Date.UTC(2027, 0, 1)));
    const deps = {
      page: async (n: number, limit: number) =>
        [...store.entries()].filter(([, r]) => r <= n).slice(0, limit).map(([id]) => id),
      remove: async (ids: string[]) => { ids.forEach((id) => store.delete(id)); },
    };
    const bounded = await runBannedPhoneSweep(now, deps, { pageSize: 3, maxPages: 2 });
    expect(bounded).toEqual({ deleted: 6, pages: 2 });
    const rest = await runBannedPhoneSweep(now, deps, { pageSize: 3, maxPages: 2 });
    expect(rest.deleted).toBe(1);
    expect([...store.keys()]).toEqual(['young']);
  });
});
