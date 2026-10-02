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
import {
  SafetyCode,
  createBlockReason,
} from './safety';

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
      // contact_info: phones / e-mails / handles / PIX keys outside the
      // payment link (anti-scam); prohibited_text: language.
      const code = mod.reason === 'contact_info' ? 'contact_info' : 'prohibited_text';
      throw new HttpsError('invalid-argument', code, { code, kinds: mod.terms ?? [] });
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

      // Phase 1 safety: ID document uploaded to create; agreement + approved
      // document (+ new-host paid limit) to publish a listing taking money.
      const blocked = createBlockReason(profile);
      if (blocked) throw safetyError(blocked);
      // A new listing has no dates yet, and availability must be defined by
      // dates: it is always stored as a draft, published via
      // publishUserExperience once it has an upcoming date.

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
        status: 'draft',
        hostId: uid,
        createdAt: now,
        updatedAt: now,
        ratingSum: 0,
        ratingCount: 0,
        ratingAvg: 0,
        reviewCount: 0,
        ratingDist: { '1': 0, '2': 0, '3': 0, '4': 0, '5': 0 },
        viewCount: 0,
        // Explore promotion is server-owned (setExperienceFeatured, admin).
        isFeatured: false,
        // Its (empty) aggregate is part of the host's profile totals from the
        // start, so review triggers keep profiles/{uid}.hostRating* in step.
        // Without a profile there is nothing to count into (backfill later).
        hostRatingCounted: profileSnap.exists,
      });
      tx.set(counterRef, { count: count + 1, updatedAt: now }, { merge: true });
      return { id: expRef.id, count: count + 1, limit: max, status: 'draft' };
    });

    return result;
  },
);

/** Structured refusal the client maps to a guided prompt (see safety.ts). */
export function safetyError(code: SafetyCode): HttpsError {
  return new HttpsError('failed-precondition', code, { code });
}

/** The host's published PAID listings (aggregate count: 1 read / 1000 docs). */
export async function countPublishedPaid(
  tx: admin.firestore.Transaction,
  hostId: string,
  excludeId?: string,
): Promise<number> {
  const agg = await tx.get(
    db.collection(EXPERIENCES)
      .where('hostId', '==', hostId)
      .where('status', '==', 'published')
      .where('isFree', '==', false)
      .count(),
  );
  let n = agg.data().count;
  if (excludeId) {
    const self = await tx.get(db.collection(EXPERIENCES).doc(excludeId));
    const d = self.data();
    if (d && d.hostId === hostId && d.status === 'published' && d.isFree === false) n -= 1;
  }
  return Math.max(0, n);
}
