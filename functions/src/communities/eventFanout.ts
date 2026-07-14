/**
 * Community event → members push fan-out (NEW, isolated module).
 *
 * When an event linked to a community (`communityId` set) becomes `published`,
 * push an FCM notification to every member of that community and write a
 * matching in-app `notifications` doc.
 *
 * Fires on:
 *   - events/{eventId} onCreate  — created already `published` with communityId.
 *   - events/{eventId} onUpdate  — transitioning INTO `published` with communityId.
 *
 * Independent of the business-followers fan-out (business_new_event.ts): a
 * community event with a business organizer notifies BOTH audiences via separate
 * idempotency flags (`pushedToCommunity` here vs `pushedToFollowers` there).
 *
 * Scale: members paged (MEMBER_PAGE); multicast in 500-chunks; in-app docs in
 * ≤450-op batches.
 */

import {
  onDocumentCreated,
  onDocumentUpdated,
} from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import '../shared/firebaseAdmin';

const db = admin.firestore();

const FCM_CHUNK = 500;
const MEMBER_PAGE = 500;
const BATCH_LIMIT = 450;

function preview(title: string): string {
  return title.length > 120 ? `${title.substring(0, 117)}...` : title;
}

async function fanOutCommunityEvent(
  eventId: string,
  eventData: admin.firestore.DocumentData,
  eventRef: admin.firestore.DocumentReference,
): Promise<void> {
  if (eventData.status !== 'published') return;
  const communityId = (eventData.communityId as string) || '';
  if (!communityId) return;
  if (eventData.pushedToCommunity === true) return;

  // Claim idempotency flag transactionally.
  const claimed = await db.runTransaction(async (txn) => {
    const fresh = await txn.get(eventRef);
    if (!fresh.exists) return false;
    if (fresh.data()?.pushedToCommunity === true) return false;
    txn.update(eventRef, {
      pushedToCommunity: true,
      pushedToCommunityAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return true;
  });
  if (!claimed) return;

  const communitySnap = await db
    .collection('communities')
    .doc(communityId)
    .get();
  const communityName =
    (communitySnap.data()?.name as string) || 'Your community';

  const eventTitle = (eventData.title as string) || 'New event';
  const eventImage = (eventData.imageUrl as string) || undefined;
  const title = `New event in ${communityName}`;
  const body = preview(eventTitle);
  const dataPayload: Record<string, string> = {
    type: 'community_event',
    eventId,
    communityId,
    action: 'open_event',
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

    const recipientIds = page.docs
      .filter((d) => d.data()?.isBanned !== true)
      .map((d) => d.id);
    total += recipientIds.length;

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
          notification: {
            title,
            body,
            ...(eventImage ? { imageUrl: eventImage } : {}),
          },
          data: dataPayload,
          android: {
            priority: 'high',
            collapseKey: `community_event_${eventId}`,
            notification: {
              sound: 'default',
              channelId: 'greengo_notifications',
              priority: 'high' as any,
              tag: `community_event_${eventId}`,
              ...(eventImage ? { imageUrl: eventImage } : {}),
            },
          },
          apns: {
            headers: { 'apns-collapse-id': `community_event_${eventId}` },
            payload: { aps: { sound: 'default', badge: 1 } },
          },
        });
      } catch (e) {
        console.error('Community event multicast failed', eventId, e);
      }
    }

    let batch = db.batch();
    let ops = 0;
    const commits: Promise<unknown>[] = [];
    for (const uid of recipientIds) {
      const ref = db.collection('notifications').doc();
      batch.set(ref, {
        userId: uid,
        type: 'community_event',
        title,
        message: body,
        body,
        data: dataPayload,
        imageUrl: eventImage ?? null,
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
    `Community event ${eventId} fanned out to ${total} member(s) of ${communityId}`,
  );
}

export const onCommunityEventCreated = onDocumentCreated(
  'events/{eventId}',
  monitored('onCommunityEventCreated', async (event) => {
    const snap = event.data;
    if (!snap) return;
    await fanOutCommunityEvent(
      event.params.eventId as string,
      snap.data(),
      snap.ref,
    );
  }),
);

export const onCommunityEventPublished = onDocumentUpdated(
  'events/{eventId}',
  monitored('onCommunityEventPublished', async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === 'published') return;
    if (after.status !== 'published') return;
    await fanOutCommunityEvent(
      event.params.eventId as string,
      after,
      event.data!.after.ref,
    );
  }),
);
