/**
 * ID-document retention — Storage/Firestore side. Policy + pure decisions in
 * idDocumentRetentionLogic.ts.
 *
 * P2-6 (owner decision): the image is DELETED once a decision is made; an
 * undecided image is kept at most 7 days. See idDocumentRetentionLogic.ts.
 *
 * Server-only data (rules: no client access at all):
 *   Storage  id_documents/{uid}/{ts}.jpg   the document AWAITING a decision
 *   Storage  retention/{uid}/{ts}.jpg      legacy (pre-P2-6) retained copies
 *   Firestore id_documents/{uid}           pending: { currentPath, uploadedAt,
 *                                             status:'pending', documentType,
 *                                             purgeImageAfter, consentMissing? }
 *                                           decided: { ageVerified, method,
 *                                             decidedAt, birthYear, imageDeleted }
 *   Firestore id_document_retention/{id}   { uid, storagePaths[], verificationStatus,
 *                                             reason: 'replaced'|'account-deleted',
 *                                             retainedAt, purgeAfter, legalHold }
 *
 * Exported functions:
 *   purgeRetainedIdDocuments  daily schedule, erases due entries (paginated)
 *   setIdDocumentLegalHold    admin callable, sets/clears a hold
 *   backfillIdVerifiedFlags   admin callable, repairs profiles.isAgeVerified
 */
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { requireAdmin, SUPER_ADMIN_ONLY } from '../shared/adminAuth';
import { db, logInfo, logError, logWarning } from '../shared/utils';
import {
  RetentionEntry,
  entryPaths,
  idVerifiedFlagFor,
  idVerifiedFlagNeedsRepair,
  pendingPurgeAfterMs,
  planPurgePage,
} from './idDocumentRetentionLogic';

export const ID_DOCUMENTS = 'id_documents';
export const ID_DOCUMENT_RETENTION = 'id_document_retention';

const Timestamp = admin.firestore.Timestamp;

function tsMs(v: unknown): number | null {
  if (v instanceof admin.firestore.Timestamp) return v.toMillis();
  if (typeof v === 'number' && Number.isFinite(v)) return v;
  return null;
}

function toEntry(d: admin.firestore.DocumentSnapshot): RetentionEntry {
  const x = d.data() ?? {};
  return {
    id: d.id,
    uid: typeof x.uid === 'string' ? x.uid : undefined,
    storagePaths: x.storagePaths,
    purgeAfterMs: tsMs(x.purgeAfter),
    legalHold: x.legalHold,
  };
}

async function deleteObjectIfExists(path: string): Promise<boolean> {
  try {
    await admin.storage().bucket().file(path).delete({ ignoreNotFound: true });
    return true;
  } catch (e) {
    logError(`idDocumentRetention: delete ${path} failed`, e);
    return false;
  }
}

// ─────────────────────────────────────────────────────── live documents

/**
 * Moves a freshly submitted document (`age_verification/{uid}/…`, the
 * client's write-only upload prefix) to the server-only `id_documents/{uid}/`
 * prefix and makes it the account's current (undecided) document. A previous
 * undecided document is DELETED (P2-6: no retention of replaced images).
 * Returns the new path, or null if the move failed (caller then deletes the
 * upload — never leave it behind).
 */
export async function retainSubmittedDocument(
  uid: string,
  uploadPath: string,
  documentType: string,
  opts: { consentMissing?: boolean } = {},
): Promise<string | null> {
  const bucket = admin.storage().bucket();
  const name = uploadPath.split('/').pop() || `${Date.now()}.jpg`;
  const livePath = `${ID_DOCUMENTS}/${uid}/${Date.now()}_${name}`;
  try {
    await bucket.file(uploadPath).move(livePath);
  } catch (e) {
    logError(`retainSubmittedDocument: move ${uploadPath} failed`, e);
    return null;
  }
  const indexRef = db.collection(ID_DOCUMENTS).doc(uid);
  let prevPath: string | null = null;
  try {
    await db.runTransaction(async (tx) => {
      const prev = await tx.get(indexRef);
      const p = prev.data()?.currentPath;
      prevPath = typeof p === 'string' && p && p !== livePath ? p : null;
      const now = Timestamp.now();
      tx.set(indexRef, {
        currentPath: livePath,
        uploadedAt: now,
        status: 'pending',
        documentType,
        updatedAt: now,
        // P2-6: the image is purged after 7 days if nobody decided by then.
        purgeImageAfter: Timestamp.fromMillis(pendingPurgeAfterMs(now.toMillis())),
        ...(opts.consentMissing ? { consentMissing: true } : {}),
      });
    });
  } catch (e) {
    // The object is under the server-only prefix either way; the decision,
    // the daily sweep and the account-deletion hook all list the prefix.
    logError(`retainSubmittedDocument: index update failed for ${uid}`, e);
  }
  if (prevPath) await deleteObjectIfExists(prevPath);
  return livePath;
}

/** Mirrors the verification decision onto the document index. */
export async function setIdDocumentStatus(uid: string, status: string): Promise<void> {
  try {
    await db.collection(ID_DOCUMENTS).doc(uid).set(
      { status, updatedAt: Timestamp.now() },
      { merge: true },
    );
  } catch (e) {
    logError(`setIdDocumentStatus: ${uid} failed`, e);
  }
}

/**
 * Deletes every stored image of [uid]: the live prefix `id_documents/{uid}/`
 * and every legacy retention entry that is NOT under a legal hold (objects
 * first, then the entry). Returns how many objects were deleted, how many
 * entries were kept because of a hold, and how many deletes failed.
 */
export async function deleteAllIdDocumentImages(
  uid: string,
  extraPaths: string[] = [],
): Promise<{ deleted: number; held: number; failed: number }> {
  let deleted = 0;
  let failed = 0;
  let held = 0;
  const bucket = admin.storage().bucket();
  const paths = new Set<string>(extraPaths.filter((p) => typeof p === 'string' && p));
  try {
    const [files] = await bucket.getFiles({ prefix: `${ID_DOCUMENTS}/${uid}/` });
    for (const f of files) paths.add(f.name);
  } catch (e) {
    logError(`deleteAllIdDocumentImages: list ${uid} failed`, e);
    failed++;
  }
  for (const p of paths) {
    if (await deleteObjectIfExists(p)) deleted++;
    else failed++;
  }
  const entries = await db.collection(ID_DOCUMENT_RETENTION).where('uid', '==', uid).limit(100).get();
  for (const d of entries.docs) {
    if (d.data()?.legalHold === true) {
      held++;
      continue;
    }
    const ps = entryPaths(toEntry(d));
    const ok = await Promise.all(ps.map(deleteObjectIfExists));
    deleted += ok.filter(Boolean).length;
    if (ok.every(Boolean)) await d.ref.delete();
    else failed++;
  }
  return { deleted, held, failed };
}

/**
 * P2-6: a verification DECISION was made (automatic or by an admin, approve or
 * reject). Delete the image and any retention copy, and keep only the minimal
 * record { ageVerified, method, decidedAt, birthYear } (+ the audit flag
 * consentMissing when the upload came from an app without the consent sheet).
 */
export async function finalizeIdDocumentDecision(
  uid: string,
  decision: { verified: boolean; method: string; birthYear: number | null },
  extraPaths: string[] = [],
): Promise<{ deleted: number; held: number; failed: number }> {
  const indexRef = db.collection(ID_DOCUMENTS).doc(uid);
  const prev = (await indexRef.get()).data() ?? {};
  const cur = typeof prev.currentPath === 'string' && prev.currentPath ? [prev.currentPath] : [];
  const res = await deleteAllIdDocumentImages(uid, [...cur, ...extraPaths]);
  await indexRef.set({
    ageVerified: decision.verified,
    method: decision.method,
    decidedAt: Timestamp.now(),
    birthYear: decision.birthYear,
    imageDeleted: res.failed === 0,
    ...(prev.consentMissing === true ? { consentMissing: true } : {}),
    // Kept ONLY while a delete failed, so the daily sweep retries it.
    ...(res.failed > 0 && cur.length ? { currentPath: cur[0], status: 'decided' } : {}),
  });
  if (res.failed > 0) logError(`finalizeIdDocumentDecision: ${res.failed} delete(s) failed for ${uid}; the sweep retries`);
  if (res.held > 0) logWarning(`finalizeIdDocumentDecision: ${res.held} entries of ${uid} kept under legal hold`);
  return res;
}

/**
 * P2-6: an image waited longer than PENDING_REVIEW_DAYS for a human decision.
 * Delete it; the user has to upload again ('rejected' / 'reuploadRequired').
 */
export async function expireUndecidedDocument(uid: string): Promise<void> {
  const indexRef = db.collection(ID_DOCUMENTS).doc(uid);
  const prev = (await indexRef.get()).data() ?? {};
  const cur = typeof prev.currentPath === 'string' && prev.currentPath ? [prev.currentPath] : [];
  const res = await deleteAllIdDocumentImages(uid, cur);
  const now = Timestamp.now();
  await indexRef.set({
    ageVerified: false,
    method: 'document',
    decidedAt: null,
    birthYear: null,
    status: 'expired',
    expiredAt: now,
    imageDeleted: res.failed === 0,
    ...(prev.consentMissing === true ? { consentMissing: true } : {}),
    ...(res.failed > 0 && cur.length ? { currentPath: cur[0], purgeImageAfter: now } : {}),
  });
  const queueRef = db.collection('age_verification_queue').doc(uid);
  const queue = await queueRef.get();
  if (queue.exists && queue.data()?.status === 'pending') {
    await queueRef.set({
      status: 'expired',
      expiredAt: now,
      documentDateOfBirth: admin.firestore.FieldValue.delete(),
      reason: 'reviewExpired',
    }, { merge: true });
  }
  const profileRef = db.collection('profiles').doc(uid);
  const profile = await profileRef.get();
  if (profile.exists && profile.data()?.ageVerification?.status === 'pending') {
    await profileRef.set({
      ageVerification: {
        status: 'rejected',
        rejectionReason: 'reuploadRequired',
        reviewedBy: 'system',
        updatedAt: now,
      },
      isAgeVerified: false,
    }, { merge: true });
  }
}

// ─────────────────────────────────────────────────────── account deletion

/**
 * Account deleted: P2-6 — every image of the user is DELETED (no 30-day
 * retention any more), except legacy entries under an admin legal hold; the
 * live index doc is removed. Idempotent: both the Auth-delete and the
 * profile-delete cascades call it. Returns the number of objects deleted.
 * (Name kept for the existing callers.)
 */
export async function retainIdDocumentsOnAccountDeletion(uid: string): Promise<number> {
  if (!uid) return 0;
  const res = await deleteAllIdDocumentImages(uid);
  await db.collection(ID_DOCUMENTS).doc(uid).delete().catch(() => undefined);
  logInfo(`idDocuments on account deletion: ${uid} — ${res.deleted} deleted, ${res.held} on legal hold, ${res.failed} failed`);
  return res.deleted;
}

// ─────────────────────────────────────────────────────── purge

const PURGE_PAGE = 200;
const PURGE_MAX_PAGES = 25;

async function birthYearFromPrivateProfile(uid: string): Promise<number | null> {
  try {
    const v = (await db.collection('profiles_private').doc(uid).get()).data()?.ageVerification;
    if (typeof v?.documentBirthYear === 'number') return v.documentBirthYear;
    const ts = v?.documentDateOfBirth;
    return ts instanceof admin.firestore.Timestamp ? ts.toDate().getUTCFullYear() : null;
  } catch {
    return null;
  }
}

/**
 * The daily sweep (exported for tests):
 *  1. undecided images older than 7 days -> deleted, user must re-upload;
 *  2. legacy index docs that still point at an image although a decision was
 *     made (pre-P2-6, or a failed delete) -> image deleted, record minimised;
 *  3. legacy retention entries -> deleted now (unless under legal hold).
 */
export async function runIdDocumentPurge(nowMs: number = Date.now()): Promise<Record<string, number>> {
  const stats = { expired: 0, legacyDecided: 0, retentionPurged: 0, held: 0, objects: 0, failures: 0 };

  // 1. Expired pending reviews. Processed docs lose purgeImageAfter (or get a
  //    fresh one on a failed delete), so re-reading page 1 always progresses.
  for (let i = 0; i < PURGE_MAX_PAGES; i++) {
    const page = await db.collection(ID_DOCUMENTS)
      .where('purgeImageAfter', '<=', Timestamp.fromMillis(nowMs))
      .orderBy('purgeImageAfter')
      .limit(PURGE_PAGE)
      .get();
    let failedHere = 0;
    for (const d of page.docs) {
      try {
        const st = d.data()?.status;
        if (st === 'verified' || st === 'rejected' || st === 'decided') {
          await finalizeIdDocumentDecision(d.id, {
            verified: st === 'verified', method: 'document', birthYear: await birthYearFromPrivateProfile(d.id),
          });
          stats.legacyDecided++;
        } else {
          await expireUndecidedDocument(d.id);
          stats.expired++;
        }
      } catch (e) {
        failedHere++;
        logError(`runIdDocumentPurge: expiring ${d.id} failed`, e);
      }
    }
    stats.failures += failedHere;
    if (page.size < PURGE_PAGE || failedHere > 0) break;
  }

  // 2. Legacy docs that still reference an image.
  let cursor: admin.firestore.DocumentSnapshot | null = null;
  for (let i = 0; i < PURGE_MAX_PAGES; i++) {
    let q = db.collection(ID_DOCUMENTS).where('currentPath', '>', '').orderBy('currentPath').limit(PURGE_PAGE);
    if (cursor) q = q.startAfter(cursor);
    const page = await q.get();
    for (const d of page.docs) {
      const x = d.data() ?? {};
      try {
        if (x.status === 'pending') {
          if (!x.purgeImageAfter) {
            const up = tsMs(x.uploadedAt) ?? nowMs;
            await d.ref.set({ purgeImageAfter: Timestamp.fromMillis(pendingPurgeAfterMs(up)) }, { merge: true });
          }
          continue;
        }
        if (x.status === 'expired') {
          await expireUndecidedDocument(d.id);
          continue;
        }
        await finalizeIdDocumentDecision(d.id, {
          verified: x.status === 'verified' || x.ageVerified === true,
          method: typeof x.method === 'string' ? x.method : 'document',
          birthYear: typeof x.birthYear === 'number' ? x.birthYear : await birthYearFromPrivateProfile(d.id),
        });
        stats.legacyDecided++;
      } catch (e) {
        stats.failures++;
        logError(`runIdDocumentPurge: legacy ${d.id} failed`, e);
      }
    }
    if (page.size < PURGE_PAGE) break;
    cursor = page.docs[page.docs.length - 1];
  }

  // 3. Legacy retention entries: no waiting period any more (P2-6).
  let rCursor: admin.firestore.DocumentSnapshot | null = null;
  for (let i = 0; i < PURGE_MAX_PAGES; i++) {
    let q = db.collection(ID_DOCUMENT_RETENTION).orderBy('purgeAfter').limit(PURGE_PAGE);
    if (rCursor) q = q.startAfter(rCursor);
    const page = await q.get();
    const plan = planPurgePage(page.docs.map(toEntry), Number.MAX_SAFE_INTEGER, PURGE_PAGE);
    stats.held += plan.held;
    for (const e of plan.due) {
      const paths = entryPaths(e);
      const results = await Promise.all(paths.map(deleteObjectIfExists));
      if (results.every(Boolean)) {
        stats.objects += paths.length;
        await db.collection(ID_DOCUMENT_RETENTION).doc(e.id).delete();
        stats.retentionPurged++;
      } else {
        stats.failures++; // retried tomorrow (idempotent: missing objects are fine)
      }
    }
    if (plan.done || page.empty) break;
    rCursor = page.docs[page.docs.length - 1];
    if (i === PURGE_MAX_PAGES - 1) logWarning('purgeRetainedIdDocuments: page cap reached, continuing tomorrow');
  }
  logInfo(`purgeRetainedIdDocuments: ${JSON.stringify(stats)}`);
  return stats;
}

export const purgeRetainedIdDocuments = onSchedule(
  { schedule: '30 3 * * *', timeZone: 'UTC', memory: '512MiB', timeoutSeconds: 540 },
  async () => {
    await runIdDocumentPurge(Date.now());
  },
);

// ─────────────────────────────────────────────────────── admin callables

// P1-6: ID-document retention controls are superAdmin-only (was users.isAdmin).
async function requireIdDocAdmin(auth: { uid?: string; token?: any } | undefined): Promise<string> {
  return (await requireAdmin(auth, SUPER_ADMIN_ONLY)).uid;
}

/**
 * Places / lifts a legal hold (e.g. an open scam report) on one retention
 * entry ({retentionId}) or on every entry of a user ({uid}). Held entries are
 * never purged until the hold is lifted.
 */
export const setIdDocumentLegalHold = onCall<{ retentionId?: string; uid?: string; hold?: boolean; note?: string }>(
  { memory: '512MiB', timeoutSeconds: 60 },
  async (request) => {
    const adminUid = await requireIdDocAdmin(request.auth);
    const hold = request.data?.hold === true;
    const patch = {
      legalHold: hold,
      legalHoldBy: adminUid,
      legalHoldAt: Timestamp.now(),
      legalHoldNote: typeof request.data?.note === 'string' ? request.data.note.slice(0, 500) : null,
    };
    const rid = request.data?.retentionId;
    if (typeof rid === 'string' && rid) {
      const ref = db.collection(ID_DOCUMENT_RETENTION).doc(rid);
      if (!(await ref.get()).exists) throw new HttpsError('not-found', 'No such retention entry.');
      await ref.update(patch);
      return { updated: 1 };
    }
    const uid = request.data?.uid;
    if (typeof uid !== 'string' || !uid) {
      throw new HttpsError('invalid-argument', 'retentionId or uid is required.');
    }
    const snap = await db.collection(ID_DOCUMENT_RETENTION).where('uid', '==', uid).limit(100).get();
    const batch = db.batch();
    snap.docs.forEach((d) => batch.update(d.ref, patch));
    if (!snap.empty) await batch.commit();
    logInfo(`setIdDocumentLegalHold: ${adminUid} hold=${hold} uid=${uid} (${snap.size})`);
    return { updated: snap.size };
  },
);

/**
 * Admin-only, resumable: repairs `profiles.isAgeVerified` (THE "ID verified"
 * badge flag) from `ageVerification.status`. writeStatus() always writes both,
 * so this is a safety net. Call with the returned `cursor` until `done`.
 */
export const backfillIdVerifiedFlags = onCall<{ cursor?: string; pageSize?: number }>(
  { memory: '512MiB', timeoutSeconds: 540 },
  async (request) => {
    await requireIdDocAdmin(request.auth);
    const pageSize = Math.min(Math.max(Number(request.data?.pageSize) || 300, 1), 500);
    let q = db.collection('profiles')
      .orderBy(admin.firestore.FieldPath.documentId())
      .select('ageVerification', 'isAgeVerified')
      .limit(pageSize);
    if (typeof request.data?.cursor === 'string' && request.data.cursor) {
      q = q.startAfter(request.data.cursor);
    }
    const page = await q.get();
    let repaired = 0;
    let batch = db.batch();
    let ops = 0;
    for (const d of page.docs) {
      const data = d.data();
      if (!idVerifiedFlagNeedsRepair(data)) continue;
      batch.update(d.ref, { isAgeVerified: idVerifiedFlagFor(data.ageVerification) });
      repaired++;
      if (++ops >= 400) {
        await batch.commit();
        batch = db.batch();
        ops = 0;
      }
    }
    if (ops > 0) await batch.commit();
    const last = page.docs[page.docs.length - 1];
    return { scanned: page.size, repaired, cursor: last ? last.id : null, done: page.size < pageSize };
  },
);
