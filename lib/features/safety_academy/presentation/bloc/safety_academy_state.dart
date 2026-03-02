import 'package:equatable/equatable.dart';

import '../../domain/entities/safety_lesson.dart';
import '../../domain/entities/safety_module.dart';
import '../../domain/entities/safety_progress.dart';

/// State for the Safety Academy BLoC
class SafetyAcademyState extends Equatable {
  /// All available safety modules
  final List<SafetyModule> modules;

  /// Lessons for the currently viewed module
  final List<SafetyLesson> currentLessons;

  /// Current user's progress through the academy
  final SafetyProgress? progress;

  /// Whether modules are currently loading
  final bool isLoadingModules;

  /// Whether lessons are currently loading
  final bool isLoadingLessons;

  /// Whether progress is currently loading
  final bool isLoadingProgress;

  /// Error message, if any
  final String? errorMessage;

  /// Success message for UI feedback
  final String? successMessage;

  /// Whether a lesson was just completed (for UI feedback)
  final bool lessonCompleted;

  /// Whether a module was just completed (for UI feedback)
  final bool moduleCompleted;

  const SafetyAcademyState({
    this.modules = const [],
    this.currentLessons = const [],
    this.progress,
    this.isLoadingModules = false,
    this.isLoadingLessons = false,
    this.isLoadingProgress = false,
    this.errorMessage,
    this.successMessage,
    this.lessonCompleted = false,
    this.moduleCompleted = false,
  });

  factory SafetyAcademyState.initial() => const SafetyAcademyState();

  SafetyAcademyState copyWith({
    List<SafetyModule>? modules,
    List<SafetyLesson>? currentLessons,
    SafetyProgress? progress,
    bool? isLoadingModules,
    bool? isLoadingLessons,
    bool? isLoadingProgress,
    String? errorMessage,
    String? successMessage,
    bool? lessonCompleted,
    bool? moduleCompleted,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SafetyAcademyState(
      modules: modules ?? this.modules,
      currentLessons: currentLessons ?? this.currentLessons,
      progress: progress ?? this.progress,
      isLoadingModules: isLoadingModules ?? this.isLoadingModules,
      isLoadingLessons: isLoadingLessons ?? this.isLoadingLessons,
      isLoadingProgress: isLoadingProgress ?? this.isLoadingProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      lessonCompleted: lessonCompleted ?? this.lessonCompleted,
      moduleCompleted: moduleCompleted ?? this.moduleCompleted,
    );
  }

  @override
  List<Object?> get props => [
        modules,
        currentLessons,
        progress,
        isLoadingModules,
        isLoadingLessons,
        isLoadingProgress,
        errorMessage,
        successMessage,
        lessonCompleted,
        moduleCompleted,
      ];
}
