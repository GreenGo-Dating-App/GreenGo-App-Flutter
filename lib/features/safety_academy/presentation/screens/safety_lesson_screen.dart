import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/safety_lesson.dart';
import '../../domain/entities/safety_module.dart';
import '../bloc/safety_academy_bloc.dart';
import '../bloc/safety_academy_event.dart';
import '../bloc/safety_academy_state.dart';
import 'safety_quiz_screen.dart';

/// Screen for displaying lessons within a safety module.
///
/// Shows a list of lessons; tapping one expands into scrollable content
/// with text, tips, warnings, and checklists. Includes quiz navigation
/// and lesson completion tracking.
class SafetyLessonScreen extends StatefulWidget {
  final String userId;
  final SafetyModule module;

  const SafetyLessonScreen({
    super.key,
    required this.userId,
    required this.module,
  });

  @override
  State<SafetyLessonScreen> createState() => _SafetyLessonScreenState();
}

class _SafetyLessonScreenState extends State<SafetyLessonScreen> {
  int? _selectedLessonIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(
          widget.module.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<SafetyAcademyBloc, SafetyAcademyState>(
        listener: (context, state) {
          if (state.lessonCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lesson completed!'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoadingLessons) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            );
          }

          final lessons = state.currentLessons;
          if (lessons.isEmpty) {
            return const Center(
              child: Text(
                'No lessons available yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          // Progress bar
          final completedCount = state.progress != null
              ? lessons
                  .where((l) => state.progress!.isLessonCompleted(l.id))
                  .length
              : 0;
          final progressFraction =
              lessons.isEmpty ? 0.0 : completedCount / lessons.length;

          return Column(
            children: [
              // Progress indicator
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completedCount / ${lessons.length} lessons',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${(progressFraction * 100).toInt()}%',
                          style: const TextStyle(
                            color: AppColors.richGold,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressFraction,
                        backgroundColor: AppColors.backgroundInput,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.richGold,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Lessons list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    final isCompleted =
                        state.progress?.isLessonCompleted(lesson.id) ?? false;
                    final isSelected = _selectedLessonIndex == index;

                    return _buildLessonTile(
                      context,
                      lesson: lesson,
                      index: index,
                      isCompleted: isCompleted,
                      isSelected: isSelected,
                      state: state,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLessonTile(
    BuildContext context, {
    required SafetyLesson lesson,
    required int index,
    required bool isCompleted,
    required bool isSelected,
    required SafetyAcademyState state,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppColors.richGold, width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          // Lesson header (always visible)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.successGreen.withValues(alpha: 0.2)
                    : AppColors.backgroundInput,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check,
                        color: AppColors.successGreen, size: 20)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            title: Text(
              lesson.title,
              style: TextStyle(
                color: isCompleted
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                decoration:
                    isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              '+${lesson.xpReward} XP${lesson.quiz != null ? ' | Quiz' : ''}',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            trailing: Icon(
              isSelected
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: AppColors.textTertiary,
            ),
            onTap: () {
              setState(() {
                _selectedLessonIndex = isSelected ? null : index;
              });
            },
          ),

          // Expanded lesson content
          if (isSelected) _buildLessonContent(context, lesson, state),
        ],
      ),
    );
  }

  Widget _buildLessonContent(
    BuildContext context,
    SafetyLesson lesson,
    SafetyAcademyState state,
  ) {
    final isCompleted =
        state.progress?.isLessonCompleted(lesson.id) ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.divider),
          const SizedBox(height: 8),

          // Content sections
          ...lesson.contentSections
              .map((section) => _buildContentSection(section)),

          const SizedBox(height: 16),

          // Quiz button if available
          if (lesson.quiz != null && !isCompleted)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToQuiz(context, lesson),
                  icon: const Icon(Icons.quiz, size: 18),
                  label: const Text('Take Quiz'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.richGold,
                    side: const BorderSide(color: AppColors.richGold),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),

          // Complete lesson button
          if (!isCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<SafetyAcademyBloc>().add(
                        CompleteLesson(
                          userId: widget.userId,
                          lessonId: lesson.id,
                        ),
                      );

                  // Check if all lessons in module are now completed
                  _checkModuleCompletion(context, lesson.id, state);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Complete Lesson',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

          if (isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle,
                      color: AppColors.successGreen, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Completed',
                    style: TextStyle(
                      color: AppColors.successGreen,
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

  Widget _buildContentSection(LessonContent section) {
    switch (section.type) {
      case LessonContentType.text:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            section.content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        );

      case LessonContentType.tip:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.infoBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.infoBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.infoBlue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.content,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );

      case LessonContentType.warning:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningAmber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.warningAmber.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warningAmber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.content,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );

      case LessonContentType.checklist:
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundInput,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (section.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    section.content,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ...section.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_box_outline_blank,
                            color: AppColors.textTertiary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
    }
  }

  void _navigateToQuiz(BuildContext context, SafetyLesson lesson) {
    if (lesson.quiz == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SafetyQuizScreen(
          userId: widget.userId,
          lesson: lesson,
          quiz: lesson.quiz!,
          onComplete: (score) {
            context.read<SafetyAcademyBloc>().add(
                  CompleteLesson(
                    userId: widget.userId,
                    lessonId: lesson.id,
                    quizScore: score,
                  ),
                );
          },
        ),
      ),
    );
  }

  void _checkModuleCompletion(
    BuildContext context,
    String completedLessonId,
    SafetyAcademyState state,
  ) {
    final lessons = state.currentLessons;
    final progress = state.progress;
    if (progress == null) return;

    // Count completed lessons including the one just completed
    final completedIds = {...progress.completedLessons, completedLessonId};
    final allLessonIds = lessons.map((l) => l.id).toSet();
    final allDone = allLessonIds.every((id) => completedIds.contains(id));

    if (allDone) {
      context.read<SafetyAcademyBloc>().add(
            CompleteModule(
              userId: widget.userId,
              moduleId: widget.module.id,
            ),
          );
    }
  }
}
