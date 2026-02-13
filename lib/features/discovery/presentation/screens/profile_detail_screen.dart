import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../core/widgets/membership_badge.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/swipe_action.dart';
import '../widgets/swipe_buttons.dart';

/// Profile Detail Screen
///
/// Full profile view with photos, bio, interests, and details
/// Includes Instagram-like photo likes feature
class ProfileDetailScreen extends StatefulWidget {
  final Profile profile;
  final String currentUserId;
  final Match? match;
  final Function(SwipeActionType)? onSwipe;

  const ProfileDetailScreen({
    super.key,
    required this.profile,
    required this.currentUserId,
    this.match,
    this.onSwipe,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPhotoIndex = 0;

  // Photo likes state
  Map<int, bool> _photoLikedByMe = {};
  Map<int, int> _photoLikeCounts = {};
  bool _showLikeAnimation = false;

  @override
  void initState() {
    super.initState();
    _loadPhotoLikes();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Load like status for all photos
  Future<void> _loadPhotoLikes() async {
    if (widget.profile.photoUrls.isEmpty) return;

    final firestore = FirebaseFirestore.instance;

    for (int i = 0; i < widget.profile.photoUrls.length; i++) {
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
      child: Scaffold(
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
                            Text(
                              widget.profile.displayName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${widget.profile.age}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 28,
                              ),
                            ),
                            // Show membership badge if not free tier
                            if (widget.profile.membershipTier != MembershipTier.free) ...[
                              const SizedBox(width: 12),
                              MembershipBadge(
                                tier: widget.profile.membershipTier,
                                compact: true,
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

                        // Location
                        if (widget.profile.location != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.textTertiary,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.profile.location!.displayAddress,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 24),

                        // Bio
                        if (widget.profile.bio != null &&
                            widget.profile.bio!.isNotEmpty) ...[
                          _buildSectionTitle('About'),
                          const SizedBox(height: 12),
                          Text(
                            widget.profile.bio!,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Interests
                        if (widget.profile.interests.isNotEmpty) ...[
                          _buildSectionTitle('Interests'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.profile.interests
                                .map((interest) => _buildInterestChip(interest))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Looking for
                        if (widget.profile.lookingFor != null) ...[
                          _buildSectionTitle('Looking for'),
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
                            widget.profile.education != null ||
                            widget.profile.occupation != null) ...[
                          _buildSectionTitle('Details'),
                          const SizedBox(height: 12),
                          if (widget.profile.height != null)
                            _buildDetailRow(
                              icon: Icons.height,
                              label: 'Height',
                              value: '${widget.profile.height} cm',
                            ),
                          if (widget.profile.education != null)
                            _buildDetailRow(
                              icon: Icons.school,
                              label: 'Education',
                              value: widget.profile.education!,
                            ),
                          if (widget.profile.occupation != null)
                            _buildDetailRow(
                              icon: Icons.work,
                              label: 'Occupation',
                              value: widget.profile.occupation!,
                            ),
                          const SizedBox(height: 24),
                        ],

                        // Social Links section
                        if (widget.profile.socialLinks != null &&
                            widget.profile.socialLinks!.hasAnyLink) ...[
                          _buildSectionTitle('Social Profiles'),
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
                                    'You matched with ${widget.profile.displayName} on ${_formatMatchDate(widget.match!.matchedAt)}',
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

          // Action buttons - Hide when self-view, show appropriate buttons based on match status
          if (!_isSelfView)
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
              "Let's Chat!",
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
        GestureDetector(
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
        return 'Long-term relationship';
      case 'short_term':
        return 'Short-term relationship';
      case 'friendship':
        return 'Friendship';
      case 'casual':
        return 'Casual dating';
      default:
        return lookingFor;
    }
  }

  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
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
        color: const Color(0xFF000000),
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
        color: const Color(0xFF000000),
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
    String finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }

    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link'),
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
