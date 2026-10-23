import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/ai_consent_service.dart';
import '../services/translation_service.dart';
import 'ai_consent_sheet.dart';
import '../../generated/app_localizations.dart';
import '../services/app_sound_service.dart';

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
///
/// Consent (Apple 5.1.2(i)): translating sends the text to Google, so it
/// needs the account's AI consent. Auto mode asks once
/// ([AiConsentGate.allowAutoTranslate]); without consent the original is
/// shown with a "Translate" action, and tapping it asks again
/// ([AiConsentGate.requestTranslation]).
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
    this.aiConsent,
    this.translator,
  });

  /// Consent source; defaults to [AiConsentService.instance] (tests inject).
  final AiConsentService? aiConsent;

  /// Translation backend; defaults to the shared store / [TranslationService]
  /// (tests inject). Returns the translation or the original.
  final Future<String> Function(String text, String target, {required bool shared})?
      translator;

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

  /// Auto mode without consent: the original with a "Translate" action.
  bool _awaitingConsent = false;

  AiConsentService get _consent => widget.aiConsent ?? AiConsentService.instance;

  /// Synchronous consent check; false when it cannot be read (no Firebase).
  bool _grantedNow() {
    try {
      return _consent.isGranted;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      _consent.statusListenable.addListener(_onConsentChanged);
    } catch (_) {}
    if (widget.autoTranslate) _startAuto();
  }

  @override
  void dispose() {
    try {
      _consent.statusListenable.removeListener(_onConsentChanged);
    } catch (_) {}
    super.dispose();
  }

  /// Accepted elsewhere (the sheet another widget opened, Settings): the
  /// waiting auto text translates now.
  void _onConsentChanged() {
    if (!mounted || !widget.autoTranslate || !_awaitingConsent) return;
    if (_grantedNow()) {
      setState(() => _awaitingConsent = false);
      _translate();
    }
  }

  void _startAuto() {
    if (widget.text.trim().isEmpty) return;
    if (_grantedNow()) {
      _translate();
      return;
    }
    _awaitingConsent = true;
    // The consent sheet needs a laid-out context.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      bool ok;
      try {
        ok = await AiConsentGate.allowAutoTranslate(context, service: _consent);
      } catch (_) {
        ok = false;
      }
      if (!mounted || !_awaitingConsent) return;
      if (ok) {
        setState(() => _awaitingConsent = false);
        _translate();
      }
    });
  }

  @override
  void didUpdateWidget(TranslatableText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.targetLang != widget.targetLang) {
      _translated = null;
      _showingTranslation = false;
      _sameLanguage = false;
      _awaitingConsent = false;
      if (widget.autoTranslate) _startAuto();
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
      final target = widget.targetLang.replaceAll('_', '-');
      final custom = widget.translator;
      final svc = custom == null ? TranslationService() : null;
      final result = custom != null
          ? await custom(widget.text, target, shared: widget.autoTranslate)
          : widget.autoTranslate
          ? await svc!.translateSharedOne(widget.text, targetLanguage: target)
          : await svc!.translate(
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
      if (!widget.autoTranslate && _showingTranslation) {
        AppSoundService().play(AppSound.translate);
      }
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
    // Sends the text to Google: the account's AI consent (asks again after
    // a decline: the tap is the user reconsidering).
    bool ok;
    try {
      ok = await AiConsentGate.requestTranslation(context, service: _consent);
    } catch (_) {
      ok = false;
    }
    if (!ok || !mounted) return;
    _awaitingConsent = false;
    // The consent listener may already have started it.
    if (_translating || _translated != null) return;
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
            _awaitingConsent ||
            (_translated != null && !_sameLanguage));
    final keepClamped = widget.autoTranslate || !_showingTranslation;
    final showingTranslation =
        !_translating && _showingTranslation && _translated != null;
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
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Terms 14.3: a shown translation is marked "Translated".
                if (showingTranslation) ...[
                  const Icon(Icons.translate,
                      size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 3),
                  Text(
                    l10n.chatTranslated,
                    key: const ValueKey('translatable-text-translated'),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                  ),
                  const Text(' · ',
                      style: TextStyle(
                          color: AppColors.textTertiary, fontSize: 12)),
                ],
                GestureDetector(
                  key: const ValueKey('translatable-text-action'),
                  onTap: _translating ? null : _toggle,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
