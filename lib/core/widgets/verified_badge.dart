import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../services/user_directory_service.dart';

/// THE "Verified" badge (one badge everywhere): shown next to a user's name
/// when GreenGo has APPROVED their identity document.
///
/// Source of truth: the server-owned profile flag `isAgeVerified` (set only by
/// the document-verification functions), exposed as [UserBrief.idVerified].
/// Banned / inactive accounts never show it ([UserBrief.showVerifiedBadge]).
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 14, this.showLabel = false});

  final double size;

  /// Adds the word "Verified" after the check (profile headers, host rows).
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final icon = Icon(Icons.verified_rounded,
        size: size, color: AppColors.richGold);
    return Tooltip(
      message: l.verifiedBadgeTooltip,
      child: Semantics(
        label: l.verifiedBadgeTooltip,
        child: showLabel
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                icon,
                const SizedBox(width: 3),
                Text(l.verifiedBadgeLabel,
                    style: TextStyle(
                        color: AppColors.richGold,
                        fontSize: size * 0.85,
                        fontWeight: FontWeight.w600)),
              ])
            : icon,
      ),
    );
  }
}

/// [VerifiedBadge] for [uid], read from the cached + batched
/// [UserDirectoryService] brief (no extra reads where the name is already
/// resolved). Renders nothing until resolved / when not verified.
class UserVerifiedBadge extends StatelessWidget {
  const UserVerifiedBadge({
    super.key,
    required this.uid,
    this.size = 14,
    this.showLabel = false,
    this.padding = const EdgeInsets.only(left: 4),
  });

  final String uid;
  final double size;
  final bool showLabel;
  final EdgeInsetsGeometry padding;

  /// Pure visibility rule (unit-tested).
  static bool isVisible(UserBrief? brief) => brief?.showVerifiedBadge ?? false;

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: UserDirectoryService.instance,
      builder: (context, _) {
        final brief = UserDirectoryService.instance.cached(uid);
        if (brief == null) UserDirectoryService.instance.resolve([uid]);
        if (!isVisible(brief)) return const SizedBox.shrink();
        return Padding(
          padding: padding,
          child: VerifiedBadge(size: size, showLabel: showLabel),
        );
      },
    );
  }
}

/// Plain round check (gold when [isPremium], blue otherwise). NOT the ID
/// badge — used for BUSINESS verification (storefronts), which has its own
/// tooltip. (This was the old `VerifiedBadge` visual.)
class CheckBadge extends StatelessWidget {
  const CheckBadge({
    super.key,
    this.size = 16,
    this.isPremium = false,
  });
  final double size;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isPremium ? AppColors.richGold : AppColors.infoBlue,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        size: size * 0.7,
        color: isPremium ? AppColors.deepBlack : Colors.white,
      ),
    );
  }
}

/// Business account badge — a gold "Business" pill shown on business profiles.
/// The [label] is passed in so the text stays localized.
class BusinessBadge extends StatelessWidget {
  const BusinessBadge({required this.label, super.key, this.size = 20});
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront, size: size * 0.75, color: AppColors.deepBlack),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.deepBlack,
              fontSize: size * 0.6,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium/Gold member badge
class PremiumBadge extends StatelessWidget {

  const PremiumBadge({
    super.key,
    this.size = 20,
  });
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            size: size * 0.8,
            color: AppColors.deepBlack,
          ),
          const SizedBox(width: 2),
          Text(
            'PRO', // i18n-ignore: tier badge label, same in all languages
            style: TextStyle(
              color: AppColors.deepBlack,
              fontSize: size * 0.6,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
