/// Shared-link guests (people who booked an event / experience from a shared
/// link WITHOUT a GreenGo account, functions/src/guest) appear in attendee
/// lists, the door and booking lists under a GUEST KEY instead of a uid:
/// `guest_` + 40 hex characters (functions/src/shared/guestIdentity.ts).
/// A guest has no profile, so it is never resolved, linked or messaged.
final RegExp _guestKeyRe = RegExp(r'^guest_[0-9a-f]{40}$');

/// True for a shared-link guest's id (never a real Firebase Auth uid).
bool isGuestUserId(String? id) => id != null && _guestKeyRe.hasMatch(id);

/// Account deletion (functions/src/auth/accountDeletion.ts) replaces a
/// deleted user's id with `deleted_user` in shared records (bookings,
/// conversations) and with a 64-hex pseudonym in purchase records kept for
/// bookkeeping (privacy policy 15.2 e). Neither has a profile.
const String kDeletedUserId = 'deleted_user';
final RegExp _pseudonymRe = RegExp(r'^[0-9a-f]{64}$');

/// True for the id of a user who deleted their account.
bool isDeletedUserId(String? id) =>
    id != null && (id == kDeletedUserId || _pseudonymRe.hasMatch(id));
