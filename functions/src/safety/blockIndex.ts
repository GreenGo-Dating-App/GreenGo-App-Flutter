/**
 * Deterministic block index (INC-2026-001, docs/security/profiles-rules-lockdown.md §3).
 *
 * Blocks live in `blockedUsers/{randomId}` = {blockerId, blockedUserId}. Rules
 * can only call exists() on a KNOWN path, so this keeps
 * `block_index/{blockerId}_{blockedUserId}` in step; the profiles `get` rule
 * denies a blocked user opening the blocker's profile. Clients can neither
 * read nor write block_index (rules: if false).
 *
 * Duplicate block docs for one pair are possible (each block creates a new
 * doc), so a deletion removes the index only when no other block doc for the
 * pair is left.
 *
 * Deploy: syncBlockIndex. Backfill: scripts/backfill-block-index.ts.
 */
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';

export const BLOCK_INDEX = 'block_index';

type Pair = { blockerId: string; blockedUserId: string };

const validId = (v: unknown): v is string =>
  typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/');

export function pairOf(data: any): Pair | null {
  const blockerId = data?.blockerId;
  const blockedUserId = data?.blockedUserId;
  if (!validId(blockerId) || !validId(blockedUserId) || blockerId === blockedUserId) return null;
  return { blockerId, blockedUserId };
}

export const blockIndexId = (p: Pair) => `${p.blockerId}_${p.blockedUserId}`;

export async function applyBlockIndexChange(
  before: any,
  after: any,
  fs: admin.firestore.Firestore = admin.firestore(),
): Promise<{ set: string | null; deleted: string | null }> {
  const b = pairOf(before);
  const a = pairOf(after);
  let set: string | null = null;
  let deleted: string | null = null;
  if (a) {
    set = blockIndexId(a);
    await fs.collection(BLOCK_INDEX).doc(set).set({
      blockerId: a.blockerId,
      blockedUserId: a.blockedUserId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  if (b && (!a || blockIndexId(a) !== blockIndexId(b))) {
    const left = await fs.collection('blockedUsers')
      .where('blockerId', '==', b.blockerId)
      .where('blockedUserId', '==', b.blockedUserId)
      .limit(1)
      .get();
    if (left.empty) {
      deleted = blockIndexId(b);
      await fs.collection(BLOCK_INDEX).doc(deleted).delete();
    }
  }
  return { set, deleted };
}

export const syncBlockIndex = onDocumentWritten(
  { document: 'blockedUsers/{blockId}', memory: '512MiB' },
  async (event) => {
    const before = event.data?.before?.exists ? event.data.before.data() : undefined;
    const after = event.data?.after?.exists ? event.data.after.data() : undefined;
    await applyBlockIndexChange(before, after);
  },
);

/**
 * Backfill core: scans blockedUsers in document-id order and writes the index
 * doc of every valid pair (idempotent; re-run from scratch is always correct).
 */
export async function runBlockIndexBackfill(
  opts: { firestore?: admin.firestore.Firestore; pageSize?: number; apply?: boolean } = {},
): Promise<{ scanned: number; indexed: number }> {
  const fs = opts.firestore ?? admin.firestore();
  const pageSize = Math.min(opts.pageSize ?? 400, 450);
  let cursor: string | null = null;
  let scanned = 0;
  let indexed = 0;
  for (;;) {
    let q = fs.collection('blockedUsers').orderBy(admin.firestore.FieldPath.documentId()).limit(pageSize);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.get();
    if (snap.empty) break;
    const batch = fs.batch();
    for (const d of snap.docs) {
      const p = pairOf(d.data());
      if (!p) continue;
      indexed++;
      batch.set(fs.collection(BLOCK_INDEX).doc(blockIndexId(p)), {
        blockerId: p.blockerId,
        blockedUserId: p.blockedUserId,
        createdAt: d.data().blockedAt ?? admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    if (opts.apply !== false) await batch.commit();
    scanned += snap.size;
    cursor = snap.docs[snap.docs.length - 1].id;
    if (snap.size < pageSize) break;
  }
  return { scanned, indexed };
}
