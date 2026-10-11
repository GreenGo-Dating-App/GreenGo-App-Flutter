/**
 * Share-link previews for EXPERIENCES (/x/{id}) and catalogue ATTRACTIONS
 * (/a/{id}), localized fixed strings, community/event takedown privacy, and
 * the HTTP handler end to end with a WhatsApp crawler user agent (Firestore,
 * axios and sharp mocked - no network, no emulator).
 */
import {
  FALLBACK_IMAGE,
  attractionImageUrl,
  attractionPhotoPolicy,
  buildAttractionPreview,
  buildCommunityPreview,
  buildEventPreview,
  buildExperiencePreview,
  categoryLabel,
  firstSentence,
  formatDuration,
  formatPrice,
  genericPreview,
  parseSharePath,
  pickLocale,
  renderHtml,
} from '../../src/share/sharePreviewCore';
import { ARB_CATALOG } from '../../src/shared/i18n/catalog.generated';

const ts = (ms: number) => ({ toMillis: () => ms });
const NOW = Date.UTC(2026, 9, 11);
const EXP_PHOTO =
  'https://firebasestorage.googleapis.com/v0/b/greengo-chat.firebasestorage.app/o/experiences%2Fx1%2Fmain.jpg?alt=media&token=t1';

const og = (html: string, prop: string): string | null => {
  const m = html.match(new RegExp(`<meta (?:property|name)="${prop}" content="([^"]*)"`));
  return m ? m[1] : null;
};

const experience = (): Record<string, unknown> => ({
  hostId: 'host1',
  hostName: 'Marta Rossi',
  title: 'Pasta-making class in Trastevere',
  description:
    'Learn to make fresh pasta with a Roman nonna. We finish with lunch and wine on the terrace. Call +39 333 123 4567!',
  mainPhotoUrl: EXP_PHOTO,
  photoUrls: [],
  city: 'Rome',
  country: 'Italy',
  locationName: 'Trastevere',
  durationMinutes: 150,
  price: 45,
  currency: 'EUR',
  isFree: false,
  status: 'published',
  updatedAt: ts(1760000000000),
});

const attraction = (): Record<string, unknown> => ({
  id: 4242,
  name: 'Colosseum',
  cityName: 'Rome',
  countryName: 'Italy',
  category: 'Historic Site',
  descriptionShort: 'The largest ancient amphitheatre ever built.',
  descriptionMedium: 'Long text. More text.',
  img: { base: 'attractions/IT/4242', hash: 'abc123', token: 'tok-1', source: 'commons' },
  attribution: { author: 'Jane Doe', license: 'CC BY-SA 4.0', sourceUrl: 'https://commons.wikimedia.org/x', required: true },
  status: 'published',
  updatedAt: ts(1750000000000),
});

// ---------------------------------------------------------------------------
describe('parseSharePath (new kinds)', () => {
  it('parses experience and attraction pages and images', () => {
    expect(parseSharePath('/x/exp_1')).toEqual({ isImage: false, kind: 'x', id: 'exp_1' });
    expect(parseSharePath('/a/4242')).toEqual({ isImage: false, kind: 'a', id: '4242' });
    expect(parseSharePath('/og/x/exp_1.jpg')).toEqual({ isImage: true, kind: 'x', id: 'exp_1' });
    expect(parseSharePath('/og/a/4242.jpg')).toEqual({ isImage: true, kind: 'a', id: '4242' });
  });
  it('rejects malformed ids', () => {
    expect(parseSharePath('/x/<b>')).toBeNull();
    expect(parseSharePath('/a/')).toBeNull();
  });
});

describe('pickLocale', () => {
  it('defaults to English (crawlers usually send no Accept-Language)', () => {
    expect(pickLocale(undefined)).toBe('en');
    expect(pickLocale('')).toBe('en');
    expect(pickLocale('ja-JP,zh;q=0.8')).toBe('en');
  });
  it('honours weights, regions and ?hl=', () => {
    expect(pickLocale('pt-BR,pt;q=0.9,en;q=0.8')).toBe('pt_BR');
    expect(pickLocale('pt-PT')).toBe('pt');
    expect(pickLocale('en;q=0.3, it-IT;q=0.9')).toBe('it');
    expect(pickLocale('ja,de;q=0.5')).toBe('de');
    expect(pickLocale('en', 'fr')).toBe('fr');
    expect(pickLocale('es', 'xx')).toBe('es');
  });
});

describe('formatting helpers', () => {
  it('formats prices in the card language and handles bad input', () => {
    expect(formatPrice(45, 'EUR', 'en')).toBe('€45');
    expect(formatPrice(80.5, 'BRL', 'pt_BR')).toMatch(/R\$\s?80,50/);
    expect(formatPrice(0, 'EUR', 'en')).toBe('');
    expect(formatPrice(12, 'NOPE1', 'en')).toBe('12 NOPE1');
    expect(formatPrice(12, '', 'en')).toBe('12');
  });
  it('formats durations from catalog units', () => {
    expect(formatDuration(150, 'en')).toBe('2 h 30 min');
    expect(formatDuration(60, 'de')).toBe('1 h');
    expect(formatDuration(45, 'it')).toBe('45 min');
    expect(formatDuration(0, 'en')).toBe('');
  });
  it('takes the first sentence', () => {
    expect(firstSentence('One. Two.')).toBe('One.');
    expect(firstSentence('No full stop here')).toBe('No full stop here');
  });
});

// ---------------------------------------------------------------------------
describe('buildExperiencePreview', () => {
  it('published -> full card: 📍 city · price · duration · by host — first sentence', () => {
    const p = buildExperiencePreview('exp_1', experience());
    expect(p.shareable).toBe(true);
    expect(p.title).toBe('Pasta-making class in Trastevere');
    expect(p.description).toBe(
      '📍 Rome · €45 · 2 h 30 min · by Marta Rossi — Learn to make fresh pasta with a Roman nonna.',
    );
    expect(p.imageUrl).toBe(EXP_PHOTO);
    expect(p.version).toBe(1760000000000);
    const html = renderHtml(p);
    expect(og(html, 'og:title')).toBe('Pasta-making class in Trastevere');
    expect(og(html, 'og:url')).toBe('https://greengo-chat.web.app/x/exp_1');
    expect(og(html, 'og:image')).toBe('https://greengo-chat.web.app/og/x/exp_1.jpg?v=1760000000000');
    expect(og(html, 'og:type')).toBe('website');
    expect(og(html, 'og:locale')).toBe('en_US');
    expect(og(html, 'twitter:card')).toBe('summary_large_image');
    expect(html).toContain('"greengo://x/exp_1"');
    expect(html).toContain('/?link=%2Fx%2Fexp_1');
    expect(html).not.toContain('robots');
  });

  it('free experiences say Free (localized) and contact details are scrubbed', () => {
    const d = { ...experience(), isFree: true, price: 0, description: 'Call +39 333 123 4567 now. Bye.' };
    const p = buildExperiencePreview('exp_1', d, 'it');
    expect(p.description).toContain(ARB_CATALOG.it.attrFree);
    expect(p.description).toContain('di Marta Rossi');
    expect(p.description).not.toMatch(/333|4567/);
  });

  it('falls back to the first gallery photo, else the brand image', () => {
    const d = { ...experience(), mainPhotoUrl: '', photoUrls: ['http://insecure/x.jpg', EXP_PHOTO] };
    expect(buildExperiencePreview('e', d).imageUrl).toBe(EXP_PHOTO);
    const none = buildExperiencePreview('e', { ...experience(), mainPhotoUrl: '' });
    expect(none.imageUrl).toBeNull();
    const html = renderHtml(none);
    expect(og(html, 'og:image')).toBe(FALLBACK_IMAGE);
    expect(og(html, 'twitter:card')).toBe('summary');
  });

  it('truncates long descriptions to <= 200 chars with an ellipsis', () => {
    const d = { ...experience(), description: `${'word '.repeat(80)}end.` };
    const p = buildExperiencePreview('e', d);
    expect(p.description.length).toBeLessThanOrEqual(200);
    expect(p.description.endsWith('…')).toBe(true);
    const long = buildExperiencePreview('e', { ...experience(), title: 'T'.repeat(300) });
    expect(long.title.length).toBeLessThanOrEqual(90);
  });

  it.each([
    ['draft', { status: 'draft' }],
    ['hidden (reports / moderation / banned host)', { status: 'hidden', moderation: { reason: 'host_banned' } }],
    ['missing status', { status: undefined }],
    ['copyright hold', { copyrightHold: { noticeId: 'n1' } }],
    ['safety hold', { safetyHold: { caseId: 's1' } }],
  ])('%s -> generic card, nothing leaks', (_l, patch) => {
    const p = buildExperiencePreview('exp_1', { ...experience(), ...(patch as Record<string, unknown>) });
    expect(p.shareable).toBe(false);
    const html = renderHtml(p);
    expect(og(html, 'og:title')).toBe('GreenGo');
    expect(og(html, 'og:image')).toBe(FALLBACK_IMAGE);
    expect(html).not.toContain('Pasta');
    expect(html).not.toContain('Marta');
    expect(html).not.toContain('firebasestorage');
  });

  it('never uses a photo moved under safety_holds/', () => {
    const held =
      'https://firebasestorage.googleapis.com/v0/b/b/o/safety_holds%2Fcase1%2Fexperiences%2Fx.jpg?alt=media';
    const p = buildExperiencePreview('e', { ...experience(), mainPhotoUrl: held });
    expect(p.imageUrl).toBeNull();
  });

  it('escapes HTML in host-controlled text', () => {
    const d = { ...experience(), title: '<script>alert(1)</script>"x', hostName: '<img src=x onerror=1>' };
    const html = renderHtml(buildExperiencePreview('e', d));
    expect(html).not.toContain('<script>alert(1)');
    expect(html).not.toContain('<img src=x');
    expect(html).toContain('&lt;script&gt;alert(1)&lt;/script&gt;&quot;x');
  });
});

// ---------------------------------------------------------------------------
describe('attractions', () => {
  it('published -> full card with localized category and the licence credit', () => {
    const p = buildAttractionPreview('4242', attraction(), 'greengo-chat.firebasestorage.app');
    expect(p.shareable).toBe(true);
    expect(p.title).toBe('Colosseum');
    expect(p.description).toBe(
      `📍 Rome, Italy · ${ARB_CATALOG.en.attrCatHistoricSite} — The largest ancient amphitheatre ever built. · Photo: Jane Doe, CC BY-SA 4.0`,
    );
    expect(p.imageUrl).toBe(
      'https://firebasestorage.googleapis.com/v0/b/greengo-chat.firebasestorage.app/o/attractions%2FIT%2F4242%2Fhero-abc123.webp?alt=media&token=tok-1',
    );
    const html = renderHtml(p);
    expect(og(html, 'og:url')).toBe('https://greengo-chat.web.app/a/4242');
    expect(og(html, 'og:image')).toBe('https://greengo-chat.web.app/og/a/4242.jpg?v=1750000000000');
    expect(og(html, 'twitter:card')).toBe('summary_large_image');
  });

  it('localizes the category and the credit label (German)', () => {
    const p = buildAttractionPreview('4242', attraction(), undefined, 'de');
    expect(p.description).toContain(ARB_CATALOG.de.attrCatHistoricSite);
    expect(p.description).toContain('Foto: Jane Doe');
    expect(categoryLabel('Brand-new category', 'de')).toBe('Brand-new category');
    expect(renderHtml(p)).toContain('<html lang="de">');
  });

  it.each([
    ['CC BY-ND 4.0'],
    ['CC BY-NC-SA 3.0'],
    ['All rights reserved'],
    ['Fair use'],
  ])('licence %s forbids the photo -> brand image, no credit', (license) => {
    const d = { ...attraction(), attribution: { author: 'X', license, required: true } };
    expect(attractionPhotoPolicy(d).use).toBe(false);
    const p = buildAttractionPreview('4242', d);
    expect(p.shareable).toBe(true);
    expect(p.imageUrl).toBeNull();
    expect(p.description).not.toContain('Photo:');
    expect(og(renderHtml(p), 'og:image')).toBe(FALLBACK_IMAGE);
  });

  it('attribution required but unknown author/licence -> brand image', () => {
    const d = { ...attraction(), attribution: { author: '', license: '', required: true } };
    expect(buildAttractionPreview('4242', d).imageUrl).toBeNull();
  });

  it('AI-generated / public-domain photos need no credit', () => {
    const ai = { ...attraction(), img: { ...(attraction().img as object), source: 'ai' }, attribution: null };
    const p = buildAttractionPreview('4242', ai);
    expect(p.imageUrl).not.toBeNull();
    expect(p.description).not.toContain('Photo:');
    const pd = { ...attraction(), attribution: { author: '', license: 'Public domain', required: false } };
    expect(attractionPhotoPolicy(pd)).toEqual({ use: true, credit: null });
  });

  it('unpublished / taken down -> generic', () => {
    for (const patch of [{ status: 'draft' }, { status: undefined }, { copyrightHold: { noticeId: 'n' } }]) {
      const p = buildAttractionPreview('4242', { ...attraction(), ...patch });
      expect(p.shareable).toBe(false);
      expect(renderHtml(p)).not.toContain('Colosseum');
    }
  });

  it('rejects a weird bucket name instead of building a URL', () => {
    expect(attractionImageUrl(attraction(), 'evil.com/x?')).toBeNull();
  });
});

// ---------------------------------------------------------------------------
describe('communities & events never leak when private / held', () => {
  const community = { name: 'Secret Club', description: 'Our hidden place', imageUrl: EXP_PHOTO, memberCount: 9, city: 'Oslo' };
  it.each([
    ['private', { isPublic: false }],
    ['isPrivate flag', { isPrivate: true }],
    ['copyright hold', { copyrightHold: { noticeId: 'n' } }],
    ['hidden status', { status: 'hidden' }],
    ['removed status', { status: 'removed' }],
    ['deleted', { isDeleted: true }],
  ])('%s community -> generic', (_l, patch) => {
    const html = renderHtml(buildCommunityPreview('c1', { ...community, ...(patch as Record<string, unknown>) }));
    expect(og(html, 'og:title')).toBe('GreenGo');
    expect(og(html, 'og:image')).toBe(FALLBACK_IMAGE);
    expect(html).not.toContain('Secret');
    expect(html).not.toContain('hidden place');
    expect(html).not.toContain('firebasestorage');
  });
  it('public community keeps its card; held photo is dropped', () => {
    const ok = buildCommunityPreview('c1', community, 'pt_BR');
    expect(ok.shareable).toBe(true);
    expect(ok.description).toContain('9 membros');
    const held = buildCommunityPreview('c1', {
      ...community,
      imageUrl: 'https://firebasestorage.googleapis.com/v0/b/b/o/safety_holds%2Fc%2Fx.jpg',
    });
    expect(held.imageUrl).toBeNull();
  });
  it('copyright-held (cancelled) event -> generic', () => {
    const p = buildEventPreview('e1', { status: 'cancelled', title: 'Pirated', copyrightHold: { noticeId: 'n' } }, NOW);
    expect(p.shareable).toBe(false);
  });
});

describe('localized fixed strings', () => {
  it('generic card and buttons come from the catalog', () => {
    const html = renderHtml(genericPreview('x', 'abc', 'fr'));
    expect(og(html, 'og:description')).toBe(ARB_CATALOG.fr.sharePreviewGenericDescription);
    expect(og(html, 'og:locale')).toBe('fr_FR');
    expect(html).toContain(ARB_CATALOG.fr.sharePreviewOpenApp);
    expect(html).toContain(ARB_CATALOG.fr.sharePreviewOpenWeb);
  });
  it('event facts use the catalog (Spanish)', () => {
    const p = buildEventPreview('e1', { status: 'published', title: 'Fiesta', organizerName: 'Ana', attendeeCount: 4 }, NOW, 'es');
    expect(p.description).toContain('por Ana');
    expect(p.description).toContain('4 asistirán');
  });
});

// ---------------------------------------------------------------------------
// HTTP handler, end to end with a WhatsApp crawler UA.
// ---------------------------------------------------------------------------
const mockDocs: Record<string, Record<string, unknown> | undefined> = {};

jest.mock('firebase-functions/v2/https', () => ({
  onRequest: (_opts: unknown, handler: unknown) => handler,
}));
jest.mock('../../src/shared/monitoring', () => ({
  monitored: (_name: string, handler: unknown) => handler,
}));
jest.mock('axios', () => ({ __esModule: true, default: { get: jest.fn() } }));
jest.mock('sharp', () => ({ __esModule: true, default: jest.fn() }));
jest.mock('../../src/shared/firebaseAdmin', () => ({
  admin: {
    firestore: () => ({
      collection: (c: string) => ({
        doc: (id: string) => ({
          get: async () => {
            const d = mockDocs[`${c}/${id}`];
            return { exists: !!d, data: () => d, get: (k: string) => (d ? d[k] : undefined) };
          },
        }),
      }),
    }),
  },
}));

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { sharePreview } = require('../../src/share/sharePreview');

interface FakeRes {
  statusCode: number;
  headers: Record<string, string>;
  body: unknown;
  location?: string;
}

async function call(path: string, headers: Record<string, string> = {}, query: Record<string, string> = {}): Promise<FakeRes> {
  const out: FakeRes = { statusCode: 200, headers: {}, body: undefined };
  const lower = Object.fromEntries(Object.entries(headers).map(([k, v]) => [k.toLowerCase(), v]));
  const req = { method: 'GET', path, query, get: (h: string) => lower[h.toLowerCase()] };
  const res = {
    status(c: number) { out.statusCode = c; return res; },
    set(k: string, v: string) { out.headers[k.toLowerCase()] = v; return res; },
    type(t: string) { out.headers['content-type'] = t; return res; },
    send(b: unknown) { out.body = b; return res; },
    redirect(c: number, l: string) { out.statusCode = c; out.location = l; return res; },
  };
  await sharePreview(req, res);
  return out;
}

const WHATSAPP_UA = 'WhatsApp/2.23.20.0 A';

describe('sharePreview handler (WhatsApp crawler)', () => {
  beforeEach(() => {
    for (const k of Object.keys(mockDocs)) delete mockDocs[k];
    mockDocs['user_experiences/exp_1'] = experience();
    mockDocs['attractions/4242'] = attraction();
    mockDocs['attraction_config/app'] = { storageBucket: 'greengo-chat.firebasestorage.app' };
  });

  it('/x/{id} returns the experience Open Graph card', async () => {
    const r = await call('/x/exp_1', { 'User-Agent': WHATSAPP_UA });
    expect(r.statusCode).toBe(200);
    expect(r.headers['content-type']).toBe('html');
    expect(r.headers['cache-control']).toBe('public, max-age=300, s-maxage=600');
    expect(r.headers.vary).toBe('Accept-Language');
    const html = String(r.body);
    expect(og(html, 'og:title')).toBe('Pasta-making class in Trastevere');
    expect(og(html, 'og:description')).toContain('📍 Rome · €45 · 2 h 30 min · by Marta Rossi');
    expect(og(html, 'og:image')).toBe('https://greengo-chat.web.app/og/x/exp_1.jpg?v=1760000000000');
  });

  it('/a/{id} returns the attraction card, localized by Accept-Language', async () => {
    const r = await call('/a/4242', { 'User-Agent': WHATSAPP_UA, 'Accept-Language': 'it-IT,it;q=0.9' });
    const html = String(r.body);
    expect(r.headers['cache-control']).toBe('public, max-age=300, s-maxage=1800');
    expect(og(html, 'og:title')).toBe('Colosseum');
    expect(og(html, 'og:description')).toContain(`📍 Rome, Italy · ${ARB_CATALOG.it.attrCatHistoricSite}`);
    expect(og(html, 'og:description')).toContain('Foto: Jane Doe, CC BY-SA 4.0');
    expect(og(html, 'og:locale')).toBe('it_IT');
  });

  it('hidden experience / unknown id -> generic card', async () => {
    mockDocs['user_experiences/exp_1'] = { ...experience(), status: 'hidden' };
    for (const path of ['/x/exp_1', '/x/missing', '/a/999']) {
      const html = String((await call(path, { 'User-Agent': WHATSAPP_UA })).body);
      expect(og(html, 'og:title')).toBe('GreenGo');
      expect(html).not.toContain('Pasta');
    }
  });

  it('image of a hidden experience redirects to the brand image', async () => {
    mockDocs['user_experiences/exp_1'] = { ...experience(), status: 'draft' };
    const r = await call('/og/x/exp_1.jpg');
    expect(r.statusCode).toBe(302);
    expect(r.location).toBe(FALLBACK_IMAGE);
  });

  it('unknown paths go home', async () => {
    const r = await call('/zz/abc');
    expect(r.statusCode).toBe(302);
  });
});
