"use strict";
/**
 * Ticketmaster Discovery ingester → `external_events` (source: 'ticketmaster').
 *
 * Pulls live events (concerts, sports, arts, theater) for the top tourism
 * countries with their exact venue coordinates, so they plot precisely on the
 * map (zoom mini-image pins). Key from TICKETMASTER_API_KEY secret; no-ops until
 * it's set. Mirrors the Viator/Tiqets ingester shape (source-isolated).
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
exports.runIngestTicketmasterNow = exports.ingestTicketmaster = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const db = admin.firestore();
const COLLECTION = 'external_events';
const TICKETMASTER_API_KEY = (0, params_1.defineSecret)('TICKETMASTER_API_KEY');
const PER_COUNTRY = 100;
// Top tourism countries → ISO-2 codes (Ticketmaster filters by countryCode).
const COUNTRY_ISO = {
    France: 'FR', Spain: 'ES', 'United States': 'US', Italy: 'IT', Turkey: 'TR',
    Mexico: 'MX', 'United Kingdom': 'GB', Germany: 'DE', Greece: 'GR',
    Austria: 'AT', Japan: 'JP', Thailand: 'TH', Portugal: 'PT',
    Netherlands: 'NL', Croatia: 'HR', 'United Arab Emirates': 'AE', Canada: 'CA',
    Australia: 'AU', China: 'CN', Egypt: 'EG', India: 'IN', Indonesia: 'ID',
    Vietnam: 'VN', Switzerland: 'CH', 'Czech Republic': 'CZ', Poland: 'PL',
    Ireland: 'IE', Morocco: 'MA', 'South Africa': 'ZA', Brazil: 'BR',
    Argentina: 'AR', Peru: 'PE', Iceland: 'IS', Hungary: 'HU', Belgium: 'BE',
    Denmark: 'DK', Sweden: 'SE', Norway: 'NO', Singapore: 'SG', Malaysia: 'MY',
    Philippines: 'PH', 'South Korea': 'KR', 'New Zealand': 'NZ', Israel: 'IL',
    Jordan: 'JO', Cambodia: 'KH', 'Costa Rica': 'CR', Colombia: 'CO',
    Chile: 'CL', 'Saudi Arabia': 'SA',
};
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
        const snap = await db
            .collection(COLLECTION)
            .where('source', '==', 'ticketmaster')
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
        batch.set(db.collection('external_country_stats').doc(`ticketmaster_${country}`), { source: 'ticketmaster', country, count, updatedAt: now }, { merge: true });
    }
    await batch.commit();
}
function mapEvent(e, countryName) {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o;
    const venue = (((_a = e._embedded) === null || _a === void 0 ? void 0 : _a.venues) || [])[0] || {};
    const loc = venue.location || {};
    const lat = loc.latitude != null ? Number(loc.latitude) : null;
    const lng = loc.longitude != null ? Number(loc.longitude) : null;
    // Largest image.
    let img;
    let bestW = -1;
    for (const im of e.images || []) {
        if ((im.width || 0) > bestW) {
            bestW = im.width || 0;
            img = im.url;
        }
    }
    const price = (e.priceRanges || [])[0] || {};
    return {
        id: `tm_${e.id}`,
        data: {
            source: 'ticketmaster',
            externalId: e.id,
            title: e.name,
            description: (_b = e.info) !== null && _b !== void 0 ? _b : null,
            imageUrl: img !== null && img !== void 0 ? img : null,
            category: (_f = (_e = (_d = (_c = e.classifications) === null || _c === void 0 ? void 0 : _c[0]) === null || _d === void 0 ? void 0 : _d.segment) === null || _e === void 0 ? void 0 : _e.name) !== null && _f !== void 0 ? _f : 'event',
            city: (_h = (_g = venue.city) === null || _g === void 0 ? void 0 : _g.name) !== null && _h !== void 0 ? _h : null,
            country: countryName,
            lat,
            lng,
            fromPrice: price.min != null ? Number(price.min) : null,
            currency: (_j = price.currency) !== null && _j !== void 0 ? _j : 'USD',
            rating: 0,
            reviewCount: 0,
            startDate: (_m = (_l = (_k = e.dates) === null || _k === void 0 ? void 0 : _k.start) === null || _l === void 0 ? void 0 : _l.localDate) !== null && _m !== void 0 ? _m : null,
            bookingUrl: (_o = e.url) !== null && _o !== void 0 ? _o : null,
            fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
    };
}
async function fetchForCountry(key, iso, countryName) {
    var _a, _b, _c;
    const docs = [];
    const pageSize = 100;
    for (let page = 0; docs.length < PER_COUNTRY; page++) {
        try {
            const url = `https://app.ticketmaster.com/discovery/v2/events.json?apikey=${key}` +
                `&countryCode=${iso}&size=${pageSize}&page=${page}&sort=relevance,desc`;
            const res = await fetch(url);
            if (!res.ok) {
                console.error(`TM ${countryName} HTTP ${res.status} (page ${page})`);
                break;
            }
            const json = await res.json();
            const events = ((_a = json._embedded) === null || _a === void 0 ? void 0 : _a.events) || [];
            if (events.length === 0)
                break;
            for (const e of events) {
                const d = mapEvent(e, countryName);
                if (d)
                    docs.push(d);
            }
            const totalPages = (_c = (_b = json.page) === null || _b === void 0 ? void 0 : _b.totalPages) !== null && _c !== void 0 ? _c : 1;
            if (page + 1 >= totalPages)
                break;
        }
        catch (e) {
            console.error(`TM ${countryName} failed (page ${page})`, e);
            break;
        }
    }
    return docs.slice(0, PER_COUNTRY);
}
async function runTicketmaster(key) {
    if (!key) {
        console.log('ingestTicketmaster: TICKETMASTER_API_KEY not set — skipping.');
        return 0;
    }
    const all = [];
    for (const [name, iso] of Object.entries(COUNTRY_ISO)) {
        all.push(...(await fetchForCountry(key, iso, name)));
    }
    if (all.length > 0) {
        await upsertAll(all);
        await writeCountryStats(all);
    }
    console.log(`ingestTicketmaster: upserted ${all.length} events.`);
    return all.length;
}
exports.ingestTicketmaster = (0, scheduler_1.onSchedule)({ schedule: 'every 12 hours', timeoutSeconds: 540, memory: '512MiB', secrets: [TICKETMASTER_API_KEY] }, async () => {
    await runTicketmaster(TICKETMASTER_API_KEY.value());
});
// Manual trigger: ?token=<KEY> to pull now; &clear=1 to wipe TM first.
exports.runIngestTicketmasterNow = (0, https_1.onRequest)({ timeoutSeconds: 540, memory: '512MiB', secrets: [TICKETMASTER_API_KEY] }, async (req, res) => {
    const key = TICKETMASTER_API_KEY.value();
    if (!key || req.query.token !== key) {
        res.status(403).send('Forbidden');
        return;
    }
    let cleared = 0;
    if (req.query.clear)
        cleared = await clearSource();
    const count = await runTicketmaster(key);
    res.status(200).json({ ok: true, cleared, upserted: count });
});
//# sourceMappingURL=ticketmaster.js.map