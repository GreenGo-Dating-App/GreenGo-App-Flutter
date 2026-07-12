import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_glass.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../../events/data/datasources/events_remote_datasource.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/screens/event_detail_loader_screen.dart';
import '../../../events/presentation/screens/event_ticket_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<Event> mine = const <Event>[];
    try {
      final ds = di.sl<EventsRemoteDataSource>();
      // getUserEvents already returns every event the user is going to (RSVP
      // status == going) PLUS the ones they organize, regardless of publish or
      // featured state. Show a scannable ticket for ALL of them — never filter
      // by publish/live state. We only reorder by time so the tickets the user
      // actually needs at the door surface first.
      final all = await ds.getUserEvents(widget.currentUserId);
      final now = DateTime.now();
      // "Not past" = still upcoming OR currently ongoing (endDate not reached).
      // This keeps today's / in-progress events (which the future-only filter
      // used to hide) at the top alongside upcoming ones.
      bool isPast(Event e) => e.endDate.isBefore(now);
      final upcoming = all.where((e) => !isPast(e)).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      final past = all.where(isPast).toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      mine = [...upcoming, ...past];
    } catch (_) {
      mine = const <Event>[];
    }
    if (mounted) setState(() => _events = mine);
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
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
        itemCount: events.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.qrHubTicketHint,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 12.5),
              ),
            );
          }
          return _ticketCard(context, events[index - 1]);
        },
      ),
    );
  }

  Widget _ticketCard(BuildContext context, Event event) {
    final payload =
        EventTicketPayload(eventId: event.id, userId: widget.currentUserId)
            .encode();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppGlass.radiusCard),
        onTap: () => Navigator.of(context).push(
          EventTicketScreen.route(event: event, userId: widget.currentUserId),
        ),
        child: GlassContainer(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Compact scannable QR (same payload as the full ticket screen).
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: QrImageView(
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
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.title,
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
                      DateFormat('EEE, MMM d • h:mm a').format(event.startDate),
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
  late final EventsRemoteDataSource _dataSource;

  String? _lastValue;
  DateTime _lastHandled = DateTime.fromMillisecondsSinceEpoch(0);
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _dataSource = di.sl<EventsRemoteDataSource>();
  }

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
    final payload = EventTicketPayload.tryDecode(raw);
    if (payload == null) {
      _feedback(l10n.qrHubInvalidCode, ok: false);
      return;
    }

    Event? event;
    try {
      event = await _dataSource.getEventById(payload.eventId);
    } catch (_) {
      event = null;
    }
    if (!mounted) return;
    if (event == null) {
      _feedback(l10n.qrHubInvalidCode, ok: false);
      return;
    }

    final me = widget.currentUserId;

    // Case A — the current user organizes this event and is scanning SOMEONE
    // ELSE's ticket → the existing door check-in.
    if (event.organizerId == me && payload.userId != me) {
      try {
        await _dataSource.checkInAttendee(
          eventId: event.id,
          attendeeUserId: payload.userId,
        );
        _feedback(l10n.eventCheckedInSuccess(payload.userId), ok: true);
      } catch (_) {
        _feedback(l10n.eventInvalidTicket, ok: false);
      }
      return;
    }

    // Case B — the code is the current user's own ticket → just open the event.
    if (payload.userId == me) {
      _openEvent(event.id);
      return;
    }

    // Case C — a shared event code the current user can join → join (capacity-
    // safe, existing join logic) then open the event.
    try {
      await _dataSource.joinEventWithTier(eventId: event.id, userId: me);
      _feedback(l10n.qrHubJoinedEvent, ok: true);
      _openEvent(event.id);
    } catch (_) {
      _feedback(l10n.qrHubInvalidCode, ok: false);
    }
  }

  void _openEvent(String eventId) {
    if (!mounted) return;
    Navigator.of(context).push(
      EventDetailLoaderScreen.route(
        eventId: eventId,
        currentUserId: widget.currentUserId,
      ),
    );
  }

  void _feedback(String message, {required bool ok}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
          duration: const Duration(milliseconds: 1600),
        ),
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
          errorBuilder: (context, error, child) => _buildError(l10n),
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
              _round(Icons.flash_on, () => _controller.toggleTorch()),
              const SizedBox(width: 8),
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
