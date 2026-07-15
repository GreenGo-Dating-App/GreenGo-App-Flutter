"use strict";
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
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onProfileDeleted = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
require("../shared/firebaseAdmin");
const db = admin.firestore();
exports.onProfileDeleted = (0, firestore_1.onDocumentDeleted)('profiles/{uid}', (0, monitoring_1.monitored)('onProfileDeleted', async (event) => {
    const uid = event.params.uid;
    if (!uid)
        return;
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
    }
    catch (e) {
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
    }
    catch (e) {
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
    }
    catch (e) {
        // Event likes may not carry a userId field on all docs — best-effort.
    }
    // 3) Business graph — the businesses this user FOLLOWS (via the mirror index
    //    user_business_following/{uid}/businesses), decrement each business's
    //    followerCount and delete both edges.
    try {
        const following = await db
            .collection('user_business_following')
            .doc(uid)
            .collection('businesses')
            .get();
        for (const d of following.docs) {
            const businessId = d.id;
            const b = db.batch();
            b.delete(d.ref);
            b.delete(db
                .collection('business_followers')
                .doc(businessId)
                .collection('followers')
                .doc(uid));
            b.update(db.collection('profiles').doc(businessId), {
                followerCount: admin.firestore.FieldValue.increment(-1),
            });
            await b.commit();
        }
        await db.collection('user_business_following').doc(uid).delete();
    }
    catch (e) {
        console.error('onProfileDeleted: business-follow cleanup failed', uid, e);
    }
    // 4) If the user WAS a business, remove its follower/rating/lead trees.
    try {
        for (const path of [
            `business_followers/${uid}`,
            `business_ratings/${uid}`,
            `business_leads/${uid}`,
        ]) {
            await db.recursiveDelete(db.doc(path));
        }
    }
    catch (e) {
        console.error('onProfileDeleted: business-owned cleanup failed', uid, e);
    }
    // 5) Firebase Auth user — server-side, so a failed client re-auth can never
    //    leave an orphaned Auth account.
    try {
        await admin.auth().deleteUser(uid);
    }
    catch (e) {
        // Already deleted (client did it) or never existed — fine.
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
    }
    catch (e) {
        console.error('onProfileDeleted: storage cleanup failed', uid, e);
    }
    console.log(`onProfileDeleted: cascade complete for ${uid}`);
}));
//# sourceMappingURL=accountCleanup.js.map