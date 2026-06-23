/**
 * Builds a compact, query-cheap **shard index** of `external_events` so the app
 * can load a whole source (5k–12k events) in a handful of document reads, hold
 * it in memory, and order it globally by distance / date / stars / reviews.
 *
 * Output collection `external_events_index`:
 *   {source}_meta  → { source, shardCount, total, updatedAt }
 *   {source}_{i}   → { source, shard: i, count, events: [ {compact record}, ... ] }
 *
 * Each compact record carries only what the list/cards + sorting need (id,
 * title, bookingUrl, imageUrl, category, city, country, price, rating,
 * reviewCount, durationMinutes, lat, lng, startDate). Rebuilt by the manual
 * trigger below and at the end of each ingester run, so it stays fresh.
 *
 * Internal Firestore only — no external API calls — so it always succeeds.
 */

import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';

const db = admin.firestore();
const SOURCE_COLLECTION = 'external_events';
const INDEX_COLLECTION = 'external_events_index';
const SHARD_SIZE = 500;

// Reuse existing source keys as the admin token for the manual trigger, so no
// new secret needs provisioning.
const VIATOR_API_KEY = defineSecret('VIATOR_API_KEY');
const TICKETMASTER_API_KEY = defineSecret('TICKETMASTER_API_KEY');

type Compact = Record<string, unknown>;

function compact(id: string, d: Record<string, unknown>): Compact {
  const out: Compact = { id };
  // Keep only the fields the app reads; drop nullish to keep shards small.
  const keys = [
    'title', 'bookingUrl', 'website', 'wikidataUrl', 'describedAtUrl',
    'imageUrl', 'category', 'city', 'country', 'fromPrice', 'currency',
    'rating', 'reviewCount', 'durationMinutes', 'lat', 'lng', 'startDate',
  ];
  for (const k of keys) {
    const v = d[k];
    if (v !== undefined && v !== null && v !== '') out[k] = v;
  }
  return out;
}

/** Rebuild the shard index for one source. Returns {total, shards}. */
export async function buildSourceIndex(
  source: string
): Promise<{ total: number; shards: number }> {
  // Read the whole source in pages and pack into compact records.
  const records: Compact[] = [];
  let cursor: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  for (;;) {
    let q = db
      .collection(SOURCE_COLLECTION)
      .where('source', '==', source)
      .orderBy('rating', 'desc')
      .limit(1000);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.get();
    if (snap.empty) break;
    for (const doc of snap.docs) records.push(compact(doc.id, doc.data()));
    cursor = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < 1000) break;
  }

  // Wipe any previous shards for this source (handles a shrinking dataset).
  const old = await db
    .collection(INDEX_COLLECTION)
    .where('source', '==', source)
    .get();
  let batch = db.batch();
  let ops = 0;
  const commits: Promise<unknown>[] = [];
  const flush = () => {
    if (ops > 0) {
      commits.push(batch.commit());
      batch = db.batch();
      ops = 0;
    }
  };
  for (const d of old.docs) {
    batch.delete(d.ref);
    if (++ops >= 400) flush();
  }
  flush();

  // Write new shards.
  const shardCount = Math.ceil(records.length / SHARD_SIZE);
  const now = admin.firestore.FieldValue.serverTimestamp();
  for (let i = 0; i < shardCount; i++) {
    const slice = records.slice(i * SHARD_SIZE, (i + 1) * SHARD_SIZE);
    batch.set(db.collection(INDEX_COLLECTION).doc(`${source}_${i}`), {
      source,
      shard: i,
      count: slice.length,
      events: slice,
      updatedAt: now,
    });
    if (++ops >= 400) flush();
  }
  batch.set(db.collection(INDEX_COLLECTION).doc(`${source}_meta`), {
    source,
    shardCount,
    total: records.length,
    updatedAt: now,
  });
  ops++;
  flush();
  await Promise.all(commits);

  console.log(
    `buildSourceIndex(${source}): ${records.length} events → ${shardCount} shards.`
  );
  return { total: records.length, shards: shardCount };
}

// Manual trigger: ?token=<VIATOR or TICKETMASTER key>&source=viator|tiqets|ticketmaster
// Omit source to rebuild all three.
export const runBuildExternalIndexNow = onRequest(
  {
    timeoutSeconds: 540,
    memory: '512MiB',
    secrets: [VIATOR_API_KEY, TICKETMASTER_API_KEY],
  },
  async (req, res) => {
    const token = req.query.token;
    const valid =
      token === VIATOR_API_KEY.value() || token === TICKETMASTER_API_KEY.value();
    if (!token || !valid) {
      res.status(403).send('Forbidden');
      return;
    }
    const source = req.query.source as string | undefined;
    const sources = source ? [source] : ['viator', 'tiqets', 'ticketmaster'];
    const result: Record<string, { total: number; shards: number }> = {};
    for (const s of sources) {
      result[s] = await buildSourceIndex(s);
    }
    res.status(200).json({ ok: true, result });
  }
);
