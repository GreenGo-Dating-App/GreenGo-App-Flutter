/**
 * Pure (I/O-free) half of the `sharePreview` function: turns a Firestore
 * document into the preview card data and renders the Open Graph HTML.
 * Kept free of firebase-admin / sharp / axios so it is unit-testable.
 *
 * Kinds:
 *   e = event      (/e/{eventId})
 *   c = community  (/c/{communityId})
 *   u = profile    (/u/{userId})
 *   x = experience (/x/{experienceId})   user_experiences/{id}
 *   a = attraction (/a/{attractionId})   attractions/{id} (curated catalogue)
 *
 * Every fixed string comes from the server i18n catalog (ARB-backed, see
 * shared/i18n): the card is rendered in the crawler's Accept-Language
 * ([pickLocale]), English otherwise.
 */

import { AppLocale, DEFAULT_LOCALE, SUPPORTED_LOCALES, t } from '../shared/i18n';
import type { ArbKey } from '../shared/i18n';
import { gt } from '../guest/guestI18n';

export const HOST = 'https://greengo-chat.web.app';
export const PLAY_URL =
  'https://play.google.com/store/apps/details?id=com.greengochat.greengochatapp';
// TODO: replace id123456789 with the real numeric App Store ID once assigned
// (same placeholder the old static fallback pages used).
export const APPSTORE_URL = 'https://apps.apple.com/app/greengo/id123456789';
/** Branded card used whenever a link has no (shareable) photo of its own. */
export const FALLBACK_IMAGE = `${HOST}/icons/Icon-512.png`;

export const OG_W = 1200;
export const OG_H = 630;

export type Kind = 'e' | 'c' | 'u' | 'x' | 'a';

const KINDS: readonly Kind[] = ['e', 'c', 'u', 'x', 'a'];

export interface Preview {
  kind: Kind;
  id: string;
  title: string;
  description: string;
  imageUrl: string | null;
  version: number;
  /** false = generic card (missing / private / hidden / not yet published). */
  shareable: boolean;
  /** Language the card's fixed strings are rendered in. */
  locale: AppLocale;
  /**
   * Shared-link guest landing (guest/): the page offers "Open in the GreenGo
   * app" OR "Continue as guest" instead of auto-redirecting. Set by
   * sharePreview.ts for guest-viewable events / experiences / attractions.
   */
  guestLanding?: boolean;
}

export const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

/** Brand name: never translated. */
export const BRAND = 'GreenGo';

export function genericPreview(kind: Kind, id: string, locale: AppLocale = DEFAULT_LOCALE): Preview {
  return {
    kind,
    id,
    title: BRAND,
    description: t(locale, 'sharePreviewGenericDescription'),
    imageUrl: null,
    version: 0,
    shareable: false,
    locale,
  };
}

// ---------------------------------------------------------------------------
// Locale
// ---------------------------------------------------------------------------

const SUPPORTED = new Set<string>(SUPPORTED_LOCALES);

/** One Accept-Language / ?hl= tag -> a supported app locale, or null. */
function matchLocale(tag: string): AppLocale | null {
  const v = tag.trim().replace(/-/g, '_');
  if (!v || v === '*') return null;
  const [lang, region] = v.split('_');
  const base = (lang || '').toLowerCase();
  if (base === 'pt' && (region || '').toUpperCase() === 'BR') return 'pt_BR';
  return SUPPORTED.has(base) ? (base as AppLocale) : null;
}

/**
 * The card language: an explicit `?hl=` wins, then the best-weighted
 * Accept-Language entry we support, else English (most link-preview crawlers
 * send no Accept-Language at all).
 */
export function pickLocale(acceptLanguage: unknown, hl?: unknown): AppLocale {
  if (typeof hl === 'string') {
    const m = matchLocale(hl);
    if (m) return m;
  }
  if (typeof acceptLanguage !== 'string' || !acceptLanguage.trim()) return DEFAULT_LOCALE;
  const entries = acceptLanguage
    .split(',')
    .map((part, i) => {
      const [tag, ...params] = part.trim().split(';');
      const qp = params.map((x) => x.trim()).find((x) => x.startsWith('q='));
      const q = qp ? Number(qp.slice(2)) : 1;
      return { tag: (tag ?? '').trim(), q: Number.isFinite(q) ? q : 0, i };
    })
    .filter((e) => e.tag && e.q > 0)
    .sort((a, b) => b.q - a.q || a.i - b.i);
  for (const e of entries) {
    const m = matchLocale(e.tag);
    if (m) return m;
  }
  return DEFAULT_LOCALE;
}

/** BCP-47 tag for Intl / <html lang>. */
export function bcp47(locale: AppLocale): string {
  return locale.replace('_', '-');
}

const OG_LOCALE: Record<AppLocale, string> = {
  en: 'en_US',
  de: 'de_DE',
  es: 'es_ES',
  fr: 'fr_FR',
  it: 'it_IT',
  pt: 'pt_PT',
  pt_BR: 'pt_BR',
};

export function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

export function clip(s: string, max: number): string {
  const t = s.replace(/\s+/g, ' ').trim();
  return t.length <= max ? t : `${t.slice(0, max - 1).trimEnd()}…`;
}

export function str(v: unknown): string {
  return typeof v === 'string' ? v.trim() : '';
}

/** Firestore Timestamp (or anything with toMillis()) -> epoch ms; else 0. */
export function millis(v: unknown): number {
  if (v && typeof (v as { toMillis?: unknown }).toMillis === 'function') {
    const n = (v as { toMillis: () => number }).toMillis();
    return typeof n === 'number' && Number.isFinite(n) ? n : 0;
  }
  return 0;
}

/**
 * Parse a Hosting path into (isImage, kind, id). Returns null for anything
 * that is not one of our link shapes or carries a malformed id.
 *   /e/{id}  /c/{id}  /u/{id}  /x/{id}  /a/{id}  /og/{kind}/{id}.jpg
 */
export function parseSharePath(
  path: string,
): { isImage: boolean; kind: Kind; id: string } | null {
  const parts = path.split('/').filter(Boolean);
  const isImage = parts[0] === 'og';
  const kind = isImage ? parts[1] : parts[0];
  const rawId = (isImage ? parts[2] : parts[1]) ?? '';
  let id: string;
  try {
    id = decodeURIComponent(isImage ? rawId.replace(/\.jpg$/i, '') : rawId);
  } catch {
    return null;
  }
  if (!(KINDS as readonly string[]).includes(kind ?? '')) return null;
  if (!ID_RE.test(id)) return null;
  return { isImage, kind: kind as Kind, id };
}

// ---------------------------------------------------------------------------
// Events & communities
// ---------------------------------------------------------------------------

/**
 * Content taken down (copyright notice, safety hold, moderation) must never
 * surface in a public card, whatever else its document says.
 */
export function isTakenDown(d: Record<string, unknown>): boolean {
  if (d.copyrightHold) return true;
  if (d.safetyHold) return true;
  if (d.isHidden === true || d.hidden === true) return true;
  // Hidden after the owner's plan dropped (entitlements/downgrade.ts).
  if (d.hiddenByDowngrade === true) return true;
  if (d.isDeleted === true || millis(d.deletedAt) > 0) return true;
  const status = str(d.status);
  return status === 'hidden' || status === 'removed' || status === 'deleted' || status === 'suspended';
}

function decodeSafe(s: string): string {
  try {
    return decodeURIComponent(s);
  } catch {
    return s;
  }
}

/**
 * Storage objects under a safety hold are MOVED to `safety_holds/...`; a URL
 * that points there (or any non-https URL) is never used.
 */
export function safeImageUrl(v: unknown): string | null {
  const u = str(v);
  if (!u.startsWith('https://')) return null;
  if (/safety_holds/i.test(decodeSafe(u))) return null;
  return u;
}

/** First sentence of [text] (or the whole text when it has no full stop). */
export function firstSentence(text: string): string {
  const flat = text.replace(/\s+/g, ' ').trim();
  const m = flat.match(/^(.+?[.!?。])(\s|$)/);
  return m ? m[1] : flat;
}

export function buildEventPreview(
  id: string,
  d: Record<string, unknown>,
  now: number = Date.now(),
  locale: AppLocale = DEFAULT_LOCALE,
): Preview {
  const generic = genericPreview('e', id, locale);
  const status = str(d.status);
  const publishAt = millis(d.publishAt);
  const notLiveYet =
    status === 'draft' || (status === 'scheduled' && publishAt > now);
  if (notLiveYet || isTakenDown(d)) return generic;

  const title = str(d.title) || t(locale, 'sharePreviewEventTitle');
  const place = str(d.locationName) || str(d.city);
  const going = typeof d.attendeeCount === 'number' ? d.attendeeCount : 0;
  const organizer = str(d.organizerName);
  const facts = [
    place ? `📍 ${place}` : '',
    organizer && organizer !== 'Current User'
      ? t(locale, 'sharePreviewByHost', { name: organizer })
      : '',
    going > 0 ? t(locale, 'sharePreviewGoing', { count: going }) : '',
  ].filter(Boolean);
  const body = str(d.description);
  const description = clip(
    [facts.join(' · '), body].filter(Boolean).join(' — '),
    200,
  );
  return {
    kind: 'e',
    id,
    title: clip(title, 90),
    description: description || generic.description,
    imageUrl: safeImageUrl(d.imageUrl),
    version: millis(d.updatedAt) || millis(d.createdAt),
    shareable: true,
    locale,
  };
}

/**
 * Communities: only PUBLIC ones get a real card. Private (isPublic false),
 * hidden / deleted / taken-down communities render the generic card.
 */
export function buildCommunityPreview(
  id: string,
  d: Record<string, unknown>,
  locale: AppLocale = DEFAULT_LOCALE,
): Preview {
  const generic = genericPreview('c', id, locale);
  if (d.isPublic === false || d.isPrivate === true || isTakenDown(d)) return generic;
  const name = str(d.name) || t(locale, 'sharePreviewCommunityTitle');
  const members = typeof d.memberCount === 'number' ? d.memberCount : 0;
  const place = [str(d.city), str(d.country)].filter(Boolean).join(', ');
  const facts = [
    members > 0 ? `👥 ${t(locale, 'sharePreviewMembers', { count: members })}` : '',
    place ? `📍 ${place}` : '',
  ].filter(Boolean);
  const description = clip(
    [facts.join(' · '), str(d.description)].filter(Boolean).join(' — '),
    200,
  );
  return {
    kind: 'c',
    id,
    title: clip(name, 90),
    description: description || generic.description,
    imageUrl: safeImageUrl(d.imageUrl),
    version: millis(d.lastActivityAt) || millis(d.createdAt),
    shareable: true,
    locale,
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
export function scrubContactInfo(text: string): string {
  return text
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '')
    .replace(/\b(?:https?:\/\/|www\.)\S+/gi, '')
    .replace(
      /\b[a-z0-9-]+\.(?:com|net|org|io|me|app|link|ly|br|it|de|fr|es|uk|co|info|biz|xyz|site|online|shop)(?:\/\S*)?\b/gi,
      '',
    )
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
export function isProfileShareable(
  d: Record<string, unknown>,
  now: number = Date.now(),
): boolean {
  if (d.isBanned === true) return false;
  const status = str(d.accountStatus) || 'active';
  if (status !== 'active') return false;
  if (d.isDeleted === true || millis(d.deletedAt) > 0) return false;
  if (d.isGhostMode === true) return false;
  if (d.isIncognito === true) {
    const until = millis(d.incognitoExpiry);
    // No expiry recorded = incognito until turned off.
    if (until === 0 || until > now) return false;
  }
  // Forward-compatible opt-out ("don't show my card when my link is shared").
  if (d.allowProfileSharing === false) return false;
  return true;
}

/** Coarse, privacy-safe place label: city only when the user allows it. */
function profilePlace(d: Record<string, unknown>): string {
  if (d.showOnMap === false) return '';
  const disc = str(d.globeDiscoverability) || 'approximate';
  if (disc === 'hidden') return '';
  const loc = (d.location ?? {}) as Record<string, unknown>;
  if (disc === 'country') return str(loc.country);
  return str(loc.city) || str(loc.country);
}

/** The MAIN photo: first public photo (the app's carousel/avatar order). */
export function mainProfilePhoto(d: Record<string, unknown>): string | null {
  const lists = [d.photoUrls, d.photos];
  for (const l of lists) {
    if (Array.isArray(l)) {
      const first = l.find((u) => typeof u === 'string' && u.trim().startsWith('https://'));
      if (typeof first === 'string') return first.trim();
    }
  }
  if (d.isBusiness === true) {
    const cover = str(d.coverImageUrl);
    if (cover.startsWith('https://')) return cover;
  }
  return null;
}

export function buildProfilePreview(
  id: string,
  d: Record<string, unknown>,
  now: number = Date.now(),
  locale: AppLocale = DEFAULT_LOCALE,
): Preview {
  const generic = genericPreview('u', id, locale);
  if (!isProfileShareable(d, now)) return generic;

  const isBusiness = d.isBusiness === true;
  const name =
    (isBusiness ? str(d.businessName) : '') || str(d.displayName) || '';
  if (!name || name === 'Unknown') return generic;

  const place = profilePlace(d);
  const title = clip(place ? `${name} · ${place}` : name, 90);

  const rawBio = (isBusiness ? str(d.storefrontBio) : '') || str(d.bio);
  const bio = clip(scrubContactInfo(rawBio), 180);
  const description = bio
    ? `${bio}`
    : t(locale, 'sharePreviewConnectWith', { name: clip(name, 40) });

  return {
    kind: 'u',
    id,
    title,
    description,
    imageUrl: mainProfilePhoto(d),
    version: millis(d.updatedAt) || millis(d.createdAt),
    shareable: true,
    locale,
  };
}

// ---------------------------------------------------------------------------
// Experiences (user_experiences/{id})
// ---------------------------------------------------------------------------

/** "€25" / "R$ 80,00" in the card language; '' for no usable price. */
export function formatPrice(amount: unknown, currency: unknown, locale: AppLocale): string {
  if (typeof amount !== 'number' || !Number.isFinite(amount) || amount <= 0) return '';
  const cur = str(currency).toUpperCase();
  const whole = Number.isInteger(amount);
  if (/^[A-Z]{3}$/.test(cur)) {
    try {
      return new Intl.NumberFormat(bcp47(locale), {
        style: 'currency',
        currency: cur,
        minimumFractionDigits: whole ? 0 : 2,
        maximumFractionDigits: whole ? 0 : 2,
      }).format(amount);
    } catch {
      // unknown currency code: fall through to the plain number
    }
  }
  const n = new Intl.NumberFormat(bcp47(locale), {
    maximumFractionDigits: whole ? 0 : 2,
  }).format(amount);
  return cur ? `${n} ${cur}` : n;
}

/** 90 -> "1 h 30 min" (units from the catalog); '' for none. */
export function formatDuration(minutes: unknown, locale: AppLocale): string {
  if (typeof minutes !== 'number' || !Number.isFinite(minutes) || minutes <= 0) return '';
  const total = Math.round(minutes);
  const h = Math.floor(total / 60);
  const m = total % 60;
  return [
    h > 0 ? t(locale, 'sharePreviewHours', { hours: h }) : '',
    m > 0 ? t(locale, 'sharePreviewMinutes', { minutes: m }) : '',
  ]
    .filter(Boolean)
    .join(' ');
}

/** The card photo: mainPhotoUrl, else the first gallery photo. */
export function mainExperiencePhoto(d: Record<string, unknown>): string | null {
  const main = safeImageUrl(d.mainPhotoUrl);
  if (main) return main;
  if (Array.isArray(d.photoUrls)) {
    for (const u of d.photoUrls) {
      const ok = safeImageUrl(u);
      if (ok) return ok;
    }
  }
  return null;
}

/**
 * Experience card: only PUBLISHED listings that are not taken down. Drafts,
 * hidden (reports / text moderation / banned host / admin) and
 * copyright-held listings render the generic card.
 *   title       = listing title
 *   description = "📍 city · price|Free · duration · by host — first sentence"
 */
export function buildExperiencePreview(
  id: string,
  d: Record<string, unknown>,
  locale: AppLocale = DEFAULT_LOCALE,
): Preview {
  const generic = genericPreview('x', id, locale);
  if (str(d.status) !== 'published' || isTakenDown(d)) return generic;

  const title = str(d.title) || t(locale, 'sharePreviewExperienceTitle');
  const place = str(d.city) || str(d.locationName);
  const price =
    d.isFree === true
      ? t(locale, 'attrFree')
      : formatPrice(d.price, d.currency, locale) ||
        formatPrice(d.groupPrice, d.currency, locale);
  const host = str(d.hostName);
  const facts = [
    place ? `📍 ${place}` : '',
    price,
    formatDuration(d.durationMinutes, locale),
    host ? t(locale, 'sharePreviewByHost', { name: clip(host, 40) }) : '',
  ].filter(Boolean);
  const body = firstSentence(scrubContactInfo(str(d.description)));
  const description = clip([facts.join(' · '), body].filter(Boolean).join(' — '), 200);
  return {
    kind: 'x',
    id,
    title: clip(title, 90),
    description: description || generic.description,
    imageUrl: mainExperiencePhoto(d),
    version: millis(d.updatedAt) || millis(d.createdAt),
    shareable: true,
    locale,
  };
}

// ---------------------------------------------------------------------------
// Attractions (curated catalogue, attractions/{id})
// ---------------------------------------------------------------------------

/** Default bucket the catalogue images live in (attraction_config/app). */
export const DEFAULT_ATTRACTION_BUCKET = 'greengo-chat.firebasestorage.app';

const CATEGORY_KEYS: Record<string, ArbKey> = {
  Religious: 'attrCatReligious',
  'Historic Site': 'attrCatHistoricSite',
  Museum: 'attrCatMuseum',
  Nature: 'attrCatNature',
  Neighborhood: 'attrCatNeighborhood',
  Beach: 'attrCatBeach',
  Garden: 'attrCatGarden',
  Monument: 'attrCatMonument',
  Square: 'attrCatSquare',
  Street: 'attrCatStreet',
  Architecture: 'attrCatArchitecture',
  'Observation Deck': 'attrCatObservationDeck',
  Castle: 'attrCatCastle',
  Market: 'attrCatMarket',
  Mountain: 'attrCatMountain',
  Palace: 'attrCatPalace',
  Island: 'attrCatIsland',
  Lake: 'attrCatLake',
  'National Park': 'attrCatNationalPark',
  Bridge: 'attrCatBridge',
  'Theme Park': 'attrCatThemePark',
  Waterfall: 'attrCatWaterfall',
  Zoo: 'attrCatZoo',
  Shopping: 'attrCatShopping',
  Aquarium: 'attrCatAquarium',
  Other: 'attrCatOther',
};

/** Same mapping as the app's CategoryLabels: known -> translated, else raw. */
export function categoryLabel(raw: unknown, locale: AppLocale): string {
  const c = str(raw);
  if (!c) return '';
  const key = CATEGORY_KEYS[c];
  return key ? t(locale, key) : c;
}

/** Licences we may not crop/resize (ND) or use in a promotional card (NC). */
const RESTRICTIVE_LICENSE =
  /(\bnd\b|noderiv|no-deriv|\bnc\b|noncommercial|non-commercial|all rights reserved|fair use)/i;

/**
 * May the attraction's photo be used in a link card, and with which credit?
 *  - AI-generated / no attribution record: yes, no credit.
 *  - ND / NC / "all rights reserved" / fair-use licences: NO (brand image).
 *  - Attribution required (CC BY / BY-SA...): yes, with "author, licence" in
 *    the card text; if the record lacks both author and licence: NO.
 */
export function attractionPhotoPolicy(d: Record<string, unknown>): { use: boolean; credit: string | null } {
  const img = (d.img ?? {}) as Record<string, unknown>;
  if (str(img.source) === 'ai') return { use: true, credit: null };
  const at = d.attribution;
  if (!at || typeof at !== 'object') return { use: true, credit: null };
  const a = at as Record<string, unknown>;
  const author = str(a.author);
  const license = str(a.license);
  if (RESTRICTIVE_LICENSE.test(license)) return { use: false, credit: null };
  const credit = [author, license].filter(Boolean).join(', ');
  if (a.required === true) return credit ? { use: true, credit } : { use: false, credit: null };
  return { use: true, credit: author ? credit : null };
}

/** Firebase Storage URL of the attraction's `hero` variant (as the app builds it). */
export function attractionImageUrl(d: Record<string, unknown>, bucket: string): string | null {
  const img = (d.img ?? {}) as Record<string, unknown>;
  const base = str(img.base);
  const hash = str(img.hash);
  const token = str(img.token);
  if (!base || !hash || !token || !/^[a-z0-9.-]+$/i.test(bucket)) return null;
  const path = encodeURIComponent(`${base}/hero-${hash}.webp`);
  return safeImageUrl(
    `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${path}?alt=media&token=${encodeURIComponent(token)}`,
  );
}

/**
 * Attraction card: only PUBLISHED catalogue entries.
 *   title       = name
 *   description = "📍 city, country · category — short description"
 *                 (+ " · Photo: author, licence" when the licence needs it)
 */
export function buildAttractionPreview(
  id: string,
  d: Record<string, unknown>,
  bucket: string = DEFAULT_ATTRACTION_BUCKET,
  locale: AppLocale = DEFAULT_LOCALE,
): Preview {
  const generic = genericPreview('a', id, locale);
  if (str(d.status) !== 'published' || isTakenDown(d)) return generic;

  const title = str(d.name) || t(locale, 'sharePreviewAttractionTitle');
  const place = [str(d.cityName), str(d.countryName)].filter(Boolean).join(', ');
  const facts = [place ? `📍 ${place}` : '', categoryLabel(d.category, locale)].filter(Boolean);
  const body = str(d.descriptionShort) || firstSentence(str(d.descriptionMedium));
  const policy = attractionPhotoPolicy(d);
  const imageUrl = policy.use ? attractionImageUrl(d, bucket) : null;
  const credit =
    imageUrl && policy.credit ? t(locale, 'sharePreviewPhotoCredit', { credit: clip(policy.credit, 60) }) : '';
  const main = clip(
    [facts.join(' · '), body].filter(Boolean).join(' — '),
    credit ? Math.max(80, 200 - credit.length - 3) : 200,
  );
  const description = [main, credit].filter(Boolean).join(' · ');
  return {
    kind: 'a',
    id,
    title: clip(title, 90),
    description: description || generic.description,
    imageUrl,
    version: millis(d.updatedAt) || millis(d.createdAt),
    shareable: true,
    locale,
  };
}

// ---------------------------------------------------------------------------
// HTML
// ---------------------------------------------------------------------------

/** Path the web app understands (see DeepLinkService.captureWebLaunchLink). */
export function webAppUrl(kind: Kind, id: string, chat = false): string {
  return `${HOST}/?link=${encodeURIComponent(`/${kind}/${id}${chat ? '?chat=1' : ''}`)}`;
}

export function ogImageUrl(p: Preview): string {
  return p.shareable && p.imageUrl
    ? `${HOST}/og/${p.kind}/${encodeURIComponent(p.id)}.jpg?v=${p.version}`
    : FALLBACK_IMAGE;
}

/**
 * [chat]: the link asked to open the buyer <-> organizer chat (`?chat=1`,
 * ticket / booking e-mails); kept on the app and web hand-offs.
 */
export function renderHtml(p: Preview, chat = false): string {
  const url = `${HOST}/${p.kind}/${encodeURIComponent(p.id)}`;
  const hasOwnImage = p.shareable && !!p.imageUrl;
  const image = ogImageUrl(p);
  const title = escapeHtml(p.title);
  const desc = escapeHtml(p.description);
  const img = escapeHtml(image);
  const u = escapeHtml(url);
  const withChat = chat && (p.kind === 'e' || p.kind === 'x');
  const appUrl = `greengo://${p.kind}/${encodeURIComponent(p.id)}${withChat ? '?chat=1' : ''}`;
  const web = webAppUrl(p.kind, p.id, withChat);
  const lang = escapeHtml(bcp47(p.locale));
  const ogLocale = OG_LOCALE[p.locale];
  const openApp = escapeHtml(t(p.locale, 'sharePreviewOpenApp'));
  const openWeb = escapeHtml(t(p.locale, 'sharePreviewOpenWeb'));
  // Profiles are people: keep them out of search engines (link-preview
  // crawlers ignore robots meta, so cards still render).
  const robots =
    p.kind === 'u' ? '\n  <meta name="robots" content="noindex, nofollow" />' : '';
  const imageTags = hasOwnImage
    ? `
  <meta property="og:image:width" content="${OG_W}" />
  <meta property="og:image:height" content="${OG_H}" />
  <meta property="og:image:type" content="image/jpeg" />
  <meta name="twitter:card" content="summary_large_image" />`
    : `
  <meta name="twitter:card" content="summary" />`;
  const ogType = p.kind === 'u' && p.shareable ? 'profile' : 'website';
  // Guest landing: two explicit choices, no automatic redirect (a visitor
  // without the app must be able to pick "Continue as guest").
  const guest = p.guestLanding === true && p.shareable && (p.kind === 'e' || p.kind === 'x' || p.kind === 'a');
  const guestUrl = `${HOST}/guest/${p.kind}/${encodeURIComponent(p.id)}?hl=${encodeURIComponent(p.locale)}`;
  const actions = guest
    ? `<a class="btn" id="store" href="${PLAY_URL}">${escapeHtml(gt(p.locale, 'guest.landing.openApp'))}</a>
  <a class="btn guest" id="guest" href="${escapeHtml(guestUrl)}">${escapeHtml(gt(p.locale, 'guest.landing.continueGuest'))}</a>
  <p class="hint">${escapeHtml(gt(p.locale, 'guest.landing.guestHint'))}</p>`
    : `<a class="btn" id="store" href="${PLAY_URL}">${openApp}</a>
  <a class="web" id="web" href="${escapeHtml(web)}">${openWeb}</a>`;

  return `<!DOCTYPE html>
<html lang="${lang}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${title}</title>
  <meta name="description" content="${desc}" />${robots}
  <link rel="canonical" href="${u}" />
  <meta property="og:site_name" content="${BRAND}" />
  <meta property="og:type" content="${ogType}" />
  <meta property="og:locale" content="${ogLocale}" />
  <meta property="og:url" content="${u}" />
  <meta property="og:title" content="${title}" />
  <meta property="og:description" content="${desc}" />
  <meta property="og:image" content="${img}" />
  <meta property="og:image:secure_url" content="${img}" />
  <meta property="og:image:alt" content="${title}" />${imageTags}
  <meta name="twitter:title" content="${title}" />
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
    a.btn.guest { margin-top: 12px; background: transparent; color: #D4AF37; border: 1px solid #D4AF37; }
    p.hint { margin-top: 12px; font-size: 13px; color: #8A8A8A; }
  </style>
</head>
<body>
  ${hasOwnImage ? `<img src="${img}" alt="" />` : ''}
  <h1>${title}</h1>
  <p>${desc}</p>
  ${actions}
  <script>
    // If the app is installed, App Links / Universal Links opened it before
    // this page loaded. Otherwise try the custom scheme once, then go to the
    // right store. Desktop browsers go straight to the web app, which opens
    // the shared item after sign-in.
    (function () {
      var ua = navigator.userAgent || navigator.vendor || "";
      var isIOS = /iPad|iPhone|iPod/.test(ua) && !window.MSStream;
      var isAndroid = /android/i.test(ua);
      var storeUrl = isIOS ? ${JSON.stringify(APPSTORE_URL)} : ${JSON.stringify(PLAY_URL)};
      var webUrl = ${JSON.stringify(web)};
      var store = document.getElementById("store");
      store.href = storeUrl;
      function openApp() {
        if (!isAndroid && !isIOS) { window.location.replace(webUrl); return; }
        var left = false;
        document.addEventListener("visibilitychange", function () {
          if (document.hidden) left = true;
        });
        setTimeout(function () { if (!left) window.location.href = storeUrl; }, 1500);
        window.location.href = ${JSON.stringify(appUrl)};
      }
      // Guest landing: wait for the visitor's choice. Otherwise as before.
      if (${guest ? 'true' : 'false'}) {
        store.addEventListener("click", function (ev) { ev.preventDefault(); openApp(); });
        return;
      }
      openApp();
    })();
  </script>
</body>
</html>`;
}
