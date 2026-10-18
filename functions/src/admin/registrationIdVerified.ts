/**
 * Registration ID photo decided by an admin → the profile's "Verified" badge.
 *
 * The badge (and every "approved document" check) reads the server-owned
 * `profiles.isAgeVerified`, which the profile rules forbid the owner to set.
 * An admin decision on the registration photo is recorded in `admin_actions`
 * (admins only; written by the panel, its callables and the in-app admin
 * tools), so a create there is a trusted signal:
 *   - approved, and the profile still says approved → isAgeVerified = true;
 *   - rejected / resubmission requested → isAgeVerified = false, unless the
 *     age-verification document itself is verified (that approval stands).
 * Every final decision (approve / reject / resubmission requested) then
 * DELETES the reviewed photo and clears its references (Privacy Policy 8.3,
 * verificationPhotoRetention.ts); a photo still awaiting review is kept.
 */
import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import '../shared/firebaseAdmin';
import { ADMIN_ACTIONS, registrationIdApproved } from '../shared/registrationIdReview';
import { deleteRegistrationPhotoOnDecision, toMillis } from '../safety/verificationPhotoRetention';
import { FINAL_REGISTRATION_ACTIONS } from '../safety/verificationPhotoRetentionLogic';

const OPTS = { memory: '512MiB' as const, timeoutSeconds: 60 };

export type BadgePatch = Record<string, unknown> | null;

/** Pure (unit-tested): the profile patch for an admin [actionType], or null. */
export function verifiedPatchFor(
  actionType: string,
  profile: Record<string, any> | null | undefined
): BadgePatch {
  if (!profile) return null;
  if (actionType === 'verification_approved') {
    if (profile.isAgeVerified === true) return null;
    if (!registrationIdApproved(profile, 'approved')) return null;
    return { isAgeVerified: true, idVerifiedVia: 'registration_review' };
  }
  if (actionType === 'verification_rejected' || actionType === 'verification_resubmission_requested') {
    if (profile.isAgeVerified !== true) return null;
    if (profile.ageVerification?.status === 'verified') return null;
    return { isAgeVerified: false, idVerifiedVia: null };
  }
  return null;
}

export const onAdminVerificationAction = onDocumentCreated(
  { document: `${ADMIN_ACTIONS}/{actionId}`, ...OPTS },
  async (event) => {
    const a = event.data?.data();
    const uid = typeof a?.targetUserId === 'string' ? a.targetUserId : '';
    const type = typeof a?.actionType === 'string' ? a.actionType : '';
    if (!uid || uid.includes('/') || !type.startsWith('verification_')) return;
    const ref = admin.firestore().collection('profiles').doc(uid);
    await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const patch = verifiedPatchFor(type, snap.data());
      if (!patch) return;
      tx.update(ref, {
        ...patch,
        idVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    if (FINAL_REGISTRATION_ACTIONS[type]) {
      await deleteRegistrationPhotoOnDecision(uid, {
        atMs: toMillis(a?.timestamp),
        by: typeof a?.performedBy === 'string' ? a.performedBy : null,
      });
    }
  }
);
