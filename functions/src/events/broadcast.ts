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
import '../shared/firebaseAdmin';

const db = admin.firestore();
const FCM_CHUNK = 500;

export const onEventBroadcastCreated = onDocumentCreated(
  'events/{eventId}/messages/{messageId}',
  async (event) => {
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
  }
);
