/**
 * createUserExperience — the ONLY way to create a `user_experiences` doc.
 *
 * Why a callable (and `allow create: if false` in the rules) instead of a
 * rules-only check against a trigger-maintained counter:
 *  - atomic: the per-host counter `user_experience_counts/{uid}` is read and
 *    incremented in the SAME transaction that writes the experience, so two
 *    parallel creates cannot both slip under the limit (a trigger-maintained
 *    counter lags the write, and a burst of creates would all pass the rule);
 *  - one tier rule: the limit uses shared/effectiveTier.ts (expired Silver =
 *    FREE), which handles every stored `membershipEndDate` shape (Timestamp,
 *    millis, ISO string) — Firestore rules cannot parse the string forms;
 *  - full server validation + moderation of the payload at write time, and
 *    every server-owned field (ratings, status 'hidden', moderation, hostId)
 *    is set here, never taken from the client.
 * Cost: one cold-start-prone round trip per create, and creation needs the
 * function deployed (edits/deletes stay direct Firestore writes).
 *
 * A host downgraded below their current count keeps every existing
 * experience (nothing is auto-hidden) — they just cannot create new ones.
 */
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { effectiveTier, isProfileAdmin } from '../shared/effectiveTier';
import { moderateExperienceText } from './moderation';
import { maxExperiencesFor, validateExperiencePayload } from './validation';

const db = admin.firestore();

export const EXPERIENCES = 'user_experiences';
export const EXPERIENCE_COUNTS = 'user_experience_counts';

export const createUserExperience = onCall(
  { memory: '512MiB', timeoutSeconds: 60 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const v = validateExperiencePayload(request.data as Record<string, unknown>);
    if (!v.ok) {
      throw new HttpsError('invalid-argument', 'invalid_experience', {
        code: 'invalid_experience',
        fields: v.errors,
      });
    }
    const mod = moderateExperienceText(v.data);
    if (!mod.ok) {
      throw new HttpsError('invalid-argument', 'prohibited_text', {
        code: 'prohibited_text',
      });
    }

    const profileRef = db.collection('profiles').doc(uid);
    const counterRef = db.collection(EXPERIENCE_COUNTS).doc(uid);
    const expRef = db.collection(EXPERIENCES).doc();

    const result = await db.runTransaction(async (tx) => {
      const [profileSnap, counterSnap] = await Promise.all([
        tx.get(profileRef),
        tx.get(counterRef),
      ]);
      const profile = profileSnap.data() ?? null;
      const tier = effectiveTier(profile);
      const max = maxExperiencesFor(tier, isProfileAdmin(profile));

      let count = Number(counterSnap.data()?.count ?? 0) || 0;
      if (max !== null && count >= max) {
        // Self-heal a drifted counter (e.g. a failed delete trigger) before
        // refusing: the authoritative number is the host's actual docs.
        const agg = await tx.get(
          db.collection(EXPERIENCES).where('hostId', '==', uid).count(),
        );
        count = agg.data().count;
        if (count >= max) {
          throw new HttpsError('resource-exhausted', 'experience_limit', {
            code: 'experience_limit',
            limit: max,
            count,
            tier,
          });
        }
      }

      const now = admin.firestore.FieldValue.serverTimestamp();
      tx.set(expRef, {
        ...v.data,
        hostId: uid,
        createdAt: now,
        updatedAt: now,
        ratingSum: 0,
        ratingCount: 0,
        ratingAvg: 0,
        reviewCount: 0,
        ratingDist: { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 },
        viewCount: 0,
      });
      tx.set(counterRef, { count: count + 1, updatedAt: now }, { merge: true });
      return { id: expRef.id, count: count + 1, limit: max };
    });

    return result;
  },
);
