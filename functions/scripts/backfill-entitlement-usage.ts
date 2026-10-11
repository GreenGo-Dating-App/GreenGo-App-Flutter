/**
 * One-off backfill for the membership caps (audit 2026-10-11). DRY-RUN BY
 * DEFAULT. Idempotent.
 *
 * Run AFTER onEventWrittenUsage / onGroupWrittenUsage / onSupportChatCreated
 * are deployed and BEFORE the tightened Firestore rules go live, so users who
 * already have ongoing events / groups get their entitlement_usage/{uid}
 * counters (otherwise their first create after the rules deploy is accepted
 * by the rules and only then removed again by the trigger), and existing
 * support tickets get their queue rank (priorityRank).
 *
 *   - events with endDate > now  -> recountEvents(organizerId)
 *   - groups                     -> entitlement_usage.groupsCreated per creator
 *   - support_chats w/o priorityRank -> priority fields from the owner's tier
 *   - CHECK (read-only, always): paid / Base members whose end date is not a
 *     Timestamp or epoch millis. The rules fail closed on such a value (an ISO
 *     string), so these users would be treated as FREE / without Base by the
 *     tightened rules: fix them (Timestamp) before deploying the rules.
 *
 * Usage (from functions/):
 *   npx tsc --outDir scripts/.out --module commonjs --target es2019 \
 *     --esModuleInterop --skipLibCheck --resolveJsonModule scripts/backfill-entitlement-usage.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/sa.json GCLOUD_PROJECT=greengo-chat \
 *     node scripts/.out/scripts/backfill-entitlement-usage.js [--apply]
 */
import * as admin from 'firebase-admin';

if (!admin.apps.length) admin.initializeApp();

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { recountEvents, USAGE_COLLECTION } = require('../src/entitlements/usage');
// eslint-disable-next-line @typescript-eslint/no-var-requires
const { supportPriorityFields } = require('../src/admin/adminPanelFunctions');

const PAGE = 500;

async function main() {
  const db = admin.firestore();
  const apply = process.argv.includes('--apply');
  const out = { organizers: 0, groupCreators: 0, groups: 0, tickets: 0, badEndDates: [] as string[] };

  // ---- read-only check: end dates the rules cannot read
  const okDate = (v: unknown) => v instanceof admin.firestore.Timestamp || typeof v === 'number';
  const paid = await db.collection('profiles')
    .where('membershipTier', 'in', ['SILVER', 'GOLD', 'PLATINUM', 'silver', 'gold', 'platinum']).get();
  for (const d of paid.docs) {
    if (!okDate(d.get('membershipEndDate')) && d.get('isAdmin') !== true) out.badEndDates.push(`${d.id}:membershipEndDate`);
  }
  const base = await db.collection('profiles').where('hasBaseMembership', '==', true).get();
  for (const d of base.docs) {
    if (!okDate(d.get('baseMembershipEndDate'))) out.badEndDates.push(`${d.id}:baseMembershipEndDate`);
  }

  // ---- ongoing events -> organizers
  const organizers = new Set<string>();
  let last: admin.firestore.QueryDocumentSnapshot | undefined;
  for (;;) {
    let q = db.collection('events')
      .where('endDate', '>', admin.firestore.Timestamp.now())
      .orderBy('endDate')
      .select('organizerId')
      .limit(PAGE);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    for (const d of snap.docs) {
      const o = d.get('organizerId');
      if (typeof o === 'string' && o && !o.includes('/')) organizers.add(o);
    }
    if (snap.size < PAGE) break;
    last = snap.docs[snap.docs.length - 1];
  }
  out.organizers = organizers.size;
  if (apply) {
    for (const uid of organizers) await recountEvents(uid);
  }

  // ---- groups per creator
  const groupsBy = new Map<string, number>();
  last = undefined;
  for (;;) {
    let q = db.collection('groups').orderBy(admin.firestore.FieldPath.documentId()).select('createdBy').limit(PAGE);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    for (const d of snap.docs) {
      const c = d.get('createdBy');
      if (typeof c === 'string' && c && !c.includes('/')) groupsBy.set(c, (groupsBy.get(c) ?? 0) + 1);
      out.groups++;
    }
    if (snap.size < PAGE) break;
    last = snap.docs[snap.docs.length - 1];
  }
  out.groupCreators = groupsBy.size;
  if (apply) {
    let batch = db.batch();
    let n = 0;
    for (const [uid, count] of groupsBy) {
      batch.set(db.collection(USAGE_COLLECTION).doc(uid), {
        groupsCreated: count,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      if (++n % 400 === 0) { await batch.commit(); batch = db.batch(); }
    }
    await batch.commit();
  }

  // ---- support tickets without a queue rank
  last = undefined;
  for (;;) {
    let q = db.collection('support_chats').orderBy(admin.firestore.FieldPath.documentId()).limit(PAGE);
    if (last) q = q.startAfter(last);
    const snap = await q.get();
    for (const d of snap.docs) {
      const data = d.data();
      if (typeof data.priorityRank === 'number') continue;
      out.tickets++;
      if (apply) await d.ref.update(await supportPriorityFields(data.userId, data.priority));
    }
    if (snap.size < PAGE) break;
    last = snap.docs[snap.docs.length - 1];
  }

  console.log(`${apply ? 'APPLIED' : '[DRY RUN - pass --apply to write]'} ${JSON.stringify(out)}`);
}

if (require.main === module) main().catch((e) => { console.error(e); process.exit(1); });
