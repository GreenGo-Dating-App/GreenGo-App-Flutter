import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/language_progress.dart';
import '../../domain/entities/supported_language.dart';

/// Horizontal scrollable list of language cards the user is currently learning.
/// Each card shows the flag, language name, proficiency badge, and XP progress.
class YourLanguagesSection extends StatelessWidget {
  final List<LanguageProgress> languageProgress;
  final Function(String languageCode) onLanguageTap;

  const YourLanguagesSection({
    super.key,
    required this.languageProgress,
    required this.onLanguageTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (languageProgress.isEmpty) {
      return _buildEmptyState(l10n);
    }

    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: languageProgress.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _LanguageCard(
            progress: languageProgress[index],
            onTap: () => onLanguageTap(languageProgress[index].languageCode),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations? l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            color: AppColors.richGold.withValues(alpha: 0.6),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.noLanguagesYet ?? 'No languages yet. Start learning!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual language card within the horizontal list.
class _LanguageCard extends StatelessWidget {
  final LanguageProgress progress;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.progress,
    required this.onTap,
  });

  /// Calculates a normalized XP fraction for the mini progress bar.
  /// Uses the proficiency thresholds from LanguageProficiencyExtension.
  double _xpFraction() {
    final current = progress.proficiency;
    final proficiencies = LanguageProficiency.values;
    final idx = proficiencies.indexOf(current);

    // Current tier required words
    final currentRequired = current.requiredWords;

    // Next tier required words, or use a reasonable ceiling
    final int nextRequired;
    if (idx < proficiencies.length - 1) {
      nextRequired = proficiencies[idx + 1].requiredWords;
    } else {
      // Already at max proficiency
      return 1.0;
    }

    final range = nextRequired - currentRequired;
    if (range <= 0) return 1.0;
    final withinRange = progress.wordsLearned - currentRequired;
    return (withinRange / range).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final language = SupportedLanguage.getByCode(progress.languageCode);
    final flag = language?.flag ?? '';
    final langName = language?.name ?? progress.languageName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Flag emoji
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),

            // Language name
            Text(
              langName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),

            // Proficiency badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.richGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${progress.proficiency.emoji} ${progress.proficiency.displayName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const Spacer(),

            // Mini XP progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _xpFraction(),
                minHeight: 5,
                backgroundColor: AppColors.divider,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.richGold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
