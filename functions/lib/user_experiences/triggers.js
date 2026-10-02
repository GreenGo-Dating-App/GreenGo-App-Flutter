"use strict";
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
exports.onExperienceReplyCreated = exports.onExperienceReviewWritten = exports.onUserExperienceWritten = exports.AGG_EVENTS = void 0;
/**
 * User experiences — Firestore triggers.
 *
 *  onUserExperienceWritten   user_experiences/{experienceId}
 *    - create/update: re-moderates the listing text (the client check can be
 *      bypassed) → auto-hides on prohibited language, auto-restores once clean;
 *    - delete: decrements the host's `user_experience_counts` counter,
 *      subtracts the experience's last rating aggregate from the host's
 *      profile totals (exactly once, by event id) and deletes the
 *      reviews/replies subtree (bounded by the subtree size). The review
 *      delete events that follow find the experience gone and change nothing,
 *      so the host is never decremented twice.
 *
 *  onExperienceReviewWritten user_experiences/{experienceId}/reviews/{reviewerId}
 *    - moderation: sets status visible|rejected from the comment (prohibited
 *      language or a link → rejected; hidden from everyone but the author);
 *    - aggregates: ratingSum/ratingCount/ratingAvg/reviewCount/ratingDist on the
 *      experience AND hostRatingSum/hostRatingCount/hostRatingAvg on the
 *      host's profile (when the experience is `hostRatingCounted`), in ONE
 *      transaction, deduplicated by event id (only visible reviews count);
 *    - notifies the host once when a review first becomes visible.
 *
 *  onExperienceReplyCreated  …/reviews/{reviewerId}/replies/{replyId}
 *    - moderation (same rule as reviews) → status visible|rejected;
 *    - notifies each mentioned user (≤ 10) + the review author.
 *
 * 512MiB: the functions bundle needs ~200MB RSS just to load; 256MiB triggers
 * are OOM-killed on cold start and their events silently dropped.
 */
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
require("../shared/firebaseAdmin");
const notifyHelpers_1 = require("../notifications/notifyHelpers");
const moderation_1 = require("./moderation");
const aggregates_1 = require("./aggregates");
const createUserExperience_1 = require("./createUserExperience");
const db = admin.firestore();
const OPTS = { memory: '512MiB', timeoutSeconds: 120 };
/** Dedupe markers for aggregate deltas (TTL on `expireAt`; no client access). */
exports.AGG_EVENTS = 'user_experience_agg_events';
const AGG_EVENT_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const PROFILES = 'profiles';
function aggMarker(extra) {
    return Object.assign(Object.assign({}, extra), { expireAt: admin.firestore.Timestamp.fromMillis(Date.now() + AGG_EVENT_TTL_MS) });
}
function snippet(text, max = 120) {
    const s = typeof text === 'string' ? text.trim().replace(/\s+/g, ' ') : '';
    return s.length > max ? `${s.slice(0, max - 1)}…` : s;
}
// ─────────────────────────────────────────────────────────────── experience
const MODERATED_FIELDS = [
    'title', 'description', 'meetingPoint', 'availability', 'cancellationPolicy',
    'included', 'notIncluded', 'status', 'cancellationNotes',
];
function moderatedFieldsChanged(before, after) {
    return MODERATED_FIELDS.some((f) => { var _a, _b; return JSON.stringify((_a = before[f]) !== null && _a !== void 0 ? _a : null) !== JSON.stringify((_b = after[f]) !== null && _b !== void 0 ? _b : null); });
}
exports.onUserExperienceWritten = (0, firestore_1.onDocumentWritten)(Object.assign({ document: `${createUserExperience_1.EXPERIENCES}/{experienceId}` }, OPTS), async (event) => {
    var _a, _b, _c, _d, _e, _f;
    const { experienceId } = event.params;
    const before = (_c = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before) === null || _b === void 0 ? void 0 : _b.data()) !== null && _c !== void 0 ? _c : null;
    const after = (_f = (_e = (_d = event.data) === null || _d === void 0 ? void 0 : _d.after) === null || _e === void 0 ? void 0 : _e.data()) !== null && _f !== void 0 ? _f : null;
    if (!after) {
        // Deleted: counter + subtree cleanup.
        const hostId = before === null || before === void 0 ? void 0 : before.hostId;
        if (hostId) {
            try {
                await db.runTransaction(async (tx) => {
                    var _a;
                    const ref = db.collection(createUserExperience_1.EXPERIENCE_COUNTS).doc(hostId);
                    const snap = await tx.get(ref);
                    const count = Math.max(0, (Number((_a = snap.data()) === null || _a === void 0 ? void 0 : _a.count) || 0) - 1);
                    tx.set(ref, {
                        count,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    }, { merge: true });
                });
            }
            catch (e) {
                console.error(`experience counter decrement failed (${hostId}):`, e);
            }
        }
        // Host overall rating: remove this experience's contribution. Uses the
        // deleted snapshot, which includes every review delta committed before
        // the delete (review transactions read the experience, so they either
        // committed first or will see it missing and skip).
        const contribution = (0, aggregates_1.experienceHostContribution)(before);
        if (hostId && (before === null || before === void 0 ? void 0 : before.hostRatingCounted) === true && !(0, aggregates_1.isZeroHostDelta)(contribution)) {
            try {
                const markerRef = db.collection(exports.AGG_EVENTS).doc(event.id);
                const profileRef = db.collection(PROFILES).doc(hostId);
                await db.runTransaction(async (tx) => {
                    const [marker, profile] = await Promise.all([
                        tx.get(markerRef),
                        tx.get(profileRef),
                    ]);
                    if (marker.exists)
                        return; // duplicate delivery
                    tx.set(markerRef, aggMarker({ experienceId, hostId, kind: 'experience_deleted' }));
                    if (!profile.exists)
                        return;
                    tx.update(profileRef, Object.assign({}, (0, aggregates_1.applyHostRatingDelta)(profile.data(), (0, aggregates_1.negateHostDelta)(contribution))));
                });
            }
            catch (e) {
                console.error(`host rating decrement failed (${hostId}/${experienceId}):`, e);
            }
        }
        try {
            await db.recursiveDelete(db.collection(createUserExperience_1.EXPERIENCES).doc(experienceId).collection('reviews'));
        }
        catch (e) {
            console.error(`experience ${experienceId} subtree delete failed:`, e);
        }
        return;
    }
    // Aggregate-only writes (review triggers) don't change the text: skip.
    if (before && !moderatedFieldsChanged(before, after))
        return;
    const patch = (0, moderation_1.experienceModerationPatch)(after);
    if (!patch)
        return;
    try {
        await event.data.after.ref.update(Object.assign(Object.assign({}, patch), { moderation: patch.moderation === null
                ? admin.firestore.FieldValue.delete()
                : patch.moderation }));
    }
    catch (e) {
        console.error(`experience ${experienceId} moderation patch failed:`, e);
    }
});
// ─────────────────────────────────────────────────────────────── reviews
exports.onExperienceReviewWritten = (0, firestore_1.onDocumentWritten)(Object.assign({ document: `${createUserExperience_1.EXPERIENCES}/{experienceId}/reviews/{reviewerId}` }, OPTS), async (event) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j;
    const { experienceId, reviewerId } = event.params;
    const before = (_c = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before) === null || _b === void 0 ? void 0 : _b.data()) !== null && _c !== void 0 ? _c : null;
    const after = (_f = (_e = (_d = event.data) === null || _d === void 0 ? void 0 : _d.after) === null || _e === void 0 ? void 0 : _e.data()) !== null && _f !== void 0 ? _f : null;
    // 1) Moderation: decide the status from the CURRENT comment. Writing it
    //    re-fires this trigger; that next event carries its own before/after
    //    delta, so every event below applies exactly its own delta and the
    //    sum over all events is the true aggregate.
    if (after) {
        const decision = (0, moderation_1.moderateCommentText)(after.comment);
        const status = decision.ok ? 'visible' : 'rejected';
        if (after.status !== status) {
            try {
                await event.data.after.ref.update({
                    status,
                    moderation: decision.ok
                        ? admin.firestore.FieldValue.delete()
                        : {
                            reason: decision.reason,
                            terms: (_g = decision.terms) !== null && _g !== void 0 ? _g : [],
                            checkedAt: admin.firestore.FieldValue.serverTimestamp(),
                        },
                });
            }
            catch (e) {
                console.error(`review moderation failed (${experienceId}/${reviewerId}):`, e);
            }
        }
    }
    // 2) Aggregates (this event's own before → after delta).
    const delta = (0, aggregates_1.computeAggregateDelta)(before, after);
    let becameVisible = false;
    if (!(0, aggregates_1.isZeroDelta)(delta)) {
        const expRef = db.collection(createUserExperience_1.EXPERIENCES).doc(experienceId);
        const markerRef = db.collection(exports.AGG_EVENTS).doc(event.id);
        try {
            await db.runTransaction(async (tx) => {
                var _a;
                // All reads before any write (Firestore transaction rule).
                const [marker, exp] = await Promise.all([tx.get(markerRef), tx.get(expRef)]);
                if (marker.exists)
                    return; // duplicate delivery
                const expData = exp.exists ? (_a = exp.data()) !== null && _a !== void 0 ? _a : {} : null;
                const hostId = typeof (expData === null || expData === void 0 ? void 0 : expData.hostId) === 'string' ? expData.hostId : '';
                // Only experiences already folded into the host totals (new ones, or
                // after backfillHostRatings) move them; others wait for the backfill,
                // which adds their whole aggregate at once.
                const profile = expData && hostId && expData.hostRatingCounted === true
                    ? await tx.get(db.collection(PROFILES).doc(hostId))
                    : null;
                tx.set(markerRef, aggMarker({ experienceId }));
                // Experience deleted meanwhile: its delete trigger already removed
                // its (committed) aggregate from the host, so nothing to do here.
                if (!expData)
                    return;
                tx.update(expRef, Object.assign({}, (0, aggregates_1.applyAggregateDelta)(expData, delta)));
                if (profile === null || profile === void 0 ? void 0 : profile.exists) {
                    tx.update(profile.ref, Object.assign({}, (0, aggregates_1.applyHostRatingDelta)(profile.data(), (0, aggregates_1.hostDeltaFromAggregateDelta)(delta))));
                }
            });
        }
        catch (e) {
            console.error(`review aggregate failed (${experienceId}/${reviewerId}):`, e);
        }
        becameVisible = (before === null || before === void 0 ? void 0 : before.status) !== 'visible' && (after === null || after === void 0 ? void 0 : after.status) === 'visible' &&
            !(before === null || before === void 0 ? void 0 : before.hostNotified) && !(after === null || after === void 0 ? void 0 : after.hostNotified);
    }
    // 3) Tell the host about a NEW visible review (once per review).
    if (becameVisible && after) {
        try {
            const exp = await db.collection(createUserExperience_1.EXPERIENCES).doc(experienceId).get();
            const hostId = (_h = exp.data()) === null || _h === void 0 ? void 0 : _h.hostId;
            await event.data.after.ref.update({ hostNotified: true });
            if (hostId && hostId !== reviewerId) {
                const actor = await (0, notifyHelpers_1.resolveActor)(reviewerId);
                await (0, notifyHelpers_1.emitNotification)({
                    recipientId: hostId,
                    type: 'experience_review',
                    title: 'reviewed your experience',
                    body: snippet((_j = exp.data()) === null || _j === void 0 ? void 0 : _j.title) || 'New review',
                    data: {
                        action: 'experience',
                        experienceId,
                        reviewId: reviewerId,
                    },
                    actor,
                });
            }
        }
        catch (e) {
            console.error(`review host notify failed (${experienceId}):`, e);
        }
    }
});
// ─────────────────────────────────────────────────────────────── replies
exports.onExperienceReplyCreated = (0, firestore_1.onDocumentCreated)(Object.assign({ document: `${createUserExperience_1.EXPERIENCES}/{experienceId}/reviews/{reviewId}/replies/{replyId}` }, OPTS), async (event) => {
    var _a, _b;
    const { experienceId, reviewId } = event.params;
    const snap = event.data;
    const reply = snap === null || snap === void 0 ? void 0 : snap.data();
    if (!snap || !reply)
        return;
    const decision = (0, moderation_1.moderateCommentText)(reply.text);
    try {
        await snap.ref.update(Object.assign({ status: decision.ok ? 'visible' : 'rejected' }, (decision.ok
            ? {}
            : {
                moderation: {
                    reason: decision.reason,
                    terms: (_a = decision.terms) !== null && _a !== void 0 ? _a : [],
                    checkedAt: admin.firestore.FieldValue.serverTimestamp(),
                },
            })));
    }
    catch (e) {
        console.error(`reply moderation failed (${experienceId}/${reviewId}):`, e);
        return;
    }
    if (!decision.ok)
        return;
    const authorId = reply.authorId;
    const recipients = (0, moderation_1.replyRecipients)({
        replyAuthorId: authorId,
        reviewAuthorId: reviewId, // review doc id == reviewer uid
        mentions: reply.mentions,
    });
    if (recipients.length === 0)
        return;
    try {
        const [actor, exp] = await Promise.all([
            (0, notifyHelpers_1.resolveActor)(authorId),
            db.collection(createUserExperience_1.EXPERIENCES).doc(experienceId).get(),
        ]);
        const title = snippet((_b = exp.data()) === null || _b === void 0 ? void 0 : _b.title, 60);
        const body = snippet(reply.text) || title;
        await Promise.all(recipients.map((r) => (0, notifyHelpers_1.emitNotification)({
            recipientId: r.uid,
            type: r.type,
            title: r.type === 'experience_mention'
                ? 'mentioned you in a review reply'
                : 'replied to your review',
            body,
            data: {
                action: 'experience',
                experienceId,
                reviewId,
            },
            actor,
        }).catch((e) => console.error(`reply notify ${r.uid} failed:`, e))));
    }
    catch (e) {
        console.error(`reply notify failed (${experienceId}/${reviewId}):`, e);
    }
});
//# sourceMappingURL=triggers.js.map