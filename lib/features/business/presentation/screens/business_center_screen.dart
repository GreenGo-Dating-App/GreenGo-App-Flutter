import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/tier_entitlements.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../generated/app_localizations.dart';
import '../../../finance_documents/data/billing_profile_repository.dart';
import '../../../finance_documents/presentation/bloc/billing_profile_cubit.dart';
import '../../../finance_documents/presentation/widgets/billing_status.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/widgets/edit_section_card.dart';
import '../../../ticket_payments/domain/ticket_payments.dart';
import '../../data/business_center_repository.dart';
import '../business_tools.dart';
import 'business_hub_screen.dart';

/// Business Center (owner request 2026-10-14): one CRM-style place to run a
/// business, opened from the Explore header and from Profile > Business.
/// Tabs: Overview (this month + what needs action), Customers, Sales,
/// Listings, Marketing, Storefront. Every tool of the former Business hub is
/// here (same screens, [BusinessTools]); experiences stay in My Space.
/// A paused business (membership below Silver) gets the hub's reactivate
/// state instead.
class BusinessCenterScreen extends StatefulWidget {
  const BusinessCenterScreen({required this.profile, this.repository, this.billingRepository, this.clock, super.key});

  final Profile profile;

  /// Test seams.
  final BusinessCenterRepository? repository;
  final BillingProfileRepository? billingRepository;
  final DateTime Function()? clock;

  /// From a screen without a [ProfileBloc] (Explore): brings its own.
  static Route<void> route(Profile profile) => MaterialPageRoute<void>(
        builder: (_) => BlocProvider<ProfileBloc>(
          create: (_) => di.sl<ProfileBloc>()..add(ProfileLoadRequested(userId: profile.userId)),
          child: BusinessCenterScreen(profile: profile),
        ),
      );

  @override
  State<BusinessCenterScreen> createState() => _BusinessCenterScreenState();
}

class _BusinessCenterScreenState extends State<BusinessCenterScreen> {
  late final BusinessCenterRepository _repo = widget.repository ?? FirestoreBusinessCenterRepository();
  late Future<BusinessMonthStats> _stats;
  late Future<BusinessTodo> _todo;

  Profile get p => widget.profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final now = (widget.clock ?? DateTime.now)();
    _stats = _repo.monthStats(p.userId, now);
    _todo = _repo.todo(p.userId);
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait<Object>([_stats, _todo]);
  }

  /// Opens a tool and refreshes the overview when coming back.
  Future<void> _go(Future<void> Function() open) async {
    await open();
    if (mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    if (!TierEntitlements.isBusinessActive(p.effectiveTier, p.isBusiness)) {
      return BusinessHubScreen(profile: p);
    }
    final l = AppLocalizations.of(context)!;
    final tabs = <(String, IconData, Widget)>[
      (l.bcTabOverview, Icons.dashboard_outlined, _overview(l)),
      (l.bcTabCustomers, Icons.people_alt_outlined, _customers(l)),
      (l.bcTabSales, Icons.payments_outlined, _sales(l)),
      (l.bcTabListings, Icons.event_note, _listings(l)),
      (l.bcTabMarketing, Icons.campaign_outlined, _marketing(l)),
      (l.bcTabStorefront, Icons.storefront_outlined, _storefront(l)),
    ];
    final body = DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => SafeNavigation.pop(context),
          ),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.bcTitle,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            if ((p.businessName ?? '').isNotEmpty)
              Text(p.businessName!, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ]),
          actions: [
            IconButton(
              key: const ValueKey('bc-view-storefront'),
              tooltip: l.viewStorefront,
              icon: const Icon(Icons.visibility_outlined, color: AppColors.richGold),
              onPressed: () => BusinessTools.openStorefront(context, p),
            ),
          ],
          bottom: TabBar(
            key: const ValueKey('bc-tabs'),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.richGold,
            labelColor: AppColors.richGold,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [for (final t in tabs) Tab(icon: Icon(t.$2, size: 20), text: t.$1)],
          ),
        ),
        body: TabBarView(children: [for (final t in tabs) t.$3]),
      ),
    );
    return p.isBusiness ? BillingStatusScope(repository: widget.billingRepository, child: body) : body;
  }

  // ───────────────────────────────────────────── Overview

  Widget _overview(AppLocalizations l) => RefreshIndicator(
        color: AppColors.richGold,
        onRefresh: _refresh,
        child: ListView(
          key: const ValueKey('bc-overview'),
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          children: [
            Text(l.bcThisMonth, style: _h),
            const SizedBox(height: 10),
            FutureBuilder<BusinessMonthStats>(
              future: _stats,
              builder: (context, snap) => _kpis(l, snap.data, loading: snap.connectionState != ConnectionState.done),
            ),
            const SizedBox(height: 24),
            Text(l.bcActionNeeded, style: _h),
            const SizedBox(height: 10),
            if (p.isBusiness) const BillingRequiredBanner(),
            FutureBuilder<BusinessTodo>(future: _todo, builder: (context, snap) => _todoList(l, snap.data)),
            const SizedBox(height: 24),
            Text(l.bcQuickActions, style: _h),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _quick(l.businessHubScanner, Icons.qr_code_scanner, () => BusinessTools.openScanner(context, p), 'bc-q-scan'),
              _quick(l.businessEventsTitle, Icons.event_note, () => _go(() => BusinessTools.openManageEvents(context, p)), 'bc-q-events'),
              _quick(l.promoteTitle, Icons.campaign, () => BusinessTools.openPromote(context, p), 'bc-q-promote'),
              _quick(l.editStorefront, Icons.edit_note, () => BusinessTools.openStorefrontEditor(context, p), 'bc-q-edit'),
            ]),
          ],
        ),
      );

  static const _h = TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700);

  Widget _kpis(AppLocalizations l, BusinessMonthStats? s, {required bool loading}) {
    String money(int v) => s?.currency == null ? '—' : formatTicketAmount(v, s!.currency!);
    final cards = <(String, String, String, IconData)>[
      (l.bcKpiSales, money(s?.sales ?? 0), 'bc-kpi-sales', Icons.point_of_sale),
      (l.bcKpiPayout, money(s?.net ?? 0), 'bc-kpi-payout', Icons.account_balance_wallet_outlined),
      (l.bcKpiTickets, '${s?.ticketsSold ?? 0}', 'bc-kpi-tickets', Icons.confirmation_number_outlined),
      (l.bcKpiFees, money(s?.fees ?? 0), 'bc-kpi-fees', Icons.receipt_long_outlined),
      (l.bcKpiFollowers, '${s?.followers ?? 0}', 'bc-kpi-followers', Icons.people_alt_outlined),
      (l.bcKpiLeads, '${s?.newLeads ?? 0}', 'bc-kpi-leads', Icons.inbox_outlined),
      (l.bcKpiRating, (s?.ratingCount ?? 0) == 0 ? '—' : '${s!.ratingAvg.toStringAsFixed(1)} ★ (${s.ratingCount})',
          'bc-kpi-rating', Icons.star_outline),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 720 ? 4 : (c.maxWidth >= 420 ? 3 : 2);
      final w = (c.maxWidth - (cols - 1) * 10) / cols;
      return Wrap(spacing: 10, runSpacing: 10, children: [
        for (final k in cards)
          Container(
            key: ValueKey(k.$3),
            width: w,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(k.$4, size: 16, color: AppColors.richGold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(k.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 8),
              Text(loading ? '…' : k.$2,
                  key: ValueKey('${k.$3}-value'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            ]),
          ),
      ]);
    });
  }

  Widget _todoList(AppLocalizations l, BusinessTodo? t) {
    if (t == null) return const SizedBox.shrink();
    final items = <Widget>[
      if (!t.paymentsConnected)
        _todoItem(l.bcTodoConnectPayments, Icons.account_balance_wallet_outlined, 'bc-todo-connect',
            () => _go(() => BusinessTools.openGetPaid(context, p))),
      if (t.bookingRequests > 0)
        _todoItem(l.bcTodoBookingRequests(t.bookingRequests), Icons.event_available, 'bc-todo-bookings',
            () => _go(() => BusinessTools.openBookingRequests(context, p))),
      if (t.paymentsToConfirm > 0)
        _todoItem(l.bcTodoPayments(t.paymentsToConfirm), Icons.payments_outlined, 'bc-todo-payments',
            () => _go(() => BusinessTools.openPaymentsToConfirm(context, p))),
    ];
    return BlocBuilder<BillingProfileCubit, BillingProfileState>(
      builder: (context, b) {
        final billingMissing = b.status == BillingLoadStatus.ready && !b.complete;
        if (items.isEmpty && !billingMissing) {
          return Padding(
            key: const ValueKey('bc-todo-none'),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(l.bcAllCaughtUp, style: const TextStyle(color: AppColors.textSecondary))),
            ]),
          );
        }
        return Column(children: items);
      },
    );
  }

  Widget _todoItem(String text, IconData icon, String key, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: AppColors.warningAmber.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: InkWell(
            key: ValueKey(key),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Icon(icon, color: AppColors.warningAmber, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: const TextStyle(color: AppColors.textPrimary))),
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ]),
            ),
          ),
        ),
      );

  Widget _quick(String label, IconData icon, VoidCallback onTap, String key) => ActionChip(
        key: ValueKey(key),
        avatar: Icon(icon, size: 18, color: AppColors.richGold),
        label: Text(label),
        labelStyle: const TextStyle(color: AppColors.textPrimary),
        backgroundColor: AppColors.backgroundCard,
        side: const BorderSide(color: AppColors.divider),
        onPressed: onTap,
      );

  // ───────────────────────────────────────────── other tabs

  Widget _tab(String key, String intro, List<Widget> tiles) => ListView(
        key: ValueKey(key),
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        children: [
          Text(intro, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
          const SizedBox(height: 16),
          for (final t in tiles) ...[t, const SizedBox(height: 14)],
        ],
      );

  Widget _tile(String key, String title, String subtitle, IconData icon, VoidCallback onTap) =>
      EditSectionCard(key: ValueKey(key), title: title, subtitle: subtitle, icon: icon, onTap: onTap);

  Widget _customers(AppLocalizations l) => _tab('bc-customers', l.bcCustomersIntro, [
        _tile('bc-leads', l.businessLeadsTitle, l.businessContact, Icons.inbox_outlined,
            () => _go(() => BusinessTools.openLeads(context, p))),
        _tile('bc-followers', l.businessHubFollowers, l.businessHubFollowersSubtitle, Icons.people_alt_outlined,
            () => BusinessTools.openFollowers(context, p)),
        _tile('bc-bookings', l.bcBookingsTitle, l.bcBookingsSubtitle, Icons.event_available,
            () => _go(() => BusinessTools.openBookingRequests(context, p))),
      ]);

  Widget _sales(AppLocalizations l) => _tab('bc-sales', l.bcSalesIntro, [
        _tile('bc-get-paid', l.tpGetPaidTitle, l.tpGetPaidSubtitle, Icons.account_balance_wallet_outlined,
            () => _go(() => BusinessTools.openGetPaid(context, p))),
        _tile('bc-payments-confirm', l.bcPaymentsToConfirmTitle, l.bcPaymentsToConfirmSubtitle,
            Icons.payments_outlined, () => _go(() => BusinessTools.openPaymentsToConfirm(context, p))),
        if (p.isBusiness) ...[
          const InvoiceDetailsTile(),
          _tile('bc-invoices', l.financeDocsTitle, l.financeDocsSubtitle, Icons.receipt_long_outlined,
              () => BusinessTools.openInvoices(context)),
        ],
      ]);

  Widget _listings(AppLocalizations l) => _tab('bc-listings', l.bcListingsIntro, [
        _tile('bc-events', l.businessEventsTitle, l.bcEventsSubtitle, Icons.event_note,
            () => _go(() => BusinessTools.openManageEvents(context, p))),
        _tile('bc-experiences', l.bcExperiencesTitle, l.bcExperiencesSubtitle, Icons.explore_outlined,
            () => BusinessTools.openMySpace(context, p)),
        _tile('bc-scanner', l.businessHubScanner, l.businessHubScannerSubtitle, Icons.qr_code_scanner,
            () => BusinessTools.openScanner(context, p)),
      ]);

  Widget _marketing(AppLocalizations l) => _tab('bc-marketing', l.bcMarketingIntro, [
        _tile('bc-promote', l.promoteTitle, l.featureThisEvent, Icons.campaign,
            () => BusinessTools.openPromote(context, p)),
        _tile('bc-analytics', l.businessHubAnalytics, l.personalStatisticsSubtitle, Icons.insights,
            () => BusinessTools.openAnalytics(context, p)),
        _tile('bc-followers-m', l.businessHubFollowers, l.businessHubFollowersSubtitle, Icons.people_alt_outlined,
            () => BusinessTools.openFollowers(context, p)),
      ]);

  Widget _storefront(AppLocalizations l) => _tab('bc-storefront', l.bcStorefrontIntro, [
        _tile('bc-view-storefront-tile', l.viewStorefront, p.businessName ?? l.businessProfileLabel,
            Icons.storefront_outlined, () => BusinessTools.openStorefront(context, p)),
        _tile('bc-edit-storefront', l.editStorefront, l.editStorefrontSubtitle, Icons.edit_note,
            () => BusinessTools.openStorefrontEditor(context, p)),
        _tile('bc-account', l.businessHubAccount, p.businessName ?? l.businessProfileLabel, Icons.storefront,
            () => BusinessTools.openBusinessAccount(context, p)),
        _tile('bc-verification', l.requestVerification,
            p.businessVerified ? l.businessVerifiedLabel : l.requestVerificationMessage,
            p.businessVerified ? Icons.verified : Icons.verified_outlined,
            () => BusinessTools.openVerification(context, p)),
      ]);
}
