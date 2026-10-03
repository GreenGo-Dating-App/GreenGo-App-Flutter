"use strict";
/**
 * Pure (I/O-free) half of the `sharePreview` function: turns a Firestore
 * document into the preview card data and renders the Open Graph HTML.
 * Kept free of firebase-admin / sharp / axios so it is unit-testable.
 *
 * Kinds:
 *   e = event      (/e/{eventId})
 *   c = community  (/c/{communityId})
 *   u = profile    (/u/{userId})
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.GENERIC_DESCRIPTION = exports.ID_RE = exports.OG_H = exports.OG_W = exports.FALLBACK_IMAGE = exports.APPSTORE_URL = exports.PLAY_URL = exports.HOST = void 0;
exports.genericPreview = genericPreview;
exports.escapeHtml = escapeHtml;
exports.clip = clip;
exports.str = str;
exports.millis = millis;
exports.parseSharePath = parseSharePath;
exports.buildEventPreview = buildEventPreview;
exports.buildCommunityPreview = buildCommunityPreview;
exports.scrubContactInfo = scrubContactInfo;
exports.isProfileShareable = isProfileShareable;
exports.mainProfilePhoto = mainProfilePhoto;
exports.buildProfilePreview = buildProfilePreview;
exports.webAppUrl = webAppUrl;
exports.ogImageUrl = ogImageUrl;
exports.renderHtml = renderHtml;
exports.HOST = 'https://greengo-chat.web.app';
exports.PLAY_URL = 'https://play.google.com/store/apps/details?id=com.greengochat.greengochatapp';
// TODO: replace id123456789 with the real numeric App Store ID once assigned
// (same placeholder the old static fallback pages used).
exports.APPSTORE_URL = 'https://apps.apple.com/app/greengo/id123456789';
/** Branded card used whenever a link has no (shareable) photo of its own. */
exports.FALLBACK_IMAGE = `${exports.HOST}/icons/Icon-512.png`;
exports.OG_W = 1200;
exports.OG_H = 630;
exports.ID_RE = /^[A-Za-z0-9_-]{1,128}$/;
exports.GENERIC_DESCRIPTION = 'Discover people, cultures, events and communities around the world.';
function genericPreview(kind, id) {
    return {
        kind,
        id,
        title: 'GreenGo',
        description: exports.GENERIC_DESCRIPTION,
        imageUrl: null,
        version: 0,
        shareable: false,
    };
}
function escapeHtml(s) {
    return s
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}
function clip(s, max) {
    const t = s.replace(/\s+/g, ' ').trim();
    return t.length <= max ? t : `${t.slice(0, max - 1).trimEnd()}…`;
}
function str(v) {
    return typeof v === 'string' ? v.trim() : '';
}
/** Firestore Timestamp (or anything with toMillis()) -> epoch ms; else 0. */
function millis(v) {
    if (v && typeof v.toMillis === 'function') {
        const n = v.toMillis();
        return typeof n === 'number' && Number.isFinite(n) ? n : 0;
    }
    return 0;
}
/**
 * Parse a Hosting path into (isImage, kind, id). Returns null for anything
 * that is not one of our link shapes or carries a malformed id.
 *   /e/{id}  /c/{id}  /u/{id}  /og/{kind}/{id}.jpg
 */
function parseSharePath(path) {
    var _a;
    const parts = path.split('/').filter(Boolean);
    const isImage = parts[0] === 'og';
    const kind = isImage ? parts[1] : parts[0];
    const rawId = (_a = (isImage ? parts[2] : parts[1])) !== null && _a !== void 0 ? _a : '';
    let id;
    try {
        id = decodeURIComponent(isImage ? rawId.replace(/\.jpg$/i, '') : rawId);
    }
    catch (_b) {
        return null;
    }
    if (kind !== 'e' && kind !== 'c' && kind !== 'u')
        return null;
    if (!exports.ID_RE.test(id))
        return null;
    return { isImage, kind, id };
}
// ---------------------------------------------------------------------------
// Events & communities
// ---------------------------------------------------------------------------
function buildEventPreview(id, d, now = Date.now()) {
    const generic = genericPreview('e', id);
    const status = str(d.status);
    const publishAt = millis(d.publishAt);
    const notLiveYet = status === 'draft' || (status === 'scheduled' && publishAt > now);
    if (notLiveYet)
        return generic;
    const title = str(d.title) || 'GreenGo event';
    const place = str(d.locationName) || str(d.city);
    const going = typeof d.attendeeCount === 'number' ? d.attendeeCount : 0;
    const organizer = str(d.organizerName);
    const facts = [
        place ? `📍 ${place}` : '',
        organizer && organizer !== 'Current User' ? `by ${organizer}` : '',
        going > 0 ? `${going} going` : '',
    ].filter(Boolean);
    const body = str(d.description);
    const description = clip([facts.join(' · '), body].filter(Boolean).join(' — '), 200);
    return {
        kind: 'e',
        id,
        title: clip(title, 90),
        description: description || generic.description,
        imageUrl: str(d.imageUrl) || null,
        version: millis(d.updatedAt) || millis(d.createdAt),
        shareable: true,
    };
}
function buildCommunityPreview(id, d) {
    const generic = genericPreview('c', id);
    if (d.isPublic === false)
        return generic;
    const name = str(d.name) || 'GreenGo community';
    const members = typeof d.memberCount === 'number' ? d.memberCount : 0;
    const place = [str(d.city), str(d.country)].filter(Boolean).join(', ');
    const facts = [
        members > 0 ? `👥 ${members} ${members === 1 ? 'member' : 'members'}` : '',
        place ? `📍 ${place}` : '',
    ].filter(Boolean);
    const description = clip([facts.join(' · '), str(d.description)].filter(Boolean).join(' — '), 200);
    return {
        kind: 'c',
        id,
        title: clip(name, 90),
        description: description || generic.description,
        imageUrl: str(d.imageUrl) || null,
        version: millis(d.lastActivityAt) || millis(d.createdAt),
        shareable: true,
    };
}
// ---------------------------------------------------------------------------
// Profiles
// ---------------------------------------------------------------------------
/**
 * Strip contact details out of free text before it goes into a PUBLIC preview
 * card: e-mail addresses, URLs / domains, @handles and phone-number-like runs
 * of digits. The bio is shown in-app to signed-in users only; the link card is
 * visible to anyone the link is forwarded to.
 */
function scrubContactInfo(text) {
    return text
        .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '')
        .replace(/\b(?:https?:\/\/|www\.)\S+/gi, '')
        .replace(/\b[a-z0-9-]+\.(?:com|net|org|io|me|app|link|ly|br|it|de|fr|es|uk|co|info|biz|xyz|site|online|shop)(?:\/\S*)?\b/gi, '')
        .replace(/(^|[\s(])@[A-Za-z0-9_.]{2,}/g, '$1')
        // 7+ digits, optionally separated by spaces, dots, dashes, parentheses,
        // optionally with a leading +  (phone numbers, WhatsApp numbers…)
        .replace(/\+?\d(?:[\s().-]*\d){6,}/g, '')
        .replace(/\s+([,.;:!?])/g, '$1')
        .replace(/\s{2,}/g, ' ')
        .trim();
}
/**
 * Should this profile's real name / photo / bio appear in a public link card?
 * Every "do not surface me" state the app knows about yields false:
 * missing/deleted, banned, suspended/restricted/any non-active status,
 * incognito (while not expired), ghost mode, and an explicit sharing opt-out.
 */
function isProfileShareable(d, now = Date.now()) {
    if (d.isBanned === true)
        return false;
    const status = str(d.accountStatus) || 'active';
    if (status !== 'active')
        return false;
    if (d.isDeleted === true || millis(d.deletedAt) > 0)
        return false;
    if (d.isGhostMode === true)
        return false;
    if (d.isIncognito === true) {
        const until = millis(d.incognitoExpiry);
        // No expiry recorded = incognito until turned off.
        if (until === 0 || until > now)
            return false;
    }
    // Forward-compatible opt-out ("don't show my card when my link is shared").
    if (d.allowProfileSharing === false)
        return false;
    return true;
}
/** Coarse, privacy-safe place label: city only when the user allows it. */
function profilePlace(d) {
    var _a;
    if (d.showOnMap === false)
        return '';
    const disc = str(d.globeDiscoverability) || 'approximate';
    if (disc === 'hidden')
        return '';
    const loc = ((_a = d.location) !== null && _a !== void 0 ? _a : {});
    if (disc === 'country')
        return str(loc.country);
    return str(loc.city) || str(loc.country);
}
/** The MAIN photo: first public photo (the app's carousel/avatar order). */
function mainProfilePhoto(d) {
    const lists = [d.photoUrls, d.photos];
    for (const l of lists) {
        if (Array.isArray(l)) {
            const first = l.find((u) => typeof u === 'string' && u.trim().startsWith('https://'));
            if (typeof first === 'string')
                return first.trim();
        }
    }
    if (d.isBusiness === true) {
        const cover = str(d.coverImageUrl);
        if (cover.startsWith('https://'))
            return cover;
    }
    return null;
}
function buildProfilePreview(id, d, now = Date.now()) {
    const generic = genericPreview('u', id);
    if (!isProfileShareable(d, now))
        return generic;
    const isBusiness = d.isBusiness === true;
    const name = (isBusiness ? str(d.businessName) : '') || str(d.displayName) || '';
    if (!name || name === 'Unknown')
        return generic;
    const place = profilePlace(d);
    const title = clip(place ? `${name} · ${place}` : name, 90);
    const rawBio = (isBusiness ? str(d.storefrontBio) : '') || str(d.bio);
    const bio = clip(scrubContactInfo(rawBio), 180);
    const description = bio
        ? `${bio}`
        : `Connect with ${clip(name, 40)} on GreenGo — meet people and cultures from around the world.`;
    return {
        kind: 'u',
        id,
        title,
        description,
        imageUrl: mainProfilePhoto(d),
        version: millis(d.updatedAt) || millis(d.createdAt),
        shareable: true,
    };
}
// ---------------------------------------------------------------------------
// HTML
// ---------------------------------------------------------------------------
/** Path the web app understands (see DeepLinkService.captureWebLaunchLink). */
function webAppUrl(kind, id) {
    return `${exports.HOST}/?link=${encodeURIComponent(`/${kind}/${id}`)}`;
}
function ogImageUrl(p) {
    return p.shareable && p.imageUrl
        ? `${exports.HOST}/og/${p.kind}/${encodeURIComponent(p.id)}.jpg?v=${p.version}`
        : exports.FALLBACK_IMAGE;
}
function renderHtml(p) {
    const url = `${exports.HOST}/${p.kind}/${encodeURIComponent(p.id)}`;
    const hasOwnImage = p.shareable && !!p.imageUrl;
    const image = ogImageUrl(p);
    const t = escapeHtml(p.title);
    const desc = escapeHtml(p.description);
    const img = escapeHtml(image);
    const u = escapeHtml(url);
    const appUrl = `greengo://${p.kind}/${encodeURIComponent(p.id)}`;
    const web = webAppUrl(p.kind, p.id);
    const what = p.kind === 'e' ? 'event' : p.kind === 'c' ? 'community' : 'profile';
    // Profiles are people: keep them out of search engines (link-preview
    // crawlers ignore robots meta, so cards still render).
    const robots = p.kind === 'u' ? '\n  <meta name="robots" content="noindex, nofollow" />' : '';
    const imageTags = hasOwnImage
        ? `
  <meta property="og:image:width" content="${exports.OG_W}" />
  <meta property="og:image:height" content="${exports.OG_H}" />
  <meta property="og:image:type" content="image/jpeg" />
  <meta name="twitter:card" content="summary_large_image" />`
        : `
  <meta name="twitter:card" content="summary" />`;
    const ogType = p.kind === 'u' && p.shareable ? 'profile' : 'website';
    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${t}</title>
  <meta name="description" content="${desc}" />${robots}
  <link rel="canonical" href="${u}" />
  <meta property="og:site_name" content="GreenGo" />
  <meta property="og:type" content="${ogType}" />
  <meta property="og:url" content="${u}" />
  <meta property="og:title" content="${t}" />
  <meta property="og:description" content="${desc}" />
  <meta property="og:image" content="${img}" />
  <meta property="og:image:secure_url" content="${img}" />
  <meta property="og:image:alt" content="${t}" />${imageTags}
  <meta name="twitter:title" content="${t}" />
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
    img { width: 100%; max-width: 420px; border-radius: 16px; object-fit: cover; aspect-ratio: 1200 / 630; }
    h1 { color: #D4AF37; font-size: 22px; margin: 20px 0 8px; max-width: 420px; }
    p { color: #B0B0B0; font-size: 15px; max-width: 420px; line-height: 1.5; margin: 0; }
    a.btn {
      margin-top: 24px; padding: 14px 28px; border-radius: 30px;
      background: #D4AF37; color: #0A0A0A; font-weight: 700; text-decoration: none;
    }
    a.web { margin-top: 16px; color: #D4AF37; font-size: 14px; }
  </style>
</head>
<body>
  ${hasOwnImage ? `<img src="${img}" alt="" />` : ''}
  <h1>${t}</h1>
  <p>${desc}</p>
  <a class="btn" id="store" href="${exports.PLAY_URL}">Open in GreenGo</a>
  <a class="web" id="web" href="${escapeHtml(web)}">Open on the web</a>
  <script>
    // If the app is installed, App Links / Universal Links opened it before
    // this page loaded. Otherwise try the custom scheme once, then go to the
    // right store for this ${what}. Desktop browsers go straight to the web
    // app, which opens this ${what} after sign-in.
    (function () {
      var ua = navigator.userAgent || navigator.vendor || "";
      var isIOS = /iPad|iPhone|iPod/.test(ua) && !window.MSStream;
      var isAndroid = /android/i.test(ua);
      var storeUrl = isIOS ? ${JSON.stringify(exports.APPSTORE_URL)} : ${JSON.stringify(exports.PLAY_URL)};
      var webUrl = ${JSON.stringify(web)};
      document.getElementById("store").href = storeUrl;
      if (!isAndroid && !isIOS) { window.location.replace(webUrl); return; }
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
//# sourceMappingURL=sharePreviewCore.js.map