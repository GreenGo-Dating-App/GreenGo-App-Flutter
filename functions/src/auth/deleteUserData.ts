/**
 * Account deletion cascade.
 *
 * Guideline 5.1.1(v): an app that offers account creation must let the user
 * delete the account — and Apple means the account, not just the ability to
 * sign in. GDPR Article 17 says the same about the data behind it.
 *
 * Until v4.0.0 GreenGo's "delete account" called `user.delete()` on the client
 * and stopped there. That removes the Firebase Auth record and leaves
 * everything else: the profile and its photos, coin balances, community
 * memberships, event attendance, blocked lists, and — since Wave 2 — age
 * verification records. The account was unreachable, not deleted.
 *
 * This runs on the auth deletion trigger rather than as a callable, so it
 * fires however the user is removed: from the app, from the admin panel, or by
 * hand in the Firebase console.
 *
 * WHAT IS DELETED
 *   Every document keyed by the user's own id, and every Storage prefix
 *   scoped to them.
 *
 * WHAT IS ANONYMISED INSTEAD
 *   Messages already delivered to another person. Deleting those would edit
 *   somebody else's conversation history, which is neither required nor
 *   desirable; the sender is replaced with a tombstone so nothing traces back.
 *   This is the standard reading of "personal data" for two-party content and
 *   is stated in the privacy policy.
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { db, logInfo, logError } from '../shared/utils';

/** Top-level collections whose document id IS the user id. */
const USER_KEYED_COLLECTIONS = [
  'profiles',
  'users',
  'coinBalances',
  'coin_balances',
  'memberships',
  'subscriptions',
  'user_settings',
  'user_favorite_communities',
  'user_group_tags',
  'blocked_users',
  'age_verification_queue',
  'identity_verifications',
  'notification_settings',
  'user_presence',
];

/** Storage prefixes scoped to one user. */
const USER_STORAGE_PREFIXES = [
  'profiles',
  'video_profiles',
  'voice_intros',
  'verifications',
  'age_verification',
];

/**
 * Collections holding documents that BELONG to a user but are keyed by their
 * own id, found via a `userId`-shaped field.
 */
const OWNED_BY_QUERY: Array<{ collection: string; field: string }> = [
  { collection: 'coinTransactions', field: 'userId' },
  { collection: 'coin_transactions', field: 'userId' },
  { collection: 'purchaseLedger', field: 'userId' },
  { collection: 'user_reports', field: 'reporterId' },
  { collection: 'event_attendees', field: 'userId' },
  { collection: 'community_members', field: 'userId' },
  { collection: 'saved_searches', field: 'userId' },
  { collection: 'likes', field: 'fromUserId' },
  { collection: 'likes', field: 'toUserId' },
];

/** Messages are anonymised, not deleted — see the file header. */
const ANONYMISE: Array<{ collection: string; field: string }> = [
  { collection: 'messages', field: 'senderId' },
  { collection: 'community_messages', field: 'senderId' },
  { collection: 'event_chat_messages', field: 'senderId' },
];

const TOMBSTONE = 'deleted_user';

async function deleteByQuery(
  collection: string,
  field: string,
  uid: string
): Promise<number> {
  let removed = 0;
  // Paged so a heavy account cannot blow the function's memory.
  for (;;) {
    const snap = await db
      .collection(collection)
      .where(field, '==', uid)
      .limit(300)
      .get();
    if (snap.empty) break;

    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    removed += snap.size;
    if (snap.size < 300) break;
  }
  return removed;
}

async function anonymiseByQuery(
  collection: string,
  field: string,
  uid: string
): Promise<number> {
  let touched = 0;
  for (;;) {
    const snap = await db
      .collection(collection)
      .where(field, '==', uid)
      .limit(300)
      .get();
    if (snap.empty) break;

    const batch = db.batch();
    snap.docs.forEach((d) =>
      batch.update(d.ref, {
        [field]: TOMBSTONE,
        senderName: TOMBSTONE,
        senderPhotoUrl: null,
        anonymisedAt: admin.firestore.Timestamp.now(),
      })
    );
    await batch.commit();
    touched += snap.size;
    if (snap.size < 300) break;
  }
  return touched;
}

export const onUserDeletedCleanup = functions
  .runWith({ memory: '512MB', timeoutSeconds: 540 })
  .auth.user()
  .onDelete(async (user) => {
    const uid = user.uid;
    logInfo(`onUserDeletedCleanup: starting for ${uid}`);

    const report = {
      documents: 0,
      anonymised: 0,
      files: 0,
      failures: [] as string[],
    };

    // 1. Documents keyed by the user id.
    for (const collection of USER_KEYED_COLLECTIONS) {
      try {
        await db.collection(collection).doc(uid).delete();
        report.documents += 1;
      } catch (e) {
        report.failures.push(`${collection}/${uid}`);
        logError(`onUserDeletedCleanup: ${collection}/${uid} failed`, e);
      }
    }

    // 2. Documents owned via a field.
    for (const { collection, field } of OWNED_BY_QUERY) {
      try {
        report.documents += await deleteByQuery(collection, field, uid);
      } catch (e) {
        report.failures.push(`${collection}.${field}`);
        logError(`onUserDeletedCleanup: query delete ${collection}.${field} failed`, e);
      }
    }

    // 3. Two-party content: anonymise rather than destroy.
    for (const { collection, field } of ANONYMISE) {
      try {
        report.anonymised += await anonymiseByQuery(collection, field, uid);
      } catch (e) {
        report.failures.push(`anonymise ${collection}.${field}`);
        logError(`onUserDeletedCleanup: anonymise ${collection} failed`, e);
      }
    }

    // 4. Storage.
    const bucket = admin.storage().bucket();
    for (const prefix of USER_STORAGE_PREFIXES) {
      try {
        const [files] = await bucket.getFiles({ prefix: `${prefix}/${uid}/` });
        await Promise.all(files.map((f) => f.delete()));
        report.files += files.length;
      } catch (e) {
        report.failures.push(`storage:${prefix}/${uid}`);
        logError(`onUserDeletedCleanup: storage ${prefix}/${uid} failed`, e);
      }
    }

    // 5. A record that the deletion happened, with NO personal data in it.
    //    Needed to answer "did you delete my account?" without keeping the
    //    account. The uid is already gone from Auth and is not reversible to a
    //    person on its own.
    try {
      await db.collection('deletion_receipts').doc(uid).set({
        deletedAt: admin.firestore.Timestamp.now(),
        documentsDeleted: report.documents,
        messagesAnonymised: report.anonymised,
        filesDeleted: report.files,
        failures: report.failures,
      });
    } catch (e) {
      logError('onUserDeletedCleanup: could not write receipt', e);
    }

    if (report.failures.length > 0) {
      // Loud on purpose: a partial deletion is a compliance problem, not a
      // cosmetic one, and somebody has to finish it by hand.
      logError(
        `onUserDeletedCleanup: INCOMPLETE for ${uid} — ${report.failures.length} failures`,
        report.failures
      );
    } else {
      logInfo(
        `onUserDeletedCleanup: done for ${uid} — ${report.documents} docs, ` +
          `${report.anonymised} messages anonymised, ${report.files} files`
      );
    }
  });
