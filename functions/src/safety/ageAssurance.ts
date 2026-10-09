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
 * PRIVACY (P2-6, OWNER DECISION 2026-10-08 — supersedes the retention text
 * below): the image is DELETED as soon as a decision is made (automatic or by
 * an admin, approve or reject), including any retention copy; only
 * {ageVerified, method, decidedAt, birthYear} is kept (id_documents/{uid}).
 * An image waiting for a human review is kept at most 7 days, then purged and
 * the user must re-upload. The document-number fingerprint is a salted HMAC
 * (RETENTION_SALT), kept only so one document cannot verify many accounts.
 * Explicit consent (consents/{uid}.id_verification, via recordConsent) is
 * required before upload; app versions without the consent sheet are still
 * accepted (consentMissing:true) until app_config/compliance
 * .idConsentRequired is set to true — REMOVE THE GRACE PATH after minVersion.
 *
 * Historical note: an identity document is the most sensitive data GreenGo will ever
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

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { requireAdmin, MODERATION_ROLES, SUPER_ADMIN_ONLY } from '../shared/adminAuth';
import vision from '@google-cloud/vision';
import { db, logInfo, logError, logWarning } from '../shared/utils';
import {
  finalizeIdDocumentDecision,
  retainSubmittedDocument,
  setIdDocumentStatus,
} from './idDocumentRetention';
import { birthYearOf, documentFingerprint, legacyDocumentHash } from './idDocumentRetentionLogic';

// Lazy: index.js loads every module; an eager client costs memory everywhere.
let visionClientInstance: InstanceType<typeof vision.ImageAnnotatorClient> | null = null;
function visionClient(): InstanceType<typeof vision.ImageAnnotatorClient> {
  visionClientInstance ??= new vision.ImageAnnotatorClient();
  return visionClientInstance;
}

/** Consent type recorded by the app's ID consent sheet (recordConsent). */
export const ID_CONSENT_TYPE = 'id_verification';
export const ID_CONSENT_MIN_VERSION = 1;

/** True when consents/{uid}.id_verification is an accepted, current consent. */
export async function hasIdVerificationConsent(uid: string): Promise<boolean> {
  try {
    const c = (await db.collection('consents').doc(uid).get()).data()?.[ID_CONSENT_TYPE];
    return !!c && c.accepted === true && Number(c.version) >= ID_CONSENT_MIN_VERSION;
  } catch (e) {
    logWarning(`hasIdVerificationConsent: read failed for ${uid}`, e);
    return false;
  }
}

/**
 * Grace path switch. While false (default), uploads from app versions that do
 * not show the consent sheet are accepted and flagged consentMissing:true.
 * Set app_config/compliance.idConsentRequired = true once minVersion includes
 * the consent sheet; then submitAgeDocument refuses without a consent.
 */
async function idConsentEnforced(): Promise<boolean> {
  if (process.env.ID_CONSENT_ENFORCED === 'true') return true;
  try {
    return (await db.collection('app_config').doc('compliance').get()).data()?.idConsentRequired === true;
  } catch {
    return false;
  }
}

function documentSalt(): string {
  return process.env.RETENTION_SALT || '';
}

// ============================================================================
// Status model
// ============================================================================

/**
 * `none`      — no birth date on file yet (incomplete onboarding).
 * `declared`  — the user stated a birth date. Enough to use the app.
 * `pending`   — a document was submitted and is awaiting an admin decision.
 * `verified`  — age confirmed. Required to publish in Communities.
 * `rejected`  — the document was unreadable or contradicted the declaration.
 */
export type AgeVerificationStatus =
  | 'none'
  | 'declared'
  | 'pending'
  | 'verified'
  | 'rejected';

export const MINIMUM_AGE = 18;

/** How far the document's birth date may sit from the declared one. */
const DOB_TOLERANCE_DAYS = 1;

/** Confidence at or above which the document is accepted without a human. */
const AUTO_VERIFY_CONFIDENCE = 0.85;

/**
 * Owner policy (Oct 2026): an identity document stays "under review" until an
 * admin decides in the admin panel. Automatic acceptance of high-confidence
 * documents is therefore OFF unless ID_AUTO_VERIFY=true. Automatic REJECTIONS
 * (underage, unreadable, no birth date, document reused) are unchanged.
 */
export function idAutoVerifyEnabled(env: string | undefined = process.env.ID_AUTO_VERIFY): boolean {
  return (env || '').trim().toLowerCase() === 'true';
}

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
export function parseDateOfBirth(text: string): Date | null {
  const candidates: Date[] = [];

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
      if (d) candidates.push(d);
    }
  }

  // 2. Explicitly labelled birth dates win over any loose date on the card.
  const labelled = text.match(
    /(?:date of birth|birth date|born|nascita|geboren|geburtsdatum|naissance|nacimiento|nascimento)[^\d]{0,20}(\d{1,2})[\/.\-\s](\d{1,2}|[A-Za-z]{3,})[\/.\-\s](\d{2,4})/i
  );
  if (labelled) {
    const d = fromParts(labelled[1], labelled[2], labelled[3]);
    if (d) candidates.push(d);
  }

  // 3. ISO.
  for (const m of text.matchAll(/\b(\d{4})-(\d{2})-(\d{2})\b/g)) {
    const d = buildDate(+m[1], +m[2], +m[3]);
    if (d) candidates.push(d);
  }

  // 4. Day-first numeric, the European norm: dd/mm/yyyy, dd.mm.yyyy, dd-mm-yyyy.
  for (const m of text.matchAll(/\b(\d{1,2})[\/.\-](\d{1,2})[\/.\-](\d{4})\b/g)) {
    const d = fromParts(m[1], m[2], m[3]);
    if (d) candidates.push(d);
  }

  // 5. Day with a month name: 14 MAR 1990.
  for (const m of text.matchAll(/\b(\d{1,2})[\s.\-]([A-Za-z]{3,})[\s.\-](\d{4})\b/g)) {
    const d = fromParts(m[1], m[2], m[3]);
    if (d) candidates.push(d);
  }

  // A document carries several dates (issue, expiry, birth). The birth date is
  // the only one that can be decades old, so prefer the EARLIEST plausible one.
  const plausible = candidates.filter(isPlausibleBirthDate);
  if (plausible.length === 0) return null;
  plausible.sort((a, b) => a.getTime() - b.getTime());
  return plausible[0];
}

const MONTHS: Record<string, number> = {
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

function fromParts(day: string, month: string, year: string): Date | null {
  const d = parseInt(day, 10);
  const y = year.length === 2 ? 1900 + parseInt(year, 10) : parseInt(year, 10);
  let m: number;
  if (/^\d+$/.test(month)) {
    m = parseInt(month, 10);
  } else {
    const key = month.slice(0, 3).toLowerCase();
    m = MONTHS[key] ?? NaN;
  }
  return buildDate(y, m, d);
}

/** MRZ dates are YYMMDD with no century. A birth date is always in the past. */
function fromYYMMDD(s: string): Date | null {
  const yy = parseInt(s.slice(0, 2), 10);
  const mm = parseInt(s.slice(2, 4), 10);
  const dd = parseInt(s.slice(4, 6), 10);
  const thisYear = new Date().getUTCFullYear() % 100;
  const century = yy > thisYear ? 1900 : 2000;
  return buildDate(century + yy, mm, dd);
}

function buildDate(y: number, m: number, d: number): Date | null {
  if (!Number.isFinite(y) || !Number.isFinite(m) || !Number.isFinite(d)) return null;
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  const date = new Date(Date.UTC(y, m - 1, d));
  // Rejects 31 February and friends, which JS would otherwise roll over.
  if (date.getUTCMonth() !== m - 1 || date.getUTCDate() !== d) return null;
  return date;
}

function isPlausibleBirthDate(d: Date): boolean {
  const age = ageFrom(d);
  return age >= 13 && age <= 120;
}

export function ageFrom(dob: Date, now: Date = new Date()): number {
  let age = now.getUTCFullYear() - dob.getUTCFullYear();
  const beforeBirthday =
    now.getUTCMonth() < dob.getUTCMonth() ||
    (now.getUTCMonth() === dob.getUTCMonth() && now.getUTCDate() < dob.getUTCDate());
  if (beforeBirthday) age -= 1;
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
export async function requiresIdDocument(uid: string): Promise<boolean> {
  try {
    const user = await admin.auth().getUser(uid);
    const providers = user.providerData.map((p) => p.providerId);
    if (providers.length === 0) return false;
    return providers.every((p) => p === 'phone');
  } catch (e) {
    logWarning(`requiresIdDocument: could not read auth user ${uid}`, e);
    // Fail OPEN for the requirement check: never lock someone out of the app
    // because an auth lookup blipped. Publishing still needs 'verified'.
    return false;
  }
}

/** Writes the status to the profile, plus the denormalised flag rules read. */
async function writeStatus(
  uid: string,
  status: AgeVerificationStatus,
  extra: Record<string, unknown> = {}
): Promise<void> {
  await db.collection('profiles').doc(uid).set(
    {
      ageVerification: {
        status,
        updatedAt: admin.firestore.Timestamp.now(),
        ...extra,
      },
      // Denormalised so security rules cost ONE document read instead of
      // reaching into a nested map on every community write.
      isAgeVerified: status === 'verified',
    },
    { merge: true }
  );
  // P1-4: ID-derived values also live in the owner/admin-only private
  // profile, so they survive the later strip of the public copies.
  const privateAv: Record<string, unknown> = {};
  if (extra.documentHash !== undefined) privateAv.documentHash = extra.documentHash;
  if (extra.documentDateOfBirth !== undefined) privateAv.documentDateOfBirth = extra.documentDateOfBirth;
  if (extra.documentBirthYear !== undefined) privateAv.documentBirthYear = extra.documentBirthYear;
  if (Object.keys(privateAv).length) {
    await db.collection('profiles_private').doc(uid).set({ ageVerification: privateAv }, { merge: true });
  }
}

/** Declared date of birth: private profile first, legacy public field second. */
async function declaredDateOfBirth(uid: string, publicData: Record<string, any> | undefined): Promise<Date | null> {
  let ts: any = null;
  try {
    ts = (await db.collection('profiles_private').doc(uid).get()).data()?.dateOfBirth ?? null;
  } catch (e) {
    logWarning(`declaredDateOfBirth: private read failed for ${uid}`, e);
  }
  ts = ts ?? publicData?.dateOfBirth;
  return ts instanceof admin.firestore.Timestamp ? ts.toDate() : null;
}

/** Deletes the uploaded document. Called on every path, success or failure. */
async function destroyDocument(documentPath: string): Promise<void> {
  try {
    await admin.storage().bucket().file(documentPath).delete();
    logInfo(`ageAssurance: deleted document ${documentPath}`);
  } catch (e) {
    // Worth shouting about: an identity document that outlives its purpose is
    // the whole privacy risk of this feature.
    logError(`ageAssurance: FAILED to delete document ${documentPath}`, e);
  }
}

// ============================================================================
// Callables
// ============================================================================

/**
 * What the client needs to render the verification prompt: current status,
 * whether a document is mandatory for this account, and why.
 */
export const getAgeVerificationState = onCall(
  { memory: '512MiB' },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

    const snap = await db.collection('profiles').doc(uid).get();
    const data = snap.data() ?? {};
    const status: AgeVerificationStatus =
      (data.ageVerification?.status as AgeVerificationStatus) ??
      ((await declaredDateOfBirth(uid, data)) ? 'declared' : 'none');

    return {
      status,
      documentRequired: await requiresIdDocument(uid),
      canPublishToCommunities: status === 'verified',
      rejectionReason: data.ageVerification?.rejectionReason ?? null,
    };
  }
);

/**
 * Reads an uploaded identity document, decides, and deletes the image.
 *
 * `documentPath` is a Storage path (not a URL) so the function can delete it
 * afterwards; the client uploads to a write-only, user-scoped prefix.
 *
 * P2-6: requires the `id_verification` consent (grace path for old apps, see
 * idConsentEnforced); the image is deleted on every decision and kept at most
 * 7 days while a human review is pending.
 */
export const submitAgeDocument = onCall({ memory: '1GiB' }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');

  const documentPath = String(request.data?.documentPath ?? '');
  const documentType = String(request.data?.documentType ?? 'id_card');

  if (!documentPath.startsWith(`age_verification/${uid}/`)) {
    throw new HttpsError(
      'permission-denied',
      'Document must be uploaded to your own verification folder.'
    );
  }

  const consented = await hasIdVerificationConsent(uid);
  if (!consented && (await idConsentEnforced())) {
    await destroyDocument(documentPath);
    throw new HttpsError(
      'failed-precondition',
      'Please review and accept the ID verification notice first.',
      { reason: 'ID_CONSENT_REQUIRED' }
    );
  }
  // GRACE PATH (remove after minVersion): old apps never show the consent
  // sheet; accept, but flag the record for audit.
  const consentMissing = !consented;
  if (consentMissing) logWarning(`submitAgeDocument: no id_verification consent for ${uid} (grace path)`);

  const profileRef = db.collection('profiles').doc(uid);
  const profileSnap = await profileRef.get();
  if (!profileSnap.exists) {
    await destroyDocument(documentPath);
    throw new HttpsError('failed-precondition', 'Complete your profile first.');
  }

  const declaredDob = await declaredDateOfBirth(uid, profileSnap.data());

  await writeStatus(uid, 'pending', { submittedAt: admin.firestore.Timestamp.now() });

  // Move to the server-only prefix BEFORE OCR, so the image is never left
  // under the client's upload prefix. Null = move failed -> OCR the upload
  // and delete it afterwards.
  const keptPath = await retainSubmittedDocument(uid, documentPath, documentType, { consentMissing });
  const ocrPath = keptPath ?? documentPath;
  const releaseUpload = async () => {
    if (!keptPath) await destroyDocument(documentPath);
  };
  /** P2-6: a decision was made -> the image (and any retention copy) goes. */
  const decided = async (verified: boolean, dob: Date | null) => {
    await finalizeIdDocumentDecision(
      uid,
      { verified, method: 'document', birthYear: birthYearOf(dob) },
      keptPath ? [] : [documentPath],
    );
  };

  let text = '';
  try {
    const bucket = admin.storage().bucket().name;
    const [result] = await visionClient().textDetection(
      `gs://${bucket}/${ocrPath}`
    );
    text = result.fullTextAnnotation?.text ?? '';
  } catch (e) {
    logError(`submitAgeDocument: OCR failed for ${uid}`, e);
    await releaseUpload();
    await writeStatus(uid, 'rejected', {
      rejectionReason: 'unreadable',
      reviewedBy: 'system',
    });
    await decided(false, null);
    return { status: 'rejected', reason: 'unreadable' };
  }

  const documentDob = parseDateOfBirth(text);
  const documentNumber = text.match(/\b[A-Z0-9]{6,12}\b/)?.[0] ?? null;

  // Not retained (move failed): the upload has served its purpose.
  await releaseUpload();

  if (!documentDob) {
    await writeStatus(uid, 'rejected', {
      rejectionReason: 'noBirthDateFound',
      reviewedBy: 'system',
    });
    await decided(false, null);
    return { status: 'rejected', reason: 'noBirthDateFound' };
  }

  const age = ageFrom(documentDob);
  if (age < MINIMUM_AGE) {
    await writeStatus(uid, 'rejected', {
      rejectionReason: 'underage',
      reviewedBy: 'system',
      documentBirthYear: birthYearOf(documentDob),
    });
    await decided(false, documentDob);
    logWarning(`submitAgeDocument: underage document for ${uid} (age ${age})`);
    return { status: 'rejected', reason: 'underage' };
  }

  // Does the document agree with what the user told us?
  let matchesDeclaration = true;
  if (declaredDob) {
    const deltaDays =
      Math.abs(documentDob.getTime() - declaredDob.getTime()) / 86_400_000;
    matchesDeclaration = deltaDays <= DOB_TOLERANCE_DAYS;
  }

  // One document, one account. P2-6: a keyed HMAC (RETENTION_SALT), never the
  // number itself; the old unsalted hash is still MATCHED so documents used
  // before this change keep blocking reuse, but never written again.
  const documentHash = documentNumber
    ? documentFingerprint(documentType, documentNumber, documentSalt())
    : null;
  const legacyHash = documentNumber ? legacyDocumentHash(documentType, documentNumber) : null;

  if (documentHash && legacyHash) {
    // Public copy (legacy) AND private copy (P1-4).
    const snaps = await Promise.all(
      ['profiles', 'profiles_private'].map((c) =>
        db.collection(c).where('ageVerification.documentHash', 'in', [documentHash, legacyHash]).limit(2).get()
      )
    );
    const otherAccount = snaps.flatMap((s) => s.docs).find((d) => d.id !== uid);
    if (otherAccount) {
      await writeStatus(uid, 'rejected', {
        rejectionReason: 'documentAlreadyUsed',
        reviewedBy: 'system',
      });
      await decided(false, documentDob);
      logWarning(`submitAgeDocument: document reuse by ${uid}`);
      return { status: 'rejected', reason: 'documentAlreadyUsed' };
    }
  }

  const confidence = computeConfidence({
    hasMrz: /^[A-Z0-9<]{28,44}$/m.test(text.replace(/ /g, '')),
    matchesDeclaration,
    hasDocumentNumber: documentNumber !== null,
  });

  if (idAutoVerifyEnabled() && matchesDeclaration && confidence >= AUTO_VERIFY_CONFIDENCE) {
    await writeStatus(uid, 'verified', {
      method: 'document',
      reviewedBy: 'system',
      confidence,
      documentHash,
      documentBirthYear: birthYearOf(documentDob),
      verifiedAt: admin.firestore.Timestamp.now(),
    });
    await decided(true, documentDob);
    logInfo(`submitAgeDocument: auto-verified ${uid} (confidence ${confidence})`);
    return { status: 'verified' };
  }

  // Anything uncertain goes to a human rather than guessing. The image stays
  // (server-only) for at most 7 days; the reviewer needs the birth date read
  // off the document, which is removed again with the decision.
  if (!keptPath) {
    // Nothing for a reviewer to look at (the move failed and the upload is
    // gone): ask for a new upload instead of queueing a blind review.
    await writeStatus(uid, 'rejected', { rejectionReason: 'reuploadRequired', reviewedBy: 'system' });
    await decided(false, documentDob);
    return { status: 'rejected', reason: 'reuploadRequired' };
  }
  await db.collection('age_verification_queue').doc(uid).set({
    userId: uid,
    submittedAt: admin.firestore.Timestamp.now(),
    documentType,
    documentDateOfBirth: admin.firestore.Timestamp.fromDate(documentDob),
    documentBirthYear: birthYearOf(documentDob),
    declaredDateOfBirth: declaredDob
      ? admin.firestore.Timestamp.fromDate(declaredDob)
      : null,
    matchesDeclaration,
    confidence,
    documentHash,
    status: 'pending',
    ...(consentMissing ? { consentMissing: true } : {}),
  });
  await writeStatus(uid, 'pending', { confidence, documentHash });
  await setIdDocumentStatus(uid, 'pending');
  logInfo(`submitAgeDocument: queued ${uid} for review (confidence ${confidence})`);
  return { status: 'pending' };
});

function computeConfidence(signals: {
  hasMrz: boolean;
  matchesDeclaration: boolean;
  hasDocumentNumber: boolean;
}): number {
  let score = 0.4;
  if (signals.hasMrz) score += 0.35; // machine-readable, check-digited
  if (signals.matchesDeclaration) score += 0.2;
  if (signals.hasDocumentNumber) score += 0.1;
  return Math.min(score, 1);
}

/**
 * Admin decision on a queued submission. Used by the admin panel's
 * verification queue.
 */
export const reviewAgeVerification = onCall({ memory: '512MiB' }, async (request) => {
  const adminUid = request.auth?.uid;
  if (!adminUid) throw new HttpsError('unauthenticated', 'Sign in required.');

  // P1-6: moderation decision -> superAdmin | moderator (was users.isAdmin).
  await requireAdmin(request.auth, MODERATION_ROLES);

  const targetUid = String(request.data?.userId ?? '');
  const approve = request.data?.approve === true;
  const reason = String(request.data?.reason ?? '');
  if (!targetUid) throw new HttpsError('invalid-argument', 'userId is required.');

  const queueRef = db.collection('age_verification_queue').doc(targetUid);
  const queued = await queueRef.get();
  // P2-6: an expired review has no image any more; the user must re-upload.
  if (approve && queued.data()?.status === 'expired') {
    throw new HttpsError(
      'failed-precondition',
      'This submission expired (image deleted after 7 days). Ask the user to upload the document again.'
    );
  }
  const docDob = queued.data()?.documentDateOfBirth;
  const birthYear = docDob instanceof admin.firestore.Timestamp ? docDob.toDate().getUTCFullYear()
    : (typeof queued.data()?.documentBirthYear === 'number' ? queued.data()?.documentBirthYear : null);

  await writeStatus(targetUid, approve ? 'verified' : 'rejected', {
    method: 'document',
    reviewedBy: adminUid,
    reviewedAt: admin.firestore.Timestamp.now(),
    rejectionReason: approve ? null : reason || 'rejectedByReviewer',
    documentHash: queued.data()?.documentHash ?? null,
    ...(birthYear !== null ? { documentBirthYear: birthYear } : {}),
    // P2-6: the full birth date read off the document is not kept after a decision.
    documentDateOfBirth: admin.firestore.FieldValue.delete(),
    ...(approve ? { verifiedAt: admin.firestore.Timestamp.now() } : {}),
  });

  if (queued.exists) {
    await queueRef.set(
      {
        status: approve ? 'approved' : 'rejected',
        reviewedBy: adminUid,
        reviewedAt: admin.firestore.Timestamp.now(),
        reason: reason || null,
        documentDateOfBirth: admin.firestore.FieldValue.delete(),
        documentBirthYear: birthYear,
      },
      { merge: true }
    );
  }

  // P2-6: decision made -> delete the image (+ any retention copy).
  await finalizeIdDocumentDecision(targetUid, { verified: approve, method: 'document', birthYear });

  logInfo(
    `reviewAgeVerification: ${adminUid} ${approve ? 'approved' : 'rejected'} ${targetUid}`
  );
  return { status: approve ? 'verified' : 'rejected' };
});

const IMAGE_DELETED_MESSAGE =
  'The document image was deleted after the verification decision (retention policy). Only the result and birth year are kept.';

/** Largest document image returned inline (callable responses cap at 10 MB). */
const MAX_DOCUMENT_BYTES = 7 * 1024 * 1024;

const isoOf = (v: unknown): string | null =>
  v instanceof admin.firestore.Timestamp ? v.toDate().toISOString() : null;

/**
 * Admin view of ONE user's age verification, for the admin panel's Users page:
 * the status on the profile, the review-queue entry (birth date read off the
 * document vs. the declared one, confidence) and the retained document image
 * itself, returned inline as base64 — no signed URL, so nothing shareable
 * outlives the dialog. Every call that returns an image is written to
 * `admin_audit_log` (who looked at whose identity document, when).
 * Decisions still go through [reviewAgeVerification].
 */
export const getAgeVerificationDetails = onCall({ memory: '512MiB' }, async (request) => {
  const adminUid = request.auth?.uid;
  if (!adminUid) throw new HttpsError('unauthenticated', 'Sign in required.');
  // P1-6: returns the identity-document image -> superAdmin ONLY.
  await requireAdmin(request.auth, SUPER_ADMIN_ONLY);
  const targetUid = String(request.data?.userId ?? '');
  if (!targetUid) throw new HttpsError('invalid-argument', 'userId is required.');

  const [profileSnap, queueSnap, indexSnap] = await Promise.all([
    db.collection('profiles').doc(targetUid).get(),
    db.collection('age_verification_queue').doc(targetUid).get(),
    db.collection('id_documents').doc(targetUid).get(),
  ]);
  const profile = profileSnap.data() ?? {};
  const av = (profile.ageVerification ?? {}) as Record<string, any>;
  const queue = queueSnap.data() ?? null;
  const index = indexSnap.data() ?? null;

  let document: { contentType: string; dataBase64: string; uploadedAt: string | null } | null = null;
  let documentError: string | null = null;
  const path = typeof index?.currentPath === 'string' ? index.currentPath : null;
  if (path) {
    try {
      const file = admin.storage().bucket().file(path);
      const [meta] = await file.getMetadata();
      if (Number(meta.size ?? 0) > MAX_DOCUMENT_BYTES) {
        documentError = 'Document is too large to display.';
      } else {
        const [buf] = await file.download();
        document = {
          contentType: String(meta.contentType || 'image/jpeg'),
          dataBase64: buf.toString('base64'),
          uploadedAt: isoOf(index?.uploadedAt),
        };
        await db.collection('admin_audit_log').add({
          adminId: adminUid,
          adminEmail: request.auth?.token?.email ?? 'unknown',
          action: 'view_id_document',
          targetType: 'user',
          targetId: targetUid,
          details: { path },
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // P2-6: a 404 means the image was already deleted (decision or 7-day purge).
      const notFound = (e as { code?: unknown })?.code === 404;
      if (!notFound) logError(`getAgeVerificationDetails: reading ${path} failed`, e);
      documentError = notFound
        ? IMAGE_DELETED_MESSAGE
        : 'The document file could not be read.';
    }
  } else if (index && (index.imageDeleted === true || index.decidedAt || index.status === 'expired')) {
    // P2-6: images are deleted once a decision is made / after 7 days pending.
    documentError = index.status === 'expired'
      ? 'The document image was deleted after 7 days without a decision. The user must upload it again.'
      : IMAGE_DELETED_MESSAGE;
  }
  const imageDeleted = document === null && (
    index?.imageDeleted === true || !!index?.decidedAt || index?.status === 'expired' || documentError === IMAGE_DELETED_MESSAGE
  );

  const status: AgeVerificationStatus =
    (av.status as AgeVerificationStatus) ?? (profile.dateOfBirth ? 'declared' : 'none');
  return {
    userId: targetUid,
    status,
    isAgeVerified: profile.isAgeVerified === true,
    documentRequired: await requiresIdDocument(targetUid),
    method: av.method ?? null,
    confidence: typeof av.confidence === 'number' ? av.confidence : (queue?.confidence ?? null),
    rejectionReason: av.rejectionReason ?? null,
    reviewedBy: av.reviewedBy ?? null,
    reviewedAt: isoOf(av.reviewedAt),
    verifiedAt: isoOf(av.verifiedAt),
    declaredDateOfBirth: isoOf(profile.dateOfBirth),
    documentDateOfBirth: isoOf(av.documentDateOfBirth) ?? isoOf(queue?.documentDateOfBirth),
    // P2-6: after a decision only the birth year is kept.
    documentBirthYear: typeof av.documentBirthYear === 'number' ? av.documentBirthYear
      : (typeof queue?.documentBirthYear === 'number' ? queue.documentBirthYear
        : (typeof index?.birthYear === 'number' ? index.birthYear : null)),
    decidedAt: isoOf(index?.decidedAt),
    imageDeleted,
    consentMissing: index?.consentMissing === true || queue?.consentMissing === true,
    documentType: queue?.documentType ?? index?.documentType ?? null,
    matchesDeclaration: typeof queue?.matchesDeclaration === 'boolean' ? queue.matchesDeclaration : null,
    queueStatus: queue?.status ?? null,
    submittedAt: isoOf(queue?.submittedAt) ?? isoOf(av.submittedAt),
    document,
    documentError,
  };
});

/**
 * Backfills `ageVerification.status = 'declared'` for existing users who have a
 * birth date but no status yet, so the app does not show every existing user a
 * verification prompt on first launch of v4.0.0.
 */
export const backfillDeclaredAge = onCall({ memory: '1GiB' }, async (request) => {
  const adminUid = request.auth?.uid;
  if (!adminUid) throw new HttpsError('unauthenticated', 'Sign in required.');
  await requireAdmin(request.auth, SUPER_ADMIN_ONLY); // P1-6

  const snap = await db.collection('profiles').limit(5000).get();
  let updated = 0;
  let batch = db.batch();
  let queued = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.ageVerification?.status) continue;
    if (!data.dateOfBirth) continue;
    batch.set(
      doc.ref,
      {
        ageVerification: {
          status: 'declared',
          updatedAt: admin.firestore.Timestamp.now(),
        },
        isAgeVerified: false,
      },
      { merge: true }
    );
    updated += 1;
    queued += 1;
    if (queued >= 400) {
      await batch.commit();
      batch = db.batch();
      queued = 0;
    }
  }
  if (queued > 0) await batch.commit();

  logInfo(`backfillDeclaredAge: ${updated} profiles set to 'declared'`);
  return { updated, scanned: snap.size };
});
