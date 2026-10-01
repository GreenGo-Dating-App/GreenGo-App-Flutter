/// Someone who can be '@'-tagged in a review thread (the review author, the
/// host and earlier repliers).
class MentionCandidate {
  const MentionCandidate({required this.uid, required this.name});
  final String uid;
  final String name;
}

/// A run of reply text: plain, or an '@Name' mention of [uid].
class MentionSegment {
  const MentionSegment(this.text, {this.uid});
  final String text;
  final String? uid;
  bool get isMention => uid != null;
}

/// Pure '@'-mention helpers (unit tested).
class MentionParser {
  const MentionParser._();

  static const int maxQueryLength = 30;

  /// The text typed after an '@' that the caret is currently in, or null when
  /// the caret isn't in a mention. The '@' must start the text or follow
  /// whitespace (so emails don't trigger it); the query can contain spaces
  /// (names do) but not a newline, and is capped at [maxQueryLength].
  static String? activeQuery(String text, int cursor) {
    if (cursor < 0 || cursor > text.length) return null;
    final before = text.substring(0, cursor);
    final at = before.lastIndexOf('@');
    if (at < 0) return null;
    if (at > 0 && !_isSpace(before[at - 1])) return null;
    final q = before.substring(at + 1);
    if (q.contains('\n') || q.length > maxQueryLength) return null;
    return q;
  }

  /// Candidates whose name matches [query] (case-insensitive prefix of the
  /// name or of any word in it), excluding [excludeUid] and empty names.
  static List<MentionCandidate> suggestions(
    List<MentionCandidate> candidates,
    String query, {
    String? excludeUid,
    int limit = 6,
  }) {
    final q = query.trim().toLowerCase();
    final seen = <String>{};
    final out = <MentionCandidate>[];
    for (final c in candidates) {
      final name = c.name.trim();
      if (name.isEmpty || c.uid == excludeUid || !seen.add(c.uid)) continue;
      final n = name.toLowerCase();
      final match = q.isEmpty ||
          n.startsWith(q) ||
          n.split(RegExp(r'\s+')).any((w) => w.startsWith(q));
      if (match) out.add(c);
      if (out.length >= limit) break;
    }
    return out;
  }

  /// Replaces the active '@query' before [cursor] with '@Name ' and returns
  /// the new text and caret position. Unchanged when no mention is active.
  static ({String text, int cursor}) insert(
      String text, int cursor, String name) {
    final q = activeQuery(text, cursor);
    if (q == null) return (text: text, cursor: cursor);
    final start = cursor - q.length - 1; // the '@'
    final insertion = '@$name ';
    final after = text.substring(cursor);
    final newText = text.substring(0, start) + insertion + after;
    return (text: newText, cursor: start + insertion.length);
  }

  /// Uids of [candidates] whose '@Name' appears in [text] (whole name,
  /// followed by end/space/punctuation). Longer names are matched first so
  /// "@Ana Maria" wins over "@Ana". Deduplicated, capped at [max].
  static List<String> resolveMentions(
    String text,
    List<MentionCandidate> candidates, {
    int max = 10,
  }) {
    final sorted = [...candidates.where((c) => c.name.trim().isNotEmpty)]
      ..sort((a, b) => b.name.length.compareTo(a.name.length));
    var remaining = text;
    final out = <String>[];
    for (final c in sorted) {
      final re = _mentionRe(c.name.trim());
      if (re.hasMatch(remaining)) {
        if (!out.contains(c.uid)) out.add(c.uid);
        // Blank out matched mentions so a shorter name can't re-match them.
        remaining = remaining.replaceAllMapped(re, (m) => ' ' * m[0]!.length);
        if (out.length >= max) break;
      }
    }
    return out;
  }

  /// Splits [text] into plain / mention segments for highlighting, given the
  /// display names of the stored mention uids ({uid: name}).
  static List<MentionSegment> segments(String text, Map<String, String> names) {
    final entries = names.entries.where((e) => e.value.trim().isNotEmpty).toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    if (entries.isEmpty || !text.contains('@')) return [MentionSegment(text)];

    // Find every mention match, longest names first, without overlaps.
    final spans = <({int start, int end, String uid})>[];
    for (final e in entries) {
      for (final m in _mentionRe(e.value.trim()).allMatches(text)) {
        final s = m.start, en = m.start + 1 + e.value.trim().length;
        if (spans.any((x) => s < x.end && en > x.start)) continue;
        spans.add((start: s, end: en, uid: e.key));
      }
    }
    if (spans.isEmpty) return [MentionSegment(text)];
    spans.sort((a, b) => a.start.compareTo(b.start));

    final out = <MentionSegment>[];
    var i = 0;
    for (final s in spans) {
      if (s.start > i) out.add(MentionSegment(text.substring(i, s.start)));
      out.add(MentionSegment(text.substring(s.start, s.end), uid: s.uid));
      i = s.end;
    }
    if (i < text.length) out.add(MentionSegment(text.substring(i)));
    return out;
  }

  static RegExp _mentionRe(String name) => RegExp(
        '(?<![^\\s])@${RegExp.escape(name)}(?=\$|[\\s.,;:!?)\\]}\'"])',
        caseSensitive: false,
      );

  static bool _isSpace(String ch) => ch.trim().isEmpty;
}
