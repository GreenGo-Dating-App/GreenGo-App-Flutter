import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

/// Game Invite Popup
///
/// Shown to the invited user when a game invite arrives.
/// Displays host info, game details, and Accept/Decline buttons.
/// Auto-dismisses after 30 seconds.
class GameInvitePopup extends StatefulWidget {
  final String inviteId;
  final String roomId;
  final String hostNickname;
  final String? hostPhotoUrl;
  final String gameName;
  final String gameType;
  final String targetLanguage;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const GameInvitePopup({
    super.key,
    required this.inviteId,
    required this.roomId,
    required this.hostNickname,
    this.hostPhotoUrl,
    required this.gameName,
    required this.gameType,
    required this.targetLanguage,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<GameInvitePopup> createState() => _GameInvitePopupState();
}

class _GameInvitePopupState extends State<GameInvitePopup>
    with SingleTickerProviderStateMixin {
  Timer? _autoDeclineTimer;
  int _secondsRemaining = 30;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _autoDeclineTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsRemaining--;
      });
      if (_secondsRemaining <= 0) {
        timer.cancel();
        widget.onDecline();
      }
    });
  }

  @override
  void dispose() {
    _autoDeclineTimer?.cancel();
    _bounceController.dispose();
    super.dispose();
  }

  String _gameEmoji(String gameType) {
    const emojis = {
      'wordBomb': '\u{1F4A3}',
      'translationRace': '\u{1F3CE}',
      'pictureGuess': '\u{1F5BC}',
      'grammarDuel': '\u{2694}',
      'vocabularyChain': '\u{1F517}',
      'languageSnaps': '\u{1F0CF}',
      'languageTapples': '\u{1F524}',
      'categories': '\u{1F4CB}',
    };
    return emojis[gameType] ?? '\u{1F3AE}';
  }

  String _languageName(String code) {
    const names = {
      'it': 'Italian',
      'en': 'English',
      'fr': 'French',
      'de': 'German',
      'pt': 'Portuguese',
      'pt-BR': 'Brazilian Portuguese',
      'es': 'Spanish',
    };
    return names[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.richGold.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.richGold.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Game emoji
              Text(
                _gameEmoji(widget.gameType),
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 12),

              // Game name
              Text(
                widget.gameName,
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Host avatar
              CircleAvatar(
                radius: 28,
                backgroundImage: widget.hostPhotoUrl != null
                    ? NetworkImage(widget.hostPhotoUrl!)
                    : null,
                backgroundColor: AppColors.backgroundInput,
                child: widget.hostPhotoUrl == null
                    ? const Icon(Icons.person,
                        color: AppColors.textTertiary, size: 28)
                    : null,
              ),
              const SizedBox(height: 12),

              // Invite message
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '@${widget.hostNickname}',
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: ' invited you to play!',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Language badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language,
                        color: AppColors.richGold, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _languageName(widget.targetLanguage),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Timer
              Text(
                'Expires in ${_secondsRemaining}s',
                style: TextStyle(
                  color: _secondsRemaining <= 10
                      ? AppColors.errorRed
                      : AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),

              // Action buttons
              Row(
                children: [
                  // Decline
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onDecline();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Decline',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Accept
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        widget.onAccept();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.backgroundDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: const Text('Accept',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
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
}
