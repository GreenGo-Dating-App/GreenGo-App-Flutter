/**
 * External experiences ingester (Viator only).
 *
 * On a schedule, pulls bookable experiences from Viator (tours, activities,
 * attraction tickets) for a curated list of destinations and upserts them into
 * the `external_events` collection. The app reads that collection (cache-first)
 * and deep-links out to Viator to book — so API calls stay bounded (a few
 * hundred per run, NOT per user) and scale to millions of users.
 *
 * The Viator API key is stored as a Functions secret (VIATOR_API_KEY). If it is
 * not set the run no-ops, so this deploys safely before the secret exists.
 *
 * Does NOT touch the native `events` collection or its functions.
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';

const db = admin.firestore();
const COLLECTION = 'external_events';

const VIATOR_API_KEY = defineSecret('VIATOR_API_KEY');

// Top 50 tourism countries worldwide. We match these to Viator's COUNTRY
// destinations dynamically (no hardcoded ids) and pull the top 10 experiences
// for each — so the feed is ~500 top-rated experiences across 50 countries.
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

const PRODUCTS_PER_COUNTRY = 10;

type Doc = { id: string; data: Record<string, unknown> };

async function upsertAll(docs: Doc[]): Promise<void> {
  let batch = db.batch();
  let ops = 0;
  const commits: Promise<unknown>[] = [];
  const now = admin.firestore.FieldValue.serverTimestamp();
  for (const { id, data } of docs) {
    batch.set(
      db.collection(COLLECTION).doc(id),
      { ...data, updatedAt: now },
      { merge: true }
    );
    if (++ops >= 400) {
      commits.push(batch.commit());
      batch = db.batch();
      ops = 0;
    }
  }
  if (ops > 0) commits.push(batch.commit());
  await Promise.all(commits);
}

// Production first; fresh keys are often sandbox-only until prod access lands.
const VIATOR_BASES = [
  'https://api.viator.com/partner',
  'https://api.sandbox.viator.com/partner',
];

const VIATOR_HEADERS = (apiKey: string) => ({
  'exp-api-key': apiKey,
  Accept: 'application/json;version=2.0',
  'Accept-Language': 'en-US',
  'Content-Type': 'application/json',
});

/// Resolve the top-50 country names to Viator COUNTRY destination ids.
async function resolveCountries(
  apiKey: string,
  base: string
): Promise<{ id: string; name: string }[]> {
  try {
    const res = await fetch(`${base}/destinations`, {
      headers: VIATOR_HEADERS(apiKey),
    });
    if (!res.ok) {
      console.error(`Viator destinations HTTP ${res.status} (${base})`);
      return [];
    }
    const json: any = await res.json();
    const dests: any[] = json.destinations || [];
    const byName = new Map<string, any>();
    for (const d of dests) {
      if (d.type === 'COUNTRY' && d.name) {
        byName.set(String(d.name).toLowerCase(), d);
      }
    }
    const out: { id: string; name: string }[] = [];
    for (const name of TOP_COUNTRIES) {
      const d = byName.get(name.toLowerCase());
      if (d) out.push({ id: String(d.destinationId), name });
    }
    return out;
  } catch (e) {
    console.error(`Viator destinations failed (${base})`, e);
    return [];
  }
}

/// Top [PRODUCTS_PER_COUNTRY] experiences for one country.
async function fetchTopForCountry(
  apiKey: string,
  base: string,
  destId: string,
  countryName: string
): Promise<Doc[]> {
  try {
    const res = await fetch(`${base}/products/search`, {
      method: 'POST',
      headers: VIATOR_HEADERS(apiKey),
      body: JSON.stringify({
        filtering: { destination: destId },
        sorting: { sort: 'TRAVELER_RATING', order: 'DESCENDING' },
        pagination: { start: 1, count: PRODUCTS_PER_COUNTRY },
        currency: 'USD',
      }),
    });
    if (!res.ok) {
      console.error(`Viator ${countryName} HTTP ${res.status}`);
      return [];
    }
    const json: any = await res.json();
    const products: any[] = json.products || [];
    return products.map((p) => {
      // Pick the highest-resolution image variant (max width × height).
      const variants: any[] = p.images?.[0]?.variants || [];
      let best: any;
      for (const v of variants) {
        const area = (v.width || 0) * (v.height || 0);
        const bestArea = best ? (best.width || 0) * (best.height || 0) : -1;
        if (area > bestArea) best = v;
      }
      const img = best?.url;
      return {
        id: `viator_${p.productCode}`,
        data: {
          source: 'viator',
          externalId: p.productCode,
          title: p.title,
          description: p.description ?? null,
          imageUrl: img ?? null,
          category: 'tour',
          city: null,
          country: countryName,
          fromPrice: p.pricing?.summary?.fromPrice ?? null,
          currency: p.pricing?.currency ?? 'USD',
          rating: p.reviews?.combinedAverageRating ?? null,
          reviewCount: p.reviews?.totalReviews ?? null,
          durationMinutes: p.duration?.fixedDurationInMinutes ?? null,
          bookingUrl: p.productUrl ?? null,
          fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      };
    });
  } catch (e) {
    console.error(`Viator fetch failed for ${countryName}`, e);
    return [];
  }
}

async function runIngestion(apiKey: string): Promise<number> {
  if (!apiKey) {
    console.log('ingestExternalEvents: VIATOR_API_KEY not set — skipping.');
    return 0;
  }
  for (const base of VIATOR_BASES) {
    const countries = await resolveCountries(apiKey, base);
    if (countries.length === 0) {
      console.log(`ingestExternalEvents: no countries from ${base}, trying next.`);
      continue;
    }
    const all: Doc[] = [];
    for (const c of countries) {
      all.push(...(await fetchTopForCountry(apiKey, base, c.id, c.name)));
    }
    if (all.length > 0) {
      await upsertAll(all);
      console.log(
        `ingestExternalEvents: upserted ${all.length} experiences across ` +
          `${countries.length} countries from ${base}.`
      );
      return all.length;
    }
    console.log(`ingestExternalEvents: no products from ${base}, trying next.`);
  }
  console.log('ingestExternalEvents: no Viator results from any base.');
  return 0;
}

// Scheduled refresh, every 12 hours.
export const ingestExternalEvents = onSchedule(
  {
    schedule: 'every 12 hours',
    timeoutSeconds: 540,
    memory: '512MiB',
    secrets: [VIATOR_API_KEY],
  },
  async () => {
    await runIngestion(VIATOR_API_KEY.value());
  }
);

// Curated real, public Viator experiences — used to seed `external_events` for
// a working demo until the live API key is activated. Real titles + booking
// URLs (viator.com); replaced by live API data once the key works.
const SEED_DOCS: Doc[] = [
  {
    id: 'viator_seed_rome_colosseum',
    data: {
      source: 'viator', externalId: 'seed_rome_colosseum',
      title: 'Colosseum, Roman Forum & Palatine Hill Skip-the-Line Tour',
      category: 'tour', city: 'Rome', country: 'IT',
      imageUrl: 'https://picsum.photos/seed/colosseum/800/600',
      fromPrice: 54, currency: 'EUR', rating: 4.6, reviewCount: 12890,
      durationMinutes: 180, bookingUrl: 'https://www.viator.com/Rome-tours/d511',
    },
  },
  {
    id: 'viator_seed_paris_eiffel',
    data: {
      source: 'viator', externalId: 'seed_paris_eiffel',
      title: 'Eiffel Tower Summit Access by Elevator',
      category: 'attraction', city: 'Paris', country: 'FR',
      imageUrl: 'https://picsum.photos/seed/eiffel/800/600',
      fromPrice: 69, currency: 'EUR', rating: 4.5, reviewCount: 8742,
      durationMinutes: 120, bookingUrl: 'https://www.viator.com/Paris-tours/d479',
    },
  },
  {
    id: 'viator_seed_tokyo_food',
    data: {
      source: 'viator', externalId: 'seed_tokyo_food',
      title: 'Tokyo by Night: Food & Culture Walking Tour',
      category: 'experience', city: 'Tokyo', country: 'JP',
      imageUrl: 'https://picsum.photos/seed/tokyo/800/600',
      fromPrice: 95, currency: 'USD', rating: 4.9, reviewCount: 2103,
      durationMinutes: 180, bookingUrl: 'https://www.viator.com/Tokyo-tours/d334',
    },
  },
  {
    id: 'viator_seed_barcelona_sagrada',
    data: {
      source: 'viator', externalId: 'seed_barcelona_sagrada',
      title: 'Sagrada Família Fast-Track Guided Tour',
      category: 'attraction', city: 'Barcelona', country: 'ES',
      imageUrl: 'https://picsum.photos/seed/sagrada/800/600',
      fromPrice: 49, currency: 'EUR', rating: 4.8, reviewCount: 15420,
      durationMinutes: 90, bookingUrl: 'https://www.viator.com/Barcelona-tours/d562',
    },
  },
  {
    id: 'viator_seed_nyc_skyline',
    data: {
      source: 'viator', externalId: 'seed_nyc_skyline',
      title: 'New York Skyline: Empire State Building Skip-the-Line',
      category: 'attraction', city: 'New York', country: 'US',
      imageUrl: 'https://picsum.photos/seed/nyc/800/600',
      fromPrice: 48, currency: 'USD', rating: 4.5, reviewCount: 9981,
      durationMinutes: 90, bookingUrl: 'https://www.viator.com/New-York-City-tours/d687',
    },
  },
  {
    id: 'viator_seed_dubai_desert',
    data: {
      source: 'viator', externalId: 'seed_dubai_desert',
      title: 'Dubai Red Dunes Desert Safari with BBQ Dinner',
      category: 'experience', city: 'Dubai', country: 'AE',
      imageUrl: 'https://picsum.photos/seed/dubai/800/600',
      fromPrice: 35, currency: 'USD', rating: 4.7, reviewCount: 6210,
      durationMinutes: 360, bookingUrl: 'https://www.viator.com/Dubai-tours/d828',
    },
  },
];

// Manual trigger (admin), guarded by the Viator key as token:
//   ?token=<KEY>          → pull live data now
//   ?token=<KEY>&seed=1   → seed curated demo experiences into external_events
export const runIngestExternalEventsNow = onRequest(
  { timeoutSeconds: 540, memory: '512MiB', secrets: [VIATOR_API_KEY] },
  async (req, res) => {
    const key = VIATOR_API_KEY.value();
    if (!key || req.query.token !== key) {
      res.status(403).send('Forbidden');
      return;
    }
    if (req.query.seed === '1') {
      await upsertAll(SEED_DOCS);
      res.status(200).json({ ok: true, seeded: SEED_DOCS.length });
      return;
    }
    const count = await runIngestion(key);
    res.status(200).json({ ok: true, upserted: count });
  }
);
