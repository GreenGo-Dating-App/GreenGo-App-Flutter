import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/events_repository.dart';
import 'events_event.dart';
import 'events_state.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

/// Events BLoC
///
/// Manages events loading, filtering, RSVP, and CRUD operations.
/// Uses EventsRepository (Either<Failure, T>) for all data operations.
class EventsBloc extends Bloc<EventsEvent, EventsState> {

  EventsBloc({required this.repository}) : super(const EventsInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<LoadEventById>(_onLoadEventById);
    on<CreateEvent>(_onCreateEvent);
    on<UpdateEvent>(_onUpdateEvent);
    on<DeleteEvent>(_onDeleteEvent);
    on<HideEvent>(_onHideEvent);
    on<RsvpEvent>(_onRsvpEvent);
    on<CancelRsvp>(_onCancelRsvp);
    on<LoadEventAttendees>(_onLoadEventAttendees);
    on<LoadUserEvents>(_onLoadUserEvents);
    on<FilterByCategory>(_onFilterByCategory);
    on<LoadNearbyEvents>(_onLoadNearbyEvents);
  }
  final EventsRepository repository;

  // Cache the full events list for client-side filtering
  List<Event> _allEvents = [];
  List<Event> _userEvents = [];
  List<Event> _nearbyEvents = [];
  Map<String, List<EventAttendee>> _attendeesMap = {};
  EventCategory? _selectedCategory;

  Future<void> _onLoadEvents(
    LoadEvents event,
    Emitter<EventsState> emit,
  ) async {
    // Only a FIRST load shows a loading state; a reload (after RSVP/create,
    // pull-to-refresh) keeps the current list on screen until the new one lands.
    if (_allEvents.isEmpty) emit(const EventsLoading());

    final result = await repository.getEvents(
      category: event.category,
      city: event.city,
      upcoming: event.upcoming,
    );

    result.fold(
      (failure) {
        debugPrint('Failed to load events: ${failure.message}');
        // Don't blank an already-painted list on a server hiccup.
        if (state is! EventsLoaded) emit(EventsError(failure.message));
      },
      (events) {
        _allEvents = events;
        _selectedCategory = null;
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

    // TIME-BOUND. The repository turns every throw into a Left, but a read that
    // never comes back produces neither - and the loader screen shows a
    // spinner for any state that is not loaded-or-error, so an unbounded await
    // is an endless spinner with no way out. On timeout we surface an error the
    // user can retreat from.
    final result = await repository
        .getEventById(event.eventId)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => const Left(ServerFailure('Loading the event timed out')),
        );

    await result.fold(
      (failure) async {
        debugPrint('Failed to load event: ${failure.message}');
        emit(EventsError(failure.message));
      },
      (loadedEvent) async {
        if (loadedEvent == null) {
          emit(const EventsError('Event not found'));
          return;
        }

        // Attendees live in a subcollection and were previously read from
        // `_attendeesMap` - a cache only LoadEventAttendees fills. Opening an
        // event never dispatched that, so the roster was always empty. Fetch
        // them here instead.
        //
        // Deliberately NON-FATAL and shown second: the event itself is what the
        // user asked for, so it is emitted first and the roster fills in after.
        // A slow or failing attendee read must never hold the page hostage -
        // that is the same mistake as the unbounded read above.
        emit(EventDetailLoaded(
          event: loadedEvent,
          attendees: _attendeesMap[event.eventId] ?? const [],
        ));

        final attendeesResult = await repository
            .getEventAttendees(event.eventId)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => const Right(<EventAttendee>[]),
            );
        attendeesResult.fold(
          (failure) => debugPrint('Attendees unavailable: ${failure.message}'),
          (attendees) {
            if (attendees.isEmpty) return;
            _attendeesMap[event.eventId] = attendees;
            if (!emit.isDone) {
              emit(EventDetailLoaded(
                event: loadedEvent,
                attendees: attendees,
              ));
            }
          },
        );
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
    // Optimistic, in-place update — NO full-screen EventsLoading. Edits like
    // "boost/feature" are a small field change; blanking the whole Events screen
    // while the write completes made it look stuck.
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

    // Persist in the background; log on failure (the next reload reconciles).
    final result = await repository.updateEvent(event.event);
    result.fold(
      (failure) => debugPrint('Failed to update event: ${failure.message}'),
      (_) {},
    );
  }

  Future<void> _onDeleteEvent(
    DeleteEvent event,
    Emitter<EventsState> emit,
  ) async {
    // OPTIMISTIC removal: drop the event from every in-memory list and repaint
    // the list IMMEDIATELY (no full-screen EventsLoading, which blanked all the
    // tabs and — because EventDeleted isn't EventsLoaded — left them empty until
    // a manual reload). Persist in the BACKGROUND. Mirrors _onUpdateEvent.
    _allEvents.removeWhere((e) => e.id == event.eventId);
    _userEvents.removeWhere((e) => e.id == event.eventId);
    _nearbyEvents.removeWhere((e) => e.id == event.eventId);
    _attendeesMap.remove(event.eventId);
    // Transient signal for the "event deleted" snackbar, immediately followed by
    // the refreshed list state so the tabs never blank.
    emit(EventDeleted(eventId: event.eventId));
    emit(EventsLoaded(
      events: _allEvents,
      selectedCategory: _selectedCategory,
      attendeesMap: _attendeesMap,
      userEvents: _userEvents,
      nearbyEvents: _nearbyEvents,
    ));

    // Persist in the background; a later reload reconciles on failure.
    final result = await repository.deleteEvent(event.eventId);
    result.fold(
      (failure) => debugPrint('Failed to delete event: ${failure.message}'),
      (_) {},
    );
  }

  /// Hide a (reported) event from the viewer's in-memory lists immediately —
  /// no server delete. Reconciled by moderation server-side.
  void _onHideEvent(HideEvent event, Emitter<EventsState> emit) {
    _allEvents.removeWhere((e) => e.id == event.eventId);
    _userEvents.removeWhere((e) => e.id == event.eventId);
    _nearbyEvents.removeWhere((e) => e.id == event.eventId);
    _attendeesMap.remove(event.eventId);
    emit(EventsLoaded(
      events: _allEvents,
      selectedCategory: _selectedCategory,
      attendeesMap: _attendeesMap,
      userEvents: _userEvents,
      nearbyEvents: _nearbyEvents,
    ));
  }

  Future<void> _onRsvpEvent(
    RsvpEvent event,
    Emitter<EventsState> emit,
  ) async {
    // Preserve whether the user is on the detail screen BEFORE the write.
    final wasDetail = state is EventDetailLoaded;
    final result = await repository.rsvpEvent(
      event.eventId,
      event.userId,
      event.status,
    );

    await result.fold(
      (failure) async {
        debugPrint('Failed to RSVP: ${failure.message}');
        emit(EventsError(failure.message));
      },
      (_) async {
        debugPrint('RSVP success: ${event.eventId} (${event.status})');
        emit(EventRsvpSuccess(eventId: event.eventId, status: event.status));
        await _refreshAfterRsvp(event.eventId, wasDetail, emit);
      },
    );
  }

  Future<void> _onCancelRsvp(
    CancelRsvp event,
    Emitter<EventsState> emit,
  ) async {
    final wasDetail = state is EventDetailLoaded;

    // OPTIMISTIC: if the user only ATTENDS this event (doesn't organize it),
    // drop it from the My Events cache so the "Going" list updates instantly.
    // Keep a copy to restore if the server call fails.
    Event? removed;
    var removedIdx = -1;
    if (!wasDetail) {
      removedIdx = _userEvents.indexWhere((e) => e.id == event.eventId);
      if (removedIdx >= 0 &&
          _userEvents[removedIdx].organizerId != event.userId) {
        removed = _userEvents.removeAt(removedIdx);
        emit(EventsLoaded(
          events: _allEvents,
          selectedCategory: _selectedCategory,
          attendeesMap: _attendeesMap,
          userEvents: _userEvents,
          nearbyEvents: _nearbyEvents,
        ));
      }
    }

    final result = await repository.cancelRsvp(
      event.eventId,
      event.userId,
    );

    await result.fold(
      (failure) async {
        debugPrint('Failed to cancel RSVP: ${failure.message}');
        // Restore the optimistically-removed event.
        if (removed != null) {
          _userEvents.insert(
              removedIdx.clamp(0, _userEvents.length), removed);
        }
        emit(EventsError(failure.message));
      },
      (_) async {
        debugPrint('RSVP cancelled: ${event.eventId}');
        emit(EventRsvpSuccess(eventId: event.eventId, status: 'cancelled'));
        await _refreshAfterRsvp(event.eventId, wasDetail, emit);
      },
    );
  }

  /// After an RSVP/cancel, reload the affected event + its attendees so counts
  /// are fresh, update the caches, and re-emit the RIGHT state: keep the detail
  /// screen if that's where the user is (was previously clobbered to a list),
  /// otherwise re-emit the list with the corrected event.
  Future<void> _refreshAfterRsvp(
    String eventId,
    bool wasDetail,
    Emitter<EventsState> emit,
  ) async {
    // Refresh attendees (best-effort).
    final attendeesResult = await repository.getEventAttendees(eventId);
    attendeesResult.fold(
      (f) => debugPrint('RSVP refresh attendees failed: ${f.message}'),
      (attendees) {
        _attendeesMap = Map.from(_attendeesMap)..[eventId] = attendees;
      },
    );

    // Refresh the single event so attendeeCount is accurate.
    Event? fresh;
    final eventResult = await repository.getEventById(eventId);
    eventResult.fold(
      (f) => debugPrint('RSVP refresh event failed: ${f.message}'),
      (e) {
        if (e != null) {
          fresh = e;
          _replaceInCaches(e);
        }
      },
    );

    if (wasDetail && fresh != null) {
      emit(EventDetailLoaded(
        event: fresh!,
        attendees: _attendeesMap[eventId] ?? const [],
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

  /// Replace an event in every cached list it appears in (by id).
  void _replaceInCaches(Event e) {
    void put(List<Event> list) {
      final i = list.indexWhere((x) => x.id == e.id);
      if (i >= 0) list[i] = e;
    }

    put(_allEvents);
    put(_userEvents);
    put(_nearbyEvents);
  }

  Future<void> _onLoadEventAttendees(
    LoadEventAttendees event,
    Emitter<EventsState> emit,
  ) async {
    final result = await repository.getEventAttendees(event.eventId);

    result.fold(
      (failure) {
        debugPrint('Failed to load attendees: ${failure.message}');
        // Attendees are secondary: only surface an error if there is nothing
        // on screen yet (otherwise keep the list visible).
        if (state is! EventsLoaded && state is! EventDetailLoaded) {
          emit(EventsError(failure.message));
        }
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
    void applyUser(List<Event> events) {
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
    }

    final result = await repository.getUserEvents(event.userId);
    result.fold(
      (failure) {
        debugPrint('Failed to load user events: ${failure.message}');
        if (state is! EventsLoaded) {
          emit(EventsError(failure.message));
        }
      },
      applyUser,
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
        if (state is! EventsLoaded) {
          emit(EventsError(failure.message));
        }
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
