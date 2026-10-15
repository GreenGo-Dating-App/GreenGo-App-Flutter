import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/tier_entitlements.dart';
import '../../../../core/services/tier_gate.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../generated/app_localizations.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../explore/presentation/screens/qr_hub_screen.dart';
import '../../../finance_documents/presentation/screens/finance_documents_screen.dart';
import '../../../finance_documents/presentation/widgets/billing_status.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/widgets/edit_section_card.dart';
import '../../../ticket_payments/presentation/screens/get_paid_screen.dart';
import 'business_account_screen.dart';
import 'business_events_screen.dart';
import 'business_verification_request_screen.dart';
import 'business_leads_screen.dart';
import 'business_storefront_screen.dart';
import 'followers_screen.dart';
import 'promote_screen.dart';
import 'storefront_editor_screen.dart';

/// Business hub — the B2B home inside the user's Profile.
///
/// Groups every business-facing feature behind a single entry point so the
/// main profile menu stays uncluttered:
///  - Business account (turn a personal account into a business/venue account)
///  - Analytics (Platinum-gated organizer dashboard)
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
    final tier = profile.effectiveTier;
    final allowed =
        await TierGate().ensureAnalytics(context, uid, knownTier: tier);
    if (!allowed || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnalyticsScreen(userId: uid, tier: tier),
      ),
    );
  }

  /// Opens the editable storefront editor (name, description, gallery,
  /// opening hours…) for this business, carrying the shared [ProfileBloc] so
  /// edits propagate back to the profile without a manual reload. This entry
  /// moved here from "Edit profile" so all business tools live in the hub.
  Future<void> _openStorefrontEditor(BuildContext context) async {
    final profileBloc = context.read<ProfileBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: profileBloc,
          child: StorefrontEditorScreen(profile: profile),
        ),
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

  /// Opens "Get paid" (connect Stripe / Mercado Pago). It lives here for
  /// active business accounts, the only ones that can sell paid tickets.
  Future<void> _openGetPaid(BuildContext context) async {
    await Navigator.of(context).push(GetPaidScreen.route(profile.userId));
  }

  /// Opens the bounded list of people who follow this business (own uid).
  Future<void> _openFollowers(BuildContext context) async {
    await Navigator.of(context).push(
      FollowersScreen.route(businessId: profile.userId),
    );
  }

  /// Opens the door scanner (My Space "Scan tickets") so the organizer can
  /// quickly check attendees in. It routes each scanned ticket to the right
  /// event's check-in — no need to pick an event first.
  Future<void> _openQuickScanner(BuildContext context) async {
    await Navigator.of(context).push(
      QrScanScreen.route(currentUserId: profile.userId),
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

  /// Opens the seller's GreenGo fee invoices + monthly statements (PDF
  /// download). Reachable in the paused state too: invoices are legal
  /// documents a lapsed business must still be able to get.
  Future<void> _openInvoices(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FinanceDocumentsScreen()),
    );
  }

  /// Opens the dedicated verification request screen (document upload, owner
  /// name, phone OTP…). This is a DIFFERENT surface from the Business account
  /// screen — the two must never land on the same page.
  Future<void> _openVerification(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BusinessVerificationRequestScreen(profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Business capabilities require an active Silver, Gold or Platinum
    // membership. If it has lapsed the account keeps its isBusiness flag but
    // the storefront / leads / promote tools are paused — render a "renew"
    // state INSTEAD of the tool tiles so a lapsed business can't reach them.
    // (Analytics itself stays Platinum-only: analyticsEnabled.)
    final businessActive = TierEntitlements.isBusinessActive(
        profile.effectiveTier, profile.isBusiness);
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
      body: businessActive
          ? _buildTools(context, l10n)
          : _buildPausedState(context, l10n),
    );
  }

  /// Glass "Business paused — renew Platinum" state shown when the account is
  /// flagged business but no longer holds an active Platinum membership.
  Widget _buildPausedState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.richGold.withValues(alpha: 0.16),
                AppColors.richGold.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(
              color: AppColors.richGold.withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.richGold.withValues(alpha: 0.18),
                ),
                child: const Icon(Icons.pause_circle_outline,
                    color: AppColors.richGold, size: 34),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.businessPausedTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.businessPausedSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => TierGate().openMembershipUpgrade(
                    context,
                    currentUserId: profile.userId,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.backgroundDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.workspace_premium, size: 20),
                  label: Text(
                    l10n.businessReactivate,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (profile.isBusiness) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  key: const ValueKey('business-hub-invoices-paused'),
                  onPressed: () => _openInvoices(context),
                  style: TextButton.styleFrom(foregroundColor: AppColors.richGold),
                  icon: const Icon(Icons.receipt_long_outlined, size: 20),
                  label: Text(l10n.financeDocsTitle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The full business tool list — only reachable while business is active.
  /// A business account also loads its invoice-details status once
  /// ([BillingStatusScope]): the required banner + the Invoice details tile.
  Widget _buildTools(BuildContext context, AppLocalizations l10n) {
    final tools = _buildToolList(context, l10n);
    return profile.isBusiness ? BillingStatusScope(child: tools) : tools;
  }

  Widget _buildToolList(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profile.isBusiness) const BillingRequiredBanner(),
            Text(
              l10n.businessSectionSubtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            // View Storefront — first position (what customers actually see).
            EditSectionCard(
              title: l10n.viewStorefront,
              subtitle: profile.businessName ?? l10n.businessProfileLabel,
              icon: Icons.storefront_outlined,
              onTap: () => _openStorefront(context),
            ),
            const SizedBox(height: 16),
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
              title: l10n.businessEventsTitle,
              subtitle: l10n.businessSectionSubtitle,
              icon: Icons.event_note,
              onTap: () => _openManageEvents(context),
            ),
            const SizedBox(height: 16),
            EditSectionCard(
              key: const ValueKey('business-hub-get-paid'),
              title: l10n.tpGetPaidTitle,
              subtitle: l10n.tpGetPaidSubtitle,
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => _openGetPaid(context),
            ),
            const SizedBox(height: 16),
            if (profile.isBusiness) ...[
              const InvoiceDetailsTile(),
              const SizedBox(height: 16),
              EditSectionCard(
                key: const ValueKey('business-hub-invoices'),
                title: l10n.financeDocsTitle,
                subtitle: l10n.financeDocsSubtitle,
                icon: Icons.receipt_long_outlined,
                onTap: () => _openInvoices(context),
              ),
              const SizedBox(height: 16),
            ],
            EditSectionCard(
              title: l10n.businessHubScanner,
              subtitle: l10n.businessHubScannerSubtitle,
              icon: Icons.qr_code_scanner,
              onTap: () => _openQuickScanner(context),
            ),
            const SizedBox(height: 16),
            EditSectionCard(
              title: l10n.businessHubFollowers,
              subtitle: l10n.businessHubFollowersSubtitle,
              icon: Icons.people_alt_outlined,
              onTap: () => _openFollowers(context),
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
              title: l10n.editStorefront,
              subtitle: l10n.editStorefrontSubtitle,
              icon: Icons.edit_note,
              onTap: () => _openStorefrontEditor(context),
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
    );
  }
}
