import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../domain/entities/match.dart';
import 'profile_detail_screen.dart';

/// Match Detail Screen
/// Shows match info with overlapping photos, both users' details, gamification stats
class MatchDetailScreen extends StatefulWidget {
  final Match match;
  final Profile? profile;
  final String currentUserId;

  const MatchDetailScreen({
    super.key,
    required this.match,
    this.profile,
    required this.currentUserId,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  Profile? _currentUserProfile;
  Profile? _otherUserProfile;
  Map<String, dynamic>? _currentUserGamification;
  Map<String, dynamic>? _otherUserGamification;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _otherUserProfile = widget.profile;
    _fetchData();
  }

  String get _otherUserId => widget.match.getOtherUserId(widget.currentUserId);

  Future<void> _fetchData() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Fetch current user's profile, other user profile (if not provided), and gamification data
      final futures = <Future<dynamic>>[
        firestore.collection('profiles').doc(widget.currentUserId).get(),
        firestore.collection('user_levels').doc(widget.currentUserId).get(),
        firestore.collection('user_levels').doc(_otherUserId).get(),
      ];

      // Also fetch other user's profile if not provided
      if (widget.profile == null) {
        futures.add(firestore.collection('profiles').doc(_otherUserId).get());
      }

      final results = await Future.wait(futures);

      final profileDoc = results[0] as DocumentSnapshot;
      final currentGamDoc = results[1] as DocumentSnapshot;
      final otherGamDoc = results[2] as DocumentSnapshot;

      if (mounted) {
        setState(() {
          if (profileDoc.exists) {
            _currentUserProfile = ProfileModel.fromFirestore(profileDoc);
          }
          if (currentGamDoc.exists) {
            _currentUserGamification = currentGamDoc.data() as Map<String, dynamic>?;
          }
          if (otherGamDoc.exists) {
            _otherUserGamification = otherGamDoc.data() as Map<String, dynamic>?;
          }
          // Set other user profile from Firestore if not provided
          if (widget.profile == null && results.length > 3) {
            final otherProfileDoc = results[3] as DocumentSnapshot;
            if (otherProfileDoc.exists) {
              _otherUserProfile = ProfileModel.fromFirestore(otherProfileDoc);
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

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
                _buildAppBar(context),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.richGold),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),

                              // Overlapping photos
                              _buildOverlappingPhotos(),

                              const SizedBox(height: 24),

                              // "It's a Match!" header
                              const Text(
                                "It's a Match!",
                                style: TextStyle(
                                  color: AppColors.richGold,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Match date
                              Text(
                                'Matched on ${DateFormat('MMMM d, yyyy').format(widget.match.matchedAt)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Both users' info cards side by side
                              _buildUserInfoCards(),

                              const SizedBox(height: 20),

                              // Gamification stats
                              _buildGamificationSection(),

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
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildOverlappingPhotos() {
    final currentPhotoUrl = _currentUserProfile?.photoUrls.isNotEmpty == true
        ? _currentUserProfile!.photoUrls.first
        : null;
    final otherPhotoUrl = _otherUserProfile?.photoUrls.isNotEmpty == true
        ? _otherUserProfile!.photoUrls.first
        : null;

    return SizedBox(
      height: 140,
      width: 220,
      child: Stack(
        children: [
          // Current user (left)
          Positioned(
            left: 0,
            child: _buildCirclePhoto(currentPhotoUrl, 120),
          ),
          // Other user (right, overlapping)
          Positioned(
            right: 0,
            child: _buildCirclePhoto(otherPhotoUrl, 120),
          ),
        ],
      ),
    );
  }

  Widget _buildCirclePhoto(String? photoUrl, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.richGold, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.richGold.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.backgroundCard,
      child: const Icon(Icons.person, size: 50, color: AppColors.textTertiary),
    );
  }

  Widget _buildUserInfoCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current user card
        Expanded(
          child: _buildUserCard(
            name: _currentUserProfile?.displayName ?? 'You',
            age: _currentUserProfile != null
                ? _calculateAge(_currentUserProfile!.dateOfBirth)
                : null,
            education: _currentUserProfile?.education,
            occupation: _currentUserProfile?.occupation,
            height: _currentUserProfile?.height,
            weight: _currentUserProfile?.weight,
            isCurrentUser: true,
          ),
        ),
        const SizedBox(width: 12),
        // Other user card
        Expanded(
          child: _buildUserCard(
            name: _otherUserProfile?.displayName ?? 'Match',
            age: _otherUserProfile != null
                ? _calculateAge(_otherUserProfile!.dateOfBirth)
                : null,
            education: _otherUserProfile?.education,
            occupation: _otherUserProfile?.occupation,
            height: _otherUserProfile?.height,
            weight: _otherUserProfile?.weight,
            isCurrentUser: false,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard({
    required String name,
    int? age,
    String? education,
    String? occupation,
    int? height,
    int? weight,
    required bool isCurrentUser,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrentUser
                  ? AppColors.richGold.withOpacity(0.4)
                  : AppColors.richGold.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCurrentUser)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'YOU',
                    style: TextStyle(
                      color: AppColors.richGold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (age != null)
                Text(
                  '$age years',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              const SizedBox(height: 8),
              if (education != null)
                _buildMiniInfo(Icons.school_outlined, education),
              if (occupation != null)
                _buildMiniInfo(Icons.work_outline, occupation),
              if (height != null)
                _buildMiniInfo(Icons.height, '$height cm'),
              if (weight != null)
                _buildMiniInfo(Icons.fitness_center, '$weight kg'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationSection() {
    if (_currentUserGamification == null && _otherUserGamification == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.richGold.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              const Text(
                'Progress Comparison',
                style: TextStyle(
                  color: AppColors.richGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Current user stats
                  Expanded(
                    child: _buildGamificationStats(
                      _currentUserProfile?.displayName ?? 'You',
                      _currentUserGamification,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 80,
                    color: AppColors.divider,
                  ),
                  // Other user stats
                  Expanded(
                    child: _buildGamificationStats(
                      _otherUserProfile?.displayName ?? 'Match',
                      _otherUserGamification,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamificationStats(String name, Map<String, dynamic>? data) {
    final level = data?['level'] as int? ?? 1;
    final totalXP = data?['totalXP'] as int? ?? 0;

    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        _buildStatRow('Level', '$level'),
        _buildStatRow('XP', '$totalXP'),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.richGold,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        if (_otherUserProfile != null)
          _buildGlassButton(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileDetailScreen(
                    profile: _otherUserProfile!,
                    currentUserId: widget.currentUserId,
                    match: widget.match,
                  ),
                ),
              );
            },
            icon: Icons.person_outline,
            label: 'See Profile',
            isPrimary: false,
          ),
        const SizedBox(height: 16),
        if (_otherUserProfile != null)
          _buildGlassButton(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    matchId: widget.match.matchId,
                    otherUserId: widget.match.getOtherUserId(widget.currentUserId),
                    currentUserId: widget.currentUserId,
                    otherUserProfile: _otherUserProfile!,
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
          'Are you sure you want to unmatch with ${_otherUserProfile?.displayName ?? 'this user'}? This cannot be undone.',
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
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Unmatched with ${_otherUserProfile?.displayName ?? 'user'}'),
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
