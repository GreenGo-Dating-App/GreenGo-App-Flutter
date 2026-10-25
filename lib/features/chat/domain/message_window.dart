import 'entities/message.dart';
import 'entities/message_page.dart';

/// The messages a chat screen shows (1:1 and group), newest first:
/// a locally cached copy until the first live snapshot, then the LIVE window
/// of the newest messages + the older pages loaded on scroll.
///
/// Only the window is listened to; older pages are read once and kept here,
/// so scrolling back never re-reads what is already loaded and the listener
/// never grows. Owner 2026-10-24: "we read what is cached first inside the
/// app, then load only the last 20 messages, and if the user scrolls we load
/// other messages as pagination".
class MessageWindow {
  /// The current live window (newest first).
  List<Message> _live = const [];

  /// Older pages + messages pushed out of the live window by newer ones.
  final Map<String, Message> _older = {};

  /// The locally cached copy shown until the first live snapshot.
  List<Message> _cached = const [];

  List<Message> _messages = const [];

  /// Oldest document read by the live window / by the last older page.
  DateTime? _liveCursor;
  DateTime? _olderCursor;

  bool _hasMore = false;
  bool _liveLoaded = false;

  /// What the list shows, newest first, without duplicates.
  List<Message> get messages => _messages;

  /// Older messages may exist on the server.
  bool get hasMore => _hasMore;

  /// A live snapshot has arrived (the cached copy is replaced).
  bool get liveLoaded => _liveLoaded;

  /// Showing the cached copy, no live snapshot yet.
  bool get showingCache => !_liveLoaded && _cached.isNotEmpty;

  /// Where the next older page starts (exclusive), or null when unknown.
  DateTime? get nextCursor {
    final a = _liveCursor, b = _olderCursor;
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  void reset() {
    _live = const [];
    _older.clear();
    _cached = const [];
    _messages = const [];
    _liveCursor = null;
    _olderCursor = null;
    _hasMore = false;
    _liveLoaded = false;
  }

  /// Paints the locally cached copy (ignored once the live window arrived).
  bool showCached(List<Message> cached) {
    if (_liveLoaded || cached.isEmpty) return false;
    _cached = _sorted(cached);
    _messages = _cached;
    return true;
  }

  /// Folds a live-window snapshot in. Returns false when it was ignored: an
  /// empty answer of the local Firestore cache while the cached copy shows
  /// (the server answer follows; no "say hi" flash meanwhile).
  bool applyLive(MessagePage page) {
    if (showingCache && page.fromCache && page.messages.isEmpty) return false;

    final live = _sorted(page.messages);
    final liveIds = {for (final m in live) m.messageId};
    final cursor = page.cursor ?? (live.isEmpty ? null : live.last.sentAt);

    if (!_liveLoaded) {
      // First snapshot replaces the cached copy. Its messages OLDER than the
      // window are kept as the first older page only when they continue it
      // (overlap, or the window holds the whole history), never across a gap
      // of messages that arrived while the chat was closed.
      final continues =
          !page.hasMore || _cached.any((m) => liveIds.contains(m.messageId));
      if (continues && cursor != null) {
        final older = [
          for (final m in _cached)
            if (!liveIds.contains(m.messageId) && m.sentAt.isBefore(cursor)) m,
        ];
        for (final m in older) {
          _older[m.messageId] = m;
        }
        if (older.isNotEmpty) _olderCursor = older.last.sentAt;
      }
      _cached = const [];
      _hasMore = page.hasMore;
      _liveLoaded = true;
    } else if (page.hasMore && cursor != null) {
      // Messages that left a FULL window and are older than it were pushed
      // out by newer ones: they move to the older pages. (One that left a
      // window that isn't full, or from inside its range, was deleted.)
      for (final m in _live) {
        if (!liveIds.contains(m.messageId) && m.sentAt.isBefore(cursor)) {
          _older[m.messageId] = m;
        }
      }
      if (_olderCursor == null) _hasMore = true;
    } else if (_olderCursor == null) {
      _hasMore = page.hasMore;
    }

    // An older message inside the window's range that the window no longer
    // has was deleted.
    if (cursor != null) {
      _older.removeWhere(
        (id, m) => !m.sentAt.isBefore(cursor) && !liveIds.contains(id),
      );
    }

    _live = live;
    _liveCursor = cursor;
    _rebuild();
    return true;
  }

  /// Adds an older page (loaded on scroll).
  void applyOlder(MessagePage page) {
    final liveIds = {for (final m in _live) m.messageId};
    for (final m in page.messages) {
      if (!liveIds.contains(m.messageId)) _older[m.messageId] = m;
    }
    _olderCursor = page.cursor ?? _olderCursor;
    // No cursor = nothing was read: the history is complete.
    _hasMore = page.hasMore && page.cursor != null;
    _rebuild();
  }

  /// A message this user removed leaves the (static) older pages at once;
  /// the live window drops it with its next snapshot. True when it changed.
  bool drop(String messageId) {
    if (_older.remove(messageId) == null) return false;
    _rebuild();
    return true;
  }

  void _rebuild() {
    final liveIds = {for (final m in _live) m.messageId};
    _messages = _sorted([
      ..._live,
      for (final m in _older.values)
        if (!liveIds.contains(m.messageId)) m,
    ]);
  }

  static List<Message> _sorted(Iterable<Message> list) =>
      [...list]..sort((a, b) => b.sentAt.compareTo(a.sentAt));
}
