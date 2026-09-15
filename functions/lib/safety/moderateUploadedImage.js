"use strict";
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
 * PRIVATE PHOTOS ARE EXEMPT
 * -------------------------
 * By product decision, private-album photos are not checked. They live in the
 * SAME storage path as public ones (`profiles/{uid}/photos/...`) - only the
 * Firestore array they land in differs - so the path cannot tell them apart.
 * The uploader marks them with `visibility: private` custom metadata instead.
 * An image with NO visibility metadata is treated as PUBLIC and IS checked:
 * the default has to be the safe one, or an old client that sets no metadata
 * would silently bypass moderation.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.moderateUploadedImage = void 0;
exports.moderationDocId = moderationDocId;
const storage_1 = require("firebase-functions/v2/storage");
const admin = __importStar(require("firebase-admin"));
const vision_1 = __importDefault(require("@google-cloud/vision"));
const utils_1 = require("../shared/utils");
const db = admin.firestore();
// Constructed lazily: this module is loaded by index.js along with every other
// function, and building the client eagerly costs memory in all of them.
let visionClient = null;
function client() {
    visionClient !== null && visionClient !== void 0 ? visionClient : (visionClient = new vision_1.default.ImageAnnotatorClient());
    return visionClient;
}
/** Prefixes holding user-uploaded imagery that must be moderated. */
const MODERATED = [
    'profiles/', // profile photos, event covers, group avatars
    'communities/',
    'chat_images/',
    'group_media/',
    'support_attachments/',
    'storefronts/',
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
    'verifications/',
    'age_verification/',
    'business_verification/',
    'FCMImages/',
];
const IMAGE = /\.(jpe?g|png|webp|heic|heif|bmp|gif)$/i;
/** Firestore doc id for an object path (ids may not contain '/'). */
function moderationDocId(objectPath) {
    return objectPath.replace(/\//g, '~');
}
const RANK = {
    UNKNOWN: 0, VERY_UNLIKELY: 0, UNLIKELY: 1, POSSIBLE: 2, LIKELY: 3, VERY_LIKELY: 4,
};
const atLeast = (v, min) => RANK[v || 'UNKNOWN'] >= RANK[min];
exports.moderateUploadedImage = (0, storage_1.onObjectFinalized)({
    // Vision responses plus the image buffer do not fit the 256MiB default
    // alongside this codebase - index.js alone needs ~200MB to load.
    memory: '512MiB',
    timeoutSeconds: 120,
}, async (event) => {
    const objectPath = event.data.name || '';
    const contentType = event.data.contentType || '';
    const meta = (event.data.metadata || {});
    if (NEVER.some((p) => objectPath.startsWith(p)))
        return;
    if (!MODERATED.some((p) => objectPath.startsWith(p)))
        return;
    if (!contentType.startsWith('image/') && !IMAGE.test(objectPath))
        return;
    // Voice notes and videos live under the same prefixes.
    if (/\/(voice|chat_voice|chat_videos)\//.test('/' + objectPath))
        return;
    // PRIVATE ALBUM - exempt by product decision. Absence of the flag means
    // public, so nothing can opt out of moderation by simply omitting it.
    if ((meta.visibility || '').toLowerCase() === 'private') {
        (0, utils_1.logInfo)(`[moderate] skipped (private): ${objectPath}`);
        return;
    }
    const docRef = db.collection('image_moderation').doc(moderationDocId(objectPath));
    const userId = meta.userId || objectPath.split('/')[1] || '';
    // Only a MAIN profile photo must contain a face; everything else is
    // checked for explicit content alone.
    const requireFace = (meta.requireFace || '').toLowerCase() === 'true';
    const bucket = admin.storage().bucket(event.data.bucket);
    const gcsUri = `gs://${event.data.bucket}/${objectPath}`;
    try {
        // ONE annotate call for all three features. SafeSearch is billed free
        // when requested alongside Label Detection, so labels cost nothing extra
        // here and give admins context on a rejection.
        const [result] = await client().annotateImage({
            image: { source: { imageUri: gcsUri } },
            features: [
                { type: 'SAFE_SEARCH_DETECTION' },
                { type: 'LABEL_DETECTION', maxResults: 10 },
                ...(requireFace ? [{ type: 'FACE_DETECTION', maxResults: 5 }] : []),
            ],
        });
        const safe = result.safeSearchAnnotation || {};
        const faces = result.faceAnnotations || [];
        const labels = (result.labelAnnotations || [])
            .map((l) => l.description)
            .filter(Boolean);
        const reasons = [];
        // Nudity: zero tolerance. POSSIBLE is enough to hold it back.
        if (atLeast(safe.adult, 'POSSIBLE'))
            reasons.push('adult');
        // Racy at POSSIBLE fires on ordinary beach and gym photos, so the bar
        // here is LIKELY. Tune in one place if it proves too loose or too tight.
        if (atLeast(safe.racy, 'LIKELY'))
            reasons.push('racy');
        if (atLeast(safe.violence, 'LIKELY'))
            reasons.push('violence');
        if (requireFace && faces.length === 0)
            reasons.push('no_face');
        const approved = reasons.length === 0;
        if (!approved) {
            // MOVE to quarantine rather than delete - a false positive must be
            // recoverable, and an admin needs to see what was rejected.
            try {
                await bucket.file(objectPath).copy(bucket.file(`quarantine/${objectPath}`));
                await bucket.file(objectPath).delete();
            }
            catch (e) {
                (0, utils_1.logError)(`[moderate] quarantine move failed for ${objectPath}`, e);
            }
            await db.collection('moderation_queue').add({
                type: 'image',
                userId,
                objectPath,
                quarantinePath: `quarantine/${objectPath}`,
                reasons,
                safeSearch: {
                    adult: safe.adult || null,
                    racy: safe.racy || null,
                    violence: safe.violence || null,
                    medical: safe.medical || null,
                    spoof: safe.spoof || null,
                },
                labels,
                status: 'pending_review',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
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
        (0, utils_1.logInfo)(`[moderate] ${approved ? 'APPROVED' : 'REJECTED'} ${objectPath}` +
            (approved ? '' : ` reasons=${reasons.join(',')}`));
    }
    catch (e) {
        // FAIL CLOSED on the verdict the client waits for. If Vision is down or
        // the API is disabled we must not hand back "approved" - that is exactly
        // how an unchecked image reaches a profile. The file is left in place so
        // an admin can resolve it; the uploader is told the check failed.
        (0, utils_1.logError)(`[moderate] verification error for ${objectPath}`, e);
        await docRef.set({
            status: 'error',
            userId,
            objectPath,
            reasons: ['verification_failed'],
            checkedAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 24 * 3600 * 1000),
        }, { merge: true });
    }
});
//# sourceMappingURL=moderateUploadedImage.js.map