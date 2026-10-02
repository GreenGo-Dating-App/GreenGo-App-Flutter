/**
 * backfillHostRatings — admin-only, resumable, one-off.
 *
 * Folds every experience that predates the host-rating totals (no
 * `hostRatingCounted: true`) into `profiles/{hostId}.hostRatingSum /
 * hostRatingCount / hostRatingAvg`. The experience's own aggregate is the sum
 * of its VISIBLE reviews (maintained exactly-once by onExperienceReviewWritten),
 * so the host totals become Σ visible reviews over all their experiences.
 *
 * Per experience, ONE transaction reads the experience + the host profile,
 * adds the aggregate and sets `hostRatingCounted: true`. Review triggers read
 * the same experience in their transactions, so a review landing concurrently
 * is counted exactly once (before the flag: inside the aggregate we add; after
 * it: by the trigger). Re-running is safe: flagged experiences are skipped.
 *
 * Pages `user_experiences` by document id; call repeatedly with the returned
 * `cursor` until `done`.
 */
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { applyHostRatingDelta, experienceHostContribution } from './aggregates';
import { EXPERIENCES } from './createUserExperience';

const db = admin.firestore();

export const backfillHostRatings = onCall<{ cursor?: string; pageSize?: number }>(
  { memory: '512MiB', timeoutSeconds: 540 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
    const me = await db.collection('users').doc(uid).get();
    if (!me.data()?.isAdmin) throw new HttpsError('permission-denied', 'Admin only.');

    const pageSize = Math.min(Math.max(Number(request.data?.pageSize) || 200, 1), 500);
    let q = db
      .collection(EXPERIENCES)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(pageSize);
    if (typeof request.data?.cursor === 'string' && request.data.cursor) {
      q = q.startAfter(request.data.cursor);
    }

    const page = await q.get();
    let counted = 0;
    let failed = 0;
    for (const doc of page.docs) {
      if (doc.get('hostRatingCounted') === true) continue;
      const hostId = doc.get('hostId');
      if (typeof hostId !== 'string' || !hostId) continue;
      try {
        const done = await db.runTransaction(async (tx) => {
          const [exp, profile] = await Promise.all([
            tx.get(doc.ref),
            tx.get(db.collection('profiles').doc(hostId)),
          ]);
          if (!exp.exists || exp.get('hostRatingCounted') === true) return false;
          if (!profile.exists) return false; // deleted host: nothing to fold into
          tx.update(profile.ref, {
            ...applyHostRatingDelta(profile.data(), experienceHostContribution(exp.data())),
          });
          tx.update(exp.ref, { hostRatingCounted: true });
          return true;
        });
        if (done) counted++;
      } catch (e) {
        failed++;
        console.error(`backfillHostRatings ${doc.id} failed:`, e);
      }
    }
    const last = page.docs[page.docs.length - 1];
    return {
      scanned: page.size,
      counted,
      failed,
      cursor: last ? last.id : null,
      done: page.size < pageSize,
    };
  },
);
