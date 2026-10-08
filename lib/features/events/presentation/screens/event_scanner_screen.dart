import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/qr_checkin_service.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../../discovery/data/datasources/discovery_remote_datasource.dart';
import '../../data/datasources/events_remote_datasource.dart';
import '../../domain/entities/event.dart';
import '../widgets/scan_result_overlay.dart';

/// Organizer-only QR scanner that checks attendees in at the door.
///
/// Every scanned ticket is verified by the SERVER (checkInEventAttendee:
/// signed code, this event, RSVP going, time window, door rights), which also
/// records that organizer and attendee met in person. The live roster here
/// only feeds the checked-in counter. A short debounce stops a single held-up
/// ticket from firing repeatedly.
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
  final QrCheckinService _checkin = QrCheckinService();

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
    // Only a GreenGo EVENT ticket can open this door; everything is verified
    // by the server (signature, this event, RSVP, time window, door rights).
    final code = ScannedCheckInCode.parse(raw);
    if (code is PaidTicketCode) {
      final r = await _checkin.checkInPaidTicket(code, eventId: widget.event.id);
      if (!mounted) return;
      final label = [
        if (r.ticketTypeName != null) r.ticketTypeName!.toUpperCase(),
        r.name,
      ].where((s) => s.isNotEmpty).join(' · ');
      if (r.approved) {
        _approved(l10n, label);
      } else {
        _denied(l10n, r.reasonText(l10n), name: label.isEmpty ? null : label);
      }
      return;
    }
    if (code is! EventTicketCode || code.eventId != widget.event.id) {
      _denied(l10n, code == null ? l10n.eventInvalidTicket : l10n.checkinWrongPlace);
      return;
    }
    final r = await _checkin.checkInEvent(code, eventId: widget.event.id);
    if (!mounted) return;
    final name = r.name.isNotEmpty
        ? r.name
        : (_attendees[code.userId]?.userName ?? '');
    if (r.approved) {
      _approved(l10n, name);
    } else {
      _denied(l10n, CheckInOutcome(
        approved: false,
        alreadyCheckedIn: r.alreadyCheckedIn,
        name: name,
        reason: r.reason,
      ).reasonText(l10n), name: name.isEmpty ? null : name);
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

  /// Lightweight snackbar for scanner-management feedback (add/remove allowed
  /// scanners) — NOT ticket check-in, which uses the full-screen result above.
  void _feedback(String message, {required bool ok}) {
    if (!mounted) return;
    if (!ok) {
      showUserErrorMessage(context, message);
      return;
    }
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

  /// Owner action: invite another GreenGo member (by nickname) to be allowed to
  /// scan/redeem this event's QR tickets.
  Future<void> _manageScanners() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final nickname = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.eventScanManageScanners,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.eventScanInviteScannerHint,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.eventScanNicknameHint,
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.backgroundInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.eventScanAddScanner,
                style: const TextStyle(
                    color: AppColors.richGold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nickname == null || nickname.isEmpty || !mounted) return;
    await _addScannerByNickname(nickname);
  }

  Future<void> _addScannerByNickname(String nickname) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final profile =
          await di.sl<DiscoveryRemoteDataSource>().searchByNickname(nickname);
      if (!mounted) return;
      if (profile == null) {
        _feedback(l10n.eventScanScannerNotFound, ok: false);
        return;
      }
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .update({
        'allowedScannerIds': FieldValue.arrayUnion([profile.userId]),
      });
      if (mounted) {
        _feedback(l10n.eventScanScannerAdded(profile.displayName), ok: true);
      }
    } catch (_) {
      if (mounted) _feedback(l10n.eventScanScannerAddFailed, ok: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Works in browsers too (installed PWA on a phone, or a PC webcam):
    // mobile_scanner asks for camera permission via getUserMedia, and a
    // refusal or missing camera lands in _buildError.
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        title: Text(l10n.eventScanCheckIn),
        actions: [
          IconButton(
            tooltip: l10n.eventScanManageScanners,
            onPressed: _manageScanners,
            icon: const Icon(Icons.person_add_alt, color: AppColors.richGold),
          ),
          // Browsers can't drive the torch.
          if (!kIsWeb)
            IconButton(
              tooltip: l10n.bkTorch,
              onPressed: () => _controller.toggleTorch(),
              icon: const Icon(Icons.flash_on, color: AppColors.richGold),
            ),
          IconButton(
            tooltip: l10n.bkSwitchCamera,
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
