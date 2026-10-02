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

/** Hosts that only ever serve generated placeholder graphics. */
export const PLACEHOLDER_HOSTS: readonly string[] = [
  'placehold.co',
  'placehold.it',
  'placeholder.com',
  'via.placeholder.com',
  'dummyimage.com',
  'fakeimg.pl',
  'ui-avatars.com',
];

/** True when [url] is a non-empty absolute http(s) URL that is not a placeholder. */
export function isUsableImageUrl(url: unknown): boolean {
  if (typeof url !== 'string') return false;
  const s = url.trim();
  if (s.length === 0) return false;
  let parsed: URL;
  try {
    parsed = new URL(s);
  } catch (_) {
    return false;
  }
  if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') return false;
  const host = parsed.hostname.toLowerCase();
  if (host.length === 0) return false;
  return !PLACEHOLDER_HOSTS.some((p) => host === p || host.endsWith(`.${p}`));
}

/** Ticketmaster Discovery image object (only the fields we read). */
export interface TmImage {
  url?: string;
  width?: number;
  fallback?: boolean;
}

/**
 * The best Ticketmaster image: the widest one that is the event's OWN image,
 * else (only when the event has none) the widest generic category "fallback"
 * image. `fallback` says which one was picked.
 */
export function pickTicketmasterImage(
  images: TmImage[] | undefined
): { url: string | null; fallback: boolean } {
  let own: TmImage | undefined;
  let generic: TmImage | undefined;
  for (const im of images || []) {
    if (!isUsableImageUrl(im?.url)) continue;
    if (im.fallback === true) {
      if (!generic || (im.width || 0) > (generic.width || 0)) generic = im;
    } else if (!own || (im.width || 0) > (own.width || 0)) {
      own = im;
    }
  }
  const best = own ?? generic;
  return { url: best?.url ?? null, fallback: !own && !!generic };
}
