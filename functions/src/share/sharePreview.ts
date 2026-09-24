/**
 * Link previews for shared GreenGo EVENTS and COMMUNITIES.
 *
 * WhatsApp, Telegram, Instagram (DMs), iMessage, Slack… build their preview
 * card from the page's Open Graph tags, and their crawlers never run
 * JavaScript. So the shareable links must be rendered on the server:
 *
 *   /e/{eventId}           -> HTML with og:title/description/image for the event
 *   /c/{communityId}       -> same for a community
 *   /og/e/{eventId}.jpg    -> 1200x630 JPEG preview image (the og:image)
 *   /og/c/{communityId}.jpg
 *
 * Firebase Hosting rewrites these paths here (firebase.json). Every response
 * is CDN-cacheable, so a link that goes viral costs ~one Firestore read and
 * one resize per cache window, not one per viewer.
 *
 * People (not crawlers) who open the link get the same page: if the app is
 * installed the OS already opened it via App Links / Universal Links; otherwise
 * the page tries `greengo://` once and then sends them to the right store.
 *
 * Privacy: drafts, not-yet-published scheduled events and private communities
 * render a generic GreenGo card - never their title, text or photo.
 */

import { onRequest } from 'firebase-functions/v2/https';
import axios from 'axios';
import sharp from 'sharp';
import { monitored } from '../shared/monitoring';
import { admin } from '../shared/firebaseAdmin';

const HOST = 'https://greengo-chat.web.app';
const PLAY_URL =
  'https://play.google.com/store/apps/details?id=com.greengochat.greengochatapp';
// TODO: replace id123456789 with the real numeric App Store ID once assigned
// (same placeholder the old static fallback pages used).
const APPSTORE_URL = 'https://apps.apple.com/app/greengo/id123456789';
const FALLBACK_IMAGE = `${HOST}/icons/Icon-512.png`;

const OG_W = 1200;
const OG_H = 630;
const MAX_SOURCE_BYTES = 15 * 1024 * 1024;

// Cache: HTML is short at the browser (edits show up quickly) and longer at
// the CDN; images are immutable per ?v= so they can live much longer.
const HTML_CACHE = 'public, max-age=300, s-maxage=1800';
const IMAGE_CACHE = 'public, max-age=86400, s-maxage=604800';

// Only these hosts are fetched server-side (no SSRF through a user-supplied
// image URL). Anything else is redirected to so the crawler fetches it itself.
const FETCHABLE_HOSTS = [
  'firebasestorage.googleapis.com',
  'storage.googleapis.com',
  'images.unsplash.com',
];

type Kind = 'e' | 'c';

interface Preview {
  kind: Kind;
  id: string;
  title: string;
  description: string;
  imageUrl: string | null;
  version: number;
  /** false = generic card (missing / private / not yet published). */
  shareable: boolean;
}

const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function clip(s: string, max: number): string {
  const t = s.replace(/\s+/g, ' ').trim();
  return t.length <= max ? t : `${t.slice(0, max - 1).trimEnd()}…`;
}

function str(v: unknown): string {
  return typeof v === 'string' ? v.trim() : '';
}

function millis(v: unknown): number {
  if (v instanceof admin.firestore.Timestamp) return v.toMillis();
  return 0;
}

async function loadPreview(kind: Kind, id: string): Promise<Preview> {
  const generic: Preview = {
    kind,
    id,
    title: 'GreenGo',
    description:
      'Discover people, cultures, events and communities around the world.',
    imageUrl: null,
    version: 0,
    shareable: false,
  };

  const snap = await admin
    .firestore()
    .collection(kind === 'e' ? 'events' : 'communities')
    .doc(id)
    .get();
  if (!snap.exists) return generic;
  const d = snap.data() ?? {};

  if (kind === 'e') {
    const status = str(d.status);
    const publishAt = millis(d.publishAt);
    const notLiveYet =
      status === 'draft' ||
      (status === 'scheduled' && publishAt > Date.now());
    if (notLiveYet) return generic;

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
    const description = clip(
      [facts.join(' · '), body].filter(Boolean).join(' — '),
      200,
    );
    return {
      kind,
      id,
      title: clip(title, 90),
      description: description || generic.description,
      imageUrl: str(d.imageUrl) || null,
      version: millis(d.updatedAt) || millis(d.createdAt),
      shareable: true,
    };
  }

  // Community
  if (d.isPublic === false) return generic;
  const name = str(d.name) || 'GreenGo community';
  const members = typeof d.memberCount === 'number' ? d.memberCount : 0;
  const place = [str(d.city), str(d.country)].filter(Boolean).join(', ');
  const facts = [
    members > 0 ? `👥 ${members} ${members === 1 ? 'member' : 'members'}` : '',
    place ? `📍 ${place}` : '',
  ].filter(Boolean);
  const description = clip(
    [facts.join(' · '), str(d.description)].filter(Boolean).join(' — '),
    200,
  );
  return {
    kind,
    id,
    title: clip(name, 90),
    description: description || generic.description,
    imageUrl: str(d.imageUrl) || null,
    version: millis(d.lastActivityAt) || millis(d.createdAt),
    shareable: true,
  };
}

function renderHtml(p: Preview): string {
  const url = `${HOST}/${p.kind}/${encodeURIComponent(p.id)}`;
  const hasOwnImage = p.shareable && !!p.imageUrl;
  const image = hasOwnImage
    ? `${HOST}/og/${p.kind}/${encodeURIComponent(p.id)}.jpg?v=${p.version}`
    : FALLBACK_IMAGE;
  const t = escapeHtml(p.title);
  const desc = escapeHtml(p.description);
  const img = escapeHtml(image);
  const u = escapeHtml(url);
  const appUrl = `greengo://${p.kind}/${encodeURIComponent(p.id)}`;
  const what = p.kind === 'e' ? 'event' : 'community';
  const imageTags = hasOwnImage
    ? `
  <meta property="og:image:width" content="${OG_W}" />
  <meta property="og:image:height" content="${OG_H}" />
  <meta property="og:image:type" content="image/jpeg" />
  <meta name="twitter:card" content="summary_large_image" />`
    : `
  <meta name="twitter:card" content="summary" />`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${t}</title>
  <meta name="description" content="${desc}" />
  <link rel="canonical" href="${u}" />
  <meta property="og:site_name" content="GreenGo" />
  <meta property="og:type" content="website" />
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
  </style>
</head>
<body>
  ${hasOwnImage ? `<img src="${img}" alt="" />` : ''}
  <h1>${t}</h1>
  <p>${desc}</p>
  <a class="btn" id="store" href="${PLAY_URL}">Open in GreenGo</a>
  <script>
    // If the app is installed, App Links / Universal Links opened it before
    // this page loaded. Otherwise try the custom scheme once, then go to the
    // right store for this ${what}.
    (function () {
      var ua = navigator.userAgent || navigator.vendor || "";
      var isIOS = /iPad|iPhone|iPod/.test(ua) && !window.MSStream;
      var isAndroid = /android/i.test(ua);
      var storeUrl = isIOS ? ${JSON.stringify(APPSTORE_URL)} : ${JSON.stringify(PLAY_URL)};
      document.getElementById("store").href = storeUrl;
      if (!isAndroid && !isIOS) return; // desktop: let them read the card
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
    return await sharp(Buffer.from(resp.data))
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
    const parts = req.path.split('/').filter(Boolean);
    const isImage = parts[0] === 'og';
    const kind = (isImage ? parts[1] : parts[0]) as Kind;
    const rawId = (isImage ? parts[2] : parts[1]) ?? '';
    const id = decodeURIComponent(isImage ? rawId.replace(/\.jpg$/i, '') : rawId);

    if ((kind !== 'e' && kind !== 'c') || !ID_RE.test(id)) {
      res.redirect(302, HOST);
      return;
    }

    let preview: Preview;
    try {
      preview = await loadPreview(kind, id);
    } catch {
      preview = {
        kind,
        id,
        title: 'GreenGo',
        description:
          'Discover people, cultures, events and communities around the world.',
        imageUrl: null,
        version: 0,
        shareable: false,
      };
    }

    if (isImage) {
      const out = await renderImage(preview);
      if (typeof out === 'string') {
        res.set('Cache-Control', 'public, max-age=3600, s-maxage=3600');
        res.redirect(302, out);
        return;
      }
      res.set('Cache-Control', IMAGE_CACHE);
      res.type('image/jpeg').send(out);
      return;
    }

    res.set('Cache-Control', HTML_CACHE);
    res.type('html').send(renderHtml(preview));
  }),
);
