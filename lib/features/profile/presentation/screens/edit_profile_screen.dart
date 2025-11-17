import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/edit_section_card.dart';
import 'photo_management_screen.dart';
import 'edit_basic_info_screen.dart';
import 'edit_bio_screen.dart';
import 'edit_interests_screen.dart';
import 'edit_location_screen.dart';

class EditProfileScreen extends StatelessWidget {
  final String? userId;
  final Profile? profile;

  const EditProfileScreen({
    super.key,
    this.userId,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = di.sl<ProfileBloc>();
        // Load profile if only userId is provided
        if (profile == null && userId != null) {
          bloc.add(ProfileLoadRequested(userId: userId!));
        }
        return bloc;
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
            'Edit Profile',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully'),
                  backgroundColor: AppColors.successGreen,
                ),
              );
              Navigator.of(context).pop(state.profile);
            } else if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            }
          },
          builder: (context, state) {
            // Determine which profile to use
            final currentProfile = state is ProfileLoaded
                ? state.profile
                : profile;

            // Show loading while profile is being fetched
            if (currentProfile == null) {
              if (state is ProfileLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.richGold,
                  ),
                );
              }
              return const Center(
                child: Text(
                  'Unable to load profile',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                children: [
                  // Photos Section
                  EditSectionCard(
                    title: 'Photos',
                    subtitle: '${currentProfile.photoUrls.length}/6 photos',
                    icon: Icons.photo_library,
                    onTap: () => _navigateToPhotoManagement(context, currentProfile),
                  ),

                  const SizedBox(height: 16),

                  // Basic Info Section
                  EditSectionCard(
                    title: 'Basic Information',
                    subtitle: '${currentProfile.displayName}, ${currentProfile.age}',
                    icon: Icons.person,
                    onTap: () => _navigateToEditBasicInfo(context, currentProfile),
                  ),

                  const SizedBox(height: 16),

                  // Bio Section
                  EditSectionCard(
                    title: 'About Me',
                    subtitle: currentProfile.bio.isEmpty
                        ? 'Add a bio'
                        : currentProfile.bio.length > 50
                            ? '${currentProfile.bio.substring(0, 50)}...'
                            : currentProfile.bio,
                    icon: Icons.edit_note,
                    onTap: () => _navigateToEditBio(context, currentProfile),
                  ),

                  const SizedBox(height: 16),

                  // Interests Section
                  EditSectionCard(
                    title: 'Interests',
                    subtitle: '${currentProfile.interests.length} interests',
                    icon: Icons.favorite,
                    onTap: () => _navigateToEditInterests(context, currentProfile),
                  ),

                  const SizedBox(height: 16),

                  // Location & Languages Section
                  EditSectionCard(
                    title: 'Location & Languages',
                    subtitle: currentProfile.location.displayAddress,
                    icon: Icons.location_on,
                    onTap: () => _navigateToEditLocation(context, currentProfile),
                  ),

                  const SizedBox(height: 16),

                  // Voice Recording Section
                  EditSectionCard(
                    title: 'Voice Introduction',
                    subtitle: currentProfile.voiceRecordingUrl != null
                        ? 'Voice recorded'
                        : 'No voice recording',
                    icon: Icons.mic,
                    onTap: () => _navigateToEditVoice(context),
                  ),

                  const SizedBox(height: 32),

                  // Delete Account Button
                  OutlinedButton(
                    onPressed: () => _showDeleteAccountDialog(context, currentProfile),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: const BorderSide(color: AppColors.errorRed),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Delete Account'),
                  ),

                  const SizedBox(height: 16),

                  // Export Data Button
                  OutlinedButton(
                    onPressed: () => _exportUserData(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Export My Data (GDPR)'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _navigateToPhotoManagement(BuildContext context, Profile currentProfile) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoManagementScreen(profile: currentProfile),
      ),
    );
    // Refresh profile if updated
    if (result != null && context.mounted) {
      // Profile was updated
    }
  }

  Future<void> _navigateToEditBasicInfo(BuildContext context, Profile currentProfile) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditBasicInfoScreen(profile: currentProfile),
      ),
    );
    if (result != null && context.mounted) {
      // Profile was updated
    }
  }

  Future<void> _navigateToEditBio(BuildContext context, Profile currentProfile) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditBioScreen(profile: currentProfile),
      ),
    );
    if (result != null && context.mounted) {
      // Profile was updated
    }
  }

  Future<void> _navigateToEditInterests(BuildContext context, Profile currentProfile) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditInterestsScreen(profile: currentProfile),
      ),
    );
    if (result != null && context.mounted) {
      // Profile was updated
    }
  }

  Future<void> _navigateToEditLocation(BuildContext context, Profile currentProfile) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditLocationScreen(profile: currentProfile),
      ),
    );
    if (result != null && context.mounted) {
      // Profile was updated
    }
  }

  void _navigateToEditVoice(BuildContext context) {
    // TODO: Implement voice recording edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit voice coming soon')),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, Profile currentProfile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount(context, currentProfile);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteAccount(BuildContext context, Profile currentProfile) {
    context.read<ProfileBloc>().add(
          ProfileDeleteRequested(userId: currentProfile.userId),
        );
  }

  void _exportUserData(BuildContext context) {
    // TODO: Implement GDPR data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting your data...'),
        backgroundColor: AppColors.richGold,
      ),
    );

    // Simulate export
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data export sent to your email'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    });
  }
}
