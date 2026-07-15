/**
 * Group cascade cleanup (NEW, isolated module).
 *
 * When a group doc is deleted (an admin permanently deletes the group from the
 * client — the client can only delete the top-level `groups/{groupId}` doc,
 * since security rules scope the members/messages subcollections to their own
 * owner/sender), this trigger recursively removes the orphaned subcollections
 * (members, messages) plus each member's private inbox thread, using the Admin
 * SDK (which bypasses rules).
 */

import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

const db = admin.firestore();
const PAGE = 400;

async function deleteCollection(
  ref: admin.firestore.CollectionReference,
): Promise<void> {
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const snap = await ref.limit(PAGE).get();
    if (snap.empty) break;
    const batch = db.batch();
    for (const d of snap.docs) batch.delete(d.ref);
    await batch.commit();
    if (snap.size < PAGE) break;
  }
}

export const onGroupDeleted = onDocumentDeleted(
  'groups/{groupId}',
  monitored('onGroupDeleted', async (event) => {
    const groupId = event.params.groupId as string;
    const before = event.data?.data() || {};
    const groupRef = db.collection('groups').doc(groupId);

    // Subcollections under the (now-deleted) group doc.
    await deleteCollection(groupRef.collection('members'));
    await deleteCollection(groupRef.collection('messages'));

    // Each participant's private inbox thread for this group.
    const participants = Array.isArray(before.participants)
      ? (before.participants as string[])
      : [];
    for (let i = 0; i < participants.length; i += PAGE) {
      const chunk = participants.slice(i, i + PAGE);
      const batch = db.batch();
      for (const uid of chunk) {
        batch.delete(
          db
            .collection('user_group_inbox')
            .doc(uid)
            .collection('threads')
            .doc(groupId),
        );
      }
      await batch.commit();
    }

    console.log(`onGroupDeleted: cleaned up group ${groupId}`);
  }),
);
