/**
 * translateTexts: cache misses go to the FREE endpoint, translations are
 * stored at translations/{sha256(target\0text)} with the same doc shape, and
 * the response keeps the same order/format ('' = not translated).
 */

const stored = new Map<string, any>();
const writes: { id: string; data: any }[] = [];
let quotaUsed = 0;
const consents = new Map<string, any>(); // consents/{uid}

jest.mock('firebase-admin', () => {
  const ref = (col: string, id: string) => ({
    col,
    id,
    get: async () => ({ exists: consents.has(id), data: () => consents.get(id) }),
  });
  const db: any = {
    collection: (col: string) => ({ doc: (id: string) => ref(col, id) }),
    getAll: async (...refs: any[]) =>
      refs.map((r) => ({ exists: stored.has(r.id), data: () => stored.get(r.id) })),
    runTransaction: async (cb: any) =>
      cb({
        get: async () => ({ data: () => ({ count: quotaUsed }) }),
        set: (_r: any, d: any) => {
          quotaUsed = d.count;
        },
      }),
    batch: () => {
      const pending: { id: string; data: any }[] = [];
      return {
        set: (r: any, data: any) => pending.push({ id: r.id, data }),
        commit: async () => {
          writes.push(...pending);
        },
      };
    },
  };
  const firestoreFn: any = () => db;
  firestoreFn.FieldValue = { serverTimestamp: () => 'TS' };
  firestoreFn.Timestamp = { fromMillis: (n: number) => n };
  return {
    apps: [{}],
    initializeApp: jest.fn(),
    firestore: firestoreFn,
    storage: () => ({}),
    auth: () => ({}),
    messaging: () => ({}),
  };
});

const mockMany = jest.fn();
jest.mock('../freeTranslate', () => ({
  freeTranslateMany: (...args: any[]) => mockMany(...args),
}));

import { sharedTranslationId, translateTexts } from '../sharedTranslations';
import {
  clearTranslationConsentCache,
  requireTranslationConsent,
  TRANSLATION_CONSENT_TTL_MS,
} from '../../shared/aiConsent';

const call = (data: any, uid: string | null = 'u1') =>
  (translateTexts as any).run({ data, auth: uid ? { uid } : undefined });

beforeEach(() => {
  stored.clear();
  writes.length = 0;
  quotaUsed = 0;
  mockMany.mockReset();
  consents.clear();
  consents.set('u1', { ai_processing: { accepted: true, version: 2 } });
  clearTranslationConsentCache();
});

describe('viewer consent (Apple 5.1.2(i))', () => {
  it('refuses a caller who never accepted: nothing read, nothing sent to Google', async () => {
    consents.clear();
    await expect(call({ texts: ['Hello'], target: 'it' }))
      .rejects.toMatchObject({
        code: 'failed-precondition',
        details: { code: 'AI_CONSENT_REQUIRED', reason: 'consent-required' },
      });
    expect(mockMany).not.toHaveBeenCalled();
    expect(writes).toHaveLength(0);
  });

  it('refuses a caller who turned AI services off', async () => {
    consents.set('u1', { ai_processing: { accepted: false, version: 2 } });
    await expect(call({ texts: ['Hello'], target: 'it' }))
      .rejects.toMatchObject({ code: 'failed-precondition' });
    expect(mockMany).not.toHaveBeenCalled();
  });

  it('an empty request needs no consent check', async () => {
    consents.clear();
    await expect(call({ texts: [], target: 'it' })).resolves.toEqual({ translations: [] });
  });

  it('a grant is cached briefly per instance; a refusal is never cached', async () => {
    let t = 1000;
    const now = () => t;
    consents.clear();
    await expect(requireTranslationConsent('u9', now)).rejects.toBeTruthy();
    consents.set('u9', { ai_processing: { accepted: true, version: 1 } });
    await expect(requireTranslationConsent('u9', now)).resolves.toBeUndefined(); // grant is immediate
    consents.set('u9', { ai_processing: { accepted: false, version: 2 } });
    await expect(requireTranslationConsent('u9', now)).resolves.toBeUndefined(); // cached grant
    t += TRANSLATION_CONSENT_TTL_MS + 1;
    await expect(requireTranslationConsent('u9', now)).rejects.toMatchObject({ code: 'failed-precondition' });
  });
});

it('translates only the misses with the free endpoint and stores them', async () => {
  stored.set(sharedTranslationId('it', 'Hello'), { translated: 'Ciao' });
  mockMany.mockResolvedValue([{ text: 'Buongiorno', detectedLanguage: 'en', sameLanguage: false }]);

  const out = await call({ texts: ['Hello', 'Good morning'], target: 'it' });

  expect(out).toEqual({ translations: ['Ciao', 'Buongiorno'] });
  expect(mockMany).toHaveBeenCalledWith(['Good morning'], 'it', expect.objectContaining({ concurrency: 4 }));
  expect(writes).toEqual([
    {
      id: sharedTranslationId('it', 'Good morning'),
      data: { target: 'it', translated: 'Buongiorno', source: 'en', createdAt: 'TS' },
    },
  ]);
  expect(quotaUsed).toBe(1);
});

it("returns '' for texts the endpoint could not translate and stores nothing for them", async () => {
  mockMany.mockResolvedValue([null, { text: 'Hola', detectedLanguage: 'en', sameLanguage: false }]);

  const out = await call({ texts: ['A', 'Hello'], target: 'es' });

  expect(out).toEqual({ translations: ['', 'Hola'] });
  expect(writes.map((w) => w.id)).toEqual([sharedTranslationId('es', 'Hello')]);
});

it('respects the daily miss quota', async () => {
  quotaUsed = 1500;
  const out = await call({ texts: ['Hello'], target: 'it' });
  expect(out).toEqual({ translations: [''] });
  expect(mockMany).not.toHaveBeenCalled();
});

it('rejects unauthenticated callers and bad targets', async () => {
  await expect(call({ texts: ['x'], target: 'it' }, null)).rejects.toMatchObject({ code: 'unauthenticated' });
  await expect(call({ texts: ['x'], target: 'Italian' })).rejects.toMatchObject({ code: 'invalid-argument' });
});
