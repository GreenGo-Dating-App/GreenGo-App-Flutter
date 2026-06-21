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
// Top 50 tourism countries worldwide. We match these to Viator's COUNTRY
// destinations dynamically (no hardcoded ids) and pull the top 10 experiences
// for each — so the feed is ~500 top-rated experiences across 50 countries.
const TOP_COUNTRIES = [
    'France', 'Spain', 'United States', 'Italy', 'Turkey', 'Mexico',
    'United Kingdom', 'Germany', 'Greece', 'Austria', 'Japan', 'Thailand',
    'Portugal', 'Netherlands', 'Croatia', 'United Arab Emirates', 'Canada',
    'Australia', 'China', 'Egypt', 'India', 'Indonesia', 'Vietnam',
    'Switzerland', 'Czech Republic', 'Poland', 'Ireland', 'Morocco',
    'South Africa', 'Brazil', 'Argentina', 'Peru', 'Iceland', 'Hungary',
    'Belgium', 'Denmark', 'Sweden', 'Norway', 'Singapore', 'Malaysia',
    'Philippines', 'South Korea', 'New Zealand', 'Israel', 'Jordan',
    'Cambodia', 'Costa Rica', 'Colombia', 'Chile', 'Saudi Arabia',
];
const PRODUCTS_PER_COUNTRY = 100;
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
/// Delete all external_events for a source (so a re-feed replaces, not merges,
/// the previous set). Batched; loops until the source is empty.
async function clearSource(source) {
    let total = 0;
    for (;;) {
        const snap = await db
            .collection(COLLECTION)
            .where('source', '==', source)
            .limit(400)
            .get();
        if (snap.empty)
            break;
        const batch = db.batch();
        snap.docs.forEach((d) => batch.delete(d.ref));
        await batch.commit();
        total += snap.size;
        if (snap.size < 400)
            break;
    }
    console.log(`clearSource(${source}): deleted ${total}`);
    return total;
}
// Production first; fresh keys are often sandbox-only until prod access lands.
const VIATOR_BASES = [
    'https://api.viator.com/partner',
    'https://api.sandbox.viator.com/partner',
];
const VIATOR_HEADERS = (apiKey) => ({
    'exp-api-key': apiKey,
    Accept: 'application/json;version=2.0',
    'Accept-Language': 'en-US',
    'Content-Type': 'application/json',
});
/// Fetch Viator destinations once: returns the matched top-50 countries, a full
/// id→{name,type,lat,lng} map (so we can resolve each product's city + precise
/// coordinates), and the list of all CITY destinations (for the city lookup
/// table).
async function fetchDestinations(apiKey, base) {
    var _a, _b;
    const empty = {
        countries: [],
        idMap: new Map(),
        cities: [],
    };
    try {
        const res = await fetch(`${base}/destinations`, {
            headers: VIATOR_HEADERS(apiKey),
        });
        if (!res.ok) {
            console.error(`Viator destinations HTTP ${res.status} (${base})`);
            return empty;
        }
        const json = await res.json();
        const dests = json.destinations || [];
        const idMap = new Map();
        const byName = new Map();
        const byId = new Map();
        for (const d of dests) {
            if (d.destinationId != null) {
                byId.set(String(d.destinationId), d);
                idMap.set(String(d.destinationId), {
                    name: d.name,
                    type: String(d.type || ''),
                    lat: (_a = d.center) === null || _a === void 0 ? void 0 : _a.latitude,
                    lng: (_b = d.center) === null || _b === void 0 ? void 0 : _b.longitude,
                });
            }
            if (d.type === 'COUNTRY' && d.name) {
                byName.set(String(d.name).toLowerCase(), d);
            }
        }
        // Resolve each CITY's country name by walking up parentDestinationId.
        function countryOf(d) {
            let cur = d;
            for (let i = 0; i < 6 && cur; i++) {
                if (String(cur.type) === 'COUNTRY')
                    return cur.name;
                cur = byId.get(String(cur.parentDestinationId));
            }
            return '';
        }
        const cities = dests
            .filter((d) => { var _a; return d.type === 'CITY' && ((_a = d.center) === null || _a === void 0 ? void 0 : _a.latitude) != null; })
            .map((d) => ({
            id: String(d.destinationId),
            name: d.name,
            lat: d.center.latitude,
            lng: d.center.longitude,
            country: countryOf(d),
        }));
        const aliases = {
            'United States': ['usa', 'united states of america', 'us', 'america'],
            'United Kingdom': ['uk', 'great britain', 'britain', 'england'],
            'United Arab Emirates': ['uae'],
            'Czech Republic': ['czechia'],
            'South Korea': ['korea', 'republic of korea'],
        };
        const countries = [];
        for (const name of TOP_COUNTRIES) {
            let d = byName.get(name.toLowerCase());
            if (!d) {
                for (const alias of aliases[name] || []) {
                    d = byName.get(alias);
                    if (d)
                        break;
                }
            }
            if (d)
                countries.push({ id: String(d.destinationId), name });
            else
                console.log(`ingest: no Viator country match for ${name}`);
        }
        return { countries, idMap, cities };
    }
    catch (e) {
        console.error(`Viator destinations failed (${base})`, e);
        return empty;
    }
}
/// Resolve a product's city (name + precise coordinates) from its destination
/// refs (prefer the primary non-country destination).
function cityInfoFor(p, idMap, countryName) {
    var _a, _b;
    const dests = p.destinations || [];
    const ordered = [...dests].sort((a, b) => (b.primary ? 1 : 0) - (a.primary ? 1 : 0));
    for (const d of ordered) {
        const info = idMap.get(String(d.ref));
        if (info && info.type !== 'COUNTRY' && info.name && info.name !== countryName) {
            return { name: info.name, lat: (_a = info.lat) !== null && _a !== void 0 ? _a : null, lng: (_b = info.lng) !== null && _b !== void 0 ? _b : null };
        }
    }
    return { name: null, lat: null, lng: null };
}
// Affiliate params — append to every product URL so taps open the booking-ready
// Viator page attributed to this partner.
const AFFILIATE_PID = 'P00306636';
const AFFILIATE_MCID = '42383';
function withAffiliate(url) {
    if (!url)
        return null;
    const base = url.split('?')[0];
    return `${base}?pid=${AFFILIATE_PID}&mcid=${AFFILIATE_MCID}&medium=link`;
}
function mapProduct(p, countryName, idMap) {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q;
    // Pick the highest-resolution image variant (max width × height).
    const variants = ((_b = (_a = p.images) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.variants) || [];
    let best;
    for (const v of variants) {
        const area = (v.width || 0) * (v.height || 0);
        const bestArea = best ? (best.width || 0) * (best.height || 0) : -1;
        if (area > bestArea)
            best = v;
    }
    const city = cityInfoFor(p, idMap, countryName);
    return {
        id: `viator_${p.productCode}`,
        data: {
            source: 'viator',
            externalId: p.productCode,
            title: p.title,
            description: (_c = p.description) !== null && _c !== void 0 ? _c : null,
            imageUrl: (_d = best === null || best === void 0 ? void 0 : best.url) !== null && _d !== void 0 ? _d : null,
            category: 'tour',
            city: city.name,
            country: countryName,
            // Precise coordinates from the product's primary city destination.
            lat: city.lat,
            lng: city.lng,
            fromPrice: (_g = (_f = (_e = p.pricing) === null || _e === void 0 ? void 0 : _e.summary) === null || _f === void 0 ? void 0 : _f.fromPrice) !== null && _g !== void 0 ? _g : null,
            currency: (_j = (_h = p.pricing) === null || _h === void 0 ? void 0 : _h.currency) !== null && _j !== void 0 ? _j : 'USD',
            // Default to 0 (not null) so orderBy('rating'/'reviewCount') includes
            // every doc — Firestore omits docs missing the ordered field.
            rating: (_l = (_k = p.reviews) === null || _k === void 0 ? void 0 : _k.combinedAverageRating) !== null && _l !== void 0 ? _l : 0,
            reviewCount: (_o = (_m = p.reviews) === null || _m === void 0 ? void 0 : _m.totalReviews) !== null && _o !== void 0 ? _o : 0,
            durationMinutes: (_q = (_p = p.duration) === null || _p === void 0 ? void 0 : _p.fixedDurationInMinutes) !== null && _q !== void 0 ? _q : null,
            bookingUrl: withAffiliate(p.productUrl),
            fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
    };
}
// Pull a larger pool per country, then keep the top [PRODUCTS_PER_COUNTRY] by
// number of reviews among those rated > 4 stars (popularity, not just rating).
const COUNTRY_POOL = 250;
async function fetchTopForCountry(apiKey, base, destId, countryName, idMap) {
    const products = [];
    const pageSize = 50;
    for (let start = 1; start <= COUNTRY_POOL; start += pageSize) {
        const count = Math.min(pageSize, COUNTRY_POOL - (start - 1));
        try {
            const res = await fetch(`${base}/products/search`, {
                method: 'POST',
                headers: VIATOR_HEADERS(apiKey),
                body: JSON.stringify({
                    filtering: { destination: destId },
                    sorting: { sort: 'TRAVELER_RATING', order: 'DESCENDING' },
                    pagination: { start, count },
                    currency: 'USD',
                }),
            });
            if (!res.ok) {
                console.error(`Viator ${countryName} HTTP ${res.status} (start ${start})`);
                break;
            }
            const json = await res.json();
            const batch = json.products || [];
            if (batch.length === 0)
                break;
            products.push(...batch);
            if (batch.length < count)
                break; // no more pages
        }
        catch (e) {
            console.error(`Viator fetch failed for ${countryName} (start ${start})`, e);
            break;
        }
    }
    // Criteria: rating strictly above 4 stars, ranked by most reviews.
    const ranked = products
        .filter((p) => { var _a, _b; return ((_b = (_a = p.reviews) === null || _a === void 0 ? void 0 : _a.combinedAverageRating) !== null && _b !== void 0 ? _b : 0) > 4; })
        .sort((a, b) => { var _a, _b, _c, _d; return ((_b = (_a = b.reviews) === null || _a === void 0 ? void 0 : _a.totalReviews) !== null && _b !== void 0 ? _b : 0) - ((_d = (_c = a.reviews) === null || _c === void 0 ? void 0 : _c.totalReviews) !== null && _d !== void 0 ? _d : 0); })
        .slice(0, PRODUCTS_PER_COUNTRY);
    return ranked.map((p) => mapProduct(p, countryName, idMap));
}
/// Per-country counts → `external_country_stats/{source}_{country}` so the globe
/// can show complete markers cheaply (≤ #countries docs).
async function writeCountryStats(docs, source) {
    const counts = {};
    for (const d of docs) {
        const c = d.data.country;
        if (c)
            counts[c] = (counts[c] || 0) + 1;
    }
    const batch = db.batch();
    const now = admin.firestore.FieldValue.serverTimestamp();
    for (const [country, count] of Object.entries(counts)) {
        batch.set(db.collection('external_country_stats').doc(`${source}_${country}`), { source, country, count, updatedAt: now }, { merge: true });
    }
    await batch.commit();
}
/// City → coordinates lookup table. Writes every provider city (name, country,
/// lat, lng) to `city_coordinates/{id}` so the app can query coordinates for any
/// available city (selectors, precise map plotting). No artificial cap — writes
/// all available (Viator alone ≈ 3,400; grows with Tiqets).
async function writeCityCoordinates(cities) {
    let batch = db.batch();
    let ops = 0;
    const commits = [];
    const now = admin.firestore.FieldValue.serverTimestamp();
    for (const c of cities) {
        batch.set(db.collection('city_coordinates').doc(`viator_${c.id}`), {
            city: c.name,
            country: c.country,
            lat: c.lat,
            lng: c.lng,
            nameLower: c.name.toLowerCase(),
            updatedAt: now,
        }, { merge: true });
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
async function runIngestion(apiKey) {
    if (!apiKey) {
        console.log('ingestExternalEvents: VIATOR_API_KEY not set — skipping.');
        return 0;
    }
    for (const base of VIATOR_BASES) {
        const { countries, idMap, cities } = await fetchDestinations(apiKey, base);
        if (countries.length === 0) {
            console.log(`ingestExternalEvents: no countries from ${base}, trying next.`);
            continue;
        }
        // Build/refresh the city → coordinates lookup table.
        await writeCityCoordinates(cities);
        const all = [];
        for (const c of countries) {
            all.push(...(await fetchTopForCountry(apiKey, base, c.id, c.name, idMap)));
        }
        if (all.length > 0) {
            await upsertAll(all);
            await writeCountryStats(all, 'viator');
            console.log(`ingestExternalEvents: upserted ${all.length} experiences across ` +
                `${countries.length} countries from ${base}.`);
            return all.length;
        }
        console.log(`ingestExternalEvents: no products from ${base}, trying next.`);
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
            imageUrl: 'https://picsum.photos/seed/colosseum/800/600',
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
            imageUrl: 'https://picsum.photos/seed/eiffel/800/600',
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
            imageUrl: 'https://picsum.photos/seed/tokyo/800/600',
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
            imageUrl: 'https://picsum.photos/seed/sagrada/800/600',
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
            imageUrl: 'https://picsum.photos/seed/nyc/800/600',
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
            imageUrl: 'https://picsum.photos/seed/dubai/800/600',
            fromPrice: 35, currency: 'USD', rating: 4.7, reviewCount: 6210,
            durationMinutes: 360, bookingUrl: 'https://www.viator.com/Dubai-tours/d828',
        },
    },
    // Tiqets attractions (museums/landmarks) — Attractions tab seed (with geo).
    {
        id: 'tiqets_seed_colosseum',
        data: {
            source: 'tiqets', externalId: 'seed_colosseum',
            title: 'Colosseum, Roman Forum & Palatine Hill — Skip-the-Line',
            category: 'attraction', city: 'Rome', country: 'IT',
            imageUrl: 'https://picsum.photos/seed/tqcolosseum/800/600',
            fromPrice: 18, currency: 'EUR', rating: 4.7, reviewCount: 5312,
            lat: 41.8902, lng: 12.4922,
            bookingUrl: 'https://www.tiqets.com/en/rome-attractions-c66903/',
        },
    },
    {
        id: 'tiqets_seed_louvre',
        data: {
            source: 'tiqets', externalId: 'seed_louvre',
            title: 'Louvre Museum — Timed Entrance',
            category: 'attraction', city: 'Paris', country: 'FR',
            imageUrl: 'https://picsum.photos/seed/tqlouvre/800/600',
            fromPrice: 22, currency: 'EUR', rating: 4.6, reviewCount: 8740,
            lat: 48.8606, lng: 2.3376,
            bookingUrl: 'https://www.tiqets.com/en/paris-attractions-c66746/',
        },
    },
    {
        id: 'tiqets_seed_sagrada',
        data: {
            source: 'tiqets', externalId: 'seed_sagrada',
            title: 'Sagrada Família — Fast-Track Entry',
            category: 'attraction', city: 'Barcelona', country: 'ES',
            imageUrl: 'https://picsum.photos/seed/tqsagrada/800/600',
            fromPrice: 26, currency: 'EUR', rating: 4.8, reviewCount: 12450,
            lat: 41.4036, lng: 2.1744,
            bookingUrl: 'https://www.tiqets.com/en/barcelona-attractions-c71993/',
        },
    },
    {
        id: 'tiqets_seed_vangogh',
        data: {
            source: 'tiqets', externalId: 'seed_vangogh',
            title: 'Van Gogh Museum — Skip-the-Line',
            category: 'attraction', city: 'Amsterdam', country: 'NL',
            imageUrl: 'https://picsum.photos/seed/tqvangogh/800/600',
            fromPrice: 24, currency: 'EUR', rating: 4.7, reviewCount: 9320,
            lat: 52.3584, lng: 4.8811,
            bookingUrl: 'https://www.tiqets.com/en/amsterdam-attractions-c75061/',
        },
    },
    {
        id: 'tiqets_seed_empire',
        data: {
            source: 'tiqets', externalId: 'seed_empire',
            title: 'Empire State Building Observatory',
            category: 'attraction', city: 'New York', country: 'US',
            imageUrl: 'https://picsum.photos/seed/tqempire/800/600',
            fromPrice: 44, currency: 'USD', rating: 4.6, reviewCount: 15980,
            lat: 40.7484, lng: -73.9857,
            bookingUrl: 'https://www.tiqets.com/en/new-york-attractions-c75819/',
        },
    },
    {
        id: 'tiqets_seed_burj',
        data: {
            source: 'tiqets', externalId: 'seed_burj',
            title: 'Burj Khalifa — At the Top',
            category: 'attraction', city: 'Dubai', country: 'AE',
            imageUrl: 'https://picsum.photos/seed/tqburj/800/600',
            fromPrice: 40, currency: 'USD', rating: 4.6, reviewCount: 21030,
            lat: 25.1972, lng: 55.2744,
            bookingUrl: 'https://www.tiqets.com/en/dubai-attractions-c76083/',
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
    if (req.query.seed) {
        // ?seed=1 → all; ?seed=tiqets / ?seed=viator → only that source.
        const src = String(req.query.seed);
        const docs = src === '1'
            ? SEED_DOCS
            : SEED_DOCS.filter((d) => d.data.source === src);
        await upsertAll(docs);
        res.status(200).json({ ok: true, seeded: docs.length });
        return;
    }
    // ?clear=viator → delete the previous set first, then re-feed fresh.
    let cleared = 0;
    if (req.query.clear)
        cleared = await clearSource(String(req.query.clear));
    const count = await runIngestion(key);
    res.status(200).json({ ok: true, cleared, upserted: count });
});
//# sourceMappingURL=ingest.js.map