import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/onboarding_button.dart';
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
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.richGold),
              title: const Text('Take Photo', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.richGold),
              title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleContinue(List<String> photoUrls) {
    if (photoUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one photo'),
          backgroundColor: AppColors.errorRed,
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
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is! OnboardingInProgress) {
          return const SizedBox.shrink();
        }

        final isUploading = state is OnboardingPhotoUploading;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: _handleBack,
            ),
            title: OnboardingProgressBar(
              currentStep: state.stepIndex,
              totalSteps: state.totalSteps,
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Add your photos',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.richGold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload at least one clear photo of yourself',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 40),

                  // Photo Grid
                  Expanded(
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
                          isFirst: index == 0,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info Box
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
                          Icons.info_outline,
                          color: AppColors.richGold,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Photos are verified using AI to ensure authenticity',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Continue Button
                  OnboardingButton(
                    text: 'Continue',
                    onPressed: () => _handleContinue(state.photoUrls),
                    isLoading: isUploading,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final String photoUrl;
  final VoidCallback onRemove;

  const _PhotoCard({
    required this.photoUrl,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.richGold, width: 2),
            image: DecorationImage(
              image: NetworkImage(photoUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.errorRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
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
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: isFirst ? AppColors.richGold : AppColors.divider,
            width: isFirst ? 2 : 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: isFirst ? AppColors.richGold : AppColors.textTertiary,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              isFirst ? 'Add Photo' : '',
              style: TextStyle(
                color: isFirst ? AppColors.richGold : AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
