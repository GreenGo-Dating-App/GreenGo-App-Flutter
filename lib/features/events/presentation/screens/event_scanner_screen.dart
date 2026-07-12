import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/events_remote_datasource.dart';
import '../../domain/entities/event.dart';
import 'event_ticket_screen.dart';

/// Organizer-only QR scanner that checks attendees in at the door.
///
/// Validates every scanned code against this event (namespace + eventId match,
/// attendee exists & is going), then flips their `checkedIn` flag. A short
/// debounce stops a single held-up ticket from firing repeatedly.
class EventScannerScreen extends StatefulWidget {
  const EventScannerScreen({
    required this.event,
    required this.ownerUserId,
    super.key,
  });

  final Event event;
  final String ownerUserId;

  static Route<void> route({
    required Event event,
    required String ownerUserId,
  }) {
    return MaterialPageRoute(
      builder: (_) =>
          EventScannerScreen(event: event, ownerUserId: ownerUserId),
    );
  }

  @override
  State<EventScannerScreen> createState() => _EventScannerScreenState();
}

class _EventScannerScreenState extends State<EventScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );
  late final EventsRemoteDataSource _dataSource;
  StreamSubscription<List<EventAttendee>>? _attendeesSub;

  /// Live attendee roster (keyed by userId) used for validation + checked-in state.
  final Map<String, EventAttendee> _attendees = {};

  String? _lastValue;
  DateTime _lastHandled = DateTime.fromMillisecondsSinceEpoch(0);
  bool _processing = false;
  int _checkedInCount = 0;

  @override
  void initState() {
    super.initState();
    _dataSource = di.sl<EventsRemoteDataSource>();
    _attendeesSub = _dataSource.watchAttendees(widget.event.id).listen((list) {
      _attendees
        ..clear()
        ..addEntries(list.map((a) => MapEntry(a.userId, a)));
      final count = list.where((a) => a.checkedIn).length;
      if (mounted) setState(() => _checkedInCount = count);
    });
  }

  @override
  void dispose() {
    _attendeesSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null, orElse: () => null);
    if (raw == null) return;

    // Debounce: ignore the same value re-detected within 2.5s.
    final now = DateTime.now();
    if (raw == _lastValue &&
        now.difference(_lastHandled) < const Duration(milliseconds: 2500)) {
      return;
    }
    _lastValue = raw;
    _lastHandled = now;
    _processing = true;

    try {
      await _handlePayload(raw);
    } finally {
      // Small cool-down so we don't hammer on a held-up ticket.
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) _processing = false;
    }
  }

  Future<void> _handlePayload(String raw) async {
    final l10n = AppLocalizations.of(context)!;
    final payload = EventTicketPayload.tryDecode(raw);

    // Invalid: not a GreenGo ticket, or for a different event.
    if (payload == null || payload.eventId != widget.event.id) {
      _feedback(l10n.eventInvalidTicket, ok: false);
      return;
    }

    final attendee = _attendees[payload.userId];
    if (attendee == null || attendee.status != RSVPStatus.going) {
      _feedback(l10n.eventInvalidTicket, ok: false);
      return;
    }
    if (attendee.checkedIn) {
      _feedback(l10n.eventAlreadyCheckedIn(attendee.userName), ok: false);
      return;
    }

    try {
      await _dataSource.checkInAttendee(
        eventId: widget.event.id,
        attendeeUserId: payload.userId,
      );
      _feedback(l10n.eventCheckedInSuccess(attendee.userName), ok: true);
    } catch (_) {
      _feedback(l10n.eventInvalidTicket, ok: false);
    }
  }

  void _feedback(String message, {required bool ok}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
          duration: const Duration(milliseconds: 1400),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        title: Text(l10n.eventScanCheckIn),
        actions: [
          IconButton(
            tooltip: 'Flash',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flash_on, color: AppColors.richGold),
          ),
          IconButton(
            tooltip: 'Flip camera',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch, color: AppColors.richGold),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) =>
                _buildError(context, error, l10n),
          ),
          // Framing reticle.
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
          // Instructions + running checked-in tally.
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.eventScanInstructions,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${l10n.eventCheckedIn}: $_checkedInCount',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    MobileScannerException error,
    AppLocalizations l10n,
  ) {
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
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
