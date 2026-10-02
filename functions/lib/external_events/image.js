"use strict";
/**
 * "Only elements with pictures are shown" — the server-side twin of the app's
 * `DisplayImage.isUsableUrl` (lib/core/utils/display_image.dart). Keep the two
 * in sync.
 *
 * Ingesters stamp `hasImage` on every `external_events` doc they write, so a
 * future query can filter server-side once existing docs are backfilled
 * (scripts/backfill_external_events_has_image.js). The app does NOT depend on
 * the field: its client-side predicate stays the source of truth.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.PLACEHOLDER_HOSTS = void 0;
exports.isUsableImageUrl = isUsableImageUrl;
exports.pickTicketmasterImage = pickTicketmasterImage;
/** Hosts that only ever serve generated placeholder graphics. */
exports.PLACEHOLDER_HOSTS = [
    'placehold.co',
    'placehold.it',
    'placeholder.com',
    'via.placeholder.com',
    'dummyimage.com',
    'fakeimg.pl',
    'ui-avatars.com',
];
/** True when [url] is a non-empty absolute http(s) URL that is not a placeholder. */
function isUsableImageUrl(url) {
    if (typeof url !== 'string')
        return false;
    const s = url.trim();
    if (s.length === 0)
        return false;
    let parsed;
    try {
        parsed = new URL(s);
    }
    catch (_) {
        return false;
    }
    if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:')
        return false;
    const host = parsed.hostname.toLowerCase();
    if (host.length === 0)
        return false;
    return !exports.PLACEHOLDER_HOSTS.some((p) => host === p || host.endsWith(`.${p}`));
}
/**
 * The best Ticketmaster image: the widest one that is the event's OWN image,
 * else (only when the event has none) the widest generic category "fallback"
 * image. `fallback` says which one was picked.
 */
function pickTicketmasterImage(images) {
    var _a;
    let own;
    let generic;
    for (const im of images || []) {
        if (!isUsableImageUrl(im === null || im === void 0 ? void 0 : im.url))
            continue;
        if (im.fallback === true) {
            if (!generic || (im.width || 0) > (generic.width || 0))
                generic = im;
        }
        else if (!own || (im.width || 0) > (own.width || 0)) {
            own = im;
        }
    }
    const best = own !== null && own !== void 0 ? own : generic;
    return { url: (_a = best === null || best === void 0 ? void 0 : best.url) !== null && _a !== void 0 ? _a : null, fallback: !own && !!generic };
}
//# sourceMappingURL=image.js.map