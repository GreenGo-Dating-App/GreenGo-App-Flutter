/**
 * Tests for the applySignupGrants Firestore trigger.
 *
 * Deep happy-path testing (multi-coupon transactional grants) is best done
 * against the emulator; these unit tests cover the guards that decide
 * whether the trigger even reaches the grant logic.
 */

jest.mock('firebase-admin', () => {
  const firestoreFn: any = () => ({});
  firestoreFn.Timestamp = {
    fromDate: (d: Date) => ({ toDate: () => d, toMillis: () => d.getTime() }),
    now: () => ({ toDate: () => new Date(), toMillis: () => Date.now() }),
  };
  firestoreFn.FieldValue = { increment: (n: number) => n };
  return {
    apps: [{ name: '[DEFAULT]' }],
    initializeApp: jest.fn(),
    firestore: firestoreFn,
    storage: () => ({ bucket: () => ({}) }),
    auth: () => ({}),
  };
});

// Controlled in-memory state per test
let mockProfileData: any = null;
let mockCouponDocs: any[] = [];
const profileWrites: any[] = [];

const fakeDb: any = {
  collection: jest.fn(() => fakeDb),
  doc: jest.fn(() => fakeDb),
  where: jest.fn(() => fakeDb),
  limit: jest.fn(() => fakeDb),
  get: jest.fn(async () => {
    // Generic get — disambiguate by stack: returns profile or coupons query
    // based on the last collection() call. Simpler to inspect call list.
    const lastCol = (fakeDb.collection as jest.Mock).mock.calls.slice(-1)[0]?.[0];
    if (lastCol === 'profiles') {
      return { exists: mockProfileData !== null, data: () => mockProfileData };
    }
    return {
      empty: mockCouponDocs.length === 0,
      docs: mockCouponDocs,
      size: mockCouponDocs.length,
    };
  }),
  set: jest.fn(async (data: any) => {
    profileWrites.push(data);
  }),
  runTransaction: jest.fn(async (cb: any) => {
    const tx = { get: jest.fn(), set: jest.fn(), update: jest.fn() };
    return cb(tx);
  }),
};

jest.mock('../../src/shared/utils', () => ({
  db: fakeDb,
  logInfo: jest.fn(),
  logError: jest.fn(),
}));
jest.mock('../../src/notifications/couponEmails', () => ({
  sendCouponRedeemedEmail: jest.fn(async () => undefined),
}));

import { applySignupGrants } from '../../src/coupons/applySignupGrants';

const fire = async (opts: { uid: string; email?: string | null }) => {
  const handler: any = applySignupGrants as any;
  const event = {
    params: { userId: opts.uid },
    data: opts.email === undefined ? undefined : { data: () => ({ email: opts.email }) },
  };
  return await handler.run(event);
};

beforeEach(() => {
  mockProfileData = null;
  mockCouponDocs = [];
  profileWrites.length = 0;
  jest.clearAllMocks();
});

describe('applySignupGrants — guard paths', () => {
  it('skips when the new user doc has no email', async () => {
    await fire({ uid: 'u1', email: null });
    expect(fakeDb.runTransaction).not.toHaveBeenCalled();
    expect(profileWrites).toHaveLength(0);
  });

  it('short-circuits when signupGrantsAppliedAt is already set (idempotency)', async () => {
    mockProfileData = { signupGrantsAppliedAt: { toDate: () => new Date(), toMillis: () => 1 } };
    await fire({ uid: 'u1', email: 'a@b.com' });
    expect(fakeDb.runTransaction).not.toHaveBeenCalled();
    expect(profileWrites).toHaveLength(0);
  });

  it('marks the profile as processed when no coupons match (prevents repeated queries)', async () => {
    mockProfileData = null;
    mockCouponDocs = []; // no matches
    await fire({ uid: 'u1', email: 'newuser@b.com' });
    // Should NOT have entered the per-coupon transaction loop.
    expect(fakeDb.runTransaction).not.toHaveBeenCalled();
    // But SHOULD have written a marker so we don't re-query forever.
    expect(profileWrites).toHaveLength(1);
    expect(profileWrites[0]).toHaveProperty('signupGrantsAppliedAt');
  });
});
