import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';

/// A bottom sheet widget that presents multilingual video prompts
/// for users to choose from when recording their video introduction.
class VideoPromptSelector extends StatelessWidget {

  const VideoPromptSelector({
    required this.onPromptSelected, super.key,
  });
  /// Callback when a prompt is selected. Receives the value stored on the
  /// video doc ([videoPromptStoredValue]); display it via [localizedVideoPrompt].
  final void Function(String storedPrompt) onPromptSelected;

  /// Show the prompt selector as a modal bottom sheet.
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VideoPromptSelector(
        onPromptSelected: (prompt) {
          Navigator.pop(context, prompt);
        },
      ),
    );
  }

  /// Default prompts available for video introductions. The video doc keeps
  /// storing the English template ([videoPromptStoredValue]) so older app
  /// versions keep working; text is localized at display time via
  /// [localizedVideoPrompt].
  static const List<VideoPrompt> prompts = [
    VideoPrompt(id: 'introduce_yourself', icon: Icons.waving_hand),
    VideoPrompt(id: 'native_language', icon: Icons.translate),
    VideoPrompt(id: 'teach_phrase', icon: Icons.school),
    VideoPrompt(id: 'favorite_place', icon: Icons.place),
    VideoPrompt(id: 'cultural_exchange', icon: Icons.public),
    VideoPrompt(id: 'hidden_talent', icon: Icons.auto_awesome),
    VideoPrompt(id: 'dream_trip', icon: Icons.flight),
    VideoPrompt(id: VideoPrompt.freeStyleId, icon: Icons.mic),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXL),
          topRight: Radius.circular(AppDimensions.radiusXL),
        ),
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
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              children: [
                Text(
                  l10n.videoPromptSelectorTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.videoPromptSelectorSubtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Prompt cards
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingL,
              ),
              shrinkWrap: true,
              itemCount: prompts.length,
              itemBuilder: (context, index) {
                final prompt = prompts[index];
                return _PromptCard(
                  prompt: prompt,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onPromptSelected(videoPromptStoredValue(prompt.id));
                  },
                );
              },
            ),
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

/// A prompt card widget displayed in the selector list.
class _PromptCard extends StatelessWidget {

  const _PromptCard({
    required this.prompt,
    required this.onTap,
  });
  final VideoPrompt prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundInput,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    prompt.icon,
                    color: AppColors.richGold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prompt.title(l10n),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prompt.description(l10n),
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Data class representing a video recording prompt.
class VideoPrompt {

  const VideoPrompt({
    required this.id,
    required this.icon,
  });

  static const String freeStyleId = 'free_style';

  /// Stable id stored on the video doc. Never change existing ids.
  final String id;
  final IconData icon;

  String title(AppLocalizations l10n) {
    switch (id) {
      case 'introduce_yourself':
        return l10n.videoPromptIntroduceTitle;
      case 'native_language':
        return l10n.videoPromptNativeTitle;
      case 'teach_phrase':
        return l10n.videoPromptTeachTitle;
      case 'favorite_place':
        return l10n.videoPromptPlaceTitle;
      case 'cultural_exchange':
        return l10n.videoPromptCultureTitle;
      case 'hidden_talent':
        return l10n.videoPromptTalentTitle;
      case 'dream_trip':
        return l10n.videoPromptTripTitle;
      default:
        return l10n.videoPromptFreeTitle;
    }
  }

  String description(AppLocalizations l10n) {
    switch (id) {
      case 'introduce_yourself':
        return l10n.videoPromptIntroduceDesc;
      case 'native_language':
        return l10n.videoPromptNativeDesc;
      case 'teach_phrase':
        return l10n.videoPromptTeachDesc;
      case 'favorite_place':
        return l10n.videoPromptPlaceDesc;
      case 'cultural_exchange':
        return l10n.videoPromptCultureDesc;
      case 'hidden_talent':
        return l10n.videoPromptTalentDesc;
      case 'dream_trip':
        return l10n.videoPromptTripDesc;
      default:
        return l10n.videoPromptFreeDesc;
    }
  }
}

// Canonical English prompt texts stored on video docs, mapped to the stable
// ids so they display localized.
const Map<String, String> _legacyVideoPromptTexts = {
  'Introduce yourself in your favorite language': 'introduce_yourself',
  'Say something in your native language': 'native_language',
  'Teach us a phrase in your language': 'teach_phrase',
  "What's your favorite place to visit?": 'favorite_place',
  'Describe your ideal cultural exchange': 'cultural_exchange',
  'Show us a hidden talent or fun fact about you': 'hidden_talent',
  'Describe your dream travel destination': 'dream_trip',
  'Free style - no prompt': VideoPrompt.freeStyleId,
};

/// Value stored on the video doc for prompt [id]: the canonical English
/// template (what every app version already stores and understands).
String videoPromptStoredValue(String id) {
  for (final e in _legacyVideoPromptTexts.entries) {
    if (e.value == id) return e.key;
  }
  return id;
}

/// Localized prompt text for a stored `prompt` value (a prompt id, or a
/// legacy English template). Unknown values are shown as-is.
String localizedVideoPrompt(AppLocalizations l10n, String stored) {
  final id = _legacyVideoPromptTexts[stored] ?? stored;
  switch (id) {
    case 'introduce_yourself':
      return l10n.videoPromptIntroduceTemplate;
    case 'native_language':
      return l10n.videoPromptNativeTemplate;
    case 'teach_phrase':
      return l10n.videoPromptTeachTemplate;
    case 'favorite_place':
      return l10n.videoPromptPlaceTemplate;
    case 'cultural_exchange':
      return l10n.videoPromptCultureTemplate;
    case 'hidden_talent':
      return l10n.videoPromptTalentTemplate;
    case 'dream_trip':
      return l10n.videoPromptTripTemplate;
    case VideoPrompt.freeStyleId:
      return l10n.videoPromptFreeTemplate;
    default:
      return stored;
  }
}
