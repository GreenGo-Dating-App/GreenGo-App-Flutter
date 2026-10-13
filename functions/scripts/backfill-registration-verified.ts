/**
 * One-off backfill: users whose REGISTRATION ID photo an admin approved
 * before onAdminVerificationAction existed get the "Verified" badge
 * (profiles.isAgeVerified). DRY-RUN BY DEFAULT. Idempotent.
 *
 * Trusted source only: the latest registration decision in admin_actions
 * (admins only) must be an approval AND the profile must still say approved.
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-registration-verified.ts
 *   GCLOUD_PROJECT=greengo-chat node scripts/.out/backfill-registration-verified.js (after npm run build) [--apply]
 */
import * as admin from 'firebase-admin';

if (!admin.apps.length) admin.initializeApp();

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { latestRegistrationReview } = require('../../lib/shared/registrationIdReview');
// eslint-disable-next-line @typescript-eslint/no-var-requires
const { verifiedPatchFor } = require('../../lib/admin/registrationIdVerified');

async function main() {
  const db = admin.firestore();
  const apply = process.argv.includes('--apply');
  const types = ['verification_approved', 'verification_rejected', 'verification_resubmission_requested', 'verification_status_set'];
  const byUser = new Map<string, Array<Record<string, unknown>>>();
  for (const t of types) {
    const snap = await db.collection('admin_actions').where('actionType', '==', t).get();
    for (const d of snap.docs) {
      const uid = d.get('targetUserId');
      if (typeof uid !== 'string' || !uid || uid.includes('/')) continue;
      const list = byUser.get(uid) ?? [];
      list.push(d.data());
      byUser.set(uid, list);
    }
  }
  let candidates = 0;
  let updated = 0;
  for (const [uid, actions] of byUser) {
    if (latestRegistrationReview(actions) !== 'approved') continue;
    candidates++;
    const ref = db.collection('profiles').doc(uid);
    const p = await ref.get();
    const patch = verifiedPatchFor('verification_approved', p.data());
    if (!patch) continue;
    updated++;
    console.log(`${apply ? 'SET' : 'would set'} verified: ${uid}`);
    if (apply) {
      await ref.update({ ...patch, idVerifiedAt: admin.firestore.FieldValue.serverTimestamp() });
    }
  }
  console.log(JSON.stringify({ usersWithDecisions: byUser.size, latestApproved: candidates, updated, apply }));
}

main().then(() => process.exit(0), (e) => { console.error(e); process.exit(1); });
