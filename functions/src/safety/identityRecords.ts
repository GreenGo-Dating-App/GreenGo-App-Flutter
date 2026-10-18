/**
 * Optional ID-document details, stored ENCRYPTED for authority requests.
 *
 * identity_records/{uid} is server-only (rules: no client read/write at all).
 * The plaintext fields exist only in memory inside these callables and are
 * never logged. See docs/safety/identity-records.md for the contract.
 *
 *  submitIdentityDetails        owner      store a PENDING encrypted record
 *  adminGetIdentityDetailsForReview  moderator  decrypt for the reviewer (audited)
 *  adminConfirmIdentityDetails  moderator  approve (re-encrypt confirmed) / reject (delete)
 *  adminRevealIdentityRecord    superAdmin legal basis + reference, audit FIRST
 *  sweepIdentityRecords         daily      retention (legal holds block deletion)
 */
import * as admin from 'firebase-admin';
import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { defineSecret } from 'firebase-functions/params';
import '../shared/firebaseAdmin';
import { requireAdmin, MODERATION_ROLES, SUPER_ADMIN_ONLY } from '../shared/adminAuth';
import { activeHoldsFor } from './takedowns/legalHold';
import {
  decryptIdentity,
  encryptIdentity,
  EncryptedBlob,
  IdentityFields,
  normalizeIdentityFields,
  parseKeyring,
} from './identityRecordCrypto';
import {
  IDENTITY_ACCESS_LOG,
  IDENTITY_RATE_LIMITS,
  IDENTITY_RECORDS,
  isIdentitySource,
  onAccountDeletion,
  rateLimitStep,
  PENDING_MAX_AGE_MS,
  REVEAL_LIMIT,
  SUBMIT_LIMIT,
  sweepDecision,
  validateRevealRequest,
} from './identityRecordsLogic';

export const ID_DATA_KEY = defineSecret('ID_DATA_KEY');
const CALL = { memory: '512MiB' as const, secrets: [ID_DATA_KEY] };

const db = () => admin.firestore();
const now = () => admin.firestore.Timestamp.now();

/** Overridable in tests. */
export const deps = {
  keyValue: (): string | undefined => process.env.ID_DATA_KEY,
  requireAdmin,
  activeHoldsFor,
};

function ring() {
  try {
    return parseKeyring(deps.keyValue());
  } catch {
    throw new HttpsError('failed-precondition', 'identity_key_unavailable');
  }
}

function fieldsOrThrow(input: unknown): IdentityFields {
  try {
    return normalizeIdentityFields(input);
  } catch (e: any) {
    throw new HttpsError('invalid-argument', String(e?.message || 'invalid_fields'), {
      code: String(e?.message || 'invalid_fields'),
    });
  }
}

/** Fixed-window Firestore counter; throws resource-exhausted when over. */
async function takeRateLimit(key: string, limit: { cap: number; windowMs: number }): Promise<void> {
  const ref = db().collection(IDENTITY_RATE_LIMITS).doc(key);
  const ok = await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const r = rateLimitStep(snap.data() as any, limit, Date.now());
    if (r.allowed) {
      tx.set(ref, {
        ...r.next,
        expireAt: admin.firestore.Timestamp.fromMillis(r.next.windowStartMs + limit.windowMs),
      });
    }
    return r.allowed;
  });
  if (!ok) throw new HttpsError('resource-exhausted', 'rate_limited', { code: 'rate_limited' });
}

function uidArg(data: any): string {
  const uid = typeof data?.uid === 'string' ? data.uid.trim() : '';
  if (!uid || uid.length > 128 || uid.includes('/')) {
    throw new HttpsError('invalid-argument', 'invalid_uid');
  }
  return uid;
}

// ── Owner ───────────────────────────────────────────────────────────────────

export async function handleSubmit(request: CallableRequest<any>) {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
  const source = request.data?.source;
  if (!isIdentitySource(source)) throw new HttpsError('invalid-argument', 'invalid_source');
  const fields = fieldsOrThrow(request.data?.fields);
  await takeRateLimit(`submit_${uid}`, SUBMIT_LIMIT);
  const ref = db().collection(IDENTITY_RECORDS).doc(uid);
  const existing = (await ref.get()).data();
  // A confirmed record is replaced only through a new admin review.
  const enc = encryptIdentity(fields, uid, ring());
  if (existing?.status === 'verified') {
    await ref.set({ pending: { enc, source, submittedAt: now() } }, { merge: true });
  } else {
    await ref.set({
      uid, status: 'pending', source, enc, submittedAt: now(), retainUntil: null,
      // Single-field index for the sweep (a pending record nobody reviewed).
      pendingExpiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + PENDING_MAX_AGE_MS),
    });
  }
  return { ok: true };
}

export const submitIdentityDetails = onCall(CALL, handleSubmit);

// ── Reviewer ────────────────────────────────────────────────────────────────

export async function handleGetForReview(request: CallableRequest<any>) {
  const caller = await deps.requireAdmin(request.auth, MODERATION_ROLES);
  const uid = uidArg(request.data);
  const snap = await db().collection(IDENTITY_RECORDS).doc(uid).get();
  const rec = snap.data();
  if (!rec) return { found: false };
  const blob: EncryptedBlob | undefined = rec.pending?.enc ?? rec.enc;
  if (!blob) return { found: false };
  await db().collection('admin_audit_log').add({
    adminId: caller.uid,
    action: 'view_identity_details_for_review',
    targetType: 'user',
    targetId: uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  const fields = decryptIdentity(blob, uid, ring());
  return {
    found: true,
    status: rec.pending ? 'pending' : rec.status,
    source: rec.pending?.source ?? rec.source ?? null,
    fields,
  };
}

export const adminGetIdentityDetailsForReview = onCall(CALL, handleGetForReview);

export async function handleConfirm(request: CallableRequest<any>) {
  const caller = await deps.requireAdmin(request.auth, MODERATION_ROLES);
  const uid = uidArg(request.data);
  const decision = request.data?.decision;
  if (decision !== 'approve' && decision !== 'reject') {
    throw new HttpsError('invalid-argument', 'invalid_decision');
  }
  const ref = db().collection(IDENTITY_RECORDS).doc(uid);
  const rec = (await ref.get()).data();
  if (!rec) return { ok: true, stored: false };
  if (decision === 'reject') {
    // A rejected re-submission never removes an earlier confirmed record.
    if (rec.status === 'verified' && rec.pending) {
      await ref.update({ pending: admin.firestore.FieldValue.delete() });
    } else if (rec.status !== 'verified') {
      await ref.delete();
    }
    return { ok: true, stored: false };
  }
  const keyring = ring();
  const submitted: EncryptedBlob = rec.pending?.enc ?? rec.enc;
  // The reviewer's corrections win; otherwise the user's entry is confirmed.
  const fields = request.data?.fields != null
    ? fieldsOrThrow(request.data.fields)
    : decryptIdentity(submitted, uid, keyring);
  const enc = encryptIdentity(fields, uid, keyring);
  await ref.set({
    uid,
    status: 'verified',
    source: rec.pending?.source ?? rec.source ?? null,
    enc,
    keyVersion: enc.keyVersion,
    docType: fields.docType,
    issuingCountry: fields.issuingCountry,
    verifiedAt: now(),
    reviewedBy: caller.uid,
    retainUntil: null,
    submittedAt: rec.pending?.submittedAt ?? rec.submittedAt ?? null,
  });
  return { ok: true, stored: true };
}

export const adminConfirmIdentityDetails = onCall(CALL, handleConfirm);

// ── Authorities ─────────────────────────────────────────────────────────────

export async function handleReveal(request: CallableRequest<any>) {
  const caller = await deps.requireAdmin(request.auth, SUPER_ADMIN_ONLY);
  const v = validateRevealRequest(request.data);
  if (typeof v === 'string') throw new HttpsError('invalid-argument', v, { code: v });
  await takeRateLimit(`reveal_${caller.uid}`, REVEAL_LIMIT);
  const ref = db().collection(IDENTITY_RECORDS).doc(v.uid);
  const rec = (await ref.get()).data();
  if (!rec || rec.status !== 'verified' || !rec.enc) {
    throw new HttpsError('not-found', 'no_identity_record');
  }
  // Audit BEFORE any plaintext exists: a failed audit write means no reveal.
  await db().collection(IDENTITY_ACCESS_LOG).add({
    adminUid: caller.uid,
    adminEmail: request.auth?.token?.email ?? null,
    subjectUid: v.uid,
    legalBasis: v.legalBasis,
    reference: v.reference,
    at: admin.firestore.FieldValue.serverTimestamp(),
  });
  const fields = decryptIdentity(rec.enc, v.uid, ring());
  return {
    uid: v.uid,
    fields,
    docType: rec.docType ?? fields.docType,
    issuingCountry: rec.issuingCountry ?? fields.issuingCountry,
    verifiedAt: rec.verifiedAt?.toMillis?.() ?? null,
    reviewedBy: rec.reviewedBy ?? null,
    retainUntil: rec.retainUntil?.toMillis?.() ?? null,
  };
}

export const adminRevealIdentityRecord = onCall(CALL, handleReveal);

// ── Retention ───────────────────────────────────────────────────────────────

/** Account deletion: pending -> delete; verified -> retainUntil = +6 months. */
export async function retainIdentityRecordOnAccountDeletion(uid: string, nowMs = Date.now()): Promise<void> {
  const ref = db().collection(IDENTITY_RECORDS).doc(uid);
  const snap = await ref.get();
  const d = onAccountDeletion(snap.data(), nowMs);
  if (d.action === 'delete') await ref.delete();
  if (d.action === 'retain') {
    await ref.update({
      retainUntil: admin.firestore.Timestamp.fromMillis(d.retainUntilMs),
      accountDeletedAt: admin.firestore.Timestamp.fromMillis(nowMs),
      pending: admin.firestore.FieldValue.delete(),
    });
  }
}

const SWEEP_PAGE = 300;
const SWEEP_MAX_PAGES = 20;

export async function runIdentitySweep(nowMs = Date.now()): Promise<{ deleted: number; held: number }> {
  let deleted = 0;
  let held = 0;
  const handle = async (docs: FirebaseFirestore.QueryDocumentSnapshot[]) => {
    for (const doc of docs) {
      const rec = doc.data();
      const first = sweepDecision(rec, nowMs, false);
      if (first === 'keep') continue;
      const holds = await deps.activeHoldsFor(doc.id, nowMs);
      const d = sweepDecision(rec, nowMs, holds.length > 0);
      if (d === 'delete') {
        await doc.ref.delete();
        deleted++;
      } else if (d === 'held') {
        held++;
      }
    }
  };
  const nowTs = admin.firestore.Timestamp.fromMillis(nowMs);
  // 1) expired retention (account deleted + 6 months).
  for (let page = 0; page < SWEEP_MAX_PAGES; page++) {
    const s = await db().collection(IDENTITY_RECORDS)
      .where('retainUntil', '<=', nowTs).orderBy('retainUntil').limit(SWEEP_PAGE).get();
    const before = deleted;
    await handle(s.docs);
    if (s.size < SWEEP_PAGE || deleted === before) break;
  }
  // 2) pending submissions nobody reviewed within 30 days.
  for (let page = 0; page < SWEEP_MAX_PAGES; page++) {
    const before = deleted;
    const s = await db().collection(IDENTITY_RECORDS)
      .where('pendingExpiresAt', '<=', nowTs).orderBy('pendingExpiresAt').limit(SWEEP_PAGE).get();
    await handle(s.docs);
    if (s.size < SWEEP_PAGE || deleted === before) break;
  }
  console.log(`identityRecords sweep: deleted=${deleted} held=${held}`);
  return { deleted, held };
}

export const sweepIdentityRecords = onSchedule(
  { schedule: '50 3 * * *', timeZone: 'UTC', memory: '512MiB', timeoutSeconds: 540 },
  async () => {
    await runIdentitySweep(Date.now());
    // Banned phone hashes past their 5-year retention (phoneVerification.ts).
    const { runBannedPhoneSweep } = await import('./phoneVerification');
    await runBannedPhoneSweep(Date.now());
  },
);
