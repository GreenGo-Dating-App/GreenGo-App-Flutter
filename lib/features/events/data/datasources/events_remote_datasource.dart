import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/geo_query.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_country_stat.dart';
import '../models/event_attendee_model.dart';
import '../models/event_model.dart';

/// Result of a tier-aware join: whether the attendee is going or waitlisted,
/// and (when waitlisted) their 1-based position in the queue.
class RsvpJoinResult {
  const RsvpJoinResult({required this.status, this.waitlistPosition = 0});
  final RSVPStatus status;
  final int waitlistPosition;
  bool get isWaitlisted => status == RSVPStatus.waitlist;
}

/// Events Remote Data Source Interface
abstract class EventsRemoteDataSource {
  Future<List<Event>> getEvents({
    String? category,
    String? city,
    bool? upcoming,
  });

  Future<Event?> getEventById(String id);

  Future<String> createEvent(Event event);

  /// Batch-create every occurrence of a recurring series in a single write
  /// round-trip (cheap; series are capped at [kMaxSeriesOccurrences] docs).
  Future<void> createEventsBatch(List<Event> events);

  /// Cancel a whole recurring series: flags future occurrences (startDate >= now)
  /// as cancelled so they drop out of every feed (isLive == false).
  Future<void> cancelSeries(String seriesId);

  /// Tier-aware, capacity-safe join. Runs a Firestore transaction on the event's
  /// denormalized counters: if the chosen tier (or the event) is full the
  /// attendee is written with status `waitlist`, otherwise `going`.
  Future<RsvpJoinResult> joinEventWithTier({
    required String eventId,
    required String userId,
    String? tierId,
  });

  /// Cancel a going/waitlist RSVP and, transactionally, promote the OLDEST
  /// waitlisted attendee of the same tier to `going` (auto-promotion).
  Future<void> cancelRsvpWithPromotion(String eventId, String userId);

  /// 1-based waitlist position of [userId] for their tier (0 = not waitlisted).
  Future<int> getWaitlistPosition(String eventId, String userId);

  Future<void> updateEvent(Event event);

  Future<void> deleteEvent(String eventId);

  Future<void> rsvpEvent(
    String eventId,
    String userId,
    String status, {
    bool isInvisible,
    bool isAnonymous,
    bool muteNotifications,
    bool visibleToOrganizerOnly,
  });

  Future<void> cancelRsvp(String eventId, String userId);

  /// Write/remove the per-user like doc. `likeCount` is kept current by the
  /// onEventLikeWrite Cloud Function.
  Future<void> setEventLiked(String eventId, String userId, bool liked);

  /// Live stream of whether [userId] likes [eventId].
  Stream<bool> watchEventLiked(String eventId, String userId);

  Future<List<EventAttendee>> getEventAttendees(String eventId);

  /// QR check-in: mark an attendee as present (organizer only, enforced by
  /// rules). Sets `checkedIn=true` and `checkedInAt=serverTimestamp`.
  Future<void> checkInAttendee({
    required String eventId,
    required String attendeeUserId,
  });

  /// Set how many guests an attendee is bringing (attendee edits their own doc).
  Future<void> setAttendeeGuestCount({
    required String eventId,
    required String userId,
    required int guestCount,
  });

  /// Live attendee roster for the owner's attendance screen. Bounded to 500
  /// docs (index-free — a single subcollection read, no composite index).
  Stream<List<EventAttendee>> watchAttendees(String eventId);

  Future<List<Event>> getEventsNearLocation(
    double lat,
    double lng,
    double radiusKm,
  );

  Future<List<Event>> getUserEvents(String userId);

  /// Nearest published community events to a point, via geohash (scales to a
  /// large table — only the closest [limit] are read/returned).
  Future<List<Event>> getNearbyCommunityEvents({
    required double lat,
    required double lng,
    int limit,
  });

  /// Full-text-ish search by name/typology/city (public events only).
  Future<List<Event>> searchEvents(String query);

  /// Per-country aggregates for the globe (top-3 preview + count per country).
  Future<List<EventCountryStat>> getCountryStats();

  /// Top public events in a country (for the globe country tap).
  /// If [networkUserIds] is provided, only events organized by those users are
  /// returned ("My Network" view).
  Future<List<Event>> getEventsByCountry(
    String country, {
    int limit,
    List<String>? networkUserIds,
  });

  /// Stream event messages for group chat
  Stream<List<EventChatMessage>> getEventMessages(String eventId);

  /// Send a message to event group chat
  Future<void> sendEventMessage(String eventId, EventChatMessage message);

  /// Admin broadcast to everyone in the event (rendered as an announcement).
  Future<void> broadcastToEvent(String eventId, EventChatMessage message);
}

/// Event Chat Message (lightweight, for event group chat sub-collection)
class EventChatMessage {

  const EventChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text, required this.timestamp, this.senderPhotoUrl,
    this.isBroadcast = false,
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
      isBroadcast: data['isBroadcast'] as bool? ?? false,
    );
  }
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final DateTime timestamp;

  /// True for admin announcements broadcast to all attendees.
  final bool isBroadcast;

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isBroadcast': isBroadcast,
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

  EventsRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('events');

  /// Statuses that a live/discoverable event may hold. Scheduled events are
  /// fetched too, then gated client-side on `publishAt <= now` (isLive) so
  /// auto-publish works without a backend. Uses whereIn (same composite index
  /// as the old equality filter — no new index required).
  ///
  /// TODO(cf-autopublish): an OPTIONAL future Cloud Function could flip
  /// scheduled -> published once publishAt passes (scheduled query). Not needed
  /// for correctness — the client isLive gate already auto-publishes.
  static const List<String> _liveStatuses = ['published', 'scheduled'];

  @override
  Future<List<Event>> getEvents({
    String? category,
    String? city,
    bool? upcoming,
  }) async {
    try {
      var query =
          _eventsCollection.where('status', whereIn: _liveStatuses);

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
          .map(EventModel.fromFirestore)
          .where((e) => e.isPublic) // private events excluded from discovery
          .where((e) => e.isLive) // scheduled-but-not-yet-due events hidden
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
  Future<void> createEventsBatch(List<Event> events) async {
    if (events.isEmpty) return;
    try {
      final batch = _firestore.batch();
      for (final e in events) {
        final json = EventModel.fromEntity(e).toJson();
        final ref =
            e.id.isEmpty ? _eventsCollection.doc() : _eventsCollection.doc(e.id);
        batch.set(ref, json);
      }
      await batch.commit();
      debugPrint('Event series created: ${events.length} occurrences');
    } catch (e) {
      debugPrint('Error creating event series: $e');
      throw ServerException('Failed to create event series: $e');
    }
  }

  @override
  Future<void> cancelSeries(String seriesId) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      // Single-field equality (no composite index); a series is bounded to
      // kMaxSeriesOccurrences docs so this stays cheap.
      final snap =
          await _eventsCollection.where('seriesId', isEqualTo: seriesId).get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        final start = doc.data()['startDate'];
        // Only flag future/ongoing occurrences; keep past ones as history.
        if (start is Timestamp && start.compareTo(now) >= 0) {
          batch.update(doc.reference, {
            'status': EventStatus.cancelled.name,
            'updatedAt': now,
          });
        }
      }
      await batch.commit();
      debugPrint('Series cancelled: $seriesId');
    } catch (e) {
      debugPrint('Error cancelling series: $e');
      throw ServerException('Failed to cancel series: $e');
    }
  }

  @override
  Future<void> updateEvent(Event event) async {
    try {
      final model = EventModel.fromEntity(event);
      final json = model.toJson();
      json['updatedAt'] = Timestamp.fromDate(DateTime.now());
      // CF-maintained counters — never overwrite from a (possibly stale) client.
      json.remove('likeCount');
      json.remove('attendeeCount');

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
    String status, {
    bool isInvisible = false,
    bool isAnonymous = false,
    bool muteNotifications = false,
    bool visibleToOrganizerOnly = false,
  }) async {
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
        isInvisible: isInvisible,
        isAnonymous: isAnonymous,
        muteNotifications: muteNotifications,
        visibleToOrganizerOnly: visibleToOrganizerOnly,
      );

      // Set the attendee in sub-collection (use userId as doc ID for uniqueness)
      await _eventsCollection
          .doc(eventId)
          .collection('attendees')
          .doc(userId)
          .set(attendeeData.toJson());

      // Update attendee count on the event document
      await _updateAttendeeCount(eventId);

      // TODO(passport): award a Cultural Passport "event" stamp here once this
      // data layer can resolve the event's category cheaply (it only has the
      // eventId at this point). Until then, PassportService.load() derives event
      // stamps from the user's RSVP'd events via a bounded collectionGroup read,
      // so the stamp still appears — just lazily rather than at RSVP time.

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
  Future<RsvpJoinResult> joinEventWithTier({
    required String eventId,
    required String userId,
    String? tierId,
  }) async {
    try {
      // Resolve profile for the attendee card (outside the transaction).
      final userDoc =
          await _firestore.collection('profiles').doc(userId).get();
      final userData = userDoc.data() ?? {};
      final userName = userData['displayName'] as String? ??
          userData['nickname'] as String? ??
          'Unknown';
      final userPhotoUrl = userData['photoUrl'] as String? ??
          (userData['photoUrls'] is List &&
                  (userData['photoUrls'] as List).isNotEmpty
              ? (userData['photoUrls'] as List).first as String?
              : null);

      final eventRef = _eventsCollection.doc(eventId);
      final attendeeRef = eventRef.collection('attendees').doc(userId);
      final now = DateTime.now();

      final status = await _firestore.runTransaction<RSVPStatus>((tx) async {
        final eventSnap = await tx.get(eventRef);
        final attendeeSnap = await tx.get(attendeeRef);
        final data = eventSnap.data() ?? {};

        final maxAttendees = (data['maxAttendees'] as num?)?.toInt() ?? 0;
        final attendeeCount = (data['attendeeCount'] as num?)?.toInt() ?? 0;
        final tierCounts =
            Map<String, dynamic>.from(data['tierGoingCounts'] as Map? ?? {});
        final tiers = (data['ticketTiers'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(TicketTier.fromMap)
                .toList() ??
            const <TicketTier>[];

        final existingData = attendeeSnap.data();
        final existingStatus = existingData?['status'] as String?;
        final wasGoing = existingStatus == RSVPStatus.going.name;

        // Locate the chosen tier (if any) and evaluate capacity.
        TicketTier? tier;
        for (final t in tiers) {
          if (t.id == tierId) {
            tier = t;
            break;
          }
        }
        final tierGoing =
            tier != null ? ((tierCounts[tier.id] as num?)?.toInt() ?? 0) : 0;
        final tierFull =
            tier != null && !tier.isUnlimited && tierGoing >= tier.capacity;
        final eventFull = maxAttendees > 0 && attendeeCount >= maxAttendees;

        final hasRoom = !tierFull && !eventFull;
        final target =
            (hasRoom || wasGoing) ? RSVPStatus.going : RSVPStatus.waitlist;

        final attendee = EventAttendeeModel(
          id: userId,
          eventId: eventId,
          userId: userId,
          userName: userName,
          userPhotoUrl: userPhotoUrl,
          status: target,
          rsvpDate: now,
          isApproved: true,
          tierId: tierId,
        );
        final json = attendee.toJson();
        // Preserve the original rsvpDate so waitlist ordering stays stable.
        if (existingData != null && existingData['rsvpDate'] != null) {
          json['rsvpDate'] = existingData['rsvpDate'];
        }
        tx.set(attendeeRef, json);

        // Bump denormalized counters only when newly transitioning to going.
        if (target == RSVPStatus.going && !wasGoing) {
          final update = <String, dynamic>{'attendeeCount': attendeeCount + 1};
          if (tier != null) {
            update['tierGoingCounts.${tier.id}'] = tierGoing + 1;
          }
          tx.update(eventRef, update);
        }
        return target;
      });

      if (status == RSVPStatus.waitlist) {
        final pos = await getWaitlistPosition(eventId, userId);
        debugPrint('Waitlisted: $userId -> $eventId (#$pos)');
        return RsvpJoinResult(
            status: RSVPStatus.waitlist, waitlistPosition: pos);
      }
      debugPrint('Joined (going): $userId -> $eventId');
      return const RsvpJoinResult(status: RSVPStatus.going);
    } catch (e) {
      debugPrint('Error joining event with tier: $e');
      throw ServerException('Failed to join event: $e');
    }
  }

  @override
  Future<void> cancelRsvpWithPromotion(String eventId, String userId) async {
    try {
      final eventRef = _eventsCollection.doc(eventId);
      final attendeeRef = eventRef.collection('attendees').doc(userId);

      final cancelSnap = await attendeeRef.get();
      if (!cancelSnap.exists) return;
      final cancelData = cancelSnap.data() ?? {};
      final wasGoing = (cancelData['status'] as String?) == RSVPStatus.going.name;
      final tierId = cancelData['tierId'] as String?;

      // Find the OLDEST waitlisted attendee of the SAME tier to promote. Single
      // equality query (no composite index), sorted client-side; bounded read.
      DocumentReference<Map<String, dynamic>>? promoteRef;
      if (wasGoing) {
        final wl = await eventRef
            .collection('attendees')
            .where('status', isEqualTo: RSVPStatus.waitlist.name)
            .limit(200)
            .get();
        final sameTier = wl.docs
            .where((d) => (d.data()['tierId'] as String?) == tierId)
            .toList()
          ..sort((a, b) =>
              _tsCompare(a.data()['rsvpDate'], b.data()['rsvpDate']));
        if (sameTier.isNotEmpty) promoteRef = sameTier.first.reference;
      }

      await _firestore.runTransaction((tx) async {
        final eventSnap = await tx.get(eventRef);
        final data = eventSnap.data() ?? {};
        final attendeeCount = (data['attendeeCount'] as num?)?.toInt() ?? 0;
        final tierCounts =
            Map<String, dynamic>.from(data['tierGoingCounts'] as Map? ?? {});
        final tierGoing =
            tierId != null ? ((tierCounts[tierId] as num?)?.toInt() ?? 0) : 0;

        // Re-read the promotion candidate inside the transaction.
        DocumentSnapshot<Map<String, dynamic>>? promoSnap;
        if (promoteRef != null) promoSnap = await tx.get(promoteRef);

        // Reads done — now writes. Remove the cancelling RSVP.
        tx.delete(attendeeRef);

        var newCount = attendeeCount;
        var newTierGoing = tierGoing;
        if (wasGoing) {
          newCount = attendeeCount > 0 ? attendeeCount - 1 : 0;
          newTierGoing = tierGoing > 0 ? tierGoing - 1 : 0;
        }

        // Auto-promote the oldest still-waitlisted attendee into the freed slot.
        if (promoSnap != null &&
            promoSnap.exists &&
            (promoSnap.data()?['status'] as String?) ==
                RSVPStatus.waitlist.name) {
          tx.update(promoSnap.reference, {'status': RSVPStatus.going.name});
          newCount += 1;
          newTierGoing += 1;
        }

        final update = <String, dynamic>{'attendeeCount': newCount};
        if (tierId != null) update['tierGoingCounts.$tierId'] = newTierGoing;
        tx.update(eventRef, update);
      });
      debugPrint('RSVP cancelled + promotion run: $userId -> $eventId');
    } catch (e) {
      debugPrint('Error cancelling RSVP with promotion: $e');
      throw ServerException('Failed to cancel RSVP: $e');
    }
  }

  @override
  Future<int> getWaitlistPosition(String eventId, String userId) async {
    try {
      final snap = await _eventsCollection
          .doc(eventId)
          .collection('attendees')
          .where('status', isEqualTo: RSVPStatus.waitlist.name)
          .limit(200)
          .get();
      final mine = snap.docs.where((d) => d.id == userId).toList();
      if (mine.isEmpty) return 0;
      final myTier = mine.first.data()['tierId'] as String?;
      final sameTier = snap.docs
          .where((d) => (d.data()['tierId'] as String?) == myTier)
          .toList()
        ..sort((a, b) =>
            _tsCompare(a.data()['rsvpDate'], b.data()['rsvpDate']));
      final idx = sameTier.indexWhere((d) => d.id == userId);
      return idx < 0 ? 0 : idx + 1;
    } catch (e) {
      debugPrint('Error getting waitlist position: $e');
      return 0;
    }
  }

  /// Compare two Firestore `rsvpDate` values (Timestamp) for ascending order,
  /// tolerating nulls/other types (treated as epoch-zero).
  int _tsCompare(dynamic a, dynamic b) {
    final ta = a is Timestamp ? a : Timestamp.fromMillisecondsSinceEpoch(0);
    final tb = b is Timestamp ? b : Timestamp.fromMillisecondsSinceEpoch(0);
    return ta.compareTo(tb);
  }

  @override
  Future<void> setEventLiked(
      String eventId, String userId, bool liked) async {
    try {
      final ref =
          _eventsCollection.doc(eventId).collection('likes').doc(userId);
      if (liked) {
        await ref.set({
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.delete();
      }
    } catch (e) {
      debugPrint('Error setting like ($liked) for $eventId: $e');
      throw ServerException('Failed to update like: $e');
    }
  }

  @override
  Stream<bool> watchEventLiked(String eventId, String userId) {
    return _eventsCollection
        .doc(eventId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((d) => d.exists);
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
          .map(EventAttendeeModel.fromFirestore)
          .toList();
    } catch (e) {
      debugPrint('Error getting attendees: $e');
      throw ServerException('Failed to load attendees: $e');
    }
  }

  @override
  Future<void> checkInAttendee({
    required String eventId,
    required String attendeeUserId,
  }) async {
    try {
      await _eventsCollection
          .doc(eventId)
          .collection('attendees')
          .doc(attendeeUserId)
          .update({
        'checkedIn': true,
        'checkedInAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Checked in: $attendeeUserId -> $eventId');
    } catch (e) {
      debugPrint('Error checking in attendee: $e');
      throw ServerException('Failed to check in attendee: $e');
    }
  }

  @override
  Future<void> setAttendeeGuestCount({
    required String eventId,
    required String userId,
    required int guestCount,
  }) async {
    try {
      final count = guestCount < 0 ? 0 : guestCount;
      await _eventsCollection
          .doc(eventId)
          .collection('attendees')
          .doc(userId)
          .set({'guestCount': count}, SetOptions(merge: true));
      debugPrint('Guest count set: $userId -> $eventId ($count)');
    } catch (e) {
      debugPrint('Error setting guest count: $e');
      throw ServerException('Failed to set guest count: $e');
    }
  }

  @override
  Stream<List<EventAttendee>> watchAttendees(String eventId) {
    return _eventsCollection
        .doc(eventId)
        .collection('attendees')
        .limit(500)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(EventAttendeeModel.fromFirestore)
            .toList());
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
          .where('status', whereIn: _liveStatuses)
          .where(
            'startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()),
          )
          .orderBy('startDate', descending: false)
          .limit(200)
          .get();

      final events = snapshot.docs
          .map(EventModel.fromFirestore)
          .where((event) {
        if (!event.isPublic) return false; // private events excluded from discovery
        if (!event.isLive) return false; // scheduled-not-yet-due hidden
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
          .map(EventModel.fromFirestore)
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
      final attendingEvents = <Event>[];
      for (var i = 0; i < additionalIds.length; i += 10) {
        final batch = additionalIds.skip(i).take(10).toList();
        final batchSnapshot = await _eventsCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        attendingEvents.addAll(
          batchSnapshot.docs.map(EventModel.fromFirestore),
        );
      }

      // Combine and sort by start date.
      final combined = [...organizedEvents, ...attendingEvents];

      // Mark the current user's "going" RSVP on every event in the going set
      // (attendees are stored in a subcollection, so the event doc's denormalized
      // attendees array can't be trusted). This lets the Going tab include events
      // the user RSVP'd to — INCLUDING ones they organized and then joined.
      final allEvents = combined.map((e) {
        final alreadyGoing = e.attendees.any(
            (a) => a.userId == userId && a.status == RSVPStatus.going);
        if (attendingEventIds.contains(e.id) && !alreadyGoing) {
          return e.copyWith(attendees: [
            ...e.attendees,
            EventAttendee(
              id: userId,
              eventId: e.id,
              userId: userId,
              userName: '',
              status: RSVPStatus.going,
              rsvpDate: DateTime.now(),
            ),
          ]);
        }
        return e;
      }).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

      debugPrint('User events: ${allEvents.length} (${organizedEvents.length} organized, ${attendingEvents.length} attending)');
      return allEvents;
    } catch (e) {
      debugPrint('Error getting user events: $e');
      throw ServerException('Failed to load user events: $e');
    }
  }

  @override
  Future<List<Event>> getNearbyCommunityEvents({
    required double lat,
    required double lng,
    int limit = 100,
  }) async {
    try {
      final out = <String, Event>{};
      // Expanding rings: 100km → 300 → 900 → 2700 → global, until we have enough.
      var radiusM = 100000.0;
      const maxRadiusM = 20000000.0;
      final now = DateTime.now();
      while (out.length < limit && radiusM <= maxRadiusM) {
        final bounds = GeoQuery.queryBounds(lat, lng, radiusM);
        final snaps = await Future.wait(bounds.map((b) => _eventsCollection
            .where('status', whereIn: _liveStatuses)
            .orderBy('geohash')
            .startAt([b[0]]).endAt([b[1]]).get()));
        for (final s in snaps) {
          for (final doc in s.docs) {
            if (out.containsKey(doc.id)) continue;
            final e = EventModel.fromFirestore(doc);
            if (!e.isPublic) continue;
            if (!e.isLive) continue; // scheduled-not-yet-due hidden
            if (e.endDate.isBefore(now)) continue; // upcoming/ongoing only
            out[doc.id] = e;
          }
        }
        if (radiusM >= maxRadiusM) break;
        radiusM *= 3;
      }
      final list = out.values.toList();
      double dist(Event e) {
        if (e.latitude == null || e.longitude == null) return double.infinity;
        return GeoQuery.distanceMeters(lat, lng, e.latitude!, e.longitude!);
      }
      list.sort((a, b) => dist(a).compareTo(dist(b)));
      return list.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting nearby community events: $e');
      return [];
    }
  }

  @override
  Future<List<Event>> searchEvents(String query) async {
    try {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return [];
      final token = q
          .split(RegExp(r'[^a-z0-9]+'))
          .firstWhere((t) => t.length >= 2, orElse: () => '');
      if (token.isEmpty) return [];

      // Single array-contains (no composite index); refine + visibility on client.
      final snapshot = await _eventsCollection
          .where('searchKeywords', arrayContains: token)
          .limit(50)
          .get();

      return snapshot.docs
          .map(EventModel.fromFirestore)
          .where((e) => e.isLive && e.isPublic)
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
    } catch (e) {
      debugPrint('Error searching events: $e');
      throw ServerException('Failed to search events: $e');
    }
  }

  @override
  Future<List<EventCountryStat>> getCountryStats() async {
    try {
      final snap = await _firestore
          .collection('event_country_stats')
          .orderBy('count', descending: true)
          .limit(300)
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        final top = (data['topEvents'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(EventPreview.fromMap)
                .toList() ??
            const <EventPreview>[];
        return EventCountryStat(
          country: data['country'] as String? ?? d.id,
          count: (data['count'] as num?)?.toInt() ?? 0,
          topEvents: top,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting country stats: $e');
      throw ServerException('Failed to load country stats: $e');
    }
  }

  @override
  Future<List<Event>> getEventsByCountry(
    String country, {
    int limit = 10,
    List<String>? networkUserIds,
  }) async {
    try {
      final snap = await _eventsCollection
          .where('country', isEqualTo: country)
          .where('status', whereIn: _liveStatuses)
          .where('visibility', isEqualTo: 'public')
          .orderBy('attendeeCount', descending: true)
          .limit(networkUserIds == null ? limit : 60)
          .get();
      var events = snap.docs
          .map(EventModel.fromFirestore)
          .where((e) => e.isLive) // scheduled-not-yet-due hidden
          .toList();
      if (networkUserIds != null) {
        final net = networkUserIds.toSet();
        events = events
            .where((e) => net.contains(e.organizerId))
            .take(limit)
            .toList();
      }
      return events;
    } catch (e) {
      debugPrint('Error getting events by country: $e');
      throw ServerException('Failed to load events for country: $e');
    }
  }

  @override
  Future<void> broadcastToEvent(
    String eventId,
    EventChatMessage message,
  ) async {
    // A broadcast is an announcement message; rules restrict this to the
    // organizer. A Cloud Function fans it out via the per-event FCM topic.
    try {
      await _eventsCollection
          .doc(eventId)
          .collection('messages')
          .add(message.toJson());
    } catch (e) {
      debugPrint('Error broadcasting to event: $e');
      throw ServerException('Failed to broadcast: $e');
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
          .map(EventChatMessage.fromFirestore)
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
