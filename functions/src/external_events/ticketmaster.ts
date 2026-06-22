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

const db = admin.firestore();
const COLLECTION = 'external_events';
const TICKETMASTER_API_KEY = defineSecret('TICKETMASTER_API_KEY');
const PER_COUNTRY = 100;

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

async function runTicketmaster(key: string): Promise<number> {
  if (!key) {
    console.log('ingestTicketmaster: TICKETMASTER_API_KEY not set — skipping.');
    return 0;
  }
  const all: Doc[] = [];
  for (const [name, iso] of Object.entries(COUNTRY_ISO)) {
    const docs = await fetchForCountry(key, iso, name);
    // Dedupe within a country by title + city (TM repeats a show across dates).
    const seen = new Set<string>();
    for (const d of docs) {
      const key2 =
        `${(d.data.title as string) || ''}|${(d.data.city as string) || ''}`
          .toLowerCase();
      if (seen.has(key2)) continue;
      seen.add(key2);
      all.push(d);
    }
  }
  if (all.length > 0) {
    await upsertAll(all);
    await writeCountryStats(all);
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
    let cleared = 0;
    if (req.query.clear) cleared = await clearSource();
    const count = await runTicketmaster(key);
    res.status(200).json({ ok: true, cleared, upserted: count });
  }
);
