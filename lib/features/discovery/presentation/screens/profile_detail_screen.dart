import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/flavor_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../core/widgets/country_flag_badge.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../generated/app_localizations.dart';
import '../../../safety/presentation/widgets/safety_actions_menu.dart';
import '../../../app_tour/presentation/tour_controller.dart';
import '../../../app_tour/presentation/tour_keys.dart';
import '../../../app_tour/presentation/widgets/gesture_glyphs.dart';
import '../../../app_tour/presentation/widgets/tour_showcase.dart';
import '../../../business/presentation/screens/business_storefront_screen.dart';
import '../../../business/presentation/widgets/business_contact_button.dart';
import '../../../business/presentation/widgets/business_follow_button.dart';
import '../../../chat/presentation/connect_and_chat.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/swipe_action.dart';
import '../widgets/swipe_buttons.dart';

/// Profile Detail Screen
///
/// Full profile view with photos, bio, interests, and details
/// Includes Instagram-like photo likes feature
class ProfileDetailScreen extends StatefulWidget {

  const ProfileDetailScreen({
    required this.profile, required this.currentUserId, super.key,
    this.match,
    this.onSwipe,
  });
  final Profile profile;
  final String currentUserId;
  final Match? match;
  final Function(SwipeActionType)? onSwipe;

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  // Photo likes state
  final Map<int, bool> _photoLikedByMe = {};
  final Map<int, int> _photoLikeCounts = {};
  bool _showLikeAnimation = false;

  // Voice playback state
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingVoice = false;
  Duration _voiceDuration = Duration.zero;
  Duration _voicePosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadPhotoLikes();
    _setupVoicePlayer();

    // One-time double-tap-to-like hint when viewing someone else's photos
    if (widget.currentUserId != widget.profile.userId &&
        widget.profile.photoUrls.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = TourKeys.detailPhotoDoubleTap.currentContext;
        if (ctx == null) return;
        TourController.instance.maybeStartMiniTour(
          ctx,
          tourId: TourController.profileDetailTourId,
          userId: widget.currentUserId,
          keys: [TourKeys.detailPhotoDoubleTap],
        );
      });
    }
  }

  void _setupVoicePlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _voiceDuration = duration);
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _voicePosition = position);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlayingVoice = false;
          _voicePosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Load like status for all photos
  Future<void> _loadPhotoLikes() async {
    if (widget.profile.photoUrls.isEmpty) return;

    final firestore = FirebaseFirestore.instance;

    for (var i = 0; i < widget.profile.photoUrls.length; i++) {
      final photoUrl = widget.profile.photoUrls[i];
      final photoId = _getPhotoId(photoUrl);

      // Check if current user liked this photo
      final likeDoc = await firestore
          .collection('photo_likes')
          .doc('${widget.profile.userId}_${photoId}_${widget.currentUserId}')
          .get();

      // Get total like count
      final likesQuery = await firestore
          .collection('photo_likes')
          .where('profileUserId', isEqualTo: widget.profile.userId)
          .where('photoId', isEqualTo: photoId)
          .count()
          .get();

      if (mounted) {
        setState(() {
          _photoLikedByMe[i] = likeDoc.exists;
          _photoLikeCounts[i] = likesQuery.count ?? 0;
        });
      }
    }
  }

  String _getPhotoId(String photoUrl) {
    // Extract a unique identifier from the photo URL
    return photoUrl.hashCode.toString();
  }

  /// Toggle like on current photo
  Future<void> _togglePhotoLike() async {
    final photoIndex = _currentPhotoIndex;
    final photoUrl = widget.profile.photoUrls[photoIndex];
    final photoId = _getPhotoId(photoUrl);
    final isLiked = _photoLikedByMe[photoIndex] ?? false;

    final firestore = FirebaseFirestore.instance;
    final docId = '${widget.profile.userId}_${photoId}_${widget.currentUserId}';

    if (isLiked) {
      // Unlike
      await firestore.collection('photo_likes').doc(docId).delete();
      setState(() {
        _photoLikedByMe[photoIndex] = false;
        _photoLikeCounts[photoIndex] = (_photoLikeCounts[photoIndex] ?? 1) - 1;
      });
    } else {
      // Like
      await firestore.collection('photo_likes').doc(docId).set({
        'profileUserId': widget.profile.userId,
        'photoId': photoId,
        'photoUrl': photoUrl,
        'likerId': widget.currentUserId,
        'likedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _photoLikedByMe[photoIndex] = true;
        _photoLikeCounts[photoIndex] = (_photoLikeCounts[photoIndex] ?? 0) + 1;
        _showLikeAnimation = true;
      });

      // Haptic feedback
      HapticFeedback.mediumImpact();

      // Hide animation after delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _showLikeAnimation = false);
        }
      });

      // Send notification to profile owner (if not liking own photo)
      if (widget.profile.userId != widget.currentUserId) {
        _sendPhotoLikeNotification(photoIndex);
      }
    }
  }

  /// Send notification when someone likes a photo
  Future<void> _sendPhotoLikeNotification(int photoIndex) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Get current user's profile for name
      final userDoc = await firestore.collection('profiles').doc(widget.currentUserId).get();
      final userName = userDoc.data()?['displayName'] ?? 'Someone';
      final userNickname = userDoc.data()?['nickname'] as String?;

      final displayName = userNickname != null ? '@$userNickname' : userName;

      await firestore.collection('notifications').add({
        'userId': widget.profile.userId,
        'type': 'photo_like',
        'title': 'New Photo Like',
        'message': '$displayName liked your photo',
        'data': {
          'likerId': widget.currentUserId,
          'likerName': userName,
          'likerNickname': userNickname,
          'photoIndex': photoIndex,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Error sending photo like notification: $e');
    }
  }

  Future<void> _toggleVoicePlayback() async {
    if (_isPlayingVoice) {
      await _audioPlayer.pause();
      setState(() => _isPlayingVoice = false);
    } else {
      if (_voicePosition == Duration.zero) {
        await _audioPlayer.play(UrlSource(widget.profile.voiceRecordingUrl!));
      } else {
        await _audioPlayer.resume();
      }
      setState(() => _isPlayingVoice = true);
    }
  }

  String _formatVoiceDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if this is self-view mode (user viewing their own profile)
  bool get _isSelfView => widget.profile.userId == widget.currentUserId;

  @override
  Widget build(BuildContext context) {
    final hasPhotos = widget.profile.photoUrls.isNotEmpty;
    final isMatched = widget.match != null;

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SafeNavigation.navigateToHome(context, widget.currentUserId);
        }
      },
      child: ShowCaseWidget(
        builder: (showcaseContext) => Scaffold(
        backgroundColor: AppColors.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => SafeNavigation.pop(context, userId: widget.currentUserId),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        actions: [
          // Apple-safe culture flavor: a single, unobtrusive Message action
          // (opens a chat immediately — NO like/super-like/match/Connect).
          // Full/dating flavor keeps its swipe buttons instead, so hide it there.
          if (!_isSelfView &&
              !(FlavorConfig.enableMatching ||
                  FlavorConfig.enableSwipeDiscovery))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: AppLocalizations.of(context)!.sendMessage,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  openConnectChat(
                    context,
                    currentUserId: widget.currentUserId,
                    otherUserId: widget.profile.userId,
                    otherUserProfile: widget.profile,
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.richGold,
                  ),
                ),
              ),
            ),
          // Safety overflow menu: Report / Block (reuses existing infra).
          // Never shown when viewing your own profile.
          if (!_isSelfView)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SafetyActionsMenu(
                currentUserId: widget.currentUserId,
                reportedUserId: widget.profile.userId,
                reportedUserName: widget.profile.displayName,
                isReportedUserAdmin: widget.profile.isAdmin,
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            slivers: [
              // Photo carousel
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: hasPhotos
                      ? _buildPhotoCarousel()
                      : _buildPhotoPlaceholder(),
                ),
              ),

              // Profile info
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppDimensions.radiusXL),
                      topRight: Radius.circular(AppDimensions.radiusXL),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name, age, and membership tier
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.profile.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Gold verified check badge for verified users.
                            if (widget.profile.isVerified ||
                                widget.profile.businessVerified) ...[
                              const SizedBox(width: 8),
                              Tooltip(
                                message:
                                    AppLocalizations.of(context)!.safetyVerifiedBadge,
                                child: const VerifiedBadge(
                                  size: 22,
                                  isPremium: true,
                                ),
                              ),
                            ],
                            const SizedBox(width: 12),
                            Text(
                              '${widget.profile.age}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 28,
                              ),
                            ),
                            // Show language flags
                            if (widget.profile.languages.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              LanguageFlagBadge(
                                languages: widget.profile.languages,
                                fontSize: 18,
                              ),
                            ],
                            // Traveler badge
                            if (widget.profile.isTravelerActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.flight, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppLocalizations.of(context)?.travelerBadge ?? 'Traveler',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Nickname
                        if (widget.profile.nickname != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.richGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.richGold.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              '@${widget.profile.nickname}',
                              style: const TextStyle(
                                color: AppColors.richGold,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Location — uses effectiveLocation to show traveler city when active
                        Row(
                          children: [
                            Icon(
                              widget.profile.isTravelerActive ? Icons.flight : Icons.location_on,
                              color: widget.profile.isTravelerActive
                                  ? const Color(0xFF42A5F5)
                                  : AppColors.textTertiary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.profile.effectiveLocation.displayAddress,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Business surface: Follow + Contact + storefront entry.
                        // Shown only for business accounts. The Follow/Contact
                        // widgets self-hide their action when viewing your own.
                        if (widget.profile.isBusiness) ...[
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              BusinessFollowButton(
                                businessId: widget.profile.userId,
                                currentUserId: widget.currentUserId,
                                compact: true,
                              ),
                              if (!_isSelfView)
                                BusinessContactButton(
                                  businessProfile: widget.profile,
                                  currentUserId: widget.currentUserId,
                                  compact: true,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => BusinessStorefrontScreen(
                                      business: widget.profile,
                                      currentUserId: widget.currentUserId,
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.richGold,
                                side: const BorderSide(color: AppColors.richGold),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusM),
                                ),
                              ),
                              icon: const Icon(Icons.storefront, size: 18),
                              label: Text(
                                AppLocalizations.of(context)!.viewStorefront,
                                style: const TextStyle(
                                  color: AppColors.richGold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Bio
                        if (widget.profile.bio.isNotEmpty) ...[
                          _buildSectionTitle(AppLocalizations.of(context)!.about),
                          const SizedBox(height: 12),
                          Text(
                            widget.profile.bio,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Voice Recording - "Listen me!"
                        if (widget.profile.voiceRecordingUrl != null &&
                            widget.profile.voiceRecordingUrl!.isNotEmpty) ...[
                          _buildVoicePlaybackCard(),
                          const SizedBox(height: 24),
                        ],

                        // Interests
                        if (widget.profile.interests.isNotEmpty) ...[
                          _buildSectionTitle(AppLocalizations.of(context)!.interests),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.profile.interests
                                .map(_buildInterestChip)
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Looking for
                        if (widget.profile.lookingFor != null) ...[
                          _buildSectionTitle(AppLocalizations.of(context)!.lookingFor),
                          const SizedBox(height: 12),
                          Text(
                            _getLookingForText(widget.profile.lookingFor!),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Additional details
                        if (widget.profile.height != null ||
                            widget.profile.weight != null ||
                            widget.profile.education != null ||
                            widget.profile.occupation != null) ...[
                          _buildSectionTitle(AppLocalizations.of(context)!.details),
                          const SizedBox(height: 12),
                          if (widget.profile.height != null)
                            _buildDetailRow(
                              icon: Icons.height,
                              label: AppLocalizations.of(context)!.height,
                              value: '${widget.profile.height} cm',
                            ),
                          if (widget.profile.weight != null)
                            _buildDetailRow(
                              icon: Icons.fitness_center,
                              label: AppLocalizations.of(context)!.weightLabel,
                              value: '${widget.profile.weight} kg',
                            ),
                          if (widget.profile.education != null)
                            _buildDetailRow(
                              icon: Icons.school,
                              label: AppLocalizations.of(context)!.education,
                              value: widget.profile.education!,
                            ),
                          if (widget.profile.occupation != null)
                            _buildDetailRow(
                              icon: Icons.work,
                              label: AppLocalizations.of(context)!.occupation,
                              value: widget.profile.occupation!,
                            ),
                          const SizedBox(height: 24),
                        ],

                        // Social Links section
                        if (widget.profile.socialLinks != null &&
                            widget.profile.socialLinks!.hasAnyLink) ...[
                          _buildSectionTitle(AppLocalizations.of(context)!.socialProfiles),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _buildSocialLinkButtons(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Match badge if matched
                        if (isMatched) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.richGold.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusM),
                              border: Border.all(
                                color: AppColors.richGold.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: AppColors.richGold,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.matchedWithDate(widget.profile.displayName, _formatMatchDate(widget.match!.matchedAt)),
                                    style: const TextStyle(
                                      color: AppColors.richGold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Bottom padding for action buttons
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Action buttons — only the FULL/dating flavor shows bottom actions
          // (swipe/like/super-like or the matched "Let's Chat" button). The
          // Apple-safe culture flavor has NO bottom action here — connecting is
          // a single Message action in the app bar (see [build]'s AppBar
          // actions). No like/super-like/match/Connect button anywhere.
          if (!_isSelfView &&
              (FlavorConfig.enableMatching ||
                  FlavorConfig.enableSwipeDiscovery))
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: isMatched
                    ? _buildMatchedActionButtons(context)
                    : widget.onSwipe != null
                        ? SwipeButtons(
                            onPass: () {
                              widget.onSwipe!(SwipeActionType.pass);
                              Navigator.of(context).pop();
                            },
                            onLike: () {
                              widget.onSwipe!(SwipeActionType.like);
                              Navigator.of(context).pop();
                            },
                            onSuperLike: () {
                              widget.onSwipe!(SwipeActionType.superLike);
                              Navigator.of(context).pop();
                            },
                          )
                        : const SizedBox.shrink(),
              ),
            ),
        ],
      ),
      ),
      ),
    );
  }

  /// Build action buttons when users are matched (Let's Chat! button)
  Widget _buildMatchedActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _navigateToChat(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.richGold,
          foregroundColor: AppColors.deepBlack,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
          shadowColor: AppColors.richGold.withOpacity(0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble, size: 24),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.letsChat,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChat(BuildContext context) {
    if (widget.match == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          matchId: widget.match!.matchId,
          currentUserId: widget.currentUserId,
          otherUserId: widget.profile.userId,
          otherUserProfile: widget.profile,
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel() {
    return Stack(
      children: [
        // Photos with double-tap to like
        TourShowcase(
          showcaseKey: TourKeys.detailPhotoDoubleTap,
          title: AppLocalizations.of(context)!.tourDetailDoubleTapTitle,
          description: AppLocalizations.of(context)!.tourDetailDoubleTapDesc,
          gesture: TourGesture.doubleTap,
          child: GestureDetector(
          onDoubleTap: _togglePhotoLike,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPhotoIndex = index;
              });
            },
            itemCount: widget.profile.photoUrls.length,
            itemBuilder: (context, index) {
              return Image.network(
                widget.profile.photoUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPhotoPlaceholder(),
              );
            },
          ),
        ),
        ),

        // Like animation (heart that appears on double-tap)
        if (_showLikeAnimation)
          const Positioned.fill(
            child: Center(
              child: _LikeAnimationWidget(),
            ),
          ),

        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.backgroundDark,
                  AppColors.backgroundDark.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Photo indicators
        if (widget.profile.photoUrls.length > 1)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Row(
              children: List.generate(
                widget.profile.photoUrls.length,
                (index) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index == _currentPhotoIndex
                          ? AppColors.richGold
                          : AppColors.textTertiary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Like button and count (Instagram style)
        Positioned(
          bottom: 16,
          right: 16,
          child: _buildPhotoLikeButton(),
        ),
      ],
    );
  }

  Widget _buildPhotoLikeButton() {
    final isLiked = _photoLikedByMe[_currentPhotoIndex] ?? false;
    final likeCount = _photoLikeCounts[_currentPhotoIndex] ?? 0;

    return GestureDetector(
      onTap: _togglePhotoLike,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(isLiked),
                color: isLiked ? Colors.red : Colors.white,
                size: 24,
              ),
            ),
            if (likeCount > 0) ...[
              const SizedBox(width: 6),
              Text(
                likeCount > 999 ? '${(likeCount / 1000).toStringAsFixed(1)}k' : '$likeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: AppColors.backgroundCard,
      child: const Center(
        child: Icon(
          Icons.person,
          size: 100,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInterestChip(String interest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        interest,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getLookingForText(String lookingFor) {
    switch (lookingFor.toLowerCase()) {
      case 'long_term':
        return AppLocalizations.of(context)!.longTermRelationship;
      case 'short_term':
        return AppLocalizations.of(context)!.shortTermRelationship;
      case 'friendship':
        return AppLocalizations.of(context)!.friendship;
      case 'casual':
        return AppLocalizations.of(context)!.casualDating;
      default:
        return lookingFor;
    }
  }

  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return AppLocalizations.of(context)!.today;
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      return AppLocalizations.of(context)!.daysAgo(difference.inDays);
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Widget _buildVoicePlaybackCard() {
    final progress = _voiceDuration.inMilliseconds > 0
        ? _voicePosition.inMilliseconds / _voiceDuration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.richGold.withOpacity(0.15),
            AppColors.richGold.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _toggleVoicePlayback,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.richGold,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.richGold.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                _isPlayingVoice ? Icons.pause : Icons.play_arrow,
                color: AppColors.deepBlack,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Waveform and label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.mic,
                      color: AppColors.richGold,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.listenMe,
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _isPlayingVoice || _voicePosition > Duration.zero
                          ? '${_formatVoiceDuration(_voicePosition)} / ${_formatVoiceDuration(_voiceDuration)}'
                          : _voiceDuration > Duration.zero
                              ? _formatVoiceDuration(_voiceDuration)
                              : '',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Waveform bars
                SizedBox(
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(28, (index) {
                      final isActive = index / 28 <= progress;
                      final height = 6.0 + (index % 7) * 2.5;
                      return Container(
                        width: 3,
                        height: height,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.richGold
                              : AppColors.richGold.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSocialLinkButtons() {
    final socialLinks = widget.profile.socialLinks;
    if (socialLinks == null) return [];

    final buttons = <Widget>[];

    if (socialLinks.instagramUrl != null) {
      buttons.add(_buildSocialButton(
        icon: Icons.camera_alt,
        label: 'Instagram',
        color: const Color(0xFFE4405F),
        url: socialLinks.instagramUrl!,
      ));
    }

    if (socialLinks.facebookUrl != null) {
      buttons.add(_buildSocialButton(
        icon: Icons.facebook,
        label: 'Facebook',
        color: const Color(0xFF1877F2),
        url: socialLinks.facebookUrl!,
      ));
    }

    if (socialLinks.tiktokUrl != null) {
      buttons.add(_buildSocialButton(
        icon: Icons.music_note,
        label: 'TikTok',
        color: const Color(0xFFFFFFFF),
        url: socialLinks.tiktokUrl!,
      ));
    }

    if (socialLinks.linkedinUrl != null) {
      buttons.add(_buildSocialButton(
        icon: Icons.work,
        label: 'LinkedIn',
        color: const Color(0xFF0A66C2),
        url: socialLinks.linkedinUrl!,
      ));
    }

    if (socialLinks.xUrl != null) {
      buttons.add(_buildSocialButton(
        icon: Icons.alternate_email,
        label: 'X',
        color: const Color(0xFFFFFFFF),
        url: socialLinks.xUrl!,
      ));
    }

    return buttons;
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required String url,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchUrl(url),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    // Ensure URL has a scheme
    var finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }

    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.couldNotOpenLink),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}

/// Like animation widget (heart that pops up on double-tap)
class _LikeAnimationWidget extends StatefulWidget {
  const _LikeAnimationWidget();

  @override
  State<_LikeAnimationWidget> createState() => _LikeAnimationWidgetState();
}

class _LikeAnimationWidgetState extends State<_LikeAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 30,
      ),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: const Icon(
              Icons.favorite,
              color: Colors.red,
              size: 100,
            ),
          ),
        );
      },
    );
  }
}
