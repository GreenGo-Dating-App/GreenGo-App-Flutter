/**
 * Community renamed by its creator (owner request 2026-10-21: the creator can
 * edit the community info) → the denormalised `communityName` on every
 * linked user_experiences/{id} follows ("Posted in <community>" chip).
 *
 * Only a real NAME change does any work (cover / description / rules edits
 * return before any read). Every other community surface (cards, detail,
 * joined list, announcement / event pushes, share preview) reads the
 * community doc live, so this is the only copy to refresh.
 *
 * Scale: keyset pages of RENAME_PAGE docs ordered by document id
 * (`startAfter` the last doc: the update does not remove a doc from the
 * query, so an id cursor is exact), one batched write per page, bounded by
 * MAX_ROUNDS. Idempotent: a doc already carrying the new name is skipped, so
 * a retried delivery rewrites nothing.
 */
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { communityDisplayName } from './communityLink';

export const RENAME_PAGE = 400;
export const MAX_ROUNDS = 250; // 100k linked experiences per community

/**
 * Sets `communityName` = [name] on every experience linked to [communityId];
 * returns how many docs were updated.
 */
export async function syncCommunityNameOnExperiences(
  db: admin.firestore.Firestore,
  communityId: string,
  name: string | null,
  pageSize = RENAME_PAGE,
): Promise<number> {
  let total = 0;
  let cursor: admin.firestore.QueryDocumentSnapshot | null = null;
  for (let round = 0; round < MAX_ROUNDS; round++) {
    let q = db
      .collection('user_experiences')
      .where('communityId', '==', communityId)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(pageSize);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.get();
    if (snap.empty) break;
    const batch = db.batch();
    let n = 0;
    for (const d of snap.docs) {
      if ((d.get('communityName') ?? null) === name) continue;
      batch.update(d.ref, {
        communityName: name === null ? admin.firestore.FieldValue.delete() : name,
      });
      n++;
    }
    if (n > 0) await batch.commit();
    total += n;
    cursor = snap.docs[snap.docs.length - 1];
    if (snap.size < pageSize) break;
  }
  return total;
}

export const onCommunityRenamedSyncExperiences = onDocumentUpdated(
  { document: 'communities/{communityId}', memory: '512MiB', timeoutSeconds: 300 },
  async (event) => {
    const { communityId } = event.params;
    const before = communityDisplayName(event.data?.before?.data());
    const after = communityDisplayName(event.data?.after?.data());
    if (before === after) return;
    try {
      const n = await syncCommunityNameOnExperiences(admin.firestore(), communityId, after);
      if (n > 0) console.log(`community ${communityId} renamed: updated ${n} experiences`);
    } catch (e) {
      console.error(`community ${communityId} rename sync failed:`, e);
      throw e; // idempotent; let the retry policy (if enabled) re-run it
    }
  },
);
