import {
  FreeTranslateError,
  freeTranslate,
  freeTranslateMany,
  freeTranslationClient,
  normalizeTarget,
  parseFreeResponse,
  sameBaseLanguage,
} from '../freeTranslate';

/** Free-endpoint body: one [translated, original] pair per sentence. */
const body = (sentences: [string, string][], detected: string) =>
  JSON.stringify([sentences.map(([t, o]) => [t, o, null, null, 10]), null, detected]);

const res = (status: number, text = '') =>
  ({ ok: status >= 200 && status < 300, status, text: async () => text }) as unknown as Response;

const noDelay = { backoffMs: () => 0 };

describe('parseFreeResponse', () => {
  it('joins every sentence in order and reports the detected language', () => {
    const r = parseFreeResponse(
      body([['Ciao amico mio. ', 'Hello my friend. '], ['Come stai?', 'How are you?']], 'en'),
      'Hello my friend. How are you?',
      'it',
    );
    expect(r).toEqual({ text: 'Ciao amico mio. Come stai?', detectedLanguage: 'en', sameLanguage: false });
  });

  it('returns the original when the source already is the target (incl. regional variants)', () => {
    const r = parseFreeResponse(body([['Bom dia', 'Bom dia']], 'pt'), 'Bom dia', 'pt-BR');
    expect(r).toEqual({ text: 'Bom dia', detectedLanguage: 'pt', sameLanguage: true });
  });

  it('rejects bodies that are not the endpoint format', () => {
    expect(parseFreeResponse('<html>captcha</html>', 'x', 'it')).toBeNull();
    expect(parseFreeResponse('{"a":1}', 'x', 'it')).toBeNull();
    expect(parseFreeResponse('[]', 'x', 'it')).toBeNull();
  });
});

describe('language helpers', () => {
  it('normalizes targets the way the endpoint expects', () => {
    expect(normalizeTarget('pt_BR')).toBe('pt-BR');
    expect(normalizeTarget('EN')).toBe('en');
    expect(normalizeTarget('zh-cn')).toBe('zh-CN');
    expect(sameBaseLanguage('pt', 'pt-BR')).toBe(true);
    expect(sameBaseLanguage('en', 'it')).toBe(false);
  });
});

describe('freeTranslate', () => {
  it('retries a 429 and then succeeds', async () => {
    const fetchImpl = jest
      .fn()
      .mockResolvedValueOnce(res(429, 'Too Many Requests'))
      .mockResolvedValueOnce(res(200, body([['Ciao', 'Hello']], 'en')));
    const r = await freeTranslate('Hello', 'it', { fetchImpl, ...noDelay });
    expect(r.text).toBe('Ciao');
    expect(fetchImpl).toHaveBeenCalledTimes(2);
    const url = fetchImpl.mock.calls[0][0] as string;
    expect(url).toContain('client=gtx');
    expect(url).toContain('tl=it');
    expect(url).toContain('q=Hello');
  });

  it('throws a transient 429 error after the last attempt', async () => {
    const fetchImpl = jest.fn().mockResolvedValue(res(429));
    await expect(freeTranslate('Hello', 'it', { fetchImpl, ...noDelay })).rejects.toMatchObject({
      status: 429,
      transient: true,
    });
    expect(fetchImpl).toHaveBeenCalledTimes(3);
  });

  it('does not retry a 400', async () => {
    const fetchImpl = jest.fn().mockResolvedValue(res(400));
    await expect(freeTranslate('Hello', 'it', { fetchImpl, ...noDelay })).rejects.toBeInstanceOf(
      FreeTranslateError,
    );
    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });

  it('retries network errors', async () => {
    const fetchImpl = jest
      .fn()
      .mockRejectedValueOnce(new Error('ECONNRESET'))
      .mockResolvedValueOnce(res(200, body([['Hallo', 'Hello']], 'en')));
    const r = await freeTranslate('Hello', 'de', { fetchImpl, ...noDelay });
    expect(r.text).toBe('Hallo');
  });

  it('sends long texts as a POST body', async () => {
    const long = 'word '.repeat(400);
    const fetchImpl = jest.fn().mockResolvedValue(res(200, body([['parola', long]], 'en')));
    await freeTranslate(long, 'it', { fetchImpl, ...noDelay });
    const [url, init] = fetchImpl.mock.calls[0];
    expect(init.method).toBe('POST');
    expect(url).not.toContain('q=');
    expect(new URLSearchParams(init.body).get('q')).toBe(long);
  });

  it('short-circuits when source and target are the same language', async () => {
    const fetchImpl = jest.fn();
    const r = await freeTranslate('Hi', 'en-GB', { source: 'en', fetchImpl });
    expect(r).toEqual({ text: 'Hi', detectedLanguage: 'en', sameLanguage: true });
    expect(fetchImpl).not.toHaveBeenCalled();
  });
});

describe('freeTranslateMany', () => {
  it('keeps order, limits concurrency and returns null for failures', async () => {
    let active = 0;
    let peak = 0;
    const fetchImpl = jest.fn(async (url: string) => {
      active++;
      peak = Math.max(peak, active);
      await new Promise((r) => setTimeout(r, 5));
      active--;
      const q = new URL(url).searchParams.get('q')!;
      if (q === 'bad') return res(400);
      return res(200, body([[`T:${q}`, q]], 'en'));
    });
    const texts = Array.from({ length: 12 }, (_, i) => (i === 5 ? 'bad' : `m${i}`));
    const out = await freeTranslateMany(texts, 'it', {
      fetchImpl: fetchImpl as unknown as typeof fetch,
      concurrency: 3,
      ...noDelay,
    });
    expect(peak).toBeLessThanOrEqual(3);
    expect(out[0]?.text).toBe('T:m0');
    expect(out[11]?.text).toBe('T:m11');
    expect(out[5]).toBeNull();
  });

  it('stops after a persistent rate limit so callers return what they have', async () => {
    const fetchImpl = jest.fn().mockResolvedValue(res(429));
    const out = await freeTranslateMany(['a', 'b', 'c', 'd', 'e'], 'it', {
      fetchImpl,
      concurrency: 1,
      ...noDelay,
    });
    expect(out).toEqual([null, null, null, null, null]);
    // Only the first text was attempted (3 tries), the rest were skipped.
    expect(fetchImpl).toHaveBeenCalledTimes(3);
  });
});

describe('freeTranslationClient (legacy shape)', () => {
  const realFetch = global.fetch;
  afterEach(() => {
    global.fetch = realFetch;
  });

  it('answers in the TranslationServiceClient.translateText shape', async () => {
    global.fetch = jest.fn().mockResolvedValue(res(200, body([['Hola', 'Hello']], 'en'))) as never;
    const [resp] = await freeTranslationClient.translateText({
      contents: ['Hello'],
      targetLanguageCode: 'es',
    });
    expect(resp.translations).toEqual([{ translatedText: 'Hola', detectedLanguageCode: 'en' }]);
  });
});
