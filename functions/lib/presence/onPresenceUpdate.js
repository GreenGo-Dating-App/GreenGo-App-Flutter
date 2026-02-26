"use strict";
/**
 * onPresenceUpdate Cloud Function
 *
 * Triggers when a profile document is updated. When `isOnline` transitions
 * from false to true (user opens the app), reverse-geocodes the profile's
 * lat/lng to enrich the `location.city` and `location.country` fields.
 *
 * This ensures every user's country is accurate for pool assignment and
 * country-based discovery filtering.
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.onPresenceUpdate = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const axios_1 = __importDefault(require("axios"));
const utils_1 = require("../shared/utils");
const db = admin.firestore();
// Google Geocoding API key from Firebase environment config
const GEOCODING_API_KEY = process.env.GOOGLE_GEOCODING_API_KEY || '';
/**
 * Reverse-geocode lat/lng using Google Geocoding API.
 */
async function reverseGeocode(lat, lng) {
    var _a;
    if (!GEOCODING_API_KEY) {
        (0, utils_1.logError)('onPresenceUpdate: GOOGLE_GEOCODING_API_KEY not configured');
        return null;
    }
    try {
        const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lng}&key=${GEOCODING_API_KEY}&result_type=locality|administrative_area_level_1|country`;
        const response = await axios_1.default.get(url, { timeout: 10000 });
        if (response.data.status !== 'OK' || !((_a = response.data.results) === null || _a === void 0 ? void 0 : _a.length)) {
            (0, utils_1.logInfo)(`onPresenceUpdate: Geocoding returned ${response.data.status} for ${lat},${lng}`);
            return null;
        }
        let city = '';
        let country = '';
        // Parse address components from the first result
        for (const result of response.data.results) {
            for (const component of result.address_components || []) {
                const types = component.types || [];
                if (!country && types.includes('country')) {
                    country = component.long_name;
                }
                if (!city && (types.includes('locality') || types.includes('administrative_area_level_1'))) {
                    city = component.long_name;
                }
            }
            if (city && country)
                break;
        }
        if (!country)
            return null;
        return { city: city || 'Unknown', country };
    }
    catch (error) {
        (0, utils_1.logError)(`onPresenceUpdate: Geocoding API error: ${error}`);
        return null;
    }
}
/**
 * Firestore trigger: profile document updated.
 * Detects isOnline false→true transition and enriches location data.
 */
exports.onPresenceUpdate = (0, firestore_1.onDocumentUpdated)({
    document: 'profiles/{userId}',
    memory: '256MiB',
    timeoutSeconds: 30,
}, async (event) => {
    var _a, _b, _c, _d;
    const beforeData = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before) === null || _b === void 0 ? void 0 : _b.data();
    const afterData = (_d = (_c = event.data) === null || _c === void 0 ? void 0 : _c.after) === null || _d === void 0 ? void 0 : _d.data();
    if (!beforeData || !afterData)
        return;
    // Only trigger on isOnline: false → true transition
    const wasPreviouslyOnline = beforeData.isOnline === true;
    const isNowOnline = afterData.isOnline === true;
    if (wasPreviouslyOnline || !isNowOnline)
        return;
    const userId = event.params.userId;
    const location = afterData.location;
    if (!location)
        return;
    const lat = location.latitude || 0;
    const lng = location.longitude || 0;
    // Skip if no coordinates
    if (lat === 0 && lng === 0) {
        (0, utils_1.logInfo)(`onPresenceUpdate: Skipping ${userId} — no lat/lng`);
        return;
    }
    const currentCity = location.city || '';
    const currentCountry = location.country || '';
    // Only enrich if city/country are missing or "Unknown"
    const needsCity = !currentCity || currentCity === 'Unknown';
    const needsCountry = !currentCountry || currentCountry === 'Unknown';
    if (!needsCity && !needsCountry) {
        return; // Already has valid location data
    }
    (0, utils_1.logInfo)(`onPresenceUpdate: Enriching location for ${userId} (current: ${currentCity}, ${currentCountry})`);
    const geocoded = await reverseGeocode(lat, lng);
    if (!geocoded)
        return;
    // Build update — only overwrite fields that were missing/Unknown
    const update = {};
    if (needsCity && geocoded.city && geocoded.city !== 'Unknown') {
        update['location.city'] = geocoded.city;
    }
    if (needsCountry && geocoded.country) {
        update['location.country'] = geocoded.country;
    }
    if (Object.keys(update).length === 0)
        return;
    try {
        await db.collection('profiles').doc(userId).update(update);
        (0, utils_1.logInfo)(`onPresenceUpdate: Updated ${userId} location → ${geocoded.city}, ${geocoded.country}`);
    }
    catch (error) {
        (0, utils_1.logError)(`onPresenceUpdate: Failed to update ${userId}: ${error}`);
    }
});
//# sourceMappingURL=onPresenceUpdate.js.map