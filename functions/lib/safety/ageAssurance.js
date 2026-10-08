"use strict";
/**
 * Age assurance.
 *
 * GreenGo was rejected under Guideline 2.3.6 for claiming Age Assurance it did
 * not have. A self-declared date of birth is NOT age assurance in Apple's
 * sense — it is an unverified claim. This module adds the real thing, and
 * Guideline 1.2.1 / 4.7.5 require exactly this shape: an age-restriction
 * mechanism based on a verified or declared age, limiting who can publish
 * content other people see.
 *
 * The policy, in one place:
 *
 *   • Everyone declares a date of birth at onboarding. Under-18 is already
 *     blocked there. That gives status 'declared'.
 *   • Anyone may strengthen that to 'verified' by submitting an identity
 *     document. The document's date of birth is read, checked against the
 *     declared one, and the IMAGE IS THEN DELETED.
 *   • Users who signed in with a PHONE NUMBER must submit a document. Phone
 *     auth carries no identity signal at all, so a declared birth date from a
 *     phone-only account is worth nothing.
 *   • Publishing to a Community requires 'verified'. Reading and joining stay
 *     open to everyone — the gate is on broadcasting to others, which is what
 *     1.2.1 is about.
 *
 * PRIVACY. An identity document is the most sensitive data GreenGo will ever
 * hold. Originally the image was deleted seconds after OCR. Since Phase 1
 * experience safety (hosts / paying guests must have an ID document on file,
 * admins review uncertain documents) the image is RETAINED for fraud
 * prevention — DRAFT, LAWYER REVIEW (LGPD art. 7 IX legitimate interest /
 * GDPR Art. 6(1)(f)); the privacy policy text was updated accordingly:
 *   - the upload lands in the client's write-only `age_verification/{uid}/`
 *     prefix and is immediately MOVED to the server-only
 *     `id_documents/{uid}/` prefix (no client read/write, admins via Admin
 *     SDK only), indexed by `id_documents/{uid}` (server-only);
 *   - every SUBMITTED document is kept, including unreadable / underage /
 *     reused ones: those are exactly the fraud attempts worth evidencing;
 *   - a replaced document is kept 30 days, and on account deletion all of
 *     them are moved to `retention/{uid}/` for 30 days, then erased by
 *     `purgeRetainedIdDocuments` (see idDocumentRetention*.ts) unless an
 *     admin placed a legal hold;
 *   - the upload is still DELETED when there is no profile (nothing to verify)
 *     or when the move fails (never leave it under the client prefix).
 * On the profile (readable by signed-in users) only the derived result is
 * stored: extracted birth date, a one-way hash of the document number (so the
 * same document cannot be reused across accounts) and the decision.
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
exports.backfillDeclaredAge = exports.getAgeVerificationDetails = exports.reviewAgeVerification = exports.submitAgeDocument = exports.getAgeVerificationState = exports.MINIMUM_AGE = void 0;
exports.parseDateOfBirth = parseDateOfBirth;
exports.ageFrom = ageFrom;
exports.requiresIdDocument = requiresIdDocument;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const crypto_1 = require("crypto");
const vision_1 = __importDefault(require("@google-cloud/vision"));
const utils_1 = require("../shared/utils");
const idDocumentRetention_1 = require("./idDocumentRetention");
const visionClient = new vision_1.default.ImageAnnotatorClient();
exports.MINIMUM_AGE = 18;
/** How far the document's birth date may sit from the declared one. */
const DOB_TOLERANCE_DAYS = 1;
/** Confidence at or above which the document is accepted without a human. */
const AUTO_VERIFY_CONFIDENCE = 0.85;
// ============================================================================
// Date-of-birth extraction
// ============================================================================
/**
 * Pulls a date of birth out of OCR text.
 *
 * The previous implementation accepted only `dd/mm/yyyy` and `yyyy-mm-dd`,
 * which fails on most of the documents GreenGo's users actually carry: Italian
 * and German IDs print `dd.mm.yyyy`, many print `dd MMM yyyy`, and every
 * passport in the world carries a machine-readable zone with `YYMMDD`.
 *
 * Exported so it can be unit-tested without Vision or Firestore.
 */
function parseDateOfBirth(text) {
    const candidates = [];
    // 1. Machine-readable zone (TD1/TD2/TD3). The most reliable source by far:
    //    fixed columns, no localisation, and a check digit.
    //    Passport line 2: ...NNNNNNNNN<CCC YYMMDD C SEX YYMMDD...
    //    A passport has TWO such lines and only the second carries the birth
    //    date, so every candidate line is tried rather than just the first.
    const mrzLines = text
        .split(/\r?\n/)
        .map((l) => l.replace(/\s/g, ''))
        .filter((l) => /^[A-Z0-9<]{28,44}$/.test(l) && l.includes('<'));
    for (const line of mrzLines) {
        const mrzDob = line.match(/(\d{6})\d[MF<]/);
        if (mrzDob) {
            const d = fromYYMMDD(mrzDob[1]);
            if (d)
                candidates.push(d);
        }
    }
    // 2. Explicitly labelled birth dates win over any loose date on the card.
    const labelled = text.match(/(?:date of birth|birth date|born|nascita|geboren|geburtsdatum|naissance|nacimiento|nascimento)[^\d]{0,20}(\d{1,2})[\/.\-\s](\d{1,2}|[A-Za-z]{3,})[\/.\-\s](\d{2,4})/i);
    if (labelled) {
        const d = fromParts(labelled[1], labelled[2], labelled[3]);
        if (d)
            candidates.push(d);
    }
    // 3. ISO.
    for (const m of text.matchAll(/\b(\d{4})-(\d{2})-(\d{2})\b/g)) {
        const d = buildDate(+m[1], +m[2], +m[3]);
        if (d)
            candidates.push(d);
    }
    // 4. Day-first numeric, the European norm: dd/mm/yyyy, dd.mm.yyyy, dd-mm-yyyy.
    for (const m of text.matchAll(/\b(\d{1,2})[\/.\-](\d{1,2})[\/.\-](\d{4})\b/g)) {
        const d = fromParts(m[1], m[2], m[3]);
        if (d)
            candidates.push(d);
    }
    // 5. Day with a month name: 14 MAR 1990.
    for (const m of text.matchAll(/\b(\d{1,2})[\s.\-]([A-Za-z]{3,})[\s.\-](\d{4})\b/g)) {
        const d = fromParts(m[1], m[2], m[3]);
        if (d)
            candidates.push(d);
    }
    // A document carries several dates (issue, expiry, birth). The birth date is
    // the only one that can be decades old, so prefer the EARLIEST plausible one.
    const plausible = candidates.filter(isPlausibleBirthDate);
    if (plausible.length === 0)
        return null;
    plausible.sort((a, b) => a.getTime() - b.getTime());
    return plausible[0];
}
const MONTHS = {
    jan: 1, gen: 1, ene: 1,
    feb: 2, fev: 2,
    mar: 3,
    apr: 4, abr: 4, avr: 4,
    may: 5, mag: 5, mai: 5, mei: 5,
    jun: 6, giu: 6,
    jul: 7, lug: 7, jui: 7,
    aug: 8, ago: 8, aou: 8,
    sep: 9, set: 9,
    oct: 10, ott: 10, out: 10, okt: 10,
    nov: 11,
    dec: 12, dic: 12, dez: 12,
};
function fromParts(day, month, year) {
    var _a;
    const d = parseInt(day, 10);
    const y = year.length === 2 ? 1900 + parseInt(year, 10) : parseInt(year, 10);
    let m;
    if (/^\d+$/.test(month)) {
        m = parseInt(month, 10);
    }
    else {
        const key = month.slice(0, 3).toLowerCase();
        m = (_a = MONTHS[key]) !== null && _a !== void 0 ? _a : NaN;
    }
    return buildDate(y, m, d);
}
/** MRZ dates are YYMMDD with no century. A birth date is always in the past. */
function fromYYMMDD(s) {
    const yy = parseInt(s.slice(0, 2), 10);
    const mm = parseInt(s.slice(2, 4), 10);
    const dd = parseInt(s.slice(4, 6), 10);
    const thisYear = new Date().getUTCFullYear() % 100;
    const century = yy > thisYear ? 1900 : 2000;
    return buildDate(century + yy, mm, dd);
}
function buildDate(y, m, d) {
    if (!Number.isFinite(y) || !Number.isFinite(m) || !Number.isFinite(d))
        return null;
    if (m < 1 || m > 12 || d < 1 || d > 31)
        return null;
    const date = new Date(Date.UTC(y, m - 1, d));
    // Rejects 31 February and friends, which JS would otherwise roll over.
    if (date.getUTCMonth() !== m - 1 || date.getUTCDate() !== d)
        return null;
    return date;
}
function isPlausibleBirthDate(d) {
    const age = ageFrom(d);
    return age >= 13 && age <= 120;
}
function ageFrom(dob, now = new Date()) {
    let age = now.getUTCFullYear() - dob.getUTCFullYear();
    const beforeBirthday = now.getUTCMonth() < dob.getUTCMonth() ||
        (now.getUTCMonth() === dob.getUTCMonth() && now.getUTCDate() < dob.getUTCDate());
    if (beforeBirthday)
        age -= 1;
    return age;
}
// ============================================================================
// Policy helpers
// ============================================================================
/**
 * Whether [uid] must produce an identity document.
 *
 * True for accounts whose ONLY sign-in method is a phone number. An email or
 * federated account at least ties the person to an identity provider; a phone
 * number does not, so the declared birth date behind it is unsupported.
 */
async function requiresIdDocument(uid) {
    try {
        const user = await admin.auth().getUser(uid);
        const providers = user.providerData.map((p) => p.providerId);
        if (providers.length === 0)
            return false;
        return providers.every((p) => p === 'phone');
    }
    catch (e) {
        (0, utils_1.logWarning)(`requiresIdDocument: could not read auth user ${uid}`, e);
        // Fail OPEN for the requirement check: never lock someone out of the app
        // because an auth lookup blipped. Publishing still needs 'verified'.
        return false;
    }
}
/** Writes the status to the profile, plus the denormalised flag rules read. */
async function writeStatus(uid, status, extra = {}) {
    await utils_1.db.collection('profiles').doc(uid).set({
        ageVerification: Object.assign({ status, updatedAt: admin.firestore.Timestamp.now() }, extra),
        // Denormalised so security rules cost ONE document read instead of
        // reaching into a nested map on every community write.
        isAgeVerified: status === 'verified',
    }, { merge: true });
}
/** Deletes the uploaded document. Called on every path, success or failure. */
async function destroyDocument(documentPath) {
    try {
        await admin.storage().bucket().file(documentPath).delete();
        (0, utils_1.logInfo)(`ageAssurance: deleted document ${documentPath}`);
    }
    catch (e) {
        // Worth shouting about: an identity document that outlives its purpose is
        // the whole privacy risk of this feature.
        (0, utils_1.logError)(`ageAssurance: FAILED to delete document ${documentPath}`, e);
    }
}
// ============================================================================
// Callables
// ============================================================================
/**
 * What the client needs to render the verification prompt: current status,
 * whether a document is mandatory for this account, and why.
 */
exports.getAgeVerificationState = (0, https_1.onCall)({ memory: '512MiB' }, async (request) => {
    var _a, _b, _c, _d, _e, _f;
    const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const snap = await utils_1.db.collection('profiles').doc(uid).get();
    const data = (_b = snap.data()) !== null && _b !== void 0 ? _b : {};
    const status = (_d = (_c = data.ageVerification) === null || _c === void 0 ? void 0 : _c.status) !== null && _d !== void 0 ? _d : (data.dateOfBirth ? 'declared' : 'none');
    return {
        status,
        documentRequired: await requiresIdDocument(uid),
        canPublishToCommunities: status === 'verified',
        rejectionReason: (_f = (_e = data.ageVerification) === null || _e === void 0 ? void 0 : _e.rejectionReason) !== null && _f !== void 0 ? _f : null,
    };
});
/**
 * Reads an uploaded identity document, decides, and deletes the image.
 *
 * `documentPath` is a Storage path (not a URL) so the function can delete it
 * afterwards; the client uploads to a write-only, user-scoped prefix.
 */
exports.submitAgeDocument = (0, https_1.onCall)({ memory: '1GiB' }, async (request) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k;
    const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const documentPath = String((_c = (_b = request.data) === null || _b === void 0 ? void 0 : _b.documentPath) !== null && _c !== void 0 ? _c : '');
    const documentType = String((_e = (_d = request.data) === null || _d === void 0 ? void 0 : _d.documentType) !== null && _e !== void 0 ? _e : 'id_card');
    if (!documentPath.startsWith(`age_verification/${uid}/`)) {
        throw new https_1.HttpsError('permission-denied', 'Document must be uploaded to your own verification folder.');
    }
    const profileRef = utils_1.db.collection('profiles').doc(uid);
    const profileSnap = await profileRef.get();
    if (!profileSnap.exists) {
        await destroyDocument(documentPath);
        throw new https_1.HttpsError('failed-precondition', 'Complete your profile first.');
    }
    const declaredTs = (_f = profileSnap.data()) === null || _f === void 0 ? void 0 : _f.dateOfBirth;
    const declaredDob = declaredTs instanceof admin.firestore.Timestamp ? declaredTs.toDate() : null;
    await writeStatus(uid, 'pending', { submittedAt: admin.firestore.Timestamp.now() });
    // Retain (move to the server-only prefix) BEFORE OCR, so the image is never
    // left under the client's upload prefix. Null = move failed → OCR the upload
    // and delete it afterwards (old behaviour).
    const keptPath = await (0, idDocumentRetention_1.retainSubmittedDocument)(uid, documentPath, documentType);
    const ocrPath = keptPath !== null && keptPath !== void 0 ? keptPath : documentPath;
    const releaseUpload = async () => {
        if (!keptPath)
            await destroyDocument(documentPath);
    };
    const recordDecision = async (status) => {
        if (keptPath)
            await (0, idDocumentRetention_1.setIdDocumentStatus)(uid, status);
    };
    let text = '';
    try {
        const bucket = admin.storage().bucket().name;
        const [result] = await visionClient.textDetection(`gs://${bucket}/${ocrPath}`);
        text = (_h = (_g = result.fullTextAnnotation) === null || _g === void 0 ? void 0 : _g.text) !== null && _h !== void 0 ? _h : '';
    }
    catch (e) {
        (0, utils_1.logError)(`submitAgeDocument: OCR failed for ${uid}`, e);
        await releaseUpload();
        await writeStatus(uid, 'rejected', {
            rejectionReason: 'unreadable',
            reviewedBy: 'system',
        });
        await recordDecision('rejected');
        return { status: 'rejected', reason: 'unreadable' };
    }
    const documentDob = parseDateOfBirth(text);
    const documentNumber = (_k = (_j = text.match(/\b[A-Z0-9]{6,12}\b/)) === null || _j === void 0 ? void 0 : _j[0]) !== null && _k !== void 0 ? _k : null;
    // Not retained (move failed): the upload has served its purpose.
    await releaseUpload();
    if (!documentDob) {
        await recordDecision('rejected');
        await writeStatus(uid, 'rejected', {
            rejectionReason: 'noBirthDateFound',
            reviewedBy: 'system',
        });
        return { status: 'rejected', reason: 'noBirthDateFound' };
    }
    const age = ageFrom(documentDob);
    if (age < exports.MINIMUM_AGE) {
        await writeStatus(uid, 'rejected', {
            rejectionReason: 'underage',
            reviewedBy: 'system',
            documentDateOfBirth: admin.firestore.Timestamp.fromDate(documentDob),
        });
        await recordDecision('rejected');
        (0, utils_1.logWarning)(`submitAgeDocument: underage document for ${uid} (age ${age})`);
        return { status: 'rejected', reason: 'underage' };
    }
    // Does the document agree with what the user told us?
    let matchesDeclaration = true;
    if (declaredDob) {
        const deltaDays = Math.abs(documentDob.getTime() - declaredDob.getTime()) / 86400000;
        matchesDeclaration = deltaDays <= DOB_TOLERANCE_DAYS;
    }
    // One document, one account. A hash, never the number itself.
    const documentHash = documentNumber
        ? (0, crypto_1.createHash)('sha256').update(`${documentType}:${documentNumber}`).digest('hex')
        : null;
    if (documentHash) {
        const reused = await utils_1.db
            .collection('profiles')
            .where('ageVerification.documentHash', '==', documentHash)
            .limit(2)
            .get();
        const otherAccount = reused.docs.find((d) => d.id !== uid);
        if (otherAccount) {
            await writeStatus(uid, 'rejected', {
                rejectionReason: 'documentAlreadyUsed',
                reviewedBy: 'system',
            });
            await recordDecision('rejected');
            (0, utils_1.logWarning)(`submitAgeDocument: document reuse by ${uid}`);
            return { status: 'rejected', reason: 'documentAlreadyUsed' };
        }
    }
    const confidence = computeConfidence({
        hasMrz: /^[A-Z0-9<]{28,44}$/m.test(text.replace(/ /g, '')),
        matchesDeclaration,
        hasDocumentNumber: documentNumber !== null,
    });
    if (matchesDeclaration && confidence >= AUTO_VERIFY_CONFIDENCE) {
        await writeStatus(uid, 'verified', {
            method: 'document',
            reviewedBy: 'system',
            confidence,
            documentHash,
            documentDateOfBirth: admin.firestore.Timestamp.fromDate(documentDob),
            verifiedAt: admin.firestore.Timestamp.now(),
        });
        await recordDecision('verified');
        (0, utils_1.logInfo)(`submitAgeDocument: auto-verified ${uid} (confidence ${confidence})`);
        return { status: 'verified' };
    }
    // Anything uncertain goes to a human rather than guessing.
    await utils_1.db.collection('age_verification_queue').doc(uid).set({
        userId: uid,
        submittedAt: admin.firestore.Timestamp.now(),
        documentType,
        documentDateOfBirth: admin.firestore.Timestamp.fromDate(documentDob),
        declaredDateOfBirth: declaredDob
            ? admin.firestore.Timestamp.fromDate(declaredDob)
            : null,
        matchesDeclaration,
        confidence,
        documentHash,
        status: 'pending',
    });
    await writeStatus(uid, 'pending', { confidence, documentHash });
    await recordDecision('pending');
    (0, utils_1.logInfo)(`submitAgeDocument: queued ${uid} for review (confidence ${confidence})`);
    return { status: 'pending' };
});
function computeConfidence(signals) {
    let score = 0.4;
    if (signals.hasMrz)
        score += 0.35; // machine-readable, check-digited
    if (signals.matchesDeclaration)
        score += 0.2;
    if (signals.hasDocumentNumber)
        score += 0.1;
    return Math.min(score, 1);
}
/**
 * Admin decision on a queued submission. Used by the admin panel's
 * verification queue.
 */
exports.reviewAgeVerification = (0, https_1.onCall)({ memory: '512MiB' }, async (request) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j;
    const adminUid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!adminUid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const adminDoc = await utils_1.db.collection('users').doc(adminUid).get();
    if (!((_b = adminDoc.data()) === null || _b === void 0 ? void 0 : _b.isAdmin)) {
        throw new https_1.HttpsError('permission-denied', 'Admin only.');
    }
    const targetUid = String((_d = (_c = request.data) === null || _c === void 0 ? void 0 : _c.userId) !== null && _d !== void 0 ? _d : '');
    const approve = ((_e = request.data) === null || _e === void 0 ? void 0 : _e.approve) === true;
    const reason = String((_g = (_f = request.data) === null || _f === void 0 ? void 0 : _f.reason) !== null && _g !== void 0 ? _g : '');
    if (!targetUid)
        throw new https_1.HttpsError('invalid-argument', 'userId is required.');
    const queueRef = utils_1.db.collection('age_verification_queue').doc(targetUid);
    const queued = await queueRef.get();
    await writeStatus(targetUid, approve ? 'verified' : 'rejected', Object.assign({ method: 'document', reviewedBy: adminUid, reviewedAt: admin.firestore.Timestamp.now(), rejectionReason: approve ? null : reason || 'rejectedByReviewer', documentHash: (_j = (_h = queued.data()) === null || _h === void 0 ? void 0 : _h.documentHash) !== null && _j !== void 0 ? _j : null }, (approve ? { verifiedAt: admin.firestore.Timestamp.now() } : {})));
    await queueRef.set({
        status: approve ? 'approved' : 'rejected',
        reviewedBy: adminUid,
        reviewedAt: admin.firestore.Timestamp.now(),
        reason: reason || null,
    }, { merge: true });
    await (0, idDocumentRetention_1.setIdDocumentStatus)(targetUid, approve ? 'verified' : 'rejected');
    (0, utils_1.logInfo)(`reviewAgeVerification: ${adminUid} ${approve ? 'approved' : 'rejected'} ${targetUid}`);
    return { status: approve ? 'verified' : 'rejected' };
});
/** Largest document image returned inline (callable responses cap at 10 MB). */
const MAX_DOCUMENT_BYTES = 7 * 1024 * 1024;
const isoOf = (v) => v instanceof admin.firestore.Timestamp ? v.toDate().toISOString() : null;
/**
 * Admin view of ONE user's age verification, for the admin panel's Users page:
 * the status on the profile, the review-queue entry (birth date read off the
 * document vs. the declared one, confidence) and the retained document image
 * itself, returned inline as base64 — no signed URL, so nothing shareable
 * outlives the dialog. Every call that returns an image is written to
 * `admin_audit_log` (who looked at whose identity document, when).
 * Decisions still go through [reviewAgeVerification].
 */
exports.getAgeVerificationDetails = (0, https_1.onCall)({ memory: '512MiB' }, async (request) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q, _r, _s, _t, _u, _v, _w, _x, _y, _z;
    const adminUid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!adminUid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const adminDoc = await utils_1.db.collection('users').doc(adminUid).get();
    if (!((_b = adminDoc.data()) === null || _b === void 0 ? void 0 : _b.isAdmin)) {
        throw new https_1.HttpsError('permission-denied', 'Admin only.');
    }
    const targetUid = String((_d = (_c = request.data) === null || _c === void 0 ? void 0 : _c.userId) !== null && _d !== void 0 ? _d : '');
    if (!targetUid)
        throw new https_1.HttpsError('invalid-argument', 'userId is required.');
    const [profileSnap, queueSnap, indexSnap] = await Promise.all([
        utils_1.db.collection('profiles').doc(targetUid).get(),
        utils_1.db.collection('age_verification_queue').doc(targetUid).get(),
        utils_1.db.collection('id_documents').doc(targetUid).get(),
    ]);
    const profile = (_e = profileSnap.data()) !== null && _e !== void 0 ? _e : {};
    const av = ((_f = profile.ageVerification) !== null && _f !== void 0 ? _f : {});
    const queue = (_g = queueSnap.data()) !== null && _g !== void 0 ? _g : null;
    const index = (_h = indexSnap.data()) !== null && _h !== void 0 ? _h : null;
    let document = null;
    let documentError = null;
    const path = typeof (index === null || index === void 0 ? void 0 : index.currentPath) === 'string' ? index.currentPath : null;
    if (path) {
        try {
            const file = admin.storage().bucket().file(path);
            const [meta] = await file.getMetadata();
            if (Number((_j = meta.size) !== null && _j !== void 0 ? _j : 0) > MAX_DOCUMENT_BYTES) {
                documentError = 'Document is too large to display.';
            }
            else {
                const [buf] = await file.download();
                document = {
                    contentType: String(meta.contentType || 'image/jpeg'),
                    dataBase64: buf.toString('base64'),
                    uploadedAt: isoOf(index === null || index === void 0 ? void 0 : index.uploadedAt),
                };
                await utils_1.db.collection('admin_audit_log').add({
                    adminId: adminUid,
                    adminEmail: (_p = (_l = (_k = adminDoc.data()) === null || _k === void 0 ? void 0 : _k.email) !== null && _l !== void 0 ? _l : (_o = (_m = request.auth) === null || _m === void 0 ? void 0 : _m.token) === null || _o === void 0 ? void 0 : _o.email) !== null && _p !== void 0 ? _p : 'unknown',
                    action: 'view_id_document',
                    targetType: 'user',
                    targetId: targetUid,
                    details: { path },
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        }
        catch (e) {
            (0, utils_1.logError)(`getAgeVerificationDetails: reading ${path} failed`, e);
            documentError = 'The document file could not be read.';
        }
    }
    const status = (_q = av.status) !== null && _q !== void 0 ? _q : (profile.dateOfBirth ? 'declared' : 'none');
    return {
        userId: targetUid,
        status,
        isAgeVerified: profile.isAgeVerified === true,
        documentRequired: await requiresIdDocument(targetUid),
        method: (_r = av.method) !== null && _r !== void 0 ? _r : null,
        confidence: typeof av.confidence === 'number' ? av.confidence : ((_s = queue === null || queue === void 0 ? void 0 : queue.confidence) !== null && _s !== void 0 ? _s : null),
        rejectionReason: (_t = av.rejectionReason) !== null && _t !== void 0 ? _t : null,
        reviewedBy: (_u = av.reviewedBy) !== null && _u !== void 0 ? _u : null,
        reviewedAt: isoOf(av.reviewedAt),
        verifiedAt: isoOf(av.verifiedAt),
        declaredDateOfBirth: isoOf(profile.dateOfBirth),
        documentDateOfBirth: (_v = isoOf(av.documentDateOfBirth)) !== null && _v !== void 0 ? _v : isoOf(queue === null || queue === void 0 ? void 0 : queue.documentDateOfBirth),
        documentType: (_x = (_w = queue === null || queue === void 0 ? void 0 : queue.documentType) !== null && _w !== void 0 ? _w : index === null || index === void 0 ? void 0 : index.documentType) !== null && _x !== void 0 ? _x : null,
        matchesDeclaration: typeof (queue === null || queue === void 0 ? void 0 : queue.matchesDeclaration) === 'boolean' ? queue.matchesDeclaration : null,
        queueStatus: (_y = queue === null || queue === void 0 ? void 0 : queue.status) !== null && _y !== void 0 ? _y : null,
        submittedAt: (_z = isoOf(queue === null || queue === void 0 ? void 0 : queue.submittedAt)) !== null && _z !== void 0 ? _z : isoOf(av.submittedAt),
        document,
        documentError,
    };
});
/**
 * Backfills `ageVerification.status = 'declared'` for existing users who have a
 * birth date but no status yet, so the app does not show every existing user a
 * verification prompt on first launch of v4.0.0.
 */
exports.backfillDeclaredAge = (0, https_1.onCall)({ memory: '1GiB' }, async (request) => {
    var _a, _b, _c;
    const adminUid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!adminUid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in required.');
    const adminDoc = await utils_1.db.collection('users').doc(adminUid).get();
    if (!((_b = adminDoc.data()) === null || _b === void 0 ? void 0 : _b.isAdmin)) {
        throw new https_1.HttpsError('permission-denied', 'Admin only.');
    }
    const snap = await utils_1.db.collection('profiles').limit(5000).get();
    let updated = 0;
    let batch = utils_1.db.batch();
    let queued = 0;
    for (const doc of snap.docs) {
        const data = doc.data();
        if ((_c = data.ageVerification) === null || _c === void 0 ? void 0 : _c.status)
            continue;
        if (!data.dateOfBirth)
            continue;
        batch.set(doc.ref, {
            ageVerification: {
                status: 'declared',
                updatedAt: admin.firestore.Timestamp.now(),
            },
            isAgeVerified: false,
        }, { merge: true });
        updated += 1;
        queued += 1;
        if (queued >= 400) {
            await batch.commit();
            batch = utils_1.db.batch();
            queued = 0;
        }
    }
    if (queued > 0)
        await batch.commit();
    (0, utils_1.logInfo)(`backfillDeclaredAge: ${updated} profiles set to 'declared'`);
    return { updated, scanned: snap.size };
});
//# sourceMappingURL=ageAssurance.js.map