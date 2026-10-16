import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// One event or experience the business created, for the Followers filter.
@immutable
class AudienceListing {
  const AudienceListing({
    required this.kind,
    required this.id,
    required this.title,
    required this.past,
    this.date,
  });

  /// 'event' | 'experience'.
  final String kind;
  final String id;
  final String title;

  /// Event: ended. Experience: no longer published (paused, hidden, ended).
  final bool past;

  /// Event start (null for experiences).
  final DateTime? date;
}

/// The people of one listing, with who of them follows the business.
@immutable
class ListingAudience {
  const ListingAudience({required this.people, required this.followers, this.capped = false});

  /// Attendees ('going') of an event / guests who booked an experience,
  /// newest data order, de-duplicated.
  final List<String> people;

  /// The subset of [people] that follows the business.
  final Set<String> followers;

  /// True when [people] stopped at the read cap.
  final bool capped;
}

/// Data for the Followers page filter (owner request 2026-10-15: "filter by
/// past or present event or experiences the owner created"). Every read is
/// bounded and uses queries the app already makes (organizer events, host
/// experiences, event attendees, host bookings).
abstract class FollowersAudienceService {
  Future<List<AudienceListing>> listings(String businessId, DateTime now);
  Future<ListingAudience> audience(String businessId, AudienceListing listing);

  /// Every follower with the follow date, newest first, up to [maxPeople]
  /// (for the advanced search). Returns uid -> followed at.
  Future<Map<String, DateTime?>> allFollowers(String businessId);
}

class FirestoreFollowersAudienceService implements FollowersAudienceService {
  FirestoreFollowersAudienceService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const int maxListings = 300;
  static const int maxPeople = 2000;
  static const int _page = 500;

  static DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : (v is DateTime ? v : null);

  @override
  Future<List<AudienceListing>> listings(String businessId, DateTime now) async {
    final r = await Future.wait([
      _db.collection('events').where('organizerId', isEqualTo: businessId).limit(maxListings).get(),
      _db.collection('user_experiences').where('hostId', isEqualTo: businessId).limit(maxListings).get(),
    ]);
    final out = <AudienceListing>[];
    for (final d in r[0].docs) {
      final m = d.data();
      if (m['status'] == 'draft') continue;
      final start = _date(m['startDate']);
      final end = _date(m['endDate']) ?? start;
      out.add(AudienceListing(
        kind: 'event',
        id: d.id,
        title: '${m['title'] ?? ''}'.trim(),
        date: start,
        past: m['status'] == 'cancelled' || (end != null && end.isBefore(now)),
      ));
    }
    for (final d in r[1].docs) {
      final m = d.data();
      if (m['status'] == 'draft') continue;
      out.add(AudienceListing(
        kind: 'experience',
        id: d.id,
        title: '${m['title'] ?? ''}'.trim(),
        past: m['status'] != 'published',
      ));
    }
    return sortListings(out);
  }

  @override
  Future<ListingAudience> audience(String businessId, AudienceListing listing) async {
    final people = <String>[];
    final seen = <String>{};
    var capped = false;
    if (listing.kind == 'event') {
      DocumentSnapshot<Map<String, dynamic>>? after;
      while (true) {
        Query<Map<String, dynamic>> q = _db
            .collection('events')
            .doc(listing.id)
            .collection('attendees')
            .where('status', isEqualTo: 'going')
            .orderBy(FieldPath.documentId)
            .limit(_page);
        if (after != null) q = q.startAfterDocument(after);
        final s = await q.get();
        for (final d in s.docs) {
          final uid = (d.data()['userId'] as String?) ?? d.id;
          if (seen.add(uid)) people.add(uid);
        }
        if (s.docs.length < _page) break;
        if (people.length >= maxPeople) {
          capped = true;
          break;
        }
        after = s.docs.last;
      }
    } else {
      final s = await _db
          .collection('bookings')
          .where('hostId', isEqualTo: businessId)
          .where('experienceId', isEqualTo: listing.id)
          .limit(maxPeople)
          .get();
      capped = s.docs.length >= maxPeople;
      for (final d in s.docs) {
        final m = d.data();
        if (!bookedStatuses.contains(m['status'])) continue;
        final uid = '${m['guestId'] ?? ''}';
        if (uid.isNotEmpty && seen.add(uid)) people.add(uid);
      }
    }
    return ListingAudience(people: people, followers: await _followersAmong(businessId, people), capped: capped);
  }

  @override
  Future<Map<String, DateTime?>> allFollowers(String businessId) async {
    final s = await _db
        .collection('business_followers')
        .doc(businessId)
        .collection('followers')
        .orderBy('createdAt', descending: true)
        .limit(maxPeople)
        .get();
    return {for (final d in s.docs) d.id: _date(d.data()['createdAt'])};
  }

  /// Bookings that mean the person really booked (not a declined, expired or
  /// cancelled request).
  static const Set<String> bookedStatuses = {'confirmed', 'completed', 'no_show', 'disputed', 'resolved'};

  /// Which of [uids] follow the business: document-id `whereIn`, 30 at a time.
  Future<Set<String>> _followersAmong(String businessId, List<String> uids) async {
    final col = _db.collection('business_followers').doc(businessId).collection('followers');
    final chunks = [for (var i = 0; i < uids.length; i += 30) uids.sublist(i, i + 30 > uids.length ? uids.length : i + 30)];
    final snaps = await Future.wait(chunks.map((c) => col.where(FieldPath.documentId, whereIn: c).get()));
    return {for (final s in snaps) for (final d in s.docs) d.id};
  }
}

/// Current first (events soonest first, then experiences A-Z), then past
/// (most recent event first, then experiences A-Z).
List<AudienceListing> sortListings(List<AudienceListing> all) {
  int byTitle(AudienceListing a, AudienceListing b) => a.title.toLowerCase().compareTo(b.title.toLowerCase());
  List<AudienceListing> part(bool past) {
    final ev = all.where((l) => l.past == past && l.kind == 'event').toList()
      ..sort((a, b) {
        final x = a.date ?? DateTime(0), y = b.date ?? DateTime(0);
        return past ? y.compareTo(x) : x.compareTo(y);
      });
    final ex = all.where((l) => l.past == past && l.kind == 'experience').toList()..sort(byTitle);
    return [...ev, ...ex];
  }

  return [...part(false), ...part(true)];
}
