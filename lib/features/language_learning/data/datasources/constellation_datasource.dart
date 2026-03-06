import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/cache_service.dart';
import '../models/constellation_node_model.dart';

class ConstellationDatasource {
  final FirebaseFirestore firestore;
  final CacheService cacheService;

  static const Duration _cacheTTL = Duration(hours: 24);

  ConstellationDatasource({
    required this.firestore,
    required this.cacheService,
  });

  CollectionReference get _col => firestore.collection('constellation');

  String _cacheKey(String src, String tgt) => 'constellation_${src}_$tgt';
  String _unitCacheKey(String src, String tgt, int unit) =>
      'constellation_${src}_${tgt}_u$unit';

  /// Fetches all constellation nodes for a language pair, ordered by
  /// unit then nodeIndex. Uses local cache when available.
  Future<List<ConstellationNodeModel>> getConstellation({
    required String langSource,
    required String langTarget,
  }) async {
    final key = _cacheKey(langSource, langTarget);

    // Check cache first
    final cached = cacheService.getList(key);
    if (cached != null) {
      return cached
          .map((json) => ConstellationNodeModel.fromJson(json))
          .toList();
    }

    // Fetch from Firestore
    developer.log(
      'Fetching constellation: $langSource → $langTarget',
      name: 'ConstellationDS',
    );
    try {
      final snap = await _col
          .where('languageSource', isEqualTo: langSource)
          .where('languageTarget', isEqualTo: langTarget)
          .orderBy('unit')
          .orderBy('nodeIndex')
          .get();

      developer.log(
        'Constellation query returned ${snap.docs.length} docs',
        name: 'ConstellationDS',
      );

      final models = snap.docs
          .map((doc) => ConstellationNodeModel.fromFirestore(doc))
          .toList();

      // Cache results
      if (models.isNotEmpty) {
        await cacheService.cacheList(
          key,
          models.map((m) => m.toJson()).toList(),
          ttl: _cacheTTL,
        );
      }

      return models;
    } catch (e) {
      developer.log(
        'Constellation query FAILED: $e',
        name: 'ConstellationDS',
        error: e,
      );
      rethrow;
    }
  }

  /// Fetches constellation nodes for a specific unit. Uses local cache.
  Future<List<ConstellationNodeModel>> getUnit({
    required String langSource,
    required String langTarget,
    required int unit,
  }) async {
    final key = _unitCacheKey(langSource, langTarget, unit);

    // Check cache first
    final cached = cacheService.getList(key);
    if (cached != null) {
      return cached
          .map((json) => ConstellationNodeModel.fromJson(json))
          .toList();
    }

    // Fetch from Firestore
    final snap = await _col
        .where('languageSource', isEqualTo: langSource)
        .where('languageTarget', isEqualTo: langTarget)
        .where('unit', isEqualTo: unit)
        .orderBy('nodeIndex')
        .get();

    final models = snap.docs
        .map((doc) => ConstellationNodeModel.fromFirestore(doc))
        .toList();

    // Cache results
    if (models.isNotEmpty) {
      await cacheService.cacheList(
        key,
        models.map((m) => m.toJson()).toList(),
        ttl: _cacheTTL,
      );
    }

    return models;
  }

  /// Invalidate cached constellation data for a language pair.
  Future<void> invalidateCache(String langSource, String langTarget) async {
    await cacheService.remove(_cacheKey(langSource, langTarget));
  }
}
