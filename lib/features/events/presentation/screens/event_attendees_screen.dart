import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/user_directory_service.dart';
import '../../../../generated/app_localizations.dart';
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../data/datasources/events_remote_datasource.dart';
import '../../domain/entities/event.dart';

/// Every attendee of an event, with endless scrolling.
///
/// Reached from the "see all" action next to the attendee strip on the event
/// page, which only previews the first few.
///
/// A row reads "Mark Red +5" when that attendee is bringing guests, and just
/// "Mark Red" when they are not.
///
/// Privacy is enforced exactly as on the event page: invisible and
/// organizer-only attendees are hidden from everyone but themselves and the
/// organizer, and anonymous attendees are shown without a name or photo.
class EventAttendeesScreen extends StatefulWidget {
  const EventAttendeesScreen({
    required this.event,
    required this.currentUserId,
    super.key,
  });

  final Event event;
  final String currentUserId;

  static Route<void> route({
    required Event event,
    required String currentUserId,
  }) =>
      MaterialPageRoute(
        builder: (_) => EventAttendeesScreen(
            event: event, currentUserId: currentUserId),
      );

  @override
  State<EventAttendeesScreen> createState() => _EventAttendeesScreenState();
}

class _EventAttendeesScreenState extends State<EventAttendeesScreen> {
  static const _pageSize = 30;

  final _scroll = ScrollController();
  final List<EventAttendee> _items = [];
  final Set<String> _seen = {};
  Map<String, UserBrief> _dir = const {};

  String? _cursor;
  bool _loading = false;
  bool _done = false;
  bool _failed = false;
  bool _openingProfile = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loading || _done) return;
    if (_scroll.position.maxScrollExtent - _scroll.position.pixels < 400) {
      _loadMore();
    }
  }

  bool _visible(EventAttendee a) =>
      a.status == RSVPStatus.going &&
      a.isVisibleTo(widget.currentUserId, widget.event.organizerId);

  Future<void> _loadMore() async {
    if (_loading || _done) return;
    setState(() => _loading = true);
    try {
      // Keep paging until we have a screenful of VISIBLE attendees — a page can
      // be mostly hidden entries, which would otherwise stall the scroll.
      var added = 0;
      while (added < 10 && !_done) {
        final page = await di.sl<EventsRemoteDataSource>().getAttendeesPage(
              eventId: widget.event.id,
              startAfterId: _cursor,
              limit: _pageSize,
            );
        if (page.isEmpty) {
          _done = true;
          break;
        }
        _cursor = page.last.userId;
        if (page.length < _pageSize) _done = true;
        for (final a in page) {
          if (!_visible(a)) continue;
          if (!_seen.add(a.userId)) continue;
          _items.add(a);
          added++;
        }
      }
      // Resolve current photos/names — the snapshotted ones are often stale.
      final dir = await UserDirectoryService.instance
          .resolve(_items.map((a) => a.userId));
      if (!mounted) return;
      setState(() {
        _dir = dir;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = _items.isEmpty;
        _done = true;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _seen.clear();
      _cursor = null;
      _done = false;
      _failed = false;
    });
    await _loadMore();
  }

  bool _isAnon(EventAttendee a) =>
      a.isAnonymous &&
      widget.currentUserId != a.userId &&
      widget.currentUserId != widget.event.organizerId;

  /// "Mark Red +5" when bringing guests, otherwise just "Mark Red".
  String _label(EventAttendee a) {
    final name =
        a.displayNameFor(widget.currentUserId, widget.event.organizerId);
    final resolved = _isAnon(a) ? name : (_dir[a.userId]?.name ?? name);
    return a.guestCount > 0 ? '$resolved +${a.guestCount}' : resolved;
  }

  Future<void> _openProfile(EventAttendee a) async {
    // An anonymous attendee has deliberately hidden who they are.
    if (_isAnon(a) || _openingProfile) return;
    setState(() => _openingProfile = true);
    try {
      final profile = await di.sl<ProfileRemoteDataSource>().getProfile(a.userId);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProfileDetailScreen(
          profile: profile,
          currentUserId: widget.currentUserId,
        ),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.attendeesProfileFailed)));
    } finally {
      if (mounted) setState(() => _openingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Total expected headcount: attendees plus everyone they are bringing.
    final guests = _items.fold<int>(0, (sum, a) => sum + a.guestCount);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.eventsAttendees,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            Text(
              guests > 0
                  ? l10n.attendeesCountWithGuests(_items.length, guests)
                  : l10n.attendeesCount(_items.length),
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 11.5),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.richGold,
        onRefresh: _refresh,
        child: _failed
            ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                Padding(
                  padding: const EdgeInsets.only(top: 120),
                  child: Center(
                      child: Text(l10n.attendeesLoadFailed,
                          style: const TextStyle(
                              color: AppColors.textSecondary))),
                ),
              ])
            : (_items.isEmpty && !_loading)
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 120),
                        child: Center(
                            child: Text(l10n.eventsNoAttendeesYet,
                                style: const TextStyle(
                                    color: AppColors.textSecondary))),
                      ),
                    ],
                  )
                : ListView.separated(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _items.length + (_done ? 0 : 1),
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, indent: 72, color: AppColors.divider),
                    itemBuilder: (context, i) {
                      if (i >= _items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.richGold)),
                        );
                      }
                      return _row(_items[i]);
                    },
                  ),
      ),
    );
  }

  Widget _row(EventAttendee a) {
    final anon = _isAnon(a);
    final photo = anon ? null : (a.userPhotoUrl ?? _dir[a.userId]?.photoUrl);
    final isOrganizer = a.userId == widget.event.organizerId;

    return ListTile(
      onTap: anon ? null : () => _openProfile(a),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.backgroundInput,
        backgroundImage: (photo != null && photo.isNotEmpty)
            ? CachedNetworkImageProvider(photo)
            : null,
        child: (photo == null || photo.isEmpty)
            ? Icon(anon ? Icons.visibility_off : Icons.person,
                color: AppColors.textTertiary, size: 20)
            : null,
      ),
      title: Text(
        _label(a),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w600),
      ),
      subtitle: a.guestCount > 0
          ? Text(AppLocalizations.of(context)!.attendeesBringing(a.guestCount),
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 11.5))
          : null,
      trailing: isOrganizer
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.richGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(AppLocalizations.of(context)!.attendeesOrganizer,
                  style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            )
          : (anon
              ? null
              : const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary, size: 18)),
    );
  }
}
