#!/usr/bin/env node
/**
 * "What is it?" text for every attraction, in the 7 app languages, from the
 * lead section of its Wikipedia article (via attractions.wikidataQid ->
 * Wikidata sitelinks). Wikipedia text is CC BY-SA 4.0: the app shows the
 * source link under the text (attractions.aboutSources).
 *
 * Steps (each resumable; outputs in tools/attractions_about/build/, gitignored):
 *   node build_about.js --project greengo-chat --step list       # attractions -> list.json
 *   node build_about.js --step sitelinks                         # Wikidata -> sitelinks.json
 *   node build_about.js --step titles                            # name lookup for bad/missing items -> fallback.json
 *   node build_about.js --step extracts                          # Wikipedia -> extracts.jsonl
 *   node build_about.js --step report                            # coverage per language
 *   node build_about.js --project greengo-chat --step write      # attractions.about / aboutSources
 *   --sample N  only the first N attractions of list.json (try-out)
 *
 * Firestore fields written:
 *   about:        { en, it, es, pt, pt_BR, fr, de }   3-4 sentences (max ~650 chars)
 *   aboutSources: { en: 'https://en.wikipedia.org/wiki/...', ... }
 *   aboutAt:      server timestamp
 */
const fs = require('fs');
const path = require('path');
const https = require('https');

const OUT = path.join(__dirname, 'build');
fs.mkdirSync(OUT, { recursive: true });
const WIKIS = ['en', 'it', 'es', 'pt', 'fr', 'de'];
const LANGS = [...WIKIS, 'pt_BR'];
const UA = 'GreenGoAttractionsBot/1.0 (https://greengochat.com; support@greengochat.com)';

const arg = (n, d) => {
  const i = process.argv.indexOf(n);
  return i > 0 ? process.argv[i + 1] : d;
};
const step = arg('--step');
const sample = Number(arg('--sample', 0)) || 0;

function get(url, tries = 6) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': UA, 'Accept-Encoding': 'identity' } }, (res) => {
      let b = '';
      res.setEncoding('utf8');
      res.on('data', (c) => (b += c));
      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            return resolve(JSON.parse(b));
          } catch (_) { /* retry */ }
        }
        if (tries <= 1) return reject(new Error(`HTTP ${res.statusCode} ${url.slice(0, 120)}`));
        const wait = res.statusCode === 429 ? 10000 : 1500 * (7 - tries);
        setTimeout(() => get(url, tries - 1).then(resolve, reject), wait);
      });
    }).on('error', (e) => {
      if (tries <= 1) return reject(e);
      setTimeout(() => get(url, tries - 1).then(resolve, reject), 2000);
    });
  });
}

async function pool(items, n, fn) {
  let i = 0;
  await Promise.all(Array.from({ length: n }, async () => {
    while (i < items.length) {
      const k = i++;
      await fn(items[k], k);
    }
  }));
}

function admin() {
  let a;
  try {
    a = require(path.join(__dirname, '../../functions/node_modules/firebase-admin'));
  } catch (_) {
    a = require('firebase-admin');
  }
  if (!a.apps.length) a.initializeApp({ projectId: arg('--project', 'greengo-chat') });
  return a;
}

function loadList() {
  const l = JSON.parse(fs.readFileSync(path.join(OUT, 'list.json'), 'utf8'));
  return sample ? l.slice(0, sample) : l;
}

// ---- text clean-up --------------------------------------------------------
function clean(text) {
  if (!text) return null;
  // First paragraph(s) with real content.
  let t = text.split('\n').map((s) => s.trim()).filter((s) => s.length > 40).slice(0, 2).join(' ');
  // Drop parentheticals (pronunciations, native names, translations).
  for (let k = 0; k < 3; k++) t = t.replace(/\s*[(（][^()（）]*[)）]/g, '');
  t = t.replace(/\s*\[[^\]]*\]/g, '').replace(/\s+([,.;:])/g, '$1').replace(/\s{2,}/g, ' ').trim();
  if (t.length < 60) return null;
  // 3-4 sentences, max ~650 chars, cut at a sentence end (never drops text).
  const parts = t.split(/(?<=[.!?])\s+(?=[A-ZÀ-Þ0-9"«“¿¡])/);
  let out = '';
  let n = 0;
  for (const p of parts) {
    const s = p.trim();
    if (!s) continue;
    if (n >= 3 && out.length > 220) break;
    if (out && (out + ' ' + s).length > 650) break;
    out = out ? `${out} ${s}` : s;
    n++;
    if (n >= 4) break;
  }
  if (out.length > 700) out = out.slice(0, out.lastIndexOf(' ', 680)) + '…';
  return out.length >= 60 ? out : null;
}

// ---- steps ------------------------------------------------------------------
async function stepList() {
  const db = admin().firestore();
  const snap = await db.collection('attractions').where('status', '==', 'published')
    .select('wikidataQid', 'name', 'greengoScore').get();
  const list = snap.docs
    .map((d) => ({ id: d.id, q: d.get('wikidataQid') || null, n: d.get('name'), s: d.get('greengoScore') || 0 }))
    .sort((a, b) => b.s - a.s);
  fs.writeFileSync(path.join(OUT, 'list.json'), JSON.stringify(list));
  console.log(`list: ${list.length} attractions, ${list.filter((x) => x.q).length} with a Wikidata id`);
}

async function stepSitelinks() {
  const file = path.join(OUT, 'sitelinks.json');
  const have = fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')) : {};
  const qids = [...new Set(loadList().map((x) => x.q).filter((q) => q && !(q in have)))];
  const batches = [];
  for (let i = 0; i < qids.length; i += 50) batches.push(qids.slice(i, i + 50));
  let done = 0;
  await pool(batches, 4, async (b) => {
    const sites = WIKIS.map((w) => w + 'wiki').join('|');
    const url = `https://www.wikidata.org/w/api.php?action=wbgetentities&format=json&props=sitelinks&sitefilter=${sites}&ids=${b.join('|')}`;
    const r = await get(url);
    for (const q of b) {
      const e = r.entities && r.entities[q];
      const sl = {};
      if (e && e.sitelinks) for (const w of WIKIS) if (e.sitelinks[w + 'wiki']) sl[w] = e.sitelinks[w + 'wiki'].title;
      have[q] = sl;
    }
    if (++done % 50 === 0) {
      fs.writeFileSync(file, JSON.stringify(have));
      console.log(`  sitelinks ${done}/${batches.length}`);
    }
  });
  fs.writeFileSync(file, JSON.stringify(have));
  console.log(`sitelinks: ${Object.keys(have).length} entities`);
}

async function stepExtracts() {
  const sl = JSON.parse(fs.readFileSync(path.join(OUT, 'sitelinks.json'), 'utf8'));
  const file = path.join(OUT, 'extracts.jsonl');
  const done = new Set();
  if (fs.existsSync(file)) {
    for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
      if (!line) continue;
      try {
        const o = JSON.parse(line);
        done.add(`${o.w}|${o.t}`);
      } catch (_) { /* partial last line */ }
    }
  }
  const out = fs.createWriteStream(file, { flags: 'a' });
  const fb = loadFallback();
  const all = loadList().map((a) => linksFor(a, sl, fb));
  for (const w of WIKIS) {
    const titles = [...new Set(all.map((l) => l[w]).filter((t) => t && !done.has(`${w}|${t}`)))];
    const batches = [];
    for (let i = 0; i < titles.length; i += 20) batches.push(titles.slice(i, i + 20));
    let n = 0;
    await pool(batches, 4, async (b) => {
      const url = `https://${w}.wikipedia.org/w/api.php?action=query&format=json&formatversion=2&prop=extracts&exintro=1&explaintext=1&exlimit=20&redirects=1&titles=${encodeURIComponent(b.join('|'))}`;
      let r;
      try {
        r = await get(url);
      } catch (e) {
        console.log(`  skip batch (${e.message})`);
        return;
      }
      const back = {};
      for (const x of (r.query && r.query.normalized) || []) back[x.to] = x.from;
      for (const x of (r.query && r.query.redirects) || []) back[x.to] = back[x.from] || x.from;
      for (const p of (r.query && r.query.pages) || []) {
        const t = back[p.title] || p.title;
        out.write(JSON.stringify({ w, t, x: p.extract || '' }) + '\n');
      }
      if (++n % 200 === 0) console.log(`  ${w} ${n}/${batches.length}`);
    });
    console.log(`extracts ${w}: ${titles.length} titles`);
  }
  await new Promise((r) => out.end(r));
}

const STOP = new Set(['the', 'of', 'and', 'del', 'della', 'des', 'der', 'die', 'das', 'les', 'los', 'las', 'de', 'la', 'le', 'el', 'do', 'da', 'dos', 'das', 'di']);
const fold = (s) => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
const words = (s) => fold(s).split(/[^a-z0-9]+/).filter((w) => w.length >= 3 && !STOP.has(w));

const baseName = (n) => (n || '').replace(/\s*\([^)]*\)/g, '').trim();

// The article must be the attraction itself (catches catalogue rows linked
// to the wrong Wikidata item, e.g. "2015 Mecca crane collapse" for Masjid
// al-Haram): one of its titles holds at least half of the words of the
// attraction's name and not many more words than it.
const GENERIC = new Set(['old', 'town', 'historic', 'historical', 'city', 'centre', 'center', 'district', 'quarter',
  'site', 'area', 'memorial', 'open', 'air', 'complex', 'village', 'downtown']);
function sameThing(name, links) {
  const all = words(baseName(name));
  const nw = all.filter((w) => !GENERIC.has(w)).length ? all.filter((w) => !GENERIC.has(w)) : all;
  if (!nw.length) return Object.keys(links).length > 0;
  const match = (w, t) => t === w || (t.length >= 5 && w.length >= 5 && (t.startsWith(w) || w.startsWith(t)));
  return Object.values(links).some((title) => {
    const tw = words(title).filter((w) => !GENERIC.has(w));
    const hit = nw.filter((w) => tw.some((t) => match(w, t))).length;
    return hit >= Math.ceil(nw.length / 2) && tw.length <= nw.length + 3;
  });
}

function loadFallback() {
  const f = path.join(OUT, 'fallback.json');
  return fs.existsSync(f) ? JSON.parse(fs.readFileSync(f, 'utf8')) : {};
}

// Attractions whose Wikidata item fails sameThing (or has no articles): look
// the English article up by the attraction's name, then its language links.
async function stepTitles() {
  const sl = JSON.parse(fs.readFileSync(path.join(OUT, 'sitelinks.json'), 'utf8'));
  const file = path.join(OUT, 'fallback.json');
  const have = loadFallback();
  const todo = loadList().filter((a) => !(a.id in have) && !sameThing(a.n, (a.q && sl[a.q]) || {}));
  const batches = [];
  for (let i = 0; i < todo.length; i += 40) batches.push(todo.slice(i, i + 40));
  let n = 0;
  await pool(batches, 3, async (b) => {
    const names = [...new Set(b.map((a) => baseName(a.n)).filter(Boolean))];
    const url = `https://en.wikipedia.org/w/api.php?action=query&format=json&formatversion=2&redirects=1&prop=pageprops&ppprop=disambiguation|wikibase_item&titles=${encodeURIComponent(names.join('|'))}`;
    let r;
    try {
      r = await get(url);
    } catch (e) {
      console.log(`  skip batch (${e.message})`);
      return;
    }
    const back = {};
    for (const x of (r.query && r.query.normalized) || []) back[x.to] = x.from;
    for (const x of (r.query && r.query.redirects) || []) back[x.to] = back[x.from] || x.from;
    const byName = {};
    const qOf = {};
    for (const p of (r.query && r.query.pages) || []) {
      if (p.missing || p.invalid || !p.pageprops || 'disambiguation' in p.pageprops) continue;
      byName[back[p.title] || p.title] = { en: p.title };
      if (p.pageprops.wikibase_item) qOf[back[p.title] || p.title] = p.pageprops.wikibase_item;
    }
    // The other languages: the article's own Wikidata item's sitelinks.
    const qs = [...new Set(Object.values(qOf))];
    for (let i = 0; i < qs.length; i += 50) {
      const sites = WIKIS.map((w) => w + 'wiki').join('|');
      try {
        const e = await get(`https://www.wikidata.org/w/api.php?action=wbgetentities&format=json&props=sitelinks&sitefilter=${sites}&ids=${qs.slice(i, i + 50).join('|')}`);
        for (const [nm, q] of Object.entries(qOf)) {
          const ent = e.entities && e.entities[q];
          if (!ent || !ent.sitelinks) continue;
          for (const w of WIKIS) if (ent.sitelinks[w + 'wiki']) byName[nm][w] = ent.sitelinks[w + 'wiki'].title;
        }
      } catch (_) { /* English only */ }
    }
    for (const a of b) {
      const links = byName[baseName(a.n)] || {};
      have[a.id] = sameThing(a.n, links) ? links : {};
    }
    if (++n % 25 === 0) {
      fs.writeFileSync(file, JSON.stringify(have));
      console.log(`  titles ${n}/${batches.length}`);
    }
  });
  fs.writeFileSync(file, JSON.stringify(have));
  console.log(`titles: ${todo.length} looked up, ${Object.values(have).filter((l) => Object.keys(l).length).length} found`);
}

function linksFor(a, sl, fb) {
  const own = (a.q && sl[a.q]) || {};
  if (sameThing(a.n, own)) return own;
  return fb[a.id] || {};
}

const rejected = [];
function buildAbout() {
  const sl = JSON.parse(fs.readFileSync(path.join(OUT, 'sitelinks.json'), 'utf8'));
  const ex = {};
  for (const line of fs.readFileSync(path.join(OUT, 'extracts.jsonl'), 'utf8').split('\n')) {
    if (!line) continue;
    try {
      const o = JSON.parse(line);
      ex[`${o.w}|${o.t}`] = o.x;
    } catch (_) { /* partial line */ }
  }
  const fb = loadFallback();
  const res = [];
  rejected.length = 0;
  for (const a of loadList()) {
    const links = linksFor(a, sl, fb);
    if (!Object.keys(links).length) rejected.push(`${a.n} -> ${Object.values((a.q && sl[a.q]) || {})[0] || '?'}`);
    const about = {};
    const src = {};
    for (const w of WIKIS) {
      const t = links[w];
      if (!t) continue;
      const c = clean(ex[`${w}|${t}`]);
      if (!c) continue;
      about[w] = c;
      src[w] = `https://${w}.wikipedia.org/wiki/${encodeURIComponent(t.replace(/ /g, '_'))}`;
    }
    if (about.pt) {
      about.pt_BR = about.pt;
      src.pt_BR = src.pt;
    }
    res.push({ id: a.id, n: a.n, s: a.s, about, src });
  }
  return res;
}

function stepReport() {
  const res = buildAbout();
  console.log(`attractions: ${res.length}`);
  for (const l of LANGS) console.log(`  ${l}: ${res.filter((r) => r.about[l]).length}`);
  console.log(`  any: ${res.filter((r) => Object.keys(r.about).length).length}`);
  console.log(`  all 7: ${res.filter((r) => LANGS.every((l) => r.about[l])).length}`);
  const bands = [[95, 101], [85, 95], [70, 85], [0, 70]];
  for (const [lo, hi] of bands) {
    const b = res.filter((r) => r.s >= lo && r.s < hi);
    console.log(`  score ${lo}-${hi}: ${b.length} | en ${b.filter((r) => r.about.en).length} | all7 ${b.filter((r) => LANGS.every((l) => r.about[l])).length}`);
  }
  console.log(`  no article (after name lookup): ${rejected.length}`);
  for (const x of rejected.slice(0, 15)) console.log(`    ${x}`);
  for (const r of res.slice(0, 2)) console.log('\n', r.n, JSON.stringify(r.about, null, 1));
}

async function stepWrite() {
  const a = admin();
  const db = a.firestore();
  const res = buildAbout().filter((r) => Object.keys(r.about).length);
  const w = db.bulkWriter();
  let n = 0;
  for (const r of res) {
    w.update(db.collection('attractions').doc(r.id), {
      about: r.about, aboutSources: r.src, aboutAt: a.firestore.FieldValue.serverTimestamp(),
    });
    if (++n % 5000 === 0) console.log(`  queued ${n}`);
  }
  await w.close();
  console.log(`wrote about for ${n} attractions`);
}

const steps = { list: stepList, sitelinks: stepSitelinks, titles: stepTitles, extracts: stepExtracts, report: stepReport, write: stepWrite };
if (!steps[step]) {
  console.error('--step list|sitelinks|extracts|report|write');
  process.exit(1);
}
Promise.resolve(steps[step]()).catch((e) => {
  console.error(e);
  process.exit(1);
});
