/**
 * Deployed functions of the world map snapshots (see worldMapSnapshot.ts).
 *
 *  * getWorldMapSnapshot (callable): the caller's snapshot. Fresh (< 1 h) ->
 *    returned as stored; missing / older -> built once on demand (at most
 *    once per 2 min per user) and returned. Marks the user as an active map
 *    user (`active`, `lastOpenedAt`, throttled to one write per hour) so the
 *    hourly batch keeps their snapshot fresh. `{touchOnly: true}` only
 *    refreshes the marker (the app sends it when it read a fresh snapshot
 *    directly from Firestore but its marker is older than a day).
 *  * rebuildWorldMapSnapshots (schedule, hourly): dispatcher. Pages the due
 *    snapshots (`active == true && refreshAfter <= now + 5 min`, stalest
 *    first; composite index world_map_snapshots(active ASC, refreshAfter
 *    ASC)), deactivates users who have not opened the map for 7 days and
 *    publishes the rest to Pub/Sub in messages of 100 uids. Run stats in
 *    maintenance/world_map_snapshots.
 *  * rebuildWorldMapSnapshotsBatch (Pub/Sub world-map-snapshot-rebuild):
 *    rebuilds the uids of one message, 8 at a time, sharing one profile
 *    cache; scales out with the message count.
 *
 * Deploy by name: getWorldMapSnapshot, rebuildWorldMapSnapshots,
 * rebuildWorldMapSnapshotsBatch (+ firestore rules + the index).
 */
import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onMessagePublished } from 'firebase-functions/v2/pubsub';
import { PubSub } from '@google-cloud/pubsub';
import '../shared/firebaseAdmin';
import { monitored } from '../shared/monitoring';
import {
  DueDoc,
  FAILED_RETRY_MS,
  FirestoreSnapshotReader,
  WORLD_MAP_MAINTENANCE_DOC,
  WORLD_MAP_REBUILD_TOPIC,
  WORLD_MAP_SNAPSHOTS,
  buildAndStore,
  decideOpen,
  dispatchDue,
  markerDue,
  processBatch,
  readStoredPins,
  snapshotRef,
  toMillis,
} from './worldMapSnapshot';

/* eslint-disable @typescript-eslint/no-explicit-any */

const db = admin.firestore();
const Timestamp = admin.firestore.Timestamp;

function response(doc: Record<string, any>, pins: any[], stale: boolean) {
  return {
    schema: doc.schema,
    builtAt: toMillis(doc.builtAt),
    pins,
    counts: doc.counts ?? null,
    stale,
  };
}

export const getWorldMapSnapshot = onCall(
  { memory: '512MiB', timeoutSeconds: 60 },
  monitored('getWorldMapSnapshot', async (request: any) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
    const touchOnly = request.data?.touchOnly === true;
    const nowMs = Date.now();
    const ref = snapshotRef(db, uid);
    const snap = await ref.get();
    const doc = snap.exists ? snap.data() : undefined;
    const marker = {
      active: true,
      lastOpenedAt: Timestamp.fromMillis(nowMs),
    };

    if (touchOnly) {
      if (markerDue(doc, nowMs)) {
        // A user coming back after a pause is due at once.
        await ref.set({ ...marker, ...(doc?.active === true ? {} : { refreshAfter: Timestamp.fromMillis(nowMs) }) },
          { merge: true });
      }
      return { ok: true };
    }

    const decision = decideOpen(doc, nowMs);
    if (decision !== 'build') {
      const pins = await readStoredPins(db, uid, doc!);
      if (pins) {
        if (markerDue(doc, nowMs)) await ref.set(marker, { merge: true });
        return response(doc!, pins, decision !== 'fresh');
      }
      // Chunks of another build: fall through to a rebuild.
    }

    // Claim the on-demand build (two parallel opens build once).
    const claimed = await db.runTransaction(async (tx) => {
      const cur = await tx.get(ref);
      const d = cur.exists ? cur.data() : undefined;
      if (decideOpen(d, nowMs) === 'stale-rate-limited') return false;
      // refreshAfter: a build that fails below is retried by the hourly
      // batch (a successful build overwrites it with builtAt + 55 min).
      tx.set(ref, {
        ...marker,
        lastOnDemandAt: Timestamp.fromMillis(nowMs),
        refreshAfter: Timestamp.fromMillis(nowMs + FAILED_RETRY_MS),
      }, { merge: true });
      return true;
    });
    if (!claimed) {
      const again = (await ref.get()).data();
      const pins = again ? await readStoredPins(db, uid, again) : null;
      if (again && pins) return response(again, pins, true);
      throw new HttpsError('resource-exhausted', 'Snapshot is being built, try again shortly.');
    }

    const built = await buildAndStore(db, new FirestoreSnapshotReader(db), uid, {
      nowMs,
      prevChunkCount: typeof doc?.chunkCount === 'number' ? doc.chunkCount : 0,
    });
    return {
      schema: 1,
      builtAt: built.builtAtMs,
      pins: built.pins,
      counts: built.counts,
      stale: false,
    };
  }),
);

let pubsub: PubSub | null = null;

export const rebuildWorldMapSnapshots = onSchedule(
  { schedule: 'every 60 minutes', timeZone: 'UTC', memory: '512MiB', timeoutSeconds: 540 },
  async () => {
    const nowMs = Date.now();
    pubsub ??= new PubSub();
    const topic = pubsub.topic(WORLD_MAP_REBUILD_TOPIC);
    const col = db.collection(WORLD_MAP_SNAPSHOTS);
    const result = await dispatchDue({
      async queryDue(dueBeforeMs, cursor, limit) {
        let q = col
          .where('active', '==', true)
          .where('refreshAfter', '<=', Timestamp.fromMillis(dueBeforeMs))
          .orderBy('refreshAfter', 'asc')
          .orderBy(admin.firestore.FieldPath.documentId(), 'asc')
          .select('lastOpenedAt', 'refreshAfter')
          .limit(limit);
        if (cursor) {
          q = q.startAfter(Timestamp.fromMillis(cursor.refreshAfterMs ?? 0), cursor.uid);
        }
        const s = await q.get();
        return s.docs.map((d): DueDoc => ({
          uid: d.id,
          lastOpenedAtMs: toMillis(d.get('lastOpenedAt')),
          refreshAfterMs: toMillis(d.get('refreshAfter')),
        }));
      },
      async deactivate(uids) {
        const w = db.bulkWriter();
        uids.forEach((u) => w.set(col.doc(u), { active: false }, { merge: true }));
        await w.close();
      },
      async publish(uids) {
        await topic.publishMessage({ json: { uids } });
      },
    }, nowMs);
    console.log(`rebuildWorldMapSnapshots: ${JSON.stringify(result)}`);
    await db.doc(WORLD_MAP_MAINTENANCE_DOC).set({
      lastRunAt: Timestamp.fromMillis(nowMs),
      lastRunDurationMs: Date.now() - nowMs,
      ...result,
    }, { merge: true });
  },
);

export const rebuildWorldMapSnapshotsBatch = onMessagePublished(
  { topic: WORLD_MAP_REBUILD_TOPIC, memory: '1GiB', timeoutSeconds: 540, concurrency: 1, maxInstances: 100 },
  async (event) => {
    const uids: unknown = (event.data.message.json as any)?.uids;
    if (!Array.isArray(uids)) return;
    const reader = new FirestoreSnapshotReader(db);
    const nowMs = Date.now();
    const r = await processBatch(uids.slice(0, 500) as string[], {
      load: async (uid) => {
        const s = await snapshotRef(db, uid).get();
        return s.exists ? s.data() : undefined;
      },
      build: async (uid, prevChunkCount) => {
        await buildAndStore(db, reader, uid, { prevChunkCount });
      },
      markFailed: async (uid) => {
        await snapshotRef(db, uid).set({
          refreshAfter: Timestamp.fromMillis(Date.now() + FAILED_RETRY_MS),
          lastBuildErrorAt: Timestamp.now(),
        }, { merge: true });
      },
    }, nowMs);
    console.log(`rebuildWorldMapSnapshotsBatch: ${JSON.stringify(r)}`);
  },
);
