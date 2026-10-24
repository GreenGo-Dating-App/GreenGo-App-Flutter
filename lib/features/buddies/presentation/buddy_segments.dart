import 'package:flutter/material.dart';

import '../domain/entities/buddy_message.dart';

/// One located pair of [BuddySegment]: the chunk of the message text
/// ([sStart]..[sEnd]) and its chunk in the translation ([tStart]..[tEnd]),
/// shown with colour [color] (an index into [BuddySegmentPalette]).
class BuddySegmentMatch {
  const BuddySegmentMatch({
    required this.sStart,
    required this.sEnd,
    required this.tStart,
    required this.tEnd,
    required this.color,
  });

  final int sStart;
  final int sEnd;
  final int tStart;
  final int tEnd;
  final int color;
}

/// Locates [segments] in [text] (the original) and [translated]. Pure.
///
/// `s` chunks come in order: each is searched from the end of the previous
/// match (repeated words land on the right occurrence). `t` chunks may be
/// reordered: each takes the first occurrence that overlaps no chunk already
/// taken. A segment whose `s` or `t` is not found (or is empty) is ignored;
/// the following ones still match. Pair i keeps colour i (palette order).
List<BuddySegmentMatch> locateBuddySegments(
    String text, String translated, List<BuddySegment> segments) {
  final out = <BuddySegmentMatch>[];
  final taken = <(int, int)>[];
  var cursor = 0;
  for (final seg in segments) {
    if (seg.s.isEmpty || seg.t.isEmpty) continue;
    final s = text.indexOf(seg.s, cursor);
    if (s < 0) continue;
    int? t;
    var from = 0;
    while (true) {
      final at = translated.indexOf(seg.t, from);
      if (at < 0) break;
      final end = at + seg.t.length;
      if (!taken.any((r) => at < r.$2 && r.$1 < end)) {
        t = at;
        break;
      }
      from = at + 1;
    }
    if (t == null) continue;
    taken.add((t, t + seg.t.length));
    cursor = s + seg.s.length;
    out.add(BuddySegmentMatch(
      sStart: s,
      sEnd: cursor,
      tStart: t,
      tEnd: t + seg.t.length,
      color: out.length,
    ));
  }
  return out;
}

/// Colours of matching chunks: a background tint plus a solid underline in
/// the same hue (never colour alone). The text colour itself is unchanged, so
/// contrast stays that of the bubble (dark received bubble / gold own bubble).
class BuddySegmentPalette {
  BuddySegmentPalette._();

  static const List<Color> colors = [
    Color(0xFF2196F3), // blue
    Color(0xFFE91E63), // pink
    Color(0xFF4CAF50), // green
    Color(0xFFFF9800), // orange
    Color(0xFF9C27B0), // purple
    Color(0xFF00BCD4), // cyan
  ];

  static Color of(int i) => colors[i % colors.length];

  static TextStyle style(TextStyle base, int i) {
    final c = of(i);
    return base.copyWith(
      backgroundColor: c.withValues(alpha: 0.22),
      decoration: TextDecoration.underline,
      decorationColor: c,
      decorationThickness: 2,
    );
  }
}

/// [text] with the chunks of [matches] coloured; [original] picks the `s`
/// ranges (the message text), else the `t` ranges (the translation).
class BuddySegmentText extends StatelessWidget {
  const BuddySegmentText({
    required this.text,
    required this.matches,
    required this.original,
    required this.style,
    super.key,
  });

  final String text;
  final List<BuddySegmentMatch> matches;
  final bool original;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final ranges = [
      for (final m in matches)
        original ? (m.sStart, m.sEnd, m.color) : (m.tStart, m.tEnd, m.color),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final spans = <TextSpan>[];
    var at = 0;
    for (final (start, end, color) in ranges) {
      if (start < at || end > text.length) continue;
      if (start > at) spans.add(TextSpan(text: text.substring(at, start)));
      spans.add(TextSpan(
        text: text.substring(start, end),
        style: BuddySegmentPalette.style(style, color),
      ));
      at = end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(TextSpan(style: style, children: spans));
  }
}
