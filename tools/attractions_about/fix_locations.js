#!/usr/bin/env node
/**
 * Catalogue location fixes: attractions filed under the wrong country / city,
 * with wrong coordinates, or outside the catalogue (unpublish). Fixes come from
 * a JSON file, one object per attraction:
 *
 *   {"id": 6855, "to": "IT_trieste"}                move (attraction_cities doc id)
 *   {"id": 1117, "lat": 47.7972, "lng": 13.0461}    coordinates only
 *   {"id": 6523, "unpublish": "West Bank, not in the catalogue"}
 *
 * A move updates the doc (country/city/region fields and the location wording
 * of the English texts), moves its compact row between attractions_index
 * shards, fixes attraction_name_index iso2, recounts the attraction_cities it
 * left / joined (count, hero, published) and puts ONE version on the shards /
 * {ISO}_meta / attraction_countries of every touched country. Every doc update
 * is also appended to --log (default build/location_fix.jsonl) so the i18n
 * pipeline's source.jsonl can be patched. Afterwards rebuild the lite shards:
 *   node scripts/build_attractions_lite.js --project greengo-chat --country <isos>
 *
 *   node tools/attractions_about/fix_locations.js --fixes <file.json> [--dry-run]
 */
const fs = require('fs');
const path = require('path');
const admin = require(path.join(__dirname, '../../functions/node_modules/firebase-admin'));

const arg = (k, d) => { const i = process.argv.indexOf(k); return i > 0 ? process.argv[i + 1] : d; };
const dry = process.argv.includes('--dry-run');
const FIXES = JSON.parse(fs.readFileSync(arg('--fixes'), 'utf8'));
const LOG = arg('--log', path.join(__dirname, '../attractions_i18n/build/location_fix.jsonl'));
admin.initializeApp({ projectId: 'greengo-chat' });
const db = admin.firestore();
const now = () => admin.firestore.FieldValue.serverTimestamp();

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

/** Country-level fields of the target city, from one attraction already filed there. */
async function target(cityId) {
  const c = (await db.collection('attraction_cities').doc(cityId).get()).data();
  if (!c) throw new Error(`no attraction_cities/${cityId}`);
  const s = await db.collection('attractions').where('countryIso2', '==', c.iso2)
    .where('citySlug', '==', c.citySlug).limit(1).get();
  if (s.empty) throw new Error(`no attraction in ${cityId} to copy the region fields from`);
  const r = s.docs[0].data();
  return {
    iso2: c.iso2, countryName: r.countryName, cityName: c.cityName, citySlug: c.citySlug,
    cityLat: c.lat, cityLng: c.lng, stateProvince: r.stateProvince, timezone: r.timezone,
    currency: r.currency, region: r.region, continent: r.continent,
  };
}

async function main() {
  const touched = new Set();
  const cities = new Set(); // `${iso}_${slug}` to recount
  const log = [];
  for (const f of FIXES) {
    const ref = db.collection('attractions').doc(String(f.id));
    const doc = (await ref.get()).data();
    if (!doc) { console.log(`${f.id}: missing`); continue; }
    const from = doc.countryIso2;
    touched.add(from);
    cities.add(`${from}_${doc.citySlug}`);
    const shards = await shardsOf(from);
    const sh = shards.find((s) => (s.get('items') || []).some((x) => x.i === f.id));
    const items = sh ? [...sh.get('items')] : [];
    const at = items.findIndex((x) => x.i === f.id);
    const row = at >= 0 ? items[at] : null;

    if (f.lat != null) {
      const update = { lat: f.lat, lng: f.lng, coordSource: 'manual', updatedAt: now() };
      console.log(`${doc.name}: coordinates ${doc.lat},${doc.lng} -> ${f.lat},${f.lng}`);
      log.push({ id: String(f.id), set: { lat: f.lat, lng: f.lng, coordSource: 'manual' } });
      if (!dry) {
        await ref.update(update);
        if (row) {
          items[at] = { ...row, la: f.lat, ln: f.lng };
          await sh.ref.update({ items, updatedAt: now() });
        }
      }
      continue;
    }

    const names = await db.collection('attraction_name_index').where('id', '==', f.id).get();

    if (f.unpublish) {
      console.log(`${doc.name}: unpublish (${f.unpublish}; ${names.size} name-index docs removed)`);
      log.push({ id: String(f.id), set: { status: 'hidden' } });
      if (!dry) {
        if (row) {
          items.splice(at, 1);
          await sh.ref.update({ items, count: items.length, updatedAt: now() });
        }
        await ref.update({ status: 'hidden', hiddenReason: `location: ${f.unpublish}`, updatedAt: now() });
        const b = db.batch();
        names.docs.forEach((d) => b.delete(d.ref));
        await b.commit();
      }
      continue;
    }

    // Move: fields + location wording.
    const t = await target(f.to);
    touched.add(t.iso2);
    cities.add(`${t.iso2}_${t.citySlug}`);
    const pairs = [[doc.cityName, t.cityName], [doc.countryName, t.countryName], [doc.stateProvince, t.stateProvince]];
    const set = {
      countryIso2: t.iso2, countryName: t.countryName, cityName: t.cityName, citySlug: t.citySlug,
      cityLat: t.cityLat, cityLng: t.cityLng, stateProvince: t.stateProvince, timezone: t.timezone,
      currency: t.currency, region: t.region, continent: t.continent,
      slug: String(doc.slug || '').replace(doc.citySlug, t.citySlug),
    };
    for (const k of TEXT_FIELDS) if (doc[k]) set[k] = swap(doc[k], pairs);
    for (const k of LIST_FIELDS) if (Array.isArray(doc[k])) set[k] = doc[k].map((x) => swap(x, pairs));
    console.log(`${doc.name}: ${from}/${doc.cityName} -> ${t.iso2}/${t.cityName} | ${set.descriptionShort || ''}`);
    log.push({ id: String(f.id), set });
    if (dry) continue;

    // Row out of its shard, into the target country's last shard (new shard when full).
    if (row) {
      items.splice(at, 1);
      await sh.ref.update({ items, count: items.length, updatedAt: now() });
      const newRow = { ...row, c: t.cityName, cs: t.citySlug, cu: t.currency, s: set.slug };
      if (typeof row.d === 'string') newRow.d = swap(row.d, pairs);
      const dest = await shardsOf(t.iso2);
      const last = dest[dest.length - 1];
      if (last && (last.get('items') || []).length < 500) {
        const li = [...(last.get('items') || []), newRow];
        await last.ref.update({ items: li, count: li.length, updatedAt: now() });
      } else {
        const n = last ? last.get('shard') + 1 : 0;
        await db.collection('attractions_index').doc(`${t.iso2}_${n}`).set({ iso2: t.iso2, shard: n, count: 1, items: [newRow], updatedAt: now() });
      }
    }
    await ref.update({ ...set, updatedAt: now() });
    const b = db.batch();
    names.docs.forEach((d) => b.update(d.ref, { iso2: t.iso2 }));
    await b.commit();
  }
  if (!dry) fs.appendFileSync(LOG, log.map((x) => JSON.stringify(x)).join('\n') + '\n');

  // Counts from the shards; ONE version on every shard, {ISO}_meta and
  // attraction_countries (the app and build_attractions_lite.js require them
  // to agree, else they fall back / skip the country).
  for (const iso of touched) {
    const shards = await shardsOf(iso);
    const items = shards.flatMap((s) => s.get('items') || []);
    const slugs = new Set(items.map((x) => x.cs));
    const v = Date.now();
    console.log(`${iso}: ${items.length} attractions, ${slugs.size} cities, version ${v}`);
    if (dry) continue;
    const b = db.batch();
    for (const s of shards) b.update(s.ref, { version: v });
    b.update(db.collection('attractions_index').doc(`${iso}_meta`), { total: items.length, shardCount: shards.length, version: v });
    b.update(db.collection('attraction_countries').doc(iso), {
      total: items.length, publishedCount: items.length, cityCount: slugs.size,
      indexVersion: v, updatedAt: now(),
    });
    for (const id of cities) {
      if (!id.startsWith(`${iso}_`)) continue;
      const slug = id.slice(iso.length + 1);
      const inCity = items.filter((x) => x.cs === slug).sort((p, q) => (q.sc || 0) - (p.sc || 0));
      const upd = { attractionCount: inCity.length, published: inCity.length > 0, updatedAt: now() };
      if (inCity.length) upd.heroAttractionId = inCity[0].i;
      const cref = db.collection('attraction_cities').doc(id);
      if (!(await cref.get()).exists) { console.log(`  ${id}: no city doc`); continue; }
      console.log(`  ${id}: ${inCity.length} attractions`);
      b.update(cref, upd);
    }
    await b.commit();
  }
  console.log(`countries touched: ${[...touched].join(',')}`);
}

main().then(() => process.exit(0), (e) => { console.error(e); process.exit(1); });
