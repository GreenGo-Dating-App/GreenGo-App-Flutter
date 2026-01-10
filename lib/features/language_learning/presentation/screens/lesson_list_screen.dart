import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/entities.dart';
import '../bloc/language_learning_bloc.dart';
import '../widgets/widgets.dart';

class LessonListScreen extends StatefulWidget {
  final String languageCode;
  final String languageName;

  const LessonListScreen({
    super.key,
    required this.languageCode,
    required this.languageName,
  });

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LessonLevel? _selectedLevel;
  LessonCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLessons();
  }

  void _loadLessons() {
    context.read<LanguageLearningBloc>().add(
          LoadLessonsForLanguage(
            languageCode: widget.languageCode,
            level: _selectedLevel,
            category: _selectedCategory,
          ),
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: Text(
          'Learn ${widget.languageName}',
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.pureWhite.withOpacity(0.6),
          tabs: const [
            Tab(text: 'All Lessons'),
            Tab(text: 'My Progress'),
            Tab(text: 'Purchased'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.richGold),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllLessonsTab(),
          _buildProgressTab(),
          _buildPurchasedTab(),
        ],
      ),
    );
  }

  Widget _buildAllLessonsTab() {
    return BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
      builder: (context, state) {
        if (state.isLessonsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.richGold),
          );
        }

        if (state.lessonsError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.errorRed, size: 48),
                const SizedBox(height: 16),
                Text(
                  state.lessonsError!,
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadLessons,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final lessons = state.lessons;
        if (lessons.isEmpty) {
          return _buildEmptyState('No lessons available yet');
        }

        // Group lessons by week
        final lessonsByWeek = <int, List<Lesson>>{};
        for (final lesson in lessons) {
          lessonsByWeek.putIfAbsent(lesson.weekNumber, () => []).add(lesson);
        }

        final sortedWeeks = lessonsByWeek.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedWeeks.length,
          itemBuilder: (context, index) {
            final weekNumber = sortedWeeks[index];
            final weekLessons = lessonsByWeek[weekNumber]!;

            return _buildWeekSection(weekNumber, weekLessons);
          },
        );
      },
    );
  }

  Widget _buildWeekSection(int weekNumber, List<Lesson> lessons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Week $weekNumber',
                  style: const TextStyle(
                    color: AppColors.deepBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppColors.richGold.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
        ...lessons.map((lesson) => _buildLessonCard(lesson)).toList(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    final isLocked = !lesson.isFree &&
        !context.read<LanguageLearningBloc>().isPurchased(lesson.id);

    return GestureDetector(
      onTap: () => _navigateToLesson(lesson),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLocked
                ? AppColors.pureWhite.withOpacity(0.1)
                : AppColors.richGold.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lesson Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isLocked
                    ? null
                    : LinearGradient(
                        colors: [
                          AppColors.richGold.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Day indicator
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? AppColors.pureWhite.withOpacity(0.1)
                          : AppColors.richGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'D${lesson.dayNumber}',
                        style: TextStyle(
                          color: isLocked
                              ? AppColors.pureWhite.withOpacity(0.5)
                              : AppColors.deepBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Lesson info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: const TextStyle(
                            color: AppColors.pureWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.pureWhite.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lock or price indicator
                  if (isLocked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.richGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: AppColors.richGold,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${lesson.coinPrice}',
                            style: const TextStyle(
                              color: AppColors.richGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (lesson.isFree)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'FREE',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Lesson metadata
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.deepBlack.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  _buildMetaItem(
                    Icons.access_time,
                    '${lesson.estimatedMinutes} min',
                  ),
                  const SizedBox(width: 16),
                  _buildMetaItem(
                    Icons.star,
                    '+${lesson.xpReward} XP',
                  ),
                  const SizedBox(width: 16),
                  _buildMetaItem(
                    Icons.signal_cellular_alt,
                    lesson.level.displayName,
                  ),
                  const Spacer(),
                  if (lesson.averageRating > 0)
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.richGold,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lesson.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.richGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppColors.pureWhite.withOpacity(0.5),
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: AppColors.pureWhite.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTab() {
    return BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Overview Card
              _buildProgressOverviewCard(),
              const SizedBox(height: 24),

              // Weekly Goals
              _buildWeeklyGoalsSection(),
              const SizedBox(height: 24),

              // Category Progress
              _buildCategoryProgressSection(),
              const SizedBox(height: 24),

              // Milestones
              _buildMilestonesSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total XP', '2,450', Icons.star),
              _buildStatItem('Lessons', '24', Icons.book),
              _buildStatItem('Streak', '7', Icons.local_fire_department),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Beginner Progress',
                    style: TextStyle(
                      color: AppColors.deepBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    '45%',
                    style: TextStyle(
                      color: AppColors.deepBlack,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.45,
                backgroundColor: AppColors.deepBlack.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.deepBlack,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.deepBlack, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.deepBlack,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.deepBlack.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Goals',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildGoalRow('Complete 5 lessons', 3, 5),
              const SizedBox(height: 12),
              _buildGoalRow('Earn 500 XP', 320, 500),
              const SizedBox(height: 12),
              _buildGoalRow('Practice 30 minutes', 18, 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalRow(String label, int current, int target) {
    final progress = current / target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            Text(
              '$current / $target',
              style: const TextStyle(
                color: AppColors.richGold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: AppColors.pureWhite.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0 ? AppColors.successGreen : AppColors.richGold,
          ),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildCategoryProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category Progress',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LessonCategory.values.take(8).map((category) {
            return _buildCategoryChip(category);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(LessonCategory category) {
    final progress = 0.3 + (category.index * 0.1) % 0.7; // Mock progress
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.richGold.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category.emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Text(
            category.displayName,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              color: AppColors.richGold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Milestones',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildMilestoneItem(
                'First Lesson Completed',
                '+50 XP',
                Icons.school,
                true,
              ),
              const Divider(color: AppColors.pureWhite, height: 24),
              _buildMilestoneItem(
                'Week 1 Master',
                '+100 XP',
                Icons.emoji_events,
                true,
              ),
              const Divider(color: AppColors.pureWhite, height: 24),
              _buildMilestoneItem(
                '7-Day Streak',
                '+150 XP',
                Icons.local_fire_department,
                false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneItem(
    String title,
    String reward,
    IconData icon,
    bool achieved,
  ) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: achieved
                ? AppColors.richGold.withOpacity(0.2)
                : AppColors.pureWhite.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: achieved ? AppColors.richGold : AppColors.pureWhite.withOpacity(0.3),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: achieved
                      ? AppColors.pureWhite
                      : AppColors.pureWhite.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                reward,
                style: TextStyle(
                  color: achieved
                      ? AppColors.richGold
                      : AppColors.pureWhite.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (achieved)
          const Icon(
            Icons.check_circle,
            color: AppColors.successGreen,
            size: 24,
          )
        else
          Icon(
            Icons.lock,
            color: AppColors.pureWhite.withOpacity(0.3),
            size: 20,
          ),
      ],
    );
  }

  Widget _buildPurchasedTab() {
    return BlocBuilder<LanguageLearningBloc, LanguageLearningState>(
      builder: (context, state) {
        // Mock purchased lessons - in real app, filter from state
        return _buildEmptyState(
          'Your purchased lessons will appear here',
          icon: Icons.shopping_bag_outlined,
        );
      },
    );
  }

  Widget _buildEmptyState(String message, {IconData icon = Icons.book_outlined}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.pureWhite.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: AppColors.pureWhite.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.charcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Lessons',
                style: TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Level filter
              const Text(
                'Level',
                style: TextStyle(
                  color: AppColors.richGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(
                    'All Levels',
                    _selectedLevel == null,
                    () => setSheetState(() => _selectedLevel = null),
                  ),
                  ...LessonLevel.values.take(4).map((level) {
                    return _buildFilterChip(
                      level.displayName,
                      _selectedLevel == level,
                      () => setSheetState(() => _selectedLevel = level),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Category filter
              const Text(
                'Category',
                style: TextStyle(
                  color: AppColors.richGold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip(
                    'All Categories',
                    _selectedCategory == null,
                    () => setSheetState(() => _selectedCategory = null),
                  ),
                  ...LessonCategory.values.take(8).map((category) {
                    return _buildFilterChip(
                      '${category.emoji} ${category.displayName}',
                      _selectedCategory == category,
                      () => setSheetState(() => _selectedCategory = category),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadLessons();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.richGold
              : AppColors.pureWhite.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.deepBlack : AppColors.pureWhite,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _navigateToLesson(Lesson lesson) {
    // Navigate to lesson detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(lesson: lesson),
      ),
    );
  }
}

class LessonDetailScreen extends StatelessWidget {
  final Lesson lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.deepBlack,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.richGold.withOpacity(0.3),
                      AppColors.deepBlack,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.richGold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            lesson.category.emoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lesson.description,
                    style: TextStyle(
                      color: AppColors.pureWhite.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lesson info row
                  Row(
                    children: [
                      _buildInfoChip(Icons.access_time, '${lesson.estimatedMinutes} min'),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.star, '+${lesson.xpReward} XP'),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.signal_cellular_alt, lesson.level.displayName),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Objectives
                  if (lesson.objectives.isNotEmpty) ...[
                    const Text(
                      'What you will learn',
                      style: TextStyle(
                        color: AppColors.richGold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...lesson.objectives.map((obj) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.successGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              obj,
                              style: TextStyle(
                                color: AppColors.pureWhite.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 24),
                  ],

                  // Sections
                  const Text(
                    'Lesson Content',
                    style: TextStyle(
                      color: AppColors.richGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...lesson.sections.asMap().entries.map((entry) {
                    final index = entry.key;
                    final section = entry.value;
                    return _buildSectionCard(index + 1, section);
                  }),

                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: lesson.isFree
              ? ElevatedButton(
                  onPressed: () => _startLesson(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Start Lesson',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: () => _purchaseLesson(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Unlock for ${lesson.coinPrice} Coins',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.richGold, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(int number, LessonSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.richGold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  section.type.displayName,
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${section.xpReward} XP',
            style: const TextStyle(
              color: AppColors.richGold,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _startLesson(BuildContext context) {
    // Navigate to lesson player
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting lesson...'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  void _purchaseLesson(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: const Text(
          'Unlock Lesson',
          style: TextStyle(color: AppColors.pureWhite),
        ),
        content: Text(
          'Spend ${lesson.coinPrice} coins to unlock this lesson?',
          style: TextStyle(color: AppColors.pureWhite.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.pureWhite),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<LanguageLearningBloc>().add(
                    PurchaseLessonEvent(lessonId: lesson.id),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
            ),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}
