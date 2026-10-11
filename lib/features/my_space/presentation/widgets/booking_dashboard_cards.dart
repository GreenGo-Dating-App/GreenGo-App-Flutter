import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../../experience_bookings/domain/entities/booking.dart';
import '../../data/my_space_repository.dart';
import 'space_widgets.dart';

/// Live numbers of the two booking cards (3 cheap `count()` aggregates).
class BookingCardCounts {
  const BookingCardCounts({
    this.guestUpcoming = 0,
    this.hostToConfirm = 0,
    this.hostUpcoming = 0,
  });

  final int guestUpcoming;
  final int hostToConfirm;
  final int hostUpcoming;
}

/// "My bookings" (guest) + "Bookings received" (host) as two dashboard cards
/// side by side (stacked on very narrow widths). Subtitles are live counts:
/// guest "N upcoming"; host "N to confirm" with an amber badge when there are
/// requests, else "N upcoming". Counts refresh after the opened list closes.
///
/// The tappable areas keep the keys `my-bookings` / `host-bookings`.
class BookingDashboardCards extends StatefulWidget {
  const BookingDashboardCards({
    super.key,
    required this.currentUserId,
    required this.onOpen,
    this.repository,
    this.padding = EdgeInsets.zero,
  });

  final String currentUserId;

  /// Opens the list for [role]; the counts reload when it completes.
  final Future<void> Function(BookingRole role, {bool toConfirm}) onOpen;

  /// Defaults to [FirestoreMySpaceRepository].
  final MySpaceRepository? repository;
  final EdgeInsetsGeometry padding;

  @override
  State<BookingDashboardCards> createState() => _BookingDashboardCardsState();
}

class _BookingDashboardCardsState extends State<BookingDashboardCards> {
  late final MySpaceRepository _repo =
      widget.repository ?? FirestoreMySpaceRepository();
  BookingCardCounts? _counts;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  static Future<int> _safe(Future<int> f) async {
    try {
      return await f;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _load() async {
    final uid = widget.currentUserId;
    final r = await Future.wait([
      _safe(_repo.upcomingBookings(uid, BookingRole.guest)),
      _safe(_repo.bookingRequestsToConfirm(uid)),
      _safe(_repo.upcomingBookings(uid, BookingRole.host)),
    ]);
    if (!mounted) return;
    setState(() => _counts = BookingCardCounts(
        guestUpcoming: r[0], hostToConfirm: r[1], hostUpcoming: r[2]));
  }

  Future<void> _open(BookingRole role, {bool toConfirm = false}) async {
    await widget.onOpen(role, toConfirm: toConfirm);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = _counts;
    final toConfirm = c?.hostToConfirm ?? 0;
    return Padding(
      padding: widget.padding,
      child: SpacePair(
        first: SpaceDashboardCard(
          inkKey: const ValueKey('my-bookings'),
          icon: Icons.confirmation_number_outlined,
          title: l.bkMyBookings,
          loading: c == null,
          subtitle: c == null ? null : l.bkCardUpcoming(c.guestUpcoming),
          onTap: () => _open(BookingRole.guest),
        ),
        second: SpaceDashboardCard(
          inkKey: const ValueKey('host-bookings'),
          icon: Icons.inbox_outlined,
          title: l.bkHostBookings,
          loading: c == null,
          urgent: toConfirm > 0,
          badgeCount: toConfirm,
          subtitle: c == null
              ? null
              : toConfirm > 0
                  ? l.bkCardToConfirm(toConfirm)
                  : l.bkCardUpcoming(c.hostUpcoming),
          onTap: () => _open(BookingRole.host, toConfirm: toConfirm > 0),
        ),
      ),
    );
  }
}
