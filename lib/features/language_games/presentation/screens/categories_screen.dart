import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/content/categories_data.dart';
import '../../domain/entities/game_room.dart';
import '../../domain/entities/game_round.dart';
import '../bloc/language_games_bloc.dart';
import '../bloc/language_games_event.dart';
import '../widgets/category_grid_cell.dart';

/// Categories game screen — race to fill 9 category cells with words
/// starting with the current letter. Features client-side countdown timer,
/// real category data with icons, answer feedback, opponent progress,
/// and round transition animations.
class CategoriesScreen extends StatefulWidget {
  final GameRoom room;
  final String currentUserId;
  final GameRound? currentRound;

  const CategoriesScreen({
    super.key,
    required this.room,
    required this.currentUserId,
    this.currentRound,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with TickerProviderStateMixin {
  // Timer
  Timer? _countdownTimer;
  int _remainingSeconds = 120;
  bool _timedOut = false;

  // Game state
  final Map<int, String> _filledWords = {};
  int? _activeCellIndex;
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  // Animations
  late AnimationController _letterAnimController;
  late AnimationController _roundTransitionController;
  bool _showRoundTransition = false;
  String _transitionLetter = '';

  // Feedback
  int? _lastFilledIndex;
  bool _showScorePop = false;
  String _scoreFeedback = '';

  // Track round to detect changes
  int _lastRound = -1;
  String _lastPrompt = '';

  static List<String> _localizedDefaultCategories(AppLocalizations l10n) => [
    l10n.gameCategoryAnimals,
    l10n.gameCategoryFood,
    l10n.gameCategoryCountries,
    l10n.gameCategorySports,
    l10n.gameCategoryColors,
    l10n.gameCategoryClothing,
    l10n.gameCategoryProfessions,
    l10n.gameCategoryNature,
    l10n.gameCategoryTransport,
  ];

  // Map category names to icons from CategoriesData
  static final Map<String, String> _categoryIcons = {
    for (final cat in CategoriesData.allCategories) cat.name: cat.icon,
  };

  String get _currentLetter =>
      widget.room.currentPrompt ?? widget.currentRound?.prompt ?? 'A';

  List<String> _categories(AppLocalizations l10n) {
    final roomCategories = widget.room.roundCategories;
    if (roomCategories != null && roomCategories.length >= 9) {
      return roomCategories.take(9).toList();
    }
    return _localizedDefaultCategories(l10n);
  }

  int get _filledCount => _filledWords.length;
  bool get _isHost => widget.room.isHost(widget.currentUserId);
  int get _totalDuration => widget.room.turnDurationSeconds > 0
      ? widget.room.turnDurationSeconds
      : 120;

  @override
  void initState() {
    super.initState();
    _letterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _roundTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _lastRound = widget.room.currentRound;
    _lastPrompt = _currentLetter;
    _startTimer();
  }

  @override
  void didUpdateWidget(CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newRound = widget.room.currentRound;
    final newPrompt = widget.room.currentPrompt ?? '';

    // Detect round change
    if (newRound != _lastRound || newPrompt != _lastPrompt) {
      _lastRound = newRound;
      _lastPrompt = newPrompt;
      _onNewRound(newPrompt);
    }
  }

  void _onNewRound(String newLetter) {
    _filledWords.clear();
    _activeCellIndex = null;
    _timedOut = false;
    _lastFilledIndex = null;
    _showScorePop = false;

    // Show round transition
    _transitionLetter = newLetter;
    _showRoundTransition = true;
    _roundTransitionController.reset();
    _roundTransitionController.forward();

    // Play letter entrance
    _letterAnimController.reset();
    _letterAnimController.forward();

    // Hide transition after animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showRoundTransition = false);
      }
    });

    _restartTimer();
    setState(() {});
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _computeRemainingSeconds();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _computeRemainingSeconds();
      if (_remainingSeconds <= 0 && !_timedOut) {
        _timedOut = true;
        _countdownTimer?.cancel();
        HapticFeedback.heavyImpact();
        // Host advances round on timeout
        if (_isHost) {
          context.read<LanguageGamesBloc>().add(
                AdvanceRound(roomId: widget.room.id),
              );
        }
      }
      setState(() {});
    });
  }

  void _restartTimer() {
    _timedOut = false;
    _startTimer();
  }

  void _computeRemainingSeconds() {
    final startedAt = widget.room.turnStartedAt;
    if (startedAt == null) {
      _remainingSeconds = _totalDuration;
      return;
    }
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    _remainingSeconds = (_totalDuration - elapsed).clamp(0, _totalDuration);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _letterAnimController.dispose();
    _roundTransitionController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getIconForCategory(String categoryName) {
    return _categoryIcons[categoryName] ?? '📝';
  }

  int _getOpponentFilledCount() {
    final round = widget.currentRound;
    if (round == null) return 0;
    // Count opponent answers from playerAnswers
    int count = 0;
    for (final entry in round.playerAnswers.entries) {
      if (entry.key != widget.currentUserId && entry.value.isCorrect) {
        count++;
      }
    }
    return count;
  }

  void _onCellTapped(int index) {
    if (_filledWords.containsKey(index) || _timedOut) return;
    setState(() => _activeCellIndex = index);
    _textController.clear();
    HapticFeedback.selectionClick();
    _showWordInput(index);
  }

  void _showWordInput(int index) {
    final l10n = AppLocalizations.of(context)!;
    final category = _categories(l10n)[index];
    final icon = _getIconForCategory(category);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.gameCategoriesStartsWith(category, _currentLetter),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.gameCategoriesEnterWordHint(_currentLetter),
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: AppColors.richGold),
                  onPressed: () => _submitWord(ctx, index),
                ),
              ),
              onSubmitted: (_) => _submitWord(ctx, index),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          if (!_filledWords.containsKey(index)) {
            _activeCellIndex = null;
          }
        });
      }
    });
  }

  void _submitWord(BuildContext ctx, int index) {
    final l10n = AppLocalizations.of(context)!;
    final word = _textController.text.trim();
    if (word.isEmpty) return;

    if (!word.toUpperCase().startsWith(_currentLetter.toUpperCase())) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.gameWordMustStartWith(_currentLetter)),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    // Check if word already used in another cell
    if (_filledWords.values
        .any((w) => w.toLowerCase() == word.toLowerCase())) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.gameCategoriesWordAlreadyUsedInCategory),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _filledWords[index] = word;
      _activeCellIndex = null;
      _lastFilledIndex = index;

      // Show score pop
      _showScorePop = true;
      _scoreFeedback = '+10';
    });

    Navigator.pop(ctx);

    // Submit to server: format "cellIndex:word"
    context.read<LanguageGamesBloc>().add(SubmitAnswer(
          roomId: widget.room.id,
          userId: widget.currentUserId,
          answer: '$index:$word',
        ));

    // Hide score pop after delay
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showScorePop = false);
    });

    // Check if all 9 filled → advance round
    if (_filledWords.length >= 9 && _isHost) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          context.read<LanguageGamesBloc>().add(
                AdvanceRound(roomId: widget.room.id),
              );
        }
      });
    }
  }

  void _showAbandonDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.gameAbandonTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.gameAbandonLoseMessage,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LanguageGamesBloc>().add(
                    LeaveRoom(
                        roomId: widget.room.id,
                        userId: widget.currentUserId),
                  );
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(l10n.gameLeave,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          '${widget.room.gameType.emoji} ${l10n.gameCategoriesTitle}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          // Round indicator
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                l10n.gameRoundCounter(widget.room.currentRound, widget.room.totalRounds),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app,
                color: AppColors.errorRed, size: 20),
            tooltip: l10n.gameAbandonTooltip,
            onPressed: _showAbandonDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Letter + Timer row
                _buildLetterAndTimer(),
                const SizedBox(height: 16),

                // Player progress
                _buildPlayerProgress(),
                const SizedBox(height: 16),

                // 3x3 category grid
                Expanded(child: _buildCategoryGrid()),

                // Bottom hint
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  child: Text(
                    _timedOut
                        ? l10n.gameCategoriesTimesUp
                        : l10n.gameCategoriesTapToFill,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Score pop overlay
          if (_showScorePop) _buildScorePop(),

          // Round transition overlay
          if (_showRoundTransition) _buildRoundTransition(),
        ],
      ),
    );
  }

  Widget _buildLetterAndTimer() {
    final l10n = AppLocalizations.of(context)!;
    final progress = _remainingSeconds / _totalDuration;
    final isLow = _remainingSeconds <= 15;

    return Row(
      children: [
        // Animated letter circle
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _letterAnimController,
            curve: Curves.elasticOut,
          ),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.richGold.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _currentLetter,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Progress + timer
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$_filledCount/9',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.gameCategoriesFilled,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  // Timer
                  Icon(
                    Icons.timer,
                    color: isLow ? AppColors.errorRed : AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color:
                          isLow ? AppColors.errorRed : AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Timer bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.backgroundCard,
                  valueColor: AlwaysStoppedAnimation(
                    isLow ? AppColors.errorRed : AppColors.richGold,
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerProgress() {
    final l10n = AppLocalizations.of(context)!;
    final opponentFilled = _getOpponentFilledCount();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: widget.room.players.map((p) {
          final isMe = p.userId == widget.currentUserId;
          final score = widget.room.scores[p.userId] ?? 0;
          final filled = isMe ? _filledCount : opponentFilled;

          return Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Progress bar mini
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: filled / 9,
                        strokeWidth: 3,
                        backgroundColor:
                            AppColors.divider.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation(
                          isMe ? AppColors.richGold : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$filled',
                        style: TextStyle(
                          color: isMe
                              ? AppColors.richGold
                              : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isMe ? l10n.gameYou : p.displayName,
                        style: TextStyle(
                          color: isMe
                              ? AppColors.richGold
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight:
                              isMe ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l10n.gameScorePts(score),
                        style: TextStyle(
                          color: isMe
                              ? AppColors.richGold
                              : AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final l10n = AppLocalizations.of(context)!;
    final categories = _categories(l10n);
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryGridCell(
          category: category,
          categoryIcon: _getIconForCategory(category),
          filledWord: _filledWords[index],
          isActive: _activeCellIndex == index,
          index: index,
          onTap: () => _onCellTapped(index),
        );
      },
    );
  }

  Widget _buildScorePop() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: (1.0 - value).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -60 * value),
                  child: Transform.scale(
                    scale: 0.8 + 0.4 * Curves.elasticOut.transform(value),
                    child: child,
                  ),
                ),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.successGreen.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Text(
                _scoreFeedback,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundTransition() {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _roundTransitionController,
      builder: (context, child) {
        final t = _roundTransitionController.value;

        // Phase 1: background fades in (0-0.2)
        // Phase 2: letter scales in (0.2-0.6)
        // Phase 3: hold (0.6-0.8)
        // Phase 4: everything fades out (0.8-1.0)

        double bgOpacity;
        double letterScale;
        double letterOpacity;

        if (t < 0.2) {
          bgOpacity = (t / 0.2) * 0.7;
          letterScale = 0.0;
          letterOpacity = 0.0;
        } else if (t < 0.6) {
          bgOpacity = 0.7;
          final lt = (t - 0.2) / 0.4;
          letterScale = Curves.elasticOut.transform(lt);
          letterOpacity = lt.clamp(0.0, 1.0);
        } else if (t < 0.8) {
          bgOpacity = 0.7;
          letterScale = 1.0;
          letterOpacity = 1.0;
        } else {
          final ft = (t - 0.8) / 0.2;
          bgOpacity = 0.7 * (1.0 - ft);
          letterScale = 1.0 + ft * 0.3;
          letterOpacity = 1.0 - ft;
        }

        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.black.withValues(alpha: bgOpacity),
              alignment: Alignment.center,
              child: Opacity(
                opacity: letterOpacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: letterScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.gameCategoriesNewLetter,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.richGold.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _transitionLetter.isNotEmpty
                              ? _transitionLetter
                              : _currentLetter,
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.gameRoundNumber(widget.room.currentRound),
                        style: const TextStyle(
                          color: AppColors.richGold,
                          fontSize: 18,
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
      },
    );
  }
}
