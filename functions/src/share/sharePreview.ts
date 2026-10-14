/**
 * Link previews for shared GreenGo EVENTS, COMMUNITIES, PROFILES,
 * EXPERIENCES and catalogue ATTRACTIONS.
 *
 * WhatsApp, Telegram, Instagram (DMs), iMessage, Slack… build their preview
 * card from the page's Open Graph tags, and their crawlers never run
 * JavaScript. So the shareable links must be rendered on the server:
 *
 *   /e/{eventId}           -> HTML with og:title/description/image for the event
 *   /c/{communityId}       -> same for a community
 *   /u/{userId}            -> same for a user profile (main photo, name, city)
 *   /x/{experienceId}      -> same for a published experience (user_experiences)
 *   /a/{attractionId}      -> same for a catalogue attraction (attractions)
 *   /og/e/{eventId}.jpg    -> 1200x630 JPEG preview image (the og:image)
 *   /og/c/{communityId}.jpg
 *   /og/u/{userId}.jpg     -> the profile's MAIN photo, fitted on 1200x630
 *   /og/x/{experienceId}.jpg, /og/a/{attractionId}.jpg
 *
 * Firebase Hosting rewrites these paths here (firebase.json). Every response
 * is CDN-cacheable, so a link that goes viral costs ~one Firestore read and
 * one resize per cache window, not one per viewer.
 *
 * People (not crawlers) who open the link get the same page: if the app is
 * installed the OS already opened it via App Links / Universal Links; otherwise
 * the page tries `greengo://` once and then sends them to the right store.
 * Desktop browsers are sent to the web app (`/?link=/u/{id}`), which opens the
 * target after sign-in.
 *
 * Privacy: drafts, not-yet-published scheduled events, private communities and
 * hidden profiles (missing/deleted, banned, suspended, incognito, ghost mode,
 * sharing opt-out) render a generic GreenGo card - never their name, text or
 * photo. So do unpublished / hidden / copyright- or safety-held experiences
 * and unpublished attractions. Profile cards never include age, birth date,
 * exact location or contact details (see sharePreviewCore.ts). Attraction
 * photos whose licence forbids the use fall back to the brand image; those
 * that require attribution carry it in the card text.
 *
 * Language: fixed strings come from the ARB-backed server catalog, in the
 * request's Accept-Language (or ?hl=), English by default; responses carry
 * `Vary: Accept-Language` so the CDN keeps one copy per language.
 */

import { onRequest } from 'firebase-functions/v2/https';
import axios from 'axios';
import sharp from 'sharp';
import { monitored } from '../shared/monitoring';
import { admin } from '../shared/firebaseAdmin';
import {
  DEFAULT_ATTRACTION_BUCKET,
  FALLBACK_IMAGE,
  HOST,
  Kind,
  OG_H,
  OG_W,
  Preview,
  buildAttractionPreview,
  buildCommunityPreview,
  buildEventPreview,
  buildExperiencePreview,
  buildProfilePreview,
  genericPreview,
  parseSharePath,
  pickLocale,
  renderHtml,
} from './sharePreviewCore';
import type { AppLocale } from '../shared/i18n';
import { handleReferralPreview } from './referralPreview';
import { guestViewBlock } from '../guest/guestModel';

const MAX_SOURCE_BYTES = 15 * 1024 * 1024;

// Cache: HTML is short at the browser (edits show up quickly) and longer at
// the CDN; images are immutable per ?v= so they can live much longer.
// Profiles use shorter CDN windows so going incognito / changing the photo
// takes effect quickly.
const HTML_CACHE = 'public, max-age=300, s-maxage=1800';
const PROFILE_HTML_CACHE = 'public, max-age=300, s-maxage=600';
const IMAGE_CACHE = 'public, max-age=86400, s-maxage=604800';
const PROFILE_IMAGE_CACHE = 'public, max-age=3600, s-maxage=86400';
// Experiences are user content that can be hidden / taken down at any time:
// short CDN windows so a takedown stops showing within the hour.
const UGC_HTML_CACHE = 'public, max-age=300, s-maxage=600';
const UGC_IMAGE_CACHE = 'public, max-age=3600, s-maxage=3600';

function htmlCache(kind: Kind): string {
  if (kind === 'u') return PROFILE_HTML_CACHE;
  if (kind === 'x') return UGC_HTML_CACHE;
  return HTML_CACHE;
}

function imageCache(kind: Kind): string {
  if (kind === 'u') return PROFILE_IMAGE_CACHE;
  if (kind === 'x') return UGC_IMAGE_CACHE;
  return IMAGE_CACHE;
}

// Only these hosts are fetched server-side (no SSRF through a user-supplied
// image URL). Anything else is redirected to so the crawler fetches it itself.
const FETCHABLE_HOSTS = [
  'firebasestorage.googleapis.com',
  'storage.googleapis.com',
  'images.unsplash.com',
];

const COLLECTION: Record<Kind, string> = {
  e: 'events',
  c: 'communities',
  u: 'profiles',
  x: 'user_experiences',
  a: 'attractions',
};

// Bucket of the catalogue images (attraction_config/app.storageBucket, as the
// app reads it); one read per instance.
let attractionBucket: Promise<string> | null = null;
function getAttractionBucket(): Promise<string> {
  attractionBucket ??= admin
    .firestore()
    .collection('attraction_config')
    .doc('app')
    .get()
    .then((d) => {
      const b = d.get('storageBucket');
      return typeof b === 'string' && b.trim() ? b.trim() : DEFAULT_ATTRACTION_BUCKET;
    })
    .catch(() => {
      attractionBucket = null;
      return DEFAULT_ATTRACTION_BUCKET;
    });
  return attractionBucket;
}

async function loadPreview(kind: Kind, id: string, locale: AppLocale): Promise<Preview> {
  const snap = await admin.firestore().collection(COLLECTION[kind]).doc(id).get();
  if (!snap.exists) return genericPreview(kind, id, locale);
  const d = (snap.data() ?? {}) as Record<string, unknown>;
  // Guest landing ("Continue as guest", guest/) only for what a guest may see.
  const guest = (p: Preview): Preview =>
    (p.shareable && !guestViewBlock(kind as 'e' | 'x' | 'a', d, Date.now()) ? { ...p, guestLanding: true } : p);
  if (kind === 'e') return guest(buildEventPreview(id, d, Date.now(), locale));
  if (kind === 'c') return buildCommunityPreview(id, d, locale);
  if (kind === 'x') return guest(buildExperiencePreview(id, d, locale));
  if (kind === 'a') return guest(buildAttractionPreview(id, d, await getAttractionBucket(), locale));
  return buildProfilePreview(id, d, Date.now(), locale);
}

/**
 * Profile photos are usually portrait: fit the WHOLE photo (face never
 * cropped) on a blurred, darkened copy of itself so the card is still the
 * 1.91:1 large-image format WhatsApp / Telegram / Instagram expect.
 */
async function fitPortrait(source: Buffer): Promise<Buffer> {
  const base = sharp(source).rotate();
  const background = await base
    .clone()
    .resize(OG_W, OG_H, { fit: 'cover', position: 'attention' })
    .blur(28)
    .modulate({ brightness: 0.55 })
    .toBuffer();
  const foreground = await base
    .clone()
    .resize(OG_W, OG_H, { fit: 'inside', withoutEnlargement: false })
    .toBuffer();
  return sharp(background)
    .composite([{ input: foreground, gravity: 'center' }])
    .jpeg({ quality: 80, progressive: true, mozjpeg: true })
    .toBuffer();
}

async function renderImage(p: Preview): Promise<Buffer | string> {
  if (!p.shareable || !p.imageUrl) return FALLBACK_IMAGE;
  let src: URL;
  try {
    src = new URL(p.imageUrl);
  } catch {
    return FALLBACK_IMAGE;
  }
  if (src.protocol !== 'https:' || !FETCHABLE_HOSTS.includes(src.hostname)) {
    // Not ours to fetch: let the crawler load it directly.
    return src.protocol === 'https:' ? src.toString() : FALLBACK_IMAGE;
  }
  try {
    const resp = await axios.get<ArrayBuffer>(src.toString(), {
      responseType: 'arraybuffer',
      timeout: 8000,
      maxContentLength: MAX_SOURCE_BYTES,
      maxRedirects: 3,
    });
    const source = Buffer.from(resp.data);
    if (p.kind === 'u') return await fitPortrait(source);
    return await sharp(source)
      .rotate() // honour EXIF orientation from phone photos
      .resize(OG_W, OG_H, { fit: 'cover', position: 'attention' })
      .jpeg({ quality: 78, progressive: true, mozjpeg: true })
      .toBuffer();
  } catch {
    return FALLBACK_IMAGE;
  }
}

export const sharePreview = onRequest(
  { memory: '512MiB', timeoutSeconds: 30, invoker: 'public' },
  monitored('sharePreview', async (req, res) => {
    if (req.method !== 'GET' && req.method !== 'HEAD') {
      res.status(405).send('method not allowed');
      return;
    }
    if (await handleReferralPreview(req, res)) return; // /r/{CODE} invite links
    const parsed = parseSharePath(req.path);
    if (!parsed) {
      res.redirect(302, HOST);
      return;
    }
    const { isImage, kind, id } = parsed;
    const locale = pickLocale(req.get('accept-language'), req.query.hl);

    let preview: Preview;
    try {
      preview = await loadPreview(kind, id, locale);
    } catch {
      preview = genericPreview(kind, id, locale);
    }

    if (isImage) {
      const out = await renderImage(preview);
      if (typeof out === 'string') {
        res.set('Cache-Control', 'public, max-age=3600, s-maxage=3600');
        res.redirect(302, out);
        return;
      }
      res.set('Cache-Control', imageCache(kind));
      res.type('image/jpeg').send(out);
      return;
    }

    res.set('Cache-Control', htmlCache(kind));
    res.set('Vary', 'Accept-Language');
    res.type('html').send(renderHtml(preview));
  }),
);
