import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/membership_badge.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../domain/entities/match.dart';

/// Match Card Widget
///
/// Displays a match in the matches list
class MatchCardWidget extends StatelessWidget {
  final Match match;
  final Profile? profile;
  final String currentUserId;
  final VoidCallback? onTap;

  const MatchCardWidget({
    super.key,
    required this.match,
    this.profile,
    required this.currentUserId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNewMatch = match.isNewMatch(currentUserId);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: isNewMatch ? AppColors.richGold : AppColors.divider,
              width: isNewMatch ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Profile photo
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    child: profile?.photoUrls.isNotEmpty == true
                        ? Image.network(
                            profile!.photoUrls.first,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),

                  // New match indicator
                  if (isNewMatch)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.richGold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          color: AppColors.deepBlack,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // Match info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile?.displayName ?? 'Match',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight:
                                isNewMatch ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        // Show membership badge if not free tier
                        if (profile != null && profile!.membershipTier != MembershipTier.free) ...[
                          const SizedBox(width: 6),
                          MembershipIndicator(tier: profile!.membershipTier),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match.lastMessage ?? 'Start chatting!',
                      style: TextStyle(
                        color: match.unreadCount > 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: match.unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match.timeSinceMatchText,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Indicators
              Column(
                children: [
                  if (match.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.richGold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${match.unreadCount}',
                        style: const TextStyle(
                          color: AppColors.deepBlack,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isNewMatch) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'NEW',
                      style: TextStyle(
                        color: AppColors.richGold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),

              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.backgroundInput,
      child: const Icon(
        Icons.person,
        color: AppColors.textTertiary,
        size: 30,
      ),
    );
  }
}
