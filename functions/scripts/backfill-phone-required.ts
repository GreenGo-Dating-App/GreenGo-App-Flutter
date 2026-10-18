/**
 * One-off backfill of phone_required/{uid} for accounts created on/after
 * 16 Oct 2026 BEFORE onAuthUserCreatedPhoneRequired was deployed (owner rule
 * 2026-10-17: only new accounts must verify a phone; the rules read this
 * server-only marker). DRY-RUN BY DEFAULT. Idempotent. Older accounts are
 * never marked. Logs counts only (no phone numbers, no uids).
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-phone-required.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/backfill-phone-required.js [--apply]
 */
import * as admin from 'firebase-admin';
import { PHONE_REQUIRED, phoneRequiredFor } from '../src/shared/participation';

async function main() {
  if (!admin.apps.length) admin.initializeApp();
  const apply = process.argv.includes('--apply');
  const db = admin.firestore();
  let scanned = 0;
  let marked = 0;
  let withPhone = 0;
  let pageToken: string | undefined;
  do {
    const page = await admin.auth().listUsers(1000, pageToken);
    const batch = db.batch();
    let writes = 0;
    for (const u of page.users) {
      scanned++;
      const created = Date.parse(u.metadata.creationTime);
      if (!phoneRequiredFor(created)) continue;
      if (u.phoneNumber) withPhone++;
      marked++;
      if (apply) {
        batch.set(db.collection(PHONE_REQUIRED).doc(u.uid), { createdAtMs: created, reason: 'new_account' }, { merge: true });
        writes++;
      }
    }
    if (writes > 0) await batch.commit();
    pageToken = page.pageToken;
  } while (pageToken);
  console.log(`${apply ? 'APPLIED' : '[DRY RUN - pass --apply to write]'} scanned=${scanned} newAccounts=${marked} newWithPhone=${withPhone}`);
}

if (require.main === module) main().catch((e) => { console.error(e); process.exit(1); });
