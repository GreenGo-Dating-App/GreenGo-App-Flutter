/**
 * INC-2026-001 residual: removes the account email (and any other non
 * allow-listed field) from the PUBLIC `nicknames/{nick}` mapping docs.
 * DRY-RUN BY DEFAULT: pass --apply to write.
 *
 * `nicknames/{nick}` is readable by anyone (`allow get: if true`) so the app
 * can check a nickname without signing in. It used to hold `{email, uid}`,
 * which let anyone who knew a nickname read the account email. Nickname
 * sign-in now runs on the server (signInWithNickname), so the email is no
 * longer needed there. After this script every doc holds only
 * `{uid, nickname, createdAt}` (createdAt only where it already existed;
 * `nickname` is filled from the doc id where missing).
 *
 * RUN ORDER (coordinator):
 *   1. deploy the `signInWithNickname` function (and the rules allow-list);
 *   2. deploy the web build that signs in by nickname through the function
 *      (mobile: the app version that does the same, forced via minVersion);
 *   3. run this script with --apply.
 * App versions <= 4.6.0+195 resolve nickname -> email on the client: after
 * step 3 their NICKNAME sign-in fails ("No account found"); email sign-in
 * keeps working.
 *
 * Per doc, one transaction: re-read, delete every key outside the
 * allow-list, add `nickname` = doc id if missing. Re-runnable: it re-queries
 * the source every time; clean docs are only read.
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/strip-nickname-emails.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/strip-nickname-emails.js [--apply] \
 *     [--page-size 300] [--start-after <nick>] [--max-pages N]
 *
 * Output never prints an email: only counts and doc ids (nicknames, public).
 */
import * as admin from 'firebase-admin';

export const NICKNAME_ALLOWED_KEYS = ['uid', 'nickname', 'createdAt'] as const;

function arg(name: string): string | undefined {
  const i = process.argv.indexOf(name);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

/** Strips one doc. Returns the keys removed (+ 'nickname+' when it was added). */
export async function stripNicknameDoc(
  fs: admin.firestore.Firestore,
  nick: string,
  apply: boolean,
): Promise<string[]> {
  const ref = fs.collection('nicknames').doc(nick);
  return fs.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return [];
    const d = snap.data() ?? {};
    const removed = Object.keys(d).filter((k) => !(NICKNAME_ALLOWED_KEYS as readonly string[]).includes(k));
    const upd: Record<string, any> = {};
    for (const k of removed) upd[k] = admin.firestore.FieldValue.delete();
    const changes = [...removed];
    if (typeof d.nickname !== 'string' || !d.nickname) {
      upd.nickname = nick;
      changes.push('nickname+');
    }
    if (apply && changes.length) tx.update(ref, upd);
    return changes;
  });
}

async function main() {
  if (!admin.apps.length) admin.initializeApp();
  const fs = admin.firestore();
  const apply = process.argv.includes('--apply');
  const pageSize = Math.min(Number(arg('--page-size') ?? 300), 400);
  const maxPages = Number(arg('--max-pages') ?? Number.MAX_SAFE_INTEGER);
  let cursor: string | null = arg('--start-after') ?? null;
  let scanned = 0, changed = 0, pages = 0, noUid = 0;
  const counts: Record<string, number> = {};
  for (;;) {
    let q = fs.collection('nicknames').orderBy(admin.firestore.FieldPath.documentId()).limit(pageSize);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.select('uid').get();
    if (snap.empty) break;
    for (const d of snap.docs) if (typeof d.get('uid') !== 'string') noUid++;
    for (let i = 0; i < snap.docs.length; i += 10) {
      const res = await Promise.all(snap.docs.slice(i, i + 10).map((d) => stripNicknameDoc(fs, d.id, apply)));
      for (const keys of res) {
        if (keys.length) changed++;
        for (const k of keys) counts[k] = (counts[k] ?? 0) + 1;
      }
    }
    scanned += snap.size;
    cursor = snap.docs[snap.docs.length - 1].id;
    pages++;
    console.log(`scanned=${scanned} ${apply ? 'changed' : 'would change'}=${changed} lastId=${cursor}`);
    if (snap.size < pageSize || pages >= maxPages) break;
  }
  console.log(`${apply ? 'APPLIED' : '[DRY RUN - pass --apply to write]'} scanned=${scanned} docs=${changed} withoutUid=${noUid}`);
  console.log(JSON.stringify(counts, null, 2));
}

if (require.main === module) main().catch((e) => { console.error(e?.message || e); process.exit(1); });
