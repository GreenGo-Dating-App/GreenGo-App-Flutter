/**
 * Geohash support for `external_events` so the app can query nearest-first
 * straight from the DB (server-ordered, paginated) instead of sorting on the
 * client. Standard geohash (base32, longitude on even bits) — must match the
 * client's geohashForLocation in lib/core/utils/geo_query.dart.
 */

import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';

const db = admin.firestore();
const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

/** Encode a coordinate to a geohash of [precision] chars. */
export function geohashEncode(lat: number, lng: number, precision = 9): string {
  let idx = 0;
  let bit = 0;
  let evenBit = true;
  let geohash = '';
  let latMin = -90;
  let latMax = 90;
  let lngMin = -180;
  let lngMax = 180;
  while (geohash.length < precision) {
    if (evenBit) {
      const mid = (lngMin + lngMax) / 2;
      if (lng >= mid) {
        idx = idx * 2 + 1;
        lngMin = mid;
      } else {
        idx = idx * 2;
        lngMax = mid;
      }
    } else {
      const mid = (latMin + latMax) / 2;
      if (lat >= mid) {
        idx = idx * 2 + 1;
        latMin = mid;
      } else {
        idx = idx * 2;
        latMax = mid;
      }
    }
    evenBit = !evenBit;
    if (++bit === 5) {
      geohash += BASE32[idx];
      bit = 0;
      idx = 0;
    }
  }
  return geohash;
}

// Reuse existing source keys as the admin token for the manual trigger.
const VIATOR_API_KEY = defineSecret('VIATOR_API_KEY');
const TICKETMASTER_API_KEY = defineSecret('TICKETMASTER_API_KEY');
const GEOAPIFY_API_KEY = defineSecret('GEOAPIFY_API_KEY');

/** One-time backfill: set `geohash` on every external_events doc that has
 *  coordinates but no geohash yet. Internal Firestore only (no external API). */
export const runBackfillGeohashNow = onRequest(
  {
    timeoutSeconds: 1800,
    memory: '512MiB',
    secrets: [VIATOR_API_KEY, TICKETMASTER_API_KEY, GEOAPIFY_API_KEY],
  },
  async (req, res) => {
    const token = req.query.token;
    const valid =
      token === VIATOR_API_KEY.value() ||
      token === TICKETMASTER_API_KEY.value() ||
      token === GEOAPIFY_API_KEY.value();
    if (!token || !valid) {
      res.status(403).send('Forbidden');
      return;
    }
    const force = !!req.query.force; // recompute even if geohash exists
    let cursor: FirebaseFirestore.QueryDocumentSnapshot | undefined;
    let updated = 0;
    let scanned = 0;
    for (;;) {
      let q = db
        .collection('external_events')
        .orderBy('__name__')
        .limit(500);
      if (cursor) q = q.startAfter(cursor);
      const snap = await q.get();
      if (snap.empty) break;
      let batch = db.batch();
      let ops = 0;
      for (const doc of snap.docs) {
        scanned++;
        const d = doc.data();
        const lat = d.lat as number | undefined;
        const lng = d.lng as number | undefined;
        if (typeof lat !== 'number' || typeof lng !== 'number') continue;
        if (!force && typeof d.geohash === 'string' && d.geohash.length > 0) {
          continue;
        }
        batch.set(doc.ref, { geohash: geohashEncode(lat, lng) }, { merge: true });
        if (++ops >= 400) {
          await batch.commit();
          updated += ops;
          batch = db.batch();
          ops = 0;
        }
      }
      if (ops > 0) {
        await batch.commit();
        updated += ops;
      }
      cursor = snap.docs[snap.docs.length - 1];
      if (snap.docs.length < 500) break;
    }
    console.log(`backfillGeohash: ${updated} updated / ${scanned} scanned.`);
    res.status(200).json({ ok: true, scanned, updated });
  }
);
