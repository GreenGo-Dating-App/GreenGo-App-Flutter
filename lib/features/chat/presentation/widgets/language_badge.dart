import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Language Badge Widget
///
/// Displays a compact row of language chips showing the languages a user speaks.
/// Shows the first 2-3 languages with flag emoji or language code abbreviations.
/// Designed to be placed next to user names in chat headers or profile cards.
///
/// Usage:
/// ```dart
/// LanguageBadge(
///   languages: ['English', 'Italian', 'Spanish'],
///   maxDisplay: 2,
/// )
/// ```
class LanguageBadge extends StatelessWidget {
  /// List of language names or codes the user speaks
  final List<String> languages;

  /// Maximum number of language chips to display (default: 3)
  final int maxDisplay;

  /// Whether to use compact mode (smaller chips, for tight spaces)
  final bool compact;

  /// Optional: highlight the native language with a gold border
  final String? nativeLanguage;

  const LanguageBadge({
    super.key,
    required this.languages,
    this.maxDisplay = 3,
    this.compact = false,
    this.nativeLanguage,
  });

  /// Map of language names/codes to flag emojis
  static const Map<String, String> _languageFlags = {
    // Full names
    'english': '\u{1F1EC}\u{1F1E7}',
    'italian': '\u{1F1EE}\u{1F1F9}',
    'italiano': '\u{1F1EE}\u{1F1F9}',
    'spanish': '\u{1F1EA}\u{1F1F8}',
    'espanol': '\u{1F1EA}\u{1F1F8}',
    'french': '\u{1F1EB}\u{1F1F7}',
    'francais': '\u{1F1EB}\u{1F1F7}',
    'german': '\u{1F1E9}\u{1F1EA}',
    'deutsch': '\u{1F1E9}\u{1F1EA}',
    'portuguese': '\u{1F1F5}\u{1F1F9}',
    'portugues': '\u{1F1F5}\u{1F1F9}',
    'chinese': '\u{1F1E8}\u{1F1F3}',
    'mandarin': '\u{1F1E8}\u{1F1F3}',
    'japanese': '\u{1F1EF}\u{1F1F5}',
    'korean': '\u{1F1F0}\u{1F1F7}',
    'arabic': '\u{1F1F8}\u{1F1E6}',
    'russian': '\u{1F1F7}\u{1F1FA}',
    'hindi': '\u{1F1EE}\u{1F1F3}',
    'dutch': '\u{1F1F3}\u{1F1F1}',
    'turkish': '\u{1F1F9}\u{1F1F7}',
    'polish': '\u{1F1F5}\u{1F1F1}',
    'swedish': '\u{1F1F8}\u{1F1EA}',
    'norwegian': '\u{1F1F3}\u{1F1F4}',
    'danish': '\u{1F1E9}\u{1F1F0}',
    'finnish': '\u{1F1EB}\u{1F1EE}',
    'greek': '\u{1F1EC}\u{1F1F7}',
    'czech': '\u{1F1E8}\u{1F1FF}',
    'romanian': '\u{1F1F7}\u{1F1F4}',
    'hungarian': '\u{1F1ED}\u{1F1FA}',
    'thai': '\u{1F1F9}\u{1F1ED}',
    'vietnamese': '\u{1F1FB}\u{1F1F3}',
    'indonesian': '\u{1F1EE}\u{1F1E9}',
    'malay': '\u{1F1F2}\u{1F1FE}',
    'filipino': '\u{1F1F5}\u{1F1ED}',
    'ukrainian': '\u{1F1FA}\u{1F1E6}',
    'hebrew': '\u{1F1EE}\u{1F1F1}',
    'persian': '\u{1F1EE}\u{1F1F7}',
    'swahili': '\u{1F1F0}\u{1F1EA}',
    // ISO codes
    'en': '\u{1F1EC}\u{1F1E7}',
    'it': '\u{1F1EE}\u{1F1F9}',
    'es': '\u{1F1EA}\u{1F1F8}',
    'fr': '\u{1F1EB}\u{1F1F7}',
    'de': '\u{1F1E9}\u{1F1EA}',
    'pt': '\u{1F1F5}\u{1F1F9}',
    'zh': '\u{1F1E8}\u{1F1F3}',
    'ja': '\u{1F1EF}\u{1F1F5}',
    'ko': '\u{1F1F0}\u{1F1F7}',
    'ar': '\u{1F1F8}\u{1F1E6}',
    'ru': '\u{1F1F7}\u{1F1FA}',
    'hi': '\u{1F1EE}\u{1F1F3}',
    'nl': '\u{1F1F3}\u{1F1F1}',
    'tr': '\u{1F1F9}\u{1F1F7}',
    'pl': '\u{1F1F5}\u{1F1F1}',
    'sv': '\u{1F1F8}\u{1F1EA}',
    'no': '\u{1F1F3}\u{1F1F4}',
    'da': '\u{1F1E9}\u{1F1F0}',
    'fi': '\u{1F1EB}\u{1F1EE}',
    'el': '\u{1F1EC}\u{1F1F7}',
    'cs': '\u{1F1E8}\u{1F1FF}',
    'ro': '\u{1F1F7}\u{1F1F4}',
    'hu': '\u{1F1ED}\u{1F1FA}',
    'th': '\u{1F1F9}\u{1F1ED}',
    'vi': '\u{1F1FB}\u{1F1F3}',
    'id': '\u{1F1EE}\u{1F1E9}',
    'ms': '\u{1F1F2}\u{1F1FE}',
    'tl': '\u{1F1F5}\u{1F1ED}',
    'uk': '\u{1F1FA}\u{1F1E6}',
    'he': '\u{1F1EE}\u{1F1F1}',
    'fa': '\u{1F1EE}\u{1F1F7}',
    'sw': '\u{1F1F0}\u{1F1EA}',
  };

  /// Get a short display code for a language
  static String _getShortCode(String language) {
    final lower = language.toLowerCase().trim();
    // If already a 2-letter code, return uppercase
    if (lower.length == 2) return lower.toUpperCase();
    // Return first 2 characters uppercase as abbreviation
    if (lower.length >= 2) {
      return lower.substring(0, 2).toUpperCase();
    }
    return language.toUpperCase();
  }

  /// Get flag emoji for a language (returns null if not found)
  static String? _getFlag(String language) {
    return _languageFlags[language.toLowerCase().trim()];
  }

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) return const SizedBox.shrink();

    final displayLanguages = languages.take(maxDisplay).toList();
    final remaining = languages.length - displayLanguages.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...displayLanguages.map((lang) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildChip(lang),
            )),
        if (remaining > 0)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 4 : 6,
              vertical: compact ? 1 : 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundInput,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              '+$remaining',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: compact ? 9 : 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChip(String language) {
    final flag = _getFlag(language);
    final code = _getShortCode(language);
    final isNative = nativeLanguage != null &&
        language.toLowerCase().trim() == nativeLanguage!.toLowerCase().trim();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: isNative
            ? AppColors.richGold.withValues(alpha: 0.12)
            : AppColors.backgroundInput,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: isNative
            ? Border.all(
                color: AppColors.richGold.withValues(alpha: 0.4),
                width: 0.5,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (flag != null) ...[
            Text(
              flag,
              style: TextStyle(fontSize: compact ? 10 : 12),
            ),
            SizedBox(width: compact ? 2 : 3),
          ],
          Text(
            code,
            style: TextStyle(
              color: isNative ? AppColors.richGold : AppColors.textSecondary,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
