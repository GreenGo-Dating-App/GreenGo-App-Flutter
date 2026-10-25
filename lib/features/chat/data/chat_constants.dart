// Shared chat constants.

/// Maximum allowed length (in characters) for any chat message body.
///
/// Enforced defense-in-depth: it caps the composer input widgets (so typing
/// and paste are limited) AND is re-checked in every send path before writing
/// to Firestore (so pasted / programmatic sends can never exceed it). Applies
/// uniformly to 1:1 exchanges, group / community chats, and event chats.
const int kMaxMessageLength = 4096;

/// Messages per chat page (1:1 and group): the live window of the newest
/// messages, and each older page loaded as the user scrolls up. Owner
/// 2026-10-24: "load only the last 20 messages, then paginate on scroll".
const int kChatPageSize = 20;
