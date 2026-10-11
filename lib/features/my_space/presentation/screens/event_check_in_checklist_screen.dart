import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/user_display_name.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/screens/event_scanner_screen.dart';
import '../../../experience_bookings/presentation/booking_l10n.dart';
import '../../data/my_space_repository.dart';
import '../widgets/check_in_widgets.dart';
import '../widgets/space_widgets.dart';

/// Organizer's check-in CHECKLIST for one event: every going attendee with a
/// tick, search, All / Not here yet / Checked in filters, a manual check-in
/// toggle (and undo) through the server callable, and "Scan" preset to this
/// event (the existing [EventScannerScreen]).
///
/// Counts are server count()s; the roster is paginated (50 per page).
class EventCheckInChecklistScreen extends StatefulWidget {
  const EventCheckInChecklistScreen({
    super.key,
    required this.event,
    required this.currentUserId,
    required this.repository,
    this.openScanner,
  });

  final Event event;
  final String currentUserId;
  final MySpaceRepository repository;

  /// Test hook; defaults to pushing [EventScannerScreen].
  final Future<void> Function(BuildContext context)? openScanner;

  static Route<void> route({
    required Event event,
    required String currentUserId,
    required MySpaceRepository repository,
  }) =>
      MaterialPageRoute<void>(
        builder: (_) => EventCheckInChecklistScreen(
          event: event,
          currentUserId: currentUserId,
          repository: repository,
        ),
      );

  @override
  State<EventCheckInChecklistScreen> createState() =>
      _EventCheckInChecklistScreenState();
}

class _EventCheckInChecklistScreenState
    extends State<EventCheckInChecklistScreen> {
  static const int _pageSize = 50;

  final _search = TextEditingController();
  final List<EventAttendee> _items = [];
  final Set<String> _busy = {};
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _failed = false;
  EventCheckInStats? _stats;
  String _query = '';
  CheckInFilter _filter = CheckInFilter.all;

  MySpaceRepository get _repo => widget.repository;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    unawaited(_loadStats());
    try {
      final page =
          await _repo.goingAttendees(widget.event.id, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final s = await _repo.eventCheckInStats(widget.event.id);
      if (mounted) setState(() => _stats = s);
    } catch (_) {/* the summary falls back to the loaded rows */}
  }

  Future<void> _more() async {
    if (_loadingMore || !_hasMore || _items.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.goingAttendees(widget.event.id,
          startAfterId: _items.last.id, limit: _pageSize);
      if (!mounted) return;
      final known = _items.map((a) => a.id).toSet();
      setState(() {
        _items.addAll(page.items.where((a) => !known.contains(a.id)));
        _hasMore = page.hasMore;
      });
    } catch (_) {
      // Keep what is shown; the button stays to retry.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _scan() async {
    final open = widget.openScanner;
    if (open != null) {
      await open(context);
    } else {
      await Navigator.of(context).push(EventScannerScreen.route(
          event: widget.event, ownerUserId: widget.currentUserId));
    }
    if (mounted) await _reload();
  }

  Future<void> _toggle(EventAttendee a) async {
    final l = AppLocalizations.of(context)!;
    final name = displayUserName(l, a.userName);
    final next = !a.checkedIn;
    final ok = next
        ? await confirmCheckInChange(context,
            title: l.msCheckInConfirmTitle,
            body: l.msCheckInConfirmBody(name),
            action: l.msCheckIn)
        : await confirmCheckInChange(context,
            title: l.msUndoCheckInTitle,
            body: l.msUndoCheckInBody(name),
            action: l.msUndo,
            color: AppColors.errorRed);
    if (!ok || !mounted) return;

    // Optimistic: flip the tick + counter now, revert on a refusal.
    void apply(bool checked) {
      final i = _items.indexWhere((x) => x.id == a.id);
      if (i >= 0) {
        _items[i] = _items[i].copyWith(
            checkedIn: checked, checkedInAt: checked ? DateTime.now() : null);
      }
      final s = _stats;
      if (s != null) {
        _stats = EventCheckInStats(
          going: s.going,
          checkedIn: (s.checkedIn + (checked ? 1 : -1)).clamp(0, s.going),
        );
      }
    }

    setState(() {
      _busy.add(a.id);
      apply(next);
    });
    final r = await _repo.setEventCheckIn(widget.event.id, a.userId, next);
    if (!mounted) return;
    setState(() {
      _busy.remove(a.id);
      if (!r.approved) apply(!next);
    });
    if (!r.approved) {
      await showUserErrorMessage(context, r.reasonText(l));
      return;
    }
    if (next && r.alreadyCheckedIn) {
      // Someone scanned them meanwhile: the optimistic +1 double-counted.
      unawaited(_loadStats());
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content: Text(next ? l.msCheckedInSnack(name) : l.msCheckInUndoneSnack),
      backgroundColor: next ? AppColors.successGreen : null,
      duration: const Duration(seconds: 2),
    ));
  }

  List<EventAttendee> get _visible {
    final l = AppLocalizations.of(context)!;
    final q = _query.trim().toLowerCase();
    return _items.where((a) {
      if (_filter == CheckInFilter.pending && a.checkedIn) return false;
      if (_filter == CheckInFilter.checkedIn && !a.checkedIn) return false;
      if (q.isEmpty) return true;
      return displayUserName(l, a.userName).toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final e = widget.event;
    final stats = _stats;
    final total = stats?.going ?? _items.length;
    final checked = stats?.checkedIn ?? _items.where((a) => a.checkedIn).length;
    final visible = _loading ? const <EventAttendee>[] : _visible;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(l.msCheckInTitle),
      ),
      body: RefreshIndicator(
        color: AppColors.richGold,
        onRefresh: _reload,
        child: _lazyList([
          Text(e.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(BookingL10n.dateTime(context, e.startDate),
              style:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          const SizedBox(height: 14),
          CheckInSummaryCard(
            checkedIn: checked,
            total: total,
            onScan: _scan,
          ),
          const SizedBox(height: 14),
          CheckInFilterBar(
            controller: _search,
            filter: _filter,
            onFilter: (f) => setState(() => _filter = f),
            onQuery: (q) => setState(() => _query = q),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.richGold)),
            )
          else if (_failed)
            _message(Icons.cloud_off_outlined, l.somethingWentWrong,
                action: TextButton(onPressed: _reload, child: Text(l.retry)))
          else if (_items.isEmpty)
            _message(Icons.groups_outlined, l.msNoGoingAttendees,
                key: const ValueKey('checklist-empty'))
          else if (visible.isEmpty && !_hasMore)
            _message(Icons.search_off, l.msNoMatches)
          else
            for (final a in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _row(l, a),
              ),
          if (!_loading && _hasMore) ...[
            if (_query.trim().isNotEmpty || _filter != CheckInFilter.all)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(l.msSearchLoadedOnly,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12)),
              ),
            Center(
              child: TextButton.icon(
                key: const ValueKey('checklist-more'),
                onPressed: _loadingMore ? null : _more,
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.richGold,
                    minimumSize: const Size(44, 44)),
                icon: _loadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.richGold))
                    : const Icon(Icons.expand_more),
                label: Text(l.msLoadMore),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  /// Lazily built rows (a long roster never builds off-screen rows), each
  /// width-capped for tablets / desktop.
  Widget _lazyList(List<Widget> items) => ListView.builder(
        key: const ValueKey('checklist-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: items.length,
        itemBuilder: (_, i) => SpaceMaxWidth(child: items[i]),
      );

  Widget _row(AppLocalizations l, EventAttendee a) {
    final name = displayUserName(l, a.userName);
    final photo = a.userPhotoUrl;
    return CheckInRow(
      key: ValueKey('row-${a.userId}'),
      toggleKey: ValueKey('check-${a.userId}'),
      name: name,
      checkedIn: a.checkedIn,
      busy: _busy.contains(a.id),
      onToggle: () => _toggle(a),
      detail: a.guestCount > 0 ? l.eventGuestsBringing(a.guestCount) : null,
      who: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.backgroundInput,
          backgroundImage: (photo != null && photo.isNotEmpty)
              ? CachedNetworkImageProvider(photo)
              : null,
          child: (photo == null || photo.isEmpty)
              ? Text(
                  isMissingUserName(a.userName)
                      ? '?'
                      : a.userName.trim()[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700))
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _message(IconData icon, String text, {Widget? action, Key? key}) =>
      Padding(
        key: key,
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(children: [
          Icon(icon, size: 44, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
          if (action != null) action,
        ]),
      );
}
