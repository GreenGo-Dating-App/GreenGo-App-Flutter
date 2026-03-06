import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'game_play_screen.dart';

/// Matchmaking/waiting room screen
/// Shows player slots, ready status, and game config before starting
class GameWaitingScreen extends StatefulWidget {
  final String userId;
  final String displayName;
  final GameRoom room;

  const GameWaitingScreen({
    super.key,
    required this.userId,
    this.displayName = 'Player',
    required this.room,
  });

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite code copied!'),
        backgroundColor: AppColors.successGreen,
        duration: Duration(seconds: 2),
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
            onComplete: () => GamePlayScreen(
              userId: widget.userId,
              room: room,
            ),
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
    return Column(
      children: [
        Text(room.gameType.emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        FadeTransition(
          opacity: _pulseAnimation,
          child: const Text(
            'Waiting for Players...',
            style: TextStyle(
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _InfoBadge(
          icon: Icons.language,
          label: _languageDisplayName(room.targetLanguage),
        ),
        const SizedBox(width: 12),
        _InfoBadge(icon: Icons.speed, label: 'Level ${room.difficulty}'),
        const SizedBox(width: 12),
        _InfoBadge(
            icon: Icons.replay, label: '${room.totalRounds} rounds'),
      ],
    );
  }

  Widget _buildPlayerSlots(GameRoom room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLAYERS',
          style: TextStyle(
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
                      isMe ? 'You' : player.displayName,
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
                        child: const Text(
                          'HOST',
                          style: TextStyle(
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
                  const Text(
                    'Disconnected',
                    style: TextStyle(color: AppColors.errorRed, fontSize: 11),
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
                  player.isReady ? 'Ready' : 'Not Ready',
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
            const Text(
              'Waiting...',
              style: TextStyle(
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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          // Get host nickname from ProfileBloc
          String hostNickname = 'Host';
          String? hostPhotoUrl;
          try {
            final profileState = context.read<ProfileBloc>().state;
            if (profileState is ProfileLoaded) {
              hostNickname = profileState.profile.nickname ?? 'Host';
              hostPhotoUrl = profileState.profile.photoUrls.isNotEmpty
                  ? profileState.profile.photoUrls.first
                  : null;
            } else if (profileState is ProfileUpdated) {
              hostNickname = profileState.profile.nickname ?? 'Host';
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
        label: const Text('Invite Player'),
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
          const Text(
            'INVITE CODE',
            style: TextStyle(
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
          const Text(
            'Share this code with friends to join',
            style:
                TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCount(GameRoom room) {
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
            '${room.players.length} players in room'
            '${notReadyCount > 0 ? ' ($notReadyCount not ready)' : ''}',
            style: const TextStyle(
                color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(GameRoom room, bool isHost, bool isReady) {
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 24),
                      SizedBox(width: 8),
                      Text('Start Game',
                          style: TextStyle(
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
                    isReady ? 'Cancel Ready' : 'Ready Up',
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
                child: const Text(
                  'Leave Room',
                  style: TextStyle(
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

  String _languageDisplayName(String code) {
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

/// Splash screen showing the game icon while the game loads.
/// Displays for 2 seconds, then transitions to the actual game screen.
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

    _iconController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_navigated) {
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
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_iconController, _pulseController]),
              builder: (context, _) {
                return Opacity(
                  opacity: _iconOpacity.value,
                  child: Transform.scale(
                    scale: _iconScale.value * _pulseAnimation.value,
                    child: Container(
                      width: 160,
                      height: 160,
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
                        width: 140,
                        height: 140,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              widget.gameType.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
