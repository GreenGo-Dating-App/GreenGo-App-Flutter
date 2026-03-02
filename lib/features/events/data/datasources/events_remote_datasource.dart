import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/event.dart';
import '../models/event_model.dart';
import '../models/event_attendee_model.dart';

/// Events Remote Data Source Interface
abstract class EventsRemoteDataSource {
  Future<List<Event>> getEvents({
    String? category,
    String? city,
    bool? upcoming,
  });

  Future<Event?> getEventById(String id);

  Future<String> createEvent(Event event);

  Future<void> updateEvent(Event event);

  Future<void> deleteEvent(String eventId);

  Future<void> rsvpEvent(String eventId, String userId, String status);

  Future<void> cancelRsvp(String eventId, String userId);

  Future<List<EventAttendee>> getEventAttendees(String eventId);

  Future<List<Event>> getEventsNearLocation(
    double lat,
    double lng,
    double radiusKm,
  );

  Future<List<Event>> getUserEvents(String userId);

  /// Stream event messages for group chat
  Stream<List<EventChatMessage>> getEventMessages(String eventId);

  /// Send a message to event group chat
  Future<void> sendEventMessage(String eventId, EventChatMessage message);
}

/// Event Chat Message (lightweight, for event group chat sub-collection)
class EventChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final DateTime timestamp;

  const EventChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.text,
    required this.timestamp,
  });

  factory EventChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EventChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      text: data['text'] as String? ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// Events Remote Data Source Implementation
///
/// Full Firestore CRUD for events.
/// Collection: 'events'
/// Sub-collection: 'events/{eventId}/attendees'
/// Sub-collection: 'events/{eventId}/messages'
class EventsRemoteDataSourceImpl implements EventsRemoteDataSource {
  final FirebaseFirestore _firestore;

  EventsRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('events');

  @override
  Future<List<Event>> getEvents({
    String? category,
    String? city,
    bool? upcoming,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _eventsCollection
          .where('status', isEqualTo: EventStatus.published.name);

      // Filter by category
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      // Filter by city
      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      // Filter upcoming events only
      if (upcoming == true) {
        query = query.where(
          'startDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()),
        );
      }

      // Order by start date
      query = query.orderBy('startDate', descending: false);

      // Limit results
      query = query.limit(100);

      final snapshot = await query.get();

      final events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      debugPrint('Events loaded: ${events.length} events');
      return events;
    } catch (e) {
      debugPrint('Error getting events: $e');
      throw ServerException('Failed to load events: $e');
    }
  }

  @override
  Future<Event?> getEventById(String id) async {
    try {
      final doc = await _eventsCollection.doc(id).get();
      if (!doc.exists) return null;
      return EventModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting event by ID: $e');
      throw ServerException('Failed to load event: $e');
    }
  }

  @override
  Future<String> createEvent(Event event) async {
    try {
      final model = EventModel.fromEntity(event);
      final json = model.toJson();

      // If the event has an ID, use it; otherwise let Firestore generate one
      if (event.id.isNotEmpty &&
          !event.id.startsWith(RegExp(r'\d').pattern)) {
        await _eventsCollection.doc(event.id).set(json);
        return event.id;
      } else {
        final docRef = await _eventsCollection.add(json);
        debugPrint('Event created: ${docRef.id}');
        return docRef.id;
      }
    } catch (e) {
      debugPrint('Error creating event: $e');
      throw ServerException('Failed to create event: $e');
    }
  }

  @override
  Future<void> updateEvent(Event event) async {
    try {
      final model = EventModel.fromEntity(event);
      final json = model.toJson();
      json['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _eventsCollection.doc(event.id).update(json);
      debugPrint('Event updated: ${event.id}');
    } catch (e) {
      debugPrint('Error updating event: $e');
      throw ServerException('Failed to update event: $e');
    }
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    try {
      // Delete attendees sub-collection first
      final attendeesSnapshot = await _eventsCollection
          .doc(eventId)
          .collection('attendees')
          .get();
      for (final doc in attendeesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete messages sub-collection
      final messagesSnapshot = await _eventsCollection
          .doc(eventId)
          .collection('messages')
          .get();
      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the event document
      await _eventsCollection.doc(eventId).delete();
      debugPrint('Event deleted: $eventId');
    } catch (e) {
      debugPrint('Error deleting event: $e');
      throw ServerException('Failed to delete event: $e');
    }
  }

  @override
  Future<void> rsvpEvent(
    String eventId,
    String userId,
    String status,
  ) async {
    try {
      // Get user profile for attendee info
      final userDoc =
          await _firestore.collection('profiles').doc(userId).get();
      final userData = userDoc.data() ?? {};

      final attendeeData = EventAttendeeModel(
        id: userId,
        eventId: eventId,
        userId: userId,
        userName: userData['displayName'] as String? ??
            userData['nickname'] as String? ??
            'Unknown',
        userPhotoUrl: userData['photoUrl'] as String? ??
            (userData['photoUrls'] is List &&
                    (userData['photoUrls'] as List).isNotEmpty
                ? (userData['photoUrls'] as List).first as String?
                : null),
        status: _parseRsvpStatusFromString(status),
        rsvpDate: DateTime.now(),
        isApproved: true,
      );

      // Set the attendee in sub-collection (use userId as doc ID for uniqueness)
      await _eventsCollection
          .doc(eventId)
          .collection('attendees')
          .doc(userId)
          .set(attendeeData.toJson());

      // Update attendee count on the event document
      await _updateAttendeeCount(eventId);

      debugPrint('RSVP recorded: $userId -> $eventId ($status)');
    } catch (e) {
      debugPrint('Error RSVP event: $e');
      throw ServerException('Failed to RSVP: $e');
    }
  }

  @override
  Future<void> cancelRsvp(String eventId, String userId) async {
    try {
      await _eventsCollection
          .doc(eventId)
          .collection('attendees')
          .doc(userId)
          .delete();

      // Update attendee count
      await _updateAttendeeCount(eventId);

      debugPrint('RSVP cancelled: $userId -> $eventId');
    } catch (e) {
      debugPrint('Error cancelling RSVP: $e');
      throw ServerException('Failed to cancel RSVP: $e');
    }
  }

  @override
  Future<List<EventAttendee>> getEventAttendees(String eventId) async {
    try {
      final snapshot = await _eventsCollection
          .doc(eventId)
          .collection('attendees')
          .orderBy('rsvpDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => EventAttendeeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting attendees: $e');
      throw ServerException('Failed to load attendees: $e');
    }
  }

  @override
  Future<List<Event>> getEventsNearLocation(
    double lat,
    double lng,
    double radiusKm,
  ) async {
    try {
      // Firestore does not support native geo-queries without GeoFlutterFire.
      // We fetch upcoming published events and filter by distance client-side.
      final snapshot = await _eventsCollection
          .where('status', isEqualTo: EventStatus.published.name)
          .where(
            'startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()),
          )
          .orderBy('startDate', descending: false)
          .limit(200)
          .get();

      final events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .where((event) {
        if (event.latitude == null || event.longitude == null) return false;
        final distance = _calculateDistanceKm(
          lat,
          lng,
          event.latitude!,
          event.longitude!,
        );
        return distance <= radiusKm;
      }).toList();

      // Sort by distance
      events.sort((a, b) {
        final distA = _calculateDistanceKm(lat, lng, a.latitude!, a.longitude!);
        final distB = _calculateDistanceKm(lat, lng, b.latitude!, b.longitude!);
        return distA.compareTo(distB);
      });

      debugPrint('Nearby events: ${events.length} within ${radiusKm}km');
      return events;
    } catch (e) {
      debugPrint('Error getting nearby events: $e');
      throw ServerException('Failed to load nearby events: $e');
    }
  }

  @override
  Future<List<Event>> getUserEvents(String userId) async {
    try {
      // Get events the user organized
      final organizedSnapshot = await _eventsCollection
          .where('organizerId', isEqualTo: userId)
          .orderBy('startDate', descending: false)
          .get();

      final organizedEvents = organizedSnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      // Get events the user is attending (query attendees sub-collections)
      // Firestore does not support sub-collection group queries without
      // collectionGroup, so we use collectionGroup on 'attendees'.
      final attendingSnapshot = await _firestore
          .collectionGroup('attendees')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: RSVPStatus.going.name)
          .get();

      // Extract event IDs from the attendee documents
      final attendingEventIds = attendingSnapshot.docs
          .map((doc) {
            // Path: events/{eventId}/attendees/{userId}
            final segments = doc.reference.path.split('/');
            if (segments.length >= 2) {
              return segments[1]; // eventId
            }
            return null;
          })
          .whereType<String>()
          .toSet();

      // Remove events the user already organized (avoid duplicates)
      final organizedIds = organizedEvents.map((e) => e.id).toSet();
      final additionalIds =
          attendingEventIds.difference(organizedIds).toList();

      // Fetch attending events by ID (batched)
      final List<Event> attendingEvents = [];
      for (int i = 0; i < additionalIds.length; i += 10) {
        final batch = additionalIds.skip(i).take(10).toList();
        final batchSnapshot = await _eventsCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        attendingEvents.addAll(
          batchSnapshot.docs.map((doc) => EventModel.fromFirestore(doc)),
        );
      }

      // Combine and sort by start date
      final allEvents = [...organizedEvents, ...attendingEvents];
      allEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

      debugPrint('User events: ${allEvents.length} (${organizedEvents.length} organized, ${attendingEvents.length} attending)');
      return allEvents;
    } catch (e) {
      debugPrint('Error getting user events: $e');
      throw ServerException('Failed to load user events: $e');
    }
  }

  @override
  Stream<List<EventChatMessage>> getEventMessages(String eventId) {
    return _eventsCollection
        .doc(eventId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(200)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EventChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Future<void> sendEventMessage(
    String eventId,
    EventChatMessage message,
  ) async {
    try {
      await _eventsCollection
          .doc(eventId)
          .collection('messages')
          .add(message.toJson());
    } catch (e) {
      debugPrint('Error sending event message: $e');
      throw ServerException('Failed to send message: $e');
    }
  }

  // ── Private helpers ──

  /// Update the attendeeCount field on the event document
  Future<void> _updateAttendeeCount(String eventId) async {
    try {
      final attendeesSnapshot = await _eventsCollection
          .doc(eventId)
          .collection('attendees')
          .where('status', isEqualTo: RSVPStatus.going.name)
          .get();

      await _eventsCollection.doc(eventId).update({
        'attendeeCount': attendeesSnapshot.docs.length,
      });
    } catch (e) {
      debugPrint('Error updating attendee count: $e');
    }
  }

  /// Calculate distance between two lat/lng points using the Haversine formula.
  double _calculateDistanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Parse RSVPStatus from string
  RSVPStatus _parseRsvpStatusFromString(String status) {
    try {
      return RSVPStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => RSVPStatus.interested,
      );
    } catch (_) {
      return RSVPStatus.interested;
    }
  }
}
