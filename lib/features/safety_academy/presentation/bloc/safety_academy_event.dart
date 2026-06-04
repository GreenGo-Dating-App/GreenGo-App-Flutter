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

  const LoadLessons(this.moduleId);
  final String moduleId;

  @override
  List<Object?> get props => [moduleId];
}

/// Load the current user's progress
class LoadProgress extends SafetyAcademyEvent {

  const LoadProgress(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Mark a lesson as completed, optionally with a quiz score
class CompleteLesson extends SafetyAcademyEvent {

  const CompleteLesson({
    required this.userId,
    required this.lessonId,
    this.quizScore,
  });
  final String userId;
  final String lessonId;
  final int? quizScore;

  @override
  List<Object?> get props => [userId, lessonId, quizScore];
}

/// Mark a module as completed (all lessons finished)
class CompleteModule extends SafetyAcademyEvent {

  const CompleteModule({
    required this.userId,
    required this.moduleId,
  });
  final String userId;
  final String moduleId;

  @override
  List<Object?> get props => [userId, moduleId];
}
