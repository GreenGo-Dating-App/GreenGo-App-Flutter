import '../../domain/entities/event.dart';

/// Events BLoC States
abstract class EventsState {
  const EventsState();
}

/// Initial state before any events are loaded
class EventsInitial extends EventsState {
  const EventsInitial();
}

/// Loading events from repository
class EventsLoading extends EventsState {
  const EventsLoading();
}

/// Events loaded successfully
class EventsLoaded extends EventsState {
  /// All events from the repository (unfiltered)
  final List<Event> events;

  /// Currently selected category filter (null = all)
  final EventCategory? selectedCategory;

  /// Attendees map keyed by eventId
  final Map<String, List<EventAttendee>> attendeesMap;

  /// User events (events the user organized or is attending)
  final List<Event> userEvents;

  /// Nearby events
  final List<Event> nearbyEvents;

  const EventsLoaded({
    required this.events,
    this.selectedCategory,
    this.attendeesMap = const {},
    this.userEvents = const [],
    this.nearbyEvents = const [],
  });

  /// Get filtered events based on selected category
  List<Event> get filteredEvents {
    if (selectedCategory == null) return events;
    return events
        .where((e) => e.category == selectedCategory)
        .toList();
  }

  /// Get upcoming events (filtered)
  List<Event> get upcomingEvents {
    return filteredEvents
        .where((e) => e.isUpcoming)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// Copy with updated fields
  EventsLoaded copyWith({
    List<Event>? events,
    EventCategory? selectedCategory,
    bool clearCategory = false,
    Map<String, List<EventAttendee>>? attendeesMap,
    List<Event>? userEvents,
    List<Event>? nearbyEvents,
  }) {
    return EventsLoaded(
      events: events ?? this.events,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      attendeesMap: attendeesMap ?? this.attendeesMap,
      userEvents: userEvents ?? this.userEvents,
      nearbyEvents: nearbyEvents ?? this.nearbyEvents,
    );
  }
}

/// Error loading events
class EventsError extends EventsState {
  final String message;

  const EventsError(this.message);
}

/// Event created successfully
class EventCreated extends EventsState {
  final String eventId;

  const EventCreated({required this.eventId});
}

/// Event RSVP updated successfully
class EventRsvpSuccess extends EventsState {
  final String eventId;
  final String status;

  const EventRsvpSuccess({required this.eventId, required this.status});
}

/// Event deleted successfully
class EventDeleted extends EventsState {
  final String eventId;

  const EventDeleted({required this.eventId});
}

/// Single event loaded
class EventDetailLoaded extends EventsState {
  final Event event;
  final List<EventAttendee> attendees;

  const EventDetailLoaded({
    required this.event,
    this.attendees = const [],
  });
}
