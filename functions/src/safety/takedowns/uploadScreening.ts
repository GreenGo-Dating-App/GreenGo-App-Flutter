/**
 * Hash screening of new uploads (called by moderateUploadedImage before the
 * Vision check).
 *
 * SCOPE - PUBLIC SURFACES ONLY (audit EU-19): profile photos, community
 * media, storefronts, video-profile thumbnails and event covers (all under
 * the public prefixes below, not marked `visibility: private`). Private chat,
 * group and support images are NOT hash-scanned for anyone: the EU ePrivacy
 * derogation (Reg. 2021/1232) that allowed voluntary CSAM scanning of private
 * messages lapsed on 3 Apr 2026, and counsel has not cleared a country-gated
 * variant yet. Reports of private content still go through the report flow
 * (a user report is not scanning).
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
}): Promise<ScreeningResult> {
  if (!isPublicScanScope(p.objectPath, p.visibility)) return { scanned: false, blocked: false };
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
    reportedUserId: p.userId || null,
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
