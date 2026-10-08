import '../../../ticket_payments/presentation/screens/my_ticket_orders_screen.dart';
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/qr_checkin_service.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../../events/data/datasources/events_remote_datasource.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/screens/event_ticket_screen.dart';
import '../../../events/presentation/widgets/scan_result_overlay.dart';
import '../../../experience_bookings/data/datasources/bookings_remote_datasource.dart';
import '../../../experience_bookings/domain/entities/booking.dart';
import '../../../experience_bookings/presentation/screens/booking_detail_screen.dart';

/// QR hub — one place for everything QR:
///  - **My tickets**: a QR code for EVERY event the user has joined (going) or
///    organizes — upcoming & ongoing first, finished events after — reusing the
///    exact [EventTicketPayload] the organizer scanner validates. A joined event
///    always shows its ticket regardless of publish/featured state.
///  - **Scan**: a [MobileScanner] that parses a scanned GreenGo code and routes
///    it — check a person in (when the current user organizes that event), join
///    the current user to the event, or open their own ticket's event.
///
/// Apple-safe / glass. Reuses [EventsRemoteDataSource] and [EventTicketScreen]
/// so ticket codes stay 100% compatible with the existing check-in scanner.
class QRHubScreen extends StatelessWidget {
  const QRHubScreen({super.key, required this.currentUserId});

  final String currentUserId;

  static Route<void> route({required String currentUserId}) {
    return MaterialPageRoute<void>(
      builder: (_) => QRHubScreen(currentUserId: currentUserId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          title: Text(l10n.qrHubTitle),
          bottom: TabBar(
            indicatorColor: AppColors.richGold,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: l10n.qrHubTabMyTickets),
              Tab(text: l10n.qrHubTabScan),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MyTicketsTab(currentUserId: currentUserId),
            _ScanTab(currentUserId: currentUserId),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My tickets
// ─────────────────────────────────────────────────────────────────────────────

class _MyTicketsTab extends StatefulWidget {
  const _MyTicketsTab({required this.currentUserId});

  final String currentUserId;

  @override
  State<_MyTicketsTab> createState() => _MyTicketsTabState();
}

class _MyTicketsTabState extends State<_MyTicketsTab> {
  // null == loading; empty == loaded, no joined/organized events.
  List<Event>? _events;
  // Confirmed upcoming experience bookings (the guest's check-in codes).
  List<Booking> _bookings = const <Booking>[];
  final HiddenTicketsStore _hiddenStore = HiddenTicketsStore();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _loadBookings() async {
    try {
      final page = await BookingsRemoteDataSource().bookings(
        BookingsQuery(
            role: BookingRole.guest,
            uid: widget.currentUserId,
            upcoming: true),
        limit: 20,
      );
      final mine = page.items
          .where((b) => b.status == BookingStatus.confirmed)
          .toList();
      if (mounted) setState(() => _bookings = mine);
    } catch (_) {/* keep what is shown */}
  }

  Future<void> _load() async {
    unawaited(_loadBookings());
    List<Event> mine = const <Event>[];
    try {
      final ds = di.sl<EventsRemoteDataSource>();
      // getUserEvents already returns every event the user is going to (RSVP
      // status == going) PLUS the ones they organize, regardless of publish or
      // featured state. Show a scannable ticket for ALL of them — never filter
      // by publish/live state. We only reorder by time so the tickets the user
      // actually needs at the door surface first.
      // Tickets the user deleted from a PAST event are hidden per-user (the
      // attendee record is kept) — one small doc read, fetched in parallel.
      final hiddenFuture = _hiddenStore
          .getAll(widget.currentUserId)
          .catchError((Object _) => <String>{});
      // Server load (shared session memo) starts now…
      final serverFuture = ds.getUserEvents(widget.currentUserId);
      serverFuture.then((_) {}, onError: (Object _) {});
      // …while the local cache paints the tickets in milliseconds.
      try {
        final cached = await ds.getUserEvents(widget.currentUserId,
            preferCache: true);
        if (cached.isNotEmpty) {
          final hidden = await hiddenFuture;
          if (mounted && _events == null) {
            setState(() => _events = _arrange(cached, hidden));
          }
        }
      } catch (_) {/* not cached: wait for the server */}
      final results = await Future.wait<Object>([serverFuture, hiddenFuture]);
      mine = _arrange(results[0] as List<Event>, results[1] as Set<String>);
    } catch (_) {
      // Keep a cached paint rather than blanking it on a server failure.
      mine = _events ?? const <Event>[];
    }
    if (mounted) setState(() => _events = mine);
  }

  /// Hidden tickets dropped; "not past" (upcoming OR ongoing, endDate not
  /// reached — so today's / in-progress events stay at the top) soonest
  /// first, then past ones most recent first.
  List<Event> _arrange(List<Event> events, Set<String> hidden) {
    final all = events.where((e) => !hidden.contains(e.id)).toList();
    final now = DateTime.now();
    bool isPast(Event e) => e.endDate.isBefore(now);
    final upcoming = all.where((e) => !isPast(e)).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final past = all.where(isPast).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return [...upcoming, ...past];
  }

  /// Drop a deleted ticket from the list immediately (no refetch needed).
  void _removeLocally(Event event) {
    final events = _events;
    if (events == null || !mounted) return;
    setState(() => _events = events.where((e) => e.id != event.id).toList());
  }

  /// Delete a ticket from the list: upcoming = cancel my RSVP, past = hide it
  /// from my list (confirm dialog + error snackbar live in the shared helper).
  Future<void> _deleteTicket(Event event) async {
    final removed = await EventTicketRemoval.confirmAndRemove(
      context,
      event: event,
      userId: widget.currentUserId,
    );
    if (removed) _removeLocally(event);
  }

  Future<void> _openTicket(Event event) async {
    final removed = await Navigator.of(context).push(
      EventTicketScreen.route(event: event, userId: widget.currentUserId),
    );
    // The full ticket screen has its own delete; reflect it here on return.
    if (removed == true) _removeLocally(event);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final events = _events;
    if (events == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      );
    }
    if (events.isEmpty && _bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.of(context)
                    .push(MyTicketOrdersScreen.route(widget.currentUserId)),
                icon: const Icon(Icons.receipt_long, color: AppColors.richGold),
                label: Text(l10n.tpMyPurchases, style: const TextStyle(color: AppColors.richGold)),
              ),
              const Icon(Icons.confirmation_number_outlined,
                  color: AppColors.textTertiary, size: 48),
              const SizedBox(height: 16),
              Text(
                l10n.qrHubNoTickets,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.richGold,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: events.length + _bookings.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Expanded(
                  child: Text(
                    l10n.qrHubTicketHint,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12.5),
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('qr-hub-my-purchases'),
                  onPressed: () => Navigator.of(context)
                      .push(MyTicketOrdersScreen.route(widget.currentUserId)),
                  icon: const Icon(Icons.receipt_long, size: 18, color: AppColors.richGold),
                  label: Text(l10n.tpMyPurchases,
                      style: const TextStyle(color: AppColors.richGold)),
                ),
              ]),
            );
          }
          // Experience bookings first (usually the next thing to attend).
          if (index <= _bookings.length) {
            return _bookingCard(context, _bookings[index - 1]);
          }
          return _ticketCard(context, events[index - 1 - _bookings.length]);
        },
      ),
    );
  }

  /// An experience booking: tap -> booking detail -> "Show check-in code".
  Widget _bookingCard(BuildContext context, Booking b) {
    final l10n = AppLocalizations.of(context)!;
    return _card(
      onTap: () => Navigator.of(context).push(BookingDetailScreen.route(
          bookingId: b.id, currentUserId: widget.currentUserId, initial: b)),
      leading: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: AppColors.richGold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.explore, color: AppColors.richGold, size: 36),
      ),
      label: l10n.qrHubExperienceTicket,
      title: b.experienceTitle ?? '',
      when: b.slotStart,
    );
  }

  Widget _ticketCard(BuildContext context, Event event) {
    return _card(
      onTap: () => _openTicket(event),
      // The signed ticket once this device has it (the full ticket screen
      // fetches and caches it); a QR glyph until then.
      leading: _TicketThumb(eventId: event.id, userId: widget.currentUserId),
      title: event.title,
      when: event.startDate,
      trailing: IconButton(
        tooltip: AppLocalizations.of(context)!.eventTicketDelete,
        icon: const Icon(Icons.delete_outline,
            color: AppColors.textTertiary, size: 22),
        onPressed: () => _deleteTicket(event),
      ),
    );
  }

  Widget _card({
    required VoidCallback onTap,
    required Widget leading,
    required String title,
    required DateTime when,
    String? label,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppGlass.radiusCard),
        onTap: onTap,
        child: GlassContainer(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (label != null) ...[
                      Text(
                        label,
                        style: const TextStyle(
                            color: AppColors.richGold,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat.MMMEd(AppLocalizations.of(context)!.localeName).format(when)} \u2022 ${DateFormat.jm(AppLocalizations.of(context)!.localeName).format(when)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.qr_code_2, color: AppColors.richGold, size: 22),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan
// ─────────────────────────────────────────────────────────────────────────────

class _ScanTab extends StatefulWidget {
  const _ScanTab({required this.currentUserId});

  final String currentUserId;

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );
  final QrCheckinService _checkin = QrCheckinService();

  String? _lastValue;
  DateTime _lastHandled = DateTime.fromMillisecondsSinceEpoch(0);
  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null, orElse: () => null);
    if (raw == null) return;

    final now = DateTime.now();
    if (raw == _lastValue &&
        now.difference(_lastHandled) < const Duration(milliseconds: 2500)) {
      return;
    }
    _lastValue = raw;
    _lastHandled = now;
    _processing = true;

    try {
      await _handle(raw);
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) _processing = false;
    }
  }

  Future<void> _handle(String raw) async {
    final l10n = AppLocalizations.of(context)!;
    // Event tickets AND experience booking codes are both redeemed here; the
    // server decides (signature, door rights, RSVP / booking, time window) and
    // records that the two people met in person. Never navigates.
    final code = ScannedCheckInCode.parse(raw);
    final CheckInOutcome r;
    if (code is PaidTicketCode) {
      r = await _checkin.checkInPaidTicket(code);
    } else if (code is EventTicketCode) {
      r = await _checkin.checkInEvent(code);
    } else if (code is BookingTicketCode) {
      r = await _checkin.checkInBooking(code);
    } else {
      _denied(l10n, l10n.qrHubInvalidCode);
      return;
    }
    if (!mounted) return;
    if (r.approved) {
      _approved(l10n, [
        if (r.ticketTypeName != null) r.ticketTypeName!.toUpperCase(),
        if (r.partySize > 1) l10n.tpGroupOf(r.partySize),
        r.name,
      ].where((s) => s.isNotEmpty).join(' · '));
    } else {
      _denied(l10n, r.reasonText(l10n), name: r.name.isEmpty ? null : r.name);
    }
  }

  void _approved(AppLocalizations l10n, String name) {
    if (!mounted) return;
    showScanResult(
      context,
      approved: true,
      statusLabel: l10n.scanResultApproved,
      time: DateTime.now(),
      name: name,
    );
  }

  void _denied(AppLocalizations l10n, String reason, {String? name}) {
    if (!mounted) return;
    showScanResult(
      context,
      approved: false,
      statusLabel: l10n.scanResultDenied,
      time: DateTime.now(),
      name: name,
      detail: reason,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => _buildError(l10n),
        ),
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.richGold, width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.qrHubScanInstructions,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Row(
            children: [
              // Browsers can't drive the torch.
              if (!kIsWeb) ...[
                _round(Icons.flash_on, () => _controller.toggleTorch()),
                const SizedBox(width: 8),
              ],
              _round(Icons.cameraswitch, () => _controller.switchCamera()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _round(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppColors.richGold, size: 20),
        ),
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography,
                color: AppColors.textTertiary, size: 48),
            const SizedBox(height: 16),
            Text(
              l10n.eventCameraPermission,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact QR of an event ticket: the SIGNED ticket cached on this device,
/// or a QR glyph until the full ticket screen has fetched it.
class _TicketThumb extends StatefulWidget {
  const _TicketThumb({required this.eventId, required this.userId});

  final String eventId;
  final String userId;

  @override
  State<_TicketThumb> createState() => _TicketThumbState();
}

class _TicketThumbState extends State<_TicketThumb> {
  late final Future<String?> _payload =
      QrCheckinService().cachedEventTicket(widget.eventId, widget.userId);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: FutureBuilder<String?>(
        future: _payload,
        builder: (context, snap) {
          final payload = snap.data;
          if (payload == null) {
            return const SizedBox(
              width: 72,
              height: 72,
              child: Icon(Icons.qr_code_2, color: AppColors.deepBlack, size: 48),
            );
          }
          return QrImageView(
            data: payload,
            version: QrVersions.auto,
            size: 72,
            gapless: false,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.deepBlack,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.deepBlack,
            ),
          );
        },
      ),
    );
  }
}
