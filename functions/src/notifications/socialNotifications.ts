/**
 * Social notifications (NEW, isolated module).
 *
 * Emits an in-app notification (+ FCM push) with the ACTOR's avatar + name to
 * the owner/organizer when someone acts on their thing:
 *   - joins your community        (communities/{id}/members/{uid} onCreate)
 *   - joins your event            (events/{id}/attendees/{uid} onCreate)
 *   - follows your business       (business_followers/{bizId}/followers/{uid})
 *   - rates your business         (business_ratings/{bizId}/ratings/{uid})
 *   - likes your event            (events/{id}/likes/{uid} onCreate)
 *
 * Titles are stored WITHOUT the actor's name (the Flutter tile renders
 * `actorName` as a bold, tappable span). `imageUrl`/`actorId`/`actorName` drive
 * the tile's left avatar + name-tap → actor profile.
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

const db = admin.firestore();

interface Actor {
  id: string;
  name: string;
  photo?: string;
}

/** Resolve an actor's display name + avatar from their profile. */
async function resolveActor(actorId: string): Promise<Actor> {
  try {
    const snap = await db.collection('profiles').doc(actorId).get();
    const p = snap.data() || {};
    const name =
      (p.displayName as string) ||
      (p.nickname as string) ||
      (p.name as string) ||
      'Someone';
    const photo =
      (p.profilePhotoUrl as string) ||
      (Array.isArray(p.photos) ? (p.photos[0] as string) : undefined) ||
      (Array.isArray(p.photoUrls) ? (p.photoUrls[0] as string) : undefined);
    return { id: actorId, name, photo };
  } catch {
    return { id: actorId, name: 'Someone' };
  }
}

/**
 * Emit one notification to [recipientId]: an in-app `notifications` doc carrying
 * the actor identity, plus a best-effort FCM push if the recipient has a token.
 */
async function emit(
  recipientId: string,
  type: string,
  title: string,
  body: string,
  data: Record<string, string>,
  actor: Actor,
): Promise<void> {
  if (!recipientId || recipientId === actor.id) return;

  // In-app doc (Flutter NotificationModel shape + actor fields).
  await db.collection('notifications').add({
    userId: recipientId,
    type,
    title,
    message: body,
    body,
    data,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    actorId: actor.id,
    actorName: actor.name,
    ...(actor.photo ? { imageUrl: actor.photo } : {}),
  });

  // Best-effort push.
  try {
    const userSnap = await db.collection('users').doc(recipientId).get();
    const token = userSnap.data()?.fcmToken as string | undefined;
    if (token) {
      await admin.messaging().send({
        token,
        notification: {
          title: `${actor.name} ${title}`,
          body,
          ...(actor.photo ? { imageUrl: actor.photo } : {}),
        },
        data,
        android: {
          priority: 'high',
          notification: { sound: 'default', channelId: 'greengo_notifications' },
        },
        apns: { payload: { aps: { sound: 'default', badge: 1 } } },
      });
    }
  } catch {
    // Never fail the trigger on a push error.
  }
}

// ── e) Someone joined your community ────────────────────────────────────────
export const onCommunityMemberJoined = onDocumentCreated(
  'communities/{communityId}/members/{userId}',
  monitored('onCommunityMemberJoined', async (event) => {
    const communityId = event.params.communityId as string;
    const userId = event.params.userId as string;

    const cSnap = await db.collection('communities').doc(communityId).get();
    const c = cSnap.data();
    if (!c) return;
    const ownerId = (c.createdByUserId as string) || '';
    if (!ownerId || ownerId === userId) return; // creator auto-joins

    const actor = await resolveActor(userId);
    await emit(
      ownerId,
      'community_join',
      `joined your community ${(c.name as string) || ''}`.trim(),
      (c.name as string) || 'Your community',
      { type: 'community_join', communityId, action: 'open_community', actorId: userId },
      actor,
    );
  }),
);

// ── f) Someone joined your event ────────────────────────────────────────────
export const onEventAttendeeJoined = onDocumentCreated(
  'events/{eventId}/attendees/{userId}',
  monitored('onEventAttendeeJoined', async (event) => {
    const eventId = event.params.eventId as string;
    const userId = event.params.userId as string;
    const status = (event.data?.data()?.status as string) || '';
    if (status && status !== 'going') return; // only real RSVPs

    const eSnap = await db.collection('events').doc(eventId).get();
    const e = eSnap.data();
    if (!e) return;
    const organizerId = (e.organizerId as string) || '';
    if (!organizerId || organizerId === userId) return;

    const actor = await resolveActor(userId);
    await emit(
      organizerId,
      'event_join',
      `joined your event ${(e.title as string) || ''}`.trim(),
      (e.title as string) || 'Your event',
      { type: 'event_join', eventId, action: 'open_event', actorId: userId },
      actor,
    );
  }),
);

// ── w) Someone follows your business ────────────────────────────────────────
export const onBusinessFollowed = onDocumentCreated(
  'business_followers/{businessId}/followers/{userId}',
  monitored('onBusinessFollowed', async (event) => {
    const businessId = event.params.businessId as string;
    const userId = event.params.userId as string;
    if (businessId === userId) return;

    const actor = await resolveActor(userId);
    await emit(
      businessId,
      'business_follow',
      'started following your business',
      'You have a new follower',
      { type: 'business_follow', businessId, action: 'open_profile', profileId: userId, actorId: userId },
      actor,
    );
  }),
);

// ── u) Someone rated your business ──────────────────────────────────────────
export const onBusinessRated = onDocumentCreated(
  'business_ratings/{businessId}/ratings/{userId}',
  monitored('onBusinessRated', async (event) => {
    const businessId = event.params.businessId as string;
    const userId = event.params.userId as string;
    if (businessId === userId) return;
    const stars = (event.data?.data()?.rating as number) || 0;

    const actor = await resolveActor(userId);
    await emit(
      businessId,
      'business_rating',
      stars > 0 ? `rated your business ${stars}★` : 'rated your business',
      'You have a new rating',
      { type: 'business_rating', businessId, action: 'open_profile', profileId: businessId, actorId: userId },
      actor,
    );
  }),
);

// ── n) Someone liked your event ─────────────────────────────────────────────
export const onEventLiked = onDocumentCreated(
  'events/{eventId}/likes/{userId}',
  monitored('onEventLiked', async (event) => {
    const eventId = event.params.eventId as string;
    const userId = event.params.userId as string;

    const eSnap = await db.collection('events').doc(eventId).get();
    const e = eSnap.data();
    if (!e) return;
    const organizerId = (e.organizerId as string) || '';
    if (!organizerId || organizerId === userId) return;

    const actor = await resolveActor(userId);
    await emit(
      organizerId,
      'event_like',
      `liked your event ${(e.title as string) || ''}`.trim(),
      (e.title as string) || 'Your event',
      { type: 'event_like', eventId, action: 'open_event', actorId: userId },
      actor,
    );
  }),
);
