import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #7: Message Reactions
/// Emoji reactions for chat messages
class MessageReactions extends StatelessWidget {
  final Map<String, int> reactions;
  final String? userReaction;
  final Function(String emoji)? onReactionTap;
  final Function(String emoji)? onReactionLongPress;

  const MessageReactions({
    super.key,
    required this.reactions,
    this.userReaction,
    this.onReactionTap,
    this.onReactionLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      children: reactions.entries.map((entry) {
        final isUserReaction = userReaction == entry.key;
        return GestureDetector(
          onTap: () => onReactionTap?.call(entry.key),
          onLongPress: () => onReactionLongPress?.call(entry.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isUserReaction
                  ? AppColors.richGold.withOpacity(0.3)
                  : AppColors.backgroundInput,
              borderRadius: BorderRadius.circular(12),
              border: isUserReaction
                  ? Border.all(color: AppColors.richGold, width: 1)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 14)),
                if (entry.value > 1) ...[
                  const SizedBox(width: 2),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      color: isUserReaction
                          ? AppColors.richGold
                          : AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Reaction picker popup
class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onReactionSelected;

  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
  });

  static const reactions = ['❤️', '😂', '😮', '😢', '😡', '👍', '👎'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions
            .map((emoji) => GestureDetector(
                  onTap: () => onReactionSelected(emoji),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
