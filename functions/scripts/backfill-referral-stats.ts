/**
 * One-off backfill of referral_stats/{ownerId} (invite-friends milestones) from
 * referral_redemptions, granting every milestone an inviter ALREADY reached
 * (5 -> 1 month Silver, 10 -> Gold, 20 -> Platinum), once. Idempotent; see
 * src/referral/referralBackfill.ts.
 *
 * DRY-RUN BY DEFAULT, and the dry run is enforced, not just intended: before
 * anything runs, every Firestore write entry point of the Admin SDK
 * (DocumentReference set/update/create/delete, CollectionReference.add,
 * WriteBatch.commit, Firestore.runTransaction/bulkWriter/recursiveDelete) is
 * replaced by a function that throws. Grants and notifications go through those
 * same entry points, so a dry run cannot write anything.
 *
 * Run AFTER redeemReferral (new version) is deployed.
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-referral-stats.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/backfill-referral-stats.js [--apply] [--json]
 */
import * as admin from 'firebase-admin';
import { runReferralStatsBackfill } from '../src/referral/referralBackfill';

const APPLY = process.argv.includes('--apply');

/** Makes every Firestore write throw (dry-run guarantee). */
export function installReadOnlyGuard(): void {
  const fs = admin.firestore;
  const deny = (what: string) => function denied(): never {
    throw new Error(`READ-ONLY dry run: ${what} is blocked (pass --apply to write)`);
  };
  const patch = (proto: any, names: string[], label: string) => {
    for (const n of names) {
      if (proto && typeof proto[n] === 'function') proto[n] = deny(`${label}.${n}`);
    }
  };
  patch(fs.DocumentReference.prototype, ['set', 'update', 'create', 'delete'], 'DocumentReference');
  patch(fs.CollectionReference.prototype, ['add'], 'CollectionReference');
  patch(fs.WriteBatch.prototype, ['commit', 'set', 'update', 'create', 'delete'], 'WriteBatch');
  patch(fs.Transaction.prototype, ['set', 'update', 'create', 'delete'], 'Transaction');
  patch(fs.Firestore.prototype, ['runTransaction', 'bulkWriter', 'recursiveDelete', 'batch'], 'Firestore');
}

async function main() {
  if (!admin.apps.length) admin.initializeApp();
  if (!APPLY) installReadOnlyGuard();
  // Module imports only DEFINE functions; the guard patches the prototypes, so
  // it covers every Firestore instance whenever it was created.
  const r = await runReferralStatsBackfill({ apply: APPLY });
  const withGrants = r.plans.filter((p: any) => p.toGrant.length);
  if (process.argv.includes('--json')) {
    console.log(JSON.stringify({ ...r, plans: withGrants }, null, 2));
  } else {
    for (const p of withGrants) {
      console.log(`${p.ownerId}: ${p.invitedCount} invitations (stored ${p.storedCount}), granted before [${p.alreadyGranted.join(',')}]`);
      for (const g of p.toGrant) {
        console.log(`   -> milestone ${g.count}: 1 month ${g.tier} => profile becomes ${g.predictedTier} until ${g.predictedEnd}`);
      }
    }
  }
  console.log(`${APPLY ? 'APPLIED' : '[DRY RUN - read-only, pass --apply to write]'} redemptions=${r.redemptionsScanned} inviters=${r.owners} invitersWithGrants=${r.ownersWithGrants} grants=${JSON.stringify(r.grants)} failures=${r.failures.length}`);
  for (const f of r.failures) console.log(`   FAILED ${f}`);
}

if (require.main === module) main().catch((e) => { console.error(e); process.exit(1); });
