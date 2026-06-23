/**
 * Geoapify attractions ingester → `external_events` (source: 'geoapify').
 *
 * A free, commercial-safe alternative to Tiqets for museums, tourist attractions
 * and theme/amusement parks. Geoapify Places (OpenStreetMap-based) supplies the
 * POIs (name, category, coordinates, city/country); Wikipedia/Wikidata enriches
 * each notable POI with a description + image (Geoapify itself returns no photos
 * or reviews). No per-user calls — a scheduled run upserts a bounded pool into
 * `external_events`; the app reads that collection cache-first and scales to
 * millions of users. Reviews are not available free, so rating/reviewCount stay
 * 0 and users add their own in-app reviews.
 *
 * Key from the GEOAPIFY_API_KEY secret; no-ops until it's set, so it deploys
 * safely beforehand. Does NOT touch the native `events` collection.
 *
 * Free tier: ~3,000 requests/day. This run makes ~1 Places call per city plus
 * one enrichment call per notable POI — a few hundred to ~2k per run, well under
 * the cap (and only on the schedule, never per user).
 */

import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';
import { buildSourceIndex } from './build_index';
import { geohashEncode } from './geohash';

const db = admin.firestore();
const COLLECTION = 'external_events';
const GEOAPIFY_API_KEY = defineSecret('GEOAPIFY_API_KEY');

// Geoapify categories: museums, tourist attractions/sights, theme & amusement
// parks, plus city parks and national parks.
const CATEGORIES = [
  'entertainment.museum',
  'tourism.attraction',
  'tourism.sights',
  'entertainment.theme_park',
  'leisure.park',
  'national_park',
].join(',');

const SEARCH_RADIUS_M = 30000; // 30 km around each city centre
const PLACES_PER_CITY = 200; // Geoapify page size (max 500 on free tier)
const KEEP_PER_CITY = 10; // top N notable POIs kept per city
const CITY_LIMIT = 10000; // effectively all cities in the city_coordinates table
const CITY_FETCH_CONCURRENCY = 8; // parallel Geoapify Places calls

// Always covered (prepended), so major cities are present even if absent from /
// late in the city_coordinates table. Country names match the other sources.
const GUARANTEED_CITIES: { name: string; lat: number; lng: number; country: string }[] = [
  { name: 'New York', lat: 40.7128, lng: -74.006, country: 'United States' },
  { name: 'Los Angeles', lat: 34.0522, lng: -118.2437, country: 'United States' },
  { name: 'Sao Paulo', lat: -23.5505, lng: -46.6333, country: 'Brazil' },
  { name: 'Rio de Janeiro', lat: -22.9068, lng: -43.1729, country: 'Brazil' },
  { name: 'Paris', lat: 48.8566, lng: 2.3522, country: 'France' },
  { name: 'Rome', lat: 41.9028, lng: 12.4964, country: 'Italy' },
  { name: 'Milan', lat: 45.4642, lng: 9.19, country: 'Italy' },
  { name: 'Madrid', lat: 40.4168, lng: -3.7038, country: 'Spain' },
  { name: 'London', lat: 51.5074, lng: -0.1278, country: 'United Kingdom' },
  { name: 'Berlin', lat: 52.52, lng: 13.405, country: 'Germany' },
];

// Top tourism cities worldwide with centre coordinates + ISO-2 country code.
// Bounded list → bounded API usage; expand freely (each adds ~1 Places call).
const CITIES: { name: string; lat: number; lng: number; cc: string }[] = [
  { name: 'Paris', lat: 48.8566, lng: 2.3522, cc: 'FR' },
  { name: 'London', lat: 51.5074, lng: -0.1278, cc: 'GB' },
  { name: 'Rome', lat: 41.9028, lng: 12.4964, cc: 'IT' },
  { name: 'Barcelona', lat: 41.3874, lng: 2.1686, cc: 'ES' },
  { name: 'Madrid', lat: 40.4168, lng: -3.7038, cc: 'ES' },
  { name: 'Amsterdam', lat: 52.3676, lng: 4.9041, cc: 'NL' },
  { name: 'Berlin', lat: 52.52, lng: 13.405, cc: 'DE' },
  { name: 'Vienna', lat: 48.2082, lng: 16.3738, cc: 'AT' },
  { name: 'Prague', lat: 50.0755, lng: 14.4378, cc: 'CZ' },
  { name: 'Lisbon', lat: 38.7223, lng: -9.1393, cc: 'PT' },
  { name: 'Athens', lat: 37.9838, lng: 23.7275, cc: 'GR' },
  { name: 'Istanbul', lat: 41.0082, lng: 28.9784, cc: 'TR' },
  { name: 'Florence', lat: 43.7696, lng: 11.2558, cc: 'IT' },
  { name: 'Venice', lat: 45.4408, lng: 12.3155, cc: 'IT' },
  { name: 'Munich', lat: 48.1351, lng: 11.582, cc: 'DE' },
  { name: 'Budapest', lat: 47.4979, lng: 19.0402, cc: 'HU' },
  { name: 'Dublin', lat: 53.3498, lng: -6.2603, cc: 'IE' },
  { name: 'Copenhagen', lat: 55.6761, lng: 12.5683, cc: 'DK' },
  { name: 'Stockholm', lat: 59.3293, lng: 18.0686, cc: 'SE' },
  { name: 'Zurich', lat: 47.3769, lng: 8.5417, cc: 'CH' },
  { name: 'Brussels', lat: 50.8503, lng: 4.3517, cc: 'BE' },
  { name: 'New York', lat: 40.7128, lng: -74.006, cc: 'US' },
  { name: 'Los Angeles', lat: 34.0522, lng: -118.2437, cc: 'US' },
  { name: 'San Francisco', lat: 37.7749, lng: -122.4194, cc: 'US' },
  { name: 'Las Vegas', lat: 36.1699, lng: -115.1398, cc: 'US' },
  { name: 'Orlando', lat: 28.5383, lng: -81.3792, cc: 'US' }, // theme parks
  { name: 'Chicago', lat: 41.8781, lng: -87.6298, cc: 'US' },
  { name: 'Washington', lat: 38.9072, lng: -77.0369, cc: 'US' },
  { name: 'Toronto', lat: 43.6532, lng: -79.3832, cc: 'CA' },
  { name: 'Mexico City', lat: 19.4326, lng: -99.1332, cc: 'MX' },
  { name: 'Rio de Janeiro', lat: -22.9068, lng: -43.1729, cc: 'BR' },
  { name: 'Sao Paulo', lat: -23.5505, lng: -46.6333, cc: 'BR' },
  { name: 'Buenos Aires', lat: -34.6037, lng: -58.3816, cc: 'AR' },
  { name: 'Lima', lat: -12.0464, lng: -77.0428, cc: 'PE' },
  { name: 'Dubai', lat: 25.2048, lng: 55.2708, cc: 'AE' },
  { name: 'Cairo', lat: 30.0444, lng: 31.2357, cc: 'EG' },
  { name: 'Marrakesh', lat: 31.6295, lng: -7.9811, cc: 'MA' },
  { name: 'Cape Town', lat: -33.9249, lng: 18.4241, cc: 'ZA' },
  { name: 'Tokyo', lat: 35.6762, lng: 139.6503, cc: 'JP' },
  { name: 'Kyoto', lat: 35.0116, lng: 135.7681, cc: 'JP' },
  { name: 'Osaka', lat: 34.6937, lng: 135.5023, cc: 'JP' }, // theme parks
  { name: 'Seoul', lat: 37.5665, lng: 126.978, cc: 'KR' },
  { name: 'Bangkok', lat: 13.7563, lng: 100.5018, cc: 'TH' },
  { name: 'Singapore', lat: 1.3521, lng: 103.8198, cc: 'SG' },
  { name: 'Hong Kong', lat: 22.3193, lng: 114.1694, cc: 'HK' },
  { name: 'Beijing', lat: 39.9042, lng: 116.4074, cc: 'CN' },
  { name: 'Shanghai', lat: 31.2304, lng: 121.4737, cc: 'CN' },
  { name: 'Kuala Lumpur', lat: 3.139, lng: 101.6869, cc: 'MY' },
  { name: 'Bali', lat: -8.4095, lng: 115.1889, cc: 'ID' },
  { name: 'Sydney', lat: -33.8688, lng: 151.2093, cc: 'AU' },
  { name: 'Melbourne', lat: -37.8136, lng: 144.9631, cc: 'AU' },
  { name: 'Auckland', lat: -36.8485, lng: 174.7633, cc: 'NZ' },
  { name: 'Jerusalem', lat: 31.7683, lng: 35.2137, cc: 'IL' },
  { name: 'Reykjavik', lat: 64.1466, lng: -21.9426, cc: 'IS' },
];

type Doc = { id: string; data: Record<string, unknown> };

async function upsertAll(docs: Doc[]): Promise<void> {
  let batch = db.batch();
  let ops = 0;
  const commits: Promise<unknown>[] = [];
  const now = admin.firestore.FieldValue.serverTimestamp();
  for (const { id, data } of docs) {
    batch.set(db.collection(COLLECTION).doc(id), { ...data, updatedAt: now }, { merge: true });
    if (++ops >= 400) {
      commits.push(batch.commit());
      batch = db.batch();
      ops = 0;
    }
  }
  if (ops > 0) commits.push(batch.commit());
  await Promise.all(commits);
}

/// Delete all external_events for a source, so a re-feed replaces (not merges)
/// the previous set. Batched; loops until empty.
async function clearSource(source: string): Promise<number> {
  let total = 0;
  for (;;) {
    const snap = await db
      .collection(COLLECTION)
      .where('source', '==', source)
      .limit(400)
      .get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    total += snap.size;
    if (snap.size < 400) break;
  }
  console.log(`clearSource(${source}): deleted ${total}`);
  return total;
}

/// Per-country counts → `external_country_stats/{source}_{country}` so the globe
/// can show markers cheaply.
async function writeCountryStats(docs: Doc[], source: string): Promise<void> {
  const counts: Record<string, number> = {};
  for (const d of docs) {
    const c = d.data.country as string | undefined;
    if (c) counts[c] = (counts[c] || 0) + 1;
  }
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();
  for (const [country, count] of Object.entries(counts)) {
    batch.set(
      db.collection('external_country_stats').doc(`${source}_${country}`),
      { source, country, count, updatedAt: now },
      { merge: true }
    );
  }
  await batch.commit();
}

/// Human-readable category from Geoapify's category tags.
function categoryLabel(cats: string[]): string {
  if (cats.some((c) => c.includes('theme_park') || c.includes('amusement'))) return 'theme_park';
  if (cats.some((c) => c.includes('museum'))) return 'museum';
  if (cats.some((c) => c.includes('national_park'))) return 'national_park';
  if (cats.some((c) => c.includes('park'))) return 'park';
  return 'attraction';
}

/// Fetch one city's notable POIs from Geoapify Places. Keeps only POIs that are
/// notable enough to enrich (have a Wikipedia or Wikidata reference) so every
/// card ends up with a description + image.
async function fetchCity(
  key: string,
  city: { name: string; lat: number; lng: number; country: string }
): Promise<Doc[]> {
  try {
    const url =
      `https://api.geoapify.com/v2/places?categories=${CATEGORIES}` +
      `&filter=circle:${city.lng},${city.lat},${SEARCH_RADIUS_M}` +
      `&bias=proximity:${city.lng},${city.lat}` +
      `&limit=${PLACES_PER_CITY}&apiKey=${key}`;
    const res = await fetch(url);
    if (!res.ok) {
      console.error(`Geoapify ${city.name} HTTP ${res.status}`);
      return [];
    }
    const json: any = await res.json();
    const features: any[] = json.features || [];
    const docs: Doc[] = [];
    for (const f of features) {
      const p = f.properties || {};
      const raw = (p.datasource && p.datasource.raw) || {};
      const name: string | undefined = p.name || raw['name:en'] || raw.name;
      if (!name) continue;
      const wikidata: string | undefined = raw.wikidata;
      const wikipedia: string | undefined = raw.wikipedia; // "lang:Article Title"
      // Notability filter: require a wiki reference (so we can enrich it).
      if (!wikidata && !wikipedia) continue;
      const lat = p.lat ?? f.geometry?.coordinates?.[1] ?? null;
      const lng = p.lon ?? f.geometry?.coordinates?.[0] ?? null;
      const id = wikidata ? `geoapify_wd_${wikidata}` : `geoapify_${p.place_id}`;
      const website: string | undefined = raw.website || raw['contact:website'] || p.website;
      docs.push({
        id,
        data: {
          source: 'geoapify',
          externalId: wikidata || String(p.place_id || ''),
          title: name,
          description: null, // filled by enrichment
          imageUrl: null, // filled by enrichment
          category: categoryLabel(p.categories || []),
          city: p.city || city.name,
          country: city.country, // country name (consistent with other sources)
          // No free reviews → 0 (kept as a number so orderBy includes the doc).
          rating: 0,
          reviewCount: 0,
          lat,
          lng,
          geohash:
            typeof lat === 'number' && typeof lng === 'number'
              ? geohashEncode(lat, lng)
              : null,
          // Link fields are finalized in enrichment. `website` = official site
          // (OSM), `bookingUrl` = best primary link, `wikidataUrl` = WD page.
          website: website || null,
          bookingUrl: null,
          wikidataUrl: null,
          _wikidata: wikidata || null,
          _wikipedia: wikipedia || null,
          fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      });
      if (docs.length >= KEEP_PER_CITY) break;
    }
    return docs;
  } catch (e) {
    console.error(`Geoapify ${city.name} failed`, e);
    return [];
  }
}

// Wikimedia asks for a descriptive UA with contact info; a generic one gets
// throttled hard (which is why per-item enrichment only filled a few images).
const WIKI_HEADERS = {
  'User-Agent':
    'GreenGoApp/1.0 (https://greengo-chat.web.app; places ingester) firebase-functions',
};

function commonsFilePath(file: string): string {
  return `https://commons.wikimedia.org/wiki/Special:FilePath/${encodeURIComponent(
    file
  )}?width=800`;
}

type WdInfo = { desc?: string; file?: string; title?: string; lang?: string };

/// Batch-resolve Wikidata entities (≤50 per call) → English description, P18
/// image file, and best Wikipedia sitelink. ~43 calls for 2k items instead of
/// 2k, so Wikimedia doesn't rate-limit us.
async function wikidataBatch(ids: string[]): Promise<Map<string, WdInfo>> {
  const out = new Map<string, WdInfo>();
  for (let i = 0; i < ids.length; i += 50) {
    const chunk = ids.slice(i, i + 50);
    try {
      const url =
        `https://www.wikidata.org/w/api.php?action=wbgetentities&format=json` +
        `&props=descriptions%7Cclaims%7Csitelinks&languages=en` +
        `&ids=${chunk.join('%7C')}`;
      const res = await fetch(url, { headers: WIKI_HEADERS });
      if (!res.ok) continue;
      const j: any = await res.json();
      for (const id of chunk) {
        const ent = j.entities?.[id];
        if (!ent) continue;
        const desc = ent.descriptions?.en?.value as string | undefined;
        const file = ent.claims?.P18?.[0]?.mainsnak?.datavalue?.value as
          | string
          | undefined;
        const sl = ent.sitelinks || {};
        let title: string | undefined;
        let lang: string | undefined;
        if (sl.enwiki) {
          title = sl.enwiki.title;
          lang = 'en';
        } else {
          const k = Object.keys(sl).find(
            (x) => x.endsWith('wiki') && !x.startsWith('commons')
          );
          if (k) {
            title = sl[k].title;
            lang = k.replace(/wiki$/, '');
          }
        }
        out.set(id, { desc, file, title, lang });
      }
    } catch (e) {
      console.error('wikidataBatch chunk failed', e);
    }
  }
  return out;
}

/// Batch Wikipedia pageimages + intro extract for one language (≤50 titles per
/// call). Returns requestedTitle → { img, extract }, resolving normalization
/// and redirects so the lookup matches the title we asked for.
async function wikipediaBatch(
  lang: string,
  titles: string[]
): Promise<Map<string, { img?: string; extract?: string }>> {
  const out = new Map<string, { img?: string; extract?: string }>();
  for (let i = 0; i < titles.length; i += 50) {
    const chunk = titles.slice(i, i + 50);
    try {
      const url =
        `https://${lang}.wikipedia.org/w/api.php?action=query&format=json` +
        `&prop=pageimages%7Cextracts&piprop=thumbnail&pithumbsize=800` +
        `&exintro=1&explaintext=1&redirects=1` +
        `&titles=${chunk.map((t) => encodeURIComponent(t)).join('%7C')}`;
      const res = await fetch(url, { headers: WIKI_HEADERS });
      if (!res.ok) continue;
      const j: any = await res.json();
      const q = j.query || {};
      const remap = new Map<string, string>();
      for (const n of q.normalized || []) remap.set(n.from, n.to);
      for (const r of q.redirects || []) remap.set(r.from, r.to);
      const byFinal = new Map<string, { img?: string; extract?: string }>();
      for (const pid of Object.keys(q.pages || {})) {
        const pg = q.pages[pid];
        if (pg.title) {
          byFinal.set(pg.title, {
            img: pg.thumbnail?.source,
            extract: pg.extract,
          });
        }
      }
      for (const t of chunk) {
        let f = t;
        if (remap.has(f)) f = remap.get(f)!; // normalization
        if (remap.has(f)) f = remap.get(f)!; // then redirect
        const data = byFinal.get(f) || byFinal.get(t);
        if (data && (data.img || data.extract)) out.set(t, data);
      }
    } catch (e) {
      console.error(`wikipediaBatch ${lang} chunk failed`, e);
    }
  }
  return out;
}

/// Real photo near the POI from Wikimedia Commons (no API key) — fallback for
/// places without a Wikidata P18 / Wikipedia image (e.g. many parks).
async function commonsGeoImage(lat: number, lng: number): Promise<string | null> {
  try {
    const url =
      `https://commons.wikimedia.org/w/api.php?action=query&format=json` +
      `&list=geosearch&gsnamespace=6&gsradius=1000&gslimit=8` +
      `&gscoord=${lat}%7C${lng}`;
    const res = await fetch(url, { headers: WIKI_HEADERS });
    if (!res.ok) return null;
    const j: any = await res.json();
    const hits: any[] = j.query?.geosearch || [];
    for (const h of hits) {
      const t: string = h.title || '';
      if (!/^File:.+\.(jpe?g|png)$/i.test(t)) continue;
      return commonsFilePath(t.replace(/^File:/, ''));
    }
    return null;
  } catch (_) {
    return null;
  }
}

/// Enrich all docs with descriptions + images using batched Wikimedia calls
/// (avoids the rate-limiting that throttled per-item enrichment), then a Commons
/// geo-photo fallback for the remainder. Mutates each doc.data in place.
async function enrichAll(all: Doc[]): Promise<void> {
  // Phase 1 — Wikidata batch (P18 image, en description, Wikipedia sitelink).
  const wdIds = [
    ...new Set(
      all.map((d) => d.data._wikidata as string | null).filter(Boolean)
    ),
  ] as string[];
  const wd = await wikidataBatch(wdIds);

  // Phase 2 — choose a Wikipedia article per doc (OSM tag, else WD sitelink)
  // and batch-fetch images/extracts per language.
  const titlesByLang = new Map<string, Set<string>>();
  for (const doc of all) {
    const d = doc.data;
    let lang: string | undefined;
    let title: string | undefined;
    const wp = d._wikipedia as string | null;
    if (wp && wp.includes(':')) {
      lang = wp.slice(0, wp.indexOf(':'));
      title = wp.slice(wp.indexOf(':') + 1);
    } else if (d._wikidata) {
      const info = wd.get(d._wikidata as string);
      if (info?.title && info.lang) {
        lang = info.lang;
        title = info.title;
      }
    }
    if (lang && title) {
      d._wpLang = lang;
      d._wpTitle = title;
      if (!titlesByLang.has(lang)) titlesByLang.set(lang, new Set());
      titlesByLang.get(lang)!.add(title);
    }
  }
  const wpByLang = new Map<
    string,
    Map<string, { img?: string; extract?: string }>
  >();
  for (const [lang, set] of titlesByLang) {
    wpByLang.set(lang, await wikipediaBatch(lang, [...set]));
  }

  // Phase 3 — assign description + image; collect the ones still missing a photo.
  const needGeo: Doc[] = [];
  for (const doc of all) {
    const d = doc.data;
    const info = d._wikidata ? wd.get(d._wikidata as string) : undefined;
    const wpd =
      d._wpLang && d._wpTitle
        ? wpByLang.get(d._wpLang as string)?.get(d._wpTitle as string)
        : undefined;
    const desc = wpd?.extract || info?.desc;
    // Wikipedia thumbnails are always raster. Wikidata P18 can be SVG/TIFF/etc
    // which Flutter's network image can't decode (renders blank) — only accept
    // raster P18 files; anything else falls through to the Commons geo-photo.
    const p18 =
      info?.file && /\.(jpe?g|png|webp|gif)$/i.test(info.file)
        ? commonsFilePath(info.file)
        : undefined;
    const img = wpd?.img || p18;
    if (desc && !d.description) d.description = desc;
    if (img && !d.imageUrl) d.imageUrl = img;
    if (!d.imageUrl) needGeo.push(doc);
  }

  // Phase 4 — Commons geo-photo for the remainder (bounded concurrency).
  await pool(needGeo, 4, async (doc) => {
    const d = doc.data;
    if (typeof d.lat === 'number' && typeof d.lng === 'number') {
      const g = await commonsGeoImage(d.lat as number, d.lng as number);
      if (g) d.imageUrl = g;
    }
  });

  // Finalize the link fields + clean up private fields. Primary link priority:
  // official website → Wikipedia article → Wikidata page → Google Maps.
  for (const doc of all) {
    const d = doc.data;
    const lang = d._wpLang as string | undefined;
    const title = d._wpTitle as string | undefined;
    const wikipediaUrl =
      lang && title
        ? `https://${lang}.wikipedia.org/wiki/${encodeURIComponent(title)}`
        : null;
    const wikidataUrl = d._wikidata
      ? `https://www.wikidata.org/wiki/${d._wikidata}`
      : null;
    const mapsUrl = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(
      `${d.title} ${d.city || ''}`.trim()
    )}`;
    d.wikidataUrl = wikidataUrl;
    d.bookingUrl =
      (d.website as string | null) || wikipediaUrl || wikidataUrl || mapsUrl;
    delete d._wikidata;
    delete d._wikipedia;
    delete d._wpLang;
    delete d._wpTitle;
  }
}

/// Run [tasks] with bounded concurrency.
async function pool<T>(items: T[], size: number, fn: (t: T) => Promise<void>): Promise<void> {
  for (let i = 0; i < items.length; i += size) {
    await Promise.all(items.slice(i, i + size).map(fn));
  }
}

/// The cities to scan: up to [CITY_LIMIT] from the `city_coordinates` table
/// (so we only use cities we already have coordinates for). Falls back to the
/// small embedded list if the table is empty.
async function loadCities(): Promise<
  { name: string; lat: number; lng: number; country: string }[]
> {
  // Guaranteed majors first so they're always covered (and processed first when
  // the run is chunked).
  const out: { name: string; lat: number; lng: number; country: string }[] = [
    ...GUARANTEED_CITIES,
  ];
  const seen = new Set(out.map((c) => c.name.toLowerCase()));
  try {
    const snap = await db.collection('city_coordinates').limit(CITY_LIMIT).get();
    for (const d of snap.docs) {
      const data = d.data();
      const name = data.city as string | undefined;
      const lat = data.lat as number | undefined;
      const lng = data.lng as number | undefined;
      const country = (data.country as string | undefined) || '';
      if (name && typeof lat === 'number' && typeof lng === 'number') {
        const key = name.toLowerCase();
        if (seen.has(key)) continue;
        seen.add(key);
        out.push({ name, lat, lng, country });
      }
    }
  } catch (e) {
    console.error('loadCities: city_coordinates read failed', e);
  }
  return out;
}

async function runGeoapify(
  key: string,
  opts: { offset?: number; limit?: number } = {}
): Promise<{ cities: number; found: number; saved: number; totalCities: number }> {
  if (!key) {
    console.log('ingestGeoapify: GEOAPIFY_API_KEY not set — skipping.');
    return { cities: 0, found: 0, saved: 0, totalCities: 0 };
  }
  const allCities = await loadCities();
  const totalCities = allCities.length;
  // Process a slice so the free Geoapify tier (3k req/day) can be covered over
  // several runs: ?offset=&limit=. Default = all.
  const offset = opts.offset ?? 0;
  const cities = opts.limit != null
      ? allCities.slice(offset, offset + opts.limit)
      : allCities.slice(offset);
  // Fetch all cities concurrently (bounded); dedupe by doc id across radii.
  const byId = new Map<string, Doc>();
  await pool(cities, CITY_FETCH_CONCURRENCY, async (city) => {
    for (const doc of await fetchCity(key, city)) {
      if (!byId.has(doc.id)) byId.set(doc.id, doc);
    }
  });
  const all = [...byId.values()];
  if (all.length === 0) {
    console.log('ingestGeoapify: no POIs returned.');
    return { cities: cities.length, found: 0, saved: 0, totalCities };
  }
  // Enrich with descriptions + images via batched Wikimedia calls.
  await enrichAll(all);
  // Attractions are only worth showing with a photo → drop the image-less ones
  // so we never store (or render) a blank card.
  const withImage = all.filter((d) => !!d.data.imageUrl);
  await upsertAll(withImage);
  await writeCountryStats(withImage, 'geoapify');
  await buildSourceIndex('geoapify');
  console.log(
    `ingestGeoapify: ${withImage.length}/${all.length} attractions with images ` +
      `saved across ${cities.length} cities (offset ${offset}/${totalCities}).`
  );
  return {
    cities: cities.length,
    found: all.length,
    saved: withImage.length,
    totalCities,
  };
}

// Attractions are static reference data — imported via this manual trigger, not
// on a schedule. The free Geoapify tier is ~3k requests/day, so a large city
// list is imported in chunks (merge, not clear) across days:
//   ?token=<KEY>&count=1            → just report how many cities are in scope
//   ?token=<KEY>&offset=0&limit=2000 → import cities [0,2000)
//   ?token=<KEY>&offset=2000        → import the rest
//   ?token=<KEY>&clear=1&offset=0&limit=2000 → wipe geoapify first, then import
export const runIngestGeoapifyNow = onRequest(
  { timeoutSeconds: 1800, memory: '1GiB', secrets: [GEOAPIFY_API_KEY] },
  monitored('runIngestGeoapifyNow', async (req, res) => {
    const key = GEOAPIFY_API_KEY.value();
    if (!key || req.query.token !== key) {
      res.status(403).send('Forbidden');
      return;
    }
    if (req.query.count) {
      const cities = await loadCities();
      res.status(200).json({ ok: true, totalCities: cities.length });
      return;
    }
    const offset = req.query.offset ? parseInt(req.query.offset as string, 10) : 0;
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : undefined;
    let cleared = 0;
    if (req.query.clear) cleared = await clearSource('geoapify');
    const r = await runGeoapify(key, { offset, limit });
    res.status(200).json({
      ok: true,
      cleared,
      offset,
      processedCities: r.cities,
      totalCities: r.totalCities,
      found: r.found,
      saved: r.saved,
      nextOffset: offset + r.cities,
      done: offset + r.cities >= r.totalCities,
    });
  })
);
