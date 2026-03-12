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
import '../../../../core/utils/safe_navigation.dart';
import 'usage_stats_screen.dart';
import 'traveler_location_picker_screen.dart';
import '../../../../generated/app_localizations.dart';
import '../../../gamification/presentation/screens/achievements_screen.dart';
import '../../../gamification/presentation/screens/journey_screen.dart';
import '../../../gamification/presentation/screens/leaderboard_screen.dart';
import '../../../gamification/presentation/screens/daily_challenges_screen.dart';
import '../../../gamification/presentation/screens/personal_stats_screen.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_event.dart';
import '../../../gamification/domain/entities/achievement.dart';
import '../../../coins/presentation/bloc/coin_bloc.dart';
import '../../../coins/presentation/bloc/coin_event.dart';

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
      return PopScope(
        canPop: Navigator.of(context).canPop(),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            SafeNavigation.navigateToHome(context, userId ?? '');
          }
        },
        child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => SafeNavigation.pop(context, userId: userId),
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
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.profileAccountDeletedSuccess),
                  backgroundColor: Colors.green,
                ),
              );
              context.read<AuthBloc>().add(const AuthSignOutRequested());
              return;
            }
            if (state is ProfileBoostActivated) {
              final remaining = state.expiry.difference(DateTime.now());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.profileBoostedForMinutes(remaining.inMinutes)),
                  backgroundColor: const Color(0xFFDAA520),
                ),
              );
            }
            if (state is ProfileBoostInsufficientCoins) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.profileNotEnoughCoins(state.required, state.available)),
                  backgroundColor: AppColors.errorRed,
                  action: SnackBarAction(
                    label: AppLocalizations.of(context)!.profileGetCoins,
                    textColor: Colors.white,
                    onPressed: () {
                      if (userId != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CoinShopScreen(userId: userId!)),
                        );
                      }
                    },
                  ),
                ),
              );
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

                  const SizedBox(height: 16),

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
                    subtitle: AppLocalizations.of(context)!.profilePhotosCount(activeProfile.photoUrls.length),
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
                    subtitle: AppLocalizations.of(context)!.profileInterestsCount(activeProfile.interests.length),
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
                  Text(
                    AppLocalizations.of(context)!.profilePremiumFeatures,
                    style: const TextStyle(
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

                  // Boost Profile
                  _BoostProfileCard(
                    profile: activeProfile,
                    onBoost: () => _activateBoost(context, activeProfile),
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

                  // Coin Shop
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.profileCoinShop,
                    subtitle: AppLocalizations.of(context)!.profileCoinShopSubtitle,
                    icon: Icons.monetization_on,
                    onTap: () => _navigateToCoinShop(context, activeProfile),
                  ),
                  const SizedBox(height: 16),

                  // Restart Discovery
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.profileRestartDiscovery,
                    subtitle: AppLocalizations.of(context)!.profileRestartDiscoverySubtitle,
                    icon: Icons.refresh,
                    onTap: () => _showRestartDiscoveryDialog(context, activeProfile),
                  ),
                  const SizedBox(height: 16),

                  // Usage Stats
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.profileMyUsage,
                    subtitle: AppLocalizations.of(context)!.profileMyUsageSubtitle,
                    icon: Icons.bar_chart,
                    onTap: () => _navigateToUsageStats(context, activeProfile),
                  ),

                  // Progress & Growth Section
                  const SizedBox(height: 32),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.profileProgressGrowth,
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.personalStatistics,
                    subtitle: AppLocalizations.of(context)!.personalStatisticsSubtitle,
                    icon: Icons.insights,
                    onTap: () => _navigateToPersonalStats(context, activeProfile),
                  ),
                  const SizedBox(height: 16),
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.achievementsTitle,
                    subtitle: AppLocalizations.of(context)!.achievementsSubtitle,
                    icon: Icons.emoji_events,
                    onTap: () => _navigateToAchievements(context, activeProfile),
                  ),
                  const SizedBox(height: 16),
                  EditSectionCard(
                    title: AppLocalizations.of(context)!.dailyChallengesTitle,
                    subtitle: AppLocalizations.of(context)!.dailyChallengesSubtitle,
                    icon: Icons.today,
                    onTap: () => _navigateToDailyChallenges(context, activeProfile),
                  ),

                  // Achievement Badges Section
                  const SizedBox(height: 32),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),
                  _AchievementBadgesSection(userId: activeProfile.userId),

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

  Widget _buildXpBadge(String userId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('language_progress')
          .where('userId', isEqualTo: userId)
          .get(),
      builder: (context, snapshot) {
        int totalXp = 0;
        if (snapshot.hasData && snapshot.data != null) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null && data['totalXpEarned'] != null) {
              totalXp += (data['totalXpEarned'] as num).toInt();
            }
          }
        }
        final l10n = AppLocalizations.of(context)!;
        final formattedXp = totalXp.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFDAA520), Color(0xFFF5C842)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDAA520).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.greengoXpLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.xpAmountLabel(formattedXp),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
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

    return AppLocalizations.of(context)!.profileLinkedCount(links.length);
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

  void _navigateToCoinShop(BuildContext context, Profile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => di.sl<CoinBloc>()
            ..add(LoadCoinBalance(profile.userId))
            ..add(const LoadAvailablePackages()),
          child: CoinShopScreen(userId: profile.userId),
        ),
      ),
    );
  }

  void _navigateToLeaderboard(BuildContext context, Profile currentProfile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => di.sl<GamificationBloc>()
            ..add(LoadLeaderboard(userId: currentProfile.userId)),
          child: LeaderboardScreen(userId: currentProfile.userId),
        ),
      ),
    );
  }

  void _navigateToAchievements(BuildContext context, Profile currentProfile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => di.sl<GamificationBloc>()
            ..add(LoadUserAchievements(currentProfile.userId)),
          child: AchievementsScreen(userId: currentProfile.userId),
        ),
      ),
    );
  }

  void _navigateToDailyChallenges(BuildContext context, Profile currentProfile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => di.sl<GamificationBloc>()
            ..add(LoadDailyChallenges(currentProfile.userId)),
          child: DailyChallengesScreen(userId: currentProfile.userId),
        ),
      ),
    );
  }

  void _navigateToPersonalStats(BuildContext context, Profile currentProfile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PersonalStatsScreen(userId: currentProfile.userId),
      ),
    );
  }

  Widget _buildBaseMembershipSection(BuildContext context, Profile profile) {
    final isActive = profile.isBaseMembershipActive;
    final endDate = profile.baseMembershipEndDate;

    if (profile.hasBaseMembership && endDate != null) {
      // Show membership card with status — tappable to extend
      final isExpired = endDate.isBefore(DateTime.now());
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => BaseMembershipDialog.show(
          context: context,
          userId: profile.userId,
          isExtending: isActive,
        ),
        child: Container(
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
                  Text(
                    AppLocalizations.of(context)!.profileGreengoMembership,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.profileMembershipValidTill('${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}'),
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
                isExpired ? AppLocalizations.of(context)!.profileMembershipExpired : AppLocalizations.of(context)!.profileMembershipActive,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
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
      label: Text(AppLocalizations.of(context)!.profileGetMembership),
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
          title: Text(
            AppLocalizations.of(context)!.profileConfirmYourPassword,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.profileDeleteAccountWarning,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
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
                      errorText = AppLocalizations.of(context)!.profileUnableToVerifyAccount;
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
                      errorText = e.message ?? AppLocalizations.of(context)!.profileAuthenticationFailed;
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
      SnackBar(
        content: Text(AppLocalizations.of(context)!.profileExportingData),
        backgroundColor: AppColors.richGold,
      ),
    );

    // Simulate export
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileDataExportSent),
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
    // Sign out via AuthBloc, with direct Firebase fallback
    try {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    } catch (e) {
      debugPrint('[Logout] AuthBloc dispatch failed: $e — using direct Firebase signOut');
      FirebaseAuth.instance.signOut();
    }
  }

  void _showRestartDiscoveryDialog(BuildContext context, Profile profile) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          AppLocalizations.of(context)!.profileRestartDiscoveryDialogTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context)!.profileRestartDiscoveryDialogContent,
          style: const TextStyle(color: AppColors.textSecondary),
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
            child: Text(
              AppLocalizations.of(context)!.profileRestart,
              style: const TextStyle(color: AppColors.richGold),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileDiscoveryRestarted),
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
            content: Text(AppLocalizations.of(context)!.profileFailedRestartDiscovery(e.toString())),
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

  Future<void> _activateBoost(BuildContext context, Profile profile) async {
    // Check if already boosted
    if (profile.isBoosted &&
        profile.boostExpiry != null &&
        profile.boostExpiry!.isAfter(DateTime.now())) {
      final remaining = profile.boostExpiry!.difference(DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileAlreadyBoosted(remaining.inMinutes)),
          backgroundColor: const Color(0xFFDAA520),
        ),
      );
      return;
    }

    final cost = CoinFeaturePrices.boost;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.flash_on, color: Color(0xFFDAA520), size: 28),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.profileBoostProfile, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.profileBoostDescription,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDAA520).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDAA520).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: AppColors.richGold, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.profileBoostCost(cost),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDAA520),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.of(context)!.profileBoostNow),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Dispatch boost event
    context.read<ProfileBloc>().add(
      ProfileBoostRequested(userId: profile.userId),
    );

    // Listen for result
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileActivatingBoost),
          backgroundColor: Color(0xFFDAA520),
          duration: Duration(seconds: 1),
        ),
      );
    }
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
          title: Row(
            children: [
              const Icon(Icons.visibility_off, color: AppColors.richGold),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.profileActivateIncognito, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18)),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)!.profileIncognitoDescription(costText),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: AppColors.textTertiary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold),
              child: Text(AppLocalizations.of(context)!.profileActivate, style: const TextStyle(color: Colors.white)),
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
                title: Text(AppLocalizations.of(context)!.profileInsufficientCoins, style: const TextStyle(color: AppColors.textPrimary)),
                content: Text(
                  AppLocalizations.of(context)!.profileIncognitoCost(CoinFeaturePrices.incognito),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: AppColors.textTertiary)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => di.sl<CoinBloc>()..add(LoadCoinBalance(profile.userId))..add(const LoadAvailablePackages()), child: CoinShopScreen(userId: profile.userId))),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold),
                    child: Text(AppLocalizations.of(context)!.profileBuyCoins, style: const TextStyle(color: Colors.white)),
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
            SnackBar(
              content: Text(AppLocalizations.of(context)!.profileIncognitoActivated),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileIncognitoDeactivated),
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
        title: Row(
          children: [
            const Icon(Icons.flight, color: Color(0xFF1E88E5)),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.profileActivateTravelerMode, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18)),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.profileTravelerDescription(costText),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5)),
            child: Text(AppLocalizations.of(context)!.profileContinue, style: const TextStyle(color: Colors.white)),
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
              title: Text(AppLocalizations.of(context)!.profileInsufficientCoins, style: const TextStyle(color: AppColors.textPrimary)),
              content: Text(
                AppLocalizations.of(context)!.profileTravelerCost(CoinFeaturePrices.traveler),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: AppColors.textTertiary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => di.sl<CoinBloc>()..add(LoadCoinBalance(profile.userId))..add(const LoadAvailablePackages()), child: CoinShopScreen(userId: profile.userId))),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold),
                  child: Text(AppLocalizations.of(context)!.profileBuyCoins, style: const TextStyle(color: Colors.white)),
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
          content: Text(AppLocalizations.of(context)!.profileTravelerActivated(location.city)),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileTravelerDeactivated),
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
        title: Text(
          AppLocalizations.of(context)!.profileTravelerMode,
          style: const TextStyle(
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
                child: Text(AppLocalizations.of(context)!.profileStop, style: const TextStyle(color: AppColors.errorRed, fontSize: 12)),
              )
            : ElevatedButton(
                onPressed: onActivate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(AppLocalizations.of(context)!.profileActivate, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
      ),
    );
  }
}

/// Incognito toggle card widget
class _BoostProfileCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onBoost;

  const _BoostProfileCard({
    required this.profile,
    required this.onBoost,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = profile.isBoosted &&
        profile.boostExpiry != null &&
        profile.boostExpiry!.isAfter(DateTime.now());

    final remaining = isActive
        ? profile.boostExpiry!.difference(DateTime.now())
        : Duration.zero;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFF2A1F0E), const Color(0xFF1A1408), const Color(0xFF2A1F0E)]
              : [AppColors.backgroundCard, AppColors.backgroundCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFFD700).withOpacity(0.6)
              : AppColors.richGold.withOpacity(0.2),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header row: icon + title + status
            Row(
              children: [
                // Gold flash icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFDAA520), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive ? AppLocalizations.of(context)!.profileBoosted : AppLocalizations.of(context)!.profileBoostProfile,
                        style: TextStyle(
                          color: isActive ? AppColors.richGold : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isActive
                            ? '${remaining.inMinutes}m remaining'
                            : AppLocalizations.of(context)!.profileBoostSubtitle,
                        style: TextStyle(
                          color: isActive
                              ? AppColors.richGold.withOpacity(0.7)
                              : AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Active badge
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.profileActiveLabel,
                      style: const TextStyle(
                        color: Color(0xFF2A1F0E),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
            // Boost button (only when inactive)
            if (!isActive) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: onBoost,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFDAA520), Color(0xFFFFA500)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flash_on, color: Color(0xFF2A1F0E), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.profileBoostNow,
                          style: const TextStyle(
                            color: Color(0xFF2A1F0E),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A1F0E).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.monetization_on, color: const Color(0xFF2A1F0E).withOpacity(0.8), size: 14),
                              const SizedBox(width: 3),
                              Text(
                                '${CoinFeaturePrices.boost}',
                                style: TextStyle(
                                  color: const Color(0xFF2A1F0E).withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
        title: Text(
          AppLocalizations.of(context)!.profileIncognitoMode,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isActive
              ? '${remaining.inHours}h ${remaining.inMinutes % 60}m remaining'
              : (profile.membershipTier == MembershipTier.platinum ||
                      profile.membershipTier == MembershipTier.test)
                  ? AppLocalizations.of(context)!.profileIncognitoFreePlatinum
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

/// Achievement badges section for profile page
/// Shows unlocked achievements as badges, user can toggle which to display on profile
class _AchievementBadgesSection extends StatefulWidget {
  final String userId;

  const _AchievementBadgesSection({required this.userId});

  @override
  State<_AchievementBadgesSection> createState() => _AchievementBadgesSectionState();
}

class _AchievementBadgesSectionState extends State<_AchievementBadgesSection> {
  bool _isLoading = true;
  List<_AchievementBadgeData> _unlockedAchievements = [];
  Set<String> _displayedBadgeIds = {};

  @override
  void initState() {
    super.initState();
    _loadAchievementBadges();
  }

  Future<void> _loadAchievementBadges() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Load unlocked achievements
      final progressDocs = await firestore
          .collection('achievement_progress')
          .where('userId', isEqualTo: widget.userId)
          .where('isUnlocked', isEqualTo: true)
          .get();

      // Load displayed badges preference
      final prefDoc = await firestore
          .collection('user_badge_preferences')
          .doc(widget.userId)
          .get();

      final displayed = <String>{};
      if (prefDoc.exists) {
        final list = prefDoc.data()?['displayedBadges'] as List<dynamic>? ?? [];
        displayed.addAll(list.cast<String>());
      }

      final unlocked = <_AchievementBadgeData>[];
      for (final doc in progressDocs.docs) {
        final data = doc.data();
        final achievementId = data['achievementId'] as String? ?? '';
        final achievement = Achievements.getById(achievementId);
        if (achievement != null) {
          unlocked.add(_AchievementBadgeData(
            achievement: achievement,
            unlockedAt: (data['unlockedAt'] as Timestamp?)?.toDate(),
          ));
        }
      }

      if (mounted) {
        setState(() {
          _unlockedAchievements = unlocked;
          _displayedBadgeIds = displayed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading achievement badges: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleBadgeDisplay(String achievementId) async {
    final newSet = Set<String>.from(_displayedBadgeIds);
    if (newSet.contains(achievementId)) {
      newSet.remove(achievementId);
    } else {
      if (newSet.length >= 5) return; // Max 5 displayed badges
      newSet.add(achievementId);
    }

    setState(() => _displayedBadgeIds = newSet);

    // Save to Firestore
    FirebaseFirestore.instance
        .collection('user_badge_preferences')
        .doc(widget.userId)
        .set({
      'displayedBadges': newSet.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  static IconData _getAchievementIcon(String achievementId) {
    switch (achievementId) {
      case 'first_match': return Icons.handshake;
      case 'conversation_starter': return Icons.chat_bubble;
      case 'video_champion': return Icons.videocam;
      case 'profile_master': return Icons.person_pin;
      case 'globe_trotter': return Icons.public;
      case 'generous_heart': return Icons.card_giftcard;
      case 'daily_dedication': return Icons.calendar_today;
      case 'super_star': return Icons.star;
      case 'social_butterfly': return Icons.groups;
      case 'perfect_week': return Icons.event_available;
      case 'early_bird': return Icons.wb_sunny;
      case 'night_owl': return Icons.nightlight_round;
      case 'centurion': return Icons.military_tech;
      case 'speed_dater': return Icons.bolt;
      case 'photo_collector': return Icons.photo_library;
      case 'trend_setter': return Icons.trending_up;
      case 'verified': return Icons.verified;
      case 'premium_member': return Icons.workspace_premium;
      case 'coin_collector': return Icons.monetization_on;
      case 'monthly_streak': return Icons.local_fire_department;
      case 'vocabulary_beginner': return Icons.abc;
      case 'vocabulary_intermediate': return Icons.spellcheck;
      case 'vocabulary_advanced': return Icons.menu_book;
      case 'vocabulary_master': return Icons.auto_stories;
      case 'rare_word_hunter': return Icons.search;
      default: return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shield, color: AppColors.richGold, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.achievementBadges,
              style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.achievementBadgesSubtitle,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.richGold, strokeWidth: 2),
            ),
          )
        else if (_unlockedAchievements.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events, color: AppColors.textTertiary, size: 36),
                const SizedBox(height: 8),
                Text(
                  l10n.noBadgesYet,
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _unlockedAchievements.map((data) {
              final isDisplayed = _displayedBadgeIds.contains(data.achievement.achievementId);
              final rarityColor = Color(data.achievement.rarity.colorValue);

              return GestureDetector(
                onTap: () => _toggleBadgeDisplay(data.achievement.achievementId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isDisplayed
                        ? rarityColor.withValues(alpha: 0.15)
                        : AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDisplayed ? rarityColor : AppColors.divider.withValues(alpha: 0.3),
                      width: isDisplayed ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [rarityColor, rarityColor.withValues(alpha: 0.7)],
                              ),
                              boxShadow: isDisplayed
                                  ? [BoxShadow(color: rarityColor.withValues(alpha: 0.4), blurRadius: 8)]
                                  : null,
                            ),
                            child: Icon(
                              _getAchievementIcon(data.achievement.achievementId),
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          if (isDisplayed)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.richGold,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 10),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.achievement.name,
                        style: TextStyle(
                          color: isDisplayed ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 8,
                          fontWeight: isDisplayed ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _AchievementBadgeData {
  final Achievement achievement;
  final DateTime? unlockedAt;

  _AchievementBadgeData({required this.achievement, this.unlockedAt});
}

