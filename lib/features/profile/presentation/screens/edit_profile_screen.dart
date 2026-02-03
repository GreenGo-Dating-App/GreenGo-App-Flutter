import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/providers/language_provider.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../widgets/edit_section_card.dart';
import '../../../admin/presentation/screens/verification_admin_screen.dart';
import '../../../admin/presentation/screens/reports_admin_screen.dart';
import '../../../membership/presentation/screens/membership_admin_screen.dart';
import '../../../admin/presentation/bloc/verification_admin_bloc.dart';
import '../../../admin/data/datasources/verification_admin_remote_data_source.dart';
import '../../../admin/data/repositories/verification_admin_repository_impl.dart';
import 'photo_management_screen.dart';
import 'edit_basic_info_screen.dart';
import 'edit_bio_screen.dart';
import 'edit_interests_screen.dart';
import 'edit_location_screen.dart';
import 'edit_social_links_screen.dart';
import 'edit_nickname_screen.dart';
import 'edit_voice_screen.dart';
// Progress screen moved to bottom navigation - import removed
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../../../chat/presentation/screens/support_tickets_list_screen.dart';
// Gamification/Coins screens disabled due to compile errors
// import '../../../gamification/presentation/screens/achievements_screen.dart';
// import '../../../gamification/presentation/screens/journey_screen.dart';
// import '../../../gamification/presentation/screens/leaderboard_screen.dart';
// import '../../../gamification/presentation/screens/daily_challenges_screen.dart';
// import '../../../coins/presentation/screens/coin_shop_screen.dart';
// import '../../../coins/presentation/screens/transaction_history_screen.dart';
// import '../../../gamification/presentation/bloc/gamification_bloc.dart';
// import '../../../coins/presentation/bloc/coin_bloc.dart';

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
                  // View My Profile Section (top)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: EditSectionCard(
                      title: 'View My Profile',
                      subtitle: 'See how others view your profile',
                      icon: Icons.visibility,
                      onTap: () => _navigateToViewProfile(context, currentProfile),
                    ),
                  ),

                  // Photos Section
                  EditSectionCard(
                    title: 'Photos',
                    subtitle: '${currentProfile.photoUrls.length}/6 photos',
                    icon: Icons.photo_library,
                    onTap: () => _navigateToPhotoManagement(context, currentProfile),
                  ),

                  const SizedBox(height: 16),

                  // Nickname Section
                  EditSectionCard(
                    title: 'Nickname',
                    subtitle: currentProfile.nickname != null
                        ? '@${currentProfile.nickname}'
                        : 'Set your unique nickname',
                    icon: Icons.alternate_email,
                    onTap: () => _navigateToEditNickname(context, currentProfile),
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
                    onTap: () => _navigateToEditVoice(context, currentProfile),
                  ),

                  const SizedBox(height: 16),

                  // Social Links Section
                  EditSectionCard(
                    title: 'Social Profiles',
                    subtitle: _getSocialLinksSubtitle(currentProfile),
                    icon: Icons.share,
                    onTap: () => _navigateToEditSocialLinks(context, currentProfile),
                  ),

                  const SizedBox(height: 16),

                  // App Language Section
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return EditSectionCard(
                        title: 'App Language',
                        subtitle: languageProvider.currentLanguageName,
                        icon: Icons.language,
                        onTap: () => _showLanguageDialog(context, languageProvider),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),
                  const Text(
                    'Help & Support',
                    style: TextStyle(
                      color: AppColors.richGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Support Section
                  EditSectionCard(
                    title: 'Support Center',
                    subtitle: 'Get help, report issues, contact us',
                    icon: Icons.support_agent,
                    onTap: () => _navigateToSupport(context, currentProfile),
                  ),

                  // Gamification & Rewards Section - Moved to Progress tab in bottom navigation
                  // TODO: Re-enable when gamification/coins features are fixed
                  // const SizedBox(height: 32),
                  // const Divider(color: AppColors.divider),
                  // const SizedBox(height: 16),
                  // const Text(
                  //   'Rewards & Progress',
                  //   style: TextStyle(
                  //     color: AppColors.richGold,
                  //     fontSize: 18,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  // const SizedBox(height: 16),
                  // EditSectionCard(
                  //   title: 'Coin Shop',
                  //   subtitle: 'Purchase coins and premium features',
                  //   icon: Icons.monetization_on,
                  //   onTap: () => _navigateToCoinShop(context, currentProfile),
                  // ),
                  // ... other gamification navigation disabled ...

                  // Admin Panel Section (only visible to admins)
                  if (currentProfile.isAdmin) ...[
                    const SizedBox(height: 32),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),
                    const Text(
                      'Admin',
                      style: TextStyle(
                        color: AppColors.richGold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    EditSectionCard(
                      title: 'Verification Panel',
                      subtitle: 'Review user verifications',
                      icon: Icons.verified_user,
                      onTap: () => _navigateToAdminVerification(context, currentProfile),
                    ),
                    const SizedBox(height: 16),
                    EditSectionCard(
                      title: 'Reports Panel',
                      subtitle: 'Review reported messages & manage accounts',
                      icon: Icons.report,
                      onTap: () => _navigateToAdminReports(context, currentProfile),
                    ),
                    const SizedBox(height: 16),
                    EditSectionCard(
                      title: 'Membership Panel',
                      subtitle: 'Manage coupons, tiers & rules',
                      icon: Icons.card_membership,
                      onTap: () => _navigateToAdminMembership(context, currentProfile),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Delete Account Button (hidden for admin users)
                  if (!currentProfile.isAdmin)
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

                  const SizedBox(height: 16),

                  // Log Out Button
                  ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToViewProfile(BuildContext context, Profile currentProfile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          profile: currentProfile,
          currentUserId: currentProfile.userId,
          // No match and no onSwipe - this is self-view mode
        ),
      ),
    );
  }

  Future<void> _navigateToEditNickname(BuildContext context, Profile currentProfile) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => di.sl<ProfileBloc>(),
          child: EditNicknameScreen(profile: currentProfile),
        ),
      ),
    );
    if (result != null && context.mounted) {
      // Profile was updated
    }
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

  Future<void> _navigateToEditVoice(BuildContext context, Profile currentProfile) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => di.sl<ProfileBloc>(),
          child: EditVoiceScreen(profile: currentProfile),
        ),
      ),
    );
    if (result != null && context.mounted) {
      // Profile was updated
    }
  }

  void _navigateToSupport(BuildContext context, Profile currentProfile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SupportTicketsListScreen(
          currentUserId: currentProfile.userId,
        ),
      ),
    );
  }

  String _getSocialLinksSubtitle(Profile profile) {
    if (profile.socialLinks == null || !profile.socialLinks!.hasAnyLink) {
      return 'No social profiles linked';
    }

    final links = <String>[];
    if (profile.socialLinks!.facebook != null) links.add('Facebook');
    if (profile.socialLinks!.instagram != null) links.add('Instagram');
    if (profile.socialLinks!.tiktok != null) links.add('TikTok');
    if (profile.socialLinks!.linkedin != null) links.add('LinkedIn');
    if (profile.socialLinks!.x != null) links.add('X');

    return '${links.length} profile${links.length == 1 ? '' : 's'} linked';
  }

  Future<void> _navigateToEditSocialLinks(BuildContext context, Profile currentProfile) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditSocialLinksScreen(profile: currentProfile),
      ),
    );
    if (result != null && context.mounted) {
      // Profile was updated
    }
  }

  void _navigateToAdminVerification(BuildContext context, Profile currentProfile) {
    // Create the repository and bloc for the admin screen
    final remoteDataSource = VerificationAdminRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
    );
    final repository = VerificationAdminRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => VerificationAdminBloc(repository: repository),
          child: VerificationAdminScreen(adminId: currentProfile.userId),
        ),
      ),
    );
  }

  void _navigateToAdminReports(BuildContext context, Profile currentProfile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportsAdminScreen(adminId: currentProfile.userId),
      ),
    );
  }

  void _navigateToAdminMembership(BuildContext context, Profile currentProfile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MembershipAdminScreen(adminId: currentProfile.userId),
      ),
    );
  }

  // Gamification & Coins Navigation Methods - Moved to Progress tab in bottom navigation
  // void _navigateToCoinShop(BuildContext context, Profile currentProfile) { ... }
  // void _navigateToTransactionHistory(BuildContext context, Profile currentProfile) { ... }
  // void _navigateToAchievements(BuildContext context, Profile currentProfile) { ... }
  // void _navigateToDailyChallenges(BuildContext context, Profile currentProfile) { ... }
  // void _navigateToLeaderboard(BuildContext context, Profile currentProfile) { ... }
  // void _navigateToJourney(BuildContext context, Profile currentProfile) { ... }

  void _showLanguageDialog(BuildContext context, LanguageProvider languageProvider) {
    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'it', 'name': 'Italiano'},
      {'code': 'es', 'name': 'Español'},
      {'code': 'fr', 'name': 'Français'},
      {'code': 'pt', 'name': 'Português'},
      {'code': 'de', 'name': 'Deutsch'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Select Language',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              final isSelected = languageProvider.currentLocale.languageCode == lang['code'];

              return ListTile(
                title: Text(
                  lang['name']!,
                  style: TextStyle(
                    color: isSelected ? AppColors.richGold : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.richGold)
                    : null,
                onTap: () {
                  languageProvider.setLocale(Locale(lang['code']!));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Language changed to ${lang['name']}'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
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
    // Prevent admin account deletion
    if (currentProfile.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin accounts cannot be deleted'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Log Out',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _logout(context);
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: AppColors.richGold),
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    context.read<AuthBloc>().add(const AuthSignOutRequested());
    // Navigate to login screen and clear navigation stack
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}
