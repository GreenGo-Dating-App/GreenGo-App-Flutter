/**
 * One-shot import of an email allowlist file into the `coupons` collection
 * as auto-grant signup coupons.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     npx ts-node functions/scripts/importEmailWhitelist.ts <path/to/file.txt>
 *
 * Input file format (header lines + email lines; flexible word order):
 *
 *   1 YEAR PLATINUM
 *
 *   alice@example.com
 *   bob@example.com
 *
 *   1 MONTH PLATINUM
 *
 *   carol@example.com
 *   ...
 *
 *   GOLD 6 MONTHS
 *
 *   dave@example.com
 *
 * Trailing markers like "  =====> DONE" are stripped.
 *
 * The script is idempotent — re-running skips emails that already have an
 * active SIGNUP-* coupon for the same tier + duration.
 */

import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';

interface Section {
  tier: 'SILVER' | 'GOLD' | 'PLATINUM';
  durationDays: number;
  emails: string[];
}

const TIER_WORDS = new Set(['SILVER', 'GOLD', 'PLATINUM']);

function parseDuration(words: string[]): number | null {
  // Find pattern: number + (YEAR|YEARS|MONTH|MONTHS)
  for (let i = 0; i < words.length - 1; i++) {
    const n = parseInt(words[i], 10);
    if (Number.isNaN(n)) continue;
    const unit = words[i + 1];
    if (unit === 'YEAR' || unit === 'YEARS') return n * 365;
    if (unit === 'MONTH' || unit === 'MONTHS') return n * 30;
  }
  return null;
}

function parseHeader(line: string): { tier: Section['tier']; durationDays: number } | null {
  const words = line.trim().toUpperCase().split(/\s+/);
  const tier = words.find((w) => TIER_WORDS.has(w)) as Section['tier'] | undefined;
  if (!tier) return null;
  const durationDays = parseDuration(words);
  if (durationDays === null) return null;
  return { tier, durationDays };
}

function extractEmail(line: string): string | null {
  // Take the first whitespace-separated token; ignore anything after.
  const token = line.trim().split(/\s+/)[0];
  if (!token) return null;
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(token)) return null;
  return token.toLowerCase();
}

function parseFile(text: string): Section[] {
  const lines = text.split(/\r?\n/);
  const sections: Section[] = [];
  let current: Section | null = null;
  for (const raw of lines) {
    const line = raw.trim();
    if (!line) continue;
    const header = parseHeader(line);
    if (header) {
      current = { ...header, emails: [] };
      sections.push(current);
      continue;
    }
    const email = extractEmail(line);
    if (email && current) current.emails.push(email);
  }
  return sections;
}

function randomCodeSuffix(length = 8): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let out = '';
  for (let i = 0; i < length; i++) out += chars[Math.floor(Math.random() * chars.length)];
  return out;
}

async function main() {
  const filePath = process.argv[2];
  if (!filePath) {
    console.error('Usage: ts-node importEmailWhitelist.ts <path/to/email-subscription.txt>');
    process.exit(1);
  }
  const abs = path.resolve(filePath);
  if (!fs.existsSync(abs)) {
    console.error(`File not found: ${abs}`);
    process.exit(1);
  }

  admin.initializeApp();
  const db = admin.firestore();

  const text = fs.readFileSync(abs, 'utf8');
  const sections = parseFile(text);

  let totalEmails = 0;
  let created = 0;
  let skipped = 0;

  for (const section of sections) {
    const seenInSection = new Set<string>();
    for (const email of section.emails) {
      if (seenInSection.has(email)) continue;
      seenInSection.add(email);
      totalEmails++;

      // Idempotency: skip if an active SIGNUP coupon already exists for this
      // email with the same tier + duration.
      const existing = await db
        .collection('coupons')
        .where('allowedEmail', '==', email)
        .where('tier', '==', section.tier)
        .where('durationDays', '==', section.durationDays)
        .where('disabled', '==', false)
        .limit(1)
        .get();
      if (!existing.empty) {
        skipped++;
        continue;
      }

      const now = admin.firestore.Timestamp.now();
      await db.collection('coupons').add({
        code: `SIGNUP-${section.tier}-${randomCodeSuffix()}`,
        type: 'membership',
        tier: section.tier,
        coinAmount: null,
        durationDays: section.durationDays,
        maxRedemptions: 1,
        redemptionsCount: 0,
        expiresAt: null,
        allowedEmail: email,
        autoGrantOnSignup: true,
        disabled: false,
        notes: `Imported from ${path.basename(abs)}`,
        createdAt: now,
        updatedAt: now,
        createdBy: 'importEmailWhitelist.ts',
      });
      created++;
    }
  }

  console.log(`Done. Sections: ${sections.length}, total emails: ${totalEmails}, created: ${created}, skipped: ${skipped}.`);
  process.exit(0);
}

main().catch((err) => {
  console.error('Import failed:', err);
  process.exit(1);
});
