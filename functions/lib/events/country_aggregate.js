"use strict";
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
exports.onEventWriteUpdateCountryStats = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
require("../shared/firebaseAdmin");
const db = admin.firestore();
const PREVIEW_LIMIT = 3;
async function recomputeCountry(country) {
    if (!country)
        return;
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
    }
    catch (e) {
        console.error('country count failed', country, e);
    }
    // Top-N preview by popularity.
    const topSnap = await base
        .orderBy('attendeeCount', 'desc')
        .limit(PREVIEW_LIMIT)
        .get();
    const topEvents = topSnap.docs.map((d) => {
        var _a, _b, _c, _d, _e;
        const e = d.data();
        return {
            id: d.id,
            title: (_a = e.title) !== null && _a !== void 0 ? _a : '',
            imageUrl: (_b = e.imageUrl) !== null && _b !== void 0 ? _b : null,
            attendeeCount: (_c = e.attendeeCount) !== null && _c !== void 0 ? _c : 0,
            city: (_d = e.city) !== null && _d !== void 0 ? _d : null,
            startDate: (_e = e.startDate) !== null && _e !== void 0 ? _e : null,
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
exports.onEventWriteUpdateCountryStats = (0, firestore_1.onDocumentWritten)('events/{eventId}', (0, monitoring_1.monitored)("onEventWriteUpdateCountryStats", async (event) => {
    var _a, _b;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    // Recompute every country touched by this write (handles country changes).
    const countries = new Set();
    const b = before === null || before === void 0 ? void 0 : before.country;
    const a = after === null || after === void 0 ? void 0 : after.country;
    if (b)
        countries.add(b);
    if (a)
        countries.add(a);
    if (countries.size === 0)
        return;
    await Promise.all([...countries].map(recomputeCountry));
}));
//# sourceMappingURL=country_aggregate.js.map