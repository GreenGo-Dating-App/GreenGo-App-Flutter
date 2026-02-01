import 'package:flutter/material.dart';
import '../../domain/entities/vibe_tag.dart';

/// A single vibe tag chip widget
class VibeTagChip extends StatelessWidget {
  final VibeTag tag;
  final bool isSelected;
  final bool isTemporary;
  final bool isDisabled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const VibeTagChip({
    super.key,
    required this.tag,
    this.isSelected = false,
    this.isTemporary = false,
    this.isDisabled = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color backgroundColor;
    Color textColor;
    Color borderColor;

    if (isTemporary) {
      backgroundColor = colorScheme.tertiary.withOpacity(0.2);
      textColor = colorScheme.tertiary;
      borderColor = colorScheme.tertiary;
    } else if (isSelected) {
      backgroundColor = colorScheme.primary.withOpacity(0.2);
      textColor = colorScheme.primary;
      borderColor = colorScheme.primary;
    } else if (isDisabled) {
      backgroundColor = colorScheme.surface;
      textColor = colorScheme.onSurface.withOpacity(0.5);
      borderColor = colorScheme.outline.withOpacity(0.3);
    } else {
      backgroundColor = colorScheme.surface;
      textColor = colorScheme.onSurface;
      borderColor = colorScheme.outline;
    }

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isSelected || isTemporary ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag.emoji,
              style: TextStyle(
                fontSize: 16,
                color: isDisabled ? textColor.withOpacity(0.5) : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              tag.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isTemporary) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.timer_outlined,
                size: 14,
                color: colorScheme.tertiary,
              ),
            ],
            if (tag.isPremium && !isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.star,
                size: 14,
                color: Colors.amber.shade600,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mini version of vibe tag chip for profile display
class VibeTagMiniChip extends StatelessWidget {
  final VibeTag tag;
  final bool isTemporary;

  const VibeTagMiniChip({
    super.key,
    required this.tag,
    this.isTemporary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isTemporary
            ? colorScheme.tertiary.withOpacity(0.15)
            : colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag.emoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            tag.name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isTemporary ? colorScheme.tertiary : colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// List of vibe tag chips in a wrap layout
class VibeTagChipList extends StatelessWidget {
  final List<VibeTag> tags;
  final List<String> selectedTagIds;
  final String? temporaryTagId;
  final bool showAll;
  final int maxVisible;
  final Function(VibeTag)? onTagTap;
  final Function(VibeTag)? onTagLongPress;
  final bool isSelectable;
  final bool showPremiumBadge;
  final int? maxSelectable;

  const VibeTagChipList({
    super.key,
    required this.tags,
    this.selectedTagIds = const [],
    this.temporaryTagId,
    this.showAll = false,
    this.maxVisible = 5,
    this.onTagTap,
    this.onTagLongPress,
    this.isSelectable = true,
    this.showPremiumBadge = true,
    this.maxSelectable,
  });

  @override
  Widget build(BuildContext context) {
    final displayTags = showAll ? tags : tags.take(maxVisible).toList();
    final hiddenCount = tags.length - displayTags.length;

    final isAtLimit = maxSelectable != null &&
        selectedTagIds.length >= maxSelectable! &&
        isSelectable;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...displayTags.map((tag) {
          final isSelected = selectedTagIds.contains(tag.id);
          final isTemporary = tag.id == temporaryTagId;
          final isDisabled =
              isAtLimit && !isSelected && !isTemporary && isSelectable;

          return VibeTagChip(
            tag: tag,
            isSelected: isSelected,
            isTemporary: isTemporary,
            isDisabled: isDisabled,
            onTap: onTagTap != null ? () => onTagTap!(tag) : null,
            onLongPress:
                onTagLongPress != null ? () => onTagLongPress!(tag) : null,
          );
        }),
        if (hiddenCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
            ),
            child: Text(
              '+$hiddenCount more',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
      ],
    );
  }
}
