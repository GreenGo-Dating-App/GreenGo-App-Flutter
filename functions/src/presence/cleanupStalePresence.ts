/**
 * cleanupStalePresence — Scheduled Cloud Function
 *
 * Runs every 5 minutes. Queries profiles where `isOnline == true` and
 * `lastSeen` is older than 5 minutes, then sets `isOnline: false` via
 * batched writes. Does NOT update `lastSeen` — preserves the last
 * genuine activity timestamp.
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { db, chunk, logInfo, logError } from '../shared/utils';

const STALE_THRESHOLD_MINUTES = 5;
const BATCH_SIZE = 500;

export const cleanupStalePresence = onSchedule(
  {
    schedule: 'every 5 minutes',
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async () => {
    try {
      const cutoff = new Date(Date.now() - STALE_THRESHOLD_MINUTES * 60 * 1000);

      const staleSnapshot = await db
        .collection('profiles')
        .where('isOnline', '==', true)
        .where('lastSeen', '<', cutoff)
        .get();

      if (staleSnapshot.empty) {
        logInfo('cleanupStalePresence: No stale profiles found');
        return;
      }

      const staleDocs = staleSnapshot.docs;
      const batches = chunk(staleDocs, BATCH_SIZE);

      for (const batchDocs of batches) {
        const batch = db.batch();
        for (const doc of batchDocs) {
          batch.update(doc.ref, { isOnline: false });
        }
        await batch.commit();
      }

      logInfo(`cleanupStalePresence: Cleaned up ${staleDocs.length} stale profiles`);
    } catch (error) {
      logError('cleanupStalePresence: Failed to clean up stale profiles', error);
    }
  },
);
