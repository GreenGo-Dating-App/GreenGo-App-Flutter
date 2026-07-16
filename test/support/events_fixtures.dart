import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';

/// Shared EVENTS test fixtures (separate from mock_data.dart, which is
/// communities-only). Builds domain [Event]s for bloc/state tests and seeds
/// Firestore `events` docs for datasource tests against fake_cloud_firestore.
class EventFixtures {
  EventFixtures._();

  /// A fully-populated domain Event with sensible defaults. Override only what
  /// a given test cares about (id / startDate / category / status / visibility).
  static Event build({
    String id = 'evt_1',
    String organizerId = 'org_1',
    String organizerName = 'Organizer',
    String title = 'Test Event',
    EventCategory category = EventCategory.social,
    DateTime? startDate,
    DateTime? endDate,
    EventStatus status = EventStatus.published,
    EventVisibility visibility = EventVisibility.public,
    int maxAttendees = 20,
    int attendeeCount = 0,
    String? city,
    List<EventAttendee> attendees = const [],
  }) {
    final start = startDate ?? DateTime(2030, 1, 1, 18);
    return Event(
      id: id,
      organizerId: organizerId,
      organizerName: organizerName,
      title: title,
      description: 'A test event',
      category: category,
      startDate: start,
      endDate: endDate ?? start.add(const Duration(hours: 2)),
      locationName: 'Somewhere',
      maxAttendees: maxAttendees,
      status: status,
      createdAt: DateTime(2026, 1, 1),
      visibility: visibility,
      attendeeCount: attendeeCount,
      city: city,
      attendees: attendees,
    );
  }

  /// The Firestore document shape that `EventModel.fromFirestore` reads back.
  /// Only the fields the reader/query touches are populated.
  static Map<String, dynamic> doc({
    required String organizerId,
    required DateTime startDate,
    String title = 'Seeded Event',
    String category = 'social',
    String status = 'published',
    String visibility = 'public',
    int maxAttendees = 20,
    int attendeeCount = 0,
    String? city,
    String? country,
  }) {
    return {
      'organizerId': organizerId,
      'organizerName': 'Organizer',
      'title': title,
      'description': 'seeded',
      'category': category,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(startDate.add(const Duration(hours: 2))),
      'locationName': 'Somewhere',
      'maxAttendees': maxAttendees,
      'attendeeCount': attendeeCount,
      'status': status,
      'visibility': visibility,
      'city': city,
      'country': country,
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    };
  }

  /// Seed one `events/{id}` document; returns the id used.
  static Future<String> seedEvent(
    FakeFirebaseFirestore db, {
    required String id,
    required String organizerId,
    required DateTime startDate,
    String title = 'Seeded Event',
    String category = 'social',
    String status = 'published',
    String visibility = 'public',
    String? city,
  }) async {
    await db.collection('events').doc(id).set(doc(
          organizerId: organizerId,
          startDate: startDate,
          title: title,
          category: category,
          status: status,
          visibility: visibility,
          city: city,
        ));
    return id;
  }

  /// Seed an attendee doc under `events/{eventId}/attendees/{userId}`.
  static Future<void> seedAttendee(
    FakeFirebaseFirestore db, {
    required String eventId,
    required String userId,
    String status = 'going',
  }) async {
    await db
        .collection('events')
        .doc(eventId)
        .collection('attendees')
        .doc(userId)
        .set({
      'id': userId,
      'eventId': eventId,
      'userId': userId,
      'userName': 'Attendee',
      'status': status,
      'rsvpDate': Timestamp.fromDate(DateTime(2026, 6, 1)),
      'isApproved': true,
    });
  }
}
