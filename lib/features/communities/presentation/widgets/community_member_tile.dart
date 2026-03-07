import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/community_member.dart';

/// Community Member Tile Widget
///
/// Displays a community member with avatar, name, role badge,
/// and local guide indicator
class CommunityMemberTile extends StatelessWidget {
  final CommunityMember member;
  final VoidCallback? onTap;
  final bool showRoleBadge;

  const CommunityMemberTile({
    super.key,
    required this.member,
    this.onTap,
    this.showRoleBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: 2,
      ),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.backgroundInput,
            backgroundImage: member.photoUrl != null
                ? NetworkImage(member.photoUrl!)
                : null,
            child: member.photoUrl == null
                ? Text(
                    member.displayName.isNotEmpty
                        ? member.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          // Local guide badge
          if (member.isLocalGuide)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.backgroundCard,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 10,
                  color: AppColors.pureWhite,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.displayName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showRoleBadge && member.role != CommunityRole.member) ...[
            const SizedBox(width: 8),
            _buildRoleBadge(),
          ],
        ],
      ),
      subtitle: member.languages.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.translate,
                    size: 12,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    member.languages.map((l) => l.toUpperCase()).join(', '),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : null,
      trailing: member.isLocalGuide
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppLocalizations.of(context)!.communitiesGuide,
                style: const TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildRoleBadge() {
    Color badgeColor;
    switch (member.role) {
      case CommunityRole.owner:
        badgeColor = AppColors.richGold;
      case CommunityRole.admin:
        badgeColor = AppColors.infoBlue;
      case CommunityRole.member:
        badgeColor = AppColors.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        member.role.displayName,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
