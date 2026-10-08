/**
 * Removes the sensitive fields from PUBLIC profiles/{uid} (audit C-07 / C-10,
 * plan P1-4). DRY-RUN BY DEFAULT: pass --apply to write.
 *
 * ONLY RUN WHEN ALL OF THESE HOLD (coordinator):
 *   1. mirrorPrivateProfileFields + syncCoarseFromPrivateProfile are deployed;
 *   2. scripts/backfill-profiles-private.ts finished (done=true);
 *   3. app_config/version.minVersion forces the app version that reads its own
 *      sensitive data from profiles_private and others' from geohash5 /
 *      approxLocation / age (older versions read these public fields);
 *   4. the admin panel reads the ID selfie via getVerificationPhotoUrl and
 *      DOB/email from profiles_private (not from the public profile).
 * After it, deploy the lockdown rules in docs/security/profiles-rules-lockdown.md
 * so nobody can write the fields back.
 *
 * Per doc, ONE transaction: copy any value private is still missing into
 * profiles_private (never overwriting a newer private value), then delete the
 * public copies with FieldValue.delete(). The mirror trigger never propagates
 * a deletion, so private data survives. Re-runnable: it re-queries the source
 * each time; docs with nothing left to strip are only read.
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/strip-public-sensitive-fields.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/strip-public-sensitive-fields.js [--apply] \
 *     [--page-size 300] [--start-after <uid>] [--max-pages N]
 */
import * as admin from 'firebase-admin';
import {
  PRIVATE_PROFILES, SENSITIVE_FIELDS, getPath, nestedFromPaths, privateCopyUpdates,
} from '../src/profiles/privateProfile';

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

export async function stripOne(fs: admin.firestore.Firestore, uid: string, apply: boolean): Promise<string[]> {
  return fs.runTransaction(async (tx) => {
    const pubRef = fs.collection('profiles').doc(uid);
    const privRef = fs.collection(PRIVATE_PROFILES).doc(uid);
    const [pubSnap, privSnap] = await tx.getAll(pubRef, privRef);
    if (!pubSnap.exists) return [];
    const pub = pubSnap.data() ?? {};
    const present = SENSITIVE_FIELDS.filter((f) => getPath(pub, f.pub) !== undefined);
    if (!present.length) return [];
    const missing = privateCopyUpdates(pub, privSnap.data() ?? {}, present, true);
    if (apply) {
      if (Object.keys(missing).length) tx.set(privRef, nestedFromPaths(missing), { merge: true });
      const del: Record<string, any> = {};
      for (const f of present) del[f.pub] = admin.firestore.FieldValue.delete();
      tx.update(pubRef, del);
    }
    return present.map((f) => f.pub);
  });
}

async function main() {
  if (!admin.apps.length) admin.initializeApp();
  const fs = admin.firestore();
  const apply = process.argv.includes('--apply');
  const pageSize = Math.min(Number(arg('--page-size') ?? 300), 400);
  const maxPages = Number(arg('--max-pages') ?? Number.MAX_SAFE_INTEGER);
  let cursor: string | null = arg('--start-after') ?? null;
  let scanned = 0, stripped = 0, pages = 0;
  const counts: Record<string, number> = {};
  for (;;) {
    let q = fs.collection('profiles').orderBy(admin.firestore.FieldPath.documentId()).limit(pageSize);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.select().get();
    if (snap.empty) break;
    for (let i = 0; i < snap.docs.length; i += 10) {
      const res = await Promise.all(snap.docs.slice(i, i + 10).map((d) => stripOne(fs, d.id, apply)));
      for (const fields of res) {
        if (fields.length) stripped++;
        for (const f of fields) counts[f] = (counts[f] ?? 0) + 1;
      }
    }
    scanned += snap.size;
    cursor = snap.docs[snap.docs.length - 1].id;
    pages++;
    console.log(`scanned=${scanned} ${apply ? 'stripped' : 'would strip'}=${stripped} lastId=${cursor}`);
    if (snap.size < pageSize || pages >= maxPages) break;
  }
  console.log(`${apply ? 'APPLIED' : '[DRY RUN - pass --apply to write]'} scanned=${scanned} docs=${stripped}`);
  console.log(JSON.stringify(counts, null, 2));
}

if (require.main === module) main().catch((e) => { console.error(e); process.exit(1); });
