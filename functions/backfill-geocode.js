/**
 * Backfill script: Reverse geocode profiles that have lat/lng but missing country.
 * Uses free Nominatim (OpenStreetMap) API — no API key needed.
 *
 * Usage: cd functions && node backfill-geocode.js
 */
const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'greengo-chat' });
const db = admin.firestore();

// Country name normalization (match Flutter's normalizeCountryName)
const COUNTRY_MAP = {
  'italia': 'Italy',
  'deutschland': 'Germany',
  'estados unidos': 'United States',
  'états-unis': 'United States',
  'stati uniti': 'United States',
  'vereinigte staaten': 'United States',
  'francia': 'France',
  'frankreich': 'France',
  'espagne': 'Spain',
  'españa': 'Spain',
  'spanien': 'Spain',
  'spagna': 'Spain',
  'portogallo': 'Portugal',
  'brasil': 'Brazil',
  'brasile': 'Brazil',
  'brasilien': 'Brazil',
  'brésil': 'Brazil',
  'regno unito': 'United Kingdom',
  'vereinigtes königreich': 'United Kingdom',
  'royaume-uni': 'United Kingdom',
  'svizzera': 'Switzerland',
  'schweiz': 'Switzerland',
  'suisse': 'Switzerland',
  'österreich': 'Austria',
  'autriche': 'Austria',
  'paesi bassi': 'Netherlands',
  'niederlande': 'Netherlands',
  'pays-bas': 'Netherlands',
  'grecia': 'Greece',
  'griechenland': 'Greece',
  'grèce': 'Greece',
  'turchia': 'Turkey',
  'türkei': 'Turkey',
  'turquie': 'Turkey',
  'giappone': 'Japan',
  'japon': 'Japan',
  'cina': 'China',
  'chine': 'China',
};

function normalizeCountry(name) {
  if (!name) return '';
  const lower = name.trim().toLowerCase();
  return COUNTRY_MAP[lower] || name.trim();
}

async function reverseGeocode(lat, lng) {
  const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=10&addressdetails=1`;
  const resp = await fetch(url, {
    headers: { 'User-Agent': 'GreenGo-Backfill/1.0' }
  });
  if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
  const data = await resp.json();
  const addr = data.address || {};
  const city = addr.city || addr.town || addr.village || addr.municipality || addr.county || '';
  const country = normalizeCountry(addr.country || '');
  return { city, country };
}

async function main() {
  const snap = await db.collection('profiles').get();
  console.log(`Scanning ${snap.size} profiles...`);

  for (const doc of snap.docs) {
    const d = doc.data();
    const loc = d.location || {};
    const lat = loc.latitude || 0;
    const lng = loc.longitude || 0;
    const city = loc.city || '';
    const country = loc.country || '';

    // Skip profiles with no real coordinates
    if (lat === 0 && lng === 0) {
      console.log(`SKIP ${doc.id} (${d.nickname || 'no-nick'}) — no coordinates`);
      continue;
    }

    // Check if country or city is missing
    const needsCountry = !country || country === 'Unknown';
    const needsCity = !city || city === 'Unknown';

    if (!needsCountry && !needsCity) {
      console.log(`OK   ${doc.id} (${d.nickname || 'no-nick'}) — ${city}, ${country}`);
      continue;
    }

    console.log(`FIX  ${doc.id} (${d.nickname || 'no-nick'}) — city="${city}" country="${country}" coords=${lat},${lng}`);

    try {
      const result = await reverseGeocode(lat, lng);
      console.log(`     → resolved: city="${result.city}" country="${result.country}"`);

      const update = {};
      if (needsCountry && result.country) {
        update['location.country'] = result.country;
        update['location.countryLower'] = result.country.toLowerCase();
      }
      if (needsCity && result.city) {
        update['location.city'] = result.city;
      }
      if ((needsCountry || needsCity) && result.city && result.country) {
        update['location.displayAddress'] = `${result.city}, ${result.country}`;
      }

      if (Object.keys(update).length > 0) {
        await db.collection('profiles').doc(doc.id).update(update);
        console.log(`     ✓ Updated ${Object.keys(update).join(', ')}`);
      }

      // Also fix traveler location if needed
      const tloc = d.travelerLocation || {};
      const tlat = tloc.latitude || 0;
      const tlng = tloc.longitude || 0;
      const tcountry = tloc.country || '';
      const tcity = tloc.city || '';

      if (d.isTraveler && tlat !== 0 && tlng !== 0 &&
          (!tcountry || tcountry === 'Unknown' || !tcity || tcity === 'Unknown')) {
        console.log(`     Fixing traveler location too: city="${tcity}" country="${tcountry}"`);
        const tResult = await reverseGeocode(tlat, tlng);
        console.log(`     → traveler resolved: city="${tResult.city}" country="${tResult.country}"`);
        const tUpdate = {};
        if ((!tcountry || tcountry === 'Unknown') && tResult.country) {
          tUpdate['travelerLocation.country'] = tResult.country;
        }
        if ((!tcity || tcity === 'Unknown') && tResult.city) {
          tUpdate['travelerLocation.city'] = tResult.city;
        }
        if (Object.keys(tUpdate).length > 0) {
          await db.collection('profiles').doc(doc.id).update(tUpdate);
          console.log(`     ✓ Updated traveler: ${Object.keys(tUpdate).join(', ')}`);
        }

        // Respect Nominatim rate limit (1 req/sec)
        await new Promise(r => setTimeout(r, 1100));
      }

      // Respect Nominatim rate limit (1 req/sec)
      await new Promise(r => setTimeout(r, 1100));
    } catch (e) {
      console.log(`     ✗ Error: ${e.message}`);
    }
  }

  console.log('\nDone!');
  process.exit(0);
}

main();
