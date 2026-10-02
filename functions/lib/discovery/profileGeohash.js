"use strict";
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
exports.backfillProfileGeohash = exports.PROFILE_GEOHASH_PRECISION = exports.PROFILE_GEOHASH_FIELD = void 0;
exports.discoverableGeohash = discoverableGeohash;
exports.runProfileGeohashBackfill = runProfileGeohashBackfill;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("../shared/utils");
const geohash_1 = require("../external_events/geohash");
exports.PROFILE_GEOHASH_FIELD = 'geohash';
exports.PROFILE_GEOHASH_PRECISION = 9;
const DEFAULT_PAGE_SIZE = 400;
const MAX_PAGE_SIZE = 500; // one batch commit per page
const TIME_BUDGET_MS = 480000; // stop well before the 540 s timeout
function toDate(v) {
    var _a;
    if (!v)
        return null;
    if (v instanceof Date)
        return v;
    if (v instanceof admin.firestore.Timestamp)
        return v.toDate();
    const o = v;
    if (typeof (o === null || o === void 0 ? void 0 : o.toDate) === 'function')
        return o.toDate();
    const secs = (_a = o === null || o === void 0 ? void 0 : o._seconds) !== null && _a !== void 0 ? _a : o === null || o === void 0 ? void 0 : o.seconds;
    if (typeof secs === 'number')
        return new Date(secs * 1000);
    return null;
}
function validCoords(lat, lng) {
    return (typeof lat === 'number' &&
        typeof lng === 'number' &&
        Number.isFinite(lat) &&
        Number.isFinite(lng) &&
        Math.abs(lat) <= 90 &&
        Math.abs(lng) <= 180 &&
        !(lat === 0 && lng === 0));
}
/** The geohash of the discoverable location in raw profile data, or null. */
function discoverableGeohash(data, now = new Date()) {
    if (!data)
        return null;
    const expiry = toDate(data.travelerExpiry);
    const travelerActive = data.isTraveler === true && expiry !== null && expiry.getTime() > now.getTime();
    const travel = data.travelerLocation;
    if (travelerActive && travel && typeof travel === 'object') {
        if (validCoords(travel.latitude, travel.longitude)) {
            return (0, geohash_1.geohashEncode)(travel.latitude, travel.longitude, exports.PROFILE_GEOHASH_PRECISION);
        }
    }
    const home = data.location;
    if (home && typeof home === 'object' && validCoords(home.latitude, home.longitude)) {
        return (0, geohash_1.geohashEncode)(home.latitude, home.longitude, exports.PROFILE_GEOHASH_PRECISION);
    }
    return null;
}
/** Admin = admin-panel user, rule-protected profile flag, or admin claim. */
async function assertAdmin(auth) {
    var _a, _b;
    if (!(auth === null || auth === void 0 ? void 0 : auth.uid))
        throw new https_1.HttpsError('unauthenticated', 'Sign in required');
    if (((_a = auth.token) === null || _a === void 0 ? void 0 : _a.admin) === true)
        return;
    const [adminDoc, profileDoc] = await Promise.all([
        utils_1.db.collection('admin_users').doc(auth.uid).get(),
        utils_1.db.collection('profiles').doc(auth.uid).get(),
    ]);
    if (adminDoc.exists || ((_b = profileDoc.data()) === null || _b === void 0 ? void 0 : _b.isAdmin) === true)
        return;
    throw new https_1.HttpsError('permission-denied', 'Admin only');
}
/**
 * Core loop, exported so scripts/backfill_profile_geohash.js can run the
 * exact same logic with a service account.
 */
async function runProfileGeohashBackfill(opts) {
    var _a, _b, _c, _d, _e;
    const fs = (_a = opts.firestore) !== null && _a !== void 0 ? _a : utils_1.db;
    const pageSize = Math.min(Math.max((_b = opts.pageSize) !== null && _b !== void 0 ? _b : DEFAULT_PAGE_SIZE, 1), MAX_PAGE_SIZE);
    const maxPages = Math.max((_c = opts.maxPages) !== null && _c !== void 0 ? _c : Number.MAX_SAFE_INTEGER, 1);
    const budget = (_d = opts.timeBudgetMs) !== null && _d !== void 0 ? _d : TIME_BUDGET_MS;
    const dryRun = opts.dryRun === true;
    const started = Date.now();
    const now = new Date();
    let cursor = (_e = opts.startAfter) !== null && _e !== void 0 ? _e : null;
    let scanned = 0;
    let updated = 0;
    let cleared = 0;
    let pages = 0;
    for (;;) {
        let q = fs
            .collection('profiles')
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(pageSize);
        if (cursor)
            q = q.startAfter(cursor);
        const snap = await q.get();
        if (snap.empty)
            return { scanned, updated, cleared, done: true, startAfter: null, dryRun };
        const batch = fs.batch();
        let writes = 0;
        for (const doc of snap.docs) {
            scanned++;
            const data = doc.data();
            const want = discoverableGeohash(data, now);
            const have = typeof data[exports.PROFILE_GEOHASH_FIELD] === 'string' ? data[exports.PROFILE_GEOHASH_FIELD] : null;
            if (want === have)
                continue;
            if (want) {
                batch.update(doc.ref, { [exports.PROFILE_GEOHASH_FIELD]: want });
                updated++;
            }
            else {
                // Location became unknown: drop the stale cell.
                batch.update(doc.ref, { [exports.PROFILE_GEOHASH_FIELD]: utils_1.FieldValue.delete() });
                cleared++;
            }
            writes++;
        }
        if (writes > 0 && !dryRun)
            await batch.commit();
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
exports.backfillProfileGeohash = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 540 }, async (request) => {
    var _a, _b;
    await assertAdmin(request.auth);
    const d = ((_a = request.data) !== null && _a !== void 0 ? _a : {});
    try {
        const result = await runProfileGeohashBackfill({
            startAfter: typeof d.startAfter === 'string' && d.startAfter ? d.startAfter : null,
            pageSize: typeof d.pageSize === 'number' ? d.pageSize : undefined,
            maxPages: typeof d.maxPages === 'number' ? d.maxPages : undefined,
            dryRun: d.dryRun === true,
        });
        (0, utils_1.logInfo)(`backfillProfileGeohash: ${JSON.stringify(result)}`);
        return result;
    }
    catch (e) {
        (0, utils_1.logError)(`backfillProfileGeohash failed: ${(_b = e === null || e === void 0 ? void 0 : e.message) !== null && _b !== void 0 ? _b : e}`);
        throw new https_1.HttpsError('internal', 'Backfill failed');
    }
});
//# sourceMappingURL=profileGeohash.js.map