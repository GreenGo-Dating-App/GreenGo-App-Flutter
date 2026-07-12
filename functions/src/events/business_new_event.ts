/**
 * Business new-event → followers push fan-out (NEW, isolated module).
 *
 * PART (B) of the push-delivery filter: when a business account publishes a new
 * event, push an FCM notification to every user that FOLLOWS that business, and
 * write a matching in-app `notifications` doc for each follower so it also
 * appears on the notification page.
 *
 * Fires on:
 *   - events/{eventId} onCreate  — an event created already `published`.
 *   - events/{eventId} onUpdate  — a draft/scheduled event transitioning INTO
 *                                  `published`.
 *
 * Gating (all must hold to push):
 *   1. eventData.status === 'published'
 *   2. profiles/{organizerId}.isBusiness === true
 *
 * Idempotency: an event fans out to followers AT MOST ONCE. A `pushedToFollowers`
 * flag is claimed transactionally on the event doc before any fan-out; if the
 * flag is already set (concurrent trigger, function retry, or a later edit) the
 * run is skipped. This guards both the onCreate/onUpdate overlap and Cloud
 * Functions at-least-once retries.
 *
 * Scale: designed for businesses with thousands of followers. Followers are
 * PAGED from `business_followers/{organizerId}/followers` (FOLLOWER_PAGE at a
 * time); per page we batch the FCM tokens and multicast in chunks of 500, and
 * write the in-app notification docs in ≤450-op batches. No unbounded in-memory
 * accumulation and no client-side follower iteration.
 *
 * TODO(cf-autopublish): `scheduled` events currently go live purely via
 * client-side query filtering (feeds treat now>=publishAt as live) WITHOUT any
 * doc write, so the onUpdate publish transition never fires for them and their
 * followers get no push. An optional scheduled Cloud Function could periodically
 * flip due `scheduled` events to `published` (a real doc write), which would then
 * trigger this follower fan-out. Not built here.
 */

import {
  onDocumentCreated,
  onDocumentUpdated,
} from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

const db = admin.firestore();

const FCM_CHUNK = 500; // Firebase Admin multicast hard limit.
const FOLLOWER_PAGE = 500; // Followers read per page.
const BATCH_LIMIT = 450; // In-app notification writes per batch commit.

function eventPreview(title: string): string {
  return title.length > 120 ? `${title.substring(0, 117)}...` : title;
}

/**
 * Fan out a "new event" push + in-app notification to every follower of the
 * organizing business. Idempotent via the `pushedToFollowers` flag.
 */
async function fanOutNewEventToFollowers(
  eventId: string,
  eventData: admin.firestore.DocumentData,
  eventRef: admin.firestore.DocumentReference,
): Promise<void> {
  // Gate 1: only published events.
  if (eventData.status !== 'published') return;
  // Quick pre-check (cheap short-circuit; the transaction below is authoritative).
  if (eventData.pushedToFollowers === true) return;

  const organizerId = (eventData.organizerId as string) || '';
  if (!organizerId) return;

  // Gate 2: organizer must be a business account.
  const profileSnap = await db.collection('profiles').doc(organizerId).get();
  const profile = profileSnap.data() || {};
  if (profile.isBusiness !== true) return;

  const businessName =
    (profile.businessName as string) ||
    (profile.name as string) ||
    (profile.nickname as string) ||
    (eventData.organizerName as string) ||
    'A business you follow';

  // Claim the idempotency flag transactionally BEFORE any fan-out so concurrent
  // triggers / retries can never double-send.
  const claimed = await db.runTransaction(async (txn) => {
    const fresh = await txn.get(eventRef);
    if (!fresh.exists) return false;
    if (fresh.data()?.pushedToFollowers === true) return false;
    txn.update(eventRef, {
      pushedToFollowers: true,
      pushedToFollowersAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return true;
  });
  if (!claimed) return;

  const eventTitle = (eventData.title as string) || 'New event';
  const eventImage = (eventData.imageUrl as string) || undefined;
  const title = `New event from ${businessName}`;
  const body = eventPreview(eventTitle);
  const dataPayload: Record<string, string> = {
    type: 'new_event',
    eventId,
    organizerId,
    action: 'open_event',
  };

  const followersCol = db
    .collection('business_followers')
    .doc(organizerId)
    .collection('followers');

  let lastDoc: admin.firestore.QueryDocumentSnapshot | undefined;
  let totalFollowers = 0;

  // Page through followers so memory stays bounded for large audiences.
  // eslint-disable-next-line no-constant-condition
  while (true) {
    let q = followersCol
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(FOLLOWER_PAGE);
    if (lastDoc) q = q.startAfter(lastDoc);

    const page = await q.get();
    if (page.empty) break;

    lastDoc = page.docs[page.docs.length - 1];
    const followerIds = page.docs.map((d) => d.id);
    totalFollowers += followerIds.length;

    // Resolve FCM tokens (users/{uid}.fcmToken) for this page.
    const userDocs = await Promise.all(
      followerIds.map((uid) => db.collection('users').doc(uid).get()),
    );
    const tokens: string[] = [];
    for (const ud of userDocs) {
      const t = ud.data()?.fcmToken as string | undefined;
      if (t) tokens.push(t);
    }

    // Push (chunked at the multicast limit).
    for (let i = 0; i < tokens.length; i += FCM_CHUNK) {
      const chunk = tokens.slice(i, i + FCM_CHUNK);
      try {
        await admin.messaging().sendEachForMulticast({
          tokens: chunk,
          notification: {
            title,
            body,
            ...(eventImage ? { imageUrl: eventImage } : {}),
          },
          data: dataPayload,
          android: {
            priority: 'high',
            collapseKey: `event_new_${eventId}`,
            notification: {
              sound: 'default',
              channelId: 'greengo_notifications',
              priority: 'high' as any,
              tag: `event_new_${eventId}`,
              ...(eventImage ? { imageUrl: eventImage } : {}),
            },
          },
          apns: {
            headers: { 'apns-collapse-id': `event_new_${eventId}` },
            payload: { aps: { sound: 'default', badge: 1 } },
          },
        });
      } catch (e) {
        // Best-effort: never fail the trigger on notification errors.
        console.error('Business new-event FCM multicast failed', eventId, e);
      }
    }

    // In-app notification doc per follower (matches Flutter NotificationModel:
    // userId, type, title, message, createdAt, isRead[, data]). Batched.
    let batch = db.batch();
    let ops = 0;
    const commits: Promise<unknown>[] = [];
    for (const uid of followerIds) {
      const ref = db.collection('notifications').doc();
      batch.set(ref, {
        userId: uid,
        type: 'new_event',
        title,
        message: body, // Flutter NotificationModel reads `message`
        body, // legacy field for older clients
        data: dataPayload,
        imageUrl: eventImage ?? null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      });
      ops++;
      if (ops >= BATCH_LIMIT) {
        commits.push(batch.commit());
        batch = db.batch();
        ops = 0;
      }
    }
    if (ops > 0) commits.push(batch.commit());
    await Promise.all(commits);

    if (page.size < FOLLOWER_PAGE) break; // last page
  }

  console.log(
    `Business new-event ${eventId} fanned out to ${totalFollowers} follower(s) of ${organizerId}`,
  );
}

/** Event created already in the `published` state. */
export const onEventCreatedNotifyFollowers = onDocumentCreated(
  'events/{eventId}',
  monitored('onEventCreatedNotifyFollowers', async (event) => {
    const snap = event.data;
    if (!snap) return;
    const eventId = event.params.eventId as string;
    await fanOutNewEventToFollowers(eventId, snap.data(), snap.ref);
  }),
);

/** Event transitioning INTO `published` (draft/scheduled → published). */
export const onEventPublishedNotifyFollowers = onDocumentUpdated(
  'events/{eventId}',
  monitored('onEventPublishedNotifyFollowers', async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Only act on a transition INTO published (the `pushedToFollowers` flag is
    // the real double-send guard, but this avoids needless work on every edit).
    if (before.status === 'published') return;
    if (after.status !== 'published') return;

    const eventId = event.params.eventId as string;
    await fanOutNewEventToFollowers(eventId, after, event.data!.after.ref);
  }),
);
