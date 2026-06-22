/**
 * Google Places (New) ingester → `external_events` (source: 'google').
 *
 * Pulls top attractions (museums, landmarks, parks…) for major tourist cities
 * with full detail — name, photo, rating, review count, exact coordinates,
 * category, city/country — so Attractions cards match Experiences/Live Events.
 * Deep-links to Google Maps (no booking). Key from GOOGLE_PLACES_API_KEY secret;
 * no-ops until set.
 *
 * Cost note: Places Text Search + Photo are billed per call; restrict the key
 * to the Places API and keep the schedule modest.
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';

const db = admin.firestore();
const COLLECTION = 'external_events';
const GOOGLE_PLACES_API_KEY = defineSecret('GOOGLE_PLACES_API_KEY');
const PAGES_PER_CITY = 3; // 20 results/page → up to 60 attractions/city

// Top global tourist cities → country name (for the doc's country field).
const CITIES: { city: string; country: string }[] = [
  { city: 'Paris', country: 'France' }, { city: 'Rome', country: 'Italy' },
  { city: 'London', country: 'United Kingdom' }, { city: 'New York', country: 'United States' },
  { city: 'Barcelona', country: 'Spain' }, { city: 'Tokyo', country: 'Japan' },
  { city: 'Dubai', country: 'United Arab Emirates' }, { city: 'Istanbul', country: 'Turkey' },
  { city: 'Bangkok', country: 'Thailand' }, { city: 'Amsterdam', country: 'Netherlands' },
  { city: 'Berlin', country: 'Germany' }, { city: 'Prague', country: 'Czech Republic' },
  { city: 'Vienna', country: 'Austria' }, { city: 'Madrid', country: 'Spain' },
  { city: 'Florence', country: 'Italy' }, { city: 'Venice', country: 'Italy' },
  { city: 'Lisbon', country: 'Portugal' }, { city: 'Athens', country: 'Greece' },
  { city: 'Budapest', country: 'Hungary' }, { city: 'Singapore', country: 'Singapore' },
  { city: 'Los Angeles', country: 'United States' }, { city: 'San Francisco', country: 'United States' },
  { city: 'Las Vegas', country: 'United States' }, { city: 'Miami', country: 'United States' },
  { city: 'Chicago', country: 'United States' }, { city: 'Washington', country: 'United States' },
  { city: 'Toronto', country: 'Canada' }, { city: 'Vancouver', country: 'Canada' },
  { city: 'Sydney', country: 'Australia' }, { city: 'Melbourne', country: 'Australia' },
  { city: 'Cairo', country: 'Egypt' }, { city: 'Marrakech', country: 'Morocco' },
  { city: 'Cape Town', country: 'South Africa' }, { city: 'Rio de Janeiro', country: 'Brazil' },
  { city: 'Buenos Aires', country: 'Argentina' }, { city: 'Lima', country: 'Peru' },
  { city: 'Mexico City', country: 'Mexico' }, { city: 'Cusco', country: 'Peru' },
  { city: 'Kyoto', country: 'Japan' }, { city: 'Seoul', country: 'South Korea' },
  { city: 'Hong Kong', country: 'China' }, { city: 'Beijing', country: 'China' },
  { city: 'Shanghai', country: 'China' }, { city: 'Mumbai', country: 'India' },
  { city: 'Delhi', country: 'India' }, { city: 'Bali', country: 'Indonesia' },
  { city: 'Hanoi', country: 'Vietnam' }, { city: 'Siem Reap', country: 'Cambodia' },
  { city: 'Dublin', country: 'Ireland' }, { city: 'Edinburgh', country: 'United Kingdom' },
  { city: 'Munich', country: 'Germany' }, { city: 'Milan', country: 'Italy' },
  { city: 'Naples', country: 'Italy' }, { city: 'Seville', country: 'Spain' },
  { city: 'Porto', country: 'Portugal' }, { city: 'Krakow', country: 'Poland' },
  { city: 'Warsaw', country: 'Poland' }, { city: 'Stockholm', country: 'Sweden' },
  { city: 'Copenhagen', country: 'Denmark' }, { city: 'Oslo', country: 'Norway' },
  { city: 'Reykjavik', country: 'Iceland' }, { city: 'Brussels', country: 'Belgium' },
  { city: 'Zurich', country: 'Switzerland' }, { city: 'Geneva', country: 'Switzerland' },
  { city: 'Dubrovnik', country: 'Croatia' }, { city: 'Petra', country: 'Jordan' },
  { city: 'Amman', country: 'Jordan' }, { city: 'Tel Aviv', country: 'Israel' },
  { city: 'Jerusalem', country: 'Israel' }, { city: 'Riyadh', country: 'Saudi Arabia' },
  { city: 'Kuala Lumpur', country: 'Malaysia' }, { city: 'Manila', country: 'Philippines' },
  { city: 'Auckland', country: 'New Zealand' }, { city: 'Queenstown', country: 'New Zealand' },
  { city: 'San Jose', country: 'Costa Rica' }, { city: 'Bogota', country: 'Colombia' },
  { city: 'Cartagena', country: 'Colombia' }, { city: 'Santiago', country: 'Chile' },
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

async function clearSource(): Promise<number> {
  let total = 0;
  for (;;) {
    const snap = await db.collection(COLLECTION).where('source', '==', 'google').limit(400).get();
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
      db.collection('external_country_stats').doc(`google_${country}`),
      { source: 'google', country, count, updatedAt: now },
      { merge: true }
    );
  }
  await batch.commit();
}

/// Resolve a Photo resource into a stable image URL (no key in the URL).
async function photoUrl(key: string, name: string): Promise<string | null> {
  try {
    const res = await fetch(
      `https://places.googleapis.com/v1/${name}/media` +
        `?maxHeightPx=800&skipHttpRedirect=true&key=${key}`
    );
    if (!res.ok) return null;
    const json: any = await res.json();
    return (json.photoUri as string) ?? null;
  } catch (_) {
    return null;
  }
}

function countryFrom(p: any, fallback: string): string {
  for (const c of p.addressComponents || []) {
    if ((c.types || []).includes('country')) return c.longText || fallback;
  }
  return fallback;
}

async function fetchForCity(
  key: string,
  city: string,
  countryName: string
): Promise<Doc[]> {
  const out: Doc[] = [];
  let pageToken: string | undefined;
  for (let page = 0; page < PAGES_PER_CITY; page++) {
    try {
      const res = await fetch('https://places.googleapis.com/v1/places:searchText', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': key,
          'X-Goog-FieldMask':
            'places.id,places.displayName,places.location,places.rating,' +
            'places.userRatingCount,places.photos,places.primaryTypeDisplayName,' +
            'places.googleMapsUri,places.websiteUri,places.addressComponents,' +
            'nextPageToken',
        },
        body: JSON.stringify({
          textQuery: `top tourist attractions in ${city}`,
          maxResultCount: 20,
          ...(pageToken ? { pageToken } : {}),
        }),
      });
      if (!res.ok) {
        console.error(`Google ${city} HTTP ${res.status}`);
        break;
      }
      const json: any = await res.json();
      const places: any[] = json.places || [];
      for (const p of places) {
        const loc = p.location || {};
        const img = p.photos?.[0]?.name
          ? await photoUrl(key, p.photos[0].name)
          : null;
        out.push({
          id: `google_${p.id}`,
          data: {
            source: 'google',
            externalId: p.id,
            title: p.displayName?.text ?? '',
            description: null,
            imageUrl: img,
            category: p.primaryTypeDisplayName?.text ?? 'attraction',
            city,
            country: countryFrom(p, countryName),
            lat: loc.latitude ?? null,
            lng: loc.longitude ?? null,
            fromPrice: null,
            currency: null,
            rating: p.rating ?? 0,
            reviewCount: p.userRatingCount ?? 0,
            bookingUrl: p.googleMapsUri ?? p.websiteUri ?? null,
            fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        });
      }
      pageToken = json.nextPageToken;
      if (!pageToken) break;
    } catch (e) {
      console.error(`Google ${city} failed`, e);
      break;
    }
  }
  return out;
}

async function runGoogle(key: string): Promise<number> {
  if (!key) {
    console.log('ingestGooglePlaces: GOOGLE_PLACES_API_KEY not set — skipping.');
    return 0;
  }
  const all: Doc[] = [];
  const seen = new Set<string>();
  for (const { city, country } of CITIES) {
    for (const d of await fetchForCity(key, city, country)) {
      if (seen.has(d.id)) continue;
      seen.add(d.id);
      all.push(d);
    }
  }
  if (all.length > 0) {
    await upsertAll(all);
    await writeCountryStats(all);
  }
  console.log(`ingestGooglePlaces: upserted ${all.length} attractions.`);
  return all.length;
}

export const ingestGooglePlaces = onSchedule(
  { schedule: 'every 24 hours', timeoutSeconds: 540, memory: '512MiB', secrets: [GOOGLE_PLACES_API_KEY] },
  async () => {
    await runGoogle(GOOGLE_PLACES_API_KEY.value());
  }
);

// Manual trigger: ?token=<KEY> to pull now; &clear=1 to wipe Google source first.
export const runIngestGoogleNow = onRequest(
  { timeoutSeconds: 540, memory: '512MiB', secrets: [GOOGLE_PLACES_API_KEY] },
  async (req, res) => {
    const key = GOOGLE_PLACES_API_KEY.value();
    if (!key || req.query.token !== key) {
      res.status(403).send('Forbidden');
      return;
    }
    let cleared = 0;
    if (req.query.clear) cleared = await clearSource();
    const count = await runGoogle(key);
    res.status(200).json({ ok: true, cleared, upserted: count });
  }
);
