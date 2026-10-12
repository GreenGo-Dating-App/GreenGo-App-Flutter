#!/usr/bin/env node
/**
 * Attraction names in the 7 app languages (+ alternative names for search).
 *
 * For every `attractions/{id}` with a `wikidataQid`, reads the Wikidata labels
 * and aliases (en it es pt pt-br fr de) and writes:
 *   attractions/{id}.names       { en, it, es, pt, pt_BR, fr, de }  (only the
 *                                languages Wikidata has; the app falls back to
 *                                `name`)
 *   attraction_name_index/{key}  one doc per distinct normalised name/alias of
 *                                an attraction: { n: <normalised>, id, iso2,
 *                                score } - the app prefix-searches `n`, so
 *                                "colos" finds Colosseum / Colosseo / Colisée.
 *                                key = `${n}~${id}` (slashes replaced).
 * `scripts/build_attractions_lite.js` then copies `names` into the lite shards
 * (columns n_en ... n_de) so the grid shows the local title offline.
 *
 * Resumable: skips attractions whose `names` is already set unless --force.
 *
 * Usage (repo root):
 *   node scripts/build_attraction_names_i18n.js --project greengo-chat
 *     [--country IT] [--limit N] [--dry-run] [--force]
 * Credentials: Application Default Credentials; on this PC
 * NODE_TLS_REJECT_UNAUTHORIZED=0.
 */
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
const country = (arg('--country', '') || '').toUpperCase();
const limit = Number(arg('--limit', '0')) || Infinity;
const dryRun = process.argv.includes('--dry-run');
const force = process.argv.includes('--force');

let admin;
try {
  admin = require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));
} catch (_) {
  admin = require('firebase-admin');
}
if (!admin.apps.length) admin.initializeApp({ projectId });
const db = admin.firestore();

const WD_LANGS = ['en', 'it', 'es', 'pt', 'pt-br', 'fr', 'de'];
const UA = 'GreenGoDatasetBuilder/1.0 (https://greengochat.com)';
const INDEX = 'attraction_name_index';

/** Same folding as the app's search (lower case, no diacritics, single spaces). */
function norm(s) {
  return String(s || '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[’'`´]/g, "'")
    .replace(/[^\p{L}\p{N}']+/gu, ' ')
    .trim();
}

async function wdEntities(ids) {
  const url = 'https://www.wikidata.org/w/api.php?action=wbgetentities&format=json'
    + `&ids=${ids.join('|')}&props=labels|aliases&languages=${WD_LANGS.join('|')}`;
  for (let attempt = 0; attempt < 6; attempt++) {
    try {
      const res = await fetch(url, { headers: { 'User-Agent': UA } });
      if (res.status === 429 || res.status >= 500) throw new Error(`HTTP ${res.status}`);
      return (await res.json()).entities || {};
    } catch (e) {
      await new Promise((r) => setTimeout(r, 2000 * (attempt + 1)));
    }
  }
  throw new Error('Wikidata kept failing');
}

function namesFrom(e) {
  const lab = (l) => e?.labels?.[l]?.value;
  const names = {};
  const put = (k, v) => { if (v) names[k] = v; };
  put('en', lab('en'));
  put('it', lab('it'));
  put('es', lab('es'));
  put('pt', lab('pt') || lab('pt-br'));
  put('pt_BR', lab('pt-br') || lab('pt'));
  put('fr', lab('fr'));
  put('de', lab('de'));
  const aliases = [];
  for (const l of WD_LANGS) for (const a of e?.aliases?.[l] || []) aliases.push(a.value);
  return { names, aliases };
}

async function main() {
  let q = db.collection('attractions');
  if (country) q = q.where('countryIso2', '==', country);
  const snap = await q.select('wikidataQid', 'name', 'officialName', 'countryIso2', 'greengoScore', 'names').get();
  const todo = snap.docs.filter((d) => /^Q\d+$/.test(d.get('wikidataQid') || '') && (force || !d.get('names')))
    .slice(0, limit === Infinity ? undefined : limit);
  console.log(`attractions: ${snap.size}, to do: ${todo.length}${dryRun ? ' (dry run)' : ''}`);

  let done = 0, indexed = 0;
  for (let i = 0; i < todo.length; i += 50) {
    const chunk = todo.slice(i, i + 50);
    const ent = await wdEntities(chunk.map((d) => d.get('wikidataQid')));
    let batch = db.batch(), ops = 0;
    for (const d of chunk) {
      const { names, aliases } = namesFrom(ent[d.get('wikidataQid')]);
      const id = d.id;
      const iso2 = d.get('countryIso2') || '';
      const score = d.get('greengoScore') || 0;
      const keys = new Set([d.get('name'), d.get('officialName'), ...Object.values(names), ...aliases]
        .map(norm).filter((n) => n.length >= 3));
      if (dryRun) {
        if (done < 5) console.log(id, d.get('name'), JSON.stringify(names), [...keys].slice(0, 8));
      } else {
        batch.update(d.ref, { names });
        ops++;
        for (const n of keys) {
          const key = `${n}~${id}`.replace(/\//g, '_').slice(0, 1400);
          batch.set(db.collection(INDEX).doc(key), { n, id: Number(id), iso2, score });
          ops++;
          indexed++;
          if (ops >= 450) { await batch.commit(); batch = db.batch(); ops = 0; }
        }
      }
      done++;
    }
    if (!dryRun && ops) await batch.commit();
    if ((i / 50) % 20 === 0) console.log(`  ${done}/${todo.length} (index docs ${indexed})`);
    await new Promise((r) => setTimeout(r, 150));
  }
  console.log(`DONE: ${done} attractions, ${indexed} name-index docs`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
