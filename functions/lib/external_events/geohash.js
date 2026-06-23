"use strict";
/**
 * Geohash support for `external_events` so the app can query nearest-first
 * straight from the DB (server-ordered, paginated) instead of sorting on the
 * client. Standard geohash (base32, longitude on even bits) — must match the
 * client's geohashForLocation in lib/core/utils/geo_query.dart.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.runBackfillGeohashNow = void 0;
exports.geohashEncode = geohashEncode;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const db = admin.firestore();
const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';
/** Encode a coordinate to a geohash of [precision] chars. */
function geohashEncode(lat, lng, precision = 9) {
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
            }
            else {
                idx = idx * 2;
                lngMax = mid;
            }
        }
        else {
            const mid = (latMin + latMax) / 2;
            if (lat >= mid) {
                idx = idx * 2 + 1;
                latMin = mid;
            }
            else {
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
const VIATOR_API_KEY = (0, params_1.defineSecret)('VIATOR_API_KEY');
const TICKETMASTER_API_KEY = (0, params_1.defineSecret)('TICKETMASTER_API_KEY');
const GEOAPIFY_API_KEY = (0, params_1.defineSecret)('GEOAPIFY_API_KEY');
/** One-time backfill: set `geohash` on every external_events doc that has
 *  coordinates but no geohash yet. Internal Firestore only (no external API). */
exports.runBackfillGeohashNow = (0, https_1.onRequest)({
    timeoutSeconds: 1800,
    memory: '512MiB',
    secrets: [VIATOR_API_KEY, TICKETMASTER_API_KEY, GEOAPIFY_API_KEY],
}, async (req, res) => {
    const token = req.query.token;
    const valid = token === VIATOR_API_KEY.value() ||
        token === TICKETMASTER_API_KEY.value() ||
        token === GEOAPIFY_API_KEY.value();
    if (!token || !valid) {
        res.status(403).send('Forbidden');
        return;
    }
    const force = !!req.query.force; // recompute even if geohash exists
    let cursor;
    let updated = 0;
    let scanned = 0;
    for (;;) {
        let q = db
            .collection('external_events')
            .orderBy('__name__')
            .limit(500);
        if (cursor)
            q = q.startAfter(cursor);
        const snap = await q.get();
        if (snap.empty)
            break;
        let batch = db.batch();
        let ops = 0;
        for (const doc of snap.docs) {
            scanned++;
            const d = doc.data();
            const lat = d.lat;
            const lng = d.lng;
            if (typeof lat !== 'number' || typeof lng !== 'number')
                continue;
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
        if (snap.docs.length < 500)
            break;
    }
    console.log(`backfillGeohash: ${updated} updated / ${scanned} scanned.`);
    res.status(200).json({ ok: true, scanned, updated });
});
//# sourceMappingURL=geohash.js.map