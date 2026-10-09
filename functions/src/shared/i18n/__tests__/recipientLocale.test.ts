/**
 * Recipient-locale resolution against an in-memory Firestore double:
 * users/{uid}.appLanguage -> userSettings/{uid}.language -> preferredLanguage
 * -> English, read counts, per-invocation cache and batched lookups.
 */
const store: Record<string, Record<string, unknown> | undefined> = {};
const reads: string[] = [];

function snap(p: string) {
  return { exists: store[p] !== undefined, data: () => store[p] };
}

jest.mock('firebase-admin', () => {
  const firestore = () => ({
    collection: (c: string) => ({
      doc: (id: string) => {
        const p = `${c}/${id}`;
        return { path: p, get: async () => { reads.push(p); return snap(p); } };
      },
    }),
    getAll: async (...refs: Array<{ path: string }>) => refs.map((r) => { reads.push(r.path); return snap(r.path); }),
  });
  return { apps: [{}], initializeApp: jest.fn(), firestore, storage: jest.fn(), auth: jest.fn() };
});

import { LocaleCache, resolveLocale, resolveLocales } from '../recipientLocale';

beforeEach(() => {
  for (const k of Object.keys(store)) delete store[k];
  reads.length = 0;
});

describe('resolveLocale', () => {
  it('uses users.appLanguage without any extra read when the doc is passed in', async () => {
    expect(await resolveLocale('u1', { userData: { appLanguage: 'de_DE' } })).toBe('de');
    expect(reads).toEqual([]);
  });

  it('falls back to userSettings.language (one extra read), then preferredLanguage, then en', async () => {
    store['users/u1'] = { preferredLanguage: 'it' };
    store['userSettings/u1'] = { language: 'pt_BR' };
    expect(await resolveLocale('u1')).toBe('pt_BR');
    expect(reads).toEqual(['users/u1', 'userSettings/u1']);

    store['users/u2'] = { preferredLanguage: 'it' };
    expect(await resolveLocale('u2')).toBe('it');

    expect(await resolveLocale('nobody')).toBe('en');
  });

  it('caches per invocation', async () => {
    store['users/u1'] = { appLanguage: 'fr' };
    const cache = new LocaleCache();
    await resolveLocale('u1', { cache });
    await resolveLocale('u1', { cache });
    expect(reads).toEqual(['users/u1']);
  });
});

describe('resolveLocales (fan-out batch)', () => {
  it('batches users reads and only reads userSettings for docs without appLanguage', async () => {
    store['users/a'] = { appLanguage: 'es' };
    store['users/b'] = {};
    store['userSettings/b'] = { language: 'it' };
    const out = await resolveLocales(['a', 'b', 'c', 'a']);
    expect(Object.fromEntries(out)).toEqual({ a: 'es', b: 'it', c: 'en' });
    expect(reads.filter((r) => r.startsWith('userSettings/')).sort()).toEqual(['userSettings/b', 'userSettings/c']);
    expect(reads.filter((r) => r.startsWith('users/'))).toHaveLength(3);
  });
});
