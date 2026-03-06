import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/learning_effects.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/lesson.dart';
import '../bloc/language_learning_bloc.dart';
import '../widgets/learning_path_node.dart';
import '../widgets/learning_path_connector.dart';
import '../widgets/unit_header_card.dart';

/// Main Duolingo-style learning path screen.
/// Displays a vertical zigzag path of lesson nodes organized by
/// LessonCategory units, with quiz checkpoints, flashcard reviews,
/// and AI coach sessions interspersed.
class LearningPathScreen extends StatefulWidget {
  final String languageCode;
  final String? packCategoryFilter; // If opened from a language pack

  const LearningPathScreen({
    super.key,
    required this.languageCode,
    this.packCategoryFilter,
  });

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _bgAnimController;

  // All 23 lesson categories serve as units
  late List<LessonCategory> _units;

  // Simulated progress: first 2 units unlocked for MVP
  static const int _unlockedUnits = 2;

  // Nodes per unit: 20 lessons + 3 quizzes + 2 flashcards + 1 AI coach = 26
  static const int _nodesPerUnit = 26;

  // Simulated completed node count within unlocked units
  static const int _unit0Completed = 26;
  static const int _unit1Completed = 8;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Build unit list, optionally filtered by pack category
    final allCategories = LessonCategory.values;
    if (widget.packCategoryFilter != null) {
      _units = allCategories
          .where((c) =>
              c.displayName.toLowerCase() ==
              widget.packCategoryFilter!.toLowerCase())
          .toList();
      // If no match, show all
      if (_units.isEmpty) {
        _units = allCategories;
      }
    } else {
      _units = allCategories;
    }

    // Scroll to first available node after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToFirstAvailable();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bgAnimController.dispose();
    super.dispose();
  }

  void _scrollToFirstAvailable() {
    // Approximate position: unit 1 header + nodes before first available
    // Each unit ~ 7 nodes * 140px + header 80px = ~1060px
    // First available is in unit 1 at node index 3 (after 3 completed)
    final targetOffset = (_unit0Completed > 0)
        ? (80.0 + _nodesPerUnit * 140.0 + 80.0 + _unit1Completed * 140.0)
        : 0.0;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  SupportedLanguage? get _language =>
      SupportedLanguage.getByCode(widget.languageCode);

  int _completedNodesInUnit(int unitIndex) {
    if (unitIndex == 0) return _unit0Completed;
    if (unitIndex == 1) return _unit1Completed;
    return 0;
  }

  bool _isUnitUnlocked(int unitIndex) {
    return unitIndex < _unlockedUnits;
  }

  PathNodeStatus _getNodeStatus(int unitIndex, int nodeIndexInUnit) {
    if (!_isUnitUnlocked(unitIndex)) {
      return PathNodeStatus.locked;
    }

    final completed = _completedNodesInUnit(unitIndex);

    if (nodeIndexInUnit < completed) {
      return PathNodeStatus.completed;
    } else if (nodeIndexInUnit == completed) {
      return PathNodeStatus.available;
    } else {
      return PathNodeStatus.locked;
    }
  }

  int _completedLessonsInUnit(int unitIndex) {
    final completed = _completedNodesInUnit(unitIndex);
    // Only count lesson nodes (20 of 27)
    return completed.clamp(0, 20);
  }

  void _onNodeTap(PathNodeType type, int unitIndex, int nodeIndexInUnit) {
    HapticFeedback.selectionClick();
    final category = _units[unitIndex];

    switch (type) {
      case PathNodeType.lesson:
        Navigator.pushNamed(
          context,
          '/language-learning/language-detail',
          arguments: {
            'languageCode': widget.languageCode,
            'category': category,
            'lessonIndex': nodeIndexInUnit,
          },
        );
        break;
      case PathNodeType.quiz:
        Navigator.pushNamed(
          context,
          '/language-learning/quiz-session',
          arguments: {
            'languageCode': widget.languageCode,
            'category': category.name,
          },
        );
        break;
      case PathNodeType.flashcard:
        Navigator.pushNamed(
          context,
          '/language-learning/flashcard-session',
          arguments: {
            'languageCode': widget.languageCode,
            'category': category.name,
          },
        );
        break;
      case PathNodeType.aiCoach:
        Navigator.pushNamed(
          context,
          '/language-learning/ai-coach',
          arguments: {
            'languageCode': widget.languageCode,
            'category': category.name,
          },
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = _language;
    final flagEmoji = language?.flag ?? '';
    final languageName = language?.name ?? widget.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: _buildAppBar(flagEmoji, languageName),
      body: Stack(
        children: [
          // Animated floating particles background
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _FloatingParticlesPainter(
                  progress: _bgAnimController.value,
                ),
              );
            },
          ),
          _buildBody(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String flag, String languageName) {
    return AppBar(
      backgroundColor: const Color(0xFF0A0A0A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            flag,
            style: const TextStyle(fontSize: 24),
          ),
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
      actions: [
        // Level badge
        BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
          builder: (context, state) {
            final progress = state.currentLanguageProgress;
            final level = _calculateLevel(progress?.totalXpEarned ?? 0);
            return Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.richGold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'LV $level',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
            builder: (context, state) {
              final progress = state.currentLanguageProgress;
              final totalXp = progress?.totalXpEarned ?? 0;
              final level = _calculateLevel(totalXp);
              final currentLevelXp = _xpForLevel(level);
              final nextLevelXp = _xpForLevel(level + 1);
              final xpInLevel = totalXp - currentLevelXp;
              final xpNeeded = nextLevelXp - currentLevelXp;

              return XpProgressBar(
                currentXp: xpInLevel,
                maxXp: xpNeeded,
                level: level,
                showLabel: false,
                height: 10,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
      builder: (context, state) {
        return SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 16, bottom: 100),
          child: Column(
            children: [
              // Pack focus mode banner
              if (widget.packCategoryFilter != null)
                _buildPackFocusBanner(),

              // Build all units
              ..._buildAllUnits(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPackFocusBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.richGold.withValues(alpha: 0.1),
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
            'Pack: ${widget.packCategoryFilter}',
            style: const TextStyle(
              color: AppColors.richGold,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              // Navigate back to unfiltered path
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => LearningPathScreen(
                    languageCode: widget.languageCode,
                  ),
                ),
              );
            },
            child: const Text(
              'Show All',
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

  List<Widget> _buildAllUnits() {
    final widgets = <Widget>[];

    for (int unitIndex = 0; unitIndex < _units.length; unitIndex++) {
      final category = _units[unitIndex];
      final isUnlocked = _isUnitUnlocked(unitIndex);
      final completedLessons = _completedLessonsInUnit(unitIndex);

      // Unit header card
      widgets.add(
        Opacity(
          opacity: isUnlocked ? 1.0 : 0.5,
          child: UnitHeaderCard(
            unitNumber: unitIndex + 1,
            category: category,
            completedLessons: completedLessons,
            totalLessons: 20,
          ),
        ),
      );

      // Build nodes for this unit
      widgets.addAll(_buildUnitNodes(unitIndex, category));

      // Spacing between units
      if (unitIndex < _units.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }

    return widgets;
  }

  List<Widget> _buildUnitNodes(int unitIndex, LessonCategory category) {
    final nodes = <Widget>[];

    // Build 26 nodes: 20 lessons + 3 quizzes + 2 flashcards + 1 AI coach
    // Layout: L1-L7, Quiz1, Flashcard1, L8-L14, Quiz2, L15-L20, Flashcard2, Quiz3, AI Coach
    final nodeDefinitions = <_NodeDefinition>[];
    int lessonNum = 0;

    // Block 1: 7 lessons + quiz + flashcard
    for (int j = 0; j < 7; j++) {
      lessonNum++;
      nodeDefinitions.add(_NodeDefinition(
        type: PathNodeType.lesson,
        title: '${category.emoji} Lesson $lessonNum',
        xp: 15,
      ));
    }
    nodeDefinitions.add(const _NodeDefinition(type: PathNodeType.quiz, title: 'Quiz 1', xp: 30));
    nodeDefinitions.add(const _NodeDefinition(type: PathNodeType.flashcard, title: 'Flashcards', xp: 15));

    // Block 2: 7 lessons + quiz
    for (int j = 0; j < 7; j++) {
      lessonNum++;
      nodeDefinitions.add(_NodeDefinition(
        type: PathNodeType.lesson,
        title: '${category.emoji} Lesson $lessonNum',
        xp: 20,
      ));
    }
    nodeDefinitions.add(const _NodeDefinition(type: PathNodeType.quiz, title: 'Quiz 2', xp: 30));

    // Block 3: 6 lessons + flashcard + quiz
    for (int j = 0; j < 6; j++) {
      lessonNum++;
      nodeDefinitions.add(_NodeDefinition(
        type: PathNodeType.lesson,
        title: '${category.emoji} Lesson $lessonNum',
        xp: 20,
      ));
    }
    nodeDefinitions.add(const _NodeDefinition(type: PathNodeType.flashcard, title: 'Review Cards', xp: 15));
    nodeDefinitions.add(const _NodeDefinition(type: PathNodeType.quiz, title: 'Final Quiz', xp: 40));

    // AI Coach at the end
    nodeDefinitions.add(const _NodeDefinition(type: PathNodeType.aiCoach, title: 'AI Coach', xp: 25));

    for (int i = 0; i < nodeDefinitions.length; i++) {
      final nodeDef = nodeDefinitions[i];
      final status = _getNodeStatus(unitIndex, i);
      final globalNodeIndex = unitIndex * _nodesPerUnit + i;

      // Zigzag offset: alternate left and right
      final offset = (globalNodeIndex % 2 == 0) ? -40.0 : 40.0;

      // Connector before each node (except the first node of the first unit)
      if (i > 0 || unitIndex > 0) {
        final prevStatus = i > 0
            ? _getNodeStatus(unitIndex, i - 1)
            : _getNodeStatus(unitIndex - 1, _nodesPerUnit - 1);
        final connectorCompleted =
            prevStatus == PathNodeStatus.completed;

        nodes.add(
          LearningPathConnector(
            isCompleted: connectorCompleted,
            isLeft: globalNodeIndex % 2 == 0,
            connectorIndex: globalNodeIndex,
          ),
        );
      }

      // Node with horizontal offset
      nodes.add(
        Transform.translate(
          offset: Offset(offset, 0),
          child: Center(
            child: LearningPathNode(
              type: nodeDef.type,
              status: status,
              title: nodeDef.title,
              xpReward: nodeDef.xp,
              nodeIndex: globalNodeIndex,
              onTap: status != PathNodeStatus.locked
                  ? () => _onNodeTap(nodeDef.type, unitIndex, i)
                  : null,
            ),
          ),
        ),
      );
    }

    return nodes;
  }

  // XP level calculation helpers
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

  int _xpForLevel(int level) {
    switch (level) {
      case 1:
        return 0;
      case 2:
        return 500;
      case 3:
        return 1500;
      case 4:
        return 3500;
      case 5:
        return 7000;
      case 6:
        return 12000;
      case 7:
        return 20000;
      case 8:
        return 35000;
      default:
        return level > 8 ? 35000 + (level - 8) * 10000 : 0;
    }
  }
}

/// Internal data class for node definitions within a unit.
class _NodeDefinition {
  final PathNodeType type;
  final String title;
  final int xp;

  const _NodeDefinition({
    required this.type,
    required this.title,
    required this.xp,
  });
}

/// Subtle floating particles background for the learning path.
class _FloatingParticlesPainter extends CustomPainter {
  final double progress;

  _FloatingParticlesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42); // Deterministic seed for stable positions
    const particleCount = 30;

    for (int i = 0; i < particleCount; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble() * 2 * pi;
      final radius = 1.0 + rng.nextDouble() * 2.0;

      // Gentle floating motion
      final x = baseX + sin(progress * 2 * pi * speed + phase) * 15;
      final y = baseY + cos(progress * 2 * pi * speed * 0.7 + phase) * 10;

      final opacity = 0.05 + sin(progress * 2 * pi * speed + phase).abs() * 0.08;
      final paint = Paint()
        ..color = AppColors.richGold.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
