/**
 * Owner rule: a PERSONAL account's main public photo (`profiles/{uid}.photoUrls[0]`)
 * must show a face. Business accounts (`isBusiness === true`) may use a logo.
 * Nudity / explicit checks are separate and apply to every image regardless
 * (moderateUploadedImage).
 *
 * WHY THE SERVER DECIDES
 * ----------------------
 * The upload-time face check used to run only when the upload's custom
 * metadata said `requireFace=true` - metadata the CLIENT sets. A modified
 * client (or a direct API call) could upload with `requireFace=false`, or
 * simply reorder an existing faceless photo into slot 0. The flag is still
 * honoured for the upload UX (an immediate `no_face` rejection), but the
 * decision now happens here, at the point that matters: whenever the public
 * profile's main photo changes.
 *
 * DATA
 * ----
 * moderateUploadedImage runs FACE_DETECTION on every public upload under
 * `profiles/{uid}/photos/` (same Vision call, one extra feature) and records
 * `faces: n` / `hasFace: bool` on the verdict it already writes to
 * `image_moderation/{objectPath with '/' -> '~'}`. Those verdicts are
 * short-lived (24h TTL), so for a photo whose verdict has expired (a reorder
 * days later, or a pre-existing photo) the face status is computed on demand
 * with one FACE_DETECTION call and cached back on the verdict doc.
 *
 * ENFORCEMENT (two entry points, so both orders of the race are covered)
 * -----------------------------------------------------------------------
 *  1. enforceOnProfileWrite - called from mirrorPrivateProfileFields (the
 *     existing profiles/{uid} trigger). It returns after an in-memory compare
 *     unless photoUrls[0] changed, so ordinary profile writes (presence,
 *     counters) cost nothing extra.
 *  2. enforceAfterVerdict - called by moderateUploadedImage right after it
 *     writes a verdict with hasFace=false (or a rejection) for a
 *     `profiles/{uid}/photos/` object. Covers a client that writes the URL
 *     into photoUrls[0] BEFORE moderation finished (at that moment the
 *     profile trigger found no verdict and the object may not even exist yet,
 *     so it could not decide) and overwrites of an already-approved object.
 *
 * CORRECTION
 * ----------
 * The faceless main photo is not deleted. A photo KNOWN to show a face is
 * moved to slot 0: the previous main photo if it is still in the list, else
 * the first other photo with a face. The write is a transaction that only
 * applies while photoUrls[0] is still the faceless URL and the account is
 * still personal, so a concurrent user edit is never clobbered. If no photo
 * with a face exists, photoUrls is left untouched (we never empty a profile)
 * and the user is told to add one.
 * The owner gets one in-app notice per faceless photo (deterministic id, so
 * retries and both entry points never duplicate it).
 *
 * NO LOOP
 * -------
 * The correction only ever puts a photo whose status is KNOWN 'face' in slot
 * 0. The trigger fired by that write sees photoUrls[0] == that photo, resolves
 * 'face', and stops. The "no candidate" branch writes no profile field at all.
 *
 * WHAT IS LEFT ALONE
 * ------------------
 *  - business accounts (isBusiness can only be turned ON by the owner while
 *    holding an active Silver+ tier - firestore rules - and never off, so the
 *    stored flag is trustworthy; a lapsed business keeps its logo);
 *  - URLs that are not objects in the default bucket under `profiles/`
 *    (status 'unknown');
 *  - photos whose face status cannot be determined right now (object not
 *    uploaded yet, Vision error): entry point 2 decides once the verdict lands.
 */

import * as admin from 'firebase-admin';
import vision from '@google-cloud/vision';
import { logError, logInfo } from '../shared/utils';
import { lt, notifTextFields } from '../shared/i18n';

export type FaceStatus = 'face' | 'no_face' | 'unknown';

/** Firestore doc id of an object's moderation verdict. Same as moderationDocId. */
export function verdictDocId(objectPath: string): string {
  return objectPath.replace(/\//g, '~');
}

/** Public profile photo object: `profiles/{uid}/photos/<file>`. */
export const PROFILE_PHOTO_PATH = /^profiles\/([^/]+)\/photos\/[^/]+$/;

/** Owner uid of a profile photo object path, or null. Pure. */
export function profilePhotoOwner(objectPath: string): string | null {
  const m = PROFILE_PHOTO_PATH.exec(objectPath);
  return m ? m[1] : null;
}

/**
 * Storage object behind a photo URL, or null when the URL does not point into
 * a Firebase Storage bucket. Understands Firebase download URLs
 * (`https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<encoded path>?...`),
 * `https://storage.googleapis.com/<bucket>/<path>` and `gs://<bucket>/<path>`. Pure.
 */
export function storageObjectFromUrl(url: unknown): { bucket: string; path: string } | null {
  if (typeof url !== 'string' || url.length === 0) return null;
  try {
    if (url.startsWith('gs://')) {
      const rest = url.slice(5);
      const i = rest.indexOf('/');
      if (i <= 0) return null;
      return { bucket: rest.slice(0, i), path: rest.slice(i + 1) };
    }
    const u = new URL(url);
    if (u.hostname === 'firebasestorage.googleapis.com') {
      const m = /^\/v0\/b\/([^/]+)\/o\/(.+)$/.exec(u.pathname);
      if (!m) return null;
      return { bucket: decodeURIComponent(m[1]), path: decodeURIComponent(m[2]) };
    }
    if (u.hostname === 'storage.googleapis.com') {
      const m = /^\/([^/]+)\/(.+)$/.exec(u.pathname);
      if (!m) return null;
      return { bucket: decodeURIComponent(m[1]), path: decodeURIComponent(m[2]) };
    }
  } catch {
    return null;
  }
  return null;
}

/** Face status recorded on a moderation verdict doc. Pure. */
export function faceStatusFromVerdict(v: Record<string, any> | null | undefined): FaceStatus {
  if (!v) return 'unknown';
  // A moderator restored the photo (false-positive no_face / SafeSearch): a
  // human decision outranks the detector.
  if (v.moderatorApproved === true && v.status === 'approved') return 'face';
  // Quarantined: not displayable at all, never acceptable as the main photo.
  if (v.status === 'rejected') return 'no_face';
  if (v.hasFace === true) return 'face';
  if (v.hasFace === false) return 'no_face';
  if (typeof v.faces === 'number') return v.faces > 0 ? 'face' : 'no_face';
  return 'unknown';
}

/** Exempt from the face rule: a business account may use a logo. Pure. */
export function isFaceRuleExempt(profile: Record<string, any> | null | undefined): boolean {
  return profile?.isBusiness === true;
}

function mainOf(profile: Record<string, any> | null | undefined): string | null {
  const arr = profile?.photoUrls;
  return Array.isArray(arr) && typeof arr[0] === 'string' ? arr[0] : null;
}

/** True when photoUrls[0] differs between the two snapshots. Pure. */
export function mainPhotoChanged(
  before: Record<string, any> | undefined,
  after: Record<string, any> | undefined,
): boolean {
  return mainOf(before) !== mainOf(after);
}

export type CorrectionPlan =
  | { action: 'none' }
  | { action: 'reorder'; faceless: string; replacement: string }
  | { action: 'notify'; faceless: string };

/**
 * What to do about photoUrls whose slot 0 may be faceless. Statuses are
 * resolved lazily (an unknown URL may cost a Vision call), in order, stopping
 * at the first usable replacement.
 */
export async function planMainPhotoCorrection(
  photoUrls: string[],
  previousMain: string | null,
  statusOf: (url: string) => Promise<FaceStatus>,
): Promise<CorrectionPlan> {
  const main = photoUrls[0];
  if (typeof main !== 'string') return { action: 'none' };
  if ((await statusOf(main)) !== 'no_face') return { action: 'none' };
  const candidates: string[] = [];
  if (previousMain && previousMain !== main && photoUrls.includes(previousMain)) {
    candidates.push(previousMain);
  }
  for (const u of photoUrls.slice(1)) {
    if (typeof u === 'string' && u !== main && !candidates.includes(u)) candidates.push(u);
  }
  for (const c of candidates) {
    if ((await statusOf(c)) === 'face') return { action: 'reorder', faceless: main, replacement: c };
  }
  return { action: 'notify', faceless: main };
}

/**
 * photoUrls after moving [replacement] to the front, or null when the stored
 * profile no longer matches the plan (concurrent edit / now business). Pure.
 */
export function applyReorder(
  current: Record<string, any> | null | undefined,
  plan: { faceless: string; replacement: string },
): string[] | null {
  if (!current || isFaceRuleExempt(current)) return null;
  const arr = current.photoUrls;
  if (!Array.isArray(arr) || arr[0] !== plan.faceless || !arr.includes(plan.replacement)) return null;
  return [plan.replacement, ...arr.filter((u: unknown) => u !== plan.replacement)];
}

/** Deterministic notice id: one per user + faceless photo. Pure. */
export function faceNoticeId(uid: string, facelessUrl: string): string {
  const obj = storageObjectFromUrl(facelessUrl);
  const key = obj ? verdictDocId(obj.path) : facelessUrl.replace(/[^A-Za-z0-9_-]/g, '_');
  return `mainphoto_face__${uid}__${key}`.slice(0, 1400);
}

// ─────────────────────────────────────────────────────────────── ports

export interface FaceRulePorts {
  defaultBucket(): string;
  readVerdict(docId: string): Promise<Record<string, any> | null>;
  /** Number of faces in the object; throws when it cannot be read. */
  detectFaces(bucket: string, path: string): Promise<number>;
  saveFaceResult(docId: string, data: Record<string, any>): Promise<void>;
  readProfile(uid: string): Promise<Record<string, any> | null>;
  /** Transaction: read the profile, write photoUrls = mutate(profile) unless null. */
  updatePhotoUrls(
    uid: string,
    mutate: (profile: Record<string, any> | null) => string[] | null,
  ): Promise<boolean>;
  /** Create the notice; must be a no-op when [id] already exists. */
  notify(uid: string, id: string, kind: 'moved' | 'needed'): Promise<void>;
}

/** Face status of one photo URL: verdict first, else one on-demand Vision call. */
export function makeStatusResolver(uid: string, ports: FaceRulePorts) {
  const cache = new Map<string, FaceStatus>();
  return async (url: string): Promise<FaceStatus> => {
    const hit = cache.get(url);
    if (hit) return hit;
    let status: FaceStatus = 'unknown';
    const obj = storageObjectFromUrl(url);
    if (obj && obj.bucket === ports.defaultBucket() && obj.path.startsWith('profiles/')) {
      const docId = verdictDocId(obj.path);
      try {
        status = faceStatusFromVerdict(await ports.readVerdict(docId));
      } catch (e) {
        logError(`[faceRule] verdict read failed for ${obj.path}`, e);
      }
      if (status === 'unknown') {
        try {
          const faces = await ports.detectFaces(obj.bucket, obj.path);
          status = faces > 0 ? 'face' : 'no_face';
          await ports.saveFaceResult(docId, {
            objectPath: obj.path,
            userId: profilePhotoOwner(obj.path) ?? uid,
            faces,
            hasFace: faces > 0,
          });
        } catch (e) {
          // Not uploaded yet / Vision down: undecidable now. If it is a fresh
          // upload, enforceAfterVerdict decides once the verdict is written.
          logInfo(`[faceRule] face status unknown for ${obj.path}: ${(e as Error)?.message ?? e}`);
          status = 'unknown';
        }
      }
    }
    cache.set(url, status);
    return status;
  };
}

export type EnforceResult = 'skipped' | 'ok' | 'reordered' | 'notified' | 'stale';

async function execute(uid: string, plan: CorrectionPlan, ports: FaceRulePorts): Promise<EnforceResult> {
  if (plan.action === 'none') return 'ok';
  if (plan.action === 'reorder') {
    const wrote = await ports.updatePhotoUrls(uid, (p) => applyReorder(p, plan));
    if (!wrote) return 'stale';
    await ports.notify(uid, faceNoticeId(uid, plan.faceless), 'moved');
    logInfo(`[faceRule] ${uid}: faceless main photo moved out of slot 0`);
    return 'reordered';
  }
  await ports.notify(uid, faceNoticeId(uid, plan.faceless), 'needed');
  logInfo(`[faceRule] ${uid}: faceless main photo, no photo with a face to promote`);
  return 'notified';
}

/** Entry point 1: profiles/{uid} written (mirrorPrivateProfileFields). */
export async function enforceOnProfileWrite(
  uid: string,
  before: Record<string, any> | undefined,
  after: Record<string, any> | undefined,
  ports: FaceRulePorts,
): Promise<EnforceResult> {
  // In-memory filter first: almost every profile write stops here.
  if (!after || !mainPhotoChanged(before, after)) return 'skipped';
  if (isFaceRuleExempt(after)) return 'skipped';
  const photoUrls = (after.photoUrls as unknown[]).filter((u): u is string => typeof u === 'string');
  const plan = await planMainPhotoCorrection(photoUrls, mainOf(before), makeStatusResolver(uid, ports));
  return execute(uid, plan, ports);
}

/**
 * Entry point 2: moderateUploadedImage has just written [verdict] for
 * [objectPath]. Acts only when that object is the CURRENT main photo of a
 * personal profile and the verdict says it has no face.
 */
export async function enforceAfterVerdict(
  objectPath: string,
  verdict: Record<string, any>,
  ports: FaceRulePorts,
): Promise<EnforceResult> {
  const uid = profilePhotoOwner(objectPath);
  if (!uid || faceStatusFromVerdict(verdict) !== 'no_face') return 'skipped';
  const profile = await ports.readProfile(uid);
  if (!profile || isFaceRuleExempt(profile)) return 'skipped';
  const main = mainOf(profile);
  const obj = main ? storageObjectFromUrl(main) : null;
  if (!obj || obj.path !== objectPath || obj.bucket !== ports.defaultBucket()) return 'skipped';
  const photoUrls = (profile.photoUrls as unknown[]).filter((u): u is string => typeof u === 'string');
  const resolve = makeStatusResolver(uid, ports);
  // The verdict just written is authoritative for this object.
  const statusOf = (u: string) => (u === main ? Promise.resolve<FaceStatus>('no_face') : resolve(u));
  const plan = await planMainPhotoCorrection(photoUrls, null, statusOf);
  return execute(uid, plan, ports);
}

// ───────────────────────────────────────────────────── production ports

let visionClient: InstanceType<typeof vision.ImageAnnotatorClient> | null = null;

/** Firestore / Storage / Vision ports (lazy: built on first use). */
export function firestoreFaceRulePorts(): FaceRulePorts {
  const db = admin.firestore();
  return {
    defaultBucket: () => admin.storage().bucket().name,
    readVerdict: async (docId) => {
      const s = await db.collection('image_moderation').doc(docId).get();
      return s.exists ? (s.data() as Record<string, any>) : null;
    },
    detectFaces: async (bucket, path) => {
      visionClient ??= new vision.ImageAnnotatorClient();
      const [res] = await visionClient.annotateImage({
        image: { source: { imageUri: `gs://${bucket}/${path}` } },
        features: [{ type: 'FACE_DETECTION', maxResults: 5 }],
      });
      if (res.error?.message) throw new Error(res.error.message);
      return (res.faceAnnotations || []).length;
    },
    saveFaceResult: async (docId, data) => {
      await db.collection('image_moderation').doc(docId).set({
        ...data,
        faceCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 24 * 3600 * 1000),
      }, { merge: true });
    },
    readProfile: async (uid) => {
      const s = await db.collection('profiles').doc(uid).get();
      return s.exists ? (s.data() as Record<string, any>) : null;
    },
    updatePhotoUrls: (uid, mutate) => db.runTransaction(async (tx) => {
      const ref = db.collection('profiles').doc(uid);
      const s = await tx.get(ref);
      const next = mutate(s.exists ? (s.data() as Record<string, any>) : null);
      if (!next) return false;
      tx.update(ref, { photoUrls: next });
      return true;
    }),
    notify: async (uid, id, kind) => {
      try {
        await db.collection('notifications').doc(id).create({
          userId: uid,
          type: 'system',
          ...notifTextFields(
            lt('srvMainPhotoFaceTitle'),
            lt(kind === 'moved' ? 'srvMainPhotoFaceMovedBody' : 'srvMainPhotoFaceNeededBody'),
          ),
          data: { kind: 'main_photo_face_required' },
          read: false,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (e: any) {
        if (e?.code === 6 || /already exists/i.test(String(e?.message))) return;
        throw e;
      }
    },
  };
}
