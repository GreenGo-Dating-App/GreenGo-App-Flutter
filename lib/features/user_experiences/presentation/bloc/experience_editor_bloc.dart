import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_experience.dart';
import '../../domain/repositories/user_experiences_repository.dart';

abstract class ExperienceEditorEvent extends Equatable {
  const ExperienceEditorEvent();
  @override
  List<Object?> get props => [];
}

/// Save [experience] (photos already uploaded). New experiences go through
/// the `createUserExperience` callable (tier limit), edits are direct updates.
class ExperienceEditorSaved extends ExperienceEditorEvent {
  const ExperienceEditorSaved(this.experience, {required this.isNew});
  final UserExperience experience;
  final bool isNew;
  @override
  List<Object?> get props => [experience, isNew];
}

enum ExperienceEditorStatus { idle, saving, saved, failed }

class ExperienceEditorState extends Equatable {
  const ExperienceEditorState({
    this.status = ExperienceEditorStatus.idle,
    this.saved,
    this.failure,
  });

  final ExperienceEditorStatus status;

  /// The stored experience (with its id) after a successful save.
  final UserExperience? saved;
  final Failure? failure;

  @override
  List<Object?> get props => [status, saved, failure];
}

class ExperienceEditorBloc
    extends Bloc<ExperienceEditorEvent, ExperienceEditorState> {
  ExperienceEditorBloc({required UserExperiencesRepository repository})
      : _repo = repository,
        super(const ExperienceEditorState()) {
    on<ExperienceEditorSaved>(_onSaved);
  }

  final UserExperiencesRepository _repo;

  Future<void> _onSaved(
      ExperienceEditorSaved e, Emitter<ExperienceEditorState> emit) async {
    if (state.status == ExperienceEditorStatus.saving) return;
    emit(const ExperienceEditorState(status: ExperienceEditorStatus.saving));
    if (e.isNew) {
      final r = await _repo.createExperience(e.experience);
      r.fold(
        (f) => emit(ExperienceEditorState(
            status: ExperienceEditorStatus.failed, failure: f)),
        (id) => emit(ExperienceEditorState(
          status: ExperienceEditorStatus.saved,
          saved: _withId(e.experience, id),
        )),
      );
      return;
    }
    final r = await _repo.updateExperience(e.experience);
    r.fold(
      (f) => emit(ExperienceEditorState(
          status: ExperienceEditorStatus.failed, failure: f)),
      (_) => emit(ExperienceEditorState(
          status: ExperienceEditorStatus.saved, saved: e.experience)),
    );
  }

  static UserExperience _withId(UserExperience x, String id) => UserExperience(
        id: id,
        hostId: x.hostId,
        hostName: x.hostName,
        hostPhotoUrl: x.hostPhotoUrl,
        title: x.title,
        description: x.description,
        category: x.category,
        mainPhotoUrl: x.mainPhotoUrl,
        photoUrls: x.photoUrls,
        included: x.included,
        notIncluded: x.notIncluded,
        locationName: x.locationName,
        city: x.city,
        country: x.country,
        lat: x.lat,
        lng: x.lng,
        geohash: x.geohash,
        meetingPoint: x.meetingPoint,
        durationMinutes: x.durationMinutes,
        languages: x.languages,
        minGroupSize: x.minGroupSize,
        maxGroupSize: x.maxGroupSize,
        price: x.price,
        currency: x.currency,
        isFree: x.isFree,
        paymentLink: x.paymentLink,
        availability: x.availability,
        cancellationPolicy: x.cancellationPolicy,
        status: x.status,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
