/**
 * Shared notification helpers (NEW). Resolve an actor's avatar + name and emit
 * an actor-attributed in-app notification (+ FCM push). Titles are stored
 * WITHOUT the actor name; the Flutter tile renders `actorName` bold + tappable.
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';

const db = admin.firestore();

export interface Actor {
  id: string;
  name: string;
  photo?: string;
}

/** Resolve an actor's display name + avatar from their profile. */
export async function resolveActor(actorId: string): Promise<Actor> {
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

/** Resolve a recipient's FCM token (users/{id}.fcmToken). */
async function tokenFor(userId: string): Promise<string | undefined> {
  try {
    const snap = await db.collection('users').doc(userId).get();
    return snap.data()?.fcmToken as string | undefined;
  } catch {
    return undefined;
  }
}

/**
 * Emit ONE notification to [recipientId]: an in-app `notifications` doc carrying
 * the actor identity (avatar + name), plus a best-effort FCM push. No-op when
 * the recipient is the actor (unless [allowSelf]).
 */
export async function emitNotification(params: {
  recipientId: string;
  type: string;
  title: string; // action phrase WITHOUT the actor name
  body: string;
  data: Record<string, string>;
  actor?: Actor; // omit for system/no-actor notifications
  allowSelf?: boolean;
}): Promise<void> {
  const { recipientId, type, title, body, data, actor, allowSelf } = params;
  if (!recipientId) return;
  if (actor && recipientId === actor.id && !allowSelf) return;

  // pushSent: true — emitNotification sends its own FCM push below, so the
  // onNotificationCreatedPush parity trigger must skip this doc (no double-push).
  // Covers all callers of this helper (engagementNotifications, group_chat/membership).
  await db.collection('notifications').add({
    userId: recipientId,
    type,
    title,
    message: body,
    body,
    data,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    pushSent: true,
    ...(actor ? { actorId: actor.id, actorName: actor.name } : {}),
    ...(actor?.photo ? { imageUrl: actor.photo } : {}),
  });

  try {
    const token = await tokenFor(recipientId);
    if (token) {
      await admin.messaging().send({
        token,
        notification: {
          title: actor ? `${actor.name} ${title}` : title,
          body,
          ...(actor?.photo ? { imageUrl: actor.photo } : {}),
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
