/**
 * Event reminders (NEW, isolated module).
 *
 * Hourly scheduled function: finds events starting within the next 24h that
 * haven't been reminded yet, and pushes an FCM reminder to their attendees
 * (excluding muted / left). Marks `reminderSent` to avoid duplicates.
 *
 * Uses a single-field startDate range query (no composite index); status and
 * reminderSent are filtered in code.
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

const db = admin.firestore();
const FCM_CHUNK = 500;

export const sendEventReminders = onSchedule('every 60 minutes', monitored("sendEventReminders", async () => {
  const now = admin.firestore.Timestamp.now();
  const in24h = admin.firestore.Timestamp.fromMillis(
    now.toMillis() + 24 * 60 * 60 * 1000
  );

  const snap = await db
    .collection('events')
    .where('startDate', '>=', now)
    .where('startDate', '<=', in24h)
    .get();

  for (const doc of snap.docs) {
    const e = doc.data();
    if (e.status !== 'published') continue;
    if (e.reminderSent === true) continue;

    const title = (e.title as string) || 'Event';
    const attendeesSnap = await doc.ref.collection('attendees').get();
    const recipientIds = attendeesSnap.docs
      .filter((d) => {
        const a = d.data();
        if (a.muteNotifications === true) return false;
        if (a.leftAt) return false;
        return true;
      })
      .map((d) => d.id);

    if (recipientIds.length > 0) {
      const tokenDocs = await Promise.all(
        recipientIds.map((u) => db.collection('users').doc(u).get())
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
            notification: {
              title: `⏰ ${title}`,
              body: 'Starting soon — see you there!',
            },
            data: { type: 'event_reminder', eventId: doc.id },
            android: { priority: 'high' },
          });
        } catch (err) {
          console.error('Event reminder FCM failed', doc.id, err);
        }
      }
    }

    await doc.ref.update({ reminderSent: true });
  }
}));
