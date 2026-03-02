import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../bloc/explore_map_bloc.dart';
import '../bloc/explore_map_event.dart';
import '../bloc/explore_map_state.dart';
import '../../domain/entities/map_user.dart';

/// Explore Map Screen — List-based nearby users view.
///
/// Shows people near the current user, sorted by distance,
/// with a radius selector, online status, match percentage,
/// shared languages, and a "Show me on map" opt-in toggle.
class ExploreMapScreen extends StatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen> {
  double _selectedRadius = 5.0; // Default 5km
  final List<double> _radiusOptions = [1, 5, 10, 25];

  @override
  void initState() {
    super.initState();
    _loadNearbyUsers();
  }

  void _loadNearbyUsers() {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      final profile = profileState.profile;
      final loc = profile.effectiveLocation;
      context.read<ExploreMapBloc>().add(LoadNearbyUsers(
            userId: profile.userId,
            latitude: loc.latitude,
            longitude: loc.longitude,
            radiusKm: _selectedRadius,
            currentUserLanguages: profile.languages,
          ));
    }
  }

  void _refreshNearbyUsers() {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      final profile = profileState.profile;
      final loc = profile.effectiveLocation;
      context.read<ExploreMapBloc>().add(RefreshMap(
            userId: profile.userId,
            latitude: loc.latitude,
            longitude: loc.longitude,
            radiusKm: _selectedRadius,
            currentUserLanguages: profile.languages,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'People Near You',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Show on map toggle
          BlocBuilder<ExploreMapBloc, ExploreMapState>(
            builder: (context, state) {
              final showOnMap =
                  state is ExploreMapLoaded ? state.showOnMap : true;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Visible',
                    style: TextStyle(
                      color: showOnMap
                          ? AppColors.successGreen
                          : AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  Switch(
                    value: showOnMap,
                    activeColor: AppColors.successGreen,
                    inactiveThumbColor: AppColors.textTertiary,
                    inactiveTrackColor: AppColors.divider,
                    onChanged: (value) {
                      final profileState =
                          context.read<ProfileBloc>().state;
                      if (profileState is ProfileLoaded) {
                        context.read<ExploreMapBloc>().add(
                              ToggleShowOnMap(
                                userId: profileState.profile.userId,
                                showOnMap: value,
                              ),
                            );
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Radius selector chips
          _buildRadiusSelector(),
          const Divider(color: AppColors.divider, height: 1),
          // User list
          Expanded(
            child: BlocBuilder<ExploreMapBloc, ExploreMapState>(
              builder: (context, state) {
                if (state is ExploreMapLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.richGold,
                    ),
                  );
                }

                if (state is ExploreMapError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.errorRed,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Could not load nearby users',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadNearbyUsers,
                          child: const Text(
                            'Try Again',
                            style: TextStyle(color: AppColors.richGold),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ExploreMapLoaded) {
                  if (state.users.isEmpty) {
                    return _buildEmptyState();
                  }
                  return RefreshIndicator(
                    color: AppColors.richGold,
                    backgroundColor: AppColors.backgroundCard,
                    onRefresh: () async {
                      _refreshNearbyUsers();
                      // Wait briefly for the bloc to process
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: state.users.length,
                      itemBuilder: (context, index) {
                        return _buildUserCard(state.users[index]);
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.backgroundDark,
      child: Row(
        children: [
          const Icon(
            Icons.radar,
            color: AppColors.richGold,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Radius:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _radiusOptions.map((radius) {
                  final isSelected = _selectedRadius == radius;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${radius.toInt()} km',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.deepBlack
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.richGold,
                      backgroundColor: AppColors.backgroundCard,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.richGold
                            : AppColors.divider,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedRadius = radius;
                          });
                          _loadNearbyUsers();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(MapUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.backgroundInput,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? const Icon(
                          Icons.person,
                          color: AppColors.textTertiary,
                          size: 28,
                        )
                      : null,
                ),
                // Online status dot
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: user.isOnline
                          ? AppColors.online
                          : AppColors.offline,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.backgroundCard,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName ?? 'Nearby User',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Match percentage badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getMatchColor(user.matchPercentage)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${user.matchPercentage}%',
                          style: TextStyle(
                            color: _getMatchColor(user.matchPercentage),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Distance
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textTertiary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '~${user.distanceKm?.toStringAsFixed(1) ?? '?'} km away',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                      if (user.isOnline) ...[
                        const SizedBox(width: 12),
                        const Text(
                          'Online now',
                          style: TextStyle(
                            color: AppColors.online,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Shared languages
                  if (user.languagesShared.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: user.languagesShared.map((lang) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.infoBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lang,
                            style: const TextStyle(
                              color: AppColors.infoBlue,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Chevron
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_outlined,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
              size: 72,
            ),
            const SizedBox(height: 16),
            const Text(
              'No one nearby',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try increasing your search radius to find more people.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  // Jump to next larger radius
                  final currentIndex =
                      _radiusOptions.indexOf(_selectedRadius);
                  if (currentIndex < _radiusOptions.length - 1) {
                    _selectedRadius = _radiusOptions[currentIndex + 1];
                  }
                });
                _loadNearbyUsers();
              },
              icon: const Icon(Icons.zoom_out_map, size: 18),
              label: const Text('Expand Radius'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.richGold,
                side: const BorderSide(color: AppColors.richGold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMatchColor(int percentage) {
    if (percentage >= 70) return AppColors.successGreen;
    if (percentage >= 40) return AppColors.warningAmber;
    return AppColors.textTertiary;
  }
}
