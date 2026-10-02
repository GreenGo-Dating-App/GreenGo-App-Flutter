/**
 * Profile geohash backfill.
 *
 * `profiles/{uid}.geohash` is the 9-char geohash of the profile's
 * DISCOVERABLE location: the active travel location while traveller mode is
 * on (isTraveler && travelerExpiry > now), else the home `location`. The app
 * writes it whenever the profile location is saved (ProfileModel.toJson,
 * traveller toggle) and queries it nearest-first with
 * `orderBy('geohash').startAt().endAt()` range reads (GeoQuery.queryBounds).
 * Rules MUST match lib/features/profile/data/profile_geohash.dart.
 *
 * There is deliberately NO onWrite trigger on `profiles` (one of the hottest
 * collections: presence, lastSeen, counters). Existing documents are filled in
 * by this admin-only callable instead.
 *
 * Resumable WITHOUT a saved offset: every call scans the collection in
 * document-id order and recomputes the geohash of each doc, writing only the
 * docs whose stored value is missing or differs. Nothing is persisted between
 * calls; the optional `startAfter` cursor in the response is only a hint to
 * continue a run that hit its time budget. Restarting from scratch (no
 * cursor) is always correct — already-correct docs are read but not written —
 * so an interrupted run can never silently skip the remainder. Re-running it
 * later also re-centres expired travellers on their home location.
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { db, FieldValue, logInfo, logError } from '../shared/utils';
import { geohashEncode } from '../external_events/geohash';

export const PROFILE_GEOHASH_FIELD = 'geohash';
export const PROFILE_GEOHASH_PRECISION = 9;

const DEFAULT_PAGE_SIZE = 400;
const MAX_PAGE_SIZE = 500; // one batch commit per page
const TIME_BUDGET_MS = 480_000; // stop well before the 540 s timeout

function toDate(v: unknown): Date | null {
  if (!v) return null;
  if (v instanceof Date) return v;
  if (v instanceof admin.firestore.Timestamp) return v.toDate();
  const o = v as any;
  if (typeof o?.toDate === 'function') return o.toDate();
  const secs = o?._seconds ?? o?.seconds;
  if (typeof secs === 'number') return new Date(secs * 1000);
  return null;
}

function validCoords(lat: unknown, lng: unknown): lat is number {
  return (
    typeof lat === 'number' &&
    typeof lng === 'number' &&
    Number.isFinite(lat) &&
    Number.isFinite(lng) &&
    Math.abs(lat) <= 90 &&
    Math.abs(lng) <= 180 &&
    !(lat === 0 && lng === 0)
  );
}

/** The geohash of the discoverable location in raw profile data, or null. */
export function discoverableGeohash(
  data: Record<string, any> | undefined,
  now: Date = new Date(),
): string | null {
  if (!data) return null;
  const expiry = toDate(data.travelerExpiry);
  const travelerActive =
    data.isTraveler === true && expiry !== null && expiry.getTime() > now.getTime();
  const travel = data.travelerLocation;
  if (travelerActive && travel && typeof travel === 'object') {
    if (validCoords(travel.latitude, travel.longitude)) {
      return geohashEncode(travel.latitude, travel.longitude, PROFILE_GEOHASH_PRECISION);
    }
  }
  const home = data.location;
  if (home && typeof home === 'object' && validCoords(home.latitude, home.longitude)) {
    return geohashEncode(home.latitude, home.longitude, PROFILE_GEOHASH_PRECISION);
  }
  return null;
}

/** Admin = admin-panel user, rule-protected profile flag, or admin claim. */
async function assertAdmin(auth: { uid: string; token: Record<string, any> } | undefined) {
  if (!auth?.uid) throw new HttpsError('unauthenticated', 'Sign in required');
  if (auth.token?.admin === true) return;
  const [adminDoc, profileDoc] = await Promise.all([
    db.collection('admin_users').doc(auth.uid).get(),
    db.collection('profiles').doc(auth.uid).get(),
  ]);
  if (adminDoc.exists || profileDoc.data()?.isAdmin === true) return;
  throw new HttpsError('permission-denied', 'Admin only');
}

export interface BackfillResult {
  scanned: number;
  updated: number;
  cleared: number;
  done: boolean;
  /** Continue from here on the next call (only a hint; omit to restart). */
  startAfter: string | null;
  dryRun: boolean;
}

/**
 * Core loop, exported so scripts/backfill_profile_geohash.js can run the
 * exact same logic with a service account.
 */
export async function runProfileGeohashBackfill(opts: {
  startAfter?: string | null;
  pageSize?: number;
  maxPages?: number;
  dryRun?: boolean;
  timeBudgetMs?: number;
  firestore?: admin.firestore.Firestore;
}): Promise<BackfillResult> {
  const fs = opts.firestore ?? db;
  const pageSize = Math.min(Math.max(opts.pageSize ?? DEFAULT_PAGE_SIZE, 1), MAX_PAGE_SIZE);
  const maxPages = Math.max(opts.maxPages ?? Number.MAX_SAFE_INTEGER, 1);
  const budget = opts.timeBudgetMs ?? TIME_BUDGET_MS;
  const dryRun = opts.dryRun === true;
  const started = Date.now();
  const now = new Date();

  let cursor: string | null = opts.startAfter ?? null;
  let scanned = 0;
  let updated = 0;
  let cleared = 0;
  let pages = 0;

  for (;;) {
    let q = fs
      .collection('profiles')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(pageSize);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.get();
    if (snap.empty) return { scanned, updated, cleared, done: true, startAfter: null, dryRun };

    const batch = fs.batch();
    let writes = 0;
    for (const doc of snap.docs) {
      scanned++;
      const data = doc.data();
      const want = discoverableGeohash(data, now);
      const have = typeof data[PROFILE_GEOHASH_FIELD] === 'string' ? data[PROFILE_GEOHASH_FIELD] : null;
      if (want === have) continue;
      if (want) {
        batch.update(doc.ref, { [PROFILE_GEOHASH_FIELD]: want });
        updated++;
      } else {
        // Location became unknown: drop the stale cell.
        batch.update(doc.ref, { [PROFILE_GEOHASH_FIELD]: FieldValue.delete() });
        cleared++;
      }
      writes++;
    }
    if (writes > 0 && !dryRun) await batch.commit();

    cursor = snap.docs[snap.docs.length - 1].id;
    pages++;
    if (snap.size < pageSize) {
      return { scanned, updated, cleared, done: true, startAfter: null, dryRun };
    }
    if (pages >= maxPages || Date.now() - started > budget) {
      return { scanned, updated, cleared, done: false, startAfter: cursor, dryRun };
    }
  }
}

/**
 * Admin-only. Data: `{ startAfter?: string, pageSize?: number,
 * maxPages?: number, dryRun?: boolean }`. Call repeatedly, passing back
 * `startAfter`, until `done` is true (or just call again without it).
 */
export const backfillProfileGeohash = onCall(
  { memory: '512MiB', timeoutSeconds: 540 },
  async (request) => {
    await assertAdmin(request.auth as any);
    const d = (request.data ?? {}) as Record<string, unknown>;
    try {
      const result = await runProfileGeohashBackfill({
        startAfter: typeof d.startAfter === 'string' && d.startAfter ? d.startAfter : null,
        pageSize: typeof d.pageSize === 'number' ? d.pageSize : undefined,
        maxPages: typeof d.maxPages === 'number' ? d.maxPages : undefined,
        dryRun: d.dryRun === true,
      });
      logInfo(`backfillProfileGeohash: ${JSON.stringify(result)}`);
      return result;
    } catch (e: any) {
      logError(`backfillProfileGeohash failed: ${e?.message ?? e}`);
      throw new HttpsError('internal', 'Backfill failed');
    }
  },
);
