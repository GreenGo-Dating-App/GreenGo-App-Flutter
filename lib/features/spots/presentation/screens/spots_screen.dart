import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../domain/entities/spot.dart';
import '../bloc/spots_bloc.dart';
import '../bloc/spots_event.dart';
import '../bloc/spots_state.dart';
import '../widgets/spot_card.dart';
import 'spot_detail_screen.dart';

/// Main screen for Cultural Spots — shows a filterable list of spots
/// in the user's current city.
///
/// Features:
/// - Category filter chips (All, Restaurant, Cafe, Cultural Site, Market, Viewpoint)
/// - Spot cards with photo, name, category badge, rating stars, review count
/// - "Add a Spot" FAB
/// - Dark theme using AppColors
class SpotsScreen extends StatefulWidget {
  const SpotsScreen({super.key});

  @override
  State<SpotsScreen> createState() => _SpotsScreenState();
}

class _SpotsScreenState extends State<SpotsScreen> {
  SpotCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadSpots();
  }

  String _getCurrentCity() {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      return profileState.profile.effectiveLocation.city;
    }
    return '';
  }

  void _loadSpots() {
    final city = _getCurrentCity();
    if (city.isNotEmpty) {
      context.read<SpotsBloc>().add(LoadSpots(
            city: city,
            category: _selectedCategory,
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
          'Cultural Spots',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Category filter chips
          _buildCategoryFilter(),
          const Divider(color: AppColors.divider, height: 1),
          // Spots list
          Expanded(
            child: BlocConsumer<SpotsBloc, SpotsState>(
              listener: (context, state) {
                if (state is SpotCreated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Spot "${state.spot.name}" created!'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                  // Reload the list
                  _loadSpots();
                }
              },
              builder: (context, state) {
                if (state is SpotsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.richGold,
                    ),
                  );
                }

                if (state is SpotsError) {
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
                        const Text(
                          'Could not load spots',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadSpots,
                          child: const Text(
                            'Try Again',
                            style: TextStyle(color: AppColors.richGold),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is SpotsLoaded) {
                  if (state.spots.isEmpty) {
                    return _buildEmptyState();
                  }
                  return RefreshIndicator(
                    color: AppColors.richGold,
                    backgroundColor: AppColors.backgroundCard,
                    onRefresh: () async {
                      _loadSpots();
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.spots.length,
                      itemBuilder: (context, index) {
                        final spot = state.spots[index];
                        return SpotCard(
                          spot: spot,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<SpotsBloc>(),
                                  child: SpotDetailScreen(spotId: spot.id),
                                ),
                              ),
                            );
                          },
                        );
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
      // Add a Spot FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSpotDialog(context),
        backgroundColor: AppColors.richGold,
        foregroundColor: AppColors.deepBlack,
        icon: const Icon(Icons.add_location_alt),
        label: const Text(
          'Add a Spot',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.backgroundDark,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "All" chip
            _buildFilterChip(null, 'All'),
            const SizedBox(width: 8),
            ...SpotCategory.values.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(cat, cat.displayName),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(SpotCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.deepBlack : AppColors.textSecondary,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.richGold,
      backgroundColor: AppColors.backgroundCard,
      side: BorderSide(
        color: isSelected ? AppColors.richGold : AppColors.divider,
      ),
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
        _loadSpots();
      },
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
              Icons.place_outlined,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
              size: 72,
            ),
            const SizedBox(height: 16),
            const Text(
              'No spots found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory != null
                  ? 'No ${_selectedCategory!.displayName.toLowerCase()} spots in this city yet. Be the first to add one!'
                  : 'No cultural spots in this city yet. Be the first to add one!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSpotDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    SpotCategory selectedCategory = SpotCategory.restaurant;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
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
                    const SizedBox(height: 20),
                    const Text(
                      'Add a New Spot',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Name field
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Spot Name',
                        labelStyle:
                            const TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.backgroundInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.richGold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description field
                    TextField(
                      controller: descriptionController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle:
                            const TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.backgroundInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.richGold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category selector
                    const Text(
                      'Category',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SpotCategory.values.map((cat) {
                        final isActive = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(
                            cat.displayName,
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.deepBlack
                                  : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          selected: isActive,
                          selectedColor: AppColors.richGold,
                          backgroundColor: AppColors.backgroundInput,
                          onSelected: (_) {
                            setSheetState(() {
                              selectedCategory = cat;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) return;

                          final profileState =
                              this.context.read<ProfileBloc>().state;
                          if (profileState is! ProfileLoaded) return;

                          final profile = profileState.profile;
                          final loc = profile.effectiveLocation;

                          final spot = Spot(
                            id: '',
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                            category: selectedCategory,
                            latitude: loc.latitude,
                            longitude: loc.longitude,
                            city: loc.city,
                            country: loc.country,
                            createdByUserId: profile.userId,
                            createdByName: profile.displayName,
                            createdAt: DateTime.now(),
                          );

                          this.context.read<SpotsBloc>().add(
                                CreateSpot(spot: spot),
                              );

                          Navigator.of(sheetContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: AppColors.deepBlack,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Spot',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
