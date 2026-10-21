import '../../domain/entities/community_message.dart';

/// The messages of ONE community detail (chat, tips and announcements share
/// the `communities/{id}/messages` collection), loaded page by page.
///
/// Owner notes 2026-10-20: chat and tips load only the newest [pageSize]
/// (newest first), with endless scroll to older pages until the beginning;
/// new messages still arrive live. So:
///  * the live listener covers ONLY the newest [pageSize] messages
///    ([applyLive]);
///  * older chat pages are keyset pages of [pageSize] (all types) before
///    [messagesCursor] ([addOlderPage]);
///  * older tips pages are keyset pages of [pageSize] tips only before
///    [tipsCursor] ([addTipsPage]), so a busy chat never buries the tips;
///  * with a Tips filter chip selected (owner request 2026-10-21), pages of
///    ONE tip type before [tipsCursorOf] ([addTipsPageOf]), so a rare type is
///    found on the server instead of scrolling through every tip page.
///
/// A message that drops out of the live window (newer ones arrived) is kept
/// as an older one, never lost; one that disappears from INSIDE the window
/// was deleted and is dropped.
class CommunityMessageFeed {
  CommunityMessageFeed({this.pageSize = defaultPageSize});

  static const int defaultPageSize = 50;

  final int pageSize;

  List<CommunityMessage> _live = const [];
  bool _liveSeen = false;
  final Map<String, CommunityMessage> _older = {};
  final Map<String, CommunityMessage> _olderTips = {};
  // Per stored tip type ('city_tip', ...): pages of that type only.
  final Map<String, Map<String, CommunityMessage>> _olderTipsByType = {};
  final Set<String> _typeAtStart = {};
  bool _messagesAtStart = false;
  bool _tipsAtStart = false;

  /// Whether older (chat) pages may exist before [messagesCursor].
  bool get hasMoreMessages => !_messagesAtStart;

  /// Whether older tips may exist before [tipsCursor].
  bool get hasMoreTips => !_tipsAtStart && !_messagesAtStart;

  /// Whether older tips of the stored [type] may exist before
  /// [tipsCursorOf].
  bool hasMoreTipsOf(String type) => hasMoreTips && !_typeAtStart.contains(type);

  /// [hasMoreTipsOf] for every type that has had a typed page.
  Map<String, bool> get hasMoreTipsByType => {
        for (final t in {..._olderTipsByType.keys, ..._typeAtStart})
          t: hasMoreTipsOf(t),
      };

  /// Applies a live snapshot: the newest messages, newest first, at most
  /// [pageSize].
  void applyLive(List<CommunityMessage> live) {
    if (_liveSeen && live.isNotEmpty) {
      final oldestLive = _oldest(live)!;
      final ids = {for (final m in live) m.id};
      for (final m in _live) {
        // Pushed out of the window by newer messages: keep it as older.
        if (!ids.contains(m.id) && m.sentAt.isBefore(oldestLive)) {
          _older[m.id] = m;
        }
      }
    }
    _liveSeen = true;
    _live = List.unmodifiable(live);
    // A window that is not full holds the whole collection.
    if (live.length < pageSize) {
      _messagesAtStart = true;
      _tipsAtStart = true;
    }
  }

  /// Adds an older chat page (all types, newest first) read before
  /// [messagesCursor]; a short page means the beginning was reached.
  void addOlderPage(List<CommunityMessage> page) {
    for (final m in page) {
      _older[m.id] = m;
    }
    if (page.length < pageSize) _messagesAtStart = true;
  }

  /// Adds an older tips page (tips only, newest first) read before
  /// [tipsCursor]; a short page means the first tip was reached.
  void addTipsPage(List<CommunityMessage> page) {
    for (final m in page) {
      if (m.isTip) _olderTips[m.id] = m;
    }
    if (page.length < pageSize) _tipsAtStart = true;
  }

  /// Adds an older page of ONE tip [type] (newest first) read before
  /// [tipsCursorOf]; a short page means the first tip of that type was
  /// reached.
  void addTipsPageOf(String type, List<CommunityMessage> page) {
    final byId = _olderTipsByType.putIfAbsent(type, () => {});
    for (final m in page) {
      if (m.isTip && m.type.value == type) byId[m.id] = m;
    }
    if (page.length < pageSize) _typeAtStart.add(type);
  }

  /// Drops a message removed on this device (older pages are not live).
  void remove(String messageId) {
    _older.remove(messageId);
    _olderTips.remove(messageId);
    for (final byId in _olderTipsByType.values) {
      byId.remove(messageId);
    }
    _live = List.unmodifiable(_live.where((m) => m.id != messageId));
  }

  /// Every message of every type is loaded down to here: the next older
  /// chat page starts after it. Null before the first live snapshot.
  DateTime? get messagesCursor {
    final a = _oldest(_live);
    final b = _oldest(_older.values);
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  /// Every TIP is loaded down to here (the chat pages hold the tips too):
  /// the next older tips page starts after it.
  DateTime? get tipsCursor {
    final m = messagesCursor;
    final t = _oldest(_olderTips.values);
    if (m == null) return t;
    if (t == null) return m;
    return m.isBefore(t) ? m : t;
  }

  /// Every tip of the stored [type] is loaded down to here (the chat and
  /// all-tips pages hold them too): the next page of that type starts after
  /// it. Each kind of page is contiguous from the newest, so the deepest one
  /// wins.
  DateTime? tipsCursorOf(String type) {
    final t = tipsCursor;
    final own = _oldest(_olderTipsByType[type]?.values ?? const []);
    if (t == null) return own;
    if (own == null) return t;
    return t.isBefore(own) ? t : own;
  }

  /// All loaded messages, deduplicated, newest first.
  List<CommunityMessage> get all {
    final byId = <String, CommunityMessage>{
      for (final byType in _olderTipsByType.values) ...byType,
      ..._olderTips,
      ..._older,
      for (final m in _live) m.id: m,
    };
    final out = byId.values.toList()
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return out;
  }

  static DateTime? _oldest(Iterable<CommunityMessage> list) {
    DateTime? min;
    for (final m in list) {
      if (min == null || m.sentAt.isBefore(min)) min = m.sentAt;
    }
    return min;
  }
}
