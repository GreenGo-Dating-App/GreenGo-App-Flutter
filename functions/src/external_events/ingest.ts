/**
 * External experiences ingester (NEW, isolated module).
 *
 * On a schedule, pulls bookable experiences from Tiqets (museums/attractions)
 * and Viator (tours/experiences) for a curated list of cities and upserts them
 * into the `external_events` collection. The app reads that collection (cache-
 * first) and deep-links out to book — so API calls stay bounded (a few hundred
 * city calls per run, NOT per user) and scale to millions of users.
 *
 * Keys are read from env (set via `firebase functions:secrets:set` or
 * functions config). If a provider's key is missing, that provider is skipped,
 * so this deploys and runs safely before keys exist (the app shows a built-in
 * sample preview until real data lands).
 *
 * Does NOT touch the native `events` collection or its functions.
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';

const db = admin.firestore();
const COLLECTION = 'external_events';

// Curated destination seed list. Viator destinationId + Tiqets cityId differ,
// so each entry carries both. Extend freely; ingestion is bounded by this list.
const CITIES: {
  city: string;
  country: string;
  viatorDestId?: string;
  tiqetsCityId?: number;
}[] = [
  { city: 'Rome', country: 'IT', viatorDestId: '511', tiqetsCityId: 67 },
  { city: 'Paris', country: 'FR', viatorDestId: '479', tiqetsCityId: 66746 },
  { city: 'London', country: 'GB', viatorDestId: '737', tiqetsCityId: 66744 },
  { city: 'Barcelona', country: 'ES', viatorDestId: '562', tiqetsCityId: 71993 },
  { city: 'New York', country: 'US', viatorDestId: '687', tiqetsCityId: 66745 },
  { city: 'Tokyo', country: 'JP', viatorDestId: '334' },
  { city: 'Amsterdam', country: 'NL', viatorDestId: '525', tiqetsCityId: 75061 },
  { city: 'Dubai', country: 'AE', viatorDestId: '828' },
];

type NormalizedDoc = Record<string, unknown>;

async function upsertAll(docs: { id: string; data: NormalizedDoc }[]) {
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

async function fetchViator(
  apiKey: string,
  c: (typeof CITIES)[number]
): Promise<{ id: string; data: NormalizedDoc }[]> {
  if (!c.viatorDestId) return [];
  try {
    const res = await fetch('https://api.viator.com/partner/products/search', {
      method: 'POST',
      headers: {
        'exp-api-key': apiKey,
        Accept: 'application/json;version=2.0',
        'Accept-Language': 'en-US',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        filtering: { destination: c.viatorDestId },
        sorting: { sort: 'TRAVELER_RATING', order: 'DESCENDING' },
        pagination: { start: 1, count: 30 },
        currency: 'USD',
      }),
    });
    if (!res.ok) return [];
    const json: any = await res.json();
    const products: any[] = json.products || [];
    return products.map((p) => {
      const img = p.images?.[0]?.variants?.slice(-1)?.[0]?.url as string | undefined;
      return {
        id: `viator_${p.productCode}`,
        data: {
          source: 'viator',
          externalId: p.productCode,
          title: p.title,
          description: p.description ?? null,
          imageUrl: img ?? null,
          category: 'tour',
          city: c.city,
          country: c.country,
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
    console.error(`Viator fetch failed for ${c.city}`, e);
    return [];
  }
}

async function fetchTiqets(
  apiKey: string,
  c: (typeof CITIES)[number]
): Promise<{ id: string; data: NormalizedDoc }[]> {
  if (!c.tiqetsCityId) return [];
  try {
    const res = await fetch(
      `https://api.tiqets.com/v2/products?city_id=${c.tiqetsCityId}&page_size=30`,
      { headers: { Authorization: `Token ${apiKey}`, Accept: 'application/json' } }
    );
    if (!res.ok) return [];
    const json: any = await res.json();
    const products: any[] = json.products || [];
    return products.map((p) => ({
      id: `tiqets_${p.id}`,
      data: {
        source: 'tiqets',
        externalId: String(p.id),
        title: p.title,
        description: p.tagline ?? null,
        imageUrl: p.images?.[0]?.large ?? p.images?.[0]?.medium ?? null,
        category: 'museum',
        city: p.city?.name ?? c.city,
        country: p.city?.country?.code ?? c.country,
        fromPrice: p.price?.amount ? Number(p.price.amount) : null,
        currency: p.price?.currency ?? 'EUR',
        rating: p.ratings?.average ?? null,
        reviewCount: p.ratings?.count ?? null,
        bookingUrl: p.product_url ?? null,
        fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    }));
  } catch (e) {
    console.error(`Tiqets fetch failed for ${c.city}`, e);
    return [];
  }
}

export const ingestExternalEvents = onSchedule(
  // Twice per day — refresh the cached experiences (one ingestion run per
  // schedule, not per-user). Data is persisted in `external_events` and read
  // by the app cache-first.
  { schedule: 'every 12 hours', timeoutSeconds: 540, memory: '512MiB' },
  async () => {
    const viatorKey = process.env.VIATOR_API_KEY || '';
    const tiqetsKey = process.env.TIQETS_API_KEY || '';
    if (!viatorKey && !tiqetsKey) {
      console.log('ingestExternalEvents: no provider keys set — skipping.');
      return;
    }

    const all: { id: string; data: NormalizedDoc }[] = [];
    for (const c of CITIES) {
      if (viatorKey) all.push(...(await fetchViator(viatorKey, c)));
      if (tiqetsKey) all.push(...(await fetchTiqets(tiqetsKey, c)));
    }
    if (all.length > 0) await upsertAll(all);
    console.log(`ingestExternalEvents: upserted ${all.length} experiences.`);
  }
);
