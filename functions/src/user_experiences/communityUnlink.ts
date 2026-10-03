/**
 * Community deleted → its experiences are KEPT (they belong to their hosts,
 * with their bookings and reviews) and simply unlinked: `communityId` and
 * `communityName` are removed so they no longer point at a missing community.
 *
 * Scale: pages of UNLINK_PAGE docs, one batched write per page. The query is
 * re-run from the source each round (each round consumes what it matched, so
 * an offset would skip docs) and bounded by MAX_ROUNDS.
 */
import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';

export const UNLINK_PAGE = 400;
export const MAX_ROUNDS = 250; // 100k linked experiences per deleted community

/** Unlinks every experience of [communityId]; returns how many were updated. */
export async function unlinkCommunityExperiences(
  db: admin.firestore.Firestore,
  communityId: string,
  pageSize = UNLINK_PAGE,
): Promise<number> {
  let total = 0;
  for (let round = 0; round < MAX_ROUNDS; round++) {
    const snap = await db
      .collection('user_experiences')
      .where('communityId', '==', communityId)
      .limit(pageSize)
      .get();
    if (snap.empty) break;
    const batch = db.batch();
    for (const d of snap.docs) {
      batch.update(d.ref, {
        communityId: admin.firestore.FieldValue.delete(),
        communityName: admin.firestore.FieldValue.delete(),
      });
    }
    await batch.commit();
    total += snap.size;
    if (snap.size < pageSize) break;
  }
  return total;
}

export const onCommunityDeletedUnlinkExperiences = onDocumentDeleted(
  { document: 'communities/{communityId}', memory: '512MiB', timeoutSeconds: 300 },
  async (event) => {
    const { communityId } = event.params;
    try {
      const n = await unlinkCommunityExperiences(admin.firestore(), communityId);
      if (n > 0) console.log(`community ${communityId} deleted: unlinked ${n} experiences`);
    } catch (e) {
      console.error(`unlink experiences of deleted community ${communityId} failed:`, e);
      throw e; // let the retry policy (if enabled) re-run it; idempotent
    }
  },
);
