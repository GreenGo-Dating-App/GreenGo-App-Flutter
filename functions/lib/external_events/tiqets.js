"use strict";
/**
 * Tiqets attractions ingester → `external_events` (source: 'tiqets').
 *
 * Pulls the top attractions (museums/landmarks) for the top tourism countries
 * and upserts them with geolocation (lat/lng) so the Attractions tab can order
 * by distance. Key from the TIQETS_API_KEY secret; no-ops until it's set.
 *
 * NOTE: exact Tiqets endpoint/field names are finalized once a live key is
 * available to verify against (kept isolated so verification is a one-file fix).
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
exports.runIngestTiqetsNow = exports.ingestTiqetsAttractions = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
require("../shared/firebaseAdmin");
const db = admin.firestore();
const COLLECTION = 'external_events';
const TIQETS_API_KEY = (0, params_1.defineSecret)('TIQETS_API_KEY');
const PRODUCTS_PER_COUNTRY = 100;
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
const headers = (key) => ({
    Authorization: `Token ${key}`,
    Accept: 'application/json',
});
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
/// Map Tiqets country names → ids.
async function resolveCountryIds(key) {
    try {
        const res = await fetch('https://api.tiqets.com/v2/countries', { headers: headers(key) });
        if (!res.ok) {
            console.error(`Tiqets countries HTTP ${res.status}`);
            return [];
        }
        const json = await res.json();
        const countries = json.countries || json || [];
        const byName = new Map();
        for (const c of countries) {
            if (c.name)
                byName.set(String(c.name).toLowerCase(), c);
        }
        const out = [];
        for (const name of TOP_COUNTRIES) {
            const c = byName.get(name.toLowerCase());
            if (c && c.id != null)
                out.push({ id: String(c.id), name });
        }
        return out;
    }
    catch (e) {
        console.error('Tiqets countries failed', e);
        return [];
    }
}
function mapProduct(p, countryName) {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q, _r, _s, _t, _u, _v, _w, _x;
    const geo = p.geolocation || {};
    return {
        id: `tiqets_${p.id}`,
        data: {
            source: 'tiqets',
            externalId: String(p.id),
            title: p.title,
            description: (_a = p.tagline) !== null && _a !== void 0 ? _a : null,
            imageUrl: (_g = (_d = (_c = (_b = p.images) === null || _b === void 0 ? void 0 : _b[0]) === null || _c === void 0 ? void 0 : _c.large) !== null && _d !== void 0 ? _d : (_f = (_e = p.images) === null || _e === void 0 ? void 0 : _e[0]) === null || _f === void 0 ? void 0 : _f.medium) !== null && _g !== void 0 ? _g : null,
            category: 'attraction',
            city: (_j = (_h = p.city) === null || _h === void 0 ? void 0 : _h.name) !== null && _j !== void 0 ? _j : null,
            country: (_m = (_l = (_k = p.city) === null || _k === void 0 ? void 0 : _k.country) === null || _l === void 0 ? void 0 : _l.code) !== null && _m !== void 0 ? _m : countryName,
            fromPrice: ((_o = p.price) === null || _o === void 0 ? void 0 : _o.amount) != null ? Number(p.price.amount) : null,
            currency: (_q = (_p = p.price) === null || _p === void 0 ? void 0 : _p.currency) !== null && _q !== void 0 ? _q : 'EUR',
            rating: (_s = (_r = p.ratings) === null || _r === void 0 ? void 0 : _r.average) !== null && _s !== void 0 ? _s : 0,
            reviewCount: (_u = (_t = p.ratings) === null || _t === void 0 ? void 0 : _t.count) !== null && _u !== void 0 ? _u : 0,
            lat: (_v = geo.lat) !== null && _v !== void 0 ? _v : null,
            lng: (_w = geo.lng) !== null && _w !== void 0 ? _w : null,
            bookingUrl: (_x = p.product_url) !== null && _x !== void 0 ? _x : null,
            fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
    };
}
async function fetchForCountry(key, countryId, countryName) {
    const docs = [];
    const pageSize = 50;
    for (let page = 1; docs.length < PRODUCTS_PER_COUNTRY; page++) {
        try {
            const res = await fetch(`https://api.tiqets.com/v2/products?country_id=${countryId}&page=${page}&page_size=${pageSize}`, { headers: headers(key) });
            if (!res.ok) {
                console.error(`Tiqets ${countryName} HTTP ${res.status} (page ${page})`);
                break;
            }
            const json = await res.json();
            const products = json.products || [];
            if (products.length === 0)
                break;
            docs.push(...products.map((p) => mapProduct(p, countryName)));
            if (products.length < pageSize)
                break;
        }
        catch (e) {
            console.error(`Tiqets ${countryName} failed (page ${page})`, e);
            break;
        }
    }
    return docs.slice(0, PRODUCTS_PER_COUNTRY);
}
async function runTiqets(key) {
    if (!key) {
        console.log('ingestTiqets: TIQETS_API_KEY not set — skipping.');
        return 0;
    }
    const countries = await resolveCountryIds(key);
    if (countries.length === 0)
        return 0;
    const all = [];
    for (const c of countries) {
        all.push(...(await fetchForCountry(key, c.id, c.name)));
    }
    // Attractions are only worth showing with a photo → drop the image-less ones
    // so we never store (or later render) a blank card.
    const withImage = all.filter((d) => {
        const url = d.data.imageUrl;
        return typeof url === 'string' && url.length > 0;
    });
    if (withImage.length > 0)
        await upsertAll(withImage);
    console.log(`ingestTiqets: upserted ${withImage.length}/${all.length} attractions ` +
        `with images across ${countries.length} countries.`);
    return withImage.length;
}
exports.ingestTiqetsAttractions = (0, scheduler_1.onSchedule)({ schedule: 'every 12 hours', timeoutSeconds: 540, memory: '512MiB', secrets: [TIQETS_API_KEY] }, (0, monitoring_1.monitored)("ingestTiqetsAttractions", async () => {
    await runTiqets(TIQETS_API_KEY.value());
}));
// Manual trigger: GET ?token=<TIQETS_API_KEY> to pull attractions now.
exports.runIngestTiqetsNow = (0, https_1.onRequest)({ timeoutSeconds: 540, memory: '512MiB', secrets: [TIQETS_API_KEY] }, (0, monitoring_1.monitored)("runIngestTiqetsNow", async (req, res) => {
    const key = TIQETS_API_KEY.value();
    if (!key || req.query.token !== key) {
        res.status(403).send('Forbidden');
        return;
    }
    const count = await runTiqets(key);
    res.status(200).json({ ok: true, upserted: count });
}));
//# sourceMappingURL=tiqets.js.map