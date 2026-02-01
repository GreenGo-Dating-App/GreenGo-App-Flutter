import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/swipe_action.dart';
import '../widgets/swipe_buttons.dart';

/// Profile Detail Screen
///
/// Full profile view with photos, bio, interests, and details
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Check if this is self-view mode (user viewing their own profile)
  bool get _isSelfView => widget.profile.userId == widget.currentUserId;

  @override
  Widget build(BuildContext context) {
    final hasPhotos = widget.profile.photoUrls.isNotEmpty;
    final isMatched = widget.match != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
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
                        // Name and age
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
    );
  }

  /// Build action buttons when users are matched (Chat button)
  Widget _buildMatchedActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Chat Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _navigateToChat(context),
              icon: const Icon(Icons.chat_bubble),
              label: Text('Chat with ${widget.profile.displayName}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                ),
              ),
            ),
          ),
        ],
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
        // Photos
        PageView.builder(
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
      ],
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
}
