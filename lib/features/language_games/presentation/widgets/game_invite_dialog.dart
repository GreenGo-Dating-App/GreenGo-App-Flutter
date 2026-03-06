import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/game_room.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';

/// Game Invite Dialog
///
/// Allows the host to search for a player by nickname and send a game invite.
class GameInviteDialog extends StatefulWidget {
  final GameRoom room;
  final String hostNickname;
  final String? hostPhotoUrl;

  const GameInviteDialog({
    super.key,
    required this.room,
    required this.hostNickname,
    this.hostPhotoUrl,
  });

  static Future<void> show(
    BuildContext context,
    GameRoom room, {
    required String hostNickname,
    String? hostPhotoUrl,
  }) {
    return showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<LanguageGamesBloc>(),
        child: GameInviteDialog(
          room: room,
          hostNickname: hostNickname,
          hostPhotoUrl: hostPhotoUrl,
        ),
      ),
    );
  }

  @override
  State<GameInviteDialog> createState() => _GameInviteDialogState();
}

class _GameInviteDialogState extends State<GameInviteDialog> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isSearching = false;
  Profile? _foundProfile;
  String? _errorMessage;
  bool _hasSearched = false;
  bool _isSending = false;

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
          _errorMessage = 'No player found with that nickname';
        });
        return;
      }

      final doc = querySnapshot.docs.first;
      final profile = ProfileModel.fromFirestore(doc);

      // Don't allow inviting yourself
      if (profile.userId == widget.room.hostUserId) {
        setState(() {
          _isSearching = false;
          _hasSearched = true;
          _errorMessage = 'You cannot invite yourself';
        });
        return;
      }

      // Don't allow inviting someone already in the room
      if (widget.room.players.any((p) => p.userId == profile.userId)) {
        setState(() {
          _isSearching = false;
          _hasSearched = true;
          _errorMessage = 'This player is already in the room';
        });
        return;
      }

      setState(() {
        _isSearching = false;
        _hasSearched = true;
        _foundProfile = profile;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _hasSearched = true;
        _errorMessage = 'Search failed. Try again.';
      });
    }
  }

  Future<void> _sendInvite() async {
    if (_foundProfile == null || _isSending) return;

    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();

    context.read<LanguageGamesBloc>().add(
          SendGameInvite(
            roomId: widget.room.id,
            invitedUserId: _foundProfile!.userId,
            hostNickname: widget.hostNickname,
            hostPhotoUrl: widget.hostPhotoUrl,
          ),
        );

    // Brief delay for UX
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invite sent to @${_foundProfile!.nickname}!'),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.person_add,
                    color: AppColors.richGold, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Invite Player',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      color: AppColors.textTertiary, size: 22),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search field
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by nickname...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 16),

            // Results area
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(
                    color: AppColors.richGold, strokeWidth: 2),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              )
            else if (_foundProfile != null)
              _buildProfileResult()
            else if (!_hasSearched)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Type a nickname to find a player',
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileResult() {
    final profile = _foundProfile!;
    return Column(
      children: [
        // Profile preview
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: profile.photoUrls.isNotEmpty
                    ? NetworkImage(profile.photoUrls.first)
                    : null,
                backgroundColor: AppColors.backgroundInput,
                child: profile.photoUrls.isEmpty
                    ? const Icon(Icons.person,
                        color: AppColors.textTertiary, size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '@${profile.nickname}',
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Send invite button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSending ? null : _sendInvite,
            icon: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.backgroundDark),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_isSending ? 'Sending...' : 'Send Invite'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.backgroundDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
