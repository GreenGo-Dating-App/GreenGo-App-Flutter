/**
 * Neutral age gate, interim (audit H-21; plan P1-1 "Age entry"; COPPA,
 * Brazil ECA Digital, Apple / Google minimum-age rules).
 *
 *  - declareAge (callable): the onboarding date-of-birth step sends the date
 *    the user entered. Under 18 -> the account is marked in the server-only
 *    `age_gate/{uid}` (and `age_gate_emails/{sha256(email)}`), and every later
 *    call answers "blocked" whatever date is sent, so entering another date
 *    does not get past the gate. The minor's full date of birth is NOT stored
 *    (only the age at the time of the block).
 *  - applyProfileAgeGate: backstop for clients that write the profile
 *    directly (old app versions, the web build). Called from the existing
 *    `profiles/{uid}` onWrite trigger (reverseGeocodeProfileLocation) so no new
 *    trigger runs on this hot collection. Only acts on profile CREATION or a
 *    CHANGED dateOfBirth: a profile whose DOB says under 18, or whose account
 *    is already in `age_gate`, gets `accountStatus: 'age_blocked'` (hidden from
 *    discovery, search, map: they all require 'active'). Profiles without a
 *    DOB, and existing adult profiles, are never touched.
 */

import { onCall } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import '../shared/firebaseAdmin';
import { AppError, handleError } from '../shared/utils';
import { monitored } from '../shared/monitoring';

const db = () => admin.firestore();
const TS = () => admin.firestore.Timestamp.now();

export const AGE_GATE = 'age_gate';
export const AGE_GATE_EMAILS = 'age_gate_emails';
export const MIN_AGE = 18;
export const AGE_BLOCKED_STATUS = 'age_blocked';

const emailHash = (email: string) =>
  crypto.createHash('sha256').update(email.trim().toLowerCase(), 'utf8').digest('hex');

/** Whole years between [dob] and [now] (UTC calendar). */
export function ageOn(dob: Date, now = new Date()): number {
  let age = now.getUTCFullYear() - dob.getUTCFullYear();
  const m = now.getUTCMonth() - dob.getUTCMonth();
  if (m < 0 || (m === 0 && now.getUTCDate() < dob.getUTCDate())) age--;
  return age;
}

/** Strict 'YYYY-MM-DD' (also accepts a full ISO timestamp) -> Date (UTC). */
export function parseDob(v: unknown): Date | null {
  if (typeof v !== 'string') return null;
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(v.trim());
  if (!m) return null;
  const [y, mo, d] = [Number(m[1]), Number(m[2]), Number(m[3])];
  const date = new Date(Date.UTC(y, mo - 1, d));
  if (date.getUTCFullYear() !== y || date.getUTCMonth() !== mo - 1 || date.getUTCDate() !== d) return null;
  return date;
}

/** A profile's dateOfBirth (Timestamp, Date, ISO string or millis) -> Date. */
export function profileDob(v: unknown): Date | null {
  if (!v) return null;
  if (v instanceof admin.firestore.Timestamp) return v.toDate();
  if (v instanceof Date) return isNaN(v.getTime()) ? null : v;
  if (typeof (v as any)?.toDate === 'function') return (v as any).toDate();
  if (typeof v === 'number') return new Date(v);
  if (typeof v === 'string') {
    const d = new Date(v);
    return isNaN(d.getTime()) ? null : d;
  }
  return null;
}

export async function isAgeBlocked(uid: string, email?: string | null): Promise<boolean> {
  const reads = [db().collection(AGE_GATE).doc(uid).get()];
  if (email) reads.push(db().collection(AGE_GATE_EMAILS).doc(emailHash(email)).get());
  const snaps = await Promise.all(reads);
  return snaps.some((s) => s.exists && s.data()?.blocked === true);
}

/** Marks [uid] (and its email) as under-age. Idempotent. */
export async function markAgeBlocked(uid: string, email: string | null | undefined, age: number | null, source: string) {
  const batch = db().batch();
  batch.set(db().collection(AGE_GATE).doc(uid), {
    blocked: true,
    reason: 'under_18',
    ageAtBlock: age,
    source,
    blockedAt: TS(),
    attempts: admin.firestore.FieldValue.increment(1),
  }, { merge: true });
  if (email) {
    batch.set(db().collection(AGE_GATE_EMAILS).doc(emailHash(email)), { blocked: true, blockedAt: TS() }, { merge: true });
  }
  await batch.commit();
}

export async function handleDeclareAge(request: any) {
  const uid = request?.auth?.uid as string | undefined;
  if (!uid) throw new AppError('UNAUTHENTICATED', 'User must be authenticated', 401);
  const email = (request.auth?.token?.email as string | undefined) ?? null;
  const dob = parseDob(request.data?.dob);
  const now = new Date();
  if (!dob || dob.getTime() > now.getTime() || dob.getUTCFullYear() < 1900) {
    throw new AppError('INVALID_ARGUMENT', 'Invalid date of birth', 400);
  }

  if (await isAgeBlocked(uid, email)) {
    await db().collection(AGE_GATE).doc(uid).set({
      blocked: true, attempts: admin.firestore.FieldValue.increment(1), lastAttemptAt: TS(),
    }, { merge: true });
    return { success: true, allowed: false, reason: 'AGE_BLOCKED' };
  }

  const age = ageOn(dob, now);
  if (age < MIN_AGE) {
    await markAgeBlocked(uid, email, age, 'declareAge');
    // If onboarding already wrote a profile, hide it now.
    const profile = db().collection('profiles').doc(uid);
    await db().runTransaction(async (tx) => {
      const p = await tx.get(profile);
      if (p.exists) tx.update(profile, { accountStatus: AGE_BLOCKED_STATUS, ageBlockedAt: TS() });
    });
    return { success: true, allowed: false, reason: 'UNDER_18' };
  }
  return { success: true, allowed: true };
}

export const declareAge = onCall(
  { memory: '512MiB', timeoutSeconds: 30 },
  monitored('declareAge', async (request: any) => {
    try {
      return await handleDeclareAge(request);
    } catch (e) {
      throw handleError(e);
    }
  }),
);

/**
 * Trigger backstop (see header). Returns true when it blocked the profile.
 * Cheap on the hot path: one field comparison on every unrelated write.
 */
export async function applyProfileAgeGate(
  uid: string,
  before: FirebaseFirestore.DocumentData | null | undefined,
  after: FirebaseFirestore.DocumentData | null | undefined,
  ref: FirebaseFirestore.DocumentReference,
): Promise<boolean> {
  if (!after || after.accountStatus === AGE_BLOCKED_STATUS) return false;
  const created = !before;
  const dobAfter = profileDob(after.dateOfBirth);
  const dobBefore = before ? profileDob(before.dateOfBirth) : null;
  const dobChanged = !!dobAfter && (!dobBefore || dobBefore.getTime() !== dobAfter.getTime());
  if (!created && !dobChanged) return false;

  const age = dobAfter ? ageOn(dobAfter) : null;
  let block = age !== null && age < MIN_AGE;
  if (!block && created) block = await isAgeBlocked(uid, typeof after.email === 'string' ? after.email : null);
  if (!block) return false;

  if (age !== null && age < MIN_AGE) {
    await markAgeBlocked(uid, typeof after.email === 'string' ? after.email : null, age, 'profile_trigger');
  }
  await ref.update({ accountStatus: AGE_BLOCKED_STATUS, ageBlockedAt: TS() });
  return true;
}
