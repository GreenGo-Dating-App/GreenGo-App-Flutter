import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/membership_badge.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../domain/entities/match.dart';

/// Match Card Widget
///
/// Displays a match in the matches list with photo, info, and compatibility
class MatchCardWidget extends StatelessWidget {
  final Match match;
  final Profile? profile;
  final String currentUserId;
  final double? compatibilityPercent;
  final VoidCallback? onTap;

  const MatchCardWidget({
    super.key,
    required this.match,
    this.profile,
    required this.currentUserId,
    this.compatibilityPercent,
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
                            width: 64,
                            height: 64,
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
                    // Name, age, city
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _buildTitleText(),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight:
                                  isNewMatch ? FontWeight.bold : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                    // Compatibility percentage
                    if (compatibilityPercent != null)
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            color: _getCompatibilityColor(compatibilityPercent!),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${compatibilityPercent!.toStringAsFixed(0)}% compatible',
                            style: TextStyle(
                              color: _getCompatibilityColor(compatibilityPercent!),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    // Last message or time
                    Text(
                      _formatLastMessage(match.lastMessage) ?? match.timeSinceMatchText,
                      style: TextStyle(
                        color: match.unreadCount > 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: match.unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  String _buildTitleText() {
    if (profile == null) return 'Match';
    final name = profile!.displayName;
    final age = profile!.age;
    final city = profile!.effectiveLocation.city;

    final parts = <String>[name];
    if (age > 0) parts.add('$age');
    if (city.isNotEmpty) parts.add(city);

    return parts.join(', ');
  }

  Color _getCompatibilityColor(double percent) {
    if (percent >= 70) return const Color(0xFF4CAF50); // Green
    if (percent >= 50) return AppColors.richGold;
    return AppColors.textSecondary;
  }

  /// Formats the last message for display — replaces raw URLs with friendly labels
  String? _formatLastMessage(String? message) {
    if (message == null || message.isEmpty) return null;
    final lower = message.toLowerCase();
    // Firebase Storage URLs for media
    if (lower.contains('firebasestorage.googleapis.com') || lower.startsWith('https://storage.googleapis.com')) {
      if (lower.contains('.mp4') || lower.contains('.mov') || lower.contains('.avi') || lower.contains('video')) {
        return '🎥 Video';
      }
      if (lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('.png') || lower.contains('.webp') || lower.contains('image')) {
        return '📷 Photo';
      }
      if (lower.contains('.m4a') || lower.contains('.aac') || lower.contains('.mp3') || lower.contains('voice') || lower.contains('audio')) {
        return '🎤 Voice message';
      }
      return '📎 Attachment';
    }
    return message;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.backgroundInput,
      child: const Icon(
        Icons.person,
        color: AppColors.textTertiary,
        size: 30,
      ),
    );
  }
}
