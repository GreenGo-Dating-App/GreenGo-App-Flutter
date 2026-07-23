/**
 * Notification preference gate.
 *
 * Reads `notification_preferences/{uid}` and decides whether a push of a given
 * category should be delivered. Honors the master toggle + per-category flags +
 * quiet hours (evaluated in the user's local time via a stored UTC offset).
 *
 * Fail-OPEN: on a missing doc or read error we return `true` so a transient
 * problem never silently drops notifications. Categories default to enabled.
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';

const db = admin.firestore();

export type NotifCategory =
  // Granular per-channel categories (match the client settings screen).
  | 'exchanges'
  | 'groups'
  | 'eventsChat'
  | 'communityChat'
  | 'announcements'
  | 'tips'
  // Legacy buckets still produced by categoryForType for non-chat types.
  | 'messages'
  | 'events'
  | 'communities'
  | 'social'
  | 'account';

/**
 * Per-category default (used when the user has NO prefs doc, or the specific
 * category key is absent). Only exchanges, groups, community announcements and
 * event chats are ON by default; business chat, community chat and tips are OFF
 * until the user opts in. Legacy buckets default ON (fail-open).
 */
const CATEGORY_DEFAULTS: Record<string, boolean> = {
  exchanges: true,
  groups: true,
  eventsChat: true,
  communityChat: false,
  announcements: true,
  tips: false,
  // legacy
  messages: true,
  events: true,
  communities: true,
  social: true,
  account: true,
};

function defaultFor(category: string): boolean {
  return CATEGORY_DEFAULTS[category] ?? true;
}

/** Map a notification `type`/`action` string to its preference category. */
export function categoryForType(type: string): NotifCategory {
  const t = (type || '').toLowerCase();
  if (t.includes('group')) return 'groups';
  if (t.includes('announce')) return 'announcements';
  if (t.includes('tip')) return 'tips';
  if (t.includes('event') && (t.includes('message') || t.includes('chat'))) {
    return 'eventsChat';
  }
  if (t.includes('communit') && (t.includes('message') || t.includes('chat'))) {
    return 'communityChat';
  }
  if (t.includes('message') || t.includes('chat') || t.includes('support')) {
    return 'exchanges';
  }
  if (
    t.includes('event') ||
    t.includes('rsvp') ||
    t.includes('attend') ||
    t.includes('reminder') ||
    t.includes('member') ||
    t.includes('communit')
  ) {
    return 'announcements';
  }
  if (
    t.includes('approv') ||
    t.includes('verif') ||
    t.includes('account') ||
    t.includes('admin') ||
    t.includes('broadcast')
  ) {
    return 'account';
  }
  return 'social';
}

function inQuietHours(
  start: string | undefined,
  end: string | undefined,
  tzOffsetMinutes: number,
): boolean {
  if (!start || !end) return false;
  const [sh] = start.split(':').map(Number);
  const [eh] = end.split(':').map(Number);
  if (Number.isNaN(sh) || Number.isNaN(eh)) return false;
  // Local hour = UTC hour + offset.
  const utcHour = new Date(Date.now()).getUTCHours();
  const localHour = (((utcHour + Math.round(tzOffsetMinutes / 60)) % 24) + 24) % 24;
  // Overnight window (e.g. 22 → 08) vs same-day window.
  return sh > eh ? localHour >= sh || localHour < eh : localHour >= sh && localHour < eh;
}

/** Whether to send `uid` a push of `category`. Never throws. */
export async function shouldNotify(
  uid: string,
  category: NotifCategory,
): Promise<boolean> {
  if (!uid) return false;
  try {
    const snap = await db.collection('notification_preferences').doc(uid).get();
    if (!snap.exists) return defaultFor(category);
    const d = snap.data() || {};
    if (d.pushEnabled === false) return false;
    const cats = (d.categories || {}) as Record<string, unknown>;
    const raw = cats[category];
    // Absent key → per-category default; explicit false → blocked.
    const catAllowed = raw === undefined ? defaultFor(category) : raw !== false;
    if (!catAllowed) return false;
    if (
      d.quietHoursEnabled === true &&
      inQuietHours(d.quietHoursStart, d.quietHoursEnd, Number(d.tzOffsetMinutes) || 0)
    ) {
      return false;
    }
    return true;
  } catch {
    return true;
  }
}

/**
 * Filter a list of recipient uids to those who accept `category`, for multicast
 * fan-outs. Batched pref reads (chunks of 300 via `getAll`). Fail-open per uid.
 */
export async function filterUidsByPref(
  uids: string[],
  category: NotifCategory,
): Promise<Set<string>> {
  const allowed = new Set<string>();
  if (uids.length === 0) return allowed;
  const CHUNK = 300;
  for (let i = 0; i < uids.length; i += CHUNK) {
    const slice = uids.slice(i, i + CHUNK);
    try {
      const refs = slice.map((u) =>
        db.collection('notification_preferences').doc(u),
      );
      const snaps = await db.getAll(...refs);
      snaps.forEach((snap, idx) => {
        const uid = slice[idx];
        if (!snap.exists) {
          if (defaultFor(category)) allowed.add(uid);
          return;
        }
        const d = snap.data() || {};
        if (d.pushEnabled === false) return;
        const cats = (d.categories || {}) as Record<string, unknown>;
        const raw = cats[category];
        const catAllowed = raw === undefined ? defaultFor(category) : raw !== false;
        if (!catAllowed) return;
        if (
          d.quietHoursEnabled === true &&
          inQuietHours(
            d.quietHoursStart,
            d.quietHoursEnd,
            Number(d.tzOffsetMinutes) || 0,
          )
        ) {
          return;
        }
        allowed.add(uid);
      });
    } catch {
      // Fail-open: allow this chunk on error.
      slice.forEach((u) => allowed.add(u));
    }
  }
  return allowed;
}
