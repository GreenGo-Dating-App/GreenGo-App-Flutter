/**
 * Address search for the in-app location picker (event venue, experience
 * meeting point, chat "share a place", alert-city and traveler-city search).
 *
 * Three callables, all auth-required:
 *   - searchAddress  forward autocomplete (as-you-type suggestions)
 *   - resolvePlace   coordinates + city/country for a Google suggestion
 *                    (Photon suggestions already carry them)
 *   - reverseGeocode PRECISE reverse geocoding for a pin the user dropped on
 *                    a public meeting place. Profile location keeps using
 *                    reverseGeocodeCoarse (~1 km), which is unchanged.
 *
 * Why server-side: no third party ever sees the user's IP, keys never ship in
 * the client, and one shared cache + per-user rate limit keep the cost flat
 * however many people type at once.
 *
 * Provider:
 *   - Google Places API (New) when GOOGLE_PLACES_API_KEY (or
 *     app_config/api_keys.places_api_key) is set: Autocomplete + Place Details
 *     share a client session token, so a whole typing session bills as ONE
 *     Place Details request. Reverse uses the Geocoding API key
 *     (GOOGLE_GEOCODING_API_KEY / geocoding_api_key) when present.
 *   - Otherwise Photon (photon.komoot.io): OSM data, built for typeahead.
 *     Nominatim is NEVER used here: its usage policy forbids autocomplete.
 *
 * Language: suggestion text is in the user's language where the provider
 * supports it; the structured city/country fields are always requested in
 * English, the app's canonical form (city alerts and country filters compare
 * those strings).
 *
 * Deploy: searchAddress, resolvePlace, reverseGeocode
 */
import { onCall } from 'firebase-functions/v2/https';
import { AppError, handleError } from '../shared/utils';
import { consumeQuota, getServerKey, requireUid } from '../ai/aiGateway';

// ── Limits ──────────────────────────────────────────────────────────────────

/** Requests per user per minute, all three callables together (per instance). */
export const PER_MINUTE_LIMIT = 60;
/** Provider lookups (cache misses) per user per day. */
export const DAILY_PROVIDER_LIMIT = 1000;
export const MIN_QUERY = 2;
export const MAX_QUERY = 120;
export const MAX_RESULTS = 6;
const TIMEOUT_MS = 6000;
const CACHE_MAX = 5000;
const SEARCH_TTL_MS = 6 * 3600_000;
const PLACE_TTL_MS = 24 * 3600_000;
/** Location bias radius for Google (meters). */
const BIAS_RADIUS_M = 50_000;

export const USER_AGENT =
  'GreenGo-server-geocoder/1.0 (+https://greengochat.com; support@greengochat.com)';
const PHOTON = 'https://photon.komoot.io';
const PHOTON_LANGS = new Set(['en', 'de', 'fr']);

// ── Types ───────────────────────────────────────────────────────────────────

export type SearchMode = 'address' | 'city';
export type Provider = 'google' | 'photon';

export interface Suggestion {
  id: string;
  primary: string;
  secondary: string;
  /** Present for Photon; Google needs resolvePlace. */
  lat?: number;
  lng?: number;
  city: string;
  country: string;
  countryCode: string;
  /** Google place id, to pass to resolvePlace. */
  placeId?: string;
}

export interface Place {
  address: string;
  lat: number;
  lng: number;
  city: string;
  country: string;
  countryCode: string;
  placeId?: string;
}

export interface SearchInput {
  query: string;
  lang: string;
  mode: SearchMode;
  biasLat?: number;
  biasLng?: number;
  sessionToken?: string;
}

// ── Dependencies (swapped in tests) ─────────────────────────────────────────

export interface HttpResult { ok: boolean; status: number; body: any }
export interface Deps {
  fetchJson: (url: string, init?: { method?: string; headers?: Record<string, string>; body?: string }) => Promise<HttpResult>;
  placesKey: () => Promise<string | null>;
  geocodingKey: () => Promise<string | null>;
  quota: (uid: string) => Promise<void>;
  now: () => number;
}

async function defaultFetchJson(url: string, init: { method?: string; headers?: Record<string, string>; body?: string } = {}): Promise<HttpResult> {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), TIMEOUT_MS);
  try {
    const res: any = await fetch(url, { ...init, signal: ctrl.signal });
    let body: any = null;
    try { body = await res.json(); } catch { body = null; }
    return { ok: !!res.ok, status: Number(res.status) || 0, body };
  } finally {
    clearTimeout(t);
  }
}

const defaultDeps: Deps = {
  fetchJson: defaultFetchJson,
  placesKey: () => getServerKey('GOOGLE_PLACES_API_KEY', 'places_api_key'),
  geocodingKey: () => getServerKey('GOOGLE_GEOCODING_API_KEY', 'geocoding_api_key'),
  quota: (uid) => consumeQuota(uid, 'placeSearch', 1, DAILY_PROVIDER_LIMIT),
  now: () => Date.now(),
};
let deps: Deps = defaultDeps;
/** Test hook: override some dependencies; call with no args to restore. */
export function _setDeps(over?: Partial<Deps>) { deps = over ? { ...defaultDeps, ...over } : defaultDeps; }

// ── Validation ──────────────────────────────────────────────────────────────

export function validCoordinates(lat: unknown, lng: unknown): boolean {
  return typeof lat === 'number' && typeof lng === 'number'
    && Number.isFinite(lat) && Number.isFinite(lng)
    && Math.abs(lat) <= 90 && Math.abs(lng) <= 180;
}

/** Lowercase, NFKC, single spaces: two spellings of one query share a cache entry. */
export function normalizeQuery(q: string): string {
  return q.normalize('NFKC').toLowerCase().replace(/\s+/g, ' ').trim();
}

/** "pt_BR" / "pt-br" / "PT" → "pt-BR" / "pt"; anything odd → "en". */
export function normalizeLang(raw: unknown): string {
  if (typeof raw !== 'string') return 'en';
  const m = /^([a-zA-Z]{2})(?:[-_]([a-zA-Z]{2}))?$/.exec(raw.trim());
  if (!m) return 'en';
  return m[2] ? `${m[1].toLowerCase()}-${m[2].toUpperCase()}` : m[1].toLowerCase();
}

const TOKEN_RE = /^[A-Za-z0-9_-]{8,64}$/;
const PLACE_ID_RE = /^[A-Za-z0-9_-]{10,300}$/;

/** Validates raw callable data into a [SearchInput]; throws INVALID_ARGUMENT. */
export function parseSearchInput(data: any): SearchInput {
  const raw = typeof data?.query === 'string' ? data.query : '';
  const query = raw.replace(/\s+/g, ' ').trim();
  if (query.length < MIN_QUERY || query.length > MAX_QUERY) {
    throw new AppError('INVALID_ARGUMENT', `query must be ${MIN_QUERY}-${MAX_QUERY} characters`, 400);
  }
  const mode: SearchMode = data?.mode === 'city' ? 'city' : 'address';
  const input: SearchInput = { query, lang: normalizeLang(data?.lang), mode };
  if (validCoordinates(data?.lat, data?.lng)) {
    // ~11 km: enough to rank nearby results, coarse enough to share cache
    // entries and to say nothing precise about where the user is.
    input.biasLat = Math.round(data.lat * 10) / 10;
    input.biasLng = Math.round(data.lng * 10) / 10;
  }
  if (typeof data?.sessionToken === 'string' && TOKEN_RE.test(data.sessionToken)) {
    input.sessionToken = data.sessionToken;
  }
  return input;
}

// ── Rate limit (per instance, no I/O) ───────────────────────────────────────

const windows = new Map<string, { start: number; count: number }>();

/** Fixed one-minute window per user; throws RESOURCE_EXHAUSTED past the limit. */
export function checkRateLimit(uid: string, now: number = deps.now()): void {
  const w = windows.get(uid);
  if (!w || now - w.start >= 60_000) {
    if (windows.size > 50_000) windows.clear(); // bound memory on a hot instance
    windows.set(uid, { start: now, count: 1 });
    return;
  }
  w.count += 1;
  if (w.count > PER_MINUTE_LIMIT) {
    throw new AppError('RATE_LIMITED', 'Too many searches. Please wait a moment.', 429, { reason: 'RATE_LIMITED' });
  }
}

// ── Cache (per instance LRU with TTL) ───────────────────────────────────────

const cache = new Map<string, { at: number; ttl: number; value: unknown }>();

function cacheGet<T>(key: string): T | undefined {
  const hit = cache.get(key);
  if (!hit) return undefined;
  if (deps.now() - hit.at > hit.ttl) { cache.delete(key); return undefined; }
  cache.delete(key); cache.set(key, hit); // refresh LRU position
  return hit.value as T;
}

function cacheSet(key: string, value: unknown, ttl: number) {
  if (cache.size >= CACHE_MAX) cache.delete(cache.keys().next().value as string);
  cache.set(key, { at: deps.now(), ttl, value });
}

/** Test hook. */
export function _resetState() { cache.clear(); windows.clear(); }

export function searchCacheKey(provider: Provider, i: SearchInput): string {
  const bias = i.biasLat !== undefined ? `${i.biasLat},${i.biasLng}` : '-';
  return `s|${provider}|${i.mode}|${i.lang}|${bias}|${normalizeQuery(i.query)}`;
}

// ── Photon adapter ──────────────────────────────────────────────────────────

const str = (v: unknown): string => (typeof v === 'string' ? v.trim() : '');
const firstNonEmpty = (v: unknown[]): string => v.map(str).find((s) => s.length > 0) ?? '';

/** The city a Photon feature belongs to (the feature itself for a city). */
function photonCity(p: any): string {
  const t = str(p?.type);
  if (t === 'city' || (str(p?.osm_key) === 'place' && ['city', 'town', 'village'].includes(str(p?.osm_value)))) {
    return firstNonEmpty([p?.name, p?.city]);
  }
  return firstNonEmpty([p?.city, p?.town, p?.village, p?.locality, p?.county, p?.state]);
}

export function photonFeatureToSuggestion(f: any): Suggestion | null {
  const p = f?.properties ?? {};
  const coords = f?.geometry?.coordinates;
  if (!Array.isArray(coords) || coords.length < 2) return null;
  const [lng, lat] = coords;
  if (!validCoordinates(lat, lng)) return null;
  const street = [str(p.street), str(p.housenumber)].filter(Boolean).join(' ');
  const name = str(p.name);
  const primary = name || street;
  if (!primary) return null;
  const city = photonCity(p);
  const country = str(p.country);
  const cityLine = [str(p.postcode), city !== primary ? city : ''].filter(Boolean).join(' ');
  const secondary = [
    name && street && street !== name ? street : '',
    cityLine,
    str(p.state) !== city && str(p.state) !== primary ? str(p.state) : '',
    country !== primary ? country : '',
  ].filter(Boolean).join(', ');
  return {
    id: p.osm_id != null ? `osm:${str(p.osm_type)}${p.osm_id}` : `osm:${lat},${lng}`,
    primary,
    secondary,
    lat,
    lng,
    city,
    country,
    countryCode: str(p.countrycode).toUpperCase(),
  };
}

function dedupe(list: Suggestion[]): Suggestion[] {
  const seen = new Set<string>();
  const out: Suggestion[] = [];
  for (const s of list) {
    const k = `${s.primary}|${s.secondary}`.toLowerCase();
    if (seen.has(k)) continue;
    seen.add(k);
    out.push(s);
    if (out.length >= MAX_RESULTS) break;
  }
  return out;
}

function photonLang(lang: string): string {
  const base = lang.slice(0, 2);
  return PHOTON_LANGS.has(base) ? base : 'en';
}

export async function photonSearch(i: SearchInput): Promise<Suggestion[]> {
  const params = new URLSearchParams({ q: i.query, limit: String(MAX_RESULTS + 4), lang: 'en' });
  if (i.biasLat !== undefined) {
    params.set('lat', String(i.biasLat));
    params.set('lon', String(i.biasLng));
  }
  if (i.mode === 'city') params.append('layer', 'city');
  const res = await deps.fetchJson(`${PHOTON}/api/?${params.toString()}`, {
    headers: { Accept: 'application/json', 'User-Agent': USER_AGENT },
  });
  if (!res.ok) throw new Error(`photon ${res.status}`);
  const feats: any[] = Array.isArray(res.body?.features) ? res.body.features : [];
  return dedupe(feats.map(photonFeatureToSuggestion).filter((s): s is Suggestion => s !== null));
}

export async function photonReverse(lat: number, lng: number, lang: string): Promise<Place | null> {
  const params = new URLSearchParams({ lat: String(lat), lon: String(lng), limit: '1', lang: photonLang(lang) });
  const res = await deps.fetchJson(`${PHOTON}/reverse?${params.toString()}`, {
    headers: { Accept: 'application/json', 'User-Agent': USER_AGENT },
  });
  if (!res.ok) throw new Error(`photon ${res.status}`);
  const f = Array.isArray(res.body?.features) ? res.body.features[0] : null;
  const s = f ? photonFeatureToSuggestion(f) : null;
  if (!s) return null;
  return {
    address: [s.primary, s.secondary].filter(Boolean).join(', '),
    // The pin the user placed, not the feature's centroid.
    lat,
    lng,
    city: s.city,
    country: s.country,
    countryCode: s.countryCode,
  };
}

// ── Google adapter (Places API New + Geocoding) ─────────────────────────────

export async function googleSearch(i: SearchInput, key: string): Promise<Suggestion[]> {
  const body: any = { input: i.query, languageCode: i.lang };
  if (i.sessionToken) body.sessionToken = i.sessionToken;
  if (i.biasLat !== undefined) {
    body.locationBias = { circle: { center: { latitude: i.biasLat, longitude: i.biasLng }, radius: BIAS_RADIUS_M } };
  }
  if (i.mode === 'city') body.includedPrimaryTypes = ['(cities)'];
  const res = await deps.fetchJson('https://places.googleapis.com/v1/places:autocomplete', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-Goog-Api-Key': key },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`google autocomplete ${res.status}`);
  const list: any[] = Array.isArray(res.body?.suggestions) ? res.body.suggestions : [];
  const out: Suggestion[] = [];
  for (const s of list) {
    const p = s?.placePrediction;
    const placeId = str(p?.placeId);
    if (!placeId) continue;
    const primary = firstNonEmpty([p?.structuredFormat?.mainText?.text, p?.text?.text]);
    if (!primary) continue;
    out.push({
      id: `g:${placeId}`,
      placeId,
      primary,
      secondary: str(p?.structuredFormat?.secondaryText?.text),
      city: '',
      country: '',
      countryCode: '',
    });
  }
  return dedupe(out);
}

/** City + country (+ ISO code) from Google address components (New or legacy shape). */
export function googleComponents(components: any[]): { city: string; country: string; countryCode: string } {
  let city = '';
  let admin2 = '';
  let admin1 = '';
  let country = '';
  let countryCode = '';
  for (const c of Array.isArray(components) ? components : []) {
    const types: string[] = Array.isArray(c?.types) ? c.types : [];
    const long = firstNonEmpty([c?.longText, c?.long_name]);
    const short = firstNonEmpty([c?.shortText, c?.short_name]);
    if (!city && (types.includes('locality') || types.includes('postal_town'))) city = long;
    if (!admin2 && types.includes('administrative_area_level_2')) admin2 = long;
    if (!admin1 && types.includes('administrative_area_level_1')) admin1 = long;
    if (!country && types.includes('country')) { country = long; countryCode = short.toUpperCase(); }
  }
  return { city: city || admin2 || admin1, country, countryCode };
}

export async function googleDetails(placeId: string, key: string, sessionToken?: string): Promise<Place | null> {
  const params = new URLSearchParams({ languageCode: 'en' });
  if (sessionToken) params.set('sessionToken', sessionToken);
  const res = await deps.fetchJson(
    `https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}?${params.toString()}`, {
      headers: {
        'X-Goog-Api-Key': key,
        'X-Goog-FieldMask': 'id,formattedAddress,location,addressComponents',
      },
    });
  if (!res.ok) throw new Error(`google details ${res.status}`);
  const b = res.body ?? {};
  const lat = b?.location?.latitude;
  const lng = b?.location?.longitude;
  if (!validCoordinates(lat, lng)) return null;
  return { address: str(b.formattedAddress), lat, lng, placeId, ...googleComponents(b.addressComponents) };
}

export async function googleReverse(lat: number, lng: number, lang: string, key: string): Promise<Place | null> {
  const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lng}`
    + `&language=${encodeURIComponent(lang)}&key=${encodeURIComponent(key)}`;
  const res = await deps.fetchJson(url, { headers: { Accept: 'application/json' } });
  if (!res.ok || res.body?.status !== 'OK' || !Array.isArray(res.body.results) || !res.body.results.length) return null;
  const first = res.body.results[0];
  // City/country from every result, like reverseGeocodeCoarse.
  const all = res.body.results.flatMap((r: any) => r?.address_components ?? []);
  return { address: str(first?.formatted_address), lat, lng, placeId: str(first?.place_id) || undefined, ...googleComponents(all) };
}

// ── Handlers ────────────────────────────────────────────────────────────────

async function provider(): Promise<{ name: Provider; key: string | null }> {
  const key = await deps.placesKey();
  return key ? { name: 'google', key } : { name: 'photon', key: null };
}

export async function handleSearchAddress(request: any): Promise<{ success: true; provider: Provider; suggestions: Suggestion[] }> {
  const uid = requireUid(request);
  const input = parseSearchInput(request.data);
  checkRateLimit(uid);
  const p = await provider();
  const ck = searchCacheKey(p.name, input);
  const cached = cacheGet<Suggestion[]>(ck);
  if (cached) return { success: true, provider: p.name, suggestions: cached };
  await deps.quota(uid);
  let suggestions: Suggestion[];
  try {
    suggestions = p.name === 'google' ? await googleSearch(input, p.key!) : await photonSearch(input);
  } catch (e: any) {
    console.warn(`searchAddress: ${p.name} failed: ${e?.message ?? e}`);
    throw new AppError('UNAVAILABLE', 'Address search is temporarily unavailable.', 503, { reason: 'PROVIDER_UNAVAILABLE' });
  }
  cacheSet(ck, suggestions, SEARCH_TTL_MS);
  return { success: true, provider: p.name, suggestions };
}

export async function handleResolvePlace(request: any): Promise<{ success: true; place: Place | null }> {
  const uid = requireUid(request);
  const placeId = typeof request.data?.placeId === 'string' ? request.data.placeId.trim() : '';
  if (!PLACE_ID_RE.test(placeId)) throw new AppError('INVALID_ARGUMENT', 'placeId is required', 400);
  const token = typeof request.data?.sessionToken === 'string' && TOKEN_RE.test(request.data.sessionToken)
    ? request.data.sessionToken : undefined;
  checkRateLimit(uid);
  const ck = `p|${placeId}`;
  const cached = cacheGet<Place | null>(ck);
  if (cached !== undefined) return { success: true, place: cached };
  const key = await deps.placesKey();
  if (!key) throw new AppError('UNAVAILABLE', 'Place details are not available.', 503, { reason: 'PROVIDER_UNAVAILABLE' });
  await deps.quota(uid);
  let place: Place | null;
  try {
    place = await googleDetails(placeId, key, token);
  } catch (e: any) {
    console.warn(`resolvePlace failed: ${e?.message ?? e}`);
    throw new AppError('UNAVAILABLE', 'Address search is temporarily unavailable.', 503, { reason: 'PROVIDER_UNAVAILABLE' });
  }
  cacheSet(ck, place, PLACE_TTL_MS);
  return { success: true, place };
}

/** 5 decimals (~1 m): precise enough for a meeting point, stable for caching. */
export const precise = (v: number) => Math.round(v * 1e5) / 1e5;

export async function handleReverseGeocode(request: any): Promise<{ success: true; place: Place | null }> {
  const uid = requireUid(request);
  const { lat, lng } = request.data ?? {};
  if (!validCoordinates(lat, lng)) throw new AppError('INVALID_ARGUMENT', 'lat/lng are required', 400);
  const lang = normalizeLang(request.data?.lang);
  checkRateLimit(uid);
  const la = precise(lat);
  const lo = precise(lng);
  const gKey = await deps.geocodingKey();
  const ck = `r|${gKey ? 'google' : 'photon'}|${lang}|${la},${lo}`;
  const cached = cacheGet<Place | null>(ck);
  if (cached !== undefined) return { success: true, place: cached };
  await deps.quota(uid);
  let place: Place | null = null;
  try {
    place = gKey ? await googleReverse(la, lo, lang, gKey) : await photonReverse(la, lo, lang);
  } catch (e: any) {
    // A dropped pin is still a valid answer without an address.
    console.warn(`reverseGeocode failed: ${e?.message ?? e}`);
    return { success: true, place: null };
  }
  cacheSet(ck, place, PLACE_TTL_MS);
  return { success: true, place };
}

const opts = { memory: '512MiB' as const, timeoutSeconds: 20 };

export const searchAddress = onCall(opts, async (request) => {
  try { return await handleSearchAddress(request); } catch (e) { throw handleError(e); }
});

export const resolvePlace = onCall(opts, async (request) => {
  try { return await handleResolvePlace(request); } catch (e) { throw handleError(e); }
});

export const reverseGeocode = onCall(opts, async (request) => {
  try { return await handleReverseGeocode(request); } catch (e) { throw handleError(e); }
});
