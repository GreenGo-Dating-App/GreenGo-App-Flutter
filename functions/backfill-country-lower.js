/**
 * Backfill script: Normalize country names and add countryLower field
 *
 * Usage: cd functions && node backfill-country-lower.js
 *
 * This script reads all profiles from Firestore, normalizes locale-dependent
 * country names to English (e.g., "Italia" -> "Italy"), and sets countryLower.
 * It processes in batches of 500 to avoid memory issues.
 */

const admin = require('firebase-admin');

admin.initializeApp({
  projectId: 'greengo-chat',
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

// Same normalization map as in the Flutter app
const COUNTRY_NORMALIZATION = {
  // Italian
  'italia': 'Italy', 'stati uniti': 'United States', "stati uniti d'america": 'United States',
  'germania': 'Germany', 'francia': 'France', 'spagna': 'Spain', 'svizzera': 'Switzerland',
  'regno unito': 'United Kingdom', 'paesi bassi': 'Netherlands', 'giappone': 'Japan',
  'cina': 'China', 'brasile': 'Brazil', 'portogallo': 'Portugal', 'svezia': 'Sweden',
  'norvegia': 'Norway', 'danimarca': 'Denmark', 'finlandia': 'Finland', 'belgio': 'Belgium',
  'grecia': 'Greece', 'turchia': 'Turkey', 'egitto': 'Egypt', 'sudafrica': 'South Africa',
  'messico': 'Mexico', 'corea del sud': 'South Korea', 'corea del nord': 'North Korea',
  'nuova zelanda': 'New Zealand', 'irlanda': 'Ireland', 'polonia': 'Poland',
  'romania': 'Romania', 'ungheria': 'Hungary', 'repubblica ceca': 'Czech Republic',
  'croazia': 'Croatia', 'lussemburgo': 'Luxembourg', 'cipro': 'Cyprus', 'islanda': 'Iceland',
  'lettonia': 'Latvia', 'lituania': 'Lithuania', 'estonia': 'Estonia',
  'slovacchia': 'Slovakia', 'slovenia': 'Slovenia', 'albania': 'Albania',
  'marocco': 'Morocco', 'tunisia': 'Tunisia', 'thailandia': 'Thailand',
  'filippine': 'Philippines', 'emirati arabi uniti': 'United Arab Emirates',
  'arabia saudita': 'Saudi Arabia',
  // German
  'deutschland': 'Germany', 'frankreich': 'France', 'vereinigte staaten': 'United States',
  'vereinigtes königreich': 'United Kingdom', 'großbritannien': 'United Kingdom',
  'italien': 'Italy', 'spanien': 'Spain', 'schweiz': 'Switzerland',
  'niederlande': 'Netherlands', 'belgien': 'Belgium', 'österreich': 'Austria',
  'griechenland': 'Greece', 'türkei': 'Turkey', 'ägypten': 'Egypt',
  'brasilien': 'Brazil', 'mexiko': 'Mexico', 'argentinien': 'Argentina',
  'schweden': 'Sweden', 'norwegen': 'Norway', 'dänemark': 'Denmark',
  'finnland': 'Finland', 'irland': 'Ireland', 'polen': 'Poland',
  'rumänien': 'Romania', 'ungarn': 'Hungary', 'tschechien': 'Czech Republic',
  'kroatien': 'Croatia', 'slowakei': 'Slovakia', 'slowenien': 'Slovenia',
  'albanien': 'Albania', 'neuseeland': 'New Zealand', 'südafrika': 'South Africa',
  'südkorea': 'South Korea', 'nordkorea': 'North Korea', 'philippinen': 'Philippines',
  'lettland': 'Latvia', 'litauen': 'Lithuania', 'estland': 'Estonia',
  'tunesien': 'Tunisia', 'saudi-arabien': 'Saudi Arabia',
  'vereinigte arabische emirate': 'United Arab Emirates', 'zypern': 'Cyprus',
  'luxemburg': 'Luxembourg',
  // Spanish
  'estados unidos': 'United States', 'reino unido': 'United Kingdom',
  'alemania': 'Germany', 'españa': 'Spain', 'suiza': 'Switzerland',
  'países bajos': 'Netherlands', 'bélgica': 'Belgium', 'suecia': 'Sweden',
  'noruega': 'Norway', 'dinamarca': 'Denmark', 'turquía': 'Turkey',
  'egipto': 'Egypt', 'japón': 'Japan', 'nueva zelanda': 'New Zealand',
  'sudáfrica': 'South Africa', 'méxico': 'Mexico', 'hungría': 'Hungary',
  'república checa': 'Czech Republic', 'eslovaquia': 'Slovakia', 'eslovenia': 'Slovenia',
  'filipinas': 'Philippines', 'tailandia': 'Thailand',
  'emiratos árabes unidos': 'United Arab Emirates', 'arabia saudí': 'Saudi Arabia',
  'chipre': 'Cyprus', 'islandia': 'Iceland', 'letonia': 'Latvia',
  'marruecos': 'Morocco', 'túnez': 'Tunisia',
  // French
  'états-unis': 'United States', 'états unis': 'United States',
  'royaume-uni': 'United Kingdom', 'allemagne': 'Germany', 'espagne': 'Spain',
  'suisse': 'Switzerland', 'pays-bas': 'Netherlands', 'belgique': 'Belgium',
  'italie': 'Italy', 'autriche': 'Austria', 'grèce': 'Greece',
  'turquie': 'Turkey', 'égypte': 'Egypt', 'brésil': 'Brazil',
  'mexique': 'Mexico', 'argentine': 'Argentina', 'suède': 'Sweden',
  'norvège': 'Norway', 'danemark': 'Denmark', 'finlande': 'Finland',
  'irlande': 'Ireland', 'pologne': 'Poland', 'roumanie': 'Romania',
  'hongrie': 'Hungary', 'tchéquie': 'Czech Republic', 'république tchèque': 'Czech Republic',
  'croatie': 'Croatia', 'slovaquie': 'Slovakia', 'slovénie': 'Slovenia',
  'albanie': 'Albania', 'nouvelle-zélande': 'New Zealand',
  'afrique du sud': 'South Africa', 'corée du sud': 'South Korea',
  'corée du nord': 'North Korea', 'japon': 'Japan', 'chine': 'China',
  'thaïlande': 'Thailand', 'émirats arabes unis': 'United Arab Emirates',
  'arabie saoudite': 'Saudi Arabia', 'chypre': 'Cyprus', 'islande': 'Iceland',
  'lituanie': 'Lithuania', 'lettonie': 'Latvia', 'estonie': 'Estonia',
  'maroc': 'Morocco', 'tunisie': 'Tunisia',
  // Portuguese
  'alemanha': 'Germany', 'frança': 'France', 'espanha': 'Spain',
  'suíça': 'Switzerland', 'itália': 'Italy', 'áustria': 'Austria',
  'grécia': 'Greece', 'turquia': 'Turkey', 'egito': 'Egypt',
  'japão': 'Japan', 'nova zelândia': 'New Zealand', 'áfrica do sul': 'South Africa',
  'coreia do sul': 'South Korea', 'coreia do norte': 'North Korea',
  'polônia': 'Poland', 'romênia': 'Romania', 'hungria': 'Hungary',
  'república tcheca': 'Czech Republic', 'eslováquia': 'Slovakia',
  'eslovênia': 'Slovenia', 'croácia': 'Croatia', 'albânia': 'Albania',
  'tailândia': 'Thailand', 'emirados árabes unidos': 'United Arab Emirates',
  'arábia saudita': 'Saudi Arabia', 'islândia': 'Iceland',
  'letônia': 'Latvia', 'lituânia': 'Lithuania', 'estônia': 'Estonia',
  'marrocos': 'Morocco', 'tunísia': 'Tunisia',
  // English variants
  'united states of america': 'United States', 'usa': 'United States', 'us': 'United States',
  'uk': 'United Kingdom', 'great britain': 'United Kingdom', 'england': 'United Kingdom',
  'holland': 'Netherlands', 'czechia': 'Czech Republic',
  "côte d'ivoire": 'Ivory Coast',
};

function normalizeCountry(country) {
  if (!country) return country;
  return COUNTRY_NORMALIZATION[country.toLowerCase()] || country;
}

async function backfillCountryNormalization() {
  console.log('Starting country normalization backfill...');

  let totalProcessed = 0;
  let totalUpdated = 0;
  let totalSkipped = 0;
  let lastDoc = null;
  const BATCH_SIZE = 500;

  while (true) {
    let query = db.collection('profiles').limit(BATCH_SIZE);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    const batch = db.batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const location = data.location;

      if (location && location.country && typeof location.country === 'string') {
        const normalized = normalizeCountry(location.country);
        const countryLower = normalized.toLowerCase();

        // Update if country needs normalization or countryLower is wrong
        if (location.country !== normalized || location.countryLower !== countryLower) {
          const update = {
            'location.country': normalized,
            'location.countryLower': countryLower,
          };
          batch.update(doc.ref, update);
          batchCount++;
          totalUpdated++;
          if (location.country !== normalized) {
            console.log(`  Normalizing: "${location.country}" -> "${normalized}" (${doc.id.substring(0, 8)})`);
          }
        } else {
          totalSkipped++;
        }
      } else {
        totalSkipped++;
      }

      totalProcessed++;
    }

    if (batchCount > 0) {
      await batch.commit();
      console.log(`Batch committed: ${batchCount} profiles updated (${totalProcessed} processed so far)`);
    } else {
      console.log(`Batch skipped: all ${snapshot.size} profiles already up to date (${totalProcessed} processed so far)`);
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];

    if (snapshot.size < BATCH_SIZE) {
      break;
    }
  }

  console.log('\n--- Backfill Complete ---');
  console.log(`Total processed: ${totalProcessed}`);
  console.log(`Total updated:   ${totalUpdated}`);
  console.log(`Total skipped:   ${totalSkipped}`);
}

backfillCountryNormalization()
  .then(() => {
    console.log('Done!');
    process.exit(0);
  })
  .catch((err) => {
    console.error('Error during backfill:', err);
    process.exit(1);
  });
