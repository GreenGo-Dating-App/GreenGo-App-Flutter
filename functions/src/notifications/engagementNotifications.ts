/**
 * Engagement notifications (NEW): profile views (throttled), ticket QR scans,
 * and boost start/end. See notifyHelpers for the shared emit.
 */
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import { resolveActor, emitNotification } from './notifyHelpers';
import '../shared/firebaseAdmin';

const db = admin.firestore();

// ── m) Someone viewed your profile — throttled to 1 per viewer per day ───────
export const onProfileViewed = onDocumentCreated(
  'user_interactions/{viewerId}/events/{eventId}',
  monitored('onProfileViewed', async (event) => {
    const d = event.data?.data();
    if (!d || d.type !== 'profile_view') return;

    const viewerId = event.params.viewerId as string;
    const targetId = (d.targetId as string) || '';
    if (!targetId || targetId === viewerId) return;

    // Throttle: at most one "viewed your profile" per viewer→target per day.
    const day = new Date().toISOString().slice(0, 10); // yyyy-mm-dd (UTC)
    const dedupRef = db
      .collection('notif_dedup')
      .doc(`pv_${targetId}_${viewerId}_${day}`);
    try {
      await dedupRef.create({ at: admin.firestore.FieldValue.serverTimestamp() });
    } catch {
      return; // already notified today
    }

    const actor = await resolveActor(viewerId);
    await emitNotification({
      recipientId: targetId,
      type: 'profile_view',
      title: 'viewed your profile',
      body: 'Tap to see who stopped by',
      data: { type: 'profile_view', action: 'open_profile', profileId: viewerId, actorId: viewerId },
      actor,
    });
  }),
);

// ── j) Your event ticket QR is being scanned ─────────────────────────────────
export const onTicketScanned = onDocumentUpdated(
  'events/{eventId}/attendees/{userId}',
  monitored('onTicketScanned', async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    // Only on the check-in transition (false → true).
    if (before.checkedIn === true || after.checkedIn !== true) return;

    const eventId = event.params.eventId as string;
    const attendeeId = event.params.userId as string;

    const eSnap = await db.collection('events').doc(eventId).get();
    const title = (eSnap.data()?.title as string) || 'your event';

    await emitNotification({
      recipientId: attendeeId,
      type: 'qr_scanned',
      title: `Your ticket for ${title} was scanned`,
      body: "You're checked in — enjoy!",
      data: { type: 'qr_scanned', eventId, action: 'open_event' },
    });
  }),
);

// ── o) / q) Boost STARTED — profile / event ──────────────────────────────────
function isFutureTs(v: unknown): boolean {
  return v instanceof admin.firestore.Timestamp && v.toDate().getTime() > Date.now();
}

export const onProfileBoostStarted = onDocumentUpdated(
  'profiles/{uid}',
  monitored('onProfileBoostStarted', async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    const b = before.businessPromotedUntil;
    const a = after.businessPromotedUntil;
    // Started when it became a future time and actually changed.
    if (!isFutureTs(a)) return;
    if (b instanceof admin.firestore.Timestamp && a instanceof admin.firestore.Timestamp &&
        b.toMillis() === a.toMillis()) return;
    // Reset the "ended" flag for the new cycle.
    await event.data!.after.ref.set({ boostEndNotified: false }, { merge: true });
    await emitNotification({
      recipientId: event.params.uid as string,
      type: 'boost_started',
      title: 'Your profile boost is now live',
      body: 'Your profile is being promoted to more people',
      data: { type: 'boost_started', subject: 'profile', action: 'open_profile' },
    });
  }),
);

export const onEventBoostStarted = onDocumentUpdated(
  'events/{eventId}',
  monitored('onEventBoostStarted', async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    const wasFeatured = before.isFeatured === true && isFutureTs(before.featuredUntil);
    const nowFeatured = after.isFeatured === true && isFutureTs(after.featuredUntil);
    if (wasFeatured || !nowFeatured) return;
    const organizerId = (after.organizerId as string) || '';
    if (!organizerId) return;
    await event.data!.after.ref.set({ boostEndNotified: false }, { merge: true });
    await emitNotification({
      recipientId: organizerId,
      type: 'boost_started',
      title: `Your event ${(after.title as string) || ''} boost is now live`.trim(),
      body: 'Your event is being promoted in Explore',
      data: { type: 'boost_started', subject: 'event', eventId: event.params.eventId as string, action: 'open_event' },
    });
  }),
);

// ── p) / r) Boost ENDED — hourly sweep of expired boosts ─────────────────────
export const checkBoostExpiries = onSchedule('every 60 minutes', async () => {
  const now = admin.firestore.Timestamp.now();
  const since = admin.firestore.Timestamp.fromMillis(now.toMillis() - 3 * 60 * 60 * 1000);

  // Profiles whose boost expired in the last 3h and weren't yet notified.
  const profiles = await db
    .collection('profiles')
    .where('businessPromotedUntil', '>', since)
    .where('businessPromotedUntil', '<=', now)
    .limit(200)
    .get();
  for (const doc of profiles.docs) {
    if (doc.data().boostEndNotified === true) continue;
    await doc.ref.set({ boostEndNotified: true }, { merge: true });
    await emitNotification({
      recipientId: doc.id,
      type: 'boost_ended',
      title: 'Your profile boost has ended',
      body: 'Boost again to keep reaching more people',
      data: { type: 'boost_ended', subject: 'profile', action: 'open_profile' },
    });
  }

  // Events whose feature window expired in the last 3h.
  const events = await db
    .collection('events')
    .where('featuredUntil', '>', since)
    .where('featuredUntil', '<=', now)
    .limit(200)
    .get();
  for (const doc of events.docs) {
    const e = doc.data();
    if (e.boostEndNotified === true) continue;
    const organizerId = (e.organizerId as string) || '';
    if (!organizerId) continue;
    await doc.ref.set({ boostEndNotified: true }, { merge: true });
    await emitNotification({
      recipientId: organizerId,
      type: 'boost_ended',
      title: `Your event ${(e.title as string) || ''} boost has ended`.trim(),
      body: 'Boost again to keep it featured',
      data: { type: 'boost_ended', subject: 'event', eventId: doc.id, action: 'open_event' },
    });
  }
});
