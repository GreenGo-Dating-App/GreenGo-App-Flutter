/**
 * Share-link previews (sharePreviewCore): profile privacy rules, Open Graph
 * rendering and path parsing. Pure functions - no Firestore / network.
 */
import {
  FALLBACK_IMAGE,
  buildCommunityPreview,
  buildEventPreview,
  buildProfilePreview,
  isProfileShareable,
  mainProfilePhoto,
  parseSharePath,
  renderHtml,
  scrubContactInfo,
  webAppUrl,
} from '../../src/share/sharePreviewCore';

const ts = (ms: number) => ({ toMillis: () => ms });
const NOW = Date.UTC(2026, 9, 3);
const PHOTO =
  'https://firebasestorage.googleapis.com/v0/b/x.appspot.com/o/p%2F1.jpg?alt=media&token=abc';

const baseProfile = (): Record<string, unknown> => ({
  userId: 'uid123',
  displayName: 'Ana Souza',
  bio: 'Love languages, samba and street food. Teaching Portuguese!',
  photoUrls: [PHOTO, 'https://firebasestorage.googleapis.com/second.jpg'],
  location: { city: 'Lisbon', country: 'Portugal', latitude: 38.7123, longitude: -9.1456 },
  dateOfBirth: ts(Date.UTC(1995, 4, 1)),
  accountStatus: 'active',
  updatedAt: ts(1700000000000),
});

const og = (html: string, prop: string): string | null => {
  const m = html.match(
    new RegExp(`<meta (?:property|name)="${prop}" content="([^"]*)"`),
  );
  return m ? m[1] : null;
};

describe('parseSharePath', () => {
  it('parses page and image paths for every kind', () => {
    expect(parseSharePath('/u/uid123')).toEqual({ isImage: false, kind: 'u', id: 'uid123' });
    expect(parseSharePath('/e/ev_1')).toEqual({ isImage: false, kind: 'e', id: 'ev_1' });
    expect(parseSharePath('/c/c-1')).toEqual({ isImage: false, kind: 'c', id: 'c-1' });
    expect(parseSharePath('/og/u/uid123.jpg')).toEqual({ isImage: true, kind: 'u', id: 'uid123' });
  });
  it('rejects unknown kinds and malformed ids', () => {
    expect(parseSharePath('/x/abc')).toBeNull();
    expect(parseSharePath('/u/')).toBeNull();
    expect(parseSharePath('/u/a%20b')).toBeNull();
    expect(parseSharePath('/u/%E0%A4%A')).toBeNull();
    expect(parseSharePath('/u/<script>')).toBeNull();
  });
});

describe('profile privacy', () => {
  it('a normal active profile is shareable', () => {
    expect(isProfileShareable(baseProfile(), NOW)).toBe(true);
  });
  it.each([
    ['banned', { isBanned: true }],
    ['suspended', { accountStatus: 'suspended' }],
    ['deleted status', { accountStatus: 'deleted' }],
    ['restricted', { accountStatus: 'restricted' }],
    ['isDeleted flag', { isDeleted: true }],
    ['ghost mode', { isGhostMode: true }],
    ['incognito without expiry', { isIncognito: true }],
    ['incognito not expired', { isIncognito: true, incognitoExpiry: ts(NOW + 60000) }],
    ['sharing opt-out', { allowProfileSharing: false }],
  ])('%s -> generic card with no personal data', (_label, patch) => {
    const d = { ...baseProfile(), ...(patch as Record<string, unknown>) };
    expect(isProfileShareable(d, NOW)).toBe(false);
    const p = buildProfilePreview('uid123', d, NOW);
    expect(p.shareable).toBe(false);
    const html = renderHtml(p);
    expect(html).not.toContain('Ana');
    expect(html).not.toContain('Lisbon');
    expect(html).not.toContain('firebasestorage');
    expect(og(html, 'og:image')).toBe(FALLBACK_IMAGE);
    expect(og(html, 'og:title')).toBe('GreenGo');
  });
  it('expired incognito is shareable again', () => {
    const d = { ...baseProfile(), isIncognito: true, incognitoExpiry: ts(NOW - 1000) };
    expect(isProfileShareable(d, NOW)).toBe(true);
  });
});

describe('buildProfilePreview', () => {
  it('uses name + city, a bio excerpt and the MAIN (first) photo', () => {
    const p = buildProfilePreview('uid123', baseProfile(), NOW);
    expect(p.shareable).toBe(true);
    expect(p.title).toBe('Ana Souza · Lisbon');
    expect(p.description).toContain('samba');
    expect(p.imageUrl).toBe(PHOTO);
    expect(p.version).toBe(1700000000000);
  });

  it('never leaks age, birth date, coordinates or contact info', () => {
    const d = {
      ...baseProfile(),
      bio: 'Call me +55 (11) 98765-4321 or mail ana.souza@gmail.com, IG @ana.sz, see www.ana.com and ana.link/x',
    };
    const html = renderHtml(buildProfilePreview('uid123', d, NOW));
    expect(html).not.toMatch(/98765|4321/);
    expect(html).not.toContain('gmail');
    expect(html).not.toContain('@ana');
    expect(html).not.toContain('www.ana.com');
    expect(html).not.toContain('ana.link');
    expect(html).not.toContain('1995');
    expect(html).not.toContain('38.71');
    expect(html).not.toContain('9.14');
  });

  it('respects location visibility', () => {
    expect(buildProfilePreview('u', { ...baseProfile(), globeDiscoverability: 'hidden' }, NOW).title).toBe('Ana Souza');
    expect(buildProfilePreview('u', { ...baseProfile(), showOnMap: false }, NOW).title).toBe('Ana Souza');
    expect(buildProfilePreview('u', { ...baseProfile(), globeDiscoverability: 'country' }, NOW).title).toBe(
      'Ana Souza · Portugal',
    );
  });

  it('falls back to a friendly description and the branded image', () => {
    const d = { ...baseProfile(), bio: '', photoUrls: [] };
    const p = buildProfilePreview('uid123', d, NOW);
    expect(p.description).toContain('Connect with Ana Souza');
    expect(p.imageUrl).toBeNull();
    const html = renderHtml(p);
    expect(og(html, 'og:image')).toBe(FALLBACK_IMAGE);
    expect(og(html, 'twitter:card')).toBe('summary');
  });

  it('business accounts use the business name / storefront bio / cover', () => {
    const d = {
      ...baseProfile(),
      isBusiness: true,
      businessName: 'Casa Fado',
      storefrontBio: 'Live fado every night.',
      photoUrls: [],
      coverImageUrl: 'https://firebasestorage.googleapis.com/cover.jpg',
    };
    const p = buildProfilePreview('biz1', d, NOW);
    expect(p.title).toBe('Casa Fado · Lisbon');
    expect(p.description).toBe('Live fado every night.');
    expect(p.imageUrl).toBe('https://firebasestorage.googleapis.com/cover.jpg');
  });

  it('mainProfilePhoto ignores non-https entries and supports legacy `photos`', () => {
    expect(mainProfilePhoto({ photoUrls: ['', 'http://x/a.jpg', PHOTO] })).toBe(PHOTO);
    expect(mainProfilePhoto({ photos: [PHOTO] })).toBe(PHOTO);
    expect(mainProfilePhoto({})).toBeNull();
  });
});

describe('renderHtml (profile)', () => {
  const html = renderHtml(buildProfilePreview('uid123', baseProfile(), NOW));

  it('emits large-image Open Graph tags pointing at the resized main photo', () => {
    expect(og(html, 'og:title')).toBe('Ana Souza · Lisbon');
    expect(og(html, 'og:url')).toBe('https://greengo-chat.web.app/u/uid123');
    expect(og(html, 'og:image')).toBe('https://greengo-chat.web.app/og/u/uid123.jpg?v=1700000000000');
    expect(og(html, 'og:image:width')).toBe('1200');
    expect(og(html, 'og:image:height')).toBe('630');
    expect(og(html, 'twitter:card')).toBe('summary_large_image');
    expect(og(html, 'og:type')).toBe('profile');
    expect(og(html, 'robots')).toBe('noindex, nofollow');
  });

  it('hands humans to the app (custom scheme) and desktop to the web app', () => {
    expect(html).toContain('"greengo://u/uid123"');
    expect(html).toContain(JSON.stringify(webAppUrl('u', 'uid123')));
    expect(webAppUrl('u', 'uid123')).toBe('https://greengo-chat.web.app/?link=%2Fu%2Fuid123');
  });

  it('escapes HTML in user-controlled text', () => {
    const d = { ...baseProfile(), displayName: '<img src=x onerror=alert(1)>"', bio: '</script><b>x</b>' };
    const out = renderHtml(buildProfilePreview('uid123', d, NOW));
    expect(out).not.toContain('<img src=x');
    expect(out).not.toContain('</script><b>');
    expect(out).toContain('&lt;img src=x onerror=alert(1)&gt;&quot;');
  });
});

describe('events & communities keep their behaviour', () => {
  it('draft / future scheduled events are generic', () => {
    expect(buildEventPreview('e1', { status: 'draft', title: 'Secret' }, NOW).shareable).toBe(false);
    expect(
      buildEventPreview('e1', { status: 'scheduled', publishAt: ts(NOW + 1000), title: 'Soon' }, NOW).shareable,
    ).toBe(false);
    const live = buildEventPreview('e1', { status: 'published', title: 'Party', city: 'Rome', attendeeCount: 3 }, NOW);
    expect(live.shareable).toBe(true);
    expect(live.description).toContain('📍 Rome');
  });
  it('private communities are generic', () => {
    expect(buildCommunityPreview('c1', { isPublic: false, name: 'Hidden' }).shareable).toBe(false);
    expect(buildCommunityPreview('c1', { name: 'Open', memberCount: 1 }).description).toContain('1 member');
  });
});

describe('scrubContactInfo', () => {
  it('keeps normal prose', () => {
    expect(scrubContactInfo('I speak 3 languages, love 2 cats.')).toBe('I speak 3 languages, love 2 cats.');
  });
});
