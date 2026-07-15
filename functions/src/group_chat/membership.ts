/**
 * Group Chat membership maintenance (NEW, isolated module).
 *
 * All cross-user writes for groups happen here with the Admin SDK (which
 * bypasses security rules), so clients only ever write the group document and
 * their own data. Two triggers on the dedicated `groups` collection:
 *
 *   onGroupCreated           — seed every member's `members/{uid}` doc and
 *                              private `user_group_inbox` thread; post the
 *                              "created" system message.
 *   onGroupParticipantsChanged — diff the participants array on update; seed
 *                              added members, mark removed members (leftAt +
 *                              delete their inbox thread), post system messages,
 *                              and keep each member doc's role in sync with the
 *                              authoritative `roles` map.
 *
 * Never touches the legacy 1:1 `conversations` collection or its functions.
 */

import {
  onDocumentCreated,
  onDocumentUpdated,
} from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import { resolveActor, emitNotification } from '../notifications/notifyHelpers';
import '../shared/firebaseAdmin';

const db = admin.firestore();
const INBOX_COL = 'user_group_inbox';
const THREADS_SUB = 'threads';
const BATCH_LIMIT = 450;

function inboxThreadRef(uid: string, groupId: string) {
  return db.collection(INBOX_COL).doc(uid).collection(THREADS_SUB).doc(groupId);
}

function memberRef(groupId: string, uid: string) {
  return db.collection('groups').doc(groupId).collection('members').doc(uid);
}

function systemMessageRef(groupId: string) {
  return db.collection('groups').doc(groupId).collection('messages').doc();
}

async function commitInChunks(
  writes: ((batch: admin.firestore.WriteBatch) => void)[]
): Promise<void> {
  let batch = db.batch();
  let ops = 0;
  const commits: Promise<unknown>[] = [];
  for (const apply of writes) {
    apply(batch);
    ops++;
    if (ops >= BATCH_LIMIT) {
      commits.push(batch.commit());
      batch = db.batch();
      ops = 0;
    }
  }
  if (ops > 0) commits.push(batch.commit());
  await Promise.all(commits);
}

function seedWrites(
  groupId: string,
  uid: string,
  role: string,
  name: string,
  photoUrl: string | null,
  memberCount: number,
  preview: string,
  unread: number
): ((b: admin.firestore.WriteBatch) => void)[] {
  const now = admin.firestore.FieldValue.serverTimestamp();
  return [
    (b) =>
      b.set(
        memberRef(groupId, uid),
        {
          userId: uid,
          role,
          joinedAt: now,
          lastReadAt: now,
          notificationsEnabled: true,
          leftAt: null,
        },
        { merge: true }
      ),
    (b) =>
      b.set(
        inboxThreadRef(uid, groupId),
        {
          groupId,
          name,
          photoUrl,
          isGroup: true,
          lastMessagePreview: preview,
          lastMessageAt: now,
          unreadCount: unread,
          pinned: false,
          muted: false,
          memberCount,
          updatedAt: now,
        },
        { merge: true }
      ),
  ];
}

export const onGroupCreated = onDocumentCreated(
  'groups/{groupId}',
  monitored("onGroupCreated", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const groupId = event.params.groupId as string;
    const group = snap.data() as Record<string, any>;
    const participants: string[] = group.participants || [];
    const roles: Record<string, string> = group.roles || {};
    const name = group.groupInfo?.name || 'Group';
    const photoUrl = group.groupInfo?.photoUrl ?? null;
    const createdBy = group.createdBy as string;

    const writes: ((b: admin.firestore.WriteBatch) => void)[] = [];
    for (const uid of participants) {
      writes.push(
        ...seedWrites(
          groupId,
          uid,
          roles[uid] || 'member',
          name,
          photoUrl,
          participants.length,
          'Group created',
          0
        )
      );
    }
    // "created" system message.
    writes.push((b) =>
      b.set(systemMessageRef(groupId), {
        senderId: createdBy,
        receiverId: '',
        matchId: groupId,
        content: `created the group "${name}"`,
        type: 'system',
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      })
    );
    await commitInChunks(writes);
  })
);

export const onGroupParticipantsChanged = onDocumentUpdated(
  'groups/{groupId}',
  monitored("onGroupParticipantsChanged", async (event) => {
    const before = event.data?.before.data() as Record<string, any> | undefined;
    const after = event.data?.after.data() as Record<string, any> | undefined;
    if (!before || !after) return;

    const groupId = event.params.groupId as string;
    const prev: string[] = before.participants || [];
    const next: string[] = after.participants || [];
    const roles: Record<string, string> = after.roles || {};
    const name = after.groupInfo?.name || 'Group';
    const photoUrl = after.groupInfo?.photoUrl ?? null;

    let added = next.filter((u) => !prev.includes(u));
    const removed = prev.filter((u) => !next.includes(u));
    if (added.length === 0 && removed.length === 0) return;

    // Business (storefront) identities can't be group members. Strip any that
    // were just added (defense-in-depth: the client already hides them from the
    // add-member pickers). Remove them from participants + roles, then continue
    // with the non-business additions.
    if (added.length > 0) {
      const businessAdded: string[] = [];
      for (const uid of added) {
        const p = await db.collection('profiles').doc(uid).get();
        if (p.data()?.isBusiness === true) businessAdded.push(uid);
      }
      if (businessAdded.length > 0) {
        const updates: Record<string, unknown> = {
          participants:
            admin.firestore.FieldValue.arrayRemove(...businessAdded),
        };
        for (const uid of businessAdded) {
          updates[`roles.${uid}`] = admin.firestore.FieldValue.delete();
        }
        await db.collection('groups').doc(groupId).update(updates);
        added = added.filter((u) => !businessAdded.includes(u));
      }
    }
    if (added.length === 0 && removed.length === 0) return;

    const now = admin.firestore.FieldValue.serverTimestamp();
    const writes: ((b: admin.firestore.WriteBatch) => void)[] = [];

    for (const uid of added) {
      writes.push(
        ...seedWrites(
          groupId,
          uid,
          roles[uid] || 'member',
          name,
          photoUrl,
          next.length,
          'You were added to the group',
          1
        )
      );
    }

    for (const uid of removed) {
      writes.push((b) =>
        b.set(memberRef(groupId, uid), { leftAt: now }, { merge: true })
      );
      writes.push((b) => b.delete(inboxThreadRef(uid, groupId)));
    }

    if (added.length > 0) {
      writes.push((b) =>
        b.set(systemMessageRef(groupId), {
          senderId: '',
          receiverId: '',
          matchId: groupId,
          content:
            added.length === 1
              ? 'A new member joined'
              : `${added.length} new members joined`,
          type: 'system',
          status: 'sent',
          sentAt: now,
        })
      );
    }
    if (removed.length > 0) {
      writes.push((b) =>
        b.set(systemMessageRef(groupId), {
          senderId: '',
          receiverId: '',
          matchId: groupId,
          content:
            removed.length === 1
              ? 'A member left the group'
              : `${removed.length} members left the group`,
          type: 'system',
          status: 'sent',
          sentAt: now,
        })
      );
    }

    await commitInChunks(writes);

    // Notifications: tell each ADDED user they were added (b), and tell the
    // group owner that someone joined their group (d). The actor for "added
    // you" is the group owner (the usual adder); for "joined your group" it's
    // the added user.
    if (added.length > 0) {
      const ownerId = (after.createdBy as string) ||
        (after.groupInfo?.createdBy as string) || '';
      const ownerActor = ownerId ? await resolveActor(ownerId) : undefined;
      for (const uid of added) {
        if (uid === ownerId) continue;
        // → the added user
        await emitNotification({
          recipientId: uid,
          type: 'group_add',
          title: `added you to ${name}`,
          body: name,
          data: { type: 'group_add', groupId, action: 'open_group', actorId: ownerId },
          actor: ownerActor,
        });
        // → the group owner
        if (ownerId) {
          const joiner = await resolveActor(uid);
          await emitNotification({
            recipientId: ownerId,
            type: 'group_join',
            title: `joined your group ${name}`,
            body: name,
            data: { type: 'group_join', groupId, action: 'open_group', actorId: uid },
            actor: joiner,
          });
        }
      }
    }
  })
);

/**
 * onGroupInfoChanged — when the group name or photo changes, fan the new value
 * out to every member's inbox index so the group list / icon updates instantly
 * for everyone (not just the open chat). Cheap: one merge-set per member.
 */
export const onGroupInfoChanged = onDocumentUpdated(
  'groups/{groupId}',
  monitored("onGroupInfoChanged", async (event) => {
    const before = event.data?.before.data() as Record<string, any> | undefined;
    const after = event.data?.after.data() as Record<string, any> | undefined;
    if (!before || !after) return;

    const groupId = event.params.groupId as string;
    const beforeName = before.groupInfo?.name ?? null;
    const afterName = after.groupInfo?.name ?? null;
    const beforePhoto = before.groupInfo?.photoUrl ?? null;
    const afterPhoto = after.groupInfo?.photoUrl ?? null;

    const nameChanged = beforeName !== afterName;
    const photoChanged = beforePhoto !== afterPhoto;
    if (!nameChanged && !photoChanged) return;

    const participants: string[] = after.participants || [];
    if (participants.length === 0) return;

    const update: Record<string, unknown> = {};
    if (nameChanged) update.name = afterName ?? 'Group';
    if (photoChanged) update.photoUrl = afterPhoto;

    const writes = participants.map(
      (uid) => (b: admin.firestore.WriteBatch) =>
        b.set(inboxThreadRef(uid, groupId), update, { merge: true })
    );
    await commitInChunks(writes);
  })
);
