/**
 * Smoke tests for redeemCoupon — focuses on the error-code mapping
 * since the tier extension itself is exhaustively covered by
 * grants.test.ts. We stub Firestore via a fake runTransaction.
 */

const tsFromDate = (d: Date) => ({ toDate: () => d, toMillis: () => d.getTime() });
const tsNow = () => tsFromDate(new Date());

jest.mock('firebase-admin', () => {
  const firestoreFn: any = () => ({});
  firestoreFn.Timestamp = {
    fromDate: tsFromDate,
    now: tsNow,
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

// In-memory state controlled per test
let mockCouponDoc: any = null;
let mockRedemptionExists = false;

const makeRef = (path: string): any => {
  const ref: any = { id: path.split('/').pop() || 'doc', path };
  ref.collection = (name: string) => ({
    doc: (id: string) => makeRef(`${path}/${name}/${id}`),
  });
  return ref;
};

// A "query" is a separate object from a doc ref so the tx.get dispatcher
// can tell them apart.
const QUERY_MARKER: any = { __query: true };
QUERY_MARKER.where = jest.fn(() => QUERY_MARKER);
QUERY_MARKER.limit = jest.fn(() => QUERY_MARKER);

const fakeDb: any = {
  collection: jest.fn((name: string) => ({
    where: (..._args: any[]) => QUERY_MARKER,
    doc: (id: string) => makeRef(`${name}/${id || 'auto'}`),
    add: jest.fn(),
  })),
  runTransaction: jest.fn(async (cb: any) => {
    const tx: any = {
      get: jest.fn(async (refOrQuery: any) => {
        if (refOrQuery === QUERY_MARKER || refOrQuery?.__query) {
          return {
            empty: mockCouponDoc === null,
            docs: mockCouponDoc
              ? [{ ref: makeRef('coupons/c1'), data: () => mockCouponDoc }]
              : [],
          };
        }
        // Direct doc reads — redemption / profile / balance.
        if (refOrQuery?.path?.includes('/redemptions/')) {
          return { exists: mockRedemptionExists };
        }
        if (refOrQuery?.path?.startsWith('profiles/')) {
          return { exists: false, data: () => ({}) };
        }
        if (refOrQuery?.path?.startsWith('coinBalances/')) {
          return { exists: false, data: () => ({}) };
        }
        return { exists: false, data: () => ({}) };
      }),
      set: jest.fn(),
      update: jest.fn(),
    };
    return cb(tx);
  }),
};

jest.mock('../../src/shared/utils', () => ({
  db: fakeDb,
  logInfo: jest.fn(),
  logError: jest.fn(),
  FieldValue: { increment: (n: number) => n },
}));

// Stub the email notifier so the test doesn't try to hit Brevo
jest.mock('../../src/notifications/couponEmails', () => ({
  sendCouponRedeemedEmail: jest.fn(async () => undefined),
}));

import { redeemCoupon } from '../../src/coupons/redeemCoupon';

// firebase-functions/v2/https exports a CallableRequest type but at runtime
// the `onCall` returns a wrapped callable. We invoke its `.run` directly.
const callRedeem = async (opts: { uid?: string | null; email?: string; code?: string }) => {
  const handler: any = redeemCoupon as any;
  const request: any = {
    auth: opts.uid ? { uid: opts.uid, token: { email: opts.email } } : undefined,
    data: { code: opts.code ?? 'GG-TEST' },
  };
  return await handler.run(request);
};

beforeEach(() => {
  mockCouponDoc = null;
  mockRedemptionExists = false;
  jest.clearAllMocks();
  fakeDb.collection.mockImplementation((name: string) => ({
    where: (..._args: any[]) => QUERY_MARKER,
    doc: (id: string) => makeRef(`${name}/${id || 'auto'}`),
    add: jest.fn(),
  }));
});

describe('redeemCoupon — error mapping', () => {
  it('rejects unauthenticated callers with code=unauthenticated', async () => {
    await expect(callRedeem({ uid: null })).rejects.toMatchObject({
      code: 'unauthenticated',
    });
  });

  it('rejects an empty code with invalid-argument', async () => {
    await expect(callRedeem({ uid: 'u1', email: 'a@b', code: '   ' })).rejects.toMatchObject({
      code: 'invalid-argument',
    });
  });

  it('returns not-found when the code does not match any coupon', async () => {
    mockCouponDoc = null;
    await expect(callRedeem({ uid: 'u1', email: 'a@b', code: 'BAD' })).rejects.toMatchObject({
      code: 'not-found',
    });
  });

  it('returns failed-precondition when the coupon is disabled', async () => {
    mockCouponDoc = {
      code: 'GG-X',
      type: 'coins',
      tier: null,
      coinAmount: 100,
      durationDays: 30,
      maxRedemptions: null,
      redemptionsCount: 0,
      expiresAt: null,
      allowedEmail: null,
      disabled: true,
    };
    await expect(callRedeem({ uid: 'u1', email: 'a@b', code: 'GG-X' })).rejects.toMatchObject({
      code: 'failed-precondition',
    });
  });

  it('returns failed-precondition when the coupon has expired', async () => {
    mockCouponDoc = {
      code: 'GG-X',
      type: 'coins',
      coinAmount: 100,
      durationDays: 30,
      maxRedemptions: null,
      redemptionsCount: 0,
      expiresAt: tsFromDate(new Date(Date.now() - 24 * 3600 * 1000)),
      allowedEmail: null,
      disabled: false,
    };
    await expect(callRedeem({ uid: 'u1', email: 'a@b', code: 'GG-X' })).rejects.toMatchObject({
      code: 'failed-precondition',
    });
  });

  it('returns failed-precondition when max redemptions are reached', async () => {
    mockCouponDoc = {
      code: 'GG-X',
      type: 'coins',
      coinAmount: 100,
      durationDays: 30,
      maxRedemptions: 5,
      redemptionsCount: 5,
      expiresAt: null,
      allowedEmail: null,
      disabled: false,
    };
    await expect(callRedeem({ uid: 'u1', email: 'a@b', code: 'GG-X' })).rejects.toMatchObject({
      code: 'failed-precondition',
    });
  });

  it('returns permission-denied when the email gate does not match', async () => {
    mockCouponDoc = {
      code: 'GG-X',
      type: 'coins',
      coinAmount: 100,
      durationDays: 30,
      maxRedemptions: null,
      redemptionsCount: 0,
      expiresAt: null,
      allowedEmail: 'vip@greengo.app',
      disabled: false,
    };
    await expect(
      callRedeem({ uid: 'u1', email: 'other@user.com', code: 'GG-X' }),
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('accepts a bundle coupon with coins + base + membership and returns a multi-part summary', async () => {
    mockCouponDoc = {
      code: 'GG-BUNDLE',
      // Legacy fields absent — effectiveGrants reads from the bundle.
      type: null,
      tier: null,
      coinAmount: null,
      durationDays: null,
      grants: [
        { kind: 'coins', coinAmount: 500 },
        { kind: 'base_membership', durationDays: 90 },
        { kind: 'membership', tier: 'GOLD', durationDays: 30 },
      ],
      maxRedemptions: 1,
      redemptionsCount: 0,
      expiresAt: null,
      allowedEmail: null,
      disabled: false,
    };
    const res: any = await callRedeem({ uid: 'u1', email: 'a@b.com', code: 'GG-BUNDLE' });
    expect(res.ok).toBe(true);
    expect(res.grantSummary).toContain('+500 coins');
    expect(res.grantSummary).toContain('BASE +90d');
    expect(res.grantSummary).toContain('GOLD +30d');
    expect(res.grants).toHaveLength(3);
    // Backward-compat fields populated from the first matching grant.
    expect(res.tier).toBe('GOLD');
    expect(res.coinAmount).toBe(500);
  });

  it('rejects a misconfigured coupon with neither type nor grants', async () => {
    mockCouponDoc = {
      code: 'GG-EMPTY',
      type: null,
      grants: [],
      maxRedemptions: null,
      redemptionsCount: 0,
      expiresAt: null,
      allowedEmail: null,
      disabled: false,
    };
    await expect(
      callRedeem({ uid: 'u1', email: 'a@b.com', code: 'GG-EMPTY' }),
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });
});
