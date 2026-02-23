import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/membership_badge.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/providers/language_provider.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/location.dart' as profile_entity;
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../widgets/edit_section_card.dart';
import '../../../admin/presentation/screens/admin_2fa_screen.dart';
import '../../../admin/presentation/screens/verification_admin_screen.dart';
import '../../../admin/presentation/screens/reports_admin_screen.dart';
import '../../../membership/presentation/screens/membership_admin_screen.dart';
import '../../../admin/presentation/bloc/verification_admin_bloc.dart';
import '../../../admin/data/datasources/verification_admin_remote_data_source.dart';
import '../../../admin/data/repositories/verification_admin_repository_impl.dart';
import '../../../coins/domain/entities/coin_transaction.dart';
import '../../../coins/domain/repositories/coin_repository.dart';
import '../../../coins/presentation/screens/coin_shop_screen.dart';
import '../../../discovery/data/datasources/discovery_remote_datasource.dart';
import '../../../../core/widgets/base_membership_dialog.dart';
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
import '../../../main/presentation/screens/main_navigation_screen.dart';
import 'usage_stats_screen.dart';
import 'traveler_location_picker_screen.dart';
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileDeleted) {
              // Account deleted — sign out to trigger AuthWrapper navigation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deleted successfully.'),
                  backgroundColor: Colors.green,
                ),
              );
              context.read<AuthBloc>().add(const AuthSignOutRequested());
              return;
            }
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
                  // Profile Header with name and membership badge
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            activeProfile.displayName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (activeProfile.membershipTier != MembershipTier.free) ...[
                          const SizedBox(width: 10),
                          MembershipBadge(
                            tier: activeProfile.membershipTier,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                  ),

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

                  // About Me Section
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.aboutMe,
                    subtitle: _getAboutMeSubtitle(context, activeProfile),
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

                  // Premium Features Section
                  const Text(
                    'Premium Features',
                    style: TextStyle(
                      color: AppColors.richGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Incognito Mode Toggle
                  _IncognitoToggleCard(
                    profile: activeProfile,
                    onToggle: (enabled) => _toggleIncognito(context, activeProfile, enabled),
                  ),

                  const SizedBox(height: 16),

                  // Traveler Mode Toggle
                  _TravelerToggleCard(
                    profile: activeProfile,
                    onActivate: () => _activateTraveler(context, activeProfile),
                    onDeactivate: () => _deactivateTraveler(context, activeProfile),
                  ),

                  const SizedBox(height: 16),

                  // Usage Stats
                  EditSectionCard(
                    title: 'My Usage',
                    subtitle: 'View your daily usage and tier limits',
                    icon: Icons.bar_chart,
                    onTap: () => _navigateToUsageStats(context, activeProfile),
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

                  // Base Membership Section
                  _buildBaseMembershipSection(context, activeProfile),

                  const SizedBox(height: 16),

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

  String _getAboutMeSubtitle(BuildContext context, Profile profile) {
    if (profile.bio.isEmpty) {
      return AppLocalizations.of(context)!.addBio;
    }
    final parts = <String>[];
    if (profile.weight != null) parts.add('${profile.weight}kg');
    if (profile.height != null) parts.add('${profile.height}cm');
    if (profile.education != null && profile.education!.isNotEmpty) {
      parts.add(profile.education!);
    }
    if (parts.isNotEmpty) return parts.join(' • ');
    return profile.bio.length > 50
        ? '${profile.bio.substring(0, 50)}...'
        : profile.bio;
  }

  Future<bool> _verify2FA(BuildContext context) async {
    if (Admin2FAScreen.isVerified) return true;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const Admin2FAScreen()),
    );
    return result == true;
  }

  Future<void> _navigateToAdminVerification(BuildContext context, Profile currentProfile) async {
    if (!await _verify2FA(context)) return;
    if (!context.mounted) return;

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

  Future<void> _navigateToAdminReports(BuildContext context, Profile currentProfile) async {
    if (!await _verify2FA(context)) return;
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportsAdminScreen(adminId: currentProfile.userId),
      ),
    );
  }

  Future<void> _navigateToAdminMembership(BuildContext context, Profile currentProfile) async {
    if (!await _verify2FA(context)) return;
    if (!context.mounted) return;

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

  Widget _buildBaseMembershipSection(BuildContext context, Profile profile) {
    final isActive = profile.isBaseMembershipActive;
    final endDate = profile.baseMembershipEndDate;

    if (profile.hasBaseMembership && endDate != null) {
      // Show membership card with status
      final isExpired = endDate.isBefore(DateTime.now());
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
                : AppColors.errorRed.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                    : AppColors.errorRed.withValues(alpha: 0.15),
              ),
              child: Icon(
                isActive ? Icons.verified : Icons.warning_amber_rounded,
                color: isActive ? const Color(0xFF4CAF50) : AppColors.errorRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GreenGo Membership',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Valid till ${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}',
                    style: TextStyle(
                      color: isActive ? AppColors.textSecondary : AppColors.errorRed,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF4CAF50) : AppColors.errorRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isExpired ? 'Expired' : 'Active',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // No membership — show get button
    return OutlinedButton.icon(
      onPressed: () => BaseMembershipDialog.show(
        context: context,
        userId: profile.userId,
      ),
      icon: const Icon(Icons.star_outline),
      label: const Text('Get GreenGo Membership'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.richGold,
        side: const BorderSide(color: AppColors.richGold),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider languageProvider) {
    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'it', 'name': 'Italiano'},
      {'code': 'es', 'name': 'Español'},
      {'code': 'fr', 'name': 'Français'},
      {'code': 'pt', 'name': 'Português'},
      {'code': 'pt_BR', 'name': 'Português (Brasil)'},
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
              final code = lang['code']!;
              final parts = code.split('_');
              final locale = parts.length > 1 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
              final currentKey = languageProvider.currentLocale.countryCode != null
                  ? '${languageProvider.currentLocale.languageCode}_${languageProvider.currentLocale.countryCode}'
                  : languageProvider.currentLocale.languageCode;
              final isSelected = currentKey == code;

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
                  languageProvider.setLocale(locale);
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

  void _showDeleteAccountDialog(BuildContext screenContext, Profile currentProfile) {
    // Prevent admin account deletion
    if (currentProfile.isAdmin) {
      ScaffoldMessenger.of(screenContext).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(screenContext)!.adminAccountsCannotBeDeleted),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Step 1: Confirm intent
    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          AppLocalizations.of(dialogContext)!.deleteAccount,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(dialogContext)!.deleteAccountConfirmation,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Step 2: Ask for password confirmation
              _showPasswordConfirmDialog(screenContext, currentProfile);
            },
            child: Text(
              AppLocalizations.of(dialogContext)!.deleteAccount,
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showPasswordConfirmDialog(BuildContext screenContext, Profile currentProfile) {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    String? errorText;
    bool isLoading = false;

    showDialog(
      context: screenContext,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text(
            'Confirm Your Password',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is permanent and cannot be undone. '
                'All your data, matches, and messages will be deleted. '
                'Please enter your password to confirm.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.password,
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  errorText: errorText,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.textSecondary),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.richGold),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.errorRed),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.errorRed),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () {
                passwordController.dispose();
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: isLoading ? null : () async {
                final password = passwordController.text.trim();
                if (password.isEmpty) {
                  setDialogState(() => errorText = AppLocalizations.of(context)!.passwordRequired);
                  return;
                }

                setDialogState(() {
                  isLoading = true;
                  errorText = null;
                });

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null || user.email == null) {
                    setDialogState(() {
                      isLoading = false;
                      errorText = 'Unable to verify account';
                    });
                    return;
                  }

                  // Re-authenticate with password
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: password,
                  );
                  await user.reauthenticateWithCredential(credential);

                  // Password correct — close dialog and delete account
                  passwordController.dispose();
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();

                  // Use screenContext (not dialog context) to dispatch BLoC event
                  screenContext.read<ProfileBloc>().add(
                    ProfileDeleteRequested(userId: currentProfile.userId),
                  );
                } on FirebaseAuthException catch (e) {
                  setDialogState(() {
                    isLoading = false;
                    if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                      errorText = AppLocalizations.of(context)!.authErrorWrongPassword;
                    } else {
                      errorText = e.message ?? 'Authentication failed';
                    }
                  });
                } catch (e) {
                  setDialogState(() {
                    isLoading = false;
                    errorText = e.toString();
                  });
                }
              },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.errorRed),
                    )
                  : Text(
                      AppLocalizations.of(context)!.deleteAccount,
                      style: const TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
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
    // Clear discovery caches before signing out
    try {
      final datasource = GetIt.I<DiscoveryRemoteDataSource>();
      datasource.clearAllDiscoveryCaches();
    } catch (_) {}
    // Sign out — AuthWrapper in main.dart handles navigation reactively
    context.read<AuthBloc>().add(const AuthSignOutRequested());
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

      // Clear in-memory discovery cache so fresh profiles load
      try {
        final datasource = GetIt.I<DiscoveryRemoteDataSource>();
        datasource.clearDiscoveryCache(profile.userId);
      } catch (_) {}

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
        // Refresh the discovery tab so it rebuilds with fresh data
        context.findAncestorStateOfType<MainNavigationScreenState>()?.refreshDiscoveryTab();
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

  void _navigateToUsageStats(BuildContext context, Profile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UsageStatsScreen(
          userId: profile.userId,
          membershipTier: profile.membershipTier,
          profile: profile,
        ),
      ),
    );
  }

  Future<void> _toggleIncognito(BuildContext context, Profile profile, bool enabled) async {
    if (enabled) {
      // Platinum/Test gets it free, others pay coins
      final isPlatinum = profile.membershipTier == MembershipTier.platinum ||
          profile.membershipTier == MembershipTier.test;

      // Show confirmation dialog
      final costText = isPlatinum ? 'Free with Platinum' : '${CoinFeaturePrices.incognito} coins';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Row(
            children: [
              Icon(Icons.visibility_off, color: AppColors.richGold),
              SizedBox(width: 8),
              Text('Activate Incognito?', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
            ],
          ),
          content: Text(
            'Incognito mode hides your profile from discovery for 24 hours.\n\nCost: $costText',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold),
              child: const Text('Activate', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      if (!isPlatinum) {
        try {
          final coinRepository = GetIt.instance<CoinRepository>();
          final balanceResult = await coinRepository.getBalance(profile.userId);

          if (!context.mounted) return;

          final hasEnough = balanceResult.fold(
            (failure) => false,
            (balance) => balance.availableCoins >= CoinFeaturePrices.incognito,
          );

          if (!hasEnough) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.backgroundCard,
                title: const Text('Insufficient Coins', style: TextStyle(color: AppColors.textPrimary)),
                content: Text(
                  'Incognito mode costs ${CoinFeaturePrices.incognito} coins per day.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CoinShopScreen(userId: profile.userId)),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold),
                    child: const Text('Buy Coins', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            return;
          }

          // Deduct coins
          await coinRepository.purchaseFeature(
            userId: profile.userId,
            featureName: 'incognito',
            cost: CoinFeaturePrices.incognito,
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
            );
          }
          return;
        }
      }

      if (!context.mounted) return;

      // Update profile
      try {
        final expiry = DateTime.now().add(const Duration(hours: 24));
        await FirebaseFirestore.instance.collection('profiles').doc(profile.userId).update({
          'isIncognito': true,
          'incognitoExpiry': Timestamp.fromDate(expiry),
        });

        if (context.mounted) {
          context.read<ProfileBloc>().add(ProfileLoadRequested(userId: profile.userId));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incognito mode activated for 24 hours!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
          );
        }
      }
    } else {
      // Disable incognito
      await FirebaseFirestore.instance.collection('profiles').doc(profile.userId).update({
        'isIncognito': false,
      });

      if (context.mounted) {
        context.read<ProfileBloc>().add(ProfileLoadRequested(userId: profile.userId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incognito mode deactivated.'),
            backgroundColor: AppColors.richGold,
          ),
        );
      }
    }
  }

  Future<void> _activateTraveler(BuildContext context, Profile profile) async {
    // Platinum gets it free, Gold pays 100 coins
    final isPlatinum = profile.membershipTier == MembershipTier.platinum ||
        profile.membershipTier == MembershipTier.test;

    // Show confirmation dialog
    final costText = isPlatinum ? 'Free with Platinum' : '${CoinFeaturePrices.traveler} coins';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Row(
          children: [
            Icon(Icons.flight, color: Color(0xFF1E88E5)),
            SizedBox(width: 8),
            Text('Activate Traveler Mode?', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
          ],
        ),
        content: Text(
          'Traveler mode lets you appear in a different city\'s discovery feed for 24 hours.\n\nCost: $costText',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5)),
            child: const Text('Continue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    if (!isPlatinum) {
      try {
        final coinRepository = GetIt.instance<CoinRepository>();
        final balanceResult = await coinRepository.getBalance(profile.userId);

        if (!context.mounted) return;

        final hasEnough = balanceResult.fold(
          (failure) => false,
          (balance) => balance.availableCoins >= CoinFeaturePrices.traveler,
        );

        if (!hasEnough) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.backgroundCard,
              title: const Text('Insufficient Coins', style: TextStyle(color: AppColors.textPrimary)),
              content: Text(
                'Traveler mode costs ${CoinFeaturePrices.traveler} coins per day.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CoinShopScreen(userId: profile.userId)),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold),
                  child: const Text('Buy Coins', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          return;
        }

        // Deduct coins
        await coinRepository.purchaseFeature(
          userId: profile.userId,
          featureName: 'traveler',
          cost: CoinFeaturePrices.traveler,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;

    // Show map picker dialog for the user to select their traveler location
    _showLocationPickerDialog(context, profile);
  }

  Future<void> _showLocationPickerDialog(BuildContext context, Profile profile) async {
    final selectedLocation = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => const TravelerLocationPickerScreen(),
      ),
    );

    if (selectedLocation == null || !context.mounted) return;

    final location = selectedLocation as profile_entity.Location;
    final expiry = DateTime.now().add(const Duration(hours: 24));

    await FirebaseFirestore.instance.collection('profiles').doc(profile.userId).update({
      'isTraveler': true,
      'travelerExpiry': Timestamp.fromDate(expiry),
      'travelerLocation': {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'city': location.city,
        'country': location.country,
        'displayAddress': location.displayAddress,
      },
    });

    if (context.mounted) {
      context.read<ProfileBloc>().add(ProfileLoadRequested(userId: profile.userId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Traveler mode activated! Appearing in ${location.city} for 24 hours.'),
          backgroundColor: const Color(0xFF1E88E5),
        ),
      );
    }
  }

  Future<void> _deactivateTraveler(BuildContext context, Profile profile) async {
    await FirebaseFirestore.instance.collection('profiles').doc(profile.userId).update({
      'isTraveler': false,
      'travelerLocation': null,
    });

    if (context.mounted) {
      context.read<ProfileBloc>().add(ProfileLoadRequested(userId: profile.userId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Traveler mode deactivated. Back to your real location.'),
          backgroundColor: AppColors.richGold,
        ),
      );
    }
  }
}

/// Traveler toggle card widget
class _TravelerToggleCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;

  const _TravelerToggleCard({
    required this.profile,
    required this.onActivate,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = profile.isTravelerActive;
    final isPlatinum = profile.membershipTier == MembershipTier.platinum ||
        profile.membershipTier == MembershipTier.test;

    final remaining = isActive && profile.travelerExpiry != null
        ? profile.travelerExpiry!.difference(DateTime.now())
        : Duration.zero;

    final costText = isPlatinum ? 'Free with Platinum' : '${CoinFeaturePrices.traveler} coins/day';
    final locationText = isActive && profile.travelerLocation != null
        ? '${profile.travelerLocation!.city}, ${profile.travelerLocation!.country}'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: isActive
            ? Border.all(color: const Color(0xFF1E88E5).withOpacity(0.5))
            : null,
      ),
      child: ListTile(
        leading: Icon(
          Icons.flight,
          color: isActive ? const Color(0xFF1E88E5) : AppColors.textTertiary,
        ),
        title: const Text(
          'Traveler Mode',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isActive
              ? '$locationText - ${remaining.inHours}h ${remaining.inMinutes % 60}m remaining'
              : '$costText - Appear in another city',
          style: TextStyle(
            color: isActive ? const Color(0xFF1E88E5) : AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
        trailing: isActive
            ? TextButton(
                onPressed: onDeactivate,
                child: const Text('Stop', style: TextStyle(color: AppColors.errorRed, fontSize: 12)),
              )
            : ElevatedButton(
                onPressed: onActivate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Activate', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
      ),
    );
  }
}

/// Incognito toggle card widget
class _IncognitoToggleCard extends StatelessWidget {
  final Profile profile;
  final Function(bool) onToggle;

  const _IncognitoToggleCard({
    required this.profile,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = profile.isIncognito &&
        profile.incognitoExpiry != null &&
        profile.incognitoExpiry!.isAfter(DateTime.now());

    final remaining = isActive
        ? profile.incognitoExpiry!.difference(DateTime.now())
        : Duration.zero;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: isActive
            ? Border.all(color: AppColors.richGold.withOpacity(0.5))
            : null,
      ),
      child: ListTile(
        leading: Icon(
          Icons.visibility_off,
          color: isActive ? AppColors.richGold : AppColors.textTertiary,
        ),
        title: const Text(
          'Incognito Mode',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isActive
              ? '${remaining.inHours}h ${remaining.inMinutes % 60}m remaining'
              : (profile.membershipTier == MembershipTier.platinum ||
                      profile.membershipTier == MembershipTier.test)
                  ? 'Free with Platinum - Hidden from discovery'
                  : '${CoinFeaturePrices.incognito} coins/day - Hidden from discovery',
          style: TextStyle(
            color: isActive ? AppColors.richGold : AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value: isActive,
          onChanged: onToggle,
          activeColor: AppColors.richGold,
        ),
      ),
    );
  }
}

