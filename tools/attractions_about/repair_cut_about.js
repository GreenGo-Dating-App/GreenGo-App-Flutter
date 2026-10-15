#!/usr/bin/env node
/**
 * Repairs "What is it?" texts that build_about.js cut right after an
 * abbreviation: its sentence split took "St." / "J." / "Pty." for a sentence
 * end, so a text could stop at "...also known as the Church of St.". The
 * text is rebuilt from the saved Wikipedia extract with an abbreviation-aware
 * split, and only accepted when the old text is a prefix of the new one.
 *
 *   node repair_cut_about.js --extracts <build/extracts.jsonl> --source <source.jsonl> [--out <file>]
 *   node repair_cut_about.js --write --out <file>       # apply to Firestore
 *
 * Writes {id, lang, old, text} lines; the i18n pipeline applies them
 * (attractions/{id}.about.{lang}) and re-translates the languages made from
 * those texts.
 */
const fs = require('fs');

const arg = (k, d) => { const i = process.argv.indexOf(k); return i > 0 ? process.argv[i + 1] : d; };
const ABBR = '(?:St|Ste|Sta|Sto|Sts|Mt|Ft|Dr|Sr|Jr|No|Nr|Mr|Mrs|Rev|Gen|Fr|Ss|SS|Sv|sv|Kath|hl|hll|Hl|ca|approx|Ltd|Co|Inc|Bros|Pty|Prof|Ing|Arch|Mons|Card|Pres|Gov|Lt|Col|Capt|Sgt|[A-Z])';
/** Sentence end, but not after an abbreviation or an initial. */
const SPLIT = new RegExp(`(?<=[.!?])(?<!\\b${ABBR}\\.)\\s+(?=[A-ZÀ-Þ0-9"«“¿¡])`);
/** A text that stops at an abbreviation ("86 av. J.-C." / "a. C." / "B.C." end a sentence). */
const ERA = /(?:J\.-C|a\. ?C|d\. ?C|v\. ?Chr|n\. ?Chr|B\. ?C|A\. ?D|a\.C|d\.C|C\. ?E)\.$/;
const CUT = { test: (s) => new RegExp(`\\b${ABBR}\\.$`).test(s) && !ERA.test(s) };

/** Same as build_about.js clean(), with the abbreviation-aware split. */
function clean(text) {
  if (!text) return null;
  let t = text.split('\n').map((s) => s.trim()).filter((s) => s.length > 40).slice(0, 2).join(' ');
  for (let k = 0; k < 3; k++) t = t.replace(/\s*[(（][^()（）]*[)）]/g, '');
  t = t.replace(/\s*\[[^\]]*\]/g, '').replace(/\s+([,.;:])/g, '$1').replace(/\s{2,}/g, ' ').trim();
  if (t.length < 60) return null;
  let out = '';
  let n = 0;
  for (const p of t.split(SPLIT)) {
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

/** --write: attractions/{id}.about.{lang} = text for every line of --out. */
async function write() {
  const path = require('path');
  const admin = require(path.join(__dirname, '../../functions/node_modules/firebase-admin'));
  admin.initializeApp({ projectId: 'greengo-chat' });
  const db = admin.firestore();
  const bw = db.bulkWriter();
  let failed = 0;
  bw.onWriteError((e) => {
    if (e.failedAttempts < 5) return true;
    failed++;
    return false;
  });
  const xs = fs.readFileSync(arg('--out'), 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l));
  for (const x of xs) bw.update(db.collection('attractions').doc(x.id), { [`about.${x.lang}`]: x.text });
  await bw.close();
  console.log(`WRITE DONE ${xs.length}, failed ${failed}`);
}

function main() {
  if (process.argv.includes('--write')) return write().then(() => process.exit(0));
  const ex = new Map();
  for (const l of fs.readFileSync(arg('--extracts'), 'utf8').split('\n')) {
    if (!l) continue;
    try {
      const o = JSON.parse(l);
      ex.set(`${o.w}|${o.t}`, o.x);
    } catch (_) { /* partial line */ }
  }
  const out = [];
  const stats = { cut: 0, repaired: 0, noExtract: 0, notPrefix: 0 };
  for (const l of fs.readFileSync(arg('--source'), 'utf8').split('\n')) {
    if (!l) continue;
    const r = JSON.parse(l);
    const srcs = r.aboutSources || {};
    for (const [w, txt] of Object.entries(r.about || {})) {
      if (typeof txt !== 'string' || !CUT.test(txt)) continue;
      stats.cut++;
      const url = srcs[w] || '';
      const title = decodeURIComponent(url.split('/wiki/')[1] || '').replace(/_/g, ' ');
      const raw = ex.get(`${w === 'pt_BR' ? 'pt' : w}|${title}`);
      if (!raw) { stats.noExtract++; continue; }
      const t = clean(raw);
      if (!t || t === txt || CUT.test(t) || !t.startsWith(txt)) { stats.notPrefix++; continue; }
      stats.repaired++;
      out.push({ id: r._doc, lang: w, old: txt, text: t });
    }
  }
  fs.writeFileSync(arg('--out', 'about_cut_fix.jsonl'), out.map((x) => JSON.stringify(x)).join('\n') + '\n');
  console.log(stats);
  for (const x of out.slice(0, 3)) console.log(`${x.id} ${x.lang}: ...${x.old.slice(-40)} => ${x.text.slice(x.old.length, x.old.length + 90)}`);
}

main();
