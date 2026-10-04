#!/usr/bin/env node
/**
 * Build `attraction_config/geo` - the ONE document the app reads to decide
 * which published country a user is in (AttractionsDataSource.geoIndex /
 * resolveCountry), from `attraction_countries` + `attraction_cities`.
 *
 * Without this doc the app can only use the countries' bounding boxes (it
 * never falls back to reading the ~37k attraction_cities docs), so border
 * cases (Lisbon is inside both the PT and ES boxes) resolve to the home
 * country instead. tools/attractions/seed_firestore.cjs + seed_bbox.cjs write
 * the same doc during a full seed; this script rebuilds it on its own.
 *
 * Format (what the app expects):
 *   {
 *     version: <ms epoch>,
 *     updatedAt: <server timestamp>,
 *     countries: [
 *       { iso2: 'FR', name: 'France', bbox: [S, W, N, E] | null,
 *         cities: [lat, lng, lat, lng, ...] },   // FLAT: Firestore forbids
 *       ...                                       // arrays inside arrays
 *     ]
 *   }
 * Coordinates are rounded to 3 decimals (~110 m), cities sorted by doc id,
 * countries by iso2, so the output is deterministic.
 *
 * Idempotent: it rebuilds from the source collections every time and skips
 * the write when the stored `countries` is already identical (prints
 * "unchanged"). Read-only with --dry-run.
 *
 * Usage (from the repo root; firebase-admin comes from functions/node_modules):
 *   set GOOGLE_APPLICATION_CREDENTIALS=<service-account.json>
 *     (PowerShell: $env:GOOGLE_APPLICATION_CREDENTIALS="...")
 *   node scripts/build_attraction_geo_index.js --project greengo-chat [--dry-run] [--cell 0.05]
 *
 *   --cell <deg>  optional thinning: keep one city per <deg> x <deg> grid cell
 *                 per country. 0 (default) keeps every city. Sizes measured on
 *                 2026-10-04 (37,055 cities): 0 -> ~512 KB, 0.05 -> ~465 KB,
 *                 0.1 -> ~375 KB, 0.2 -> ~250 KB. Thinning only coarsens the
 *                 nearest-city tie-break between overlapping boxes.
 *
 * On this PC the corporate TLS proxy may require NODE_TLS_REJECT_UNAUTHORIZED=0.
 */

const path = require('path');

function arg(name, fallback) {
  const i = process.argv.indexOf(name);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}

const projectId = arg('--project', process.env.GCLOUD_PROJECT);
if (!projectId) {
  console.error('Missing --project <projectId>');
  process.exit(1);
}
process.env.GCLOUD_PROJECT = projectId;
process.env.GOOGLE_CLOUD_PROJECT = projectId;

const dryRun = process.argv.includes('--dry-run');
const cell = Number(arg('--cell', '0'));
if (!Number.isFinite(cell) || cell < 0) {
  console.error('--cell must be a number >= 0');
  process.exit(1);
}

const admin = require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));
if (!admin.apps.length) admin.initializeApp({ projectId });
const db = admin.firestore();

/** Firestore's hard document limit is 1 MiB; leave headroom for field names. */
const MAX_DOC_BYTES = 1024 * 1024 - 16 * 1024;

const round3 = (n) => Number(n.toFixed(3));
const isNum = (v) => typeof v === 'number' && Number.isFinite(v);

async function main() {
  const started = Date.now();
  const [countriesSnap, citiesSnap] = await Promise.all([
    db.collection('attraction_countries').where('published', '==', true).get(),
    db.collection('attraction_cities')
      .where('published', '==', true)
      .select('iso2', 'lat', 'lng')
      .get(),
  ]);
  console.log(
    `read ${countriesSnap.size} countries + ${citiesSnap.size} cities in ${Date.now() - started} ms`,
  );
  if (countriesSnap.empty) {
    // Never overwrite a good doc with an empty one (e.g. wrong project).
    console.error('No published attraction_countries - nothing written.');
    process.exit(1);
  }

  // iso2 -> ordered city coordinates (optionally one per grid cell).
  const cityDocs = [...citiesSnap.docs].sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
  const byIso = new Map();
  let skipped = 0;
  for (const d of cityDocs) {
    const m = d.data();
    const iso = String(m.iso2 || d.id.split('_')[0] || '').toUpperCase();
    if (!iso || !isNum(m.lat) || !isNum(m.lng)) {
      skipped++;
      continue;
    }
    let entry = byIso.get(iso);
    if (!entry) byIso.set(iso, (entry = { cells: new Set(), flat: [] }));
    if (cell > 0) {
      const key = `${Math.floor(m.lat / cell)}:${Math.floor(m.lng / cell)}`;
      if (entry.cells.has(key)) continue;
      entry.cells.add(key);
    }
    entry.flat.push(round3(m.lat), round3(m.lng));
  }

  const countries = countriesSnap.docs
    .map((d) => {
      const m = d.data();
      const iso = String(m.iso2 || d.id).toUpperCase();
      const bbox = Array.isArray(m.bbox) && m.bbox.length === 4 && m.bbox.every(isNum)
        ? m.bbox.map((v) => Number(v))
        : null;
      return {
        iso2: iso,
        name: String(m.name || iso),
        bbox,
        cities: (byIso.get(iso) || { flat: [] }).flat,
      };
    })
    .sort((a, b) => (a.iso2 < b.iso2 ? -1 : a.iso2 > b.iso2 ? 1 : 0));

  const points = countries.reduce((n, c) => n + c.cities.length / 2, 0);
  const bytes = Buffer.byteLength(JSON.stringify({ countries }));
  const noBox = countries.filter((c) => !c.bbox).map((c) => c.iso2);
  const noCity = countries.filter((c) => c.cities.length === 0).map((c) => c.iso2);
  console.log(
    `built ${countries.length} countries, ${points} city points` +
      (cell > 0 ? ` (cell ${cell} deg)` : '') +
      `, ~${Math.round(bytes / 1024)} KB` +
      (skipped ? `, ${skipped} cities without coordinates skipped` : ''),
  );
  if (noBox.length) console.warn(`WARN no bbox (run tools/attractions/seed_bbox.cjs): ${noBox.join(' ')}`);
  if (noCity.length) console.warn(`WARN no cities: ${noCity.join(' ')}`);
  if (bytes > MAX_DOC_BYTES) {
    console.error(
      `Too big for one Firestore document (${bytes} bytes). Re-run with --cell 0.1 (or larger).`,
    );
    process.exit(1);
  }

  const ref = db.collection('attraction_config').doc('geo');
  const current = await ref.get();
  const same = current.exists &&
    JSON.stringify(current.data().countries || null) === JSON.stringify(countries);
  if (same) {
    console.log('attraction_config/geo unchanged - nothing to write.');
    return;
  }
  if (dryRun) {
    console.log(`(dry run) would ${current.exists ? 'replace' : 'create'} attraction_config/geo`);
    return;
  }
  await ref.set({
    version: Date.now(),
    countries,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`attraction_config/geo ${current.exists ? 'replaced' : 'created'}.`);
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error('FAILED:', e && e.message ? e.message : e);
    process.exit(1);
  });
