"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.backfillIdVerifiedFlags = exports.setIdDocumentLegalHold = exports.purgeRetainedIdDocuments = exports.ID_DOCUMENT_RETENTION = exports.ID_DOCUMENTS = void 0;
exports.retainSubmittedDocument = retainSubmittedDocument;
exports.setIdDocumentStatus = setIdDocumentStatus;
exports.retainIdDocumentsOnAccountDeletion = retainIdDocumentsOnAccountDeletion;
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
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("../shared/utils");
const idDocumentRetentionLogic_1 = require("./idDocumentRetentionLogic");
exports.ID_DOCUMENTS = 'id_documents';
exports.ID_DOCUMENT_RETENTION = 'id_document_retention';
const Timestamp = admin.firestore.Timestamp;
function tsMs(v) {
    if (v instanceof admin.firestore.Timestamp)
        return v.toMillis();
    if (typeof v === 'number' && Number.isFinite(v))
        return v;
    return null;
}
function toEntry(d) {
    var _a;
    const x = (_a = d.data()) !== null && _a !== void 0 ? _a : {};
    return {
        id: d.id,
        uid: typeof x.uid === 'string' ? x.uid : undefined,
        storagePaths: x.storagePaths,
        purgeAfterMs: tsMs(x.purgeAfter),
        legalHold: x.legalHold,
    };
}
async function deleteObjectIfExists(path) {
    try {
        await admin.storage().bucket().file(path).delete({ ignoreNotFound: true });
        return true;
    }
    catch (e) {
        (0, utils_1.logError)(`idDocumentRetention: delete ${path} failed`, e);
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
async function retainSubmittedDocument(uid, uploadPath, documentType) {
    const bucket = admin.storage().bucket();
    const name = uploadPath.split('/').pop() || `${Date.now()}.jpg`;
    const livePath = `${exports.ID_DOCUMENTS}/${uid}/${Date.now()}_${name}`;
    try {
        await bucket.file(uploadPath).move(livePath);
    }
    catch (e) {
        (0, utils_1.logError)(`retainSubmittedDocument: move ${uploadPath} failed`, e);
        return null;
    }
    const indexRef = utils_1.db.collection(exports.ID_DOCUMENTS).doc(uid);
    try {
        await utils_1.db.runTransaction(async (tx) => {
            var _a, _b, _c;
            const prev = await tx.get(indexRef);
            const prevPath = (_a = prev.data()) === null || _a === void 0 ? void 0 : _a.currentPath;
            const now = Timestamp.now();
            if (typeof prevPath === 'string' && prevPath && prevPath !== livePath) {
                tx.set(utils_1.db.collection(exports.ID_DOCUMENT_RETENTION).doc(), {
                    uid,
                    storagePaths: [prevPath],
                    verificationStatus: (_c = (_b = prev.data()) === null || _b === void 0 ? void 0 : _b.status) !== null && _c !== void 0 ? _c : null,
                    reason: 'replaced',
                    retainedAt: now,
                    purgeAfter: Timestamp.fromMillis((0, idDocumentRetentionLogic_1.purgeAfterMs)(now.toMillis())),
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
    }
    catch (e) {
        // The object is under the server-only prefix either way; the account
        // deletion hook lists the prefix, so it can never be orphaned forever.
        (0, utils_1.logError)(`retainSubmittedDocument: index update failed for ${uid}`, e);
    }
    return livePath;
}
/** Mirrors the verification decision onto the document index. */
async function setIdDocumentStatus(uid, status) {
    try {
        await utils_1.db.collection(exports.ID_DOCUMENTS).doc(uid).set({ status, updatedAt: Timestamp.now() }, { merge: true });
    }
    catch (e) {
        (0, utils_1.logError)(`setIdDocumentStatus: ${uid} failed`, e);
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
async function retainIdDocumentsOnAccountDeletion(uid) {
    var _a, _b, _c, _d, _e, _f;
    if (!uid)
        return 0;
    const bucket = admin.storage().bucket();
    const moved = [];
    try {
        const [files] = await bucket.getFiles({ prefix: `${exports.ID_DOCUMENTS}/${uid}/` });
        for (const f of files) {
            const dest = (0, idDocumentRetentionLogic_1.retentionPathFor)(f.name, uid);
            try {
                await f.move(dest);
                moved.push(dest);
            }
            catch (e) {
                (0, utils_1.logError)(`retainIdDocumentsOnAccountDeletion: move ${f.name} failed`, e);
            }
        }
    }
    catch (e) {
        (0, utils_1.logError)(`retainIdDocumentsOnAccountDeletion: list ${uid} failed`, e);
    }
    const indexRef = utils_1.db.collection(exports.ID_DOCUMENTS).doc(uid);
    const accountRef = utils_1.db.collection(exports.ID_DOCUMENT_RETENTION).doc(`account_${uid}`);
    const existing = await utils_1.db
        .collection(exports.ID_DOCUMENT_RETENTION)
        .where('uid', '==', uid)
        .limit(100)
        .get();
    const index = await indexRef.get();
    if (moved.length === 0 && existing.empty) {
        if (index.exists)
            await indexRef.delete().catch(() => undefined);
        return 0;
    }
    const nowMs = Date.now();
    const merged = (0, idDocumentRetentionLogic_1.mergeAccountRetention)(moved, nowMs, existing.docs.map(toEntry));
    const batch = utils_1.db.batch();
    for (const d of existing.docs)
        if (d.id !== accountRef.id)
            batch.delete(d.ref);
    batch.set(accountRef, {
        uid,
        storagePaths: merged.storagePaths,
        verificationStatus: (_d = (_b = (_a = index.data()) === null || _a === void 0 ? void 0 : _a.status) !== null && _b !== void 0 ? _b : (_c = existing.docs.find((d) => d.id === accountRef.id)) === null || _c === void 0 ? void 0 : _c.get('verificationStatus')) !== null && _d !== void 0 ? _d : null,
        reason: 'account-deleted',
        deletedAccountAt: (_f = (_e = existing.docs.find((d) => d.id === accountRef.id)) === null || _e === void 0 ? void 0 : _e.get('deletedAccountAt')) !== null && _f !== void 0 ? _f : Timestamp.fromMillis(nowMs),
        retainedAt: Timestamp.fromMillis(nowMs),
        purgeAfter: Timestamp.fromMillis(merged.purgeAfterMs),
        legalHold: merged.legalHold,
        retentionPurpose: 'fraud-prevention',
    });
    if (index.exists)
        batch.delete(indexRef);
    await batch.commit();
    (0, utils_1.logInfo)(`retainIdDocumentsOnAccountDeletion: ${uid} — ${moved.length} moved, ${merged.storagePaths.length} retained`);
    return moved.length;
}
// ─────────────────────────────────────────────────────── purge
const PURGE_PAGE = 200;
const PURGE_MAX_PAGES = 25;
exports.purgeRetainedIdDocuments = (0, scheduler_1.onSchedule)({ schedule: '30 3 * * *', timeZone: 'UTC', memory: '512MiB', timeoutSeconds: 540 }, async () => {
    const nowMs = Date.now();
    let cursor = null;
    let purged = 0;
    let held = 0;
    let objects = 0;
    let failures = 0;
    for (let i = 0; i < PURGE_MAX_PAGES; i++) {
        let q = utils_1.db
            .collection(exports.ID_DOCUMENT_RETENTION)
            .where('purgeAfter', '<=', Timestamp.fromMillis(nowMs))
            .orderBy('purgeAfter')
            .limit(PURGE_PAGE);
        if (cursor)
            q = q.startAfter(cursor);
        const page = await q.get();
        const plan = (0, idDocumentRetentionLogic_1.planPurgePage)(page.docs.map(toEntry), nowMs, PURGE_PAGE);
        held += plan.held;
        for (const e of plan.due) {
            const paths = (0, idDocumentRetentionLogic_1.entryPaths)(e);
            const results = await Promise.all(paths.map(deleteObjectIfExists));
            if (results.every(Boolean)) {
                objects += paths.length;
                await utils_1.db.collection(exports.ID_DOCUMENT_RETENTION).doc(e.id).delete();
                purged++;
            }
            else {
                failures++; // retried tomorrow (idempotent: missing objects are fine)
            }
        }
        if (plan.done || page.empty)
            break;
        cursor = page.docs[page.docs.length - 1];
        if (i === PURGE_MAX_PAGES - 1)
            (0, utils_1.logWarning)('purgeRetainedIdDocuments: page cap reached, continuing tomorrow');
    }
    (0, utils_1.logInfo)(`purgeRetainedIdDocuments: purged ${purged} entries / ${objects} objects, ${held} on legal hold, ${failures} failed`);
});
// ─────────────────────────────────────────────────────── admin callables
async function requireAdmin(uid) {
    var _a;
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const me = await utils_1.db.collection('users').doc(uid).get();
    if (!((_a = me.data()) === null || _a === void 0 ? void 0 : _a.isAdmin))
        throw new https_1.HttpsError('permission-denied', 'Admin only.');
    return uid;
}
/**
 * Places / lifts a legal hold (e.g. an open scam report) on one retention
 * entry ({retentionId}) or on every entry of a user ({uid}). Held entries are
 * never purged until the hold is lifted.
 */
exports.setIdDocumentLegalHold = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 60 }, async (request) => {
    var _a, _b, _c, _d, _e;
    const adminUid = await requireAdmin((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid);
    const hold = ((_b = request.data) === null || _b === void 0 ? void 0 : _b.hold) === true;
    const patch = {
        legalHold: hold,
        legalHoldBy: adminUid,
        legalHoldAt: Timestamp.now(),
        legalHoldNote: typeof ((_c = request.data) === null || _c === void 0 ? void 0 : _c.note) === 'string' ? request.data.note.slice(0, 500) : null,
    };
    const rid = (_d = request.data) === null || _d === void 0 ? void 0 : _d.retentionId;
    if (typeof rid === 'string' && rid) {
        const ref = utils_1.db.collection(exports.ID_DOCUMENT_RETENTION).doc(rid);
        if (!(await ref.get()).exists)
            throw new https_1.HttpsError('not-found', 'No such retention entry.');
        await ref.update(patch);
        return { updated: 1 };
    }
    const uid = (_e = request.data) === null || _e === void 0 ? void 0 : _e.uid;
    if (typeof uid !== 'string' || !uid) {
        throw new https_1.HttpsError('invalid-argument', 'retentionId or uid is required.');
    }
    const snap = await utils_1.db.collection(exports.ID_DOCUMENT_RETENTION).where('uid', '==', uid).limit(100).get();
    const batch = utils_1.db.batch();
    snap.docs.forEach((d) => batch.update(d.ref, patch));
    if (!snap.empty)
        await batch.commit();
    (0, utils_1.logInfo)(`setIdDocumentLegalHold: ${adminUid} hold=${hold} uid=${uid} (${snap.size})`);
    return { updated: snap.size };
});
/**
 * Admin-only, resumable: repairs `profiles.isAgeVerified` (THE "ID verified"
 * badge flag) from `ageVerification.status`. writeStatus() always writes both,
 * so this is a safety net. Call with the returned `cursor` until `done`.
 */
exports.backfillIdVerifiedFlags = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 540 }, async (request) => {
    var _a, _b, _c;
    await requireAdmin((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid);
    const pageSize = Math.min(Math.max(Number((_b = request.data) === null || _b === void 0 ? void 0 : _b.pageSize) || 300, 1), 500);
    let q = utils_1.db.collection('profiles')
        .orderBy(admin.firestore.FieldPath.documentId())
        .select('ageVerification', 'isAgeVerified')
        .limit(pageSize);
    if (typeof ((_c = request.data) === null || _c === void 0 ? void 0 : _c.cursor) === 'string' && request.data.cursor) {
        q = q.startAfter(request.data.cursor);
    }
    const page = await q.get();
    let repaired = 0;
    let batch = utils_1.db.batch();
    let ops = 0;
    for (const d of page.docs) {
        const data = d.data();
        if (!(0, idDocumentRetentionLogic_1.idVerifiedFlagNeedsRepair)(data))
            continue;
        batch.update(d.ref, { isAgeVerified: (0, idDocumentRetentionLogic_1.idVerifiedFlagFor)(data.ageVerification) });
        repaired++;
        if (++ops >= 400) {
            await batch.commit();
            batch = utils_1.db.batch();
            ops = 0;
        }
    }
    if (ops > 0)
        await batch.commit();
    const last = page.docs[page.docs.length - 1];
    return { scanned: page.size, repaired, cursor: last ? last.id : null, done: page.size < pageSize };
});
//# sourceMappingURL=idDocumentRetention.js.map