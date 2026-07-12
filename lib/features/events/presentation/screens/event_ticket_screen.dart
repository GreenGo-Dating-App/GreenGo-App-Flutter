import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
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
/// Renders a premium, self-contained ticket: the event image, name, when/where
/// (date, venue, location) and how many people this ticket admits, wrapped
/// around a scannable QR (validated + checked in by the organizer's scanner).
/// When the event allows guests, an inline control lets the holder pick how
/// many guests they are bringing (persisted to their attendee doc) — which is
/// reflected live in the "Admits N" count.
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

  /// Best available "where" line: street address, else city/country, else the
  /// venue name (as a last resort so the row never renders blank).
  String? get _locationLine {
    final event = widget.event;
    final address = event.address?.trim();
    if (address != null && address.isNotEmpty) return address;
    final parts = <String>[
      if ((event.city ?? '').trim().isNotEmpty) event.city!.trim(),
      if ((event.country ?? '').trim().isNotEmpty) event.country!.trim(),
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    final venue = event.locationName.trim();
    return venue.isNotEmpty ? venue : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final event = widget.event;
    final payload = EventTicketPayload(
      eventId: event.id,
      userId: widget.userId,
    ).encode();

    // This ticket admits the holder plus any guests they're bringing.
    final admitCount = 1 + (_guestCount < 0 ? 0 : _guestCount);
    final venue = event.locationName.trim();
    final location = _locationLine;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        title: Text(l10n.eventMyTicket),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TicketCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageHeader(event, admitCount, l10n),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInfoRow(
                            icon: Icons.event_outlined,
                            label: l10n.eventTicketWhen,
                            value: DateFormat('EEE, MMM d • h:mm a')
                                .format(event.startDate),
                          ),
                          if (venue.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildInfoRow(
                              icon: Icons.location_city_outlined,
                              label: l10n.eventTicketVenue,
                              value: venue,
                            ),
                          ],
                          if (location != null && location != venue) ...[
                            const SizedBox(height: 14),
                            _buildInfoRow(
                              icon: Icons.place_outlined,
                              label: l10n.eventTicketWhere,
                              value: location,
                            ),
                          ],
                          const SizedBox(height: 14),
                          _buildInfoRow(
                            icon: Icons.groups_outlined,
                            label: l10n.eventTicketGuestsLabel,
                            value: l10n.eventTicketAdmits(admitCount),
                          ),
                        ],
                      ),
                    ),
                    const _PerforatedDivider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                      child: Column(
                        children: [
                          // White quiet-zone card keeps the QR reliably
                          // scannable over the dark/glass backdrop.
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
                          const SizedBox(height: 14),
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
                  ],
                ),
              ),
              if (event.guestsAllowed) ...[
                const SizedBox(height: 20),
                _buildGuestPicker(l10n),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Rounded-top event image with a gradient scrim + the event name overlaid.
  Widget _buildImageHeader(
    Event event,
    int admitCount,
    AppLocalizations l10n,
  ) {
    const double height = 180;
    const radius = Radius.circular(AppGlass.radiusCard);
    final imageUrl = event.imageUrl;

    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: radius, topRight: radius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(
                  color: AppColors.backgroundInput,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.richGold,
                      ),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => _buildImageFallback(),
              )
            else
              _buildImageFallback(),
            // Bottom scrim so the overlaid title stays readable on any image.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                    Colors.black87,
                  ],
                  stops: [0.35, 0.75, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
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
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _AdmitBadge(text: l10n.eventTicketAdmits(admitCount)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.charcoal, AppColors.deepBlack],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_activity_outlined,
          color: AppColors.richGold,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.richGold, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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

/// Glass "stub" that holds the whole ticket, with a subtle gold hairline.
class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppGlass.radiusCard),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppGlass.radiusCard),
        child: child,
      ),
    );
  }
}

/// Small gold "Admits N" pill overlaid on the ticket header image.
class _AdmitBadge extends StatelessWidget {
  const _AdmitBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.richGold.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups, color: AppColors.deepBlack, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.deepBlack,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Perforated ticket-stub divider: two side notches + a dashed line, echoing a
/// torn-off admission ticket.
class _PerforatedDivider extends StatelessWidget {
  const _PerforatedDivider();

  @override
  Widget build(BuildContext context) {
    const notch = BoxDecoration(
      color: AppColors.backgroundDark,
      shape: BoxShape.circle,
    );
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Transform.translate(
            offset: const Offset(-12, 0),
            child: Container(width: 24, height: 24, decoration: notch),
          ),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: _DashedLine(),
            ),
          ),
          Transform.translate(
            offset: const Offset(12, 0),
            child: Container(width: 24, height: 24, decoration: notch),
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: _DashedLinePainter(),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.richGold.withValues(alpha: 0.35)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const dashWidth = 6.0;
    const gap = 5.0;
    final y = size.height / 2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
