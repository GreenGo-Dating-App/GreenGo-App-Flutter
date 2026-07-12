import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/country_flag_colors.dart';
import '../../../../core/utils/country_flag_helper.dart';
import '../../domain/entities/cultural_passport.dart';

/// Builds and persists a user's [CulturalPassport].
///
/// Design goals (see project memory — "design for millions / perf-first"):
///  * All Firestore queries are **bounded** (hard `limit`s + capped `whereIn`
///    batches) and **index-free** — only single-field equality queries and
///    document-id `whereIn` reads, which never require a composite index.
///  * [load] is **cache-first**: an in-memory memo short-circuits repeat reads
///    within a session, and each derivation source is wrapped independently so
///    one failing query can never blank the whole passport.
///  * Stamps are *derived* from existing data (conversations, the user's
///    profile, RSVP'd events) and then *merged* with anything explicitly
///    stored via [awardStamp], so the passport is always at least as complete
///    as the user's real activity.
///
/// Doc shape: `user_passports/{userId} = {`
///   `countryStamps: [ISO...], languageStamps: [lang...], eventStamps: [cat...],`
///   `updatedAt }`.
class PassportService {
  PassportService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _passportsCol = 'user_passports';
  static const String _conversationsCol = 'conversations';
  static const String _profilesCol = 'profiles';
  static const String _attendeesGroup = 'attendees';
  static const String _eventsCol = 'events';

  // Bounds — keep every read cheap regardless of how active the user is.
  static const int _maxConversationsPerSide = 40;
  static const int _maxPartners = 30;
  static const int _maxEventRsvps = 60;
  static const int _whereInBatch = 10; // Firestore `whereIn` hard cap.

  /// Valid stamp families for [awardStamp].
  static const Set<String> stampTypes = {'country', 'language', 'event'};

  /// Session memo so a re-open of the passport screen is instant (cache-first).
  final Map<String, CulturalPassport> _memo = <String, CulturalPassport>{};

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _firestore.collection(_passportsCol).doc(userId);

  /// Loads the user's passport, cache-first.
  ///
  /// Merges any stored stamps with stamps DERIVED from existing data:
  ///  * country stamps  ← the countries of the people in the user's
  ///                       `conversations` (partner profiles),
  ///  * language stamps ← the user's own `languages` / `preferredLanguages` /
  ///                       `nativeLanguage` + chat partners' languages,
  ///  * event stamps     ← the categories of events the user RSVP'd to.
  Future<CulturalPassport> load(String userId) async {
    if (userId.isEmpty) return const CulturalPassport.empty();

    final cached = _memo[userId];
    if (cached != null) return cached;

    // 1) Stored stamps (explicit awards / previously persisted).
    var stored = const CulturalPassport.empty();
    try {
      final snap = await _doc(userId).get();
      stored = CulturalPassport.fromMap(snap.data());
    } catch (e) {
      debugPrint('PassportService.load stored read failed: $e');
    }

    final countries = <String>{...stored.countryStamps};
    final languages = <String>{...stored.languageStamps};
    final events = <String>{...stored.eventStamps};

    // 2) Derive from conversations (partner countries + partner languages).
    try {
      final partnerIds = await _partnerUserIds(userId);
      final partners = await _readProfiles(partnerIds);
      for (final data in partners) {
        for (final code in _profileCountryCodes(data)) {
          countries.add(code);
        }
        languages.addAll(_profileLanguages(data));
      }
    } catch (e) {
      debugPrint('PassportService.load conversation derivation failed: $e');
    }

    // 3) Derive the user's own languages from their profile.
    try {
      final ownSnap = await _firestore.collection(_profilesCol).doc(userId).get();
      languages.addAll(_profileLanguages(ownSnap.data()));
    } catch (e) {
      debugPrint('PassportService.load own-profile derivation failed: $e');
    }

    // 4) Derive event stamps from RSVP'd / attended events.
    try {
      events.addAll(await _attendedEventCategories(userId));
    } catch (e) {
      debugPrint('PassportService.load event derivation failed: $e');
    }

    final passport = CulturalPassport(
      countryStamps: countries.toList(),
      languageStamps: languages.toList(),
      eventStamps: events.toList(),
      updatedAt: stored.updatedAt,
    );
    _memo[userId] = passport;
    return passport;
  }

  /// Explicitly awards a stamp (for future triggers, e.g. joining an event).
  ///
  /// [type] must be one of [stampTypes]. Country values are normalised to their
  /// ISO alpha-2 code when resolvable. Idempotent via `arrayUnion`.
  Future<void> awardStamp({
    required String userId,
    required String type,
    required String value,
  }) async {
    if (userId.isEmpty) return;
    if (!stampTypes.contains(type)) return;

    var stamp = value.trim();
    if (stamp.isEmpty) return;

    final String field;
    switch (type) {
      case 'country':
        field = 'countryStamps';
        stamp = _resolveCountryCode(stamp) ?? stamp.toUpperCase();
        break;
      case 'language':
        field = 'languageStamps';
        break;
      case 'event':
      default:
        field = 'eventStamps';
        break;
    }

    try {
      await _doc(userId).set(<String, dynamic>{
        field: FieldValue.arrayUnion(<String>[stamp]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _memo.remove(userId); // Force a fresh derive+merge next load.
    } catch (e) {
      debugPrint('PassportService.awardStamp failed ($type=$stamp): $e');
    }
  }

  /// Drops any cached passport for [userId] (e.g. after external activity).
  void invalidate(String userId) => _memo.remove(userId);

  // ---------------------------------------------------------------------------
  // Derivation helpers (all bounded, index-free)
  // ---------------------------------------------------------------------------

  /// The other participants of the user's 1:1 conversations, capped.
  ///
  /// Uses two single-field equality queries (no composite index) instead of a
  /// `Filter.or`, each bounded by [_maxConversationsPerSide].
  Future<List<String>> _partnerUserIds(String userId) async {
    final ids = <String>{};

    Future<void> collect(String field) async {
      final snap = await _firestore
          .collection(_conversationsCol)
          .where(field, isEqualTo: userId)
          .limit(_maxConversationsPerSide)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final u1 = data['userId1'] as String?;
        final u2 = data['userId2'] as String?;
        final other = u1 == userId ? u2 : u1;
        if (other != null && other.isNotEmpty && other != userId) {
          ids.add(other);
        }
        if (ids.length >= _maxPartners) break;
      }
    }

    await collect('userId1');
    if (ids.length < _maxPartners) await collect('userId2');

    return ids.take(_maxPartners).toList();
  }

  /// Batch-reads profile docs by id (`whereIn`, ≤10 per query), capped.
  Future<List<Map<String, dynamic>>> _readProfiles(List<String> userIds) async {
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < userIds.length; i += _whereInBatch) {
      final batch = userIds.skip(i).take(_whereInBatch).toList();
      if (batch.isEmpty) break;
      final snap = await _firestore
          .collection(_profilesCol)
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final doc in snap.docs) {
        out.add(doc.data());
      }
    }
    return out;
  }

  /// The categories of events the user RSVP'd to / is attending, capped.
  ///
  /// Single-field `collectionGroup` equality query (single-field indexes are
  /// created automatically by Firestore — no composite index needed).
  Future<Set<String>> _attendedEventCategories(String userId) async {
    final attendeeSnap = await _firestore
        .collectionGroup(_attendeesGroup)
        .where('userId', isEqualTo: userId)
        .limit(_maxEventRsvps)
        .get();

    final eventIds = <String>{};
    for (final doc in attendeeSnap.docs) {
      // Path: events/{eventId}/attendees/{docId}
      final segments = doc.reference.path.split('/');
      if (segments.length >= 2) eventIds.add(segments[1]);
    }
    if (eventIds.isEmpty) return <String>{};

    final categories = <String>{};
    final ids = eventIds.toList();
    for (var i = 0; i < ids.length; i += _whereInBatch) {
      final batch = ids.skip(i).take(_whereInBatch).toList();
      final snap = await _firestore
          .collection(_eventsCol)
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final doc in snap.docs) {
        final category = doc.data()['category'];
        if (category is String && category.trim().isNotEmpty) {
          categories.add(category.trim());
        }
      }
    }
    return categories;
  }

  /// Extracts every resolvable country ISO code from a profile document.
  Iterable<String> _profileCountryCodes(Map<String, dynamic>? data) sync* {
    if (data == null) return;

    final location = data['location'];
    if (location is Map) {
      final code = _resolveCountryCode(location['country']?.toString());
      if (code != null) yield code;
    }
    for (final key in const ['primaryOrigin', 'secondaryOrigin']) {
      final code = _resolveCountryCode(data[key]?.toString());
      if (code != null) yield code;
    }
  }

  /// Extracts the language names a profile document speaks / wants to learn.
  Iterable<String> _profileLanguages(Map<String, dynamic>? data) sync* {
    if (data == null) return;
    for (final key in const ['languages', 'preferredLanguages']) {
      final value = data[key];
      if (value is List) {
        for (final lang in value) {
          if (lang is String && lang.trim().isNotEmpty) yield lang.trim();
        }
      }
    }
    final native = data['nativeLanguage'];
    if (native is String && native.trim().isNotEmpty) yield native.trim();
  }

  /// Resolves a country name or code to an ISO 3166-1 alpha-2 code.
  static String? _resolveCountryCode(String? country) {
    if (country == null) return null;
    final raw = country.trim();
    if (raw.isEmpty) return null;
    // CountryFlagColors handles alpha-2 codes + ~50 common English names.
    final byColors = CountryFlagColors.resolveCode(raw);
    if (byColors != null) return byColors;
    // Fall back to the full 198-country name table.
    if (raw.length == 2) return raw.toUpperCase();
    return CountryFlagHelper.getCodeFromName(raw);
  }
}
