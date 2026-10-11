import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../bloc/bookings_list_bloc.dart';
import '../bookings_first_page_cache.dart';
import '../widgets/booking_widgets.dart';
import 'booking_detail_screen.dart';

/// "My bookings" (guest) or "Bookings received" (host — all experiences, or
/// one [experienceId]): Upcoming / Past tabs, 20 per page, infinite scroll.
/// The host's all-experiences list adds a first "To confirm" tab (requests
/// only, served by the (hostId, status, slotStart) index) with quick Accept /
/// Decline through the same respond action as the booking detail.
class BookingsListScreen extends StatelessWidget {
  const BookingsListScreen({
    super.key,
    required this.role,
    required this.currentUserId,
    this.experienceId,
    this.title,
    this.openToConfirm = false,
    this.repository,
    this.firstPageCache = const BookingsFirstPageCache(),
  });

  final BookingRole role;
  final String currentUserId;
  final String? experienceId;

  /// App bar title override (e.g. the experience's title).
  final String? title;

  /// Host list: open on the "To confirm" tab (e.g. from a pending badge).
  final bool openToConfirm;

  /// Defaults to the registered [BookingsRepository] (tests inject a fake).
  final BookingsRepository? repository;

  /// "Paint last time's page first" cache (tests pass a no-op one).
  final BookingsFirstPageCache firstPageCache;

  /// Host, all experiences: the "To confirm" tab is shown.
  bool get hasToConfirmTab => role == BookingRole.host && experienceId == null;

  static Route<void> route({
    required BookingRole role,
    required String currentUserId,
    String? experienceId,
    String? title,
    bool openToConfirm = false,
  }) =>
      MaterialPageRoute(
        builder: (_) => BookingsListScreen(
          role: role,
          currentUserId: currentUserId,
          experienceId: experienceId,
          title: title,
          openToConfirm: openToConfirm,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final repo = repository ?? di.sl<BookingsRepository>();
    final toConfirm = hasToConfirmTab;
    // (status filter, upcoming) per tab.
    final tabs = <(BookingStatus?, bool)>[
      if (toConfirm) (BookingStatus.requested, true),
      (null, true),
      (null, false),
    ];
    return DefaultTabController(
      length: tabs.length,
      initialIndex: toConfirm && !openToConfirm ? 1 : 0,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          title: Text(
            title ??
                (role == BookingRole.guest ? l.bkMyBookings : l.bkHostBookings),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.richGold,
            labelColor: AppColors.richGold,
            unselectedLabelColor: AppColors.textTertiary,
            tabs: [
              if (toConfirm) Tab(text: l.bkTabToConfirm),
              Tab(text: l.bkUpcoming),
              Tab(text: l.bkPast),
            ],
          ),
        ),
        body: TabBarView(children: [
          for (final (status, upcoming) in tabs)
            BlocProvider(
              create: (_) =>
                  BookingsListBloc(repository: repo, cache: firstPageCache)
                ..add(BookingsListStarted(BookingsQuery(
                  role: role,
                  uid: currentUserId,
                  upcoming: upcoming,
                  experienceId: experienceId,
                  status: status,
                ))),
              child: _BookingsTab(
                currentUserId: currentUserId,
                upcoming: upcoming,
                toConfirm: status == BookingStatus.requested,
                repository: repo,
              ),
            ),
        ]),
      ),
    );
  }
}

class _BookingsTab extends StatefulWidget {
  const _BookingsTab({
    required this.currentUserId,
    required this.upcoming,
    required this.repository,
    this.toConfirm = false,
  });
  final String currentUserId;
  final bool upcoming;
  final BookingsRepository repository;

  /// Requests only, each with quick Accept / Decline.
  final bool toConfirm;

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();

  /// Booking ids with an Accept / Decline in flight.
  final Set<String> _busy = <String>{};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.maxScrollExtent - _scroll.position.pixels < 400) {
        context.read<BookingsListBloc>().add(const BookingsListMoreRequested());
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open(Booking b) async {
    final bloc = context.read<BookingsListBloc>();
    final updated = await Navigator.of(context).push(BookingDetailScreen.route(
        bookingId: b.id, currentUserId: widget.currentUserId, initial: b));
    if (updated != null) bloc.add(BookingsListItemUpdated(updated));
  }

  /// Quick answer to a request: the same respondToBookingRequest action as
  /// the detail screen. Decline asks first.
  Future<void> _respond(Booking b, {required bool accept}) async {
    final l = AppLocalizations.of(context)!;
    final bloc = context.read<BookingsListBloc>();
    if (!accept) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: Text(l.bkDeclineConfirm,
              style: const TextStyle(color: AppColors.textPrimary)),
          content: Text(l.bkDeclineBody,
              style: const TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.bkDecline,
                    style: const TextStyle(color: AppColors.errorRed))),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _busy.add(b.id));
    final r = await widget.repository.respond(b, accept: accept);
    if (!mounted) return;
    setState(() => _busy.remove(b.id));
    r.fold(
      (f) => showUserError(context, f),
      (updated) {
        bloc.add(BookingsListItemUpdated(updated));
        showBookingSnack(context, accept ? l.bkAccepted : l.bkDeclined);
      },
    );
  }

  Widget _quickActions(AppLocalizations l, Booking b) {
    final busy = _busy.contains(b.id);
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Expanded(
          child: OutlinedButton(
            key: ValueKey('decline-${b.id}'),
            onPressed: busy ? null : () => _respond(b, accept: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.errorRed,
              side: BorderSide(color: AppColors.errorRed.withValues(alpha: 0.6)),
              minimumSize: const Size(0, 44),
              shape: shape,
            ),
            child: Text(l.bkDecline, overflow: TextOverflow.ellipsis),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            key: ValueKey('accept-${b.id}'),
            onPressed: busy ? null : () => _respond(b, accept: true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
              minimumSize: const Size(0, 44),
              shape: shape,
            ),
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.deepBlack))
                : Text(l.bkAccept, overflow: TextOverflow.ellipsis),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<BookingsListBloc, BookingsListState>(
      builder: (context, s) {
        Future<void> refresh() async =>
            context.read<BookingsListBloc>().add(const BookingsListRefreshed());
        if (s.status == BookingsListStatus.loading && s.items.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.richGold));
        }
        // To confirm: an answered request leaves the list right away.
        final items = widget.toConfirm
            ? s.items.where((b) => b.status == BookingStatus.requested).toList()
            : s.items;
        if (items.isEmpty) {
          return RefreshIndicator(
            color: AppColors.richGold,
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Icon(
                    widget.toConfirm
                        ? Icons.mark_email_read_outlined
                        : widget.upcoming
                            ? Icons.event_available_outlined
                            : Icons.history,
                    size: 64,
                    color: AppColors.textTertiary),
                const SizedBox(height: 12),
                Text(
                  s.status == BookingsListStatus.failure
                      ? l.somethingWentWrong
                      : widget.toConfirm
                          ? l.bkNoneToConfirm
                          : (widget.upcoming ? l.bkNoUpcoming : l.bkNoPast),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.richGold,
          onRefresh: refresh,
          child: ListView.builder(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            itemCount: items.length + (s.hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.richGold)),
                );
              }
              final b = items[i];
              final tile = BookingTile(
                booking: b,
                currentUserId: widget.currentUserId,
                onTap: () => _open(b),
              );
              if (!widget.toConfirm) return tile;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [tile, _quickActions(l, b)],
              );
            },
          ),
        );
      },
    );
  }
}
