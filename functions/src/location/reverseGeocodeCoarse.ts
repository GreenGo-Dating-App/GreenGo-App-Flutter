/**
 * reverseGeocodeCoarse (callable, v2): city + country for a position, for the
 * WEB build (the `geocoding` plugin has no web implementation).
 *
 * Legal audit 2026-10 (EU-05 / BR-06 data minimisation): the browser used to
 * call nominatim.openstreetmap.org directly, so a third party with no DPA got
 * the user's IP address together with their position. Now the device calls
 * this function and the third party only ever sees:
 *   - coordinates ROUNDED HERE to 2 decimals (~1.1 km), whatever the client
 *     sent (only a city is wanted anyway);
 *   - the Cloud Functions egress IP, never the user's.
 * Provider: Google Geocoding API when GOOGLE_GEOCODING_API_KEY (or
 * app_config/api_keys.geocoding_api_key) is configured (contracted Google
 * Maps Platform), else Nominatim with an identifying User-Agent (OSMF usage
 * policy). Results are cached per rounded cell in memory, and each user has a
 * small daily quota (ai_usage counter, shared helper).
 *
 * Deploy: reverseGeocodeCoarse
 */
import { onCall } from 'firebase-functions/v2/https';
import { AppError, handleError } from '../shared/utils';
import { consumeQuota, getServerKey, requireUid } from '../ai/aiGateway';

/** Per user per day. A web session geocodes once per real move. */
export const DAILY_LIMIT = 100;
const CACHE_MAX = 2000;
const TIMEOUT_MS = 8000;

export interface CoarsePlace {
  city: string;
  country: string;
}

/** [v] rounded to 2 decimals (~1.1 km). */
export function coarse(v: number): number {
  return Math.round(v * 100) / 100;
}

export function validCoordinates(lat: unknown, lng: unknown): lat is number {
  return typeof lat === 'number' && typeof lng === 'number'
    && Number.isFinite(lat) && Number.isFinite(lng)
    && Math.abs(lat) <= 90 && Math.abs(lng) <= 180;
}

const firstNonEmpty = (v: unknown[]): string =>
  v.map((x) => (typeof x === 'string' ? x.trim() : '')).find((s) => s.length > 0) ?? '';

/** City + country from a Nominatim `reverse?format=jsonv2` body. */
export function parseNominatim(body: any): CoarsePlace | null {
  const addr = body?.address ?? {};
  const city = firstNonEmpty([addr.city, addr.town, addr.village, addr.municipality, addr.county, addr.state]);
  const country = firstNonEmpty([addr.country]);
  return city || country ? { city, country } : null;
}

/** City + country from a Google Geocoding API body. */
export function parseGoogle(body: any): CoarsePlace | null {
  if (body?.status !== 'OK' || !Array.isArray(body.results)) return null;
  let city = '';
  let admin1 = '';
  let country = '';
  for (const r of body.results) {
    for (const c of r?.address_components ?? []) {
      const types: string[] = c?.types ?? [];
      if (!city && (types.includes('locality') || types.includes('postal_town'))) city = c.long_name ?? '';
      if (!admin1 && types.includes('administrative_area_level_1')) admin1 = c.long_name ?? '';
      if (!country && types.includes('country')) country = c.long_name ?? '';
    }
  }
  city = city || admin1;
  return city || country ? { city, country } : null;
}

const cache = new Map<string, CoarsePlace | null>();
/** Test hook. */
export function _resetCache() { cache.clear(); }

async function fetchJson(url: string, headers: Record<string, string>): Promise<any> {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), TIMEOUT_MS);
  try {
    const res: any = await fetch(url, { headers, signal: ctrl.signal });
    if (!res.ok) return null;
    return await res.json();
  } finally {
    clearTimeout(t);
  }
}

export async function lookup(lat: number, lng: number): Promise<CoarsePlace | null> {
  const la = coarse(lat).toFixed(2);
  const lo = coarse(lng).toFixed(2);
  const key = `${la},${lo}`;
  if (cache.has(key)) return cache.get(key) ?? null;
  let place: CoarsePlace | null = null;
  const googleKey = await getServerKey('GOOGLE_GEOCODING_API_KEY', 'geocoding_api_key');
  if (googleKey) {
    const body = await fetchJson(
      `https://maps.googleapis.com/maps/api/geocode/json?latlng=${la},${lo}`
        + `&result_type=locality|administrative_area_level_1|country&language=en&key=${encodeURIComponent(googleKey)}`,
      { Accept: 'application/json' });
    place = parseGoogle(body);
  } else {
    const body = await fetchJson(
      `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${la}&lon=${lo}`
        + '&zoom=10&addressdetails=1&accept-language=en',
      { Accept: 'application/json', 'User-Agent': 'GreenGo-server-geocoder/1.0 (+https://greengochat.com)' });
    place = parseNominatim(body);
  }
  if (cache.size >= CACHE_MAX) cache.delete(cache.keys().next().value as string);
  cache.set(key, place);
  return place;
}

export async function handleReverseGeocodeCoarse(request: any): Promise<{ success: true; city: string; country: string }> {
  const uid = requireUid(request);
  const { lat, lng } = request.data ?? {};
  if (!validCoordinates(lat, lng)) throw new AppError('INVALID_ARGUMENT', 'lat/lng are required', 400);
  await consumeQuota(uid, 'reverseGeocode', 1, DAILY_LIMIT);
  let place: CoarsePlace | null = null;
  try {
    place = await lookup(lat, lng as number);
  } catch (e: any) {
    console.warn(`reverseGeocodeCoarse: lookup failed: ${e?.message ?? e}`);
  }
  return { success: true, city: place?.city ?? '', country: place?.country ?? '' };
}

export const reverseGeocodeCoarse = onCall(
  { memory: '512MiB', timeoutSeconds: 30 },
  async (request) => {
    try {
      return await handleReverseGeocodeCoarse(request);
    } catch (e) {
      throw handleError(e);
    }
  },
);
