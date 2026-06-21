"use strict";
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
exports.ingestExternalEvents = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const db = admin.firestore();
const COLLECTION = 'external_events';
// Curated destination seed list. Viator destinationId + Tiqets cityId differ,
// so each entry carries both. Extend freely; ingestion is bounded by this list.
const CITIES = [
    { city: 'Rome', country: 'IT', viatorDestId: '511', tiqetsCityId: 67 },
    { city: 'Paris', country: 'FR', viatorDestId: '479', tiqetsCityId: 66746 },
    { city: 'London', country: 'GB', viatorDestId: '737', tiqetsCityId: 66744 },
    { city: 'Barcelona', country: 'ES', viatorDestId: '562', tiqetsCityId: 71993 },
    { city: 'New York', country: 'US', viatorDestId: '687', tiqetsCityId: 66745 },
    { city: 'Tokyo', country: 'JP', viatorDestId: '334' },
    { city: 'Amsterdam', country: 'NL', viatorDestId: '525', tiqetsCityId: 75061 },
    { city: 'Dubai', country: 'AE', viatorDestId: '828' },
];
async function upsertAll(docs) {
    let batch = db.batch();
    let ops = 0;
    const commits = [];
    const now = admin.firestore.FieldValue.serverTimestamp();
    for (const { id, data } of docs) {
        batch.set(db.collection(COLLECTION).doc(id), Object.assign(Object.assign({}, data), { updatedAt: now }), { merge: true });
        if (++ops >= 400) {
            commits.push(batch.commit());
            batch = db.batch();
            ops = 0;
        }
    }
    if (ops > 0)
        commits.push(batch.commit());
    await Promise.all(commits);
}
async function fetchViator(apiKey, c) {
    if (!c.viatorDestId)
        return [];
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
        if (!res.ok)
            return [];
        const json = await res.json();
        const products = json.products || [];
        return products.map((p) => {
            var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q, _r, _s, _t;
            const img = (_e = (_d = (_c = (_b = (_a = p.images) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.variants) === null || _c === void 0 ? void 0 : _c.slice(-1)) === null || _d === void 0 ? void 0 : _d[0]) === null || _e === void 0 ? void 0 : _e.url;
            return {
                id: `viator_${p.productCode}`,
                data: {
                    source: 'viator',
                    externalId: p.productCode,
                    title: p.title,
                    description: (_f = p.description) !== null && _f !== void 0 ? _f : null,
                    imageUrl: img !== null && img !== void 0 ? img : null,
                    category: 'tour',
                    city: c.city,
                    country: c.country,
                    fromPrice: (_j = (_h = (_g = p.pricing) === null || _g === void 0 ? void 0 : _g.summary) === null || _h === void 0 ? void 0 : _h.fromPrice) !== null && _j !== void 0 ? _j : null,
                    currency: (_l = (_k = p.pricing) === null || _k === void 0 ? void 0 : _k.currency) !== null && _l !== void 0 ? _l : 'USD',
                    rating: (_o = (_m = p.reviews) === null || _m === void 0 ? void 0 : _m.combinedAverageRating) !== null && _o !== void 0 ? _o : null,
                    reviewCount: (_q = (_p = p.reviews) === null || _p === void 0 ? void 0 : _p.totalReviews) !== null && _q !== void 0 ? _q : null,
                    durationMinutes: (_s = (_r = p.duration) === null || _r === void 0 ? void 0 : _r.fixedDurationInMinutes) !== null && _s !== void 0 ? _s : null,
                    bookingUrl: (_t = p.productUrl) !== null && _t !== void 0 ? _t : null,
                    fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
                },
            };
        });
    }
    catch (e) {
        console.error(`Viator fetch failed for ${c.city}`, e);
        return [];
    }
}
async function fetchTiqets(apiKey, c) {
    if (!c.tiqetsCityId)
        return [];
    try {
        const res = await fetch(`https://api.tiqets.com/v2/products?city_id=${c.tiqetsCityId}&page_size=30`, { headers: { Authorization: `Token ${apiKey}`, Accept: 'application/json' } });
        if (!res.ok)
            return [];
        const json = await res.json();
        const products = json.products || [];
        return products.map((p) => {
            var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q, _r, _s, _t, _u, _v;
            return ({
                id: `tiqets_${p.id}`,
                data: {
                    source: 'tiqets',
                    externalId: String(p.id),
                    title: p.title,
                    description: (_a = p.tagline) !== null && _a !== void 0 ? _a : null,
                    imageUrl: (_g = (_d = (_c = (_b = p.images) === null || _b === void 0 ? void 0 : _b[0]) === null || _c === void 0 ? void 0 : _c.large) !== null && _d !== void 0 ? _d : (_f = (_e = p.images) === null || _e === void 0 ? void 0 : _e[0]) === null || _f === void 0 ? void 0 : _f.medium) !== null && _g !== void 0 ? _g : null,
                    category: 'museum',
                    city: (_j = (_h = p.city) === null || _h === void 0 ? void 0 : _h.name) !== null && _j !== void 0 ? _j : c.city,
                    country: (_m = (_l = (_k = p.city) === null || _k === void 0 ? void 0 : _k.country) === null || _l === void 0 ? void 0 : _l.code) !== null && _m !== void 0 ? _m : c.country,
                    fromPrice: ((_o = p.price) === null || _o === void 0 ? void 0 : _o.amount) ? Number(p.price.amount) : null,
                    currency: (_q = (_p = p.price) === null || _p === void 0 ? void 0 : _p.currency) !== null && _q !== void 0 ? _q : 'EUR',
                    rating: (_s = (_r = p.ratings) === null || _r === void 0 ? void 0 : _r.average) !== null && _s !== void 0 ? _s : null,
                    reviewCount: (_u = (_t = p.ratings) === null || _t === void 0 ? void 0 : _t.count) !== null && _u !== void 0 ? _u : null,
                    bookingUrl: (_v = p.product_url) !== null && _v !== void 0 ? _v : null,
                    fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
                },
            });
        });
    }
    catch (e) {
        console.error(`Tiqets fetch failed for ${c.city}`, e);
        return [];
    }
}
exports.ingestExternalEvents = (0, scheduler_1.onSchedule)(
// Twice per day — refresh the cached experiences (one ingestion run per
// schedule, not per-user). Data is persisted in `external_events` and read
// by the app cache-first.
{ schedule: 'every 12 hours', timeoutSeconds: 540, memory: '512MiB' }, async () => {
    const viatorKey = process.env.VIATOR_API_KEY || '';
    const tiqetsKey = process.env.TIQETS_API_KEY || '';
    if (!viatorKey && !tiqetsKey) {
        console.log('ingestExternalEvents: no provider keys set — skipping.');
        return;
    }
    const all = [];
    for (const c of CITIES) {
        if (viatorKey)
            all.push(...(await fetchViator(viatorKey, c)));
        if (tiqetsKey)
            all.push(...(await fetchTiqets(tiqetsKey, c)));
    }
    if (all.length > 0)
        await upsertAll(all);
    console.log(`ingestExternalEvents: upserted ${all.length} experiences.`);
});
//# sourceMappingURL=ingest.js.map