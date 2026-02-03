import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class EditInterestsScreen extends StatefulWidget {
  final Profile profile;

  const EditInterestsScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditInterestsScreen> createState() => _EditInterestsScreenState();
}

class _EditInterestsScreenState extends State<EditInterestsScreen> {
  final List<String> _selectedInterests = [];
  final int _minInterests = 3;
  final int _maxInterests = 10;
  bool _isSaving = false;

  final List<String> _availableInterests = [
    'Travel',
    'Photography',
    'Music',
    'Fitness',
    'Cooking',
    'Reading',
    'Movies',
    'Gaming',
    'Art',
    'Dance',
    'Yoga',
    'Hiking',
    'Swimming',
    'Cycling',
    'Running',
    'Sports',
    'Fashion',
    'Technology',
    'Writing',
    'Coffee',
    'Wine',
    'Beer',
    'Food',
    'Vegetarian',
    'Vegan',
    'Pets',
    'Dogs',
    'Cats',
    'Nature',
    'Beach',
    'Mountains',
    'Camping',
    'Surfing',
    'Skiing',
    'Snowboarding',
    'Meditation',
    'Spirituality',
    'Volunteering',
    'Environment',
    'Politics',
    'Science',
    'History',
    'Languages',
    'Teaching',
  ];

  @override
  void initState() {
    super.initState();
    _selectedInterests.addAll(widget.profile.interests);
  }

  bool get _isValid =>
      _selectedInterests.length >= _minInterests &&
      _selectedInterests.length <= _maxInterests;

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        if (_selectedInterests.length < _maxInterests) {
          _selectedInterests.add(interest);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum $_maxInterests interests allowed'),
              backgroundColor: AppColors.warningAmber,
            ),
          );
        }
      }
    });
  }

  void _saveInterests() {
    if (!_isValid || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final updatedProfile = widget.profile.copyWith(
      interests: _selectedInterests,
      updatedAt: DateTime.now(),
    );

    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(profile: updatedProfile),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Interests saved successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          Navigator.of(context).pop(state.profile);
        } else if (state is ProfileError) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Interests',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          if (_isSaving)
            const Padding(
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
          else
            TextButton(
              onPressed: _isValid ? _saveInterests : null,
              child: Text(
                'Save',
                style: TextStyle(
                  color: _isValid ? AppColors.richGold : AppColors.textTertiary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress Info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(
                  _isValid ? Icons.check_circle : Icons.info_outline,
                  color: _isValid ? AppColors.successGreen : AppColors.richGold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedInterests.length}/$_maxInterests interests selected',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedInterests.length < _minInterests
                            ? 'Select at least $_minInterests interests'
                            : 'Great! Your interests help us find better matches',
                        style: TextStyle(
                          color: _selectedInterests.length < _minInterests
                              ? AppColors.errorRed
                              : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Interests Grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableInterests.map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return GestureDetector(
                    onTap: () => _toggleInterest(interest),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.richGold
                            : AppColors.backgroundCard,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.richGold
                              : AppColors.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            interest,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.deepBlack
                                  : AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check,
                              color: AppColors.deepBlack,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
