import 'package:equatable/equatable.dart';

/// Base event class for the Safety Academy BLoC
sealed class SafetyAcademyEvent extends Equatable {
  const SafetyAcademyEvent();

  @override
  List<Object?> get props => [];
}

/// Load all safety modules for the academy home screen
class LoadModules extends SafetyAcademyEvent {
  const LoadModules();
}

/// Load lessons for a specific module
class LoadLessons extends SafetyAcademyEvent {
  final String moduleId;

  const LoadLessons(this.moduleId);

  @override
  List<Object?> get props => [moduleId];
}

/// Load the current user's progress
class LoadProgress extends SafetyAcademyEvent {
  final String userId;

  const LoadProgress(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Mark a lesson as completed, optionally with a quiz score
class CompleteLesson extends SafetyAcademyEvent {
  final String userId;
  final String lessonId;
  final int? quizScore;

  const CompleteLesson({
    required this.userId,
    required this.lessonId,
    this.quizScore,
  });

  @override
  List<Object?> get props => [userId, lessonId, quizScore];
}

/// Mark a module as completed (all lessons finished)
class CompleteModule extends SafetyAcademyEvent {
  final String userId;
  final String moduleId;

  const CompleteModule({
    required this.userId,
    required this.moduleId,
  });

  @override
  List<Object?> get props => [userId, moduleId];
}
