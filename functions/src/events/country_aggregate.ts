/**
 * Per-country event aggregation for the globe ("Network & Events").
 *
 * Maintains `event_country_stats/{country}` documents holding a small preview
 * (top 3 most-popular public events) + total count for each country. The globe
 * reads only these lightweight docs (one small read per country) instead of
 * scanning the whole events collection — so it scales to millions of events.
 * Tapping a country then loads its full top-N list on demand (client query).
 *
 * Recomputed whenever an event is created/updated/deleted (covers visibility,
 * country, status, and attendeeCount/popularity changes). Isolated, new module.
 */

import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

const db = admin.firestore();
const PREVIEW_LIMIT = 3;

async function recomputeCountry(country: string): Promise<void> {
  if (!country) return;
  const base = db
    .collection('events')
    .where('country', '==', country)
    .where('status', '==', 'published')
    .where('visibility', '==', 'public');

  // Total count (cheap aggregation).
  let count = 0;
  try {
    const agg = await base.count().get();
    count = agg.data().count;
  } catch (e) {
    console.error('country count failed', country, e);
  }

  // Top-N preview by popularity.
  const topSnap = await base
    .orderBy('attendeeCount', 'desc')
    .limit(PREVIEW_LIMIT)
    .get();
  const topEvents = topSnap.docs.map((d) => {
    const e = d.data();
    return {
      id: d.id,
      title: e.title ?? '',
      imageUrl: e.imageUrl ?? null,
      attendeeCount: e.attendeeCount ?? 0,
      city: e.city ?? null,
      startDate: e.startDate ?? null,
    };
  });

  const ref = db.collection('event_country_stats').doc(country);
  if (count === 0) {
    // No public events left in this country — remove the stale aggregate.
    await ref.delete().catch(() => undefined);
    return;
  }
  await ref.set({
    country,
    count,
    topEvents,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

export const onEventWriteUpdateCountryStats = onDocumentWritten(
  'events/{eventId}',
  monitored("onEventWriteUpdateCountryStats", async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    // Recompute every country touched by this write (handles country changes).
    const countries = new Set<string>();
    const b = before?.country as string | undefined;
    const a = after?.country as string | undefined;
    if (b) countries.add(b);
    if (a) countries.add(a);
    if (countries.size === 0) return;

    await Promise.all([...countries].map(recomputeCountry));
  })
);
