import 'message.dart';

/// One page of a chat's messages: the live newest window or an older page
/// fetched on scroll (owner 2026-10-24: cache first, then only the newest
/// 20, then older pages of 20 as the user scrolls up).
class MessagePage {
  const MessagePage({
    required this.messages,
    required this.hasMore,
    this.cursor,
    this.fromCache = false,
  });

  /// Messages visible to the user, newest first (hidden ones filtered out).
  final List<Message> messages;

  /// The query filled its limit, so older messages may exist.
  final bool hasMore;

  /// `sentAt` of the oldest document READ (hidden ones included): the next
  /// older page starts after it, so a page of deleted-for-me messages never
  /// stalls the scroll.
  final DateTime? cursor;

  /// Answered by the local Firestore cache (may be partial or empty).
  final bool fromCache;
}
