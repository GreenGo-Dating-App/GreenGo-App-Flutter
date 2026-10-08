/**
 * setExperienceFeatured — admin-only promotion of a member-hosted experience
 * into Explore "Top experiences" (tier 1: featured first).
 *
 *   { experienceId: string, days: 0..30 }
 *     days 1..30 → isFeatured: true,  featuredUntil: now + days
 *     days 0     → isFeatured: false, featuredUntil: null (unfeature)
 *
 * `isFeatured` / `featuredUntil` are SERVER-OWNED: firestore.rules lists them in
 * serverOwnedExperienceFields() (no client update), creates go through the
 * createUserExperience callable (always `isFeatured: false`). The client treats
 * a listing as featured only while `isFeatured && featuredUntil > now`, so an
 * expired promotion needs no cleanup job.
 *
 * No payment / boost purchase flow yet — admins only.
 */
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { requireAdmin, MODERATION_ROLES } from '../shared/adminAuth';
import '../shared/firebaseAdmin';
import { EXPERIENCES } from './createUserExperience';
import { FEATURE_MAX_DAYS, featuredPatch } from './featuredPatch';

const db = admin.firestore();

export { FEATURE_MAX_DAYS, featuredPatch };

export const setExperienceFeatured = onCall<{ experienceId?: unknown; days?: unknown }>(
  { memory: '512MiB', timeoutSeconds: 30 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
    await requireAdmin(request.auth, MODERATION_ROLES); // P1-6 (was users.isAdmin)

    const experienceId = request.data?.experienceId;
    if (typeof experienceId !== 'string' || !experienceId || experienceId.includes('/')) {
      throw new HttpsError('invalid-argument', 'experienceId required.');
    }
    const patch = featuredPatch(request.data?.days, Date.now());
    if ('error' in patch) {
      throw new HttpsError('invalid-argument', `days must be an integer 0..${FEATURE_MAX_DAYS}.`);
    }

    const ref = db.collection(EXPERIENCES).doc(experienceId);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError('not-found', 'Experience not found.');
    if (patch.isFeatured && snap.get('status') !== 'published') {
      throw new HttpsError('failed-precondition', 'Only published experiences can be featured.');
    }

    const featuredUntil = patch.featuredUntilMs === null
      ? null
      : admin.firestore.Timestamp.fromMillis(patch.featuredUntilMs);
    await ref.update({ isFeatured: patch.isFeatured, featuredUntil });
    console.log(`setExperienceFeatured(${experienceId}, days=${request.data?.days}) by ${uid}`);
    return {
      experienceId,
      isFeatured: patch.isFeatured,
      featuredUntil: patch.featuredUntilMs,
    };
  },
);
