import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/tier_entitlements.dart';
import '../../../../generated/app_localizations.dart';
import '../../../membership/domain/entities/membership.dart';
import 'pre_registration_offer.dart';

/// The reveal shown once the email is entered on the Create Account screen.
///
/// Announces what the address is entitled to - a pre-registration tier, or the
/// 2026 welcome pack - and then shows WHAT THAT ACTUALLY BUYS, drawn from
/// [TierEntitlements] rather than from a hand-written list, so the promise
/// cannot drift away from the entitlements the app really enforces.
///
/// The animation is staggered: the badge scales in, then each feature slides up
/// in turn. It is skipped entirely when the platform asks for reduced motion -
/// an "amazing animation" that ignores that setting is just an accessibility
/// problem with good art direction.
class TierRevealDialog extends StatefulWidget {
  const TierRevealDialog({required this.offer, super.key});

  final PreRegistrationOffer offer;

  @override
  State<TierRevealDialog> createState() => _TierRevealDialogState();
}

class _TierRevealDialogState extends State<TierRevealDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// How many feature rows we stagger. Kept in one place so the intervals
  /// below cannot drift out of step with the list actually rendered.
  static const int _maxRows = 6;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    // Start after the first frame so the dialog's own entrance does not fight
    // the stagger.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  MembershipTier get _tier {
    switch (widget.offer.tier?.toUpperCase()) {
      case 'PLATINUM':
        return MembershipTier.platinum;
      case 'GOLD':
        return MembershipTier.gold;
      case 'SILVER':
        return MembershipTier.silver;
      default:
        return MembershipTier.free;
    }
  }

  /// Tier palette. Base/welcome uses the brand green so the standard pack still
  /// feels like a gift rather than a consolation prize.
  List<Color> get _gradient {
    switch (_tier) {
      case MembershipTier.platinum:
        return [AppColors.platinumBlueDark, AppColors.platinumBlue];
      case MembershipTier.gold:
        return [const Color(0xFFB8860B), AppColors.richGold];
      case MembershipTier.silver:
        return [const Color(0xFF757575), const Color(0xFFBDBDBD)];
      default:
        return [const Color(0xFF1B5E20), const Color(0xFF43A047)];
    }
  }

  IconData get _icon {
    switch (_tier) {
      case MembershipTier.platinum:
        return Icons.workspace_premium;
      case MembershipTier.gold:
        return Icons.military_tech;
      case MembershipTier.silver:
        return Icons.star;
      default:
        return Icons.card_giftcard;
    }
  }

  /// The features this package includes, read from the real entitlements.
  List<({IconData icon, String label})> _features(AppLocalizations l10n) {
    final t = _tier;
    String count(int? v) => v == null ? l10n.featureUnlimited : '$v';

    final rows = <({IconData icon, String label})>[
      (
        icon: Icons.chat_bubble_outline,
        label: l10n.featureDailyConnects(count(TierEntitlements.maxDailyConnects(t))),
      ),
      (
        icon: Icons.monetization_on_outlined,
        label: l10n.featureMonthlyCoins(TierEntitlements.monthlyCoins(t)),
      ),
      (
        icon: Icons.event_available_outlined,
        label: l10n.featureEvents(count(TierEntitlements.maxEvents(t))),
      ),
      // Boosts are omitted rather than shown as zero: the Base pack grants
      // none, and "0 profile boosts a month" is not a feature.
      if (TierEntitlements.boostsPerMonth(t) > 0)
        (
          icon: Icons.rocket_launch_outlined,
          label: l10n.featureBoosts(TierEntitlements.boostsPerMonth(t)),
        ),
      (
        icon: Icons.visibility_outlined,
        label: l10n.featureDiscoveryReveals(TierEntitlements.discoveryFreeReveal(t)),
      ),
    ];

    // Perks that only exist above a certain tier - shown only when included,
    // so the list reads as "what you get", never "what you do not".
    if (TierEntitlements.travelModeEnabled(t)) {
      rows.add((icon: Icons.flight_takeoff, label: l10n.featureTravelMode));
    } else if (TierEntitlements.canSeeWhoConnected(t)) {
      rows.add((icon: Icons.people_alt_outlined, label: l10n.featureWhoConnected));
    }

    return rows.take(_maxRows).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final offer = widget.offer;
    final features = _features(l10n);

    final headline = offer.isPreRegistration && offer.tier != null
        ? offer.tier!
        : l10n.offerWelcomePackTitle;

    final subtitle = offer.isPreRegistration
        ? (offer.membershipDays != null
            ? l10n.offerTierLine(
                offer.tier ?? '',
                humaniseDuration(l10n, offer.membershipDays!),
              )
            : '')
        : l10n.offerFreeMonthLine;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.backgroundCard,
            border: Border.all(color: _gradient.last.withValues(alpha: 0.6)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(l10n, headline, subtitle, reduceMotion),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.featureIncludedTitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < features.length; i++)
                      _featureRow(features[i], i, reduceMotion),
                    if ((offer.baseMembershipDays ?? 0) > 0) ...[
                      const SizedBox(height: 4),
                      _plainRow(
                        Icons.verified_outlined,
                        l10n.offerBaseLine(
                          humaniseDuration(l10n, offer.baseMembershipDays!),
                        ),
                      ),
                    ],
                    if ((offer.coins ?? 0) > 0)
                      _plainRow(
                        Icons.savings_outlined,
                        l10n.offerCoinsLine(offer.coins!),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.offerAppliedFromToday,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _gradient.last,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.ok),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(
    AppLocalizations l10n,
    String headline,
    String subtitle,
    bool reduceMotion,
  ) {
    final badge = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
      ),
      child: Icon(_icon, size: 40, color: Colors.white),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          if (reduceMotion)
            badge
          else
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: const Interval(0, 0.45, curve: Curves.elasticOut),
              ),
              child: badge,
            ),
          const SizedBox(height: 12),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 15,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _featureRow(
    ({IconData icon, String label}) f,
    int index,
    bool reduceMotion,
  ) {
    final row = _plainRow(f.icon, f.label);
    if (reduceMotion) return row;

    // Each row starts a little after the one before it.
    final start = 0.35 + (index * 0.09);
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        start.clamp(0.0, 0.95),
        (start + 0.25).clamp(0.05, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(curve),
        child: row,
      ),
    );
  }

  Widget _plainRow(IconData icon, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: _gradient.last),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
}
