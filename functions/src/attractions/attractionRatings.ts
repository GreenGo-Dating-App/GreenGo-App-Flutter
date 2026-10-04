/**
 * Attraction user ratings → server-owned aggregate on `attraction_stats`.
 *
 * Users rate a catalogue attraction from its detail page by writing their OWN
 * doc `attraction_ratings/{attractionId}/ratings/{uid}` { stars 1..5,
 * createdAt, updatedAt } (create / change / delete; the rules pin the doc id
 * to the caller's uid). No client may write the aggregate fields
 * (ratingSum / ratingCount / ratingAvg / ratingDist / ratingUpdatedAt); this
 * trigger maintains them exactly once per write event — see
 * attractionRatingAggregate.ts for the model.
 *
 * RETRIES are on: a dropped event (cold-start OOM, contention) would leave the
 * aggregate permanently off. Safe because every event id is claimed in the
 * same transaction that applies its delta.
 */
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';
import { RatingAggregateDeps, applyRatingEvent } from './attractionRatingAggregate';

const db = admin.firestore();

const deps: RatingAggregateDeps = {
  db,
  serverTimestamp: () => admin.firestore.FieldValue.serverTimestamp(),
};

export const onAttractionRatingWritten = onDocumentWritten(
  {
    document: 'attraction_ratings/{attractionId}/ratings/{uid}',
    memory: '512MiB',
    retry: true,
  },
  monitored('onAttractionRatingWritten', async (event) => {
    const attractionId = event.params.attractionId as string;
    const before = event.data?.before?.exists ? event.data.before.data() : undefined;
    const after = event.data?.after?.exists ? event.data.after.data() : undefined;
    await applyRatingEvent(deps, event.id, attractionId, before?.stars, after?.stars);
  }),
);
