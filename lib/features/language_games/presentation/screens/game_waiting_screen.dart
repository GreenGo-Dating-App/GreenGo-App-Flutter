import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/widgets/animated_svg_icon.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_sound_service.dart';
import '../../domain/entities/game_player.dart';
import '../../domain/entities/game_room.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../bloc/language_games_state.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../widgets/game_invite_dialog.dart';
import '../widgets/player_avatar_circle.dart';
import 'categories_screen.dart';
import 'game_play_screen.dart';
import 'game_results_screen.dart';
import 'grammar_duel_screen.dart';
import 'language_snaps_screen.dart';
import 'language_tapples_screen.dart';
import 'picture_guess_screen.dart';
import 'translation_race_screen.dart';
import 'vocabulary_chain_screen.dart';

/// Matchmaking/waiting room screen
/// Shows player slots, ready status, and game config before starting
class GameWaitingScreen extends StatefulWidget {
  final String userId;
  final String? displayName;
  final GameRoom room;

  const GameWaitingScreen({
    super.key,
    required this.userId,
    this.displayName,
    required this.room,
  });

  /// Returns the display name, falling back to the localized default.
  String getDisplayName(AppLocalizations l10n) =>
      displayName ?? l10n.gameDefaultPlayerName;

  @override
  State<GameWaitingScreen> createState() => _GameWaitingScreenState();
}

class _GameWaitingScreenState extends State<GameWaitingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Start background waiting music
    AppSoundService().playBgMusic(AppSound.gameWaiting);
  }

  @override
  void dispose() {
    AppSoundService().stopBgMusic();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  GameRoom _roomFromState(LanguageGamesState state) {
    if (state is LanguageGamesInRoom) return state.room;
    return widget.room;
  }

  void _onReadyTap(GameRoom room) {
    HapticFeedback.mediumImpact();
    context.read<LanguageGamesBloc>().add(
          ToggleReady(roomId: room.id, userId: widget.userId),
        );
  }

  void _onStartGame(GameRoom room) {
    HapticFeedback.heavyImpact();
    context.read<LanguageGamesBloc>().add(StartGame(roomId: room.id));
  }

  void _onLeaveRoom(GameRoom room) {
    HapticFeedback.lightImpact();
    context.read<LanguageGamesBloc>().add(
          LeaveRoom(roomId: room.id, userId: widget.userId),
        );
    Navigator.of(context).pop();
  }

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.gameWaitingInviteCodeCopied),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToGamePlay(GameRoom room) {
    AppSoundService().stopBgMusic();
    AppSoundService().play(AppSound.gameStart);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<LanguageGamesBloc>(),
          child: _GameLoadingSplash(
            gameType: room.gameType,
            onComplete: () {
              if (room.gameType == GameType.translationRace) {
                return _TranslationRaceWrapper(
                  userId: widget.userId,
                  initialRoom: room,
                );
              }
              if (room.gameType == GameType.pictureGuess) {
                return _PictureGuessWrapper(
                  userId: widget.userId,
                  initialRoom: room,
                );
              }
              if (room.gameType == GameType.grammarDuel) {
                return _GrammarDuelWrapper(
                  userId: widget.userId,
                  initialRoom: room,
                );
              }
              if (room.gameType == GameType.vocabularyChain) {
                return _VocabularyChainWrapper(
                  userId: widget.userId,
                  initialRoom: room,
                );
              }
              if (room.gameType == GameType.languageSnaps) {
                return _LanguageSnapsWrapper(
                  userId: widget.userId,
                  initialRoom: room,
                );
              }
              if (room.gameType == GameType.languageTapples) {
                return _LanguageTapplesWrapper(
                  userId: widget.userId,
                  initialRoom: room,
                );
              }
              if (room.gameType == GameType.categories) {
                return _CategoriesWrapper(
                  userId: widget.userId,
                  initialRoom: room,
                );
              }
              return GamePlayScreen(
                userId: widget.userId,
                room: room,
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LanguageGamesBloc, LanguageGamesState>(
      listener: (context, state) {
        if (state is LanguageGamesInRoom &&
            state.room.status == GameStatus.inProgress) {
          _navigateToGamePlay(state.room);
        }
      },
      builder: (context, state) {
        final room = _roomFromState(state);
        final isHost = room.isHost(widget.userId);
        final currentPlayer = room.getPlayer(widget.userId);
        final isReady = currentPlayer?.isReady ?? false;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundDark,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: AppColors.textPrimary),
              onPressed: () => _onLeaveRoom(room),
            ),
            title: Text(
              '${room.gameType.emoji} ${room.gameType.displayName}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              // Floating particle background
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, _) => CustomPaint(
                    painter: _WaitingParticlePainter(
                      progress: _particleController.value,
                    ),
                  ),
                ),
              ),
              // Main content
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildWaitingHeader(room),
                        const SizedBox(height: 24),
                        _buildGameInfoBadges(room),
                        const SizedBox(height: 28),
                        _buildPlayerSlots(room),
                        const SizedBox(height: 16),
                        if (isHost && !room.isFull)
                          _buildInvitePlayerButton(room),
                        const SizedBox(height: 24),
                        if (room.friendGroupId != null)
                          _buildInviteCode(room.friendGroupId!),
                        _buildLiveCount(room),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                  _buildBottomActions(room, isHost, isReady),
                ],
              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaitingHeader(GameRoom room) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(room.gameType.emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        FadeTransition(
          opacity: _pulseAnimation,
          child: Text(
            l10n.gameWaitingForPlayers,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          room.playerCountText,
          style: const TextStyle(
            color: AppColors.richGold,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGameInfoBadges(GameRoom room) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _InfoBadge(
          icon: Icons.language,
          label: _languageDisplayName(room.targetLanguage, l10n),
        ),
        const SizedBox(width: 12),
        _InfoBadge(icon: Icons.speed, label: l10n.gameWaitingLevelNumber(room.difficulty)),
        const SizedBox(width: 12),
        _InfoBadge(
            icon: Icons.replay, label: l10n.gameWaitingRoundsCount(room.totalRounds)),
      ],
    );
  }

  Widget _buildPlayerSlots(GameRoom room) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.gameWaitingPlayersHeader,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(room.maxPlayers, (index) {
          if (index < room.players.length) {
            return _buildFilledSlot(room.players[index], room);
          }
          return _buildEmptySlot();
        }),
      ],
    );
  }

  Widget _buildFilledSlot(GamePlayer player, GameRoom room) {
    final isMe = player.userId == widget.userId;
    final isHost = room.hostUserId == player.userId;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.richGold.withValues(alpha: 0.08)
            : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? AppColors.richGold.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          PlayerAvatarCircle(
            player: player,
            isCurrentUser: isMe,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isMe ? l10n.gameYou : player.displayName,
                      style: TextStyle(
                        color: isMe
                            ? AppColors.richGold
                            : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isHost) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.richGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.gameWaitingHost,
                          style: const TextStyle(
                            color: AppColors.richGold,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (!player.isConnected)
                  Text(
                    l10n.gameWaitingDisconnected,
                    style: const TextStyle(color: AppColors.errorRed, fontSize: 11),
                  ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: player.isReady
                  ? AppColors.successGreen.withValues(alpha: 0.15)
                  : AppColors.divider.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: player.isReady
                    ? AppColors.successGreen
                    : AppColors.divider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  player.isReady
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: player.isReady
                      ? AppColors.successGreen
                      : AppColors.textTertiary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  player.isReady ? l10n.gameWaitingReady : l10n.gameWaitingNotReady,
                  style: TextStyle(
                    color: player.isReady
                        ? AppColors.successGreen
                        : AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot() {
    final l10n = AppLocalizations.of(context)!;
    return FadeTransition(
      opacity: _pulseAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.divider.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.backgroundInput.withValues(alpha: 0.5),
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.gameWaitingEllipsis,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitePlayerButton(GameRoom room) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          // Get host nickname from ProfileBloc
          String hostNickname = l10n.gameWaitingHost;
          String? hostPhotoUrl;
          try {
            final profileState = context.read<ProfileBloc>().state;
            if (profileState is ProfileLoaded) {
              hostNickname = profileState.profile.nickname ?? l10n.gameWaitingHost;
              hostPhotoUrl = profileState.profile.photoUrls.isNotEmpty
                  ? profileState.profile.photoUrls.first
                  : null;
            } else if (profileState is ProfileUpdated) {
              hostNickname = profileState.profile.nickname ?? l10n.gameWaitingHost;
              hostPhotoUrl = profileState.profile.photoUrls.isNotEmpty
                  ? profileState.profile.photoUrls.first
                  : null;
            }
          } catch (_) {}
          GameInviteDialog.show(
            context,
            room,
            hostNickname: hostNickname,
            hostPhotoUrl: hostPhotoUrl,
          );
        },
        icon: const Icon(Icons.person_add, size: 18),
        label: Text(l10n.gameWaitingInvitePlayer),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.richGold,
          side: BorderSide(
              color: AppColors.richGold.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildInviteCode(String code) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.richGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            l10n.gameWaitingInviteCodeHeader,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                code.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _copyInviteCode(code),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy_rounded,
                      color: AppColors.richGold, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.gameWaitingShareCode,
            style:
                const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCount(GameRoom room) {
    final l10n = AppLocalizations.of(context)!;
    final notReadyCount = room.players.where((p) => !p.isReady).length;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.successGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.successGreen.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${l10n.gameWaitingPlayersInRoom(room.players.length)}'
            '${notReadyCount > 0 ? ' ${l10n.gameWaitingNotReadyCount(notReadyCount)}' : ''}',
            style: const TextStyle(
                color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(GameRoom room, bool isHost, bool isReady) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isHost && room.allPlayersReady)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _onStartGame(room),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.backgroundDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 24),
                      const SizedBox(width: 8),
                      Text(l10n.gameWaitingStartGame,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _onReadyTap(room),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReady
                        ? AppColors.divider
                        : AppColors.successGreen,
                    foregroundColor:
                        isReady ? AppColors.textSecondary : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isReady ? l10n.gameWaitingCancelReady : l10n.gameWaitingReadyUp,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _onLeaveRoom(room),
                child: Text(
                  l10n.gameWaitingLeaveRoom,
                  style: const TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _languageDisplayName(String code, AppLocalizations l10n) {
    final names = {
      'it': l10n.gameLanguageItalian,
      'en': l10n.gameLanguageEnglish,
      'fr': l10n.gameLanguageFrench,
      'de': l10n.gameLanguageGerman,
      'pt': l10n.gameLanguagePortuguese,
      'pt-BR': l10n.gameLanguageBrazilianPortuguese,
      'es': l10n.gameLanguageSpanish,
    };
    return names[code] ?? code;
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.richGold, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating particles background for waiting screen
class _WaitingParticlePainter extends CustomPainter {
  final double progress;

  _WaitingParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(31);
    const count = 30;

    for (int i = 0; i < count; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble() * pi * 2;
      final radius = 1.5 + rng.nextDouble() * 2.5;

      // Float upward and drift sideways
      final dy = -size.height * 0.15 * ((progress * speed + rng.nextDouble()) % 1.0);
      final dx = sin(progress * pi * 2 * speed + phase) * 20;
      final opacity = (0.04 + 0.06 * sin(progress * pi * 2 * speed + phase)).clamp(0.0, 1.0);

      final px = baseX + dx;
      final py = (baseY + dy) % size.height;

      // Gold particles
      canvas.drawCircle(
        Offset(px, py),
        radius,
        Paint()..color = AppColors.richGold.withOpacity(opacity),
      );

      // Small glow around each particle
      canvas.drawCircle(
        Offset(px, py),
        radius * 3,
        Paint()..color = AppColors.richGold.withOpacity(opacity * 0.15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaitingParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Splash screen showing the game icon + 3-2-1-GO! countdown before game.
/// Total duration: ~3.5s (icon 800ms + countdown ~2700ms).
class _GameLoadingSplash extends StatefulWidget {
  final GameType gameType;
  final Widget Function() onComplete;

  const _GameLoadingSplash({
    required this.gameType,
    required this.onComplete,
  });

  @override
  State<_GameLoadingSplash> createState() => _GameLoadingSplashState();
}

class _GameLoadingSplashState extends State<_GameLoadingSplash>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconScale;
  late Animation<double> _iconOpacity;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _particleController;

  // Countdown state
  String? _countdownText; // "3", "2", "1", "GO!"
  late AnimationController _countdownController;
  late Animation<double> _countdownScale;
  late Animation<double> _countdownOpacity;
  late AnimationController _flashController;
  late Animation<double> _flashOpacity;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _iconScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Countdown number animation (reused for each number)
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _countdownScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.elasticOut),
    );
    _countdownOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _countdownController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // GO! flash
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.35), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.0), weight: 70),
    ]).animate(_flashController);

    _iconController.forward();

    // Start countdown sequence after icon animation
    _runCountdownSequence();
  }

  Future<void> _runCountdownSequence() async {
    // Wait for icon animation to finish
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    // 3
    await _showCountdownNumber('3');
    if (!mounted) return;

    // 2
    await _showCountdownNumber('2');
    if (!mounted) return;

    // 1
    await _showCountdownNumber('1');
    if (!mounted) return;

    // GO!
    HapticFeedback.heavyImpact();
    setState(() => _countdownText = 'GO!');
    _countdownController.reset();
    _countdownController.forward();
    _flashController.reset();
    _flashController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Navigate to game
    if (!_navigated) {
      _navigated = true;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => BlocProvider.value(
            value: context.read<LanguageGamesBloc>(),
            child: widget.onComplete(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  Future<void> _showCountdownNumber(String number) async {
    HapticFeedback.lightImpact();
    setState(() => _countdownText = number);
    _countdownController.reset();
    _countdownController.forward();

    // Scale in (400ms) + hold (200ms) = 600ms per number
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _iconController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _countdownController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isGo = _countdownText == 'GO!';
    final displayCountdownText = _countdownText == 'GO!'
        ? l10n.gameWaitingCountdownGo
        : _countdownText;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Fire particles background (intensify during countdown)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                painter: _SplashParticlePainter(
                  progress: _particleController.value,
                  intensity: _countdownText != null ? 1.5 : 0.8,
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon (fades out when countdown starts)
                AnimatedOpacity(
                  opacity: _countdownText != null ? 0.3 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_iconController, _pulseController]),
                    builder: (context, _) {
                      return Opacity(
                        opacity: _iconOpacity.value,
                        child: Transform.scale(
                          scale: _iconScale.value * _pulseAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.richGold.withValues(alpha: 0.3),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: AnimatedSvgIcon(
                              assetPath: widget.gameType.iconAsset,
                              width: 100,
                              height: 100,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Game title
                AnimatedOpacity(
                  opacity: _countdownText != null ? 0.4 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    widget.gameType.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Countdown number / GO!
                SizedBox(
                  height: 120,
                  child: _countdownText != null
                      ? AnimatedBuilder(
                          animation: _countdownController,
                          builder: (context, _) {
                            return Opacity(
                              opacity: _countdownOpacity.value,
                              child: Transform.scale(
                                scale: _countdownScale.value,
                                child: Text(
                                  displayCountdownText!,
                                  style: TextStyle(
                                    fontSize: isGo ? 100 : 80,
                                    fontWeight: FontWeight.bold,
                                    color: isGo
                                        ? AppColors.richGold
                                        : Colors.white,
                                    shadows: isGo
                                        ? [
                                            const Shadow(
                                              color: AppColors.richGold,
                                              blurRadius: 30,
                                            ),
                                            Shadow(
                                              color: AppColors.richGold
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 60,
                                            ),
                                          ]
                                        : [
                                            Shadow(
                                              color: Colors.white
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 20,
                                            ),
                                          ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.richGold),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.gameWaitingGetReady,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),

          // GO! flash overlay
          if (isGo)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _flashOpacity,
                builder: (context, _) {
                  return IgnorePointer(
                    child: Container(
                      color: Colors.white.withValues(alpha: _flashOpacity.value),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Fire particles for splash screen — intensity increases during countdown
class _SplashParticlePainter extends CustomPainter {
  final double progress;
  final double intensity;

  _SplashParticlePainter({required this.progress, this.intensity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    final count = (20 * intensity).toInt();

    for (int i = 0; i < count; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble() * pi * 2;
      final radius = 1.5 + rng.nextDouble() * 2.0;

      final dy = -size.height * 0.15 * ((progress * speed + rng.nextDouble()) % 1.0);
      final dx = sin(progress * pi * 2 * speed + phase) * 15;
      final opacity = (0.04 + 0.06 * intensity * sin(progress * pi * 2 * speed + phase))
          .clamp(0.0, 0.15);

      final px = baseX + dx;
      final py = (baseY + dy) % size.height;

      final color = i % 3 == 0
          ? AppColors.warningAmber
          : i % 3 == 1
              ? AppColors.errorRed
              : AppColors.richGold;

      canvas.drawCircle(
        Offset(px, py),
        radius,
        Paint()..color = color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashParticlePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.intensity != intensity;
  }
}

/// Wrapper that subscribes to bloc state and passes room/round to TranslationRaceScreen
class _TranslationRaceWrapper extends StatelessWidget {
  final String userId;
  final GameRoom initialRoom;

  const _TranslationRaceWrapper({
    required this.userId,
    required this.initialRoom,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageGamesBloc, LanguageGamesState>(
      builder: (context, state) {
        final room = state is LanguageGamesInRoom ? state.room : initialRoom;
        final round = state is LanguageGamesInRoom ? state.currentRound : null;

        if (room.status == GameStatus.finished ||
            state is LanguageGamesFinished) {
          final finishedRoom =
              state is LanguageGamesFinished ? state.room : room;
          final scores = state is LanguageGamesFinished
              ? state.finalScores
              : room.scores;
          final xp =
              state is LanguageGamesFinished ? state.xpEarned : room.xpReward;
          return GameResultsScreen(
            room: finishedRoom,
            finalScores: scores,
            currentUserId: userId,
            xpEarned: xp,
          );
        }

        return TranslationRaceScreen(
          room: room,
          currentUserId: userId,
          currentRound: round,
        );
      },
    );
  }
}

/// Wrapper that subscribes to bloc state and passes room/round to PictureGuessScreen
class _PictureGuessWrapper extends StatelessWidget {
  final String userId;
  final GameRoom initialRoom;

  const _PictureGuessWrapper({
    required this.userId,
    required this.initialRoom,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageGamesBloc, LanguageGamesState>(
      builder: (context, state) {
        final room = state is LanguageGamesInRoom ? state.room : initialRoom;
        final round = state is LanguageGamesInRoom ? state.currentRound : null;

        if (room.status == GameStatus.finished ||
            state is LanguageGamesFinished) {
          final finishedRoom =
              state is LanguageGamesFinished ? state.room : room;
          final scores = state is LanguageGamesFinished
              ? state.finalScores
              : room.scores;
          final xp =
              state is LanguageGamesFinished ? state.xpEarned : room.xpReward;
          return GameResultsScreen(
            room: finishedRoom,
            finalScores: scores,
            currentUserId: userId,
            xpEarned: xp,
          );
        }

        return PictureGuessScreen(
          room: room,
          currentUserId: userId,
          currentRound: round,
        );
      },
    );
  }
}

/// Wrapper that subscribes to bloc state and passes room/round to GrammarDuelScreen
class _GrammarDuelWrapper extends StatelessWidget {
  final String userId;
  final GameRoom initialRoom;

  const _GrammarDuelWrapper({
    required this.userId,
    required this.initialRoom,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageGamesBloc, LanguageGamesState>(
      builder: (context, state) {
        final room = state is LanguageGamesInRoom ? state.room : initialRoom;
        final round = state is LanguageGamesInRoom ? state.currentRound : null;

        if (room.status == GameStatus.finished ||
            state is LanguageGamesFinished) {
          final finishedRoom =
              state is LanguageGamesFinished ? state.room : room;
          final scores = state is LanguageGamesFinished
              ? state.finalScores
              : room.scores;
          final xp =
              state is LanguageGamesFinished ? state.xpEarned : room.xpReward;
          return GameResultsScreen(
            room: finishedRoom,
            finalScores: scores,
            currentUserId: userId,
            xpEarned: xp,
          );
        }

        return GrammarDuelScreen(
          room: room,
          currentUserId: userId,
          currentRound: round,
        );
      },
    );
  }
}

class _VocabularyChainWrapper extends StatelessWidget {
  final String userId;
  final GameRoom initialRoom;

  const _VocabularyChainWrapper({
    required this.userId,
    required this.initialRoom,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageGamesBloc, LanguageGamesState>(
      builder: (context, state) {
        final room = state is LanguageGamesInRoom ? state.room : initialRoom;
        final round = state is LanguageGamesInRoom ? state.currentRound : null;

        if (room.status == GameStatus.finished ||
            state is LanguageGamesFinished) {
          final finishedRoom =
              state is LanguageGamesFinished ? state.room : room;
          final scores = state is LanguageGamesFinished
              ? state.finalScores
              : room.scores;
          final xp =
              state is LanguageGamesFinished ? state.xpEarned : room.xpReward;
          return GameResultsScreen(
            room: finishedRoom,
            finalScores: scores,
            currentUserId: userId,
            xpEarned: xp,
          );
        }

        return VocabularyChainScreen(
          room: room,
          currentUserId: userId,
          currentRound: round,
        );
      },
    );
  }
}

class _LanguageSnapsWrapper extends StatelessWidget {
  final String userId;
  final GameRoom initialRoom;

  const _LanguageSnapsWrapper({
    required this.userId,
    required this.initialRoom,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageGamesBloc, LanguageGamesState>(
      builder: (context, state) {
        final room = state is LanguageGamesInRoom ? state.room : initialRoom;
        final round = state is LanguageGamesInRoom ? state.currentRound : null;

        if (room.status == GameStatus.finished ||
            state is LanguageGamesFinished) {
          final finishedRoom =
              state is LanguageGamesFinished ? state.room : room;
          final scores = state is LanguageGamesFinished
              ? state.finalScores
              : room.scores;
          final xp =
              state is LanguageGamesFinished ? state.xpEarned : room.xpReward;
          return GameResultsScreen(
            room: finishedRoom,
            finalScores: scores,
            currentUserId: userId,
            xpEarned: xp,
          );
        }

        return LanguageSnapsScreen(
          room: room,
          currentUserId: userId,
          currentRound: round,
        );
      },
    );
  }
}

class _LanguageTapplesWrapper extends StatelessWidget {
  final String userId;
  final GameRoom initialRoom;

  const _LanguageTapplesWrapper({
    required this.userId,
    required this.initialRoom,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageGamesBloc, LanguageGamesState>(
      builder: (context, state) {
        final room = state is LanguageGamesInRoom ? state.room : initialRoom;
        final round = state is LanguageGamesInRoom ? state.currentRound : null;

        if (room.status == GameStatus.finished ||
            state is LanguageGamesFinished) {
          final finishedRoom =
              state is LanguageGamesFinished ? state.room : room;
          final scores = state is LanguageGamesFinished
              ? state.finalScores
              : room.scores;
          final xp =
              state is LanguageGamesFinished ? state.xpEarned : room.xpReward;
          return GameResultsScreen(
            room: finishedRoom,
            finalScores: scores,
            currentUserId: userId,
            xpEarned: xp,
          );
        }

        return LanguageTapplesScreen(
          room: room,
          currentUserId: userId,
          currentRound: round,
        );
      },
    );
  }
}

class _CategoriesWrapper extends StatelessWidget {
  final String userId;
  final GameRoom initialRoom;

  const _CategoriesWrapper({
    required this.userId,
    required this.initialRoom,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageGamesBloc, LanguageGamesState>(
      builder: (context, state) {
        final room = state is LanguageGamesInRoom ? state.room : initialRoom;
        final round = state is LanguageGamesInRoom ? state.currentRound : null;

        if (room.status == GameStatus.finished ||
            state is LanguageGamesFinished) {
          final finishedRoom =
              state is LanguageGamesFinished ? state.room : room;
          final scores = state is LanguageGamesFinished
              ? state.finalScores
              : room.scores;
          final xp =
              state is LanguageGamesFinished ? state.xpEarned : room.xpReward;
          return GameResultsScreen(
            room: finishedRoom,
            finalScores: scores,
            currentUserId: userId,
            xpEarned: xp,
          );
        }

        return CategoriesScreen(
          room: room,
          currentUserId: userId,
          currentRound: round,
        );
      },
    );
  }
}
