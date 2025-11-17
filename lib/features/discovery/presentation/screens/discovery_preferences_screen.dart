import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
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

  void _savePreferences() {
    if (_hasChanges && widget.onSave != null) {
      widget.onSave!(_preferences);
    }
    Navigator.of(context).pop();
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
            TextButton(
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
                  value: _preferences.maxDistanceKm?.toDouble() ?? 200,
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
                        maxDistanceKm: value ? null : 50,
                      ),
                    );
                  },
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
                  onPressed: () {
                    // TODO: Show deal breaker selection dialog
                  },
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
