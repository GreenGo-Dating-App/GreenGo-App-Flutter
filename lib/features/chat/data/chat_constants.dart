// Shared chat constants.

/// Maximum allowed length (in characters) for any chat message body.
///
/// Enforced defense-in-depth: it caps the composer input widgets (so typing
/// and paste are limited) AND is re-checked in every send path before writing
/// to Firestore (so pasted / programmatic sends can never exceed it). Applies
/// uniformly to 1:1 exchanges, group / community chats, and event chats.
const int kMaxMessageLength = 4096;
