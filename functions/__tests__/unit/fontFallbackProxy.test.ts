/**
 * fontFallbackProxyCore: the /gfonts allow-list must only ever proxy
 * fonts.gstatic.com font files (never an open proxy), and the handler must
 * cache good fonts immutably and refuse anything that is not a font.
 */
import {
  FONT_CACHE,
  MAX_FONT_BYTES,
  NOT_FOUND_CACHE,
  fontTargetForPath,
  handleFontRequest,
  looksLikeFont,
} from '../../src/web/fontFallbackProxyCore';

const ROBOTO = '/s/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2';
const EMOJI = '/s/notocoloremoji/v32/Yq6P-KqIXTD0t4D9z1ESnKM3-HpFabsE4tq3luCC7p-aXxcn.3.woff2';
const WOFF2 = Buffer.concat([Buffer.from('wOF2', 'latin1'), Buffer.alloc(64, 1)]);

describe('fontTargetForPath', () => {
  it.each([
    [ROBOTO],
    ['/gfonts' + ROBOTO],
    [EMOJI],
    ['/gfonts/s/notosansjp/v53/-F6jfjtqLzI2JPCgQBnw7HFyzSD-AsregP8VFBEj75vY0rw-oME.0.woff2'],
    ['/gfonts/s/notosansarabic/v18/nwpxtLGrOAZMl5nJ_wfgRg3DrWFZWsnVBJ_sS6tlqHHFlhQ5l3sQWIHPqzCfyGyvu3CBFQLaig.ttf'],
  ])('allows engine font path %s', (p) => {
    const t = fontTargetForPath(p);
    expect(t).not.toBeNull();
    expect(t!.url.startsWith('https://fonts.gstatic.com/s/')).toBe(true);
    expect(t!.url).toBe('https://fonts.gstatic.com' + p.replace(/^\/gfonts/, ''));
  });

  it('maps content types by extension', () => {
    expect(fontTargetForPath(ROBOTO)!.contentType).toBe('font/woff2');
    expect(fontTargetForPath('/s/notosans/v1/abcdefgh12.ttf')!.contentType).toBe('font/ttf');
  });

  it.each([
    [''],
    ['/'],
    ['/gfonts/'],
    ['/s/'],
    // other hosts / schemes / open-proxy attempts
    ['/gfonts/https://evil.example/x.woff2'],
    ['/gfonts//evil.example/s/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2'],
    ['/gfonts/s/roboto/v32/../../../etc/passwd'],
    ['/gfonts/s/roboto/v32/%2e%2e%2fKFOmCnqEu92Fr1Me4GZLCzYlKw.woff2'],
    ['/gfonts/s/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2?x=1'],
    // families outside the allow-list
    ['/gfonts/s/lato/v24/S6uyw4BMUTPHjx4wXg.woff2'],
    ['/gfonts/s/materialicons/v1/abcdefghijkl.woff2'],
    // other gstatic trees (e.g. flutter-canvaskit, icons) and non-font files
    ['/gfonts/flutter-canvaskit/abc/canvaskit.wasm'],
    ['/gfonts/s/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.js'],
    ['/gfonts/s/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.svg'],
    ['/gfonts/s/roboto/vX/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2'],
    ['/gfonts/s/Roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2'],
    ['/gfonts/s/roboto/v32/short.woff2'],
    ['/other/s/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2'],
    ['/gfonts/s/roboto/v32/' + 'a'.repeat(400) + '.woff2'],
  ])('rejects %s', (p) => {
    expect(fontTargetForPath(p)).toBeNull();
  });

  it('rejects non-strings', () => {
    expect(fontTargetForPath(undefined)).toBeNull();
    expect(fontTargetForPath(42)).toBeNull();
  });
});

describe('looksLikeFont', () => {
  it('accepts font signatures', () => {
    for (const tag of ['wOF2', 'wOFF', 'OTTO', 'true']) {
      expect(looksLikeFont(Buffer.concat([Buffer.from(tag, 'latin1'), Buffer.alloc(8)]))).toBe(true);
    }
    expect(looksLikeFont(Buffer.from([0, 1, 0, 0, 0, 0]))).toBe(true);
  });
  it('rejects html / empty', () => {
    expect(looksLikeFont(Buffer.from('<!DOCTYPE html>'))).toBe(false);
    expect(looksLikeFont(Buffer.alloc(0))).toBe(false);
  });
});

function fakeRes() {
  const r: any = { headers: {} as Record<string, string>, code: 0, body: undefined, ended: false };
  r.status = (c: number) => { r.code = c; return r; };
  r.set = (k: string, v: string) => { r.headers[k] = v; return r; };
  r.send = (b?: unknown) => { r.body = b; return r; };
  r.end = () => { r.ended = true; return r; };
  return r;
}

describe('handleFontRequest', () => {
  it('serves an allowed font with immutable caching and never calls upstream for other paths', async () => {
    const fetcher = jest.fn().mockResolvedValue({ status: 200, data: WOFF2 });
    const res = fakeRes();
    await handleFontRequest({ method: 'GET', path: '/gfonts' + ROBOTO }, res, fetcher);
    expect(fetcher).toHaveBeenCalledWith('https://fonts.gstatic.com' + ROBOTO);
    expect(res.code).toBe(200);
    expect(res.headers['Content-Type']).toBe('font/woff2');
    expect(res.headers['Cache-Control']).toBe(FONT_CACHE);
    expect(res.body).toBe(WOFF2);

    const bad = fakeRes();
    await handleFontRequest({ method: 'GET', path: '/gfonts/https://evil.example/x' }, bad, fetcher);
    expect(bad.code).toBe(404);
    expect(bad.headers['Cache-Control']).toBe(NOT_FOUND_CACHE);
    expect(fetcher).toHaveBeenCalledTimes(1);
  });

  it('HEAD returns headers only', async () => {
    const res = fakeRes();
    await handleFontRequest({ method: 'HEAD', path: ROBOTO }, res, async () => ({ status: 200, data: WOFF2 }));
    expect(res.code).toBe(200);
    expect(res.ended).toBe(true);
    expect(res.body).toBeUndefined();
  });

  it('rejects other methods', async () => {
    const fetcher = jest.fn();
    const res = fakeRes();
    await handleFontRequest({ method: 'POST', path: ROBOTO }, res, fetcher);
    expect(res.code).toBe(405);
    expect(fetcher).not.toHaveBeenCalled();
  });

  it('passes upstream 404 through with a short cache', async () => {
    const res = fakeRes();
    await handleFontRequest({ method: 'GET', path: ROBOTO }, res, async () => ({ status: 404, data: Buffer.from('') }));
    expect(res.code).toBe(404);
    expect(res.headers['Cache-Control']).toBe(NOT_FOUND_CACHE);
  });

  it.each([
    ['redirect', { status: 302, data: Buffer.alloc(0) }],
    ['html instead of a font', { status: 200, data: Buffer.from('<html>login</html>') }],
    ['oversized', { status: 200, data: Buffer.concat([Buffer.from('wOF2'), Buffer.alloc(MAX_FONT_BYTES)]) }],
    ['server error', { status: 500, data: Buffer.alloc(0) }],
  ])('refuses a bad upstream response (%s) without caching it', async (_n, upstream) => {
    const res = fakeRes();
    await handleFontRequest({ method: 'GET', path: ROBOTO }, res, async () => upstream as any);
    expect(res.code).toBe(502);
    expect(res.headers['Cache-Control']).toBe('no-store');
  });

  it('maps network errors to 502 no-store', async () => {
    const res = fakeRes();
    await handleFontRequest({ method: 'GET', path: ROBOTO }, res, async () => { throw new Error('ECONNRESET'); });
    expect(res.code).toBe(502);
    expect(res.headers['Cache-Control']).toBe('no-store');
  });
});
