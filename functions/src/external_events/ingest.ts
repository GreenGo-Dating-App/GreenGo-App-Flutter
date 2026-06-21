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

// Curated Viator destinationIds. Extend freely; ingestion is bounded by this.
const DESTINATIONS: { city: string; country: string; viatorDestId: string }[] = [
  { city: 'Rome', country: 'IT', viatorDestId: '511' },
  { city: 'Paris', country: 'FR', viatorDestId: '479' },
  { city: 'London', country: 'GB', viatorDestId: '737' },
  { city: 'Barcelona', country: 'ES', viatorDestId: '562' },
  { city: 'New York', country: 'US', viatorDestId: '687' },
  { city: 'Tokyo', country: 'JP', viatorDestId: '334' },
  { city: 'Amsterdam', country: 'NL', viatorDestId: '525' },
  { city: 'Dubai', country: 'AE', viatorDestId: '828' },
  { city: 'Lisbon', country: 'PT', viatorDestId: '538' },
  { city: 'Berlin', country: 'DE', viatorDestId: '488' },
];

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

async function fetchViator(
  apiKey: string,
  d: (typeof DESTINATIONS)[number],
  base: string
): Promise<Doc[]> {
  try {
    const res = await fetch(`${base}/products/search`, {
      method: 'POST',
      headers: {
        'exp-api-key': apiKey,
        Accept: 'application/json;version=2.0',
        'Accept-Language': 'en-US',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        filtering: { destination: d.viatorDestId },
        sorting: { sort: 'TRAVELER_RATING', order: 'DESCENDING' },
        pagination: { start: 1, count: 30 },
        currency: 'USD',
      }),
    });
    if (!res.ok) {
      console.error(`Viator ${d.city} HTTP ${res.status}`);
      return [];
    }
    const json: any = await res.json();
    const products: any[] = json.products || [];
    return products.map((p) => {
      const variants = p.images?.[0]?.variants || [];
      const img = variants.length ? variants[variants.length - 1]?.url : undefined;
      return {
        id: `viator_${p.productCode}`,
        data: {
          source: 'viator',
          externalId: p.productCode,
          title: p.title,
          description: p.description ?? null,
          imageUrl: img ?? null,
          category: 'tour',
          city: d.city,
          country: d.country,
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
    console.error(`Viator fetch failed for ${d.city}`, e);
    return [];
  }
}

async function runIngestion(apiKey: string): Promise<number> {
  if (!apiKey) {
    console.log('ingestExternalEvents: VIATOR_API_KEY not set — skipping.');
    return 0;
  }
  for (const base of VIATOR_BASES) {
    const all: Doc[] = [];
    for (const d of DESTINATIONS) {
      all.push(...(await fetchViator(apiKey, d, base)));
    }
    if (all.length > 0) {
      await upsertAll(all);
      console.log(
        `ingestExternalEvents: upserted ${all.length} Viator experiences from ${base}.`
      );
      return all.length;
    }
    console.log(`ingestExternalEvents: no results from ${base}, trying next.`);
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
      imageUrl: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&q=80',
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
      imageUrl: 'https://images.unsplash.com/photo-1543349689-9a4d426bee8e?w=800&q=80',
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
      imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&q=80',
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
      imageUrl: 'https://images.unsplash.com/photo-1583779457094-ab6f9164a1c8?w=800&q=80',
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
      imageUrl: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=800&q=80',
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
      imageUrl: 'https://images.unsplash.com/photo-1451337516015-6b6e9a44a8a3?w=800&q=80',
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
