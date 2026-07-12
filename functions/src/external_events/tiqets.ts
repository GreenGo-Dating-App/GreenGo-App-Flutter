/**
 * Tiqets attractions ingester → `external_events` (source: 'tiqets').
 *
 * Pulls the top attractions (museums/landmarks) for the top tourism countries
 * and upserts them with geolocation (lat/lng) so the Attractions tab can order
 * by distance. Key from the TIQETS_API_KEY secret; no-ops until it's set.
 *
 * NOTE: exact Tiqets endpoint/field names are finalized once a live key is
 * available to verify against (kept isolated so verification is a one-file fix).
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

const db = admin.firestore();
const COLLECTION = 'external_events';
const TIQETS_API_KEY = defineSecret('TIQETS_API_KEY');
const PRODUCTS_PER_COUNTRY = 100;

const TOP_COUNTRIES = [
  'France', 'Spain', 'United States', 'Italy', 'Turkey', 'Mexico',
  'United Kingdom', 'Germany', 'Greece', 'Austria', 'Japan', 'Thailand',
  'Portugal', 'Netherlands', 'Croatia', 'United Arab Emirates', 'Canada',
  'Australia', 'China', 'Egypt', 'India', 'Indonesia', 'Vietnam',
  'Switzerland', 'Czech Republic', 'Poland', 'Ireland', 'Morocco',
  'South Africa', 'Brazil', 'Argentina', 'Peru', 'Iceland', 'Hungary',
  'Belgium', 'Denmark', 'Sweden', 'Norway', 'Singapore', 'Malaysia',
  'Philippines', 'South Korea', 'New Zealand', 'Israel', 'Jordan',
  'Cambodia', 'Costa Rica', 'Colombia', 'Chile', 'Saudi Arabia',
];

type Doc = { id: string; data: Record<string, unknown> };

const headers = (key: string) => ({
  Authorization: `Token ${key}`,
  Accept: 'application/json',
});

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

/// Map Tiqets country names → ids.
async function resolveCountryIds(key: string): Promise<{ id: string; name: string }[]> {
  try {
    const res = await fetch('https://api.tiqets.com/v2/countries', { headers: headers(key) });
    if (!res.ok) {
      console.error(`Tiqets countries HTTP ${res.status}`);
      return [];
    }
    const json: any = await res.json();
    const countries: any[] = json.countries || json || [];
    const byName = new Map<string, any>();
    for (const c of countries) {
      if (c.name) byName.set(String(c.name).toLowerCase(), c);
    }
    const out: { id: string; name: string }[] = [];
    for (const name of TOP_COUNTRIES) {
      const c = byName.get(name.toLowerCase());
      if (c && c.id != null) out.push({ id: String(c.id), name });
    }
    return out;
  } catch (e) {
    console.error('Tiqets countries failed', e);
    return [];
  }
}

function mapProduct(p: any, countryName: string): Doc {
  const geo = p.geolocation || {};
  return {
    id: `tiqets_${p.id}`,
    data: {
      source: 'tiqets',
      externalId: String(p.id),
      title: p.title,
      description: p.tagline ?? null,
      imageUrl: p.images?.[0]?.large ?? p.images?.[0]?.medium ?? null,
      category: 'attraction',
      city: p.city?.name ?? null,
      country: p.city?.country?.code ?? countryName,
      fromPrice: p.price?.amount != null ? Number(p.price.amount) : null,
      currency: p.price?.currency ?? 'EUR',
      rating: p.ratings?.average ?? 0,
      reviewCount: p.ratings?.count ?? 0,
      lat: geo.lat ?? null,
      lng: geo.lng ?? null,
      bookingUrl: p.product_url ?? null,
      fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  };
}

async function fetchForCountry(key: string, countryId: string, countryName: string): Promise<Doc[]> {
  const docs: Doc[] = [];
  const pageSize = 50;
  for (let page = 1; docs.length < PRODUCTS_PER_COUNTRY; page++) {
    try {
      const res = await fetch(
        `https://api.tiqets.com/v2/products?country_id=${countryId}&page=${page}&page_size=${pageSize}`,
        { headers: headers(key) }
      );
      if (!res.ok) {
        console.error(`Tiqets ${countryName} HTTP ${res.status} (page ${page})`);
        break;
      }
      const json: any = await res.json();
      const products: any[] = json.products || [];
      if (products.length === 0) break;
      docs.push(...products.map((p) => mapProduct(p, countryName)));
      if (products.length < pageSize) break;
    } catch (e) {
      console.error(`Tiqets ${countryName} failed (page ${page})`, e);
      break;
    }
  }
  return docs.slice(0, PRODUCTS_PER_COUNTRY);
}

async function runTiqets(key: string): Promise<number> {
  if (!key) {
    console.log('ingestTiqets: TIQETS_API_KEY not set — skipping.');
    return 0;
  }
  const countries = await resolveCountryIds(key);
  if (countries.length === 0) return 0;
  const all: Doc[] = [];
  for (const c of countries) {
    all.push(...(await fetchForCountry(key, c.id, c.name)));
  }
  // Attractions are only worth showing with a photo → drop the image-less ones
  // so we never store (or later render) a blank card.
  const withImage = all.filter((d) => {
    const url = d.data.imageUrl;
    return typeof url === 'string' && url.length > 0;
  });
  if (withImage.length > 0) await upsertAll(withImage);
  console.log(
    `ingestTiqets: upserted ${withImage.length}/${all.length} attractions ` +
      `with images across ${countries.length} countries.`
  );
  return withImage.length;
}

export const ingestTiqetsAttractions = onSchedule(
  { schedule: 'every 12 hours', timeoutSeconds: 540, memory: '512MiB', secrets: [TIQETS_API_KEY] },
  monitored("ingestTiqetsAttractions", async () => {
    await runTiqets(TIQETS_API_KEY.value());
  })
);

// Manual trigger: GET ?token=<TIQETS_API_KEY> to pull attractions now.
export const runIngestTiqetsNow = onRequest(
  { timeoutSeconds: 540, memory: '512MiB', secrets: [TIQETS_API_KEY] },
  monitored("runIngestTiqetsNow", async (req, res) => {
    const key = TIQETS_API_KEY.value();
    if (!key || req.query.token !== key) {
      res.status(403).send('Forbidden');
      return;
    }
    const count = await runTiqets(key);
    res.status(200).json({ ok: true, upserted: count });
  })
);
