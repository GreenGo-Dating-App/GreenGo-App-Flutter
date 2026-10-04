#!/usr/bin/env node
/**
 * Build `attractions_lite/{ISO2}_{n}` - the LIST layout of the attractions
 * catalogue - from the existing `attractions_index/{ISO2}_{n}` shards, plus a
 * small manifest on `attraction_countries/{ISO2}.lite`.
 *
 * WHY
 *   `attractions_index` keeps every compact record as a Firestore map with ~29
 *   fields (500 per shard). A big country (FR, 2,827 attractions) is 6 docs /
 *   ~1.36 MB (Firestore size; more on the wire) the first time the Attractions
 *   tab opens it. The lite layout carries ONLY what the grid / list / filters /
 *   sort / in-country search render, packed one row per attraction:
 *     FR 1.36 MB / 6 docs  ->  ~0.4 MB / 1 doc   (see the dry-run report)
 *   The detail page still reads the full `attractions/{id}` doc.
 *
 * WHEN TO RUN
 *   After EVERY catalogue (re)seed (tools/attractions/seed_firestore.cjs) or any
 *   other change to `attractions_index`. Until it runs, the app ignores stale
 *   lite data on its own: the manifest records the source `indexVersion`, and a
 *   reseed bumps `attraction_countries/{ISO2}.indexVersion`, so the app falls
 *   back to the full shards for that country (correct, just heavier).
 *
 * LITE DOC FORMAT (format 1) - `attractions_lite/{ISO2}_{n}`
 *   {
 *     iso2, shard, shards,          // this shard / total shards of the build
 *     format: 1,
 *     version: '<16 hex>',          // content hash of the whole country build
 *     src: <number>,                // attractions_index {ISO2}_meta.version
 *     count, minScore, maxScore,    // rows in this shard; score range
 *     sep: '|',                     // row field separator (absent from data)
 *     cols: ['i','n','c',...],      // column names, in row order
 *     dict: { cat: [...], ... },    // a column listed here stores an INDEX
 *     rows: ['100001|Palace of Versailles|Versailles|...', ...],
 *     builtAt: <timestamp>          // changes only when the content changes
 *   }
 *   Rows keep the index order (GreenGo Score, best first) and are cut into
 *   shards of at most --max-bytes (default 700,000; Firestore's limit is
 *   1 MiB), so every country today is ONE doc. Empty cell = absent; trailing
 *   empty cells are dropped.
 *
 *   Columns (decoder: lib/features/attractions/data/attractions_lite_codec.dart)
 *     i   id                       n   name            c   city name
 *     cs  city slug   ('' = liteSlug(c); written whenever that differs)
 *     s   slug        ('' = liteSlug(n) + '-' + cs; written whenever that differs)
 *     cat category*   ci  category icon*  imp importance key*  ii importance icon*
 *     la, ln          lat / lng rounded to 5 decimals (~1 m)
 *     b   image base  ('' = 'attractions/{ISO2}/{id}')
 *     h   image hash
 *     t   image token, a UUID packed as 22-char base64url (16 bytes)
 *     tk  image token verbatim (only when it is not a UUID)
 *     sc  GreenGo Score
 *     st  score tier  ('' = derived from sc: >=90 iconic, >=80 exceptional,
 *                      >=70 excellent, >=60 great, else worth_visit)
 *     r   Google rating            tp  ticket price (only when > 0)
 *     cu  currency* (only with tp)
 *     f   flags bitmask: 1 free entry, 2 UNESCO, 4 must visit, 8 top-10
 *     dt  description template tail*: description = '{n} in {c}: ' + tail
 *     d   description verbatim (when not templated), capped at 120 chars
 *     vd  visit duration*          aa  photo credit author
 *     al  photo credit licence*
 *   (* = dictionary column: the cell is an index into dict[col])
 *   Not carried (detail page only): categoryGroup, indoorOutdoor,
 *   wheelchairAccessible - the detail page loads them from `attractions/{id}`.
 *
 * MANIFEST - `attraction_countries/{ISO2}.lite` (field update, nothing else on
 * the doc is touched; the app already reads these docs)
 *   { format: 1, shards, version, src, count, bytes, builtAt }
 *   The app uses the lite shards only when format is supported AND
 *   src == the country's indexVersion AND every shard of `version` is present.
 *
 * IDEMPOTENT
 *   Rebuilds from `attractions_index` every time. A shard whose stored version
 *   already equals the new one is skipped ("unchanged"), as is the manifest.
 *   Lite shards beyond the new shard count (and, on a full run, lite docs of
 *   countries no longer in the index) are deleted. Write order per country:
 *   shards -> manifest -> stale deletes, so a reader never sees a manifest
 *   pointing at missing shards.
 *
 * USAGE (from the repo root; firebase-admin comes from functions/node_modules)
 *   set GOOGLE_APPLICATION_CREDENTIALS=<service-account.json>
 *     (PowerShell: $env:GOOGLE_APPLICATION_CREDENTIALS="...")
 *   node scripts/build_attractions_lite.js --project greengo-chat --dry-run
 *   node scripts/build_attractions_lite.js --project greengo-chat
 *   node scripts/build_attractions_lite.js --project greengo-chat --country FR
 *
 *   --dry-run          read + build + report sizes; write / delete nothing
 *   --country XX       only that country (repeatable or comma-separated)
 *   --max-bytes N      shard size cap (default 700000)
 *   --source-json F    offline: build from a JSON dump {docId: data} of
 *                      attractions_index instead of Firestore (implies
 *                      --dry-run; for measuring / tests)
 *
 * Firestore rules: `attractions_lite` must be readable by signed-in users
 * (same as attractions_index). Until it is, the app's lite read fails and it
 * silently uses the full shards.
 *
 * On this PC the corporate TLS proxy may require NODE_TLS_REJECT_UNAUTHORIZED=0.
 */

'use strict';

const path = require('path');
const crypto = require('crypto');

const FORMAT = 1;
const LITE = 'attractions_lite';
const INDEX = 'attractions_index';
const COUNTRIES = 'attraction_countries';
const DESC_CAP = 120;

const COLS = [
  'i', 'n', 'c', 'cs', 's', 'cat', 'ci', 'imp', 'ii', 'la', 'ln', 'b', 'h', 't',
  'tk', 'sc', 'st', 'r', 'tp', 'cu', 'f', 'dt', 'd', 'vd', 'aa', 'al',
];
const DICT_COLS = ['cat', 'ci', 'imp', 'ii', 'cu', 'dt', 'vd', 'al'];
const SEPARATORS = ['|', '~', '^', '`', '¦', '\u001f'];

// ---------------------------------------------------------------- helpers ---

/**
 * Accent folding of the app's `liteSlug` (attractions_lite_codec.dart) - KEEP
 * IN SYNC. A value holding a letter outside ASCII and outside this table is
 * "not derivable": its slug is then always written verbatim.
 */
const FOLD = {
  a: 'àáâãäåāăą',
  c: 'çćĉċč',
  d: 'ď',
  e: 'èéêëēĕėęě',
  g: 'ĝğġģ',
  h: 'ĥ',
  i: 'ìíîïĩīĭį',
  j: 'ĵ',
  k: 'ķ',
  l: 'ĺļľ',
  n: 'ñńņňǹ',
  o: 'òóôõöōŏő',
  r: 'ŕŗř',
  s: 'śŝşšș',
  t: 'ţťț',
  u: 'ùúûüũūŭůűų',
  w: 'ŵ',
  y: 'ýÿŷ',
  z: 'źżž',
};
const FOLD_MAP = new Map();
for (const [base, chars] of Object.entries(FOLD)) for (const ch of chars) FOLD_MAP.set(ch, base);

/** True when every character of [s] is one `liteSlug` handles identically in Dart. */
function derivable(s) {
  for (const ch of String(s)) {
    const code = ch.codePointAt(0);
    if (code >= 0x20 && code <= 0x7e) continue;
    if (ch === '’') continue;
    // Upper-case forms must lower-case INTO the table (1:1 in Latin-1 / Ext-A).
    if (FOLD_MAP.has(ch) || (ch.toLowerCase().length === 1 && FOLD_MAP.has(ch.toLowerCase()))) continue;
    return false;
  }
  return true;
}

/**
 * Same as the app's `liteSlug`: lower-case, fold the accents above, drop
 * apostrophes (' and ’), every other run of non [a-z0-9] -> '-', trim the
 * dashes ("Port d'Envalira" -> "port-denvalira", "Zürich" -> "zurich").
 */
function liteSlug(s) {
  let out = '';
  for (const ch of String(s).toLowerCase()) out += FOLD_MAP.get(ch) || ch;
  return out.replace(/['’]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}

function tierFor(score) {
  if (score >= 90) return 'iconic';
  if (score >= 80) return 'exceptional';
  if (score >= 70) return 'excellent';
  if (score >= 60) return 'great';
  return 'worth_visit';
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

function packUuid(u) {
  return Buffer.from(u.replace(/-/g, ''), 'hex').toString('base64url');
}

function unpackUuid(b) {
  const h = Buffer.from(b, 'base64url').toString('hex');
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20)}`;
}

function num(v) {
  return typeof v === 'number' && Number.isFinite(v) ? v : null;
}

function str(v) {
  if (v === null || v === undefined) return '';
  const s = String(v).trim();
  return s;
}

/** Shortest decimal form, rounded to [dp] places. */
function fmt(v, dp) {
  const n = num(v);
  if (n === null) return '';
  return String(dp === undefined ? n : Number(n.toFixed(dp)));
}

function capDescription(d) {
  if (d.length <= DESC_CAP) return d;
  const cut = d.slice(0, DESC_CAP - 1);
  const word = cut.replace(/\s+\S*$/, '');
  return `${(word.length >= 60 ? word : cut).trimEnd()}…`;
}

/**
 * Firestore storage size of a value (https://firebase.google.com/docs/firestore/storage-size).
 * Timestamps count 8 bytes.
 */
function fsSize(v) {
  if (v === null || v === undefined || typeof v === 'boolean') return 1;
  if (typeof v === 'number') return 8;
  if (typeof v === 'string') return Buffer.byteLength(v, 'utf8') + 1;
  if (v instanceof Date || (v && typeof v._seconds === 'number') || (v && v.constructor && v.constructor.name === 'Timestamp')) return 8;
  if (v && v.constructor && v.constructor.name === 'FieldTransform') return 8;
  if (Array.isArray(v)) return v.reduce((s, x) => s + fsSize(x), 0);
  if (typeof v === 'object') {
    return Object.entries(v).reduce((s, [k, x]) => s + Buffer.byteLength(k, 'utf8') + 1 + fsSize(x), 0);
  }
  return 8;
}

function docSize(collection, id, data) {
  // document name + 32 bytes of overhead.
  return Buffer.byteLength(collection, 'utf8') + 1 + Buffer.byteLength(id, 'utf8') + 1 + 16 + 32 + fsSize(data);
}

// ------------------------------------------------------------------ build ---

/** One index record -> { col: rawValue } (dictionary columns still raw). */
function liteCells(it, iso) {
  const id = num(it.i);
  const name = str(it.n);
  const city = str(it.c);
  const citySlug = str(it.cs);
  const cells = {};
  cells.i = id === null ? '' : String(Math.trunc(id));
  cells.n = name;
  cells.c = city;
  cells.cs = citySlug && !(derivable(city) && liteSlug(city) === citySlug) ? citySlug : '';
  const slug = str(it.s);
  cells.s = slug && !(derivable(name) && `${liteSlug(name)}-${citySlug}` === slug) ? slug : '';
  cells.cat = str(it.cat);
  cells.ci = str(it.ci);
  cells.imp = str(it.imp);
  cells.ii = str(it.ii);
  cells.la = fmt(it.la, 5);
  cells.ln = fmt(it.ln, 5);
  const base = str(it.b);
  cells.b = base && base !== `attractions/${iso}/${cells.i}` ? base : '';
  cells.h = str(it.h);
  const tok = str(it.tk);
  cells.t = UUID.test(tok) ? packUuid(tok) : '';
  cells.tk = tok && !UUID.test(tok) ? tok : '';
  const score = num(it.sc) === null ? 0 : Math.trunc(it.sc);
  cells.sc = String(score);
  const tier = str(it.st);
  cells.st = tier && tier !== tierFor(score) ? tier : '';
  cells.r = fmt(it.r);
  const price = num(it.tp);
  cells.tp = price !== null && price > 0 ? fmt(price) : '';
  cells.cu = cells.tp ? str(it.cu) : '';
  const flags = (it.f === true ? 1 : 0) | (it.u === true ? 2 : 0) | (it.mv === true ? 4 : 0) | (it.t10 === true ? 8 : 0);
  cells.f = flags ? String(flags) : '';
  const d = str(it.d);
  const prefix = `${name} in ${city}: `;
  if (d && name && city && d.startsWith(prefix) && d.length > prefix.length) {
    cells.dt = d.slice(prefix.length);
    cells.d = '';
  } else {
    cells.dt = '';
    cells.d = d ? capDescription(d) : '';
  }
  cells.vd = str(it.vd);
  const at = it.at && typeof it.at === 'object' ? it.at : null;
  cells.aa = at ? str(at.a) : '';
  cells.al = cells.aa ? str(at.l) : '';
  return { cells, score };
}

/** Rows of [cellsList] encoded against fresh per-shard dictionaries. */
function encodeShard(cellsList) {
  const dict = {};
  const lookup = {};
  for (const col of DICT_COLS) {
    dict[col] = [];
    lookup[col] = new Map();
  }
  const values = cellsList.map((cells) => COLS.map((col) => {
    const v = cells[col];
    if (!v || !lookup[col]) return v || '';
    let i = lookup[col].get(v);
    if (i === undefined) {
      i = dict[col].length;
      dict[col].push(v);
      lookup[col].set(v, i);
    }
    return String(i);
  }));
  // A separator absent from every cell of this shard.
  const sep = SEPARATORS.find((s) => values.every((row) => row.every((v) => !v.includes(s))));
  if (!sep) throw new Error('no usable row separator for this shard');
  const rows = values.map((row) => {
    let end = row.length;
    while (end > 0 && row[end - 1] === '') end--;
    return row.slice(0, end).join(sep);
  });
  for (const col of DICT_COLS) if (dict[col].length === 0) delete dict[col];
  return { sep, dict, rows };
}

/**
 * Build the lite shards of one country from its index records (index order).
 * Returns { docs: [{id, data}], version, count, bytes }. `data` has no builtAt.
 */
function buildCountry(iso, items, src, maxBytes) {
  const built = items.map((it) => liteCells(it, iso));
  // Greedy cut by measured size (re-encoded per shard: dictionaries are local).
  const groups = [];
  let start = 0;
  while (start < built.length) {
    let lo = start + 1;
    let hi = built.length;
    // Largest end with size <= maxBytes (binary search; size grows with rows).
    const sizeOf = (end) => {
      const enc = encodeShard(built.slice(start, end).map((b) => b.cells));
      return fsSize({ rows: enc.rows, dict: enc.dict, cols: COLS }) + 400;
    };
    if (sizeOf(hi) <= maxBytes) {
      lo = hi;
    } else {
      while (lo < hi) {
        const mid = Math.ceil((lo + hi) / 2);
        if (sizeOf(mid) <= maxBytes) lo = mid;
        else hi = mid - 1;
      }
    }
    groups.push([start, lo]);
    start = lo;
  }
  const shards = groups.length;
  const encoded = groups.map(([a, b]) => ({ enc: encodeShard(built.slice(a, b).map((x) => x.cells)), scores: built.slice(a, b).map((x) => x.score) }));
  const version = crypto.createHash('sha1')
    .update(JSON.stringify({ format: FORMAT, iso, src, cols: COLS, shards: encoded.map((e) => e.enc) }))
    .digest('hex').slice(0, 16);
  const docs = encoded.map(({ enc, scores }, shard) => {
    const data = {
      iso2: iso,
      shard,
      shards,
      format: FORMAT,
      version,
      src,
      count: enc.rows.length,
      minScore: Math.min(...scores),
      maxScore: Math.max(...scores),
      sep: enc.sep,
      cols: COLS,
      dict: enc.dict,
      rows: enc.rows,
    };
    return { id: `${iso}_${shard}`, data, bytes: docSize(LITE, `${iso}_${shard}`, { ...data, builtAt: 0 }) };
  });
  for (const d of docs) {
    if (d.bytes > 1024 * 1024 - 1024) throw new Error(`${d.id} is ${d.bytes} bytes (over 1 MiB)`);
  }
  return { docs, version, count: built.length, bytes: docs.reduce((s, d) => s + d.bytes, 0) };
}

/**
 * Decode a lite doc back to index-shaped records (used to self-check every
 * build: what the app will parse must equal the source on every lite field).
 */
function decodeDoc(data, iso) {
  const cols = data.cols;
  const out = [];
  for (const row of data.rows) {
    const parts = row.split(data.sep);
    const v = (col) => {
      const i = cols.indexOf(col);
      const raw = i >= 0 && i < parts.length ? parts[i] : '';
      if (!raw) return '';
      const dl = data.dict[col];
      return dl ? dl[Number(raw)] : raw;
    };
    const n = v('n');
    const c = v('c');
    const cs = v('cs') || liteSlug(c);
    const flags = Number(v('f') || 0);
    const sc = Number(v('sc') || 0);
    const t = v('t');
    out.push({
      i: Number(v('i')), n, c, cs,
      s: v('s') || `${liteSlug(n)}-${cs}`,
      cat: v('cat'), ci: v('ci'), imp: v('imp'), ii: v('ii'),
      la: v('la') ? Number(v('la')) : null, ln: v('ln') ? Number(v('ln')) : null,
      b: v('b') || `attractions/${iso}/${v('i')}`,
      h: v('h'), tk: t ? unpackUuid(t) : v('tk'),
      sc, st: v('st') || tierFor(sc),
      r: v('r') ? Number(v('r')) : null,
      tp: v('tp') ? Number(v('tp')) : null, cu: v('cu'),
      f: (flags & 1) !== 0, u: (flags & 2) !== 0, mv: (flags & 4) !== 0, t10: (flags & 8) !== 0,
      d: v('dt') ? `${n} in ${c}: ${v('dt')}` : v('d'),
      vd: v('vd'), aa: v('aa'), al: v('al'),
    });
  }
  return out;
}

/** Throws when a decoded record disagrees with its source on a lite field. */
function selfCheck(iso, items, docs) {
  const decoded = docs.flatMap((d) => decodeDoc(d.data, iso));
  if (decoded.length !== items.length) throw new Error(`${iso}: decoded ${decoded.length} of ${items.length}`);
  const same = (a, b) => (a === undefined || a === null || a === '' ? '' : a) === (b === undefined || b === null || b === '' ? '' : b);
  items.forEach((src, k) => {
    const got = decoded[k];
    const want = {
      i: src.i, n: str(src.n), c: str(src.c), cs: str(src.cs), s: str(src.s),
      cat: str(src.cat), ci: str(src.ci), imp: str(src.imp), ii: str(src.ii),
      b: str(src.b), h: str(src.h), tk: str(src.tk), sc: Math.trunc(num(src.sc) || 0),
      st: str(src.st) || tierFor(Math.trunc(num(src.sc) || 0)), r: num(src.r),
      tp: num(src.tp) && src.tp > 0 ? src.tp : null, cu: num(src.tp) && src.tp > 0 ? str(src.cu) : '',
      f: src.f === true, u: src.u === true, mv: src.mv === true, t10: src.t10 === true,
      vd: str(src.vd), aa: src.at ? str(src.at.a) : '', al: src.at && str(src.at.a) ? str(src.at.l) : '',
    };
    for (const [k2, w] of Object.entries(want)) {
      if (!same(got[k2], w)) throw new Error(`${iso} id ${src.i}: ${k2} decoded ${JSON.stringify(got[k2])} != ${JSON.stringify(w)}`);
    }
    const d = str(src.d);
    if (!(got.d === d || (d.length > DESC_CAP && got.d === capDescription(d)))) {
      throw new Error(`${iso} id ${src.i}: description mismatch`);
    }
    for (const k2 of ['la', 'ln']) {
      if ((src[k2] == null) !== (got[k2] == null) || (src[k2] != null && Math.abs(src[k2] - got[k2]) > 6e-6)) {
        throw new Error(`${iso} id ${src.i}: ${k2} mismatch`);
      }
    }
  });
}

/** Same content as stored (ignores builtAt / server fields). */
function sameDoc(stored, data) {
  if (!stored) return false;
  return stored.version === data.version && stored.shard === data.shard &&
    stored.shards === data.shards && stored.format === data.format &&
    stored.src === data.src && stored.count === data.count;
}

// ------------------------------------------------------------------- main ---

function arg(name) {
  const out = [];
  process.argv.forEach((a, i) => {
    if (a === name && process.argv[i + 1]) out.push(process.argv[i + 1]);
  });
  return out;
}

function kb(n) {
  return `${(n / 1024).toFixed(0)} KB`;
}

/** iso -> { items (index order), src, shardCount, problems } from index docs. */
function groupIndex(entries) {
  const by = new Map();
  for (const [id, data] of entries) {
    const iso = String(data.iso2 || id.split('_')[0]).toUpperCase();
    let g = by.get(iso);
    if (!g) by.set(iso, (g = { shards: [], meta: null }));
    if (id.endsWith('_meta')) g.meta = data;
    else g.shards.push(data);
  }
  const out = new Map();
  for (const [iso, g] of by) {
    g.shards.sort((a, b) => (a.shard || 0) - (b.shard || 0));
    const items = g.shards.flatMap((s) => (Array.isArray(s.items) ? s.items : []));
    const problems = [];
    if (!g.meta) problems.push('no _meta doc');
    else {
      if (g.meta.shardCount !== g.shards.length) problems.push(`meta.shardCount ${g.meta.shardCount} != ${g.shards.length} shards`);
      if (typeof g.meta.total === 'number' && g.meta.total !== items.length) problems.push(`meta.total ${g.meta.total} != ${items.length} items`);
    }
    const src = g.meta && typeof g.meta.version === 'number' ? g.meta.version : (g.shards[0] && g.shards[0].version) || 0;
    out.set(iso, { items, src, fullBytes: g.shards.reduce((s, d) => s + docSize(INDEX, `${iso}_${d.shard}`, d), 0), fullDocs: g.shards.length, problems });
  }
  return out;
}

async function main() {
  const sourceJson = arg('--source-json')[0];
  const dryRun = process.argv.includes('--dry-run') || !!sourceJson;
  const only = new Set(arg('--country').flatMap((c) => c.split(',')).map((c) => c.trim().toUpperCase()).filter(Boolean));
  const maxBytes = Number(arg('--max-bytes')[0] || 700000);
  if (!Number.isFinite(maxBytes) || maxBytes < 50000 || maxBytes > 1000000) {
    console.error('--max-bytes must be between 50000 and 1000000');
    process.exit(1);
  }

  let db = null;
  let admin = null;
  let entries;
  if (sourceJson) {
    entries = Object.entries(JSON.parse(require('fs').readFileSync(sourceJson, 'utf8')));
  } else {
    const projectId = arg('--project')[0] || process.env.GCLOUD_PROJECT;
    if (!projectId) {
      console.error('Missing --project <projectId>');
      process.exit(1);
    }
    process.env.GCLOUD_PROJECT = projectId;
    process.env.GOOGLE_CLOUD_PROJECT = projectId;
    admin = require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));
    if (!admin.apps.length) admin.initializeApp({ projectId });
    db = admin.firestore();
    entries = [];
    const isos = only.size ? [...only] : [null];
    for (const iso of isos) {
      const q = iso ? db.collection(INDEX).where('iso2', '==', iso) : db.collection(INDEX);
      const snap = await q.get();
      for (const d of snap.docs) entries.push([d.id, d.data()]);
    }
  }
  if (only.size) entries = entries.filter(([id, d]) => only.has(String(d.iso2 || id.split('_')[0]).toUpperCase()));
  const countries = groupIndex(entries);
  if (countries.size === 0) {
    console.error('No attractions_index docs found - nothing to do.');
    process.exit(1);
  }
  console.log(`${dryRun ? '[dry-run] ' : ''}${countries.size} countries from ${entries.length} index docs (max ${maxBytes} bytes/shard)`);

  const totals = { full: 0, lite: 0, fullDocs: 0, liteDocs: 0, written: 0, skipped: 0, deleted: 0, manifests: 0, failed: 0 };
  const report = [];
  for (const iso of [...countries.keys()].sort()) {
    const c = countries.get(iso);
    if (c.problems.length) {
      console.warn(`  ${iso}: SKIPPED - incomplete index (${c.problems.join('; ')})`);
      totals.failed++;
      continue;
    }
    let build;
    try {
      build = buildCountry(iso, c.items, c.src, maxBytes);
      selfCheck(iso, c.items, build.docs);
    } catch (e) {
      console.warn(`  ${iso}: SKIPPED - ${e.message}`);
      totals.failed++;
      continue;
    }
    totals.full += c.fullBytes;
    totals.lite += build.bytes;
    totals.fullDocs += c.fullDocs;
    totals.liteDocs += build.docs.length;
    report.push([iso, c.items.length, c.fullDocs, c.fullBytes, build.docs.length, build.bytes, Math.max(...build.docs.map((d) => d.bytes))]);

    if (!db) continue;
    const existing = await db.collection(LITE).where('iso2', '==', iso)
      .select('version', 'shard', 'shards', 'format', 'src', 'count').get();
    const stored = new Map(existing.docs.map((d) => [d.id, d.data()]));
    const now = admin.firestore.FieldValue.serverTimestamp();
    let wrote = 0;
    for (const d of build.docs) {
      if (sameDoc(stored.get(d.id), d.data)) {
        totals.skipped++;
        continue;
      }
      wrote++;
      if (!dryRun) await db.collection(LITE).doc(d.id).set({ ...d.data, builtAt: now });
    }
    totals.written += wrote;

    const countryRef = db.collection(COUNTRIES).doc(iso);
    const countryDoc = await countryRef.get();
    const manifest = { format: FORMAT, shards: build.docs.length, version: build.version, src: c.src, count: build.count, bytes: build.bytes };
    const old = countryDoc.exists ? countryDoc.get('lite') : null;
    const manifestSame = old && ['format', 'shards', 'version', 'src', 'count', 'bytes'].every((k) => old[k] === manifest[k]);
    if (!countryDoc.exists) {
      console.warn(`  ${iso}: no ${COUNTRIES}/${iso} doc - shards built, manifest NOT written (the app will not use them)`);
    } else {
      const iv = countryDoc.get('indexVersion');
      if (typeof iv === 'number' && iv !== c.src) {
        console.warn(`  ${iso}: ${COUNTRIES}/${iso}.indexVersion ${iv} != index version ${c.src} - the app will keep using the full shards until they agree`);
      }
    }
    if (countryDoc.exists && !manifestSame) {
      totals.manifests++;
      if (!dryRun) await countryRef.update({ lite: { ...manifest, builtAt: now } });
    }

    const keep = new Set(build.docs.map((d) => d.id));
    const stale = [...stored.keys()].filter((id) => !keep.has(id));
    for (const id of stale) {
      totals.deleted++;
      if (!dryRun) await db.collection(LITE).doc(id).delete();
    }
    console.log(`  ${iso}: ${build.docs.length} shard(s) ${kb(build.bytes)} - ${wrote} ${dryRun ? "to write" : "written"}, ${build.docs.length - wrote} unchanged, ${stale.length} stale ${dryRun ? "to delete" : "deleted"}${manifestSame ? "" : (dryRun ? ", manifest to update" : ", manifest updated")}`);
  }

  // Full run: lite docs of countries that left the index.
  if (db && !only.size) {
    const all = await db.collection(LITE).select('iso2').get();
    const gone = all.docs.filter((d) => !countries.has(String(d.get('iso2') || d.id.split('_')[0]).toUpperCase()));
    const goneIsos = new Set(gone.map((d) => String(d.get('iso2') || d.id.split('_')[0]).toUpperCase()));
    for (const iso of goneIsos) {
      const ref = db.collection(COUNTRIES).doc(iso);
      const snap = await ref.get();
      if (snap.exists && snap.get('lite') !== undefined) {
        totals.manifests++;
        if (!dryRun) await ref.update({ lite: admin.firestore.FieldValue.delete() });
      }
    }
    for (const d of gone) {
      totals.deleted++;
      if (!dryRun) await d.ref.delete();
    }
    if (gone.length) console.log(`  removed ${gone.length} lite doc(s) of ${goneIsos.size} countries no longer indexed: ${[...goneIsos].join(', ')}`);
  }

  report.sort((a, b) => b[3] - a[3]);
  console.log('\nlargest countries (Firestore storage size):');
  console.log('  ISO  items  full docs / size  ->  lite docs / size (largest shard)  saving');
  for (const [iso, n, fd, fb, ld, lb, lmax] of report.slice(0, 15)) {
    console.log(`  ${iso}  ${String(n).padStart(5)}  ${String(fd).padStart(2)} / ${kb(fb).padStart(8)}  ->  ${String(ld).padStart(2)} / ${kb(lb).padStart(7)} (${kb(lmax)})  ${((1 - lb / fb) * 100).toFixed(0)}%`);
  }
  console.log(`\ntotal: ${totals.fullDocs} docs / ${(totals.full / 1048576).toFixed(1)} MB  ->  ${totals.liteDocs} docs / ${(totals.lite / 1048576).toFixed(1)} MB`);
  if (db) {
    console.log(`${dryRun ? 'would write' : 'wrote'} ${totals.written} shard(s), ${totals.skipped} unchanged, ${totals.deleted} deleted, ${totals.manifests} manifest(s) updated`);
  }
  if (totals.failed) {
    console.error(`${totals.failed} countr${totals.failed === 1 ? 'y' : 'ies'} skipped (see warnings)`);
    process.exitCode = 2;
  }
}

module.exports = { buildCountry, decodeDoc, liteSlug, derivable, tierFor, packUuid, unpackUuid, liteCells, COLS, FORMAT };

if (require.main === module) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}
