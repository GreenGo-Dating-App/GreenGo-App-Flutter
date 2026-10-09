/**
 * Shared notification helpers (NEW). Resolve an actor's avatar + name and emit
 * an actor-attributed in-app notification (+ FCM push). Titles are stored
 * WITHOUT the actor name; the Flutter tile renders `actorName` bold + tappable.
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { brandPush } from './brand';
import { shouldNotify, categoryForType } from './prefs';
import { LText, notifTextFields, render, t, AppLocale } from '../shared/i18n';
import { resolveLocale } from '../shared/i18n/recipientLocale';

const db = admin.firestore();

export interface Actor {
  id: string;
  name: string;
  photo?: string;
  /** True when the profile has no usable name ([name] is then "Someone"). */
  unknown?: boolean;
}

/** The actor's name as shown in a push for [locale] ("Someone" localized). */
export function actorNameFor(locale: AppLocale, actor: Actor): string {
  return actor.unknown || !actor.name ? t(locale, 'srvSomeone') : actor.name;
}

/** Resolve an actor's display name + avatar from their profile. */
export async function resolveActor(actorId: string): Promise<Actor> {
  try {
    const snap = await db.collection('profiles').doc(actorId).get();
    const p = snap.data() || {};
    const known =
      (p.displayName as string) ||
      (p.nickname as string) ||
      (p.name as string) ||
      '';
    const photo =
      (p.profilePhotoUrl as string) ||
      (Array.isArray(p.photos) ? (p.photos[0] as string) : undefined) ||
      (Array.isArray(p.photoUrls) ? (p.photoUrls[0] as string) : undefined);
    // Stored English stand-in for app versions that read actorName as-is;
    // pushes use actorNameFor() (localized).
    return known
      ? { id: actorId, name: known, photo }
      : { id: actorId, name: t('en', 'srvSomeone'), photo, unknown: true };
  } catch {
    return { id: actorId, name: t('en', 'srvSomeone'), unknown: true };
  }
}

/**
 * Resolve a recipient's FCM token (users/{id}.fcmToken) and app language from
 * the same doc (one read; userSettings only when appLanguage is missing).
 */
async function pushTargetFor(
  userId: string,
): Promise<{ token?: string; locale: AppLocale }> {
  try {
    const data = (await db.collection('users').doc(userId).get()).data() || null;
    const token = data?.fcmToken as string | undefined;
    if (!token) return { locale: 'en' };
    return { token, locale: await resolveLocale(userId, { userData: data }) };
  } catch {
    return { locale: 'en' };
  }
}

/**
 * Emit ONE notification to [recipientId]: an in-app `notifications` doc carrying
 * the actor identity (avatar + name), plus a best-effort FCM push. No-op when
 * the recipient is the actor (unless [allowSelf]).
 *
 * [title] / [body] are catalog texts (lt(key, params)) or verbatim user
 * content (rawText(...)). The doc stores `titleKey` / `bodyKey` / `params`
 * (rendered by the app in the viewer's language) + English fallbacks; the
 * push is rendered in the recipient's language.
 */
export async function emitNotification(params: {
  recipientId: string;
  type: string;
  title: LText; // action phrase WITHOUT the actor name
  body: LText;
  data: Record<string, string>;
  actor?: Actor; // omit for system/no-actor notifications
  allowSelf?: boolean;
}): Promise<void> {
  const { recipientId, type, title, body, actor, allowSelf } = params;
  if (!recipientId) return;
  if (actor && recipientId === actor.id && !allowSelf) return;

  // When there's an actor, always carry their identity in the push DATA payload
  // so the client can render + link the actor's name from a background push.
  const data = actor
    ? { ...params.data, actorId: actor.id, actorName: actor.name }
    : params.data;

  // pushSent: true — emitNotification sends its own FCM push below, so the
  // onNotificationCreatedPush parity trigger must skip this doc (no double-push).
  // Covers all callers of this helper (engagementNotifications, group_chat/membership).
  await db.collection('notifications').add({
    userId: recipientId,
    type,
    ...notifTextFields(title, body),
    data,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    pushSent: true,
    ...(actor ? { actorId: actor.id, actorName: actor.name } : {}),
    ...(actor?.photo ? { imageUrl: actor.photo } : {}),
  });

  // Respect the recipient's per-category preference (feed doc already written).
  if (!(await shouldNotify(recipientId, categoryForType(type)))) return;

  try {
    const { token, locale } = await pushTargetFor(recipientId);
    if (token) {
      const pushTitle = render(locale, title);
      await admin.messaging().send({
        token,
        notification: brandPush(
          actor ? `${actorNameFor(locale, actor)} ${pushTitle}` : pushTitle,
          render(locale, body),
          actor?.photo,
        ),
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
