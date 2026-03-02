import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/cultural_tip.dart';
import '../models/country_spotlight_model.dart';
import '../models/cultural_tip_model.dart';
import '../models/dating_etiquette_model.dart';

abstract class CulturalExchangeRemoteDataSource {
  Future<CountrySpotlightModel?> getActiveSpotlight();
  Future<List<CountrySpotlightModel>> getSpotlightHistory();
  Future<List<CulturalTipModel>> getCulturalTips({
    String? country,
    String? category,
  });
  Future<void> submitCulturalTip(CulturalTipModel tip);
  Future<void> likeCulturalTip(String tipId, String userId);
  Future<DatingEtiquetteModel?> getDatingEtiquette(String country);
  Future<List<String>> getAvailableCountries();
}

class CulturalExchangeRemoteDataSourceImpl
    implements CulturalExchangeRemoteDataSource {
  final FirebaseFirestore _firestore;

  CulturalExchangeRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  // ==================== Collection References ====================

  CollectionReference<Map<String, dynamic>> get _spotlightsCollection =>
      _firestore.collection('country_spotlights');

  CollectionReference<Map<String, dynamic>> get _tipsCollection =>
      _firestore.collection('cultural_tips');

  CollectionReference<Map<String, dynamic>> get _etiquetteCollection =>
      _firestore.collection('dating_etiquette');

  // ==================== Country Spotlights ====================

  @override
  Future<CountrySpotlightModel?> getActiveSpotlight() async {
    try {
      final snapshot = await _spotlightsCollection
          .where('isActive', isEqualTo: true)
          .orderBy('weekOf', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return CountrySpotlightModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      // If index not ready, try fetching the most recent spotlight
      try {
        final snapshot = await _spotlightsCollection
            .orderBy('weekOf', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) return null;

        final model = CountrySpotlightModel.fromFirestore(snapshot.docs.first);
        if (model.isActive) return model;
        return null;
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<List<CountrySpotlightModel>> getSpotlightHistory() async {
    try {
      final snapshot = await _spotlightsCollection
          .orderBy('weekOf', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => CountrySpotlightModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== Cultural Tips ====================

  @override
  Future<List<CulturalTipModel>> getCulturalTips({
    String? country,
    String? category,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _tipsCollection;

      if (country != null && country.isNotEmpty) {
        query = query.where('country', isEqualTo: country);
      }

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => CulturalTipModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Fallback without ordering if index is missing
      try {
        Query<Map<String, dynamic>> query = _tipsCollection;

        if (country != null && country.isNotEmpty) {
          query = query.where('country', isEqualTo: country);
        }

        final snapshot = await query.limit(50).get();

        final tips = snapshot.docs
            .map((doc) => CulturalTipModel.fromFirestore(doc))
            .toList();

        // Filter category locally if needed
        if (category != null && category.isNotEmpty) {
          final tipCategory = TipCategory.values.firstWhere(
            (e) => e.name == category,
            orElse: () => TipCategory.customs,
          );
          return tips.where((t) => t.category == tipCategory).toList();
        }

        // Sort locally by createdAt descending
        tips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return tips;
      } catch (_) {
        return [];
      }
    }
  }

  @override
  Future<void> submitCulturalTip(CulturalTipModel tip) async {
    await _tipsCollection.add(tip.toJson());
  }

  @override
  Future<void> likeCulturalTip(String tipId, String userId) async {
    final tipRef = _tipsCollection.doc(tipId);
    final likesRef = tipRef.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final likeDoc = await transaction.get(likesRef);

      if (likeDoc.exists) {
        // User already liked — unlike
        transaction.delete(likesRef);
        transaction.update(tipRef, {
          'likes': FieldValue.increment(-1),
        });
      } else {
        // Add like
        transaction.set(likesRef, {
          'userId': userId,
          'likedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(tipRef, {
          'likes': FieldValue.increment(1),
        });
      }
    });
  }

  // ==================== Dating Etiquette ====================

  @override
  Future<DatingEtiquetteModel?> getDatingEtiquette(String country) async {
    try {
      final doc = await _etiquetteCollection.doc(country).get();

      if (!doc.exists || doc.data() == null) return null;

      return DatingEtiquetteModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<String>> getAvailableCountries() async {
    try {
      final snapshot = await _etiquetteCollection.get();

      return snapshot.docs.map((doc) => doc.id).toList()..sort();
    } catch (e) {
      return [];
    }
  }
}
