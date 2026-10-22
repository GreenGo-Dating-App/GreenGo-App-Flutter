/**
 * adminQuarantinePreview: lets a moderator SEE a held picture in the admin
 * panel (owner request 2026-10-22, Apple guideline 1.2: act on held content
 * quickly).
 *
 * Why a callable: moderateUploadedImage moves a held upload to
 * `quarantine/<path>` with a NEW download token, so the URL stored anywhere
 * stops working. storage.rules give `quarantine/**` read only to
 * `token.admin == true`, a legacy boolean claim that the current admin role
 * sync (admin/adminClaims.ts, `adminRole` claim) never sets, so panel
 * moderators cannot read it with the Storage SDK. Handing out the
 * quarantined copy's token would also give a permanent bearer link. Instead
 * this returns a V4 signed URL valid PREVIEW_TTL_MS.
 *
 * Contract:
 *   in:  { queueId }  (a moderation_queue item; the caller never names a path)
 *   out: { url, expiresAt, path, location: 'quarantine' | 'original', contentType }
 * Items: `quarantinedImage` (quarantinePath, else objectPath when the move
 * failed or the file was already restored), `imageReview` (same fields), and
 * `appeal` items carrying `imageReview.objectPath` (picture appeals).
 * Only moderated image prefixes are served: never safety_holds/, legal_holds/
 * or any other path. Role: superAdmin | moderator. Every view is audited.
 *
 * IAM: same as getMediaUrl (runtime SA needs signBlob on itself).
 */

import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import { MODERATION_ROLES, requireAdmin } from '../shared/adminAuth';

export const PREVIEW_TTL_MS = 10 * 60 * 1000;

/** User-image prefixes moderateUploadedImage screens (and so may quarantine). */
export const PREVIEWABLE_PREFIXES = [
  'profiles/', 'communities/', 'chat_images/', 'group_media/', 'support_attachments/',
  'storefronts/', 'video_profiles/', 'ticket_receipts/',
];

const QUEUE_ID = /^[^/]{1,1500}$/;

function cleanObjectPath(p: unknown): string | null {
  if (typeof p !== 'string' || p.length === 0 || p.length > 1024) return null;
  if (p.includes('..') || p.includes('\\') || p.startsWith('/') || p.includes('//')) return null;
  return PREVIEWABLE_PREFIXES.some((x) => p.startsWith(x)) ? p : null;
}

export interface PreviewCandidate {
  path: string;
  location: 'quarantine' | 'original';
}

/**
 * Storage paths to try for a queue item, quarantine first. Pure. Empty when
 * the item is not a picture item or names an unexpected path.
 */
export function previewCandidates(item: Record<string, any> | undefined | null): PreviewCandidate[] {
  if (!item) return [];
  let objectPath: string | null = null;
  let quarantinePath: unknown = null;
  if (item.itemType === 'quarantinedImage' || item.itemType === 'imageReview' || item.type === 'image') {
    objectPath = cleanObjectPath(item.objectPath ?? item.itemId);
    quarantinePath = item.quarantinePath;
  } else if (item.itemType === 'appeal' && item.imageReview && typeof item.imageReview === 'object') {
    objectPath = cleanObjectPath(item.imageReview.objectPath);
  } else {
    return [];
  }
  if (!objectPath) return [];
  const expectedQuarantine = `quarantine/${objectPath}`;
  // A stored quarantinePath must be exactly quarantine/<objectPath>; anything
  // else is ignored (never serve a path the item merely claims).
  const q = quarantinePath == null || quarantinePath === expectedQuarantine ? expectedQuarantine : null;
  const out: PreviewCandidate[] = [];
  if (q) out.push({ path: q, location: 'quarantine' });
  out.push({ path: objectPath, location: 'original' });
  return out;
}

/** Overridable in unit tests; production uses the defaults. */
export const quarantinePreviewDeps = {
  db: (): FirebaseFirestore.Firestore => admin.firestore(),
  now: (): number => Date.now(),
  requireModerator: async (auth: unknown): Promise<{ uid: string; role: string }> => {
    const who = await requireAdmin(auth as any, MODERATION_ROLES);
    return { uid: who.uid, role: who.role };
  },
  /** null = object missing; else its content type. */
  stat: async (path: string): Promise<{ contentType: string | null } | null> => {
    const file = admin.storage().bucket().file(path);
    const [exists] = await file.exists();
    if (!exists) return null;
    const [meta] = await file.getMetadata();
    return { contentType: (meta?.contentType as string) ?? null };
  },
  sign: async (path: string, expires: number): Promise<string> => {
    const [url] = await admin.storage().bucket().file(path).getSignedUrl({ version: 'v4', action: 'read', expires });
    return url;
  },
};

export interface QuarantinePreviewResult {
  url: string;
  expiresAt: number;
  path: string;
  location: 'quarantine' | 'original';
  contentType: string | null;
}

export async function handleQuarantinePreview(auth: unknown, data: unknown): Promise<QuarantinePreviewResult> {
  const d = quarantinePreviewDeps;
  const who = await d.requireModerator(auth);
  const queueId = (data as any)?.queueId;
  if (typeof queueId !== 'string' || !QUEUE_ID.test(queueId)) {
    throw new HttpsError('invalid-argument', 'queueId is required', { code: 'invalid_queue_id' });
  }
  const snap = await d.db().collection('moderation_queue').doc(queueId).get();
  if (!snap.exists) throw new HttpsError('not-found', 'Queue item not found', { code: 'queue_item_not_found' });

  const candidates = previewCandidates(snap.data());
  if (candidates.length === 0) {
    throw new HttpsError('failed-precondition', 'Not a picture item', { code: 'not_a_picture_item' });
  }

  for (const c of candidates) {
    const st = await d.stat(c.path);
    if (!st) continue;
    const expiresAt = d.now() + PREVIEW_TTL_MS;
    let url: string;
    try {
      url = await d.sign(c.path, expiresAt);
    } catch (e: any) {
      console.error('adminQuarantinePreview: signing failed', e?.message || e);
      throw new HttpsError('failed-precondition', 'Preview URL signing is not configured', { code: 'signing_failed' });
    }
    try {
      await d.db().collection('admin_audit_log').add({
        adminId: who.uid,
        action: 'viewedHeldImage',
        targetType: 'moderation_queue',
        targetId: queueId,
        details: { path: c.path, location: c.location, role: who.role },
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e: any) {
      console.error('adminQuarantinePreview: audit write failed', e?.message || e);
    }
    return { url, expiresAt, path: c.path, location: c.location, contentType: st.contentType };
  }
  throw new HttpsError('not-found', 'The picture is no longer stored', { code: 'object_not_found' });
}

export const adminQuarantinePreview = onCall(
  { memory: '512MiB', timeoutSeconds: 30 },
  (request) => handleQuarantinePreview(request.auth, request.data),
);
