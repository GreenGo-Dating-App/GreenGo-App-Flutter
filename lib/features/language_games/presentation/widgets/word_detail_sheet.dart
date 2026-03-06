import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/pronunciation_service.dart';

/// Bottom sheet that shows word details when a user long-presses a word.
///
/// Features:
/// - Word in target language (large, prominent)
/// - Translation in user's native language
/// - Pronunciation play button (TTS via PronunciationService)
/// - Example sentence with translation
/// - "Save to flashcards" action
/// - Phonetic hint (if available)
///
/// Usage:
/// ```dart
/// WordDetailSheet.show(
///   context,
///   word: 'casa',
///   translation: 'house',
///   language: 'es',
///   exampleSentence: 'Mi casa es tu casa.',
///   exampleTranslation: 'My house is your house.',
/// );
/// ```
class WordDetailSheet extends StatefulWidget {
  final String word;
  final String translation;
  final String language;
  final String? exampleSentence;
  final String? exampleTranslation;
  final String? phoneticHint;
  final String? partOfSpeech;
  final VoidCallback? onSaveToFlashcards;

  const WordDetailSheet({
    super.key,
    required this.word,
    required this.translation,
    required this.language,
    this.exampleSentence,
    this.exampleTranslation,
    this.phoneticHint,
    this.partOfSpeech,
    this.onSaveToFlashcards,
  });

  /// Show the bottom sheet — call this from a long-press handler
  static Future<void> show(
    BuildContext context, {
    required String word,
    required String translation,
    required String language,
    String? exampleSentence,
    String? exampleTranslation,
    String? phoneticHint,
    String? partOfSpeech,
    VoidCallback? onSaveToFlashcards,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => WordDetailSheet(
        word: word,
        translation: translation,
        language: language,
        exampleSentence: exampleSentence,
        exampleTranslation: exampleTranslation,
        phoneticHint: phoneticHint,
        partOfSpeech: partOfSpeech,
        onSaveToFlashcards: onSaveToFlashcards,
      ),
    );
  }

  @override
  State<WordDetailSheet> createState() => _WordDetailSheetState();
}

class _WordDetailSheetState extends State<WordDetailSheet> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PronunciationService _pronunciationService = PronunciationService();

  bool _isLoadingAudio = false;
  bool _isPlaying = false;
  bool _savedToFlashcards = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPronunciation() async {
    if (_isLoadingAudio) return;

    setState(() => _isLoadingAudio = true);
    HapticFeedback.lightImpact();

    try {
      final url = await _pronunciationService.getPronunciationUrl(
        widget.word,
        _getLanguageName(widget.language),
      );

      if (url != null && mounted) {
        setState(() => _isPlaying = true);
        await _audioPlayer.play(UrlSource(url));
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isPlaying = false);
        });
      }
    } catch (e) {
      debugPrint('[WordDetailSheet] Audio error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  String _getLanguageName(String code) {
    const names = {
      'en': 'english',
      'es': 'spanish',
      'fr': 'french',
      'de': 'german',
      'it': 'italian',
      'pt': 'portuguese',
      'pt-BR': 'portuguese',
    };
    return names[code] ?? 'english';
  }

  String _getLanguageFlag(String code) {
    const flags = {
      'en': '\u{1F1EC}\u{1F1E7}',
      'es': '\u{1F1EA}\u{1F1F8}',
      'fr': '\u{1F1EB}\u{1F1F7}',
      'de': '\u{1F1E9}\u{1F1EA}',
      'it': '\u{1F1EE}\u{1F1F9}',
      'pt': '\u{1F1F5}\u{1F1F9}',
      'pt-BR': '\u{1F1E7}\u{1F1F7}',
    };
    return flags[code] ?? '\u{1F30D}';
  }

  void _onSaveToFlashcards() {
    HapticFeedback.mediumImpact();
    setState(() => _savedToFlashcards = true);
    widget.onSaveToFlashcards?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.richGold.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.richGold.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Main word + play button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                // Flag
                Text(
                  _getLanguageFlag(widget.language),
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                // Word
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.word,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (widget.phoneticHint != null)
                        Text(
                          widget.phoneticHint!,
                          style: TextStyle(
                            color: AppColors.textTertiary.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      if (widget.partOfSpeech != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.richGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.partOfSpeech!,
                            style: const TextStyle(
                              color: AppColors.richGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Play button
                GestureDetector(
                  onTap: _playPronunciation,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.richGold, AppColors.accentGold],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.richGold.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isLoadingAudio
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              color: AppColors.deepBlack,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            _isPlaying
                                ? Icons.volume_up_rounded
                                : Icons.play_arrow_rounded,
                            color: AppColors.deepBlack,
                            size: 28,
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              height: 1,
              color: AppColors.divider.withValues(alpha: 0.5),
            ),
          ),

          // Translation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    color: AppColors.successGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Translation',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.translation,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Example sentence
          if (widget.exampleSentence != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundInput.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          color: AppColors.richGold.withValues(alpha: 0.7),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Example',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.exampleSentence!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                    if (widget.exampleTranslation != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.exampleTranslation!,
                        style: TextStyle(
                          color: AppColors.textTertiary.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Row(
              children: [
                // Save to flashcards
                if (widget.onSaveToFlashcards != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: _savedToFlashcards ? null : _onSaveToFlashcards,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _savedToFlashcards
                              ? AppColors.successGreen.withValues(alpha: 0.15)
                              : AppColors.backgroundInput,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _savedToFlashcards
                                ? AppColors.successGreen.withValues(alpha: 0.4)
                                : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _savedToFlashcards
                                  ? Icons.check_circle_rounded
                                  : Icons.bookmark_add_rounded,
                              color: _savedToFlashcards
                                  ? AppColors.successGreen
                                  : AppColors.richGold,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _savedToFlashcards ? 'Saved!' : 'Save to Flashcards',
                              style: TextStyle(
                                color: _savedToFlashcards
                                    ? AppColors.successGreen
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (widget.onSaveToFlashcards != null)
                  const SizedBox(width: 12),
                // Play again button
                Expanded(
                  child: GestureDetector(
                    onTap: _playPronunciation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.richGold, AppColors.accentGold],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isPlaying
                                ? Icons.volume_up_rounded
                                : Icons.hearing_rounded,
                            color: AppColors.deepBlack,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isPlaying ? 'Playing...' : 'Listen Again',
                            style: const TextStyle(
                              color: AppColors.deepBlack,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension to make any text widget long-pressable for word details
///
/// Usage:
/// ```dart
/// Text('casa').withWordDetail(
///   context,
///   translation: 'house',
///   language: 'es',
/// )
/// ```
class LongPressWordWrapper extends StatelessWidget {
  final Widget child;
  final String word;
  final String translation;
  final String language;
  final String? exampleSentence;
  final String? exampleTranslation;
  final String? phoneticHint;
  final String? partOfSpeech;
  final VoidCallback? onSaveToFlashcards;

  const LongPressWordWrapper({
    super.key,
    required this.child,
    required this.word,
    required this.translation,
    required this.language,
    this.exampleSentence,
    this.exampleTranslation,
    this.phoneticHint,
    this.partOfSpeech,
    this.onSaveToFlashcards,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => WordDetailSheet.show(
        context,
        word: word,
        translation: translation,
        language: language,
        exampleSentence: exampleSentence,
        exampleTranslation: exampleTranslation,
        phoneticHint: phoneticHint,
        partOfSpeech: partOfSpeech,
        onSaveToFlashcards: onSaveToFlashcards,
      ),
      child: child,
    );
  }
}
