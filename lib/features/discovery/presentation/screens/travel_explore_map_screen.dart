import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../chat/presentation/widgets/language_badge.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/domain/entities/profile.dart';
import '../widgets/local_guide_badge.dart';
import '../widgets/traveler_overlay.dart';
import 'profile_detail_screen.dart';

/// Travel Explore Map Screen
///
/// A full-screen list view showing traveler profiles organized by city.
/// Sections: "Travelers in your city" and "Travelers worldwide".
/// Each card shows: photo, name, origin city, languages, distance.
/// Filter toggle: "In my city" / "Worldwide".
class TravelExploreMapScreen extends StatefulWidget {
  final String userId;
  final Profile? currentUserProfile;

  const TravelExploreMapScreen({
    super.key,
    required this.userId,
    this.currentUserProfile,
  });

  @override
  State<TravelExploreMapScreen> createState() => _TravelExploreMapScreenState();
}

enum _TravelFilter { inMyCity, worldwide }

class _TravelExploreMapScreenState extends State<TravelExploreMapScreen> {
  _TravelFilter _filter = _TravelFilter.worldwide;
  bool _isLoading = true;
  List<Profile> _travelers = [];
  List<Profile> _localGuides = [];
  String? _error;

  String get _userCity =>
      widget.currentUserProfile?.effectiveLocation.city ?? '';

  @override
  void initState() {
    super.initState();
    _loadTravelers();
  }

  Future<void> _loadTravelers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Query active travelers (isTraveler == true)
      final travelerQuery = await firestore
          .collection('profiles')
          .where('isTraveler', isEqualTo: true)
          .limit(200)
          .get();

      final travelers = <Profile>[];
      for (final doc in travelerQuery.docs) {
        try {
          final profile = ProfileModel.fromFirestore(doc);
          // Only include active travelers (expiry still valid)
          if (profile.isTravelerActive && profile.userId != widget.userId) {
            travelers.add(profile);
          }
        } catch (_) {
          // Skip invalid profiles
        }
      }

      // Query local guides
      final guideQuery = await firestore
          .collection('profiles')
          .where('isLocalGuide', isEqualTo: true)
          .limit(200)
          .get();

      final guides = <Profile>[];
      for (final doc in guideQuery.docs) {
        try {
          final profile = ProfileModel.fromFirestore(doc);
          if (profile.isLocalGuide && profile.userId != widget.userId) {
            guides.add(profile);
          }
        } catch (_) {
          // Skip invalid profiles
        }
      }

      if (mounted) {
        setState(() {
          _travelers = travelers;
          _localGuides = guides;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Get travelers filtered by the current filter mode
  List<Profile> get _filteredTravelers {
    if (_filter == _TravelFilter.worldwide) return _travelers;

    // Filter to travelers in the user's city
    return _travelers.where((t) {
      final travelerCity =
          t.effectiveLocation.city.toLowerCase().trim();
      return travelerCity == _userCity.toLowerCase().trim() &&
          _userCity.isNotEmpty;
    }).toList();
  }

  /// Get local guides filtered by the current filter mode
  List<Profile> get _filteredLocalGuides {
    if (_filter == _TravelFilter.worldwide) return _localGuides;

    return _localGuides.where((g) {
      final guideCity = (g.localGuideCity ?? '').toLowerCase().trim();
      return guideCity == _userCity.toLowerCase().trim() &&
          _userCity.isNotEmpty;
    }).toList();
  }

  /// Group travelers by their effective city
  Map<String, List<Profile>> get _travelersByCity {
    final map = <String, List<Profile>>{};
    for (final t in _filteredTravelers) {
      final city = t.effectiveLocation.city.isNotEmpty
          ? t.effectiveLocation.city
          : 'Unknown';
      map.putIfAbsent(city, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.explore, color: AppColors.richGold, size: 22),
            SizedBox(width: 8),
            Text(
              'Travel Explore',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadTravelers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter toggle
          _buildFilterToggle(),
          const SizedBox(height: 4),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.richGold),
                    ),
                  )
                : _error != null
                    ? _buildErrorState()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _buildFilterButton(
            'In my city',
            Icons.location_city,
            _TravelFilter.inMyCity,
          ),
          _buildFilterButton(
            'Worldwide',
            Icons.public,
            _TravelFilter.worldwide,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
      String label, IconData icon, _TravelFilter filter) {
    final isActive = _filter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _filter = filter);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.richGold : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed, size: 48),
          const SizedBox(height: 16),
          Text(
            'Could not load travelers',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadTravelers,
            child: const Text(
              'Try again',
              style: TextStyle(color: AppColors.richGold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final travelers = _filteredTravelers;
    final guides = _filteredLocalGuides;
    final travelersByCity = _travelersByCity;

    if (travelers.isEmpty && guides.isEmpty) {
      return _buildEmptyState();
    }

    // Build the list of city sections
    final List<Widget> sections = [];

    // Stats bar
    sections.add(_buildStatsBar(travelers.length, guides.length));
    sections.add(const SizedBox(height: 16));

    // Travelers in user's city (highlighted at top when worldwide filter)
    if (_filter == _TravelFilter.worldwide && _userCity.isNotEmpty) {
      final inMyCity = travelers.where((t) {
        return t.effectiveLocation.city.toLowerCase().trim() ==
            _userCity.toLowerCase().trim();
      }).toList();
      if (inMyCity.isNotEmpty) {
        sections.add(_buildSectionHeader(
          'Travelers in $_userCity',
          Icons.location_city,
          inMyCity.length,
        ));
        sections.add(const SizedBox(height: 8));
        for (final t in inMyCity) {
          sections.add(_buildTravelerCard(t));
        }
        sections.add(const SizedBox(height: 20));
      }
    }

    // All travelers by city
    for (final entry in travelersByCity.entries) {
      final city = entry.key;
      final cityTravelers = entry.value;
      // Skip the "in my city" section if already shown above
      if (_filter == _TravelFilter.worldwide &&
          city.toLowerCase().trim() == _userCity.toLowerCase().trim()) {
        continue;
      }
      sections.add(_buildSectionHeader(
        'Travelers in $city',
        Icons.flight_land,
        cityTravelers.length,
      ));
      sections.add(const SizedBox(height: 8));
      for (final t in cityTravelers) {
        sections.add(_buildTravelerCard(t));
      }
      sections.add(const SizedBox(height: 20));
    }

    // Local guides section
    if (guides.isNotEmpty) {
      sections.add(_buildSectionHeader(
        'Local Guides',
        Icons.shield,
        guides.length,
      ));
      sections.add(const SizedBox(height: 8));
      for (final g in guides) {
        sections.add(_buildLocalGuideCard(g));
      }
      sections.add(const SizedBox(height: 20));
    }

    sections.add(const SizedBox(height: 40));

    return RefreshIndicator(
      color: AppColors.richGold,
      backgroundColor: AppColors.backgroundCard,
      onRefresh: _loadTravelers,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: sections,
      ),
    );
  }

  Widget _buildStatsBar(int travelerCount, int guideCount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(Icons.flight, 'Travelers', travelerCount, const Color(0xFF1E88E5)),
          Container(width: 1, height: 30, color: AppColors.divider),
          _buildStatItem(Icons.shield, 'Guides', guideCount, const Color(0xFF43A047)),
          Container(width: 1, height: 30, color: AppColors.divider),
          _buildStatItem(Icons.public, 'Cities',
              _travelersByCity.length, AppColors.richGold),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, int count, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, color: AppColors.richGold, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.richGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.richGold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTravelerCard(Profile profile) {
    final originCity = profile.location.city.isNotEmpty
        ? profile.location.city
        : profile.location.country;
    final travelCity = profile.effectiveLocation.city.isNotEmpty
        ? profile.effectiveLocation.city
        : profile.effectiveLocation.country;
    final photoUrl =
        profile.photoUrls.isNotEmpty ? profile.photoUrls.first : null;

    return GestureDetector(
      onTap: () => _openProfile(profile),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            // Profile photo
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 60,
                height: 60,
                child: photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.backgroundInput,
                          child: const Icon(Icons.person,
                              color: AppColors.textTertiary, size: 28),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.backgroundInput,
                          child: const Icon(Icons.person,
                              color: AppColors.textTertiary, size: 28),
                        ),
                      )
                    : Container(
                        color: AppColors.backgroundInput,
                        child: const Icon(Icons.person,
                            color: AppColors.textTertiary, size: 28),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Profile info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and age
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${profile.displayName}, ${profile.age}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Traveler overlay (compact)
                      TravelerOverlay(profile: profile, compact: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Origin -> Travel city route
                  Row(
                    children: [
                      Icon(Icons.home, size: 12,
                          color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Text(
                        originCity,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.arrow_forward,
                            size: 10, color: AppColors.textTertiary),
                      ),
                      Icon(Icons.flight_land, size: 12,
                          color: AppColors.infoBlue),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          travelCity,
                          style: const TextStyle(
                            color: AppColors.infoBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Languages
                  if (profile.languages.isNotEmpty)
                    LanguageBadge(
                      languages: profile.languages,
                      maxDisplay: 3,
                      compact: true,
                      nativeLanguage: profile.nativeLanguage,
                    ),
                ],
              ),
            ),
            // Arrow
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalGuideCard(Profile profile) {
    final city = profile.localGuideCity ?? profile.effectiveLocation.city;
    final photoUrl =
        profile.photoUrls.isNotEmpty ? profile.photoUrls.first : null;

    return GestureDetector(
      onTap: () => _openProfile(profile),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // Profile photo
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 60,
                height: 60,
                child: photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.backgroundInput,
                          child: const Icon(Icons.person,
                              color: AppColors.textTertiary, size: 28),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.backgroundInput,
                          child: const Icon(Icons.person,
                              color: AppColors.textTertiary, size: 28),
                        ),
                      )
                    : Container(
                        color: AppColors.backgroundInput,
                        child: const Icon(Icons.person,
                            color: AppColors.textTertiary, size: 28),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Profile info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name, age, and guide badge
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${profile.displayName}, ${profile.age}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      LocalGuideBadge(
                        localGuideCity: null,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Guide city
                  Row(
                    children: [
                      const Icon(Icons.shield, size: 12,
                          color: Color(0xFF43A047)),
                      const SizedBox(width: 3),
                      Text(
                        'Guide in $city',
                        style: const TextStyle(
                          color: Color(0xFF43A047),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Languages
                  if (profile.languages.isNotEmpty)
                    LanguageBadge(
                      languages: profile.languages,
                      maxDisplay: 3,
                      compact: true,
                      nativeLanguage: profile.nativeLanguage,
                    ),
                ],
              ),
            ),
            // Arrow
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _filter == _TravelFilter.inMyCity;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.location_city : Icons.flight,
            color: AppColors.textTertiary,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'No travelers in $_userCity right now'
                : 'No travelers found',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try switching to Worldwide to see all travelers'
                : 'Check back later for active travelers',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          if (isFiltered) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() => _filter = _TravelFilter.worldwide);
              },
              child: const Text(
                'Show Worldwide',
                style: TextStyle(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openProfile(Profile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileDetailScreen(
          profile: profile,
          currentUserId: widget.userId,
        ),
      ),
    );
  }
}
