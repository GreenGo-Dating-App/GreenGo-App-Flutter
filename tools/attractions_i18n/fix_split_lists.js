#!/usr/bin/env node
/**
 * Repairs English list items that the catalogue generator split at the dot of
 * an abbreviation: ["St", "Andrew's Castle is among ..."] ->
 * ["St. Andrew's Castle is among ..."]. Two items are joined when the end of
 * the first and the start of the second are the two halves of the attraction,
 * city, region or country name around a ". ", or when the first ends with a
 * bare "St"/"Sts"/"Ste"/"Sv"/"Mt" and the second starts with a capital.
 *
 *   node fix_split_lists.js                 # fix build/source.jsonl (backup kept), report
 *   node fix_split_lists.js --write         # ...and update attractions/{id} in Firestore
 *
 * Run before `--step extract` so the templates are made from the joined text.
 */
const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, 'build');
const SRC = path.join(OUT, 'source.jsonl');
const LISTS = ['topHighlights', 'interestingFacts', 'curiosities'];
const ABBR = /(?:^|[\s(])(?:St|Sts|Ste|Sv|Mt)$/;

function join(list, halves) {
  const v = [...list];
  let n = 0;
  for (let i = 0; i < v.length - 1;) {
    const a = v[i];
    const b = v[i + 1];
    const byName = halves.some((p) => p.some((x, k) => k < p.length - 1 && a.endsWith(x) && b.startsWith(p[k + 1])));
    if (byName || (ABBR.test(a) && /^\p{Lu}/u.test(b))) {
      v.splice(i, 2, `${a}. ${b}`);
      n++;
    } else {
      i++;
    }
  }
  return [v, n];
}

async function main() {
  const lines = fs.readFileSync(SRC, 'utf8').split('\n').filter((l) => l.trim());
  const fixes = [];
  let joined = 0;
  const out = lines.map((l) => {
    const r = JSON.parse(l);
    const halves = [r.name, r.cityName, r.stateProvince, r.countryName]
      .filter((x) => typeof x === 'string' && x.includes('. ')).map((x) => x.split('. '));
    const patch = {};
    for (const f of LISTS) {
      if (!Array.isArray(r[f]) || !r[f].every((x) => typeof x === 'string')) continue;
      const [v, n] = join(r[f], halves);
      if (n) {
        patch[f] = v;
        r[f] = v;
        joined += n;
      }
    }
    if (Object.keys(patch).length) fixes.push({ id: r._doc, patch });
    return JSON.stringify(r);
  });
  console.log(`attractions ${lines.length}, fixed ${fixes.length}, items joined ${joined}`);
  // build/split_fix.jsonl keeps every patch made so far: a second run finds
  // the source already joined, and --write still sends the earlier patches.
  const log = path.join(OUT, 'split_fix.jsonl');
  if (fixes.length) {
    const bak = path.join(OUT, 'source.before_split_fix.jsonl');
    if (!fs.existsSync(bak)) fs.copyFileSync(SRC, bak);
    fs.writeFileSync(SRC, out.join('\n') + '\n');
    fs.appendFileSync(log, fixes.map((x) => JSON.stringify(x)).join('\n') + '\n');
    console.log('sample:', JSON.stringify(fixes[0]).slice(0, 300));
  }
  if (!process.argv.includes('--write')) return;
  const byId = new Map();
  if (fs.existsSync(log)) {
    for (const l of fs.readFileSync(log, 'utf8').split('\n')) {
      if (!l.trim()) continue;
      const x = JSON.parse(l);
      byId.set(x.id, { ...(byId.get(x.id) || {}), ...x.patch });
    }
  }
  fixes.length = 0;
  for (const [id, patch] of byId) fixes.push({ id, patch });

  let a;
  try {
    a = require(path.join(__dirname, '../../functions/node_modules/firebase-admin'));
  } catch (_) {
    a = require('firebase-admin');
  }
  a.initializeApp({ projectId: 'greengo-chat' });
  const bw = a.firestore().bulkWriter();
  let failed = 0;
  bw.onWriteError((e) => {
    if (e.failedAttempts < 5) return true;
    failed++;
    return false;
  });
  for (const f of fixes) bw.update(a.firestore().collection('attractions').doc(f.id), f.patch);
  await bw.close();
  console.log(`WRITE DONE ${fixes.length}, failed ${failed}`);
}

main().then(() => process.exit(0), (e) => { console.error(e); process.exit(1); });
