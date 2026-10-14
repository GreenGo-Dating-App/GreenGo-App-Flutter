/// Shared-link guests (people who booked an event / experience from a shared
/// link WITHOUT a GreenGo account, functions/src/guest) appear in attendee
/// lists, the door and booking lists under a GUEST KEY instead of a uid:
/// `guest_` + 40 hex characters (functions/src/shared/guestIdentity.ts).
/// A guest has no profile, so it is never resolved, linked or messaged.
final RegExp _guestKeyRe = RegExp(r'^guest_[0-9a-f]{40}$');

/// True for a shared-link guest's id (never a real Firebase Auth uid).
bool isGuestUserId(String? id) => id != null && _guestKeyRe.hasMatch(id);
