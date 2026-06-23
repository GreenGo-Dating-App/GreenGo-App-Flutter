/**
 * Ticketmaster Discovery ingester → `external_events` (source: 'ticketmaster').
 *
 * Pulls live events (concerts, sports, arts, theater) for the top tourism
 * countries with their exact venue coordinates, so they plot precisely on the
 * map (zoom mini-image pins). Key from TICKETMASTER_API_KEY secret; no-ops until
 * it's set. Mirrors the Viator/Tiqets ingester shape (source-isolated).
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { buildSourceIndex } from './build_index';
import { geohashEncode } from './geohash';

const db = admin.firestore();
const COLLECTION = 'external_events';
const TICKETMASTER_API_KEY = defineSecret('TICKETMASTER_API_KEY');
const PER_COUNTRY = 200;

// Top tourism countries → ISO-2 codes (Ticketmaster filters by countryCode).
const COUNTRY_ISO: Record<string, string> = {
  France: 'FR', Spain: 'ES', 'United States': 'US', Italy: 'IT', Turkey: 'TR',
  Mexico: 'MX', 'United Kingdom': 'GB', Germany: 'DE', Greece: 'GR',
  Austria: 'AT', Japan: 'JP', Thailand: 'TH', Portugal: 'PT',
  Netherlands: 'NL', Croatia: 'HR', 'United Arab Emirates': 'AE', Canada: 'CA',
  Australia: 'AU', China: 'CN', Egypt: 'EG', India: 'IN', Indonesia: 'ID',
  Vietnam: 'VN', Switzerland: 'CH', 'Czech Republic': 'CZ', Poland: 'PL',
  Ireland: 'IE', Morocco: 'MA', 'South Africa': 'ZA', Brazil: 'BR',
  Argentina: 'AR', Peru: 'PE', Iceland: 'IS', Hungary: 'HU', Belgium: 'BE',
  Denmark: 'DK', Sweden: 'SE', Norway: 'NO', Singapore: 'SG', Malaysia: 'MY',
  Philippines: 'PH', 'South Korea': 'KR', 'New Zealand': 'NZ', Israel: 'IL',
  Jordan: 'JO', Cambodia: 'KH', 'Costa Rica': 'CR', Colombia: 'CO',
  Chile: 'CL', 'Saudi Arabia': 'SA',
};

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

async function clearSource(): Promise<number> {
  let total = 0;
  for (;;) {
    const snap = await db
      .collection(COLLECTION)
      .where('source', '==', 'ticketmaster')
      .limit(400)
      .get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    total += snap.size;
    if (snap.size < 400) break;
  }
  return total;
}

async function writeCountryStats(docs: Doc[]): Promise<void> {
  const counts: Record<string, number> = {};
  for (const d of docs) {
    const c = d.data.country as string | undefined;
    if (c) counts[c] = (counts[c] || 0) + 1;
  }
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();
  for (const [country, count] of Object.entries(counts)) {
    batch.set(
      db.collection('external_country_stats').doc(`ticketmaster_${country}`),
      { source: 'ticketmaster', country, count, updatedAt: now },
      { merge: true }
    );
  }
  await batch.commit();
}

function mapEvent(e: any, countryName: string): Doc | null {
  const venue = (e._embedded?.venues || [])[0] || {};
  const loc = venue.location || {};
  const lat = loc.latitude != null ? Number(loc.latitude) : null;
  const lng = loc.longitude != null ? Number(loc.longitude) : null;
  // Largest image.
  let img: string | undefined;
  let bestW = -1;
  for (const im of e.images || []) {
    if ((im.width || 0) > bestW) {
      bestW = im.width || 0;
      img = im.url;
    }
  }
  const price = (e.priceRanges || [])[0] || {};
  return {
    id: `tm_${e.id}`,
    data: {
      source: 'ticketmaster',
      externalId: e.id,
      title: e.name,
      description: e.info ?? null,
      imageUrl: img ?? null,
      category: e.classifications?.[0]?.segment?.name ?? 'event',
      city: venue.city?.name ?? venue.name ?? null,
      country: countryName,
      lat,
      lng,
      geohash:
        typeof lat === 'number' && typeof lng === 'number'
          ? geohashEncode(lat, lng)
          : null,
      fromPrice: price.min != null ? Number(price.min) : null,
      currency: price.currency ?? 'USD',
      rating: 0,
      reviewCount: 0,
      startDate: e.dates?.start?.localDate ?? null,
      bookingUrl: e.url ?? null,
      fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  };
}

async function fetchForCountry(key: string, iso: string, countryName: string): Promise<Doc[]> {
  const docs: Doc[] = [];
  const pageSize = 100;
  for (let page = 0; docs.length < PER_COUNTRY; page++) {
    try {
      const url =
        `https://app.ticketmaster.com/discovery/v2/events.json?apikey=${key}` +
        `&countryCode=${iso}&size=${pageSize}&page=${page}&sort=relevance,desc`;
      const res = await fetch(url);
      if (!res.ok) {
        console.error(`TM ${countryName} HTTP ${res.status} (page ${page})`);
        break;
      }
      const json: any = await res.json();
      const events: any[] = json._embedded?.events || [];
      if (events.length === 0) break;
      for (const e of events) {
        const d = mapEvent(e, countryName);
        if (d) docs.push(d);
      }
      const totalPages = json.page?.totalPages ?? 1;
      if (page + 1 >= totalPages) break;
    } catch (e) {
      console.error(`TM ${countryName} failed (page ${page})`, e);
      break;
    }
  }
  return docs.slice(0, PER_COUNTRY);
}

// Event-dense cities (where Ticketmaster has deep coverage) → adds depth beyond
// the per-country top lists so the feed approaches 5k. {city, country name}.
const TOP_CITIES: { city: string; country: string }[] = [
  // United States
  ...['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix',
    'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'Austin',
    'San Jose', 'Las Vegas', 'Nashville', 'Atlanta', 'Miami', 'Boston',
    'Seattle', 'Denver', 'Washington', 'Detroit', 'Minneapolis', 'Orlando',
    'Tampa', 'Portland', 'Charlotte', 'San Francisco', 'Pittsburgh',
    'St. Louis', 'Sacramento', 'Kansas City', 'Cleveland', 'Columbus',
    'Indianapolis', 'New Orleans', 'Salt Lake City', 'Cincinnati',
    'Baltimore', 'Milwaukee', 'Brooklyn', 'Anaheim']
      .map((c) => ({ city: c, country: 'United States' })),
  // United Kingdom
  ...['London', 'Manchester', 'Birmingham', 'Glasgow', 'Liverpool', 'Leeds',
    'Edinburgh', 'Bristol', 'Cardiff', 'Newcastle', 'Sheffield', 'Nottingham']
      .map((c) => ({ city: c, country: 'United Kingdom' })),
  // Canada
  ...['Toronto', 'Montreal', 'Vancouver', 'Calgary', 'Ottawa', 'Edmonton']
      .map((c) => ({ city: c, country: 'Canada' })),
  // Australia
  ...['Sydney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaide']
      .map((c) => ({ city: c, country: 'Australia' })),
  // Germany
  ...['Berlin', 'Munich', 'Hamburg', 'Cologne', 'Frankfurt', 'Stuttgart']
      .map((c) => ({ city: c, country: 'Germany' })),
  // France
  ...['Paris', 'Lyon', 'Marseille', 'Toulouse', 'Nice']
      .map((c) => ({ city: c, country: 'France' })),
  // Spain
  ...['Madrid', 'Barcelona', 'Valencia', 'Seville']
      .map((c) => ({ city: c, country: 'Spain' })),
  // Italy
  ...['Rome', 'Milan', 'Naples', 'Turin', 'Bologna']
      .map((c) => ({ city: c, country: 'Italy' })),
  // Brazil
  ...['Sao Paulo', 'Rio de Janeiro', 'Brasilia', 'Belo Horizonte', 'Curitiba']
      .map((c) => ({ city: c, country: 'Brazil' })),
  // Others
  { city: 'Amsterdam', country: 'Netherlands' },
  { city: 'Rotterdam', country: 'Netherlands' },
  { city: 'Dublin', country: 'Ireland' },
  { city: 'Mexico City', country: 'Mexico' },
  { city: 'Guadalajara', country: 'Mexico' },
  { city: 'Monterrey', country: 'Mexico' },
  { city: 'Stockholm', country: 'Sweden' },
  { city: 'Oslo', country: 'Norway' },
  { city: 'Copenhagen', country: 'Denmark' },
  { city: 'Brussels', country: 'Belgium' },
  { city: 'Vienna', country: 'Austria' },
  { city: 'Zurich', country: 'Switzerland' },
  { city: 'Warsaw', country: 'Poland' },
  { city: 'Lisbon', country: 'Portugal' },
];

async function fetchForCity(
  key: string,
  city: string,
  countryName: string
): Promise<Doc[]> {
  const docs: Doc[] = [];
  const pageSize = 100;
  for (let page = 0; docs.length < PER_COUNTRY; page++) {
    try {
      const url =
        `https://app.ticketmaster.com/discovery/v2/events.json?apikey=${key}` +
        `&city=${encodeURIComponent(city)}&size=${pageSize}&page=${page}` +
        `&sort=relevance,desc`;
      const res = await fetch(url);
      if (!res.ok) break;
      const json: any = await res.json();
      const events: any[] = json._embedded?.events || [];
      if (events.length === 0) break;
      for (const e of events) {
        const d = mapEvent(e, countryName);
        if (d) docs.push(d);
      }
      const totalPages = json.page?.totalPages ?? 1;
      if (page + 1 >= totalPages) break;
    } catch (_) {
      break;
    }
  }
  return docs;
}

// Cities we guarantee deep coverage for (target ≥ MIN_PER_PRIORITY each). The
// per-city fetch already pages up to PER_COUNTRY (200), so any city with that
// many events on Ticketmaster easily clears the floor; the returned counts show
// where TM simply doesn't have 50 (e.g. sparse markets).
const MIN_PER_PRIORITY = 50;
const PRIORITY_CITIES: {
  city: string; country: string; lat: number; lng: number;
}[] = [
  { city: 'New York', country: 'United States', lat: 40.7128, lng: -74.0060 },
  { city: 'Los Angeles', country: 'United States', lat: 34.0522, lng: -118.2437 },
  { city: 'Sao Paulo', country: 'Brazil', lat: -23.5505, lng: -46.6333 },
  { city: 'Rio de Janeiro', country: 'Brazil', lat: -22.9068, lng: -43.1729 },
  { city: 'Paris', country: 'France', lat: 48.8566, lng: 2.3522 },
  { city: 'Rome', country: 'Italy', lat: 41.9028, lng: 12.4964 },
  { city: 'Milan', country: 'Italy', lat: 45.4642, lng: 9.1900 },
  { city: 'Madrid', country: 'Spain', lat: 40.4168, lng: -3.7038 },
  { city: 'London', country: 'United Kingdom', lat: 51.5074, lng: -0.1278 },
  { city: 'Berlin', country: 'Germany', lat: 52.5200, lng: 13.4050 },
];

/** Geo-radius pull (reliable across regions, unlike the city= text filter). */
async function fetchForGeo(
  key: string,
  lat: number,
  lng: number,
  countryName: string
): Promise<Doc[]> {
  const docs: Doc[] = [];
  const pageSize = 100;
  for (let page = 0; docs.length < PER_COUNTRY; page++) {
    try {
      const url =
        `https://app.ticketmaster.com/discovery/v2/events.json?apikey=${key}` +
        `&latlong=${lat},${lng}&radius=75&unit=km` +
        `&size=${pageSize}&page=${page}&sort=distance,asc`;
      const res = await fetch(url);
      if (!res.ok) break;
      const json: any = await res.json();
      const events: any[] = json._embedded?.events || [];
      if (events.length === 0) break;
      for (const e of events) {
        const d = mapEvent(e, countryName);
        if (d) docs.push(d);
      }
      const totalPages = json.page?.totalPages ?? 1;
      if (page + 1 >= totalPages) break;
    } catch (_) {
      break;
    }
  }
  return docs.slice(0, PER_COUNTRY);
}

/** Targeted pull of just the priority cities; upserts + rebuilds the index. */
async function runPriorityCities(key: string): Promise<Record<string, number>> {
  if (!key) return {};
  const counts: Record<string, number> = {};
  const all: Doc[] = [];
  const seen = new Set<string>();
  for (const { city, country, lat, lng } of PRIORITY_CITIES) {
    // Geo-radius first (reliable), fall back to city= text match.
    let docs = await fetchForGeo(key, lat, lng, country);
    if (docs.length < MIN_PER_PRIORITY) {
      const byName = await fetchForCity(key, city, country);
      const have = new Set(docs.map((d) => d.id));
      for (const d of byName) if (!have.has(d.id)) docs.push(d);
    }
    counts[city] = docs.length;
    for (const d of docs) {
      const k =
        `${(d.data.title as string) || ''}|${(d.data.city as string) || ''}`
          .toLowerCase();
      if (seen.has(k)) continue;
      seen.add(k);
      all.push(d);
    }
    if (docs.length < MIN_PER_PRIORITY) {
      console.warn(`TM priority ${city}: only ${docs.length} (< ${MIN_PER_PRIORITY}).`);
    }
  }
  if (all.length > 0) {
    await upsertAll(all);
    await writeCountryStats(all);
    await buildSourceIndex('ticketmaster');
  }
  return counts;
}

async function runTicketmaster(key: string): Promise<number> {
  if (!key) {
    console.log('ingestTicketmaster: TICKETMASTER_API_KEY not set — skipping.');
    return 0;
  }
  const all: Doc[] = [];
  // Global dedupe by title + city across country + city pulls.
  const seen = new Set<string>();
  function add(docs: Doc[]): void {
    for (const d of docs) {
      const k =
        `${(d.data.title as string) || ''}|${(d.data.city as string) || ''}`
          .toLowerCase();
      if (seen.has(k)) continue;
      seen.add(k);
      all.push(d);
    }
  }

  for (const [name, iso] of Object.entries(COUNTRY_ISO)) {
    add(await fetchForCountry(key, iso, name));
  }
  for (const { city, country } of TOP_CITIES) {
    add(await fetchForCity(key, city, country));
  }
  if (all.length > 0) {
    await upsertAll(all);
    await writeCountryStats(all);
    await buildSourceIndex('ticketmaster');
  }
  console.log(`ingestTicketmaster: upserted ${all.length} events.`);
  return all.length;
}

export const ingestTicketmaster = onSchedule(
  { schedule: 'every 12 hours', timeoutSeconds: 540, memory: '512MiB', secrets: [TICKETMASTER_API_KEY] },
  async () => {
    await runTicketmaster(TICKETMASTER_API_KEY.value());
  }
);

// Manual trigger: ?token=<KEY> to pull now; &clear=1 to wipe TM first.
export const runIngestTicketmasterNow = onRequest(
  { timeoutSeconds: 540, memory: '512MiB', secrets: [TICKETMASTER_API_KEY] },
  async (req, res) => {
    const key = TICKETMASTER_API_KEY.value();
    if (!key || req.query.token !== key) {
      res.status(403).send('Forbidden');
      return;
    }
    // ?priority=1 → fast targeted refresh of the 10 priority cities only.
    if (req.query.priority) {
      const counts = await runPriorityCities(key);
      res.status(200).json({ ok: true, mode: 'priority', counts });
      return;
    }
    let cleared = 0;
    if (req.query.clear) cleared = await clearSource();
    const count = await runTicketmaster(key);
    res.status(200).json({ ok: true, cleared, upserted: count });
  }
);
