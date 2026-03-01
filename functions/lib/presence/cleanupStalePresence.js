"use strict";
/**
 * cleanupStalePresence — Scheduled Cloud Function
 *
 * Runs every 5 minutes. Queries profiles where `isOnline == true` and
 * `lastSeen` is older than 5 minutes, then sets `isOnline: false` via
 * batched writes. Does NOT update `lastSeen` — preserves the last
 * genuine activity timestamp.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.cleanupStalePresence = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const utils_1 = require("../shared/utils");
const STALE_THRESHOLD_MINUTES = 5;
const BATCH_SIZE = 500;
exports.cleanupStalePresence = (0, scheduler_1.onSchedule)({
    schedule: 'every 5 minutes',
    memory: '256MiB',
    timeoutSeconds: 60,
}, async () => {
    try {
        const cutoff = new Date(Date.now() - STALE_THRESHOLD_MINUTES * 60 * 1000);
        const staleSnapshot = await utils_1.db
            .collection('profiles')
            .where('isOnline', '==', true)
            .where('lastSeen', '<', cutoff)
            .get();
        if (staleSnapshot.empty) {
            (0, utils_1.logInfo)('cleanupStalePresence: No stale profiles found');
            return;
        }
        const staleDocs = staleSnapshot.docs;
        const batches = (0, utils_1.chunk)(staleDocs, BATCH_SIZE);
        for (const batchDocs of batches) {
            const batch = utils_1.db.batch();
            for (const doc of batchDocs) {
                batch.update(doc.ref, { isOnline: false });
            }
            await batch.commit();
        }
        (0, utils_1.logInfo)(`cleanupStalePresence: Cleaned up ${staleDocs.length} stale profiles`);
    }
    catch (error) {
        (0, utils_1.logError)('cleanupStalePresence: Failed to clean up stale profiles', error);
    }
});
//# sourceMappingURL=cleanupStalePresence.js.map