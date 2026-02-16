import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/action_success_dialog.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class EditBasicInfoScreen extends StatefulWidget {
  final Profile profile;

  const EditBasicInfoScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditBasicInfoScreen> createState() => _EditBasicInfoScreenState();
}

class _EditBasicInfoScreenState extends State<EditBasicInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedGender;
  String? _selectedOrientation;
  bool _isSaving = false;

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  final List<String> _orientationOptions = [
    'Straight',
    'Gay',
    'Bisexual',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profile.displayName;
    _selectedGender = widget.profile.gender;
    _selectedOrientation = widget.profile.sexualOrientation;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final name = _nameController.text.trim();
    return name.isNotEmpty &&
        name.length >= 2 &&
        name.length <= 50 &&
        _selectedGender != null;
  }

  void _saveChanges() {
    if (!_isValid || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final updatedProfile = widget.profile.copyWith(
      displayName: _nameController.text.trim(),
      gender: _selectedGender!,
      sexualOrientation: _selectedOrientation,
      updatedAt: DateTime.now(),
    );

    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(profile: updatedProfile),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) async {
        if (state is ProfileUpdated) {
          // Show success dialog instead of snackbar
          await ActionSuccessDialog.showBasicInfoUpdated(context);
          if (context.mounted) {
            Navigator.of(context).pop(state.profile);
          }
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
          'Edit Basic Info',
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
              onPressed: _isValid ? _saveChanges : null,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Name
            const Text(
              'Display Name',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.backgroundInput,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: const BorderSide(color: AppColors.richGold, width: 2),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 24),

            // Date of Birth (Read-only)
            const Text(
              'Date of Birth',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.profile.dateOfBirth.day}/${widget.profile.dateOfBirth.month}/${widget.profile.dateOfBirth.year}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Age ${widget.profile.age} - Cannot be changed for verification',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Gender
            const Text(
              'Gender',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            ...GenderOptions.map((gender) {
              return GestureDetector(
                onTap: () => setState(() => _selectedGender = gender),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedGender == gender
                        ? AppColors.richGold.withOpacity(0.1)
                        : AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: _selectedGender == gender
                          ? AppColors.richGold
                          : AppColors.divider,
                      width: _selectedGender == gender ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getGenderIcon(gender),
                        color: _selectedGender == gender
                            ? AppColors.richGold
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        gender,
                        style: TextStyle(
                          color: _selectedGender == gender
                              ? AppColors.richGold
                              : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: _selectedGender == gender
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedGender == gender)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.richGold,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Sexual Orientation
            const Text(
              'Sexual Orientation',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'This is private and not shown on your profile card',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),

            ..._orientationOptions.map((orientation) {
              return GestureDetector(
                onTap: () => setState(() => _selectedOrientation = orientation),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedOrientation == orientation
                        ? AppColors.richGold.withOpacity(0.1)
                        : AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: _selectedOrientation == orientation
                          ? AppColors.richGold
                          : AppColors.divider,
                      width: _selectedOrientation == orientation ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getOrientationIcon(orientation),
                        color: _selectedOrientation == orientation
                            ? AppColors.richGold
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        orientation,
                        style: TextStyle(
                          color: _selectedOrientation == orientation
                              ? AppColors.richGold
                              : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: _selectedOrientation == orientation
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedOrientation == orientation)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.richGold,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.richGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.richGold,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your date of birth cannot be changed for age verification purposes. '
                      'Your exact age is visible to matches.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
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
    );
  }

  IconData _getGenderIcon(String gender) {
    switch (gender) {
      case 'Male':
        return Icons.male;
      case 'Female':
        return Icons.female;
      case 'Non-binary':
        return Icons.transgender;
      default:
        return Icons.help_outline;
    }
  }

  IconData _getOrientationIcon(String orientation) {
    switch (orientation) {
      case 'Straight':
        return Icons.favorite;
      case 'Gay':
        return Icons.diversity_1;
      case 'Bisexual':
        return Icons.diversity_3;
      case 'Other':
        return Icons.more_horiz;
      default:
        return Icons.help_outline;
    }
  }

  // Helper to avoid repetition
  List<String> get GenderOptions => _genderOptions;
}
