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
import 'business_events_screen.dart';
import 'business_leads_screen.dart';
import 'business_storefront_screen.dart';
import 'promote_screen.dart';

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

  /// Opens the public storefront preview for the OWN business. Force
  /// [isBusiness] so the preview renders even before the account write settles.
  Future<void> _openStorefront(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BusinessStorefrontScreen(
          business: profile.copyWith(isBusiness: true),
          currentUserId: profile.userId,
        ),
      ),
    );
  }

  /// Opens the leads / enquiries list for this business (own uid).
  Future<void> _openLeads(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BusinessLeadsScreen(businessId: profile.userId),
      ),
    );
  }

  /// Opens the organizer's own events management surface, scoped to this
  /// business [Profile] so it can create/edit/manage the events it owns.
  Future<void> _openManageEvents(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BusinessEventsScreen(profile: profile),
      ),
    );
  }

  /// Opens the promote surface (share/boost the business + its events).
  Future<void> _openPromote(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PromoteScreen(business: profile),
      ),
    );
  }

  /// Verification (request + status) lives inside the Business account screen,
  /// so route there where the request/pending/approved flow is wired.
  Future<void> _openVerification(BuildContext context) => _openBusinessAccount(context);

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
            const SizedBox(height: 16),
            EditSectionCard(
              title: l10n.businessEventsTitle,
              subtitle: l10n.businessSectionSubtitle,
              icon: Icons.event_note,
              onTap: () => _openManageEvents(context),
            ),
            const SizedBox(height: 16),
            EditSectionCard(
              title: l10n.promoteTitle,
              subtitle: l10n.featureThisEvent,
              icon: Icons.campaign,
              onTap: () => _openPromote(context),
            ),
            const SizedBox(height: 16),
            EditSectionCard(
              title: l10n.viewStorefront,
              subtitle: profile.businessName ?? l10n.businessProfileLabel,
              icon: Icons.storefront_outlined,
              onTap: () => _openStorefront(context),
            ),
            const SizedBox(height: 16),
            EditSectionCard(
              title: l10n.businessLeadsTitle,
              subtitle: l10n.businessContact,
              icon: Icons.inbox_outlined,
              onTap: () => _openLeads(context),
            ),
            const SizedBox(height: 16),
            EditSectionCard(
              title: l10n.requestVerification,
              subtitle: profile.businessVerified
                  ? l10n.businessVerifiedLabel
                  : l10n.requestVerificationMessage,
              icon: profile.businessVerified
                  ? Icons.verified
                  : Icons.verified_outlined,
              onTap: () => _openVerification(context),
            ),
          ],
        ),
      ),
    );
  }
}
