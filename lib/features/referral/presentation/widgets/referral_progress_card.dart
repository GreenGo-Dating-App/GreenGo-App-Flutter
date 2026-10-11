import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/services/referral_service.dart';

/// Localized tier name for a referral milestone.
String referralTierName(AppLocalizations l10n, ReferralMilestoneTier tier) {
  switch (tier) {
    case ReferralMilestoneTier.silver:
      return l10n.membershipSilver;
    case ReferralMilestoneTier.gold:
      return l10n.membershipGold;
    case ReferralMilestoneTier.platinum:
      return l10n.membershipPlatinum;
  }
}

/// Invite progress + milestone ladder (5 -> Silver, 10 -> Gold,
/// 20 -> Platinum), driven by the server-authoritative [progress].
class ReferralProgressCard extends StatelessWidget {
  const ReferralProgressCard({super.key, required this.progress});

  final ReferralProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final next = progress.nextMilestone;
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events,
                  color: AppColors.richGold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.referralMilestonesTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.referralFriendsJoined(progress.invitedCount),
            key: const Key('referralFriendsJoined'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            next == null
                ? l10n.referralAllMilestonesUnlocked
                : l10n.referralMoreToTier(
                    progress.remainingToNext,
                    referralTierName(l10n, next.tier),
                  ),
            key: const Key('referralNextMilestone'),
            style: const TextStyle(
              color: AppColors.richGold,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _ladderFraction(progress.invitedCount),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.richGold),
            ),
          ),
          const SizedBox(height: 12),
          for (final m in ReferralService.milestones)
            _MilestoneRow(
              milestone: m,
              unlocked: progress.isUnlocked(m),
            ),
        ],
      ),
    );
  }

  static double _ladderFraction(int count) {
    final top = ReferralService.milestones.last.count;
    if (count <= 0) return 0;
    return count >= top ? 1 : count / top;
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone, required this.unlocked});

  final ReferralMilestone milestone;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      key: Key('referralMilestone_${milestone.count}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.check_circle : Icons.radio_button_unchecked,
            key: Key(
              unlocked
                  ? 'referralMilestoneUnlocked_${milestone.count}'
                  : 'referralMilestoneLocked_${milestone.count}',
            ),
            color: unlocked ? AppColors.richGold : AppColors.textSecondary,
            size: 22,
            semanticLabel: unlocked ? l10n.referralMilestoneUnlocked : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.referralMilestoneFriends(milestone.count),
              style: TextStyle(
                color:
                    unlocked ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              l10n.referralMilestoneReward(
                referralTierName(l10n, milestone.tier),
              ),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: unlocked ? AppColors.richGold : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
