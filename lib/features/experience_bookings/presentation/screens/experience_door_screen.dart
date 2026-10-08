import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/qr_checkin_service.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../../discovery/data/datasources/discovery_remote_datasource.dart';
import '../../../events/presentation/widgets/scan_result_overlay.dart';
import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../data/datasources/bookings_remote_datasource.dart';
import '../../domain/entities/booking.dart';
import 'booking_detail_screen.dart';

/// The DOOR of an experience: scan ANY guest's booking QR
/// (`greengo:checkin:{bookingId}:{code}`) one after the other, like the event
/// door scanner. The server (checkInBooking) verifies the signed code, that
/// the booking belongs to THIS experience, the scanner's rights (host or a
/// door helper) and the time window, checks the guest in and records that
/// host and guest met in person. Works in browsers too.
class ExperienceDoorScannerScreen extends StatefulWidget {
  const ExperienceDoorScannerScreen({
    super.key,
    required this.experience,
    required this.currentUserId,
  });

  final UserExperience experience;
  final String currentUserId;

  static Route<void> route({
    required UserExperience experience,
    required String currentUserId,
  }) =>
      MaterialPageRoute(
        builder: (_) => ExperienceDoorScannerScreen(
            experience: experience, currentUserId: currentUserId),
      );

  @override
  State<ExperienceDoorScannerScreen> createState() =>
      _ExperienceDoorScannerScreenState();
}

class _ExperienceDoorScannerScreenState
    extends State<ExperienceDoorScannerScreen> {
  final MobileScannerController _controller =
      MobileScannerController(detectionSpeed: DetectionSpeed.normal);
  final QrCheckinService _checkin = QrCheckinService();

  String? _lastValue;
  DateTime _lastHandled = DateTime.fromMillisecondsSinceEpoch(0);
  bool _processing = false;
  int _checkedInNow = 0;

  bool get _isHost => widget.experience.hostId == widget.currentUserId;

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
    final l = AppLocalizations.of(context)!;
    final code = ScannedCheckInCode.parse(raw);
    if (code is! BookingTicketCode) {
      _result(false, l.scanResultDenied,
          detail: code == null ? l.bkErrInvalidCode : l.checkinWrongPlace);
      return;
    }
    final r = await _checkin.checkInBooking(code,
        experienceId: widget.experience.id);
    if (!mounted) return;
    if (r.approved) {
      setState(() => _checkedInNow++);
      _result(true, l.scanResultApproved,
          name: r.name,
          detail: r.guestCount > 1 ? l.expDoorAdmits(r.guestCount) : null);
    } else {
      _result(false, l.scanResultDenied,
          name: r.name.isEmpty ? null : r.name, detail: r.reasonText(l));
    }
  }

  void _result(bool ok, String label, {String? name, String? detail}) {
    if (!mounted) return;
    showScanResult(context,
        approved: ok,
        statusLabel: label,
        time: DateTime.now(),
        name: name,
        detail: detail);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        title: Text(l.expDoorTitle),
        actions: [
          if (_isHost)
            IconButton(
              tooltip: l.expAttendanceTitle,
              icon: const Icon(Icons.fact_check_outlined,
                  color: AppColors.richGold),
              onPressed: () => Navigator.of(context).push(
                  ExperienceAttendanceScreen.route(
                      experience: widget.experience,
                      currentUserId: widget.currentUserId)),
            ),
          if (_isHost)
            IconButton(
              tooltip: l.expDoorHelpers,
              icon: const Icon(Icons.group_add_outlined,
                  color: AppColors.richGold),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                backgroundColor: AppColors.backgroundCard,
                isScrollControlled: true,
                builder: (_) =>
                    _DoorHelpersSheet(experience: widget.experience),
              ),
            ),
          if (!kIsWeb)
            IconButton(
              tooltip: l.bkTorch,
              onPressed: () => _controller.toggleTorch(),
              icon: const Icon(Icons.flash_on, color: AppColors.richGold),
            ),
          IconButton(
            tooltip: l.bkSwitchCamera,
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch, color: AppColors.richGold),
          ),
        ],
      ),
      body: Stack(children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.eventCameraPermission,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ),
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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(widget.experience.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.richGold, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(l.expDoorInstructions,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              if (_checkedInNow > 0) ...[
                const SizedBox(height: 6),
                Text(l.expDoorCheckedInNow(_checkedInNow),
                    style: const TextStyle(
                        color: AppColors.successGreen, fontSize: 13)),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Host: who is expected and who is in, per date of the experience.
class ExperienceAttendanceScreen extends StatefulWidget {
  const ExperienceAttendanceScreen({
    super.key,
    required this.experience,
    required this.currentUserId,
  });

  final UserExperience experience;
  final String currentUserId;

  static Route<void> route({
    required UserExperience experience,
    required String currentUserId,
  }) =>
      MaterialPageRoute(
        builder: (_) => ExperienceAttendanceScreen(
            experience: experience, currentUserId: currentUserId),
      );

  @override
  State<ExperienceAttendanceScreen> createState() =>
      _ExperienceAttendanceScreenState();
}

class _ExperienceAttendanceScreenState
    extends State<ExperienceAttendanceScreen> {
  // null == loading.
  List<Booking>? _bookings;
  final Map<String, String> _names = <String, String>{};
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final page = await BookingsRemoteDataSource().bookings(
        BookingsQuery(
          role: BookingRole.host,
          uid: widget.currentUserId,
          upcoming: true,
          experienceId: widget.experience.id,
        ),
        limit: 100,
      );
      final list = page.items
          .where((b) =>
              b.status == BookingStatus.confirmed ||
              b.status == BookingStatus.completed ||
              b.status == BookingStatus.noShow)
          .toList();
      await _loadNames(list.map((b) => b.guestId).toSet());
      if (mounted) setState(() => _bookings = list);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _loadNames(Set<String> ids) async {
    final missing = ids.where((id) => !_names.containsKey(id)).take(100);
    final db = FirebaseFirestore.instance;
    await Future.wait(missing.map((id) async {
      try {
        final d = (await db.collection('profiles').doc(id).get()).data();
        _names[id] = (d?['displayName'] as String?) ??
            (d?['nickname'] as String?) ??
            '';
      } catch (_) {
        _names[id] = '';
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bookings = _bookings;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        title: Text(l.expAttendanceTitle),
        actions: [
          IconButton(
            tooltip: l.expDoorTitle,
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.richGold),
            onPressed: () async {
              await Navigator.of(context).push(ExperienceDoorScannerScreen.route(
                  experience: widget.experience,
                  currentUserId: widget.currentUserId));
              if (mounted) _load();
            },
          ),
        ],
      ),
      body: _failed && bookings == null
          ? Center(
              child: Text(l.checkinNetwork,
                  style: const TextStyle(color: AppColors.textSecondary)))
          : bookings == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.richGold))
              : RefreshIndicator(
                  color: AppColors.richGold,
                  onRefresh: _load,
                  child: bookings.isEmpty
                      ? ListView(children: [
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(l.expAttendanceEmpty,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                          ),
                        ])
                      : _list(l, bookings),
                ),
    );
  }

  Widget _list(AppLocalizations l, List<Booking> bookings) {
    // Grouped by date (slot start), soonest first.
    final bySlot = <DateTime, List<Booking>>{};
    for (final b in bookings) {
      bySlot.putIfAbsent(b.slotStart, () => <Booking>[]).add(b);
    }
    final slots = bySlot.keys.toList()..sort();
    final fmt = DateFormat('EEE, MMM d • HH:mm');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final s in slots) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Row(children: [
              Expanded(
                child: Text(fmt.format(s),
                    style: const TextStyle(
                        color: AppColors.richGold,
                        fontWeight: FontWeight.w700)),
              ),
              Text(
                l.expAttendanceCount(
                  bySlot[s]!.where((b) => b.isCheckedIn).fold<int>(
                      0, (n, b) => n + (b.guests < 1 ? 1 : b.guests)),
                  bySlot[s]!.fold<int>(
                      0, (n, b) => n + (b.guests < 1 ? 1 : b.guests)),
                ),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ]),
          ),
          for (final b in bySlot[s]!)
            Card(
              color: AppColors.backgroundCard,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => Navigator.of(context).push(
                    BookingDetailScreen.route(
                        bookingId: b.id,
                        currentUserId: widget.currentUserId,
                        initial: b)),
                leading: Icon(
                  b.isCheckedIn
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: b.isCheckedIn
                      ? AppColors.successGreen
                      : AppColors.textTertiary,
                ),
                title: Text(
                  (_names[b.guestId] ?? '').isNotEmpty
                      ? _names[b.guestId]!
                      : b.guestId,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  b.isCheckedIn
                      ? '${l.eventCheckedIn} • ${DateFormat.Hm().format(b.checkedInAt!.toLocal())}'
                      : l.eventNotCheckedIn,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                trailing: b.guests > 1
                    ? Text('×${b.guests}',
                        style: const TextStyle(color: AppColors.textSecondary))
                    : null,
              ),
            ),
        ],
      ],
    );
  }
}

/// Host: the members allowed to scan guests in at the door (max 10).
/// Stored on the experience (`allowedScannerIds`); the server reads it.
class _DoorHelpersSheet extends StatefulWidget {
  const _DoorHelpersSheet({required this.experience});

  final UserExperience experience;

  @override
  State<_DoorHelpersSheet> createState() => _DoorHelpersSheetState();
}

class _DoorHelpersSheetState extends State<_DoorHelpersSheet> {
  static const int _max = 10;
  late List<String> _ids = List<String>.of(widget.experience.allowedScannerIds);
  final Map<String, String> _names = <String, String>{};
  final TextEditingController _nick = TextEditingController();
  bool _busy = false;

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore
      .instance
      .collection('user_experiences')
      .doc(widget.experience.id);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _nick.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final d = (await _doc.get()).data();
      final ids = (d?['allowedScannerIds'] as List?)?.whereType<String>().toList() ??
          const <String>[];
      final db = FirebaseFirestore.instance;
      await Future.wait(ids.where((i) => !_names.containsKey(i)).map((id) async {
        final p = (await db.collection('profiles').doc(id).get()).data();
        _names[id] = (p?['displayName'] as String?) ?? (p?['nickname'] as String?) ?? id;
      }));
      if (mounted) setState(() => _ids = ids);
    } catch (_) {/* keep the list shown */}
  }

  Future<void> _add() async {
    final l = AppLocalizations.of(context)!;
    final nickname = _nick.text.trim().replaceFirst('@', '');
    if (nickname.isEmpty || _busy) return;
    if (_ids.length >= _max) {
      showUserErrorMessage(context, l.expDoorHelpersMax(_max));
      return;
    }
    setState(() => _busy = true);
    try {
      final profile =
          await di.sl<DiscoveryRemoteDataSource>().searchByNickname(nickname);
      if (!mounted) return;
      if (profile == null) {
        showUserErrorMessage(context, l.eventScanScannerNotFound);
        return;
      }
      if (profile.userId == widget.experience.hostId) return;
      await _doc.update({
        'allowedScannerIds': FieldValue.arrayUnion([profile.userId]),
      });
      _names[profile.userId] = profile.displayName;
      _nick.clear();
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l.eventScanScannerAdded(profile.displayName))));
      }
    } catch (_) {
      if (mounted) showUserErrorMessage(context, l.eventScanScannerAddFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(String id) async {
    try {
      await _doc.update({
        'allowedScannerIds': FieldValue.arrayRemove([id]),
      });
      await _refresh();
    } catch (_) {
      if (mounted) {
        showUserErrorMessage(
            context, AppLocalizations.of(context)!.eventScanScannerAddFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.expDoorHelpers,
              style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(l.expDoorHelpersHint,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _nick,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l.eventScanNicknameHint,
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _busy ? null : _add,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack),
              child: Text(l.eventScanAddScanner),
            ),
          ]),
          const SizedBox(height: 12),
          for (final id in _ids)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.badge_outlined,
                  color: AppColors.richGold),
              title: Text(_names[id] ?? id,
                  style: const TextStyle(color: AppColors.textPrimary)),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: AppColors.textTertiary),
                onPressed: () => _remove(id),
              ),
            ),
        ],
      ),
    );
  }
}
