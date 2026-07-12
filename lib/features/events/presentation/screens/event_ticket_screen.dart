import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_glass.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/events_remote_datasource.dart';
import '../../domain/entities/event.dart';

/// Compact, namespaced codec for the QR ticket payload.
///
/// A ticket encodes only the two ids needed to validate + check in:
///   greengo:{"e":"<eventId>","u":"<userId>"}
/// The `greengo:` prefix lets the scanner ignore unrelated QR codes cheaply.
class EventTicketPayload {
  const EventTicketPayload({required this.eventId, required this.userId});

  static const String prefix = 'greengo:';

  final String eventId;
  final String userId;

  String encode() => '$prefix${jsonEncode({'e': eventId, 'u': userId})}';

  /// Returns null if [raw] is not a well-formed GreenGo ticket.
  static EventTicketPayload? tryDecode(String? raw) {
    if (raw == null || !raw.startsWith(prefix)) return null;
    try {
      final map = jsonDecode(raw.substring(prefix.length))
          as Map<String, dynamic>;
      final e = map['e'] as String?;
      final u = map['u'] as String?;
      if (e == null || u == null || e.isEmpty || u.isEmpty) return null;
      return EventTicketPayload(eventId: e, userId: u);
    } catch (_) {
      return null;
    }
  }
}

/// Attendee's QR "ticket" for an event they are going to.
///
/// Shows a scannable QR (validated + checked in by the organizer's scanner),
/// the event title/date, and — when the event allows guests — a control to
/// pick how many guests they are bringing (persisted to their attendee doc).
class EventTicketScreen extends StatefulWidget {
  const EventTicketScreen({
    required this.event,
    required this.userId,
    super.key,
  });

  final Event event;
  final String userId;

  static Route<void> route({required Event event, required String userId}) {
    return MaterialPageRoute(
      builder: (_) => EventTicketScreen(event: event, userId: userId),
    );
  }

  @override
  State<EventTicketScreen> createState() => _EventTicketScreenState();
}

class _EventTicketScreenState extends State<EventTicketScreen> {
  late final EventsRemoteDataSource _dataSource;
  int _guestCount = 0;
  bool _savingGuests = false;

  @override
  void initState() {
    super.initState();
    _dataSource = di.sl<EventsRemoteDataSource>();
    // Seed guest count from the current RSVP, if present in the loaded event.
    final me = widget.event.attendees
        .where((a) => a.userId == widget.userId)
        .toList();
    if (me.isNotEmpty) _guestCount = me.first.guestCount;
  }

  Future<void> _setGuestCount(int value) async {
    final clamped =
        value.clamp(0, widget.event.guestsAllowedPerAttendee).toInt();
    if (clamped == _guestCount) return;
    setState(() {
      _guestCount = clamped;
      _savingGuests = true;
    });
    try {
      await _dataSource.setAttendeeGuestCount(
        eventId: widget.event.id,
        userId: widget.userId,
        guestCount: clamped,
      );
    } finally {
      if (mounted) setState(() => _savingGuests = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final payload = EventTicketPayload(
      eventId: widget.event.id,
      userId: widget.userId,
    ).encode();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        title: Text(l10n.eventMyTicket),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      widget.event.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('EEE, MMM d • h:mm a')
                          .format(widget.event.startDate),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // White quiet-zone card keeps the QR reliably scannable
                    // over the dark/glass backdrop.
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppGlass.radiusCard),
                      ),
                      child: QrImageView(
                        data: payload,
                        version: QrVersions.auto,
                        size: 220,
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
                    const SizedBox(height: 16),
                    Text(
                      l10n.eventTicketSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.event.guestsAllowed) ...[
                const SizedBox(height: 20),
                _buildGuestPicker(l10n),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestPicker(AppLocalizations l10n) {
    final max = widget.event.guestsAllowedPerAttendee;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.group_add, color: AppColors.richGold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.eventBringGuests,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.eventGuestCount(_guestCount, max),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: (_savingGuests || _guestCount <= 0)
                ? null
                : () => _setGuestCount(_guestCount - 1),
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.richGold,
          ),
          Text(
            '$_guestCount',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: (_savingGuests || _guestCount >= max)
                ? null
                : () => _setGuestCount(_guestCount + 1),
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.richGold,
          ),
        ],
      ),
    );
  }
}
