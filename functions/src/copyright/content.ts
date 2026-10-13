/**
 * Disabling and restoring the material named in an accepted copyright notice.
 *
 * Reuses the moderation removal mechanics (admin/moderationQueue.ts
 * removeContent) so every client already hides the result:
 *   message       -> "deleted for everyone" + moderator placeholder text,
 *                    media URLs cleared
 *   event         -> status 'cancelled' (off sale, out of every live query)
 *   experience    -> status 'hidden'
 *   profilePhoto  -> URL removed from profiles.photoUrls / users.photos
 *
 * Unlike a moderator removal, a copyright removal must be REVERSIBLE
 * (§512(g)(2)(C)): the overwritten fields are kept in `backup` on the notice
 * and the document carries `copyrightHold.noticeId`, so restore only undoes
 * what this notice did. The backup is never written onto the content doc
 * itself (chat participants can read that doc).
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { t } from '../shared/i18n';
import { ContentTarget } from './model';

const db = () => admin.firestore();
const FV = admin.firestore.FieldValue;

const MESSAGE_TEXT_FIELDS = ['content', 'text', 'caption'] as const;
const MESSAGE_MEDIA_FIELDS = ['mediaUrl', 'imageUrl', 'videoUrl', 'audioUrl', 'fileUrl', 'thumbnailUrl', 'gifUrl', 'stickerUrl'] as const;
const MESSAGE_FLAG_FIELDS = ['isDeletedForEveryone', 'isDeleted'] as const;

export interface ContentInfo {
  exists: boolean;
  ownerUid: string | null;
  /** Short preview for the admin (never the full document). */
  preview: { text: string | null; mediaUrl: string | null; status: string | null; title: string | null };
  /** Public link where the content can be opened, when there is one. */
  link: string | null;
}

function firstString(d: Record<string, any>, keys: readonly string[]): string | null {
  for (const k of keys) if (typeof d[k] === 'string' && d[k]) return d[k];
  return null;
}

/** Reads the target and finds its owner (uploader). */
export async function inspectTarget(target: ContentTarget): Promise<ContentInfo> {
  const snap = await db().doc(target.path).get();
  const empty: ContentInfo = { exists: false, ownerUid: null, preview: { text: null, mediaUrl: null, status: null, title: null }, link: null };
  if (!snap.exists) return empty;
  const d = snap.data() || {};
  switch (target.type) {
    case 'message':
      return {
        exists: true,
        ownerUid: firstString(d, ['senderId', 'userId', 'authorId']),
        preview: {
          text: (firstString(d, MESSAGE_TEXT_FIELDS) || '').slice(0, 300) || null,
          mediaUrl: firstString(d, MESSAGE_MEDIA_FIELDS),
          status: d.isDeletedForEveryone ? 'deleted' : null,
          title: null,
        },
        link: null,
      };
    case 'event':
      return {
        exists: true,
        ownerUid: firstString(d, ['organizerId', 'createdBy', 'hostId']),
        preview: { text: (typeof d.description === 'string' ? d.description.slice(0, 300) : null), mediaUrl: firstString(d, ['imageUrl', 'coverImageUrl', 'photoUrl']), status: d.status ?? null, title: d.title ?? null },
        link: `https://greengo-chat.web.app/e/${snap.id}`,
      };
    case 'experience':
      return {
        exists: true,
        ownerUid: firstString(d, ['hostId', 'ownerId']),
        preview: { text: (typeof d.description === 'string' ? d.description.slice(0, 300) : null), mediaUrl: Array.isArray(d.photoUrls) ? d.photoUrls[0] ?? null : firstString(d, ['coverUrl', 'imageUrl']), status: d.status ?? null, title: d.title ?? null },
        link: null,
      };
    case 'profilePhoto': {
      const photos: unknown[] = Array.isArray(d.photoUrls) ? d.photoUrls : [];
      return {
        exists: photos.includes(target.photoUrl),
        ownerUid: snap.id,
        preview: { text: null, mediaUrl: target.photoUrl, status: photos.includes(target.photoUrl) ? 'visible' : 'not_on_profile', title: d.displayName ?? null },
        link: `https://greengo-chat.web.app/u/${snap.id}`,
      };
    }
  }
}

export interface RemovalRecord {
  type: ContentTarget['type'];
  path: string;
  photoUrl: string | null;
  backup: Record<string, unknown>;
}

/** Disables the content; idempotent for the same notice. */
export async function disableContent(target: ContentTarget, noticeId: string, nowMs: number): Promise<RemovalRecord> {
  const ref = db().doc(target.path);
  const hold = { noticeId, at: admin.firestore.Timestamp.fromMillis(nowMs) };
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'content_not_found');
    const d = snap.data() || {};
    const prior = d.copyrightHold?.noticeId;
    if (target.type !== 'profilePhoto' && prior && prior !== noticeId) {
      throw new HttpsError('failed-precondition', 'content_already_held');
    }
    const backup: Record<string, unknown> = {};

    switch (target.type) {
      case 'message': {
        if (prior === noticeId) return { ...target, backup: {} };
        const patch: Record<string, unknown> = {};
        const placeholder = t('en', 'srvMessageRemovedByModerator');
        for (const f of [...MESSAGE_TEXT_FIELDS, ...MESSAGE_MEDIA_FIELDS, ...MESSAGE_FLAG_FIELDS]) {
          backup[f] = f in d ? d[f] : '__absent__';
        }
        backup.metadataSystemKey = d.metadata?.systemKey ?? '__absent__';
        backup.metadataAbsent = d.metadata === undefined;
        for (const f of MESSAGE_TEXT_FIELDS) if (typeof d[f] === 'string') patch[f] = placeholder;
        for (const f of MESSAGE_MEDIA_FIELDS) if (f in d) patch[f] = null;
        patch.isDeletedForEveryone = true;
        patch.isDeleted = true;
        patch['metadata.systemKey'] = 'srvMessageRemovedByModerator';
        // Stored translations of the held text (translatePrivateText); not
        // backed up: they are re-made on demand after a restore.
        if ('tr' in d) patch.tr = FV.delete();
        if ('trHash' in d) patch.trHash = FV.delete();
        patch.copyrightHold = hold;
        tx.update(ref, patch);
        break;
      }
      case 'event':
      case 'experience': {
        if (prior === noticeId) return { ...target, backup: {} };
        backup.status = d.status ?? null;
        tx.update(ref, {
          status: target.type === 'event' ? 'cancelled' : 'hidden',
          copyrightHold: hold,
          moderation: {
            reason: 'copyright_notice',
            reasonCode: 'copyright',
            queueId: null,
            removedBy: 'copyright',
            removedAt: hold.at,
            previousStatus: d.status ?? null,
          },
        });
        break;
      }
      case 'profilePhoto': {
        const photos: unknown[] = Array.isArray(d.photoUrls) ? d.photoUrls : [];
        backup.index = photos.indexOf(target.photoUrl);
        if (backup.index !== -1) {
          tx.update(ref, { photoUrls: FV.arrayRemove(target.photoUrl), [`copyrightHolds.${noticeId}`]: hold });
          tx.set(db().collection('users').doc(ref.id), { photos: FV.arrayRemove(target.photoUrl) }, { merge: true });
        }
        break;
      }
    }
    return { ...target, backup };
  });
}

/** Restores what [disableContent] did for this notice (no-op when gone or held by another notice). */
export async function restoreContent(removal: RemovalRecord, noticeId: string): Promise<'restored' | 'skipped'> {
  const ref = db().doc(removal.path);
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return 'skipped';
    const d = snap.data() || {};
    if (removal.type === 'profilePhoto') {
      if (!removal.photoUrl || removal.backup?.index === -1) return 'skipped';
      tx.update(ref, { photoUrls: FV.arrayUnion(removal.photoUrl), [`copyrightHolds.${noticeId}`]: FV.delete() });
      tx.set(db().collection('users').doc(ref.id), { photos: FV.arrayUnion(removal.photoUrl) }, { merge: true });
      return 'restored';
    }
    if (d.copyrightHold?.noticeId !== noticeId) return 'skipped';
    const backup: Record<string, unknown> = removal.backup ?? {};
    if (removal.type === 'message') {
      const patch: Record<string, unknown> = { copyrightHold: FV.delete() };
      for (const [k, v] of Object.entries(backup)) {
        if (k === 'metadataAbsent') continue;
        if (k === 'metadataSystemKey' && backup.metadataAbsent === true) continue;
        const f = k === 'metadataSystemKey' ? 'metadata.systemKey' : k;
        patch[f] = v === '__absent__' ? FV.delete() : v;
      }
      // The removal created the metadata map; drop it again.
      if (backup.metadataAbsent === true) patch.metadata = FV.delete();
      tx.update(ref, patch);
      return 'restored';
    }
    const expected = removal.type === 'event' ? 'cancelled' : 'hidden';
    const patch: Record<string, unknown> = { copyrightHold: FV.delete(), moderation: FV.delete() };
    // Only undo our own status change (the owner may have edited it since).
    if (d.status === expected) patch.status = backup.status ?? (removal.type === 'event' ? 'published' : 'draft');
    tx.update(ref, patch);
    return 'restored';
  });
}
