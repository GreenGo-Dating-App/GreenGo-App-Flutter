/**
 * Group Chat fan-out (NEW, isolated module).
 *
 * Triggered when a message is appended to a group in the dedicated `groups`
 * collection. The client writes the message exactly once; this function does
 * all the O(N) work server-side so the client write path stays O(1):
 *
 *   1. Denormalize lastMessage / lastMessageAt onto the group doc.
 *   2. Fan out a tiny summary to each member's private inbox index
 *      `user_group_inbox/{uid}/threads/{groupId}` and bump unread for everyone
 *      except the sender (batched, 450 writes/commit).
 *   3. Push an FCM notification to active, non-muted recipients (chunked
 *      multicast).
 *
 * Does NOT touch the legacy 1:1 `conversations` collection or its functions.
 *
 * Scale note: groups are capped (256 members) so per-message multicast is
 * bounded. For unbounded public "Culture Rooms" later, switch step 3 to FCM
 * topic publish (O(1)) by subscribing members to a `group_{id}` topic on join.
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { brandPush } from '../notifications/brand';
import { filterUidsByPref } from '../notifications/prefs';
import { monitored } from '../shared/monitoring';
import { PUSH_MEMORY } from '../shared/pushRuntime';
import '../shared/firebaseAdmin';

const db = admin.firestore();

const INBOX_COL = 'user_group_inbox';
const THREADS_SUB = 'threads';
const BATCH_LIMIT = 450;
const FCM_CHUNK = 500;

function previewFor(type: string, content: string): string {
  switch (type) {
    case 'image':
      return '📷 Photo';
    case 'video':
      return '🎥 Video';
    case 'gif':
      return 'GIF';
    case 'sticker':
      return '✨ Sticker';
    case 'voice_note':
      return '🎤 Voice message';
    case 'event':
      return '📅 Event';
    case 'location':
      return '📍 Location';
    case 'system':
      return content;
    default:
      return content.length > 120 ? `${content.substring(0, 117)}...` : content;
  }
}

async function senderDisplayName(senderId: string): Promise<string> {
  try {
    const doc = await db.collection('profiles').doc(senderId).get();
    const d = doc.data();
    return (d?.nickname as string) || (d?.name as string) || 'Someone';
  } catch {
    return 'Someone';
  }
}

export const onGroupMessageCreated = onDocumentCreated(
  {
    document: 'groups/{groupId}/messages/{messageId}',
    memory: PUSH_MEMORY,
  },
  monitored("onGroupMessageCreated", async (event) => {
    const snap = event.data;
    if (!snap) return;

    const msg = snap.data() as Record<string, unknown>;
    const groupId = event.params.groupId as string;
    const senderId = (msg.senderId as string) || '';
    const type = (msg.type as string) || 'text';
    const content = (msg.content as string) || '';
    const sentAt =
      (msg.sentAt as admin.firestore.Timestamp) ||
      admin.firestore.FieldValue.serverTimestamp();
    const isSystem = type === 'system';

    const groupRef = db.collection('groups').doc(groupId);
    const groupSnap = await groupRef.get();
    if (!groupSnap.exists) return;

    const group = groupSnap.data() as Record<string, any>;
    const participants: string[] = group.participants || [];
    if (participants.length === 0) return;

    const groupName = group.groupInfo?.name || 'Group';
    const groupPhoto = group.groupInfo?.photoUrl ?? null;
    const preview = previewFor(type, content);

    // 1) Denormalize last message onto the group doc.
    await groupRef.set(
      {
        lastMessage: {
          messageId: snap.id,
          senderId,
          content: preview,
          type,
          sentAt,
        },
        lastMessageAt: sentAt,
      },
      { merge: true }
    );

    // 2) Fan out inbox summaries (batched).
    let batch = db.batch();
    let ops = 0;
    const commits: Promise<unknown>[] = [];
    for (const uid of participants) {
      const threadRef = db
        .collection(INBOX_COL)
        .doc(uid)
        .collection(THREADS_SUB)
        .doc(groupId);

      const update: Record<string, unknown> = {
        groupId,
        name: groupName,
        photoUrl: groupPhoto,
        isGroup: true,
        lastMessagePreview: preview,
        lastSenderId: senderId,
        lastMessageAt: sentAt,
        updatedAt: sentAt,
        memberCount: participants.length,
      };
      if (uid !== senderId) {
        update.unreadCount = admin.firestore.FieldValue.increment(1);
      }
      batch.set(threadRef, update, { merge: true });
      ops++;
      if (ops >= BATCH_LIMIT) {
        commits.push(batch.commit());
        batch = db.batch();
        ops = 0;
      }
    }
    if (ops > 0) commits.push(batch.commit());
    await Promise.all(commits);

    // 3) Push notifications (skip system messages, sender, muted/left members).
    if (isSystem) return;

    const recipientIds = participants.filter((u) => u !== senderId);
    if (recipientIds.length === 0) return;

    const [senderName, memberDocs] = await Promise.all([
      senderDisplayName(senderId),
      Promise.all(
        recipientIds.map((u) => groupRef.collection('members').doc(u).get())
      ),
    ]);

    const activeRecipients = recipientIds.filter((_, i) => {
      const m = memberDocs[i].data();
      if (!m) return true;
      if (m.leftAt) return false;
      if (m.notificationsEnabled === false) return false;
      return true;
    });
    if (activeRecipients.length === 0) return;

    // Per-category notification preference (messages).
    const allowed = await filterUidsByPref(activeRecipients, 'messages');
    const prefRecipients = activeRecipients.filter((u) => allowed.has(u));
    if (prefRecipients.length === 0) return;

    const tokenDocs = await Promise.all(
      prefRecipients.map((u) => db.collection('users').doc(u).get())
    );
    const tokens: string[] = [];
    for (const td of tokenDocs) {
      const t = td.data()?.fcmToken as string | undefined;
      if (t) tokens.push(t);
    }
    if (tokens.length === 0) return;

    for (let i = 0; i < tokens.length; i += FCM_CHUNK) {
      const chunk = tokens.slice(i, i + FCM_CHUNK);
      try {
        await admin.messaging().sendEachForMulticast({
          tokens: chunk,
          notification: brandPush(groupName, `${senderName}: ${preview}`),
          data: {
            type: 'group_message',
            groupId,
            // conversationId mirrors groupId so the client foreground handler
            // and tap-routing treat groups like 1:1 exchanges.
            conversationId: groupId,
            senderId,
          },
          // Match the 1:1 "exchange" notification sound + channel exactly.
          android: {
            priority: 'high',
            collapseKey: `group_${groupId}`,
            notification: {
              sound: 'default',
              channelId: 'greengo_notifications',
              priority: 'high' as any,
              tag: `group_${groupId}`,
            },
          },
          apns: {
            headers: { 'apns-collapse-id': `group_${groupId}` },
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        });
      } catch (e) {
        // Best-effort: never fail the trigger on notification errors.
        console.error('Group FCM multicast failed', e);
      }
    }
  })
);
