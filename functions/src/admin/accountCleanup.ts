/**
 * Account deletion cascade (NEW, isolated module) — #3.
 *
 * Fires when a `profiles/{uid}` doc is DELETED (the client self-delete flow and
 * the admin hard-delete both remove that doc). The client already hard-deletes
 * the top-level per-user docs, but it leaves STALE denormalized counts, orphaned
 * subcollection membership/attendee/follower docs, the Firebase Auth user (only
 * if the client re-auth succeeded), and Storage media. This trigger — Admin SDK,
 * so it bypasses rules — finishes the job so a deleted user is truly gone,
 * invisible, and uncounted.
 *
 * Every section is independently try/caught so one failure can't abort the rest.
 */

import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';
import { retainIdDocumentsOnAccountDeletion } from '../safety/idDocumentRetention';
import { enqueueFollowGraphCleanup } from '../social/followCleanup';
import { serverDeletionRunning } from '../auth/accountDeletion';

const db = admin.firestore();

export const onProfileDeleted = onDocumentDeleted(
  // 512MiB: at the 256MiB default the instance can be OOM-killed while loading
  // the bundle, and this (non-retried) event would be dropped silently.
  { document: 'profiles/{uid}', memory: '512MiB', timeoutSeconds: 540 },
  monitored('onProfileDeleted', async (event) => {
    const uid = event.params.uid as string;
    if (!uid) return;

    // 1) Community memberships — delete each member doc + decrement the parent
    //    community's memberCount (members carry a `userId` field).
    try {
      const snap = await db
        .collectionGroup('members')
        .where('userId', '==', uid)
        .get();
      for (const d of snap.docs) {
        const communityRef = d.ref.parent.parent;
        const b = db.batch();
        b.delete(d.ref);
        if (communityRef) {
          b.update(communityRef, {
            memberCount: admin.firestore.FieldValue.increment(-1),
          });
        }
        await b.commit();
      }
    } catch (e) {
      console.error('onProfileDeleted: community members cleanup failed', uid, e);
    }

    // 2) Event attendance — attendee docs are keyed by uid; decrement the
    //    event's attendeeCount. Also remove the user's event likes.
    try {
      const snap = await db
        .collectionGroup('attendees')
        .where('userId', '==', uid)
        .get();
      for (const d of snap.docs) {
        const eventRef = d.ref.parent.parent;
        const b = db.batch();
        b.delete(d.ref);
        if (eventRef) {
          b.update(eventRef, {
            attendeeCount: admin.firestore.FieldValue.increment(-1),
          });
        }
        await b.commit();
      }
    } catch (e) {
      console.error('onProfileDeleted: attendees cleanup failed', uid, e);
    }
    try {
      const likes = await db
        .collectionGroup('likes')
        .where('userId', '==', uid)
        .get();
      for (const d of likes.docs) {
        await d.ref.delete();
      }
    } catch (e) {
      // Event likes may not carry a userId field on all docs — best-effort.
    }

    // 3) Follow graph — BOTH directions (edges where this user follows someone
    //    and edges where someone follows this user, plus both mirrors). Queued
    //    as a bounded, self-continuing job (social/followCleanup.ts) so an
    //    account with millions of followers cannot time this trigger out. The
    //    other side's followersCount / followingCount is decremented exactly
    //    once by onUserFollowDeleted as each counted edge is deleted.
    try {
      await enqueueFollowGraphCleanup(db, uid);
    } catch (e) {
      console.error('onProfileDeleted: follow-graph cleanup enqueue failed', uid, e);
    }

    // 4) If the user WAS a business, remove its rating/lead trees (its follower
    //    edges are handled by the follow-graph job above, mirrors included).
    try {
      for (const path of [
        `business_ratings/${uid}`,
        `business_leads/${uid}`,
      ]) {
        await db.recursiveDelete(db.doc(path));
      }
    } catch (e) {
      console.error('onProfileDeleted: business-owned cleanup failed', uid, e);
    }

    // 5) Firebase Auth user — server-side, so a failed client re-auth can never
    //    leave an orphaned Auth account.
    //     EXCEPT while a server-side deletion (deleteMyAccount / website link,
    //     auth/accountDeletion.ts) is running: that path deletes the profile
    //     near the end and the Auth user strictly LAST, and must be able to
    //     leave the account intact if a later step fails.
    try {
      if (!(await serverDeletionRunning(uid))) {
        await admin.auth().deleteUser(uid);
      }
    } catch (e) {
      // Already deleted (client did it) or never existed — fine.
    }

    // 5b) Identity documents are NOT deleted: moved to retention/{uid}/ and
    //     kept 30 days (fraud prevention; DRAFT — lawyer review). Idempotent
    //     with the same call in onUserDeletedCleanup.
    try {
      await retainIdDocumentsOnAccountDeletion(uid);
    } catch (e) {
      console.error('onProfileDeleted: ID document retention failed', uid, e);
    }

    // 6) Storage media under the user's known prefixes (best-effort).
    try {
      const bucket = admin.storage().bucket();
      for (const prefix of [
        `profiles/${uid}/`,
        `users/${uid}/`,
        `verification/${uid}/`,
        `voice/${uid}/`,
      ]) {
        await bucket.deleteFiles({ prefix }).catch(() => undefined);
      }
    } catch (e) {
      console.error('onProfileDeleted: storage cleanup failed', uid, e);
    }

    console.log(`onProfileDeleted: cascade complete for ${uid}`);
  }),
);
