import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_experience.dart';
import '../../domain/repositories/user_experiences_repository.dart';

abstract class ExperienceDetailEvent extends Equatable {
  const ExperienceDetailEvent();
  @override
  List<Object?> get props => [];
}

/// Load by id; [initial] paints immediately (e.g. the card the user tapped)
/// while the fresh document is fetched.
class ExperienceDetailRequested extends ExperienceDetailEvent {
  const ExperienceDetailRequested(this.id, {this.initial});
  final String id;
  final UserExperience? initial;
  @override
  List<Object?> get props => [id, initial];
}

class ExperienceDetailStatusChanged extends ExperienceDetailEvent {
  const ExperienceDetailStatusChanged(this.status);
  final ExperienceStatus status;
  @override
  List<Object?> get props => [status];
}

class ExperienceDetailDeleted extends ExperienceDetailEvent {
  const ExperienceDetailDeleted();
}

class ExperienceDetailReported extends ExperienceDetailEvent {
  const ExperienceDetailReported(this.reporterId);
  final String reporterId;
  @override
  List<Object?> get props => [reporterId];
}

/// One-shot outcome the screen reacts to (snackbar / pop).
enum ExperienceDetailAction { none, statusChanged, deleted, reported, failed }

enum ExperienceDetailLoad { loading, ready, notFound, failure }

class ExperienceDetailState extends Equatable {
  const ExperienceDetailState({
    this.load = ExperienceDetailLoad.loading,
    this.experience,
    this.busy = false,
    this.action = ExperienceDetailAction.none,
    this.actionSeq = 0,
  });

  final ExperienceDetailLoad load;
  final UserExperience? experience;
  final bool busy;
  final ExperienceDetailAction action;

  /// Bumped per action so identical consecutive actions still notify.
  final int actionSeq;

  ExperienceDetailState copyWith({
    ExperienceDetailLoad? load,
    UserExperience? experience,
    bool? busy,
    ExperienceDetailAction? action,
  }) =>
      ExperienceDetailState(
        load: load ?? this.load,
        experience: experience ?? this.experience,
        busy: busy ?? this.busy,
        action: action ?? ExperienceDetailAction.none,
        actionSeq: action != null ? actionSeq + 1 : actionSeq,
      );

  @override
  List<Object?> get props => [load, experience, busy, action, actionSeq];
}

class ExperienceDetailBloc
    extends Bloc<ExperienceDetailEvent, ExperienceDetailState> {
  ExperienceDetailBloc({required UserExperiencesRepository repository})
      : _repo = repository,
        super(const ExperienceDetailState()) {
    on<ExperienceDetailRequested>(_onRequested);
    on<ExperienceDetailStatusChanged>(_onStatus);
    on<ExperienceDetailDeleted>(_onDeleted);
    on<ExperienceDetailReported>(_onReported);
  }

  final UserExperiencesRepository _repo;

  Future<void> _onRequested(ExperienceDetailRequested e,
      Emitter<ExperienceDetailState> emit) async {
    if (e.initial != null) {
      emit(ExperienceDetailState(
          load: ExperienceDetailLoad.ready, experience: e.initial));
    }
    final r = await _repo.getExperience(e.id);
    r.fold(
      (_) {
        if (state.experience == null) {
          emit(state.copyWith(load: ExperienceDetailLoad.failure));
        }
      },
      (x) => emit(x == null
          ? const ExperienceDetailState(load: ExperienceDetailLoad.notFound)
          : state.copyWith(load: ExperienceDetailLoad.ready, experience: x)),
    );
  }

  Future<void> _onStatus(ExperienceDetailStatusChanged e,
      Emitter<ExperienceDetailState> emit) async {
    final x = state.experience;
    if (x == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final r = await _repo.setStatus(x.id, e.status);
    r.fold(
      (_) => emit(state.copyWith(
          busy: false, action: ExperienceDetailAction.failed)),
      (_) => emit(state.copyWith(
        busy: false,
        experience: x.copyWith(status: e.status),
        action: ExperienceDetailAction.statusChanged,
      )),
    );
  }

  Future<void> _onDeleted(
      ExperienceDetailDeleted e, Emitter<ExperienceDetailState> emit) async {
    final x = state.experience;
    if (x == null || state.busy) return;
    emit(state.copyWith(busy: true));
    final r = await _repo.deleteExperience(x.id);
    r.fold(
      (_) => emit(state.copyWith(
          busy: false, action: ExperienceDetailAction.failed)),
      (_) => emit(state.copyWith(
          busy: false, action: ExperienceDetailAction.deleted)),
    );
  }

  Future<void> _onReported(
      ExperienceDetailReported e, Emitter<ExperienceDetailState> emit) async {
    final x = state.experience;
    if (x == null) return;
    final r =
        await _repo.reportExperience(experience: x, reporterId: e.reporterId);
    emit(state.copyWith(
        action: r.isRight()
            ? ExperienceDetailAction.reported
            : ExperienceDetailAction.failed));
  }
}
