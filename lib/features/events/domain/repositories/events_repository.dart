import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/event.dart';
import '../entities/event_country_stat.dart';

/// Events Repository Interface
abstract class EventsRepository {
  /// Get events with optional filters
  Future<Either<Failure, List<Event>>> getEvents({
    String? category,
    String? city,
    bool? upcoming,
  });

  /// Get a single event by ID
  Future<Either<Failure, Event?>> getEventById(String id);

  /// Create a new event, returns the event ID
  Future<Either<Failure, String>> createEvent(Event event);

  /// Update an existing event
  Future<Either<Failure, void>> updateEvent(Event event);

  /// Delete an event
  Future<Either<Failure, void>> deleteEvent(String eventId);

  /// RSVP to an event (with optional attendee privacy controls)
  Future<Either<Failure, void>> rsvpEvent(
    String eventId,
    String userId,
    String status, {
    bool isInvisible,
    bool isAnonymous,
    bool muteNotifications,
    bool visibleToOrganizerOnly,
  });

  /// Cancel RSVP for an event
  Future<Either<Failure, void>> cancelRsvp(String eventId, String userId);

  /// Like / unlike an event. The denormalized `likeCount` is maintained by the
  /// onEventLikeWrite Cloud Function, so this only writes the per-user like doc.
  Future<Either<Failure, void>> setEventLiked(
    String eventId,
    String userId,
    bool liked,
  );

  /// Live stream of whether [userId] currently likes [eventId].
  Stream<bool> watchEventLiked(String eventId, String userId);

  /// Get attendees for an event
  Future<Either<Failure, List<EventAttendee>>> getEventAttendees(
    String eventId,
  );

  /// Get events near a location within a radius
  Future<Either<Failure, List<Event>>> getEventsNearLocation(
    double lat,
    double lng,
    double radiusKm,
  );

  /// Get events the user created or is attending
  Future<Either<Failure, List<Event>>> getUserEvents(String userId);

  /// Search public events by name / typology / city.
  Future<Either<Failure, List<Event>>> searchEvents(String query);

  /// Per-country aggregates for the globe.
  Future<Either<Failure, List<EventCountryStat>>> getCountryStats();

  /// Top public events in a country (optionally limited to the user's network).
  Future<Either<Failure, List<Event>>> getEventsByCountry(
    String country, {
    int limit,
    List<String>? networkUserIds,
  });
}
