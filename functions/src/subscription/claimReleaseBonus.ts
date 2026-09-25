/**
 * One free month, granted once per user after the release date.
 *
 * This used to run entirely on the client: it read the membership, computed a
 * new end date, and wrote `profiles/{uid}.membershipEndDate` itself. That only
 * worked because the profile rules let a user write their own entitlement
 * fields - which is the same permission that let anyone award themselves
 * Platinum outright. Closing that hole necessarily breaks any client-side
 * grant, so the grant moves here.
 *
 * Moving it server-side also fixes two things the client version could not:
 *
 *   - "once per user" was enforced by reading a flag and then writing it, with
 *     no transaction. Two launches racing each other both saw `false` and both
 *     granted a month. This claims the flag inside a transaction, so a second
 *     caller loses.
 *   - the caller chose their own new end date. Now the server computes it.
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { db, logInfo, logError } from '../shared/utils';
import { hasActivePaidTier, normalizeStoredTier, tierDateFromValue } from '../shared/effectiveTier';

/**
 * Eligibility comes from `profiles/{uid}` (the entitlement source of truth),
 * NOT from `memberships/*`, which the client can write: an ACTIVE paid tier
 * (SILVER/GOLD/PLATINUM with membershipEndDate > now) is required. FREE,
 * legacy 'BASIC', TEST and expired tiers get nothing — extending an expired
 * tier's end date would revive it.
 */
export const claimReleaseBonus = onCall({ memory: '512MiB' }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

  const userRef = db.collection('users').doc(uid);
  const profileRef = db.collection('profiles').doc(uid);

  try {
    // Claim the flag and grant in ONE transaction. Whoever wins grants;
    // everyone else returns `alreadyClaimed` and writes nothing. As before,
    // the claim is spent even when the user is not eligible.
    type ClaimResult =
      | { granted: false; reason: string }
      | { granted: true; newEndDate: string };
    const result = await db.runTransaction<ClaimResult>(async (tx) => {
      const userSnap = await tx.get(userRef);
      const profileSnap = await tx.get(profileRef);
      if (!userSnap.exists) return { granted: false, reason: 'alreadyClaimed' };
      if (userSnap.data()?.releaseBonusGranted === true) {
        return { granted: false, reason: 'alreadyClaimed' };
      }
      tx.set(userRef, { releaseBonusGranted: true }, { merge: true });

      const profile = profileSnap.data();
      const now = new Date();
      if (!hasActivePaidTier(profile, now)) {
        const stored = normalizeStoredTier(profile?.membershipTier);
        return {
          granted: false,
          reason: stored === 'FREE' || stored === 'BASIC' || stored === 'TEST'
            ? 'tierNotEligible'
            : 'noActiveMembership',
        };
      }

      // Active paid tier: push its (future) end date by one month.
      const currentEnd = tierDateFromValue(profile!.membershipEndDate) as Date;
      const newEnd = new Date(currentEnd);
      newEnd.setMonth(newEnd.getMonth() + 1);
      const newEndTs = admin.firestore.Timestamp.fromDate(newEnd);
      const nowTs = admin.firestore.Timestamp.now();

      tx.set(profileRef, { membershipEndDate: newEndTs, updatedAt: nowTs }, { merge: true });
      tx.set(userRef, { membershipEndDate: newEndTs, updatedAt: nowTs }, { merge: true });
      return { granted: true, newEndDate: newEnd.toISOString() };
    });

    if (!result.granted) return result;

    // Display mirror only (never read for decisions): keep the active
    // memberships doc's endDate in step with the profile.
    try {
      const memberships = await db
        .collection('memberships')
        .where('userId', '==', uid)
        .where('isActive', '==', true)
        .orderBy('createdAt', 'desc')
        .limit(1)
        .get();
      if (!memberships.empty) {
        await memberships.docs[0].ref.update({
          endDate: admin.firestore.Timestamp.fromDate(new Date(result.newEndDate)),
          updatedAt: admin.firestore.Timestamp.now(),
        });
      }
    } catch (e) {
      logError(`claimReleaseBonus: memberships mirror update failed for ${uid}`, e);
    }

    logInfo(`claimReleaseBonus: granted 1 month to ${uid}, new end ${result.newEndDate}`);
    return result;
  } catch (e) {
    logError(`claimReleaseBonus failed for ${uid}`, e);
    // A failed transaction wrote nothing, so the claim is not spent.
    throw new HttpsError('internal', 'Could not claim the release bonus.');
  }
});
