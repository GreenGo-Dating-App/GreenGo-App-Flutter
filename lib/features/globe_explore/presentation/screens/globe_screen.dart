import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../domain/entities/globe_user.dart';
import '../bloc/globe_bloc.dart';
import '../bloc/globe_event.dart';
import '../bloc/globe_state.dart';
import '../widgets/globe_map_view.dart';
import '../widgets/globe_country_search.dart';

class GlobeScreen extends StatelessWidget {
  final String userId;

  const GlobeScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    context.read<GlobeBloc>().add(GlobeLoadRequested(userId: userId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.globeMyNetwork,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
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
    List<String> countries = [];
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
              style: TextStyle(
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
  final Color? color;
  final IconData? icon;
  final String label;

  const _LegendItem({this.color, this.icon, required this.label});

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
