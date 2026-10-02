/**
 * ID-document retention — Storage/Firestore side. Policy + pure decisions in
 * idDocumentRetentionLogic.ts (DRAFT — lawyer review).
 *
 * Server-only data (rules: no client access at all):
 *   Storage  id_documents/{uid}/{ts}.jpg   documents of a LIVE account
 *   Storage  retention/{uid}/{ts}.jpg      documents of a DELETED account
 *   Firestore id_documents/{uid}           { currentPath, uploadedAt, status,
 *                                             documentType, updatedAt }
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
import { db, logInfo, logError, logWarning } from '../shared/utils';
import {
  RetentionEntry,
  entryPaths,
  idVerifiedFlagFor,
  idVerifiedFlagNeedsRepair,
  mergeAccountRetention,
  planPurgePage,
  purgeAfterMs,
  retentionPathFor,
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
 * prefix, makes it the account's current document and sends the previous one
 * (if any) to retention for 30 days. Returns the new path, or null if the
 * move failed (caller then deletes the upload — never leave it behind).
 */
export async function retainSubmittedDocument(
  uid: string,
  uploadPath: string,
  documentType: string,
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
  try {
    await db.runTransaction(async (tx) => {
      const prev = await tx.get(indexRef);
      const prevPath = prev.data()?.currentPath;
      const now = Timestamp.now();
      if (typeof prevPath === 'string' && prevPath && prevPath !== livePath) {
        tx.set(db.collection(ID_DOCUMENT_RETENTION).doc(), {
          uid,
          storagePaths: [prevPath],
          verificationStatus: prev.data()?.status ?? null,
          reason: 'replaced',
          retainedAt: now,
          purgeAfter: Timestamp.fromMillis(purgeAfterMs(now.toMillis())),
          legalHold: false,
        });
      }
      tx.set(indexRef, {
        currentPath: livePath,
        uploadedAt: now,
        status: 'pending',
        documentType,
        updatedAt: now,
      });
    });
  } catch (e) {
    // The object is under the server-only prefix either way; the account
    // deletion hook lists the prefix, so it can never be orphaned forever.
    logError(`retainSubmittedDocument: index update failed for ${uid}`, e);
  }
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

// ─────────────────────────────────────────────────────── account deletion

/**
 * Account deleted: move every `id_documents/{uid}/…` object to
 * `retention/{uid}/…`, fold earlier retention entries of the user into ONE
 * `account_{uid}` entry (purge = deletion + 30 days, holds preserved) and
 * delete the live index doc. Idempotent: both the Auth-delete and the
 * profile-delete cascades call it; the second run finds nothing to move and
 * leaves the entry as is.
 */
export async function retainIdDocumentsOnAccountDeletion(uid: string): Promise<number> {
  if (!uid) return 0;
  const bucket = admin.storage().bucket();
  const moved: string[] = [];
  try {
    const [files] = await bucket.getFiles({ prefix: `${ID_DOCUMENTS}/${uid}/` });
    for (const f of files) {
      const dest = retentionPathFor(f.name, uid);
      try {
        await f.move(dest);
        moved.push(dest);
      } catch (e) {
        logError(`retainIdDocumentsOnAccountDeletion: move ${f.name} failed`, e);
      }
    }
  } catch (e) {
    logError(`retainIdDocumentsOnAccountDeletion: list ${uid} failed`, e);
  }

  const indexRef = db.collection(ID_DOCUMENTS).doc(uid);
  const accountRef = db.collection(ID_DOCUMENT_RETENTION).doc(`account_${uid}`);
  const existing = await db
    .collection(ID_DOCUMENT_RETENTION)
    .where('uid', '==', uid)
    .limit(100)
    .get();
  const index = await indexRef.get();

  if (moved.length === 0 && existing.empty) {
    if (index.exists) await indexRef.delete().catch(() => undefined);
    return 0;
  }

  const nowMs = Date.now();
  const merged = mergeAccountRetention(moved, nowMs, existing.docs.map(toEntry));
  const batch = db.batch();
  for (const d of existing.docs) if (d.id !== accountRef.id) batch.delete(d.ref);
  batch.set(accountRef, {
    uid,
    storagePaths: merged.storagePaths,
    verificationStatus: index.data()?.status ?? existing.docs.find((d) => d.id === accountRef.id)?.get('verificationStatus') ?? null,
    reason: 'account-deleted',
    deletedAccountAt: existing.docs.find((d) => d.id === accountRef.id)?.get('deletedAccountAt') ?? Timestamp.fromMillis(nowMs),
    retainedAt: Timestamp.fromMillis(nowMs),
    purgeAfter: Timestamp.fromMillis(merged.purgeAfterMs),
    legalHold: merged.legalHold,
    retentionPurpose: 'fraud-prevention',
  });
  if (index.exists) batch.delete(indexRef);
  await batch.commit();
  logInfo(`retainIdDocumentsOnAccountDeletion: ${uid} — ${moved.length} moved, ${merged.storagePaths.length} retained`);
  return moved.length;
}

// ─────────────────────────────────────────────────────── purge

const PURGE_PAGE = 200;
const PURGE_MAX_PAGES = 25;

export const purgeRetainedIdDocuments = onSchedule(
  { schedule: '30 3 * * *', timeZone: 'UTC', memory: '512MiB', timeoutSeconds: 540 },
  async () => {
    const nowMs = Date.now();
    let cursor: admin.firestore.DocumentSnapshot | null = null;
    let purged = 0;
    let held = 0;
    let objects = 0;
    let failures = 0;
    for (let i = 0; i < PURGE_MAX_PAGES; i++) {
      let q = db
        .collection(ID_DOCUMENT_RETENTION)
        .where('purgeAfter', '<=', Timestamp.fromMillis(nowMs))
        .orderBy('purgeAfter')
        .limit(PURGE_PAGE);
      if (cursor) q = q.startAfter(cursor);
      const page = await q.get();
      const plan = planPurgePage(page.docs.map(toEntry), nowMs, PURGE_PAGE);
      held += plan.held;
      for (const e of plan.due) {
        const paths = entryPaths(e);
        const results = await Promise.all(paths.map(deleteObjectIfExists));
        if (results.every(Boolean)) {
          objects += paths.length;
          await db.collection(ID_DOCUMENT_RETENTION).doc(e.id).delete();
          purged++;
        } else {
          failures++; // retried tomorrow (idempotent: missing objects are fine)
        }
      }
      if (plan.done || page.empty) break;
      cursor = page.docs[page.docs.length - 1];
      if (i === PURGE_MAX_PAGES - 1) logWarning('purgeRetainedIdDocuments: page cap reached, continuing tomorrow');
    }
    logInfo(`purgeRetainedIdDocuments: purged ${purged} entries / ${objects} objects, ${held} on legal hold, ${failures} failed`);
  },
);

// ─────────────────────────────────────────────────────── admin callables

async function requireAdmin(uid: string | undefined): Promise<string> {
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
  const me = await db.collection('users').doc(uid).get();
  if (!me.data()?.isAdmin) throw new HttpsError('permission-denied', 'Admin only.');
  return uid;
}

/**
 * Places / lifts a legal hold (e.g. an open scam report) on one retention
 * entry ({retentionId}) or on every entry of a user ({uid}). Held entries are
 * never purged until the hold is lifted.
 */
export const setIdDocumentLegalHold = onCall<{ retentionId?: string; uid?: string; hold?: boolean; note?: string }>(
  { memory: '512MiB', timeoutSeconds: 60 },
  async (request) => {
    const adminUid = await requireAdmin(request.auth?.uid);
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
    await requireAdmin(request.auth?.uid);
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
