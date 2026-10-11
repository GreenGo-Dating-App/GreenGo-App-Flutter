import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/screens/event_ticket_screen.dart';
import '../../../experience_bookings/domain/entities/booking.dart';
import '../../../experience_bookings/presentation/booking_l10n.dart';
import '../../../experience_bookings/presentation/screens/bookings_list_screen.dart';
import '../../../explore/presentation/screens/qr_hub_screen.dart';
import '../../../ticket_payments/presentation/screens/payments_to_confirm_screen.dart';
import '../../../user_experiences/presentation/screens/my_experiences_screen.dart';
import '../../data/my_space_repository.dart';
import '../../domain/my_space_models.dart';
import '../bloc/my_space_cubit.dart';
import '../widgets/booking_dashboard_cards.dart';
import '../widgets/space_widgets.dart';
import 'event_check_in_checklist_screen.dart';
import 'session_check_in_checklist_screen.dart';

/// My Space (Explore → the QR button): one place to run everything the user
/// hosts and attends.
///
///   header      greeting + two big actions: Scan tickets / My tickets
///   To do       booking requests to confirm · payments to confirm · today's
///               check-ins · upcoming bookings as a guest — or "All done"
///   Events      Hosting (date, going, check-in progress → checklist) and
///               Attending (my upcoming events → ticket)
///   Experiences My bookings / Bookings received cards, My experiences, and
///               upcoming sessions (check-in progress → checklist)
///
/// Every number is a server count() or a bounded per-user query; the hub
/// links into the existing screens instead of duplicating their logic.
class MySpaceScreen extends StatelessWidget {
  const MySpaceScreen({
    super.key,
    required this.currentUserId,
    this.repository,
    this.clock,
  });

  final String currentUserId;

  /// Defaults to [FirestoreMySpaceRepository] (tests inject a fake).
  final MySpaceRepository? repository;
  final DateTime Function()? clock;

  static Route<void> route({required String currentUserId}) =>
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/my-space'),
        builder: (_) => MySpaceScreen(currentUserId: currentUserId),
      );

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? FirestoreMySpaceRepository();
    return RepositoryProvider<MySpaceRepository>.value(
      value: repo,
      child: BlocProvider(
        create: (_) =>
            MySpaceCubit(repository: repo, uid: currentUserId, clock: clock)
              ..load(),
        child: _MySpaceView(currentUserId: currentUserId),
      ),
    );
  }
}

class _MySpaceView extends StatefulWidget {
  const _MySpaceView({required this.currentUserId});
  final String currentUserId;

  @override
  State<_MySpaceView> createState() => _MySpaceViewState();
}

class _MySpaceViewState extends State<_MySpaceView> {
  /// Check-in numbers per hosted event (2 count()s each, loaded once).
  final Map<String, Future<EventCheckInStats>> _stats = {};

  bool _showAllHosting = false;

  MySpaceRepository get _repo => context.read<MySpaceRepository>();
  MySpaceCubit get _cubit => context.read<MySpaceCubit>();

  Future<EventCheckInStats> _statsFor(String eventId) =>
      _stats.putIfAbsent(eventId, () => _repo.eventCheckInStats(eventId));

  Future<void> _refresh() async {
    setState(_stats.clear);
    await _cubit.load();
  }

  Future<void> _push(Route<Object?> route, {bool reload = true}) async {
    await Navigator.of(context).push(route);
    if (reload && mounted) await _refresh();
  }

  // ───────────────────────────────────────────── navigation

  void _openScanner() =>
      _push(QrScanScreen.route(currentUserId: widget.currentUserId),
          reload: false);

  void _openTickets() =>
      _push(MyTicketsScreen.route(currentUserId: widget.currentUserId),
          reload: false);

  Future<void> _openBookings(BookingRole role, {bool toConfirm = false}) =>
      _push(BookingsListScreen.route(
        role: role,
        currentUserId: widget.currentUserId,
        openToConfirm: toConfirm,
      ));

  void _openPayments() =>
      _push(PaymentsToConfirmScreen.route(widget.currentUserId));

  void _openEventChecklist(Event e) => _push(EventCheckInChecklistScreen.route(
      event: e, currentUserId: widget.currentUserId, repository: _repo));

  void _openSessionChecklist(CheckInSession s) =>
      _push(SessionCheckInChecklistScreen.route(
          session: s, currentUserId: widget.currentUserId, repository: _repo));

  void _openTicket(Event e) =>
      _push(EventTicketScreen.route(event: e, userId: widget.currentUserId));

  Future<void> _openToday(List<Object> today) async {
    if (today.length == 1) {
      final only = today.single;
      if (only is Event) {
        _openEventChecklist(only);
      } else {
        _openSessionChecklist(only as CheckInSession);
      }
      return;
    }
    final l = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(l.msTodaySheetTitle,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
              ),
              for (final item in today)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: item is Event
                      ? _hostedEventCard(item,
                          onTap: () => Navigator.pop(ctx, item))
                      : _sessionCard(item as CheckInSession,
                          onTap: () => Navigator.pop(ctx, item)),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    if (picked is Event) {
      _openEventChecklist(picked);
    } else if (picked is CheckInSession) {
      _openSessionChecklist(picked);
    }
  }

  // ───────────────────────────────────────────── build

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(l.msTitle),
        actions: [
          IconButton(
            tooltip: l.refresh,
            icon: const Icon(Icons.refresh, color: AppColors.textTertiary),
            onPressed: _refresh,
          ),
        ],
      ),
      body: BlocBuilder<MySpaceCubit, MySpaceState>(
        builder: (context, s) {
          return RefreshIndicator(
            color: AppColors.richGold,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                SpaceMaxWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(l),
                      const SizedBox(height: 16),
                      SpacePair(
                        breakpoint: 340,
                        first: _PrimaryTile(
                          key: const ValueKey('ms-scan'),
                          primary: true,
                          icon: Icons.qr_code_scanner,
                          title: l.msScanTickets,
                          hint: l.msScanTicketsHint,
                          onTap: _openScanner,
                        ),
                        second: _PrimaryTile(
                          key: const ValueKey('ms-tickets'),
                          icon: Icons.confirmation_number_outlined,
                          title: l.qrHubTabMyTickets,
                          hint: l.msMyTicketsHint,
                          onTap: _openTickets,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _todoCard(l, s),
                      const SizedBox(height: 20),
                      _segments(l, s.section),
                      const SizedBox(height: 4),
                      if (s.section == MySpaceSection.events)
                        ..._eventsSection(l, s)
                      else
                        ..._experiencesSection(l, s),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(AppLocalizations l) {
    final hour = _cubit.now().hour;
    final greeting = hour < 12
        ? l.msGreetingMorning
        : hour < 18
            ? l.msGreetingAfternoon
            : l.msGreetingEvening;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            greeting,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.msGreetingSubtitle,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────── To do

  Widget _todoCard(AppLocalizations l, MySpaceState s) {
    final c = s.counts;
    final today = s.todayCheckIns(_cubit.now());
    final loading = s.countsLoad == MySpaceLoad.loading ||
        s.eventsLoad == MySpaceLoad.loading ||
        s.sessionsLoad == MySpaceLoad.loading;
    final rows = <Widget>[
      if (c.bookingRequestsToConfirm > 0)
        _todoRow(
          key: const ValueKey('todo-requests'),
          icon: Icons.mark_email_unread_outlined,
          text: l.msTodoBookingRequests(c.bookingRequestsToConfirm),
          count: c.bookingRequestsToConfirm,
          urgent: true,
          onTap: () => _openBookings(BookingRole.host, toConfirm: true),
        ),
      if (c.paymentsToConfirm > 0)
        _todoRow(
          key: const ValueKey('todo-payments'),
          icon: Icons.payments_outlined,
          text: l.msTodoPayments(c.paymentsToConfirm),
          count: c.paymentsToConfirm,
          urgent: true,
          onTap: _openPayments,
        ),
      if (today.isNotEmpty)
        _todoRow(
          key: const ValueKey('todo-checkin'),
          icon: Icons.how_to_reg_outlined,
          text: l.msTodoCheckInToday(today.length),
          count: today.length,
          onTap: () => _openToday(today),
        ),
      if (c.guestUpcomingBookings > 0)
        _todoRow(
          key: const ValueKey('todo-upcoming'),
          icon: Icons.event_available_outlined,
          text: l.msTodoUpcomingBookings(c.guestUpcomingBookings),
          count: c.guestUpcomingBookings,
          onTap: () => _openBookings(BookingRole.guest),
        ),
    ];
    final total =
        c.bookingRequestsToConfirm + c.paymentsToConfirm + today.length;
    return SpaceCard(
      highlight: total > 0,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 6),
            child: Row(children: [
              const Icon(Icons.checklist_rounded,
                  color: AppColors.richGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l.msTodoTitle,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              if (total > 0) SpaceCountBadge(count: total, urgent: true),
            ]),
          ),
          if (rows.isEmpty && loading)
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 8, 14),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.richGold,
                backgroundColor: Colors.transparent,
              ),
            )
          else if (rows.isEmpty)
            _allDone(l)
          else
            ...rows,
        ],
      ),
    );
  }

  Widget _allDone(AppLocalizations l) {
    return Padding(
      key: const ValueKey('todo-all-done'),
      padding: const EdgeInsets.fromLTRB(0, 6, 8, 12),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.successGreen.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.check_rounded,
              color: AppColors.successGreen, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.msAllDone,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(l.msAllDoneBody,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 13)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _todoRow({
    required Key key,
    required IconData icon,
    required String text,
    required int count,
    required VoidCallback onTap,
    bool urgent = false,
  }) {
    return Semantics(
      button: true,
      label: text,
      excludeSemantics: true,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              SpaceIconBadge(
                icon: icon,
                size: 36,
                color: urgent ? AppColors.warningAmber : AppColors.richGold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 8),
              SpaceCountBadge(count: count, urgent: urgent),
              const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary, size: 22),
            ]),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────── segmented control

  Widget _segments(AppLocalizations l, MySpaceSection current) {
    Widget seg(MySpaceSection s, String label, IconData icon, Key key) {
      final selected = s == current;
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          excludeSemantics: true,
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(12),
            onTap: () => _cubit.selectSection(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 44),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: selected
                    ? const LinearGradient(colors: [
                        AppColors.richGold,
                        AppColors.accentGold,
                      ])
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 18,
                      color: selected
                          ? AppColors.deepBlack
                          : AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? AppColors.deepBlack
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        seg(MySpaceSection.events, l.msSegmentEvents, Icons.event_outlined,
            const ValueKey('ms-seg-events')),
        const SizedBox(width: 4),
        seg(MySpaceSection.experiences, l.msSegmentExperiences,
            Icons.explore_outlined, const ValueKey('ms-seg-experiences')),
      ]),
    );
  }

  // ───────────────────────────────────────────── Events

  String _weekday(DateTime d) =>
      DateFormat.E(AppLocalizations.of(context)!.localeName).format(d);

  List<Widget> _eventsSection(AppLocalizations l, MySpaceState s) {
    final loading = s.eventsLoad == MySpaceLoad.loading;
    const cap = 8;
    final hosting = _showAllHosting || s.hosting.length <= cap
        ? s.hosting
        : s.hosting.take(cap).toList();
    return [
      SpaceSectionHeader(title: l.msHosting, icon: Icons.campaign_outlined),
      if (loading)
        _loadingBlock()
      else if (s.eventsFailed)
        _errorBlock(l)
      else if (s.hosting.isEmpty)
        _emptyBlock(Icons.event_note_outlined, l.msNoHosting,
            key: const ValueKey('ms-no-hosting'))
      else ...[
        for (final e in hosting)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _hostedEventCard(e, onTap: () => _openEventChecklist(e)),
          ),
        if (hosting.length < s.hosting.length)
          _moreButton(l, () => setState(() => _showAllHosting = true)),
      ],
      SpaceSectionHeader(
        title: l.msAttending,
        icon: Icons.confirmation_number_outlined,
        trailing: TextButton(
          onPressed: _openTickets,
          style: TextButton.styleFrom(
              foregroundColor: AppColors.richGold,
              minimumSize: const Size(44, 44)),
          child: Text(l.msSeeAll),
        ),
      ),
      if (loading)
        _loadingBlock()
      else if (s.eventsFailed)
        const SizedBox.shrink()
      else if (s.attending.isEmpty)
        _emptyBlock(Icons.local_activity_outlined, l.msNoAttending,
            key: const ValueKey('ms-no-attending'))
      else
        for (final e in s.attending.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _attendingCard(l, e),
          ),
    ];
  }

  Widget _hostedEventCard(Event e, {required VoidCallback onTap}) {
    final l = AppLocalizations.of(context)!;
    final now = _cubit.now();
    final today = MySpaceRules.isCheckInDay(e.startDate, e.endDate, now);
    return _RowCard(
      key: ValueKey('ms-hosted-${e.id}'),
      onTap: onTap,
      semanticsLabel:
          '${e.title}. ${BookingL10n.dateTime(context, e.startDate)}',
      leading: SpaceDateBlock(
        weekday: _weekday(e.startDate),
        day: '${e.startDate.day}',
        today: today,
      ),
      title: e.title,
      subtitle:
          '${BookingL10n.time(context, e.startDate)} · ${l.msGoingCount(e.goingCount)}',
      footer: FutureBuilder<EventCheckInStats>(
        future: _statsFor(e.id),
        builder: (context, snap) {
          final st = snap.data;
          if (snap.hasError) return const SizedBox.shrink();
          return SpaceProgress(
            label: st == null
                ? l.msCheckedInProgress(0, e.goingCount)
                : l.msCheckedInProgress(st.checkedIn, st.going),
            value: st?.progress,
          );
        },
      ),
    );
  }

  Widget _attendingCard(AppLocalizations l, Event e) {
    return _RowCard(
      key: ValueKey('ms-attending-${e.id}'),
      onTap: () => _openTicket(e),
      semanticsLabel:
          '${e.title}. ${BookingL10n.dateTime(context, e.startDate)}. ${l.msOpenTicket}',
      leading: SpaceDateBlock(
        weekday: _weekday(e.startDate),
        day: '${e.startDate.day}',
        today: MySpaceRules.isCheckInDay(e.startDate, e.endDate, _cubit.now()),
      ),
      title: e.title,
      subtitle: [
        BookingL10n.time(context, e.startDate),
        if (e.locationName.trim().isNotEmpty) e.locationName.trim(),
      ].join(' · '),
      trailing: const Icon(Icons.qr_code_2, color: AppColors.richGold),
    );
  }

  // ───────────────────────────────────────────── Experiences

  List<Widget> _experiencesSection(AppLocalizations l, MySpaceState s) {
    return [
      const SizedBox(height: 14),
      BookingDashboardCards(
        currentUserId: widget.currentUserId,
        repository: _repo,
        onOpen: (role, {toConfirm = false}) async {
          await Navigator.of(context).push(BookingsListScreen.route(
            role: role,
            currentUserId: widget.currentUserId,
            openToConfirm: toConfirm,
          ));
          if (mounted) unawaited(_cubit.loadCounts());
        },
      ),
      const SizedBox(height: 10),
      SpaceDashboardCard(
        inkKey: const ValueKey('ms-my-experiences'),
        icon: Icons.auto_awesome_outlined,
        title: l.uexpMine,
        subtitle: l.msMyExperiencesHint,
        onTap: () => _push(MyExperiencesScreen.route(widget.currentUserId)),
      ),
      SpaceSectionHeader(title: l.msSessions, icon: Icons.schedule_outlined),
      if (s.sessionsLoad == MySpaceLoad.loading)
        _loadingBlock()
      else if (s.sessionsFailed)
        _errorBlock(l)
      else if (s.sessions.isEmpty)
        _emptyBlock(Icons.event_busy_outlined, l.msNoSessions,
            key: const ValueKey('ms-no-sessions'))
      else
        for (final x in s.sessions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _sessionCard(x, onTap: () => _openSessionChecklist(x)),
          ),
    ];
  }

  Widget _sessionCard(CheckInSession x, {required VoidCallback onTap}) {
    final l = AppLocalizations.of(context)!;
    return _RowCard(
      key: ValueKey('ms-session-${x.id}'),
      onTap: onTap,
      semanticsLabel: '${x.title}. ${BookingL10n.dateTime(context, x.start)}',
      leading: SpaceDateBlock(
        weekday: _weekday(x.start),
        day: '${x.start.day}',
        today: MySpaceRules.isCheckInDay(x.start, x.end, _cubit.now()),
      ),
      title: x.title.isEmpty ? l.bkDetailTitle : x.title,
      subtitle:
          '${BookingL10n.range(context, x.start, x.end)} · ${l.bkGuestsCount(x.guests)}',
      footer: SpaceProgress(
        label: l.msCheckedInProgress(x.checkedIn, x.bookings.length),
        value: x.progress,
      ),
    );
  }

  // ───────────────────────────────────────────── blocks

  Widget _loadingBlock() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppColors.richGold),
          ),
        ),
      );

  Widget _emptyBlock(IconData icon, String text, {Key? key}) => SpaceCard(
        key: key,
        child: Row(children: [
          Icon(icon, color: AppColors.textTertiary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 13.5)),
          ),
        ]),
      );

  Widget _errorBlock(AppLocalizations l) => SpaceCard(
        child: Row(children: [
          const Icon(Icons.cloud_off_outlined,
              color: AppColors.textTertiary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l.somethingWentWrong,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 13.5)),
          ),
          TextButton(
            onPressed: _refresh,
            style: TextButton.styleFrom(
                foregroundColor: AppColors.richGold,
                minimumSize: const Size(44, 44)),
            child: Text(l.retry),
          ),
        ]),
      );

  Widget _moreButton(AppLocalizations l, VoidCallback onTap) => Center(
        child: TextButton.icon(
          onPressed: onTap,
          style: TextButton.styleFrom(
              foregroundColor: AppColors.richGold,
              minimumSize: const Size(44, 44)),
          icon: const Icon(Icons.expand_more),
          label: Text(l.msSeeAll),
        ),
      );
}

/// A big action tile of the header. [primary] = solid gold.
class _PrimaryTile extends StatelessWidget {
  const _PrimaryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? AppColors.deepBlack : AppColors.textPrimary;
    return Semantics(
      button: true,
      label: '$title. $hint',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kSpaceRadius + 2),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kSpaceRadius + 2),
              gradient: primary
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accentGold, AppColors.richGold],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.backgroundCard,
                        Color.alphaBlend(
                            AppColors.richGold.withValues(alpha: 0.08),
                            AppColors.backgroundCard),
                      ],
                    ),
              border: primary
                  ? null
                  : Border.all(
                      color: AppColors.richGold.withValues(alpha: 0.4)),
              boxShadow: primary
                  ? [
                      BoxShadow(
                        color: AppColors.richGold.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 112),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SpaceIconBadge(icon: icon, size: 40, filled: primary),
                    const SizedBox(height: 12),
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: fg,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.15)),
                    const SizedBox(height: 2),
                    Text(hint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: fg.withValues(alpha: primary ? 0.75 : 0.6),
                            fontSize: 12.5,
                            height: 1.25)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A list card: leading block, title, subtitle, optional footer / trailing.
class _RowCard extends StatelessWidget {
  const _RowCard({
    super.key,
    required this.onTap,
    required this.semanticsLabel,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.footer,
    this.trailing,
  });

  final VoidCallback onTap;
  final String semanticsLabel;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? footer;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kSpaceRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(kSpaceRadius),
              border:
                  Border.all(color: AppColors.richGold.withValues(alpha: 0.16)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 12.5)),
                      if (footer != null) ...[
                        const SizedBox(height: 10),
                        footer!,
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ] else
                  const Icon(Icons.chevron_right,
                      color: AppColors.textTertiary, size: 22),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
