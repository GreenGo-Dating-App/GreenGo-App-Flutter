#!/usr/bin/env node
/**
 * Fill `attractions/{id}.curiosities` with the attraction's TOP 5 CURIOSITIES
 * (English; the detail page translates them on the fly like the rest of its
 * prose). Generated with Gemini from the attraction's own catalogue text
 * (name, place, category, descriptions, history), so the facts stay about the
 * right place.
 *
 * Written fields:
 *   curiosities:      [5 strings, each <= ~180 chars]
 *   curiositiesModel: the Gemini model used
 *   curiositiesAt:    server timestamp
 *
 * RESUMABLE: every run walks the whole collection (ordered by doc id, paged)
 * and only generates for docs that do not already hold 5 curiosities, so a
 * stopped run is simply started again (no saved offset). Re-generate
 * everything with --force.
 *
 * Usage (from the repo root; firebase-admin comes from functions/node_modules):
 *   node scripts/generate_attraction_curiosities.js --project greengo-chat
 *     [--limit N]        stop after N attempted docs (try it with 5 first)
 *     [--country FR]     only one country (countryIso2)
 *     [--concurrency 8]  parallel Gemini calls (default 8)
 *     [--model gemini-flash-latest]
 *     [--dry-run]        generate and print, write nothing
 *     [--force]          regenerate docs that already have curiosities
 *
 * The Gemini key is read like the Cloud Functions read it: env GEMINI_API_KEY,
 * else app_config/api_keys.gemini_api_key. Credentials: Application Default
 * Credentials (gcloud auth application-default login) or
 * GOOGLE_APPLICATION_CREDENTIALS. On this PC the corporate TLS proxy may need
 * NODE_TLS_REJECT_UNAUTHORIZED=0.
 *
 * NOTE: a full catalogue re-seed that uses set() without merge would drop
 * these fields - run this script again after such a seed.
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

const limit = Number(arg('--limit', '0')) || Infinity;
const country = (arg('--country', '') || '').toUpperCase();
const concurrency = Math.max(1, Number(arg('--concurrency', '8')) || 8);
const model = arg('--model', 'gemini-flash-latest');
const dryRun = process.argv.includes('--dry-run');
const force = process.argv.includes('--force');

let admin;
try {
  admin = require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));
} catch (_) {
  admin = require('firebase-admin'); // NODE_PATH
}
if (!admin.apps.length) admin.initializeApp({ projectId });
const db = admin.firestore();

const PAGE = 500;
const WANT = 5;
const MAX_CHARS = 180;

async function geminiKey() {
  if (process.env.GEMINI_API_KEY) return process.env.GEMINI_API_KEY;
  const d = (await db.doc('app_config/api_keys').get()).data() || {};
  const k = (d.gemini_api_key || '').trim();
  if (!k) throw new Error('No Gemini key (env GEMINI_API_KEY or app_config/api_keys.gemini_api_key)');
  return k;
}

function clip(s, n) {
  s = String(s || '').replace(/\s+/g, ' ').trim();
  return s.length > n ? s.slice(0, n) : s;
}

function prompt(a) {
  const lines = [
    `Attraction: ${a.name}${a.officialName && a.officialName !== a.name ? ` (official name: ${a.officialName})` : ''}`,
    `Place: ${[a.cityName, a.countryName || a.countryIso2].filter(Boolean).join(', ')}`,
    a.category ? `Category: ${a.category}` : '',
    a.descriptionLong || a.descriptionMedium || a.descriptionShort
      ? `Description: ${clip(a.descriptionLong || a.descriptionMedium || a.descriptionShort, 1500)}` : '',
    a.historySummary ? `History: ${clip(a.historySummary, 800)}` : '',
    (a.topHighlights || []).length ? `Highlights: ${a.topHighlights.slice(0, 6).join('; ')}` : '',
  ].filter(Boolean);
  return `${lines.join('\n')}

Write the TOP ${WANT} CURIOSITIES a visitor would love to know about THIS attraction: surprising, specific, true facts (history, records, architecture, legends clearly labelled as legends, hidden details, famous visitors, numbers).
Rules:
- Exactly ${WANT} items, English, each one sentence of at most ${MAX_CHARS} characters.
- Only facts you are confident are true for this exact place; no invented dates, names or numbers.
- If little is known about it, use well-established facts about its type, history or surroundings that apply to it, and say so plainly.
- No marketing tone, no emojis, no numbering, no repeating the name at the start of every item.`;
}

async function generate(key, a) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${key}`;
  const body = {
    contents: [{ role: 'user', parts: [{ text: prompt(a) }] }],
    generationConfig: {
      temperature: 0.4,
      responseMimeType: 'application/json',
      responseSchema: {
        type: 'OBJECT',
        properties: { curiosities: { type: 'ARRAY', items: { type: 'STRING' } } },
        required: ['curiosities'],
      },
    },
  };
  for (let attempt = 0; attempt < 6; attempt++) {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (res.status === 429 || res.status >= 500) {
      await new Promise((r) => setTimeout(r, Math.min(60000, 2000 * 2 ** attempt)));
      continue;
    }
    const j = await res.json();
    if (!res.ok) throw new Error(`Gemini ${res.status}: ${JSON.stringify(j.error || j).slice(0, 200)}`);
    const text = j.candidates?.[0]?.content?.parts?.map((p) => p.text || '').join('') || '';
    const list = (JSON.parse(text).curiosities || [])
      .map((s) => clip(String(s).replace(/^\s*(\d+[.)]|[-*•])\s*/, ''), MAX_CHARS + 40))
      .filter((s) => s.length >= 15);
    const unique = [...new Set(list)];
    if (unique.length >= WANT) return unique.slice(0, WANT);
    if (attempt >= 2) throw new Error(`only ${unique.length} curiosities`);
  }
  throw new Error('Gemini kept failing (rate limit / server errors)');
}

const FIELDS = ['name', 'officialName', 'cityName', 'countryName', 'countryIso2', 'category',
  'descriptionShort', 'descriptionMedium', 'descriptionLong', 'historySummary', 'topHighlights', 'curiosities'];

async function main() {
  const key = await geminiKey();
  let base = db.collection('attractions');
  if (country) base = base.where('countryIso2', '==', country);
  let last = null;
  let scanned = 0, done = 0, skipped = 0, failed = 0, attempted = 0;
  const started = Date.now();
  let aborted = false;

  for (;;) {
    let q = base.orderBy(admin.firestore.FieldPath.documentId()).select(...FIELDS).limit(PAGE);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    if (snap.empty) break;
    last = snap.docs[snap.docs.length - 1];
    scanned += snap.size;

    const todo = snap.docs.filter((d) => {
      const c = d.get('curiosities');
      const has = Array.isArray(c) && c.length >= WANT;
      if (has && !force) skipped++;
      return force || !has;
    });

    let i = 0;
    const worker = async () => {
      while (i < todo.length && attempted < limit && !aborted) {
        const d = todo[i++];
        attempted++;
        try {
          const list = await generate(key, d.data());
          done++;
          if (dryRun) {
            console.log(`\n${d.id} ${d.get('name')} (${d.get('cityName')}, ${d.get('countryIso2')})`);
            list.forEach((s, n) => console.log(`  ${n + 1}. ${s}`));
          } else {
            await d.ref.update({
              curiosities: list,
              curiositiesModel: model,
              curiositiesAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          failed++;
          console.error(`FAIL ${d.id} ${d.get('name')}: ${e.message.slice(0, 160)}`);
          // Nothing works (bad model / key / quota): stop instead of failing
          // the whole catalogue one call at a time.
          if (done === 0 && failed >= 10) aborted = true;
        }
      }
    };
    await Promise.all(Array.from({ length: concurrency }, worker));

    const mins = ((Date.now() - started) / 60000).toFixed(1);
    console.log(`[${mins} min] scanned ${scanned} | generated ${done} | already had ${skipped} | failed ${failed}`);
    if (attempted >= limit) break;
    if (aborted) {
      console.error('ABORTED: the first calls all failed - check the model / key / quota.');
      process.exit(1);
    }
  }
  console.log(`DONE: generated ${done}, already had ${skipped}, failed ${failed} (re-run to retry failures)`);
  process.exit(failed && done === 0 ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
