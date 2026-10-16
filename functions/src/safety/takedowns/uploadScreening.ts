/**
 * Hash screening of new uploads (called by moderateUploadedImage before the
 * Vision check).
 *
 * SCOPE (audit EU-19, Terms 17.1 b):
 *   - ALWAYS: public surfaces - profile photos, community media, storefronts,
 *     video-profile thumbnails and event covers (the public prefixes below,
 *     not marked `visibility: private`).
 *   - ONLY WHEN `app_config/safety_settings.privateHashScanEnabled == true`:
 *     1:1 chat images (`chat_images/`), group media (`group_media/`) and
 *     private-album photos (`profiles/` with `visibility: private`). Same hash
 *     lookup, no extra cost beyond the download + hash already done for
 *     public uploads. OFF by default: the EU ePrivacy derogation (Reg.
 *     2021/1232) that allowed voluntary CSAM scanning of private messages
 *     lapsed on 3 Apr 2026 and counsel has to clear it first (owner step,
 *     docs/safety/csae-ncii-runbook.md section 5).
 *   - Never: support attachments, receipts, voice/video.
 * Reports of private content always go through the report flow (a user
 * report is not scanning).
 *
 * On a match the object is moved out of reach at once and a P0 case opens:
 *   - csam_hash_list (external lists) or a blocked CSAE hash -> CSAE case,
 *     file moved to the case hold, legal hold on the uploader;
 *   - a blocked NCII hash (an image we removed before) -> NCII case linked to
 *     the original case.
 * The uploader's client sees an ordinary "rejected" verdict.
 *
 * Fail-open on infrastructure errors (the Vision check that follows is
 * fail-closed for the verdict anyway).
 */

import * as admin from 'firebase-admin';
import '../../shared/firebaseAdmin';
import { computeImageHashes } from './perceptualHash';
import { findBlockedMatch, findCsamMatch, BlockedHashMatch } from './hashLists';
import { createSafetyCase, HiddenItem, SAFETY_HOLD_PREFIX } from './safetyCases';
import { classifyWithContentSafetyApi } from './contentSafetyApi';

const db = () => admin.firestore();

/** Public prefixes (event covers and group avatars live under profiles/). */
export const PUBLIC_HASH_SCAN_PREFIXES = ['profiles/', 'communities/', 'storefronts/', 'video_profiles/'];
const MAX_BYTES = 25 * 1024 * 1024;

export function isPublicScanScope(objectPath: string, visibility: string): boolean {
  return visibility !== 'private' && PUBLIC_HASH_SCAN_PREFIXES.some((p) => objectPath.startsWith(p));
}

/** Private surfaces, scanned only behind the counsel flag (see header). */
export const PRIVATE_HASH_SCAN_PREFIXES = ['chat_images/', 'group_media/'];

export function isPrivateScanScope(objectPath: string, visibility: string): boolean {
  if (/\/(voice|chat_voice|chat_videos)\//.test('/' + objectPath)) return false;
  if (PRIVATE_HASH_SCAN_PREFIXES.some((p) => objectPath.startsWith(p))) return true;
  return visibility === 'private' && objectPath.startsWith('profiles/');
}

export function isScanScope(objectPath: string, visibility: string, privateScanEnabled: boolean): boolean {
  return isPublicScanScope(objectPath, visibility)
    || (privateScanEnabled && isPrivateScanScope(objectPath, visibility));
}

// One settings read per instance per 5 minutes, not one per upload.
const FLAG_TTL_MS = 5 * 60_000;
let flagCache: { value: boolean; at: number } | null = null;

export async function privateHashScanEnabled(nowMs = Date.now()): Promise<boolean> {
  if (flagCache && nowMs - flagCache.at < FLAG_TTL_MS) return flagCache.value;
  let value = false;
  try {
    value = (await db().doc('app_config/safety_settings').get()).data()?.privateHashScanEnabled === true;
  } catch (e) {
    // Keep the last known value on a read error (default off).
    value = flagCache?.value ?? false;
  }
  flagCache = { value, at: nowMs };
  return value;
}

/** Tests only. */
export function resetPrivateScanFlagCache(): void {
  flagCache = null;
}

export interface ScreeningResult {
  scanned: boolean;
  blocked: boolean;
  caseId?: string;
  kind?: 'ncii' | 'csae';
  match?: BlockedHashMatch;
}

export async function screenUploadAgainstHashLists(p: {
  bucketName: string;
  objectPath: string;
  userId: string;
  visibility: string;
  size?: number;
  /** Uploader from the object's metadata (chat paths carry no uid segment). */
  uploaderId?: string | null;
}): Promise<ScreeningResult> {
  const isPublic = isPublicScanScope(p.objectPath, p.visibility);
  if (!isPublic) {
    if (!isPrivateScanScope(p.objectPath, p.visibility)) return { scanned: false, blocked: false };
    if (!(await privateHashScanEnabled())) return { scanned: false, blocked: false };
  }
  // chat_images/{chatKey}/ and group_media/{groupId}/: the 2nd segment is not
  // a user - only trust the uploader stamp there.
  const reportedUserId = isPublic || p.objectPath.startsWith('profiles/')
    ? (p.userId || null)
    : (p.uploaderId || null);
  if (p.size && p.size > MAX_BYTES) return { scanned: false, blocked: false };
  const bucket = admin.storage().bucket(p.bucketName);
  const file = bucket.file(p.objectPath);
  let buf: Buffer;
  try {
    [buf] = await file.download();
  } catch (e) {
    console.error(`[uploadScreening] download failed for ${p.objectPath}`, (e as Error)?.message || e);
    return { scanned: false, blocked: false };
  }
  let hashes;
  try {
    hashes = await computeImageHashes(buf);
  } catch (e) {
    // Not decodable as an image (or an unsupported format): nothing to match.
    return { scanned: false, blocked: false };
  }

  const csam = await findCsamMatch(hashes);
  const blocked = csam ?? await findBlockedMatch(hashes);

  // Optional classifier (stub; off unless CONTENT_SAFETY_API_ENABLED=true).
  if (!blocked) {
    const verdict = await classifyWithContentSafetyApi(buf);
    if (verdict?.reviewPriority === 'VERY_HIGH') {
      // TODO(content-safety): open a CSAE review case without hiding once the
      // API is contracted and its precision is known.
      console.warn(`[uploadScreening] Content Safety API flagged ${p.objectPath} (review)`);
    }
    return { scanned: true, blocked: false };
  }

  const kind = blocked.kind;
  // Move the object out of reach first, then open the case around it.
  const tmpCase = db().collection('safety_cases').doc();
  const holdPath = `${SAFETY_HOLD_PREFIX}${tmpCase.id}/${p.objectPath}`;
  try {
    await file.copy(bucket.file(holdPath));
    await file.delete({ ignoreNotFound: true });
  } catch (e) {
    console.error(`[uploadScreening] move failed for ${p.objectPath}`, e);
  }
  const preHidden: HiddenItem[] = [{
    type: 'storage', path: p.objectPath, holdPath, hashes, contentType: null,
  }];
  await createSafetyCase({
    caseId: tmpCase.id,
    kind,
    source: 'hash_match',
    requester: { name: null, email: null, phone: null, uid: null, role: 'system' },
    contentRefs: [],
    preHidden,
    reportedUserId,
    description: `Re-upload blocked: ${blocked.list} ${blocked.how} match`,
    hashMatch: {
      list: blocked.list,
      entryId: blocked.id,
      how: blocked.how,
      distance: blocked.distance ?? null,
      matchedCaseId: blocked.caseId,
    },
  });
  return { scanned: true, blocked: true, caseId: tmpCase.id, kind, match: blocked };
}
