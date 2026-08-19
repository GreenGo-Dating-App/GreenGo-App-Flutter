/**
 * Seed curated attractions into Firestore for the launch countries.
 *
 * Writes
 *   attractions/{id}                     full record (app-facing)
 *   attractions/{id}/meta/marketing      SEO / AI-prompt block (admin-only)
 *   attractions_index/{ISO2}_0           compact shard the app actually lists
 *   attractions_index/{ISO2}_meta        version gate
 *   attraction_countries/{ISO2}          coverage + publish flag
 *   attraction_cities/{ISO2}_{citySlug}  city registry
 *   attraction_taxonomy/{categoryKey}    26 categories -> icon + group + labels
 *   attraction_config/app                cdn-free config the app reads
 *
 * Gate: only attractions with an uploaded image set are published.
 *
 * Usage: NODE_PATH=../../functions/node_modules node seed_firestore.cjs [--dry]
 */
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const XLSX = require('xlsx');

const SA = 'D:/Projects/GreenGo/firebase/greengo-chat-firebase-adminsdk.json';
const BUCKET = 'greengo-chat.firebasestorage.app';
const XLSX_PATH = 'C:/Users/Software Engineering/Desktop/Travel-Attractions-Dataset/master.xlsx';
const UPLOADS = path.join(__dirname, 'upload_manifest.json');
const COUNTRIES = null; // null = every country present in the sheet
const DRY = process.argv.includes('--dry');

admin.initializeApp({ credential: admin.credential.cert(require(SA)), storageBucket: BUCKET });
const db = admin.firestore();

// ---- category -> icon + group (1 category, 1 icon) --------------------------
const CATS = {
  'Religious':        ['temple',            'religious',      'Religious site'],
  'Historic Site':    ['history_edu',       'landmarks',      'Historic site'],
  'Museum':           ['museum',            'museums',        'Museum'],
  'Nature':           ['forest',            'nature',         'Nature'],
  'Neighborhood':     ['holiday_village',   'neighborhoods',  'Neighbourhood'],
  'Beach':            ['beach_access',      'beaches',        'Beach'],
  'Garden':           ['local_florist',     'gardens',        'Garden'],
  'Monument':         ['account_balance',   'landmarks',      'Monument'],
  'Square':           ['location_city',     'landmarks',      'Square'],
  'Street':           ['signpost',          'landmarks',      'Street'],
  'Architecture':     ['apartment',         'landmarks',      'Architecture'],
  'Observation Deck': ['visibility',        'viewpoints',     'Viewpoint'],
  'Castle':           ['castle',            'castlesPalaces', 'Castle'],
  'Market':           ['storefront',        'markets',        'Market'],
  'Mountain':         ['terrain',           'nature',         'Mountain'],
  'Palace':           ['villa',             'castlesPalaces', 'Palace'],
  'Island':           ['water',             'nature',         'Island'],
  'Lake':             ['water_drop',        'nature',         'Lake'],
  'National Park':    ['park',              'nature',         'National park'],
  'Other':            ['place',             'other',          'Other'],
  'Bridge':           ['bridge',            'landmarks',      'Bridge'],
  'Theme Park':       ['attractions',       'family',         'Theme park'],
  'Waterfall':        ['waves',             'nature',         'Waterfall'],
  'Zoo':              ['pets',              'family',         'Zoo'],
  'Shopping':         ['shopping_bag',      'markets',        'Shopping'],
  'Aquarium':         ['aquarium',          'family',         'Aquarium'],
};

const IMPORTANCE = {
  'World Icon':             ['world_icon',    'public',          5],
  'International Landmark': ['international', 'travel_explore',  4],
  'National Landmark':      ['national',      'flag',            3],
  'Regional Attraction':    ['regional',      'map',             2],
  'Local Attraction':       ['local',         'place',           1],
};

function tierOf(score) {
  if (score >= 90) return 'iconic';
  if (score >= 80) return 'exceptional';
  if (score >= 70) return 'excellent';
  if (score >= 60) return 'great';
  return 'worth_visit';
}

const slugify = (s) => String(s).toLowerCase().normalize('NFKD')
  .replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

const num = (v) => (v === undefined || v === null || v === '' || Number.isNaN(Number(v)))
  ? null : Number(v);
const str = (v) => (v === undefined || v === null || String(v).trim() === '' ||
  String(v).toLowerCase() === 'nan') ? null : String(v).trim();
const bool = (v) => v === true || String(v).toLowerCase() === 'true';
const splitList = (v) => {
  const s = str(v);
  if (!s) return [];
  return s.split(/;\s*|\.\s+(?=[A-Z])/).map((x) => x.trim()).filter(Boolean).slice(0, 8);
};

async function commitAll(ops) {
  let batch = db.batch(), n = 0, committed = 0;
  for (const fn of ops) {
    fn(batch); n++;
    if (n >= 400) { await batch.commit(); committed += n; batch = db.batch(); n = 0; }
  }
  if (n) { await batch.commit(); committed += n; }
  return committed;
}

(async () => {
  const uploads = JSON.parse(fs.readFileSync(UPLOADS, 'utf8'));
  const wb = XLSX.readFile(XLSX_PATH);
  const rows = XLSX.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]], { defval: null })
    .filter((r) => !COUNTRIES || COUNTRIES.includes(String(r.CountryISO2)));
  console.log(`rows for launch countries: ${rows.length}`);

  const ops = [];
  const byCountry = {};
  const cityMap = {};
  const countryName = {};
  const catsSeen = new Set();
  let published = 0, skipped = 0, noScore = 0;

  for (const r of rows) {
    const id = Number(r.AttractionID);
    const up = uploads[String(id)];
    if (!up) { skipped++; continue; } // gate: no image => not published

    // Gate: every published attraction MUST carry a GreenGo Score. A record
    // without one would render a blank badge on every card.
    const rawScore = num(r.PopularityScore);
    if (rawScore === null || rawScore <= 0) {
      noScore++;
      continue;
    }

    const iso = String(r.CountryISO2);
    const citySlug = slugify(r.CityName);
    const cat = str(r.Category) || 'Other';
    const catMeta = CATS[cat] || CATS['Other'];
    const impMeta = IMPORTANCE[str(r.ImportanceLevel)] || IMPORTANCE['Local Attraction'];
    const score = rawScore;
    catsSeen.add(cat);

    const lat = num(r.WikidataLat) ?? num(r.Latitude);
    const lng = num(r.WikidataLng) ?? num(r.Longitude);
    const coordVerified = num(r.WikidataLat) !== null;

    const attribution = up.kind === 'ai' ? null : {
      author: str(r.CommonsImageAuthor),
      license: str(r.CommonsImageLicense),
      sourceUrl: str(r.CommonsImageUrl),
      required: String(r.CommonsAttributionRequired) === 'Yes',
    };

    const doc = {
      id, slug: str(r.Slug), name: str(r.AttractionName), officialName: str(r.OfficialName),
      countryIso2: iso, countryName: str(r.CountryName), continent: str(r.Continent),
      region: str(r.Region), stateProvince: str(r.StateProvince),
      cityName: str(r.CityName), citySlug,
      cityLat: num(r.CityLatitude), cityLng: num(r.CityLongitude),
      timezone: str(r.Timezone), streetAddress: str(r.StreetAddress),

      lat, lng, coordVerified,
      coordSource: coordVerified ? 'wikidata' : 'dataset',
      wikidataQid: str(r.WikidataQID),

      category: cat, categoryIcon: catMeta[0], categoryGroup: catMeta[1],
      importanceLevel: str(r.ImportanceLevel), importanceKey: impMeta[0],
      importanceIcon: impMeta[1], importanceRank: impMeta[2],

      greengoScore: score, scoreTier: tierOf(score),
      googleRating: num(r.GoogleRatingApprox),
      photographyScore: num(r.PhotographyScore),
      bucketListScore: num(r.BucketListScore),
      historicalScore: num(r.HistoricalImportanceScore),
      architecturalScore: num(r.ArchitecturalImportanceScore),
      naturalScore: num(r.NaturalImportanceScore),
      annualVisitors: str(r.AnnualVisitorsApprox),

      unesco: bool(r.UNESCO), mustVisit: bool(r.MustVisit),
      topInCity: bool(r.TopAttractionInCity),
      top10Country: bool(r.Top10CountryAttraction),
      worldTop1000: bool(r.WorldTop1000),

      freeEntry: bool(r.FreeEntry), ticketPrice: num(r.AverageTicketPrice),
      currency: str(r.Currency),
      openingHours: str(r.OpeningHours), visitDuration: str(r.AverageVisitDuration),
      bestSeason: str(r.BestSeason), bestTimeOfDay: str(r.BestTimeOfDay),
      indoorOutdoor: str(r.IndoorOutdoor),
      wheelchairAccessible: str(r.WheelchairAccessible),
      petFriendly: str(r.PetFriendly), safetyLevel: str(r.SafetyLevel),

      descriptionShort: str(r.DescriptionShort),
      descriptionMedium: str(r.DescriptionMedium),
      descriptionLong: str(r.DescriptionLong),
      historySummary: str(r.HistorySummary),
      topHighlights: splitList(r.TopHighlights),
      photographyTips: str(r.PhotographyTips),
      interestingFacts: splitList(r.InterestingFacts),
      altText: str(r.AltText),
      tags: (str(r.Tags) || '').split(',').map((s) => s.trim()).filter(Boolean),

      img: { base: up.base, hash: up.hash, token: up.token, source: up.kind },
      attribution,

      status: 'published',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    ops.push((b) => b.set(db.collection('attractions').doc(String(id)), doc, { merge: true }));
    ops.push((b) => b.set(
      db.collection('attractions').doc(String(id)).collection('meta').doc('marketing'),
      {
        seoTitle: str(r.SEO_Title), seoDescription: str(r.SEO_MetaDescription),
        seoKeywords: str(r.SEO_Keywords), searchKeywords: str(r.SearchKeywords),
        aiImagePrompt: str(r.AIImagePrompt), negativePrompt: str(r.NegativePrompt),
        instagramCaption: str(r.InstagramCaption), tiktokCaption: str(r.TikTokCaption),
        commonsFile: str(r.CommonsImageFile), commonsUrl: str(r.CommonsImageUrl),
      }, { merge: true }));

    countryName[iso] = doc.countryName || iso;
    (byCountry[iso] = byCountry[iso] || []).push({
      i: id, s: doc.slug, n: doc.name, c: doc.cityName, cs: citySlug,
      cat, ci: catMeta[0], cg: catMeta[1],
      imp: impMeta[0], ii: impMeta[1],
      la: lat, ln: lng,
      b: up.base, h: up.hash, tk: up.token,
      sc: score, st: doc.scoreTier,
      r: doc.googleRating, tp: doc.ticketPrice, cu: doc.currency, f: doc.freeEntry,
      u: doc.unesco, mv: doc.mustVisit, t10: doc.top10Country,
      d: doc.descriptionShort, vd: doc.visitDuration, io: doc.indoorOutdoor,
      wa: doc.wheelchairAccessible,
      at: attribution && attribution.required
        ? { a: attribution.author, l: attribution.license } : null,
    });

    const ck = `${iso}_${citySlug}`;
    if (!cityMap[ck]) {
      cityMap[ck] = {
        id: ck, iso2: iso, countryName: doc.countryName,
        citySlug, cityName: doc.cityName,
        lat: doc.cityLat, lng: doc.cityLng, timezone: doc.timezone,
        population: num(r.CityPopulation),
        published: true, attractionCount: 0, heroAttractionId: id, heroScore: score,
      };
    }
    cityMap[ck].attractionCount++;
    if (score > cityMap[ck].heroScore) { cityMap[ck].heroAttractionId = id; cityMap[ck].heroScore = score; }
    published++;
  }

  // index shards (<=500 per shard; each country has <=100)
  const version = Date.now();
  for (const [iso, items] of Object.entries(byCountry)) {
    items.sort((a, b) => b.sc - a.sc);
    for (let i = 0; i * 500 < items.length; i++) {
      const slice = items.slice(i * 500, (i + 1) * 500);
      ops.push((b) => b.set(db.collection('attractions_index').doc(`${iso}_${i}`), {
        iso2: iso, shard: i, count: slice.length, items: slice, version,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }));
    }
    ops.push((b) => b.set(db.collection('attractions_index').doc(`${iso}_meta`), {
      iso2: iso, shardCount: Math.ceil(items.length / 500), total: items.length,
      version, updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }));
  }

  // country registry
  for (const [iso, items] of Object.entries(byCountry)) {
    const cities = Object.values(cityMap).filter((c) => c.iso2 === iso);
    ops.push((b) => b.set(db.collection('attraction_countries').doc(iso), {
      iso2: iso, name: countryName[iso] || iso, published: true,
      total: items.length, publishedCount: items.length, cityCount: cities.length,
      indexVersion: version,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true }));
  }

  // city registry
  for (const c of Object.values(cityMap)) {
    const { heroScore, ...rest } = c;
    ops.push((b) => b.set(db.collection('attraction_cities').doc(c.id),
      { ...rest, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true }));
  }

  // taxonomy: one doc per category (icon + group + label)
  let order = 0;
  for (const [cat, [icon, group, label]] of Object.entries(CATS)) {
    const key = slugify(cat);
    ops.push((b) => b.set(db.collection('attraction_taxonomy').doc(key), {
      key, category: cat, icon, group, order: order++,
      fallbackLabel: label, published: catsSeen.has(cat),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true }));
  }

  // config
  ops.push((b) => b.set(db.collection('attraction_config').doc('app'), {
    storageBucket: BUCKET,
    imageUrlTemplate:
      'https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media&token={token}',
    variants: ['micro', 'thumb', 'card', 'hero'],
    defaultSort: 'distance',
    sortOptions: ['distance', 'score', 'rating', 'price', 'name'],
    scoreTiers: [
      { key: 'iconic', min: 90 }, { key: 'exceptional', min: 80 },
      { key: 'excellent', min: 70 }, { key: 'great', min: 60 },
      { key: 'worth_visit', min: 0 },
    ],
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true }));

  console.log(`published=${published} skipped(no image)=${skipped} `
    + `skipped(no score)=${noScore} writes=${ops.length}`);
  if (DRY) { console.log('DRY RUN - nothing written'); process.exit(0); }

  const n = await commitAll(ops);
  console.log('\n=== FIRESTORE SEED DONE ===');
  console.log(`writes committed : ${n}`);
  console.log(`attractions      : ${published}`);
  for (const [iso, items] of Object.entries(byCountry)) console.log(`  ${iso}: ${items.length}`);
  console.log(`cities           : ${Object.keys(cityMap).length}`);
  console.log(`taxonomy docs    : ${Object.keys(CATS).length}`);
  process.exit(0);
})().catch((e) => { console.error('FATAL', e); process.exit(1); });
