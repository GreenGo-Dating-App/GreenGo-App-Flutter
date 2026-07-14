import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../../events/data/datasources/events_remote_datasource.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/screens/event_detail_loader_screen.dart';
import '../../../events/presentation/screens/events_screen.dart';
import '../../domain/entities/community.dart';

/// The Events tab inside a community — lists the community's own events (RSVP
/// via the existing event detail screen). Owner/admins can create an event that
/// is pre-linked to this community.
class CommunityEventsTab extends StatefulWidget {
  const CommunityEventsTab({
    required this.community,
    required this.canManage,
    required this.currentUserId,
    super.key,
  });

  final Community community;
  final bool canManage;
  final String currentUserId;

  @override
  State<CommunityEventsTab> createState() => _CommunityEventsTabState();
}

class _CommunityEventsTabState extends State<CommunityEventsTab> {
  late Future<List<Event>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Event>> _load() =>
      di.sl<EventsRemoteDataSource>().getCommunityEvents(widget.community.id);

  void _refresh() => setState(() => _future = _load());

  Future<void> _createEvent() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateEventScreen(
          currentUserId: widget.currentUserId,
          communityId: widget.community.id,
          lockCommunity: true,
          onEventCreated: (event) async {
            try {
              await di
                  .sl<EventsRemoteDataSource>()
                  .createEvent(EventModel.fromEntity(event));
            } catch (_) {
              // Surfaced by the empty/refresh state; nothing else to do here.
            }
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
    _refresh();
  }

  void _openEvent(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventDetailLoaderScreen(
          eventId: event.id,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (widget.canManage)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.paddingM,
                AppDimensions.paddingS, AppDimensions.paddingM, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _createEvent,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.richGold,
                  side: const BorderSide(color: AppColors.richGold),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.communitiesCreateEvent),
              ),
            ),
          ),
        Expanded(
          child: FutureBuilder<List<Event>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.richGold),
                );
              }
              final events = (snapshot.data ?? const [])
                  // Show live events (published/scheduled), newest-start first.
                  .where((e) => e.status != EventStatus.draft)
                  .toList()
                ..sort((a, b) => a.startDate.compareTo(b.startDate));
              if (events.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_outlined,
                          size: 56,
                          color: AppColors.textTertiary.withValues(alpha: 0.5)),
                      const SizedBox(height: AppDimensions.paddingM),
                      Text(
                        l10n.communitiesEventsEmpty,
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.richGold,
                backgroundColor: AppColors.backgroundCard,
                onRefresh: () async => _refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _eventTile(context, events[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _eventTile(BuildContext context, Event event) {
    final df = DateFormat('EEE, MMM d • h:mm a');
    return InkWell(
      onTap: () => _openEvent(event),
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.richGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: const Icon(Icons.event, color: AppColors.richGold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    df.format(event.startDate),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
