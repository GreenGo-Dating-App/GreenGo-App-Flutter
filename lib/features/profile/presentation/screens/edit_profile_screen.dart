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
import '../../../authentication/presentation/screens/change_password_screen.dart';
import '../../../chat/presentation/screens/support_tickets_list_screen.dart';
import '../../../../generated/app_localizations.dart';
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
    // Check if ProfileBloc exists in parent context (from MainNavigationScreen)
    ProfileBloc? parentBloc;
    try {
      parentBloc = context.read<ProfileBloc>();
    } catch (_) {
      // No parent bloc found
    }

    Widget buildContent(BuildContext context) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            AppLocalizations.of(context)!.editProfile,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            // Only show error messages here - sub-screens handle their own success responses
            // Do NOT pop on ProfileUpdated as child screens may trigger updates
            if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            }
          },
          builder: (context, state) {
            // Determine which profile to use - check all states that contain a profile
            Profile? currentProfile;
            if (state is ProfileLoaded) {
              currentProfile = state.profile;
            } else if (state is ProfileUpdated) {
              currentProfile = state.profile;
            } else if (state is ProfileCreated) {
              currentProfile = state.profile;
            } else {
              currentProfile = profile;
            }

            // Show loading while profile is being fetched
            if (currentProfile == null) {
              if (state is ProfileLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.richGold,
                  ),
                );
              }
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.unableToLoadProfile,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            // Create a non-null reference for use in the UI
            final activeProfile = currentProfile;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                children: [
                  // View My Profile Section (top)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: EditSectionCard(
                      title: AppLocalizations.of(context)!.viewMyProfile,
                      subtitle: AppLocalizations.of(context)!.seeHowOthersViewProfile,
                      icon: Icons.visibility,
                      onTap: () => _navigateToViewProfile(context, activeProfile),
                    ),
                  ),

                  // Photos Section
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.photos,
                    subtitle: '${activeProfile.photoUrls.length}/6 photos',
                    icon: Icons.photo_library,
                    onTap: () => _navigateToPhotoManagement(context, activeProfile),
                  ),

                  const SizedBox(height: 16),

                  // Nickname Section
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.nickname,
                    subtitle: activeProfile.nickname != null
                        ? '@${activeProfile.nickname}'
                        : AppLocalizations.of(context)!.setYourUniqueNickname,
                    icon: Icons.alternate_email,
                    onTap: () => _navigateToEditNickname(context, activeProfile),
                  ),

                  const SizedBox(height: 16),

                  // Basic Info Section
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.basicInformation,
                    subtitle: '${activeProfile.displayName}, ${activeProfile.age}',
                    icon: Icons.person,
                    onTap: () => _navigateToEditBasicInfo(context, activeProfile),
                  ),

                  const SizedBox(height: 16),

                  // Bio Section
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.aboutMe,
                    subtitle: activeProfile.bio.isEmpty
                        ? AppLocalizations.of(context)!.addBio
                        : activeProfile.bio.length > 50
                            ? '${activeProfile.bio.substring(0, 50)}...'
                            : activeProfile.bio,
                    icon: Icons.edit_note,
                    onTap: () => _navigateToEditBio(context, activeProfile),
                  ),

                  const SizedBox(height: 16),

                  // Interests Section
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.interests,
                    subtitle: '${activeProfile.interests.length} interests',
                    icon: Icons.favorite,
                    onTap: () => _navigateToEditInterests(context, activeProfile),
                  ),

                  const SizedBox(height: 16),

                  // Location & Languages Section
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.locationAndLanguages,
                    subtitle: activeProfile.location.displayAddress,
                    icon: Icons.location_on,
                    onTap: () => _navigateToEditLocation(context, activeProfile),
                  ),

                  const SizedBox(height: 16),

                  // Voice Recording Section
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.voiceIntroduction,
                    subtitle: activeProfile.voiceRecordingUrl != null
                        ? AppLocalizations.of(context)!.voiceRecorded
                        : AppLocalizations.of(context)!.noVoiceRecording,
                    icon: Icons.mic,
                    onTap: () => _navigateToEditVoice(context, activeProfile),
                  ),

                  const SizedBox(height: 16),

                  // Social Links Section
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.socialProfiles,
                    subtitle: _getSocialLinksSubtitle(context, activeProfile),
                    icon: Icons.share,
                    onTap: () => _navigateToEditSocialLinks(context, activeProfile),
                  ),

                  const SizedBox(height: 16),

                  // App Language Section
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return EditSectionCard(
                        title: AppLocalizations.of(context)!.appLanguage,
                        subtitle: languageProvider.currentLanguageName,
                        icon: Icons.language,
                        onTap: () => _showLanguageDialog(context, languageProvider),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Change Password Section
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.changePassword,
                    subtitle: AppLocalizations.of(context)!.changePasswordSubtitle,
                    icon: Icons.lock_outline,
                    onTap: () => _navigateToChangePassword(context),
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.helpAndSupport,
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Support Section
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.supportCenter,
                    subtitle: AppLocalizations.of(context)!.supportCenterSubtitle,
                    icon: Icons.support_agent,
                    onTap: () => _navigateToSupport(context, activeProfile),
                  ),
                  const SizedBox(height: 16),

                  // Restart Discovery
                  EditSectionCard(
                    title: 'Restart Discovery',
                    subtitle: 'Reset all swipes and start fresh',
                    icon: Icons.refresh,
                    onTap: () => _showRestartDiscoveryDialog(context, activeProfile),
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
                  //   onTap: () => _navigateToCoinShop(context, activeProfile),
                  // ),
                  // ... other gamification navigation disabled ...

                  // Admin Panel Section (only visible to admins)
                  if (activeProfile.isAdmin) ...[
                    const SizedBox(height: 32),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.admin,
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    EditSectionCard(
                      title: AppLocalizations.of(context)!.verificationPanel,
                      subtitle: AppLocalizations.of(context)!.reviewUserVerifications,
                      icon: Icons.verified_user,
                      onTap: () => _navigateToAdminVerification(context, activeProfile),
                    ),
                    const SizedBox(height: 16),
                    EditSectionCard(
                      title: AppLocalizations.of(context)!.reportsPanel,
                      subtitle: AppLocalizations.of(context)!.reviewReportedMessages,
                      icon: Icons.report,
                      onTap: () => _navigateToAdminReports(context, activeProfile),
                    ),
                    const SizedBox(height: 16),
                    EditSectionCard(
                      title: AppLocalizations.of(context)!.membershipPanel,
                      subtitle: AppLocalizations.of(context)!.manageCouponsTiersRules,
                      icon: Icons.card_membership,
                      onTap: () => _navigateToAdminMembership(context, activeProfile),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Delete Account Button (hidden for admin users)
                  if (!activeProfile.isAdmin)
                    OutlinedButton(
                      onPressed: () => _showDeleteAccountDialog(context, activeProfile),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        side: const BorderSide(color: AppColors.errorRed),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(AppLocalizations.of(context)!.deleteAccount),
                    ),

                  const SizedBox(height: 16),

                  // Export Data Button - Temporarily disabled until backend implementation
                  // TODO: Re-enable when GDPR export Cloud Function is ready
                  // OutlinedButton(
                  //   onPressed: () => _exportUserData(context),
                  //   style: OutlinedButton.styleFrom(
                  //     foregroundColor: AppColors.textSecondary,
                  //     side: const BorderSide(color: AppColors.divider),
                  //     minimumSize: const Size(double.infinity, 50),
                  //   ),
                  //   child: const Text('Export My Data (GDPR)'),
                  // ),
                  // const SizedBox(height: 16),

                  // Log Out Button
                  ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.logout),
                    label: Text(AppLocalizations.of(context)!.logOut),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      );
    }

    // If ProfileBloc exists in parent context, use it directly
    if (parentBloc != null) {
      return buildContent(context);
    }

    // Otherwise, create a new ProfileBloc for standalone usage
    return BlocProvider(
      create: (context) {
        final bloc = di.sl<ProfileBloc>();
        if (profile == null && userId != null) {
          bloc.add(ProfileLoadRequested(userId: userId!));
        }
        return bloc;
      },
      child: Builder(builder: buildContent),
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
    final profileBloc = context.read<ProfileBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: profileBloc,
          child: EditNicknameScreen(profile: currentProfile),
        ),
      ),
    );
    // Profile updates are propagated through shared BLoC - no reload needed
  }

  Future<void> _navigateToPhotoManagement(BuildContext context, Profile currentProfile) async {
    final profileBloc = context.read<ProfileBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: profileBloc,
          child: PhotoManagementScreen(profile: currentProfile),
        ),
      ),
    );
    // Profile updates are propagated through shared BLoC - no reload needed
  }

  Future<void> _navigateToEditBasicInfo(BuildContext context, Profile currentProfile) async {
    final profileBloc = context.read<ProfileBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: profileBloc,
          child: EditBasicInfoScreen(profile: currentProfile),
        ),
      ),
    );
    // Profile updates are propagated through shared BLoC - no reload needed
  }

  Future<void> _navigateToEditBio(BuildContext context, Profile currentProfile) async {
    final profileBloc = context.read<ProfileBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: profileBloc,
          child: EditBioScreen(profile: currentProfile),
        ),
      ),
    );
    // Profile updates are propagated through shared BLoC - no reload needed
  }

  Future<void> _navigateToEditInterests(BuildContext context, Profile currentProfile) async {
    final profileBloc = context.read<ProfileBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: profileBloc,
          child: EditInterestsScreen(profile: currentProfile),
        ),
      ),
    );
    // Profile updates are propagated through shared BLoC - no reload needed
  }

  Future<void> _navigateToEditLocation(BuildContext context, Profile currentProfile) async {
    final profileBloc = context.read<ProfileBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: profileBloc,
          child: EditLocationScreen(profile: currentProfile),
        ),
      ),
    );
    // Profile updates are propagated through shared BLoC - no reload needed
  }

  Future<void> _navigateToEditVoice(BuildContext context, Profile currentProfile) async {
    final profileBloc = context.read<ProfileBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: profileBloc,
          child: EditVoiceScreen(profile: currentProfile),
        ),
      ),
    );
    // Profile updates are propagated through shared BLoC - no reload needed
  }

  void _navigateToChangePassword(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
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

  String _getSocialLinksSubtitle(BuildContext context, Profile profile) {
    if (profile.socialLinks == null || !profile.socialLinks!.hasAnyLink) {
      return AppLocalizations.of(context)!.noSocialProfilesLinked;
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
    final profileBloc = context.read<ProfileBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: profileBloc,
          child: EditSocialLinksScreen(profile: currentProfile),
        ),
      ),
    );
    // Profile updates are propagated through shared BLoC - no reload needed
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
        title: Text(
          AppLocalizations.of(context)!.selectLanguage,
          style: const TextStyle(color: AppColors.textPrimary),
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
                      content: Text(AppLocalizations.of(context)!.languageChangedTo(lang['name']!)),
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
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
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
        title: Text(
          AppLocalizations.of(context)!.deleteAccount,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteAccountConfirmation,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount(context, currentProfile);
            },
            child: Text(
              AppLocalizations.of(context)!.deleteAccount,
              style: const TextStyle(color: AppColors.errorRed),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.adminAccountsCannotBeDeleted),
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
        title: Text(
          AppLocalizations.of(context)!.logOut,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context)!.logOutConfirmation,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _logout(context);
            },
            child: Text(
              AppLocalizations.of(context)!.logOut,
              style: const TextStyle(color: AppColors.richGold),
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

  void _showRestartDiscoveryDialog(BuildContext context, Profile profile) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Restart Discovery',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'This will erase all your swipes (likes, nopes, super likes) so you can rediscover everyone from scratch.\n\nYour matches and chats will NOT be affected.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _restartDiscovery(context, profile);
            },
            child: const Text(
              'Restart',
              style: TextStyle(color: AppColors.richGold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restartDiscovery(BuildContext context, Profile profile) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.richGold),
        ),
      );

      // Delete all swipe records for this user
      final swipesQuery = await FirebaseFirestore.instance
          .collection('swipes')
          .where('userId', isEqualTo: profile.userId)
          .get();

      // Delete in batches
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in swipesQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Also reset daily swipe usage counter
      final todayKey = _getTodayKey();
      await FirebaseFirestore.instance
          .collection('dailyUsage')
          .doc(profile.userId)
          .collection('days')
          .doc(todayKey)
          .set({'swipeCount': 0}, SetOptions(merge: true));

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discovery restarted! You can now see all profiles again.'),
            backgroundColor: AppColors.richGold,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restart discovery: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
