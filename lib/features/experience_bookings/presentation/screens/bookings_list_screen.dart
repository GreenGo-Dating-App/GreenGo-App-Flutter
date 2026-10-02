import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../bloc/bookings_list_bloc.dart';
import '../widgets/booking_widgets.dart';
import 'booking_detail_screen.dart';

/// "My bookings" (guest) or "Bookings received" (host — all experiences, or
/// one [experienceId]): Upcoming / Past tabs, 20 per page, infinite scroll.
class BookingsListScreen extends StatelessWidget {
  const BookingsListScreen({
    super.key,
    required this.role,
    required this.currentUserId,
    this.experienceId,
    this.title,
  });

  final BookingRole role;
  final String currentUserId;
  final String? experienceId;

  /// App bar title override (e.g. the experience's title).
  final String? title;

  static Route<void> route({
    required BookingRole role,
    required String currentUserId,
    String? experienceId,
    String? title,
  }) =>
      MaterialPageRoute(
        builder: (_) => BookingsListScreen(
          role: role,
          currentUserId: currentUserId,
          experienceId: experienceId,
          title: title,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
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
            tabs: [Tab(text: l.bkUpcoming), Tab(text: l.bkPast)],
          ),
        ),
        body: TabBarView(children: [
          for (final upcoming in const [true, false])
            BlocProvider(
              create: (_) => BookingsListBloc(
                  repository: di.sl<BookingsRepository>())
                ..add(BookingsListStarted(BookingsQuery(
                  role: role,
                  uid: currentUserId,
                  upcoming: upcoming,
                  experienceId: experienceId,
                ))),
              child: _BookingsTab(
                currentUserId: currentUserId,
                upcoming: upcoming,
              ),
            ),
        ]),
      ),
    );
  }
}

class _BookingsTab extends StatefulWidget {
  const _BookingsTab({required this.currentUserId, required this.upcoming});
  final String currentUserId;
  final bool upcoming;

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();

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
        if (s.items.isEmpty) {
          return RefreshIndicator(
            color: AppColors.richGold,
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Icon(
                    widget.upcoming
                        ? Icons.event_available_outlined
                        : Icons.history,
                    size: 64,
                    color: AppColors.textTertiary),
                const SizedBox(height: 12),
                Text(
                  s.status == BookingsListStatus.failure
                      ? l.somethingWentWrong
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
            itemCount: s.items.length + (s.hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= s.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.richGold)),
                );
              }
              final b = s.items[i];
              return BookingTile(
                booking: b,
                currentUserId: widget.currentUserId,
                onTap: () => _open(b),
              );
            },
          ),
        );
      },
    );
  }
}
