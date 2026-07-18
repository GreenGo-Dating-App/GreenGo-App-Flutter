/**
 * Event reminders (NEW, isolated module).
 *
 * Hourly scheduled function with THREE reminder windows for events an attendee
 * has joined: 24h before, 6h before, and "just started". Each window fires at
 * most once (per-window flags `reminded24h`/`reminded6h`/`remindedStart`), pushes
 * an FCM reminder AND writes an in-app `notifications` doc (so it shows on the
 * notifications page). Single-field startDate range query (no composite index);
 * status + flags filtered in code.
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { brandPush } from '../notifications/brand';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

const db = admin.firestore();
const FCM_CHUNK = 500;
const HOUR = 60 * 60 * 1000;

async function fanOutReminder(
  eventId: string,
  eventRef: admin.firestore.DocumentReference,
  title: string,
  body: string,
  flag: string,
): Promise<void> {
  const attendeesSnap = await eventRef.collection('attendees').get();
  const recipientIds = attendeesSnap.docs
    .filter((d) => {
      const a = d.data();
      return a.muteNotifications !== true && !a.leftAt;
    })
    .map((d) => d.id);

  // Claim the window flag first (idempotent across retries).
  await eventRef.update({ [flag]: true });
  if (recipientIds.length === 0) return;

  const dataPayload = { type: 'event_reminder', eventId, action: 'open_event' };

  // FCM.
  const tokenDocs = await Promise.all(
    recipientIds.map((u) => db.collection('users').doc(u).get()),
  );
  const tokens: string[] = [];
  for (const td of tokenDocs) {
    const t = td.data()?.fcmToken as string | undefined;
    if (t) tokens.push(t);
  }
  for (let i = 0; i < tokens.length; i += FCM_CHUNK) {
    const chunk = tokens.slice(i, i + FCM_CHUNK);
    try {
      await admin.messaging().sendEachForMulticast({
        tokens: chunk,
        notification: brandPush(`⏰ ${title}`, body),
        data: dataPayload,
        android: { priority: 'high' },
      });
    } catch (err) {
      console.error('Event reminder FCM failed', eventId, err);
    }
  }

  // In-app docs (batched).
  let batch = db.batch();
  let ops = 0;
  const commits: Promise<unknown>[] = [];
  for (const uid of recipientIds) {
    batch.set(db.collection('notifications').doc(), {
      userId: uid,
      type: 'event_reminder',
      title,
      message: body,
      body,
      data: dataPayload,
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
}

export const sendEventReminders = onSchedule(
  'every 60 minutes',
  monitored('sendEventReminders', async () => {
    const nowMs = admin.firestore.Timestamp.now().toMillis();
    // Cover all three windows: started (up to 1h ago) → 24h ahead.
    const from = admin.firestore.Timestamp.fromMillis(nowMs - HOUR);
    const to = admin.firestore.Timestamp.fromMillis(nowMs + 24 * HOUR);

    const snap = await db
      .collection('events')
      .where('startDate', '>=', from)
      .where('startDate', '<=', to)
      .get();

    for (const doc of snap.docs) {
      const e = doc.data();
      if (e.status !== 'published') continue;
      const startMs = (e.startDate as admin.firestore.Timestamp)?.toMillis?.();
      if (!startMs) continue;
      const title = (e.title as string) || 'Event';
      const dt = startMs - nowMs; // ms until start (negative = already started)

      try {
        if (dt <= 0 && dt > -HOUR && e.remindedStart !== true) {
          await fanOutReminder(doc.id, doc.ref, title,
            'is starting now — enjoy!', 'remindedStart');
        } else if (dt > 0 && dt <= 6 * HOUR && e.reminded6h !== true) {
          await fanOutReminder(doc.id, doc.ref, title,
            'starts in about 6 hours', 'reminded6h');
        } else if (dt > 6 * HOUR && dt <= 24 * HOUR && e.reminded24h !== true) {
          await fanOutReminder(doc.id, doc.ref, title,
            'is tomorrow — see you there!', 'reminded24h');
        }
      } catch (err) {
        console.error('sendEventReminders event failed', doc.id, err);
      }
    }
  }),
);
