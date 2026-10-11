/**
 * Invite links (/r/{CODE}): pure (I/O-free) half of the preview page served by
 * `sharePreview`. Kept separate from sharePreviewCore.ts so the /r/ route is an
 * isolated addition.
 *
 * The page:
 *  - carries Open Graph tags ("{name} invited you to GreenGo" + the friend's
 *    benefit, 1 week of Base membership) in the viewer's language
 *    (Accept-Language), with the GreenGo brand image;
 *  - stores the code for a web sign-up on this origin (the Flutter web app's
 *    SharedPreferences keys, see PendingReferralStore);
 *  - Android: tries the app, then the Play Store with `&referrer=CODE` so the
 *    code survives a fresh install (Install Referrer);
 *  - iOS: no deferred deep link - if the app is installed the Universal Link
 *    already opened it; otherwise "Open in the app" / "Get the app" buttons;
 *  - desktop: continues to the web app (`/?link=/r/CODE`).
 *
 * Privacy: only the inviter's PUBLIC display name is shown, and only when
 * their profile is shareable (isProfileShareable); never photo, bio, place,
 * age or ids.
 */
import { AppLocale, normalizeLocale, t } from '../shared/i18n';
import {
  APPSTORE_URL,
  FALLBACK_IMAGE,
  HOST,
  PLAY_URL,
  clip,
  escapeHtml,
  isProfileShareable,
  str,
} from './sharePreviewCore';

/** Codes are generated from an unambiguous charset (see ReferralService). */
export const REFERRAL_CODE_RE = /^[A-Z0-9]{4,16}$/;

/** `/r/{CODE}` -> normalized code (upper case), else null. */
export function parseReferralPath(path: string): string | null {
  const parts = path.split('/').filter(Boolean);
  if (parts.length !== 2 || parts[0] !== 'r') return null;
  let code: string;
  try {
    code = decodeURIComponent(parts[1]).trim().toUpperCase();
  } catch {
    return null;
  }
  return REFERRAL_CODE_RE.test(code) ? code : null;
}

/** First supported language of an Accept-Language header (q-ordered). */
export function localeFromAcceptLanguage(header: unknown): AppLocale {
  if (typeof header !== 'string' || !header.trim()) return 'en';
  const ranked = header
    .split(',')
    .map((part, i) => {
      const [tag, ...params] = part.trim().split(';');
      const q = params.map((p) => p.trim()).find((p) => p.startsWith('q='));
      const weight = q ? Number(q.slice(2)) : 1;
      return { tag: tag.trim(), weight: Number.isFinite(weight) ? weight : 0, i };
    })
    .filter((x) => x.tag && x.tag !== '*' && x.weight > 0)
    .sort((a, b) => b.weight - a.weight || a.i - b.i);
  for (const r of ranked) {
    const lang = r.tag.split(/[-_]/)[0].toLowerCase();
    if (['en', 'de', 'es', 'fr', 'it', 'pt'].includes(lang)) return normalizeLocale(r.tag);
  }
  return 'en';
}

/** Public display name of the inviter, or '' when it must not be shown. */
export function inviterPublicName(profile: Record<string, unknown> | null | undefined): string {
  if (!profile || !isProfileShareable(profile)) return '';
  const name = (profile.isBusiness === true ? str(profile.businessName) : '') || str(profile.displayName);
  if (!name || name === 'Unknown') return '';
  return clip(name, 40);
}

export interface ReferralPreview {
  code: string;
  locale: AppLocale;
  title: string;
  description: string;
}

export function buildReferralPreview(code: string, inviterName: string, locale: AppLocale): ReferralPreview {
  return {
    code,
    locale,
    title: inviterName
      ? t(locale, 'srvReferralPreviewTitleNamed', { name: inviterName })
      : t(locale, 'srvReferralPreviewTitle'),
    description: t(locale, 'srvReferralPreviewBody'),
  };
}

/** Play Store URL that hands the code to the app through the Install Referrer. */
export function playStoreReferralUrl(code: string): string {
  return `${PLAY_URL}&referrer=${encodeURIComponent(code)}`;
}

export function referralWebAppUrl(code: string): string {
  return `${HOST}/?link=${encodeURIComponent(`/r/${code}`)}`;
}

const HTML_LANG: Record<AppLocale, string> = {
  en: 'en', de: 'de', es: 'es', fr: 'fr', it: 'it', pt: 'pt', pt_BR: 'pt-BR',
};

export function renderReferralHtml(p: ReferralPreview): string {
  const url = `${HOST}/r/${encodeURIComponent(p.code)}`;
  const tt = escapeHtml(p.title);
  const desc = escapeHtml(p.description);
  const img = escapeHtml(FALLBACK_IMAGE);
  const u = escapeHtml(url);
  const appUrl = `greengo://r/${encodeURIComponent(p.code)}`;
  const play = playStoreReferralUrl(p.code);
  const web = referralWebAppUrl(p.code);
  const openApp = escapeHtml(t(p.locale, 'srvReferralPreviewOpenApp'));
  const getApp = escapeHtml(t(p.locale, 'srvReferralPreviewGetApp'));
  const onWeb = escapeHtml(t(p.locale, 'srvReferralPreviewWeb'));

  return `<!DOCTYPE html>
<html lang="${HTML_LANG[p.locale]}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${tt}</title>
  <meta name="description" content="${desc}" />
  <meta name="robots" content="noindex, nofollow" />
  <link rel="canonical" href="${u}" />
  <meta property="og:site_name" content="GreenGo" />
  <meta property="og:type" content="website" />
  <meta property="og:url" content="${u}" />
  <meta property="og:title" content="${tt}" />
  <meta property="og:description" content="${desc}" />
  <meta property="og:image" content="${img}" />
  <meta property="og:image:secure_url" content="${img}" />
  <meta property="og:image:alt" content="GreenGo" />
  <meta name="twitter:card" content="summary" />
  <meta name="twitter:title" content="${tt}" />
  <meta name="twitter:description" content="${desc}" />
  <meta name="twitter:image" content="${img}" />
  <style>
    html, body { min-height: 100%; margin: 0; }
    body {
      background: #0A0A0A; color: #FFFFFF;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex; flex-direction: column; align-items: center; justify-content: center;
      text-align: center; padding: 24px; box-sizing: border-box;
    }
    img { width: 96px; height: 96px; border-radius: 22px; }
    h1 { color: #D4AF37; font-size: 22px; margin: 20px 0 8px; max-width: 420px; }
    p { color: #B0B0B0; font-size: 15px; max-width: 420px; line-height: 1.5; margin: 0; }
    a.btn {
      margin-top: 24px; padding: 14px 28px; border-radius: 30px; min-width: 220px; box-sizing: border-box;
      background: #D4AF37; color: #0A0A0A; font-weight: 700; text-decoration: none;
    }
    a.btn.alt { margin-top: 12px; background: transparent; color: #D4AF37; border: 1px solid #D4AF37; }
    a.web { margin-top: 16px; color: #D4AF37; font-size: 14px; }
  </style>
</head>
<body>
  <img src="${img}" alt="GreenGo" />
  <h1>${tt}</h1>
  <p>${desc}</p>
  <a class="btn" id="open" href="${escapeHtml(appUrl)}">${openApp}</a>
  <a class="btn alt" id="store" href="${escapeHtml(play)}">${getApp}</a>
  <a class="web" id="web" href="${escapeHtml(web)}">${onWeb}</a>
  <script>
    (function () {
      var code = ${JSON.stringify(p.code)};
      // Same keys the Flutter web app's PendingReferralStore reads
      // (shared_preferences on web = localStorage, "flutter." prefix, JSON values).
      try {
        localStorage.setItem("flutter.pending_referral_code", JSON.stringify(code));
        localStorage.setItem("flutter.pending_referral_at", JSON.stringify(Date.now()));
      } catch (e) {}
      var ua = navigator.userAgent || navigator.vendor || "";
      var isIOS = /iPad|iPhone|iPod/.test(ua) && !window.MSStream;
      var isAndroid = /android/i.test(ua);
      var storeUrl = isIOS ? ${JSON.stringify(APPSTORE_URL)} : ${JSON.stringify(play)};
      document.getElementById("store").href = storeUrl;
      if (!isAndroid && !isIOS) { window.location.replace(${JSON.stringify(web)}); return; }
      // iOS: no deferred deep link; a Universal Link already opened an
      // installed app, so just offer the two buttons.
      if (isIOS) return;
      var left = false;
      document.addEventListener("visibilitychange", function () {
        if (document.hidden) left = true;
      });
      setTimeout(function () { if (!left) window.location.href = storeUrl; }, 1500);
      window.location.href = ${JSON.stringify(appUrl)};
    })();
  </script>
</body>
</html>`;
}
