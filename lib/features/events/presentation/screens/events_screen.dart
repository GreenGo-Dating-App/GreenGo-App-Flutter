import '../../../../core/widgets/listing_wizard.dart';
import '../../../ticket_payments/presentation/ticket_l10n.dart';
import '../../../ticket_payments/domain/ticket_payments.dart';
import '../../../ticket_payments/presentation/screens/get_paid_screen.dart';
import '../../../ticket_payments/presentation/screens/ticket_types_screen.dart';
import '../../../ticket_payments/presentation/widgets/buy_ticket_sheet.dart';
import '../../../ticket_payments/presentation/widgets/ticket_payment_selector.dart';
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
import '../../../../core/utils/first_screen_gate.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../core/widgets/translatable_text.dart';
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
import '../../../attractions/presentation/widgets/attractions_filter_sheet.dart';
import '../../../attractions/presentation/widgets/attractions_tab.dart';
import 'event_attendees_screen.dart';
import '../widgets/experiences_tab.dart';
import '../widgets/attraction_menu_dialog.dart';
import '../widgets/external_event_tiles.dart';
import '../widgets/interleaved_feed_view.dart';
import '../../data/datasources/external_events_pager.dart';
import '../../data/datasources/external_events_preloader.dart';
import '../../domain/entities/external_event.dart';
import '../../domain/feed_interleave.dart';
import '../../../user_experiences/domain/repositories/user_experiences_repository.dart';
import '../../../user_experiences/presentation/experience_creation_gate.dart';
import '../../../user_experiences/presentation/screens/experience_editor_screen.dart';
import '../../../user_experiences/presentation/screens/my_experiences_screen.dart';
import '../../../user_experiences/presentation/widgets/merged_experiences_feed.dart';
import '../../../user_experiences/presentation/widgets/community_experiences_tab.dart';
import '../widgets/event_like_button.dart';
import '../widgets/event_organizer_row.dart';
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
import '../../data/services/event_geocoder.dart';
import '../../data/services/event_series_service.dart';
import '../../data/services/events_cache_service.dart';
import '../../data/services/events_location.dart';
import '../../data/services/events_prefetch.dart';
import '../../domain/entities/event.dart';
import '../../../safety/presentation/widgets/event_safety_checkin.dart';
import '../bloc/events_bloc.dart';
import '../bloc/events_event.dart';
import '../bloc/events_state.dart';
import '../widgets/co_owner_picker_sheet.dart';
import '../widgets/share_event_sheet.dart';
import 'event_attendance_screen.dart';
import 'event_chat_screen.dart';
import 'event_scanner_screen.dart';
import 'event_ticket_screen.dart';
import '../../../../core/widgets/boost_celebration.dart';
import '../../../../core/widgets/verified_badge.dart';

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

/// Feed filter of the Events and Experiences tabs (the chip next to Sort):
/// All (community + partner merged) · Community · Partner · Mine.
enum _FeedFilter { all, community, partner, mine }

class EventsScreen extends StatefulWidget {

  const EventsScreen({
    required this.currentUserId, super.key,
    this.initialTab = 0,
  });
  final String currentUserId;

  /// Tab to open on: 0 Events, 1 Attractions, [experiencesTab] Experiences.
  /// Opening on Experiences (e.g. Explore "Top experiences → See all") also
  /// selects its "All" filter (community + partner).
  final int initialTab;

  static const int experiencesTab = 2;

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
  String _extSort = 'distance';
  // Sort for the curated Attractions tab (own keys: distance|score|rating|price|name).
  String _attrSort = 'distance'; // distance | score | rating | price | name
  // Bridge to the Attractions tab's filter sheet (score / category /
  // country -> city); the icon lives in the search bar, the data in the tab.
  final AttractionsFilterController _attrFilters =
      AttractionsFilterController();
  // Live Events (ticketmaster) has its own order: DISTANCE (nearest) first by
  // default; the user can switch to Date.
  String _liveSort = 'distance'; // date | distance
  // Native tabs (Upcoming/Community/My Events): order by DATE (earliest first)
  // by default; the user can still switch to distance/popular from the menu.
  String _nativeSort = 'date'; // distance | date | popular

  // My Events time bucket (the old "Going" tab is merged into My Events).
  _MyEventsFilter _myEventsFilter = _MyEventsFilter.upcoming;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));
    if (widget.initialTab == EventsScreen.experiencesTab) {
      _expFilter = _FeedFilter.all;
      _sessionExpFilter = _FeedFilter.all;
    }

    // Create the BLoC with repository and datasource
    final dataSource = EventsRemoteDataSourceImpl();
    _eventsDataSource = dataSource; // reused for whole-table community search
    final repository = EventsRepositoryImpl(remoteDataSource: dataSource);
    _eventsBloc = EventsBloc(repository: repository);

    // Load initial events. The worldwide "upcoming" list is only a fallback
    // for viewers with no location anchor (the nearest-first community query
    // covers everyone else), so it is requested once the anchor is known to
    // be missing — see [_loadUpcomingFallback].
    _eventsBloc.add(LoadUserEvents(userId: widget.currentUserId));
    _resolveProfilePlace();

    // Paint the community feed last shown (local cache, no network) while the
    // anchor resolves and the server query runs; the server result replaces it.
    _paintCachedCommunity();

    // Rebuild on tab change so the category bar shows/hides per tab.
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {});
      // The listener also fires while the swipe animation runs; act once,
      // when the index has settled.
      if (_tabController.indexIsChanging) return;
      // Refresh "My events" (organised + going) when its view is opened
      // (served from the datasource's session memo when still fresh).
      if (_isEventsTab && _eventsFilter == _FeedFilter.mine) {
        _eventsBloc.add(LoadUserEvents(userId: widget.currentUserId));
      }
    });

    // Location for distance ordering: an instant anchor first (never waits
    // for GPS), refined by a fresh fix afterwards.
    final anchor = EventsLocation.current;
    if (anchor != null) {
      _userLat = anchor.lat;
      _userLng = anchor.lng;
      _anchorResolved = true;
    }
    _initLocation();
  }

  /// Profile city / country (local cache first) — narrows the partner side of
  /// "All" to the viewer's country and the no-location fallback list to their
  /// city.
  String? _profileCity;
  String? _profileCountry;
  bool _placeResolved = false;

  Future<void> _resolveProfilePlace() async {
    final place = await EventsLocation.profilePlace(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _profileCity = place?.city;
      _profileCountry = place?.country;
      _placeResolved = true;
    });
  }

  /// The bloc's "upcoming events" list is only shown when there is no
  /// location anchor (otherwise the nearest-first community list is used and
  /// only its within-100km part of the upcoming list could ever show — which
  /// the nearest-first list already contains). Without an anchor it is
  /// narrowed to the profile city, widening to the old worldwide query when
  /// the city has too few events (see [LoadEvents.widenIfFew]).
  Future<void> _loadUpcomingFallback() async {
    if (!_anchorResolved || (_userLat != null && _userLng != null)) return;
    if (!_placeResolved) {
      await _resolveProfilePlace();
      if (!mounted) return;
    }
    final city = _profileCity;
    _eventsBloc.add(LoadEvents(
      upcoming: true,
      city: (city != null && city.isNotEmpty) ? city : null,
      widenIfFew: true,
    ));
  }

  // Tabs: 0 Events (community + partner + mine, via [_eventsFilter]),
  // 1 Attractions, 2 Experiences (via [_expFilter]). The old Community /
  // Live Events / My Events tabs are filters of the Events tab now.
  static const int _kEventsTab = 0;
  static const int _kAttractionsTab = 1;
  static const int _kExperiencesTab = 2;

  bool get _isEventsTab => _tabController.index == _kEventsTab;

  // Last filter chosen per tab, remembered for the app session (not persisted).
  static _FeedFilter _sessionEventsFilter = _FeedFilter.all;
  static _FeedFilter _sessionExpFilter = _FeedFilter.all;
  _FeedFilter _eventsFilter = _sessionEventsFilter;
  _FeedFilter _expFilter = _sessionExpFilter;

  // GreenGo-category lists: every Events filter except Partner. In "All" a
  // category narrows the community side (partner items carry no category).
  bool get _isNativeTab =>
      _isEventsTab && _eventsFilter != _FeedFilter.partner;

  // Attractions tab (curated GreenGo catalogue): own sort + filter sheet in
  // the search bar (no chip row under it).
  bool get _isAttractionsTab => _tabController.index == _kAttractionsTab;

  // Experiences tab — the Partner (Viator) view also has a category filter.
  bool get _isExperiencesTab => _tabController.index == _kExperiencesTab;
  // Selected Viator category (null = all).
  String? _experienceCategory;
  // Bumped after an experience is created from the "+" chooser so the
  // Experiences lists re-query and show it.
  int _expReloadTick = 0;
  // Order of the merged Events "All" feed: soonest first by default.
  String _allSort = 'date'; // date | distance

  // Whole-table community search (Community tab): default shows the 100 closest;
  // a search queries the entire events table and shows matches.
  late final EventsRemoteDataSourceImpl _eventsDataSource;
  static const int _communityNearbyLimit = EventsPrefetch.communityLimit;
  List<Event> _communityResults = const [];
  bool _communitySearching = false;
  int _communitySearchGen = 0;
  // Default community list: the closest 100 via geohash (scales to a big table).
  List<Event> _communityNearby = const [];
  bool _communityNearbyLoading = false;
  // True once the server community query has answered (the cached paint no
  // longer needs to be kept).
  bool _communityServerLoaded = false;

  /// False until the instant location anchor is known (or known to be absent).
  /// The external sub-tabs wait for it so they query once, anchored.
  bool _anchorResolved = false;

  /// Last list state, so a transient state (loading after RSVP/create, a
  /// snackbar-only state) never blanks the tabs.
  EventsLoaded? _lastLoaded;

  final EventsCacheService _eventsCache = const EventsCacheService();

  /// Stale-while-revalidate: show the feed rendered last time, instantly, from
  /// the local cache. Never an empty state; the server load always follows.
  Future<void> _paintCachedCommunity() async {
    final cached = await _eventsCache.loadCommunity();
    if (cached.isNotEmpty &&
        mounted &&
        !_communityServerLoaded &&
        _communityNearby.isEmpty) {
      setState(() => _communityNearby = cached);
    }
  }

  /// Anchor instantly (last-known fix / last session / profile location), load
  /// against it, then refine with a medium-accuracy fix and reload only if the
  /// user turns out to be meaningfully elsewhere.
  Future<void> _initLocation() async {
    if (!_anchorResolved) {
      final anchor = await EventsLocation.quick(widget.currentUserId);
      if (!mounted) return;
      setState(() {
        _userLat = anchor?.lat;
        _userLng = anchor?.lng;
        _anchorResolved = true;
        // No anchor means no geohash query to revalidate a cached paint with;
        // the tab falls back to the (server-loaded) upcoming list instead.
        if (anchor == null && !_communityServerLoaded) {
          _communityNearby = const [];
        }
      });
    }
    unawaited(_loadUpcomingFallback());
    unawaited(_loadCommunityNearby());

    final pos = await const LocationShareService().getApproximatePosition();
    if (pos == null || !mounted) return;
    final prev = _userLat == null || _userLng == null
        ? null
        : (lat: _userLat!, lng: _userLng!);
    EventsLocation.remember(pos.latitude, pos.longitude);
    if (!EventsLocation.movedFar(prev, pos.latitude, pos.longitude)) return;
    setState(() {
      _userLat = pos.latitude;
      _userLng = pos.longitude;
    });
    unawaited(_loadCommunityNearby());
  }

  /// Closest community events around the current anchor. Adopts the background
  /// prefetch when it ran this exact query; otherwise queries the server. The
  /// visible list is kept until the new one arrives.
  Future<void> _loadCommunityNearby({bool force = false}) async {
    final lat = _userLat, lng = _userLng;
    if (lat == null || lng == null) return;
    setState(() => _communityNearbyLoading = true);
    // Pull-to-refresh must reach the server, not the session memo.
    if (force) _eventsDataSource.invalidateNearbyCommunity();
    try {
      final prefetched =
          force ? null : await EventsPrefetch.takeCommunity(lat, lng);
      final list = prefetched ??
          await _eventsDataSource.getNearbyCommunityEvents(
              lat: lat, lng: lng, limit: _communityNearbyLimit);
      // A newer anchor started its own load; let that one win.
      if (!mounted || lat != _userLat || lng != _userLng) return;
      setState(() {
        _communityNearby = list;
        _communityNearbyLoading = false;
        _communityServerLoaded = true;
      });
      unawaited(_eventsCache.saveCommunity(list));
    } catch (_) {
      if (mounted) {
        setState(() {
          _communityNearbyLoading = false;
          _communityServerLoaded = true;
        });
      }
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

  @override
  void dispose() {
    _tabController.dispose();
    _attrFilters.dispose();
    _eventsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider.value(
      value: _eventsBloc,
      child: ShowCaseWidget(
        builder: (_) => TourTrigger(
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
                onPressed: () => _showCreateChooser(context),
              ),
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
                // The three tabs share the full width equally; long
                // translations scale down instead of overflowing.
                isScrollable: false,
                tabAlignment: TabAlignment.fill,
                tabs: [
                  for (final label in [
                    AppLocalizations.of(context)!.eventsTitle,
                    AppLocalizations.of(context)!.eventsTabAttractions,
                    AppLocalizations.of(context)!.eventsTabExperiences,
                  ])
                    Tab(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(label, maxLines: 1),
                      ),
                    ),
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
              unawaited(_loadUpcomingFallback());
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
              // The bloc already re-read the affected event into its lists;
              // only "My events" (going set) can change. No list reload.
              _eventsBloc.add(LoadUserEvents(userId: widget.currentUserId));
            } else if (state is EventDeleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.eventsDeleted),
                  backgroundColor: AppColors.successGreen,
                ),
              );
            } else if (state is EventsError) {
              showUserError(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is EventsLoaded) _lastLoaded = state;
            return Column(
              children: [
                // Search by country/city/name + popularity sort
                _buildSearchAndSortBar(),
                // Category filter — native tabs use GreenGo categories;
                // Attractions filters live in the search-bar sheet.
                if (_isNativeTab) _buildCategoryFilter(_lastLoaded),
                if (_isExperiencesTab && _expFilter == _FeedFilter.partner)
                  _buildExperienceCategoryFilter(),
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

  /// Always the same tab tree: each tab shows its own loading state, so the
  /// Live / Attractions / Experiences tabs never wait for (or get torn down
  /// by) the community query, and a reload never swaps the tabs for a spinner.
  Widget _buildBody(EventsState state) {
    final loaded = _lastLoaded;
    final firstLoad = loaded == null && state is! EventsError;
    return TabBarView(
      controller: _tabController,
      children: [
        // Every tab stays mounted once built, so swiping back to it never
        // re-queries or rebuilds its list from scratch (each list widget
        // also keeps itself alive; this covers the filter bodies that don't,
        // e.g. the merged Experiences "All" feed).
        _KeepAliveTab(child: _buildEventsTab(loaded, firstLoad)),
        _KeepAliveTab(
            child: _buildExternalTab(_buildCuratedAttractionsTab)),
        _KeepAliveTab(
            child: _buildExternalTab(_buildExperiencesFilterBody)),
      ],
    );
  }

  /// Events tab body for the selected filter. Each filter is its own keyed
  /// subtree, so switching filters starts that list from the top (the
  /// paginated window resets).
  Widget _buildEventsTab(EventsLoaded? loaded, bool firstLoad) {
    final Widget body;
    switch (_eventsFilter) {
      case _FeedFilter.all:
        body = _buildExternalTab(() => _buildAllEventsFeed(loaded, firstLoad));
      case _FeedFilter.community:
        body = _buildCommunityTab(loaded, firstLoad);
      case _FeedFilter.partner:
        // The former Live Events tab: ticketmaster in chunks of 20.
        body = _buildExternalTab(() =>
            _buildExperiencesTab('ticketmaster', sortOverride: _liveSort));
      case _FeedFilter.mine:
        // The former My Events tab (organised / co-owned + RSVP'd).
        body = loaded != null
            ? _buildMyEventsTab(loaded)
            : (firstLoad ? _buildTabSpinner() : _buildEventsList(const []));
    }
    return KeyedSubtree(
        key: ValueKey('eventsFilter_${_eventsFilter.name}'), child: body);
  }

  Widget _buildTabSpinner() => const Center(
      child: CircularProgressIndicator(color: AppColors.richGold));

  /// External tabs are anchored queries: build them once the instant location
  /// anchor is known (milliseconds) so they don't query unanchored first.
  Widget _buildExternalTab(Widget Function() build) =>
      _anchorResolved ? build() : _buildTabSpinner();

  /// Search bar (country / city / name) + popularity sort toggle.
  Widget _buildSearchAndSortBar() {
    final sortMenu = _buildSortMenu();
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
                  // Events tab (All / Community) searches the whole events
                  // table.
                  if (_isEventsTab) _runCommunitySearch(v.trim());
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
          // Events / Experiences: All · Community · Partner · Mine.
          if (_isEventsTab || _isExperiencesTab) _buildFeedFilterChip(),
          if (sortMenu != null) sortMenu,
          // Attractions filters (score / category / country -> city), next to
          // the sort menu; gold dot while any filter is non-default.
          if (_isAttractionsTab) _buildAttractionFiltersButton(),
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

  /// The sort menu for the current tab / filter (null = nothing to sort).
  Widget? _buildSortMenu() {
    PopupMenuButton<String> menu(
      String current,
      ValueChanged<String> onSelected,
      List<PopupMenuEntry<String>> Function(AppLocalizations l) items,
    ) =>
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort, color: AppColors.richGold),
          tooltip: AppLocalizations.of(context)!.eventsSortBy,
          color: AppColors.backgroundCard,
          initialValue: current,
          onSelected: onSelected,
          itemBuilder: (ctx) => items(AppLocalizations.of(ctx)!),
        );

    if (_isEventsTab) {
      switch (_eventsFilter) {
        // Merged feed: soonest (default) or nearest across both sources.
        case _FeedFilter.all:
          return menu(_allSort, (v) => setState(() => _allSort = v), (l) => [
                _sortItem('date', l.eventsSortDate, Icons.event,
                    current: _allSort),
                _sortItem('distance', l.eventsSortDistance, Icons.near_me,
                    current: _allSort),
              ]);
        // Partner (ticketmaster): Date / Distance, no stars/reviews.
        case _FeedFilter.partner:
          return menu(_liveSort, (v) => setState(() => _liveSort = v), (l) => [
                _sortItem('date', l.eventsSortDate, Icons.event,
                    current: _liveSort),
                _sortItem('distance', l.eventsSortDistance, Icons.near_me,
                    current: _liveSort),
              ]);
        // Native events have no stars/reviews: Distance / Date / Popular.
        case _FeedFilter.community:
        case _FeedFilter.mine:
          return menu(_nativeSort, (v) => setState(() => _nativeSort = v),
              (l) => [
                    _sortItem('distance', l.eventsSortDistance, Icons.near_me,
                        current: _nativeSort),
                    _sortItem('date', l.eventsSortDate, Icons.event,
                        current: _nativeSort),
                    _sortItem('popular', l.eventsSortPopular,
                        Icons.local_fire_department,
                        current: _nativeSort),
                  ]);
      }
    }
    // Attractions — curated dataset: its own sort keys.
    if (_isAttractionsTab) {
      return menu(_attrSort, (v) => setState(() => _attrSort = v), (l) => [
            _sortItem('distance', l.attrSortDistance, Icons.near_me,
                current: _attrSort),
            _sortItem('score', l.attrSortScore, Icons.diamond,
                current: _attrSort),
            _sortItem('rating', l.attrSortRating, Icons.star,
                current: _attrSort),
            _sortItem('price', l.attrSortPrice, Icons.local_offer,
                current: _attrSort),
            _sortItem('name', l.attrSortName, Icons.sort_by_alpha,
                current: _attrSort),
          ]);
    }
    // Experiences: the partner sort drives Partner and the merged All feed;
    // the community feed has a fixed order (nearest, else newest).
    if (_expFilter == _FeedFilter.all || _expFilter == _FeedFilter.partner) {
      return menu(_extSort, (v) => setState(() => _extSort = v), (l) => [
            _sortItem('distance', l.eventsSortDistance, Icons.near_me),
            _sortItem('rating', l.eventsSortStars, Icons.star),
            _sortItem('reviews', l.eventsSortReviews, Icons.reviews),
            _sortItem('date', l.eventsSortDate, Icons.event),
          ]);
    }
    return null;
  }

  /// Compact dropdown chip choosing what the Events / Experiences tab shows.
  Widget _buildFeedFilterChip() {
    final l = AppLocalizations.of(context)!;
    final events = _isEventsTab;
    final current = events ? _eventsFilter : _expFilter;
    String label(_FeedFilter f) => switch (f) {
          _FeedFilter.all => l.feedFilterAll,
          _FeedFilter.community => l.feedFilterCommunity,
          _FeedFilter.partner => l.feedFilterPartner,
          _FeedFilter.mine =>
            events ? l.feedFilterMyEvents : l.feedFilterMyExperiences,
        };
    IconData icon(_FeedFilter f) => switch (f) {
          _FeedFilter.all => Icons.layers_outlined,
          _FeedFilter.community => Icons.people_alt_outlined,
          _FeedFilter.partner => Icons.handshake_outlined,
          _FeedFilter.mine => Icons.person_outline,
        };
    final active = current != _FeedFilter.all;
    return PopupMenuButton<_FeedFilter>(
      tooltip: l.feedFilterTooltip,
      color: AppColors.backgroundCard,
      initialValue: current,
      onSelected: events ? _setEventsFilter : _setExpFilter,
      itemBuilder: (_) => [
        for (final f in _FeedFilter.values)
          PopupMenuItem<_FeedFilter>(
            value: f,
            child: Row(
              children: [
                Icon(icon(f),
                    size: 18,
                    color: f == current
                        ? AppColors.richGold
                        : AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(label(f),
                    style: TextStyle(
                        color: f == current
                            ? AppColors.richGold
                            : AppColors.textPrimary)),
              ],
            ),
          ),
      ],
      child: Container(
        height: 36,
        constraints: const BoxConstraints(maxWidth: 116),
        padding: const EdgeInsets.only(left: 10, right: 2),
        decoration: BoxDecoration(
          color: active
              ? AppColors.richGold.withValues(alpha: 0.15)
              : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: active ? AppColors.richGold : AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon(current), size: 16, color: AppColors.richGold),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label(current),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down,
                color: AppColors.richGold, size: 20),
          ],
        ),
      ),
    );
  }

  void _setEventsFilter(_FeedFilter f) {
    if (f == _eventsFilter) return;
    setState(() {
      _eventsFilter = f;
      _sessionEventsFilter = f;
    });
    if (f == _FeedFilter.mine) {
      _eventsBloc.add(LoadUserEvents(userId: widget.currentUserId));
    }
  }

  void _setExpFilter(_FeedFilter f) {
    if (f == _expFilter) return;
    setState(() {
      _expFilter = f;
      _sessionExpFilter = f;
    });
  }

  Widget _buildAttractionFiltersButton() {
    return ListenableBuilder(
      listenable: _attrFilters,
      builder: (context, _) => IconButton(
        tooltip: AppLocalizations.of(context)!.filters,
        onPressed: _attrFilters.open,
        icon: Badge(
          isLabelVisible: _attrFilters.active,
          smallSize: 8,
          backgroundColor: AppColors.richGold,
          alignment: AlignmentDirectional.topEnd,
          child: const Icon(Icons.tune, color: AppColors.richGold),
        ),
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
    var result = events.where(_matchesNativeFilters).toList();
    // Apply the selected order (distance by default).
    result = _applyNativeSort(result);
    // Featured/boosted events surface first, preserving relative order.
    final featured = result.where((e) => e.isCurrentlyFeatured).toList();
    final rest = result.where((e) => !e.isCurrentlyFeatured).toList();
    return [...featured, ...rest];
  }

  /// Category chip (every native list, incl. Community which renders the
  /// server `_communityNearby` list that is not category-scoped upstream),
  /// and free-text search (country/city/name).
  bool _matchesNativeFilters(Event e) {
    if (_selectedCategory != null && e.category != _selectedCategory) {
      return false;
    }
    final q = _searchQuery.toLowerCase();
    if (q.isNotEmpty &&
        !(e.title.toLowerCase().contains(q) ||
            (e.city ?? '').toLowerCase().contains(q) ||
            e.locationName.toLowerCase().contains(q) ||
            (e.address ?? '').toLowerCase().contains(q) ||
            e.tags.any((t) => t.toLowerCase().contains(q)))) {
      return false;
    }
    return true;
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


  Widget _buildCategoryFilter(EventsLoaded? state) {
    // Only show category chips that actually have at least one event across the
    // user's native events (so empty tags are omitted).
    final present = <EventCategory>{};
    if (state != null) {
      for (final e in [...state.upcomingEvents, ...state.userEvents]) {
        present.add(e.category);
      }
    }
    for (final e in _communityNearby) {
      present.add(e.category);
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
    var list = state.upcomingEvents.where((e) => e.isLive).toList();
    if (_userLat != null && _userLng != null) {
      // Keep only community events WITHIN 100km, then nearest-first.
      list = list.where((e) => _distanceToEvent(e) <= 100).toList()
        ..sort((a, b) => _distanceToEvent(a).compareTo(_distanceToEvent(b)));
    }
    // Default view: only the closest 100 (search queries the whole table).
    return list.take(_communityNearbyLimit).toList();
  }

  /// Community tab body: default = closest 100; while searching, results come
  /// from a whole-table query (searchEvents), refined + sorted client-side.
  Widget _buildCommunityTab(EventsLoaded? state, bool firstLoad) {
    if (_searchQuery.isNotEmpty) {
      if (_communitySearching && _communityResults.isEmpty) {
        return _buildTabSpinner();
      }
      // Auto-publish gate on search results too (drafts/scheduled never listed).
      return _buildEventsList(_applySearchAndSort(
          _communityResults.where((e) => e.isLive).toList()));
    }
    // Prefer the geohash nearest-100 (cached paint, then server); fall back to
    // the bloc's loaded set when location is unknown or the nearby query
    // returned nothing.
    if (_communityNearby.isNotEmpty) {
      return _buildEventsList(_applySearchAndSort(
          _communityNearby.where((e) => e.isLive).toList()));
    }
    final waiting = _communityNearbyLoading ||
        !_anchorResolved ||
        (_userLat != null && !_communityServerLoaded);
    if (state == null || waiting) {
      return (firstLoad || waiting)
          ? _buildTabSpinner()
          : _buildEventsList(const []);
    }
    return _buildEventsList(_applySearchAndSort(_getCommunityEvents(state)));
  }

  /// My Events = events the user ORGANIZES **plus** events they've RSVP'd
  /// "going" to (the former "Going" tab is merged here), de-duplicated by id.
  List<Event> _getMyEvents(EventsLoaded state) {
    final byId = <String, Event>{};
    for (final e in state.userEvents) {
      // Created OR co-owned.
      final organizes = e.isOwner(widget.currentUserId);
      final going = e.attendees.any((a) =>
          a.userId == widget.currentUserId && a.status == RSVPStatus.going);
      if (organizes || going) byId[e.id] = e;
    }
    if (byId.isEmpty) {
      // Fallback: derive from all loaded events.
      for (final e in state.filteredEvents) {
        if (e.isOwner(widget.currentUserId) ||
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

  /// Empty state of the event lists, with the "Create event" button.
  Widget _buildNoEventsState() {
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

  /// Community / My events list: the first screen appears in one go (its
  /// covers decoded first, capped — see [FirstScreenGate]).
  Widget _buildEventsList(List<Event> events) {
    return FirstScreenGate(
      ready: true,
      images: (context, viewport) {
        final count = _gridView
            ? firstScreenGridCount(
                viewport: viewport,
                columns: _gridColumns(context),
                childAspectRatio: 0.7)
            : firstScreenListCount(
                viewportHeight: viewport.height, itemExtent: 330);
        return events
            .take(count)
            .map((e) => eventCoverImageProvider(context, e, grid: _gridView))
            .whereType<ImageProvider>()
            .toList();
      },
      placeholder: _buildTabSpinner(),
      builder: (_) => _buildEventsListBody(events),
    );
  }

  Widget _buildEventsListBody(List<Event> events) {
    if (events.isEmpty) return _buildNoEventsState();

    return RefreshIndicator(
      color: AppColors.richGold,
      onRefresh: () async {
        _eventsDataSource.invalidateUserEvents(widget.currentUserId);
        unawaited(_loadUpcomingFallback());
        _eventsBloc.add(LoadUserEvents(userId: widget.currentUserId));
        // Pull-to-refresh always re-queries the server (never the prefetch).
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
                    ? CachedNetworkImage(
                        imageUrl: event.imageUrl!,
                        fit: BoxFit.cover,
                        // Decode at tile size (disk-cached across sessions).
                        memCacheWidth:
                            eventCoverMemCacheWidth(context, grid: true),
                        placeholder: (_, __) =>
                            Container(color: AppColors.backgroundInput),
                        errorWidget: (_, __, ___) => Container(
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

  /// Curated attractions (GreenGo dataset) — country-scoped to where the user
  /// is (primaryOrigin as fallback). Sort and filters (score / category /
  /// country -> city) live in the search bar; it does not use _extSort.
  Widget _buildCuratedAttractionsTab() {
    return AttractionsTab(
      key: const ValueKey('curatedAttractions'),
      gridView: _gridView,
      query: _searchQuery,
      currentUserId: widget.currentUserId,
      userLat: _userLat,
      userLng: _userLng,
      sort: _attrSort,
      filters: _attrFilters,
    );
  }

  /// Experiences tab body for the selected filter (each keyed so a filter
  /// switch — or a newly created experience — restarts its list at the top).
  Widget _buildExperiencesFilterBody() {
    switch (_expFilter) {
      case _FeedFilter.all:
        return MergedExperiencesFeed(
          key: ValueKey('uexpAll_$_expReloadTick'),
          currentUserId: widget.currentUserId,
          gridView: _gridView,
          sort: _extSort,
          query: _searchQuery,
          userLat: _userLat,
          userLng: _userLng,
        );
      case _FeedFilter.community:
        return CommunityExperiencesTab(
          key: ValueKey('uexpCommunity_$_expReloadTick'),
          currentUserId: widget.currentUserId,
          gridView: _gridView,
          query: _searchQuery,
          userLat: _userLat,
          userLng: _userLng,
          // Creating lives in the "+" chooser; "My experiences" is a filter.
          showActions: false,
        );
      case _FeedFilter.partner:
        return _buildExperiencesTab('viator', category: _experienceCategory);
      case _FeedFilter.mine:
        return MyExperiencesPanel(
          key: ValueKey('uexpMine_$_expReloadTick'),
          currentUserId: widget.currentUserId,
        );
    }
  }

  /// Distance in km from the viewer, or null when either side is unknown.
  double? _kmTo(double? lat, double? lng) {
    if (_userLat == null || _userLng == null || lat == null || lng == null) {
      return null;
    }
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

  /// The community side of the Events "All" feed — the same list the
  /// Community view shows (nearest community events, whole-table search
  /// results while searching, the loaded set as a fallback) — plus whether it
  /// is final yet, and a key that changes only when the list does.
  ({List<Event> list, bool ready, String key}) _communityFeedInput(
      EventsLoaded? state, bool firstLoad) {
    if (_searchQuery.isNotEmpty) {
      final ready = !_communitySearching || _communityResults.isNotEmpty;
      return (
        list: _communityResults.where((e) => e.isLive).toList(),
        ready: ready,
        key: 'q${identityHashCode(_communityResults)}_$ready',
      );
    }
    // The cached paint (last session's list) seeds the feed instantly; the
    // server answer only restarts it when it holds different events (the key
    // is the id list, so an identical answer causes no jump).
    if (_communityNearby.isNotEmpty) {
      final live = _communityNearby.where((e) => e.isLive).toList();
      return (
        list: live,
        ready: true,
        key: 'n${Object.hashAll(live.map((e) => e.id))}',
      );
    }
    final waiting = _communityNearbyLoading ||
        !_anchorResolved ||
        (_userLat != null && !_communityServerLoaded);
    if (waiting || (state == null && firstLoad)) {
      return (list: const <Event>[], ready: false, key: 'wait');
    }
    if (state == null) return (list: const <Event>[], ready: true, key: 'none');
    return (
      list: _getCommunityEvents(state),
      ready: true,
      key: 'b${identityHashCode(state.upcomingEvents)}',
    );
  }

  _MergedEvent _mergedCommunity(Event e) => _MergedEvent.community(
      e, FeedSortKey(date: e.startDate, distanceKm: _kmTo(e.latitude, e.longitude)));

  _MergedEvent _mergedPartner(ExternalEvent p) => _MergedEvent.partner(
      p,
      FeedSortKey(
          date: parseFeedDate(p.startDate), distanceKm: _kmTo(p.lat, p.lng)));

  /// Client filters of the merged feed: community items use the native
  /// filters; partner items match search (title/city/country) and are hidden
  /// while a GreenGo category is selected.
  bool _matchesMergedFilters(_MergedEvent x) {
    final e = x.community;
    if (e != null) return _matchesNativeFilters(e);
    final p = x.partner!;
    if (_selectedCategory != null) return false;
    final q = _searchQuery.toLowerCase();
    if (q.isNotEmpty &&
        !(p.title.toLowerCase().contains(q) ||
            (p.city ?? '').toLowerCase().contains(q) ||
            (p.country ?? '').toLowerCase().contains(q))) {
      return false;
    }
    return true;
  }

  /// Events → "All": community events and partner (ticketmaster) live events
  /// in ONE list. Both sources stay paged (community = the nearest-100 set,
  /// partner = chunks of 20) and are merged as pages arrive, append-only:
  /// Date (default) = soonest first, same day nearest first; Distance =
  /// nearest first across both (needs the viewer's location).
  Widget _buildAllEventsFeed(EventsLoaded? loaded, bool firstLoad) {
    final input = _communityFeedInput(loaded, firstLoad);
    final byDistance =
        _allSort == 'distance' && _userLat != null && _userLng != null;
    final anchor = '$_userLat,$_userLng';
    // Date mode (worldwide soonest-first) starts in the viewer's country.
    final country = byDistance ? null : _profileCountry;
    return InterleavedFeedView<_MergedEvent>(
      sourceKeyA: '${input.key}|$anchor|$byDistance',
      sourceKeyB: '$anchor|$byDistance|$_placeResolved|$country',
      filterKey: '$_selectedCategory|$_searchQuery',
      createA: () => input.ready
          ? ListFeedSource<_MergedEvent>(
              input.list.map(_mergedCommunity).toList())
          : null,
      createB: () {
        // Wait (milliseconds, local cache) for the profile country so the
        // date feed queries once, already narrowed.
        if (!byDistance && !_placeResolved) return null;
        var pager = ExternalEventsPager(
          source: 'ticketmaster',
          // Date mode is the server-ordered soonest-first feed; distance mode
          // the nearest-first geohash rings.
          sort: byDistance ? 'distance' : 'date',
          userLat: _userLat,
          userLng: _userLng,
          liveChunks: true,
          country: country,
        );
        return CachedFirstPageFeedSource<ExternalEvent, _MergedEvent>(
          // Last session's first page, from the local cache (instant).
          cached: pager.loadCached,
          first: () async {
            // Adopt the background-warmed first page when it is this view.
            if (!byDistance) {
              final warm = await ExternalEventsPreloader.instance.take(
                  'ticketmaster',
                  sort: 'date',
                  country: country);
              if (warm != null) {
                pager = warm.pager;
                return warm.items;
              }
            }
            final page = await pager.next();
            unawaited(pager.saveFirstPage(page));
            return page;
          },
          next: () => pager.next(),
          hasMore: () => pager.hasMore,
          id: (e) => e.id,
          map: _mergedPartner,
        );
      },
      filter: _matchesMergedFilters,
      compare: byDistance
          ? (a, b) => compareNearestThenSoonest(a.key, b.key)
          : (a, b) => compareSoonestThenNearest(a.key, b.key),
      gridView: _gridView,
      // First screen in one go: covers of the first viewport decoded first.
      firstScreenImage: (context, x, grid, _) {
        final e = x.community;
        return e != null
            ? eventCoverImageProvider(context, e, grid: grid)
            : externalEventImageProvider(context, x.partner!, grid: grid);
      },
      itemBuilder: (context, x, grid) {
        final e = x.community;
        if (e != null) {
          return grid
              ? _buildEventGridTile(e)
              : EventCard(
                  event: e,
                  currentUserId: widget.currentUserId,
                  onTap: () => _showEventDetails(e),
                  onRSVP: (status) => _handleRSVP(e, status),
                );
        }
        final p = x.partner!;
        void open() => showAttractionMenu(context,
            event: p, currentUserId: widget.currentUserId);
        return grid
            ? ExternalEventGridTile(
                event: p, onTap: open, showPartnerBadge: true)
            : ExternalEventCard(event: p, onTap: open, showPartnerBadge: true);
      },
      emptyBuilder: (_) => _buildNoEventsState(),
      onRefresh: () async {
        _eventsDataSource.invalidateUserEvents(widget.currentUserId);
        unawaited(_loadUpcomingFallback());
        _eventsBloc.add(LoadUserEvents(userId: widget.currentUserId));
        await _loadCommunityNearby(force: true);
      },
    );
  }

  /// "+" in the app bar: choose between creating an event or an experience.
  void _showCreateChooser(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) {
        Widget option(
                IconData icon, String title, String desc, VoidCallback onTap) =>
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.richGold.withValues(alpha: 0.15),
                child: Icon(icon, color: AppColors.richGold),
              ),
              title: Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              subtitle: Text(desc,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              trailing:
                  const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              onTap: () {
                Navigator.pop(sheet);
                onTap();
              },
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    l.createChooserTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                option(Icons.event, l.eventsCreateEvent,
                    l.createChooserEventDesc,
                    () => _showCreateEventDialog(context)),
                option(Icons.travel_explore, l.uexpCreate,
                    l.createChooserExperienceDesc, _createExperience),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Create an experience through the tier gate (Free → upgrade prompt), then
  /// refresh the Experiences lists so it shows up.
  Future<void> _createExperience() async {
    final ok = await ExperienceCreationGate(
            repository: sl<UserExperiencesRepository>())
        .ensureCanCreate(context, widget.currentUserId);
    if (!ok || !mounted) return;
    final saved = await Navigator.of(context).push(
        ExperienceEditorScreen.route(currentUserId: widget.currentUserId));
    if (saved != null && mounted) setState(() => _expReloadTick++);
  }

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

/// Decode width (physical px) of a community event cover: the grid tile
/// ([grid], one of [eventsGridColumns] per row) or the full-width [EventCard].
/// Shared by the tiles and [eventCoverImageProvider] so a first-screen
/// precache hits the SAME ImageCache entry the tile paints.
int eventCoverMemCacheWidth(BuildContext context, {required bool grid}) {
  final mq = MediaQuery.of(context);
  final cols = grid ? eventsGridColumns(context) : 1;
  return (mq.size.width / cols * mq.devicePixelRatio).round();
}

/// The exact provider the grid tile ([grid]) / [EventCard] paints for [e]'s
/// cover, or null when it has none.
ImageProvider? eventCoverImageProvider(BuildContext context, Event e,
    {required bool grid}) {
  final url = e.imageUrl;
  if (url == null || url.isEmpty) return null;
  return cachedNetworkImageProvider(url,
      memCacheWidth: eventCoverMemCacheWidth(context, grid: grid));
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
/// Keeps an Events sub-tab mounted while the user swipes to another one, so
/// its scroll position and loaded data survive.
class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});
  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

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
                        ? CachedNetworkImage(
                            imageUrl: event.imageUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth:
                                eventCoverMemCacheWidth(context, grid: false),
                            errorWidget: (_, __, ___) => const Icon(
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
                  if (event.organizerName.trim().isNotEmpty &&
                      event.organizerName != 'Current User') ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AppColors.richGold,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!
                                .eventsByOrganizer(event.organizerName.trim()),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.richGold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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

  /// Report another user's event: confirm, write a `reports` doc, hide it from
  /// this viewer's lists immediately, and leave the screen.
  Future<void> _reportEvent(BuildContext context, Event event) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final bloc = context.read<EventsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.eventReportTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.eventReportBody,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.eventReport,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'type': 'event',
        'eventId': event.id,
        'organizerId': event.organizerId,
        'eventTitle': event.title,
        'reporterId': currentUserId,
        'reportedAt': Timestamp.fromDate(DateTime.now()),
        'status': 'pending',
      });
      bloc.add(HideEvent(eventId: event.id));
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.eventReported),
        backgroundColor: AppColors.errorRed,
      ));
      if (navigator.canPop()) navigator.pop();
    } catch (e, st) {
      if (context.mounted) showUserError(context, e, stackTrace: st);
    }
  }

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
                  ? CachedNetworkImage(
                      imageUrl: event.imageUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: (MediaQuery.of(context).size.width *
                              MediaQuery.of(context).devicePixelRatio)
                          .round(),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.backgroundCard,
                        child: const Icon(
                          Icons.event,
                          size: 80,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    )
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
              // Check-in scanner — creator + co-owners, and only while the
              // event is still running: checking someone in afterwards records
              // an arrival that did not happen.
              if (event.isOwner(currentUserId) && !event.hasEnded)
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
              // Attendance list — creator + co-owners
              if (event.isOwner(currentUserId) && !event.hasEnded)
                IconButton(
                  icon: const Icon(Icons.fact_check_outlined,
                      color: AppColors.richGold),
                  tooltip: AppLocalizations.of(context)!.eventAttendance,
                  onPressed: () => Navigator.of(context).push(
                    EventAttendanceScreen.route(event: event),
                  ),
                ),
              // Edit — creator + co-owners (deleting stays creator-only).
              // Editing a finished event changes nothing anyone can act on.
              if (event.isOwner(currentUserId) && !event.hasEnded)
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
                            // Only the creator may delete the event.
                            onEventDeleted: event.isCreator(currentUserId)
                                ? () {
                                    bloc.add(DeleteEvent(eventId: event.id));
                                    // Pop edit screen + the detail screen.
                                    Navigator.of(ctx).pop();
                                    Navigator.of(context).pop();
                                  }
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // Boost (feature) — CREATOR only (spends their coins), if not
              // already featured. Co-owners cannot boost.
              if (event.isOwner(currentUserId) &&
                  !event.isCurrentlyFeatured)
                IconButton(
                  icon: const Icon(Icons.rocket_launch,
                      color: AppColors.richGold),
                  tooltip: AppLocalizations.of(context)!.eventsBoost,
                  onPressed: () => _handleBoost(context, event),
                ),
              // Report — only on OTHER people's events.
              if (!event.isOwner(currentUserId))
                IconButton(
                  icon: const Icon(Icons.flag_outlined,
                      color: AppColors.textTertiary),
                  tooltip: AppLocalizations.of(context)!.eventReport,
                  onPressed: () => _reportEvent(context, event),
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
                onPressed: () {
                  // Open at once: the chat screen resolves the sender's real
                  // name itself (UserDirectoryService); pass what is already
                  // known as the fallback.
                  final known = UserDirectoryService.instance
                      .nameFor(currentUserId)
                      .trim();
                  final name = known.isNotEmpty ? known : 'User';
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventChatScreen(
                        event: event,
                        currentUserId: currentUserId,
                        currentUserName: name,
                        viewerLanguage:
                            Localizations.localeOf(context).languageCode,
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
                  TranslatableText(
                    text: event.title,
                    autoTranslate: true,
                    targetLang:
                        Localizations.localeOf(context).languageCode,
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
                  // Who is behind this event - everyone who can see it can
                  // see its organiser.
                  EventOrganizerRow(
                    event: event,
                    currentUserId: currentUserId,
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
                  TranslatableText(
                    text: event.description,
                    autoTranslate: true,
                    targetLang:
                        Localizations.localeOf(context).languageCode,
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
                            viewerLanguage:
                                Localizations.localeOf(context).languageCode,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.eventsAttendees,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // The strip below previews only the first 100; this opens
                      // the full, endlessly-scrolling list.
                      // Two gates, and both matter: the organiser's setting
                      // decides whether this viewer may see the roster at all,
                      // and each attendee's own privacy decides whether they
                      // appear in it.
                      if (event.canViewAttendeeList(currentUserId) &&
                          event.attendees.any((a) =>
                              a.status == RSVPStatus.going &&
                              a.isVisibleTo(currentUserId,
                                  event.organizerViewIdFor(currentUserId))))
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            EventAttendeesScreen.route(
                              event: event,
                              currentUserId: currentUserId,
                            ),
                          ),
                          style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: AppColors.richGold),
                          child: Text(
                            AppLocalizations.of(context)!.attendeesSeeAll,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    // Respect attendee privacy: hide invisible / organizer-only
                    // attendees from everyone except themselves and the organizer.
                    // Show only the first 100 going attendees.
                    final visibleGoing = event.attendees
                        .where((a) =>
                            a.status == RSVPStatus.going &&
                            a.isVisibleTo(currentUserId,
                                event.organizerViewIdFor(currentUserId)))
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
                      // Paint at once from the attendee docs; photos fill in
                      // as the (batched, cached) directory resolves.
                      child: ListenableBuilder(
                        listenable: UserDirectoryService.instance,
                        builder: (context, _) {
                          final directory = UserDirectoryService.instance;
                          final missing = visibleGoing
                              .map((a) => a.userId)
                              .where((u) => !directory.isResolved(u))
                              .toList();
                          if (missing.isNotEmpty) directory.resolve(missing);
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: visibleGoing.length,
                            itemBuilder: (context, index) {
                              final attendee = visibleGoing[index];
                              final name = attendee.displayNameFor(
                                  currentUserId,
                                  event.organizerViewIdFor(currentUserId));
                              final anon = attendee.isAnonymous &&
                                  currentUserId != attendee.userId &&
                                  !event.isOwner(currentUserId);
                              final photo = anon
                                  ? null
                                  : (attendee.userPhotoUrl ??
                                      directory
                                          .cached(attendee.userId)
                                          ?.photoUrl);
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
                final label = event.hasEnded
                    ? l10n.eventsEnded
                    : isGoing
                    ? l10n.eventsGoingLabel
                    : isWaitlisted
                        ? l10n.eventsOnWaitlist
                        : event.isFull
                            ? l10n.eventsJoinWaitlist
                            : l10n.eventsJoinEvent;
                // A finished event cannot be joined, however the button
                // would otherwise read.
                final enabled = !isGoing && !isWaitlisted && !event.hasEnded;
                // Paid events are sold as tickets (Stripe / MP / organizer link);
                // a paid event without a sale mode is not on sale yet.
                if (!event.isFree) {
                  final organizer = event.isOwner(currentUserId);
                  final onSale = event.sellsTickets && !event.hasEnded;
                  return Expanded(
                    child: ElevatedButton(
                      key: const ValueKey('event-buy-ticket'),
                      onPressed: organizer
                          ? () => Navigator.of(context).push(GetPaidScreen.route(currentUserId))
                          : (onSale
                              ? () => BuyTicketSheet.show(context, event: event, uid: currentUserId)
                              : null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.deepBlack,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        organizer
                            ? l10n.tpGetPaidTitle
                            : (event.hasEnded
                                ? l10n.eventsEnded
                                : (onSale
                                    ? (isGoing ? l10n.tpBuyMoreTickets : l10n.tpBuyTickets)
                                    : l10n.tpNotOnSaleYet)),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
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

  /// Join an event: reserve a spot via a capacity-safe Firestore transaction
  /// (waitlisting when full), and — only when actually admitted as "going" —
  /// spend coins for a paid event. Events are single general admission: there
  /// are no ticket tiers to pick, even on older events that still carry them.
  Future<void> _handleJoin(BuildContext context, Event event) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<EventsBloc>();
    final ds = sl<EventsRemoteDataSource>();

    final cost = event.isFree ? 0 : (event.price ?? 0).round();

    // Pre-check affordability for paid joins so we rarely have to roll back.
    if (cost > 0) {
      final afford =
          await sl<CanAffordFeature>()(userId: currentUserId, cost: cost);
      if (!context.mounted) return;
      if (!afford.fold((_) => false, (v) => v)) {
        unawaited(showUserErrorMessage(context, l10n.eventsInsufficientCoins));
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
      );
    } catch (e) {
      reportUserError(e);
      if (context.mounted) {
        unawaited(showUserErrorMessage(context, l10n.eventsRsvpError));
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
            unawaited(
                showUserErrorMessage(context, l10n.eventsInsufficientCoins));
          }
          return;
        }
      }
      if (context.mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text(l10n.eventsRsvpUpdated)));
      }
    }

    // Refresh "My events" (we wrote directly, bypassing the RSVP bloc event;
    // the datasource dropped its memo on the write).
    bloc.add(LoadUserEvents(userId: currentUserId));
    if (context.mounted) Navigator.pop(context);
  }

  /// Organizer-only "Feature this event" placement section shown on the detail
  /// screen. When active, shows "Featured until …"; otherwise shows a paid
  /// call-to-action that spends coins to feature the event for 7 days.
  Widget _buildFeaturedSection(BuildContext context, Event event) {
    // Any owner (creator or co-owner) may boost, paying with their own coins.
    if (!event.isOwner(currentUserId)) {
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
    // The server prices the option (duration in hours) and sets
    // isFeatured / featuredUntil in the same transaction as the debit.
    final charge = await sl<PurchaseFeature>()(
      userId: currentUserId,
      featureName: 'event_boost',
      cost: cost,
      relatedId: event.id,
      option: duration.inHours,
    );
    if (!context.mounted) return;
    if (!charge.fold((_) => false, (_) => true)) {
      unawaited(showUserErrorMessage(context, l10n.eventsInsufficientCoins));
      return;
    }
    final serverUntil = charge.fold((_) => null, (txn) {
      final effect = txn.metadata?['effect'];
      final ms = effect is Map ? effect['featuredUntil'] : null;
      return ms is num ? DateTime.fromMillisecondsSinceEpoch(ms.toInt()) : null;
    });
    bloc.add(UpdateEvent(
      event: event.copyWith(
        isFeatured: true,
        featuredUntil: serverUntil ?? DateTime.now().add(duration),
      ),
    ));
    if (!context.mounted) return;
    await BoostCelebration.show(
      context,
      title: l10n.boostEventCelebrationTitle,
      subtitle: l10n.eventBoostEndsIn(_boostDurationLabel(l10n, duration)),
    );
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

  static final Map<String, ({Future<int> pos, DateTime at})> _waitlistMemo =
      {};

  static Future<int> _waitlistPosition(String eventId, String userId) {
    final key = '$eventId|$userId';
    final hit = _waitlistMemo[key];
    if (hit != null &&
        DateTime.now().difference(hit.at) < const Duration(seconds: 30)) {
      return hit.pos;
    }
    if (_waitlistMemo.length > 50) _waitlistMemo.clear();
    final f = sl<EventsRemoteDataSource>().getWaitlistPosition(eventId, userId);
    _waitlistMemo[key] = (pos: f, at: DateTime.now());
    return f;
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
        // Memoised per event/user: a rebuild must not re-run the query.
        future: _waitlistPosition(event.id, currentUserId),
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
  // Paid tickets: how buyers pay (instant Stripe / MP or manual link).
  TicketPaymentChoice _ticket = const TicketPaymentChoice();
  final _maxPerUserController = TextEditingController(text: '4');
  String _currency = '\$';
  static const List<String> _currencies = ['\$', '€', '£', 'R\$', '¥'];
  EventVisibility _visibility = EventVisibility.public;
  AttendeeListVisibility _attendeeListVisibility =
      AttendeeListVisibility.participants;
  bool _isUnlimited = false;
  // Guests each attendee may bring (0 = guests not allowed). Feeds QR check-in.
  int _guestsAllowedPerAttendee = 0;
  static const int _maxGuestsAllowed = 10;
  double? _lat;
  double? _lng;
  String? _pickedCity;
  String? _pickedCountry;
  // The location text the coordinates above belong to (the last map pick, or
  // the saved event's name when editing). When the organiser types something
  // else, the typed text is geocoded on save instead of reusing stale coords.
  String? _coordsLabel;

  // ---- Co-owners (creator-managed; max kMaxEventCoOrganizers) ----
  final List<String> _coOwnerIds = [];
  final Map<String, UserBrief> _coOwnerBriefs = {};
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

  /// Only the event's creator manages co-owners (a co-owner editing the event
  /// sees them read-only).
  bool get _canManageCoOwners =>
      !_isEditing || widget.existing!.isCreator(widget.currentUserId);

  Future<void> _resolveCoOwnerBriefs() async {
    final missing =
        _coOwnerIds.where((id) => !_coOwnerBriefs.containsKey(id)).toList();
    if (missing.isEmpty) return;
    final briefs = await UserDirectoryService.instance.resolve(missing);
    if (!mounted) return;
    setState(() => _coOwnerBriefs.addAll(briefs));
  }

  Future<void> _addCoOwner() async {
    if (!_canManageCoOwners) return;
    final l10n = AppLocalizations.of(context)!;
    if (_coOwnerIds.length >= kMaxEventCoOrganizers) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.eventsCoOwnerLimit(kMaxEventCoOrganizers))));
      return;
    }
    final creatorId = widget.existing?.organizerId ?? widget.currentUserId;
    final picked = await showCoOwnerPicker(
      context,
      currentUserId: widget.currentUserId,
      excludeIds: {creatorId, ..._coOwnerIds},
    );
    if (picked == null || !mounted) return;
    if (_coOwnerIds.contains(picked.userId) ||
        _coOwnerIds.length >= kMaxEventCoOrganizers) {
      return;
    }
    setState(() {
      _coOwnerIds.add(picked.userId);
      _coOwnerBriefs[picked.userId] =
          UserBrief(name: picked.name, photoUrl: picked.photoUrl);
    });
  }

  /// "Co-owners" section: chips (avatar + name), removable by the creator,
  /// plus "Add co-owner" (nickname search / recent chats).
  Widget _buildCoOwnersSection() {
    final l10n = AppLocalizations.of(context)!;
    final canManage = _canManageCoOwners;
    if (!canManage && _coOwnerIds.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.eventsCoOwners,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            canManage
                ? l10n.eventsCoOwnersHelper
                : l10n.eventsCoOwnersCreatorOnly,
            style: const TextStyle(
                color: AppColors.textTertiary, fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in _coOwnerIds) _coOwnerChip(id, canManage, l10n),
              if (canManage && _coOwnerIds.length < kMaxEventCoOrganizers)
                ActionChip(
                  backgroundColor: AppColors.backgroundCard,
                  avatar: const Icon(Icons.person_add_alt_1,
                      size: 18, color: AppColors.richGold),
                  label: Text(l10n.eventsAddCoOwner,
                      style: const TextStyle(color: AppColors.richGold)),
                  onPressed: _addCoOwner,
                ),
            ],
          ),
          if (canManage && _coOwnerIds.length >= kMaxEventCoOrganizers)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.eventsCoOwnerLimit(kMaxEventCoOrganizers),
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _coOwnerChip(String id, bool canManage, AppLocalizations l10n) {
    final b = _coOwnerBriefs[id];
    // Never show a raw id: an unresolved name renders as an ellipsis.
    final resolved = b?.name.trim() ?? '';
    final name = resolved.isNotEmpty ? resolved : '\u2026';
    final photo = b?.photoUrl;
    final hasPhoto = photo != null && photo.isNotEmpty;
    return InputChip(
      backgroundColor: AppColors.backgroundCard,
      avatar: CircleAvatar(
        backgroundColor: AppColors.backgroundInput,
        backgroundImage: hasPhoto ? CachedNetworkImageProvider(photo) : null,
        child: hasPhoto
            ? null
            : Text(name[0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textPrimary)),
      ),
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
          child: Text(name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary)),
        ),
        if (UserVerifiedBadge.isVisible(b))
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: VerifiedBadge(size: 14),
          ),
      ]),
      deleteIconColor: AppColors.textSecondary,
      deleteButtonTooltipMessage: l10n.eventsCoOwnerRemove,
      onDeleted:
          canManage ? () => setState(() => _coOwnerIds.remove(id)) : null,
    );
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerDraft());
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
    _ticket = TicketPaymentChoice(
      provider: TicketProvider.fromWire(e.ticketProvider),
      linkMethod: e.ticketLinkMethod,
      instructions: e.ticketPaymentInstructions,
    );
    _maxPerUserController.text = e.maxTicketsPerUser?.toString() ?? '';
    _visibility = e.visibility;
    _attendeeListVisibility = e.attendeeListVisibility;
    _isUnlimited = e.isUnlimited;
    _guestsAllowedPerAttendee = e.guestsAllowedPerAttendee;
    if (!e.isUnlimited) _maxAttendeesController.text = e.maxAttendees.toString();
    _lat = e.latitude;
    _lng = e.longitude;
    _pickedCity = e.city;
    _pickedCountry = e.country;
    _coordsLabel = e.locationName;
    _coOwnerIds.addAll(e.coOrganizerIds);
    _resolveCoOwnerBriefs();
    _externalLinks.addAll(e.externalLinks);
    if (e.languagePairs != null) _languagePairsController.text = e.languagePairs!;
    // Show already-uploaded images in the edit form.
    _existingMainUrl = e.imageUrl;
    _existingPhotoUrls.addAll(e.photoUrls);
    // Prefill recurrence + schedule so editing preserves them.
    if (e.recurrence != null) {
      _recurFreq = e.recurrence!.frequency;
      _recurInterval = e.recurrence!.safeInterval;
      _recurCount = e.recurrence!.safeCount;
    }
    _publishAt = e.publishAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxAttendeesController.dispose();
    _maxPerUserController.dispose();
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
      _coordsLabel = loc.displayAddress;
    });
  }

  /// Location as saved: the typed text, plus coordinates when they still
  /// belong to it. If the organiser typed a new place after (or instead of) a
  /// map pick, geocode the text; if that fails the text is saved with NO
  /// coordinates (still a valid event, just not in nearest-first lists).
  Future<_EventPlace> _resolveLocationForSave() async {
    final text = _locationController.text.trim();
    final label = _coordsLabel?.trim();
    if (_lat != null && _lng != null && label != null && label == text) {
      return _EventPlace(
        lat: _lat,
        lng: _lng,
        city: _pickedCity,
        country: _pickedCountry,
        manual: false,
      );
    }
    final loc = await EventGeocoder.geocode(text);
    if (loc == null) return const _EventPlace(manual: true);
    // Remember the result so a retried save doesn't geocode again.
    _lat = loc.latitude;
    _lng = loc.longitude;
    _pickedCity = loc.city.isNotEmpty ? loc.city : null;
    _pickedCountry = loc.country.isNotEmpty ? loc.country : null;
    _coordsLabel = text;
    return _EventPlace(
      lat: _lat,
      lng: _lng,
      city: _pickedCity,
      country: _pickedCountry,
      manual: true,
    );
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
        child: ListingWizard(
          editMode: _isEditing,
          controller: _wizard,
          onStepChanged: (_) => _autosaveDraft(),
          steps: [
            WizardStep(
              title: AppLocalizations.of(context)!.wzEventBasics,
              icon: Icons.edit_note,
              error: _basicsError,
              summary: () => _titleController.text,
              builder: (context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
              ]),
            ),
            WizardStep(
              title: AppLocalizations.of(context)!.wzWhenWhere,
              icon: Icons.place_outlined,
              error: _whereError,
              summary: () => '${DateFormat('EEE, MMM d \u2022 h:mm a').format(_startDate)} · ${_locationController.text}',
              builder: (context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Typed by hand (venue / address) OR picked on the map.
            TextFormField(
              controller: _locationController,
              style: const TextStyle(color: AppColors.textPrimary),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                      AppLocalizations.of(context)!.eventsLocation)
                  .copyWith(
                helperText: AppLocalizations.of(context)!.eventsLocationHelper,
                helperStyle: const TextStyle(color: AppColors.textTertiary),
                helperMaxLines: 2,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_outlined,
                      color: AppColors.richGold),
                  tooltip: AppLocalizations.of(context)!.eventsPickOnMap,
                  onPressed: _pickLocation,
                ),
              ),
              validator: (v) => (v?.trim().isEmpty ?? true)
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
            _buildRecurrenceSection(),
            const SizedBox(height: 16),
            // Link to a community (owner/admin communities only). Hidden when the
            // community is fixed by the caller (opened from a community's Events
            // tab) or when the user manages no communities.
            _buildCoOwnersSection(),
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
            const SizedBox(height: 8),
            // Who may see WHO IS COMING - a separate decision from who may see
            // the event. An event can be open to all while its guest list is
            // not.
            Text(
              AppLocalizations.of(context)!.eventsAttendeeListVisibility,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            SegmentedButton<AttendeeListVisibility>(
              segments: [
                ButtonSegment(
                  value: AttendeeListVisibility.private,
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: Text(AppLocalizations.of(context)!
                      .eventsAttendeeListPrivate),
                ),
                ButtonSegment(
                  value: AttendeeListVisibility.participants,
                  icon: const Icon(Icons.groups_outlined, size: 18),
                  label: Text(AppLocalizations.of(context)!
                      .eventsAttendeeListParticipants),
                ),
                ButtonSegment(
                  value: AttendeeListVisibility.public,
                  icon: const Icon(Icons.public, size: 18),
                  label: Text(AppLocalizations.of(context)!
                      .eventsAttendeeListPublic),
                ),
              ],
              selected: {_attendeeListVisibility},
              showSelectedIcon: false,
              onSelectionChanged: (sel) =>
                  setState(() => _attendeeListVisibility = sel.first),
            ),
            const SizedBox(height: 6),
            Text(
              switch (_attendeeListVisibility) {
                AttendeeListVisibility.private =>
                  AppLocalizations.of(context)!.eventsAttendeeListPrivateHint,
                AttendeeListVisibility.participants => AppLocalizations.of(
                    context)!
                    .eventsAttendeeListParticipantsHint,
                AttendeeListVisibility.public =>
                  AppLocalizations.of(context)!.eventsAttendeeListPublicHint,
              },
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                height: 1.3,
              ),
            ),
              ]),
            ),
            WizardStep(
              title: AppLocalizations.of(context)!.wzTickets,
              icon: Icons.confirmation_number_outlined,
              error: _ticketsError,
              summary: () => _isFree
                  ? AppLocalizations.of(context)!.eventsFreeEvent
                  : '$_currency${_priceController.text} · ${_isUnlimited ? '\u221e' : _maxAttendeesController.text}',
              builder: (context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
                    AppLocalizations.of(context)!.eventsCapacityAllowed),
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
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('event-max-per-user'),
                controller: _maxPerUserController,
                style: const TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                    AppLocalizations.of(context)!.tpMaxTicketsPerUser),
              ),
            ],
            if (!_isFree && _isEditing) ...[
              if (_isEditing)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(TicketTypesScreen.route(
                        widget.existing!.id, isoCurrencyFor(_currency) ?? 'usd')),
                    icon: const Icon(Icons.style_outlined, color: AppColors.richGold),
                    label: Text(AppLocalizations.of(context)!.tpTicketTypes),
                  ),
                ),
            ],
              ]),
            ),
            WizardStep(
              title: AppLocalizations.of(context)!.wzPayment,
              icon: Icons.payments_outlined,
              skip: _isFree,
              error: _paymentError,
              summary: () => _ticket.provider == null
                  ? '—'
                  : TicketL10n.provider(AppLocalizations.of(context)!, _ticket.provider!),
              builder: (context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TicketPaymentSelector(
                uid: widget.currentUserId,
                value: _ticket,
                onChanged: (c) => setState(() => _ticket = c),
                capacity: _isUnlimited ? null : int.tryParse(_maxAttendeesController.text),
                price: double.tryParse(_priceController.text),
                currency: _currency,
              ),
              ]),
            ),
            WizardStep(
              title: AppLocalizations.of(context)!.wzReview,
              icon: Icons.fact_check_outlined,
              builder: (context) => _buildReview(),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Wizard: per-step validation, review, local draft ----
  final ListingWizardController _wizard = ListingWizardController();

  String? _basicsError() {
    final l = AppLocalizations.of(context)!;
    if (_titleController.text.trim().isEmpty) return l.wzErrTitle;
    if (_descriptionController.text.trim().isEmpty) return l.wzErrDescription;
    return null;
  }

  String? _whereError() {
    final l = AppLocalizations.of(context)!;
    if (_locationController.text.trim().isEmpty) return l.wzErrLocation;
    if (!_endDate.isAfter(_startDate)) return l.wzErrDates;
    return null;
  }

  String? _ticketsError() {
    final l = AppLocalizations.of(context)!;
    if (!_isUnlimited) {
      final c = int.tryParse(_maxAttendeesController.text.trim());
      if (c == null || c < 1) return l.wzErrCapacity;
    }
    if (!_isFree) {
      final n = int.tryParse(_priceController.text.trim());
      if (n == null || n < 1 || n > 1000) return l.eventsPriceRange;
    }
    return null;
  }

  String? _paymentError() {
    if (_isFree) return null;
    if (!_ticket.isComplete || needsReconnect(_ticket)) {
      return AppLocalizations.of(context)!.tpChooseHowToGetPaid;
    }
    return null;
  }

  Widget _buildReview() {
    final l = AppLocalizations.of(context)!;
    final checks = <(String, bool, VoidCallback?)>[
      if (_basicsError() != null) (_basicsError()!, true, () => _wizard.goTo(0)),
      if (_whereError() != null) (_whereError()!, true, () => _wizard.goTo(1)),
      if (_ticketsError() != null) (_ticketsError()!, true, () => _wizard.goTo(2)),
      if (_paymentError() != null) (_paymentError()!, true, () => _wizard.goTo(3)),
      if (_mainPhoto == null && (_existingMainUrl ?? '').isEmpty)
        (l.wzWarnNoPhoto, false, () => _wizard.goTo(0)),
      if (!_isFree && _ticket.provider == TicketProvider.link && (_isUnlimited || (int.tryParse(_maxAttendeesController.text) ?? 0) >= kLargeAudienceThreshold))
        (l.wzWarnManualLarge, false, _isFree ? null : () => _wizard.goTo(3)),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.wzPreviewTitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
      const SizedBox(height: 6),
      Card(
        key: const ValueKey('event-review-preview'),
        color: AppColors.backgroundCard,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_titleController.text.isEmpty ? '—' : _titleController.text,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(DateFormat('EEE, MMM d yyyy \u2022 h:mm a').format(_startDate),
                style: const TextStyle(color: AppColors.textSecondary)),
            Text(_locationController.text, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text(_isFree ? l.eventsFreeLabel : '$_currency${_priceController.text}',
                style: const TextStyle(color: AppColors.richGold, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      WizardChecklist(items: checks),
      const SizedBox(height: 16),
      _buildSaveActions(),
    ]);
  }

  WizardDraftStore get _draftStore => WizardDraftStore('wizard_event_${widget.currentUserId}');

  Map<String, dynamic> _draftMap() => {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _category.name,
        'location': _locationController.text,
        'start': _startDate.millisecondsSinceEpoch,
        'end': _endDate.millisecondsSinceEpoch,
        'isFree': _isFree,
        'price': _priceController.text,
        'currency': _currency,
        'unlimited': _isUnlimited,
        'capacity': _maxAttendeesController.text,
        'maxPerUser': _maxPerUserController.text,
        'guests': _guestsAllowedPerAttendee,
        'provider': _ticket.provider?.wire,
        'linkMethod': _ticket.linkMethod,
      };

  void _restoreDraft(Map<String, dynamic> d) {
    setState(() {
      _titleController.text = d['title'] as String? ?? '';
      _descriptionController.text = d['description'] as String? ?? '';
      _category = EventCategory.values.firstWhere((c) => c.name == d['category'], orElse: () => _category);
      _locationController.text = d['location'] as String? ?? '';
      final st = d['start'] as int?;
      final en = d['end'] as int?;
      if (st != null && DateTime.fromMillisecondsSinceEpoch(st).isAfter(DateTime.now())) {
        _startDate = DateTime.fromMillisecondsSinceEpoch(st);
        if (en != null) _endDate = DateTime.fromMillisecondsSinceEpoch(en);
      }
      _isFree = d['isFree'] as bool? ?? true;
      _priceController.text = d['price'] as String? ?? _priceController.text;
      _currency = _currencies.contains(d['currency']) ? d['currency'] as String : _currency;
      _isUnlimited = d['unlimited'] as bool? ?? false;
      _maxAttendeesController.text = d['capacity'] as String? ?? _maxAttendeesController.text;
      _maxPerUserController.text = d['maxPerUser'] as String? ?? _maxPerUserController.text;
      _guestsAllowedPerAttendee = (d['guests'] as int?) ?? 0;
      _ticket = TicketPaymentChoice(
          provider: TicketProvider.fromWire(d['provider']), linkMethod: d['linkMethod'] as String?);
    });
  }

  Future<void> _autosaveDraft() async {
    if (_isEditing) return;
    await _draftStore.write(_draftMap());
  }

  Future<void> _offerDraft() async {
    if (_isEditing) return;
    final d = await _draftStore.read();
    if (d == null || !mounted) return;
    if (await WizardDraftStore.askResume(context)) {
      _restoreDraft(d);
    } else {
      await _draftStore.clear();
    }
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
    } catch (e) {
      reportUserError(e);
      if (mounted) {
        unawaited(showUserErrorMessage(context, l10n.eventsSeriesCancelError));
      }
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
      unawaited(showUserErrorMessage(
          context, AppLocalizations.of(context)!.eventTextProhibited));
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
          unawaited(showUserErrorMessage(context, l10n.eventsInsufficientCoins));
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
          unawaited(showUserErrorMessage(
              context, AppLocalizations.of(context)!.photoExplicitContent));
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

    // Location: typed text + coordinates (map pick, or geocoded from text).
    setState(() => _saving = true);
    final place = await _resolveLocationForSave();
    if (!mounted) return;
    setState(() => _saving = false);
    final locationText = _locationController.text.trim();
    final noCoords = place.lat == null || place.lng == null;
    if (noCoords) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.eventsLocationNotOnMap)));
    }
    // Creator-managed co-owner list (never the creator, max 5).
    final creatorId = widget.existing?.organizerId ?? widget.currentUserId;
    final coOwnerIds = _coOwnerIds
        .where((id) => id.isNotEmpty && id != creatorId)
        .toSet()
        .take(kMaxEventCoOrganizers)
        .toList();

    final maxAttendees =
        _isUnlimited ? 0 : (int.tryParse(_maxAttendeesController.text) ?? 20);
    if (!_isFree && (!_ticket.isComplete || needsReconnect(_ticket))) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.tpChooseHowToGetPaid)));
      return;
    }
    final maxPerUser = int.tryParse(_maxPerUserController.text.trim());
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
      // status/publishAt; only update editable fields. Events are now single
      // general-admission (no priced tiers) gated by the capacity field.
      final event = widget.existing!.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        imageUrl: imageUrl,
        photoUrls: photoUrls,
        startDate: _startDate,
        endDate: _endDate,
        locationName: locationText,
        address: place.manual ? locationText : null,
        latitude: place.lat,
        longitude: place.lng,
        city: place.city,
        country: place.country,
        clearCoordinates: noCoords,
        // Only the creator changes co-owners; a co-owner's edit keeps them.
        coOrganizerIds: _canManageCoOwners ? coOwnerIds : null,
        maxAttendees: maxAttendees,
        price: price,
        currency: _isFree ? null : _currency,
        ticketProvider: _isFree ? null : _ticket.provider?.wire,
        ticketLinkMethod: _ticket.provider == TicketProvider.link ? _ticket.linkMethod : null,
        ticketPaymentInstructions:
            _ticket.provider == TicketProvider.link ? _ticket.instructions : null,
        currencyCode: _isFree ? null : isoCurrencyFor(_currency),
        clearTicketing: _isFree,
        maxTicketsPerUser: maxPerUser == 0 ? null : maxPerUser,
        clearMaxTicketsPerUser: maxPerUser == null || maxPerUser == 0,
        visibility: _visibility,
        attendeeListVisibility: _attendeeListVisibility,
        externalLinks: _externalLinks,
        languagePairs: languagePairs,
        guestsAllowedPerAttendee: _guestsAllowedPerAttendee,
        ticketTiers: const [],
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
      locationName: locationText,
      address: place.manual ? locationText : null,
      latitude: place.lat,
      longitude: place.lng,
      city: place.city,
      country: place.country,
      coOrganizerIds: coOwnerIds,
      maxAttendees: maxAttendees,
      price: price,
      currency: _isFree ? null : _currency,
      ticketProvider: _isFree ? null : _ticket.provider?.wire,
      ticketLinkMethod: _ticket.provider == TicketProvider.link ? _ticket.linkMethod : null,
      ticketPaymentInstructions:
          _ticket.provider == TicketProvider.link ? _ticket.instructions : null,
      currencyCode: _isFree ? null : isoCurrencyFor(_currency),
      maxTicketsPerUser: maxPerUser == 0 ? null : maxPerUser,
      visibility: _visibility,
      attendeeListVisibility: _attendeeListVisibility,
      externalLinks: _externalLinks,
      status: status,
      publishAt: status == EventStatus.scheduled ? publishAt : null,
      recurrence: recurrence.isRecurring ? recurrence : null,
      ticketTiers: const [],
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
      unawaited(_draftStore.clear());
      widget.onEventCreated(occurrences.first);
      return;
    }

    unawaited(_draftStore.clear());
    widget.onEventCreated(base);
  }
}

/// Where an event is, as resolved on save: coordinates (+ city/country) when
/// known, and whether the location text was typed by hand ([manual]).
class _EventPlace {
  const _EventPlace({
    required this.manual,
    this.lat,
    this.lng,
    this.city,
    this.country,
  });
  final double? lat;
  final double? lng;
  final String? city;
  final String? country;
  final bool manual;
}

/// One row of the Events "All" feed: a community event or a partner
/// (ticketmaster) live event, with its merge key.
class _MergedEvent {
  _MergedEvent.community(Event this.community, this.key) : partner = null;
  _MergedEvent.partner(ExternalEvent this.partner, this.key)
      : community = null;

  final Event? community;
  final ExternalEvent? partner;
  final FeedSortKey key;
}
