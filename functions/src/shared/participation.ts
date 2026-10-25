/**
 * Owner rule (2026-10-25, replaces the Base-only rule of 2026-10-11): the
 * FREE version may participate in events and experiences too. Every
 * participation path still calls [assertCanParticipate] (an existing
 * account) and [assertPhoneVerified]; the refusal code is kept for old apps.
 *
 * "Participate" = becoming an attendee of someone else's event or experience:
 * RSVP going / waitlist (Firestore rules `canParticipate`), ticket checkouts
 * (createTicketCheckout, kind 'event'), experience bookings / booking requests
 * (createBooking). NOT gated: browsing, 'interested', organizers / hosts on
 * their own listings, cancelling, check-in of existing attendees, refunds,
 * paying an EXISTING confirmed booking (the booking was the participation).
 * Existing attendees / bookings are never removed retroactively.
 *
 * Refusal shape (the app maps it to the Base-membership dialog):
 *   HttpsError('failed-precondition', 'base_membership_required',
 *              { code: 'base_membership_required' })
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';

export const BASE_MEMBERSHIP_REQUIRED = 'base_membership_required';

/**
 * True when `profile` may join events / book experiences right now.
 * Owner rule 2026-10-25: the FREE version may join events and book
 * experiences too, so any existing account may participate (the verified
 * phone is still required: [assertPhoneVerified]). [now] is kept for callers.
 */
export function canParticipate(
  profile: Record<string, any> | null | undefined,
  now: Date = new Date(),
): boolean {
  void now;
  return !!profile;
}

/** The refusal every participation path throws. */
export function baseMembershipRequired(): HttpsError {
  return new HttpsError('failed-precondition', BASE_MEMBERSHIP_REQUIRED, {
    code: BASE_MEMBERSHIP_REQUIRED,
  });
}

/** Throws [baseMembershipRequired] unless `profile` may participate. */
export function assertCanParticipate(
  profile: Record<string, any> | null | undefined,
  now: Date = new Date(),
): void {
  if (!canParticipate(profile, now)) throw baseMembershipRequired();
}

/** Reads `profiles/{uid}` and applies [assertCanParticipate]. */
export async function assertUserCanParticipate(uid: string, now: Date = new Date()): Promise<void> {
  const snap = await admin.firestore().collection('profiles').doc(uid).get();
  assertCanParticipate(snap.data(), now);
}

/**
 * Owner rule (2026-10-17): joining / booking / buying tickets / creating
 * events and experiences / enabling a business account need a VERIFIED phone
 * number on the account: the Firebase Auth ID-token claim `phone_number`
 * (set once an SMS-verified phone credential is linked; the app refreshes the
 * token after linking). Rules mirror: `phoneVerified()`. Refusal shape:
 *   HttpsError('failed-precondition', 'phone_verification_required',
 *              { code: 'phone_verification_required' })
 */
export const PHONE_VERIFICATION_REQUIRED = 'phone_verification_required';

export function phoneVerificationRequired(): HttpsError {
  return new HttpsError('failed-precondition', PHONE_VERIFICATION_REQUIRED, {
    code: PHONE_VERIFICATION_REQUIRED,
  });
}

/** True when the caller's ID token carries a verified phone number. */
export function tokenHasVerifiedPhone(token: Record<string, unknown> | null | undefined): boolean {
  return !!token && typeof token.phone_number === 'string' && token.phone_number.length > 0;
}

/**
 * Who needs the phone (owner decision 2026-10-17, final): ONLY accounts
 * created on/after 16 Oct 2026 00:00 UTC. Older accounts are never required
 * nor blocked. Mirror: kPhoneRequiredForAccountsCreatedFrom in
 * lib/core/constants/phone_verification_countries.dart (sync test). Rules
 * cannot see the creation time: the onAuthUserCreatedPhoneRequired trigger
 * writes the server-only marker phone_required/{uid} for new accounts and the
 * rules check `!exists(phone_required/uid) || phone_number claim`.
 */
export const PHONE_REQUIRED_FOR_ACCOUNTS_CREATED_FROM = '2026-10-16T00:00:00Z';
export const PHONE_REQUIRED = 'phone_required';

/** Pure: does an account created at [createdAtMs] need a verified phone? */
export function phoneRequiredFor(createdAtMs: number | null | undefined): boolean {
  return typeof createdAtMs === 'number' && createdAtMs >= Date.parse(PHONE_REQUIRED_FOR_ACCOUNTS_CREATED_FROM);
}

/** Auth creation time of [uid] (ms), or null when unknown. */
export async function authCreatedAtMs(uid: string): Promise<number | null> {
  try {
    const u = await admin.auth().getUser(uid);
    const t = Date.parse(u.metadata.creationTime);
    return Number.isFinite(t) ? t : null;
  } catch {
    return null;
  }
}

/**
 * Throws [phoneVerificationRequired] when the token has no `phone_number`
 * and the account was created on/after the cutoff. The Auth lookup happens
 * only for callers WITHOUT a phone.
 */
export async function assertPhoneVerified(
  token: Record<string, unknown> | null | undefined,
  uid: string,
  createdAt: (uid: string) => Promise<number | null> = authCreatedAtMs,
): Promise<void> {
  if (tokenHasVerifiedPhone(token)) return;
  if (phoneRequiredFor(await createdAt(uid))) throw phoneVerificationRequired();
}

/** The caller satisfies the identity requirement: a verified phone, or an
 *  account created before the cutoff (never required). */
export async function identityRequirementMet(
  token: Record<string, unknown> | null | undefined,
  uid: string,
  createdAt: (uid: string) => Promise<number | null> = authCreatedAtMs,
): Promise<boolean> {
  if (tokenHasVerifiedPhone(token)) return true;
  return !phoneRequiredFor(await createdAt(uid));
}

/** Same as [identityRequirementMet] for another user (e.g. the host), from
 *  the Auth user record: a verified phone, or created before the cutoff. */
export async function identityRequirementMetForUid(uid: string): Promise<boolean> {
  try {
    const u = await admin.auth().getUser(uid);
    if (typeof u.phoneNumber === 'string' && u.phoneNumber.length > 0) return true;
    return !phoneRequiredFor(Date.parse(u.metadata.creationTime));
  } catch {
    return false;
  }
}
