import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/error/failures.dart';
import '../../../../core/utils/geo_query.dart';
import '../../../../generated/app_localizations.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../events/data/datasources/events_remote_datasource.dart';
import '../../../events/data/datasources/external_events_data_source.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/domain/entities/event_country_stat.dart';
import '../../../events/domain/entities/external_event.dart';
import '../../../events/domain/repositories/events_repository.dart';
import '../../../events/presentation/screens/event_detail_loader_screen.dart';
import '../../data/country_centroids.dart';
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../domain/entities/globe_user.dart';
import '../bloc/globe_bloc.dart';
import '../bloc/globe_event.dart';
import '../bloc/globe_state.dart';
import '../widgets/globe_country_search.dart';
import '../widgets/globe_map_view.dart';

class GlobeScreen extends StatefulWidget {
  const GlobeScreen({required this.userId, super.key});
  final String userId;

  @override
  State<GlobeScreen> createState() => _GlobeScreenState();
}

class _GlobeScreenState extends State<GlobeScreen> {
  /// Exposed so the existing helper methods keep using `userId` unchanged.
  String get userId => widget.userId;

  /// World-map layers (independent, any combination):
  /// My Community (contacts), Community Events (native, precise pins),
  /// Attractions (Tiqets), Experiences (Viator).
  bool _showContacts = true;
  bool _showCommunityEvents = false;
  bool _showLiveEvents = false;
  bool _showAttractions = false;
  bool _showExperiences = false;
  List<Event> _nativeEvents = const [];
  List<EventCountryStat> _experienceStats = const []; // viator
  List<EventCountryStat> _attractionStats = const []; // tiqets
  List<EventCountryStat> _liveEventStats = const []; // ticketmaster
  // Precise pins for the most-recently-tapped country (mini-image markers).
  List<ExternalEvent> _countryPins = const [];

  // Per-coordinate event dots for the CURRENT viewport (no country aggregation).
  final ExternalEventsDataSource _extDs = ExternalEventsDataSource();
  final EventsRemoteDataSourceImpl _nativeDs = EventsRemoteDataSourceImpl();
  List<ExternalEvent> _viewportExternal = const [];
  List<Event> _viewportCommunity = const [];
  int _viewportGen = 0;
  double? _vpLat, _vpLng, _vpRadius;
  // Last viewport actually loaded — used to skip redundant reloads when the map
  // emits onPositionChanged without a real move (prevents a refresh loop).
  double? _loadedLat, _loadedLng, _loadedRadius;

  @override
  void initState() {
    super.initState();
    // Load globe data ONCE. (Previously dispatched from build(), which re-fired
    // on every rebuild — so each layer toggle reloaded the bloc, flashed the
    // loading spinner, recreated the map and reset the view, making it look like
    // only one layer showed at a time.)
    context.read<GlobeBloc>().add(GlobeLoadRequested(userId: userId));
  }

  /// Load per-coordinate event dots for the visible area (debounced upstream).
  /// [force] bypasses the "did the viewport actually move?" guard (used by
  /// layer toggles, which must re-query even at the same position).
  Future<void> _loadViewport(double lat, double lng, double radiusM,
      {bool force = false}) async {
    // Skip if the camera hasn't meaningfully moved since the last load.
    // flutter_map fires onPositionChanged repeatedly (incl. without gestures),
    // so without this guard the globe re-queries + setState's continuously.
    if (!force && _loadedLat != null && _loadedRadius != null) {
      final moved = GeoQuery.distanceMeters(_loadedLat!, _loadedLng!, lat, lng);
      final radiusDelta = (_loadedRadius! - radiusM).abs();
      if (moved < _loadedRadius! * 0.15 &&
          radiusDelta < _loadedRadius! * 0.15) {
        _vpLat = lat;
        _vpLng = lng;
        _vpRadius = radiusM;
        return;
      }
    }
    _vpLat = lat;
    _vpLng = lng;
    _vpRadius = radiusM;
    final gen = ++_viewportGen;
    // External layers (each enabled source), within the viewport.
    final futures = <Future<List<ExternalEvent>>>[];
    if (_showAttractions) {
      futures.add(_extDs.getInBounds(
          source: 'geoapify', lat: lat, lng: lng, radiusM: radiusM));
    }
    if (_showExperiences) {
      futures.add(_extDs.getInBounds(
          source: 'viator', lat: lat, lng: lng, radiusM: radiusM));
    }
    if (_showLiveEvents) {
      futures.add(_extDs.getInBounds(
          source: 'ticketmaster', lat: lat, lng: lng, radiusM: radiusM));
    }
    final external =
        (await Future.wait(futures)).expand((e) => e).toList();
    // Public community events nearby (getNearbyCommunityEvents filters private).
    List<Event> community = const [];
    if (_showCommunityEvents) {
      community = await _nativeDs.getNearbyCommunityEvents(
          lat: lat, lng: lng, limit: 200);
    }
    if (!mounted || gen != _viewportGen) return;
    _loadedLat = lat;
    _loadedLng = lng;
    _loadedRadius = radiusM;
    setState(() {
      _viewportExternal = external;
      _viewportCommunity = community;
    });
  }

  /// Re-load the current viewport after a layer toggle (force past the
  /// no-movement guard, since the enabled sources changed).
  void _reloadViewport() {
    if (_vpLat != null && _vpLng != null && _vpRadius != null) {
      _loadViewport(_vpLat!, _vpLng!, _vpRadius!, force: true);
    }
  }

  /// Per-country counts from the precomputed aggregate (complete + cheap).
  Future<void> _loadCountryStats(String source) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('external_country_stats')
          .where('source', isEqualTo: source)
          .get();
      if (!mounted) return;
      final stats = snap.docs
          .map((d) => EventCountryStat(
                country: d.data()['country'] as String? ?? '',
                count: (d.data()['count'] as num?)?.toInt() ?? 0,
              ))
          .where((s) => s.country.isNotEmpty)
          .toList();
      setState(() {
        if (source == 'viator') {
          _experienceStats = stats;
        } else if (source == 'geoapify') {
          _attractionStats = stats;
        } else {
          _liveEventStats = stats;
        }
      });
    } catch (_) {/* best-effort */}
  }

  /// Country markers to show: attractions and/or experiences per the toggles.
  List<EventCountryStat> get _activeStats {
    final merged = <String, EventCountryStat>{};
    void add(List<EventCountryStat> list) {
      for (final s in list) {
        final e = merged[s.country];
        merged[s.country] = EventCountryStat(
          country: s.country,
          count: (e?.count ?? 0) + s.count,
        );
      }
    }

    if (_showAttractions) add(_attractionStats);
    if (_showExperiences) add(_experienceStats);
    if (_showLiveEvents) add(_liveEventStats);
    return merged.values.toList();
  }

  /// Load precise pins for a country so zooming in reveals individual
  /// experiences/attractions with mini-image previews.
  Future<void> _loadCountryPins(String country) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('external_events')
          .where('country', isEqualTo: country)
          .limit(200)
          .get();
      final items = snap.docs
          .map(ExternalEvent.fromFirestore)
          .where((e) => e.lat != null && e.lng != null)
          .toList();
      if (mounted) setState(() => _countryPins = items);
    } catch (_) {/* best-effort */}
  }

  Widget _externalTile(ExternalEvent e) => ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 48,
            height: 48,
            child: (e.imageUrl != null && e.imageUrl!.isNotEmpty)
                ? Image(
                    image: CachedNetworkImageProvider(e.imageUrl!),
                    fit: BoxFit.cover)
                : Container(
                    color: AppColors.backgroundInput,
                    child: const Icon(Icons.local_activity,
                        color: AppColors.textTertiary)),
          ),
        ),
        title: Text(e.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        subtitle: Text(
          [
            if (e.city != null && e.city!.isNotEmpty) e.city!,
            if (e.rating != null && e.rating! > 0) '⭐ ${e.rating}',
            if (e.fromPrice != null)
              '${e.currency ?? ''} ${e.fromPrice!.toStringAsFixed(0)}',
          ].join('  ·  '),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing:
            const Icon(Icons.open_in_new, color: AppColors.richGold, size: 18),
        onTap: e.bookingUrl.isEmpty
            ? null
            : () => launchUrl(Uri.parse(e.bookingUrl),
                mode: LaunchMode.externalApplication),
      );

  /// Sheet listing a group of co-located items (tapping a multi-item pin).
  void _showItemsSheet(BuildContext context, List<ExternalEvent> items) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, sc) => ListView(
            controller: sc,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Text(items.first.city ?? '',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              ...items.map(_externalTile),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Tap a country → list its Experiences + Attractions (queried directly, so
  /// it's complete regardless of which markers are on the map).
  Future<void> _showCountryDetailSheet(
      BuildContext context, String country) async {
    final snap = await FirebaseFirestore.instance
        .collection('external_events')
        .where('country', isEqualTo: country)
        .limit(150)
        .get();
    final all = snap.docs.map(ExternalEvent.fromFirestore).toList()
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    final exp = all.where((e) => e.source == 'viator').toList();
    final att = all.where((e) => e.source == 'geoapify').toList();
    final live = all.where((e) => e.source == 'ticketmaster').toList();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    Widget tile(ExternalEvent e) => ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: (e.imageUrl != null && e.imageUrl!.isNotEmpty)
                  ? Image(
                      image: CachedNetworkImageProvider(e.imageUrl!),
                      fit: BoxFit.cover)
                  : Container(
                      color: AppColors.backgroundInput,
                      child: const Icon(Icons.local_activity,
                          color: AppColors.textTertiary)),
            ),
          ),
          title: Text(e.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          subtitle: Text(
            [
              if (e.city != null && e.city!.isNotEmpty) e.city!,
              if (e.rating != null && e.rating! > 0) '⭐ ${e.rating}',
              if (e.fromPrice != null)
                '${e.currency ?? ''} ${e.fromPrice!.toStringAsFixed(0)}',
            ].join('  ·  '),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: const Icon(Icons.open_in_new,
              color: AppColors.richGold, size: 18),
          onTap: e.bookingUrl.isEmpty
              ? null
              : () => launchUrl(Uri.parse(e.bookingUrl),
                  mode: LaunchMode.externalApplication),
        );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, sc) => ListView(
            controller: sc,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Text(country,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              if (exp.isEmpty && att.isEmpty && live.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(l10n.eventsNoEventsFound,
                        style:
                            const TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              if (live.isNotEmpty) ...[
                _countrySectionHeader(
                    '${l10n.eventsTabLiveEvents} (${live.length})'),
                ...live.map(tile),
              ],
              if (att.isNotEmpty) ...[
                _countrySectionHeader(
                    '${l10n.eventsTabAttractions} (${att.length})'),
                ...att.map(tile),
              ],
              if (exp.isNotEmpty) ...[
                _countrySectionHeader(
                    '${l10n.eventsTabExperiences} (${exp.length})'),
                ...exp.map(tile),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countrySectionHeader(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.richGold, fontWeight: FontWeight.bold)),
      );

  /// Layers are mutually exclusive — selecting one turns all the others off
  /// ("if my network is on, all the others must be off"). Tapping the active
  /// layer again turns it off (none selected).
  void _selectLayer(String layer) {
    setState(() {
      final turningOff = (layer == 'contacts' && _showContacts) ||
          (layer == 'community' && _showCommunityEvents) ||
          (layer == 'live' && _showLiveEvents) ||
          (layer == 'attractions' && _showAttractions) ||
          (layer == 'experiences' && _showExperiences);
      _showContacts = !turningOff && layer == 'contacts';
      _showCommunityEvents = !turningOff && layer == 'community';
      _showLiveEvents = !turningOff && layer == 'live';
      _showAttractions = !turningOff && layer == 'attractions';
      _showExperiences = !turningOff && layer == 'experiences';
    });
    // Reload so the now-disabled event sources are cleared from the map.
    _reloadViewport();
  }

  /// Vertical layer-toggle panel shown on the right of the map.
  Widget _buildLayerPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget btn(IconData icon, bool active, String tooltip, VoidCallback onTap) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon,
                size: 24,
                color: active ? AppColors.richGold : AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.people, _showContacts, l10n.globeLayerContacts,
              () => _selectLayer('contacts')),
          btn(Icons.event, _showCommunityEvents,
              l10n.globeLayerCommunityEvents, () => _selectLayer('community')),
          btn(Icons.confirmation_number, _showLiveEvents,
              l10n.globeLayerLiveEvents, () => _selectLayer('live')),
          btn(Icons.museum, _showAttractions, l10n.eventsTabAttractions,
              () => _selectLayer('attractions')),
          btn(Icons.local_activity, _showExperiences,
              l10n.globeLayerExperiences, () => _selectLayer('experiences')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.globeMyWorldMap,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
          // Layer toggles moved to a vertical panel on the right of the map.
          IconButton(
            icon: const Icon(Icons.refresh,
                color: AppColors.textSecondary, size: 22),
            onPressed: () => context.read<GlobeBloc>().add(
                  GlobeRefreshRequested(userId: userId),
                ),
          ),
        ],
      ),
      body: BlocConsumer<GlobeBloc, GlobeState>(
        listener: (context, state) {
          if (state is GlobePinSelected) {
            _showUserBottomSheet(context, state.selectedUser);
          }
          if (state is GlobeCountrySelected) {
            _showCountryMatchesSheet(
              context,
              state.countryName,
              state.matchesInCountry,
            );
          }
        },
        builder: (context, state) {
          if (state is GlobeLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentGold,
              ),
            );
          }

          GlobeData? data;
          String? flyToCountry;

          if (state is GlobeLoaded) {
            data = state.data;
            flyToCountry = state.flyToCountry;
          } else if (state is GlobePinSelected) {
            data = state.data;
          } else if (state is GlobeCountrySelected) {
            data = state.data;
          }

          if (data != null) {
            return Stack(
              children: [
                GlobeMapView(
                  data: data,
                  // My world map shows only my network (people) — events are
                  // intentionally excluded to keep the map uncluttered.
                  showMatched: true,
                  showDiscovery: false,
                  flyToCountry: flyToCountry,
                  onPinTapped: (tappedUserId, pinType) {
                    context.read<GlobeBloc>().add(
                          GlobePinTapped(
                            tappedUserId: tappedUserId,
                            pinType: pinType,
                          ),
                        );
                  },
                  onCountryTapped: (country, lat, lng) {
                    context.read<GlobeBloc>().add(
                          GlobeCountryTapped(
                            countryName: country,
                            latitude: lat,
                            longitude: lng,
                          ),
                        );
                  },
                  onClusterTapped: (users) {
                    _showClusterSheet(context, users);
                  },
                ),
                // Match count badge
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people,
                              color: Color(0xFFFFD700), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.globeConnectionCount(data.matchedUsers.length),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Legend overlay
                Positioned(
                  top: 8,
                  left: 12,
                  child: _buildLegend(context),
                ),
              ],
            );
          }

          if (state is GlobeError) {
            return _buildError(state.message);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showCountrySearch(BuildContext context) {
    final state = context.read<GlobeBloc>().state;
    var countries = <String>[];
    if (state is GlobeLoaded) {
      countries = state.data.allCountries;
    } else if (state is GlobePinSelected) {
      countries = state.data.allCountries;
    }
    if (countries.isNotEmpty) {
      GlobeCountrySearch.show(context, countries);
    }
  }

  Widget _buildLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(color: Colors.red, label: l10n.globeYou),
          _LegendItem(color: const Color(0xFFFFD700), label: l10n.globeConnections),
          _LegendItem(icon: Icons.flight, label: l10n.globeTraveler),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.errorRed, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToProfile(
      BuildContext context, String targetUserId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(targetUserId)
          .get();
      if (!doc.exists || !context.mounted) return;
      final profile = ProfileModel.fromFirestore(doc);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileDetailScreen(
            profile: profile,
            currentUserId: userId,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _navigateToChat(
      BuildContext context, String matchId, String otherUserId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(otherUserId)
          .get();
      if (!doc.exists || !context.mounted) return;
      final profile = ProfileModel.fromFirestore(doc);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            matchId: matchId,
            currentUserId: userId,
            otherUserId: otherUserId,
            otherUserProfile: profile,
          ),
        ),
      );
    } catch (_) {}
  }

  void _showUserBottomSheet(BuildContext context, GlobeUser user) {
    if (user.pinType == GlobePinType.currentUser) {
      _showSelfSheet(context, user);
      return;
    }

    // Only matched users appear on the map — show Profile + Chat
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Photo + info
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: user.photoUrl != null
                      ? CachedNetworkImageProvider(user.photoUrl!)
                      : null,
                  backgroundColor: AppColors.backgroundCard,
                  child: user.photoUrl == null
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.isOnline) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          if (user.isTravelerActive) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.flight,
                                color: Colors.blue, size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.city}, ${user.country}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Action buttons: Profile + Chat (matches only)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: Text(AppLocalizations.of(context)!.globeProfile),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _navigateToProfile(context, user.userId);
                    },
                  ),
                ),
                if (user.matchId != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text(AppLocalizations.of(context)!.globeChat),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _navigateToChat(
                            context, user.matchId!, user.userId);
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSelfSheet(BuildContext context, GlobeUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Show user's own photo
            CircleAvatar(
              radius: 36,
              backgroundImage: user.photoUrl != null
                  ? CachedNetworkImageProvider(user.photoUrl!)
                  : null,
              backgroundColor: AppColors.backgroundCard,
              child: user.photoUrl == null
                  ? const Icon(Icons.person, color: Colors.white, size: 36)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.globeThisIsYou,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.country,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            if (user.isTravelerActive) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flight, color: Colors.blue, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.globeTravelingTo(user.travelerCountry ?? user.country),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showClusterSheet(BuildContext context, List<GlobeUser> users) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.people,
                      color: Color(0xFFFFD700), size: 24),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.globeConnectionsHere(users.length),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: users.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (ctx, i) =>
                    _buildCountryMatchTile(context, users[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top public events in a country, shown in the country tap sheet.
  Widget _buildCountryEventsSection(BuildContext context, String countryName) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<Either<Failure, List<Event>>>(
      future:
          di.sl<EventsRepository>().getEventsByCountry(countryName, limit: 10),
      builder: (context, snapshot) {
        final events =
            snapshot.data?.fold((_) => <Event>[], (e) => e) ?? const <Event>[];
        if (events.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.event, color: AppColors.richGold, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    l10n.eventsTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) =>
                    _buildCountryEventCard(context, events[i]),
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),
          ],
        );
      },
    );
  }

  Widget _buildCountryEventCard(BuildContext context, Event e) {
    final l10n = AppLocalizations.of(context)!;
    Widget cover() => (e.imageUrl != null && e.imageUrl!.isNotEmpty)
        ? Image.network(e.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
                color: AppColors.backgroundDark,
                child: const Icon(Icons.event, color: AppColors.richGold)))
        : Container(
            color: AppColors.backgroundDark,
            child: const Icon(Icons.event, color: AppColors.richGold));
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        EventDetailLoaderScreen.route(eventId: e.id, currentUserId: userId),
      ),
      child: SizedBox(
        width: 150,
        child: Card(
          color: AppColors.backgroundCard,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 80, width: double.infinity, child: cover()),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(l10n.eventsGoing(e.goingCount),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountryMatchesSheet(
    BuildContext context,
    String countryName,
    List<GlobeUser> matches,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          countryName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          matches.isEmpty
                              ? AppLocalizations.of(context)!.globeNoConnectionsInCountry(countryName)
                              : AppLocalizations.of(context)!.globeConnectionsHere(matches.length),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (matches.isNotEmpty)
                    const Icon(Icons.people,
                        color: Color(0xFFFFD700), size: 24),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),
            // Events happening in this country (globe "Network & Events").
            _buildCountryEventsSection(context, countryName),
            Expanded(
              child: matches.isEmpty
                  ? _buildNoMatchesInCountry(context, countryName)
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: matches.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (ctx, i) =>
                          _buildCountryMatchTile(context, matches[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchesInCountry(BuildContext context, String countryName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_off,
                color: AppColors.textTertiary, size: 48),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.globeNoConnectionsInCountry(countryName),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.globeNoConnectionsHint,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryMatchTile(BuildContext context, GlobeUser match) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: match.photoUrl != null
            ? CachedNetworkImageProvider(match.photoUrl!)
            : null,
        backgroundColor: AppColors.backgroundCard,
        child: match.photoUrl == null
            ? Text(
                match.displayName.isNotEmpty
                    ? match.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: AppColors.textPrimary),
              )
            : null,
      ),
      title: Row(
        children: [
          Text(
            match.displayName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          if (match.isOnline)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          if (match.isTravelerActive) ...[
            const SizedBox(width: 6),
            const Icon(Icons.flight, color: Colors.blue, size: 16),
          ],
        ],
      ),
      subtitle: Text(
        match.city,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.person_outline,
                color: AppColors.textSecondary, size: 20),
            onPressed: () async {
              Navigator.pop(context);
              await _navigateToProfile(context, match.userId);
            },
            tooltip: AppLocalizations.of(context)!.globeViewProfileTooltip,
          ),
          if (match.matchId != null)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline,
                  color: Color(0xFFFFD700), size: 20),
              onPressed: () async {
                Navigator.pop(context);
                await _navigateToChat(
                    context, match.matchId!, match.userId);
              },
              tooltip: AppLocalizations.of(context)!.globeOpenChatTooltip,
            ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {

  const _LegendItem({required this.label, this.color, this.icon});
  final Color? color;
  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color != null)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          if (icon != null)
            Icon(icon, color: Colors.blue, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
