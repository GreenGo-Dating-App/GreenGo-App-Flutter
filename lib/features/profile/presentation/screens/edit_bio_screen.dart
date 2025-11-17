import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';

class EditBioScreen extends StatefulWidget {
  final Profile profile;

  const EditBioScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditBioScreen> createState() => _EditBioScreenState();
}

class _EditBioScreenState extends State<EditBioScreen> {
  final TextEditingController _bioController = TextEditingController();
  final int _minLength = 50;
  final int _maxLength = 500;

  @override
  void initState() {
    super.initState();
    _bioController.text = widget.profile.bio;
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final length = _bioController.text.trim().length;
    return length >= _minLength && length <= _maxLength;
  }

  void _saveBio() {
    if (!_isValid) return;

    final updatedProfile = Profile(
      userId: widget.profile.userId,
      displayName: widget.profile.displayName,
      dateOfBirth: widget.profile.dateOfBirth,
      gender: widget.profile.gender,
      photoUrls: widget.profile.photoUrls,
      bio: _bioController.text.trim(),
      interests: widget.profile.interests,
      location: widget.profile.location,
      languages: widget.profile.languages,
      voiceRecordingUrl: widget.profile.voiceRecordingUrl,
      personalityTraits: widget.profile.personalityTraits,
      createdAt: widget.profile.createdAt,
      updatedAt: DateTime.now(),
      isComplete: widget.profile.isComplete,
    );

    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(profile: updatedProfile),
        );

    Navigator.of(context).pop(updatedProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Bio',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _isValid ? _saveBio : null,
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
            // Bio Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.richGold,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for a great bio',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('Be authentic and genuine'),
                  _buildTip('Mention your hobbies and passions'),
                  _buildTip('Add a touch of humor'),
                  _buildTip('Keep it positive'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bio Input
            TextField(
              controller: _bioController,
              maxLines: 8,
              maxLength: _maxLength,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Tell people about yourself...',
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
                counterStyle: TextStyle(
                  color: _bioController.text.length < _minLength
                      ? AppColors.errorRed
                      : AppColors.textSecondary,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Character Count Info
            if (_bioController.text.trim().isNotEmpty &&
                _bioController.text.trim().length < _minLength)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.errorRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bio must be at least $_minLength characters',
                        style: const TextStyle(
                          color: AppColors.errorRed,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.successGreen,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
