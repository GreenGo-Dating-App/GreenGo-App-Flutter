import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/tier_gate.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../generated/app_localizations.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../events/presentation/screens/events_screen.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/widgets/edit_section_card.dart';
import 'business_account_screen.dart';

/// Business hub — the B2B home inside the user's Profile.
///
/// Groups every business-facing feature behind a single entry point so the
/// main profile menu stays uncluttered:
///  - Business account (turn a personal account into a business/venue account)
///  - Analytics (Platinum-gated organizer dashboard)
///  - Featured placements (promote/"Feature this event" from the Events surface)
///
/// It reuses [EditSectionCard] so the tiles match the rest of the profile menu,
/// and defers gating to [TierGate] / the destination screens themselves, so the
/// hub itself stays cheap to build and safe to open on any tier.
class BusinessHubScreen extends StatelessWidget {
  const BusinessHubScreen({required this.profile, super.key});

  final Profile profile;

  Future<void> _openBusinessAccount(BuildContext context) async {
    final profileBloc = context.read<ProfileBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: profileBloc,
          child: BusinessAccountScreen(profile: profile),
        ),
      ),
    );
  }

  /// Opens the analytics dashboard. [TierGate.ensureAnalytics] surfaces the
  /// upgrade dialog itself when the tier is below the analytics threshold.
  Future<void> _openAnalytics(BuildContext context) async {
    final uid = profile.userId;
    final tier = profile.membershipTier;
    final allowed =
        await TierGate().ensureAnalytics(context, uid, knownTier: tier);
    if (!allowed || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnalyticsScreen(userId: uid, tier: tier),
      ),
    );
  }

  /// Featured placements are created per-event via the Events surface
  /// ("Feature this event"), so route the business there.
  Future<void> _openFeatured(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventsScreen(currentUserId: profile.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => SafeNavigation.pop(context),
        ),
        title: Text(
          l10n.businessSectionTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.businessSectionSubtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            EditSectionCard(
              title: l10n.businessHubAccount,
              subtitle: profile.isBusiness
                  ? (profile.businessName ?? l10n.businessProfileLabel)
                  : l10n.businessAccountTitle,
              icon: Icons.storefront,
              onTap: () => _openBusinessAccount(context),
            ),
            const SizedBox(height: 16),
            EditSectionCard(
              title: l10n.businessHubAnalytics,
              subtitle: l10n.personalStatisticsSubtitle,
              icon: Icons.insights,
              onTap: () => _openAnalytics(context),
            ),
            const SizedBox(height: 16),
            EditSectionCard(
              title: l10n.businessHubFeatured,
              subtitle: l10n.featureThisEvent,
              icon: Icons.star_outline,
              onTap: () => _openFeatured(context),
            ),
          ],
        ),
      ),
    );
  }
}
