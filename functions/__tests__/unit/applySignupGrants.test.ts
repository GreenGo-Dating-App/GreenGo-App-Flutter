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
    const tx: any = {
      get: jest.fn(async () => ({
        exists: mockProfileData !== null,
        data: () => mockProfileData,
      })),
      set: jest.fn((_ref: any, data: any) => {
        profileWrites.push(data);
      }),
      update: jest.fn(),
    };
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
    // Should have entered the marker transaction exactly once.
    expect(fakeDb.runTransaction).toHaveBeenCalledTimes(1);
    expect(profileWrites).toHaveLength(1);
    expect(profileWrites[0]).toHaveProperty('signupGrantsAppliedAt');
  });

  it('skips the final write when a concurrent invocation already wrote signupGrantsAppliedAt', async () => {
    // First call: profile starts empty, marker is written.
    mockProfileData = null;
    mockCouponDocs = [];
    await fire({ uid: 'u1', email: 'newuser@b.com' });
    expect(profileWrites).toHaveLength(1);

    // Second call: simulate the profile now has the marker (winner of the race).
    // The outer guard catches it before the transaction; transaction never fires.
    profileWrites.length = 0;
    mockProfileData = { signupGrantsAppliedAt: { toDate: () => new Date(), toMillis: () => 1 } };
    (fakeDb.runTransaction as jest.Mock).mockClear();
    await fire({ uid: 'u1', email: 'newuser@b.com' });
    expect(fakeDb.runTransaction).not.toHaveBeenCalled();
    expect(profileWrites).toHaveLength(0);
  });
});
