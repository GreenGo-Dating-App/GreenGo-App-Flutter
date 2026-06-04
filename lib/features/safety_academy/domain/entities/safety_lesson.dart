import 'package:equatable/equatable.dart';

import 'safety_quiz.dart';

/// Content type for lesson sections
enum LessonContentType {
  text,
  tip,
  warning,
  checklist,
}

/// A single section of lesson content
class LessonContent extends Equatable {

  const LessonContent({
    required this.type,
    required this.content,
    this.items = const [],
  });
  final LessonContentType type;
  final String content;
  final List<String> items;

  @override
  List<Object?> get props => [type, content, items];
}

/// Safety Academy Lesson Entity
///
/// Represents a single lesson within a safety module.
/// Contains structured content sections and an optional quiz.
class SafetyLesson extends Equatable {

  const SafetyLesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.contentSections,
    required this.xpReward, required this.order, this.quiz,
  });
  final String id;
  final String moduleId;
  final String title;
  final List<LessonContent> contentSections;
  final SafetyQuiz? quiz;
  final int xpReward;
  final int order;

  @override
  List<Object?> get props => [
        id,
        moduleId,
        title,
        contentSections,
        quiz,
        xpReward,
        order,
      ];
}
