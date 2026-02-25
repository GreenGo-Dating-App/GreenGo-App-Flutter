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

import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import axios from 'axios';
import { logInfo, logError } from '../shared/utils';

const db = admin.firestore();

// Google Geocoding API key from Firebase environment config
const GEOCODING_API_KEY = process.env.GOOGLE_GEOCODING_API_KEY || '';

interface GeocodingResult {
  city: string;
  country: string;
}

/**
 * Reverse-geocode lat/lng using Google Geocoding API.
 */
async function reverseGeocode(lat: number, lng: number): Promise<GeocodingResult | null> {
  if (!GEOCODING_API_KEY) {
    logError('onPresenceUpdate: GOOGLE_GEOCODING_API_KEY not configured');
    return null;
  }

  try {
    const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lng}&key=${GEOCODING_API_KEY}&result_type=locality|administrative_area_level_1|country`;
    const response = await axios.get(url, { timeout: 10000 });

    if (response.data.status !== 'OK' || !response.data.results?.length) {
      logInfo(`onPresenceUpdate: Geocoding returned ${response.data.status} for ${lat},${lng}`);
      return null;
    }

    let city = '';
    let country = '';

    // Parse address components from the first result
    for (const result of response.data.results) {
      for (const component of result.address_components || []) {
        const types: string[] = component.types || [];
        if (!country && types.includes('country')) {
          country = component.long_name;
        }
        if (!city && (types.includes('locality') || types.includes('administrative_area_level_1'))) {
          city = component.long_name;
        }
      }
      if (city && country) break;
    }

    if (!country) return null;

    return { city: city || 'Unknown', country };
  } catch (error) {
    logError(`onPresenceUpdate: Geocoding API error: ${error}`);
    return null;
  }
}

/**
 * Firestore trigger: profile document updated.
 * Detects isOnline false→true transition and enriches location data.
 */
export const onPresenceUpdate = onDocumentUpdated(
  {
    document: 'profiles/{userId}',
    memory: '256MiB',
    timeoutSeconds: 30,
  },
  async (event) => {
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    if (!beforeData || !afterData) return;

    // Only trigger on isOnline: false → true transition
    const wasPreviouslyOnline = beforeData.isOnline === true;
    const isNowOnline = afterData.isOnline === true;

    if (wasPreviouslyOnline || !isNowOnline) return;

    const userId = event.params.userId;
    const location = afterData.location as Record<string, unknown> | undefined;

    if (!location) return;

    const lat = (location.latitude as number) || 0;
    const lng = (location.longitude as number) || 0;

    // Skip if no coordinates
    if (lat === 0 && lng === 0) {
      logInfo(`onPresenceUpdate: Skipping ${userId} — no lat/lng`);
      return;
    }

    const currentCity = (location.city as string) || '';
    const currentCountry = (location.country as string) || '';

    // Only enrich if city/country are missing or "Unknown"
    const needsCity = !currentCity || currentCity === 'Unknown';
    const needsCountry = !currentCountry || currentCountry === 'Unknown';

    if (!needsCity && !needsCountry) {
      return; // Already has valid location data
    }

    logInfo(`onPresenceUpdate: Enriching location for ${userId} (current: ${currentCity}, ${currentCountry})`);

    const geocoded = await reverseGeocode(lat, lng);
    if (!geocoded) return;

    // Build update — only overwrite fields that were missing/Unknown
    const update: Record<string, unknown> = {};
    if (needsCity && geocoded.city && geocoded.city !== 'Unknown') {
      update['location.city'] = geocoded.city;
    }
    if (needsCountry && geocoded.country) {
      update['location.country'] = geocoded.country;
    }

    if (Object.keys(update).length === 0) return;

    try {
      await db.collection('profiles').doc(userId).update(update);
      logInfo(`onPresenceUpdate: Updated ${userId} location → ${geocoded.city}, ${geocoded.country}`);
    } catch (error) {
      logError(`onPresenceUpdate: Failed to update ${userId}: ${error}`);
    }
  },
);
