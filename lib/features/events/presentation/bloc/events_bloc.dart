import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/events_repository.dart';
import 'events_event.dart';
import 'events_state.dart';

/// Events BLoC
///
/// Manages events loading, filtering, RSVP, and CRUD operations.
/// Uses EventsRepository (Either<Failure, T>) for all data operations.
class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final EventsRepository repository;

  // Cache the full events list for client-side filtering
  List<Event> _allEvents = [];
  List<Event> _userEvents = [];
  List<Event> _nearbyEvents = [];
  Map<String, List<EventAttendee>> _attendeesMap = {};
  EventCategory? _selectedCategory;

  EventsBloc({required this.repository}) : super(const EventsInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<LoadEventById>(_onLoadEventById);
    on<CreateEvent>(_onCreateEvent);
    on<UpdateEvent>(_onUpdateEvent);
    on<DeleteEvent>(_onDeleteEvent);
    on<RsvpEvent>(_onRsvpEvent);
    on<CancelRsvp>(_onCancelRsvp);
    on<LoadEventAttendees>(_onLoadEventAttendees);
    on<LoadUserEvents>(_onLoadUserEvents);
    on<FilterByCategory>(_onFilterByCategory);
    on<LoadNearbyEvents>(_onLoadNearbyEvents);
  }

  Future<void> _onLoadEvents(
    LoadEvents event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    final result = await repository.getEvents(
      category: event.category,
      city: event.city,
      upcoming: event.upcoming,
    );

    result.fold(
      (failure) {
        debugPrint('Failed to load events: ${failure.message}');
        emit(EventsError(failure.message));
      },
      (events) {
        _allEvents = events;
        _selectedCategory = null;
        debugPrint('Events loaded: ${events.length}');
        emit(EventsLoaded(
          events: _allEvents,
          selectedCategory: _selectedCategory,
          attendeesMap: _attendeesMap,
          userEvents: _userEvents,
          nearbyEvents: _nearbyEvents,
        ));
      },
    );
  }

  Future<void> _onLoadEventById(
    LoadEventById event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    final result = await repository.getEventById(event.eventId);

    result.fold(
      (failure) {
        debugPrint('Failed to load event: ${failure.message}');
        emit(EventsError(failure.message));
      },
      (loadedEvent) {
        if (loadedEvent == null) {
          emit(const EventsError('Event not found'));
        } else {
          final attendees = _attendeesMap[event.eventId] ?? [];
          emit(EventDetailLoaded(
            event: loadedEvent,
            attendees: attendees,
          ));
        }
      },
    );
  }

  Future<void> _onCreateEvent(
    CreateEvent event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    final result = await repository.createEvent(event.event);

    result.fold(
      (failure) {
        debugPrint('Failed to create event: ${failure.message}');
        emit(EventsError(failure.message));
      },
      (eventId) {
        debugPrint('Event created: $eventId');
        emit(EventCreated(eventId: eventId));
      },
    );
  }

  Future<void> _onUpdateEvent(
    UpdateEvent event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    final result = await repository.updateEvent(event.event);

    result.fold(
      (failure) {
        debugPrint('Failed to update event: ${failure.message}');
        emit(EventsError(failure.message));
      },
      (_) {
        // Update local cache
        final index = _allEvents.indexWhere((e) => e.id == event.event.id);
        if (index >= 0) {
          _allEvents[index] = event.event;
        }
        emit(EventsLoaded(
          events: _allEvents,
          selectedCategory: _selectedCategory,
          attendeesMap: _attendeesMap,
          userEvents: _userEvents,
          nearbyEvents: _nearbyEvents,
        ));
      },
    );
  }

  Future<void> _onDeleteEvent(
    DeleteEvent event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    final result = await repository.deleteEvent(event.eventId);

    result.fold(
      (failure) {
        debugPrint('Failed to delete event: ${failure.message}');
        emit(EventsError(failure.message));
      },
      (_) {
        _allEvents.removeWhere((e) => e.id == event.eventId);
        _userEvents.removeWhere((e) => e.id == event.eventId);
        _nearbyEvents.removeWhere((e) => e.id == event.eventId);
        _attendeesMap.remove(event.eventId);
        emit(EventDeleted(eventId: event.eventId));
      },
    );
  }

  Future<void> _onRsvpEvent(
    RsvpEvent event,
    Emitter<EventsState> emit,
  ) async {
    final result = await repository.rsvpEvent(
      event.eventId,
      event.userId,
      event.status,
    );

    result.fold(
      (failure) {
        debugPrint('Failed to RSVP: ${failure.message}');
        emit(EventsError(failure.message));
      },
      (_) {
        debugPrint('RSVP success: ${event.eventId} (${event.status})');
        emit(EventRsvpSuccess(
          eventId: event.eventId,
          status: event.status,
        ));
        // Re-emit loaded state so the UI can refresh
        emit(EventsLoaded(
          events: _allEvents,
          selectedCategory: _selectedCategory,
          attendeesMap: _attendeesMap,
          userEvents: _userEvents,
          nearbyEvents: _nearbyEvents,
        ));
      },
    );
  }

  Future<void> _onCancelRsvp(
    CancelRsvp event,
    Emitter<EventsState> emit,
  ) async {
    final result = await repository.cancelRsvp(
      event.eventId,
      event.userId,
    );

    result.fold(
      (failure) {
        debugPrint('Failed to cancel RSVP: ${failure.message}');
        emit(EventsError(failure.message));
      },
      (_) {
        debugPrint('RSVP cancelled: ${event.eventId}');
        emit(EventRsvpSuccess(
          eventId: event.eventId,
          status: 'cancelled',
        ));
        emit(EventsLoaded(
          events: _allEvents,
          selectedCategory: _selectedCategory,
          attendeesMap: _attendeesMap,
          userEvents: _userEvents,
          nearbyEvents: _nearbyEvents,
        ));
      },
    );
  }

  Future<void> _onLoadEventAttendees(
    LoadEventAttendees event,
    Emitter<EventsState> emit,
  ) async {
    final result = await repository.getEventAttendees(event.eventId);

    result.fold(
      (failure) {
        debugPrint('Failed to load attendees: ${failure.message}');
      },
      (attendees) {
        _attendeesMap = Map.from(_attendeesMap);
        _attendeesMap[event.eventId] = attendees;

        // If we are in a loaded state, re-emit with updated attendees map
        if (state is EventsLoaded) {
          emit((state as EventsLoaded).copyWith(
            attendeesMap: _attendeesMap,
          ));
        } else {
          emit(EventDetailLoaded(
            event: _allEvents.firstWhere(
              (e) => e.id == event.eventId,
              orElse: () => _allEvents.first,
            ),
            attendees: attendees,
          ));
        }
      },
    );
  }

  Future<void> _onLoadUserEvents(
    LoadUserEvents event,
    Emitter<EventsState> emit,
  ) async {
    final result = await repository.getUserEvents(event.userId);

    result.fold(
      (failure) {
        debugPrint('Failed to load user events: ${failure.message}');
      },
      (events) {
        _userEvents = events;
        if (state is EventsLoaded) {
          emit((state as EventsLoaded).copyWith(userEvents: _userEvents));
        } else {
          emit(EventsLoaded(
            events: _allEvents,
            selectedCategory: _selectedCategory,
            attendeesMap: _attendeesMap,
            userEvents: _userEvents,
            nearbyEvents: _nearbyEvents,
          ));
        }
      },
    );
  }

  void _onFilterByCategory(
    FilterByCategory event,
    Emitter<EventsState> emit,
  ) {
    _selectedCategory = event.category;

    if (state is EventsLoaded) {
      emit((state as EventsLoaded).copyWith(
        selectedCategory: _selectedCategory,
        clearCategory: _selectedCategory == null,
      ));
    } else {
      emit(EventsLoaded(
        events: _allEvents,
        selectedCategory: _selectedCategory,
        attendeesMap: _attendeesMap,
        userEvents: _userEvents,
        nearbyEvents: _nearbyEvents,
      ));
    }
  }

  Future<void> _onLoadNearbyEvents(
    LoadNearbyEvents event,
    Emitter<EventsState> emit,
  ) async {
    final result = await repository.getEventsNearLocation(
      event.latitude,
      event.longitude,
      event.radiusKm,
    );

    result.fold(
      (failure) {
        debugPrint('Failed to load nearby events: ${failure.message}');
      },
      (events) {
        _nearbyEvents = events;
        if (state is EventsLoaded) {
          emit((state as EventsLoaded).copyWith(nearbyEvents: _nearbyEvents));
        } else {
          emit(EventsLoaded(
            events: _allEvents,
            selectedCategory: _selectedCategory,
            attendeesMap: _attendeesMap,
            userEvents: _userEvents,
            nearbyEvents: _nearbyEvents,
          ));
        }
      },
    );
  }
}
