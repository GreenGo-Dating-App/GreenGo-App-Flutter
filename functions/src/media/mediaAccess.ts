/**
 * getMediaUrl — short-lived, membership-checked read URLs for PRIVATE chat
 * media (security Phase 1, P1-3; audit H-06 / L-01).
 *
 * Why: chat / group / support media is stored as a Firebase download URL
 * (`...?alt=media&token=...`) in each message's `content`. That token is a
 * bearer credential that never expires and bypasses Storage rules, so the
 * tightened storage.rules stop strangers from LISTING / GUESSING / uploading,
 * but not someone who already holds a URL (a forwarded message, a leaked
 * log, a former group member). The fix is to store the object PATH in new
 * messages and resolve it through this callable at display time.
 *
 * Contract:
 *   in:  { path: 'chat_images/{chatKey}/{file}' }  (or a download URL / gs://
 *        URI of such an object, accepted for the migration period)
 *   out: { url, expiresAt }  V4 signed GET URL valid MEDIA_URL_TTL_MS.
 *
 * Access = the same membership the Storage rules enforce (storage.rules,
 * "PRIVATE CHAT MEDIA"): synthetic 1:1 keys (search_/bizsearch_/superlike_/
 * gift_ + both uids), matches/{id}.userId1|2, conversations/{id} members,
 * groups/{id}.participants, support conversation owner / assigned agent.
 * Admin-panel staff (requireAdmin, SUPPORT roles) may read any of them.
 *
 * IAM: getSignedUrl() signs with the function's runtime service account via
 * the IAM Credentials `signBlob` API, so that account needs
 * `iam.serviceAccounts.signBlob` ON ITSELF, i.e. grant
 * roles/iam.serviceAccountTokenCreator to the runtime SA on the runtime SA.
 * roles/editor does NOT include signBlob. Without it the call fails with
 * 'failed-precondition' (logged) and nothing leaks.
 */

import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { isAdminCaller, SUPPORT_ROLES } from '../shared/adminAuth';
import { storagePathFromAudioUrl } from './voiceTranscription';

if (!admin.apps.length) admin.initializeApp();

export const MEDIA_URL_TTL_MS = 15 * 60 * 1000;
const SEGMENT = /^[A-Za-z0-9_-]{1,128}$/;
const FILE = /^[^/\\]{1,200}$/; // app names: {uuid}.{ext}
const SYNTHETIC = /^(search|bizsearch|superlike|gift)_/;

export type MediaScope =
  | { kind: 'chat'; key: string }
  | { kind: 'group'; key: string }
  | { kind: 'support'; key: string };

const ROOTS: Record<string, MediaScope['kind']> = {
  chat_images: 'chat',
  chat_voice: 'chat',
  chat_videos: 'chat',
  group_media: 'group',
  group_voice: 'group',
  support_attachments: 'support',
};

/** Which chat a private-media path belongs to; null = not private chat media. */
export function mediaScopeFromPath(path: string): MediaScope | null {
  const parts = path.split('/');
  if (parts.length !== 3) return null;
  const [root, key, file] = parts;
  const kind = ROOTS[root];
  if (!kind || !SEGMENT.test(key) || !FILE.test(file) || file.startsWith('.')) return null;
  return { kind, key };
}

function inConversation(c: FirebaseFirestore.DocumentData | undefined, uid: string): boolean {
  if (!c) return false;
  return c.userId1 === uid || c.userId2 === uid || c.supportAgentId === uid ||
    (Array.isArray(c.participants) && c.participants.includes(uid));
}

/** Same membership test as storage.rules. */
export async function isMediaMember(scope: MediaScope, uid: string): Promise<boolean> {
  const db = admin.firestore();
  if (scope.kind === 'group') {
    const p = (await db.collection('groups').doc(scope.key).get()).data()?.participants;
    return Array.isArray(p) && p.includes(uid);
  }
  if (scope.kind === 'support') {
    return inConversation((await db.collection('conversations').doc(scope.key).get()).data(), uid);
  }
  if (SYNTHETIC.test(scope.key)) {
    const p = scope.key.split('_');
    return p.length === 3 && (p[1] === uid || p[2] === uid);
  }
  if (inConversation((await db.collection('matches').doc(scope.key).get()).data(), uid)) return true;
  return inConversation((await db.collection('conversations').doc(scope.key).get()).data(), uid);
}

export const getMediaUrl = onCall(
  { memory: '512MiB', timeoutSeconds: 30 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required');

    const raw = request.data?.path ?? request.data?.url;
    const path = storagePathFromAudioUrl(raw);
    const scope = path ? mediaScopeFromPath(path) : null;
    if (!path || !scope) throw new HttpsError('invalid-argument', 'Not a private chat media path');

    const allowed = (await isMediaMember(scope, uid)) ||
      (await isAdminCaller(request.auth, SUPPORT_ROLES));
    if (!allowed) throw new HttpsError('permission-denied', 'Not a member of this chat');

    const file = admin.storage().bucket().file(path);
    const [exists] = await file.exists();
    if (!exists) throw new HttpsError('not-found', 'Media not found');

    const expires = Date.now() + MEDIA_URL_TTL_MS;
    try {
      const [url] = await file.getSignedUrl({ version: 'v4', action: 'read', expires });
      return { url, expiresAt: expires };
    } catch (e: any) {
      // Typically a missing iam.serviceAccounts.signBlob permission.
      console.error('getMediaUrl: signing failed', e?.message || e);
      throw new HttpsError('failed-precondition', 'Media URL signing is not configured');
    }
  }
);
