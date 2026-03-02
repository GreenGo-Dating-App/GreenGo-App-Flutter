import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/community.dart';

/// Community Card Widget
///
/// Displays a community in a list/grid with name, type, member count,
/// languages, last message preview, and activity time
class CommunityCard extends StatelessWidget {
  final Community community;
  final VoidCallback? onTap;
  final bool showUnreadIndicator;

  const CommunityCard({
    super.key,
    required this.community,
    this.onTap,
    this.showUnreadIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.marginM,
          vertical: AppDimensions.marginXS,
        ),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Community avatar / type icon
            _buildAvatar(),
            const SizedBox(width: AppDimensions.paddingM),

            // Community info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + type badge row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          community.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showUnreadIndicator)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.richGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Type badge + member count
                  Row(
                    children: [
                      _buildTypeBadge(),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${community.memberCount}',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      if (community.languages.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ..._buildLanguageBadges(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Last message preview + time
                  if (community.lastMessagePreview != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            community.lastMessagePreview!,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          community.lastActivityText,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _getTypeColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: community.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: Image.network(
                community.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildTypeIcon(),
              ),
            )
          : _buildTypeIcon(),
    );
  }

  Widget _buildTypeIcon() {
    return Center(
      child: Icon(
        _getTypeIconData(),
        color: _getTypeColor(),
        size: 24,
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getTypeColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        community.type.displayName,
        style: TextStyle(
          color: _getTypeColor(),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<Widget> _buildLanguageBadges() {
    return community.languages.take(2).map((lang) {
      return Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.backgroundInput,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          lang.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }).toList();
  }

  IconData _getTypeIconData() {
    switch (community.type) {
      case CommunityType.languageCircle:
        return Icons.translate;
      case CommunityType.culturalInterest:
        return Icons.public;
      case CommunityType.travelGroup:
        return Icons.flight;
      case CommunityType.localGuides:
        return Icons.location_on;
      case CommunityType.studyGroup:
        return Icons.menu_book;
      case CommunityType.general:
        return Icons.chat_bubble_outline;
    }
  }

  Color _getTypeColor() {
    switch (community.type) {
      case CommunityType.languageCircle:
        return AppColors.infoBlue;
      case CommunityType.culturalInterest:
        return AppColors.successGreen;
      case CommunityType.travelGroup:
        return AppColors.warningAmber;
      case CommunityType.localGuides:
        return AppColors.errorRed;
      case CommunityType.studyGroup:
        return AppColors.basePurple;
      case CommunityType.general:
        return AppColors.richGold;
    }
  }
}
