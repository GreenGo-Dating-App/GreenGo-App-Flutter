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

/** Tiers that get nothing: there is no paid month to extend. */
const INELIGIBLE_TIERS = ['FREE', 'free', 'TEST', 'test'];

export const claimReleaseBonus = onCall({ memory: '512MiB' }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

  const userRef = db.collection('users').doc(uid);

  try {
    // Claim the flag first, in a transaction. Whoever wins goes on to grant;
    // everyone else returns `alreadyClaimed` and writes nothing.
    const claimed = await db.runTransaction(async (tx) => {
      const snap = await tx.get(userRef);
      if (!snap.exists) return false;
      if (snap.data()?.releaseBonusGranted === true) return false;
      tx.set(userRef, { releaseBonusGranted: true }, { merge: true });
      return true;
    });

    if (!claimed) {
      return { granted: false, reason: 'alreadyClaimed' };
    }

    // The user's active membership decides whether there is anything to extend.
    const memberships = await db
      .collection('memberships')
      .where('userId', '==', uid)
      .where('isActive', '==', true)
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();

    if (memberships.empty) {
      return { granted: false, reason: 'noActiveMembership' };
    }

    const membership = memberships.docs[0];
    const data = membership.data();
    const tier = String(data.tier ?? 'FREE');

    if (INELIGIBLE_TIERS.includes(tier)) {
      return { granted: false, reason: 'tierNotEligible' };
    }

    // Extend from the later of "now" and the current end date, so a lapsed
    // membership gets a month from today rather than a month from the past.
    const currentEnd =
      data.endDate instanceof admin.firestore.Timestamp
        ? data.endDate.toDate()
        : new Date();
    const base = currentEnd > new Date() ? currentEnd : new Date();
    const newEnd = new Date(base);
    newEnd.setMonth(newEnd.getMonth() + 1);
    const newEndTs = admin.firestore.Timestamp.fromDate(newEnd);

    const batch = db.batch();
    batch.update(membership.ref, {
      endDate: newEndTs,
      updatedAt: admin.firestore.Timestamp.now(),
    });
    batch.set(
      db.collection('profiles').doc(uid),
      { membershipEndDate: newEndTs },
      { merge: true }
    );
    await batch.commit();

    logInfo(`claimReleaseBonus: granted 1 month to ${uid}, new end ${newEnd.toISOString()}`);
    return { granted: true, newEndDate: newEnd.toISOString() };
  } catch (e) {
    logError(`claimReleaseBonus failed for ${uid}`, e);
    // The flag may already be claimed at this point. Releasing it on failure
    // would reopen the double-grant race, so it stays claimed and the user
    // keeps their existing membership unchanged.
    throw new HttpsError('internal', 'Could not claim the release bonus.');
  }
});
