/**
 * Server-side NSFW moderation for every user-uploaded image.
 *
 * WHY A STORAGE TRIGGER
 * ---------------------
 * Before this, nothing checked uploads at all:
 *
 *   - the web client skipped validation entirely (`if (!kIsWeb)` in
 *     profile_bloc), relying on a "server-side moderation" that did not exist;
 *   - `moderatePhoto` in contentModeration.ts was deployed but called by
 *     NOBODY - no client, no trigger;
 *   - the Vision API was DISABLED on the project, so it could not have worked
 *     even if something had called it.
 *
 * On-device ML Kit (which mobile still runs as a fast first pass) cannot be the
 * enforcement point: it runs inside the app, so a modified client - or anyone
 * calling the Firebase API directly with a valid token - walks straight past
 * it. A Storage trigger sees every byte that lands in the bucket regardless of
 * which client sent it, which is the only place the check cannot be bypassed.
 *
 * WHAT HAPPENS TO A REJECTED IMAGE
 * --------------------------------
 * It is MOVED to `quarantine/<original path>` and deleted from its original
 * location, never destroyed: SafeSearch does produce false positives, and
 * irreversibly deleting someone's photo on a maybe is not recoverable. The
 * quarantine prefix is readable only by admins (see storage.rules).
 *
 * HOW THE CLIENT WAITS
 * --------------------
 * Every verdict is written to `image_moderation/{encodedPath}`, where the id is
 * the object path with '/' replaced by '~' so the uploader can compute it
 * without a round-trip and listen for its own result. The client blocks on that
 * document before putting the URL anywhere, so an image is never displayed or
 * attached to a profile before it has passed.
 *
 * PRIVATE PHOTOS ARE CHECKED TOO (P2-8a)
 * --------------------------------------
 * Private-album photos used to be exempt (`visibility: private` metadata).
 * They are shared with other users all the same, so since P2-8 EVERY image
 * under a moderated prefix is checked - private albums, chat and group images
 * included - with the same quarantine behaviour. The visibility is recorded on
 * the moderation_queue item so reviewers can tell them apart.
 *
 * CHAT VIDEOS ARE NOT CHECKED (yet): Vision cannot read video, and frame
 * extraction needs an ffmpeg binary the Functions runtime does not ship (only
 * the fluent-ffmpeg wrapper is installed). Options: ffmpeg-static (new npm
 * package) or the Video Intelligence API (async, separate API + billing).
 */

import { onObjectFinalized } from 'firebase-functions/v2/storage';
import * as admin from 'firebase-admin';
import vision from '@google-cloud/vision';
import { logInfo, logError } from '../shared/utils';
import { screenUploadAgainstHashLists } from './takedowns/uploadScreening';
import { createModerationDecision } from './moderationDecisions';

const db = admin.firestore();
// Constructed lazily: this module is loaded by index.js along with every other
// function, and building the client eagerly costs memory in all of them.
let visionClient: InstanceType<typeof vision.ImageAnnotatorClient> | null = null;
function client(): InstanceType<typeof vision.ImageAnnotatorClient> {
  visionClient ??= new vision.ImageAnnotatorClient();
  return visionClient;
}

/** Prefixes holding user-uploaded imagery that must be moderated. */
const MODERATED = [
  'profiles/',            // profile photos, event covers, group avatars
  'communities/',
  'chat_images/',
  'group_media/',
  'support_attachments/',
  'storefronts/',
  'video_profiles/',      // video-intro thumbnails (images only; videos skipped below)
  'ticket_receipts/',     // link-mode ticket payment receipts (private: buyer + organizer)
];

/**
 * Never moderated.
 *
 *  - `attractions/` is content OUR ingester pulls from Geoapify/Viator. It is
 *    not user content, and it is 14k of the 14.7k images in the bucket - it
 *    would dominate the Vision bill for no safety benefit.
 *  - identity/verification images are documents, not public imagery, and are
 *    deleted straight after OCR.
 *  - `quarantine/` must never re-trigger: that is an infinite loop.
 */
const NEVER = [
  'attractions/',
  'quarantine/',
  // Safety takedown holds (safety/takedowns): moved there by the server.
  'safety_holds/',
  'legal_holds/',
  'verifications/',
  'age_verification/',
  'business_verification/',
  'FCMImages/',
];

const IMAGE = /\.(jpe?g|png|webp|heic|heif|bmp|gif)$/i;

/**
 * moderation_queue id of one held upload: one item per object GENERATION, so
 * a re-upload to the same path is a new item (and a new decision).
 */
export function quarantineQueueId(objectPath: string, generation: unknown): string {
  return `image__${moderationDocId(objectPath)}__${String(generation ?? '0')}`.slice(0, 1400);
}

/** Statement-of-reasons code for SafeSearch reasons; null = no rule breach (no_face). Pure. */
export function reasonCodeForVision(reasons: string[]): string | null {
  if (reasons.includes('adult') || reasons.includes('racy')) return 'sexual_content';
  if (reasons.includes('violence')) return 'violence';
  return null;
}

/** Firestore doc id for an object path (ids may not contain '/'). */
export function moderationDocId(objectPath: string): string {
  return objectPath.replace(/\//g, '~');
}

type Likelihood =
  | 'UNKNOWN' | 'VERY_UNLIKELY' | 'UNLIKELY' | 'POSSIBLE' | 'LIKELY' | 'VERY_LIKELY';

const RANK: Record<string, number> = {
  UNKNOWN: 0, VERY_UNLIKELY: 0, UNLIKELY: 1, POSSIBLE: 2, LIKELY: 3, VERY_LIKELY: 4,
};
const atLeast = (v: Likelihood | null | undefined, min: keyof typeof RANK) =>
  RANK[v || 'UNKNOWN'] >= RANK[min];

export const moderateUploadedImage = onObjectFinalized(
  {
    // Vision responses plus the image buffer do not fit the 256MiB default
    // alongside this codebase - index.js alone needs ~200MB to load.
    memory: '512MiB',
    timeoutSeconds: 120,
  },
  async (event) => {
    const objectPath = event.data.name || '';
    const contentType = event.data.contentType || '';
    const meta = (event.data.metadata || {}) as Record<string, string>;

    if (NEVER.some((p) => objectPath.startsWith(p))) return;
    if (!MODERATED.some((p) => objectPath.startsWith(p))) return;
    if (!contentType.startsWith('image/') && !IMAGE.test(objectPath)) return;

    // Voice notes and videos live under the same prefixes.
    if (/\/(voice|chat_voice|chat_videos)\//.test('/' + objectPath)) return;

    // P2-8a: private-album images are moderated like every other image.
    const visibility = (meta.visibility || '').toLowerCase() === 'private' ? 'private' : 'public';

    const docRef = db.collection('image_moderation').doc(moderationDocId(objectPath));
    const userId = meta.userId || objectPath.split('/')[1] || '';

    // A moderator restored this exact object from quarantine (approve /
    // overturned appeal, moderationEffects.restoreQuarantined): do not screen
    // the copy again. A later re-upload is a new generation and is screened.
    try {
      const prev = (await docRef.get()).data();
      if (prev?.restorePending === true
        || (prev?.moderatorApproved === true && prev?.approvedGeneration
          && String(prev.approvedGeneration) === String(event.data.generation))) {
        logInfo(`[moderate] SKIP moderator-restored ${objectPath}`);
        return;
      }
    } catch (e) {
      logError(`[moderate] verdict read failed for ${objectPath}`, e);
    }
    // Only a MAIN profile photo must contain a face; everything else is
    // checked for explicit content alone.
    const requireFace = (meta.requireFace || '').toLowerCase() === 'true';

    const bucket = admin.storage().bucket(event.data.bucket);
    const gcsUri = `gs://${event.data.bucket}/${objectPath}`;

    // NCII / CSAE re-upload blocking (safety/takedowns/uploadScreening.ts):
    // public surfaces only (audit EU-19). A match moves the file out of reach
    // and opens a P0 safety case; the uploader sees an ordinary rejection.
    try {
      const screening = await screenUploadAgainstHashLists({
        bucketName: event.data.bucket,
        objectPath,
        userId,
        visibility,
        size: Number(event.data.size || 0),
      });
      if (screening.blocked) {
        await docRef.set({
          status: 'rejected',
          userId,
          objectPath,
          reasons: ['blocked_hash'],
          checkedAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 24 * 3600 * 1000),
        });
        logInfo(`[moderate] BLOCKED_HASH ${objectPath} case=${screening.caseId}`);
        return;
      }
    } catch (e) {
      logError(`[moderate] hash screening failed for ${objectPath}`, e);
    }

    try {
      // ONE annotate call for all three features. SafeSearch is billed free
      // when requested alongside Label Detection, so labels cost nothing extra
      // here and give admins context on a rejection.
      const [result] = await client().annotateImage({
        image: { source: { imageUri: gcsUri } },
        features: [
          { type: 'SAFE_SEARCH_DETECTION' },
          { type: 'LABEL_DETECTION', maxResults: 10 },
          ...(requireFace ? [{ type: 'FACE_DETECTION' as const, maxResults: 5 }] : []),
        ],
      });

      const safe = result.safeSearchAnnotation || {};
      const faces = result.faceAnnotations || [];
      const labels = (result.labelAnnotations || [])
        .map((l) => l.description)
        .filter(Boolean) as string[];

      const reasons: string[] = [];
      // Nudity: zero tolerance. POSSIBLE is enough to hold it back.
      if (atLeast(safe.adult as Likelihood, 'POSSIBLE')) reasons.push('adult');
      // Racy at POSSIBLE fires on ordinary beach and gym photos, so the bar
      // here is LIKELY. Tune in one place if it proves too loose or too tight.
      if (atLeast(safe.racy as Likelihood, 'LIKELY')) reasons.push('racy');
      if (atLeast(safe.violence as Likelihood, 'LIKELY')) reasons.push('violence');
      if (requireFace && faces.length === 0) reasons.push('no_face');

      const approved = reasons.length === 0;

      if (!approved) {
        // MOVE to quarantine rather than delete - a false positive must be
        // recoverable, and an admin needs to see what was rejected.
        let moved = false;
        try {
          await bucket.file(objectPath).copy(bucket.file(`quarantine/${objectPath}`));
          await bucket.file(objectPath).delete();
          moved = true;
        } catch (e) {
          logError(`[moderate] quarantine move failed for ${objectPath}`, e);
        }

        // Same shape as report items (status/addedAt/itemType) so the admin
        // panel lists it and takeModerationAction handles it: approve restores
        // the upload, removeContent confirms the hold.
        const queueId = quarantineQueueId(objectPath, event.data.generation);
        const reasonCode = reasonCodeForVision(reasons);
        const fileName = objectPath.split('/').pop() || objectPath;
        await db.collection('moderation_queue').doc(queueId).set({
          queueId,
          itemType: 'quarantinedImage',
          itemId: objectPath,
          status: 'pending',
          priority: reasonCode ? 'high' : 'low',
          category: reasonCode ? (reasonCode === 'violence' ? 'violence' : 'inappropriateContent') : 'other',
          reasonCode: reasonCode ?? 'other',
          addedAt: admin.firestore.FieldValue.serverTimestamp(),
          assignedTo: null,
          relatedReportIds: [],
          metadata: { reasonCode: reasonCode ?? 'other', reasons, visibility },
          contentRef: { type: 'photo', id: fileName, path: objectPath },
          reporterId: 'system',
          autoFlag: { engine: 'vision-safesearch', automatedActions: 'quarantine' },
          type: 'image',
          userId,
          objectPath,
          quarantinePath: `quarantine/${objectPath}`,
          visibility,
          reasons,
          safeSearch: {
            adult: safe.adult || null,
            racy: safe.racy || null,
            violence: safe.violence || null,
            medical: safe.medical || null,
            spoof: safe.spoof || null,
          },
          labels,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // DSA art. 17 / Terms 18.3: the hold is an automated measure; the
        // uploader gets the statement of reasons (in-app + email) and can
        // appeal (overturn restores the file). A missing face is a profile
        // photo requirement, not a rule breach: no decision for that alone.
        if (moved && reasonCode && userId) {
          try {
            await createModerationDecision({
              decisionId: queueId,
              queueId,
              userId,
              action: 'removeContent',
              reasonCode,
              explanation: `Our automatic image check held this photo back (${reasons.filter((r) => r !== 'no_face').join(', ')}) until a person reviews it.`,
              decidedBy: 'system',
              contentRef: { type: 'photo', id: fileName, excerpt: null },
              automated: { detection: 'vision', decision: true },
              effects: [{ type: 'quarantine', objectPath, quarantinePath: `quarantine/${objectPath}` }],
            });
          } catch (e) {
            logError(`[moderate] decision notice failed for ${objectPath}`, e);
          }
        }
      }

      await docRef.set({
        status: approved ? 'approved' : 'rejected',
        userId,
        objectPath,
        reasons,
        checkedAt: admin.firestore.FieldValue.serverTimestamp(),
        // Short-lived: the uploader reads this once. A TTL policy on this field
        // keeps the collection from growing without bound.
        expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 24 * 3600 * 1000),
      });

      logInfo(`[moderate] ${approved ? 'APPROVED' : 'REJECTED'} ${objectPath}` +
        (approved ? '' : ` reasons=${reasons.join(',')}`));
    } catch (e) {
      // FAIL CLOSED on the verdict the client waits for. If Vision is down or
      // the API is disabled we must not hand back "approved" - that is exactly
      // how an unchecked image reaches a profile. The file is left in place so
      // an admin can resolve it; the uploader is told the check failed.
      logError(`[moderate] verification error for ${objectPath}`, e);
      await docRef.set({
        status: 'error',
        userId,
        objectPath,
        reasons: ['verification_failed'],
        checkedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 24 * 3600 * 1000),
      }, { merge: true });
    }
  },
);
