/**
 * Invite-link preview page (/r/{CODE}) served by sharePreview: path parsing,
 * language selection, privacy of the inviter, Open Graph tags and the
 * store / web hand-offs. Pure functions - no Firestore / network.
 */
import {
  buildReferralPreview,
  inviterPublicName,
  localeFromAcceptLanguage,
  parseReferralPath,
  playStoreReferralUrl,
  referralWebAppUrl,
  renderReferralHtml,
} from '../../src/share/referralPreviewCore';
import { FALLBACK_IMAGE, parseSharePath } from '../../src/share/sharePreviewCore';

const og = (html: string, prop: string): string | null => {
  const m = html.match(new RegExp(`<meta (?:property|name)="${prop}" content="([^"]*)"`));
  return m ? m[1] : null;
};

describe('parseReferralPath', () => {
  test('accepts /r/{CODE} and normalizes case', () => {
    expect(parseReferralPath('/r/ABC234')).toBe('ABC234');
    expect(parseReferralPath('/r/abc234')).toBe('ABC234');
    expect(parseReferralPath('/r/ABC234/')).toBe('ABC234');
  });
  test('rejects other paths and malformed codes', () => {
    expect(parseReferralPath('/u/ABC234')).toBeNull();
    expect(parseReferralPath('/r/')).toBeNull();
    expect(parseReferralPath('/r/AB')).toBeNull();
    expect(parseReferralPath('/r/ABC_234')).toBeNull();
    expect(parseReferralPath('/r/ABC234/extra')).toBeNull();
    expect(parseReferralPath('/r/%E0%A4%A')).toBeNull();
    expect(parseReferralPath('/r/<script>')).toBeNull();
  });
  test('the existing share routes do not claim /r/', () => {
    expect(parseSharePath('/r/ABC234')).toBeNull();
  });
});

describe('localeFromAcceptLanguage', () => {
  test.each([
    ['pt-BR,pt;q=0.9,en;q=0.8', 'pt_BR'],
    ['pt-PT,pt;q=0.9', 'pt'],
    ['de-DE,de;q=0.9', 'de'],
    ['ja,fr;q=0.5', 'fr'],
    ['en;q=0.1,it;q=0.9', 'it'],
    ['zh-CN', 'en'],
    ['', 'en'],
    [undefined, 'en'],
  ])('%s -> %s', (header, locale) => {
    expect(localeFromAcceptLanguage(header)).toBe(locale);
  });
});

describe('inviterPublicName (privacy)', () => {
  test('public display name only', () => {
    expect(inviterPublicName({ displayName: 'Ana Souza', accountStatus: 'active' })).toBe('Ana Souza');
    expect(inviterPublicName({ isBusiness: true, businessName: 'Café Lisboa', displayName: 'Ana' })).toBe('Café Lisboa');
  });
  test('hidden / missing profiles show no name', () => {
    expect(inviterPublicName(null)).toBe('');
    expect(inviterPublicName({ displayName: 'Ana', isIncognito: true })).toBe('');
    expect(inviterPublicName({ displayName: 'Ana', isBanned: true })).toBe('');
    expect(inviterPublicName({ displayName: 'Ana', isGhostMode: true })).toBe('');
    expect(inviterPublicName({ displayName: 'Ana', allowProfileSharing: false })).toBe('');
    expect(inviterPublicName({ displayName: 'Unknown' })).toBe('');
  });
});

describe('renderReferralHtml', () => {
  const html = renderReferralHtml(buildReferralPreview('ABC234', 'Ana', 'en'));

  test('Open Graph card names the inviter and the friend benefit', () => {
    expect(og(html, 'og:title')).toBe('Ana invited you to GreenGo');
    expect(og(html, 'og:description')).toContain('1 week of Base membership free');
    expect(og(html, 'og:image')).toBe(FALLBACK_IMAGE);
    expect(og(html, 'og:url')).toBe('https://greengo-chat.web.app/r/ABC234');
    expect(html).toContain('name="robots" content="noindex, nofollow"');
  });

  test('localized (pt_BR) with generic title when the name is hidden', () => {
    const pt = renderReferralHtml(buildReferralPreview('ABC234', '', 'pt_BR'));
    expect(pt).toContain('<html lang="pt-BR">');
    expect(og(pt, 'og:title')).toBe('Você foi convidado para o GreenGo');
    expect(og(pt, 'og:description')).toContain('1 semana de assinatura Base');
    expect(pt).toContain('Abrir no app');
    expect(pt).toContain('Baixar o app');
  });

  test('escapes the inviter name', () => {
    const x = renderReferralHtml(buildReferralPreview('ABC234', '<b>"x"</b>', 'en'));
    expect(x).not.toContain('<b>"x"</b>');
    expect(x).toContain('&lt;b&gt;&quot;x&quot;&lt;/b&gt;');
  });

  test('Android store link carries the code as Install Referrer; desktop goes to the web app', () => {
    expect(playStoreReferralUrl('ABC234')).toBe(
      'https://play.google.com/store/apps/details?id=com.greengochat.greengochatapp&referrer=ABC234');
    expect(html).toContain(JSON.stringify(playStoreReferralUrl('ABC234')));
    expect(referralWebAppUrl('ABC234')).toBe('https://greengo-chat.web.app/?link=%2Fr%2FABC234');
    expect(html).toContain('greengo://r/ABC234');
  });

  test('stores the code for a web sign-up under the app\'s shared_preferences keys', () => {
    expect(html).toContain('localStorage.setItem("flutter.pending_referral_code", JSON.stringify(code))');
    expect(html).toContain('localStorage.setItem("flutter.pending_referral_at", JSON.stringify(Date.now()))');
  });

  test('iOS does not auto-redirect (no deferred deep link): buttons only', () => {
    expect(html).toContain('if (isIOS) return;');
  });
});
