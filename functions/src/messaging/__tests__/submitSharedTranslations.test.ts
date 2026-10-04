/**
 * submitSharedTranslations: client-contributed translations of public content
 * become shared (translations/{id}) only after TWO DIFFERENT users submitted
 * the SAME normalised translation.
 */

const docs = new Map<string, any>(); // `${collection}/${id}` -> data

jest.mock('firebase-admin', () => {
  const snap = (r: any) => ({ exists: docs.has(r.path), data: () => docs.get(r.path) });
  const ref = (col: string, id: string): any => {
    const r: any = { col, id, path: `${col}/${id}` };
    r.get = async () => snap(r);
    return r;
  };
  const db: any = {
    collection: (col: string) => ({ doc: (id: string) => ref(col, id) }),
    getAll: async (...refs: any[]) => refs.map(snap),
    runTransaction: async (cb: any) =>
      cb({
        get: async (r: any) => snap(r),
        set: (r: any, d: any, opts?: any) => {
          docs.set(r.path, opts?.merge ? { ...(docs.get(r.path) ?? {}), ...d } : d);
        },
        delete: (r: any) => docs.delete(r.path),
      }),
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

jest.mock('../freeTranslate', () => ({ freeTranslateMany: jest.fn() }));

import { sharedTranslationId } from '../sharedTranslations';
import {
  DAILY_SUBMIT_QUOTA,
  MAX_VARIANTS,
  applyVote,
  rejectReason,
  submitSharedTranslations,
  voteKey,
} from '../submitSharedTranslations';

const TEXT = 'The old harbour hosts a fish market every Sunday morning.';
const IT = 'Il vecchio porto ospita un mercato del pesce ogni domenica mattina.';
const id = sharedTranslationId('it', TEXT);
const shared = () => docs.get(`translations/${id}`);
const candidate = () => docs.get(`translation_candidates/${id}`);

const call = (uid: string | null, items: any[], target = 'it') =>
  (submitSharedTranslations as any).run({ data: { target, items }, auth: uid ? { uid } : undefined });

const submit = (uid: string, translation: string, text = TEXT) => call(uid, [{ text, translation }]);

beforeEach(() => {
  docs.clear();
  for (const u of ['u1', 'u2', 'u3']) docs.set(`users/${u}`, { accountStatus: 'active' });
});

describe('consensus', () => {
  it('one vote shares nothing and stores only a candidate', async () => {
    const out = await submit('u1', IT);
    expect(out).toMatchObject({ accepted: 1, shared: 0 });
    expect(shared()).toBeUndefined();
    const c = candidate();
    expect(c.target).toBe('it');
    expect(c.votes[voteKey(IT)]).toMatchObject({ translation: IT, uids: ['u1'] });
    expect(typeof c.expireAt).toBe('number');
    // Never the original text.
    expect(JSON.stringify(c)).not.toContain(TEXT);
  });

  it('two different users with the same translation share it (translateTexts shape)', async () => {
    await submit('u1', IT);
    const out = await submit('u2', IT);
    expect(out).toMatchObject({ accepted: 1, shared: 1 });
    expect(shared()).toEqual({
      target: 'it',
      translated: IT,
      source: null,
      createdAt: 'TS',
      origin: 'consensus',
      voters: ['u1', 'u2'],
    });
    expect(candidate()).toBeUndefined();
  });

  it('the same user twice is not consensus', async () => {
    await submit('u1', IT);
    const out = await submit('u1', IT);
    expect(out.shared).toBe(0);
    expect(shared()).toBeUndefined();
    expect(candidate().votes[voteKey(IT)].uids).toEqual(['u1']);
  });

  it('two different translations are not shared until one gets a second user', async () => {
    const other = 'Il porto antico ospita un mercato ittico ogni domenica mattina.';
    await submit('u1', IT);
    await submit('u2', other);
    expect(shared()).toBeUndefined();
    expect(Object.keys(candidate().votes)).toHaveLength(2);
    await submit('u3', other);
    expect(shared().translated).toBe(other);
    expect(shared().voters).toEqual(['u2', 'u3']);
  });

  it('treats whitespace-only differences (and NFC/NFD) as the same translation', async () => {
    const nfd = 'Caffè  al   porto\t ogni  domenica'.normalize('NFD');
    await call('u1', [{ text: 'Coffee at the harbour every Sunday', translation: nfd }]);
    await call('u2', [{ text: 'Coffee at the harbour every Sunday', translation: '  Caffè al porto ogni domenica ' }]);
    const doc = docs.get(`translations/${sharedTranslationId('it', 'Coffee at the harbour every Sunday')}`);
    expect(doc.translated).toBe('Caffè al porto ogni domenica');
  });

  it('a user changing their mind moves their single vote', () => {
    const base = { target: 'it', textHash: 'h', now: 1 };
    let r = applyVote(null, { ...base, uid: 'u1', translation: 'A' });
    r = applyVote(r.candidate, { ...base, uid: 'u1', translation: 'B', now: 2 });
    expect(Object.values(r.candidate.votes).map((v) => v.uids)).toEqual([['u1']]);
    expect(r.consensus).toBeNull();
  });

  it('bounds the number of competing variants', () => {
    let c: any = null;
    for (let i = 0; i < MAX_VARIANTS + 3; i++) {
      c = applyVote(c, { target: 'it', textHash: 'h', uid: `u${i}`, translation: `v${i}`, now: i }).candidate;
    }
    expect(Object.keys(c.votes)).toHaveLength(MAX_VARIANTS);
    // Oldest single-voter variants were evicted, newest kept.
    expect(c.votes[voteKey(`v${MAX_VARIANTS + 2}`)]).toBeDefined();
    expect(c.votes[voteKey('v0')]).toBeUndefined();
  });
});

describe('rejections', () => {
  it('rejects a translation identical to the source (same language) and stores nothing', async () => {
    const out = await submit('u1', `  ${TEXT.toUpperCase()} `);
    expect(out).toMatchObject({ accepted: 0, rejected: 1 });
    expect(candidate()).toBeUndefined();
  });

  it('is a no-op when the translation already exists', async () => {
    docs.set(`translations/${id}`, { translated: 'esistente', target: 'it' });
    const out = await submit('u1', IT);
    expect(out).toMatchObject({ accepted: 0, existing: 1 });
    expect(candidate()).toBeUndefined();
    expect(shared().translated).toBe('esistente');
    expect(docs.get(`translation_quota/u1_${new Date().toISOString().slice(0, 10).replace(/-/g, '')}_submit`)).toBeUndefined();
  });

  it('drops prohibited language, injected links and injected contact info', async () => {
    expect(rejectReason(TEXT, 'Il vecchio porto merda')).toBe('prohibited_terms');
    expect(rejectReason(TEXT, 'Il porto, vedi www.scam.example')).toBe('contains_link');
    expect(rejectReason(TEXT, 'Il porto: scrivimi su whatsapp +39 333 123 4567')).toBe('contact_info');
    expect(rejectReason('Info: www.port.example', 'Informazioni: www.port.example')).toBeNull();
    const out = await submit('u1', 'Il vecchio porto merda');
    expect(out).toMatchObject({ accepted: 0, rejected: 1 });
    expect(candidate()).toBeUndefined();
  });

  it('enforces the per-user daily quota', async () => {
    const day = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    docs.set(`translation_quota/u1_${day}_submit`, { count: DAILY_SUBMIT_QUOTA - 1 });
    const out = await call('u1', [
      { text: 'First public text', translation: 'Primo testo pubblico' },
      { text: 'Second public text', translation: 'Secondo testo pubblico' },
    ]);
    expect(out).toMatchObject({ accepted: 1 });
    expect(docs.get(`translation_quota/u1_${day}_submit`).count).toBe(DAILY_SUBMIT_QUOTA);
    const again = await submit('u1', IT);
    expect(again).toMatchObject({ accepted: 0, quotaExceeded: true });
    expect(candidate()).toBeUndefined();
  });

  it('rejects unauthenticated, banned, bad targets, too many items and oversize texts', async () => {
    await expect(submit(null as any, IT)).rejects.toMatchObject({ code: 'unauthenticated' });
    docs.set('users/bad', { isBanned: true });
    await expect(submit('bad', IT)).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(submit('nobody', IT)).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(call('u1', [{ text: TEXT, translation: IT }], 'Italian'))
      .rejects.toMatchObject({ code: 'invalid-argument' });
    const many = Array.from({ length: 21 }, (_, i) => ({ text: `t${i}`, translation: `x${i}` }));
    await expect(call('u1', many)).rejects.toMatchObject({ code: 'invalid-argument' });
    const out = await call('u1', [{ text: 'a'.repeat(5001), translation: 'b' }]);
    expect(out).toMatchObject({ accepted: 0, rejected: 1 });
  });
});
