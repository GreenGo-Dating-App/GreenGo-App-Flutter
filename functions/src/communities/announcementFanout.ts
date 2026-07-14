/**
 * Community announcement → members push fan-out (NEW, isolated module).
 *
 * When an owner/admin posts an ANNOUNCEMENT message in a community, push an FCM
 * notification to every member and write a matching in-app `notifications` doc
 * (so it also shows on the notification page).
 *
 * Fires on: communities/{communityId}/messages/{messageId} onCreate.
 * Gate: message `type === 'announcement'`.
 *
 * Idempotency: claims a `fannedOut` flag on the message doc transactionally
 * before any send, so Cloud Functions at-least-once retries can't double-send.
 *
 * Scale: members are PAGED from communities/{id}/members (MEMBER_PAGE at a time);
 * per page tokens are multicast in chunks of 500 and in-app docs written in
 * ≤450-op batches. No unbounded accumulation.
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

const db = admin.firestore();

const FCM_CHUNK = 500;
const MEMBER_PAGE = 500;
const BATCH_LIMIT = 450;

function preview(text: string): string {
  return text.length > 120 ? `${text.substring(0, 117)}...` : text;
}

export const onCommunityAnnouncementCreated = onDocumentCreated(
  'communities/{communityId}/messages/{messageId}',
  monitored('onCommunityAnnouncementCreated', async (event) => {
    const snap = event.data;
    if (!snap) return;
    const msg = snap.data();
    if (!msg || msg.type !== 'announcement') return;

    const communityId = event.params.communityId as string;
    const senderId = (msg.senderId as string) || '';

    // Claim idempotency flag on the message doc before any fan-out.
    const claimed = await db.runTransaction(async (txn) => {
      const fresh = await txn.get(snap.ref);
      if (!fresh.exists) return false;
      if (fresh.data()?.fannedOut === true) return false;
      txn.update(snap.ref, {
        fannedOut: true,
        fannedOutAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (!claimed) return;

    // Community name for the notification title.
    const communitySnap = await db
      .collection('communities')
      .doc(communityId)
      .get();
    const communityName =
      (communitySnap.data()?.name as string) || 'A community';

    const title = `📣 ${communityName}`;
    const body = preview((msg.content as string) || '');
    const dataPayload: Record<string, string> = {
      type: 'community_announcement',
      communityId,
      action: 'open_community',
    };

    const membersCol = db
      .collection('communities')
      .doc(communityId)
      .collection('members');

    let lastDoc: admin.firestore.QueryDocumentSnapshot | undefined;
    let total = 0;

    // eslint-disable-next-line no-constant-condition
    while (true) {
      let q = membersCol
        .orderBy(admin.firestore.FieldPath.documentId())
        .limit(MEMBER_PAGE);
      if (lastDoc) q = q.startAfter(lastDoc);

      const page = await q.get();
      if (page.empty) break;
      lastDoc = page.docs[page.docs.length - 1];

      // Recipients = members minus the author (and minus banned members).
      const recipientIds = page.docs
        .filter((d) => d.id !== senderId && d.data()?.isBanned !== true)
        .map((d) => d.id);
      total += recipientIds.length;

      // Resolve FCM tokens.
      const userDocs = await Promise.all(
        recipientIds.map((uid) => db.collection('users').doc(uid).get()),
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
            notification: { title, body },
            data: dataPayload,
            android: {
              priority: 'high',
              collapseKey: `community_ann_${communityId}`,
              notification: {
                sound: 'default',
                channelId: 'greengo_notifications',
                priority: 'high' as any,
                tag: `community_ann_${communityId}`,
              },
            },
            apns: {
              headers: { 'apns-collapse-id': `community_ann_${communityId}` },
              payload: { aps: { sound: 'default', badge: 1 } },
            },
          });
        } catch (e) {
          console.error('Community announcement multicast failed', communityId, e);
        }
      }

      // In-app notification docs (Flutter NotificationModel shape).
      let batch = db.batch();
      let ops = 0;
      const commits: Promise<unknown>[] = [];
      for (const uid of recipientIds) {
        const ref = db.collection('notifications').doc();
        batch.set(ref, {
          userId: uid,
          type: 'community_announcement',
          title,
          message: body,
          body,
          data: dataPayload,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
        });
        ops++;
        if (ops >= BATCH_LIMIT) {
          commits.push(batch.commit());
          batch = db.batch();
          ops = 0;
        }
      }
      if (ops > 0) commits.push(batch.commit());
      await Promise.all(commits);

      if (page.size < MEMBER_PAGE) break;
    }

    console.log(
      `Community announcement in ${communityId} fanned out to ${total} member(s)`,
    );
  }),
);
