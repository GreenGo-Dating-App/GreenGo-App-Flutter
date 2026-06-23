"use strict";
/**
 * Geoapify attractions ingester → `external_events` (source: 'geoapify').
 *
 * A free, commercial-safe alternative to Tiqets for museums, tourist attractions
 * and theme/amusement parks. Geoapify Places (OpenStreetMap-based) supplies the
 * POIs (name, category, coordinates, city/country); Wikipedia/Wikidata enriches
 * each notable POI with a description + image (Geoapify itself returns no photos
 * or reviews). No per-user calls — a scheduled run upserts a bounded pool into
 * `external_events`; the app reads that collection cache-first and scales to
 * millions of users. Reviews are not available free, so rating/reviewCount stay
 * 0 and users add their own in-app reviews.
 *
 * Key from the GEOAPIFY_API_KEY secret; no-ops until it's set, so it deploys
 * safely beforehand. Does NOT touch the native `events` collection.
 *
 * Free tier: ~3,000 requests/day. This run makes ~1 Places call per city plus
 * one enrichment call per notable POI — a few hundred to ~2k per run, well under
 * the cap (and only on the schedule, never per user).
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
exports.runIngestGeoapifyNow = exports.ingestGeoapifyAttractions = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
require("../shared/firebaseAdmin");
const build_index_1 = require("./build_index");
const db = admin.firestore();
const COLLECTION = 'external_events';
const GEOAPIFY_API_KEY = (0, params_1.defineSecret)('GEOAPIFY_API_KEY');
// Geoapify categories: museums, tourist attractions/sights, theme & amusement
// parks, plus city parks and national parks.
const CATEGORIES = [
    'entertainment.museum',
    'tourism.attraction',
    'tourism.sights',
    'entertainment.theme_park',
    'leisure.park',
    'national_park',
].join(',');
const SEARCH_RADIUS_M = 30000; // 30 km around each city centre
const PLACES_PER_CITY = 200; // Geoapify page size (max 500 on free tier)
const KEEP_PER_CITY = 60; // notable POIs we keep & enrich per city
const ENRICH_CONCURRENCY = 8; // parallel Wikipedia/Wikidata calls
// Top tourism cities worldwide with centre coordinates + ISO-2 country code.
// Bounded list → bounded API usage; expand freely (each adds ~1 Places call).
const CITIES = [
    { name: 'Paris', lat: 48.8566, lng: 2.3522, cc: 'FR' },
    { name: 'London', lat: 51.5074, lng: -0.1278, cc: 'GB' },
    { name: 'Rome', lat: 41.9028, lng: 12.4964, cc: 'IT' },
    { name: 'Barcelona', lat: 41.3874, lng: 2.1686, cc: 'ES' },
    { name: 'Madrid', lat: 40.4168, lng: -3.7038, cc: 'ES' },
    { name: 'Amsterdam', lat: 52.3676, lng: 4.9041, cc: 'NL' },
    { name: 'Berlin', lat: 52.52, lng: 13.405, cc: 'DE' },
    { name: 'Vienna', lat: 48.2082, lng: 16.3738, cc: 'AT' },
    { name: 'Prague', lat: 50.0755, lng: 14.4378, cc: 'CZ' },
    { name: 'Lisbon', lat: 38.7223, lng: -9.1393, cc: 'PT' },
    { name: 'Athens', lat: 37.9838, lng: 23.7275, cc: 'GR' },
    { name: 'Istanbul', lat: 41.0082, lng: 28.9784, cc: 'TR' },
    { name: 'Florence', lat: 43.7696, lng: 11.2558, cc: 'IT' },
    { name: 'Venice', lat: 45.4408, lng: 12.3155, cc: 'IT' },
    { name: 'Munich', lat: 48.1351, lng: 11.582, cc: 'DE' },
    { name: 'Budapest', lat: 47.4979, lng: 19.0402, cc: 'HU' },
    { name: 'Dublin', lat: 53.3498, lng: -6.2603, cc: 'IE' },
    { name: 'Copenhagen', lat: 55.6761, lng: 12.5683, cc: 'DK' },
    { name: 'Stockholm', lat: 59.3293, lng: 18.0686, cc: 'SE' },
    { name: 'Zurich', lat: 47.3769, lng: 8.5417, cc: 'CH' },
    { name: 'Brussels', lat: 50.8503, lng: 4.3517, cc: 'BE' },
    { name: 'New York', lat: 40.7128, lng: -74.006, cc: 'US' },
    { name: 'Los Angeles', lat: 34.0522, lng: -118.2437, cc: 'US' },
    { name: 'San Francisco', lat: 37.7749, lng: -122.4194, cc: 'US' },
    { name: 'Las Vegas', lat: 36.1699, lng: -115.1398, cc: 'US' },
    { name: 'Orlando', lat: 28.5383, lng: -81.3792, cc: 'US' }, // theme parks
    { name: 'Chicago', lat: 41.8781, lng: -87.6298, cc: 'US' },
    { name: 'Washington', lat: 38.9072, lng: -77.0369, cc: 'US' },
    { name: 'Toronto', lat: 43.6532, lng: -79.3832, cc: 'CA' },
    { name: 'Mexico City', lat: 19.4326, lng: -99.1332, cc: 'MX' },
    { name: 'Rio de Janeiro', lat: -22.9068, lng: -43.1729, cc: 'BR' },
    { name: 'Sao Paulo', lat: -23.5505, lng: -46.6333, cc: 'BR' },
    { name: 'Buenos Aires', lat: -34.6037, lng: -58.3816, cc: 'AR' },
    { name: 'Lima', lat: -12.0464, lng: -77.0428, cc: 'PE' },
    { name: 'Dubai', lat: 25.2048, lng: 55.2708, cc: 'AE' },
    { name: 'Cairo', lat: 30.0444, lng: 31.2357, cc: 'EG' },
    { name: 'Marrakesh', lat: 31.6295, lng: -7.9811, cc: 'MA' },
    { name: 'Cape Town', lat: -33.9249, lng: 18.4241, cc: 'ZA' },
    { name: 'Tokyo', lat: 35.6762, lng: 139.6503, cc: 'JP' },
    { name: 'Kyoto', lat: 35.0116, lng: 135.7681, cc: 'JP' },
    { name: 'Osaka', lat: 34.6937, lng: 135.5023, cc: 'JP' }, // theme parks
    { name: 'Seoul', lat: 37.5665, lng: 126.978, cc: 'KR' },
    { name: 'Bangkok', lat: 13.7563, lng: 100.5018, cc: 'TH' },
    { name: 'Singapore', lat: 1.3521, lng: 103.8198, cc: 'SG' },
    { name: 'Hong Kong', lat: 22.3193, lng: 114.1694, cc: 'HK' },
    { name: 'Beijing', lat: 39.9042, lng: 116.4074, cc: 'CN' },
    { name: 'Shanghai', lat: 31.2304, lng: 121.4737, cc: 'CN' },
    { name: 'Kuala Lumpur', lat: 3.139, lng: 101.6869, cc: 'MY' },
    { name: 'Bali', lat: -8.4095, lng: 115.1889, cc: 'ID' },
    { name: 'Sydney', lat: -33.8688, lng: 151.2093, cc: 'AU' },
    { name: 'Melbourne', lat: -37.8136, lng: 144.9631, cc: 'AU' },
    { name: 'Auckland', lat: -36.8485, lng: 174.7633, cc: 'NZ' },
    { name: 'Jerusalem', lat: 31.7683, lng: 35.2137, cc: 'IL' },
    { name: 'Reykjavik', lat: 64.1466, lng: -21.9426, cc: 'IS' },
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
/// Delete all external_events for a source, so a re-feed replaces (not merges)
/// the previous set. Batched; loops until empty.
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
/// Per-country counts → `external_country_stats/{source}_{country}` so the globe
/// can show markers cheaply.
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
/// Human-readable category from Geoapify's category tags.
function categoryLabel(cats) {
    if (cats.some((c) => c.includes('theme_park') || c.includes('amusement')))
        return 'theme_park';
    if (cats.some((c) => c.includes('museum')))
        return 'museum';
    if (cats.some((c) => c.includes('national_park')))
        return 'national_park';
    if (cats.some((c) => c.includes('park')))
        return 'park';
    return 'attraction';
}
/// Fetch one city's notable POIs from Geoapify Places. Keeps only POIs that are
/// notable enough to enrich (have a Wikipedia or Wikidata reference) so every
/// card ends up with a description + image.
async function fetchCity(key, city) {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    try {
        const url = `https://api.geoapify.com/v2/places?categories=${CATEGORIES}` +
            `&filter=circle:${city.lng},${city.lat},${SEARCH_RADIUS_M}` +
            `&bias=proximity:${city.lng},${city.lat}` +
            `&limit=${PLACES_PER_CITY}&apiKey=${key}`;
        const res = await fetch(url);
        if (!res.ok) {
            console.error(`Geoapify ${city.name} HTTP ${res.status}`);
            return [];
        }
        const json = await res.json();
        const features = json.features || [];
        const docs = [];
        for (const f of features) {
            const p = f.properties || {};
            const raw = (p.datasource && p.datasource.raw) || {};
            const name = p.name || raw['name:en'] || raw.name;
            if (!name)
                continue;
            const wikidata = raw.wikidata;
            const wikipedia = raw.wikipedia; // "lang:Article Title"
            // Notability filter: require a wiki reference (so we can enrich it).
            if (!wikidata && !wikipedia)
                continue;
            const lat = (_d = (_a = p.lat) !== null && _a !== void 0 ? _a : (_c = (_b = f.geometry) === null || _b === void 0 ? void 0 : _b.coordinates) === null || _c === void 0 ? void 0 : _c[1]) !== null && _d !== void 0 ? _d : null;
            const lng = (_h = (_e = p.lon) !== null && _e !== void 0 ? _e : (_g = (_f = f.geometry) === null || _f === void 0 ? void 0 : _f.coordinates) === null || _g === void 0 ? void 0 : _g[0]) !== null && _h !== void 0 ? _h : null;
            const id = wikidata ? `geoapify_wd_${wikidata}` : `geoapify_${p.place_id}`;
            const website = raw.website || raw['contact:website'] || p.website;
            docs.push({
                id,
                data: {
                    source: 'geoapify',
                    externalId: wikidata || String(p.place_id || ''),
                    title: name,
                    description: null, // filled by enrichment
                    imageUrl: null, // filled by enrichment
                    category: categoryLabel(p.categories || []),
                    city: p.city || city.name,
                    country: city.cc, // ISO-2, consistent with Tiqets docs
                    // No free reviews → 0 (kept as a number so orderBy includes the doc).
                    rating: 0,
                    reviewCount: 0,
                    lat,
                    lng,
                    // Filled by enrichment when missing; website preferred for the CTA.
                    bookingUrl: website || null,
                    _wikidata: wikidata || null,
                    _wikipedia: wikipedia || null,
                    fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
                },
            });
            if (docs.length >= KEEP_PER_CITY)
                break;
        }
        return docs;
    }
    catch (e) {
        console.error(`Geoapify ${city.name} failed`, e);
        return [];
    }
}
/// Enrich one doc with a description + image from Wikipedia (preferred) or
/// Wikidata. Mutates doc.data in place; clears the private _wiki* fields.
async function enrich(doc) {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p;
    const d = doc.data;
    const wikipedia = d._wikipedia;
    const wikidata = d._wikidata;
    try {
        if (wikipedia && wikipedia.includes(':')) {
            const lang = wikipedia.slice(0, wikipedia.indexOf(':'));
            const title = wikipedia.slice(wikipedia.indexOf(':') + 1);
            const res = await fetch(`https://${lang}.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(title)}`, { headers: { 'User-Agent': 'GreenGo/1.0 (places ingester)' } });
            if (res.ok) {
                const j = await res.json();
                d.description = j.extract || d.description;
                d.imageUrl = ((_a = j.thumbnail) === null || _a === void 0 ? void 0 : _a.source) || ((_b = j.originalimage) === null || _b === void 0 ? void 0 : _b.source) || d.imageUrl;
                if (!d.bookingUrl)
                    d.bookingUrl = ((_d = (_c = j.content_urls) === null || _c === void 0 ? void 0 : _c.desktop) === null || _d === void 0 ? void 0 : _d.page) || null;
            }
        }
        else if (wikidata) {
            const res = await fetch(`https://www.wikidata.org/wiki/Special:EntityData/${wikidata}.json`, { headers: { 'User-Agent': 'GreenGo/1.0 (places ingester)' } });
            if (res.ok) {
                const j = await res.json();
                const ent = (_e = j.entities) === null || _e === void 0 ? void 0 : _e[wikidata];
                d.description =
                    ((_g = (_f = ent === null || ent === void 0 ? void 0 : ent.descriptions) === null || _f === void 0 ? void 0 : _f.en) === null || _g === void 0 ? void 0 : _g.value) ||
                        ((_j = (_h = ent === null || ent === void 0 ? void 0 : ent.descriptions) === null || _h === void 0 ? void 0 : _h['en-us']) === null || _j === void 0 ? void 0 : _j.value) ||
                        d.description;
                // P18 = image (Commons filename) → render via Special:FilePath.
                const file = (_p = (_o = (_m = (_l = (_k = ent === null || ent === void 0 ? void 0 : ent.claims) === null || _k === void 0 ? void 0 : _k.P18) === null || _l === void 0 ? void 0 : _l[0]) === null || _m === void 0 ? void 0 : _m.mainsnak) === null || _o === void 0 ? void 0 : _o.datavalue) === null || _p === void 0 ? void 0 : _p.value;
                if (file) {
                    d.imageUrl = `https://commons.wikimedia.org/wiki/Special:FilePath/${encodeURIComponent(file)}?width=800`;
                }
                if (!d.bookingUrl) {
                    d.bookingUrl = `https://www.wikidata.org/wiki/${wikidata}`;
                }
            }
        }
    }
    catch (e) {
        console.error('enrich failed', doc.id, e);
    }
    // Final CTA fallback: Google Maps search by name + city.
    if (!d.bookingUrl) {
        const q = encodeURIComponent(`${d.title} ${d.city || ''}`.trim());
        d.bookingUrl = `https://www.google.com/maps/search/?api=1&query=${q}`;
    }
    delete d._wikidata;
    delete d._wikipedia;
}
/// Run [tasks] with bounded concurrency.
async function pool(items, size, fn) {
    for (let i = 0; i < items.length; i += size) {
        await Promise.all(items.slice(i, i + size).map(fn));
    }
}
async function runGeoapify(key) {
    if (!key) {
        console.log('ingestGeoapify: GEOAPIFY_API_KEY not set — skipping.');
        return 0;
    }
    // Fetch all cities (dedupe by doc id across overlapping radii).
    const byId = new Map();
    for (const city of CITIES) {
        for (const doc of await fetchCity(key, city)) {
            if (!byId.has(doc.id))
                byId.set(doc.id, doc);
        }
    }
    const all = [...byId.values()];
    if (all.length === 0) {
        console.log('ingestGeoapify: no POIs returned.');
        return 0;
    }
    // Enrich each with description + image (bounded concurrency).
    await pool(all, ENRICH_CONCURRENCY, enrich);
    await upsertAll(all);
    await writeCountryStats(all, 'geoapify');
    await (0, build_index_1.buildSourceIndex)('geoapify');
    console.log(`ingestGeoapify: upserted ${all.length} attractions across ${CITIES.length} cities.`);
    return all.length;
}
// Scheduled refresh, every 24 hours (OSM-derived data changes slowly).
exports.ingestGeoapifyAttractions = (0, scheduler_1.onSchedule)({ schedule: 'every 24 hours', timeoutSeconds: 540, memory: '512MiB', secrets: [GEOAPIFY_API_KEY] }, (0, monitoring_1.monitored)('ingestGeoapifyAttractions', async () => {
    await runGeoapify(GEOAPIFY_API_KEY.value());
}));
// Manual trigger (admin), guarded by the Geoapify key as token:
//   ?token=<KEY>              → pull attractions now
//   ?token=<KEY>&clear=1      → delete the previous geoapify set first, then refeed
exports.runIngestGeoapifyNow = (0, https_1.onRequest)({ timeoutSeconds: 540, memory: '512MiB', secrets: [GEOAPIFY_API_KEY] }, (0, monitoring_1.monitored)('runIngestGeoapifyNow', async (req, res) => {
    const key = GEOAPIFY_API_KEY.value();
    if (!key || req.query.token !== key) {
        res.status(403).send('Forbidden');
        return;
    }
    let cleared = 0;
    if (req.query.clear)
        cleared = await clearSource('geoapify');
    const count = await runGeoapify(key);
    res.status(200).json({ ok: true, cleared, upserted: count });
}));
//# sourceMappingURL=geoapify.js.map