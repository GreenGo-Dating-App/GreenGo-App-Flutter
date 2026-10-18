/**
 * Optional ID-document details (safety/identityRecords.ts): encryption,
 * validation, the authority reveal (super admin + basis + reference, audit
 * written BEFORE decrypting) and the retention sweep (legal holds win).
 */
import * as crypto from 'crypto';

// ── Minimal in-memory Firestore ─────────────────────────────────────────────
const events: string[] = [];
const store = new Map<string, Map<string, any>>();
const DELETE = { __delete: true };
const ts = (ms: number) => ({ toMillis: () => ms, __ts: ms });
const col = (name: string) => {
  if (!store.has(name)) store.set(name, new Map());
  return store.get(name)!;
};
let autoId = 0;
const docRef = (name: string, id: string): any => ({
  id,
  get: async () => ({ id, exists: col(name).has(id), data: () => col(name).get(id) }),
  set: async (data: any, opts?: any) => {
    events.push(`set:${name}`);
    col(name).set(id, opts?.merge ? { ...(col(name).get(id) ?? {}), ...data } : { ...data });
  },
  update: async (patch: any) => {
    const cur = { ...(col(name).get(id) ?? {}) };
    for (const [k, v] of Object.entries(patch)) {
      if (v === DELETE) delete cur[k];
      else cur[k] = v;
    }
    col(name).set(id, cur);
  },
  delete: async () => {
    events.push(`delete:${name}/${id}`);
    col(name).delete(id);
  },
});
const query = (name: string, filters: Array<[string, number]>, lim = 1000): any => ({
  where: (f: string, _op: string, v: any) => query(name, [...filters, [f, v.toMillis()]], lim),
  orderBy: () => query(name, filters, lim),
  limit: (n: number) => query(name, filters, n),
  get: async () => {
    const docs = [...col(name).entries()]
      .filter(([, d]) => filters.every(([f, v]) => d[f]?.toMillis && d[f].toMillis() <= v))
      .slice(0, lim)
      .map(([id, d]) => ({ id, data: () => d, ref: docRef(name, id) }));
    return { docs, size: docs.length };
  },
});
const fakeDb = {
  collection: (name: string) => ({
    doc: (id: string) => docRef(name, id),
    add: async (data: any) => {
      events.push(`add:${name}`);
      col(name).set(`auto${++autoId}`, data);
    },
    where: (f: string, op: string, v: any) => query(name, []).where(f, op, v),
  }),
  runTransaction: async (fn: any) =>
    fn({
      get: (ref: any) => ref.get(),
      set: (ref: any, d: any) => ref.set(d),
    }),
};

jest.mock('firebase-functions/v2/https', () => ({
  onCall: (_o: any, h: any) => h,
  HttpsError: class HttpsError extends Error {
    code: string;
    constructor(code: string, message: string) {
      super(message);
      this.code = code;
    }
  },
}));
jest.mock('firebase-functions/v2/scheduler', () => ({ onSchedule: (_o: any, h: any) => h }));
jest.mock('firebase-functions/params', () => ({ defineSecret: (n: string) => ({ name: n }) }));
jest.mock('../../src/shared/firebaseAdmin', () => ({}));
jest.mock('../../src/safety/takedowns/legalHold', () => ({ activeHoldsFor: jest.fn() }));
jest.mock('../../src/shared/adminAuth', () => ({
  requireAdmin: jest.fn(),
  MODERATION_ROLES: ['superAdmin', 'moderator'],
  SUPER_ADMIN_ONLY: ['superAdmin'],
}));
jest.mock('firebase-admin', () => ({
  firestore: Object.assign(() => fakeDb, {
    FieldValue: { serverTimestamp: () => 'SERVER_TS', delete: () => DELETE },
    Timestamp: { now: () => ts(Date.now()), fromMillis: (ms: number) => ts(ms) },
  }),
}));

import {
  decryptIdentity,
  encryptIdentity,
  normalizeIdentityFields,
  parseKeyring,
} from '../../src/safety/identityRecordCrypto';
import {
  deps,
  handleConfirm,
  handleReveal,
  handleSubmit,
  retainIdentityRecordOnAccountDeletion,
  runIdentitySweep,
} from '../../src/safety/identityRecords';
import {
  onAccountDeletion,
  rateLimitStep,
  RETAIN_AFTER_DELETION_MS,
  sweepDecision,
  validateRevealRequest,
} from '../../src/safety/identityRecordsLogic';

const K1 = crypto.randomBytes(32).toString('base64');
const K2 = crypto.randomBytes(32).toString('base64');
const FIELDS = {
  firstName: 'Maria',
  surname: 'Silva',
  dateOfBirth: '1990-05-17',
  docType: 'passport',
  issuingCountry: 'br',
  docNumber: 'ab123456',
};

beforeEach(() => {
  store.clear();
  events.length = 0;
  deps.keyValue = () => K1;
  deps.requireAdmin = jest.fn(async () => ({ uid: 'admin1', role: 'superAdmin', source: 'admin_users' })) as any;
  deps.activeHoldsFor = jest.fn(async () => []) as any;
});

describe('crypto', () => {
  test('round trip with a test key; a random IV per record', () => {
    const ring = parseKeyring(K1);
    const f = normalizeIdentityFields(FIELDS);
    const a = encryptIdentity(f, 'u1', ring);
    const b = encryptIdentity(f, 'u1', ring);
    expect(a.iv).not.toBe(b.iv);
    expect(a.ciphertext).not.toContain('Maria');
    expect(a.keyVersion).toBe('v1');
    expect(decryptIdentity(a, 'u1', ring)).toEqual(f);
  });

  test('a record copied to another uid does not decrypt (AAD)', () => {
    const ring = parseKeyring(K1);
    const a = encryptIdentity(normalizeIdentityFields(FIELDS), 'u1', ring);
    expect(() => decryptIdentity(a, 'u2', ring)).toThrow();
  });

  test('tampered ciphertext fails authentication', () => {
    const ring = parseKeyring(K1);
    const a = encryptIdentity(normalizeIdentityFields(FIELDS), 'u1', ring);
    const bad = Buffer.from(a.ciphertext, 'base64');
    bad[0] ^= 1;
    expect(() => decryptIdentity({ ...a, ciphertext: bad.toString('base64') }, 'u1', ring)).toThrow();
  });

  test('keyring rotation: new version encrypts, old still decrypts', () => {
    const old = encryptIdentity(normalizeIdentityFields(FIELDS), 'u1', parseKeyring(K1));
    const ring = parseKeyring(`v2:${K2},v1:${K1}`);
    expect(ring.current).toBe('v2');
    expect(decryptIdentity(old, 'u1', ring).surname).toBe('Silva');
    expect(encryptIdentity(normalizeIdentityFields(FIELDS), 'u1', ring).keyVersion).toBe('v2');
    expect(() => decryptIdentity(old, 'u1', parseKeyring(`v2:${K2}`))).toThrow(/key_version_unavailable/);
  });

  test('malformed or missing keys are refused', () => {
    expect(() => parseKeyring('')).toThrow();
    expect(() => parseKeyring(Buffer.alloc(16).toString('base64'))).toThrow();
  });

  test('field normalization and validation', () => {
    const f = normalizeIdentityFields({ ...FIELDS, firstName: '  Maria   Clara ' });
    expect(f).toMatchObject({ firstName: 'Maria Clara', issuingCountry: 'BR', docNumber: 'AB123456' });
    expect(() => normalizeIdentityFields({ ...FIELDS, dateOfBirth: '17/05/1990' })).toThrow('invalid_dateOfBirth');
    expect(() => normalizeIdentityFields({ ...FIELDS, docType: 'library_card' })).toThrow('invalid_docType');
    expect(() => normalizeIdentityFields({ ...FIELDS, surname: '' })).toThrow('invalid_surname');
    expect(() => normalizeIdentityFields({ ...FIELDS, issuingCountry: 'BRA' })).toThrow('invalid_issuingCountry');
    expect(() => normalizeIdentityFields({ ...FIELDS, docNumber: 'x' })).toThrow('invalid_docNumber');
  });
});

describe('logic', () => {
  test('reveal request needs a legal basis and a reference', () => {
    expect(validateRevealRequest({ uid: 'u1', legalBasis: 'court_order', reference: 'Proc. 123/2026' })).toMatchObject({
      uid: 'u1',
    });
    expect(validateRevealRequest({ uid: 'u1', legalBasis: 'curiosity', reference: 'Proc. 123/2026' })).toBe(
      'invalid_legal_basis',
    );
    expect(validateRevealRequest({ uid: 'u1', legalBasis: 'other', reference: 'short' })).toBe('invalid_reference');
    expect(validateRevealRequest({ legalBasis: 'other', reference: 'long enough' })).toBe('invalid_uid');
  });

  test('rate limit window', () => {
    const lim = { cap: 2, windowMs: 1000 };
    let r = rateLimitStep(null, lim, 0);
    expect(r.allowed).toBe(true);
    r = rateLimitStep(r.next, lim, 10);
    expect(r.allowed).toBe(true);
    expect(rateLimitStep(r.next, lim, 20).allowed).toBe(false);
    expect(rateLimitStep(r.next, lim, 1001).allowed).toBe(true);
  });

  test('account deletion: pending deleted, verified retained 6 months', () => {
    expect(onAccountDeletion(null, 0)).toEqual({ action: 'none' });
    expect(onAccountDeletion({ status: 'pending' }, 0)).toEqual({ action: 'delete' });
    expect(onAccountDeletion({ status: 'verified' }, 1000)).toEqual({
      action: 'retain',
      retainUntilMs: 1000 + RETAIN_AFTER_DELETION_MS,
    });
  });

  test('sweep decision honours legal holds', () => {
    expect(sweepDecision({ retainUntil: ts(5) }, 10, false)).toBe('delete');
    expect(sweepDecision({ retainUntil: ts(5) }, 10, true)).toBe('held');
    expect(sweepDecision({ retainUntil: ts(5), legalHold: true }, 10, false)).toBe('held');
    expect(sweepDecision({ retainUntil: ts(50) }, 10, false)).toBe('keep');
    expect(sweepDecision({ retainUntil: null, status: 'verified' }, 10, false)).toBe('keep');
  });
});

const call = (uid: string | null, data: any) => ({ auth: uid ? { uid, token: {} } : undefined, data }) as any;

describe('callables', () => {
  async function seedVerified(uid = 'u1') {
    await handleSubmit(call(uid, { source: 'registration', fields: FIELDS }));
    await handleConfirm(call('mod1', { uid, decision: 'approve' }));
  }

  test('submit stores only ciphertext, never plaintext', async () => {
    await handleSubmit(call('u1', { source: 'registration', fields: FIELDS }));
    const rec = col('identity_records').get('u1');
    expect(rec.status).toBe('pending');
    expect(JSON.stringify(rec)).not.toMatch(/Maria|Silva|AB123456|1990-05-17/);
  });

  test('submit requires sign-in and a valid source', async () => {
    await expect(handleSubmit(call(null, { source: 'registration', fields: FIELDS }))).rejects.toThrow();
    await expect(handleSubmit(call('u1', { source: 'x', fields: FIELDS }))).rejects.toThrow('invalid_source');
  });

  test('approve with reviewer corrections stores metadata + encrypted fields', async () => {
    await handleSubmit(call('u1', { source: 'age', fields: FIELDS }));
    await handleConfirm(call('mod1', { uid: 'u1', decision: 'approve', fields: { ...FIELDS, surname: 'Souza' } }));
    const rec = col('identity_records').get('u1');
    expect(rec).toMatchObject({ status: 'verified', docType: 'passport', issuingCountry: 'BR', reviewedBy: 'admin1' });
    expect(rec.pendingExpiresAt).toBeUndefined();
    expect(decryptIdentity(rec.enc, 'u1', parseKeyring(K1)).surname).toBe('Souza');
  });

  test('reject deletes a pending record', async () => {
    await handleSubmit(call('u1', { source: 'registration', fields: FIELDS }));
    await handleConfirm(call('mod1', { uid: 'u1', decision: 'reject' }));
    expect(col('identity_records').has('u1')).toBe(false);
  });

  test('reveal requires SUPER_ADMIN_ONLY', async () => {
    await seedVerified();
    deps.requireAdmin = jest.fn(async (_a: any, roles: any) => {
      expect(roles).toEqual(['superAdmin']);
      throw new Error('permission-denied');
    }) as any;
    await expect(
      handleReveal(call('mod1', { uid: 'u1', legalBasis: 'court_order', reference: 'Proc. 123/2026' })),
    ).rejects.toThrow('permission-denied');
    expect(col('identity_access_log').size).toBe(0);
  });

  test('reveal requires a basis and a reference', async () => {
    await seedVerified();
    await expect(handleReveal(call('a', { uid: 'u1', legalBasis: 'court_order', reference: '' }))).rejects.toThrow(
      'invalid_reference',
    );
    await expect(handleReveal(call('a', { uid: 'u1', reference: 'Proc. 123/2026' }))).rejects.toThrow(
      'invalid_legal_basis',
    );
    expect(col('identity_access_log').size).toBe(0);
  });

  test('reveal writes the audit row BEFORE decrypting and returns the fields', async () => {
    await seedVerified();
    events.length = 0;
    const keySpy = jest.fn(() => {
      events.push('decrypt');
      return K1;
    });
    deps.keyValue = keySpy;
    const out = await handleReveal(
      call('admin1', { uid: 'u1', legalBasis: 'police_request', reference: 'Oficio 77/2026 DP' }),
    );
    expect(out.fields.surname).toBe('Silva');
    expect(events.indexOf('add:identity_access_log')).toBeGreaterThanOrEqual(0);
    expect(events.indexOf('add:identity_access_log')).toBeLessThan(events.indexOf('decrypt'));
    const log = [...col('identity_access_log').values()][0];
    expect(log).toMatchObject({ adminUid: 'admin1', subjectUid: 'u1', legalBasis: 'police_request' });
  });

  test('reveal of an unknown uid is not-found and writes nothing', async () => {
    await expect(
      handleReveal(call('admin1', { uid: 'nobody', legalBasis: 'court_order', reference: 'Proc. 123/2026' })),
    ).rejects.toThrow('no_identity_record');
  });

  test('reveal is rate limited per admin', async () => {
    await seedVerified();
    for (let i = 0; i < 20; i++) {
      await handleReveal(call('admin1', { uid: 'u1', legalBasis: 'legal_hold', reference: 'Hold case 0001' }));
    }
    await expect(
      handleReveal(call('admin1', { uid: 'u1', legalBasis: 'legal_hold', reference: 'Hold case 0001' })),
    ).rejects.toThrow('rate_limited');
  });
});

describe('retention', () => {
  test('account deletion sets retainUntil; sweep deletes after it unless a legal hold applies', async () => {
    await handleSubmit(call('u1', { source: 'registration', fields: FIELDS }));
    await handleConfirm(call('mod1', { uid: 'u1', decision: 'approve' }));
    await handleSubmit(call('u2', { source: 'registration', fields: FIELDS }));
    await handleConfirm(call('mod1', { uid: 'u2', decision: 'approve' }));
    const t0 = Date.now();
    await retainIdentityRecordOnAccountDeletion('u1', t0);
    await retainIdentityRecordOnAccountDeletion('u2', t0);
    expect(col('identity_records').get('u1').retainUntil.toMillis()).toBe(t0 + RETAIN_AFTER_DELETION_MS);

    // Not yet expired: kept.
    expect(await runIdentitySweep(t0 + 1000)).toEqual({ deleted: 0, held: 0 });

    deps.activeHoldsFor = jest.fn(async (uid: string) => (uid === 'u2' ? [{ id: 'csae_u2' }] : [])) as any;
    const r = await runIdentitySweep(t0 + RETAIN_AFTER_DELETION_MS + 1);
    expect(r).toEqual({ deleted: 1, held: 1 });
    expect(col('identity_records').has('u1')).toBe(false);
    expect(col('identity_records').has('u2')).toBe(true);
  });

  test('pending records are deleted on account deletion and expire after 30 days', async () => {
    await handleSubmit(call('u1', { source: 'registration', fields: FIELDS }));
    await retainIdentityRecordOnAccountDeletion('u1');
    expect(col('identity_records').has('u1')).toBe(false);

    await handleSubmit(call('u3', { source: 'business', fields: FIELDS }));
    const r = await runIdentitySweep(Date.now() + 31 * 24 * 3600 * 1000);
    expect(r.deleted).toBe(1);
    expect(col('identity_records').has('u3')).toBe(false);
  });
});
