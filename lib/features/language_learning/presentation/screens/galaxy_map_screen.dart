import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../coins/domain/entities/coin_reward.dart';
import '../../../coins/presentation/bloc/coin_bloc.dart';
import '../../../coins/presentation/bloc/coin_event.dart';
import '../../../coins/presentation/bloc/coin_state.dart';
import '../../domain/entities/constellation_node.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/lesson.dart';
import '../bloc/language_learning_bloc.dart';
import '../widgets/constellation_painter.dart';
import '../widgets/galaxy_node.dart';
import '../widgets/learning_path_node.dart';
import '../widgets/star_system_info_sheet.dart';
import 'lesson_detail_screen.dart';
import '../../../../generated/app_localizations.dart';
import 'lesson_session_screen.dart';

/// Galaxy/Constellation Map — full-screen vertical constellation path.
///
/// Vertical-only scroll. One lesson enabled at a time (sequential unlock).
/// Each unit has 27 nodes (26 content + 1 final quiz).
/// Shiny gold unit titles with connecting line to first node.
/// Level & coins fixed overlay on top-right.
/// Background: twinkling stars, shooting meteors, distant planets.
class GalaxyMapScreen extends StatefulWidget {
  final String languageCode;
  final String? packCategoryFilter;

  const GalaxyMapScreen({
    super.key,
    required this.languageCode,
    this.packCategoryFilter,
  });

  @override
  State<GalaxyMapScreen> createState() => _GalaxyMapScreenState();
}

class _GalaxyMapScreenState extends State<GalaxyMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _starfieldController;
  late ScrollController _scrollController;
  late String _langSource;

  // Fallback when no constellation data
  static const int _defaultNodesPerUnit = 27;
  static const double _nodeSpacing = 130.0;
  static const double _unitGap = 400.0;

  // Dynamic constellation — grouped by unit
  // Key: unit number (1-based), Value: list of ConstellationNode sorted by nodeIndex
  Map<int, List<ConstellationNode>> _constellationUnits = {};
  bool get _hasConstellation => _constellationUnits.isNotEmpty;

  /// Number of nodes for a given unit index.
  int _nodesInUnit(int unitIndex) {
    if (!_hasConstellation) return 0;
    final unitNum = unitIndex + 1;
    return _constellationUnits[unitNum]?.length ?? 0;
  }

  /// Total unit count.
  int get _unitCount {
    if (_hasConstellation) return _constellationUnits.length;
    return 0;
  }

  // Track the first uncompleted node globally for isNextLesson
  int _nextUnitIndex = 0;
  int _nextNodeIndex = 0;
  bool _nextFound = false;
  bool _hasRecenteredOnData = false;

  // Lesson completion animation state
  bool _showCompletionAnimation = false;
  int _completionStars = 0;
  int _completionXp = 0;
  Duration _completionTime = Duration.zero;

  double get _canvasHeight {
    double total = 200.0;
    for (int u = 0; u < _unitCount; u++) {
      total += _nodesInUnit(u) * _nodeSpacing + _unitGap;
    }
    return total + 200;
  }

  @override
  void initState() {
    super.initState();
    _starfieldController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _scrollController = ScrollController();

    // langSource = user's app language (from LanguageProvider), e.g. 'IT'
    final languageProvider = context.read<LanguageProvider>();
    _langSource = languageProvider.currentLocale.languageCode.toUpperCase();
    final langTarget = widget.languageCode.toUpperCase();

    // Avoid source == target (can't learn your own language)
    if (_langSource == langTarget) {
      _langSource = 'EN'; // default fallback
    }

    // Load lessons, progress, and constellation
    final bloc = context.read<LanguageLearningBloc>();
    bloc.add(LoadLessonsForLanguage(languageCode: widget.languageCode));
    bloc.add(LoadLearningPathProgress(languageCode: widget.languageCode));
    bloc.add(const LoadPurchasedLessons());
    bloc.add(LoadConstellation(langSource: _langSource, langTarget: langTarget));

    // Listen for language changes — clear cache and re-fetch
    languageProvider.addListener(_onLanguageChanged);

    // Auto-claim daily 100 coins
    _claimDailyCoins();

    // Center on current progress after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnProgress();
    });
  }

  @override
  void dispose() {
    context.read<LanguageProvider>().removeListener(_onLanguageChanged);
    _starfieldController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Called when the user switches their app language in settings.
  void _onLanguageChanged() {
    if (!mounted) return;
    final languageProvider = context.read<LanguageProvider>();
    final newSource = languageProvider.currentLocale.languageCode.toUpperCase();
    final langTarget = widget.languageCode.toUpperCase();

    if (newSource == langTarget || newSource == _langSource) return;

    final oldSource = _langSource;
    _langSource = newSource;

    // Invalidate old cache and re-fetch for new language pair
    final bloc = context.read<LanguageLearningBloc>();
    bloc.add(InvalidateAndReloadConstellation(
      langSource: oldSource,
      langTarget: langTarget,
    ));
    bloc.add(LoadConstellation(langSource: _langSource, langTarget: langTarget));

    setState(() {
      _constellationUnits = {};
      _hasRecenteredOnData = false;
    });
  }

  void _claimDailyCoins() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    context.read<CoinBloc>().add(ClaimCoinReward(
      userId: userId,
      reward: CoinRewards.dailyLogin,
    ));
  }


  /// Vertical stacking: each unit starts after the previous one.
  double _unitStartY(int unitIndex) {
    double y = 200.0;
    for (int u = 0; u < unitIndex; u++) {
      y += _nodesInUnit(u) * _nodeSpacing + _unitGap;
    }
    return y;
  }

  Offset _constellationCenter(int unitIndex) {
    final nodesInUnit = _nodesInUnit(unitIndex);
    return Offset(0, _unitStartY(unitIndex) + (nodesInUnit ~/ 2) * _nodeSpacing);
  }

  /// Vertical sine-wave zigzag path for nodes within a unit.
  List<Offset> _constellationNodePositions(int unitIndex,
      {double? screenWidth}) {
    final startY = _unitStartY(unitIndex);
    final width = screenWidth ?? 400;
    final centerX = width / 2;
    final amplitude = width * 0.18;
    final freqs = [0.33, 0.25, 0.5, 0.4];
    final freq = freqs[unitIndex % freqs.length] * pi;
    final nodeCount = _nodesInUnit(unitIndex);

    return List.generate(nodeCount, (i) {
      final y = startY + i * _nodeSpacing;
      final x = centerX + amplitude * sin(i * freq);
      return Offset(x, y);
    });
  }

  void _centerOnProgress() {
    if (!_scrollController.hasClients) return;
    if (_unitCount == 0) return;
    final state = context.read<LanguageLearningBloc>().state;
    _findNextLesson(state.completedLessonIds);

    final screenWidth = MediaQuery.of(context).size.width;
    final positions =
        _constellationNodePositions(_nextUnitIndex, screenWidth: screenWidth);
    if (positions.isEmpty) return;
    final targetPos = _nextNodeIndex < positions.length
        ? positions[_nextNodeIndex]
        : positions.first;

    final screenHeight = MediaQuery.of(context).size.height;
    final targetScroll =
        (targetPos.dy - screenHeight / 2).clamp(0.0, _scrollController.position.maxScrollExtent);

    _scrollController.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
    );
  }

  void _findNextLesson(Set<String> completed) {
    _nextFound = false;
    if (_unitCount == 0) {
      _nextUnitIndex = 0;
      _nextNodeIndex = 0;
      return;
    }
    for (int u = 0; u < _unitCount; u++) {
      for (int n = 0; n < _nodesInUnit(u); n++) {
        final status = _getNodeStatusFromCompleted(u, n, completed);
        if (status == PathNodeStatus.available && !_nextFound) {
          _nextUnitIndex = u;
          _nextNodeIndex = n;
          _nextFound = true;
          return;
        }
      }
    }
    // If everything is completed, point to last node
    _nextUnitIndex = _unitCount - 1;
    _nextNodeIndex = _nodesInUnit(_nextUnitIndex) - 1;
  }

  bool _isNextLesson(int unitIndex, int nodeIndex) {
    return _nextFound &&
        unitIndex == _nextUnitIndex &&
        nodeIndex == _nextNodeIndex;
  }

  SupportedLanguage? get _language =>
      SupportedLanguage.getByCode(widget.languageCode);

  /// One-at-a-time unlock: only the FIRST uncompleted node is available.
  PathNodeStatus _getNodeStatusFromCompleted(
      int unitIndex, int nodeIndex, Set<String> completed) {
    final nodeId = _nodeId(unitIndex, nodeIndex);

    if (completed.contains(nodeId)) {
      return PathNodeStatus.completed;
    }

    // Check if this is the first uncompleted node sequentially
    // All prior nodes (across units) must be completed
    for (int u = 0; u <= unitIndex; u++) {
      final maxN = (u == unitIndex) ? nodeIndex : _nodesInUnit(u);
      for (int n = 0; n < maxN; n++) {
        if (!completed.contains(_nodeId(u, n))) {
          return PathNodeStatus.locked;
        }
      }
    }

    // If we get here, all prior nodes are completed — this is the next available
    return PathNodeStatus.available;
  }

  PathNodeStatus _getNodeStatus(int unitIndex, int nodeIndex) {
    final state = context.read<LanguageLearningBloc>().state;
    return _getNodeStatusFromCompleted(
        unitIndex, nodeIndex, state.completedLessonIds);
  }

  String _nodeId(int unitIndex, int nodeIndex) {
    return 'u${unitIndex}_n$nodeIndex';
  }

  /// Get the constellation node for a given unit+node index, if available.
  ConstellationNode? _constellationNode(int unitIndex, int nodeIndex) {
    final unitNum = unitIndex + 1;
    final nodes = _constellationUnits[unitNum];
    if (nodes == null || nodeIndex >= nodes.length) return null;
    return nodes[nodeIndex];
  }

  /// Maps constellation nodeType string to PathNodeType.
  static PathNodeType _mapNodeType(String nodeType) {
    switch (nodeType) {
      case 'ClassicLesson':
        return PathNodeType.lesson;
      case 'AICoaching':
        return PathNodeType.aiCoach;
      case 'Quiz':
      case 'FinalQuiz':
        return PathNodeType.quiz;
      case 'Flashcard':
        return PathNodeType.flashcard;
      default:
        return PathNodeType.lesson;
    }
  }

  PathNodeType _nodeType(int unitIndex, int nodeIndex) {
    final cNode = _constellationNode(unitIndex, nodeIndex);
    if (cNode != null) return _mapNodeType(cNode.nodeType);
    return PathNodeType.lesson;
  }

  String _nodeTitle(int unitIndex, int nodeIndex) {
    final cNode = _constellationNode(unitIndex, nodeIndex);
    if (cNode != null) return cNode.nodeTitle;
    return AppLocalizations.of(context)!.learningLessonNumber(nodeIndex + 1);
  }

  /// Unit title from constellation data.
  String _unitTitle(int unitIndex) {
    final cNode = _constellationNode(unitIndex, 0);
    if (cNode != null) return cNode.unitTitle;
    return AppLocalizations.of(context)!.learningUnitNumber(unitIndex + 1);
  }

  /// Coin cost for a node — from constellation data.
  int _nodeCoinCost(int unitIndex, int nodeIndex, PathNodeType type) {
    final cNode = _constellationNode(unitIndex, nodeIndex);
    if (cNode != null) return cNode.coinCost;
    return 0;
  }

  /// XP reward from constellation data.
  int _nodeXp(int unitIndex, int nodeIndex) {
    final cNode = _constellationNode(unitIndex, nodeIndex);
    if (cNode != null) return cNode.xp;
    return 0;
  }

  void _onNodeTap(int unitIndex, int nodeIndex) {
    HapticFeedback.selectionClick();
    final type = _nodeType(unitIndex, nodeIndex);
    final status = _getNodeStatus(unitIndex, nodeIndex);
    final state = context.read<LanguageLearningBloc>().state;
    final nodeId = _nodeId(unitIndex, nodeIndex);
    final unitTitleStr = _unitTitle(unitIndex);

    final coinCost = _nodeCoinCost(unitIndex, nodeIndex, type);
    final xp = _nodeXp(unitIndex, nodeIndex);

    StarSystemInfoSheet.show(
      context,
      lesson: null,
      nodeType: type,
      nodeStatus: status,
      title: '$unitTitleStr — ${_nodeTitle(unitIndex, nodeIndex)}',
      xpReward: xp,
      isPurchased: true,
      coinCost: coinCost,
      starCount: state.lessonStars[nodeId] ?? 0,
      onStartLesson: () =>
          _navigateToContent(type, unitIndex, nodeIndex, null),
    );
  }

  void _navigateToContent(
      PathNodeType type, int unitIndex, int nodeIndex, Lesson? lesson) {
    final nodeId = _nodeId(unitIndex, nodeIndex);
    final langTarget = widget.languageCode.toUpperCase();
    final unit = unitIndex + 1;

    // Compute lesson number: count ClassicLesson nodes up to and including this one
    int lessonNum = 0;
    for (int i = 0; i <= nodeIndex; i++) {
      if (_nodeType(unitIndex, i) == PathNodeType.lesson) lessonNum++;
    }

    switch (type) {
      case PathNodeType.lesson:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(
                    value: context.read<LanguageLearningBloc>()),
                BlocProvider.value(value: context.read<CoinBloc>()),
              ],
              child: LessonSessionScreen(
                languageSource: _langSource,
                languageTarget: langTarget,
                unit: unit,
                lesson: lessonNum,
                galaxyNodeId: nodeId,
              ),
            ),
          ),
        );
        break;
      case PathNodeType.quiz:
        Navigator.pushNamed(
          context,
          '/language-learning/quiz-session',
          arguments: {
            'languageCode': widget.languageCode,
            'unitTitle': _unitTitle(unitIndex),
          },
        );
        break;
      case PathNodeType.flashcard:
        Navigator.pushNamed(
          context,
          '/language-learning/flashcard-session',
          arguments: {
            'languageCode': widget.languageCode,
            'unitTitle': _unitTitle(unitIndex),
          },
        );
        break;
      case PathNodeType.aiCoach:
        Navigator.pushNamed(
          context,
          '/language-learning/ai-coach',
          arguments: {
            'languageCode': widget.languageCode,
            'unitTitle': _unitTitle(unitIndex),
          },
        );
        break;
    }
  }

  /// Show full-screen lesson completion animation with stars, XP, and time.
  void showLessonCompletionAnimation({
    required int stars,
    required int xpEarned,
    required Duration timeTaken,
  }) {
    setState(() {
      _showCompletionAnimation = true;
      _completionStars = stars;
      _completionXp = xpEarned;
      _completionTime = timeTaken;
    });
    HapticFeedback.heavyImpact();
    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showCompletionAnimation = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = _language;
    final flagEmoji = language?.flag ?? '';
    final languageName = language?.name ?? widget.languageCode;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: _buildAppBar(flagEmoji, languageName),
      body: BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
        builder: (context, state) {
          // Loading state
          if (state.isConstellationLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.richGold,
              ),
            );
          }

          // Empty state — no constellation data from Firestore
          if (!_hasConstellation) {
            _rebuildConstellationUnits(state);
            if (!_hasConstellation) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome,
                        color: Colors.white.withValues(alpha: 0.3), size: 64),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.learningNoLessonsAvailable,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.learningCheckBackSoon,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 14)),
                  ],
                ),
              );
            }
          }

          // Compute the next lesson once per build
          _findNextLesson(state.completedLessonIds);

          // Re-center viewport once when progress data loads
          if (!_hasRecenteredOnData && state.completedLessonIds.isNotEmpty) {
            _hasRecenteredOnData = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _centerOnProgress();
            });
          }

          return Stack(
            children: [
              // Deep space starfield background (fixed, outside scroll)
              AnimatedBuilder(
                animation: _starfieldController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _StarfieldPainter(
                      progress: _starfieldController.value,
                    ),
                  );
                },
              ),
              // Vertical-only scroll galaxy map
              ClipRect(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: screenWidth,
                    height: _canvasHeight,
                    child: Stack(
                      children: [
                        // Nebula regions
                        ..._buildNebulaRegions(screenWidth),
                        // Constellation lines + inter-unit connections
                        ..._buildConstellationLines(state, screenWidth),
                        // Star nodes
                        ..._buildStarNodes(state, screenWidth),
                        // Unit labels (shiny gold)
                        ..._buildUnitLabels(state, screenWidth),
                      ],
                    ),
                  ),
                ),
              ),
              // Fixed overlay: Level & Coins (top-right)
              Positioned(
                top: 12,
                right: 12,
                child: _buildLevelCoinsOverlay(),
              ),
              // Pack focus banner
              if (widget.packCategoryFilter != null)
                Positioned(
                  top: 8,
                  left: 16,
                  right: 140,
                  child: _buildPackFocusBanner(),
                ),
              // Lesson completion animation overlay
              if (_showCompletionAnimation)
                _buildCompletionAnimationOverlay(),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String flag, String languageName) {
    return AppBar(
      backgroundColor: const Color(0xFF050510),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            languageName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  /// Fixed overlay pill with coin balance + level badge.
  Widget _buildLevelCoinsOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.richGold.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coin balance
          BlocBuilder<CoinBloc, CoinState>(
            builder: (context, coinState) {
              int coins = 0;
              if (coinState is CoinBalanceLoaded) {
                coins = coinState.balance.totalCoins;
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on,
                      color: AppColors.richGold, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$coins',
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 10),
          // Level badge
          BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
            builder: (context, state) {
              final progress = state.currentLanguageProgress;
              final level = _calculateLevel(progress?.totalXpEarned ?? 0);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.richGold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'LV $level',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNebulaRegions(double screenWidth) {
    return List.generate(_unitCount, (i) {
      final center = _constellationCenter(i);
      final hue = (i * 30.0 + 200) % 360;
      final color = HSLColor.fromAHSL(1, hue, 0.4, 0.3).toColor();

      return Positioned(
        left: screenWidth / 2 - 200,
        top: center.dy - 200,
        child: Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.06),
                color.withValues(alpha: 0.02),
                Colors.transparent,
              ],
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _buildConstellationLines(
      LanguageLearningState state, double screenWidth) {
    return List.generate(_unitCount, (unitIndex) {
      final positions =
          _constellationNodePositions(unitIndex, screenWidth: screenWidth);
      final completedStars = List.generate(
        _nodesInUnit(unitIndex),
        (nodeIndex) =>
            state.completedLessonIds.contains(_nodeId(unitIndex, nodeIndex)),
      );

      // Get the first node of the next unit for inter-unit connection
      Offset? nextStart;
      if (unitIndex < _unitCount - 1) {
        final nextPositions = _constellationNodePositions(unitIndex + 1,
            screenWidth: screenWidth);
        if (nextPositions.isNotEmpty) {
          nextStart = nextPositions.first;
        }
      }

      // Unit title position for connection line
      final titleY = _unitStartY(unitIndex) - 200;
      final titlePos = Offset(screenWidth / 2, titleY);

      return Positioned.fill(
        child: CustomPaint(
          painter: ConstellationPainter(
            starPositions: positions,
            completedStars: completedStars,
            nextConstellationStart: nextStart,
            unitTitlePosition: titlePos,
          ),
        ),
      );
    });
  }

  List<Widget> _buildStarNodes(
      LanguageLearningState state, double screenWidth) {
    // Rebuild constellation units from state
    _rebuildConstellationUnits(state);

    final widgets = <Widget>[];

    for (int unitIndex = 0; unitIndex < _unitCount; unitIndex++) {
      final positions =
          _constellationNodePositions(unitIndex, screenWidth: screenWidth);
      final nodeCount = _nodesInUnit(unitIndex);

      for (int nodeIndex = 0; nodeIndex < nodeCount; nodeIndex++) {
        final pos = positions[nodeIndex];
        final type = _nodeType(unitIndex, nodeIndex);
        final status = _getNodeStatus(unitIndex, nodeIndex);
        final title = _nodeTitle(unitIndex, nodeIndex);
        final isNext = _isNextLesson(unitIndex, nodeIndex);
        final nodeId = _nodeId(unitIndex, nodeIndex);
        final xp = _nodeXp(unitIndex, nodeIndex);

        widgets.add(
          Positioned(
            left: pos.dx - 50,
            top: pos.dy - 32,
            child: GalaxyNode(
              type: type,
              status: status,
              title: title,
              xpReward: xp,
              isNextLesson: isNext,
              starCount: state.lessonStars[nodeId] ?? 0,
              onTap: status != PathNodeStatus.locked
                  ? () => _onNodeTap(unitIndex, nodeIndex)
                  : null,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  /// Rebuilds [_constellationUnits] from bloc state.
  void _rebuildConstellationUnits(LanguageLearningState state) {
    if (state.constellationNodes.isEmpty) {
      _constellationUnits = {};
      return;
    }
    final map = <int, List<ConstellationNode>>{};
    for (final node in state.constellationNodes) {
      map.putIfAbsent(node.unit, () => []).add(node);
    }
    // Sort each unit's nodes by nodeIndex
    for (final nodes in map.values) {
      nodes.sort((a, b) => a.nodeIndex.compareTo(b.nodeIndex));
    }
    _constellationUnits = map;
  }

  /// Shiny gold unit labels with emoji, title with shimmer, and progress.
  List<Widget> _buildUnitLabels(
      LanguageLearningState state, double screenWidth) {
    return List.generate(_unitCount, (i) {
      final startY = _unitStartY(i);
      final title = _unitTitle(i);
      final nodesInUnit = _nodesInUnit(i);

      // Count completed in this unit
      int completedInUnit = 0;
      for (int n = 0; n < nodesInUnit; n++) {
        if (state.completedLessonIds.contains(_nodeId(i, n))) {
          completedInUnit++;
        }
      }

      final emoji = '⭐';

      return Positioned(
        left: screenWidth / 2 - 140,
        top: startY - 250,
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji
              Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 6),
              // Gold shimmer title
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.richGold.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      colors: [
                        Color(0xFFD4AF37),
                        Color(0xFFF5E6A3),
                        Color(0xFFD4AF37),
                        Color(0xFFF5E6A3),
                        Color(0xFFD4AF37),
                      ],
                      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                    ).createShader(bounds);
                  },
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$completedInUnit/$nodesInUnit completed',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Full-screen lesson completion animation overlay.
  Widget _buildCompletionAnimationOverlay() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.8 * value),
          child: Center(
            child: Transform.scale(
              scale: value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stars
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final delay = i * 200;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400 + delay),
                        curve: Curves.elasticOut,
                        builder: (context, starValue, _) {
                          return Transform.scale(
                            scale: i < _completionStars ? starValue : 0.6,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                i < _completionStars
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 56,
                                color: i < _completionStars
                                    ? AppColors.richGold
                                    : Colors.grey.withValues(alpha: 0.4),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    AppLocalizations.of(context)!.learningLessonCompleteUpper,
                    style: TextStyle(
                      color: AppColors.richGold,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(
                          blurRadius: 20,
                          color: AppColors.richGold,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // XP earned
                      _completionStatPill(
                        icon: Icons.flash_on,
                        label: '+$_completionXp XP',
                        color: AppColors.richGold,
                      ),
                      const SizedBox(width: 16),
                      // Time taken
                      _completionStatPill(
                        icon: Icons.timer,
                        label:
                            '${_completionTime.inMinutes}:${(_completionTime.inSeconds % 60).toString().padLeft(2, '0')}',
                        color: Colors.lightBlueAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.of(context)!.learningTapToContinue,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _completionStatPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackFocusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.richGold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, color: AppColors.richGold, size: 18),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.learningPackFilter(widget.packCategoryFilter!),
            style: const TextStyle(
              color: AppColors.richGold,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacementNamed(
                context,
                '/language-learning/learning-path',
                arguments: {'languageCode': widget.languageCode},
              );
            },
            child: Text(
              AppLocalizations.of(context)!.learningShowAll,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateLevel(int totalXp) {
    if (totalXp >= 35000) return 8;
    if (totalXp >= 20000) return 7;
    if (totalXp >= 12000) return 6;
    if (totalXp >= 7000) return 5;
    if (totalXp >= 3500) return 4;
    if (totalXp >= 1500) return 3;
    if (totalXp >= 500) return 2;
    return 1;
  }
}

/// Deep space starfield with twinkling stars, shooting meteors, and distant planets.
class _StarfieldPainter extends CustomPainter {
  final double progress;

  _StarfieldPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // ── Deep space gradient background ──
    _drawNebulaeClouds(canvas, size);

    // ── Multi-layer stars ──
    _drawStarLayer1(canvas, size); // Far background: tiny dim
    _drawStarLayer2(canvas, size); // Mid field: medium
    _drawStarLayer3(canvas, size); // Foreground: bright with glow

    // ── Star clusters ──
    _drawStarClusters(canvas, size);

    // ── Distant galaxy spiral ──
    _drawGalaxySpiral(canvas, size);

    // ── Asteroids ──
    _drawAsteroids(canvas, size);

    // ── Planets ──
    _drawPlanets(canvas, size);

  }

  // ──────────────────────────────────────────
  //  NEBULA CLOUDS
  // ──────────────────────────────────────────

  void _drawNebulaeClouds(Canvas canvas, Size size) {
    final nebulaData = [
      (0.15, 0.20, 130.0, const Color(0xFF2D1B69), 0.06),
      (0.80, 0.35, 180.0, const Color(0xFF0D4D4D), 0.05),
      (0.35, 0.65, 160.0, const Color(0xFF4A0E3C), 0.04),
      (0.70, 0.80, 200.0, const Color(0xFF1A2980), 0.07),
    ];

    for (final (fx, fy, radius, color, opacity) in nebulaData) {
      final cx = fx * size.width;
      final cy = fy * size.height;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.4),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  // ──────────────────────────────────────────
  //  STAR LAYER 1 — Far background (tiny, dim)
  // ──────────────────────────────────────────

  void _drawStarLayer1(Canvas canvas, Size size) {
    final rng = Random(42);
    const count = 150;
    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final baseRadius = 0.5 + rng.nextDouble() * 1.0;
      final speed = 0.3 + rng.nextDouble() * 0.5;
      final phase = rng.nextDouble() * 2 * pi;
      final twinkle = 0.5 + 0.5 * ((sin(progress * 2 * pi * speed + phase) + 1) / 2);
      final opacity = (0.2 + 0.2 * twinkle).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(x, y),
        baseRadius * twinkle,
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }
  }

  // ──────────────────────────────────────────
  //  STAR LAYER 2 — Mid field (medium, white/blue)
  // ──────────────────────────────────────────

  void _drawStarLayer2(Canvas canvas, Size size) {
    final rng = Random(88);
    const count = 80;
    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final baseRadius = 1.0 + rng.nextDouble() * 1.5;
      final speed = 0.5 + rng.nextDouble() * 1.0;
      final phase = rng.nextDouble() * 2 * pi;
      final twinkle = 0.4 + 0.6 * ((sin(progress * 2 * pi * speed + phase) + 1) / 2);
      final opacity = (0.4 + 0.3 * twinkle).clamp(0.0, 1.0);

      final colorRoll = rng.nextDouble();
      final color = colorRoll < 0.6
          ? Colors.white.withOpacity(opacity)
          : const Color(0xFF88AAFF).withOpacity(opacity);

      canvas.drawCircle(Offset(x, y), baseRadius * twinkle, Paint()..color = color);
    }
  }

  // ──────────────────────────────────────────
  //  STAR LAYER 3 — Bright foreground with cross-glow
  // ──────────────────────────────────────────

  void _drawStarLayer3(Canvas canvas, Size size) {
    final rng = Random(55);
    const count = 30;
    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final baseRadius = 1.5 + rng.nextDouble() * 2.0;
      final speed = 0.8 + rng.nextDouble() * 1.2;
      final phase = rng.nextDouble() * 2 * pi;
      final twinkle = 0.6 + 0.4 * ((sin(progress * 2 * pi * speed + phase) + 1) / 2);
      final opacity = (0.7 + 0.3 * twinkle).clamp(0.0, 1.0);

      final colorRoll = rng.nextDouble();
      Color starColor;
      if (colorRoll < 0.5) {
        starColor = Colors.white;
      } else if (colorRoll < 0.8) {
        starColor = const Color(0xFFFFDD88); // gold
      } else {
        starColor = const Color(0xFFAABBFF); // pale blue
      }

      final r = baseRadius * twinkle;
      final center = Offset(x, y);

      // Soft glow halo
      canvas.drawCircle(
        center,
        r * 2.5,
        Paint()..color = starColor.withOpacity(opacity * 0.08),
      );

      // Cross-glow spikes
      final spikePaint = Paint()
        ..color = starColor.withOpacity(opacity * 0.25)
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round;
      final spikeLen = r * 3.5;
      canvas.drawLine(Offset(x - spikeLen, y), Offset(x + spikeLen, y), spikePaint);
      canvas.drawLine(Offset(x, y - spikeLen), Offset(x, y + spikeLen), spikePaint);

      // Core
      canvas.drawCircle(center, r, Paint()..color = starColor.withOpacity(opacity));
    }
  }

  // ──────────────────────────────────────────
  //  STAR CLUSTERS
  // ──────────────────────────────────────────

  void _drawStarClusters(Canvas canvas, Size size) {
    final clusterData = [
      (0.20, 0.15, 7),
      (0.75, 0.50, 6),
      (0.40, 0.85, 8),
    ];

    final rng = Random(99);
    for (final (fx, fy, count) in clusterData) {
      final cx = fx * size.width;
      final cy = fy * size.height;
      for (int i = 0; i < count; i++) {
        final dx = (rng.nextDouble() - 0.5) * 24;
        final dy = (rng.nextDouble() - 0.5) * 24;
        final r = 0.8 + rng.nextDouble() * 1.2;
        final speed = 1.0 + rng.nextDouble();
        final phase = rng.nextDouble() * 2 * pi;
        final twinkle = 0.6 + 0.4 * ((sin(progress * 2 * pi * speed + phase) + 1) / 2);
        canvas.drawCircle(
          Offset(cx + dx, cy + dy),
          r,
          Paint()..color = Colors.white.withOpacity(0.6 * twinkle),
        );
      }
    }
  }

  // ──────────────────────────────────────────
  //  DISTANT GALAXY SPIRAL
  // ──────────────────────────────────────────

  void _drawGalaxySpiral(Canvas canvas, Size size) {
    final cx = size.width * 0.85;
    final cy = size.height * 0.12;
    const opacity = 0.04;
    const armCount = 2;

    for (int arm = 0; arm < armCount; arm++) {
      final path = Path();
      final startAngle = arm * pi;
      bool first = true;
      for (double t = 0; t < 4 * pi; t += 0.15) {
        final r = 5 + t * 6;
        final angle = startAngle + t;
        final px = cx + r * cos(angle);
        final py = cy + r * sin(angle) * 0.5; // flattened
        if (first) {
          path.moveTo(px, py);
          first = false;
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF8888CC).withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  // ──────────────────────────────────────────
  //  ASTEROIDS
  // ──────────────────────────────────────────

  void _drawAsteroids(Canvas canvas, Size size) {
    final rng = Random(200);
    const count = 10;

    final asteroidColors = [
      const Color(0xFF8B7355), // brown
      const Color(0xFF808080), // grey
      const Color(0xFF6B5B4F), // dark brown
    ];

    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final w = 6.0 + rng.nextDouble() * 14;
      final h = w * (0.7 + rng.nextDouble() * 0.5);
      final opacity = 0.15 + rng.nextDouble() * 0.10;
      final color = asteroidColors[i % asteroidColors.length];
      final rotation = rng.nextDouble() * pi;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Body
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        Paint()..color = color.withOpacity(opacity),
      );

      // Crater (smaller darker circle)
      if (w > 10) {
        final craterX = (rng.nextDouble() - 0.5) * w * 0.3;
        final craterY = (rng.nextDouble() - 0.5) * h * 0.3;
        canvas.drawCircle(
          Offset(craterX, craterY),
          w * 0.15,
          Paint()..color = const Color(0xFF333333).withOpacity(opacity * 0.5),
        );
      }

      canvas.restore();
    }
  }

  // ──────────────────────────────────────────
  //  PLANETS
  // ──────────────────────────────────────────

  void _drawPlanets(Canvas canvas, Size size) {
    // (fracX, fracY, size, color1, color2, opacity, hasRing)
    final planets = [
      (0.12, 0.25, 35.0, const Color(0xFFCC4444), const Color(0xFF883322), 0.10, false),
      (0.85, 0.40, 50.0, const Color(0xFF5544AA), const Color(0xFF332266), 0.08, true),
      (0.30, 0.70, 25.0, const Color(0xFFDD9933), const Color(0xFFBB7711), 0.12, false),
      (0.70, 0.15, 30.0, const Color(0xFF22AAAA), const Color(0xFF116666), 0.10, false),
      (0.55, 0.90, 40.0, const Color(0xFFCC9944), const Color(0xFF886622), 0.09, true),
    ];

    for (final (fx, fy, pSize, c1, c2, opacity, hasRing) in planets) {
      final px = fx * size.width;
      final py = fy * size.height;

      // Subtle glow
      canvas.drawCircle(
        Offset(px, py),
        pSize * 1.8,
        Paint()..color = c1.withOpacity(opacity * 0.3),
      );

      // Planet body
      final planetPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            c1.withOpacity(opacity * 1.5),
            c2.withOpacity(opacity),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(px, py), radius: pSize));
      canvas.drawCircle(Offset(px, py), pSize, planetPaint);

      // Ring
      if (hasRing) {
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(0.3);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: pSize * 2.8,
            height: pSize * 0.5,
          ),
          Paint()
            ..color = c1.withOpacity(opacity * 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        canvas.restore();
      }
    }
  }


  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
