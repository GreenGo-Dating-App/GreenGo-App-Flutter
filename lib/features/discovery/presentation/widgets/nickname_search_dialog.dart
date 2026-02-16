import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/data/models/profile_model.dart';
import '../screens/profile_detail_screen.dart';

/// Nickname Search Dialog
///
/// Allows users to search for profiles by their unique nickname
class NicknameSearchDialog extends StatefulWidget {
  final String currentUserId;

  const NicknameSearchDialog({
    super.key,
    required this.currentUserId,
  });

  static Future<void> show(BuildContext context, String currentUserId) {
    return showDialog(
      context: context,
      builder: (context) => NicknameSearchDialog(currentUserId: currentUserId),
    );
  }

  @override
  State<NicknameSearchDialog> createState() => _NicknameSearchDialogState();
}

class _NicknameSearchDialogState extends State<NicknameSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isSearching = false;
  Profile? _foundProfile;
  String? _errorMessage;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();

    final nickname = value.trim().toLowerCase();

    if (nickname.isEmpty) {
      setState(() {
        _foundProfile = null;
        _errorMessage = null;
        _hasSearched = false;
      });
      return;
    }

    // Debounce the search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchByNickname(nickname);
    });
  }

  Future<void> _searchByNickname(String nickname) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundProfile = null;
    });

    try {
      // Query Firestore for the nickname
      final querySnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();

      if (!mounted) return;

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _isSearching = false;
          _hasSearched = true;
          _errorMessage = 'No profile found with @$nickname';
        });
      } else {
        final profileDoc = querySnapshot.docs.first;
        final profile = ProfileModel.fromFirestore(profileDoc);

        // Don't show user's own profile
        if (profile.userId == widget.currentUserId) {
          setState(() {
            _isSearching = false;
            _hasSearched = true;
            _errorMessage = "That's your own profile!";
          });
        } else {
          // Check if either user has blocked the other
          final isBlocked = await _isUserBlocked(widget.currentUserId, profile.userId);
          if (!mounted) return;

          if (isBlocked) {
            setState(() {
              _isSearching = false;
              _hasSearched = true;
              _errorMessage = 'No profile found with @$nickname';
            });
          } else {
            setState(() {
              _isSearching = false;
              _hasSearched = true;
              _foundProfile = profile;
            });
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _hasSearched = true;
        _errorMessage = 'Error searching. Please try again.';
      });
    }
  }

  /// Check if either user has blocked the other (bidirectional)
  Future<bool> _isUserBlocked(String userId, String otherUserId) async {
    try {
      final blockQuery = await FirebaseFirestore.instance
          .collection('blocked_users')
          .where('blockerId', whereIn: [userId, otherUserId])
          .get();

      for (final doc in blockQuery.docs) {
        final data = doc.data();
        final blockerId = data['blockerId'] as String;
        final blockedUserId = data['blockedUserId'] as String;

        if ((blockerId == userId && blockedUserId == otherUserId) ||
            (blockerId == otherUserId && blockedUserId == userId)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _viewProfile() {
    if (_foundProfile == null) return;

    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          profile: _foundProfile!,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.search,
                  color: AppColors.richGold,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Search by Nickname',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textTertiary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search input
            TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '@',
                prefixStyle: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                hintText: 'Enter nickname',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary.withOpacity(0.6),
                ),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: const BorderSide(color: AppColors.richGold),
                ),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.richGold,
                          ),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textTertiary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _foundProfile = null;
                                _errorMessage = null;
                                _hasSearched = false;
                              });
                            },
                          )
                        : null,
              ),
              onChanged: _onSearchChanged,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _searchByNickname(value.trim().toLowerCase());
                }
              },
            ),

            const SizedBox(height: 16),

            // Results section
            if (_hasSearched) ...[
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_off,
                        color: AppColors.errorRed,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_foundProfile != null) ...[
                _buildProfilePreview(),
              ],
            ] else ...[
              // Help text
              Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.textTertiary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enter a nickname to find someone directly',
                        style: TextStyle(
                          color: AppColors.textTertiary.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePreview() {
    final profile = _foundProfile!;
    final hasPhoto = profile.photoUrls.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _viewProfile,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Profile photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: AppColors.backgroundCard,
                    child: hasPhoto
                        ? Image.network(
                            profile.photoUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: AppColors.textTertiary,
                              size: 24,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: AppColors.textTertiary,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Profile info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.displayName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${profile.age}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (profile.nickname != null)
                        Text(
                          '@${profile.nickname}',
                          style: const TextStyle(
                            color: AppColors.richGold,
                            fontSize: 13,
                          ),
                        ),
                      if (profile.location.city.isNotEmpty)
                        Text(
                          profile.location.city,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                // View button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.richGold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
