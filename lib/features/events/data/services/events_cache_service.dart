import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/cache/last_result_cache.dart';
import '../../domain/entities/event.dart';
import '../models/event_model.dart';

/// Stale-while-revalidate cache for the Community events feed.
///
/// After every SERVER load the screen records the ordered ids it rendered;
/// on the next open [loadCommunity] paints exactly those events, read by id
/// from the local Firestore cache (milliseconds, no network), and the screen
/// ALWAYS follows with the server query, which replaces the list. See
/// [LastResultCache] for why this is not a query against the disk cache.
class EventsCacheService {
  const EventsCacheService();

  static const String _communityKey = 'events_community_nearby';

  /// The community feed last shown, minus anything that has since ended or
  /// stopped being public/live. Empty when nothing usable is cached.
  Future<List<Event>> loadCommunity() async {
    unawaited(_purgeLegacy());
    try {
      final docs = await LastResultCache.loadDocs(
          _communityKey, FirebaseFirestore.instance.collection('events'));
      final now = DateTime.now();
      return docs
          .map(EventModel.fromFirestore)
          .where((e) => e.isPublic && e.isLive && !e.endDate.isBefore(now))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Record the feed just loaded from the server, in display order.
  Future<void> saveCommunity(List<Event> events) =>
      LastResultCache.saveIds(_communityKey, events.map((e) => e.id));

  static bool _purged = false;

  /// The previous daily cache kept whole event JSON in SharedPreferences,
  /// which is loaded into memory at every launch. Drop it once.
  static Future<void> _purgeLegacy() async {
    if (_purged) return;
    _purged = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys().toList()) {
        if (k.startsWith('events_feed_cache_')) await prefs.remove(k);
      }
    } catch (_) {}
  }
}
