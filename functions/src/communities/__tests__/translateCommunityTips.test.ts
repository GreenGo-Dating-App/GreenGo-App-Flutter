/**
 * translateCommunityTips: only tips of THAT community are translated (text
 * read server-side), private communities need membership, stored
 * translations are served without a translate call, misses are translated
 * once and stored, and a call is capped at 30 ids.
 */

const docs = new Map<string, any>(); // full path -> data
const writes: { path: string; data: any }[] = [];
let quotaUsed = 0;
let adminCaller = false;

jest.mock('firebase-admin', () => {
  const ref = (path: string): any => ({
    path,
    id: path.split('/').pop(),
    collection: (c: string) => col(`${path}/${c}`),
    get: async () => ({ exists: docs.has(path), data: () => docs.get(path) }),
  });
  const col = (path: string): any => ({ doc: (id: string) => ref(`${path}/${id}`) });
  const db: any = {
    collection: (c: string) => col(c),
    getAll: async (...refs: any[]) =>
      refs.map((r) => ({ exists: docs.has(r.path), data: () => docs.get(r.path) })),
    runTransaction: async (cb: any) =>
      cb({
        get: async () => ({ data: () => ({ count: quotaUsed }) }),
        set: (_r: any, d: any) => {
          quotaUsed = d.count;
        },
      }),
    batch: () => {
      const pending: { path: string; data: any }[] = [];
      return {
        set: (r: any, data: any) => pending.push({ path: r.path, data }),
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
jest.mock('../../messaging/freeTranslate', () => ({
  freeTranslateMany: (...args: any[]) => mockMany(...args),
}));
jest.mock('../../shared/adminAuth', () => ({
  MODERATION_ROLES: ['superAdmin', 'moderator'],
  isAdminCaller: async () => adminCaller,
}));

import { sharedTranslationId } from '../../messaging/sharedTranslations';
import { tipTextHash, translateCommunityTips } from '../translateCommunityTips';
import { clearTranslationConsentCache } from '../../shared/aiConsent';

const call = (data: any, uid: string | null = 'u1') =>
  (translateCommunityTips as any).run({ data, auth: uid ? { uid } : undefined });

const tip = (cid: string, mid: string, content: string, type = 'language_tip') =>
  docs.set(`communities/${cid}/messages/${mid}`, { type, content, senderId: 'a' });

beforeEach(() => {
  docs.clear();
  writes.length = 0;
  quotaUsed = 0;
  adminCaller = false;
  mockMany.mockReset();
  docs.set('communities/c1', { isPublic: true });
  // The viewer allowed AI services (Apple 5.1.2(i) consent).
  docs.set('consents/u1', { ai_processing: { accepted: true, version: 2 } });
  clearTranslationConsentCache();
});

describe('viewer consent (Apple 5.1.2(i))', () => {
  it('refuses without the viewer consent: no read of tips, nothing sent to Google', async () => {
    docs.delete('consents/u1');
    tip('c1', 'm1', 'Good morning');
    await expect(call({ communityId: 'c1', messageIds: ['m1'], target: 'it' }))
      .rejects.toMatchObject({ code: 'failed-precondition', details: { code: 'AI_CONSENT_REQUIRED' } });
    expect(mockMany).not.toHaveBeenCalled();
    expect(writes).toHaveLength(0);
  });

  it('refuses when the viewer turned AI services off', async () => {
    docs.set('consents/u1', { ai_processing: { accepted: false, version: 2 } });
    tip('c1', 'm1', 'Good morning');
    await expect(call({ communityId: 'c1', messageIds: ['m1'], target: 'it' }))
      .rejects.toMatchObject({ code: 'failed-precondition' });
    expect(mockMany).not.toHaveBeenCalled();
  });

  it('the AUTHOR consent is irrelevant: only the viewer is checked', async () => {
    docs.set('consents/a', { ai_processing: { accepted: false, version: 2 } }); // tip author
    tip('c1', 'm1', 'Good morning');
    mockMany.mockResolvedValue([{ text: 'Buongiorno', detectedLanguage: 'en', sameLanguage: false }]);
    const out = await call({ communityId: 'c1', messageIds: ['m1'], target: 'it' });
    expect(out.translations[0].text).toBe('Buongiorno');
  });
});

it('serves a stored translation without calling the translator', async () => {
  tip('c1', 'm1', 'Hello');
  docs.set(`translations/${sharedTranslationId('it', 'Hello')}`, { translated: 'Ciao' });

  const out = await call({ communityId: 'c1', messageIds: ['m1'], target: 'it' });

  expect(out.translations).toEqual([
    { messageId: 'm1', hash: tipTextHash('Hello'), text: 'Ciao', sameLanguage: false },
  ]);
  expect(mockMany).not.toHaveBeenCalled();
  expect(writes).toHaveLength(0);
});

it('translates a miss once (deduped text) and stores it in the shared store', async () => {
  tip('c1', 'm1', 'Good morning');
  tip('c1', 'm2', 'Good morning', 'cultural_fact');
  mockMany.mockResolvedValue([{ text: 'Buongiorno', detectedLanguage: 'en', sameLanguage: false }]);

  const out = await call({ communityId: 'c1', messageIds: ['m1', 'm2'], target: 'it' });

  expect(mockMany).toHaveBeenCalledTimes(1);
  expect(mockMany.mock.calls[0][0]).toEqual(['Good morning']);
  expect(writes).toEqual([
    {
      path: `translations/${sharedTranslationId('it', 'Good morning')}`,
      data: {
        target: 'it',
        translated: 'Buongiorno',
        source: 'en',
        origin: 'community_tip',
        createdAt: 'TS',
      },
    },
  ]);
  expect(out.translations.map((t: any) => t.text)).toEqual(['Buongiorno', 'Buongiorno']);
  expect(quotaUsed).toBe(1);
});

it('never translates non-tips, other communities\' messages or unknown ids', async () => {
  tip('c1', 'chat', 'plain chat', 'text');
  tip('c1', 'ann', 'announcement', 'announcement');
  tip('c2', 'other', 'tip of another community');
  docs.set('communities/c2', { isPublic: true });

  const out = await call({ communityId: 'c1', messageIds: ['chat', 'ann', 'other', 'nope'], target: 'it' });

  expect(out.translations).toEqual([null, null, null, null]);
  expect(mockMany).not.toHaveBeenCalled();
  expect(writes).toHaveLength(0);
});

it('reports the same language (translation equals the original)', async () => {
  tip('c1', 'm1', 'Ciao a tutti', 'other_tip');
  mockMany.mockResolvedValue([{ text: 'Ciao a tutti', detectedLanguage: 'it', sameLanguage: true }]);
  const out = await call({ communityId: 'c1', messageIds: ['m1'], target: 'it' });
  expect(out.translations[0].sameLanguage).toBe(true);
});

it('private community: non-members are refused, members and moderators allowed', async () => {
  docs.set('communities/p1', { isPublic: false });
  tip('p1', 'm1', 'Secret tip', 'city_tip');
  docs.set(`translations/${sharedTranslationId('de', 'Secret tip')}`, { translated: 'Geheimtipp' });

  await expect(call({ communityId: 'p1', messageIds: ['m1'], target: 'de' }))
    .rejects.toMatchObject({ code: 'permission-denied' });

  docs.set('communities/p1/members/u1', { role: 'member', isBanned: true });
  await expect(call({ communityId: 'p1', messageIds: ['m1'], target: 'de' }))
    .rejects.toMatchObject({ code: 'permission-denied' });

  docs.set('communities/p1/members/u1', { role: 'member' });
  const out = await call({ communityId: 'p1', messageIds: ['m1'], target: 'de' });
  expect(out.translations[0].text).toBe('Geheimtipp');

  docs.delete('communities/p1/members/u1');
  adminCaller = true;
  const asMod = await call({ communityId: 'p1', messageIds: ['m1'], target: 'de' });
  expect(asMod.translations[0].text).toBe('Geheimtipp');
});

it('rejects more than 30 ids, bad input, unknown community and anonymous callers', async () => {
  const ids = Array.from({ length: 31 }, (_, i) => `m${i}`);
  await expect(call({ communityId: 'c1', messageIds: ids, target: 'it' }))
    .rejects.toMatchObject({ code: 'invalid-argument' });
  await expect(call({ communityId: 'c1', messageIds: ['m1'], target: 'Italian' }))
    .rejects.toMatchObject({ code: 'invalid-argument' });
  await expect(call({ communityId: 'c1/../x', messageIds: ['m1'], target: 'it' }))
    .rejects.toMatchObject({ code: 'invalid-argument' });
  await expect(call({ communityId: 'c1', messageIds: ['a/b'], target: 'it' }))
    .rejects.toMatchObject({ code: 'invalid-argument' });
  await expect(call({ communityId: 'ghost', messageIds: ['m1'], target: 'it' }))
    .rejects.toMatchObject({ code: 'not-found' });
  await expect(call({ communityId: 'c1', messageIds: ['m1'], target: 'it' }, null))
    .rejects.toMatchObject({ code: 'unauthenticated' });
  // Exactly 30 is fine.
  const ok = await call({ communityId: 'c1', messageIds: ids.slice(0, 30), target: 'it' });
  expect(ok.translations).toHaveLength(30);
});

it('client-supplied texts or translations are ignored', async () => {
  tip('c1', 'm1', 'Real tip');
  mockMany.mockResolvedValue([{ text: 'Vero consiglio', detectedLanguage: 'en', sameLanguage: false }]);
  await call({
    communityId: 'c1', messageIds: ['m1'], target: 'it',
    texts: ['evil'], translations: ['planted'],
  } as any);
  expect(mockMany.mock.calls[0][0]).toEqual(['Real tip']);
  expect(writes[0].data.translated).toBe('Vero consiglio');
});

it('over the daily quota: misses are not translated (null), hits still served', async () => {
  quotaUsed = 1999;
  tip('c1', 'm1', 'A');
  tip('c1', 'm2', 'B');
  docs.set(`translations/${sharedTranslationId('it', 'A')}`, { translated: 'A-it' });
  tip('c1', 'm3', 'C');
  const out = await call({ communityId: 'c1', messageIds: ['m1', 'm2', 'm3'], target: 'it' });
  expect(mockMany).not.toHaveBeenCalled();
  expect(out.translations[0].text).toBe('A-it');
  expect(out.translations[1]).toBeNull();
  expect(out.translations[2]).toBeNull();
});
