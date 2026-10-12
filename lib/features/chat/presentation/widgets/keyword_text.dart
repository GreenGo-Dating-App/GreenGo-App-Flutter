import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/chat_datasets/chat_datasets.dart';
import '../../../../core/services/chat_datasets/keyword_matcher.dart';
import 'keyword_actions.dart';

/// Message text with city / attraction / country names highlighted and
/// tappable (Cultural tips on). Uses [stored] keywords (from the message
/// metadata, written by the sender) when given, otherwise matches [text]
/// against the offline keyword index (e.g. for a translation).
class KeywordText extends StatefulWidget {
  const KeywordText(
    this.text, {
    required this.style,
    this.highlight = true,
    this.stored,
    this.maxLines,
    super.key,
  });

  final String text;
  final TextStyle style;
  final bool highlight;
  final List<KeywordMatch>? stored;
  final int? maxLines;

  @override
  State<KeywordText> createState() => _KeywordTextState();
}

class _KeywordTextState extends State<KeywordText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    if (widget.highlight && widget.stored == null) {
      ChatDatasets.instance.warmUpForChat();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.highlight) {
      return Text(widget.text, style: widget.style, maxLines: widget.maxLines);
    }
    return ValueListenableBuilder<int>(
      valueListenable: ChatDatasets.instance.changes,
      builder: (context, _, __) {
        final matches = widget.stored ??
            ChatDatasets.instance.keywords?.match(widget.text) ??
            const <KeywordMatch>[];
        if (matches.isEmpty) {
          return Text(widget.text, style: widget.style, maxLines: widget.maxLines);
        }
        _disposeRecognizers();
        final onLight = (widget.style.color?.computeLuminance() ?? 1) < 0.2;
        final spans = <InlineSpan>[];
        var pos = 0;
        for (final m in matches) {
          if (m.start < pos || m.end > widget.text.length) continue;
          if (m.start > pos) spans.add(TextSpan(text: widget.text.substring(pos, m.start)));
          final r = TapGestureRecognizer()..onTap = () => KeywordActions.open(context, m);
          _recognizers.add(r);
          // On a light bubble (own messages, dark text) the accent colours
          // would vanish: keep the text colour, bold + dotted underline.
          final color = onLight ? widget.style.color : _color(m.kind);
          spans.add(TextSpan(
            text: widget.text.substring(m.start, m.end),
            recognizer: r,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: color,
            ),
          ));
          pos = m.end;
        }
        if (pos < widget.text.length) spans.add(TextSpan(text: widget.text.substring(pos)));
        return Text.rich(TextSpan(style: widget.style, children: spans), maxLines: widget.maxLines);
      },
    );
  }

  Color _color(KeywordKind k) => switch (k) {
        KeywordKind.attraction => AppColors.richGold,
        KeywordKind.city => const Color(0xFF4FC3F7),
        KeywordKind.country => const Color(0xFF81C784),
      };
}
