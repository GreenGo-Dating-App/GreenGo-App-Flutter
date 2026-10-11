/**
 * One-off backfill for the personal payment links tier rule (owner rule
 * 2026-10-12, functions/src/profiles/paymentLinksVisibility.ts).
 * DRY-RUN BY DEFAULT: without --apply the script only runs READ queries and
 * never calls a write API (every write goes through syncPaymentLinksVisibility,
 * which is reachable only behind the `apply` flag below).
 *
 * For every public profile that carries at least one payment link:
 *   - effective tier FREE (expired / Base-only / never paid)  -> HIDE: links
 *     moved to profiles_private/{uid}.paymentLinksHidden, public field deleted;
 *   - effective tier SILVER / GOLD / PLATINUM                 -> keep, set
 *     paymentLinksExpireAt (= membershipEndDate) so sweepExpiredPaymentLinks
 *     hides them when the tier lapses;
 *   - TEST / admin                                            -> keep, no marker.
 *
 * Candidates are found with one indexed range query per provider key
 * (`paymentLinks.<key> > ''`, automatic single-field indexes on map
 * subfields), not a scan of every profile. Re-runnable: each run re-queries
 * the source; already-correct profiles are no-ops.
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-payment-links-visibility.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/backfill-payment-links-visibility.js [--apply] [--page-size 300]
 */
import * as admin from 'firebase-admin';
import { effectiveTier } from '../src/shared/effectiveTier';
import {
  PAYMENT_LINKS_FIELD,
  cleanLinks,
  desiredExpireAt,
  syncPaymentLinksVisibility,
} from '../src/profiles/paymentLinksVisibility';

/** PaymentMethod keys (lib/features/profile/domain/entities/payment_links.dart). */
export const PAYMENT_LINK_KEYS = ['pix', 'mercadoPago', 'picPay', 'paypal', 'venmo', 'cashApp',
  'revolut', 'wise', 'monzo', 'kofi', 'stripe'] as const;

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

export type Plan = 'hide' | 'set_expiry' | 'keep';

export function planFor(pub: Record<string, any>, now: Date): Plan {
  if (!cleanLinks(pub[PAYMENT_LINKS_FIELD])) return 'keep';
  if (effectiveTier(pub, now) === 'FREE') return 'hide';
  const want = desiredExpireAt(pub, now);
  const have = pub.paymentLinksExpireAt;
  const same = want === null
    ? have === undefined
    : have instanceof admin.firestore.Timestamp && have.toMillis() === want.toMillis();
  return same ? 'keep' : 'set_expiry';
}

/** Uids of every profile with at least one non-empty link value. Read-only. */
export async function findCandidates(fs: admin.firestore.Firestore, pageSize: number): Promise<Set<string>> {
  const uids = new Set<string>();
  for (const key of PAYMENT_LINK_KEYS) {
    const field = `${PAYMENT_LINKS_FIELD}.${key}`;
    let cursor: admin.firestore.QueryDocumentSnapshot | null = null;
    for (;;) {
      let q = fs.collection('profiles').where(field, '>', '').orderBy(field).limit(pageSize);
      if (cursor) q = q.startAfter(cursor);
      const snap = await q.get();
      snap.docs.forEach((d) => uids.add(d.id));
      if (snap.size < pageSize) break;
      cursor = snap.docs[snap.docs.length - 1];
    }
  }
  return uids;
}

export async function run(fs: admin.firestore.Firestore, apply: boolean, pageSize = 300) {
  const now = new Date();
  const candidates = await findCandidates(fs, pageSize);
  const counts = {
    mode: apply ? 'APPLY' : 'DRY-RUN',
    profilesWithLinks: candidates.size,
    hide: 0,
    setExpiry: 0,
    keep: 0,
    byEffectiveTier: {} as Record<string, number>,
    hiddenByStoredTier: {} as Record<string, number>,
    applied: { hidden: 0, expiryUpdated: 0, restored: 0, noop: 0, failed: 0 },
  };
  const ids = [...candidates];
  for (let i = 0; i < ids.length; i += 100) {
    const refs = ids.slice(i, i + 100).map((id) => fs.collection('profiles').doc(id));
    const snaps = await fs.getAll(...refs);
    for (const s of snaps) {
      if (!s.exists) continue;
      const pub = s.data() || {};
      const eff = effectiveTier(pub, now);
      counts.byEffectiveTier[eff] = (counts.byEffectiveTier[eff] || 0) + 1;
      const plan = planFor(pub, now);
      if (plan === 'hide') {
        counts.hide++;
        const stored = String(pub.membershipTier ?? '(none)');
        counts.hiddenByStoredTier[stored] = (counts.hiddenByStoredTier[stored] || 0) + 1;
      } else if (plan === 'set_expiry') counts.setExpiry++;
      else counts.keep++;

      if (!apply || plan === 'keep') continue;
      try {
        const out = await syncPaymentLinksVisibility(s.id, { firestore: fs, now });
        if (out === 'hidden') counts.applied.hidden++;
        else if (out === 'expiry_updated') counts.applied.expiryUpdated++;
        else if (out === 'restored') counts.applied.restored++;
        else counts.applied.noop++;
      } catch (e: any) {
        counts.applied.failed++;
        console.error(`failed ${s.id}: ${e?.message || e}`);
      }
    }
  }
  return counts;
}

if (require.main === module) {
  const apply = process.argv.includes('--apply');
  const pageSize = Math.min(Number(arg('--page-size') || 300), 500);
  if (!admin.apps.length) admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'greengo-chat' });
  run(admin.firestore(), apply, pageSize)
    .then((c) => {
      console.log(JSON.stringify(c, null, 2));
      process.exit(0);
    })
    .catch((e) => {
      console.error(e);
      process.exit(1);
    });
}
