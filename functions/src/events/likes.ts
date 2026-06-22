/**
 * Maintains the denormalized `likeCount` on an event whenever a per-user like
 * doc is created or deleted under `events/{eventId}/likes/{userId}`.
 *
 * Scales to millions: the client only writes its own like doc; the count is
 * a single atomic FieldValue.increment here, and the "Popular" sort reads the
 * denormalized field (no fan-in reads). Isolated to the events feature — does
 * not touch any existing collection.
 */

import {
  onDocumentCreated,
  onDocumentDeleted,
} from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';

const db = admin.firestore();

async function bump(eventId: string, delta: number): Promise<void> {
  try {
    await db
      .collection('events')
      .doc(eventId)
      .set(
        { likeCount: admin.firestore.FieldValue.increment(delta) },
        { merge: true }
      );
  } catch (e) {
    console.error(`likeCount bump failed for ${eventId} (${delta}):`, e);
  }
}

export const onEventLikeCreated = onDocumentCreated(
  'events/{eventId}/likes/{userId}',
  async (event) => {
    await bump(event.params.eventId, 1);
  }
);

export const onEventLikeDeleted = onDocumentDeleted(
  'events/{eventId}/likes/{userId}',
  async (event) => {
    await bump(event.params.eventId, -1);
  }
);
