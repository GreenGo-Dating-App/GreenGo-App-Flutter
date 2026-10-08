import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/translation_service.dart';
import '../../generated/app_localizations.dart';

/// Text rendered in the VIEWER's language (any of the app's languages),
/// per-viewer, with no schema change. Reuses the shared [TranslationService]
/// (auto source detection + caching).
///
/// - [autoTranslate] false (default): an on-demand "Translate / Show
///   original" action, as in community chat/tips/announcements.
/// - [autoTranslate] true: translated as soon as it appears (content pages:
///   events, attractions, experiences). A "Show original" / "Translate" toggle
///   stays available; when the text is already in the viewer's language
///   nothing changes and no toggle is shown.
class TranslatableText extends StatefulWidget {
  const TranslatableText({
    required this.text,
    required this.targetLang,
    required this.style,
    super.key,
    this.actionAlign = CrossAxisAlignment.start,
    this.maxLines,
    this.overflow,
    this.autoTranslate = false,
  });

  /// The original text to display (and optionally translate).
  final String text;

  /// The viewer's language code to translate INTO (e.g. 'en', 'it', 'pt').
  final String targetLang;

  /// Style for the main text.
  final TextStyle style;

  /// Alignment of the little translate action under the text.
  final CrossAxisAlignment actionAlign;

  final int? maxLines;
  final TextOverflow? overflow;

  /// Translate immediately instead of waiting for a tap.
  final bool autoTranslate;

  @override
  State<TranslatableText> createState() => _TranslatableTextState();
}

class _TranslatableTextState extends State<TranslatableText> {
  String? _translated;
  bool _translating = false;
  bool _showingTranslation = false;

  /// Auto mode found the text already in the viewer's language.
  bool _sameLanguage = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoTranslate) _translate();
  }

  @override
  void didUpdateWidget(TranslatableText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.targetLang != widget.targetLang) {
      _translated = null;
      _showingTranslation = false;
      _sameLanguage = false;
      if (widget.autoTranslate) _translate();
    }
  }

  String get _display =>
      _showingTranslation && _translated != null ? _translated! : widget.text;

  Future<void> _translate() async {
    if (widget.text.trim().isEmpty) return;
    setState(() => _translating = true);
    try {
      // Auto mode is for PUBLIC content: use the shared store, so each text
      // is translated once per language for everyone. The on-demand mode is
      // also used for chat, which must stay private.
      final svc = TranslationService();
      final target = widget.targetLang.replaceAll('_', '-');
      final result = widget.autoTranslate
          ? await svc.translateSharedOne(widget.text, targetLanguage: target)
          : await svc.translate(
              text: widget.text,
              sourceLanguage: 'auto',
              targetLanguage: target,
              // Public listings / reviews only (never chat).
              requiresConsent: false,
            );
      if (!mounted) return;
      setState(() {
        if (result.trim().isEmpty || result.trim() == widget.text.trim()) {
          _sameLanguage = widget.autoTranslate;
        } else {
          _translated = result;
          _showingTranslation = true;
        }
      });
    } catch (_) {
      // Best-effort — leave the original text on any failure.
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  Future<void> _toggle() async {
    // Already have a translation cached in-widget — just flip the view.
    if (_translated != null) {
      setState(() => _showingTranslation = !_showingTranslation);
      return;
    }
    await _translate();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = _translating
        ? l10n.communitiesTranslating
        : (_showingTranslation
            ? l10n.communitiesShowOriginal
            : l10n.communitiesTranslate);
    // Auto mode: no toggle when there's nothing to toggle (same language, or
    // the translation failed/hasn't produced anything).
    final showAction = widget.text.trim().isNotEmpty &&
        (!widget.autoTranslate ||
            _translating ||
            (_translated != null && !_sameLanguage));
    final keepClamped = widget.autoTranslate || !_showingTranslation;
    return Column(
      crossAxisAlignment: widget.actionAlign,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _display,
          style: widget.style,
          maxLines: keepClamped ? widget.maxLines : null,
          overflow: keepClamped ? widget.overflow : null,
        ),
        if (showAction)
          GestureDetector(
            onTap: _translating ? null : _toggle,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
