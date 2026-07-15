import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/platform/web_media.dart';
import '../../../../core/services/user_directory_service.dart';
import '../../../../core/services/content_filter_service.dart';
import '../../../../core/services/location_share_service.dart';
import '../../../../core/services/photo_validation_service.dart';
import '../../../../core/services/tier_gate.dart';
import '../../../../core/services/tier_limits_service.dart';
import '../../../app_tour/presentation/tour_controller.dart';
import '../../../app_tour/presentation/tour_keys.dart';
import '../../../app_tour/presentation/widgets/gesture_glyphs.dart';
import '../../../app_tour/presentation/widgets/tour_showcase.dart';
import '../../../app_tour/presentation/widgets/tour_trigger.dart';
import '../widgets/experiences_tab.dart';
import '../widgets/event_like_button.dart';
import '../../../business/data/services/leads_service.dart';
import '../../../communities/domain/entities/community.dart';
import '../../../communities/domain/repositories/communities_repository.dart';
import '../../../coins/domain/usecases/purchase_feature.dart';
import '../../../coins/presentation/bloc/coin_bloc.dart';
import '../../../coins/presentation/bloc/coin_event.dart';
import '../../../coins/presentation/screens/coin_shop_screen.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/domain/entities/location.dart' as profile_entity;
import 'event_location_picker_screen.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/datasources/events_remote_datasource.dart';
import '../../data/repositories/events_repository_impl.dart';
import '../../data/services/event_series_service.dart';
import '../../data/services/events_cache_service.dart';
import '../../domain/entities/event.dart';
import '../../../safety/presentation/widgets/event_safety_checkin.dart';
import '../bloc/events_bloc.dart';
import '../bloc/events_event.dart';
import '../bloc/events_state.dart';
import '../widgets/share_event_sheet.dart';
import 'event_attendance_screen.dart';
import 'event_chat_screen.dart';
import 'event_scanner_screen.dart';
import 'event_ticket_screen.dart';

/// Coin cost for an organizer to feature ("Feature this event") their event in
/// the Explore featured carousel for 7 days. Pure revenue, zero run-cost.
const int kFeatureEventCost = 100; // adjustable

/// Coin cost to create an EXTRA event beyond the free per-tier allowance
/// ([TierEntitlements.maxEvents]). Base 1 / Silver 3 / Gold 5 free ongoing
/// events; Platinum is unlimited (never charged). Each additional ongoing
/// event costs this many coins.
const int kExtraEventCost = 50; // adjustable

/// Events Screen - Discover local events and activities
///
/// Category chips for filtering.
/// Wired to EventsBloc for all data operations.

/// Time bucket for the "My Events" tab (past / on-going now / upcoming).
enum _MyEventsFilter { ongoing, upcoming, past }

class EventsScreen extends StatefulWidget {

  const EventsScreen({
    required this.currentUserId, super.key,
  });
  final String currentUserId;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EventsBloc _eventsBloc;
  EventCategory? _selectedCategory;
  String _searchQuery = '';
  bool _gridView = true; // default to grid view (web + mobile)

  /// Grid columns: more on wide/web screens, 3 on phones.
  int _gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1100) return 6;
    if (w >= 800) return 4;
    return 3;
  }
  double? _userLat;
  double? _userLng;
  String _extSort = 'distance'; // distance | rating | reviews | date
  // Native tabs (Upcoming/Community/My Events): order by DATE (earliest first)
  // by default; the user can still switch to distance/popular from the menu.
  String _nativeSort = 'date'; // distance | date | popular

  // Date-range filter for native event lists (Community / My Events).
  // Null = no bound. Inclusive window [_dateFrom 00:00 .. _dateTo 23:59:59].
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool get _hasDateFilter => _dateFrom != null || _dateTo != null;

  // My Events time bucket (the old "Going" tab is merged into My Events).
  _MyEventsFilter _myEventsFilter = _MyEventsFilter.upcoming;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Create the BLoC with repository and datasource
    final dataSource = EventsRemoteDataSourceImpl();
    _eventsDataSource = dataSource; // reused for whole-table community search
    final repository = EventsRepositoryImpl(remoteDataSource: dataSource);
    _eventsBloc = EventsBloc(repository: repository);

    // Load initial events
    _eventsBloc.add(const LoadEvents(upcoming: true));
    _eventsBloc.add(LoadUserEvents(userId: widget.currentUserId));

    // Cache-first community feed: render today's cached feed immediately (if
    // present) so the tab loads offline/instantly and skips the network. Only a
    // stale/absent cache — or a pull-to-refresh — triggers a Firestore query.
    _loadCommunityCache();

    // Rebuild on tab change so the category bar shows/hides per tab.
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {});
      // Refresh "My Events" (now includes Going) when opened.
      if (_tabController.index == 4) {
        _eventsBloc.add(LoadUserEvents(userId: widget.currentUserId));
      }
    });

    // Best-effort user location for distance-based ordering of all events.
    _loadUserLocation();
  }

  // External tabs (Live Events / Attractions / Experiences) have no GreenGo
  // category tags — hide the category bar there. Native tabs: Community (0),
  // My Events (4, which now also includes Going).
  bool get _isNativeTab =>
      _tabController.index == 0 || _tabController.index == 4;

  // Attractions tab (Geoapify) supports a category filter (museum/park/etc).
  bool get _isAttractionsTab => _tabController.index == 2;
  // Experiences tab (Viator) — also supports a category filter.
  bool get _isExperiencesTab => _tabController.index == 3;
  // Selected categories (null = all).
  String? _attractionCategory;
  String? _experienceCategory;

  // Whole-table community search (Community tab): default shows the 100 closest;
  // a search queries the entire events table and shows matches.
  late final EventsRemoteDataSourceImpl _eventsDataSource;
  static const int _communityNearbyLimit = 100;
  List<Event> _communityResults = const [];
  bool _communitySearching = false;
  int _communitySearchGen = 0;
  // Default community list: the closest 100 via geohash (scales to a big table).
  List<Event> _communityNearby = const [];
  bool _communityNearbyLoading = false;

  // Daily cache for the community feed. Within the same calendar day the feed is
  // served from local storage and the network is NOT hit; only a pull-to-refresh
  // (or a stale/absent cache) forces a fresh Firestore query.
  final EventsCacheService _eventsCache = const EventsCacheService();
  String get _communityFeedKey => 'community_${widget.currentUserId}';
  bool _communityCacheFresh = false; // true once today's cache is loaded/saved

  /// Cache-first community feed: on open, render today's cached feed (if any)
  /// WITHOUT any network fetch. A stale/absent cache leaves this a no-op and the
  /// normal location-driven load populates (and persists) the feed instead.
  Future<void> _loadCommunityCache() async {
    final cached = await _eventsCache.getCachedIfFresh(_communityFeedKey);
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() {
        _communityNearby = cached;
        _communityCacheFresh = true;
      });
    }
  }

  Future<void> _loadCommunityNearby({bool force = false}) async {
    if (_userLat == null || _userLng == null) return;
    // Same-day cache hit: the cache was already rendered, so skip the network
    // unless the user explicitly pulled to refresh (force == true).
    if (!force && _communityCacheFresh) return;
    setState(() => _communityNearbyLoading = true);
    try {
      final list = await _eventsDataSource.getNearbyCommunityEvents(
          lat: _userLat!, lng: _userLng!, limit: _communityNearbyLimit);
      if (!mounted) return;
      setState(() {
        _communityNearby = list;
        _communityNearbyLoading = false;
        _communityCacheFresh = true;
      });
      // Persist the freshly fetched feed + today's day stamp so the rest of the
      // day serves from cache.
      unawaited(_eventsCache.save(_communityFeedKey, list));
    } catch (_) {
      if (mounted) setState(() => _communityNearbyLoading = false);
    }
  }

  void _runCommunitySearch(String query) {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _communityResults = const [];
        _communitySearching = false;
      });
      return;
    }
    final gen = ++_communitySearchGen;
    setState(() => _communitySearching = true);
    _eventsDataSource.searchEvents(q).then((results) {
      if (!mounted || gen != _communitySearchGen) return;
      setState(() {
        _communityResults = results;
        _communitySearching = false;
      });
    }).catchError((_) {
      if (!mounted || gen != _communitySearchGen) return;
      setState(() => _communitySearching = false);
    });
  }

  Future<void> _loadUserLocation() async {
    final pos = await const LocationShareService().getCurrentPosition();
    if (pos != null && mounted) {
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      });
      _loadCommunityNearby(); // closest-100 community via geohash
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider.value(
      value: _eventsBloc,
      child: ShowCaseWidget(
        builder: (showcaseContext) => TourTrigger(
          // First-time Events tour: create button, search field, and the tabs.
          onVisible: (tourContext) =>
              TourController.instance.maybeStartMiniTour(
            tourContext,
            tourId: TourController.eventsTourId,
            userId: widget.currentUserId,
            keys: [
              TourKeys.eventsCreate,
              TourKeys.eventsSearch,
              TourKeys.eventsTabs,
            ],
          ),
          child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          title: Text(
            AppLocalizations.of(context)!.eventsAndPlacesTitle,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            TourShowcase(
              showcaseKey: TourKeys.eventsCreate,
              title: l10n.tourEventsCreateTitle,
              description: l10n.tourEventsCreateDesc,
              gesture: TourGesture.tap,
              targetShapeBorder: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.add, color: AppColors.richGold),
                onPressed: () => _showCreateEventDialog(context),
              ),
            ),
            // Date filter only applies to native tabs (Community / My Events) —
            // Attractions & Experiences have no date filter.
            if (_isNativeTab)
              IconButton(
                icon: Icon(
                  _hasDateFilter
                      ? Icons.filter_list
                      : Icons.filter_list_outlined,
                  color: _hasDateFilter
                      ? AppColors.richGold
                      : AppColors.textPrimary,
                ),
                onPressed: () => _showFilterDialog(context),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kTextTabBarHeight),
            child: TourShowcase(
              showcaseKey: TourKeys.eventsTabs,
              title: l10n.tourEventsTabsTitle,
              description: l10n.tourEventsTabsDesc,
              gesture: TourGesture.tap,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.richGold,
                labelColor: AppColors.richGold,
                unselectedLabelColor: AppColors.textSecondary,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.eventsTabCommunity),
                  Tab(text: AppLocalizations.of(context)!.eventsTabLiveEvents),
                  Tab(text: AppLocalizations.of(context)!.eventsTabAttractions),
                  Tab(text: AppLocalizations.of(context)!.eventsTabExperiences),
                  Tab(text: AppLocalizations.of(context)!.eventsTabMyEvents),
                ],
              ),
            ),
          ),
        ),
        body: BlocConsumer<EventsBloc, EventsState>(
          listener: (context, state) {
            if (state is EventCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.eventsCreatedSuccessfully),
                  backgroundColor: AppColors.successGreen,
                ),
              );
              // Reload events
              _eventsBloc.add(const LoadEvents(upcoming: true));
              _eventsBloc.add(LoadUserEvents(userId: widget.currentUserId));
            } else if (state is EventRsvpSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.status == 'cancelled'
                        ? AppLocalizations.of(context)!.eventsRsvpCancelled
                        : AppLocalizations.of(context)!.eventsRsvpUpdated,
                  ),
                  backgroundColor: AppColors.successGreen,
                ),
              );
              // Reload events to reflect changes
              _eventsBloc.add(const LoadEvents(upcoming: true));
              _eventsBloc.add(LoadUserEvents(userId: widget.currentUserId));
            } else if (state is EventDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.eventsDeleted),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            } else if (state is EventsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Search by country/city/name + popularity sort
                _buildSearchAndSortBar(),
                // Category filter — native tabs use GreenGo categories; the
                // Attractions tab uses the Geoapify place categories.
                if (_isNativeTab) _buildCategoryFilter(state),
                if (_isAttractionsTab) _buildAttractionCategoryFilter(),
                if (_isExperiencesTab) _buildExperienceCategoryFilter(),
                // Events List
                Expanded(
                  child: _buildBody(state),
                ),
              ],
            );
          },
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildBody(EventsState state) {
    if (state is EventsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      );
    }

    if (state is EventsLoaded) {
      return TabBarView(
        controller: _tabController,
        children: [
          _buildCommunityTab(state),
          _buildExperiencesTab('ticketmaster', sortOverride: 'date'),
          _buildExperiencesTab('geoapify', category: _attractionCategory),
          _buildExperiencesTab('viator', category: _experienceCategory),
          _buildMyEventsTab(state),
        ],
      );
    }

    // Default: show empty state for initial/error/other states
    return TabBarView(
      controller: _tabController,
      children: [
        _buildEventsList([]),
        _buildExperiencesTab('ticketmaster', sortOverride: 'date'),
        _buildExperiencesTab('geoapify'),
        _buildExperiencesTab('viator'),
        _buildEventsList([]),
      ],
    );
  }

  /// Search bar (country / city / name) + popularity sort toggle.
  Widget _buildSearchAndSortBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: TourShowcase(
              showcaseKey: TourKeys.eventsSearch,
              title: AppLocalizations.of(context)!.tourEventsSearchTitle,
              description: AppLocalizations.of(context)!.tourEventsSearchDesc,
              gesture: TourGesture.tap,
              child: TextField(
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (v) {
                  setState(() => _searchQuery = v.trim());
                  // Community tab searches the whole events table.
                  if (_tabController.index == 0) _runCommunitySearch(v.trim());
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: AppLocalizations.of(context)!.eventsSearchHint,
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.backgroundCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Both native and external tabs: a sort menu defaulting to Distance.
          // Native events have no stars/reviews, so they offer Distance/Date/
          // Popular; external offer Distance/Stars/Reviews/Date.
          if (_isNativeTab)
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort, color: AppColors.richGold),
              tooltip: AppLocalizations.of(context)!.eventsSortBy,
              color: AppColors.backgroundCard,
              initialValue: _nativeSort,
              onSelected: (v) => setState(() => _nativeSort = v),
              itemBuilder: (ctx) => [
                _sortItem('distance',
                    AppLocalizations.of(ctx)!.eventsSortDistance, Icons.near_me,
                    current: _nativeSort),
                _sortItem('date', AppLocalizations.of(ctx)!.eventsSortDate,
                    Icons.event,
                    current: _nativeSort),
                _sortItem(
                    'popular',
                    AppLocalizations.of(ctx)!.eventsSortPopular,
                    Icons.local_fire_department,
                    current: _nativeSort),
              ],
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort, color: AppColors.richGold),
              tooltip: AppLocalizations.of(context)!.eventsSortBy,
              color: AppColors.backgroundCard,
              initialValue: _extSort,
              onSelected: (v) => setState(() => _extSort = v),
              itemBuilder: (ctx) => [
                _sortItem('distance',
                    AppLocalizations.of(ctx)!.eventsSortDistance, Icons.near_me),
                _sortItem('rating',
                    AppLocalizations.of(ctx)!.eventsSortStars, Icons.star),
                _sortItem('reviews',
                    AppLocalizations.of(ctx)!.eventsSortReviews, Icons.reviews),
                _sortItem('date',
                    AppLocalizations.of(ctx)!.eventsSortDate, Icons.event),
              ],
            ),
          const SizedBox(width: 4),
          // List / grid view toggle
          IconButton(
            tooltip: _gridView
                ? AppLocalizations.of(context)!.eventsViewList
                : AppLocalizations.of(context)!.eventsViewGrid,
            icon: Icon(
              _gridView ? Icons.view_list : Icons.grid_view,
              color: AppColors.richGold,
            ),
            onPressed: () => setState(() => _gridView = !_gridView),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _sortItem(String value, String label, IconData icon,
      {String? current}) {
    final selected = (current ?? _extSort) == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: selected ? AppColors.richGold : AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: selected ? AppColors.richGold : AppColors.textPrimary)),
        ],
      ),
    );
  }

  /// Apply the free-text search (country/city/name) and optional popularity sort.
  List<Event> _applySearchAndSort(List<Event> events) {
    var result = events;
    final q = _searchQuery.toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((e) {
        return e.title.toLowerCase().contains(q) ||
            (e.city ?? '').toLowerCase().contains(q) ||
            e.locationName.toLowerCase().contains(q) ||
            (e.address ?? '').toLowerCase().contains(q) ||
            e.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }
    // Date-range filter (inclusive): keep events that OVERLAP the window —
    // i.e. they end on/after _dateFrom and start on/before _dateTo.
    if (_hasDateFilter) {
      final from = _dateFrom;
      final to = _dateTo;
      result = result.where((e) {
        if (from != null && e.endDate.isBefore(from)) return false;
        if (to != null && e.startDate.isAfter(to)) return false;
        return true;
      }).toList();
    }
    // Apply the selected order (distance by default).
    result = _applyNativeSort(result);
    // Featured/boosted events surface first, preserving relative order.
    final featured = result.where((e) => e.isCurrentlyFeatured).toList();
    final rest = result.where((e) => !e.isCurrentlyFeatured).toList();
    return [...featured, ...rest];
  }

  /// Order native events by the chosen mode: distance (default) / date /
  /// popular. Distance falls back to date when the user's location is unknown.
  List<Event> _applyNativeSort(List<Event> events) {
    final list = [...events];
    switch (_nativeSort) {
      case 'date':
        list.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
      case 'popular':
        // Most popular = most likes (tie-break by attendees).
        list.sort((a, b) {
          final byLikes = b.likeCount.compareTo(a.likeCount);
          return byLikes != 0
              ? byLikes
              : b.attendeeCount.compareTo(a.attendeeCount);
        });
        break;
      case 'distance':
      default:
        if (_userLat != null && _userLng != null) {
          list.sort(
              (a, b) => _distanceToEvent(a).compareTo(_distanceToEvent(b)));
        } else {
          list.sort((a, b) => a.startDate.compareTo(b.startDate));
        }
    }
    return list;
  }

  double _distanceToEvent(Event e) {
    if (_userLat == null || _userLng == null) return double.infinity;
    final lat = e.latitude, lng = e.longitude;
    if (lat == null || lng == null) return double.infinity;
    const r = 6371.0;
    final dLat = (lat - _userLat!) * math.pi / 180;
    final dLng = (lng - _userLng!) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_userLat! * math.pi / 180) *
            math.cos(lat * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }


  Widget _buildCategoryFilter(EventsState state) {
    // Only show category chips that actually have at least one event across the
    // user's native events (so empty tags are omitted).
    final present = <EventCategory>{};
    if (state is EventsLoaded) {
      for (final e in [...state.upcomingEvents, ...state.userEvents]) {
        present.add(e.category);
      }
    }
    if (present.isEmpty) return const SizedBox.shrink();
    final cats = EventCategory.values.where(present.contains).toList();
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _buildCategoryChip(null, 'All'),
          ...cats.map((category) {
            return _buildCategoryChip(category, _getCategoryName(category));
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(EventCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
          _eventsBloc.add(FilterByCategory(category: _selectedCategory));
        },
        backgroundColor: AppColors.backgroundCard,
        selectedColor: AppColors.richGold.withOpacity(0.3),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.richGold : AppColors.textPrimary,
        ),
        checkmarkColor: AppColors.richGold,
      ),
    );
  }

  String _getCategoryName(EventCategory category) {
    switch (category) {
      case EventCategory.dating:
        return 'Dating';
      case EventCategory.social:
        return 'Social';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.food:
        return 'Food & Drink';
      case EventCategory.nightlife:
        return 'Nightlife';
      case EventCategory.outdoor:
        return 'Outdoor';
      case EventCategory.arts:
        return 'Arts';
      case EventCategory.gaming:
        return 'Gaming';
      case EventCategory.travel:
        return 'Travel';
      case EventCategory.wellness:
        return 'Wellness';
      case EventCategory.languageExchange:
        return 'Language';
      case EventCategory.other:
        return 'Other';
    }
  }

  /// Community: all GreenGo user-created events. Order applied centrally
  /// (distance by default; user can switch to date / popular).
  ///
  /// Auto-publish gate: this and every other discovery feed that surfaces these
  /// events applies the `e.isLive` gate so drafts / not-yet-due scheduled events
  /// never leak into discovery (see Event.isLive). Sibling feeds now guarded:
  /// explore_screen (community-events feed) and globe_screen (country-events +
  /// viewport community layer), on top of the datasource-level filtering.
  List<Event> _getCommunityEvents(EventsLoaded state) {
    // Auto-publish gate: only live events (published, or scheduled & due) are
    // discoverable. The datasource already filters, but guard client-side too.
    final list = state.upcomingEvents.where((e) => e.isLive).toList();
    if (_userLat != null && _userLng != null) {
      list.sort((a, b) => _distanceToEvent(a).compareTo(_distanceToEvent(b)));
    }
    // Default view: only the closest 100 (search queries the whole table).
    return list.take(_communityNearbyLimit).toList();
  }

  /// Community tab body: default = closest 100; while searching, results come
  /// from a whole-table query (searchEvents), refined + sorted client-side.
  Widget _buildCommunityTab(EventsLoaded state) {
    if (_searchQuery.isNotEmpty) {
      if (_communitySearching && _communityResults.isEmpty) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.richGold));
      }
      // Auto-publish gate on search results too (drafts/scheduled never listed).
      return _buildEventsList(_applySearchAndSort(
          _communityResults.where((e) => e.isLive).toList()));
    }
    if (_communityNearbyLoading && _communityNearby.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.richGold));
    }
    // Prefer the geohash nearest-100; fall back to the bloc's loaded set when
    // location is unknown or the nearby query returned nothing.
    final list = _communityNearby.isNotEmpty
        ? _communityNearby.where((e) => e.isLive).toList()
        : _getCommunityEvents(state);
    return _buildEventsList(_applySearchAndSort(list));
  }

  /// My Events = events the user ORGANIZES **plus** events they've RSVP'd
  /// "going" to (the former "Going" tab is merged here), de-duplicated by id.
  List<Event> _getMyEvents(EventsLoaded state) {
    final byId = <String, Event>{};
    for (final e in state.userEvents) {
      final organizes = e.organizerId == widget.currentUserId;
      final going = e.attendees.any((a) =>
          a.userId == widget.currentUserId && a.status == RSVPStatus.going);
      if (organizes || going) byId[e.id] = e;
    }
    if (byId.isEmpty) {
      // Fallback: derive from all loaded events.
      for (final e in state.filteredEvents) {
        if (e.organizerId == widget.currentUserId ||
            e.attendees.any((a) => a.userId == widget.currentUserId)) {
          byId[e.id] = e;
        }
      }
    }
    var list = byId.values.toList();
    if (_selectedCategory != null) {
      list = list.where((e) => e.category == _selectedCategory).toList();
    }
    return list;
  }

  /// Narrow My Events by time bucket: Past (ended) / Soon (today/ongoing) /
  /// Upcoming (tomorrow on). Calendar/time-aware and consistent with the
  /// business "Manage my events" screen.
  List<Event> _applyMyEventsTimeFilter(List<Event> events) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));
    switch (_myEventsFilter) {
      case _MyEventsFilter.ongoing: // "Soon" = events happening TODAY
        return events
            .where((e) =>
                !e.startDate.isBefore(startOfToday) &&
                e.startDate.isBefore(endOfToday))
            .toList();
      case _MyEventsFilter.upcoming: // starts tomorrow or later
        return events.where((e) => !e.startDate.isBefore(endOfToday)).toList();
      case _MyEventsFilter.past: // the event's day has passed
        return events.where((e) => e.startDate.isBefore(startOfToday)).toList();
    }
  }

  /// The My Events tab: a past / on-going / upcoming segmented filter above the
  /// searchable, date-filterable events list.
  Widget _buildMyEventsTab(EventsLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _applyMyEventsTimeFilter(_getMyEvents(state));
    Widget seg(_MyEventsFilter f, String label) {
      final selected = _myEventsFilter == f;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: SizedBox(
              width: double.infinity,
              child: Text(label, textAlign: TextAlign.center),
            ),
            selected: selected,
            onSelected: (_) => setState(() => _myEventsFilter = f),
            backgroundColor: AppColors.backgroundCard,
            selectedColor: AppColors.richGold,
            labelStyle: TextStyle(
              color: selected ? AppColors.deepBlack : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: selected ? AppColors.richGold : AppColors.divider,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            children: [
              seg(_MyEventsFilter.ongoing, l10n.eventsFilterSoon),
              seg(_MyEventsFilter.upcoming, l10n.eventsFilterUpcoming),
              seg(_MyEventsFilter.past, l10n.eventsFilterPast),
            ],
          ),
        ),
        Expanded(child: _buildEventsList(_applySearchAndSort(filtered))),
      ],
    );
  }

  Widget _buildEventsList(List<Event> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.eventsNoEventsFound,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.eventsCheckBackLater,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateEventDialog(context),
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.eventsCreateEvent),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.richGold,
      onRefresh: () async {
        _eventsBloc.add(const LoadEvents(upcoming: true));
        _eventsBloc.add(LoadUserEvents(userId: widget.currentUserId));
        // Pull-to-refresh ALWAYS forces a network fetch of the community feed
        // and re-writes the daily cache (bypassing the same-day cache hit).
        await _loadCommunityNearby(force: true);
        // Wait briefly for the BLoC to process
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: _gridView
          ? GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridColumns(context),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.7,
              ),
              itemCount: events.length,
              itemBuilder: (context, index) =>
                  _buildEventGridTile(events[index]),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: events.length,
              itemBuilder: (context, index) {
                return EventCard(
                  event: events[index],
                  currentUserId: widget.currentUserId,
                  onTap: () => _showEventDetails(events[index]),
                  onRSVP: (status) => _handleRSVP(events[index], status),
                );
              },
            ),
    );
  }

  /// Compact tile for the 3-column grid view.
  Widget _buildEventGridTile(Event event) {
    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: AppColors.backgroundCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                    ? Image.network(event.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: AppColors.backgroundInput,
                            child: const Icon(Icons.event,
                                color: AppColors.textTertiary)))
                    : Container(
                        color: AppColors.backgroundInput,
                        child: const Icon(Icons.event,
                            color: AppColors.textTertiary)),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    buildEventStatusBadges(context, event, compact: true),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.event,
                            size: 10, color: AppColors.richGold),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            DateFormat('MMM d, h:mm a').format(event.startDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.richGold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.people,
                            size: 11, color: AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Text(
                          '${event.goingCount}',
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 10),
                        ),
                        const Spacer(),
                        EventLikeButton(
                          eventId: event.id,
                          userId: widget.currentUserId,
                          likeCount: event.likeCount,
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- External tabs (Live Events / Attractions / Experiences) — infinite scroll ----
  Widget _buildExperiencesTab(String source,
      {String? category, String? sortOverride}) {
    return ExperiencesTab(
      key: ValueKey('exp_$source'),
      source: source,
      gridView: _gridView,
      query: _searchQuery,
      popular: false,
      // Live Events (ticketmaster) are forced to date order (closest first);
      // other external tabs use the user-selected sort.
      sort: sortOverride ?? _extSort,
      category: category,
      userLat: _userLat,
      userLng: _userLng,
      currentUserId: widget.currentUserId,
    );
  }

  /// Category chips for the Attractions (Geoapify) tab.
  Widget _buildAttractionCategoryFilter() {
    final l10n = AppLocalizations.of(context)!;
    final cats = <String, String>{
      'museum': l10n.catMuseums,
      'attraction': l10n.catSights,
      'park': l10n.catParks,
      'national_park': l10n.catNationalParks,
      'theme_park': l10n.catThemeParks,
    };
    Widget chip(String? value, String label) {
      final selected = _attractionCategory == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          backgroundColor: AppColors.backgroundCard,
          selectedColor: AppColors.richGold,
          labelStyle: TextStyle(
              color: selected ? AppColors.deepBlack : AppColors.textPrimary),
          onSelected: (_) => setState(() => _attractionCategory = value),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          chip(null, l10n.eventsCategoryAll),
          ...cats.entries.map((e) => chip(e.key, e.value)),
        ],
      ),
    );
  }

  /// Category chips for the Experiences (Viator) tab.
  Widget _buildExperienceCategoryFilter() {
    final l10n = AppLocalizations.of(context)!;
    final cats = <String, String>{
      'city_tours': l10n.catTours,
      'culture': l10n.catCulture,
      'food_drink': l10n.catFoodDrink,
      'cruises': l10n.catCruises,
      'nature': l10n.catNature,
      'day_trips': l10n.catDayTrips,
      'tickets': l10n.catTickets,
      'other': l10n.catOther,
    };
    Widget chip(String? value, String label) {
      final selected = _experienceCategory == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          backgroundColor: AppColors.backgroundCard,
          selectedColor: AppColors.richGold,
          labelStyle: TextStyle(
              color: selected ? AppColors.deepBlack : AppColors.textPrimary),
          onSelected: (_) => setState(() => _experienceCategory = value),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          chip(null, l10n.eventsCategoryAll),
          ...cats.entries.map((e) => chip(e.key, e.value)),
        ],
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(
          currentUserId: widget.currentUserId,
          onEventCreated: (event) {
            _eventsBloc.add(CreateEvent(event: event));
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    final l10n = AppLocalizations.of(context)!;
    // Local working copy; committed to state only on "Apply".
    DateTime? from = _dateFrom;
    DateTime? to = _dateTo;
    final df = DateFormat.yMMMd();

    DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
    DateTime endOfDay(DateTime d) =>
        DateTime(d.year, d.month, d.day, 23, 59, 59);

    return StatefulBuilder(
      builder: (context, setSheet) {
        String rangeLabel() {
          if (from == null && to == null) return l10n.eventsDateAnyTime;
          if (from != null && to != null) {
            return '${df.format(from!)} – ${df.format(to!)}';
          }
          if (from != null) return '${l10n.eventsDateFrom} ${df.format(from!)}';
          return '${l10n.eventsDateUntil} ${df.format(to!)}';
        }

        // Is [from,to] exactly the given whole-day window? (drives chip highlight)
        bool matches(DateTime a, DateTime b) =>
            from != null &&
            to != null &&
            from!.isAtSameMomentAs(a) &&
            to!.isAtSameMomentAs(b);

        final now = DateTime.now();
        final todayStart = startOfDay(now);
        final todayEnd = endOfDay(now);
        final weekEnd = endOfDay(now.add(const Duration(days: 6)));
        final monthEnd = endOfDay(DateTime(now.year, now.month + 1, 0));

        Widget quick(String label, DateTime a, DateTime b) {
          final selected = matches(a, b);
          return Expanded(
            child: OutlinedButton(
              onPressed: () => setSheet(() {
                from = a;
                to = b;
              }),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    selected ? AppColors.deepBlack : AppColors.textPrimary,
                backgroundColor:
                    selected ? AppColors.richGold : Colors.transparent,
                side: BorderSide(
                  color: selected ? AppColors.richGold : AppColors.textTertiary,
                ),
              ),
              child: Text(label, textAlign: TextAlign.center),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.eventsFilterEvents,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (from != null || to != null)
                    TextButton(
                      onPressed: () => setSheet(() {
                        from = null;
                        to = null;
                      }),
                      child: Text(
                        l10n.eventsDateAnyTime,
                        style: const TextStyle(color: AppColors.richGold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.eventsDateRange,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              // Currently-selected window, human readable.
              Row(
                children: [
                  const Icon(Icons.event, color: AppColors.richGold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rangeLabel(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  quick(l10n.eventsToday, todayStart, todayEnd),
                  const SizedBox(width: 8),
                  quick(l10n.eventsThisWeekFilter, todayStart, weekEnd),
                  const SizedBox(width: 8),
                  quick(l10n.eventsThisMonth, todayStart, monthEnd),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 2),
                      initialDateRange: (from != null && to != null)
                          ? DateTimeRange(start: from!, end: to!)
                          : null,
                    );
                    if (picked != null) {
                      setSheet(() {
                        from = startOfDay(picked.start);
                        to = endOfDay(picked.end);
                      });
                    }
                  },
                  icon: const Icon(Icons.date_range, size: 18),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.richGold,
                    side: const BorderSide(color: AppColors.richGold),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  label: Text(l10n.eventsCustomRange),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _dateFrom = from;
                      _dateTo = to;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                  ),
                  child: Text(l10n.eventsApplyFilters),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEventDetails(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _eventsBloc,
          child: EventDetailsScreen(
            event: event,
            currentUserId: widget.currentUserId,
          ),
        ),
      ),
    );
  }

  void _handleRSVP(Event event, RSVPStatus status) {
    _eventsBloc.add(RsvpEvent(
      eventId: event.id,
      userId: widget.currentUserId,
      status: status.name,
    ));
    // Business lead capture: a positive RSVP (going / interested) to a
    // business-organized event becomes a saved-event lead. Ignored for
    // non-business organizers and self-RSVPs by the service.
    if (status == RSVPStatus.going || status == RSVPStatus.interested) {
      _logSavedEventLead(event, widget.currentUserId);
    }
  }
}

/// Fire-and-forget business lead capture for a saved / RSVP'd event. When the
/// event's organizer is a business account, [LeadsService] records the RSVP as
/// a saved-event lead in their CRM; self-RSVPs and non-business organizers are
/// cheaply ignored by the service. Never throws and never blocks the RSVP flow.
void _logSavedEventLead(Event event, String uid) {
  unawaited(
    sl<LeadsService>()
        .logSavedEventLead(
          businessId: event.organizerId,
          uid: uid,
          eventId: event.id,
        )
        .catchError((Object _) {}),
  );
}

/// Small status/recurrence badges shown on cards & tiles: Draft / Scheduled /
/// Recurring. Only the organizer ever sees draft & scheduled events, so these
/// double as "not yet public" markers.
Widget buildEventStatusBadges(BuildContext context, Event event,
    {bool compact = false}) {
  final l10n = AppLocalizations.of(context)!;
  final badges = <Widget>[];

  Widget pill(String text, Color color, IconData icon) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 5 : 8, vertical: compact ? 2 : 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 9 : 12, color: color),
            SizedBox(width: compact ? 2 : 4),
            Text(text,
                style: TextStyle(
                    color: color,
                    fontSize: compact ? 8 : 10,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  if (event.status == EventStatus.draft) {
    badges.add(pill(l10n.eventsStatusDraft, AppColors.textTertiary,
        Icons.edit_note));
  } else if (event.isPendingSchedule) {
    // Only while still pending; once publishAt passes it auto-publishes (isLive).
    final at = event.publishAt;
    final label = at != null
        ? l10n.eventsScheduledForDate(DateFormat('MMM d, h:mm a').format(at))
        : l10n.eventsStatusScheduled;
    badges.add(pill(label, AppColors.infoBlue, Icons.schedule));
  } else if (event.status == EventStatus.cancelled) {
    badges.add(pill(l10n.eventsStatusCancelled, AppColors.errorRed,
        Icons.cancel_outlined));
  }

  if (event.isRecurring) {
    badges.add(
        pill(l10n.eventsRecurringLabel, AppColors.richGold, Icons.repeat));
  }

  if (badges.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: EdgeInsets.only(top: compact ? 3 : 6),
    child: Wrap(spacing: 4, runSpacing: 4, children: badges),
  );
}

/// Event Card Widget
/// Live countdown shown to the organizer of a boosted event — ticks down to
/// when the boost (featuredUntil) expires.
class _BoostCountdown extends StatefulWidget {
  final DateTime until;
  const _BoostCountdown({required this.until});

  @override
  State<_BoostCountdown> createState() => _BoostCountdownState();
}

class _BoostCountdownState extends State<_BoostCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${mins}m';
    if (mins > 0) return '${mins}m';
    return '<1m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = widget.until.difference(DateTime.now());
    final text = remaining.isNegative
        ? l10n.eventBoostEnded
        : l10n.eventBoostEndsIn(_format(remaining));
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class EventCard extends StatelessWidget {

  const EventCard({
    required this.event, required this.currentUserId, required this.onTap, required this.onRSVP, super.key,
  });
  final Event event;
  final String currentUserId;
  final VoidCallback onTap;
  final Function(RSVPStatus) onRSVP;

  @override
  Widget build(BuildContext context) {
    final userRSVP = event.attendees
        .where((a) => a.userId == currentUserId)
        .firstOrNull;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: AppColors.backgroundDark,
                    child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                        ? Image.network(
                            event.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.event,
                              size: 60,
                              color: AppColors.textTertiary,
                            ),
                          )
                        : const Icon(
                            Icons.event,
                            size: 60,
                            color: AppColors.textTertiary,
                          ),
                  ),
                  // Category Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.richGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.category.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.deepBlack,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Featured/boosted badge
                  if (event.isCurrentlyFeatured)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.eventsFeatured,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Language badge for language exchange events
                  if (event.category == EventCategory.languageExchange &&
                      event.languagePairs != null)
                    Positioned(
                      top: 12,
                      left: 120,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.infoBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.translate,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.languagePairs!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Spots Left
                  if (!event.isFull)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.isUnlimited
                              ? AppLocalizations.of(context)!.eventsUnlimited
                              : AppLocalizations.of(context)!
                                  .eventsSpotsLeft(event.spotsLeft),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Event Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  buildEventStatusBadges(context, event),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEE, MMM d \u2022 h:mm a')
                            .format(event.startDate),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.locationName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Attendees + like
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people,
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.eventsGoing(event.goingCount),
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            EventLikeButton(
                              eventId: event.id,
                              userId: currentUserId,
                              likeCount: event.likeCount,
                            ),
                          ],
                        ),
                      ),
                      // Price
                      if (!event.isFree)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.richGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${event.currency ?? '\$'}${event.price?.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.richGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.eventsFreeLabel,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      // RSVP Button
                      ElevatedButton(
                        onPressed: event.isFull
                            ? null
                            : () => onRSVP(RSVPStatus.going),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              userRSVP?.status == RSVPStatus.going
                                  ? Colors.green
                                  : AppColors.richGold,
                          foregroundColor: AppColors.deepBlack,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          userRSVP?.status == RSVPStatus.going
                              ? AppLocalizations.of(context)!.eventsGoingLabel
                              : event.isFull
                                  ? AppLocalizations.of(context)!.eventsFullLabel
                                  : AppLocalizations.of(context)!.eventsJoinLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Event Details Screen
class EventDetailsScreen extends StatelessWidget {

  const EventDetailsScreen({
    required this.event, required this.currentUserId, super.key,
  });
  final Event event;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.backgroundDark,
            flexibleSpace: FlexibleSpaceBar(
              background: event.imageUrl != null
                  ? Image.network(event.imageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.backgroundCard,
                      child: const Icon(
                        Icons.event,
                        size: 80,
                        color: AppColors.textTertiary,
                      ),
                    ),
            ),
            actions: [
              // Check-in scanner — organizer only
              if (event.organizerId == currentUserId)
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner,
                      color: AppColors.richGold),
                  tooltip: AppLocalizations.of(context)!.eventScanCheckIn,
                  onPressed: () => Navigator.of(context).push(
                    EventScannerScreen.route(
                      event: event,
                      ownerUserId: currentUserId,
                    ),
                  ),
                ),
              // Attendance list — organizer only
              if (event.organizerId == currentUserId)
                IconButton(
                  icon: const Icon(Icons.fact_check_outlined,
                      color: AppColors.richGold),
                  tooltip: AppLocalizations.of(context)!.eventAttendance,
                  onPressed: () => Navigator.of(context).push(
                    EventAttendanceScreen.route(event: event),
                  ),
                ),
              // Edit — organizer only
              if (event.organizerId == currentUserId)
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.richGold),
                  tooltip: AppLocalizations.of(context)!.eventsEditEvent,
                  onPressed: () {
                    final bloc = context.read<EventsBloc>();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => BlocProvider.value(
                          value: bloc,
                          child: CreateEventScreen(
                            currentUserId: currentUserId,
                            existing: event,
                            onEventCreated: (e) {
                              bloc.add(UpdateEvent(event: e));
                              Navigator.of(ctx).pop();
                            },
                            onEventDeleted: () {
                              bloc.add(DeleteEvent(eventId: event.id));
                              // Pop edit screen + the detail screen.
                              Navigator.of(ctx).pop();
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // Boost (feature) — organizer only, if not already featured
              if (event.organizerId == currentUserId &&
                  !event.isCurrentlyFeatured)
                IconButton(
                  icon: const Icon(Icons.rocket_launch,
                      color: AppColors.richGold),
                  tooltip: AppLocalizations.of(context)!.eventsBoost,
                  onPressed: () => _handleBoost(context, event),
                ),
              // Single merged share: as a link, into an Exchange, or into a group.
              IconButton(
                icon: const Icon(Icons.share, color: AppColors.richGold),
                onPressed: () => showShareEventSheet(
                  context,
                  event: event,
                  currentUserId: currentUserId,
                ),
                tooltip: AppLocalizations.of(context)!.eventShare,
              ),
              // Group Chat button
              IconButton(
                icon: const Icon(Icons.chat, color: AppColors.richGold),
                onPressed: () async {
                  // Resolve the real display name so messages aren't sent as "User".
                  String name = 'User';
                  try {
                    final doc = await FirebaseFirestore.instance
                        .collection('profiles')
                        .doc(currentUserId)
                        .get();
                    final n = (doc.data()?['displayName'] as String?)?.trim();
                    if (n != null && n.isNotEmpty) name = n;
                  } catch (_) {/* fall back to "User" */}
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventChatScreen(
                        event: event,
                        currentUserId: currentUserId,
                        currentUserName: name,
                      ),
                    ),
                  );
                },
                tooltip: AppLocalizations.of(context)!.eventsGroupChatTooltip,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: EventLikeButton(
                      eventId: event.id,
                      userId: currentUserId,
                      likeCount: event.likeCount,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.calendar_today,
                    DateFormat('EEEE, MMMM d, yyyy').format(event.startDate),
                    '${DateFormat('h:mm a').format(event.startDate)} - ${DateFormat('h:mm a').format(event.endDate)}',
                  ),
                  const SizedBox(height: 12),
                  // Tappable -> opens Google Maps (coords if available, else the
                  // address text the organizer typed).
                  InkWell(
                    onTap: () {
                      final q = (event.latitude != null &&
                              event.longitude != null)
                          ? '${event.latitude},${event.longitude}'
                          : [event.locationName, event.address, event.city]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(', ');
                      launchUrl(
                        Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: _buildInfoRow(
                      Icons.location_on,
                      event.locationName,
                      event.address,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.people,
                    event.isUnlimited
                        ? AppLocalizations.of(context)!
                            .eventsGoing(event.goingCount)
                        : AppLocalizations.of(context)!.eventsAttending(
                            event.goingCount, event.maxAttendees),
                    event.isUnlimited
                        ? null
                        : AppLocalizations.of(context)!
                            .eventsSpotsLeft(event.spotsLeft),
                  ),
                  if (event.isPrivate) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.lock_outline,
                      AppLocalizations.of(context)!.eventsPrivateEvent,
                      null,
                    ),
                  ],
                  if (event.externalLinks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...event.externalLinks.map((lnk) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => launchUrl(
                              Uri.parse(lnk.url),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link,
                                    color: AppColors.richGold, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    lnk.label ?? lnk.url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.richGold,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                  // Language exchange info
                  if (event.category == EventCategory.languageExchange) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.translate,
                      event.languagePairs ?? AppLocalizations.of(context)!.eventsLanguageExchange,
                      event.languages.isNotEmpty
                          ? AppLocalizations.of(context)!.eventsLanguages(event.languages.join(', '))
                          : null,
                    ),
                  ],
                  // Feature this event (paid placement) — organizer only.
                  _buildFeaturedSection(context, event),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.eventsAboutThisEvent,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  // Tags
                  if (event.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: event.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundInput,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Group Chat link
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventChatScreen(
                            event: event,
                            currentUserId: currentUserId,
                            currentUserName: 'User',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.richGold.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: AppColors.richGold,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.eventsGroupChatTooltip,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)!.eventsChatWithAttendees,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Waitlist banner — shown when the viewer is queued.
                  _buildWaitlistBanner(context, event),
                  // "My ticket" — shown to anyone who is GOING to this event.
                  if (event.attendees.any((a) =>
                      a.userId == currentUserId &&
                      a.status == RSVPStatus.going)) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        EventTicketScreen.route(
                          event: event,
                          userId: currentUserId,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.richGold.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code_2,
                                color: AppColors.richGold),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.eventMyTicket,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                    // Safety check-in — "I've arrived safely" — for GOING users.
                    const SizedBox(height: 16),
                    EventSafetyCheckIn(
                      eventId: event.id,
                      userId: currentUserId,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.eventsAttendees,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    // Respect attendee privacy: hide invisible / organizer-only
                    // attendees from everyone except themselves and the organizer.
                    // Show only the first 100 going attendees.
                    final visibleGoing = event.attendees
                        .where((a) =>
                            a.status == RSVPStatus.going &&
                            a.isVisibleTo(currentUserId, event.organizerId))
                        .take(100)
                        .toList();
                    if (visibleGoing.isEmpty) {
                      return SizedBox(
                        height: 80,
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.eventsNoAttendeesYet,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }
                    // Resolve each attendee's CURRENT profile photo/name (the
                    // snapshotted userPhotoUrl is often missing), respecting
                    // anonymity.
                    return SizedBox(
                      height: 80,
                      child: FutureBuilder<Map<String, UserBrief>>(
                        future: UserDirectoryService.instance.resolve(
                            visibleGoing.map((a) => a.userId)),
                        builder: (context, dirSnap) {
                          final dir =
                              dirSnap.data ?? const <String, UserBrief>{};
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: visibleGoing.length,
                            itemBuilder: (context, index) {
                              final attendee = visibleGoing[index];
                              final name = attendee.displayNameFor(
                                  currentUserId, event.organizerId);
                              final anon = attendee.isAnonymous &&
                                  currentUserId != attendee.userId &&
                                  currentUserId != event.organizerId;
                              final photo = anon
                                  ? null
                                  : (attendee.userPhotoUrl ??
                                      dir[attendee.userId]?.photoUrl);
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: AppColors.backgroundCard,
                                      backgroundImage: (photo != null &&
                                              photo.isNotEmpty)
                                          ? CachedNetworkImageProvider(photo)
                                          : null,
                                      child: (photo == null || photo.isEmpty)
                                          ? Text(name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?')
                                          : null,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      name.split(' ').first,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            border: Border(
              top: BorderSide(
                  color: AppColors.textTertiary.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              if (!event.isFree)
                Text(
                  '${event.currency ?? '\$'}${event.price?.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Text(
                  AppLocalizations.of(context)!.eventsFreeLabel,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(width: 16),
              Builder(builder: (context) {
                final me = event.attendees
                    .where((a) => a.userId == currentUserId)
                    .firstOrNull;
                final l10n = AppLocalizations.of(context)!;
                final isGoing = me?.status == RSVPStatus.going;
                final isWaitlisted = me?.status == RSVPStatus.waitlist;
                // Already in (going/waitlist) => disabled label; full => allow
                // joining the waitlist; otherwise a normal join.
                final label = isGoing
                    ? l10n.eventsGoingLabel
                    : isWaitlisted
                        ? l10n.eventsOnWaitlist
                        : event.isFull
                            ? l10n.eventsJoinWaitlist
                            : l10n.eventsJoinEvent;
                final enabled = !isGoing && !isWaitlisted;
                return Expanded(
                  child: ElevatedButton(
                    onPressed:
                        enabled ? () => _handleJoin(context, event) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Join an event: pick a tier (if any), reserve a spot via a capacity-safe
  /// Firestore transaction (waitlisting when full), and — only when actually
  /// admitted as "going" — spend coins for paid tiers. Reuses the existing
  /// coin/tier gate pattern; stays fully in-economy (no real money).
  Future<void> _handleJoin(BuildContext context, Event event) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<EventsBloc>();
    final ds = sl<EventsRemoteDataSource>();

    // Choose a tier when the organizer defined any.
    TicketTier? tier;
    if (event.hasTicketTiers) {
      tier = await _pickTier(context, event);
      if (tier == null || !context.mounted) return; // cancelled
    }

    // Cost = selected tier price, else the legacy event price (implicit tier).
    final cost = tier != null
        ? tier.priceCoins
        : (event.isFree ? 0 : (event.price ?? 0).round());

    // Pre-check affordability for paid joins so we rarely have to roll back.
    if (cost > 0) {
      final afford =
          await sl<CanAffordFeature>()(userId: currentUserId, cost: cost);
      if (!context.mounted) return;
      if (!afford.fold((_) => false, (v) => v)) {
        messenger.showSnackBar(
            SnackBar(content: Text(l10n.eventsInsufficientCoins)));
        return;
      }
      final confirmed = await _confirmCoinSpend(
          context, l10n.eventsJoinEvent, l10n.eventsJoinForCoins(cost));
      if (confirmed != true || !context.mounted) return;
    }

    // Reserve the spot (transactionally). Returns going or waitlist.
    RsvpJoinResult result;
    try {
      result = await ds.joinEventWithTier(
        eventId: event.id,
        userId: currentUserId,
        tierId: tier?.id,
      );
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.eventsRsvpError)));
      }
      return;
    }
    if (!context.mounted) return;

    // Business lead capture: joining (going or waitlisted) a business-organized
    // event becomes a saved-event lead. Non-business organizers and self-joins
    // are cheaply ignored by the service.
    _logSavedEventLead(event, currentUserId);

    if (result.isWaitlisted) {
      // Full — queued. No coins charged until (and unless) promoted to going.
      messenger.showSnackBar(SnackBar(
          content: Text(l10n.eventsWaitlistPosition(result.waitlistPosition))));
    } else {
      // Admitted as going — now charge coins for a paid tier.
      if (cost > 0) {
        final charge = await sl<PurchaseFeature>()(
          userId: currentUserId,
          featureName: 'event_rsvp',
          cost: cost,
          relatedId: event.id,
        );
        if (!charge.fold((_) => false, (_) => true)) {
          // Charge failed after admission — roll the reservation back.
          await ds.cancelRsvpWithPromotion(event.id, currentUserId);
          if (context.mounted) {
            messenger.showSnackBar(
                SnackBar(content: Text(l10n.eventsInsufficientCoins)));
          }
          return;
        }
      }
      if (context.mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text(l10n.eventsRsvpUpdated)));
      }
    }

    // Refresh the lists (we wrote directly, bypassing the RSVP bloc event).
    bloc
      ..add(const LoadEvents(upcoming: true))
      ..add(LoadUserEvents(userId: currentUserId));
    if (context.mounted) Navigator.pop(context);
  }

  /// Bottom sheet to choose a ticket tier for a tiered event.
  Future<TicketTier?> _pickTier(BuildContext context, Event event) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<TicketTier>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.eventsSelectTier,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            ...event.ticketTiers.map((t) => ListTile(
                  leading: const Icon(Icons.local_activity,
                      color: AppColors.richGold),
                  title: Text(t.name,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    '${t.isFree ? l10n.eventsFreeTier : l10n.eventsTierPriceValue(t.priceCoins)} · '
                    '${t.isUnlimited ? l10n.eventsUnlimited : l10n.eventsTierCapacityValue(t.capacity)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () => Navigator.pop(ctx, t),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Organizer-only "Feature this event" placement section shown on the detail
  /// screen. When active, shows "Featured until …"; otherwise shows a paid
  /// call-to-action that spends coins to feature the event for 7 days.
  Widget _buildFeaturedSection(BuildContext context, Event event) {
    if (event.organizerId != currentUserId) {
      return const SizedBox.shrink();
    }
    final until = event.featuredUntil;
    if (event.isCurrentlyFeatured && until != null) {
      // Organizer-only: live countdown until the boost expires.
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.richGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.richGold.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.rocket_launch,
                  color: AppColors.richGold, size: 20),
              const SizedBox(width: 12),
              Expanded(child: _BoostCountdown(until: until)),
            ],
          ),
        ),
      );
    }

    // Boosting is triggered by the rocket "Boost" icon in the app bar
    // (see _handleBoost) — no separate button here, to avoid duplication.
    return const SizedBox.shrink();
  }

  /// Boost duration/cost tiers (organizer picks one). Duration -> coin cost.
  static const List<(Duration, int)> _boostOptions = [
    (Duration(hours: 1), 50),
    (Duration(hours: 6), 100),
    (Duration(hours: 12), 150),
    (Duration(hours: 24), 200),
    (Duration(days: 3), 500),
    (Duration(days: 7), 1000),
  ];

  String _boostDurationLabel(AppLocalizations l10n, Duration d) {
    if (d.inHours <= 24) return l10n.eventsBoostHours(d.inHours);
    if (d.inDays < 7) return l10n.eventsBoostDays(d.inDays);
    return l10n.eventsBoostWeeks(d.inDays ~/ 7);
  }

  Future<(Duration, int)?> _showBoostOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<(Duration, int)>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.rocket_launch, color: AppColors.richGold),
                  const SizedBox(width: 12),
                  Text(
                    l10n.eventsBoostChooseDuration,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            for (final opt in _boostOptions)
              ListTile(
                leading:
                    const Icon(Icons.schedule, color: AppColors.richGold),
                title: Text(
                  _boostDurationLabel(l10n, opt.$1),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                trailing: Text(
                  l10n.promoteCostLabel(opt.$2),
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, opt),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Boost (feature) an event — organizer picks a duration/coin tier, then
  /// pays coins and the event is featured for that duration.
  Future<void> _handleBoost(BuildContext context, Event event) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await _showBoostOptions(context);
    if (choice == null || !context.mounted) return;
    final duration = choice.$1;
    final cost = choice.$2;
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<EventsBloc>();

    final afford =
        await sl<CanAffordFeature>()(userId: currentUserId, cost: cost);
    if (!context.mounted) return;
    if (!afford.fold((_) => false, (v) => v)) {
      await _promptBuyCoins(context);
      return;
    }
    final confirmed = await _confirmCoinSpend(
        context, l10n.eventsBoost, l10n.eventsBoostConfirm(cost));
    if (confirmed != true || !context.mounted) return;
    final charge = await sl<PurchaseFeature>()(
      userId: currentUserId,
      featureName: 'event_boost',
      cost: cost,
      relatedId: event.id,
    );
    if (!context.mounted) return;
    if (!charge.fold((_) => false, (_) => true)) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.eventsInsufficientCoins)));
      return;
    }
    bloc.add(UpdateEvent(
      event: event.copyWith(
        isFeatured: true,
        featuredUntil: DateTime.now().add(duration),
      ),
    ));
    messenger.showSnackBar(SnackBar(content: Text(l10n.eventsBoosted)));
  }

  Future<bool?> _confirmCoinSpend(
      BuildContext context, String title, String body) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(body, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.groupCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.eventsConfirmAction)),
        ],
      ),
    );
  }

  /// Insufficient coins → offer to buy more, routing to the coin market.
  Future<void> _promptBuyCoins(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.eventsInsufficientCoins,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.eventsBuyCoinsPrompt,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.groupCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.eventsBuyCoins,
                  style: const TextStyle(color: AppColors.richGold))),
        ],
      ),
    );
    if (go != true || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<CoinBloc>(
          create: (_) => sl<CoinBloc>()
            ..add(LoadCoinBalance(currentUserId))
            ..add(const LoadAvailablePackages()),
          child: CoinShopScreen(userId: currentUserId),
        ),
      ),
    );
  }

  /// "You're #N on the waitlist" banner for a queued attendee. Position is read
  /// on demand (bounded query); waitlisted attendees never get the QR ticket.
  Widget _buildWaitlistBanner(BuildContext context, Event event) {
    final me = event.attendees
        .where((a) => a.userId == currentUserId)
        .firstOrNull;
    if (me == null || me.status != RSVPStatus.waitlist) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: FutureBuilder<int>(
        future:
            sl<EventsRemoteDataSource>().getWaitlistPosition(event.id, currentUserId),
        builder: (context, snap) {
          final pos = snap.data ?? 0;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.infoBlue.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top, color: AppColors.infoBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pos > 0
                        ? l10n.eventsWaitlistPosition(pos)
                        : l10n.eventsOnWaitlist,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String? subtitle) {
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
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Create Event Screen
class CreateEventScreen extends StatefulWidget {

  const CreateEventScreen({
    required this.currentUserId, required this.onEventCreated, super.key,
    this.existing,
    this.onEventDeleted,
    this.communityId,
    this.lockCommunity = false,
  });
  final String currentUserId;
  final Function(Event) onEventCreated;

  /// When set, the screen edits this event instead of creating a new one.
  final Event? existing;

  /// When editing, called if the user confirms deleting the event.
  final VoidCallback? onEventDeleted;

  /// Pre-selects a community to link the event to (from a community's Events
  /// tab). Null = no preselection (the user may pick one from the linker).
  final String? communityId;

  /// When true (opened from inside a community), the community selection is
  /// fixed and the picker is not shown.
  final bool lockCommunity;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxAttendeesController = TextEditingController(text: '20');
  final _languagePairsController = TextEditingController();
  EventCategory _category = EventCategory.social;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1, hours: 2));
  bool _isFree = true;
  final _priceController = TextEditingController(text: '10');
  String _currency = '\$';
  static const List<String> _currencies = ['\$', '€', '£', 'R\$', '¥'];
  EventVisibility _visibility = EventVisibility.public;
  bool _isUnlimited = false;
  // Guests each attendee may bring (0 = guests not allowed). Feeds QR check-in.
  int _guestsAllowedPerAttendee = 0;
  static const int _maxGuestsAllowed = 10;
  double? _lat;
  double? _lng;
  String? _pickedCity;
  String? _pickedCountry;
  XFile? _mainPhoto;
  final List<XFile> _extraPhotos = [];
  // Already-uploaded images kept when editing (URLs, shown alongside new files).
  String? _existingMainUrl;
  final List<String> _existingPhotoUrls = [];
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;
  final _linkUrlController = TextEditingController();
  final _linkLabelController = TextEditingController();
  final List<ExternalLink> _externalLinks = [];

  // ---- Recurring series (create only) ----
  RecurrenceFrequency _recurFreq = RecurrenceFrequency.none;
  int _recurInterval = 1;
  int _recurCount = 4; // total occurrences incl. the first (<= kMaxSeriesOccurrences)

  // ---- Ticket tiers (optional; empty = single implicit tier) ----
  final List<TicketTier> _tiers = [];

  // ---- Draft / scheduled publishing ----
  // Chosen when saving (Publish / Save as draft / Schedule).
  DateTime? _publishAt;
  bool _saving = false;

  // Community linkage: the selected community id + the manageable communities
  // the user may link to (loaded lazily; empty until loaded).
  String? _selectedCommunityId;
  List<Community> _manageableCommunities = const [];

  // The organizer's real display name (resolved from their profile), so created
  // events don't show the "Current User" placeholder as host.
  String _organizerName = '';

  bool get _isEditing => widget.existing != null;

  /// Resolve the organizer's display name from their profile (best-effort).
  Future<void> _loadOrganizerName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.currentUserId)
          .get();
      final name = (doc.data()?['displayName'] as String?)?.trim();
      if (name != null && name.isNotEmpty && mounted) {
        setState(() => _organizerName = name);
      }
    } catch (_) {/* fall back to the existing organizerName */}
  }

  Future<void> _loadManageableCommunities() async {
    // No picker needed when the community is fixed by the caller.
    if (widget.lockCommunity) return;
    final result =
        await sl<CommunitiesRepository>().getManageableCommunities(
      widget.currentUserId,
    );
    if (!mounted) return;
    result.fold(
      (_) {},
      (communities) => setState(() => _manageableCommunities = communities),
    );
  }

  /// "Link to community" selector. Hidden when the community is fixed by the
  /// caller or when the user manages no communities.
  Widget _buildCommunityLinker() {
    if (widget.lockCommunity || _manageableCommunities.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final value =
        _manageableCommunities.any((c) => c.id == _selectedCommunityId)
            ? _selectedCommunityId
            : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.communitiesLinkToCommunity,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: value,
            isExpanded: true,
            dropdownColor: AppColors.backgroundCard,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.groups_outlined,
                  color: AppColors.richGold, size: 20),
              filled: true,
              fillColor: AppColors.backgroundCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              DropdownMenuItem<String?>(
                child: Text(l10n.communitiesLinkNone),
              ),
              ..._manageableCommunities.map(
                (c) => DropdownMenuItem<String?>(
                  value: c.id,
                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _selectedCommunityId = v),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedCommunityId =
        widget.communityId ?? widget.existing?.communityId;
    _organizerName = widget.existing?.organizerName ?? '';
    _loadOrganizerName();
    _loadManageableCommunities();
    final e = widget.existing;
    if (e == null) return;
    // Prefill from the existing event (edit mode).
    _titleController.text = e.title;
    _descriptionController.text = e.description;
    _locationController.text = e.locationName;
    _category = e.category;
    _startDate = e.startDate;
    _endDate = e.endDate;
    _isFree = e.isFree;
    if (!e.isFree && e.price != null) {
      _priceController.text = e.price!.round().toString();
    }
    _currency = e.currency ?? '\$';
    _visibility = e.visibility;
    _isUnlimited = e.isUnlimited;
    _guestsAllowedPerAttendee = e.guestsAllowedPerAttendee;
    if (!e.isUnlimited) _maxAttendeesController.text = e.maxAttendees.toString();
    _lat = e.latitude;
    _lng = e.longitude;
    _pickedCity = e.city;
    _pickedCountry = e.country;
    _externalLinks.addAll(e.externalLinks);
    if (e.languagePairs != null) _languagePairsController.text = e.languagePairs!;
    // Show already-uploaded images in the edit form.
    _existingMainUrl = e.imageUrl;
    _existingPhotoUrls.addAll(e.photoUrls);
    // Prefill recurrence + tiers + schedule so editing preserves them.
    if (e.recurrence != null) {
      _recurFreq = e.recurrence!.frequency;
      _recurInterval = e.recurrence!.safeInterval;
      _recurCount = e.recurrence!.safeCount;
    }
    _tiers.addAll(e.ticketTiers);
    _publishAt = e.publishAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxAttendeesController.dispose();
    _languagePairsController.dispose();
    _linkUrlController.dispose();
    _linkLabelController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickMainPhoto() async {
    final x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) setState(() => _mainPhoto = x);
  }

  int get _extraCount => _existingPhotoUrls.length + _extraPhotos.length;

  Future<void> _pickExtraPhoto() async {
    if (_extraCount >= 4) return;
    final x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) setState(() => _extraPhotos.add(x));
  }

  /// Main photo + up to 4 extra photos. In edit mode, already-uploaded images
  /// (URLs) are shown and can be kept or removed; new picks are added on top.
  Widget _buildPhotoSection() {
    Widget slot({
      XFile? file,
      String? url,
      required VoidCallback onTap,
      VoidCallback? onRemove,
      bool main = false,
    }) {
      final hasImage = file != null || (url != null && url.isNotEmpty);
      return GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              width: main ? 110 : 70,
              height: main ? 110 : 70,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
                image: file != null
                    ? DecorationImage(
                        image: WebMedia.imageProviderFor(file),
                        fit: BoxFit.cover)
                    : (url != null && url.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(url), fit: BoxFit.cover)
                        : null),
                border:
                    Border.all(color: AppColors.textTertiary.withOpacity(0.3)),
              ),
              child: !hasImage
                  ? Icon(main ? Icons.add_a_photo : Icons.add,
                      color: AppColors.textSecondary)
                  : null,
            ),
            if (onRemove != null && hasImage)
              Positioned(
                right: 8,
                top: 0,
                child: GestureDetector(
                  onTap: onRemove,
                  child: const CircleAvatar(
                    radius: 11,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 116,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Main: new file takes precedence, else existing URL.
          slot(
            file: _mainPhoto,
            url: _existingMainUrl,
            main: true,
            onTap: _pickMainPhoto,
            onRemove: (_mainPhoto != null || _existingMainUrl != null)
                ? () => setState(() {
                      _mainPhoto = null;
                      _existingMainUrl = null;
                    })
                : null,
          ),
          // Existing extra photos (kept unless removed).
          ..._existingPhotoUrls.map((u) => slot(
                url: u,
                onTap: () => _previewEventPhoto(url: u),
                onRemove: () => setState(() => _existingPhotoUrls.remove(u)),
              )),
          // Newly added extra photos.
          ..._extraPhotos.map((f) => slot(
                file: f,
                onTap: () => _previewEventPhoto(file: f),
                onRemove: () => setState(() => _extraPhotos.remove(f)),
              )),
          if (_extraCount < 4) slot(onTap: _pickExtraPhoto),
        ],
      ),
    );
  }

  /// Full-screen, pinch-to-zoom preview of an event photo (file or URL).
  void _previewEventPhoto({XFile? file, String? url}) {
    if (file == null && (url == null || url.isEmpty)) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: file != null
                    ? Image(
                        image: WebMedia.imageProviderFor(file),
                        fit: BoxFit.contain)
                    : Image.network(url!, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pick the event location from the map (reuses the app's location picker).
  Future<void> _pickLocation() async {
    final loc = await Navigator.of(context)
        .push<profile_entity.Location>(EventLocationPickerScreen.route());
    if (loc == null || !mounted) return;
    setState(() {
      _lat = loc.latitude;
      _lng = loc.longitude;
      _pickedCity = loc.city;
      _pickedCountry = loc.country;
      _locationController.text = loc.displayAddress;
    });
  }

  Future<void> _showAddLinkDialog() async {
    final l10n = AppLocalizations.of(context)!;
    _linkUrlController.clear();
    _linkLabelController.clear();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.eventsAddLink,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _linkLabelController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration:
                  _inputDecoration(l10n.eventsLinkLabelHint),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkUrlController,
              style: const TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.url,
              autofocus: true,
              decoration: _inputDecoration(l10n.eventsLinkUrlHint),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.groupCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.eventsAddLink)),
        ],
      ),
    );
    if (added != true) return;
    final url = _linkUrlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _externalLinks.add(ExternalLink(
        url: url,
        label: _linkLabelController.text.trim().isEmpty
            ? null
            : _linkLabelController.text.trim(),
      ));
      _linkUrlController.clear();
      _linkLabelController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(
          _isEditing
              ? AppLocalizations.of(context)!.eventsEditEvent
              : AppLocalizations.of(context)!.eventsCreateEvent,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          if (_isEditing && widget.onEventDeleted != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
              tooltip: AppLocalizations.of(context)!.eventsDeleteEvent,
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPhotoSection(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration(AppLocalizations.of(context)!.eventsEventTitle),
              validator: (v) => v?.isEmpty ?? true ? AppLocalizations.of(context)!.eventsRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration(AppLocalizations.of(context)!.eventsDescription),
              maxLines: 4,
              validator: (v) => v?.isEmpty ?? true ? AppLocalizations.of(context)!.eventsRequired : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EventCategory>(
              initialValue: _category,
              dropdownColor: AppColors.backgroundCard,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration(AppLocalizations.of(context)!.eventsCategory),
              items: EventCategory.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            // Language Pairs field (shown only for language exchange category)
            if (_category == EventCategory.languageExchange) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _languagePairsController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  AppLocalizations.of(context)!.eventsLanguagePairs,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              style: const TextStyle(color: AppColors.textPrimary),
              readOnly: true,
              onTap: _pickLocation,
              decoration: _inputDecoration(
                      AppLocalizations.of(context)!.eventsLocation)
                  .copyWith(
                suffixIcon:
                    const Icon(Icons.map_outlined, color: AppColors.richGold),
              ),
              validator: (v) => v?.isEmpty ?? true
                  ? AppLocalizations.of(context)!.eventsRequired
                  : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                AppLocalizations.of(context)!.eventsStartDateTime,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              subtitle: Text(
                DateFormat('EEE, MMM d yyyy \u2022 h:mm a')
                    .format(_startDate),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              trailing: const Icon(Icons.calendar_today,
                  color: AppColors.richGold),
              onTap: () => _selectDateTime(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                AppLocalizations.of(context)!.eventsEndDateTime,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              subtitle: Text(
                DateFormat('EEE, MMM d yyyy \u2022 h:mm a').format(_endDate),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              trailing: const Icon(Icons.calendar_today,
                  color: AppColors.richGold),
              onTap: () => _selectDateTime(false),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                AppLocalizations.of(context)!.eventsUnlimitedAttendees,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              value: _isUnlimited,
              activeThumbColor: AppColors.richGold,
              onChanged: (v) => setState(() => _isUnlimited = v),
            ),
            if (!_isUnlimited)
              TextFormField(
                controller: _maxAttendeesController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                    AppLocalizations.of(context)!.eventsMaxAttendees),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 16),
            // Guests allowed per attendee (0..N) — enables the QR ticket guest
            // picker + counts toward the organizer's headcount.
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.eventGuestsAllowedLabel,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                IconButton(
                  onPressed: _guestsAllowedPerAttendee <= 0
                      ? null
                      : () => setState(() => _guestsAllowedPerAttendee--),
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.richGold,
                ),
                Text(
                  '$_guestsAllowedPerAttendee',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _guestsAllowedPerAttendee >= _maxGuestsAllowed
                      ? null
                      : () => setState(() => _guestsAllowedPerAttendee++),
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.richGold,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Link to a community (owner/admin communities only). Hidden when the
            // community is fixed by the caller (opened from a community's Events
            // tab) or when the user manages no communities.
            _buildCommunityLinker(),
            // Visibility: public (discoverable) vs private (invitees/link only)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                AppLocalizations.of(context)!.eventsPrivateEvent,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              value: _visibility == EventVisibility.private,
              activeThumbColor: AppColors.richGold,
              onChanged: (v) => setState(() => _visibility =
                  v ? EventVisibility.private : EventVisibility.public),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                AppLocalizations.of(context)!.eventsFreeEvent,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              value: _isFree,
              activeThumbColor: AppColors.richGold,
              onChanged: (v) => setState(() => _isFree = v),
            ),
            if (!_isFree) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  // Currency selector (default $)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _currency,
                      underline: const SizedBox.shrink(),
                      dropdownColor: AppColors.backgroundCard,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 16),
                      items: _currencies
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _currency = v ?? '\$'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                          AppLocalizations.of(context)!.eventsPriceHint),
                      validator: (v) {
                        if (_isFree) return null;
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1 || n > 1000) {
                          return AppLocalizations.of(context)!.eventsPriceRange;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // External links (tickets, website, map…)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.eventsExternalLinks,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ..._externalLinks.map((lnk) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link, color: AppColors.richGold),
                  title: Text(
                    lnk.label ?? lnk.url,
                    style: const TextStyle(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary),
                    onPressed: () =>
                        setState(() => _externalLinks.remove(lnk)),
                  ),
                )),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle, color: AppColors.richGold),
                label: Text(
                  AppLocalizations.of(context)!.eventsAddLink,
                  style: const TextStyle(color: AppColors.richGold),
                ),
                onPressed: _showAddLinkDialog,
              ),
            ),
            const SizedBox(height: 24),
            _buildRecurrenceSection(),
            const SizedBox(height: 16),
            _buildTicketTiersSection(),
            const SizedBox(height: 32),
            _buildSaveActions(),
          ],
        ),
      ),
    );
  }

  /// Recurrence editor (create only). Editing an existing occurrence instead
  /// offers to cancel the whole series.
  Widget _buildRecurrenceSection() {
    final l10n = AppLocalizations.of(context)!;
    if (_isEditing) {
      // Only offer series controls when this event belongs to a series.
      if (widget.existing?.seriesId == null) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _confirmCancelSeries,
          icon: const Icon(Icons.repeat, color: AppColors.errorRed),
          label: Text(l10n.eventsCancelSeries,
              style: const TextStyle(color: AppColors.errorRed)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.errorRed.withOpacity(0.6)),
          ),
        ),
      );
    }

    String freqLabel(RecurrenceFrequency f) {
      switch (f) {
        case RecurrenceFrequency.none:
          return l10n.eventsRepeatNone;
        case RecurrenceFrequency.daily:
          return l10n.eventsRepeatDaily;
        case RecurrenceFrequency.weekly:
          return l10n.eventsRepeatWeekly;
        case RecurrenceFrequency.monthly:
          return l10n.eventsRepeatMonthly;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.eventsRepeats,
            style: const TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          l10n.eventsRepeatHelper,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<RecurrenceFrequency>(
          initialValue: _recurFreq,
          dropdownColor: AppColors.backgroundCard,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: _inputDecoration(l10n.eventsRepeats),
          items: RecurrenceFrequency.values
              .map((f) =>
                  DropdownMenuItem(value: f, child: Text(freqLabel(f))))
              .toList(),
          onChanged: (v) =>
              setState(() => _recurFreq = v ?? RecurrenceFrequency.none),
        ),
        if (_recurFreq != RecurrenceFrequency.none) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _stepperRow(
                  label: l10n.eventsRepeatInterval,
                  value: _recurInterval,
                  min: 1,
                  max: 12,
                  onChanged: (v) => setState(() => _recurInterval = v),
                ),
              ),
            ],
          ),
          _stepperRow(
            label: l10n.eventsRepeatCount,
            value: _recurCount,
            min: 2,
            max: kMaxSeriesOccurrences,
            onChanged: (v) => setState(() => _recurCount = v),
          ),
          Text(
            l10n.eventsRepeatCap(kMaxSeriesOccurrences),
            style:
                const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _stepperRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(color: AppColors.textPrimary)),
        ),
        IconButton(
          onPressed: value <= min ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.richGold,
        ),
        Text('$value',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: value >= max ? null : () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.richGold,
        ),
      ],
    );
  }

  /// Optional ticket tiers. Empty = one implicit tier using price/maxAttendees.
  Widget _buildTicketTiersSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.eventsTicketTiers,
            style: const TextStyle(
                color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          l10n.eventsTicketTiersHelper,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        ..._tiers.map((t) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.local_activity, color: AppColors.richGold),
              title: Text(t.name,
                  style: const TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(
                '${t.isFree ? l10n.eventsFreeTier : l10n.eventsTierPriceValue(t.priceCoins)} · '
                '${t.isUnlimited ? l10n.eventsUnlimited : l10n.eventsTierCapacityValue(t.capacity)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              trailing: IconButton(
                icon:
                    const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => setState(() => _tiers.remove(t)),
              ),
            )),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add_circle, color: AppColors.richGold),
            label: Text(l10n.eventsAddTier,
                style: const TextStyle(color: AppColors.richGold)),
            onPressed: _showAddTierDialog,
          ),
        ),
      ],
    );
  }

  /// Save actions. Editing keeps a single Save button; creating offers
  /// Publish (primary), Save as draft, and Schedule.
  Widget _buildSaveActions() {
    final l10n = AppLocalizations.of(context)!;
    if (_isEditing) {
      return ElevatedButton(
        onPressed: (_uploading || _saving)
            ? null
            : () => _submit(status: widget.existing!.status),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.richGold,
          foregroundColor: AppColors.deepBlack,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _busy
            ? _spinner()
            : Text(l10n.eventsEditEvent,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }
    return Column(
      children: [
        ElevatedButton(
          onPressed: (_uploading || _saving)
              ? null
              : () => _submit(status: EventStatus.published),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.richGold,
            foregroundColor: AppColors.deepBlack,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size.fromHeight(52),
          ),
          child: _busy
              ? _spinner()
              : Text(l10n.eventsCreateEvent,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (_uploading || _saving)
                    ? null
                    : () => _submit(status: EventStatus.draft),
                icon: const Icon(Icons.edit_note, color: AppColors.richGold),
                label: Text(l10n.eventsSaveAsDraft,
                    style: const TextStyle(color: AppColors.richGold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.richGold.withOpacity(0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    (_uploading || _saving) ? null : _pickScheduleAndSubmit,
                icon: const Icon(Icons.schedule, color: AppColors.richGold),
                label: Text(l10n.eventsSchedule,
                    style: const TextStyle(color: AppColors.richGold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.richGold.withOpacity(0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool get _busy => _uploading || _saving;

  Widget _spinner() => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.deepBlack),
      );

  /// Ask for a future publish time, then save the event as `scheduled`.
  Future<void> _pickScheduleAndSubmit() async {
    final base = _publishAt ?? DateTime.now().add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null || !mounted) return;
    final publishAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    setState(() => _publishAt = publishAt);
    await _submit(status: EventStatus.scheduled, publishAt: publishAt);
  }

  /// Add/define a ticket tier via a small dialog.
  Future<void> _showAddTierDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtl = TextEditingController();
    final priceCtl = TextEditingController(text: '0');
    final capCtl = TextEditingController(text: '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.eventsAddTier,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration(l10n.eventsTierName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration(l10n.eventsTierPriceCoins),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capCtl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration(l10n.eventsTierCapacity),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.groupCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.eventsAddTier)),
        ],
      ),
    );
    if (ok != true) return;
    final name = nameCtl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _tiers.add(TicketTier(
        // Dot-free unique id (used as a Firestore nested-field key).
        id: 'tier_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        priceCoins: int.tryParse(priceCtl.text.trim())?.clamp(0, 100000) ?? 0,
        capacity: int.tryParse(capCtl.text.trim())?.clamp(0, 1000000) ?? 0,
      ));
    });
  }

  Future<void> _confirmCancelSeries() async {
    final l10n = AppLocalizations.of(context)!;
    final seriesId = widget.existing?.seriesId;
    if (seriesId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.eventsCancelSeries,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.eventsCancelSeriesConfirm,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.groupCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.eventsCancelSeries,
                  style: const TextStyle(color: AppColors.errorRed))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await sl<EventsRemoteDataSource>().cancelSeries(seriesId);
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.eventsSeriesCancelled)));
      navigator.pop();
    } catch (_) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.eventsSeriesCancelError)));
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.backgroundCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _selectDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
    );
    if (time == null) return;

    setState(() {
      final dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (isStart) {
        _startDate = dateTime;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 2));
        }
      } else {
        _endDate = dateTime;
      }
    });
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.eventsDeleteEvent,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.eventsDeleteConfirmBody,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.groupCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.eventsDeleteEvent,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onEventDeleted?.call();
  }

  /// Insufficient coins for the extra-event fee → offer to buy more, routing
  /// to the coin market (mirrors the boost flow's buy-coins prompt).
  Future<void> _promptBuyCoinsForExtraEvent(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.eventsInsufficientCoins,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.eventsBuyCoinsPrompt,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.groupCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.eventsBuyCoins,
                  style: const TextStyle(color: AppColors.richGold))),
        ],
      ),
    );
    if (go != true || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<CoinBloc>(
          create: (_) => sl<CoinBloc>()
            ..add(LoadCoinBalance(widget.currentUserId))
            ..add(const LoadAvailablePackages()),
          child: CoinShopScreen(userId: widget.currentUserId),
        ),
      ),
    );
  }

  Future<void> _submit(
      {required EventStatus status, DateTime? publishAt}) async {
    if (_uploading || _saving) return;
    if (!_formKey.currentState!.validate()) return;

    // Block hate speech / discrimination / explicit sexual language in the
    // event title and description.
    final prohibited = [
      ...ContentFilterService().findProhibitedTerms(_titleController.text),
      ...ContentFilterService().findProhibitedTerms(_descriptionController.text),
    ];
    if (prohibited.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.eventTextProhibited),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Membership gate + per-tier event allowance (only when creating).
    if (!_isEditing) {
      // 1) Valid-membership gate: a valid GreenGo membership is required to
      //    create an event. Active Base (free) stays allowed — only a truly
      //    expired membership is blocked (routes to the marketplace to renew).
      if (!await TierGate()
          .ensureValidMembershipByUid(context, widget.currentUserId)) {
        return;
      }
      if (!mounted) return;

      // 2) Extra-event paywall. Free allowance = TierEntitlements.maxEvents
      //    (Base 1 / Silver 3 / Gold 5; Platinum/test = unlimited → always
      //    free). Within the allowance the event is free; beyond it, each
      //    additional ongoing event costs [kExtraEventCost] coins.
      final events =
          await TierLimitsService().canCreateEvent(widget.currentUserId);
      if (!mounted) return;
      final needsPaywall = events.max != null && !events.allowed;
      if (needsPaywall) {
        final l10n = AppLocalizations.of(context)!;
        // Can the user afford the extra-event fee?
        final afford = await sl<CanAffordFeature>()(
            userId: widget.currentUserId, cost: kExtraEventCost);
        if (!mounted) return;
        if (!afford.fold((_) => false, (v) => v)) {
          await _promptBuyCoinsForExtraEvent(context);
          return;
        }
        // Confirm the coin spend ("Extra event · 50 coins").
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            title: Text(l10n.extraEventTitle,
                style: const TextStyle(color: AppColors.textPrimary)),
            content: Text(
              l10n.extraEventBody(kExtraEventCost),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.groupCancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                ),
                child: Text(l10n.eventsConfirmAction),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        // Charge the fee; only proceed to create on a successful charge.
        final charge = await sl<PurchaseFeature>()(
          userId: widget.currentUserId,
          featureName: 'extra_event',
          cost: kExtraEventCost,
        );
        if (!mounted) return;
        if (!charge.fold((_) => false, (_) => true)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.eventsInsufficientCoins)),
          );
          return;
        }
      }
    }

    // Nudity / explicit-content check on every event image before upload.
    // On-device ML Kit is native-only — skip on web (server-side moderation
    // still applies) so a web organizer isn't blocked from creating events.
    if (!kIsWeb) {
      final imagesToCheck = [
        if (_mainPhoto != null) _mainPhoto!,
        ..._extraPhotos,
      ];
      for (final f in imagesToCheck) {
        final res =
            await PhotoValidationService().validateImageForSending(File(f.path));
        if (!mounted) return;
        if (!res.isValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)?.photoExplicitContent ??
                      'This image contains inappropriate content and cannot be used.'),
              backgroundColor: AppColors.errorRed,
            ),
          );
          return;
        }
      }
    }

    // Upload new photos; keep already-uploaded ones the user didn't remove.
    setState(() => _uploading = true);
    String? imageUrl = _existingMainUrl;
    final photoUrls = <String>[..._existingPhotoUrls];
    try {
      final ds = sl<ProfileRemoteDataSource>();
      if (_mainPhoto != null) {
        imageUrl = await ds.uploadPhoto(widget.currentUserId, _mainPhoto!,
            folder: 'events');
      }
      for (final f in _extraPhotos) {
        photoUrls.add(await ds.uploadPhoto(widget.currentUserId, f,
            folder: 'events'));
      }
    } catch (_) {
      // Non-fatal: proceed without (or with partial) images.
    }
    if (!mounted) return;
    setState(() => _uploading = false);

    final maxAttendees =
        _isUnlimited ? 0 : (int.tryParse(_maxAttendeesController.text) ?? 20);
    final price = _isFree
        ? null
        : (double.tryParse(_priceController.text)?.clamp(1, 1000))?.toDouble();
    final languagePairs = _category == EventCategory.languageExchange
        ? (_languagePairsController.text.isNotEmpty
            ? _languagePairsController.text
            : null)
        : null;

    if (_isEditing) {
      // Preserve attendees, createdAt, featured, series, etc. Keep the existing
      // status/publishAt; only update editable fields incl. ticket tiers.
      final event = widget.existing!.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        imageUrl: imageUrl,
        photoUrls: photoUrls,
        startDate: _startDate,
        endDate: _endDate,
        locationName: _locationController.text,
        latitude: _lat,
        longitude: _lng,
        city: _pickedCity,
        country: _pickedCountry,
        maxAttendees: maxAttendees,
        price: price,
        currency: _isFree ? null : _currency,
        visibility: _visibility,
        externalLinks: _externalLinks,
        languagePairs: languagePairs,
        guestsAllowedPerAttendee: _guestsAllowedPerAttendee,
        ticketTiers: _tiers,
        communityId: _selectedCommunityId,
        clearCommunityId: _selectedCommunityId == null,
        updatedAt: DateTime.now(),
      );
      widget.onEventCreated(event);
      return;
    }

    // Creating a new event. Draft = published:false-ish; scheduled = auto-publish
    // once publishAt is reached; published = live now.
    final recurrence = EventRecurrence(
      frequency: _recurFreq,
      interval: _recurInterval,
      count: _recurCount,
    );
    final base = Event(
      id: '', // Firestore will generate the ID
      organizerId: widget.currentUserId,
      organizerName: _organizerName.isNotEmpty ? _organizerName : 'Current User',
      title: _titleController.text,
      description: _descriptionController.text,
      category: _category,
      imageUrl: imageUrl,
      photoUrls: photoUrls,
      startDate: _startDate,
      endDate: _endDate,
      locationName: _locationController.text,
      latitude: _lat,
      longitude: _lng,
      city: _pickedCity,
      country: _pickedCountry,
      maxAttendees: maxAttendees,
      price: price,
      currency: _isFree ? null : _currency,
      visibility: _visibility,
      externalLinks: _externalLinks,
      status: status,
      publishAt: status == EventStatus.scheduled ? publishAt : null,
      recurrence: recurrence.isRecurring ? recurrence : null,
      ticketTiers: _tiers,
      languagePairs: languagePairs,
      guestsAllowedPerAttendee: _guestsAllowedPerAttendee,
      communityId: _selectedCommunityId,
      createdAt: DateTime.now(),
    );

    if (recurrence.isRecurring) {
      // Generate the occurrence docs (all share a seriesId). Write the extras
      // directly (one batch), and route the first through the normal create
      // path so the Events screen refreshes + shows the success snackbar.
      final occurrences =
          EventSeriesService.instance.buildOccurrences(base, recurrence);
      setState(() => _saving = true);
      try {
        if (occurrences.length > 1) {
          await sl<EventsRemoteDataSource>()
              .createEventsBatch(occurrences.sublist(1));
        }
      } catch (_) {
        // Non-fatal: the first occurrence still goes through below.
      }
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onEventCreated(occurrences.first);
      return;
    }

    widget.onEventCreated(base);
  }
}
