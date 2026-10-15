#!/usr/bin/env node
/**
 * Every attraction text the app shows, stored in all 7 app languages
 * (en, it, es, pt, pt_BR, fr, de), so the app reads it from Firestore and a
 * language switch is instant. No runtime translation.
 *
 * The catalogue prose (descriptions, history, highlights, facts, alt text) is
 * GENERATED from ~3k English sentence templates, so it is translated as
 * templates with placeholders and rendered per attraction; the short fixed
 * fields (opening hours, season, ...) go through a dictionary; curiosities and
 * the missing "What is it?" languages are translated one by one (Claude
 * Sonnet, Message Batches API - see translate_batch.py).
 *
 * Steps (outputs in tools/attractions_i18n/build/, gitignored):
 *   node build_i18n.js --step export      # attractions -> source.jsonl
 *   node build_i18n.js --step extract     # templates.json, dict.json, entities.json, report
 *   node build_i18n.js --step jobs        # agent job files for templates/dict/entities
 *   node build_i18n.js --step render      # i18n.jsonl (+ checks)
 *   node build_i18n.js --step write       # attractions.i18n / about gaps
 * Needs GOOGLE_APPLICATION_CREDENTIALS for export/write.
 */
const fs = require('fs');
const path = require('path');
const readline = require('readline');

const OUT = path.join(__dirname, 'build');
fs.mkdirSync(OUT, { recursive: true });
const TARGETS = ['it', 'es', 'pt', 'pt_BR', 'fr', 'de'];

const arg = (n, d) => {
  const i = process.argv.indexOf(n);
  return i > 0 ? process.argv[i + 1] : d;
};
const step = arg('--step');

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

/** Prose fields rendered from templates (string or list of strings). */
const PROSE = ['descriptionShort', 'descriptionMedium', 'descriptionLong', 'historySummary',
  'topHighlights', 'interestingFacts', 'altText'];
/** Short fixed-vocabulary fields: one dictionary entry per distinct value. */
const DICT = ['openingHours', 'visitDuration', 'bestSeason', 'bestTimeOfDay', 'photographyTips',
  'wheelchairAccessible', 'indoorOutdoor', 'petFriendly', 'safetyLevel', 'annualVisitors'];
const EXPORT = ['id', 'name', 'cityName', 'citySlug', 'stateProvince', 'region', 'countryName',
  'countryIso2', 'status', 'names', 'about', 'aboutSources', 'curiosities', ...PROSE, ...DICT];

async function* rows() {
  const rl = readline.createInterface({ input: fs.createReadStream(path.join(OUT, 'source.jsonl')) });
  for await (const l of rl) if (l.trim()) yield JSON.parse(l);
}

async function stepExport() {
  const db = admin().firestore();
  const out = fs.createWriteStream(path.join(OUT, 'source.jsonl'));
  let last = null;
  let n = 0;
  for (;;) {
    let q = db.collection('attractions').orderBy('__name__').select(...EXPORT).limit(2000);
    if (last) q = q.startAfter(last);
    const s = await q.get();
    if (s.empty) break;
    for (const d of s.docs) {
      out.write(JSON.stringify({ _doc: d.id, ...d.data() }) + '\n');
      n++;
    }
    last = s.docs[s.docs.length - 1];
    process.stdout.write(`\rexported ${n}`);
  }
  await new Promise((r) => out.end(r));
  console.log(`\nEXPORT DONE ${n}`);
}

// ---------------------------------------------------------------- templates

// Sentence end, but not after "St." / "Mt." / an initial ("J. S. Bach").
const SPLIT = /(?<=[.!?])(?<!\b(?:St|Ste|Sta|Sto|Mt|Ft|Dr|Sr|Jr|No|Nr|Mr|Mrs|Rev|Gen|Fr|Ss|SS|[A-Z])\.)\s+(?=[A-Z{"'(])/;
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/** Placeholders, longest value first so "Paris" inside a name is not cut. */
function entities(r) {
  const e = [
    ['{N}', r.name],
    ['{C}', r.cityName],
    ['{S}', r.stateProvince],
    ['{K}', r.countryName],
  ].filter(([, v]) => typeof v === 'string' && v.trim().length > 1);
  return e.sort((a, b) => b[1].length - a[1].length);
}

function templatize(text, ents) {
  let t = text;
  for (const [ph, v] of ents) t = t.replace(new RegExp(`(?<![\\p{L}\\p{N}])${esc(v)}(?![\\p{L}\\p{N}])`, 'gu'), ph);
  return t;
}

/** A prose value -> list of units (list fields: one unit list per item). */
function units(v) {
  if (Array.isArray(v)) return v.map((x) => String(x));
  return typeof v === 'string' && v.trim() ? [v] : [];
}

async function stepExtract() {
  const tpl = new Map(); // template -> count
  const dict = new Map(); // value -> {fields:Set, count}
  const cities = new Map(); // `${iso}|${city}` -> {country, state, count}
  const states = new Map();
  const countries = new Map();
  let n = 0;
  let sentences = 0;
  for await (const r of rows()) {
    n++;
    const ents = entities(r);
    for (const f of PROSE) {
      for (const u of units(r[f])) {
        for (const s of templatize(u, ents).split(SPLIT)) {
          const k = s.trim();
          if (!k) continue;
          sentences++;
          tpl.set(k, (tpl.get(k) || 0) + 1);
        }
      }
    }
    for (const f of DICT) {
      const v = typeof r[f] === 'string' ? r[f].trim() : '';
      if (!v) continue;
      const d = dict.get(v) || { fields: new Set(), count: 0 };
      d.fields.add(f);
      d.count++;
      dict.set(v, d);
    }
    const iso = r.countryIso2 || '';
    if (r.cityName) {
      const k = `${iso}|${r.cityName}`;
      const c = cities.get(k) || { iso, city: r.cityName, state: r.stateProvince || '', country: r.countryName || '', count: 0 };
      c.count++;
      cities.set(k, c);
    }
    if (r.stateProvince) {
      const k = `${iso}|${r.stateProvince}`;
      const c = states.get(k) || { iso, state: r.stateProvince, country: r.countryName || '', count: 0 };
      c.count++;
      states.set(k, c);
    }
    if (r.countryName) countries.set(iso, r.countryName);
  }
  // A template keeps the id it had in the last extract (build/tr is keyed by
  // id), so after a reseed only the new texts get new ids and need translating.
  const tplPath = path.join(OUT, 'templates.json');
  const oldId = new Map(fs.existsSync(tplPath)
    ? JSON.parse(fs.readFileSync(tplPath, 'utf8')).map((t) => [t.text, t.id]) : []);
  let next = 1 + Math.max(-1, ...[...oldId.values()].map((id) => Number(id.slice(1))));
  const tplList = [...tpl.entries()].sort((a, b) => b[1] - a[1])
    .map(([text, count]) => ({ id: oldId.get(text) || `t${next++}`, text, count }));
  fs.writeFileSync(path.join(OUT, 'templates.json'), JSON.stringify(tplList, null, 1));
  fs.writeFileSync(path.join(OUT, 'dict.json'), JSON.stringify([...dict.entries()]
    .map(([text, d], i) => ({ id: `d${i}`, text, fields: [...d.fields], count: d.count })), null, 1));
  fs.writeFileSync(path.join(OUT, 'entities.json'), JSON.stringify({
    countries: Object.fromEntries([...countries.entries()].sort()),
    states: [...states.values()].sort((a, b) => b.count - a.count),
    cities: [...cities.values()].sort((a, b) => b.count - a.count),
  }, null, 1));
  const once = tplList.filter((t) => t.count === 1);
  console.log(`attractions ${n}, sentences ${sentences}, templates ${tplList.length} ` +
    `(${tplList.reduce((s, t) => s + t.text.length, 0)} chars), used once ${once.length}, ` +
    `dict ${dict.size}, states ${states.size}, cities ${cities.size}, countries ${countries.size}`);
  console.log('used-once sample:', once.slice(0, 8).map((t) => t.text));
}

// --------------------------------------------------------------------- jobs

const ABOUT_SRC = ['en', 'de', 'fr', 'es', 'it', 'pt', 'pt_BR'];

/**
 * Attractions whose "What is it?" text is a Wikipedia article about another
 * place or a generic topic (about_wrong_article.tsv: id<TAB>name<TAB>why).
 * They are never translated, and `write` deletes their about fields.
 */
function wrongAbout() {
  const p = path.join(__dirname, 'about_wrong_article.tsv');
  if (!fs.existsSync(p)) return new Set();
  return new Set(fs.readFileSync(p, 'utf8').split('\n').map((l) => l.split('\t')[0].trim()).filter((x) => /^\d+$/.test(x)));
}
const ALL = ['en', ...TARGETS];

/** "What is it?" source: English, else the first language that has one. */
function aboutSource(about) {
  if (!about || typeof about !== 'object') return null;
  for (const l of ABOUT_SRC) if (typeof about[l] === 'string' && about[l].trim()) return l;
  return null;
}

/**
 * Translation items, one JSONL file per kind, read by translate_batch.py:
 *   {id, text, targets[], ctx?}                 kinds tpl, dict, city, cur, about
 *   {id, text, ctx}                             kinds country, state (name + "in" + "of" forms)
 */
async function stepJobs() {
  const dir = path.join(OUT, 'jobs');
  fs.mkdirSync(dir, { recursive: true });
  const w = (kind, items) => {
    fs.writeFileSync(path.join(dir, `${kind}.jsonl`), items.map((x) => JSON.stringify(x)).join('\n') + '\n');
    console.log(`${kind}: ${items.length} items, ${items.reduce((s, x) => s + x.text.length, 0)} chars`);
  };
  const tpl = JSON.parse(fs.readFileSync(path.join(OUT, 'templates.json'), 'utf8'));
  w('tpl', tpl.map((t) => ({ id: t.id, text: t.text, targets: TARGETS })));
  const dict = JSON.parse(fs.readFileSync(path.join(OUT, 'dict.json'), 'utf8'));
  w('dict', dict.map((d) => ({ id: d.id, text: d.text, targets: TARGETS, ctx: `field: ${d.fields.join(', ')}` })));
  const ent = JSON.parse(fs.readFileSync(path.join(OUT, 'entities.json'), 'utf8'));
  w('country', Object.entries(ent.countries).map(([iso, name]) => ({ id: iso, text: name, ctx: `country ${iso}` })));
  w('state', ent.states.map((s) => ({ id: `${s.iso}|${s.state}`, text: s.state, ctx: `region of ${s.country}` })));
  w('city', ent.cities.map((c) => ({
    id: `${c.iso}|${c.city}`, text: c.city, targets: TARGETS, ctx: [c.state, c.country].filter(Boolean).join(', '),
  })));
  const cur = [];
  const about = [];
  const wrong = wrongAbout();
  for await (const r of rows()) {
    const where = `${r.name} (${r.cityName}, ${r.countryName})`;
    (Array.isArray(r.curiosities) ? r.curiosities : []).forEach((c, k) => {
      if (typeof c === 'string' && c.trim()) cur.push({ id: `${r._doc}#${k}`, text: c, targets: TARGETS, ctx: where });
    });
    const src = wrong.has(r._doc) ? null : aboutSource(r.about);
    if (src) {
      const missing = ALL.filter((l) => !(typeof r.about[l] === 'string' && r.about[l].trim()));
      if (missing.length) about.push({ id: r._doc, text: r.about[src], src, targets: missing, ctx: where });
    }
  }
  w('cur', cur);
  w('about', about);
}

// ------------------------------------------------------------------- render

/** id -> translations of one kind (build/tr/<kind>.jsonl from translate_batch.py). */
function loadTr(kind) {
  const p = path.join(OUT, 'tr', `${kind}.jsonl`);
  const m = new Map();
  if (!fs.existsSync(p)) return m;
  for (const l of fs.readFileSync(p, 'utf8').split('\n')) {
    if (!l.trim()) continue;
    const x = JSON.parse(l);
    m.set(x.id, x.tr);
  }
  return m;
}

const crypto = require('crypto');
/** Hash of the English texts an i18n entry was made from (stale check after a reseed). */
function srcHash(r) {
  const h = crypto.createHash('sha256');
  for (const f of [...PROSE, ...DICT, 'curiosities', 'cityName', 'name', 'stateProvince', 'countryName']) {
    h.update(JSON.stringify(r[f] ?? null));
  }
  return h.digest('hex').slice(0, 16);
}

/**
 * Per attraction and language: every PROSE / DICT field, curiosities, the
 * localised city and the list template (`shortTemplate`, {N}/{C} kept), plus
 * the missing "What is it?" languages. A field is left out when any of its
 * sentences has no translation, so the app shows that field in English rather
 * than a half-translated text.
 */
async function stepRender() {
  const tplId = new Map(JSON.parse(fs.readFileSync(path.join(OUT, 'templates.json'), 'utf8')).map((t) => [t.text, t.id]));
  const dictId = new Map(JSON.parse(fs.readFileSync(path.join(OUT, 'dict.json'), 'utf8')).map((d) => [d.text, d.id]));
  const tr = Object.fromEntries(['tpl', 'dict', 'country', 'state', 'city', 'cur', 'about'].map((k) => [k, loadTr(k)]));
  const out = fs.createWriteStream(path.join(OUT, 'i18n.jsonl'));
  const stats = {};
  const bump = (k) => { stats[k] = (stats[k] || 0) + 1; };
  const problems = [];
  let n = 0;
  let maxBytes = 0;
  const wrong = wrongAbout();

  for await (const r of rows()) {
    n++;
    const ents = entities(r);
    const country = tr.country.get(r.countryIso2 || '') || {};
    const state = tr.state.get(`${r.countryIso2 || ''}|${r.stateProvince}`) || {};
    const city = tr.city.get(`${r.countryIso2 || ''}|${r.cityName}`) || {};
    const i18n = {};
    for (const lang of TARGETS) {
      const K = country[lang] || { name: r.countryName, in: `in ${r.countryName}`, of: `of ${r.countryName}` };
      const S = state[lang] || { name: r.stateProvince, in: `in ${r.stateProvince}`, of: `of ${r.stateProvince}` };
      // Title case like the app's nameFor: Wikidata labels can be lower case ("torre Eiffel").
      const N = ((n) => n.charAt(0).toUpperCase() + n.slice(1))((r.names && r.names[lang]) || r.name);
      const C = city[lang] || r.cityName;
      const place = (t) => t
        .replace(/\{in_K\}/g, K.in).replace(/\{of_K\}/g, K.of).replace(/\{K\}/g, K.name)
        .replace(/\{in_S\}/g, S.in).replace(/\{of_S\}/g, S.of).replace(/\{S\}/g, S.name);
      const fill = (t) => place(t).replace(/\{C\}/g, C).replace(/\{N\}/g, N);
      // One prose unit -> translated template text, or null if any sentence is missing.
      const unitTpl = (u) => {
        const parts = [];
        for (const s of templatize(u, ents).split(SPLIT)) {
          const k = s.trim();
          if (!k) continue;
          const t = tr.tpl.get(tplId.get(k))?.[lang];
          if (!t) return null;
          parts.push(t);
        }
        return parts.join(' ');
      };
      const t = {};
      for (const f of PROSE) {
        const us = units(r[f]);
        if (!us.length) continue;
        const done = us.map(unitTpl);
        if (done.some((x) => x == null)) { bump(`miss:${f}:${lang}`); continue; }
        t[f] = Array.isArray(r[f]) ? done.map(fill) : fill(done[0]);
        if (f === 'descriptionShort') t.shortTemplate = place(done[0]);
      }
      for (const f of DICT) {
        const v = typeof r[f] === 'string' ? r[f].trim() : '';
        if (!v) continue;
        const x = tr.dict.get(dictId.get(v))?.[lang];
        if (x) t[f] = x; else bump(`miss:${f}:${lang}`);
      }
      const cur = Array.isArray(r.curiosities) ? r.curiosities : [];
      if (cur.length) {
        const c = cur.map((_, k) => tr.cur.get(`${r._doc}#${k}`)?.[lang]);
        if (c.every(Boolean)) t.curiosities = c; else bump(`miss:curiosities:${lang}`);
      }
      if (city[lang] && city[lang] !== r.cityName) t.cityName = city[lang];
      for (const [k, v] of Object.entries(t)) {
        const left = (Array.isArray(v) ? v.join(' ') : v).match(/\{[A-Za-z_]+\}/);
        if (left && k !== 'shortTemplate') problems.push(`${r._doc} ${lang} ${k}: ${left[0]}`);
      }
      i18n[lang] = t;
    }

    // "What is it?": fill the languages Wikipedia lacks.
    const aboutTr = tr.about.get(r._doc);
    const src = aboutSource(r.about);
    const about = {};
    const aboutTranslated = {};
    const aboutSources = {};
    const clearAbout = wrong.has(r._doc);
    if (clearAbout) bump('about:cleared');
    else if (aboutTr && src) {
      for (const [lang, text] of Object.entries(aboutTr)) {
        if (!text || (r.about && r.about[lang])) continue;
        about[lang] = text;
        aboutTranslated[lang] = src;
        if (r.aboutSources && r.aboutSources[src]) aboutSources[lang] = r.aboutSources[src];
        bump(`about:${lang}`);
      }
    }
    const rec = { doc: r._doc, src: srcHash(r), i18n, about, aboutTranslated, aboutSources };
    if (clearAbout) rec.clearAbout = true;
    const line = JSON.stringify(rec);
    maxBytes = Math.max(maxBytes, line.length);
    out.write(line + '\n');
  }
  await new Promise((res) => out.end(res));
  fs.writeFileSync(path.join(OUT, 'render_problems.txt'), problems.join('\n'));
  console.log(`rendered ${n}; largest i18n record ${maxBytes} bytes; problems ${problems.length}`);
  console.log(Object.entries(stats).sort().map(([k, v]) => `${k}=${v}`).join('\n'));
}

// -------------------------------------------------------------------- write

/**
 * attractions/{id}: i18n (whole map, replaced), i18nSrc, i18nAt, and the
 * missing about.{lang} / aboutTranslated.{lang} / aboutSources.{lang} as field
 * paths (existing Wikipedia languages are never touched; all of them are
 * deleted for the ids in about_wrong_article.tsv). source.jsonl is the
 * backup of every field this overwrites.
 *   --limit N   only the first N records (try-out)
 *   --doc ID    only that attraction
 */
async function stepWrite() {
  const a = admin();
  const db = a.firestore();
  const limit = Number(arg('--limit', 0)) || 0;
  const only = arg('--doc');
  const bw = db.bulkWriter();
  let failed = 0;
  bw.onWriteError((e) => {
    if (e.failedAttempts < 5) return true;
    failed++;
    console.error(`\nFAILED ${e.documentRef.id}: ${e.message}`);
    return false;
  });
  const rl = readline.createInterface({ input: fs.createReadStream(path.join(OUT, 'i18n.jsonl')) });
  let n = 0;
  for await (const l of rl) {
    if (!l.trim()) continue;
    const x = JSON.parse(l);
    if (only && x.doc !== only) continue;
    const upd = {
      i18n: x.i18n,
      i18nSrc: x.src,
      i18nAt: a.firestore.FieldValue.serverTimestamp(),
    };
    if (x.clearAbout) {
      for (const f of ['about', 'aboutTranslated', 'aboutSources']) upd[f] = a.firestore.FieldValue.delete();
    }
    for (const [lang, v] of Object.entries(x.about)) upd[`about.${lang}`] = v;
    for (const [lang, v] of Object.entries(x.aboutTranslated)) upd[`aboutTranslated.${lang}`] = v;
    for (const [lang, v] of Object.entries(x.aboutSources)) upd[`aboutSources.${lang}`] = v;
    bw.update(db.collection('attractions').doc(x.doc), upd);
    n++;
    if (n % 2000 === 0) process.stdout.write(`\rqueued ${n}`);
    if (limit && n >= limit) break;
  }
  await bw.close();
  console.log(`\nWRITE DONE ${n} docs, failed ${failed}`);
}

const steps = { export: stepExport, extract: stepExtract, jobs: stepJobs, render: stepRender, write: stepWrite };
if (!steps[step]) {
  console.error(`--step one of: ${Object.keys(steps).join(', ')}`);
  process.exit(1);
}
steps[step]().then(() => process.exit(0), (e) => { console.error(e); process.exit(1); });
