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
import { brandPush, messagePush } from '../notifications/brand';
import { filterUidsByPref } from '../notifications/prefs';
import { monitored } from '../shared/monitoring';
import { PUSH_MEMORY } from '../shared/pushRuntime';
import '../shared/firebaseAdmin';
import { LText, lt, notifTextFields, rawText, render, t } from '../shared/i18n';
import { pushRecipientsFromUserDocs, sendLocalizedMulticast } from '../notifications/localizedPush';

const db = admin.firestore();
const FCM_CHUNK = 500;

export const onEventBroadcastCreated = onDocumentCreated(
  {
    document: 'events/{eventId}/messages/{messageId}',
    memory: PUSH_MEMORY,
  },
  monitored("onEventBroadcastCreated", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const msg = snap.data() as Record<string, unknown>;
    if (msg.isBroadcast !== true) return;

    const eventId = event.params.eventId as string;
    const senderId = (msg.senderId as string) || '';
    const text = (msg.text as string) || '';

    const eventDoc = await db.collection('events').doc(eventId).get();
    const eventTitle = ((eventDoc.data()?.title as string) || '').trim();
    const eventImage = (eventDoc.data()?.imageUrl as string) || undefined;
    const pushTitle: LText = eventTitle
      ? lt('srvAnnouncementTitle', { name: eventTitle })
      : lt('srvAnnouncementAnEvent');
    const feedTitle: LText = eventTitle
      ? lt('notifServerAnnouncement', { name: eventTitle })
      : lt('srvAnnouncementAnEvent');

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
    const recipients = pushRecipientsFromUserDocs(tokenDocs);
    if (recipients.length === 0) return;

    await sendLocalizedMulticast(
      recipients,
      (locale) => ({
        notification: brandPush(render(locale, pushTitle), text, eventImage),
        data: { type: 'event_broadcast', eventId },
        android: { priority: 'high' },
      }),
      'Event broadcast FCM',
    );

    // Also write an in-app notification doc per attendee so the announcement
    // appears on the notifications page (case s). Batched (≤450 ops/commit).
    let batch = db.batch();
    let ops = 0;
    const commits: Promise<unknown>[] = [];
    for (const uid of recipientIds) {
      batch.set(db.collection('notifications').doc(), {
        userId: uid,
        type: 'event_announcement',
        ...notifTextFields(feedTitle, rawText(text)),
        data: { type: 'event_announcement', eventId, action: 'open_event' },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        // Attendees were already multicast above — skip the parity trigger.
        pushSent: true,
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
  {
    document: 'events/{eventId}/messages/{messageId}',
    memory: PUSH_MEMORY,
  },
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
    const title = ((eventDoc.data()?.title as string) || '').trim();
    const eventImage = (eventDoc.data()?.imageUrl as string) || undefined;

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

    // Per-category notification preference (event chats). Honors the user's
    // "Event chats" toggle — previously event-chat messages ignored prefs.
    const allowedSet = await filterUidsByPref(recipientIds, 'eventsChat');
    const prefRecipients = recipientIds.filter((u) => allowedSet.has(u));
    if (prefRecipients.length === 0) return;

    const tokenDocs = await Promise.all(
      prefRecipients.map((u) => db.collection('users').doc(u).get())
    );
    const recipients = pushRecipientsFromUserDocs(tokenDocs);
    if (recipients.length === 0) return;

    await sendLocalizedMulticast(
      recipients,
      (locale) => ({
          // Title = the sender's name, body = the message (2026-10-03).
          notification: messagePush(
            senderName || title || t(locale, 'srvUnknownUser'),
            text,
            eventImage,
          ),
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
      }),
      'Event message FCM',
    );
  })
);
