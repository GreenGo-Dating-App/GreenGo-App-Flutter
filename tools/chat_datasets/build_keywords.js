#!/usr/bin/env node
/**
 * Build the chat keyword index: attraction / city / country names in the 7 app
 * languages, so the chat can highlight "Colosseo" / "Roma" / "Italia" offline and
 * link them to the attraction page, the city's attractions, or the country's
 * cultural tips.
 *
 * Sources: Firestore `attractions` (greengoScore > --min-score, default 70) with
 * their `wikidataQid`; Wikidata labels + aliases (en it es pt pt-br fr de); the
 * city/country come from the attraction's P131 (located in) / P17 (country).
 *
 * Output (written to --out, default tools/chat_datasets/build/keywords.json):
 *   {
 *     v: <ms epoch>, minScore,
 *     a: { "<attractionId>": [iso2, citySlug, name] },
 *     c: { "<ISO2>:<citySlug>": [cityName] },
 *     k: { "<ISO2>": countryName },
 *     n: [[alias, kind, ref, cap], ...]   // kind a|c|k; ref = id / "ISO2:slug" / ISO2
 *   }
 * `alias` is normalised (lower case, no diacritics, single spaces); `cap` = 1 when
 * the alias is also a common word in one of the 7 languages, so the app only
 * links it when the user wrote it Capitalised (Nice, Split, Reading, Bath).
 *
 * Common words = the top 30,000 of the CC-BY-SA-4.0 FrequencyWords lists
 * (tools/chat_datasets/freq/<lang>_50k.txt, hermitdave/FrequencyWords).
 *
 * Usage (repo root): node tools/chat_datasets/build_keywords.js --project greengo-chat [--min-score 70]
 * Needs Application Default Credentials; on this PC NODE_TLS_REJECT_UNAUTHORIZED=0.
 */
const fs = require('fs');
const path = require('path');

function arg(name, fallback) {
  const i = process.argv.indexOf(name);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}
const projectId = arg('--project', process.env.GCLOUD_PROJECT);
if (!projectId) {
  console.error('Missing --project');
  process.exit(1);
}
const minScore = Number(arg('--min-score', '70'));
const out = arg('--out', path.join(__dirname, 'build', 'keywords.json'));

let admin;
try {
  admin = require(path.join(__dirname, '..', '..', 'functions', 'node_modules', 'firebase-admin'));
} catch (_) {
  admin = require('firebase-admin');
}
if (!admin.apps.length) admin.initializeApp({ projectId });
const db = admin.firestore();

const WD_LANGS = ['en', 'it', 'es', 'pt', 'pt-br', 'fr', 'de'];
const FREQ_LANGS = ['en', 'it', 'es', 'pt', 'pt_br', 'fr', 'de'];
const COMMON_TOP = 30000;
const UA = 'GreenGoDatasetBuilder/1.0 (https://greengochat.com)';

/** Lower case, no diacritics, letters/digits separated by single spaces. */
function norm(s) {
  return String(s || '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[’'`´]/g, "'")
    .replace(/[^\p{L}\p{N}']+/gu, ' ')
    .trim();
}

function loadCommon() {
  const set = new Set();
  for (const l of FREQ_LANGS) {
    const f = path.join(__dirname, 'freq', `${l}_50k.txt`);
    const lines = fs.readFileSync(f, 'utf8').split('\n');
    for (let i = 0; i < Math.min(COMMON_TOP, lines.length); i++) {
      const w = norm(lines[i].split(' ')[0]);
      if (w) set.add(w);
    }
  }
  return set;
}

async function wdEntities(ids, props) {
  const outMap = {};
  for (let i = 0; i < ids.length; i += 50) {
    const chunk = ids.slice(i, i + 50);
    const url = 'https://www.wikidata.org/w/api.php?action=wbgetentities&format=json'
      + `&ids=${chunk.join('|')}&props=${props}&languages=${WD_LANGS.join('|')}`;
    for (let attempt = 0; attempt < 5; attempt++) {
      const res = await fetch(url, { headers: { 'User-Agent': UA } });
      if (res.status === 429 || res.status >= 500) {
        await new Promise((r) => setTimeout(r, 2000 * (attempt + 1)));
        continue;
      }
      const j = await res.json();
      Object.assign(outMap, j.entities || {});
      break;
    }
    if ((i / 50) % 20 === 0) console.log(`  wikidata ${props}: ${Math.min(i + 50, ids.length)}/${ids.length}`);
    await new Promise((r) => setTimeout(r, 200)); // be polite
  }
  return outMap;
}

function namesOf(entity) {
  const names = [];
  if (!entity) return names;
  for (const l of WD_LANGS) {
    const lab = entity.labels?.[l]?.value;
    if (lab) names.push({ text: lab, main: true });
    for (const a of entity.aliases?.[l] || []) names.push({ text: a.value, main: false });
  }
  return names;
}

function claimIds(entity, prop) {
  return (entity?.claims?.[prop] || [])
    .map((c) => c.mainsnak?.datavalue?.value?.id)
    .filter(Boolean);
}

async function main() {
  const common = loadCommon();
  console.log(`common words: ${common.size}`);

  const snap = await db.collection('attractions').where('greengoScore', '>', minScore)
    .select('id', 'name', 'officialName', 'cityName', 'citySlug', 'countryIso2', 'countryName', 'wikidataQid')
    .get();
  console.log(`attractions > ${minScore}: ${snap.size}`);

  const rows = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  const qids = [...new Set(rows.map((r) => r.wikidataQid).filter((q) => /^Q\d+$/.test(q || '')))];
  console.log(`with wikidata: ${qids.length}`);

  const ent = await wdEntities(qids, 'labels|aliases|claims');

  // City + country entities via P131 / P17.
  const placeIds = new Set();
  const countryIds = new Set();
  for (const q of qids) {
    for (const id of claimIds(ent[q], 'P131')) placeIds.add(id);
    for (const id of claimIds(ent[q], 'P17')) countryIds.add(id);
  }
  const places = await wdEntities([...placeIds], 'labels|aliases');
  // labels only: 50 countries with all their claims is too big for one response.
  const countries = await wdEntities([...countryIds], 'labels|aliases');

  const index = { v: Date.now(), minScore, a: {}, c: {}, k: {}, n: [] };
  const seen = new Set();
  const add = (text, kind, ref, main) => {
    const alias = norm(text);
    if (alias.length < 3) return;
    const oneWord = !alias.includes(' ');
    const isCommon = oneWord && common.has(alias);
    // A generic single word that is only an alias (e.g. "amphitheater") is dropped;
    // a main label that is also a common word (Nice, Split) needs Capitals.
    if (isCommon && !main) return;
    const key = `${alias}|${kind}|${ref}`;
    if (seen.has(key)) return;
    seen.add(key);
    index.n.push([alias, kind, ref, isCommon ? 1 : 0]);
  };

  // Country ISO2: the catalogue country of the attractions that point at it (P17).
  const votes = {};
  for (const r of rows) {
    for (const cid of claimIds(ent[r.wikidataQid], 'P17')) {
      const v = (votes[cid] ??= {});
      const iso = (r.countryIso2 || '').toUpperCase();
      v[iso] = (v[iso] || 0) + 1;
    }
  }
  // Only the present-day country: per ISO2 keep the ONE Wikidata entity most
  // attractions point at (older attractions also point at the Republic of
  // Venice, the Papal States...; those must not become "Italy").
  const best = {};
  for (const [cid, v] of Object.entries(votes)) {
    const [iso, n] = Object.entries(v).sort((a, b) => b[1] - a[1])[0];
    if (!best[iso] || n > best[iso][1]) best[iso] = [cid, n];
  }
  const isoOfCountry = {};
  for (const [iso, [cid]] of Object.entries(best)) isoOfCountry[cid] = iso;

  let cityHits = 0;
  for (const r of rows) {
    const iso = (r.countryIso2 || '').toUpperCase();
    const cityKey = `${iso}:${r.citySlug}`;
    index.a[r.id] = [iso, r.citySlug, r.name];
    index.c[cityKey] ??= [r.cityName];
    index.k[iso] ??= r.countryName || iso;

    // Attraction names: our catalogue names + Wikidata labels/aliases.
    add(r.name, 'a', r.id, true);
    if (r.officialName) add(r.officialName, 'a', r.id, true);
    const e = ent[r.wikidataQid];
    for (const nm of namesOf(e)) {
      add(nm.text, 'a', r.id, nm.main);
      // "Coliseu de Roma" -> "Coliseu": drop a trailing "de/di/of/von/du <city>".
      const short = nm.text.replace(/\s+(de|di|da|do|del|della|of|von|du|des|in)\s+.+$/i, '');
      if (short !== nm.text && norm(short).length >= 5 && norm(nm.text).includes(norm(r.cityName))) {
        add(short, 'a', r.id, false);
      }
    }

    // City names: our name + the P131 place whose label matches our city name.
    add(r.cityName, 'c', cityKey, true);
    for (const pid of claimIds(e, 'P131')) {
      const p = places[pid];
      const labels = namesOf(p);
      if (labels.some((l) => norm(l.text) === norm(r.cityName))) {
        cityHits++;
        for (const l of labels) add(l.text, 'c', cityKey, l.main);
      }
    }
  }

  // Country names (only the 85 published countries we have tips for).
  for (const [id, e] of Object.entries(countries)) {
    const iso = isoOfCountry[id];
    if (!iso || !index.k[iso]) continue;
    for (const l of namesOf(e)) add(l.text, 'k', iso, l.main);
  }

  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, JSON.stringify(index));
  const kb = (fs.statSync(out).size / 1024).toFixed(0);
  console.log(`DONE: ${Object.keys(index.a).length} attractions, ${Object.keys(index.c).length} cities `
    + `(${cityHits} city name matches via Wikidata), ${Object.keys(index.k).length} countries, `
    + `${index.n.length} aliases, ${kb} KB -> ${out}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
