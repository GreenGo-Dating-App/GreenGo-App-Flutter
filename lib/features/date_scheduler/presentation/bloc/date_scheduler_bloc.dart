import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/scheduled_date.dart';
import '../../domain/usecases/date_scheduler_usecases.dart';

// Events
abstract class DateSchedulerEvent extends Equatable {
  const DateSchedulerEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserDates extends DateSchedulerEvent {
  const LoadUserDates(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class LoadUpcomingDates extends DateSchedulerEvent {
  const LoadUpcomingDates(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class CreateDateEvent extends DateSchedulerEvent {

  const CreateDateEvent({
    required this.matchId,
    required this.creatorId,
    required this.partnerId,
    required this.title,
    required this.scheduledAt,
    this.venueName,
    this.venueAddress,
    this.venueLat,
    this.venueLng,
    this.venueId,
    this.notes,
  });
  final String matchId;
  final String creatorId;
  final String partnerId;
  final String title;
  final DateTime scheduledAt;
  final String? venueName;
  final String? venueAddress;
  final double? venueLat;
  final double? venueLng;
  final String? venueId;
  final String? notes;

  @override
  List<Object?> get props => [
        matchId,
        creatorId,
        partnerId,
        title,
        scheduledAt,
        venueName,
        venueAddress,
        venueLat,
        venueLng,
        venueId,
        notes,
      ];
}

class ConfirmDateEvent extends DateSchedulerEvent {
  const ConfirmDateEvent(this.dateId);
  final String dateId;

  @override
  List<Object?> get props => [dateId];
}

class CancelDateEvent extends DateSchedulerEvent {

  const CancelDateEvent({
    required this.dateId,
    required this.userId,
    this.reason,
  });
  final String dateId;
  final String userId;
  final String? reason;

  @override
  List<Object?> get props => [dateId, userId, reason];
}

class RescheduleDateEvent extends DateSchedulerEvent {

  const RescheduleDateEvent({
    required this.dateId,
    required this.newScheduledAt,
  });
  final String dateId;
  final DateTime newScheduledAt;

  @override
  List<Object?> get props => [dateId, newScheduledAt];
}

class LoadVenueSuggestions extends DateSchedulerEvent {

  const LoadVenueSuggestions({
    required this.lat,
    required this.lng,
    this.category,
    this.radiusKm = 5,
  });
  final double lat;
  final double lng;
  final VenueCategory? category;
  final double radiusKm;

  @override
  List<Object?> get props => [lat, lng, category, radiusKm];
}

class SelectVenue extends DateSchedulerEvent {
  const SelectVenue(this.venue);
  final VenueSuggestion venue;

  @override
  List<Object?> get props => [venue];
}

// States
abstract class DateSchedulerState extends Equatable {
  const DateSchedulerState();

  @override
  List<Object?> get props => [];
}

class DateSchedulerInitial extends DateSchedulerState {
  const DateSchedulerInitial();
}

class DateSchedulerLoading extends DateSchedulerState {
  const DateSchedulerLoading();
}

class DateSchedulerError extends DateSchedulerState {
  const DateSchedulerError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class UserDatesLoaded extends DateSchedulerState {

  UserDatesLoaded({required this.dates})
      : upcoming = dates
            .where((d) => d.isUpcoming)
            .toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)),
        pending = dates
            .where((d) => d.status == DateStatus.pending)
            .toList(),
        past = dates
            .where((d) => d.isPast && d.status != DateStatus.pending)
            .toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  final List<ScheduledDate> dates;
  final List<ScheduledDate> upcoming;
  final List<ScheduledDate> pending;
  final List<ScheduledDate> past;

  @override
  List<Object?> get props => [dates, upcoming, pending, past];
}

class DateCreated extends DateSchedulerState {
  const DateCreated(this.date);
  final ScheduledDate date;

  @override
  List<Object?> get props => [date];
}

class DateConfirmed extends DateSchedulerState {
  const DateConfirmed(this.date);
  final ScheduledDate date;

  @override
  List<Object?> get props => [date];
}

class DateCancelled extends DateSchedulerState {
  const DateCancelled(this.date);
  final ScheduledDate date;

  @override
  List<Object?> get props => [date];
}

class DateRescheduled extends DateSchedulerState {
  const DateRescheduled(this.date);
  final ScheduledDate date;

  @override
  List<Object?> get props => [date];
}

class VenueSuggestionsLoaded extends DateSchedulerState {

  const VenueSuggestionsLoaded({
    required this.venues,
    this.selectedVenue,
  });
  final List<VenueSuggestion> venues;
  final VenueSuggestion? selectedVenue;

  @override
  List<Object?> get props => [venues, selectedVenue];
}

// BLoC
class DateSchedulerBloc extends Bloc<DateSchedulerEvent, DateSchedulerState> {

  DateSchedulerBloc({
    required this.createScheduledDate,
    required this.getUserDates,
    required this.getUpcomingDates,
    required this.confirmDate,
    required this.cancelDate,
    required this.rescheduleDate,
    required this.getVenueSuggestions,
  }) : super(const DateSchedulerInitial()) {
    on<LoadUserDates>(_onLoadUserDates);
    on<LoadUpcomingDates>(_onLoadUpcomingDates);
    on<CreateDateEvent>(_onCreateDate);
    on<ConfirmDateEvent>(_onConfirmDate);
    on<CancelDateEvent>(_onCancelDate);
    on<RescheduleDateEvent>(_onRescheduleDate);
    on<LoadVenueSuggestions>(_onLoadVenueSuggestions);
    on<SelectVenue>(_onSelectVenue);
  }
  final CreateScheduledDate createScheduledDate;
  final GetUserDates getUserDates;
  final GetUpcomingDates getUpcomingDates;
  final ConfirmDate confirmDate;
  final CancelDate cancelDate;
  final RescheduleDate rescheduleDate;
  final GetVenueSuggestions getVenueSuggestions;

  List<ScheduledDate> _datesCache = [];
  List<VenueSuggestion> _venuesCache = [];
  VenueSuggestion? _selectedVenue;

  Future<void> _onLoadUserDates(
    LoadUserDates event,
    Emitter<DateSchedulerState> emit,
  ) async {
    emit(const DateSchedulerLoading());

    final result = await getUserDates(event.userId);

    result.fold(
      (failure) => emit(DateSchedulerError(failure.toString())),
      (dates) {
        _datesCache = dates;
        emit(UserDatesLoaded(dates: dates));
      },
    );
  }

  Future<void> _onLoadUpcomingDates(
    LoadUpcomingDates event,
    Emitter<DateSchedulerState> emit,
  ) async {
    emit(const DateSchedulerLoading());

    final result = await getUpcomingDates(event.userId);

    result.fold(
      (failure) => emit(DateSchedulerError(failure.toString())),
      (dates) {
        _datesCache = dates;
        emit(UserDatesLoaded(dates: dates));
      },
    );
  }

  Future<void> _onCreateDate(
    CreateDateEvent event,
    Emitter<DateSchedulerState> emit,
  ) async {
    emit(const DateSchedulerLoading());

    final result = await createScheduledDate(
      matchId: event.matchId,
      creatorId: event.creatorId,
      partnerId: event.partnerId,
      title: event.title,
      scheduledAt: event.scheduledAt,
      venueName: event.venueName,
      venueAddress: event.venueAddress,
      venueLat: event.venueLat,
      venueLng: event.venueLng,
      venueId: event.venueId,
      notes: event.notes,
    );

    result.fold(
      (failure) => emit(DateSchedulerError(failure.toString())),
      (date) {
        _datesCache.add(date);
        emit(DateCreated(date));
      },
    );
  }

  Future<void> _onConfirmDate(
    ConfirmDateEvent event,
    Emitter<DateSchedulerState> emit,
  ) async {
    final result = await confirmDate(event.dateId);

    result.fold(
      (failure) => emit(DateSchedulerError(failure.toString())),
      (date) {
        _updateDateInCache(date);
        emit(DateConfirmed(date));
      },
    );
  }

  Future<void> _onCancelDate(
    CancelDateEvent event,
    Emitter<DateSchedulerState> emit,
  ) async {
    final result = await cancelDate(
      dateId: event.dateId,
      userId: event.userId,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(DateSchedulerError(failure.toString())),
      (date) {
        _updateDateInCache(date);
        emit(DateCancelled(date));
      },
    );
  }

  Future<void> _onRescheduleDate(
    RescheduleDateEvent event,
    Emitter<DateSchedulerState> emit,
  ) async {
    final result = await rescheduleDate(
      dateId: event.dateId,
      newScheduledAt: event.newScheduledAt,
    );

    result.fold(
      (failure) => emit(DateSchedulerError(failure.toString())),
      (date) {
        _updateDateInCache(date);
        emit(DateRescheduled(date));
      },
    );
  }

  Future<void> _onLoadVenueSuggestions(
    LoadVenueSuggestions event,
    Emitter<DateSchedulerState> emit,
  ) async {
    emit(const DateSchedulerLoading());

    final result = await getVenueSuggestions(
      lat: event.lat,
      lng: event.lng,
      category: event.category,
      radiusKm: event.radiusKm,
    );

    result.fold(
      (failure) => emit(DateSchedulerError(failure.toString())),
      (venues) {
        _venuesCache = venues;
        emit(VenueSuggestionsLoaded(
          venues: venues,
          selectedVenue: _selectedVenue,
        ));
      },
    );
  }

  void _onSelectVenue(
    SelectVenue event,
    Emitter<DateSchedulerState> emit,
  ) {
    _selectedVenue = event.venue;
    emit(VenueSuggestionsLoaded(
      venues: _venuesCache,
      selectedVenue: event.venue,
    ));
  }

  void _updateDateInCache(ScheduledDate date) {
    final index = _datesCache.indexWhere((d) => d.id == date.id);
    if (index >= 0) {
      _datesCache[index] = date;
    }
  }
}
