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

  /// The feature rows for this package, read from the real entitlements.
  ///
  /// Each row passes a LITERAL `Icons.x` straight to the builder. That is
  /// deliberate: Flutter shaves unused glyphs out of the icon font by static
  /// analysis of the use site, and an IconData tucked inside a record or a
  /// variable is not recognised as used - which is exactly why these icons
  /// came out blank the first time.
  List<Widget> _featureRows(AppLocalizations l10n, bool reduceMotion) {
    final t = _tier;
    String count(int? v) => v == null ? l10n.featureUnlimited : '$v';

    final rows = <Widget>[];
    void add(Widget row) => rows.add(_animated(row, rows.length, reduceMotion));

    add(_plainRow(
      const Icon(Icons.chat_bubble_outline, size: 20),
      l10n.featureDailyConnects(count(TierEntitlements.maxDailyConnects(t))),
    ));
    add(_plainRow(
      const Icon(Icons.monetization_on_outlined, size: 20),
      l10n.featureMonthlyCoins(TierEntitlements.monthlyCoins(t)),
    ));
    add(_plainRow(
      const Icon(Icons.event_available_outlined, size: 20),
      l10n.featureEvents(count(TierEntitlements.maxEvents(t))),
    ));
    // Omitted rather than shown as zero: the Base pack grants no boosts, and
    // "0 profile boosts a month" is not a feature.
    if (TierEntitlements.boostsPerMonth(t) > 0) {
      add(_plainRow(
        const Icon(Icons.rocket_launch_outlined, size: 20),
        l10n.featureBoosts(TierEntitlements.boostsPerMonth(t)),
      ));
    }
    add(_plainRow(
      const Icon(Icons.visibility_outlined, size: 20),
      l10n.featureDiscoveryReveals(TierEntitlements.discoveryFreeReveal(t)),
    ));

    // Perks that only exist above a certain tier - listed only when included,
    // so this reads as "what you get", never "what you do not".
    if (TierEntitlements.travelModeEnabled(t)) {
      add(_plainRow(
        const Icon(Icons.flight_takeoff, size: 20),
        l10n.featureTravelMode,
      ));
    } else if (TierEntitlements.canSeeWhoConnected(t)) {
      add(_plainRow(
        const Icon(Icons.people_alt_outlined, size: 20),
        l10n.featureWhoConnected,
      ));
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final offer = widget.offer;
    final features = _featureRows(l10n, reduceMotion);

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
                    ...features,
                    if ((offer.baseMembershipDays ?? 0) > 0) ...[
                      const SizedBox(height: 4),
                      _plainRow(
                        const Icon(Icons.verified_outlined, size: 20),
                        l10n.offerBaseLine(
                          humaniseDuration(l10n, offer.baseMembershipDays!),
                        ),
                      ),
                    ],
                    if ((offer.coins ?? 0) > 0)
                      _plainRow(
                        const Icon(Icons.savings_outlined, size: 20),
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

  /// Wraps a row in the staggered entrance, unless motion is reduced.
  Widget _animated(Widget row, int index, bool reduceMotion) {
    if (reduceMotion) return row;
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

  Widget _plainRow(Icon icon, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTheme(
              data: IconThemeData(color: _gradient.last, size: 20),
              child: icon,
            ),
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
