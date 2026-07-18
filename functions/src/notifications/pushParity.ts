/**
 * Push notification parity (NEW, isolated module).
 *
 * GOAL: every in-app notification doc created in the `notifications` collection
 * ALSO delivers an FCM push to that user's phone — WITHOUT double-pushing the
 * many notification types that already send their own push.
 *
 * How the double-push is avoided: every existing Cloud Function that both writes
 * a `notifications` doc AND sends its own FCM push now stamps `pushSent: true`
 * on the doc it writes. This trigger reads the created doc and:
 *   - RETURNS immediately if `pushSent === true` (someone already pushed it), else
 *   - resolves the recipient's fcmToken and sends a best-effort push using the
 *     doc's own `title`, `message`/`body` and `data` map, then marks the doc
 *     `pushSent: true` so a retry can't re-push.
 *
 * Notification writers that DON'T push (coin gifts, gamification, subscriptions,
 * call/video, admin-index, etc.) are intentionally left unmarked — this trigger
 * is what finally delivers their push. That is the parity win.
 *
 * Fires on: notifications/{notifId} onCreate. Never throws.
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { brandPush } from './brand';
import { shouldNotify, categoryForType } from './prefs';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

const db = admin.firestore();

/** Coerce an arbitrary notification `data` map into FCM's string→string shape. */
function stringifyData(
  raw: unknown,
  type: string,
): Record<string, string> {
  const out: Record<string, string> = {};
  if (raw && typeof raw === 'object') {
    for (const [k, v] of Object.entries(raw as Record<string, unknown>)) {
      if (v === null || v === undefined) continue;
      out[k] = typeof v === 'string' ? v : JSON.stringify(v);
    }
  }
  // Ensure the app always has a `type` to route on.
  if (!out.type && type) out.type = type;
  return out;
}

export const onNotificationCreatedPush = onDocumentCreated(
  'notifications/{notifId}',
  monitored('onNotificationCreatedPush', async (event) => {
    const snap = event.data;
    if (!snap) return;
    const doc = snap.data() as Record<string, unknown>;
    if (!doc) return;

    // Another function already pushed this one — do nothing.
    if (doc.pushSent === true) return;

    const userId =
      (doc.userId as string) ||
      (doc.recipientId as string) ||
      (doc.uid as string) ||
      '';
    if (!userId) return;

    const title = (doc.title as string) || '';
    const body =
      (doc.message as string) ||
      (doc.body as string) ||
      '';
    const type = (doc.type as string) || 'notification';
    const data = stringifyData(doc.data, type);
    const imageUrl = (doc.imageUrl as string) || undefined;

    // Respect the user's per-category notification preference. If they disabled
    // this category (or push), keep the in-app feed doc but skip the push and
    // mark it handled so the trigger doesn't retry.
    if (!(await shouldNotify(userId, categoryForType(type)))) {
      try {
        await snap.ref.update({ pushSent: true });
      } catch {
        // ignore
      }
      return;
    }

    // Best-effort push — never throw out of the trigger.
    try {
      const userSnap = await db.collection('users').doc(userId).get();
      const token = userSnap.data()?.fcmToken as string | undefined;
      if (token) {
        await admin.messaging().send({
          token,
          notification: brandPush(title, body, imageUrl),
          data,
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              channelId: 'greengo_notifications',
              ...(imageUrl ? { imageUrl } : {}),
            },
          },
          apns: { payload: { aps: { sound: 'default', badge: 1 } } },
        });
      }
    } catch (e) {
      console.error('onNotificationCreatedPush send failed', event.params.notifId, e);
    }

    // Mark handled (idempotent). onDocumentCreated does NOT re-fire on update,
    // so this cannot loop.
    try {
      await snap.ref.update({ pushSent: true });
    } catch {
      // ignore
    }
  }),
);
