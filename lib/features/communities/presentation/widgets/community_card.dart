import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/community.dart';
import 'sponsored_badge.dart';

/// Community Card Widget
///
/// Displays a community in a list/grid with name, type, member count,
/// languages, last message preview, and activity time
class CommunityCard extends StatelessWidget {

  const CommunityCard({
    required this.community, super.key,
    this.onTap,
    this.showUnreadIndicator = false,
  });
  final Community community;
  final VoidCallback? onTap;
  final bool showUnreadIndicator;

  @override
  Widget build(BuildContext context) {
    // Mirror the Exchange (ConversationCard) row anatomy: a full-width row with
    // only a bottom divider (no rounded "card" box), leading avatar, an info
    // column (title + subtitle) and a trailing column (time + unread dot).
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.divider.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Community avatar / type icon
            _buildAvatar(),
            const SizedBox(width: 12),

            // Community info (title + subtitle)
            _buildInfo(),

            // Trailing (last activity time + unread indicator)
            _buildTrailing(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + type badge row
          Row(
            children: [
              Flexible(
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
              const SizedBox(width: 6),
              _buildTypeBadge(),
              if (community.isSponsored) ...[
                const SizedBox(width: 6),
                const SponsoredBadge(compact: true),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Subtitle: member count + languages + last message preview
          Row(
            children: [
              const Icon(
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
              if (community.lastMessagePreview != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    community.lastMessagePreview!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrailing() {
    final hasActivity = community.lastMessagePreview != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasActivity)
          Text(
            community.lastActivityText,
            style: TextStyle(
              color: showUnreadIndicator
                  ? AppColors.richGold
                  : AppColors.textTertiary,
              fontSize: 12,
              fontWeight:
                  showUnreadIndicator ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        if (showUnreadIndicator) ...[
          const SizedBox(height: 6),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.richGold,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 56,
      height: 56,
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
