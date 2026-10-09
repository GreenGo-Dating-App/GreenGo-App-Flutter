/**
 * One-off backfill of block_index/{blockerId}_{blockedUserId} from
 * blockedUsers (INC-2026-001, lockdown doc §3). DRY-RUN BY DEFAULT.
 * Run AFTER syncBlockIndex is deployed, BEFORE the lockdown rules go live
 * (the profiles `get` rule reads block_index). Idempotent.
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-block-index.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/backfill-block-index.js [--apply]
 */
import * as admin from 'firebase-admin';
import { runBlockIndexBackfill } from '../src/safety/blockIndex';

async function main() {
  if (!admin.apps.length) admin.initializeApp();
  const apply = process.argv.includes('--apply');
  const r = await runBlockIndexBackfill({ apply });
  console.log(`${apply ? 'APPLIED' : '[DRY RUN - pass --apply to write]'} scanned=${r.scanned} indexed=${r.indexed}`);
}

if (require.main === module) main().catch((e) => { console.error(e); process.exit(1); });
