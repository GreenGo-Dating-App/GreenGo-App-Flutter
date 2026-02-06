import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/luxury_onboarding_layout.dart';
import '../../widgets/onboarding_progress_bar.dart';

class Step2PhotoUploadScreen extends StatefulWidget {
  const Step2PhotoUploadScreen({super.key});

  @override
  State<Step2PhotoUploadScreen> createState() => _Step2PhotoUploadScreenState();
}

class _Step2PhotoUploadScreenState extends State<Step2PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        if (!mounted) return;
        context.read<OnboardingBloc>().add(OnboardingPhotoAdded(photo: file));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: AppColors.richGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Add Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Take Photo',
                  subtitle: 'Use your camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 12),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Choose from Gallery',
                  subtitle: 'Select from your photos',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.richGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.richGold, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  void _handleContinue(List<String> photoUrls) {
    if (photoUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please upload at least one photo'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    context.read<OnboardingBloc>().add(const OnboardingNextStep());
  }

  void _handleBack() {
    context.read<OnboardingBloc>().add(const OnboardingPreviousStep());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is! OnboardingInProgress) {
          return const SizedBox.shrink();
        }

        final isUploading = state is OnboardingPhotoUploading;

        return LuxuryOnboardingLayout(
          title: 'Show yourself',
          subtitle: 'Add photos that represent the real you',
          onBack: _handleBack,
          progressBar: OnboardingProgressBar(
            currentStep: state.stepIndex,
            totalSteps: state.totalSteps,
          ),
          child: Column(
            children: [
              // Photo Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      final hasPhoto = index < state.photoUrls.length;

                      if (hasPhoto) {
                        return _PhotoCard(
                          photoUrl: state.photoUrls[index],
                          index: index,
                          onRemove: () {
                            final updatedPhotos = List<String>.from(state.photoUrls)
                              ..removeAt(index);
                            context.read<OnboardingBloc>().add(
                                  OnboardingPhotosUpdated(photoUrls: updatedPhotos),
                                );
                          },
                        );
                      }

                      return _AddPhotoCard(
                        onTap: isUploading ? null : _showImageSourceDialog,
                        isFirst: index == 0 && state.photoUrls.isEmpty,
                      );
                    },
                  ),
                ),
              ),

              // Info Box
              LuxuryGlassCard(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.richGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.richGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Verified Photos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your photos are verified using AI to ensure authenticity',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
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

              // Continue Button
              LuxuryButton(
                text: 'Continue',
                onPressed: () => _handleContinue(state.photoUrls),
                isLoading: isUploading,
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final String photoUrl;
  final int index;
  final VoidCallback onRemove;

  const _PhotoCard({
    required this.photoUrl,
    required this.index,
    required this.onRemove,
  });

  bool get _isLocalFile => !photoUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: index == 0
                  ? AppColors.richGold
                  : Colors.white.withOpacity(0.1),
              width: index == 0 ? 2 : 1,
            ),
            boxShadow: index == 0
                ? [
                    BoxShadow(
                      color: AppColors.richGold.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
            image: DecorationImage(
              image: _isLocalFile
                  ? FileImage(File(photoUrl))
                  : NetworkImage(photoUrl) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Main photo badge
        if (index == 0)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), AppColors.richGold],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'MAIN',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Remove button
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoCard extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isFirst;

  const _AddPhotoCard({
    this.onTap,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isFirst
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.richGold.withOpacity(0.2),
                    AppColors.richGold.withOpacity(0.05),
                  ],
                )
              : null,
          color: isFirst ? null : Colors.white.withOpacity(0.03),
          border: Border.all(
            color: isFirst
                ? AppColors.richGold
                : Colors.white.withOpacity(0.1),
            width: isFirst ? 2 : 1,
            style: isFirst ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFirst
                    ? AppColors.richGold.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
              ),
              child: Icon(
                Icons.add_photo_alternate_rounded,
                color: isFirst ? AppColors.richGold : Colors.white.withOpacity(0.3),
                size: 28,
              ),
            ),
            if (isFirst) ...[
              const SizedBox(height: 8),
              Text(
                'Add Photo',
                style: TextStyle(
                  color: AppColors.richGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
