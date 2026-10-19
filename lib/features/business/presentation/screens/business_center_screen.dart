import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/tier_entitlements.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../core/widgets/menu_row.dart';
import '../../../../generated/app_localizations.dart';
import '../../../app_tour/presentation/widgets/page_tour_host.dart';
import '../../../app_tour/presentation/tour_keys.dart';
import '../../../app_tour/presentation/tour_controller.dart';
import '../../../finance_documents/data/billing_profile_repository.dart';
import '../../../finance_documents/presentation/bloc/billing_profile_cubit.dart';
import '../../../finance_documents/presentation/widgets/billing_status.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../../profile/presentation/widgets/edit_section_card.dart';
import '../../../ticket_payments/domain/ticket_payments.dart';
import '../../data/business_center_repository.dart';
import '../business_tools.dart';
import '../company_checklist.dart';
import '../../../trader/data/trader_repository.dart';
import '../../../trader/presentation/screens/trader_declaration_screen.dart';
import '../../../my_space/data/my_space_repository.dart';
import '../../../my_space/presentation/screens/my_space_screen.dart';
import 'business_hub_screen.dart';

/// Business Center (owner request 2026-10-14): one CRM-style place to run a
/// business, opened from the Explore header and from Profile > Business.
/// Tabs: Overview (this month + what needs action), Customers, Sales,
/// My Space, Marketing, Storefront, Settings (company information checklist).
/// Every tool of the former Business hub is
/// here (same screens, [BusinessTools]); experiences stay in My Space.
/// A paused business (membership below Silver) gets the hub's reactivate
/// state instead.
/// Tab indexes of the Business Center (see the tab list in build()).
const int _kTabMySpace = 1;
const int _kTabSettings = 6;

class BusinessCenterScreen extends StatefulWidget {
  const BusinessCenterScreen(
      {required this.profile,
      this.repository,
      this.billingRepository,
      this.mySpaceRepository,
      this.traderRepository,
      this.clock,
      super.key});

  final Profile profile;

  /// Test seams.
  final BusinessCenterRepository? repository;
  final BillingProfileRepository? billingRepository;
  final MySpaceRepository? mySpaceRepository;
  final TraderRepository? traderRepository;
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

  /// The latest own profile from [ProfileBloc] (edits made in the opened
  /// tools show up here at once), else the one the screen was opened with.
  Profile? _live;
  Profile get p => _live ?? widget.profile;

  /// paymentsConnected from the last [_todo] result (Settings checklist).
  bool? _paymentsConnected;

  /// Trader declaration saved (Terms 12.4); null while unknown.
  bool? _traderDeclared;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final now = (widget.clock ?? DateTime.now)();
    _stats = _repo.monthStats(p.userId, now);
    _todo = _repo.todo(p.userId);
    _todo.then((t) {
      if (mounted) setState(() => _paymentsConnected = t.paymentsConnected);
    }, onError: (Object _) {});
    _loadTrader();
  }

  Future<void> _loadTrader() async {
    try {
      final s = await (widget.traderRepository ?? TraderRepository()).get();
      if (mounted) setState(() => _traderDeclared = s.declared);
    } catch (_) {
      // Unknown: not reported as missing.
    }
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

  /// Business Center page-tour step for tab [index] (the Storefront tab has
  /// its own editor tour, so it has no step here).
  Widget _tourTab(AppLocalizations l, int index, Widget tab) {
    final step = switch (index) {
      0 => (TourKeys.bcOverview, l.tourBcOverviewTitle, l.tourBcOverviewDesc),
      _kTabMySpace => (TourKeys.bcMySpace, l.tourBcMySpaceTitle, l.tourBcMySpaceDesc),
      2 => (TourKeys.bcSales, l.tourBcSalesTitle, l.tourBcSalesDesc),
      3 => (TourKeys.bcMarketing, l.tourBcMarketingTitle, l.tourBcMarketingDesc),
      4 => (TourKeys.bcCustomers, l.tourBcCustomersTitle, l.tourBcCustomersDesc),
      _kTabSettings => (TourKeys.bcSettings, l.tourBcSettingsTitle, l.tourBcSettingsDesc),
      _ => null,
    };
    if (step == null) return tab;
    return TourAnchor(
      tourId: TourController.businessCenterTourId,
      showcaseKey: step.$1,
      title: step.$2,
      description: step.$3,
      child: tab,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!TierEntitlements.isBusinessActive(p.effectiveTier, p.isBusiness)) {
      return BusinessHubScreen(profile: p);
    }
    final l = AppLocalizations.of(context)!;
    final tabs = <(String, IconData, Widget)>[
      // Tab order (owner, 2026-10-18): Overview, My Space, Sales, Marketing,
      // Customers, Storefront, Settings. Keep _kTabMySpace / _kTabSettings in
      // sync when reordering.
      (l.bcTabOverview, Icons.dashboard_outlined, _overview(l)),
      // Events, experiences and the door scanner live in My Space (owner,
      // 2026-10-15: "replace those menus with the My Space page").
      (l.msTitle, Icons.space_dashboard_outlined,
          KeyedSubtree(key: const ValueKey('bc-my-space'), child: MySpaceScreen(currentUserId: p.userId, embedded: true, repository: widget.mySpaceRepository))),
      (l.bcTabSales, Icons.payments_outlined, _sales(l)),
      (l.bcTabMarketing, Icons.campaign_outlined, _marketing(l)),
      (l.bcTabCustomers, Icons.people_alt_outlined, _customers(l)),
      (l.bcTabStorefront, Icons.storefront_outlined, _storefront(l)),
      (l.bcTabSettings, Icons.settings_outlined, _settings(l)),
    ];
    final body = PageTourHost(
      tourId: TourController.businessCenterTourId,
      userId: p.userId,
      enabled: p.isBusiness,
      enableAutoScroll: true,
      keys: () => [
        TourKeys.bcOverview,
        TourKeys.bcMySpace,
        TourKeys.bcSales,
        TourKeys.bcMarketing,
        TourKeys.bcCustomers,
        TourKeys.bcSettings,
      ],
      child: DefaultTabController(
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
            tabs: [
              for (var i = 0; i < tabs.length; i++)
                _tourTab(l, i, Tab(icon: Icon(tabs[i].$2, size: 20), text: tabs[i].$1)),
            ],
          ),
        ),
        body: TabBarView(children: [for (final t in tabs) t.$3]),
      ),
    ));
    final scoped = p.isBusiness ? BillingStatusScope(repository: widget.billingRepository, child: body) : body;
    ProfileBloc? bloc;
    try {
      bloc = context.read<ProfileBloc>();
    } catch (_) {
      bloc = null;
    }
    if (bloc == null) return scoped;
    return BlocListener<ProfileBloc, ProfileState>(
      bloc: bloc,
      listener: (context, state) {
        final next = switch (state) {
          ProfileLoaded(:final profile) => profile,
          ProfileUpdated(:final profile) => profile,
          _ => null,
        };
        if (next != null && next.userId == widget.profile.userId) setState(() => _live = next);
      },
      child: scoped,
    );
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
              _quick(l.msTitle, Icons.space_dashboard_outlined, () => DefaultTabController.of(context).animateTo(_kTabMySpace), 'bc-q-my-space'),
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
        final missing = missingRequired(companyChecklist(p,
            billingComplete: b.status == BillingLoadStatus.ready ? b.complete : null,
            paymentsConnected: t.paymentsConnected,
            traderDeclared: _traderDeclared));
        // Invoice details, payments and the storefront photo have their own rows.
        final company = missing
            .where((m) =>
                m != CompanyItem.invoiceDetails &&
                m != CompanyItem.payments &&
                m != CompanyItem.storefrontPhoto)
            .length;
        final rows = [
          if (missing.contains(CompanyItem.storefrontPhoto))
            _todoItem(l.bcTodoStorefrontPhoto, Icons.add_photo_alternate_outlined, 'bc-todo-storefront-photo',
                () => BusinessTools.openStorefrontEditor(context, p)),
          if (company > 0)
            _todoItem(l.bcTodoCompany(company), Icons.business_outlined, 'bc-todo-company',
                () => DefaultTabController.of(context).animateTo(_kTabSettings)),
          ...items,
        ];
        if (rows.isEmpty && !billingMissing) {
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
        return Column(children: rows);
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
          for (final t in tiles) ...[t, const SizedBox(height: MenuRow.gap)],
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

  Widget _marketing(AppLocalizations l) => _tab('bc-marketing', l.bcMarketingIntro, [
        _tile('bc-promote', l.promoteTitle, l.featureThisEvent, Icons.campaign,
            () => BusinessTools.openPromote(context, p)),
        _tile('bc-analytics', l.businessHubAnalytics, l.personalStatisticsSubtitle, Icons.insights,
            () => BusinessTools.openAnalytics(context, p)),
      ]);

  Widget _settings(AppLocalizations l) => BlocBuilder<BillingProfileCubit, BillingProfileState>(
        builder: (context, b) {
          final c = companyChecklist(p,
              billingComplete: b.status == BillingLoadStatus.ready ? b.complete : null,
              paymentsConnected: _paymentsConnected,
              traderDeclared: _traderDeclared);
          final req = CompanyItem.values.where((i) => i.required).toList();
          final done = req.where((i) => c[i] == true).length;
          String title(CompanyItem i) => switch (i) {
                CompanyItem.name => l.bcCheckName,
                CompanyItem.category => l.bcCheckCategory,
                CompanyItem.description => l.bcCheckDescription,
                CompanyItem.storefrontPhoto => l.bcCheckStorefrontPhoto,
                CompanyItem.address => l.bcCheckAddress,
                CompanyItem.invoiceDetails => l.bcCheckInvoice,
                CompanyItem.payments => l.bcCheckPayments,
                CompanyItem.traderStatus => l.bcCheckTrader,
                CompanyItem.hours => l.bcCheckHours,
                CompanyItem.contact => l.bcCheckContact,
                CompanyItem.verification => l.bcCheckVerification,
              };
          Future<void> open(CompanyItem i) => switch (i) {
                CompanyItem.name => BusinessTools.openBusinessAccount(context, p),
                CompanyItem.invoiceDetails => openInvoiceDetails(context),
                CompanyItem.payments => _go(() => BusinessTools.openGetPaid(context, p)),
                CompanyItem.traderStatus => _go(() => TraderDeclarationScreen.open(context)),
                CompanyItem.verification => BusinessTools.openVerification(context, p),
                _ => BusinessTools.openStorefrontEditor(context, p),
              };
          Widget row(CompanyItem i) {
            final v = c[i];
            final ok = v == true;
            final color = ok ? AppColors.successGreen : (i.required ? AppColors.warningAmber : AppColors.textTertiary);
            return Padding(
              padding: const EdgeInsets.only(bottom: MenuRow.gap),
              child: MenuRow(
                key: ValueKey('bc-check-${i.name}'),
                title: title(i),
                subtitle: v == null ? '…' : (ok ? l.bcCheckDone : (i.required ? l.bcCheckMissing : l.bcCheckOptional)),
                subtitleKey: ValueKey('bc-check-${i.name}-state'),
                subtitleColor: color,
                leading: Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, color: color),
                onTap: () => open(i),
              ),
            );
          }

          return ListView(
            key: const ValueKey('bc-settings'),
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            children: [
              Text(l.bcSettingsIntro, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
              const SizedBox(height: 14),
              Text(l.bcCompanyProgress(done, req.length),
                  key: const ValueKey('bc-company-progress'),
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: req.isEmpty ? 1 : done / req.length,
                  minHeight: 6,
                  backgroundColor: AppColors.backgroundCard,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.richGold),
                ),
              ),
              const SizedBox(height: 18),
              Text(l.bcRequiredSection.toUpperCase(), style: _caps),
              const SizedBox(height: 8),
              for (final i in req) row(i),
              const SizedBox(height: 14),
              Text(l.bcOptionalSection.toUpperCase(), style: _caps),
              const SizedBox(height: 8),
              for (final i in CompanyItem.values.where((i) => !i.required)) row(i),
            ],
          );
        },
      );

  static const _caps =
      TextStyle(color: AppColors.textTertiary, fontSize: 11.5, letterSpacing: 0.6, fontWeight: FontWeight.w700);

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
