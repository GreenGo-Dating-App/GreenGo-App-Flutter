import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// A bottom sheet widget that presents multilingual video prompts
/// for users to choose from when recording their video introduction.
class VideoPromptSelector extends StatelessWidget {
  /// Callback when a prompt is selected.
  final void Function(String prompt) onPromptSelected;

  const VideoPromptSelector({
    super.key,
    required this.onPromptSelected,
  });

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

  /// Default prompts available for video introductions.
  static const List<VideoPrompt> prompts = [
    VideoPrompt(
      title: 'Introduce yourself',
      description: 'Say hello and tell us who you are',
      icon: Icons.waving_hand,
      template: 'Introduce yourself in your favorite language',
    ),
    VideoPrompt(
      title: 'Native language',
      description: 'Show off your mother tongue',
      icon: Icons.translate,
      template: 'Say something in your native language',
    ),
    VideoPrompt(
      title: 'Teach a phrase',
      description: 'Share something fun to say',
      icon: Icons.school,
      template: 'Teach us a phrase in your language',
    ),
    VideoPrompt(
      title: 'Favorite place',
      description: 'Share a place that means something to you',
      icon: Icons.place,
      template: "What's your favorite place to visit?",
    ),
    VideoPrompt(
      title: 'Cultural exchange',
      description: 'What does cultural exchange mean to you?',
      icon: Icons.public,
      template: 'Describe your ideal cultural exchange',
    ),
    VideoPrompt(
      title: 'Hidden talent',
      description: 'Surprise us with something unexpected',
      icon: Icons.auto_awesome,
      template: 'Show us a hidden talent or fun fact about you',
    ),
    VideoPrompt(
      title: 'Dream trip',
      description: 'Where in the world would you go?',
      icon: Icons.flight,
      template: 'Describe your dream travel destination',
    ),
    VideoPrompt(
      title: 'Free style',
      description: 'Say whatever you want!',
      icon: Icons.mic,
      template: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Choose a Prompt',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pick a topic for your video introduction',
                  style: TextStyle(
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
                    onPromptSelected(
                        prompt.template ?? 'Free style - no prompt');
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
  final VideoPrompt prompt;
  final VoidCallback onTap;

  const _PromptCard({
    required this.prompt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                        prompt.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prompt.description,
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
  final String title;
  final String description;
  final IconData icon;

  /// The template text for this prompt. Null means free-style (no prompt).
  final String? template;

  const VideoPrompt({
    required this.title,
    required this.description,
    required this.icon,
    this.template,
  });
}
