/**
 * translateTexts: cache misses go to the FREE endpoint, translations are
 * stored at translations/{sha256(target\0text)} with the same doc shape, and
 * the response keeps the same order/format ('' = not translated).
 */

const stored = new Map<string, any>();
const writes: { id: string; data: any }[] = [];
let quotaUsed = 0;

jest.mock('firebase-admin', () => {
  const ref = (col: string, id: string) => ({ col, id });
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

const call = (data: any, uid: string | null = 'u1') =>
  (translateTexts as any).run({ data, auth: uid ? { uid } : undefined });

beforeEach(() => {
  stored.clear();
  writes.length = 0;
  quotaUsed = 0;
  mockMany.mockReset();
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
