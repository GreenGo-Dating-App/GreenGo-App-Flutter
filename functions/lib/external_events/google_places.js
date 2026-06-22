"use strict";
/**
 * Google Places (New) ingester → `external_events` (source: 'google').
 *
 * Pulls top attractions (museums, landmarks, parks…) for major tourist cities
 * with full detail — name, photo, rating, review count, exact coordinates,
 * category, city/country — so Attractions cards match Experiences/Live Events.
 * Deep-links to Google Maps (no booking). Key from GOOGLE_PLACES_API_KEY secret;
 * no-ops until set.
 *
 * Cost note: Places Text Search + Photo are billed per call; restrict the key
 * to the Places API and keep the schedule modest.
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
exports.runIngestGoogleNow = exports.ingestGooglePlaces = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const db = admin.firestore();
const COLLECTION = 'external_events';
const GOOGLE_PLACES_API_KEY = (0, params_1.defineSecret)('GOOGLE_PLACES_API_KEY');
const PAGES_PER_CITY = 3; // 20 results/page → up to 60 attractions/city
// Top global tourist cities → country name (for the doc's country field).
const CITIES = [
    { city: 'Paris', country: 'France' }, { city: 'Rome', country: 'Italy' },
    { city: 'London', country: 'United Kingdom' }, { city: 'New York', country: 'United States' },
    { city: 'Barcelona', country: 'Spain' }, { city: 'Tokyo', country: 'Japan' },
    { city: 'Dubai', country: 'United Arab Emirates' }, { city: 'Istanbul', country: 'Turkey' },
    { city: 'Bangkok', country: 'Thailand' }, { city: 'Amsterdam', country: 'Netherlands' },
    { city: 'Berlin', country: 'Germany' }, { city: 'Prague', country: 'Czech Republic' },
    { city: 'Vienna', country: 'Austria' }, { city: 'Madrid', country: 'Spain' },
    { city: 'Florence', country: 'Italy' }, { city: 'Venice', country: 'Italy' },
    { city: 'Lisbon', country: 'Portugal' }, { city: 'Athens', country: 'Greece' },
    { city: 'Budapest', country: 'Hungary' }, { city: 'Singapore', country: 'Singapore' },
    { city: 'Los Angeles', country: 'United States' }, { city: 'San Francisco', country: 'United States' },
    { city: 'Las Vegas', country: 'United States' }, { city: 'Miami', country: 'United States' },
    { city: 'Chicago', country: 'United States' }, { city: 'Washington', country: 'United States' },
    { city: 'Toronto', country: 'Canada' }, { city: 'Vancouver', country: 'Canada' },
    { city: 'Sydney', country: 'Australia' }, { city: 'Melbourne', country: 'Australia' },
    { city: 'Cairo', country: 'Egypt' }, { city: 'Marrakech', country: 'Morocco' },
    { city: 'Cape Town', country: 'South Africa' }, { city: 'Rio de Janeiro', country: 'Brazil' },
    { city: 'Buenos Aires', country: 'Argentina' }, { city: 'Lima', country: 'Peru' },
    { city: 'Mexico City', country: 'Mexico' }, { city: 'Cusco', country: 'Peru' },
    { city: 'Kyoto', country: 'Japan' }, { city: 'Seoul', country: 'South Korea' },
    { city: 'Hong Kong', country: 'China' }, { city: 'Beijing', country: 'China' },
    { city: 'Shanghai', country: 'China' }, { city: 'Mumbai', country: 'India' },
    { city: 'Delhi', country: 'India' }, { city: 'Bali', country: 'Indonesia' },
    { city: 'Hanoi', country: 'Vietnam' }, { city: 'Siem Reap', country: 'Cambodia' },
    { city: 'Dublin', country: 'Ireland' }, { city: 'Edinburgh', country: 'United Kingdom' },
    { city: 'Munich', country: 'Germany' }, { city: 'Milan', country: 'Italy' },
    { city: 'Naples', country: 'Italy' }, { city: 'Seville', country: 'Spain' },
    { city: 'Porto', country: 'Portugal' }, { city: 'Krakow', country: 'Poland' },
    { city: 'Warsaw', country: 'Poland' }, { city: 'Stockholm', country: 'Sweden' },
    { city: 'Copenhagen', country: 'Denmark' }, { city: 'Oslo', country: 'Norway' },
    { city: 'Reykjavik', country: 'Iceland' }, { city: 'Brussels', country: 'Belgium' },
    { city: 'Zurich', country: 'Switzerland' }, { city: 'Geneva', country: 'Switzerland' },
    { city: 'Dubrovnik', country: 'Croatia' }, { city: 'Petra', country: 'Jordan' },
    { city: 'Amman', country: 'Jordan' }, { city: 'Tel Aviv', country: 'Israel' },
    { city: 'Jerusalem', country: 'Israel' }, { city: 'Riyadh', country: 'Saudi Arabia' },
    { city: 'Kuala Lumpur', country: 'Malaysia' }, { city: 'Manila', country: 'Philippines' },
    { city: 'Auckland', country: 'New Zealand' }, { city: 'Queenstown', country: 'New Zealand' },
    { city: 'San Jose', country: 'Costa Rica' }, { city: 'Bogota', country: 'Colombia' },
    { city: 'Cartagena', country: 'Colombia' }, { city: 'Santiago', country: 'Chile' },
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
async function clearSource() {
    let total = 0;
    for (;;) {
        const snap = await db.collection(COLLECTION).where('source', '==', 'google').limit(400).get();
        if (snap.empty)
            break;
        const batch = db.batch();
        snap.docs.forEach((d) => batch.delete(d.ref));
        await batch.commit();
        total += snap.size;
        if (snap.size < 400)
            break;
    }
    return total;
}
async function writeCountryStats(docs) {
    const counts = {};
    for (const d of docs) {
        const c = d.data.country;
        if (c)
            counts[c] = (counts[c] || 0) + 1;
    }
    const batch = db.batch();
    const now = admin.firestore.FieldValue.serverTimestamp();
    for (const [country, count] of Object.entries(counts)) {
        batch.set(db.collection('external_country_stats').doc(`google_${country}`), { source: 'google', country, count, updatedAt: now }, { merge: true });
    }
    await batch.commit();
}
/// Resolve a Photo resource into a stable image URL (no key in the URL).
async function photoUrl(key, name) {
    var _a;
    try {
        const res = await fetch(`https://places.googleapis.com/v1/${name}/media` +
            `?maxHeightPx=800&skipHttpRedirect=true&key=${key}`);
        if (!res.ok)
            return null;
        const json = await res.json();
        return (_a = json.photoUri) !== null && _a !== void 0 ? _a : null;
    }
    catch (_) {
        return null;
    }
}
function countryFrom(p, fallback) {
    for (const c of p.addressComponents || []) {
        if ((c.types || []).includes('country'))
            return c.longText || fallback;
    }
    return fallback;
}
async function fetchForCity(key, city, countryName) {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m;
    const out = [];
    let pageToken;
    for (let page = 0; page < PAGES_PER_CITY; page++) {
        try {
            const res = await fetch('https://places.googleapis.com/v1/places:searchText', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Goog-Api-Key': key,
                    'X-Goog-FieldMask': 'places.id,places.displayName,places.location,places.rating,' +
                        'places.userRatingCount,places.photos,places.primaryTypeDisplayName,' +
                        'places.googleMapsUri,places.websiteUri,places.addressComponents,' +
                        'nextPageToken',
                },
                body: JSON.stringify(Object.assign({ textQuery: `top tourist attractions in ${city}`, maxResultCount: 20 }, (pageToken ? { pageToken } : {}))),
            });
            if (!res.ok) {
                console.error(`Google ${city} HTTP ${res.status}`);
                break;
            }
            const json = await res.json();
            const places = json.places || [];
            for (const p of places) {
                const loc = p.location || {};
                const img = ((_b = (_a = p.photos) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.name)
                    ? await photoUrl(key, p.photos[0].name)
                    : null;
                out.push({
                    id: `google_${p.id}`,
                    data: {
                        source: 'google',
                        externalId: p.id,
                        title: (_d = (_c = p.displayName) === null || _c === void 0 ? void 0 : _c.text) !== null && _d !== void 0 ? _d : '',
                        description: null,
                        imageUrl: img,
                        category: (_f = (_e = p.primaryTypeDisplayName) === null || _e === void 0 ? void 0 : _e.text) !== null && _f !== void 0 ? _f : 'attraction',
                        city,
                        country: countryFrom(p, countryName),
                        lat: (_g = loc.latitude) !== null && _g !== void 0 ? _g : null,
                        lng: (_h = loc.longitude) !== null && _h !== void 0 ? _h : null,
                        fromPrice: null,
                        currency: null,
                        rating: (_j = p.rating) !== null && _j !== void 0 ? _j : 0,
                        reviewCount: (_k = p.userRatingCount) !== null && _k !== void 0 ? _k : 0,
                        bookingUrl: (_m = (_l = p.googleMapsUri) !== null && _l !== void 0 ? _l : p.websiteUri) !== null && _m !== void 0 ? _m : null,
                        fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
                    },
                });
            }
            pageToken = json.nextPageToken;
            if (!pageToken)
                break;
        }
        catch (e) {
            console.error(`Google ${city} failed`, e);
            break;
        }
    }
    return out;
}
async function runGoogle(key) {
    if (!key) {
        console.log('ingestGooglePlaces: GOOGLE_PLACES_API_KEY not set — skipping.');
        return 0;
    }
    const all = [];
    const seen = new Set();
    for (const { city, country } of CITIES) {
        for (const d of await fetchForCity(key, city, country)) {
            if (seen.has(d.id))
                continue;
            seen.add(d.id);
            all.push(d);
        }
    }
    if (all.length > 0) {
        await upsertAll(all);
        await writeCountryStats(all);
    }
    console.log(`ingestGooglePlaces: upserted ${all.length} attractions.`);
    return all.length;
}
exports.ingestGooglePlaces = (0, scheduler_1.onSchedule)({ schedule: 'every 24 hours', timeoutSeconds: 540, memory: '512MiB', secrets: [GOOGLE_PLACES_API_KEY] }, async () => {
    await runGoogle(GOOGLE_PLACES_API_KEY.value());
});
// Manual trigger: ?token=<KEY> to pull now; &clear=1 to wipe Google source first.
exports.runIngestGoogleNow = (0, https_1.onRequest)({ timeoutSeconds: 540, memory: '512MiB', secrets: [GOOGLE_PLACES_API_KEY] }, async (req, res) => {
    const key = GOOGLE_PLACES_API_KEY.value();
    if (!key || req.query.token !== key) {
        res.status(403).send('Forbidden');
        return;
    }
    let cleared = 0;
    if (req.query.clear)
        cleared = await clearSource();
    const count = await runGoogle(key);
    res.status(200).json({ ok: true, cleared, upserted: count });
});
//# sourceMappingURL=google_places.js.map