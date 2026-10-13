import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/error/failures.dart';
import '../../../../core/utils/country_names_l10n.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../core/widgets/interactive_location_map.dart'
    show LocationMapColors;
import '../../../../generated/app_localizations.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/domain/repositories/events_repository.dart';
import '../../../events/presentation/screens/event_detail_loader_screen.dart';
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../data/country_centroids.dart';
import '../../domain/entities/globe_user.dart';
import '../bloc/globe_bloc.dart';
import '../bloc/globe_event.dart';
import '../bloc/globe_state.dart';
import '../widgets/globe_country_search.dart';
import '../widgets/globe_map_view.dart';
import '../widgets/globe_markers.dart';

/// "My World Map": where the user's network is, on the app's shared map.
///
/// The map itself is [GlobeMapView]; this screen owns the bloc wiring, the
/// light app bar (country search, refresh), the legend and connection-count
/// overlays, and the sheets a tap opens (person, cluster, country with its
/// events).
class GlobeScreen extends StatefulWidget {
  const GlobeScreen({required this.userId, super.key});
  final String userId;

  @override
  State<GlobeScreen> createState() => _GlobeScreenState();
}

class _GlobeScreenState extends State<GlobeScreen> {
  /// Exposed so the existing helper methods keep using `userId` unchanged.
  String get userId => widget.userId;

  /// Country tap sheet's events, one future per country for this screen.
  final Map<String, Future<Either<Failure, List<Event>>>> _countryEvents = {};

  @override
  void initState() {
    super.initState();
    // Load globe data ONCE (dispatching from build() re-fired on every
    // rebuild, recreating the map and resetting the view).
    context.read<GlobeBloc>().add(GlobeLoadRequested(userId: userId));
  }

  /// The data behind whichever state the bloc is in, or null while loading.
  static GlobeData? _dataOf(GlobeState state) => switch (state) {
        GlobeLoaded(:final data) => data,
        GlobePinSelected(:final data) => data,
        GlobeCountrySelected(:final data) => data,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: LocationMapColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        title: Text(l10n.globeMyWorldMap,
            style: const TextStyle(color: AppColors.textPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            key: const ValueKey('globe-country-search'),
            icon: const Icon(Icons.search, size: 22),
            tooltip: l10n.globeSearchCountryTooltip,
            onPressed: () => _showCountrySearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: l10n.refresh,
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
          if (state is GlobeError) return _buildError(state.message);
          final data = _dataOf(state);
          if (data == null) {
            return const Center(
              child: CircularProgressIndicator(color: LocationMapColors.gold),
            );
          }
          final fly = state is GlobeLoaded ? state : null;
          return Stack(
            children: [
              Positioned.fill(
                child: GlobeMapView(
                  data: data,
                  flyToCountry: fly?.flyToCountry,
                  flyRequestId: fly?.flyRequestId ?? 0,
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
                  onClusterTapped: (users) => _showClusterSheet(context, users),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: _MapChip(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LegendItem(color: kGlobeSelfColor, label: l10n.globeYou),
                      _LegendItem(
                          color: LocationMapColors.gold,
                          label: l10n.globeConnections),
                      _LegendItem(
                          icon: Icons.flight, label: l10n.globeTraveler),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 22,
                left: 0,
                right: 0,
                child: Center(
                  child: _MapChip(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people,
                            color: LocationMapColors.goldDark, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          l10n.globeConnectionCount(data.matchedUsers.length),
                          style: const TextStyle(
                            color: LocationMapColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Search every country we can place on the map (plus any network country
  /// the centroid table lacks); picking one flies the map there.
  void _showCountrySearch(BuildContext context) {
    final data = _dataOf(context.read<GlobeBloc>().state);
    final countries = <String>{
      ...countryCentroids.keys,
      if (data != null) ...data.allCountries,
    }..remove('Unknown');
    GlobeCountrySearch.show(context, countries.toList());
  }

  /// 'Unknown' is the data-layer placeholder for a missing name/city/country.
  String _orUnknown(BuildContext context, String value) => value == 'Unknown'
      ? AppLocalizations.of(context)!.chatUnknown
      : value;

  /// Localized display name for a stored (English) country value.
  String _countryLabel(BuildContext context, String country) => _orUnknown(
      context, localizedCountryName(AppLocalizations.of(context)!, country));

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
              userErrorMessage(context, message),
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
                      ? ResizeImage(CachedNetworkImageProvider(user.photoUrl!),
                          width: 128, policy: ResizeImagePolicy.fit)
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
                              _orUnknown(context, user.displayName),
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
                        '${_orUnknown(context, user.city)}, ${_countryLabel(context, user.country)}',
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
                  ? ResizeImage(CachedNetworkImageProvider(user.photoUrl!),
                      width: 144, policy: ResizeImagePolicy.fit)
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
              _countryLabel(context, user.country),
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
                    AppLocalizations.of(context)!.globeTravelingTo(_countryLabel(context, user.travelerCountry ?? user.country)),
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
      // Created ONCE per country: this lives inside a DraggableScrollableSheet
      // builder, which rebuilds on every drag frame — a future made here
      // re-ran the query each frame.
      future: _countryEvents.putIfAbsent(
          countryName,
          () => di
              .sl<EventsRepository>()
              .getEventsByCountry(countryName, limit: 10)),
      builder: (context, snapshot) {
        final events =
            (snapshot.data?.fold((_) => <Event>[], (e) => e) ?? const <Event>[])
                // Auto-publish gate (defensive): drafts / not-yet-due scheduled
                // events never leak into discovery. The datasource already
                // filters; guard here too (see Event.isLive).
                .where((e) => e.isLive)
                .toList();
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
        ? CachedNetworkImage(
            imageUrl: e.imageUrl!,
            fit: BoxFit.cover,
            memCacheWidth: 300, // 150-wide card, ~2x
            errorWidget: (_, __, ___) => Container(
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
                          localizedCountryName(
                              AppLocalizations.of(context)!, countryName),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          matches.isEmpty
                              ? AppLocalizations.of(context)!.globeNoConnectionsInCountry(localizedCountryName(AppLocalizations.of(context)!, countryName))
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
              AppLocalizations.of(context)!.globeNoConnectionsInCountry(localizedCountryName(AppLocalizations.of(context)!, countryName)),
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
            ? ResizeImage(CachedNetworkImageProvider(match.photoUrl!),
                width: 96, policy: ResizeImagePolicy.fit)
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
            _orUnknown(context, match.displayName),
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
        _orUnknown(context, match.city),
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

/// Translucent white card for overlays on the map (legend, count).
class _MapChip extends StatelessWidget {
  const _MapChip({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: LocationMapColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LocationMapColors.border),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4)],
      ),
      child: child,
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
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          if (icon != null) Icon(icon, color: kGlobeTravelerColor, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
                color: LocationMapColors.subtext, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
