import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/translation_service.dart';
import '../../generated/app_localizations.dart';

/// Text with an on-demand "Translate / Show original" action that renders the
/// content into the VIEWER's language (any of the app's languages), per-viewer,
/// with no schema change. Reuses the shared [TranslationService] (auto source
/// detection + caching). Used for event title/description, and mirrors the same
/// behaviour community chat/tips/announcements already have.
class TranslatableText extends StatefulWidget {
  const TranslatableText({
    required this.text,
    required this.targetLang,
    required this.style,
    super.key,
    this.actionAlign = CrossAxisAlignment.start,
    this.maxLines,
    this.overflow,
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

  @override
  State<TranslatableText> createState() => _TranslatableTextState();
}

class _TranslatableTextState extends State<TranslatableText> {
  String? _translated;
  bool _translating = false;
  bool _showingTranslation = false;

  String get _display =>
      _showingTranslation && _translated != null ? _translated! : widget.text;

  Future<void> _toggle() async {
    // Already have a translation cached in-widget — just flip the view.
    if (_translated != null) {
      setState(() => _showingTranslation = !_showingTranslation);
      return;
    }
    setState(() => _translating = true);
    try {
      final result = await TranslationService().translate(
        text: widget.text,
        sourceLanguage: 'auto',
        targetLanguage: widget.targetLang.replaceAll('_', '-'),
      );
      if (!mounted) return;
      setState(() {
        _translated = result;
        _showingTranslation = true;
      });
    } catch (_) {
      // Best-effort — leave the original text on any failure.
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = _translating
        ? l10n.communitiesTranslating
        : (_showingTranslation
            ? l10n.communitiesShowOriginal
            : l10n.communitiesTranslate);
    return Column(
      crossAxisAlignment: widget.actionAlign,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _display,
          style: widget.style,
          maxLines: _showingTranslation ? null : widget.maxLines,
          overflow: _showingTranslation ? null : widget.overflow,
        ),
        if (widget.text.trim().isNotEmpty)
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
