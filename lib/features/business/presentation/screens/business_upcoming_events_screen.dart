import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';
import '../../../events/presentation/screens/event_detail_loader_screen.dart';
import '../../data/business_upcoming_events.dart';
import '../widgets/storefront_event_tile.dart';

/// "See all" from a storefront's Upcoming events: EVERY upcoming event of the
/// business, soonest first, endless scroll in pages of
/// [BusinessUpcomingEventsRepository.pageSize] (bounded reads on the existing
/// events(organizerId, startDate) index).
class BusinessUpcomingEventsScreen extends StatefulWidget {
  const BusinessUpcomingEventsScreen({
    required this.businessId,
    required this.businessName,
    required this.currentUserId,
    this.repository,
    this.onOpenEvent,
    super.key,
  });

  final String businessId;
  final String businessName;
  final String currentUserId;
  final BusinessUpcomingEventsRepository? repository;

  /// Test hook; defaults to opening the event detail.
  final void Function(BuildContext context, String eventId)? onOpenEvent;

  @override
  State<BusinessUpcomingEventsScreen> createState() =>
      _BusinessUpcomingEventsScreenState();
}

class _BusinessUpcomingEventsScreenState
    extends State<BusinessUpcomingEventsScreen> {
  late final BusinessUpcomingEventsRepository _repo =
      widget.repository ?? BusinessUpcomingEventsRepository();
  final ScrollController _scroll = ScrollController();
  final List<StorefrontEvent> _events = [];
  final Set<String> _seen = {};
  UpcomingEventsPage? _last;
  bool _loading = false;
  bool _error = false;

  bool get _hasMore => _last == null || _last!.hasMore;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) _loadMore();
    });
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      // A page can come back empty after client filtering (drafts, hidden,
      // ended); keep going (bounded) so the list never stalls.
      var guard = 0;
      UpcomingEventsPage page;
      do {
        page = await _repo.page(widget.businessId, cursor: _last?.cursor);
        _last = page;
        for (final e in page.events) {
          if (_seen.add(e.id)) _events.add(e);
        }
      } while (page.events.isEmpty && page.hasMore && ++guard < 3);
      _events.sort(compareByStart);
    } catch (_) {
      _error = true;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    // The loaded rows may not fill the screen (no scroll to trigger the next
    // page): keep loading while the end is in view.
    if (!_error && _hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _scroll.hasClients &&
            _scroll.position.extentAfter < 600) {
          _loadMore();
        }
      });
    }
  }

  void _open(String id) {
    final hook = widget.onOpenEvent;
    if (hook != null) return hook(context, id);
    Navigator.of(context).push(EventDetailLoaderScreen.route(
        eventId: id, currentUserId: widget.currentUserId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.businessUpcomingEvents),
            if (widget.businessName.isNotEmpty)
              Text(widget.businessName,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
      body: Builder(builder: (context) {
        if (_events.isEmpty && _loading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.richGold));
        }
        if (_events.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Text(
                _error ? l10n.storefrontEventsLoadError : l10n.businessNoUpcomingEvents,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textTertiary),
              ),
            ),
          );
        }
        return ListView.builder(
          key: const ValueKey('storefront-all-events-list'),
          controller: _scroll,
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          itemCount: _events.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= _events.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.richGold),
                  ),
                ),
              );
            }
            final e = _events[i];
            return StorefrontEventTile(event: e, onTap: () => _open(e.id));
          },
        );
      }),
    );
  }
}
