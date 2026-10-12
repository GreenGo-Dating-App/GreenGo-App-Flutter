#!/usr/bin/env node
/**
 * One-off catalogue location fixes (2026-10-13): attractions filed under the
 * wrong country / city. Moves an attraction (doc fields + location text, its
 * compact row between attractions_index shards, attraction_name_index iso2,
 * attraction_countries counts + indexVersion) or unpublishes it. Afterwards
 * run: node scripts/build_attractions_lite.js --project greengo-chat --country <isos>
 *
 *   node tools/attractions_about/fix_locations.js --project greengo-chat [--dry-run]
 */
const path = require('path');
const admin = require(path.join(__dirname, '../../functions/node_modules/firebase-admin'));

const dry = process.argv.includes('--dry-run');
admin.initializeApp({ projectId: 'greengo-chat' });
const db = admin.firestore();

const IL = { iso2: 'IL', countryName: 'Israel', timezone: 'Asia/Jerusalem', currency: 'ILS', region: 'Western Asia', continent: 'Asia' };
const FIXES = [
  { id: 6512, to: { ...IL, cityName: 'Ein Gedi', citySlug: 'ein-gedi', cityLat: 31.4609, cityLng: 35.3884, stateProvince: 'Southern District' } },
  { id: 6531, to: { ...IL, cityName: 'Nazareth', citySlug: 'nazareth', cityLat: 32.6996, cityLng: 35.3035, stateProvince: 'Northern District' } },
  // Near Nablus (West Bank): no Palestine in the catalogue, never file it under Jordan or Israel.
  { id: 6521, unpublish: true },
  { id: 6522, unpublish: true },
  { id: 6851, to: { iso2: 'IT', countryName: 'Italy', cityName: 'Trieste', citySlug: 'trieste', cityLat: 45.65028, cityLng: 13.77028, stateProvince: 'Friuli Venezia Giulia', timezone: 'Europe/Rome', currency: 'EUR', region: 'Southern Europe', continent: 'Europe' } },
  { id: 600221, to: { iso2: 'US', countryName: 'United States', cityName: 'Roosevelt', citySlug: 'roosevelt', cityLat: 40.29861, cityLng: -109.99417, stateProvince: 'Utah', timezone: 'America/Denver', currency: 'USD', region: 'Northern America', continent: 'North America' } },
];

const TEXT_FIELDS = ['descriptionShort', 'descriptionMedium', 'descriptionLong', 'historySummary', 'streetAddress', 'altText', 'photographyTips'];
const LIST_FIELDS = ['tags', 'interestingFacts', 'topHighlights'];

function swap(s, pairs) {
  if (typeof s !== 'string') return s;
  let out = s;
  for (const [a, b] of pairs) if (a && b && a !== b) out = out.split(a).join(b);
  return out;
}

async function shardsOf(iso) {
  // {ISO}_meta (total, shardCount, version) lives in the same collection: not a shard.
  const s = await db.collection('attractions_index').where('iso2', '==', iso).get();
  return s.docs.filter((d) => !d.id.endsWith('_meta')).sort((a, b) => a.get('shard') - b.get('shard'));
}

async function main() {
  const touched = new Set();
  for (const f of FIXES) {
    const ref = db.collection('attractions').doc(String(f.id));
    const doc = (await ref.get()).data();
    if (!doc) { console.log(`${f.id}: missing`); continue; }
    const from = doc.countryIso2;
    touched.add(from);

    // 1. Take the compact row out of its current shard.
    let row = null;
    for (const sh of await shardsOf(from)) {
      const items = sh.get('items') || [];
      const i = items.findIndex((x) => x.i === f.id);
      if (i < 0) continue;
      row = items[i];
      items.splice(i, 1);
      console.log(`${doc.name}: remove from ${sh.id}`);
      if (!dry) await sh.ref.update({ items, count: items.length, version: Date.now(), updatedAt: admin.firestore.FieldValue.serverTimestamp() });
      break;
    }

    const names = await db.collection('attraction_name_index').where('id', '==', f.id).get();

    if (f.unpublish) {
      console.log(`${doc.name}: unpublish (${names.size} name-index docs removed)`);
      if (!dry) {
        await ref.update({ status: 'hidden', hiddenReason: 'location: West Bank, not in the catalogue', updatedAt: admin.firestore.FieldValue.serverTimestamp() });
        const b = db.batch();
        names.docs.forEach((d) => b.delete(d.ref));
        await b.commit();
      }
      continue;
    }

    // 2. Move: fields + location wording.
    const t = f.to;
    touched.add(t.iso2);
    const pairs = [[doc.cityName, t.cityName], [doc.countryName, t.countryName], [doc.stateProvince, t.stateProvince]];
    const update = {
      countryIso2: t.iso2, countryName: t.countryName, cityName: t.cityName, citySlug: t.citySlug,
      cityLat: t.cityLat, cityLng: t.cityLng, stateProvince: t.stateProvince, timezone: t.timezone,
      currency: t.currency, region: t.region, continent: t.continent,
      slug: String(doc.slug || '').replace(doc.citySlug, t.citySlug),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    for (const k of TEXT_FIELDS) if (doc[k]) update[k] = swap(doc[k], pairs);
    for (const k of LIST_FIELDS) if (Array.isArray(doc[k])) update[k] = doc[k].map((x) => swap(x, pairs));
    console.log(`${doc.name}: ${from}/${doc.cityName} -> ${t.iso2}/${t.cityName} | ${update.descriptionShort || ''}`);

    // 3. Row into the target country's last shard (new shard when full).
    if (row) {
      const newRow = { ...row, c: t.cityName, cs: t.citySlug, cu: t.currency, s: update.slug };
      if (typeof row.d === 'string') newRow.d = swap(row.d, pairs);
      const target = await shardsOf(t.iso2);
      const last = target[target.length - 1];
      if (!dry) {
        if (last && (last.get('items') || []).length < 500) {
          const items = [...(last.get('items') || []), newRow];
          await last.ref.update({ items, count: items.length, version: Date.now(), updatedAt: admin.firestore.FieldValue.serverTimestamp() });
        } else {
          const n = last ? last.get('shard') + 1 : 0;
          await db.collection('attractions_index').doc(`${t.iso2}_${n}`).set({ iso2: t.iso2, shard: n, count: 1, items: [newRow], version: Date.now(), updatedAt: admin.firestore.FieldValue.serverTimestamp() });
        }
      }
    }
    if (!dry) {
      await ref.update(update);
      const b = db.batch();
      names.docs.forEach((d) => b.update(d.ref, { iso2: t.iso2 }));
      await b.commit();
    }
  }

  // 4. Counts from the shards; ONE version on every shard, {ISO}_meta and
  // attraction_countries (the app and build_attractions_lite.js require them
  // to agree, else they fall back / skip the country).
  for (const iso of touched) {
    const shards = await shardsOf(iso);
    const items = shards.flatMap((s) => s.get('items') || []);
    const cities = new Set(items.map((x) => x.cs));
    const v = Date.now();
    console.log(`${iso}: ${items.length} attractions, ${cities.size} cities, version ${v}`);
    if (dry) continue;
    const b = db.batch();
    for (const sh of shards) b.update(sh.ref, { version: v });
    b.update(db.collection('attractions_index').doc(`${iso}_meta`), { total: items.length, shardCount: shards.length, version: v });
    b.update(db.collection('attraction_countries').doc(iso), {
      total: items.length, publishedCount: items.length, cityCount: cities.size,
      indexVersion: v, updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await b.commit();
  }
  console.log(`countries touched: ${[...touched].join(',')}`);
}

main().catch((e) => { console.error(e); process.exit(1); });
