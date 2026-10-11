/**
 * Owner rule (2026-10-11): "to participate in an event or experience, the
 * user must have the Base membership". Any ACTIVE paid tier (Silver / Gold /
 * Platinum) or TEST counts too - the same "Base or better" rule as 1:1
 * messaging ([hasBaseAccess]).
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
import { hasBaseAccess } from './effectiveTier';

export const BASE_MEMBERSHIP_REQUIRED = 'base_membership_required';

/** True when `profile` may join events / book experiences right now. */
export function canParticipate(
  profile: Record<string, any> | null | undefined,
  now: Date = new Date(),
): boolean {
  return hasBaseAccess(profile, now);
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
