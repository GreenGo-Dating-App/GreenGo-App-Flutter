import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/safety_academy_repository.dart';
import 'safety_academy_event.dart';
import 'safety_academy_state.dart';

/// BLoC for the Safety Academy feature.
///
/// Manages loading modules, lessons, user progress,
/// and lesson/module completion workflows.
class SafetyAcademyBloc
    extends Bloc<SafetyAcademyEvent, SafetyAcademyState> {
  final SafetyAcademyRepository _repository;

  SafetyAcademyBloc({
    required SafetyAcademyRepository repository,
  })  : _repository = repository,
        super(SafetyAcademyState.initial()) {
    on<LoadModules>(_onLoadModules);
    on<LoadLessons>(_onLoadLessons);
    on<LoadProgress>(_onLoadProgress);
    on<CompleteLesson>(_onCompleteLesson);
    on<CompleteModule>(_onCompleteModule);
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  Future<void> _onLoadModules(
    LoadModules event,
    Emitter<SafetyAcademyState> emit,
  ) async {
    emit(state.copyWith(isLoadingModules: true, clearError: true));

    try {
      final modules = await _repository.getModules();
      emit(state.copyWith(
        modules: modules,
        isLoadingModules: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingModules: false,
        errorMessage: 'Failed to load modules: $e',
      ));
    }
  }

  Future<void> _onLoadLessons(
    LoadLessons event,
    Emitter<SafetyAcademyState> emit,
  ) async {
    emit(state.copyWith(isLoadingLessons: true, clearError: true));

    try {
      final lessons = await _repository.getLessonsForModule(event.moduleId);
      emit(state.copyWith(
        currentLessons: lessons,
        isLoadingLessons: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingLessons: false,
        errorMessage: 'Failed to load lessons: $e',
      ));
    }
  }

  Future<void> _onLoadProgress(
    LoadProgress event,
    Emitter<SafetyAcademyState> emit,
  ) async {
    emit(state.copyWith(isLoadingProgress: true, clearError: true));

    try {
      final progress = await _repository.getUserProgress(event.userId);
      emit(state.copyWith(
        progress: progress,
        isLoadingProgress: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingProgress: false,
        errorMessage: 'Failed to load progress: $e',
      ));
    }
  }

  Future<void> _onCompleteLesson(
    CompleteLesson event,
    Emitter<SafetyAcademyState> emit,
  ) async {
    try {
      await _repository.completeLesson(
        event.userId,
        event.lessonId,
        event.quizScore,
      );

      // Reload progress after completion
      final progress = await _repository.getUserProgress(event.userId);

      emit(state.copyWith(
        progress: progress,
        lessonCompleted: true,
        successMessage: 'Lesson completed! XP earned.',
      ));

      // Reset the flag after emitting
      emit(state.copyWith(lessonCompleted: false, clearSuccess: true));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to complete lesson: $e',
      ));
    }
  }

  Future<void> _onCompleteModule(
    CompleteModule event,
    Emitter<SafetyAcademyState> emit,
  ) async {
    try {
      await _repository.completeModule(event.userId, event.moduleId);

      // Reload progress after completion
      final progress = await _repository.getUserProgress(event.userId);

      emit(state.copyWith(
        progress: progress,
        moduleCompleted: true,
        successMessage: 'Module completed! You earned a badge.',
      ));

      // Reset the flag after emitting
      emit(state.copyWith(moduleCompleted: false, clearSuccess: true));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to complete module: $e',
      ));
    }
  }
}
