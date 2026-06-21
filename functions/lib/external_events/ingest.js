"use strict";
/**
 * External experiences ingester (Viator only).
 *
 * On a schedule, pulls bookable experiences from Viator (tours, activities,
 * attraction tickets) for a curated list of destinations and upserts them into
 * the `external_events` collection. The app reads that collection (cache-first)
 * and deep-links out to Viator to book — so API calls stay bounded (a few
 * hundred per run, NOT per user) and scale to millions of users.
 *
 * The Viator API key is stored as a Functions secret (VIATOR_API_KEY). If it is
 * not set the run no-ops, so this deploys safely before the secret exists.
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
exports.runIngestExternalEventsNow = exports.ingestExternalEvents = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const db = admin.firestore();
const COLLECTION = 'external_events';
const VIATOR_API_KEY = (0, params_1.defineSecret)('VIATOR_API_KEY');
// Curated Viator destinationIds. Extend freely; ingestion is bounded by this.
const DESTINATIONS = [
    { city: 'Rome', country: 'IT', viatorDestId: '511' },
    { city: 'Paris', country: 'FR', viatorDestId: '479' },
    { city: 'London', country: 'GB', viatorDestId: '737' },
    { city: 'Barcelona', country: 'ES', viatorDestId: '562' },
    { city: 'New York', country: 'US', viatorDestId: '687' },
    { city: 'Tokyo', country: 'JP', viatorDestId: '334' },
    { city: 'Amsterdam', country: 'NL', viatorDestId: '525' },
    { city: 'Dubai', country: 'AE', viatorDestId: '828' },
    { city: 'Lisbon', country: 'PT', viatorDestId: '538' },
    { city: 'Berlin', country: 'DE', viatorDestId: '488' },
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
// Production first; fresh keys are often sandbox-only until prod access lands.
const VIATOR_BASES = [
    'https://api.viator.com/partner',
    'https://api.sandbox.viator.com/partner',
];
async function fetchViator(apiKey, d, base) {
    try {
        const res = await fetch(`${base}/products/search`, {
            method: 'POST',
            headers: {
                'exp-api-key': apiKey,
                Accept: 'application/json;version=2.0',
                'Accept-Language': 'en-US',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                filtering: { destination: d.viatorDestId },
                sorting: { sort: 'TRAVELER_RATING', order: 'DESCENDING' },
                pagination: { start: 1, count: 30 },
                currency: 'USD',
            }),
        });
        if (!res.ok) {
            console.error(`Viator ${d.city} HTTP ${res.status}`);
            return [];
        }
        const json = await res.json();
        const products = json.products || [];
        return products.map((p) => {
            var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q, _r;
            const variants = ((_b = (_a = p.images) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.variants) || [];
            const img = variants.length ? (_c = variants[variants.length - 1]) === null || _c === void 0 ? void 0 : _c.url : undefined;
            return {
                id: `viator_${p.productCode}`,
                data: {
                    source: 'viator',
                    externalId: p.productCode,
                    title: p.title,
                    description: (_d = p.description) !== null && _d !== void 0 ? _d : null,
                    imageUrl: img !== null && img !== void 0 ? img : null,
                    category: 'tour',
                    city: d.city,
                    country: d.country,
                    fromPrice: (_g = (_f = (_e = p.pricing) === null || _e === void 0 ? void 0 : _e.summary) === null || _f === void 0 ? void 0 : _f.fromPrice) !== null && _g !== void 0 ? _g : null,
                    currency: (_j = (_h = p.pricing) === null || _h === void 0 ? void 0 : _h.currency) !== null && _j !== void 0 ? _j : 'USD',
                    rating: (_l = (_k = p.reviews) === null || _k === void 0 ? void 0 : _k.combinedAverageRating) !== null && _l !== void 0 ? _l : null,
                    reviewCount: (_o = (_m = p.reviews) === null || _m === void 0 ? void 0 : _m.totalReviews) !== null && _o !== void 0 ? _o : null,
                    durationMinutes: (_q = (_p = p.duration) === null || _p === void 0 ? void 0 : _p.fixedDurationInMinutes) !== null && _q !== void 0 ? _q : null,
                    bookingUrl: (_r = p.productUrl) !== null && _r !== void 0 ? _r : null,
                    fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
                },
            };
        });
    }
    catch (e) {
        console.error(`Viator fetch failed for ${d.city}`, e);
        return [];
    }
}
async function runIngestion(apiKey) {
    if (!apiKey) {
        console.log('ingestExternalEvents: VIATOR_API_KEY not set — skipping.');
        return 0;
    }
    for (const base of VIATOR_BASES) {
        const all = [];
        for (const d of DESTINATIONS) {
            all.push(...(await fetchViator(apiKey, d, base)));
        }
        if (all.length > 0) {
            await upsertAll(all);
            console.log(`ingestExternalEvents: upserted ${all.length} Viator experiences from ${base}.`);
            return all.length;
        }
        console.log(`ingestExternalEvents: no results from ${base}, trying next.`);
    }
    console.log('ingestExternalEvents: no Viator results from any base.');
    return 0;
}
// Scheduled refresh, every 12 hours.
exports.ingestExternalEvents = (0, scheduler_1.onSchedule)({
    schedule: 'every 12 hours',
    timeoutSeconds: 540,
    memory: '512MiB',
    secrets: [VIATOR_API_KEY],
}, async () => {
    await runIngestion(VIATOR_API_KEY.value());
});
// Curated real, public Viator experiences — used to seed `external_events` for
// a working demo until the live API key is activated. Real titles + booking
// URLs (viator.com); replaced by live API data once the key works.
const SEED_DOCS = [
    {
        id: 'viator_seed_rome_colosseum',
        data: {
            source: 'viator', externalId: 'seed_rome_colosseum',
            title: 'Colosseum, Roman Forum & Palatine Hill Skip-the-Line Tour',
            category: 'tour', city: 'Rome', country: 'IT',
            imageUrl: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&q=80',
            fromPrice: 54, currency: 'EUR', rating: 4.6, reviewCount: 12890,
            durationMinutes: 180, bookingUrl: 'https://www.viator.com/Rome-tours/d511',
        },
    },
    {
        id: 'viator_seed_paris_eiffel',
        data: {
            source: 'viator', externalId: 'seed_paris_eiffel',
            title: 'Eiffel Tower Summit Access by Elevator',
            category: 'attraction', city: 'Paris', country: 'FR',
            imageUrl: 'https://images.unsplash.com/photo-1543349689-9a4d426bee8e?w=800&q=80',
            fromPrice: 69, currency: 'EUR', rating: 4.5, reviewCount: 8742,
            durationMinutes: 120, bookingUrl: 'https://www.viator.com/Paris-tours/d479',
        },
    },
    {
        id: 'viator_seed_tokyo_food',
        data: {
            source: 'viator', externalId: 'seed_tokyo_food',
            title: 'Tokyo by Night: Food & Culture Walking Tour',
            category: 'experience', city: 'Tokyo', country: 'JP',
            imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&q=80',
            fromPrice: 95, currency: 'USD', rating: 4.9, reviewCount: 2103,
            durationMinutes: 180, bookingUrl: 'https://www.viator.com/Tokyo-tours/d334',
        },
    },
    {
        id: 'viator_seed_barcelona_sagrada',
        data: {
            source: 'viator', externalId: 'seed_barcelona_sagrada',
            title: 'Sagrada Família Fast-Track Guided Tour',
            category: 'attraction', city: 'Barcelona', country: 'ES',
            imageUrl: 'https://images.unsplash.com/photo-1583779457094-ab6f9164a1c8?w=800&q=80',
            fromPrice: 49, currency: 'EUR', rating: 4.8, reviewCount: 15420,
            durationMinutes: 90, bookingUrl: 'https://www.viator.com/Barcelona-tours/d562',
        },
    },
    {
        id: 'viator_seed_nyc_skyline',
        data: {
            source: 'viator', externalId: 'seed_nyc_skyline',
            title: 'New York Skyline: Empire State Building Skip-the-Line',
            category: 'attraction', city: 'New York', country: 'US',
            imageUrl: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=800&q=80',
            fromPrice: 48, currency: 'USD', rating: 4.5, reviewCount: 9981,
            durationMinutes: 90, bookingUrl: 'https://www.viator.com/New-York-City-tours/d687',
        },
    },
    {
        id: 'viator_seed_dubai_desert',
        data: {
            source: 'viator', externalId: 'seed_dubai_desert',
            title: 'Dubai Red Dunes Desert Safari with BBQ Dinner',
            category: 'experience', city: 'Dubai', country: 'AE',
            imageUrl: 'https://images.unsplash.com/photo-1451337516015-6b6e9a44a8a3?w=800&q=80',
            fromPrice: 35, currency: 'USD', rating: 4.7, reviewCount: 6210,
            durationMinutes: 360, bookingUrl: 'https://www.viator.com/Dubai-tours/d828',
        },
    },
];
// Manual trigger (admin), guarded by the Viator key as token:
//   ?token=<KEY>          → pull live data now
//   ?token=<KEY>&seed=1   → seed curated demo experiences into external_events
exports.runIngestExternalEventsNow = (0, https_1.onRequest)({ timeoutSeconds: 540, memory: '512MiB', secrets: [VIATOR_API_KEY] }, async (req, res) => {
    const key = VIATOR_API_KEY.value();
    if (!key || req.query.token !== key) {
        res.status(403).send('Forbidden');
        return;
    }
    if (req.query.seed === '1') {
        await upsertAll(SEED_DOCS);
        res.status(200).json({ ok: true, seeded: SEED_DOCS.length });
        return;
    }
    const count = await runIngestion(key);
    res.status(200).json({ ok: true, upserted: count });
});
//# sourceMappingURL=ingest.js.map