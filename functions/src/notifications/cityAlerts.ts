/**
 * City event alerts.
 *
 * Users subscribe to cities in `notification_preferences.eventCities` (normalized
 * keys). This module:
 *   1. keeps a per-city subscriber index in sync with those subscriptions, and
 *   2. notifies a city's subscribers when an event (`events/{id}`, community or
 *      business) is published there — push + in-app feed doc.
 *
 * Index shape: `event_city_subscribers/{cityKey}/subscribers/{uid}`.
 * External (bulk-ingested) events are handled by a separate digest, NOT here,
 * to avoid a per-event storm.
 */
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import { brandPush } from './brand';
import { filterUidsByPref } from './prefs';
import '../shared/firebaseAdmin';

const db = admin.firestore();

const _FROM = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
const _TO = 'aaaaaaceeeeiiiinooooouuuuyy';

/** Mirror of the Flutter `CityNormalizer.normalize`. */
export function normalizeCity(raw: string): string {
  let s = (raw || '').trim().toLowerCase();
  let out = '';
  for (const ch of s) {
    const i = _FROM.indexOf(ch);
    out += i >= 0 ? _TO[i] : ch;
  }
  out = out.replace(/[^a-z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();
  return out;
}

/** Title-case a normalized key for display. */
function displayCity(key: string): string {
  return key
    .split(' ')
    .map((w) => (w ? w[0].toUpperCase() + w.slice(1) : w))
    .join(' ');
}

// ── 1. Keep the per-city subscriber index in sync ──────────────────────────
export const syncCitySubscribers = onDocumentWritten(
  'notification_preferences/{uid}',
  monitored('syncCitySubscribers', async (event) => {
    const uid = event.params.uid as string;
    const before = (event.data?.before.data()?.eventCities as string[]) || [];
    const after = (event.data?.after.data()?.eventCities as string[]) || [];
    const beforeSet = new Set(before.map(normalizeCity));
    const afterSet = new Set(after.map(normalizeCity));

    const added = [...afterSet].filter((c) => c && !beforeSet.has(c));
    const removed = [...beforeSet].filter((c) => c && !afterSet.has(c));
    if (added.length === 0 && removed.length === 0) return;

    const batch = db.batch();
    for (const city of added) {
      batch.set(
        db
          .collection('event_city_subscribers')
          .doc(city)
          .collection('subscribers')
          .doc(uid),
        { subscribedAt: admin.firestore.FieldValue.serverTimestamp() },
      );
    }
    for (const city of removed) {
      batch.delete(
        db
          .collection('event_city_subscribers')
          .doc(city)
          .collection('subscribers')
          .doc(uid),
      );
    }
    await batch.commit();
  }),
);

// ── 2. Notify a city's subscribers about a new event ────────────────────────
const SUB_PAGE = 400;
const FCM_CHUNK = 500;

/**
 * Fan out to everyone subscribed to [cityKey]. Writes an in-app feed doc AND a
 * push for each recipient. Respects the `events` preference and excludes
 * [exclude] (e.g. community members already notified). Paginated + chunked.
 */
async function notifyCity(
  cityKey: string,
  opts: {
    eventId: string;
    eventTitle: string;
    cityDisplay: string;
    imageUrl?: string;
    exclude?: Set<string>;
  },
): Promise<void> {
  const subsCol = db
    .collection('event_city_subscribers')
    .doc(cityKey)
    .collection('subscribers');

  const title = `New event in ${opts.cityDisplay}`;
  const body = opts.eventTitle;
  const data = { action: 'event', eventId: opts.eventId, city: cityKey };

  let last: admin.firestore.QueryDocumentSnapshot | undefined;
  // eslint-disable-next-line no-constant-condition
  while (true) {
    let q = subsCol
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(SUB_PAGE);
    if (last) q = q.startAfter(last);
    const page = await q.get();
    if (page.empty) break;
    last = page.docs[page.docs.length - 1];

    let uids = page.docs.map((d) => d.id);
    if (opts.exclude) uids = uids.filter((u) => !opts.exclude!.has(u));
    if (uids.length === 0) continue;

    const allowed = await filterUidsByPref(uids, 'events');
    const recipients = uids.filter((u) => allowed.has(u));
    if (recipients.length === 0) continue;

    // In-app feed docs (batched).
    const batch = db.batch();
    for (const uid of recipients) {
      batch.set(db.collection('notifications').doc(), {
        userId: uid,
        type: 'city_event',
        title,
        message: body,
        body,
        data,
        isRead: false,
        pushSent: true, // we push below; keep the parity trigger off this doc
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    // Push.
    const userDocs = await Promise.all(
      recipients.map((u) => db.collection('users').doc(u).get()),
    );
    const tokens: string[] = [];
    for (const ud of userDocs) {
      const t = ud.data()?.fcmToken as string | undefined;
      if (t) tokens.push(t);
    }
    for (let i = 0; i < tokens.length; i += FCM_CHUNK) {
      const chunk = tokens.slice(i, i + FCM_CHUNK);
      try {
        await admin.messaging().sendEachForMulticast({
          tokens: chunk,
          notification: brandPush(title, body, opts.imageUrl),
          data,
          android: {
            priority: 'high',
            collapseKey: `city_${cityKey}`,
            notification: {
              sound: 'default',
              channelId: 'greengo_notifications',
              tag: `city_${cityKey}`,
            },
          },
          apns: { payload: { aps: { sound: 'default', badge: 1 } } },
        });
      } catch (e) {
        console.error('notifyCity push failed', cityKey, e);
      }
    }
  }
}

/**
 * Fire a city alert when an event is published with a city. Covers community
 * AND business events (both live in `events/{id}`). Guarded by a `cityAlertSent`
 * flag so it sends exactly once (create-as-published or draft→published).
 */
export const onEventCityAlert = onDocumentWritten(
  'events/{eventId}',
  monitored('onEventCityAlert', async (event) => {
    const after = event.data?.after.data();
    if (!after) return; // deleted
    if (after.status !== 'published') return;
    if (after.cityAlertSent === true) return;
    const cityRaw = (after.city as string) || '';
    if (!cityRaw) return;

    const cityKey = normalizeCity(cityRaw);
    if (!cityKey) return;

    // Claim the send atomically to avoid double-fire on rapid writes.
    const ref = event.data!.after.ref;
    try {
      await db.runTransaction(async (tx) => {
        const fresh = await tx.get(ref);
        if (fresh.data()?.cityAlertSent === true) {
          throw new Error('already-sent');
        }
        tx.update(ref, { cityAlertSent: true });
      });
    } catch (e) {
      return; // already sent or lost the race
    }

    // Exclude community members who already got the community fan-out.
    const exclude = new Set<string>();
    const communityId = (after.communityId as string) || '';
    if (communityId) {
      try {
        const members = await db
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .get();
        members.docs.forEach((d) => exclude.add(d.id));
      } catch {
        // best-effort; overlap is acceptable if this fails
      }
    }

    await notifyCity(cityKey, {
      eventId: event.params.eventId as string,
      eventTitle: (after.title as string) || 'New event',
      cityDisplay: displayCity(cityKey),
      imageUrl: (after.imageUrl as string) || (after.coverImage as string),
      exclude,
    });
  }),
);
