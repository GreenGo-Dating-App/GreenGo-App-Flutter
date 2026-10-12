#!/usr/bin/env node
/**
 * Validate + merge the chat datasets (tools/chat_datasets/parts/*) into the
 * versioned files the app downloads once (lib/core/services/chat_datasets/).
 *
 * Output: tools/chat_datasets/build/
 *   quotes.json       [{id, a, d, o, t:{lang:text}}]        phrase of the day
 *   icebreakers.json  [{id, p, t}]                          p = topic
 *   sentences.json    [{id, p, l, t}]                       l = CEFR level
 *   tips.json         {ISO2: [{id, c, t}]}                  c = category
 *   freq.json         {lang: [word, ...]} top --freq-top    difficulty badge
 *   keywords.json     (from build_keywords.js, copied as is)
 *   manifest.json     {v, files: {name: {path, bytes, sha256}}}
 * Each data file is also written gzipped (<name>.json.gz) for upload.
 *
 * Checks (an item failing one is DROPPED and listed in build/report.txt):
 *   - all 7 language keys present and non-empty, single line, length limits
 *   - no duplicate ids / duplicate English texts
 *   - quotes (--verify-quotes): the original-language text, or the English one,
 *     must appear in the raw wikitext of its `source` page (accent/case/
 *     punctuation-insensitive). Pages are cached in build/.wq-cache.
 *
 * Upload (--upload): gs://<bucket>/chat_datasets/<v>/<name>.json.gz with
 * Content-Encoding gzip + long cache, then chat_datasets/manifest.json last.
 *
 * Usage (repo root):
 *   node tools/chat_datasets/build_chat_datasets.js [--verify-quotes]
 *     [--freq-top 20000] [--upload --project greengo-chat]
 */
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const crypto = require('crypto');

const ROOT = __dirname;
const PARTS = path.join(ROOT, 'parts');
const BUILD = path.join(ROOT, 'build');
const LANGS = ['en', 'it', 'es', 'pt', 'pt_BR', 'fr', 'de'];
const FREQ_FILES = { en: 'en', it: 'it', es: 'es', pt: 'pt', pt_BR: 'pt_br', fr: 'fr', de: 'de' };

function arg(name, fallback) {
  const i = process.argv.indexOf(name);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}
const verifyQuotes = process.argv.includes('--verify-quotes');
const upload = process.argv.includes('--upload');
const freqTop = Number(arg('--freq-top', '20000'));

const report = [];
const drop = (kind, id, why) => report.push(`${kind}\t${id}\t${why}`);

function norm(s) {
  return String(s || '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .trim();
}

function readParts(prefix) {
  const out = [];
  for (const f of fs.readdirSync(PARTS).filter((n) => n.startsWith(prefix) && n.endsWith('.json')).sort()) {
    try {
      out.push({ file: f, data: JSON.parse(fs.readFileSync(path.join(PARTS, f), 'utf8')) });
    } catch (e) {
      drop(prefix, f, `invalid JSON: ${e.message}`);
    }
  }
  return out;
}

/** text map -> cleaned {lang: text} or null (and the reason). */
function cleanText(t, maxLen) {
  if (!t || typeof t !== 'object') return [null, 'no text'];
  const out = {};
  for (const l of LANGS) {
    const v = String(t[l] ?? '').replace(/\s+/g, ' ').trim();
    if (!v) return [null, `missing ${l}`];
    if (v.length > maxLen) return [null, `${l} longer than ${maxLen}`];
    out[l] = v;
  }
  return [out, null];
}

function collectList(prefix, kind, maxLen, map) {
  const items = [];
  const ids = new Set();
  const en = new Set();
  for (const { file, data } of readParts(prefix)) {
    const arr = Array.isArray(data) ? data : [];
    if (!Array.isArray(data)) drop(kind, file, 'not a JSON array');
    for (const it of arr) {
      const id = String(it.id || '');
      const [t, why] = cleanText(it.text, maxLen);
      if (!id) { drop(kind, file, 'item without id'); continue; }
      if (!t) { drop(kind, id, why); continue; }
      if (ids.has(id)) { drop(kind, id, 'duplicate id'); continue; }
      const key = norm(t.en);
      if (en.has(key)) { drop(kind, id, 'duplicate English text'); continue; }
      ids.add(id);
      en.add(key);
      items.push(map(it, t));
    }
  }
  return items;
}

// ------------------------------------------------------------ wikiquote ---
const WQ_CACHE = path.join(BUILD, '.wq-cache');
async function rawPage(url) {
  const m = /^https?:\/\/([a-z-]+)\.wikiquote\.org\/wiki\/(.+)$/.exec(url || '');
  if (!m) return null;
  const file = path.join(WQ_CACHE, `${m[1]}__${m[2].replace(/[^\w.-]/g, '_')}.txt`);
  if (fs.existsSync(file)) return fs.readFileSync(file, 'utf8');
  const raw = `https://${m[1]}.wikiquote.org/w/index.php?title=${m[2]}&action=raw`;
  for (let attempt = 0; attempt < 5; attempt++) {
    const res = await fetch(raw, { headers: { 'User-Agent': 'GreenGoDatasetBuilder/1.0' } });
    if (res.status === 429 || res.status >= 500) {
      await new Promise((r) => setTimeout(r, 3000 * (attempt + 1)));
      continue;
    }
    if (!res.ok) return null;
    const text = await res.text();
    fs.mkdirSync(WQ_CACHE, { recursive: true });
    fs.writeFileSync(file, text);
    await new Promise((r) => setTimeout(r, 300));
    return text;
  }
  return null;
}

/** Wikitext without markup, folded like norm(). */
function plainWiki(w) {
  return norm(String(w)
    .replace(/\[\[(?:[^|\]]*\|)?([^\]]*)\]\]/g, '$1') // [[link|text]]
    .replace(/'''?/g, '')
    // Real tags only: a stray '<' on a page must not swallow the rest of it.
    .replace(/<\/?[a-zA-Z][^<>]{0,300}>/g, ' ')
    .replace(/&nbsp;|&mdash;|&ndash;|&hellip;/g, ' ')
    // Keep the TEXT of templates ({{citation|...}}, {{Citazione|...}}):
    // fr/it/es/de Wikiquote wrap most quotes in them. Drop only the
    // template name and the separators.
    .replace(/\{\{[^|{}]*\|/g, ' ')
    .replace(/\{\{|\}\}|\|/g, ' '));
}

async function verifyQuote(q) {
  const page = await rawPage(q.source);
  if (page == null) return `source page unavailable (${q.source})`;
  const hay = plainWiki(page);
  const candidates = [q.text[q.origLang] , q.text.en].filter(Boolean).map(norm);
  // Match the first 12 words (agents sometimes drop a trailing clause).
  for (const c of candidates) {
    const head = c.split(' ').slice(0, 12).join(' ');
    if (head.length >= 12 && hay.includes(head)) return null;
  }
  return 'not found verbatim on the source page';
}

// ---------------------------------------------------------------- build ---
async function main() {
  fs.mkdirSync(BUILD, { recursive: true });

  // Quotes
  const quotes = [];
  {
    const raw = collectList('quotes_', 'quote', 320, (it, t) => ({ it, t }));
    let checked = 0;
    for (const { it, t } of raw) {
      if (verifyQuotes) {
        const why = await verifyQuote({ ...it, text: t });
        checked++;
        if (checked % 100 === 0) console.log(`  verified ${checked}/${raw.length}`);
        if (why) { drop('quote', it.id, why); continue; }
      }
      quotes.push({ id: it.id, a: String(it.author || ''), d: it.died ?? null, o: it.origLang || null, t });
    }
  }

  const icebreakers = collectList('icebreakers_', 'icebreaker', 220,
    (it, t) => ({ id: it.id, p: it.topic, t }));
  const sentences = collectList('sentences_', 'sentence', 220,
    (it, t) => ({ id: it.id, p: it.topic, l: /^(A1|A2|B1|B2|C1|C2)$/.test(it.level) ? it.level : 'B1', t }));

  // Cultural tips: {ISO2: [...]}
  const tips = {};
  {
    const ids = new Set();
    for (const { file, data } of readParts('tips_')) {
      if (Array.isArray(data) || typeof data !== 'object') { drop('tip', file, 'not an object keyed by ISO2'); continue; }
      for (const [iso, list] of Object.entries(data)) {
        if (!/^[A-Z]{2}$/.test(iso) || !Array.isArray(list)) { drop('tip', `${file}:${iso}`, 'bad country key'); continue; }
        for (const it of list) {
          const [t, why] = cleanText(it.text, 320);
          if (!t) { drop('tip', it.id, why); continue; }
          if (ids.has(it.id)) { drop('tip', it.id, 'duplicate id'); continue; }
          ids.add(it.id);
          (tips[iso] ??= []).push({ id: it.id, c: it.category || 'general', t });
        }
      }
    }
  }

  // Word frequency (difficulty badge): top N words per language.
  const freq = {};
  for (const [lang, f] of Object.entries(FREQ_FILES)) {
    const lines = fs.readFileSync(path.join(ROOT, 'freq', `${f}_50k.txt`), 'utf8').split('\n');
    freq[lang] = lines.slice(0, freqTop).map((l) => l.split(' ')[0]).filter(Boolean);
  }

  const keywordsFile = path.join(BUILD, 'keywords.json');
  const keywords = fs.existsSync(keywordsFile) ? JSON.parse(fs.readFileSync(keywordsFile, 'utf8')) : null;

  const v = Date.now();
  const files = { quotes, icebreakers, sentences, tips, freq, ...(keywords ? { keywords } : {}) };
  const manifest = { v, files: {} };
  for (const [name, data] of Object.entries(files)) {
    const json = Buffer.from(JSON.stringify(data));
    if (name !== 'keywords') fs.writeFileSync(path.join(BUILD, `${name}.json`), json);
    const gz = zlib.gzipSync(json, { level: 9 });
    fs.writeFileSync(path.join(BUILD, `${name}.json.gz`), gz);
    manifest.files[name] = {
      path: `chat_datasets/${v}/${name}.json.gz`,
      bytes: json.length,
      gz: gz.length,
      sha256: crypto.createHash('sha256').update(json).digest('hex'),
    };
  }
  fs.writeFileSync(path.join(BUILD, 'manifest.json'), JSON.stringify(manifest, null, 1));
  fs.writeFileSync(path.join(BUILD, 'report.txt'), report.join('\n') + '\n');

  const tipCount = Object.values(tips).reduce((s, l) => s + l.length, 0);
  console.log(`quotes ${quotes.length} | icebreakers ${icebreakers.length} | sentences ${sentences.length} | `
    + `tips ${tipCount} in ${Object.keys(tips).length} countries | freq ${Object.keys(freq).length} langs | `
    + `keywords ${keywords ? keywords.n.length + ' aliases' : 'MISSING (run build_keywords.js)'}`);
  for (const [n, f] of Object.entries(manifest.files)) console.log(`  ${n}: ${(f.bytes / 1024).toFixed(0)} KB -> ${(f.gz / 1024).toFixed(0)} KB gz`);
  console.log(`dropped ${report.length} items (build/report.txt)`);

  if (upload) {
    const projectId = arg('--project', process.env.GCLOUD_PROJECT);
    let admin;
    try {
      admin = require(path.join(ROOT, '..', '..', 'functions', 'node_modules', 'firebase-admin'));
    } catch (_) {
      admin = require('firebase-admin');
    }
    if (!admin.apps.length) admin.initializeApp({ projectId, storageBucket: `${projectId}.firebasestorage.app` });
    const bucket = admin.storage().bucket();
    for (const [name, f] of Object.entries(manifest.files)) {
      await bucket.file(f.path).save(fs.readFileSync(path.join(BUILD, `${name}.json.gz`)), {
        resumable: false,
        metadata: { contentType: 'application/json', cacheControl: 'public, max-age=31536000, immutable' },
      });
      console.log(`  uploaded ${f.path}`);
    }
    await bucket.file('chat_datasets/manifest.json').save(JSON.stringify(manifest), {
      resumable: false,
      metadata: { contentType: 'application/json', cacheControl: 'public, max-age=300' },
    });
    console.log('  uploaded chat_datasets/manifest.json');
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
