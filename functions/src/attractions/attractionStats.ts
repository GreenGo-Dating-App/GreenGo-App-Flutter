/**
 * Attraction page views — unique viewers per day.
 *
 * Attractions come from a curated static catalogue, so their stats live in a
 * separate collection: `attraction_stats/{attractionId}` { viewCount, updatedAt }.
 *
 * Opening an attraction page makes the client CREATE
 * `attraction_stats/{id}/daily_viewers/{YYYYMMDD}_{uid}` (create-only, the
 * rules pin the id to today's/yesterday's UTC date + the caller's uid). Each
 * such doc is one unique viewer-day, so this trigger simply adds one to the
 * public counter, which no client may write. Bounded: one tiny write per
 * user/day/attraction.
 */
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

const db = admin.firestore();

export const onAttractionViewRecorded = onDocumentCreated(
  {
    document: 'attraction_stats/{attractionId}/daily_viewers/{viewId}',
    memory: '512MiB',
  },
  monitored('onAttractionViewRecorded', async (event) => {
    const attractionId = event.params.attractionId as string;
    if (!/^[0-9]{1,12}$/.test(attractionId)) return;
    await db.collection('attraction_stats').doc(attractionId).set(
      {
        viewCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }),
);
