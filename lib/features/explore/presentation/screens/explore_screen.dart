import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/interaction_log_service.dart';
import '../../../../core/theme/app_glass.dart';
import '../../../../core/utils/country_flag_colors.dart';
import '../../../../core/utils/country_flag_helper.dart';
import '../../../../generated/app_localizations.dart';
import '../../../business/presentation/screens/business_storefront_screen.dart';
import '../../../chat/presentation/connect_and_chat.dart';
import '../../../chat/presentation/screens/conversations_screen.dart';
import '../../../coins/presentation/bloc/coin_bloc.dart';
import '../../../coins/presentation/bloc/coin_event.dart';
import '../../../coins/presentation/screens/coin_shop_screen.dart';
import '../../../communities/data/datasources/communities_remote_datasource.dart';
import '../../../communities/domain/entities/community.dart';
import '../../../communities/presentation/bloc/communities_bloc.dart';
import '../../../communities/presentation/screens/communities_screen.dart';
import '../../../communities/presentation/screens/community_detail_screen.dart';
import '../../../cultural_exchange/data/datasources/cultural_exchange_remote_datasource.dart';
import '../../../cultural_exchange/domain/entities/country_spotlight.dart';
import '../../../cultural_exchange/presentation/bloc/cultural_exchange_bloc.dart';
import '../../../cultural_exchange/presentation/screens/cultural_exchange_screen.dart';
import '../../../discovery/data/datasources/discovery_remote_datasource.dart';
import '../../../discovery/domain/entities/match_preferences.dart';
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../../../discovery/presentation/widgets/network_grid_card.dart';
import '../../../events/data/datasources/events_remote_datasource.dart';
import '../../../events/data/datasources/external_events_data_source.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/domain/entities/external_event.dart';
import '../../../events/presentation/screens/event_detail_loader_screen.dart';
import '../../../events/presentation/screens/events_screen.dart';
import '../../../events/presentation/widgets/attraction_menu_dialog.dart';
import '../../../globe_explore/presentation/bloc/globe_bloc.dart';
import '../../../globe_explore/presentation/screens/globe_screen.dart';
import '../../../matching/domain/entities/match_candidate.dart';
import '../../../matching/domain/entities/match_score.dart';
import '../../../matching/domain/usecases/feature_engineer.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../../passport/data/services/passport_service.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../profile/presentation/widgets/people_tags_editor.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';
import '../../../notifications/presentation/bloc/notifications_state.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../recommendations/recommendation_service.dart';
import 'network_discovery_screen.dart';
import 'qr_hub_screen.dart';
import 'universal_search_screen.dart';

/// Explore Screen — the Apple-safe home tab (tab 0) for the iOS flavor.
///
/// Track F / Phase 3 of APPLE_APPROVAL_PLAN_v3.0.0 (clearing Apple 4.3(b)).
/// A non-dating, discovery-first surface: a carousel of featured cultural
/// experiences, language-practice partners and experiences happening near the
/// user. Built entirely on the existing "liquid glass" design system ([AppGlass])
/// so it reads consistently against the app's gold-and-black brand.
///
/// Real data sources (no hardcoded content):
///  - **City / country**: the current user's `profiles/{userId}` document —
///    `location.city`, `location.country` and `primaryOrigin` (ISO alpha-2).
///  - **Experiences**: the shared [ExternalEventsDataSource] over the
///    `external_events` Firestore collection (cache-first, sample fallback).
///  - **Language partners**: other `profiles` that list `nativeLanguage` /
///    `languages` / `preferredLanguages`.
///  - **Backdrop band**: a flag-derived gradient from the user's country via
///    [CountryFlagColors].
///
/// Performance guardrail: frosted-glass blur is reserved for the structural
/// hero/featured cards only. List rows use solid charcoal surfaces with a
/// hairline border to keep scrolling cheap (see [AppGlass] docs).
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.userId});

  final String userId;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Last-resort default only — real city/country is loaded from the profile.
  static const String _defaultCity = 'Lisbon';

  /// Featured events/attractions are elected only from those within this many
  /// kilometres of the user (when the user has a known location). Adjustable.
  static const double kFeaturedRadiusKm = 50;

  /// Round-robin window (minutes) for the luxury "Featured community events"
  /// carousel. When more than 3 sponsored events are eligible, the visible
  /// window advances once per this many minutes so every sponsor gets fair
  /// exposure across refreshes while staying stable within the window (no
  /// reshuffle on every rebuild).
  static const int _luxuryRotationMinutes = 15;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Resolved from the user's profile.
  String? _city;
  String? _countryName;
  String? _countryCode; // ISO alpha-2 (primaryOrigin) when available
  double? _userLat;
  double? _userLng;
  String? _displayName; // for the personalized greeting
  // The current user's fully-parsed profile (for the recommendation heuristic);
  // null when the profile read failed or couldn't be parsed.
  Profile? _me;

  // Personalized stats header. Each value is null while loading (shimmer) and a
  // display string once resolved; on failure it resolves to '–' so the tile
  // stops shimmering rather than blocking the header.
  String? _coinsStat;
  String? _tierStat; // derived from the profile's membershipTier
  String? _countriesStat; // Cultural Passport country-stamp count
  String? _peopleStat; // distinct chat partners (all time)

  // null == still loading; empty == loaded but nothing to show.
  List<_Happening>? _happenings; // the "Happening this week" row
  // "Featured events": up to 3 random community/user-created events within
  // [kFeaturedRadiusKm] of the user. Hidden when empty.
  List<_Happening>? _featuredEvents;
  // "Featured attractions": up to 3 random external (geoapify) attractions near
  // the user. Hidden when empty.
  List<_Happening>? _featuredAttractions;
  // "Featured community events" (LUXURY): up to 3 COMMUNITY/user-created events,
  // boosted-first then the nearest normal ones, within [kFeaturedRadiusKm] of
  // the user. Rendered with a premium gold-glow/shine treatment
  // ([_LuxuryEventCard]). null == loading; empty == hidden.
  List<_Happening>? _luxuryEvents;

  // ── People sections (each: null == loading, empty == loaded/hidden) ─────────
  // "Recommended for you": heuristic relevance-ranked people via the
  // [RecommendationService] (shared interests/languages + same city + proximity).
  List<MatchCandidate>? _recommended;
  // "People around you": distance-ordered neighbours via the discovery stack.
  List<MatchCandidate>? _aroundYou;
  // "Business accounts": GreenGo business profiles to discover (replaces the old
  // "same interests" row). Empty (loaded) hides the section.
  List<MatchCandidate>? _businessAccounts;
  // "People that speak {language}": profiles listing a randomly-picked language.
  List<MatchCandidate>? _sameLanguage;
  // The randomly-picked language whose speakers [_sameLanguage] holds (for the
  // dynamic section title). Set as soon as a language is chosen so the header
  // reads correctly even during the skeleton phase.
  String? _sameLanguageName;
  // Community/user-created events close to the user (distinct from "Happening
  // this week"). null == loading; empty == hidden.
  List<Event>? _communityEvents;
  // "Businesses near you": public business profiles (`profiles.isBusiness`),
  // nearest-first when a location is known else as returned. null == loading;
  // empty == hidden.
  List<Profile>? _businesses;

  // The current user's OWN spoken languages (from their profile), used to build
  // the "People that speak {language}" section (a language they themselves know).
  List<String> _userLanguages = const <String>[];
  // The current user's UPCOMING events they're going to (organized or RSVP'd).
  // null == loading; empty == none upcoming (section hidden entirely).
  List<Event>? _myEvents;
  // Public communities to join (near the user / by interest, else popular).
  // null == loading; empty == none (section shows an empty hint).
  List<Community>? _communities;
  // The active weekly Country Spotlight, or null when there is none (section
  // hidden entirely). A dedicated flag distinguishes "still loading" from
  // "loaded, nothing active".
  CountrySpotlight? _spotlight;
  bool _spotlightLoaded = false;

  /// First-paint skeleton gate: true until the core content loads (or a hard
  /// 2.5s cap), so the entry page shows a stable, layout-accurate skeleton of
  /// the core sections instead of individual sections popping in and vanishing.
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Runs the initial load behind the first-paint skeleton. Reveals the full
  /// layout as soon as content is ready, or after a hard 2.5s cap so a slow
  /// loader can never trap the user on the skeleton.
  Future<void> _bootstrap() async {
    await Future.any<void>([
      _load(),
      Future<void>.delayed(const Duration(milliseconds: 2500)),
    ]);
    if (mounted) setState(() => _bootstrapping = false);
  }

  Future<void> _load() async {
    await _loadProfile();
    // Fire the content loads concurrently; each updates state on its own and
    // never throws (a failure just hides its section).
    await Future.wait<void>([
      _loadHappenings(),
      _loadFeaturedAttractions(),
      _loadLuxuryEvents(),
      _loadRecommended(),
      _loadAroundYou(),
      _loadBusinessAccounts(),
      _loadSameLanguage(),
      _loadCommunityEvents(),
      _loadBusinesses(),
      _loadMyEvents(),
      _loadCommunities(),
      _loadSpotlight(),
      _loadCoinsStat(),
      _loadCountriesStat(),
      _loadPeopleStat(),
    ]);
  }

  Future<void> _loadProfile() async {
    try {
      final doc =
          await _firestore.collection('profiles').doc(widget.userId).get();
      final data = doc.data();
      if (data != null) {
        final loc = data['location'] as Map<String, dynamic>?;
        _city = (loc?['city'] as String?)?.trim();
        _countryName = (loc?['country'] as String?)?.trim();
        _countryCode = (data['primaryOrigin'] as String?)?.trim();
        _userLat = (loc?['latitude'] as num?)?.toDouble();
        _userLng = (loc?['longitude'] as num?)?.toDouble();
        // Traveler mode: when a user "travels" to another city, the WHOLE Explore
        // surface (greeting city, nearby events, nearby communities) follows the
        // traveled-to location instead of their real one — so it reads e.g.
        // "Explore Paris" with Paris events, not Los Angeles.
        final travelerExpiryRaw = data['travelerExpiry'];
        final travelerExpiry =
            travelerExpiryRaw is Timestamp ? travelerExpiryRaw.toDate() : null;
        final travelerActive = data['isTraveler'] == true &&
            travelerExpiry != null &&
            travelerExpiry.isAfter(DateTime.now());
        if (travelerActive) {
          final tloc = data['travelerLocation'] as Map<String, dynamic>?;
          if (tloc != null) {
            _city = (tloc['city'] as String?)?.trim() ?? _city;
            _countryName = (tloc['country'] as String?)?.trim() ?? _countryName;
            _userLat = (tloc['latitude'] as num?)?.toDouble() ?? _userLat;
            _userLng = (tloc['longitude'] as num?)?.toDouble() ?? _userLng;
          }
        }
        _displayName = (data['displayName'] as String?)?.trim();
        _userLanguages = (data['languages'] as List<dynamic>?)
                ?.map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList() ??
            const <String>[];
        final tier =
            MembershipTier.fromString((data['membershipTier'] as String?) ?? '');
        _tierStat = _tierShortLabel(tier);
        // Parse the full profile once for the recommendation heuristic. Best
        // effort — a parse failure just disables the "Recommended for you" row.
        try {
          _me = ProfileModel.fromJson({...data, 'userId': widget.userId});
        } catch (_) {
          _me = null;
        }
      }
    } catch (_) {
      // Non-fatal — fall back to defaults below.
    }
    // If the profile read failed entirely, still resolve the tier tile so it
    // doesn't shimmer forever (defaults to the Base tier label).
    _tierStat ??= _tierShortLabel(MembershipTier.free);
    if (mounted) setState(() {});
  }

  /// Reads the user's coin balance for the stats header. Prefers the stored
  /// `availableCoins`, falling back to `totalCoins` (the field the shop writes).
  Future<void> _loadCoinsStat() async {
    String value = '–';
    try {
      final doc =
          await _firestore.collection('coinBalances').doc(widget.userId).get();
      final data = doc.data();
      final coins = (data?['availableCoins'] as num?)?.toInt() ??
          (data?['totalCoins'] as num?)?.toInt() ??
          0;
      value = NumberFormat.compact().format(coins);
    } catch (_) {
      value = '–';
    }
    if (mounted) setState(() => _coinsStat = value);
  }

  /// Counts the distinct countries the user has engaged with = their Cultural
  /// Passport country-stamp count (reuses the bounded, index-free
  /// [PassportService]).
  Future<void> _loadCountriesStat() async {
    String value = '–';
    try {
      final passport = await PassportService(firestore: _firestore)
          .load(widget.userId);
      value = passport.countryStamps.length.toString();
    } catch (_) {
      value = '–';
    }
    if (mounted) setState(() => _countriesStat = value);
  }

  /// Counts the distinct people the user has ever chatted with, via two bounded,
  /// index-free equality queries over `conversations` (`userId1`/`userId2`),
  /// collecting and de-duplicating the other participant.
  Future<void> _loadPeopleStat() async {
    String value = '–';
    try {
      final ids = <String>{};

      Future<void> collect(String field) async {
        final snap = await _firestore
            .collection('conversations')
            .where(field, isEqualTo: widget.userId)
            .limit(300)
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          // Count only REAL chats: at least one message sent and not
          // canceled/deleted for this user (matches the Exchanges list rule).
          if (data['lastMessage'] == null) continue;
          if (data['isDeleted'] == true) continue;
          final deletedFor = data['deletedFor'];
          if (deletedFor is Map && deletedFor.containsKey(widget.userId)) {
            continue;
          }
          final u1 = data['userId1'] as String?;
          final u2 = data['userId2'] as String?;
          final other = u1 == widget.userId ? u2 : u1;
          if (other != null && other.isNotEmpty && other != widget.userId) {
            ids.add(other);
          }
        }
      }

      await collect('userId1');
      await collect('userId2');
      value = ids.length.toString();
    } catch (_) {
      value = '–';
    }
    if (mounted) setState(() => _peopleStat = value);
  }

  /// Compact, brand-facing tier label for the stats tile.
  String _tierShortLabel(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return 'Base';
      case MembershipTier.silver:
        return 'Silver';
      case MembershipTier.gold:
        return 'Gold';
      case MembershipTier.platinum:
        return 'Platinum';
      case MembershipTier.test:
        return 'Tester';
    }
  }

  /// Collapse recurring-series occurrences to a SINGLE instance per non-null
  /// `seriesId` (the first one seen, preserving the incoming order); standalone
  /// events pass through unchanged. Used so a recurring event shows once, not as
  /// a run of identical cards.
  List<Event> _dedupeSeries(List<Event> events) {
    final seenSeries = <String>{};
    final result = <Event>[];
    for (final e in events) {
      final sid = e.seriesId;
      if (sid != null && sid.isNotEmpty && !seenSeries.add(sid)) {
        continue; // already have an instance of this series
      }
      result.add(e);
    }
    return result;
  }

  /// Loads "Happening TODAY": community/user-created events occurring today
  /// FIRST, then the LIVE EVENTS OF THE DAY (Ticketmaster `external_events` dated
  /// today) that don't duplicate a community event. NEVER shows past events, at
  /// most 3 cards, one instance per recurring series.
  Future<void> _loadHappenings() async {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    // 1) Community events overlapping TODAY only: not yet finished AND not
    //    starting on a future day. One instance per recurring series.
    List<Event> community = const <Event>[];
    if (_userLat != null && _userLng != null) {
      try {
        final eventsDs = EventsRemoteDataSourceImpl(firestore: _firestore);
        community = await eventsDs.getNearbyCommunityEvents(
          lat: _userLat!,
          lng: _userLng!,
          limit: 40,
        );
      } catch (_) {
        community = const <Event>[];
      }
    }
    final communityToday = _dedupeSeries(
      community
          .where((e) => e.endDate.isAfter(now) && !e.startDate.isAfter(todayEnd))
          .toList(),
    );
    final communityItems =
        communityToday.map((e) => _Happening.community(e)).toList();
    final communityTitles =
        communityToday.map((e) => e.title.toLowerCase().trim()).toSet();

    // 2) LIVE EVENTS OF THE DAY — Ticketmaster external events dated today that
    //    are NOT already present as a community event (by title).
    List<ExternalEvent> live = const <ExternalEvent>[];
    final ds = ExternalEventsDataSource(firestore: _firestore);
    try {
      if (_userLat != null && _userLng != null) {
        live = await ds.getNearbyExperiences(
          source: 'ticketmaster',
          userLat: _userLat!,
          userLng: _userLng!,
          limit: 60,
        );
      } else {
        live =
            await ds.getExperiencesSorted(source: 'ticketmaster', sort: 'date');
      }
    } catch (_) {
      live = const <ExternalEvent>[];
    }
    final liveTodayItems = live
        .where((e) => e.startDate == todayStr)
        .where((e) => !communityTitles.contains(e.title.toLowerCase().trim()))
        .map((e) => _Happening.external(e))
        .where(_hasImage)
        .toList();

    // Community events (today) FIRST, then live events of the day. Max 3.
    final rows = [...communityItems, ...liveTodayItems].take(3).toList();

    if (mounted) {
      setState(() {
        _happenings = rows;
      });
    }
  }

  /// Loads "Featured events": up to 3 cards elected BOOSTED-first and
  /// community-before-live, all within [kFeaturedRadiusKm] of the user when a
  /// location is known.
  ///
  ///  1. Priority 1 — BOOSTED community events (the coin-boost mechanic:
  ///     [Event.isCurrentlyFeatured] == `isFeatured && featuredUntil` not
  ///     passed) from the `events` collection, shuffled.
  ///  2. Priority 2 — BOOSTED live/external events. External experiences carry
  ///     no featured/boost flag today, so there is nothing to add here (skipped).
  ///  3. Fallback — if still short of 3, fill with NORMAL events: community
  ///     FIRST, then live/external, de-duplicated by key.
  ///
  /// Empty (literally zero events, or on failure) → the carousel is hidden.
  Future<void> _loadFeaturedEvents() async {
    final picked = <_Happening>[];
    final seen = <String>{};

    void addUpToThree(Iterable<_Happening> items) {
      for (final h in items) {
        if (picked.length >= 3) break;
        final k = h.key;
        if (k.isNotEmpty && !seen.add(k)) continue; // dedup by stable key
        picked.add(h);
      }
    }

    // Community events near the user (source of both boosted & normal community
    // cards). Kept within [kFeaturedRadiusKm] when a location is known.
    List<_Happening> community = const <_Happening>[];
    if (_userLat != null && _userLng != null) {
      try {
        final eventsDs = EventsRemoteDataSourceImpl(firestore: _firestore);
        final events = await eventsDs.getNearbyCommunityEvents(
          lat: _userLat!,
          lng: _userLng!,
          limit: 40,
        );
        community = events
            .map((e) => _Happening.community(e))
            .where(_withinFeaturedRadius)
            .toList();
      } catch (_) {
        community = const <_Happening>[];
      }
    }

    // Priority 1 — BOOSTED community events (shuffled).
    addUpToThree(
      community.where((h) => h.isCurrentlyFeatured).toList()..shuffle(),
    );

    // Priority 2 — BOOSTED live/external events: external experiences have no
    // featured/boost flag, so there is nothing to add. (Skip to the fallback.)

    // Fallback — NORMAL events, community FIRST then live/external, until 3.
    if (picked.length < 3) {
      addUpToThree(
        community.where((h) => !h.isCurrentlyFeatured).toList()..shuffle(),
      );
    }
    if (picked.length < 3) {
      List<_Happening> external = const <_Happening>[];
      try {
        final ds = ExternalEventsDataSource(firestore: _firestore);
        List<ExternalEvent> items;
        if (_userLat != null && _userLng != null) {
          items = await ds.getNearbyExperiences(
            source: 'viator',
            userLat: _userLat!,
            userLng: _userLng!,
            limit: 40,
          );
        } else {
          items =
              await ds.getExperiencesSorted(source: 'viator', sort: 'rating');
        }
        external = items
            .map((e) => _Happening.external(e))
            .where(_hasImage) // omit picture-less attractions/experiences
            .where(_withinFeaturedRadius)
            .toList()
          ..shuffle();
      } catch (_) {
        external = const <_Happening>[];
      }
      addUpToThree(external);
    }

    if (mounted) setState(() => _featuredEvents = picked.take(3).toList());
  }

  /// Loads "Featured attractions": random external attractions (Geoapify /
  /// Wikipedia) near the user, within [kFeaturedRadiusKm] when a location is
  /// known (otherwise a rating-sorted sample). Up to 3 at random. Empty (or on
  /// failure) → the carousel is hidden.
  Future<void> _loadFeaturedAttractions() async {
    List<_Happening> picked = const <_Happening>[];
    try {
      final ds = ExternalEventsDataSource(firestore: _firestore);
      List<ExternalEvent> items;
      if (_userLat != null && _userLng != null) {
        items = await ds.getNearbyExperiences(
          source: 'geoapify',
          userLat: _userLat!,
          userLng: _userLng!,
          limit: 60,
        );
      } else {
        items =
            await ds.getExperiencesSorted(source: 'geoapify', sort: 'rating');
      }
      final pool = items
          .map((e) => _Happening.external(e))
          .where(_hasImage) // omit picture-less attractions/experiences
          .where(_withinFeaturedRadius)
          .toList()
        ..shuffle();
      picked = pool.take(3).toList();
    } catch (_) {
      picked = const <_Happening>[];
    }
    if (mounted) setState(() => _featuredAttractions = picked);
  }

  /// Round-robin window over [sponsored]: when MORE than 3 are eligible, rotate
  /// the visible 3 by a wall-clock offset (computed once, stable for
  /// [_luxuryRotationMinutes]) so every sponsor gets fair exposure across
  /// refreshes instead of always the same 3. Returns the list unchanged when 3
  /// or fewer. Expects [sponsored] pre-sorted by a STABLE key (id) so the
  /// rotation advances fairly.
  List<Event> _rotateSponsored(List<Event> sponsored) {
    if (sponsored.length <= 3) return sponsored;
    final offset = (DateTime.now().millisecondsSinceEpoch ~/
            (_luxuryRotationMinutes * 60 * 1000)) %
        sponsored.length;
    return [
      for (var i = 0; i < 3; i++) sponsored[(offset + i) % sponsored.length],
    ];
  }

  /// Loads "Featured community events" (the LUXURY carousel): up to 3 events
  /// elected with a FOUR-TIER fallback + round-robin. Only truly EMPTY when
  /// there are zero community/live events anywhere (or every fetch fails) → the
  /// carousel hides itself. Crucially it NO LONGER requires a user location: a
  /// location just refines Tiers 1–3; Tier 4 covers the (common) case of a
  /// profile with no stored coordinates.
  ///
  /// Strategy:
  ///  - Tier 1 — SPONSORED community events near the user FIRST. "Sponsored" ==
  ///    a currently-promoted event ([Event.isCurrentlyFeatured] — the paid
  ///    coin-boost mechanic: `isFeatured && featuredUntil` not passed).
  ///    Cross-referencing each event's community for a `Community.isSponsored`
  ///    flag would cost an extra read per event, so we rely on the event's own
  ///    featured/boost flag (cheap, index-light). ROUND-ROBIN via
  ///    [_rotateSponsored] so every sponsor gets fair exposure.
  ///  - Tier 2 — if FEWER than 3 sponsors, FILL the remainder with the CLOSEST
  ///    community events (nearest-first, as returned by the data source),
  ///    de-duped against Tier 1.
  ///  - Tier 3 — if there are NO community events near the user at all, FALL
  ///    BACK to nearby LIVE events (distance-sorted), lightly shuffled.
  ///  - Tier 4 — LOCATION-INDEPENDENT last resort: when we STILL have nothing
  ///    (no stored location, or nothing nearby), pull upcoming PUBLIC community
  ///    events with a plain non-geo query (sponsored-first + round-robin, then
  ///    the soonest remaining) so the carousel shows wherever the user is.
  ///
  /// Tiers 1–3 stay within [kFeaturedRadiusKm] when a location is known; all
  /// tiers are de-duplicated by event id.
  Future<void> _loadLuxuryEvents() async {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final picked = <_Happening>[];
    final seen = <String>{};

    void addAll(Iterable<_Happening> items) {
      for (final h in items) {
        if (picked.length >= 3) break;
        final k = h.key;
        if (k.isEmpty || !seen.add(k)) continue; // dedup by key
        picked.add(h);
      }
    }

    // Adapter so the existing native tiers keep adding community events.
    void addEvents(Iterable<Event> items) =>
        addAll(items.map((e) => _Happening.community(e)));

    final eventsDs = EventsRemoteDataSourceImpl(firestore: _firestore);
    final hasLocation = _userLat != null && _userLng != null;

    // Community events near the user, kept within [kFeaturedRadiusKm] when a
    // location is known (nearest-first, as returned by the data source).
    List<Event> community = const <Event>[];
    if (hasLocation) {
      try {
        final events = await eventsDs.getNearbyCommunityEvents(
          lat: _userLat!,
          lng: _userLng!,
          limit: 40,
        );
        community = _dedupeSeries(events
            .where((e) => _withinFeaturedRadius(_Happening.community(e)))
            .toList());
      } catch (_) {
        community = const <Event>[];
      }
    }

    // Tier 1 — SPONSORED (currently-featured/boosted) community events, ordered
    // by a STABLE base key (id) so the time-based round-robin advances fairly.
    final sponsored = community.where((e) => e.isCurrentlyFeatured).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    addEvents(_rotateSponsored(sponsored));

    // Tier 2 — FILL with RANDOM other community events (de-duped against the
    // sponsored picks) so the carousel rotates through the community instead of
    // always showing the same closest few.
    if (picked.length < 3) {
      final others = community.where((e) => !e.isCurrentlyFeatured).toList()
        ..shuffle();
      addEvents(others);
    }

    // Tier 3 (per spec) — LIVE EVENTS OF THE DAY: external Ticketmaster events
    // dated today, shuffled. Preferred fallback once community is exhausted.
    if (picked.length < 3) {
      List<ExternalEvent> live = const <ExternalEvent>[];
      final ds = ExternalEventsDataSource(firestore: _firestore);
      try {
        if (hasLocation) {
          live = await ds.getNearbyExperiences(
            source: 'ticketmaster',
            userLat: _userLat!,
            userLng: _userLng!,
            limit: 60,
          );
        } else {
          live = await ds.getExperiencesSorted(
              source: 'ticketmaster', sort: 'date');
        }
      } catch (_) {
        live = const <ExternalEvent>[];
      }
      final liveToday = live
          .where((e) => e.startDate == todayStr)
          .map((e) => _Happening.external(e))
          .where(_hasImage)
          .toList()
        ..shuffle();
      addAll(liveToday);
    }

    // Deep native safety nets below — only reached if community AND live-of-day
    // were all empty, so the carousel still shows something.
    // Nearby LIVE native events (distance-sorted), lightly shuffled.
    if (picked.length < 3 && community.isEmpty && hasLocation) {
      try {
        final live = await eventsDs.getEventsNearLocation(
          _userLat!,
          _userLng!,
          kFeaturedRadiusKm,
        );
        addEvents(live.take(20).toList()..shuffle());
      } catch (_) {
        // Leave picked as-is — Tier 4 still has a chance below.
      }
    }

    // Tier 4 — LOCATION-INDEPENDENT last resort. Reached when we STILL have
    // nothing to show: typically the (common) case of a profile with no stored
    // coordinates, where Tiers 1–3 were all skipped. Pull upcoming PUBLIC
    // community events with a plain non-geo query so the carousel appears
    // wherever the user is: sponsored-first (stable order + round-robin), then
    // the soonest remaining ones, de-duped against anything already picked.
    if (picked.length < 3) {
      try {
        final upcoming = await eventsDs.getEvents(upcoming: true);
        final sponsoredGlobal =
            upcoming.where((e) => e.isCurrentlyFeatured).toList()
              ..sort((a, b) => a.id.compareTo(b.id));
        addEvents(_rotateSponsored(sponsoredGlobal));
        if (picked.length < 3) {
          final others = upcoming.where((e) => !e.isCurrentlyFeatured).toList()
            ..shuffle();
          addEvents(others);
        }
      } catch (_) {
        // Leave picked as-is — Tier 5 still has a chance below.
      }
    }

    // Tier 5 — TRULY INDEX-FREE last resort. Every tier above funnels through
    // [EventsRemoteDataSourceImpl], whose queries are all filtered/ordered
    // (`status whereIn` + `startDate`/`geohash` orderBy) AND upcoming/nearby
    // only. In the common real-data case (no boosted events, nothing nearby,
    // events past-dated, or any swallowed query error) those tiers yield
    // nothing and the carousel silently blanks — which is exactly why the
    // previously-added "location-independent" Tier 4 (itself a filtered,
    // upcoming-only query) never actually rescued it. This tier issues a plain,
    // index-free collection read (no `where`/`orderBy` — just a bounded limit),
    // parses client-side and keeps any PUBLIC, LIVE event so the carousel shows
    // whenever ANY public event exists at all. Sponsored-first, then soonest.
    if (picked.length < 3) {
      try {
        final snap = await _firestore.collection('events').limit(50).get();
        final live = snap.docs
            .map<Event>(EventModel.fromFirestore)
            .where((e) => e.isPublic && e.isLive)
            .toList();
        final sponsoredRaw = live.where((e) => e.isCurrentlyFeatured).toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        addEvents(_rotateSponsored(sponsoredRaw));
        if (picked.length < 3) {
          addEvents(
            live.where((e) => !e.isCurrentlyFeatured).toList()
              ..sort((a, b) => a.startDate.compareTo(b.startDate)),
          );
        }
      } catch (_) {
        // Genuinely nothing to show — an empty result hides the carousel.
      }
    }

    if (mounted) setState(() => _luxuryEvents = picked.take(3).toList());
  }

  /// How many people each carousel shows.
  static const int _peopleWanted = 15;

  /// "People around you" — distance-ordered neighbours. Reuses the discovery
  /// stack ([DiscoveryRemoteDataSource.getDiscoveryStack]), which is already
  /// nearest-first and applies ghost/blocked/boost rules. We keep the nearest
  /// [_peopleWanted] and lightly `shuffle()` within that nearest set so the row
  /// feels fresh without pulling in far-away people. Networking/cultural only —
  /// no like/match/swipe.
  Future<void> _loadAroundYou() async {
    List<MatchCandidate> picked = const <MatchCandidate>[];
    try {
      final ds = di.sl<DiscoveryRemoteDataSource>();
      final prefs = MatchPreferences.defaultFor(widget.userId)
          .copyWith(showSupportUser: false);
      final stack = await ds.getDiscoveryStack(
        userId: widget.userId,
        preferences: prefs,
        limit: 60,
      );
      final nearest = stack
          .where((c) =>
              !c.profile.isAdmin &&
              !c.profile.isSupport &&
              c.profile.userId != widget.userId)
          .take(_peopleWanted)
          .toList()
        ..shuffle();
      picked = nearest;
    } catch (_) {
      picked = const <MatchCandidate>[];
    }
    if (mounted) setState(() => _aroundYou = picked);
  }

  /// "Business accounts" — GreenGo business profiles (`isBusiness == true`) to
  /// discover, rendered as people cards. Shuffled, capped at [_peopleWanted].
  /// Hidden entirely when there are none. Tapping "See all" opens Discovery
  /// filtered to business accounts.
  Future<void> _loadBusinessAccounts() async {
    final byId = <String, _Partner>{};
    try {
      final snap = await _firestore
          .collection('profiles')
          .where('isBusiness', isEqualTo: true)
          .limit(60)
          .get();
      for (final doc in snap.docs) {
        if (doc.id == widget.userId) continue;
        final p = _parsePartner(doc.id, doc.data());
        if (p != null) byId[doc.id] = p;
      }
    } catch (_) {
      // Leave whatever we parsed — an empty result hides the section.
    }
    final picked = (byId.values.toList()..shuffle())
        .take(_peopleWanted)
        .map(_candidateFor)
        .toList();
    if (mounted) setState(() => _businessAccounts = picked);
  }

  /// "People that speak {language}" — picks ONE language the CURRENT USER
  /// themselves knows (from their own `profiles.languages`) and shows OTHER
  /// people who also speak it. The user's languages are tried in a random order
  /// (up to a handful of attempts) and the FIRST one that actually has other
  /// speakers is chosen, so the section renders reliably rather than hiding on
  /// an unlucky pick. Shuffled, capped at [_peopleWanted]. Hidden entirely when
  /// the user lists no languages (or none of them have any other speakers).
  Future<void> _loadSameLanguage() async {
    final own = List<String>.of(_userLanguages)..shuffle();
    if (own.isEmpty) {
      if (mounted) setState(() => _sameLanguage = const <MatchCandidate>[]);
      return;
    }
    // Try several of the user's own languages before giving up.
    for (final lang in own.take(6)) {
      if (lang.isEmpty) continue;
      // Publish the tentative language immediately so the (skeleton) header
      // reads correctly while the query runs.
      if (mounted) setState(() => _sameLanguageName = lang);
      final byId = <String, _Partner>{};
      try {
        final snap = await _firestore
            .collection('profiles')
            .where('languages', arrayContains: lang)
            .limit(60)
            .get();
        for (final doc in snap.docs) {
          final p = _parsePartner(doc.id, doc.data());
          if (p != null) byId[doc.id] = p;
        }
      } catch (_) {
        // Try the next language.
      }
      if (byId.isNotEmpty) {
        final picked = (byId.values.toList()..shuffle())
            .take(_peopleWanted)
            .map(_candidateFor)
            .toList();
        if (mounted) {
          setState(() {
            _sameLanguageName = lang;
            _sameLanguage = picked;
          });
        }
        return;
      }
    }
    if (mounted) setState(() => _sameLanguage = const <MatchCandidate>[]);
  }

  /// "Recommended for you" — heuristic relevance-ranked people via the
  /// [RecommendationService] (shared interests/languages + same city +
  /// proximity, with a small jitter). Requires the current user's parsed
  /// profile ([_me]); on any failure (or an empty result) the section hides.
  Future<void> _loadRecommended() async {
    final me = _me;
    if (me == null) {
      if (mounted) setState(() => _recommended = const <MatchCandidate>[]);
      return;
    }
    List<MatchCandidate> picked = const <MatchCandidate>[];
    try {
      final profiles = await RecommendationService(firestore: _firestore)
          .recommendPeople(
        userId: widget.userId,
        me: me,
        lat: _userLat,
        lng: _userLng,
        limit: _peopleWanted,
      );
      final lat = _userLat;
      final lng = _userLng;
      picked = profiles.map((p) {
        double distanceKm = 0;
        final loc = p.effectiveLocation;
        if (lat != null &&
            lng != null &&
            (loc.latitude != 0 || loc.longitude != 0)) {
          distanceKm = FeatureEngineer()
              .calculateDistance(lat, lng, loc.latitude, loc.longitude);
        }
        return _candidateFor(_Partner(
          userId: p.userId,
          name: p.displayName,
          profile: p,
          distanceKm: distanceKm,
        ));
      }).toList();
    } catch (_) {
      picked = const <MatchCandidate>[];
    }
    if (mounted) setState(() => _recommended = picked);
  }

  /// "Community events near you" — community/user-created events close to the
  /// user (distinct from the external-heavy "Happening this week"). Requires a
  /// location; empty (or on failure) hides the section.
  Future<void> _loadCommunityEvents() async {
    List<Event> events = const <Event>[];
    if (_userLat != null && _userLng != null) {
      try {
        final eventsDs = EventsRemoteDataSourceImpl(firestore: _firestore);
        events = await eventsDs.getNearbyCommunityEvents(
          lat: _userLat!,
          lng: _userLng!,
          limit: _peopleWanted,
        );
        // Auto-publish gate (defensive): drafts / not-yet-due scheduled events
        // never leak into discovery. The datasource already filters; guard here
        // too (see Event.isLive).
        events = events.where((e) => e.isLive).toList();
      } catch (_) {
        events = const <Event>[];
      }
    }
    if (mounted) setState(() => _communityEvents = events);
  }

  /// Loads "Businesses near you": public business profiles
  /// (`profiles.isBusiness == true`), bounded to 20 with a single-field
  /// equality filter (index-light, scale-safe). Excludes the current user, the
  /// hidden admin/support account, ghost-mode profiles and any banned/suspended
  /// account. Sorted nearest-first when a location is known, else left as
  /// returned (recent). Empty (or on failure) hides the section.
  Future<void> _loadBusinesses() async {
    List<Profile> result = const <Profile>[];
    try {
      final snap = await _firestore
          .collection('profiles')
          .where('isBusiness', isEqualTo: true)
          .limit(20)
          .get();
      final lat = _userLat;
      final lng = _userLng;
      final list = <Profile>[];
      for (final doc in snap.docs) {
        final d = doc.data();
        if (doc.id == widget.userId) continue; // exclude self
        // Never surface the official GreenGo account (admin/support).
        if (d['isAdmin'] == true || d['isSupport'] == true) continue;
        if (d['isBanned'] == true) continue; // banned business
        final status = d['accountStatus'];
        if (status != null && status != 'active') continue; // suspended/deleted
        if (d['isGhostMode'] == true) continue;
        try {
          list.add(ProfileModel.fromJson({...d, 'userId': doc.id}));
        } catch (_) {
          // Skip unparseable business profiles.
        }
      }
      if (lat != null && lng != null) {
        double dist(Profile p) {
          final loc = p.effectiveLocation;
          if (loc.latitude == 0 && loc.longitude == 0) return double.infinity;
          return FeatureEngineer()
              .calculateDistance(lat, lng, loc.latitude, loc.longitude);
        }

        list.sort((a, b) => dist(a).compareTo(dist(b)));
      }
      result = list;
    } catch (_) {
      result = const <Profile>[];
    }
    if (mounted) setState(() => _businesses = result);
  }

  /// True when [h] carries a usable picture. Attractions/experiences with no
  /// image (`imageUrl` null or blank) are OMITTED from Explore entirely — a
  /// picture-less attraction card is never shown.
  bool _hasImage(_Happening h) {
    final url = h.imageUrl;
    return url != null && url.trim().isNotEmpty;
  }

  /// True when [h] qualifies for the featured carousel. With a known user
  /// location an experience must sit within [kFeaturedRadiusKm]; an experience
  /// with no coordinates can't be verified and is excluded. With NO user
  /// location we can't filter, so everything qualifies (plain random election).
  bool _withinFeaturedRadius(_Happening h) {
    final lat = _userLat;
    final lng = _userLng;
    if (lat == null || lng == null) return true; // no location → no filter
    final hLat = h.lat;
    final hLng = h.lng;
    if (hLat == null || hLng == null) return false; // unknown → can't qualify
    final distanceKm =
        FeatureEngineer().calculateDistance(lat, lng, hLat, hLng);
    return distanceKm <= kFeaturedRadiusKm;
  }

  /// Loads "My next events": the current user's UPCOMING events they're going to
  /// (organized or RSVP'd). Uses the existing [EventsRemoteDataSource.getUserEvents]
  /// (organized + attending), then keeps only events whose start is in the
  /// future, ordered soonest-first, capped at 10. Failures hide the section.
  Future<void> _loadMyEvents() async {
    List<Event> mine = const <Event>[];
    try {
      final eventsDs = EventsRemoteDataSourceImpl(firestore: _firestore);
      final all = await eventsDs.getUserEvents(widget.userId);
      final now = DateTime.now();
      mine = all.where((e) => !e.startDate.isBefore(now)).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      if (mine.length > 10) mine = mine.sublist(0, 10);
    } catch (_) {
      mine = const <Event>[];
    }
    if (mounted) setState(() => _myEvents = mine);
  }

  /// Loads "Communities to join": PUBLIC communities, preferring ones near the
  /// user (their city) or matching the user's languages, falling back to
  /// recent/popular. Excludes nothing sensitive (all public); capped at 10.
  /// Failures hide the section (empty list → an empty hint, never a crash).
  Future<void> _loadCommunities() async {
    List<Community> result = const <Community>[];
    try {
      final ds = CommunitiesRemoteDataSourceImpl(firestore: _firestore);
      final byId = <String, Community>{};

      // 1) Near the user — communities in their city.
      final city = _city;
      if (city != null && city.isNotEmpty) {
        try {
          for (final c in await ds.getCommunities(city: city)) {
            byId[c.id] = c;
          }
        } catch (_) {/* fall through to broader queries */}
      }

      // 2) Top up with recent/popular public communities (default ordering).
      if (byId.length < 10) {
        try {
          for (final c in await ds.getCommunities()) {
            byId.putIfAbsent(c.id, () => c);
            if (byId.length >= 10) break;
          }
        } catch (_) {/* keep whatever we have */}
      }

      result = byId.values.take(10).toList();
    } catch (_) {
      result = const <Community>[];
    }
    if (mounted) setState(() => _communities = result);
  }

  /// Loads the active weekly Country Spotlight (or null when there is none).
  /// A null result hides the whole section; failures do the same.
  Future<void> _loadSpotlight() async {
    CountrySpotlight? spotlight;
    try {
      final ds = CulturalExchangeRemoteDataSourceImpl(firestore: _firestore);
      spotlight = await ds.getActiveSpotlight();
    } catch (_) {
      spotlight = null;
    }
    if (mounted) {
      setState(() {
        _spotlight = spotlight;
        _spotlightLoaded = true;
      });
    }
  }

  /// Parses a `profiles` document into a discovery card, or null if it can't be
  /// shown (self, ghost-mode, non-active, or no display name).
  _Partner? _parsePartner(String id, Map<String, dynamic> d) {
    if (id == widget.userId) return null;
    if (d['isGhostMode'] == true) return null;
    // Never surface the official GreenGo account (admin/support) in the grid.
    if (d['isAdmin'] == true || d['isSupport'] == true) return null;
    if (d['accountStatus'] != null && d['accountStatus'] != 'active') {
      return null;
    }

    final name = (d['displayName'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;

    // Build the full profile so the tile can render with [NetworkGridCard]
    // (the shared 2.2.4 discovery card). If the document can't be parsed into a
    // Profile, the partner is skipped rather than shown half-formed.
    Profile profile;
    try {
      profile = ProfileModel.fromJson({...d, 'userId': id});
    } catch (_) {
      return null;
    }

    // Distance from the current user (0 == unknown; the card hides the badge).
    double distanceKm = 0;
    final lat = _userLat;
    final lng = _userLng;
    final candLoc = profile.effectiveLocation;
    if (lat != null &&
        lng != null &&
        (candLoc.latitude != 0 || candLoc.longitude != 0)) {
      distanceKm = FeatureEngineer()
          .calculateDistance(lat, lng, candLoc.latitude, candLoc.longitude);
    }

    return _Partner(
      userId: id,
      name: name,
      profile: profile,
      distanceKm: distanceKm,
    );
  }

  /// Wraps a parsed [_Partner] into a [MatchCandidate] for [NetworkGridCard].
  /// The compatibility score is intentionally 0 (hidden by the card) — Explore
  /// surfaces random cultural neighbours, not scored matches.
  MatchCandidate _candidateFor(_Partner p) {
    final now = DateTime.now();
    return MatchCandidate(
      profile: p.profile,
      matchScore: MatchScore(
        userId1: widget.userId,
        userId2: p.userId,
        overallScore: 0,
        breakdown: const ScoreBreakdown(
          locationScore: 0,
          ageCompatibilityScore: 0,
          interestOverlapScore: 0,
        ),
        calculatedAt: now,
      ),
      distance: p.distanceKm,
      suggestedAt: now,
    );
  }

  String get _displayCity {
    if (_city != null && _city!.isNotEmpty) return _city!;
    if (_countryName != null && _countryName!.isNotEmpty) return _countryName!;
    return _defaultCity;
  }

  /// The user's first name (first word of their display name), or null.
  String? get _firstName {
    final name = _displayName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.split(RegExp(r'\s+')).first;
  }

  /// A time-of-day greeting: morning (5–11), afternoon (12–16), evening
  /// (17–20), night (21–4), keyed to the device's local hour.
  String _greetingText(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour <= 11) return l10n.greetingMorning;
    if (hour >= 12 && hour <= 16) return l10n.greetingAfternoon;
    if (hour >= 17 && hour <= 20) return l10n.greetingEvening;
    return l10n.greetingNight;
  }

  /// Country used for the flag-derived backdrop gradient.
  String? get _flagCountry {
    if (_countryCode != null && _countryCode!.isNotEmpty) return _countryCode;
    return _countryName;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      // Solid black page (matches the other tabs). The flag-colored band is
      // drawn only behind the header/hero via [_TopBackdropBand]; everything
      // below it is plain black.
      body: ColoredBox(
        color: AppColors.backgroundDark,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _TopBackdropBand(
                  gradient: CountryFlagColors.gradientFor(_flagCountry),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _greeting(context, l10n)),
                              const SizedBox(width: 8),
                              _headerActions(context, l10n),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _statsRow(context, l10n, reduceMotion),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_bootstrapping)
                ..._bootstrapSkeletonSlivers(context, l10n, reduceMotion)
              else ...[
              // Featured attractions carousel near the top (hides itself when
              // empty). We intentionally do NOT show a separate generic
              // "Featured events" carousel here — the community/boosted events
              // carousel lives just below as "Featured community events"
              // (_luxuryEventsSection), so the two no longer duplicate.
              _featuredAttractionsSection(context, l10n, reduceMotion),
              // Personal & high-priority: the user's own upcoming events. Hidden
              // entirely when they have none (see [_myEventsSection]).
              _myEventsSection(context, l10n, reduceMotion),
              // "Featured community events" — a LUXURY carousel of up to three
              // boosted-first community events, placed immediately before
              // "People around you". Hidden entirely when there are none.
              _luxuryEventsSection(context, l10n, reduceMotion),
              // People sections (where the old single Network Discovery carousel
              // was): around you → same interests → speak {language}. Each hides
              // itself when empty (see [_peopleSection]).
              _peopleSection(
                context,
                l10n,
                reduceMotion,
                title: l10n.exploreAroundYou,
                people: _aroundYou,
                onSeeAll: () => _openNetworkDiscovery(context),
              ),
              // "Recommended for you" — heuristic relevance-ranked people. Placed
              // near the top of the people sections; hides itself when empty.
              _peopleSection(
                context,
                l10n,
                reduceMotion,
                title: l10n.exploreRecommended,
                people: _recommended,
                onSeeAll: () => _openNetworkDiscovery(context),
              ),
              _peopleSection(
                context,
                l10n,
                reduceMotion,
                title: l10n.exploreBusinessAccounts,
                people: _businessAccounts,
                onSeeAll: () => _openBusinessDiscovery(context),
              ),
              _peopleSection(
                context,
                l10n,
                reduceMotion,
                title: l10n.exploreSpeaksLanguage(_sameLanguageName ?? ''),
                people: _sameLanguage,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: _sectionHeader(
                    context,
                    l10n.exploreCommunitiesTitle,
                    l10n.exploreSeeAll,
                    onSeeAll: () => _openCommunitiesList(context),
                  ),
                ),
              ),
              _communitiesSection(context, l10n, reduceMotion),
              // Community events close to the user (distinct from "Happening this
              // week"). Hidden entirely when there are none.
              _communityEventsSection(context, l10n, reduceMotion),
              // "Businesses near you" — public business profiles, nearest-first,
              // placed immediately before "Happening this week". Hidden when
              // there are none (see [_businessesSection]).
              _businessesSection(context, l10n, reduceMotion),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: _sectionHeader(
                    context,
                    l10n.exploreHappeningToday,
                    l10n.exploreSeeAll,
                    onSeeAll: () => _openAllEvents(context),
                  ),
                ),
              ),
              _happeningSection(context, l10n, reduceMotion),
              // Country Spotlight — a single glass card. Hidden entirely when
              // there is no active spotlight (see [_spotlightSection]).
              _spotlightSection(context, l10n, reduceMotion),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The first-paint skeleton: the CORE sections only (featured community
  /// events → people around you → communities → happening today), in the real
  /// order and using the real section widgets so card sizes match exactly. The
  /// flakier, frequently-empty sections (attractions, my events, businesses,
  /// spotlight, the extra people rows) are intentionally omitted here so nothing
  /// skeletons-then-vanishes on first paint.
  List<Widget> _bootstrapSkeletonSlivers(
    BuildContext context,
    AppLocalizations l10n,
    bool reduceMotion,
  ) {
    return [
      _luxuryEventsSection(context, l10n, reduceMotion),
      _peopleSection(
        context,
        l10n,
        reduceMotion,
        title: l10n.exploreAroundYou,
        people: _aroundYou,
        onSeeAll: () => _openNetworkDiscovery(context),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
          child: _sectionHeader(
            context,
            l10n.exploreCommunitiesTitle,
            l10n.exploreSeeAll,
            onSeeAll: () => _openCommunitiesList(context),
          ),
        ),
      ),
      _communitiesSection(context, l10n, reduceMotion),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
          child: _sectionHeader(
            context,
            l10n.exploreHappeningToday,
            l10n.exploreSeeAll,
            onSeeAll: () => _openAllEvents(context),
          ),
        ),
      ),
      _happeningSection(context, l10n, reduceMotion),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }

  Widget _greeting(BuildContext context, AppLocalizations l10n) {
    final name = _firstName;
    final greeting = _greetingText(l10n);
    final headline = name != null ? '$greeting, $name' : greeting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.exploreTitle.toUpperCase(),
          style: const TextStyle(
            color: AppColors.richGold,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          headline,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.exploreHeadline(_displayCity),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  /// The three glass header actions, left-to-right: Universal Search, QR hub,
  /// and Notifications (a bell with an unread badge when a [NotificationsBloc]
  /// is available in the tree — which it is under the main navigation shell).
  /// Apple-safe: no dating affordances, purely utility.
  Widget _headerActions(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _headerIconButton(
          icon: Icons.search,
          tooltip: l10n.exploreSearchTooltip,
          onTap: () => Navigator.of(context).push(
            UniversalSearchScreen.route(currentUserId: widget.userId),
          ),
        ),
        const SizedBox(width: 8),
        _headerIconButton(
          icon: Icons.qr_code_scanner,
          tooltip: l10n.exploreQrTooltip,
          onTap: () => Navigator.of(context).push(
            QRHubScreen.route(currentUserId: widget.userId),
          ),
        ),
        const SizedBox(width: 8),
        _notificationBell(context, l10n),
      ],
    );
  }

  /// Notifications bell. Uses the ambient [NotificationsBloc] (provided by the
  /// main navigation shell) to render an unread badge; if the bloc isn't in the
  /// tree it degrades gracefully to a plain bell.
  Widget _notificationBell(BuildContext context, AppLocalizations l10n) {
    NotificationsBloc? bloc;
    try {
      bloc = context.read<NotificationsBloc>();
    } catch (_) {
      bloc = null;
    }
    void open() => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NotificationsScreen(userId: widget.userId),
          ),
        );
    if (bloc == null) {
      return _headerIconButton(
        icon: Icons.notifications_none,
        tooltip: l10n.notificationsTitle,
        onTap: open,
      );
    }
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      bloc: bloc,
      builder: (context, state) {
        final unread = state is NotificationsLoaded ? state.unreadCount : 0;
        return _headerIconButton(
          icon: Icons.notifications_none,
          tooltip: l10n.notificationsTitle,
          onTap: open,
          badgeCount: unread,
        );
      },
    );
  }

  /// A single circular glass header button (charcoal fill + hairline border,
  /// gold-on-white icon), with an optional red unread badge.
  Widget _headerIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: AppColors.charcoal,
            shape: CircleBorder(side: BorderSide(color: AppGlass.border)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(icon, color: AppColors.textPrimary, size: 21),
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.errorRed,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  textAlign: TextAlign.center,
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
    );
  }

  /// The personalized stats row (glass): coins, membership tier, countries
  /// engaged (passport stamps) and distinct people chatted with. Each tile
  /// shimmers until its value resolves; a failed stat resolves to '–'.
  Widget _statsRow(
    BuildContext context,
    AppLocalizations l10n,
    bool reduceMotion,
  ) {
    final animate = !reduceMotion;
    Widget divider() => Container(
          width: 1,
          height: 30,
          color: AppGlass.border,
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(AppGlass.radiusCard),
        border: Border.all(color: AppGlass.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _openCoinShop,
              borderRadius: BorderRadius.circular(AppGlass.radiusCard),
              child: _StatTile(
                icon: Icons.monetization_on_outlined,
                value: _coinsStat,
                label: l10n.statCoins,
                animate: animate,
              ),
            ),
          ),
          divider(),
          Expanded(
            child: InkWell(
              onTap: _openMembership,
              borderRadius: BorderRadius.circular(AppGlass.radiusCard),
              child: _StatTile(
                icon: Icons.workspace_premium_outlined,
                value: _tierStat,
                label: l10n.statTier,
                animate: animate,
              ),
            ),
          ),
          divider(),
          Expanded(
            child: InkWell(
              onTap: _openWorldMap,
              borderRadius: BorderRadius.circular(AppGlass.radiusCard),
              child: _StatTile(
                icon: Icons.public,
                value: _countriesStat,
                label: l10n.statCountries,
                animate: animate,
              ),
            ),
          ),
          divider(),
          Expanded(
            child: InkWell(
              onTap: _openExchange,
              borderRadius: BorderRadius.circular(AppGlass.radiusCard),
              child: _StatTile(
                icon: Icons.forum_outlined,
                value: _peopleStat,
                label: l10n.statPeople,
                animate: animate,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Coins tile → the coin shop. Tier tile → the membership upgrade sheet.
  /// Countries tile → the world map (globe). People tile → the Exchange
  /// (conversations) page. (Explore stat tiles are shortcuts into these hubs.)
  void _openCoinShop() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<CoinBloc>(
          create: (_) => di.sl<CoinBloc>()
            ..add(LoadCoinBalance(widget.userId))
            ..add(const LoadAvailablePackages()),
          child: CoinShopScreen(userId: widget.userId),
        ),
      ),
    );
  }

  void _openMembership() {
    // Tier tile → the Shop opened on its Membership tab (index 1).
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<CoinBloc>(
          create: (_) => di.sl<CoinBloc>()
            ..add(LoadCoinBalance(widget.userId))
            ..add(const LoadAvailablePackages()),
          child: CoinShopScreen(userId: widget.userId, initialTab: 1),
        ),
      ),
    );
  }

  void _openWorldMap() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<GlobeBloc>(
          create: (_) => di.sl<GlobeBloc>(),
          child: GlobeScreen(userId: widget.userId),
        ),
      ),
    );
  }

  void _openExchange() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ConversationsScreen(userId: widget.userId, showAppBar: true),
      ),
    );
  }

  /// "Featured events" — a hero carousel of up to three random community events
  /// within [kFeaturedRadiusKm] ([_FeaturedCard] style). While loading it shows
  /// a skeleton carousel; once loaded with nothing to show the whole section
  /// (header included) collapses to nothing. Tapping routes to [_openHappening]
  /// (→ [EventDetailLoaderScreen]).
  Widget _featuredEventsSection(
    BuildContext context,
    AppLocalizations l10n,
    bool reduceMotion,
  ) =>
      _featuredCarouselSection(
        context,
        reduceMotion,
        title: l10n.exploreFeaturedEvents,
        items: _featuredEvents,
        topPadding: 24,
      );

  /// "Featured attractions" — a hero carousel of up to three random external
  /// attractions near the user ([_FeaturedCard] style), directly below
  /// "Featured events". Tapping opens the read-only attraction sheet via
  /// [_openHappening]. Hidden entirely when there are none.
  Widget _featuredAttractionsSection(
    BuildContext context,
    AppLocalizations l10n,
    bool reduceMotion,
  ) =>
      _featuredCarouselSection(
        context,
        reduceMotion,
        title: l10n.exploreFeaturedAttractions,
        items: _featuredAttractions,
        topPadding: 20,
      );

  /// "Featured community events" — the LUXURY carousel of up to three
  /// boosted-first community events ([_LuxuryEventCard]: gold gradient frame,
  /// soft outer glow and an animated shine sweep). While loading it shows a
  /// premium skeleton; loaded with nothing hides the whole section (header
  /// included). Tapping opens the event detail / RSVP screen. Reduced-motion
  /// safe (no shine sweep, clamping physics).
  Widget _luxuryEventsSection(
    BuildContext context,
    AppLocalizations l10n,
    bool reduceMotion,
  ) {
    final events = _luxuryEvents;
    // Loaded and empty → hide the section entirely (no empty box).
    if (events != null && events.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final physics = reduceMotion
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();

    Widget content;
    String stateKey;
    if (events == null) {
      stateKey = 'loading';
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => _LuxuryEventCardSkeleton(animate: !reduceMotion),
      );
    } else {
      stateKey = 'loaded';
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: physics,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) => _LuxuryEventCard(
          happening: events[index],
          animate: !reduceMotion,
          onTap: () => _openHappening(context, events[index]),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Text(
              l10n.exploreFeaturedCommunity,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: _LuxuryEventCard.cardHeight,
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              child:
                  KeyedSubtree(key: ValueKey<String>(stateKey), child: content),
            ),
          ),
        ],
      ),
    );
  }

  /// Shared builder for the two hero carousels. [items] null == loading (show a
  /// skeleton carousel); empty == hide the whole section (header + carousel).
  /// The card is wider than the page gutter so the next card peeks (~1.1
  /// visible). Reduced-motion safe (clamping physics + no fade when animations
  /// are disabled).
  Widget _featuredCarouselSection(
    BuildContext context,
    bool reduceMotion, {
    required String title,
    required List<_Happening>? items,
    required double topPadding,
  }) {
    // Loaded and empty → hide the section entirely (no empty box).
    if (items != null && items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final physics = reduceMotion
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();

    Widget content;
    String stateKey;
    if (items == null) {
      stateKey = 'loading';
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => _FeaturedCardSkeleton(animate: !reduceMotion),
      );
    } else {
      stateKey = 'loaded';
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: physics,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) => _FeaturedCard(
          happening: items[index],
          animate: !reduceMotion,
          onTap: () => _openHappening(context, items[index]),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding, 20, 12),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: _FeaturedCard.cardHeight,
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              child:
                  KeyedSubtree(key: ValueKey<String>(stateKey), child: content),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title,
    String action, {
    required VoidCallback onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            action,
            style: const TextStyle(
              color: AppColors.richGold,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Portrait person-card footprint for the Network Discovery carousel — sized so
  // ~2–2.5 cards peek on a phone and the user scrolls horizontally through all
  // 20. [NetworkGridCard] fills its parent (StackFit.expand), so each card is
  // wrapped in a fixed-size box.
  // People photos are square (1:1) — width == height — with the card's own
  // rounded corners (radius 16 in [NetworkGridCard]) kept for a "bit rounded" look.
  static const double _networkCardWidth = 150;
  static const double _networkCardHeight = 150;

  /// A people carousel section (title + horizontal row of [NetworkGridCard]s).
  /// [people] null == loading (skeleton row); empty == the whole section
  /// (header included) collapses to nothing. When [onSeeAll] is non-null a
  /// "See all" action is shown in the header. Reduced-motion safe: clamping
  /// physics + no shimmer/fade when animations are disabled.
  Widget _peopleSection(
    BuildContext context,
    AppLocalizations l10n,
    bool reduceMotion, {
    required String title,
    required List<MatchCandidate>? people,
    VoidCallback? onSeeAll,
  }) {
    // Loaded and empty → hide the section entirely (no empty box).
    if (people != null && people.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final physics = reduceMotion
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();

    Widget content;
    String stateKey;
    if (people == null) {
      stateKey = 'loading';
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => SizedBox(
          width: _networkCardWidth,
          height: _networkCardHeight,
          child: _PersonSkeleton(animate: !reduceMotion),
        ),
      );
    } else {
      stateKey = 'loaded';
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: physics,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: people.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _personCard(context, people[index]),
      );
    }

    // Header: with a "See all" action when [onSeeAll] is provided, else a plain
    // title (matching the featured-carousel title styling).
    final header = onSeeAll != null
        ? _sectionHeader(context, title, l10n.exploreSeeAll, onSeeAll: onSeeAll)
        : Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          );

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: header,
          ),
          SizedBox(
            height: _networkCardHeight,
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              child:
                  KeyedSubtree(key: ValueKey<String>(stateKey), child: content),
            ),
          ),
        ],
      ),
    );
  }

  /// One fixed-size person tile in a people carousel — the shared 2.2.4
  /// [NetworkGridCard] with the Apple-safe gestures: photo → chat, name →
  /// profile, long-press → private people-tags editor.
  Widget _personCard(BuildContext context, MatchCandidate candidate) {
    final profile = candidate.profile;
    return SizedBox(
      width: _networkCardWidth,
      height: _networkCardHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppGlass.radiusCard),
        child: NetworkGridCard(
          candidate: candidate,
          isSelf: false,
          onOpenChat: () => openConnectChat(
            context,
            currentUserId: widget.userId,
            otherUserId: profile.userId,
            otherUserProfile: profile,
          ),
          onOpenProfile: () {
            // Interaction logging (fire-and-forget, never throws): a profile tap
            // in the Explore feed feeds the recommendation signal.
            di.sl<InteractionLogService>()
                .logProfileView(widget.userId, profile.userId);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProfileDetailScreen(
                  profile: profile,
                  currentUserId: widget.userId,
                ),
              ),
            );
          },
          onLongPressTag: () => showPeopleTagsEditor(
            context,
            ownerId: widget.userId,
            targetUserId: profile.userId,
            targetName: candidate.displayName,
          ),
        ),
      ),
    );
  }

  /// "Community events near you" — a carousel of community/user-created events
  /// close to the user, reusing the [_HappeningCard] via a community
  /// [_Happening] so it renders (and taps through to [EventDetailLoaderScreen])
  /// exactly like the other event cards. While loading it shows a skeleton
  /// carousel; loaded with nothing hides the whole section (header included).
  Widget _communityEventsSection(
    BuildContext context,
    AppLocalizations l10n,
    bool reduceMotion,
  ) {
    final events = _communityEvents;
    // Loaded and empty → hide the section entirely.
    if (events != null && events.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final physics = reduceMotion
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();

    Widget content;
    String stateKey;
    if (events == null) {
      stateKey = 'loading';
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => _HappeningCardSkeleton(animate: !reduceMotion),
      );
    } else {
      stateKey = 'loaded';
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: physics,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final happening = _Happening.community(events[index]);
          return _HappeningCard(
            happening: happening,
            animate: !reduceMotion,
            onTap: () => _openHappening(context, happening),
          );
        },
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Text(
              l10n.exploreCommunityEventsNearby,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: _HappeningCard.cardHeight,
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              child:
                  KeyedSubtree(key: ValueKey<String>(stateKey), child: content),
            ),
          ),
        ],
      ),
    );
  }

  /// "Businesses near you" — a horizontal carousel of public business profiles,
  /// nearest-first. While loading it shows a skeleton row; loaded with nothing
  /// hides the whole section (header included). Tapping opens the business's
  /// storefront ([BusinessStorefrontScreen]). Reduced-motion safe.
  Widget _businessesSection(
    BuildContext context,
    AppLocalizations l10n,
    bool reduceMotion,
  ) {
    final businesses = _businesses;
    // Loaded and empty → hide the section entirely.
    if (businesses != null && businesses.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final physics = reduceMotion
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();

    Widget content;
    String stateKey;
    if (businesses == null) {
      stateKey = 'loading';
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => _BusinessCardSkeleton(animate: !reduceMotion),
      );
    } else {
      stateKey = 'loaded';
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: physics,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: businesses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _BusinessCard(
          business: businesses[index],
          animate: !reduceMotion,
          onTap: () => _openBusiness(context, businesses[index]),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Text(
              l10n.exploreBusinessesNearYou,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: _BusinessCard.cardHeight,
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              child:
                  KeyedSubtree(key: ValueKey<String>(stateKey), child: content),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens a business's storefront/profile ([BusinessStorefrontScreen]). The
  /// profile-view interaction is logged (fire-and-forget) to feed the
  /// recommendation signal, matching the people-card behaviour.
  void _openBusiness(BuildContext context, Profile business) {
    di.sl<InteractionLogService>()
        .logProfileView(widget.userId, business.userId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BusinessStorefrontScreen(
          business: business,
          currentUserId: widget.userId,
        ),
      ),
    );
  }

  /// "Happening this week" — a full-width, horizontally-scrolling carousel of
  /// LARGE event cards (image-forward), showing at most three items. Community
  /// events come first (see [_loadHappenings]); tapping routes to
  /// [_openHappening]. The loading → loaded transition fades via an
  /// [AnimatedSwitcher] so cards don't pop or jump. Reduced-motion safe.
  Widget _happeningSection(
    BuildContext context,
    AppLocalizations l10n,
    bool reduceMotion,
  ) {
    Widget content;
    String stateKey;

    if (_happenings == null) {
      stateKey = 'loading';
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => _HappeningCardSkeleton(animate: !reduceMotion),
      );
    } else if (_happenings!.isEmpty) {
      stateKey = 'empty';
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Align(
          alignment: Alignment.topCenter,
          child: _EmptyHint(text: l10n.exploreNoEvents),
        ),
      );
    } else {
      stateKey = 'loaded';
      // At most three cards, community-events-first (already ordered).
      final rows = _happenings!.take(3).toList();
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _HappeningCard(
          happening: rows[index],
          animate: !reduceMotion,
          onTap: () => _openHappening(context, rows[index]),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: _HappeningCard.cardHeight,
        child: AnimatedSwitcher(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
          child: KeyedSubtree(key: ValueKey<String>(stateKey), child: content),
        ),
      ),
    );
  }

  /// "My next events" — the user's UPCOMING events (organized or RSVP'd),
  /// soonest-first, near the top of Explore. Reuses the [_HappeningCard] via a
  /// community [_Happening] so it renders (and taps through to
  /// [EventDetailLoaderScreen]) exactly like the other event cards. While
  /// loading it shows a skeleton carousel; once loaded with nothing upcoming the
  /// whole section (header included) collapses to nothing.
  Widget _myEventsSection(
    BuildContext context,
    AppLocalizations l10n,
    bool reduceMotion,
  ) {
    // Loaded and empty → hide the section entirely (no empty box).
    if (_myEvents != null && _myEvents!.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final physics = reduceMotion
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();

    Widget content;
    String stateKey;
    if (_myEvents == null) {
      stateKey = 'loading';
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => _HappeningCardSkeleton(animate: !reduceMotion),
      );
    } else {
      stateKey = 'loaded';
      final events = _myEvents!;
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: physics,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final happening = _Happening.community(events[index]);
          return _HappeningCard(
            happening: happening,
            animate: !reduceMotion,
            onTap: () => _openHappening(context, happening),
          );
        },
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: _sectionHeader(
              context,
              l10n.exploreMyNextEvents,
              l10n.exploreSeeAll,
              onSeeAll: () => _openAllEvents(context),
            ),
          ),
          SizedBox(
            height: _HappeningCard.cardHeight,
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              child:
                  KeyedSubtree(key: ValueKey<String>(stateKey), child: content),
            ),
          ),
        ],
      ),
    );
  }

  /// "Communities to join" — a horizontal carousel of public communities near
  /// the user (or recent/popular). Its section header (with "See all") is added
  /// by [build]; this returns just the carousel sliver. Reduced-motion safe.
  Widget _communitiesSection(
    BuildContext context,
    AppLocalizations l10n,
    bool reduceMotion,
  ) {
    final physics = reduceMotion
        ? const ClampingScrollPhysics()
        : const BouncingScrollPhysics();

    Widget content;
    String stateKey;
    if (_communities == null) {
      stateKey = 'loading';
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => _CommunityCardSkeleton(animate: !reduceMotion),
      );
    } else if (_communities!.isEmpty) {
      stateKey = 'empty';
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Align(
          alignment: Alignment.topCenter,
          child: _EmptyHint(text: l10n.exploreNoCommunities),
        ),
      );
    } else {
      stateKey = 'loaded';
      final communities = _communities!;
      content = ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: physics,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: communities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _CommunityCard(
          community: communities[index],
          animate: !reduceMotion,
          onTap: () => _openCommunity(context, communities[index]),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: _CommunityCard.cardHeight,
        child: AnimatedSwitcher(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
          child: KeyedSubtree(key: ValueKey<String>(stateKey), child: content),
        ),
      ),
    );
  }

  /// "Country Spotlight" — a single glass card for the active weekly spotlight.
  /// While loading it shows a skeleton card; if there is no active spotlight the
  /// whole section (header included) collapses to nothing. Tapping opens the
  /// Cultural Exchange hub.
  Widget _spotlightSection(
    BuildContext context,
    AppLocalizations l10n,
    bool reduceMotion,
  ) {
    // Loaded with no active spotlight → hide the section entirely.
    if (_spotlightLoaded && _spotlight == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    Widget content;
    String stateKey;
    if (!_spotlightLoaded) {
      stateKey = 'loading';
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _ShimmerBox(
          width: double.infinity,
          height: _SpotlightCard.cardHeight,
          radius: AppGlass.radiusCard,
          animate: !reduceMotion,
        ),
      );
    } else {
      stateKey = 'loaded';
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _SpotlightCard(
          spotlight: _spotlight!,
          animate: !reduceMotion,
          onTap: () => _openSpotlight(context),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Text(
              l10n.exploreCountrySpotlight,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: _SpotlightCard.cardHeight,
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              child:
                  KeyedSubtree(key: ValueKey<String>(stateKey), child: content),
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  /// Opens the right surface for a happening: a community event opens its full
  /// detail / RSVP screen ([EventDetailLoaderScreen], which brings its own
  /// bloc); an external experience opens the read-only attraction sheet.
  void _openHappening(BuildContext context, _Happening happening) {
    final community = happening.community;
    if (community != null) {
      // Community events open the detail loader, which already logs the
      // event_view interaction — no explicit log needed here.
      Navigator.of(context).push(
        EventDetailLoaderScreen.route(
          eventId: community.id,
          currentUserId: widget.userId,
        ),
      );
      return;
    }
    final external = happening.external;
    if (external != null) {
      // Interaction logging (fire-and-forget, never throws): an attraction tap
      // feeds the recommendation signal.
      di.sl<InteractionLogService>()
          .logAttractionView(widget.userId, external.id);
      showAttractionMenu(
        context,
        event: external,
        currentUserId: widget.userId,
      );
    }
  }

  /// "See all" for experiences → the full Events screen (external + native).
  void _openAllEvents(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EventsScreen(currentUserId: widget.userId),
      ),
    );
  }

  /// "See all" for "People around you" → the full distance-ordered people grid.
  void _openNetworkDiscovery(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NetworkDiscoveryScreen(userId: widget.userId),
      ),
    );
  }

  /// "See all" for "Business accounts" → the full people grid filtered to
  /// business accounts (Discovery opened with its business-only filter on).
  void _openBusinessDiscovery(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NetworkDiscoveryScreen(
          userId: widget.userId,
          businessOnly: true,
        ),
      ),
    );
  }

  /// Opens a community's group chat. Explore doesn't host the communities/
  /// profile blocs, so we bring fresh DI factory instances (both registered as
  /// factories) — a [ProfileBloc] loaded for the current user, and a
  /// [CommunitiesBloc] — scoped to the pushed route.
  void _openCommunity(BuildContext context, Community community) {
    // Interaction logging (fire-and-forget, never throws): a community tap feeds
    // the recommendation signal.
    di.sl<InteractionLogService>()
        .logCommunityView(widget.userId, community.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<CommunitiesBloc>(
              create: (_) => di.sl<CommunitiesBloc>(),
            ),
            BlocProvider<ProfileBloc>(
              create: (_) => di.sl<ProfileBloc>()
                ..add(ProfileLoadRequested(userId: widget.userId)),
            ),
          ],
          child: CommunityDetailScreen(community: community),
        ),
      ),
    );
  }

  /// "See all" for communities → the full communities / groups list (same bloc
  /// wiring as [_openCommunity]).
  void _openCommunitiesList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<CommunitiesBloc>(
              create: (_) => di.sl<CommunitiesBloc>(),
            ),
            BlocProvider<ProfileBloc>(
              create: (_) => di.sl<ProfileBloc>()
                ..add(ProfileLoadRequested(userId: widget.userId)),
            ),
          ],
          child: const CommunitiesScreen(),
        ),
      ),
    );
  }

  /// Opens the Cultural Exchange hub (wrapping it in its BLoC via DI), reached
  /// by tapping the Country Spotlight card.
  void _openSpotlight(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<CulturalExchangeBloc>(
          create: (_) => di.sl<CulturalExchangeBloc>(),
          child: const CulturalExchangeScreen(),
        ),
      ),
    );
  }

}

/// A flag-derived colored band drawn behind the top content so the frosted
/// glass of the featured hero has something colourful to refract, and so the
/// header subtly reflects the user's home country.
class _TopBackdropBand extends StatelessWidget {
  const _TopBackdropBand({required this.child, required this.gradient});

  final Widget child;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: DecoratedBox(
        // Soft dissolve: the flag colour glows subtly at the very top, then
        // melts smoothly into the page's solid black. The bottom stop lands on
        // an OPAQUE `backgroundDark` (identical to the page background) so there
        // is no visible seam between the band and the content below — and no
        // heavy "fade-to-black" scrim darkening the hero, which sits on the
        // clean, evenly-lit black lower portion of the band.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundDark.withValues(alpha: 0.30),
              AppColors.backgroundDark.withValues(alpha: 0.92),
              AppColors.backgroundDark,
            ],
            stops: const [0.0, 0.68, 1.0],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// A large, hero-style "Featured experience" carousel card. The event image
/// fills the whole card with a dark bottom scrim so the overlaid text stays
/// legible: a "Featured" tag sits top-left, the title + going count bottom-left,
/// and a gold "Join" pill bottom-right. Larger than [_HappeningCard] so the top
/// strip reads as the page hero. Built from a real [_Happening]; the whole card
/// taps through to [_openHappening] via [onTap]. Solid image (no per-card
/// BackdropFilter) to keep the horizontal scroll cheap.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.happening,
    required this.onTap,
    required this.animate,
  });

  final _Happening happening;
  final VoidCallback onTap;
  final bool animate;

  // Larger than [_HappeningCard]; wider than the 20px page gutter so the next
  // card peeks (~1.1 visible) on a phone.
  static const double cardWidth = 320;
  static const double cardHeight = 230;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final imageUrl = happening.imageUrl;
    final goingCount = happening.goingCount;
    final title = happening.title ?? '';

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppGlass.radiusCard),
          onTap: onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(AppGlass.radiusCard),
              border: Border.all(color: AppGlass.borderGold),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Full-bleed event image (or a branded fallback) ──────────
                if (imageUrl != null && imageUrl.isNotEmpty)
                  _FadeInImage(
                    url: imageUrl,
                    height: cardHeight,
                    animate: animate,
                  )
                else
                  Container(
                    alignment: Alignment.center,
                    color: AppColors.richGold.withValues(alpha: 0.10),
                    child: const Icon(
                      Icons.local_activity_outlined,
                      color: AppColors.richGold,
                      size: 44,
                    ),
                  ),
                // ── Legibility scrim (transparent → near-black at bottom) ────
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
                      stops: [0.35, 0.72, 1.0],
                    ),
                  ),
                ),
                // ── "Featured" tag ──────────────────────────────────────────
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.deepBlack.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppGlass.radiusPill),
                      border: Border.all(color: AppGlass.borderGold),
                    ),
                    child: Text(
                      l10n.exploreFeatured.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                // ── Title / going count / gold "Join" affordance ────────────
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.pureWhite,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            if (goingCount > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people_alt_outlined,
                                    color: AppColors.richGold,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      l10n.exploreGoingCount(goingCount),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.richGold,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppGlass.radiusPill),
                          boxShadow: AppGlass.goldGlow,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius:
                                BorderRadius.circular(AppGlass.radiusPill),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
                          ),
                          child: Text(
                            l10n.exploreJoin,
                            style: const TextStyle(
                              color: AppColors.deepBlack,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a loading "Featured experience" carousel card — matches the
/// [_FeaturedCard] footprint so the loaded content slots in without a jump.
class _FeaturedCardSkeleton extends StatelessWidget {
  const _FeaturedCardSkeleton({required this.animate});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    return _ShimmerBox(
      width: _FeaturedCard.cardWidth,
      height: _FeaturedCard.cardHeight,
      radius: AppGlass.radiusCard,
      animate: animate,
    );
  }
}

/// A LUXURY "Featured community event" hero card — a premium treatment that
/// clearly outranks the ordinary event cards: a gold gradient frame, a soft
/// gold outer glow ([AppGlass.goldGlow]), a richer gold-tinted glass scrim, a
/// diamond "Featured" accent pill, and — unless reduced motion is requested —
/// an animated diagonal shine that sweeps across the card. Built from a real
/// community [Event]; the whole card taps through via [onTap]. Overflow-safe;
/// the shine is purely decorative ([IgnorePointer]) and is omitted entirely
/// under reduced motion (leaving the static gold treatment).
class _LuxuryEventCard extends StatefulWidget {
  const _LuxuryEventCard({
    required this.happening,
    required this.onTap,
    required this.animate,
  });

  /// A community event OR an external "live event of the day" — the featured
  /// carousel falls back to external live events when community runs out.
  final _Happening happening;
  final VoidCallback onTap;
  final bool animate;

  // Hero footprint (matches [_FeaturedCard]) so it reads as a premium band.
  static const double cardWidth = 320;
  static const double cardHeight = 230;
  // Width of the gold gradient frame.
  static const double _frame = 1.6;

  @override
  State<_LuxuryEventCard> createState() => _LuxuryEventCardState();
}

class _LuxuryEventCardState extends State<_LuxuryEventCard>
    with SingleTickerProviderStateMixin {
  // Non-null only when animations are enabled (reduced motion → no sweep).
  AnimationController? _shine;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _shine = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2600),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _shine?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final happening = widget.happening;
    final imageUrl = happening.imageUrl;
    final title = happening.title ?? '';
    final goingCount = happening.goingCount;
    const innerRadius = AppGlass.radiusCard - _LuxuryEventCard._frame;

    return SizedBox(
      width: _LuxuryEventCard.cardWidth,
      height: _LuxuryEventCard.cardHeight,
      child: DecoratedBox(
        // Soft gold outer glow behind the whole card.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppGlass.radiusCard),
          boxShadow: AppGlass.goldGlow,
        ),
        child: Container(
          // Gold gradient FRAME: a thin gradient border around the inner card.
          padding: const EdgeInsets.all(_LuxuryEventCard._frame),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(AppGlass.radiusCard),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(innerRadius),
              onTap: widget.onTap,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(innerRadius),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Full-bleed event image (or a branded fallback) ───────
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      _FadeInImage(
                        url: imageUrl,
                        height: _LuxuryEventCard.cardHeight,
                        animate: widget.animate,
                      )
                    else
                      Container(
                        alignment: Alignment.center,
                        color: AppColors.richGold.withValues(alpha: 0.10),
                        child: const Icon(
                          Icons.local_activity_outlined,
                          color: AppColors.richGold,
                          size: 44,
                        ),
                      ),
                    // ── Richer, gold-tinted legibility scrim ─────────────────
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.richGold.withValues(alpha: 0.06),
                            Colors.black.withValues(alpha: 0.45),
                            AppColors.deepBlack.withValues(alpha: 0.90),
                          ],
                          stops: const [0.30, 0.70, 1.0],
                        ),
                      ),
                    ),
                    // ── Animated diagonal shine sweep (reduced-motion → none) ─
                    if (_shine != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _shine!,
                            builder: (context, child) => FractionalTranslation(
                              translation:
                                  Offset(-1.2 + 2.4 * _shine!.value, 0),
                              child: child,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.transparent,
                                    AppColors.richGold.withValues(alpha: 0.12),
                                    Colors.white.withValues(alpha: 0.24),
                                    AppColors.richGold.withValues(alpha: 0.12),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.30, 0.44, 0.5, 0.56, 0.70],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // ── Premium "Featured" accent (diamond + gold pill) ──────
                    Positioned(
                      top: 12,
                      left: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppGlass.radiusPill),
                          boxShadow: AppGlass.goldGlow,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius:
                                BorderRadius.circular(AppGlass.radiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.diamond_outlined,
                                color: AppColors.deepBlack,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                l10n.exploreFeatured.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.deepBlack,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // ── Title / going count ──────────────────────────────────
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.pureWhite,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          if (goingCount > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.people_alt_outlined,
                                  color: AppColors.richGold,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    l10n.exploreGoingCount(goingCount),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.richGold,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a loading LUXURY "Featured community event" card — keeps the
/// gold frame so the premium treatment reads even while loading, matching the
/// [_LuxuryEventCard] footprint so the loaded content slots in without a jump.
class _LuxuryEventCardSkeleton extends StatelessWidget {
  const _LuxuryEventCardSkeleton({required this.animate});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _LuxuryEventCard.cardWidth,
      height: _LuxuryEventCard.cardHeight,
      padding: const EdgeInsets.all(_LuxuryEventCard._frame),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(AppGlass.radiusCard),
      ),
      child: _ShimmerBox(
        width: double.infinity,
        height: double.infinity,
        radius: AppGlass.radiusCard - _LuxuryEventCard._frame,
        animate: animate,
      ),
    );
  }
}

/// A large, image-forward "Happening this week" carousel card. Full-bleed event
/// image on top, then title, date and the going count. Built from a real
/// [_Happening] (community event or external experience); [onTap] routes to the
/// right detail surface. Solid charcoal surface (no per-card BackdropFilter) to
/// keep the horizontal scroll cheap.
class _HappeningCard extends StatelessWidget {
  const _HappeningCard({
    required this.happening,
    required this.onTap,
    required this.animate,
  });

  final _Happening happening;
  final VoidCallback onTap;
  final bool animate;

  static const double cardWidth = 300;
  static const double cardHeight = 236;
  static const double _imageHeight = 132;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = happening.date;
    final imageUrl = happening.imageUrl;
    final goingCount = happening.goingCount;

    // Secondary line: prefer the date; else fall back to city / source.
    String? dateText = date != null ? DateFormat.MMMEd().format(date) : null;
    final subtitleParts = <String>[];
    final city = happening.city;
    if (city != null && city.isNotEmpty) subtitleParts.add(city);
    if (happening.rating != null) {
      subtitleParts.add('★ ${happening.rating!.toStringAsFixed(1)}');
    }
    if (dateText == null && happening.sourceLabel != null) {
      subtitleParts.add(happening.sourceLabel!);
    }
    final subtitle = subtitleParts.join('  ·  ');

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppGlass.radiusCard),
          onTap: onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(AppGlass.radiusCard),
              border: Border.all(color: AppGlass.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Full-width event image ──────────────────────────────────
                SizedBox(
                  height: _imageHeight,
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? _FadeInImage(
                          url: imageUrl,
                          height: _imageHeight,
                          animate: animate,
                        )
                      : Container(
                          alignment: Alignment.center,
                          color: AppColors.richGold.withValues(alpha: 0.10),
                          child: Icon(
                            date == null ? Icons.place_outlined : Icons.event,
                            color: AppColors.richGold,
                            size: 34,
                          ),
                        ),
                ),
                // ── Title / date / going ────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          happening.title ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const Spacer(),
                        if (dateText != null || subtitle.isNotEmpty)
                          Text(
                            dateText ?? subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.richGold,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (goingCount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.people_alt_outlined,
                                color: AppColors.textTertiary,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  l10n.exploreGoingCount(goingCount),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A glass "community to join" card. Full-width community image on top, then the
/// name, member count and a language/tag chip. Solid charcoal surface (no
/// per-card BackdropFilter) to keep the horizontal scroll cheap. Tapping opens
/// the community's group chat.
class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
    required this.community,
    required this.onTap,
    required this.animate,
  });

  final Community community;
  final VoidCallback onTap;
  final bool animate;

  static const double cardWidth = 240;
  static const double cardHeight = 212;
  static const double _imageHeight = 108;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final imageUrl = community.imageUrl;
    // A single language/tag chip: prefer the first language code (uppercased),
    // else the first tag.
    String? chipLabel;
    if (community.languages.isNotEmpty) {
      chipLabel = community.languages.first.toUpperCase();
    } else if (community.tags.isNotEmpty) {
      chipLabel = community.tags.first;
    }

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppGlass.radiusCard),
          onTap: onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(AppGlass.radiusCard),
              border: Border.all(color: AppGlass.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Community image (or a branded fallback) ─────────────────
                SizedBox(
                  height: _imageHeight,
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? _FadeInImage(
                          url: imageUrl,
                          height: _imageHeight,
                          animate: animate,
                        )
                      : Container(
                          alignment: Alignment.center,
                          color: AppColors.richGold.withValues(alpha: 0.10),
                          child: const Icon(
                            Icons.groups_outlined,
                            color: AppColors.richGold,
                            size: 34,
                          ),
                        ),
                ),
                // ── Name / member count + chip ──────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.people_alt_outlined,
                              color: AppColors.textTertiary,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                l10n.exploreMembersCount(community.memberCount),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            if (chipLabel != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.richGold.withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppGlass.radiusPill),
                                ),
                                child: Text(
                                  chipLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.richGold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a loading "Communities to join" card — matches the
/// [_CommunityCard] footprint so the loaded content slots in without a jump.
class _CommunityCardSkeleton extends StatelessWidget {
  const _CommunityCardSkeleton({required this.animate});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    return _ShimmerBox(
      width: _CommunityCard.cardWidth,
      height: _CommunityCard.cardHeight,
      radius: AppGlass.radiusCard,
      animate: animate,
    );
  }
}

/// A glass "business near you" card. A full-width cover/avatar image on top
/// (the business's first photo, else a branded storefront fallback), then the
/// business name and its category. Solid charcoal surface (no per-card
/// BackdropFilter) to keep the horizontal scroll cheap. Tapping opens the
/// business's storefront.
class _BusinessCard extends StatelessWidget {
  const _BusinessCard({
    required this.business,
    required this.onTap,
    required this.animate,
  });

  final Profile business;
  final VoidCallback onTap;
  final bool animate;

  static const double cardWidth = 220;
  static const double cardHeight = 200;
  static const double _imageHeight = 108;

  @override
  Widget build(BuildContext context) {
    final name = (business.businessName?.trim().isNotEmpty ?? false)
        ? business.businessName!.trim()
        : business.displayName;
    final category = business.businessCategory?.trim();
    final imageUrl =
        business.photoUrls.isNotEmpty ? business.photoUrls.first : null;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppGlass.radiusCard),
          onTap: onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(AppGlass.radiusCard),
              border: Border.all(color: AppGlass.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Cover / avatar (or a branded fallback) ──────────────────
                SizedBox(
                  height: _imageHeight,
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? _FadeInImage(
                          url: imageUrl,
                          height: _imageHeight,
                          animate: animate,
                        )
                      : Container(
                          alignment: Alignment.center,
                          color: AppColors.richGold.withValues(alpha: 0.10),
                          child: const Icon(
                            Icons.storefront_outlined,
                            color: AppColors.richGold,
                            size: 34,
                          ),
                        ),
                ),
                // ── Business name / category ────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const Spacer(),
                        if (category != null && category.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.sell_outlined,
                                color: AppColors.textTertiary,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.richGold,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a loading "Businesses near you" card — matches the
/// [_BusinessCard] footprint so the loaded content slots in without a jump.
class _BusinessCardSkeleton extends StatelessWidget {
  const _BusinessCardSkeleton({required this.animate});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    return _ShimmerBox(
      width: _BusinessCard.cardWidth,
      height: _BusinessCard.cardHeight,
      radius: AppGlass.radiusCard,
      animate: animate,
    );
  }
}

/// A single "Country Spotlight" glass card: the country flag, its name and a
/// short fact/description. Uses the spotlight image (with a legibility scrim)
/// when present, else a flag-derived gradient backdrop. Tapping opens the
/// Cultural Exchange hub.
class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({
    required this.spotlight,
    required this.onTap,
    required this.animate,
  });

  final CountrySpotlight spotlight;
  final VoidCallback onTap;
  final bool animate;

  static const double cardHeight = 170;

  @override
  Widget build(BuildContext context) {
    final country = spotlight.country;
    final code = CountryFlagHelper.getCodeFromName(country);
    final flag = code != null ? CountryFlagHelper.getFlag(code) : '';
    // A short fact: the spotlight title, else the first section's content.
    final fact = spotlight.title.isNotEmpty
        ? spotlight.title
        : (spotlight.sections.isNotEmpty ? spotlight.sections.first.content : '');
    final imageUrl = spotlight.imageUrl;

    return SizedBox(
      height: cardHeight,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppGlass.radiusCard),
          onTap: onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(AppGlass.radiusCard),
              border: Border.all(color: AppGlass.borderGold),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Backdrop: spotlight image, else a flag-derived gradient ──
                if (imageUrl.isNotEmpty)
                  _FadeInImage(
                    url: imageUrl,
                    height: cardHeight,
                    animate: animate,
                  )
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: CountryFlagColors.gradientFor(country),
                    ),
                  ),
                // ── Legibility scrim ─────────────────────────────────────────
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black38,
                        Colors.black54,
                        Colors.black87,
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // ── Flag / country / fact ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          if (flag.isNotEmpty) ...[
                            Text(flag, style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Text(
                              country,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.pureWhite,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (fact.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          fact,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 13.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One compact stat tile in the Explore header: an icon, a value (a pulsing
/// shimmer while [value] is null / still loading) and a label. Overflow-safe.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.animate,
  });

  final IconData icon;
  final String? value; // null == still loading
  final String label;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.richGold, size: 20),
        const SizedBox(height: 6),
        SizedBox(
          height: 18,
          child: value == null
              ? Center(
                  child: _ShimmerBox(
                    width: 28,
                    height: 12,
                    radius: 6,
                    animate: animate,
                  ),
                )
              : Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// A CachedNetworkImage that fades in smoothly (never pops) with a soft charcoal
/// placeholder and a graceful error fallback. Reused by the featured hero and
/// the "Happening this week" cards. Fade is disabled under reduced motion.
class _FadeInImage extends StatelessWidget {
  const _FadeInImage({
    required this.url,
    required this.height,
    required this.animate,
  });

  final String url;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      memCacheWidth: 800,
      maxWidthDiskCache: 800,
      fadeInDuration:
          animate ? const Duration(milliseconds: 250) : Duration.zero,
      placeholder: (context, _) => Container(color: AppColors.charcoal),
      errorWidget: (context, _, __) => Container(
        color: AppColors.charcoal,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textTertiary,
          size: 28,
        ),
      ),
    );
  }
}

/// A small centered hint used for empty sections.
class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(AppGlass.radiusCard),
        border: Border.all(color: AppGlass.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 13,
          height: 1.3,
        ),
      ),
    );
  }
}

/// Skeleton for a loading Network Discovery person tile (photo-forward grid
/// cell) — a single full-bleed shimmer that fills the cell.
class _PersonSkeleton extends StatelessWidget {
  const _PersonSkeleton({required this.animate});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    return _ShimmerBox(
      width: double.infinity,
      height: double.infinity,
      radius: AppGlass.radiusCard,
      animate: animate,
    );
  }
}

/// Skeleton for a loading "Happening this week" carousel card — matches the
/// [_HappeningCard] footprint so the loaded content slots in without a jump.
class _HappeningCardSkeleton extends StatelessWidget {
  const _HappeningCardSkeleton({required this.animate});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _HappeningCard.cardWidth,
      height: _HappeningCard.cardHeight,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(AppGlass.radiusCard),
          border: Border.all(color: AppGlass.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ShimmerBox(
              width: double.infinity,
              height: 132,
              radius: 0,
              animate: animate,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ShimmerBox(
                      width: double.infinity,
                      height: 14,
                      radius: 6,
                      animate: animate,
                    ),
                    const SizedBox(height: 10),
                    _ShimmerBox(
                      width: 120,
                      height: 11,
                      radius: 6,
                      animate: animate,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A lightweight pulsing placeholder box. Static (no animation) when the user
/// prefers reduced motion.
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
    required this.animate,
  });

  final double width;
  final double height;
  final double radius;
  final bool animate;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppGlass.surfaceHi,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    );
    if (_controller == null) {
      return Opacity(opacity: 0.5, child: box);
    }
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.7).animate(_controller!),
      child: box,
    );
  }
}

/// A real person to discover, distilled from a `profiles` document. Networking
/// /cultural framing only — never dating.
class _Partner {
  const _Partner({
    required this.userId,
    required this.name,
    required this.profile,
    required this.distanceKm,
  });

  final String userId;
  final String name;
  final Profile profile; // full parsed profile — powers the NetworkGridCard
  final double distanceKm; // distance from the current user (0 == unknown)
}

/// A single "Happening this week" item — either a community/user-created
/// [Event] (preferred) or a read-only external [ExternalEvent] experience. A
/// thin adapter so the hero and the card row can render both uniformly.
class _Happening {
  const _Happening._({this.community, this.external});

  factory _Happening.community(Event e) => _Happening._(community: e);
  factory _Happening.external(ExternalEvent e) => _Happening._(external: e);

  final Event? community;
  final ExternalEvent? external;

  /// Stable identity used to keep the featured item out of the row.
  String get key => community?.id ?? external?.id ?? '';

  String? get title => community?.title ?? external?.title;
  String? get city => community?.city ?? external?.city;
  String? get country => community?.country ?? external?.country;

  /// Latitude/longitude of the experience, when known — used to keep the
  /// featured carousel within [_ExploreScreenState.kFeaturedRadiusKm] km.
  double? get lat => community?.latitude ?? external?.lat;
  double? get lng => community?.longitude ?? external?.lng;

  /// The event/experience image, if any — used by the vertical list thumbnail.
  String? get imageUrl => community?.imageUrl ?? external?.imageUrl;

  /// Ratings/prices/source labels only exist for external experiences.
  double? get rating => external?.rating;
  double? get fromPrice => external?.fromPrice;
  String? get currency => external?.currency;
  String? get sourceLabel => external?.sourceLabel;

  DateTime? get date {
    final e = external;
    if (community != null) return community!.startDate;
    if (e?.startDate != null && e!.startDate!.isNotEmpty) {
      return DateTime.tryParse(e.startDate!);
    }
    return null;
  }

  /// True only for a community event that is boosted/featured right now.
  bool get isCurrentlyFeatured => community?.isCurrentlyFeatured ?? false;

  /// Number of people going — community events only (external experiences carry
  /// no attendee data, so this is 0 for them and the UI hides the label).
  int get goingCount => community?.goingCount ?? 0;
}
