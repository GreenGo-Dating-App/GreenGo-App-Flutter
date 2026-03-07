import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:greengo_chat/generated/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/content/game_content.dart';
import '../../domain/entities/game_room.dart';
import '../../domain/entities/game_round.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../bloc/language_games_state.dart';
import '../widgets/game_timer.dart';
import '../widgets/player_avatar_circle.dart';
import '../widgets/snap_card_widget.dart';

/// Represents one card in the 4x4 grid.
class _CardData {
  final int pairId;
  final String text;
  final bool isEnglish;

  const _CardData({
    required this.pairId,
    required this.text,
    required this.isEnglish,
  });
}

/// Language Snaps — memory card matching game.
/// Players take turns flipping 2 cards to find English↔Translation pairs.
/// Match = keep revealed + 5 pts + bonus turn. Mismatch = flip back + next turn.
class LanguageSnapsScreen extends StatefulWidget {
  final GameRoom room;
  final String currentUserId;
  final GameRound? currentRound;

  const LanguageSnapsScreen({
    super.key,
    required this.room,
    required this.currentUserId,
    this.currentRound,
  });

  @override
  State<LanguageSnapsScreen> createState() => _LanguageSnapsScreenState();
}

class _LanguageSnapsScreenState extends State<LanguageSnapsScreen>
    with TickerProviderStateMixin {
  // ── Card state ──
  List<_CardData> _cards = [];
  final Set<int> _matchedIndices = {};
  final List<int> _flippedIndices = [];
  bool _isProcessing = false;
  int _currentRoundSeed = 0;

  // ── Timer ──
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _hasTimedOut = false;

  // ── Turn transition ──
  bool _showTurnTransition = false;
  String _turnTransitionText = '';
  String? _previousTurnUserId;
  late AnimationController _turnTransitionController;
  late Animation<double> _turnTransitionScale;

  // ── Feedback ──
  bool _showMatchFeedback = false;
  bool _matchFeedbackCorrect = false;
  String _matchFeedbackText = '';
  late AnimationController _feedbackController;
  late Animation<double> _feedbackScale;

  // ── Score pop ──
  bool _showScorePop = false;
  String _scorePopText = '';
  Map<String, int> _previousScores = {};

  // ── Mismatch tracking ──
  final Set<int> _mismatchIndices = {};

  // ── Particle background ──
  late AnimationController _particleController;

  bool get _isMyTurn => widget.room.currentTurnUserId == widget.currentUserId;
  bool get _isHost => widget.room.isHost(widget.currentUserId);
  int get _totalPairs => _cards.isEmpty ? 8 : _cards.length ~/ 2;
  int get _matchedPairs => _matchedIndices.length ~/ 2;

  @override
  void initState() {
    super.initState();

    // Particle background
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Turn transition
    _turnTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _turnTransitionScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _turnTransitionController, curve: Curves.elasticOut),
    );

    // Feedback
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut),
    );

    _previousScores = Map.from(widget.room.scores);
    _previousTurnUserId = widget.room.currentTurnUserId;

    _generateCards();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant LanguageSnapsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect turn change
    if (widget.room.currentTurnUserId != oldWidget.room.currentTurnUserId) {
      _hasTimedOut = false;
      _startTimer();

      if (_previousTurnUserId != null &&
          _previousTurnUserId != widget.room.currentTurnUserId) {
        _showTurnTransitionOverlay();
      }
      _previousTurnUserId = widget.room.currentTurnUserId;
    }

    // Detect round change — regenerate cards
    if (widget.room.currentRound != _currentRoundSeed) {
      _generateCards();
    }

    // Detect score change
    final newScores = widget.room.scores;
    final myOldScore = _previousScores[widget.currentUserId] ?? 0;
    final myNewScore = newScores[widget.currentUserId] ?? 0;
    if (myNewScore > myOldScore) {
      _showScorePopOverlay('+${myNewScore - myOldScore}');
    }
    _previousScores = Map.from(newScores);
  }

  /// Generate 8 pairs (16 cards) from SnapCard content, shuffled.
  void _generateCards() {
    _currentRoundSeed = widget.room.currentRound;

    final snapCards = GameContent.getSnapCards(
      widget.room.targetLanguage,
      widget.room.difficulty,
    );

    // Take 8 pairs
    final pairs = snapCards.take(8).toList();

    // If we don't have enough snap card data, pad with placeholders
    while (pairs.length < 8) {
      pairs.add(SnapCard(
        english: 'Word ${pairs.length + 1}',
        translation: 'Palabra ${pairs.length + 1}',
        difficulty: 1,
      ));
    }

    // Create 16 cards: 8 English + 8 Translation, each linked by pairId
    final cards = <_CardData>[];
    for (int i = 0; i < pairs.length; i++) {
      cards.add(_CardData(
        pairId: i,
        text: pairs[i].english,
        isEnglish: true,
      ));
      cards.add(_CardData(
        pairId: i,
        text: pairs[i].translation,
        isEnglish: false,
      ));
    }

    // Shuffle with round-based seed for consistency across clients
    cards.shuffle(math.Random(widget.room.id.hashCode + _currentRoundSeed));

    setState(() {
      _cards = cards;
      _matchedIndices.clear();
      _flippedIndices.clear();
      _mismatchIndices.clear();
      _isProcessing = false;
    });
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _remainingSeconds = widget.room.turnDurationSeconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final startedAt = widget.room.turnStartedAt;
      if (startedAt == null) {
        setState(() => _remainingSeconds = widget.room.turnDurationSeconds);
        return;
      }

      final elapsed = DateTime.now().difference(startedAt).inSeconds;
      final remaining =
          (widget.room.turnDurationSeconds - elapsed).clamp(0, 999);

      setState(() => _remainingSeconds = remaining);

      if (remaining <= 0 && !_hasTimedOut) {
        _hasTimedOut = true;
        _countdownTimer?.cancel();
        HapticFeedback.heavyImpact();

        if (_isHost) {
          context.read<LanguageGamesBloc>().add(
                SnapTimeout(roomId: widget.room.id),
              );
        }
      }
    });
  }

  void _onCardTap(int index) {
    if (!_isMyTurn || _isProcessing) return;
    if (_matchedIndices.contains(index)) return;
    if (_flippedIndices.contains(index)) return;
    if (_flippedIndices.length >= 2) return;

    HapticFeedback.lightImpact();
    setState(() => _flippedIndices.add(index));

    if (_flippedIndices.length == 2) {
      _isProcessing = true;
      final idx1 = _flippedIndices[0];
      final idx2 = _flippedIndices[1];
      final card1 = _cards[idx1];
      final card2 = _cards[idx2];

      // Check if same pair and different type (english vs translation)
      final isMatch =
          card1.pairId == card2.pairId && card1.isEnglish != card2.isEnglish;

      if (isMatch) {
        // Match found!
        HapticFeedback.mediumImpact();
        _showMatchFeedbackOverlay(true, '+5');

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _matchedIndices.add(idx1);
            _matchedIndices.add(idx2);
            _flippedIndices.clear();
            _isProcessing = false;
          });

          // Submit answer to server for scoring
          context.read<LanguageGamesBloc>().add(SubmitAnswer(
                roomId: widget.room.id,
                userId: widget.currentUserId,
                answer: 'match:$idx1,$idx2',
              ));

          // Check if all pairs matched → advance round
          if (_matchedIndices.length == _cards.length && _isHost) {
            Future.delayed(const Duration(seconds: 2), () {
              if (!mounted) return;
              context.read<LanguageGamesBloc>().add(
                    AdvanceRound(roomId: widget.room.id),
                  );
            });
          }
        });
      } else {
        // Mismatch — show shake, then flip back + advance turn
        HapticFeedback.heavyImpact();
        _showMatchFeedbackOverlay(false, AppLocalizations.of(context)!.gameSnapsNoMatch);

        setState(() {
          _mismatchIndices.add(idx1);
          _mismatchIndices.add(idx2);
        });

        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          setState(() {
            _flippedIndices.clear();
            _mismatchIndices.clear();
            _isProcessing = false;
          });

          // Advance turn on mismatch (host only)
          if (_isHost) {
            context.read<LanguageGamesBloc>().add(
                  AdvanceTurn(roomId: widget.room.id),
                );
          }
        });
      }
    }
  }

  void _showTurnTransitionOverlay() {
    final l10n = AppLocalizations.of(context)!;
    if (_isMyTurn) {
      _turnTransitionText = l10n.gameYourTurn;
      HapticFeedback.mediumImpact();
    } else {
      final player = widget.room.currentTurnPlayer;
      final name = player?.displayName ?? l10n.gameOpponent;
      _turnTransitionText = l10n.gamePlayersTurn(name);
    }
    setState(() => _showTurnTransition = true);
    _turnTransitionController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _showTurnTransition = false);
    });
  }

  void _showMatchFeedbackOverlay(bool correct, String text) {
    setState(() {
      _showMatchFeedback = true;
      _matchFeedbackCorrect = correct;
      _matchFeedbackText = text;
    });
    _feedbackController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _showMatchFeedback = false);
    });
  }

  void _showScorePopOverlay(String text) {
    setState(() {
      _showScorePop = true;
      _scorePopText = text;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _showScorePop = false);
    });
  }

  void _showAbandonDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.gameAbandonTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
            l10n.gameAbandonProgressMessage,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<LanguageGamesBloc>().add(LeaveRoom(
                    roomId: widget.room.id,
                    userId: widget.currentUserId,
                  ));
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(l10n.gameAbandon,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _particleController.dispose();
    _turnTransitionController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LanguageGamesBloc, LanguageGamesState>(
      listener: (context, state) {
        if (state is LanguageGamesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          '${widget.room.gameType.emoji} ${l10n.gameSnapsTitle}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                l10n.gameRoundNumber(widget.room.currentRound),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: AppColors.errorRed),
            tooltip: l10n.gameAbandonTooltip,
            onPressed: _showAbandonDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Particle background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                painter: _SnapsParticlePainter(
                  progress: _particleController.value,
                ),
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              // Player avatars with scores
              _buildPlayerAvatars(),
              const SizedBox(height: 6),

              // Turn indicator + timer row
              _buildTurnAndTimer(),
              const SizedBox(height: 8),

              // Pairs progress
              _buildPairsProgress(),
              const SizedBox(height: 8),

              // 4x4 Card Grid
              Expanded(child: _buildCardGrid()),

              const SizedBox(height: 8),
            ],
          ),

          // Turn transition overlay
          if (_showTurnTransition) _buildTurnTransitionOverlay(),

          // Match feedback overlay
          if (_showMatchFeedback) _buildMatchFeedback(),

          // Score pop
          if (_showScorePop) _buildScorePopOverlay(),
        ],
      ),
    );
  }

  Widget _buildPlayerAvatars() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widget.room.players.map((player) {
          return PlayerAvatarCircle(
            player: player,
            isCurrentTurn:
                widget.room.currentTurnUserId == player.userId,
            isCurrentUser: player.userId == widget.currentUserId,
            showScore: true,
            size: 40,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTurnAndTimer() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Turn indicator
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _isMyTurn
                  ? AppColors.richGold.withValues(alpha: 0.15)
                  : AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isMyTurn
                  ? [
                      BoxShadow(
                        color: AppColors.richGold.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              _isMyTurn
                  ? l10n.gameSnapsYourTurnFlipCards
                  : l10n.gamePlayersTurn(widget.room.currentTurnPlayer?.displayName ?? l10n.gameWaiting),
              style: TextStyle(
                color: _isMyTurn
                    ? AppColors.richGold
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Timer
          GameTimer(
            remainingSeconds: _remainingSeconds,
            totalSeconds: widget.room.turnDurationSeconds,
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildPairsProgress() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style, color: AppColors.textTertiary, size: 14),
          const SizedBox(width: 4),
          Text(
            l10n.gameSnapsPairsFound(_matchedPairs, _totalPairs),
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          // Progress dots
          ...List.generate(_totalPairs, (i) {
            return Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _matchedPairs
                      ? AppColors.successGreen
                      : AppColors.divider,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCardGrid() {
    if (_cards.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final card = _cards[index];
          final isFlipped = _flippedIndices.contains(index);
          final isMatched = _matchedIndices.contains(index);
          final isMismatch = _mismatchIndices.contains(index);

          return SnapCardWidget(
            word: card.text,
            isFaceUp: isFlipped || isMatched,
            isMatched: isMatched,
            isMismatch: isMismatch,
            accentColor: card.isEnglish
                ? AppColors.richGold
                : AppColors.infoBlue,
            onTap: (_isMyTurn && !_isProcessing && !isMatched && !isFlipped)
                ? () => _onCardTap(index)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildTurnTransitionOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: ScaleTransition(
            scale: _turnTransitionScale,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isMyTurn
                      ? AppColors.richGold
                      : AppColors.divider,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isMyTurn
                            ? AppColors.richGold
                            : Colors.black)
                        .withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isMyTurn
                        ? Icons.touch_app_rounded
                        : Icons.hourglass_top_rounded,
                    color: _isMyTurn
                        ? AppColors.richGold
                        : AppColors.textTertiary,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _turnTransitionText,
                    style: TextStyle(
                      color: _isMyTurn
                          ? AppColors.richGold
                          : AppColors.textPrimary,
                      fontSize: _isMyTurn ? 24 : 18,
                      fontWeight: FontWeight.bold,
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

  Widget _buildMatchFeedback() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: ScaleTransition(
            scale: _feedbackScale,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: (_matchFeedbackCorrect
                        ? AppColors.successGreen
                        : AppColors.errorRed)
                    .withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_matchFeedbackCorrect
                            ? AppColors.successGreen
                            : AppColors.errorRed)
                        .withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _matchFeedbackCorrect
                        ? Icons.check
                        : Icons.close,
                    color: Colors.white,
                    size: 36,
                  ),
                  Text(
                    _matchFeedbackText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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

  Widget _buildScorePopOverlay() {
    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          builder: (context, value, child) {
            return Opacity(
              opacity: (1 - value).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -30 * value),
                child: child,
              ),
            );
          },
          child: Center(
            child: Text(
              _scorePopText,
              style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card-themed floating particles
class _SnapsParticlePainter extends CustomPainter {
  final double progress;

  _SnapsParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const count = 15;
    const seed = 42;

    for (int i = 0; i < count; i++) {
      final hash = (seed * 31 + i * 53) & 0xFFFF;
      final baseX = (hash % 1000) / 1000.0 * size.width;
      final baseY = ((hash * 7 + 123) % 1000) / 1000.0 * size.height;
      final speed = 0.15 + (hash % 100) / 100.0 * 0.4;
      final phase = (hash % 628) / 100.0;

      final dx = math.sin(progress * math.pi * 2 * speed + phase) * 12;
      final dy =
          math.cos(progress * math.pi * 2 * speed * 0.7 + phase) * 10;
      final opacity =
          (0.03 + 0.04 * math.sin(progress * math.pi * 2 * speed + phase))
              .clamp(0.0, 1.0);

      final pos = Offset(baseX + dx, baseY + dy);
      final cardSize = 6.0 + (hash % 4);

      // Draw mini card shapes
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos, width: cardSize, height: cardSize * 1.4),
        const Radius.circular(1),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = AppColors.richGold.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SnapsParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
