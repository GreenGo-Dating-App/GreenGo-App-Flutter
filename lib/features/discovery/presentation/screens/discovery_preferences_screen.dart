import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/action_success_dialog.dart';
import '../../domain/entities/match_preferences.dart';

/// Discovery Preferences Screen
///
/// Allows users to configure their matching preferences
class DiscoveryPreferencesScreen extends StatefulWidget {
  final String userId;
  final MatchPreferences? currentPreferences;
  final Function(MatchPreferences)? onSave;

  const DiscoveryPreferencesScreen({
    super.key,
    required this.userId,
    this.currentPreferences,
    this.onSave,
  });

  @override
  State<DiscoveryPreferencesScreen> createState() =>
      _DiscoveryPreferencesScreenState();
}

class _DiscoveryPreferencesScreenState
    extends State<DiscoveryPreferencesScreen> {
  late MatchPreferences _preferences;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _preferences = widget.currentPreferences ??
        MatchPreferences.defaultFor(widget.userId);
  }

  void _updatePreferences(MatchPreferences newPreferences) {
    setState(() {
      _preferences = newPreferences;
      _hasChanges = true;
    });
  }

  Future<void> _savePreferences() async {
    if (!_hasChanges || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
            'matchPreferences': _preferences.toMap(),
          }, SetOptions(merge: true));

      // Call callback if provided
      if (widget.onSave != null) {
        widget.onSave!(_preferences);
      }

      if (mounted) {
        // Show success dialog
        await ActionSuccessDialog.showPreferencesSaved(context);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showDealBreakerDialog() {
    final availableOptions = [
      'Smoking',
      'Drinking',
      'No bio',
      'No photos',
      'Different religion',
      'Different politics',
      'Has children',
      'Wants children',
      'Long distance',
      'Non-monogamy',
    ];

    // Filter out already selected deal breakers
    final availableToAdd = availableOptions
        .where((option) => !_preferences.dealBreakers.contains(option))
        .toList();

    if (availableToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All deal breakers have been added'),
          backgroundColor: AppColors.richGold,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Add Deal Breaker',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableToAdd.length,
            itemBuilder: (context, index) {
              final option = availableToAdd[index];
              return ListTile(
                title: Text(
                  option,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  _updatePreferences(
                    _preferences.copyWith(
                      dealBreakers: [..._preferences.dealBreakers, option],
                    ),
                  );
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPickerDialog() {
    final searchController = TextEditingController();
    final countries = [
      'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola',
      'Argentina', 'Armenia', 'Australia', 'Austria', 'Azerbaijan',
      'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados', 'Belarus',
      'Belgium', 'Belize', 'Benin', 'Bhutan', 'Bolivia',
      'Bosnia and Herzegovina', 'Botswana', 'Brazil', 'Brunei', 'Bulgaria',
      'Burkina Faso', 'Burundi', 'Cambodia', 'Cameroon', 'Canada',
      'Cape Verde', 'Central African Republic', 'Chad', 'Chile', 'China',
      'Colombia', 'Comoros', 'Congo', 'Costa Rica', 'Croatia',
      'Cuba', 'Cyprus', 'Czech Republic', 'Denmark', 'Djibouti',
      'Dominican Republic', 'Ecuador', 'Egypt', 'El Salvador', 'Equatorial Guinea',
      'Eritrea', 'Estonia', 'Eswatini', 'Ethiopia', 'Fiji',
      'Finland', 'France', 'Gabon', 'Gambia', 'Georgia',
      'Germany', 'Ghana', 'Greece', 'Grenada', 'Guatemala',
      'Guinea', 'Guinea-Bissau', 'Guyana', 'Haiti', 'Honduras',
      'Hungary', 'Iceland', 'India', 'Indonesia', 'Iran',
      'Iraq', 'Ireland', 'Israel', 'Italy', 'Ivory Coast',
      'Jamaica', 'Japan', 'Jordan', 'Kazakhstan', 'Kenya',
      'Kuwait', 'Kyrgyzstan', 'Laos', 'Latvia', 'Lebanon',
      'Lesotho', 'Liberia', 'Libya', 'Liechtenstein', 'Lithuania',
      'Luxembourg', 'Madagascar', 'Malawi', 'Malaysia', 'Maldives',
      'Mali', 'Malta', 'Mauritania', 'Mauritius', 'Mexico',
      'Moldova', 'Monaco', 'Mongolia', 'Montenegro', 'Morocco',
      'Mozambique', 'Myanmar', 'Namibia', 'Nepal', 'Netherlands',
      'New Zealand', 'Nicaragua', 'Niger', 'Nigeria', 'North Korea',
      'North Macedonia', 'Norway', 'Oman', 'Pakistan', 'Panama',
      'Papua New Guinea', 'Paraguay', 'Peru', 'Philippines', 'Poland',
      'Portugal', 'Qatar', 'Romania', 'Russia', 'Rwanda',
      'Saudi Arabia', 'Senegal', 'Serbia', 'Sierra Leone', 'Singapore',
      'Slovakia', 'Slovenia', 'Somalia', 'South Africa', 'South Korea',
      'South Sudan', 'Spain', 'Sri Lanka', 'Sudan', 'Suriname',
      'Sweden', 'Switzerland', 'Syria', 'Taiwan', 'Tajikistan',
      'Tanzania', 'Thailand', 'Togo', 'Trinidad and Tobago', 'Tunisia',
      'Turkey', 'Turkmenistan', 'Uganda', 'Ukraine', 'United Arab Emirates',
      'United Kingdom', 'United States', 'Uruguay', 'Uzbekistan', 'Venezuela',
      'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe',
    ];

    // Filter out already selected countries
    final availableCountries = countries
        .where((c) => !_preferences.preferredCountries.contains(c))
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final query = searchController.text.toLowerCase();
            final filtered = query.isEmpty
                ? availableCountries
                : availableCountries
                    .where((c) => c.toLowerCase().contains(query))
                    .toList();

            return AlertDialog(
              backgroundColor: AppColors.backgroundCard,
              title: const Text(
                'Select Country',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search country...',
                        hintStyle: const TextStyle(color: AppColors.textTertiary),
                        prefixIcon: const Icon(Icons.search, color: AppColors.richGold),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.richGold),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No countries found',
                                style: TextStyle(color: AppColors.textTertiary),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final country = filtered[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.public,
                                    color: AppColors.richGold,
                                    size: 20,
                                  ),
                                  title: Text(
                                    country,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  onTap: () {
                                    _updatePreferences(
                                      _preferences.copyWith(
                                        preferredCountries: [
                                          ..._preferences.preferredCountries,
                                          country,
                                        ],
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Discovery Preferences',
          style: TextStyle(
            color: AppColors.richGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_hasChanges)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _savePreferences,
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: AppColors.richGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Age range
          _buildSectionCard(
            title: 'Age Range',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Age Range',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_preferences.minAge} - ${_preferences.maxAge}',
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: RangeValues(
                    _preferences.minAge.toDouble(),
                    _preferences.maxAge.toDouble(),
                  ),
                  min: 18,
                  max: 100,
                  divisions: 82,
                  activeColor: AppColors.richGold,
                  inactiveColor: AppColors.divider,
                  onChanged: (RangeValues values) {
                    _updatePreferences(
                      _preferences.copyWith(
                        minAge: values.start.toInt(),
                        maxAge: values.end.toInt(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Distance
          _buildSectionCard(
            title: 'Maximum Distance',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Within',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _preferences.maxDistanceKm != null
                          ? '${_preferences.maxDistanceKm} km'
                          : 'Unlimited',
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: (_preferences.maxDistanceKm?.toDouble() ?? 200).clamp(1, 200),
                  min: 1,
                  max: 200,
                  divisions: 199,
                  activeColor: AppColors.richGold,
                  inactiveColor: AppColors.divider,
                  onChanged: (double value) {
                    _updatePreferences(
                      _preferences.copyWith(
                        maxDistanceKm: value.toInt(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text(
                    'No distance limit',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  value: _preferences.maxDistanceKm == null,
                  activeColor: AppColors.richGold,
                  onChanged: (bool value) {
                    _updatePreferences(
                      _preferences.copyWith(
                        clearMaxDistance: value,
                        maxDistanceKm: value ? null : 50,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Country filter
          _buildSectionCard(
            title: 'Country',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Only show people from specific countries (leave empty to show all)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                if (_preferences.preferredCountries.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _preferences.preferredCountries
                        .map((country) => Chip(
                              label: Text(
                                country,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              deleteIcon: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.errorRed,
                              ),
                              onDeleted: () {
                                _updatePreferences(
                                  _preferences.copyWith(
                                    preferredCountries: List.from(
                                        _preferences.preferredCountries)
                                      ..remove(country),
                                  ),
                                );
                              },
                              backgroundColor: AppColors.backgroundDark,
                              side: const BorderSide(color: AppColors.richGold),
                            ))
                        .toList(),
                  )
                else
                  const Text(
                    'No country filter — showing worldwide',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _showCountryPickerDialog,
                  icon: const Icon(
                    Icons.add,
                    color: AppColors.richGold,
                  ),
                  label: const Text(
                    'Add Country',
                    style: TextStyle(
                      color: AppColors.richGold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Gender preference
          _buildSectionCard(
            title: 'Show Me',
            child: Column(
              children: [
                _buildRadioOption(
                  value: 'men',
                  groupValue: _preferences.interestedInGender,
                  label: 'Men',
                  onChanged: (value) {
                    _updatePreferences(
                      _preferences.copyWith(interestedInGender: value),
                    );
                  },
                ),
                _buildRadioOption(
                  value: 'women',
                  groupValue: _preferences.interestedInGender,
                  label: 'Women',
                  onChanged: (value) {
                    _updatePreferences(
                      _preferences.copyWith(interestedInGender: value),
                    );
                  },
                ),
                _buildRadioOption(
                  value: 'everyone',
                  groupValue: _preferences.interestedInGender,
                  label: 'Everyone',
                  onChanged: (value) {
                    _updatePreferences(
                      _preferences.copyWith(interestedInGender: value),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sexual Orientation filter
          _buildSectionCard(
            title: 'Sexual Orientation',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by orientation (leave all unchecked to show everyone)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...['Straight', 'Gay', 'Bisexual', 'Other'].map((orientation) {
                  final isSelected = _preferences.preferredOrientations.contains(orientation);
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      orientation,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    value: isSelected,
                    activeColor: AppColors.richGold,
                    onChanged: (bool? value) {
                      final current = List<String>.from(_preferences.preferredOrientations);
                      if (value == true) {
                        current.add(orientation);
                      } else {
                        current.remove(orientation);
                      }
                      _updatePreferences(
                        _preferences.copyWith(preferredOrientations: current),
                      );
                    },
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Advanced filters
          _buildSectionCard(
            title: 'Advanced Filters',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Only show verified profiles',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: const Text(
                    'Show only profiles with verified photos',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  value: _preferences.onlyVerified,
                  activeColor: AppColors.richGold,
                  onChanged: (bool value) {
                    _updatePreferences(
                      _preferences.copyWith(onlyVerified: value),
                    );
                  },
                ),
                const Divider(color: AppColors.divider),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Recently active',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: const Text(
                    'Show only profiles active in the last 7 days',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  value: _preferences.onlyRecentlyActive,
                  activeColor: AppColors.richGold,
                  onChanged: (bool value) {
                    _updatePreferences(
                      _preferences.copyWith(onlyRecentlyActive: value),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Deal breakers
          _buildSectionCard(
            title: 'Deal Breakers',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Never show me profiles with these characteristics',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                if (_preferences.dealBreakers.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _preferences.dealBreakers
                        .map((dealBreaker) => _buildDealBreakerChip(dealBreaker))
                        .toList(),
                  )
                else
                  const Text(
                    'No deal breakers set',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _showDealBreakerDialog,
                  icon: const Icon(
                    Icons.add,
                    color: AppColors.richGold,
                  ),
                  label: const Text(
                    'Add Deal Breaker',
                    style: TextStyle(
                      color: AppColors.richGold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Reset button
          OutlinedButton(
            onPressed: () {
              setState(() {
                _preferences = MatchPreferences.defaultFor(widget.userId);
                _hasChanges = true;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.divider),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Reset to Default'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String value,
    required String? groupValue,
    required String label,
    required Function(String?) onChanged,
  }) {
    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
      ),
      value: value,
      groupValue: groupValue,
      activeColor: AppColors.richGold,
      onChanged: onChanged,
    );
  }

  Widget _buildDealBreakerChip(String dealBreaker) {
    return Chip(
      label: Text(
        dealBreaker,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      deleteIcon: const Icon(
        Icons.close,
        size: 18,
        color: AppColors.errorRed,
      ),
      onDeleted: () {
        _updatePreferences(
          _preferences.copyWith(
            dealBreakers: List.from(_preferences.dealBreakers)
              ..remove(dealBreaker),
          ),
        );
      },
      backgroundColor: AppColors.backgroundDark,
      side: const BorderSide(color: AppColors.divider),
    );
  }
}
