import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/events_remote_datasource.dart';
import '../../domain/entities/event.dart';

/// Organizer-only live attendance sheet: who is checked in vs not, plus the
/// total expected headcount (going attendees + the guests they bring).
class EventAttendanceScreen extends StatefulWidget {
  const EventAttendanceScreen({required this.event, super.key});

  final Event event;

  static Route<void> route({required Event event}) {
    return MaterialPageRoute(
      builder: (_) => EventAttendanceScreen(event: event),
    );
  }

  @override
  State<EventAttendanceScreen> createState() => _EventAttendanceScreenState();
}

class _EventAttendanceScreenState extends State<EventAttendanceScreen> {
  late final EventsRemoteDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = di.sl<EventsRemoteDataSource>();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        title: Text(l10n.eventAttendance),
      ),
      body: SafeArea(
        child: StreamBuilder<List<EventAttendee>>(
          stream: _dataSource.watchAttendees(widget.event.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.richGold),
              );
            }
            final going = (snapshot.data ?? const <EventAttendee>[])
                .where((a) => a.status == RSVPStatus.going)
                .toList()
              ..sort((a, b) {
                // Not-yet-checked-in first, then by name.
                if (a.checkedIn != b.checkedIn) return a.checkedIn ? 1 : -1;
                return a.userName.toLowerCase().compareTo(
                    b.userName.toLowerCase());
              });

            final checkedIn = going.where((a) => a.checkedIn).length;
            final guests =
                going.fold<int>(0, (sum, a) => sum + a.guestCount);
            final headcount = going.length + guests;

            return Column(
              children: [
                _buildSummary(
                  l10n,
                  total: going.length,
                  checkedIn: checkedIn,
                  headcount: headcount,
                ),
                Expanded(
                  child: going.isEmpty
                      ? Center(
                          child: Text(
                            l10n.eventsNoAttendeesYet,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: going.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) =>
                              _buildRow(l10n, going[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummary(
    AppLocalizations l10n, {
    required int total,
    required int checkedIn,
    required int headcount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _stat(l10n.eventCheckedIn, '$checkedIn / $total'),
            _divider(),
            _stat(l10n.eventTotalHeadcount, '$headcount'),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.richGold,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: AppColors.textTertiary.withOpacity(0.25),
      );

  Widget _buildRow(AppLocalizations l10n, EventAttendee a) {
    final photo = a.userPhotoUrl;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.backgroundCard,
            backgroundImage: (photo != null && photo.isNotEmpty)
                ? CachedNetworkImageProvider(photo)
                : null,
            child: (photo == null || photo.isEmpty)
                ? Text(
                    a.userName.isNotEmpty ? a.userName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.textPrimary),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.userName.isNotEmpty ? a.userName : '—',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (a.guestCount > 0)
                  Text(
                    l10n.eventGuestsBringing(a.guestCount),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          _statusChip(l10n, a.checkedIn),
        ],
      ),
    );
  }

  Widget _statusChip(AppLocalizations l10n, bool checkedIn) {
    final color = checkedIn ? Colors.green : AppColors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            checkedIn ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            checkedIn ? l10n.eventCheckedIn : l10n.eventNotCheckedIn,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
