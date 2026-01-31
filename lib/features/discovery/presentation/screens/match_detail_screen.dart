import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../domain/entities/match.dart';
import 'profile_detail_screen.dart';

/// Match Detail Screen
/// Shows match info with options to view profile, start chat, or unmatch
class MatchDetailScreen extends StatelessWidget {
  final Match match;
  final Profile profile;
  final String currentUserId;

  const MatchDetailScreen({
    super.key,
    required this.match,
    required this.profile,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.richGold.withOpacity(0.15),
                  Colors.black,
                  Colors.black,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // App bar
                _buildAppBar(context),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Profile photo with glow
                        _buildProfilePhoto(),

                        const SizedBox(height: 24),

                        // Name
                        Text(
                          profile.displayName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (profile.nickname != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '@${profile.nickname}',
                            style: TextStyle(
                              color: AppColors.richGold.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Match info card
                        _buildMatchInfoCard(),

                        const SizedBox(height: 32),

                        // Action buttons
                        _buildActionButtons(context),

                        const SizedBox(height: 24),

                        // Unmatch option
                        _buildUnmatchButton(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
            ),
          ),
          const Expanded(
            child: Text(
              'Match Details',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.richGold.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.richGold,
            width: 3,
          ),
        ),
        child: ClipOval(
          child: profile.photoUrls.isNotEmpty
              ? Image.network(
                  profile.photoUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderPhoto(),
                )
              : _buildPlaceholderPhoto(),
        ),
      ),
    );
  }

  Widget _buildPlaceholderPhoto() {
    return Container(
      color: AppColors.backgroundCard,
      child: const Icon(
        Icons.person,
        size: 80,
        color: AppColors.textTertiary,
      ),
    );
  }

  Widget _buildMatchInfoCard() {
    final matchDate = DateFormat('MMMM d, yyyy').format(match.matchedAt);
    final matchTime = DateFormat('h:mm a').format(match.matchedAt);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.richGold.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              // Match icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.richGold.withOpacity(0.4),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '💕',
                    style: TextStyle(fontSize: 28),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "It's a Match!",
                style: TextStyle(
                  color: AppColors.richGold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'You matched on $matchDate',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),

              Text(
                'at $matchTime',
                style: TextStyle(
                  color: AppColors.textTertiary.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 16),

              // Time ago badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.richGold.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  match.timeSinceMatchText,
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Last message info if exists
              if (match.lastMessage != null) ...[
                const SizedBox(height: 20),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Last message: "${match.lastMessage}"',
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.8),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // See Profile button
        _buildGlassButton(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProfileDetailScreen(
                  profile: profile,
                  currentUserId: currentUserId,
                  match: match,
                ),
              ),
            );
          },
          icon: Icons.person_outline,
          label: 'See Profile',
          isPrimary: false,
        ),

        const SizedBox(height: 16),

        // Start Chat button
        _buildGlassButton(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  matchId: match.matchId,
                  otherUserId: match.getOtherUserId(currentUserId),
                  currentUserId: currentUserId,
                  otherUserProfile: profile,
                ),
              ),
            );
          },
          icon: Icons.chat_bubble_outline,
          label: 'Start Chat',
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: isPrimary
                    ? const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                      )
                    : null,
                color: isPrimary ? null : Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPrimary
                      ? Colors.transparent
                      : AppColors.richGold.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isPrimary ? Colors.black : AppColors.textPrimary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isPrimary ? Colors.black : AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnmatchButton(BuildContext context) {
    return TextButton(
      onPressed: () => _showUnmatchDialog(context),
      child: Text(
        'Unmatch',
        style: TextStyle(
          color: AppColors.textTertiary.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
    );
  }

  void _showUnmatchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Unmatch',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to unmatch with ${profile.displayName}? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement unmatch functionality
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Unmatched with ${profile.displayName}'),
                  backgroundColor: AppColors.backgroundCard,
                ),
              );
            },
            child: const Text(
              'Unmatch',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
