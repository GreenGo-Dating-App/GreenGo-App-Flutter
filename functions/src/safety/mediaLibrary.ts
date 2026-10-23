/**
 * "My pictures": the per-user library of uploaded images.
 *
 *   media_library/{uid}/items/{itemId}     itemId = object path with '/' -> '~'
 *
 * WHO WRITES
 * ----------
 * ONLY the server (Admin SDK). Clients may read and delete their own items
 * (firestore rules); they can never create or edit one, so an item's `url`
 * is always an object the moderation trigger looked at, and `status` /
 * `hasFace` cannot be forged.
 *
 *  - moderateUploadedImage records every verdict on a user image:
 *      approved -> status 'approved' + url (+ approvedAt, the picker's sort key)
 *      held     -> status 'held'     (moved to quarantine/, not visible to
 *                  anyone; the owner may "Ask for a review")
 *      blocked  -> status 'rejected' (hash-list match; never reviewable here)
 *  - restoreQuarantined (moderator approve / overturned appeal / approved
 *    review request) turns the item back into 'approved'.
 *  - onMediaObjectDeleted (mediaLibraryTriggers.ts) drops an APPROVED item whose object was deleted
 *    (user removed the photo, takedown moved it), so the library never hands
 *    out a dead URL. Held items survive the quarantine move.
 *
 * WHAT IS RECORDED
 * ----------------
 * Images whose OWNER is certain: `profiles/{uid}/...` and `communities/{uid}/...`
 * (the path segment is enforced by storage.rules) and chat / group images that
 * carry `customMetadata.uploaderId` (storage.rules: must equal the uploader).
 * Private-album uploads (visibility=private), voice/video/verification files,
 * support attachments and ticket receipts are never recorded.
 *
 * SCALE
 * -----
 * One doc read + one write per moderated upload; reads are owner-scoped and
 * paged (`orderBy('createdAt')` for the screen, `orderBy('approvedAt')` for
 * the pickers - only approved items carry approvedAt, so no composite index
 * is needed).
 */

import * as admin from 'firebase-admin';
import { randomUUID } from 'crypto';
import '../shared/firebaseAdmin';
import { logError } from '../shared/utils';

export const MEDIA_LIBRARY = 'media_library';
export const LIBRARY_ITEMS = 'items';

export type LibraryStatus = 'approved' | 'held' | 'rejected';

/** Storage folder under profiles/{uid}/ -> usage label. Others are not recorded. */
const PROFILE_FOLDER_USAGE: Record<string, string> = {
  photos: 'profile',
  events: 'event',
  experiences: 'experience',
  groups: 'group',
};

const UID_RE = /^[A-Za-z0-9_-]{6,128}$/;

/** Library item id for an object path (same encoding as image_moderation). Pure. */
export function libraryItemId(objectPath: string): string {
  return objectPath.replace(/\//g, '~');
}

/**
 * Owner + usage of an uploaded object, or null when it must not be recorded.
 * Pure (exported for tests).
 */
export function libraryTarget(
  objectPath: string,
  meta: Record<string, string> | null | undefined,
): { uid: string; usage: string } | null {
  const m = meta || {};
  if ((m.visibility || '').toLowerCase() === 'private') return null;
  const seg = objectPath.split('/');
  if (seg.length < 3 || seg.some((s) => s.length === 0)) return null;
  const [root, owner] = seg;
  if (root === 'profiles') {
    if (!UID_RE.test(owner)) return null;
    if (seg.length === 3) return { uid: owner, usage: 'profile' };
    const usage = PROFILE_FOLDER_USAGE[seg[2]];
    return usage ? { uid: owner, usage } : null;
  }
  if (root === 'communities') {
    return UID_RE.test(owner) ? { uid: owner, usage: 'community' } : null;
  }
  if (root === 'chat_images' || root === 'group_media') {
    const up = typeof m.uploaderId === 'string' ? m.uploaderId : '';
    if (!UID_RE.test(up)) return null;
    return { uid: up, usage: root === 'chat_images' ? 'chat' : 'group_chat' };
  }
  return null;
}

/** Firebase download URL of an object with a download token. Pure. */
export function downloadUrlFor(bucket: string, objectPath: string, token: string): string {
  return `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodeURIComponent(objectPath)}?alt=media&token=${token}`;
}

/**
 * Smaller copies of an approved picture, written by the server only (no
 * client may write `library_renditions/`, storage.rules): a grid thumbnail
 * and a reduced copy the app reuses instead of the full-size original.
 *   library_renditions/{uid}/{itemId}_thumb.jpg   longest side <= THUMB_PX
 *   library_renditions/{uid}/{itemId}_1280.jpg    longest side <= MEDIUM_PX
 */
export const RENDITIONS = 'library_renditions';
export const THUMB_PX = 320;
export const MEDIUM_PX = 1280;
export type RenditionKind = 'thumb' | 'medium';

/** Storage path of one rendition. Pure. */
export function renditionPath(uid: string, itemId: string, kind: RenditionKind): string {
  return `${RENDITIONS}/${uid}/${itemId}_${kind === 'thumb' ? 'thumb' : MEDIUM_PX}.jpg`;
}

/**
 * Original object path of a rendition path, or null when [path] is not a
 * rendition. Used where a reused picture must be traced back to its upload
 * (main-photo face rule). Pure.
 */
export function originalFromRendition(path: string): string | null {
  const prefix = `${RENDITIONS}/`;
  if (!path.startsWith(prefix)) return null;
  const m = /^[^/]+\/(.+)_(?:thumb|1280)\.jpg$/.exec(path.slice(prefix.length));
  return m ? m[1].replace(/~/g, '/') : null;
}

export interface Renditions {
  thumbUrl: string;
  mediumUrl: string;
  mediumWidth: number;
  mediumHeight: number;
}

/** First download token in a metadata map, or null. Pure. */
export function firstToken(meta: Record<string, unknown> | null | undefined): string | null {
  const raw = meta?.firebaseStorageDownloadTokens;
  if (typeof raw !== 'string' || !raw.trim()) return null;
  return raw.split(',')[0].trim() || null;
}

// ─────────────────────────────────────────────────────────── deps

/** Overridable in unit tests; production uses the defaults. */
export const mediaLibraryDeps = {
  db: (): FirebaseFirestore.Firestore => admin.firestore(),
  now: (): number => Date.now(),
  /** Gives the object a download token when it has none; returns the token. */
  ensureToken: async (bucket: string, objectPath: string, meta: Record<string, unknown> | null): Promise<string> => {
    const existing = firstToken(meta);
    if (existing) return existing;
    const token = randomUUID();
    await admin.storage().bucket(bucket).file(objectPath)
      .setMetadata({ metadata: { firebaseStorageDownloadTokens: token } });
    return token;
  },
  /** Pixel size from the image header (first 256 KB only), or null. */
  readDims: async (bucket: string, objectPath: string): Promise<{ width: number; height: number } | null> => {
    try {
      const [buf] = await admin.storage().bucket(bucket).file(objectPath).download({ start: 0, end: 262_143 });
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const sharp = require('sharp');
      const md = await sharp(buf, { failOn: 'none' }).metadata();
      return md.width && md.height ? { width: md.width, height: md.height } : null;
    } catch {
      return null;
    }
  },
  /** Writes the thumbnail + reduced copy of an approved picture. */
  makeRenditions: async (bucket: string, objectPath: string, uid: string): Promise<Renditions> => {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const sharp = require('sharp');
    const b = admin.storage().bucket(bucket);
    const [buf] = await b.file(objectPath).download();
    const itemId = libraryItemId(objectPath);
    const write = async (kind: RenditionKind, px: number, quality: number) => {
      const { data, info } = await sharp(buf, { failOn: 'none' })
        .rotate() // apply EXIF orientation before the EXIF is dropped
        .resize({ width: px, height: px, fit: 'inside', withoutEnlargement: true })
        .jpeg({ quality, mozjpeg: true })
        .toBuffer({ resolveWithObject: true });
      const path = renditionPath(uid, itemId, kind);
      const token = randomUUID();
      await b.file(path).save(data, {
        resumable: false,
        contentType: 'image/jpeg',
        metadata: {
          // Content is immutable per path + token: let devices cache it.
          cacheControl: 'public, max-age=31536000',
          metadata: { firebaseStorageDownloadTokens: token, source: objectPath },
        },
      });
      return { url: downloadUrlFor(bucket, path, token), width: info.width as number, height: info.height as number };
    };
    const thumb = await write('thumb', THUMB_PX, 72);
    const medium = await write('medium', MEDIUM_PX, 82);
    return { thumbUrl: thumb.url, mediumUrl: medium.url, mediumWidth: medium.width, mediumHeight: medium.height };
  },
  /** Removes both renditions of an item (missing files are fine). */
  deleteRenditions: async (bucket: string, uid: string, itemId: string): Promise<void> => {
    const b = admin.storage().bucket(bucket);
    await Promise.all((['thumb', 'medium'] as RenditionKind[]).map((k) =>
      b.file(renditionPath(uid, itemId, k)).delete({ ignoreNotFound: true })));
  },
};

const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const del = () => admin.firestore.FieldValue.delete();

export function libraryRef(uid: string, itemId: string): FirebaseFirestore.DocumentReference {
  return mediaLibraryDeps.db().collection(MEDIA_LIBRARY).doc(uid).collection(LIBRARY_ITEMS).doc(itemId);
}

// ─────────────────────────────────────────────────────────── writes

export interface VerdictRecord {
  bucket: string;
  objectPath: string;
  generation: unknown;
  contentType?: string | null;
  meta: Record<string, string> | null | undefined;
  status: LibraryStatus;
  reasons?: string[];
  reasonCode?: string | null;
  hasFace?: boolean | null;
  /** moderation_queue item of the hold. */
  queueId?: string | null;
  /** moderation_decisions id when the hold produced an appealable decision. */
  decisionId?: string | null;
  /** The owner may ask for a human review (held items only). */
  reviewable?: boolean;
}

/**
 * Records one verdict in the owner's library. Returns the item path, or null
 * when the object is not a library image. Idempotent per object generation.
 */
export async function recordLibraryVerdict(v: VerdictRecord): Promise<string | null> {
  const target = libraryTarget(v.objectPath, v.meta);
  if (!target) return null;
  const ref = libraryRef(target.uid, libraryItemId(v.objectPath));
  const now = ts(mediaLibraryDeps.now());
  const prev = (await ref.get()).data();
  const base: Record<string, unknown> = {
    path: v.objectPath,
    bucket: v.bucket,
    usage: target.usage,
    contentType: v.contentType ?? null,
    generation: String(v.generation ?? '0'),
    status: v.status,
    reasons: v.reasons ?? [],
    reasonCode: v.reasonCode ?? null,
    updatedAt: now,
    createdAt: prev?.createdAt ?? now,
  };
  if (typeof v.hasFace === 'boolean') base.hasFace = v.hasFace;
  else if (!prev || !('hasFace' in prev)) base.hasFace = null;

  if (v.status === 'approved') {
    const token = await mediaLibraryDeps.ensureToken(v.bucket, v.objectPath, v.meta ?? null);
    const dims = await mediaLibraryDeps.readDims(v.bucket, v.objectPath);
    // Without renditions the app falls back to the original (never blocks
    // the approval).
    let r: Renditions | null = null;
    try {
      r = await mediaLibraryDeps.makeRenditions(v.bucket, v.objectPath, target.uid);
    } catch (e) {
      logError(`[mediaLibrary] renditions failed for ${v.objectPath}`, e);
    }
    Object.assign(base, {
      url: downloadUrlFor(v.bucket, v.objectPath, token),
      thumbUrl: r?.thumbUrl ?? null,
      mediumUrl: r?.mediumUrl ?? null,
      mediumWidth: r?.mediumWidth ?? null,
      mediumHeight: r?.mediumHeight ?? null,
      width: dims?.width ?? null,
      height: dims?.height ?? null,
      approvedAt: now,
      reviewable: false,
      quarantinePath: del(),
      heldAt: del(),
    });
  } else {
    // A held / rejected picture keeps no visible copies either.
    if (prev?.thumbUrl || prev?.mediumUrl) {
      try {
        await mediaLibraryDeps.deleteRenditions(v.bucket, target.uid, libraryItemId(v.objectPath));
      } catch (e) {
        logError(`[mediaLibrary] rendition cleanup failed for ${v.objectPath}`, e);
      }
    }
    Object.assign(base, {
      // Never a URL for something nobody may see (the owner included: a
      // shareable link to quarantined content would defeat the hold).
      url: null,
      thumbUrl: null,
      mediumUrl: null,
      approvedAt: del(),
      heldAt: now,
      quarantinePath: v.status === 'held' ? `quarantine/${v.objectPath}` : null,
      queueId: v.queueId ?? null,
      decisionId: v.decisionId ?? null,
      reviewable: v.status === 'held' && v.reviewable !== false,
      // A retried trigger for the same generation keeps a pending request.
      ...(prev && String(prev.generation) === base.generation ? {} : { review: null }),
    });
  }
  await ref.set(base, { merge: true });
  return ref.path;
}

/**
 * A moderator restored a quarantined object (restoreQuarantined). The item
 * becomes approved again with the restored generation; a pending review
 * request is marked approved and its imageReview queue item closed.
 */
export async function recordLibraryRestored(p: {
  bucket: string;
  objectPath: string;
  generation: string | null;
  meta: Record<string, string> | null | undefined;
}): Promise<string | null> {
  const target = libraryTarget(p.objectPath, p.meta);
  if (!target) return null;
  const ref = libraryRef(target.uid, libraryItemId(p.objectPath));
  const prev = (await ref.get()).data();
  const path = await recordLibraryVerdict({
    bucket: p.bucket,
    objectPath: p.objectPath,
    generation: p.generation ?? prev?.generation ?? '0',
    meta: p.meta,
    status: 'approved',
    reasons: [],
    hasFace: typeof prev?.hasFace === 'boolean' ? prev.hasFace : null,
    contentType: prev?.contentType ?? null,
  });
  const now = ts(mediaLibraryDeps.now());
  const review = prev?.review as Record<string, any> | null | undefined;
  if (review && review.status === 'pending') {
    await ref.set({ review: { ...review, status: 'approved', decidedAt: now } }, { merge: true });
    if (review.kind === 'imageReview' && typeof review.queueId === 'string') {
      const q = mediaLibraryDeps.db().collection('moderation_queue').doc(review.queueId);
      const cur = (await q.get()).data();
      if (cur && cur.status === 'pending') {
        await q.set({
          status: 'resolved',
          action: 'approve',
          resolvedAt: now,
          resolvedBy: 'linked_restore',
          slaAlertAt: del(),
        }, { merge: true });
      }
    }
  }
  return path;
}

/**
 * A person confirmed (or an appeal upheld) the hold: the item stays hidden
 * and is final unless an appealable decision still allows an appeal.
 */
export async function recordLibraryHoldFinal(p: {
  uid: string;
  objectPath: string;
  decisionId?: string | null;
  reviewable: boolean;
}): Promise<void> {
  const ref = libraryRef(p.uid, libraryItemId(p.objectPath));
  const prev = (await ref.get()).data();
  if (!prev || prev.status === 'approved') return;
  const now = ts(mediaLibraryDeps.now());
  const review = prev.review as Record<string, any> | null | undefined;
  await ref.set({
    status: 'rejected',
    reviewable: p.reviewable,
    updatedAt: now,
    ...(p.decisionId ? { decisionId: p.decisionId } : {}),
    ...(review && review.status === 'pending'
      ? { review: { ...review, status: 'rejected', decidedAt: now, ...(p.decisionId ? { decisionId: p.decisionId } : {}) } }
      : {}),
  }, { merge: true });
}

/**
 * Appeal resolved (appealResolution.resolveAppeal) on a decision whose effects
 * held images: overturned -> restoreQuarantined already re-approved them;
 * upheld -> the items become final.
 */
export async function syncLibraryAfterAppeal(
  decision: Record<string, any> | null | undefined,
  outcome: string,
): Promise<void> {
  if (!decision || decision.role === 'reporter') return;
  const uid = typeof decision.userId === 'string' ? decision.userId : '';
  if (!uid) return;
  const effects = Array.isArray(decision.effects) ? decision.effects : [];
  for (const e of effects) {
    if (e?.type !== 'quarantine' || typeof e.objectPath !== 'string') continue;
    try {
      if (outcome === 'upheld') {
        await recordLibraryHoldFinal({ uid, objectPath: e.objectPath, decisionId: decision.decisionId ?? null, reviewable: false });
      } else {
        const ref = libraryRef(uid, libraryItemId(e.objectPath));
        const prev = (await ref.get()).data();
        const review = prev?.review as Record<string, any> | null | undefined;
        if (prev && review && review.status === 'pending') {
          await ref.set({ review: { ...review, status: 'approved', decidedAt: ts(mediaLibraryDeps.now()) } }, { merge: true });
        }
      }
    } catch (err) {
      logError(`[mediaLibrary] appeal sync failed for ${e.objectPath}`, err);
    }
  }
}

/**
 * Storage object deleted: drop the APPROVED item of exactly that generation
 * (a quarantine move deletes the original too - that item is 'held' by then
 * and stays; a restore is a new generation and is not touched).
 */
export async function handleLibraryObjectDeleted(p: {
  objectPath: string;
  generation: unknown;
  meta: Record<string, string> | null | undefined;
}): Promise<'deleted' | 'kept' | 'none'> {
  const target = libraryTarget(p.objectPath, p.meta);
  if (!target) return 'none';
  const ref = libraryRef(target.uid, libraryItemId(p.objectPath));
  const cur = (await ref.get()).data();
  if (!cur) return 'none';
  if (cur.status !== 'approved' || String(cur.generation) !== String(p.generation ?? '')) return 'kept';
  await ref.delete();
  // The smaller copies must not outlive the original (removal or takedown).
  try {
    await mediaLibraryDeps.deleteRenditions(String(cur.bucket || ''), target.uid, libraryItemId(p.objectPath));
  } catch (e) {
    logError(`[mediaLibrary] rendition cleanup failed for ${p.objectPath}`, e);
  }
  return 'deleted';
}

/** Face status recorded on the owner's library item, or null. */
export async function libraryHasFace(uid: string, objectPath: string): Promise<boolean | null> {
  const d = (await libraryRef(uid, libraryItemId(objectPath)).get()).data();
  if (!d || d.status !== 'approved') return null;
  return typeof d.hasFace === 'boolean' ? d.hasFace : null;
}

/** Caches an on-demand face result on the library item (best-effort). */
export async function saveLibraryFace(uid: string, objectPath: string, hasFace: boolean): Promise<void> {
  try {
    await libraryRef(uid, libraryItemId(objectPath)).update({ hasFace });
  } catch {
    // No item (not a library image): nothing to cache.
  }
}
