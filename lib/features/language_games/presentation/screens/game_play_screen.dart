import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_sound_service.dart';
import '../../domain/entities/game_player.dart';
import '../../domain/entities/game_room.dart';
import '../../domain/entities/game_round.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../bloc/language_games_state.dart';
import '../widgets/answer_input.dart';
import '../widgets/game_scoreboard.dart';
import '../widgets/game_timer.dart';
import 'game_results_screen.dart';

/// Main in-game screen that adapts UI based on game type
/// Handles all 7 game modes with shared chrome (timer, scores, players)
class GamePlayScreen extends StatefulWidget {
  final String userId;
  final GameRoom room;

  const GamePlayScreen({
    super.key,
    required this.userId,
    required this.room,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _bombController;
  late Animation<double> _bombShakeAnimation;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackScaleAnimation;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Local state
  bool _showBoomAnimation = false;
  bool _showFeedback = false;
  String _feedbackText = '';
  Color _feedbackColor = AppColors.successGreen;
  bool _showScorePop = false;
  String _scorePopText = '';
  double _scorePopOpacity = 0.0;
  double _scorePopY = 0.0;

  // Snaps game state (memory card game)
  final List<int> _flippedCards = [];
  final Set<int> _matchedCards = {};
  bool _isProcessingSnaps = false;

  // Tapples available letters
  final List<String> _tapplesLetters = List.generate(
    26,
    (i) => String.fromCharCode(65 + i),
  );
  String? _selectedTapplesLetter;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _bombController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _bombShakeAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _bombController, curve: Curves.elasticIn),
    );

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bombController.dispose();
    _feedbackController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _submitAnswer(String answer) {
    HapticFeedback.mediumImpact();
    final room = _currentRoom;
    context.read<LanguageGamesBloc>().add(SubmitAnswer(
          roomId: room.id,
          userId: widget.userId,
          answer: answer,
        ));
  }

  /// Get the current room from BLoC state, falling back to the initial room
  GameRoom get _currentRoom {
    final state = context.read<LanguageGamesBloc>().state;
    if (state is LanguageGamesInRoom) return state.room;
    return widget.room;
  }

  void _showAnswerFeedback(bool isCorrect, String text) {
    setState(() {
      _showFeedback = true;
      _feedbackText = text;
      _feedbackColor =
          isCorrect ? AppColors.successGreen : AppColors.errorRed;
    });
    _feedbackController.forward(from: 0);

    // Show floating score pop for correct answers
    if (isCorrect) {
      final ptsMatch = RegExp(r'\+(\d+)').firstMatch(text);
      if (ptsMatch != null) {
        _showScorePopAnimation('+${ptsMatch.group(1)} pts');
      }
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showFeedback = false);
      }
    });
  }

  void _showScorePopAnimation(String text) {
    setState(() {
      _showScorePop = true;
      _scorePopText = text;
      _scorePopOpacity = 1.0;
      _scorePopY = 0.0;
    });

    // Animate upward and fade
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 16));
      if (!mounted || !_showScorePop) return false;
      setState(() {
        _scorePopY -= 1.5;
        _scorePopOpacity = (_scorePopOpacity - 0.015).clamp(0.0, 1.0);
      });
      if (_scorePopOpacity <= 0) {
        setState(() => _showScorePop = false);
        return false;
      }
      return true;
    });
  }

  void _triggerBoom() {
    setState(() => _showBoomAnimation = true);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showBoomAnimation = false);
      }
    });
  }

  void _navigateToResults(GameRoom room, Map<String, int> scores,
      String? winnerId, int xp, int coins) {
    AppSoundService().play(AppSound.gameEnd);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<LanguageGamesBloc>(),
          child: GameResultsScreen(
            userId: widget.userId,
            room: room,
            finalScores: scores,
            winnerId: winnerId,
            xpEarned: xp,
            coinsEarned: coins,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LanguageGamesBloc, LanguageGamesState>(
      listener: (context, state) {
        if (state is LanguageGamesInRoom) {
          final room = state.room;
          final round = state.currentRound;

          // Check for round results (answer feedback)
          if (round != null && round.hasPlayerAnswered(widget.userId)) {
            final answer = round.playerAnswers[widget.userId]!;
            final correctionText = answer.isCorrect
                ? 'Correct! +${answer.pointsEarned} pts'
                : 'Incorrect. The answer was "${round.correctAnswer ?? ""}"';
            _showAnswerFeedback(answer.isCorrect, correctionText);
          }

          // Bomb explosion on timeout
          if (room.gameType == GameType.wordBomb &&
              room.turnStartedAt != null) {
            final elapsed = DateTime.now()
                .difference(room.turnStartedAt!)
                .inSeconds;
            final remaining = room.turnDurationSeconds - elapsed;
            if (remaining <= 0) {
              _triggerBoom();
            } else if (remaining <= 5) {
              _bombController.repeat(reverse: true);
            } else {
              _bombController.stop();
            }
          }
        }

        if (state is LanguageGamesFinished) {
          _navigateToResults(
            state.room,
            state.finalScores,
            state.room.winnerId,
            state.xpEarned,
            0,
          );
        }
      },
      builder: (context, state) {
        final GameRoom room;
        final int timeRemaining;
        final bool hasAnswered;

        if (state is LanguageGamesInRoom) {
          room = state.room;
          // Calculate time remaining from turnStartedAt
          if (room.turnStartedAt != null) {
            final elapsed =
                DateTime.now().difference(room.turnStartedAt!).inSeconds;
            timeRemaining =
                (room.turnDurationSeconds - elapsed).clamp(0, room.turnDurationSeconds);
          } else {
            timeRemaining = room.turnDurationSeconds;
          }
          hasAnswered = state.currentRound?.hasPlayerAnswered(widget.userId) ?? false;
        } else {
          room = widget.room;
          timeRemaining = room.turnDurationSeconds;
          hasAnswered = false;
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: SafeArea(
            child: Stack(
              children: [
                // Animated particle background
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, _) => CustomPaint(
                      painter: _GamePlayParticlePainter(
                        progress: _particleController.value,
                        gameType: room.gameType,
                      ),
                    ),
                  ),
                ),

                // Main content
                Column(
                  children: [
                    // Top bar
                    _buildTopBar(room, timeRemaining),

                    // Player scoreboard
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: GameScoreboard(
                        players: room.players,
                        scores: room.scores,
                        lives: room.lives,
                        currentTurnUserId: room.currentTurnUserId,
                        currentUserId: widget.userId,
                      ),
                    ),

                    // Game area with overlays
                    Expanded(
                      child: Stack(
                        children: [
                          _buildGameArea(room, timeRemaining, hasAnswered),
                          if (_showFeedback) _buildFeedbackOverlay(),
                          if (_showBoomAnimation) _buildBoomOverlay(),
                          if (_showScorePop) _buildScorePopOverlay(),
                        ],
                      ),
                    ),

                    // Input area
                    if (!hasAnswered) _buildInputArea(room),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(GameRoom room, int timeRemaining) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          // Round counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.backgroundInput,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Round ${room.currentRound}/${room.totalRounds}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          // Timer
          GameTimer(
            remainingSeconds: timeRemaining,
            totalSeconds: room.turnDurationSeconds,
            size: 48,
          ),
          const Spacer(),
          // Game type badge with glow pulse
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.richGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.3 + 0.2 * _pulseAnimation.value),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.richGold.withValues(alpha: 0.1 * _pulseAnimation.value),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(room.gameType.emoji,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GAME AREA SWITCH
  // ============================================================

  Widget _buildGameArea(GameRoom room, int timeRemaining, bool hasAnswered) {
    switch (room.gameType) {
      case GameType.wordBomb:
        return _buildWordBombArea(room, timeRemaining);
      case GameType.translationRace:
        return _buildTranslationRaceArea(room, hasAnswered);
      case GameType.pictureGuess:
        return _buildPictureGuessArea(room);
      case GameType.grammarDuel:
        return _buildGrammarDuelArea(room, hasAnswered);
      case GameType.vocabularyChain:
        return _buildVocabularyChainArea(room);
      case GameType.languageSnaps:
        return _buildLanguageSnapsArea(room);
      case GameType.languageTapples:
        return _buildLanguageTapplesArea(room);
      case GameType.categories:
        return _buildCategoriesArea(room, hasAnswered);
    }
  }

  // ============================================================
  // WORD BOMB
  // ============================================================

  Widget _buildWordBombArea(GameRoom room, int timeRemaining) {
    final isMyTurn = room.isPlayerTurn(widget.userId);
    final prompt = room.currentPrompt ?? 'CA';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Letter prompt with pulsing glow
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.richGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.7 + 0.3 * _pulseAnimation.value),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.richGold.withValues(alpha: 0.1 + 0.15 * _pulseAnimation.value),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                prompt.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Type a word containing these letters!',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: 32),
          // Animated bomb
          _AnimatedShake(
            animation: _bombShakeAnimation,
            child: Column(
              children: [
                Text(
                  '\u{1F4A3}',
                  style: TextStyle(
                    fontSize: timeRemaining <= 5 ? 80 : 64,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: room.turnDurationSeconds > 0
                          ? timeRemaining / room.turnDurationSeconds
                          : 0,
                      minHeight: 4,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        timeRemaining <= 5
                            ? AppColors.errorRed
                            : AppColors.warningAmber,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!isMyTurn)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${room.currentTurnPlayer?.displayName ?? "Someone"} is thinking...',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // TRANSLATION RACE
  // ============================================================

  Widget _buildTranslationRaceArea(GameRoom room, bool hasAnswered) {
    final prompt = room.currentPrompt ?? 'word';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'TRANSLATE THIS WORD',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.7 + 0.3 * _pulseAnimation.value),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.richGold.withValues(alpha: 0.1 + 0.1 * _pulseAnimation.value),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                prompt,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Translate to ${_languageName(room.targetLanguage)}',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          if (hasAnswered)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.successGreen.withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      color: AppColors.successGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Answer submitted! Waiting for others...',
                    style: TextStyle(
                        color: AppColors.successGreen, fontSize: 14),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          _buildMiniLeaderboard(room),
        ],
      ),
    );
  }

  // ============================================================
  // PICTURE GUESS
  // ============================================================

  Widget _buildPictureGuessArea(GameRoom room) {
    final isDescriber = room.currentDescriberId == widget.userId;
    final prompt = room.currentPrompt ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          if (isDescriber) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.richGold.withValues(alpha: 0.15),
                  AppColors.richGold.withValues(alpha: 0.05),
                ]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.richGold, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    'DESCRIBE THIS WORD!',
                    style: TextStyle(
                      color: AppColors.richGold,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    prompt,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Do not say the word itself!',
                    style: TextStyle(
                      color: AppColors.warningAmber,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Use the chat to describe the word to other players',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ] else ...[
            const Icon(Icons.image_outlined,
                color: AppColors.richGold, size: 64),
            const SizedBox(height: 16),
            const Text(
              'GUESS THE WORD',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_getDescriberName(room)} is describing a word...',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Type your guess below!',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // GRAMMAR DUEL
  // ============================================================

  Widget _buildGrammarDuelArea(GameRoom room, bool hasAnswered) {
    final prompt = room.currentPrompt ?? 'Choose the correct form:';
    // In production, options come from GameRound.options
    final options = ['Option A', 'Option B', 'Option C', 'Option D'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'GRAMMAR QUESTION',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              prompt,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          // Multiple choice buttons
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: hasAnswered ? null : () => _submitAnswer(option),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundInput,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: const TextStyle(
                              color: AppColors.richGold,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          if (hasAnswered) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.infoBlue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_bottom,
                      color: AppColors.infoBlue, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Waiting for opponent...',
                    style:
                        TextStyle(color: AppColors.infoBlue, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // VOCABULARY CHAIN
  // ============================================================

  Widget _buildVocabularyChainArea(GameRoom room) {
    final theme = room.roundTheme ?? 'Animals';
    final prompt = room.currentPrompt ?? 'S';
    final isMyTurn = room.isPlayerTurn(widget.userId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Theme badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.richGold.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.category,
                    color: AppColors.richGold, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Theme: $theme',
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Chain visualization
          _buildChainVisualization(room.usedWords),
          const SizedBox(height: 24),
          // Letter prompt
          const Text(
            'NEXT WORD MUST START WITH',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.7 + 0.3 * _pulseAnimation.value),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.richGold.withValues(alpha: 0.15 * _pulseAnimation.value),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                prompt.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!isMyTurn)
            Text(
              '${room.currentTurnPlayer?.displayName ?? "Someone"}\'s turn',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChainVisualization(List<String> words) {
    if (words.isEmpty) {
      return const Text(
        'No words yet - start the chain!',
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final displayWords =
        words.length > 5 ? words.sublist(words.length - 5) : words;

    return Wrap(
      spacing: 4,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: displayWords.asMap().entries.map((entry) {
        final index = entry.key;
        final word = entry.value;
        final isLast = index == displayWords.length - 1;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLast
                    ? AppColors.richGold.withValues(alpha: 0.15)
                    : AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLast ? AppColors.richGold : AppColors.divider,
                ),
              ),
              child: Text(
                word,
                style: TextStyle(
                  color:
                      isLast ? AppColors.richGold : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(Icons.arrow_forward,
                    color: AppColors.textTertiary, size: 14),
              ),
          ],
        );
      }).toList(),
    );
  }

  // ============================================================
  // LANGUAGE SNAPS (Memory Card Game)
  // ============================================================

  Widget _buildLanguageSnapsArea(GameRoom room) {
    final isMyTurn = room.isPlayerTurn(widget.userId);
    const gridSize = 16; // 4x4 = 8 pairs

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Turn indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isMyTurn
                  ? AppColors.richGold.withValues(alpha: 0.15)
                  : AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isMyTurn ? AppColors.richGold : AppColors.divider,
              ),
            ),
            child: Text(
              isMyTurn
                  ? 'Your turn - flip two cards!'
                  : '${room.currentTurnPlayer?.displayName ?? "Someone"}\'s turn',
              style: TextStyle(
                color: isMyTurn ? AppColors.richGold : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Card grid
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: gridSize,
              itemBuilder: (context, index) {
                final isFlipped = _flippedCards.contains(index);
                final isMatched = _matchedCards.contains(index);

                return GestureDetector(
                  onTap: (isMyTurn &&
                          !isFlipped &&
                          !isMatched &&
                          !_isProcessingSnaps &&
                          _flippedCards.length < 2)
                      ? () => _onCardFlip(index)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isMatched
                          ? AppColors.successGreen.withValues(alpha: 0.2)
                          : (isFlipped
                              ? AppColors.richGold.withValues(alpha: 0.1)
                              : AppColors.backgroundCard),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isMatched
                            ? AppColors.successGreen
                            : (isFlipped
                                ? AppColors.richGold
                                : AppColors.divider),
                        width: isFlipped || isMatched ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isFlipped || isMatched
                        ? Text(
                            'Word ${index + 1}',
                            style: TextStyle(
                              color: isMatched
                                  ? AppColors.successGreen
                                  : AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : const Icon(
                            Icons.question_mark_rounded,
                            color: AppColors.textTertiary,
                            size: 24,
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onCardFlip(int index) {
    HapticFeedback.lightImpact();
    setState(() => _flippedCards.add(index));

    if (_flippedCards.length == 2) {
      _isProcessingSnaps = true;
      _submitAnswer('${_flippedCards[0]},${_flippedCards[1]}');

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _flippedCards.clear();
            _isProcessingSnaps = false;
          });
        }
      });
    }
  }

  // ============================================================
  // LANGUAGE TAPPLES
  // ============================================================

  Widget _buildLanguageTapplesArea(GameRoom room) {
    final isMyTurn = room.isPlayerTurn(widget.userId);
    final category = room.roundTheme ?? 'Food';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Category
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.richGold),
            ),
            child: Text(
              'Category: $category',
              style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!isMyTurn)
            Text(
              '${room.currentTurnPlayer?.displayName ?? "Someone"} is choosing...',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15),
            ),
          if (isMyTurn && _selectedTapplesLetter == null)
            const Text(
              'Pick a letter, then name a word!',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          if (isMyTurn && _selectedTapplesLetter != null)
            Text(
              'Name a ${_languageName(room.targetLanguage)} word starting with "$_selectedTapplesLetter"',
              style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 20),
          // Letter circle
          Expanded(child: Center(child: _buildLetterCircle(isMyTurn))),
        ],
      ),
    );
  }

  Widget _buildLetterCircle(bool isMyTurn) {
    final radius = MediaQuery.of(context).size.width * 0.32;
    final center = Offset(radius, radius);

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: Stack(
        children: _tapplesLetters.asMap().entries.map((entry) {
          final index = entry.key;
          final letter = entry.value;
          final angle =
              (2 * math.pi * index / _tapplesLetters.length) - math.pi / 2;
          final x = center.dx + (radius - 20) * math.cos(angle) - 16;
          final y = center.dy + (radius - 20) * math.sin(angle) - 16;
          final isSelected = letter == _selectedTapplesLetter;

          return Positioned(
            left: x,
            top: y,
            child: GestureDetector(
              onTap: isMyTurn
                  ? () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTapplesLetter = letter);
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.richGold
                      : AppColors.backgroundCard,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? AppColors.richGold : AppColors.divider,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                AppColors.richGold.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.backgroundDark
                        : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // CATEGORIES
  // ============================================================

  Widget _buildCategoriesArea(GameRoom room, bool hasAnswered) {
    final category = room.roundTheme ?? 'Animals';
    final prompt = room.currentPrompt ?? 'A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            'CATEGORIES',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Letter prompt with glow
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.7 + 0.3 * _pulseAnimation.value),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.richGold.withValues(alpha: 0.15 * _pulseAnimation.value),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                prompt.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Category display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.richGold),
            ),
            child: Text(
              'Category: $category',
              style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Name a word in "$category" starting with "$prompt"',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (hasAnswered)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.successGreen.withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      color: AppColors.successGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Answer submitted! Waiting for others...',
                    style: TextStyle(
                        color: AppColors.successGreen, fontSize: 14),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          _buildMiniLeaderboard(room),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT AREA
  // ============================================================

  Widget _buildInputArea(GameRoom room) {
    final isMyTurn = room.isPlayerTurn(widget.userId);

    // Grammar duel uses buttons
    if (room.gameType == GameType.grammarDuel) return const SizedBox.shrink();

    // Snaps uses card taps
    if (room.gameType == GameType.languageSnaps) return const SizedBox.shrink();

    // Tapples needs letter selected first
    if (room.gameType == GameType.languageTapples) {
      if (_selectedTapplesLetter == null || !isMyTurn) {
        return const SizedBox.shrink();
      }
    }

    final isTurnBased = room.gameType == GameType.wordBomb ||
        room.gameType == GameType.vocabularyChain ||
        room.gameType == GameType.languageTapples;

    final String hint;
    switch (room.gameType) {
      case GameType.wordBomb:
        hint = 'Type a word containing "${room.currentPrompt ?? ""}"...';
      case GameType.translationRace:
        hint = 'Type the translation...';
      case GameType.pictureGuess:
        hint = room.currentDescriberId == widget.userId
            ? 'Describe the word (don\'t say it!)...'
            : 'Type your guess...';
      case GameType.vocabularyChain:
        hint = 'Word starting with "${room.currentPrompt ?? ""}"...';
      case GameType.languageTapples:
        hint = 'Word starting with "$_selectedTapplesLetter"...';
      case GameType.categories:
        hint = 'Type a word starting with "${room.currentPrompt ?? ""}"...';
      default:
        hint = 'Type your answer...';
    }

    return AnswerInput(
      hintText: hint,
      enabled: isTurnBased ? isMyTurn : true,
      onSubmitted: (answer) {
        if (room.gameType == GameType.languageTapples) {
          _submitAnswer('$_selectedTapplesLetter:$answer');
          setState(() => _selectedTapplesLetter = null);
        } else {
          _submitAnswer(answer);
        }
      },
    );
  }

  // ============================================================
  // OVERLAYS
  // ============================================================

  Widget _buildFeedbackOverlay() {
    final isCorrect = _feedbackColor == AppColors.successGreen;
    return Center(
      child: ScaleTransition(
        scale: _feedbackScaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glow ring behind the feedback
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _feedbackColor.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: _feedbackColor,
                size: 56,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: _feedbackColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _feedbackColor.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 6,
                  ),
                  BoxShadow(
                    color: _feedbackColor.withValues(alpha: 0.2),
                    blurRadius: 60,
                    spreadRadius: 12,
                  ),
                ],
              ),
              child: Text(
                _feedbackText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorePopOverlay() {
    return Positioned(
      top: 80 + _scorePopY,
      left: 0,
      right: 0,
      child: Center(
        child: Opacity(
          opacity: _scorePopOpacity,
          child: Text(
            _scorePopText,
            style: TextStyle(
              color: AppColors.richGold,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: AppColors.richGold.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoomOverlay() {
    return Container(
      color: AppColors.backgroundDark.withValues(alpha: 0.85),
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Expanding shockwave ring
              Container(
                width: 200 * value,
                height: 200 * value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.errorRed.withValues(alpha: (1.0 - value) * 0.6),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warningAmber.withValues(alpha: (1.0 - value) * 0.3),
                      blurRadius: 40 * value,
                      spreadRadius: 10 * value,
                    ),
                  ],
                ),
              ),
              // Second expanding ring
              Container(
                width: 140 * value,
                height: 140 * value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.warningAmber.withValues(alpha: (1.0 - value) * 0.4),
                    width: 2,
                  ),
                ),
              ),
              // Core explosion content
              Transform.scale(
                scale: value,
                child: child,
              ),
            ],
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Explosion emoji with glow
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.errorRed.withValues(alpha: 0.4),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: AppColors.warningAmber.withValues(alpha: 0.3),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: const Text('\u{1F4A5}', style: TextStyle(fontSize: 100)),
            ),
            const SizedBox(height: 16),
            Text(
              'BOOM!',
              style: TextStyle(
                color: AppColors.errorRed,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: AppColors.errorRed.withValues(alpha: 0.6),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Time ran out! You lost a life.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _buildMiniLeaderboard(GameRoom room) {
    final sorted = room.sortedScores;
    if (sorted.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'LEADERBOARD',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          ...sorted.take(4).map((entry) {
            final player = room.getPlayer(entry.key);
            final isMe = entry.key == widget.userId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isMe ? 'You' : (player?.displayName ?? 'Player'),
                      style: TextStyle(
                        color: isMe
                            ? AppColors.richGold
                            : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value} pts',
                    style: TextStyle(
                      color: isMe ? AppColors.richGold : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getDescriberName(GameRoom room) {
    if (room.currentDescriberId == null) return 'Someone';
    final describer = room.getPlayer(room.currentDescriberId!);
    return describer?.displayName ?? 'Someone';
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
}

/// Shake animation wrapper for the bomb
class _AnimatedShake extends AnimatedWidget {
  final Widget child;

  const _AnimatedShake({
    required Animation<double> animation,
    required this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Transform.translate(
      offset: Offset(animation.value, 0),
      child: child,
    );
  }
}

/// Floating ambient particles for the game play background
class _GamePlayParticlePainter extends CustomPainter {
  final double progress;
  final GameType gameType;

  _GamePlayParticlePainter({required this.progress, required this.gameType});

  @override
  void paint(Canvas canvas, Size size) {
    final seed = gameType.index * 13 + 7;
    const count = 25;

    for (int i = 0; i < count; i++) {
      final hash = (seed * 31 + i * 47) & 0xFFFF;
      final baseX = (hash % 1000) / 1000.0 * size.width;
      final baseY = ((hash * 7 + 123) % 1000) / 1000.0 * size.height;
      final speed = 0.3 + (hash % 100) / 100.0 * 0.7;
      final phase = (hash % 628) / 100.0;
      final radius = 1.0 + (hash % 200) / 100.0;

      final dx = math.sin(progress * math.pi * 2 * speed + phase) * 12;
      final dy = math.cos(progress * math.pi * 2 * speed * 0.6 + phase) * 8;
      final opacity = (0.04 + 0.04 * math.sin(progress * math.pi * 2 * speed + phase)).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(baseX + dx, baseY + dy),
        radius,
        Paint()..color = AppColors.richGold.withValues(alpha: opacity),
      );

      // Some particles get a small glow halo
      if (i % 4 == 0) {
        canvas.drawCircle(
          Offset(baseX + dx, baseY + dy),
          radius * 3,
          Paint()..color = AppColors.richGold.withValues(alpha: opacity * 0.3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GamePlayParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
