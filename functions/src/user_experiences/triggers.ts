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
import {
  onDocumentWritten,
  onDocumentCreated,
} from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { emitNotification, resolveActor } from '../notifications/notifyHelpers';
import { lt, rawText } from '../shared/i18n';
import {
  experienceModerationPatch,
  moderateCommentText,
  replyRecipients,
} from './moderation';
import {
  applyAggregateDelta,
  applyHostRatingDelta,
  computeAggregateDelta,
  experienceHostContribution,
  hostDeltaFromAggregateDelta,
  isZeroDelta,
  isZeroHostDelta,
  negateHostDelta,
} from './aggregates';
import { EXPERIENCES, EXPERIENCE_COUNTS } from './createUserExperience';

const db = admin.firestore();
const OPTS = { memory: '512MiB' as const, timeoutSeconds: 120 };

/** Dedupe markers for aggregate deltas (TTL on `expireAt`; no client access). */
export const AGG_EVENTS = 'user_experience_agg_events';
const AGG_EVENT_TTL_MS = 7 * 24 * 60 * 60 * 1000;
const PROFILES = 'profiles';

function aggMarker(extra: Record<string, unknown>) {
  return {
    ...extra,
    expireAt: admin.firestore.Timestamp.fromMillis(Date.now() + AGG_EVENT_TTL_MS),
  };
}

function snippet(text: unknown, max = 120): string {
  const s = typeof text === 'string' ? text.trim().replace(/\s+/g, ' ') : '';
  return s.length > max ? `${s.slice(0, max - 1)}…` : s;
}

// ─────────────────────────────────────────────────────────────── experience

const MODERATED_FIELDS = [
  'title', 'description', 'meetingPoint', 'availability', 'cancellationPolicy',
  'included', 'notIncluded', 'status', 'cancellationNotes',
];

function moderatedFieldsChanged(
  before: Record<string, unknown>,
  after: Record<string, unknown>,
): boolean {
  return MODERATED_FIELDS.some(
    (f) => JSON.stringify(before[f] ?? null) !== JSON.stringify(after[f] ?? null),
  );
}

export const onUserExperienceWritten = onDocumentWritten(
  { document: `${EXPERIENCES}/{experienceId}`, ...OPTS },
  async (event) => {
    const { experienceId } = event.params;
    const before = event.data?.before?.data() ?? null;
    const after = event.data?.after?.data() ?? null;

    if (!after) {
      // Deleted: counter + subtree cleanup.
      const hostId = before?.hostId as string | undefined;
      if (hostId) {
        try {
          await db.runTransaction(async (tx) => {
            const ref = db.collection(EXPERIENCE_COUNTS).doc(hostId);
            const snap = await tx.get(ref);
            const count = Math.max(0, (Number(snap.data()?.count) || 0) - 1);
            tx.set(ref, {
              count,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
          });
        } catch (e) {
          console.error(`experience counter decrement failed (${hostId}):`, e);
        }
      }
      // Host overall rating: remove this experience's contribution. Uses the
      // deleted snapshot, which includes every review delta committed before
      // the delete (review transactions read the experience, so they either
      // committed first or will see it missing and skip).
      const contribution = experienceHostContribution(before);
      if (hostId && before?.hostRatingCounted === true && !isZeroHostDelta(contribution)) {
        try {
          const markerRef = db.collection(AGG_EVENTS).doc(event.id);
          const profileRef = db.collection(PROFILES).doc(hostId);
          await db.runTransaction(async (tx) => {
            const [marker, profile] = await Promise.all([
              tx.get(markerRef),
              tx.get(profileRef),
            ]);
            if (marker.exists) return; // duplicate delivery
            tx.set(markerRef, aggMarker({ experienceId, hostId, kind: 'experience_deleted' }));
            if (!profile.exists) return;
            tx.update(profileRef, {
              ...applyHostRatingDelta(profile.data(), negateHostDelta(contribution)),
            });
          });
        } catch (e) {
          console.error(`host rating decrement failed (${hostId}/${experienceId}):`, e);
        }
      }
      try {
        await db.recursiveDelete(
          db.collection(EXPERIENCES).doc(experienceId).collection('reviews'),
        );
      } catch (e) {
        console.error(`experience ${experienceId} subtree delete failed:`, e);
      }
      return;
    }

    // Aggregate-only writes (review triggers) don't change the text: skip.
    if (before && !moderatedFieldsChanged(before, after)) return;

    const patch = experienceModerationPatch(after);
    if (!patch) return;
    try {
      await event.data!.after.ref.update({
        ...patch,
        moderation: patch.moderation === null
          ? admin.firestore.FieldValue.delete()
          : patch.moderation,
      });
    } catch (e) {
      console.error(`experience ${experienceId} moderation patch failed:`, e);
    }
  },
);

// ─────────────────────────────────────────────────────────────── reviews

export const onExperienceReviewWritten = onDocumentWritten(
  { document: `${EXPERIENCES}/{experienceId}/reviews/{reviewerId}`, ...OPTS },
  async (event) => {
    const { experienceId, reviewerId } = event.params;
    const before = event.data?.before?.data() ?? null;
    const after = event.data?.after?.data() ?? null;

    // 1) Moderation: decide the status from the CURRENT comment. Writing it
    //    re-fires this trigger; that next event carries its own before/after
    //    delta, so every event below applies exactly its own delta and the
    //    sum over all events is the true aggregate.
    if (after) {
      const decision = moderateCommentText(after.comment);
      const status = decision.ok ? 'visible' : 'rejected';
      if (after.status !== status) {
        try {
          await event.data!.after.ref.update({
            status,
            moderation: decision.ok
              ? admin.firestore.FieldValue.delete()
              : {
                reason: decision.reason,
                terms: decision.terms ?? [],
                checkedAt: admin.firestore.FieldValue.serverTimestamp(),
              },
          });
        } catch (e) {
          console.error(`review moderation failed (${experienceId}/${reviewerId}):`, e);
        }
      }
    }

    // 2) Aggregates (this event's own before → after delta).
    const delta = computeAggregateDelta(before, after);
    let becameVisible = false;
    if (!isZeroDelta(delta)) {
      const expRef = db.collection(EXPERIENCES).doc(experienceId);
      const markerRef = db.collection(AGG_EVENTS).doc(event.id);
      try {
        await db.runTransaction(async (tx) => {
          // All reads before any write (Firestore transaction rule).
          const [marker, exp] = await Promise.all([tx.get(markerRef), tx.get(expRef)]);
          if (marker.exists) return; // duplicate delivery
          const expData = exp.exists ? exp.data() ?? {} : null;
          const hostId = typeof expData?.hostId === 'string' ? expData.hostId : '';
          // Only experiences already folded into the host totals (new ones, or
          // after backfillHostRatings) move them; others wait for the backfill,
          // which adds their whole aggregate at once.
          const profile = expData && hostId && expData.hostRatingCounted === true
            ? await tx.get(db.collection(PROFILES).doc(hostId))
            : null;

          tx.set(markerRef, aggMarker({ experienceId }));
          // Experience deleted meanwhile: its delete trigger already removed
          // its (committed) aggregate from the host, so nothing to do here.
          if (!expData) return;
          tx.update(expRef, { ...applyAggregateDelta(expData, delta) });
          if (profile?.exists) {
            tx.update(profile.ref, {
              ...applyHostRatingDelta(profile.data(), hostDeltaFromAggregateDelta(delta)),
            });
          }
        });
      } catch (e) {
        console.error(`review aggregate failed (${experienceId}/${reviewerId}):`, e);
      }
      becameVisible = before?.status !== 'visible' && after?.status === 'visible' &&
        !before?.hostNotified && !after?.hostNotified;
    }

    // 3) Tell the host about a NEW visible review (once per review).
    if (becameVisible && after) {
      try {
        const exp = await db.collection(EXPERIENCES).doc(experienceId).get();
        const hostId = exp.data()?.hostId as string | undefined;
        await event.data!.after.ref.update({ hostNotified: true });
        if (hostId && hostId !== reviewerId) {
          const actor = await resolveActor(reviewerId);
          await emitNotification({
            recipientId: hostId,
            type: 'experience_review',
            title: lt('notifServerReviewedYourExperience'),
            body: snippet(exp.data()?.title) ? rawText(snippet(exp.data()?.title)) : lt('srvNewReview'),
            data: {
              action: 'experience',
              experienceId,
              reviewId: reviewerId,
            },
            actor,
          });
        }
      } catch (e) {
        console.error(`review host notify failed (${experienceId}):`, e);
      }
    }
  },
);

// ─────────────────────────────────────────────────────────────── replies

export const onExperienceReplyCreated = onDocumentCreated(
  {
    document: `${EXPERIENCES}/{experienceId}/reviews/{reviewId}/replies/{replyId}`,
    ...OPTS,
  },
  async (event) => {
    const { experienceId, reviewId } = event.params;
    const snap = event.data;
    const reply = snap?.data();
    if (!snap || !reply) return;

    const decision = moderateCommentText(reply.text);
    try {
      await snap.ref.update({
        status: decision.ok ? 'visible' : 'rejected',
        ...(decision.ok
          ? {}
          : {
            moderation: {
              reason: decision.reason,
              terms: decision.terms ?? [],
              checkedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
          }),
      });
    } catch (e) {
      console.error(`reply moderation failed (${experienceId}/${reviewId}):`, e);
      return;
    }
    if (!decision.ok) return;

    const authorId = reply.authorId as string;
    const recipients = replyRecipients({
      replyAuthorId: authorId,
      reviewAuthorId: reviewId, // review doc id == reviewer uid
      mentions: reply.mentions,
    });
    if (recipients.length === 0) return;

    try {
      const [actor, exp] = await Promise.all([
        resolveActor(authorId),
        db.collection(EXPERIENCES).doc(experienceId).get(),
      ]);
      const title = snippet(exp.data()?.title, 60);
      const body = rawText(snippet(reply.text) || title);
      await Promise.all(recipients.map((r) => emitNotification({
        recipientId: r.uid,
        type: r.type,
        title: r.type === 'experience_mention'
          ? lt('srvMentionedYouInReviewReply')
          : lt('srvRepliedToYourReview'),
        body,
        data: {
          action: 'experience',
          experienceId,
          reviewId,
        },
        actor,
      }).catch((e) => console.error(`reply notify ${r.uid} failed:`, e))));
    } catch (e) {
      console.error(`reply notify failed (${experienceId}/${reviewId}):`, e);
    }
  },
);
