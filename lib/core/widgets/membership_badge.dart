import 'package:flutter/material.dart';
import '../../../features/membership/domain/entities/membership.dart';
import '../constants/app_colors.dart';

/// Membership Badge Widget
/// Displays a visual badge indicating the user's membership tier
class MembershipBadge extends StatelessWidget {
  final MembershipTier tier;
  final bool compact;
  final VoidCallback? onTap;

  const MembershipBadge({
    Key? key,
    required this.tier,
    this.compact = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactBadge();
    }
    return _buildFullBadge();
  }

  Widget _buildCompactBadge() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: _getGradient(),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _getPrimaryColor().withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(),
              color: Colors.white,
              size: 14,
            ),
            if (tier != MembershipTier.free) ...[
              const SizedBox(width: 4),
              Text(
                _getShortLabel(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullBadge() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: _getGradient(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getPrimaryColor().withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(),
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              tier.displayName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (tier) {
      case MembershipTier.free:
        return Icons.person;
      case MembershipTier.silver:
        return Icons.workspace_premium;
      case MembershipTier.gold:
        return Icons.star;
      case MembershipTier.platinum:
        return Icons.diamond;
      case MembershipTier.test:
        return Icons.science;
    }
  }

  String _getShortLabel() {
    switch (tier) {
      case MembershipTier.free:
        return '';
      case MembershipTier.silver:
        return 'VIP';
      case MembershipTier.gold:
        return 'VIP';
      case MembershipTier.platinum:
        return 'VIP';
      case MembershipTier.test:
        return 'TEST';
    }
  }

  Color _getPrimaryColor() {
    switch (tier) {
      case MembershipTier.free:
        return AppColors.basePurple;
      case MembershipTier.silver:
        return const Color(0xFFC0C0C0); // Silver
      case MembershipTier.gold:
        return AppColors.richGold;
      case MembershipTier.platinum:
        return AppColors.platinumBlue;
      case MembershipTier.test:
        return Colors.blue;
    }
  }

  LinearGradient _getGradient() {
    switch (tier) {
      case MembershipTier.free:
        return const LinearGradient(
          colors: [AppColors.basePurple, AppColors.basePurpleDark],
        );
      case MembershipTier.silver:
        return const LinearGradient(
          colors: [Color(0xFFE0E0E0), Color(0xFFA0A0A0)],
        );
      case MembershipTier.gold:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
        );
      case MembershipTier.platinum:
        return const LinearGradient(
          colors: [AppColors.platinumBlue, AppColors.platinumBlueDark],
        );
      case MembershipTier.test:
        return const LinearGradient(
          colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
        );
    }
  }

  /// Get tier-specific border color for profile cards
  static Color getBorderColor(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return AppColors.basePurple;
      case MembershipTier.silver:
        return const Color(0xFFC0C0C0);
      case MembershipTier.gold:
        return AppColors.richGold;
      case MembershipTier.platinum:
        return AppColors.platinumBlue;
      case MembershipTier.test:
        return Colors.blue;
    }
  }

  /// Get tier-specific gradient for profile cards
  static LinearGradient? getCardGradient(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.basePurple.withOpacity(0.1),
            AppColors.basePurpleDark.withOpacity(0.05),
          ],
        );
      case MembershipTier.silver:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFC0C0C0).withOpacity(0.1),
            const Color(0xFFA0A0A0).withOpacity(0.05),
          ],
        );
      case MembershipTier.gold:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.richGold.withOpacity(0.1),
            const Color(0xFFB8860B).withOpacity(0.05),
          ],
        );
      case MembershipTier.platinum:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.platinumBlue.withOpacity(0.1),
            AppColors.platinumBlueDark.withOpacity(0.05),
          ],
        );
      default:
        return null;
    }
  }
}

/// Small inline membership indicator for app bar
class MembershipIndicator extends StatelessWidget {
  final MembershipTier tier;
  final VoidCallback? onTap;

  const MembershipIndicator({
    Key? key,
    required this.tier,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Don't show anything for free tier
    if (tier == MembershipTier.free) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _getGradient(),
          boxShadow: [
            BoxShadow(
              color: _getPrimaryColor().withOpacity(0.4),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          _getIcon(),
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (tier) {
      case MembershipTier.free:
        return Icons.person;
      case MembershipTier.silver:
        return Icons.workspace_premium;
      case MembershipTier.gold:
        return Icons.star;
      case MembershipTier.platinum:
        return Icons.diamond;
      case MembershipTier.test:
        return Icons.science;
    }
  }

  Color _getPrimaryColor() {
    switch (tier) {
      case MembershipTier.free:
        return AppColors.basePurple;
      case MembershipTier.silver:
        return const Color(0xFFC0C0C0);
      case MembershipTier.gold:
        return AppColors.richGold;
      case MembershipTier.platinum:
        return AppColors.platinumBlue;
      case MembershipTier.test:
        return Colors.blue;
    }
  }

  LinearGradient _getGradient() {
    switch (tier) {
      case MembershipTier.free:
        return const LinearGradient(
          colors: [AppColors.basePurple, AppColors.basePurpleDark],
        );
      case MembershipTier.silver:
        return const LinearGradient(
          colors: [Color(0xFFE0E0E0), Color(0xFFA0A0A0)],
        );
      case MembershipTier.gold:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
        );
      case MembershipTier.platinum:
        return const LinearGradient(
          colors: [AppColors.platinumBlue, AppColors.platinumBlueDark],
        );
      case MembershipTier.test:
        return const LinearGradient(
          colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
        );
    }
  }
}
