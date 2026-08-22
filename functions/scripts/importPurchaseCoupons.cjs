/**
 * One-shot bulk import of the purchase email list into the `coupons` collection.
 *
 * Each buyer gets one personal coupon:
 *   - code        = the part of their email before the "@", uppercased
 *                   (mario@gmail.com -> MARIO)
 *   - allowedEmail= their email, so only that account can redeem it
 *   - maxRedemptions = 1, so it works exactly once
 *   - grants      = the tier they bought, plus the base-membership bonus:
 *
 *       1 MONTH PLATINUM  ->  PLATINUM 30d  + BASE 90d
 *       GOLD 6 MONTHS     ->  GOLD    180d  + BASE 180d
 *       1 YEAR PLATINUM   ->  PLATINUM 365d + BASE 365d
 *
 * Written as plain JS (not TS) on purpose: `ts-node` is not installed in
 * functions/ and the npm registry is unreachable from this machine, so this
 * runs with the `firebase-admin` already in node_modules.
 *
 * Usage:
 *   node functions/scripts/importPurchaseCoupons.cjs <path/to/list.txt> [--dry-run] [--commit]
 *
 *   --dry-run   parse + plan only, touches no network and no credentials (default)
 *   --commit    actually write to Firestore
 *
 * Credentials (only needed with --commit) — either:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 *   or an existing `gcloud auth application-default login` session.
 *
 * Idempotent: a coupon whose `code` already exists is updated in place. Its
 * `redemptionsCount`, `createdAt` and redemption history are never reset, so
 * re-running can't hand anyone a second redemption.
 */

const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'greengo-chat';

// Mirrors functions/src/coupons/grants.ts — the server rejects anything else.
const VALID_DURATIONS_DAYS = [7, 14, 30, 60, 90, 180, 365];
const TIER_RANK = { BASIC: 0, SILVER: 1, GOLD: 2, PLATINUM: 3 };
const TIER_WORDS = new Set(['SILVER', 'GOLD', 'PLATINUM']);

/** Base-membership bonus owed for a given purchased duration. */
function baseBonusDays(purchasedDays) {
  // A 1-month buyer gets 3 months of base; longer purchases get base for the
  // same span they bought.
  if (purchasedDays <= 30) return 90;
  return purchasedDays;
}

// ── Parsing (same file shape importEmailWhitelist.ts reads) ──────────────────

function parseDuration(words) {
  for (let i = 0; i < words.length - 1; i++) {
    const n = parseInt(words[i], 10);
    if (Number.isNaN(n)) continue;
    const unit = words[i + 1];
    if (unit === 'YEAR' || unit === 'YEARS') return n * 365;
    if (unit === 'MONTH' || unit === 'MONTHS') return n === 1 ? 30 : n * 30;
  }
  return null;
}

function parseHeader(line) {
  const words = line.trim().toUpperCase().split(/\s+/);
  const tier = words.find((w) => TIER_WORDS.has(w));
  if (!tier) return null;
  const purchasedDays = parseDuration(words);
  if (purchasedDays === null) return null;
  return { tier, purchasedDays, label: line.trim() };
}

function extractEmail(line) {
  // First whitespace-separated token; trailing "=====> DONE" markers are ignored.
  const token = line.trim().split(/\s+/)[0];
  if (!token) return null;
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(token)) return null;
  return token.toLowerCase();
}

function parseFile(text) {
  const sections = [];
  let current = null;
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim();
    if (!line) continue;
    const header = parseHeader(line);
    if (header) {
      current = { ...header, emails: [] };
      sections.push(current);
      continue;
    }
    const email = extractEmail(line);
    if (!email) continue;
    if (!current) {
      throw new Error(`Email "${email}" appears before any tier header — refusing to guess.`);
    }
    current.emails.push(email);
  }
  return sections;
}

// ── Plan building ───────────────────────────────────────────────────────────

function codeForEmail(email) {
  return email.split('@')[0].toUpperCase();
}

/**
 * When one buyer appears under two headers, keep the longer purchase — it also
 * carries the larger base bonus. Tier rank only breaks ties on equal duration.
 * (GOLD 6 MONTHS beats 1 MONTH PLATINUM.)
 */
function isBetter(a, b) {
  if (a.purchasedDays !== b.purchasedDays) return a.purchasedDays > b.purchasedDays;
  return (TIER_RANK[a.tier] ?? 0) > (TIER_RANK[b.tier] ?? 0);
}

function buildPlan(sections, sourceName) {
  const byCode = new Map();
  const notes = [];
  let totalRows = 0;

  for (const section of sections) {
    const baseDays = baseBonusDays(section.purchasedDays);
    for (const d of [section.purchasedDays, baseDays]) {
      if (!VALID_DURATIONS_DAYS.includes(d)) {
        throw new Error(
          `Section "${section.label}" needs a ${d}-day grant, which the server rejects. ` +
            `Allowed: ${VALID_DURATIONS_DAYS.join(', ')}.`,
        );
      }
    }

    for (const email of section.emails) {
      totalRows++;
      const code = codeForEmail(email);
      if (code.length < 4 || code.length > 64) {
        throw new Error(`Email "${email}" yields code "${code}" (${code.length} chars); the app requires 4–64.`);
      }

      const candidate = {
        code,
        email,
        tier: section.tier,
        purchasedDays: section.purchasedDays,
        baseDays,
        sectionLabel: section.label,
      };

      const existing = byCode.get(code);
      if (!existing) {
        byCode.set(code, candidate);
        continue;
      }
      if (existing.email !== email) {
        // Two different buyers whose emails share a local part would collide on
        // one code. Nothing in the current list does this; bail rather than
        // silently give one person the other's coupon.
        throw new Error(
          `Code collision on "${code}": ${existing.email} and ${email} would share a coupon.`,
        );
      }
      if (isBetter(candidate, existing)) {
        notes.push(
          `${email}: listed under both "${existing.sectionLabel}" and "${candidate.sectionLabel}" — keeping the better one (${candidate.sectionLabel}).`,
        );
        byCode.set(code, candidate);
      } else if (isBetter(existing, candidate)) {
        notes.push(
          `${email}: listed under both "${existing.sectionLabel}" and "${candidate.sectionLabel}" — keeping the better one (${existing.sectionLabel}).`,
        );
      } else {
        notes.push(`${email}: duplicated inside "${existing.sectionLabel}" — imported once.`);
      }
    }
  }

  const coupons = [...byCode.values()].map((c) => ({
    ...c,
    grants: [
      { kind: 'membership', tier: c.tier, durationDays: c.purchasedDays },
      { kind: 'base_membership', durationDays: c.baseDays },
    ],
    notesText: `Purchase import (${c.sectionLabel}) from ${sourceName}`,
  }));

  return { coupons, totalRows, notes };
}

// ── Firestore write ─────────────────────────────────────────────────────────

async function commit(coupons) {
  const admin = require('firebase-admin');
  admin.initializeApp({ projectId: PROJECT_ID });
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  // One pass over the existing collection so we can tell create from update
  // without 234 individual queries.
  const existingByCode = new Map();
  const snap = await db.collection('coupons').select('code').get();
  snap.forEach((doc) => {
    const code = doc.get('code');
    if (code) existingByCode.set(String(code).toUpperCase(), doc.id);
  });
  console.log(`Existing coupons in ${PROJECT_ID}: ${snap.size}`);

  let created = 0;
  let updated = 0;
  let batch = db.batch();
  let inBatch = 0;

  for (const c of coupons) {
    // Shape matches upsertCoupon's bundle branch: `grants` supersedes the
    // legacy single-grant fields, which stay null.
    const payload = {
      code: c.code,
      type: null,
      tier: null,
      coinAmount: null,
      durationDays: null,
      grants: c.grants,
      maxRedemptions: 1,
      expiresAt: null,
      allowedEmail: c.email,
      autoGrantOnSignup: false,
      disabled: false,
      notes: c.notesText,
      updatedAt: now,
      updatedBy: 'importPurchaseCoupons.cjs',
    };

    const existingId = existingByCode.get(c.code);
    if (existingId) {
      // merge:true, and redemptionsCount/createdAt are deliberately absent so
      // an already-redeemed coupon is not reopened.
      batch.set(db.collection('coupons').doc(existingId), payload, { merge: true });
      updated++;
    } else {
      batch.set(db.collection('coupons').doc(), {
        ...payload,
        redemptionsCount: 0,
        createdAt: now,
        createdBy: 'importPurchaseCoupons.cjs',
      });
      created++;
    }

    if (++inBatch >= 400) {
      await batch.commit();
      batch = db.batch();
      inBatch = 0;
      process.stdout.write('.');
    }
  }
  if (inBatch > 0) await batch.commit();
  console.log('');
  return { created, updated };
}

// ── Entry point ─────────────────────────────────────────────────────────────

async function main() {
  const args = process.argv.slice(2);
  const filePath = args.find((a) => !a.startsWith('--'));
  const doCommit = args.includes('--commit');

  if (!filePath) {
    console.error('Usage: node functions/scripts/importPurchaseCoupons.cjs <list.txt> [--commit]');
    process.exit(1);
  }
  const abs = path.resolve(filePath);
  if (!fs.existsSync(abs)) {
    console.error(`File not found: ${abs}`);
    process.exit(1);
  }

  const sections = parseFile(fs.readFileSync(abs, 'utf8'));
  const { coupons, totalRows, notes } = buildPlan(sections, path.basename(abs));

  console.log(`Source: ${abs}`);
  for (const s of sections) {
    const b = baseBonusDays(s.purchasedDays);
    console.log(
      `  ${s.label.padEnd(20)} ${String(s.emails.length).padStart(4)} emails  ->  ${s.tier} +${s.purchasedDays}d · BASE +${b}d`,
    );
  }
  console.log(`Rows: ${totalRows} · unique coupons: ${coupons.length}`);
  if (notes.length) {
    console.log('Notes:');
    for (const n of notes) console.log(`  - ${n}`);
  }
  console.log(`Sample: ${coupons[0].code} -> ${coupons[0].email} · ${JSON.stringify(coupons[0].grants)}`);

  if (!doCommit) {
    console.log('\nDry run. Re-run with --commit to write to Firestore.');
    return;
  }

  const { created, updated } = await commit(coupons);
  console.log(`Done. created=${created} updated=${updated} total=${coupons.length}`);
}

main().catch((err) => {
  console.error('Import failed:', err.message || err);
  process.exit(1);
});
