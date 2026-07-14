/**
 * Event admin broadcast fan-out (NEW, isolated module).
 *
 * When an organizer posts a broadcast (isBroadcast === true) in an event's
 * messages subcollection, push an FCM notification to every attendee (excluding
 * the sender, muted attendees, and those who left). Mirrors the group-chat
 * fan-out pattern. Events have no attendee cap, so tokens are sent in chunks.
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

const db = admin.firestore();
const FCM_CHUNK = 500;

export const onEventBroadcastCreated = onDocumentCreated(
  'events/{eventId}/messages/{messageId}',
  monitored("onEventBroadcastCreated", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const msg = snap.data() as Record<string, unknown>;
    if (msg.isBroadcast !== true) return;

    const eventId = event.params.eventId as string;
    const senderId = (msg.senderId as string) || '';
    const text = (msg.text as string) || '';

    const eventDoc = await db.collection('events').doc(eventId).get();
    const title = (eventDoc.data()?.title as string) || 'Event';

    const attendeesSnap = await db
      .collection('events')
      .doc(eventId)
      .collection('attendees')
      .get();

    const recipientIds = attendeesSnap.docs
      .filter((d) => {
        const a = d.data();
        if (d.id === senderId) return false;
        if (a.muteNotifications === true) return false;
        if (a.leftAt) return false;
        return true;
      })
      .map((d) => d.id);
    if (recipientIds.length === 0) return;

    const tokenDocs = await Promise.all(
      recipientIds.map((u) => db.collection('users').doc(u).get())
    );
    const tokens: string[] = [];
    for (const td of tokenDocs) {
      const t = td.data()?.fcmToken as string | undefined;
      if (t) tokens.push(t);
    }
    if (tokens.length === 0) return;

    for (let i = 0; i < tokens.length; i += FCM_CHUNK) {
      const chunk = tokens.slice(i, i + FCM_CHUNK);
      try {
        await admin.messaging().sendEachForMulticast({
          tokens: chunk,
          notification: { title: `📣 ${title}`, body: text },
          data: { type: 'event_broadcast', eventId },
          android: { priority: 'high' },
        });
      } catch (e) {
        console.error('Event broadcast FCM failed', e);
      }
    }

    // Also write an in-app notification doc per attendee so the announcement
    // appears on the notifications page (case s). Batched (≤450 ops/commit).
    let batch = db.batch();
    let ops = 0;
    const commits: Promise<unknown>[] = [];
    for (const uid of recipientIds) {
      batch.set(db.collection('notifications').doc(), {
        userId: uid,
        type: 'event_announcement',
        title: `Announcement · ${title}`,
        message: text,
        body: text,
        data: { type: 'event_announcement', eventId, action: 'open_event' },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      if (++ops >= 450) {
        commits.push(batch.commit());
        batch = db.batch();
        ops = 0;
      }
    }
    if (ops > 0) commits.push(batch.commit());
    await Promise.all(commits);
  })
);

/// Regular event-chat messages → push to all attendees (except sender/muted),
/// matching the 1:1/group notification sound + channel so they appear even when
/// the app is closed.
export const onEventMessageCreated = onDocumentCreated(
  'events/{eventId}/messages/{messageId}',
  monitored("onEventMessageCreated", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const msg = snap.data() as Record<string, unknown>;
    if (msg.isBroadcast === true) return; // handled by onEventBroadcastCreated

    const eventId = event.params.eventId as string;
    const senderId = (msg.senderId as string) || '';
    const senderName = (msg.senderName as string) || '';
    const text = (msg.text as string) || '';

    const eventDoc = await db.collection('events').doc(eventId).get();
    const title = (eventDoc.data()?.title as string) || 'Event';

    const attendeesSnap = await db
      .collection('events')
      .doc(eventId)
      .collection('attendees')
      .get();

    const recipientIds = attendeesSnap.docs
      .filter((d) => {
        const a = d.data();
        if (d.id === senderId) return false;
        if (a.muteNotifications === true) return false;
        if (a.leftAt) return false;
        return true;
      })
      .map((d) => d.id);
    if (recipientIds.length === 0) return;

    const tokenDocs = await Promise.all(
      recipientIds.map((u) => db.collection('users').doc(u).get())
    );
    const tokens: string[] = [];
    for (const td of tokenDocs) {
      const t = td.data()?.fcmToken as string | undefined;
      if (t) tokens.push(t);
    }
    if (tokens.length === 0) return;

    const body = senderName ? `${senderName}: ${text}` : text;
    for (let i = 0; i < tokens.length; i += FCM_CHUNK) {
      const chunk = tokens.slice(i, i + FCM_CHUNK);
      try {
        await admin.messaging().sendEachForMulticast({
          tokens: chunk,
          notification: { title, body },
          data: { type: 'event_message', eventId, conversationId: eventId },
          android: {
            priority: 'high',
            collapseKey: `event_${eventId}`,
            notification: {
              sound: 'default',
              channelId: 'greengo_notifications',
              priority: 'high' as any,
              tag: `event_${eventId}`,
            },
          },
          apns: {
            headers: { 'apns-collapse-id': `event_${eventId}` },
            payload: { aps: { sound: 'default', badge: 1 } },
          },
        });
      } catch (e) {
        console.error('Event message FCM failed', e);
      }
    }
  })
);
