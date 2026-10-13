/**
 * translatePrivateText with message refs (stored chat translations):
 * message doc `tr.<target>` / `lang` -> cross-chat cache -> ONE Cloud
 * Translation request, then one batched write; participants only.
 */

const docs = new Map<string, any>();
const writes: { op: 'set' | 'update'; path: string; data: any }[] = [];
let quotaUsed = 0;
let getAllCalls = 0;

jest.mock('firebase-admin', () => {
  const ref = (path: string): any => ({
    path,
    id: path.split('/').pop(),
    collection: (c: string) => ({ doc: (id: string) => ref(`${path}/${c}/${id}`) }),
  });
  const db: any = {
    collection: (c: string) => ({ doc: (id: string) => ref(`${c}/${id}`) }),
    getAll: async (...refs: any[]) => {
      getAllCalls++;
      return refs.map((r) => ({ exists: docs.has(r.path), data: () => docs.get(r.path) }));
    },
    runTransaction: async (cb: any) =>
      cb({
        get: async () => ({ data: () => ({ translateChars: quotaUsed }) }),
        set: (_r: any, d: any) => {
          quotaUsed = d.translateChars;
        },
      }),
    batch: () => {
      const pending: typeof writes = [];
      return {
        set: (r: any, data: any) => pending.push({ op: 'set', path: r.path, data }),
        update: (r: any, data: any) => pending.push({ op: 'update', path: r.path, data }),
        commit: async () => {
          writes.push(...pending);
        },
      };
    },
  };
  const firestoreFn: any = () => db;
  firestoreFn.FieldValue = { serverTimestamp: () => 'TS', increment: (n: number) => ({ inc: n }) };
  firestoreFn.Timestamp = { now: () => 'NOW', fromMillis: (n: number) => n };
  return {
    apps: [{}],
    initializeApp: jest.fn(),
    firestore: firestoreFn,
    storage: () => ({}),
    auth: () => ({}),
    messaging: () => ({}),
  };
});

jest.mock('../../shared/aiConsent', () => ({
  CONSENTS: 'consents',
  AI_CONSENT_TYPE: 'ai_processing',
  AI_CONSENT_MIN_VERSION: 1,
  requireAiConsent: jest.fn(async () => undefined),
}));

import {
  _setAccessTokenProvider,
  chatCacheEligible,
  chatCacheId,
  handleTranslatePrivateText,
  messageTextHash,
} from '../aiGateway';

const fetchMock = jest.fn();
(global as any).fetch = fetchMock;
_setAccessTokenProvider(async () => 'token');

/** Cloud Translation v2 answer for [texts] (one entry each). */
const apiAnswer = (items: { translatedText: string; detectedSourceLanguage: string }[]) => ({
  ok: true,
  status: 200,
  json: async () => ({ data: { translations: items } }),
});

const call = (data: any, uid = 'u1') => handleTranslatePrivateText({ data, auth: { uid } });
const ref = (messageId: string, parentId = 'c1', kind = 'conversation') => ({ kind, parentId, messageId });
const msgPath = (id: string, parent = 'conversations/c1') => `${parent}/messages/${id}`;

beforeEach(() => {
  docs.clear();
  writes.length = 0;
  quotaUsed = 0;
  getAllCalls = 0;
  fetchMock.mockReset();
  docs.set('conversations/c1', { userId1: 'u1', userId2: 'u2' });
  docs.set('groups/g1', { participants: ['u1', 'u3'] });
});

describe('chatCacheEligible', () => {
  it.each([
    ['how are you?', true],
    ['Where are you from?', true],
    ['Bom dia! 😊', true],
    ['call me 555 1234', false],
    ['my code is 123', false],
    ['12 34 56 7', false],
    ['mail me at a@b.co', false],
    ['follow @someone', false],
    ['see https://x.y/z', false],
    ['look at www.site', false],
    ['visit greengochat.com', false],
    ['x'.repeat(121), false],
    ['   ', false],
  ])('%s -> %s', (text, ok) => {
    expect(chatCacheEligible(text)).toBe(ok);
  });

  it('keys on NFC + trimmed + collapsed + lowercased text', () => {
    expect(chatCacheId('it', '  How   ARE you? ')).toBe(chatCacheId('it', 'how are you?'));
    expect(chatCacheId('it', 'Café')).toBe(chatCacheId('it', 'café'));
    expect(chatCacheId('it', 'hi')).not.toBe(chatCacheId('de', 'hi'));
  });
});

describe('translatePrivateText (message refs)', () => {
  it('returns the translation stored on the message without calling the API', async () => {
    docs.set(msgPath('m1'), {
      type: 'text', content: 'Hello friend', lang: 'en',
      tr: { it: 'Ciao amico' }, trHash: messageTextHash('Hello friend'),
    });
    const out: any = await call({ target: 'it', messages: [ref('m1')] });
    expect(out.translations[0]).toMatchObject({ messageId: 'm1', text: 'Ciao amico', layer: 'message' });
    expect(fetchMock).not.toHaveBeenCalled();
    expect(writes).toEqual([]);
    expect(quotaUsed).toBe(0);
  });

  it('ignores a stored translation of edited content', async () => {
    docs.set(msgPath('m1'), {
      type: 'text', content: 'Hello again', lang: 'en',
      tr: { it: 'Ciao amico' }, trHash: messageTextHash('Hello friend'),
    });
    fetchMock.mockResolvedValue(apiAnswer([{ translatedText: 'Ciao di nuovo', detectedSourceLanguage: 'en' }]));
    const out: any = await call({ target: 'it', messages: [ref('m1')] });
    expect(out.translations[0]).toMatchObject({ text: 'Ciao di nuovo', layer: 'api' });
    expect(writes.find((w) => w.path === msgPath('m1'))!.data).toEqual({
      tr: { it: 'Ciao di nuovo' }, trHash: messageTextHash('Hello again'),
    });
  });

  it('message lang == target (base language): original, no API', async () => {
    docs.set(msgPath('m1'), { type: 'text', content: 'Olá tudo bem', lang: 'pt' });
    const out: any = await call({ target: 'pt-BR', messages: [ref('m1')] });
    expect(out.translations[0]).toMatchObject({ text: 'Olá tudo bem', sameLanguage: true, layer: 'message' });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('cross-chat cache hit: no API, writes the per-message translation + lang', async () => {
    docs.set(msgPath('m1'), { type: 'text', content: 'How are you?' });
    docs.set(`chat_translation_cache/${chatCacheId('it', 'how are you?')}`, { text: 'Come stai?', source: 'en' });
    const out: any = await call({ target: 'it', messages: [ref('m1')] });
    expect(out.translations[0]).toMatchObject({ text: 'Come stai?', detectedLanguage: 'en', layer: 'cache' });
    expect(fetchMock).not.toHaveBeenCalled();
    expect(quotaUsed).toBe(0);
    expect(writes.find((w) => w.path === msgPath('m1'))!.data).toEqual({
      tr: { it: 'Come stai?' }, trHash: messageTextHash('How are you?'), lang: 'en',
    });
  });

  it('misses: ONE API request for the batch, then message + cache writes', async () => {
    docs.set(msgPath('m1'), { type: 'text', content: 'Good morning' });
    docs.set(msgPath('m2'), { type: 'text', content: 'Good morning' }); // duplicate text
    docs.set(msgPath('m3'), { type: 'text', content: 'Call me at 555 1234 tomorrow' }); // not cacheable
    docs.set(msgPath('g1m', 'groups/g1'), { type: 'text', content: 'Ciao a tutti', lang: 'it' });
    fetchMock.mockResolvedValue(apiAnswer([
      { translatedText: 'Buongiorno', detectedSourceLanguage: 'en' },
      { translatedText: 'Chiamami al 555 1234 domani', detectedSourceLanguage: 'en' },
    ]));

    const out: any = await call({
      target: 'it',
      messages: [ref('m1'), ref('m2'), ref('m3'), ref('g1m', 'g1', 'group')],
    });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(JSON.parse(fetchMock.mock.calls[0][1].body).q).toEqual(['Good morning', 'Call me at 555 1234 tomorrow']);
    expect(out.translations.map((t: any) => t.text)).toEqual([
      'Buongiorno', 'Buongiorno', 'Chiamami al 555 1234 domani', 'Ciao a tutti',
    ]);
    expect(out.translations[3]).toMatchObject({ sameLanguage: true, layer: 'message' });
    // Quota: only the chars sent to the API (distinct texts).
    expect(quotaUsed).toBe('Good morning'.length + 'Call me at 555 1234 tomorrow'.length);
    // 2 reads: parents + messages, then the cache docs.
    expect(getAllCalls).toBe(2);
    const paths = writes.map((w) => w.path).sort();
    expect(paths).toEqual([
      `chat_translation_cache/${chatCacheId('it', 'Good morning')}`,
      msgPath('m1'), msgPath('m2'), msgPath('m3'),
    ].sort());
    const cache = writes.find((w) => w.path.startsWith('chat_translation_cache/'))!;
    expect(cache.data).toMatchObject({ target: 'it', text: 'Buongiorno', source: 'en', hits: 1 });
    expect(JSON.stringify(cache.data)).not.toContain('Good morning'); // never the original
    expect(writes.find((w) => w.path === msgPath('m1'))!.data).toEqual({
      tr: { it: 'Buongiorno' }, trHash: messageTextHash('Good morning'), lang: 'en',
    });
  });

  it('adds a language to an existing map with a field-path update', async () => {
    docs.set(msgPath('m1'), {
      type: 'text', content: 'Hello friend', lang: 'en',
      tr: { de: 'Hallo Freund' }, trHash: messageTextHash('Hello friend'),
    });
    fetchMock.mockResolvedValue(apiAnswer([{ translatedText: 'Hola amigo', detectedSourceLanguage: 'en' }]));
    await call({ target: 'es', messages: [ref('m1')] });
    expect(writes.find((w) => w.path === msgPath('m1'))!.data).toEqual({ 'tr.es': 'Hola amigo' });
  });

  it('same-language API result: stores lang only, cache marks same without text', async () => {
    docs.set(msgPath('m1'), { type: 'text', content: 'Buongiorno a te' });
    fetchMock.mockResolvedValue(apiAnswer([{ translatedText: 'Buongiorno a te', detectedSourceLanguage: 'it' }]));
    const out: any = await call({ target: 'it', messages: [ref('m1')] });
    expect(out.translations[0]).toMatchObject({ text: 'Buongiorno a te', sameLanguage: true, layer: 'api' });
    expect(writes.find((w) => w.path === msgPath('m1'))!.data).toEqual({ lang: 'it' });
    const cache = writes.find((w) => w.path.startsWith('chat_translation_cache/'))!;
    expect(cache.data.same).toBe(true);
    expect(cache.data.text).toBeUndefined();
  });

  it('rejects a caller who is not a participant (nothing read back, no API)', async () => {
    docs.set(msgPath('m1'), { type: 'text', content: 'secret' });
    await expect(call({ target: 'it', messages: [ref('m1')] }, 'intruder'))
      .rejects.toMatchObject({ code: 'PERMISSION_DENIED' });
    await expect(call({ target: 'it', messages: [ref('x', 'g1', 'group')] }, 'u2'))
      .rejects.toMatchObject({ code: 'PERMISSION_DENIED' });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('reports missing / non-text / deleted messages per item', async () => {
    docs.set(msgPath('img'), { type: 'image', content: 'https://x/y.jpg' });
    docs.set(msgPath('del'), { type: 'text', content: 'This message was deleted', isDeletedForEveryone: true });
    const out: any = await call({ target: 'it', messages: [ref('gone'), ref('img'), ref('del')] });
    expect(out.translations).toEqual([
      { messageId: 'gone', error: 'not-found' },
      { messageId: 'img', error: 'not-text' },
      { messageId: 'del', error: 'not-text' },
    ]);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('validates refs and batch size', async () => {
    await expect(call({ target: 'it', messages: [{ parentId: 'a/b', messageId: 'm' }] }))
      .rejects.toMatchObject({ code: 'INVALID_ARGUMENT' });
    await expect(call({ target: 'it', messages: Array.from({ length: 26 }, (_, i) => ref(`m${i}`)) }))
      .rejects.toMatchObject({ code: 'TOO_MANY_ITEMS' });
  });

  it('keeps the old free-text path for old app versions', async () => {
    fetchMock.mockResolvedValue(apiAnswer([{ translatedText: 'Ciao', detectedSourceLanguage: 'en' }]));
    const out: any = await call({ target: 'it', texts: ['Hello'] });
    expect(out.translations).toEqual([{ text: 'Ciao', detectedLanguage: 'en', sameLanguage: false }]);
    expect(writes).toEqual([]);
  });
});
