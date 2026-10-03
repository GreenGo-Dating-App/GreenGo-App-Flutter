"use strict";
/**
 * Link previews for shared GreenGo EVENTS, COMMUNITIES and PROFILES.
 *
 * WhatsApp, Telegram, Instagram (DMs), iMessage, Slack… build their preview
 * card from the page's Open Graph tags, and their crawlers never run
 * JavaScript. So the shareable links must be rendered on the server:
 *
 *   /e/{eventId}           -> HTML with og:title/description/image for the event
 *   /c/{communityId}       -> same for a community
 *   /u/{userId}            -> same for a user profile (main photo, name, city)
 *   /og/e/{eventId}.jpg    -> 1200x630 JPEG preview image (the og:image)
 *   /og/c/{communityId}.jpg
 *   /og/u/{userId}.jpg     -> the profile's MAIN photo, fitted on 1200x630
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
 * photo. Profile cards never include age, birth date, exact location or
 * contact details (see sharePreviewCore.ts).
 */
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.sharePreview = void 0;
const https_1 = require("firebase-functions/v2/https");
const axios_1 = __importDefault(require("axios"));
const sharp_1 = __importDefault(require("sharp"));
const monitoring_1 = require("../shared/monitoring");
const firebaseAdmin_1 = require("../shared/firebaseAdmin");
const sharePreviewCore_1 = require("./sharePreviewCore");
const MAX_SOURCE_BYTES = 15 * 1024 * 1024;
// Cache: HTML is short at the browser (edits show up quickly) and longer at
// the CDN; images are immutable per ?v= so they can live much longer.
// Profiles use shorter CDN windows so going incognito / changing the photo
// takes effect quickly.
const HTML_CACHE = 'public, max-age=300, s-maxage=1800';
const PROFILE_HTML_CACHE = 'public, max-age=300, s-maxage=600';
const IMAGE_CACHE = 'public, max-age=86400, s-maxage=604800';
const PROFILE_IMAGE_CACHE = 'public, max-age=3600, s-maxage=86400';
// Only these hosts are fetched server-side (no SSRF through a user-supplied
// image URL). Anything else is redirected to so the crawler fetches it itself.
const FETCHABLE_HOSTS = [
    'firebasestorage.googleapis.com',
    'storage.googleapis.com',
    'images.unsplash.com',
];
const COLLECTION = {
    e: 'events',
    c: 'communities',
    u: 'profiles',
};
async function loadPreview(kind, id) {
    var _a;
    const snap = await firebaseAdmin_1.admin.firestore().collection(COLLECTION[kind]).doc(id).get();
    if (!snap.exists)
        return (0, sharePreviewCore_1.genericPreview)(kind, id);
    const d = ((_a = snap.data()) !== null && _a !== void 0 ? _a : {});
    if (kind === 'e')
        return (0, sharePreviewCore_1.buildEventPreview)(id, d);
    if (kind === 'c')
        return (0, sharePreviewCore_1.buildCommunityPreview)(id, d);
    return (0, sharePreviewCore_1.buildProfilePreview)(id, d);
}
/**
 * Profile photos are usually portrait: fit the WHOLE photo (face never
 * cropped) on a blurred, darkened copy of itself so the card is still the
 * 1.91:1 large-image format WhatsApp / Telegram / Instagram expect.
 */
async function fitPortrait(source) {
    const base = (0, sharp_1.default)(source).rotate();
    const background = await base
        .clone()
        .resize(sharePreviewCore_1.OG_W, sharePreviewCore_1.OG_H, { fit: 'cover', position: 'attention' })
        .blur(28)
        .modulate({ brightness: 0.55 })
        .toBuffer();
    const foreground = await base
        .clone()
        .resize(sharePreviewCore_1.OG_W, sharePreviewCore_1.OG_H, { fit: 'inside', withoutEnlargement: false })
        .toBuffer();
    return (0, sharp_1.default)(background)
        .composite([{ input: foreground, gravity: 'center' }])
        .jpeg({ quality: 80, progressive: true, mozjpeg: true })
        .toBuffer();
}
async function renderImage(p) {
    if (!p.shareable || !p.imageUrl)
        return sharePreviewCore_1.FALLBACK_IMAGE;
    let src;
    try {
        src = new URL(p.imageUrl);
    }
    catch (_a) {
        return sharePreviewCore_1.FALLBACK_IMAGE;
    }
    if (src.protocol !== 'https:' || !FETCHABLE_HOSTS.includes(src.hostname)) {
        // Not ours to fetch: let the crawler load it directly.
        return src.protocol === 'https:' ? src.toString() : sharePreviewCore_1.FALLBACK_IMAGE;
    }
    try {
        const resp = await axios_1.default.get(src.toString(), {
            responseType: 'arraybuffer',
            timeout: 8000,
            maxContentLength: MAX_SOURCE_BYTES,
            maxRedirects: 3,
        });
        const source = Buffer.from(resp.data);
        if (p.kind === 'u')
            return await fitPortrait(source);
        return await (0, sharp_1.default)(source)
            .rotate() // honour EXIF orientation from phone photos
            .resize(sharePreviewCore_1.OG_W, sharePreviewCore_1.OG_H, { fit: 'cover', position: 'attention' })
            .jpeg({ quality: 78, progressive: true, mozjpeg: true })
            .toBuffer();
    }
    catch (_b) {
        return sharePreviewCore_1.FALLBACK_IMAGE;
    }
}
exports.sharePreview = (0, https_1.onRequest)({ memory: '512MiB', timeoutSeconds: 30, invoker: 'public' }, (0, monitoring_1.monitored)('sharePreview', async (req, res) => {
    if (req.method !== 'GET' && req.method !== 'HEAD') {
        res.status(405).send('method not allowed');
        return;
    }
    const parsed = (0, sharePreviewCore_1.parseSharePath)(req.path);
    if (!parsed) {
        res.redirect(302, sharePreviewCore_1.HOST);
        return;
    }
    const { isImage, kind, id } = parsed;
    let preview;
    try {
        preview = await loadPreview(kind, id);
    }
    catch (_a) {
        preview = (0, sharePreviewCore_1.genericPreview)(kind, id);
    }
    if (isImage) {
        const out = await renderImage(preview);
        if (typeof out === 'string') {
            res.set('Cache-Control', 'public, max-age=3600, s-maxage=3600');
            res.redirect(302, out);
            return;
        }
        res.set('Cache-Control', kind === 'u' ? PROFILE_IMAGE_CACHE : IMAGE_CACHE);
        res.type('image/jpeg').send(out);
        return;
    }
    res.set('Cache-Control', kind === 'u' ? PROFILE_HTML_CACHE : HTML_CACHE);
    res.type('html').send((0, sharePreviewCore_1.renderHtml)(preview));
}));
//# sourceMappingURL=sharePreview.js.map