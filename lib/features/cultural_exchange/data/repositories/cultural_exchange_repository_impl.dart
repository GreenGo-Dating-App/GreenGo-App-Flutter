import 'dart:async';

import '../../../../core/cache/last_result_cache.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/cultural_exchange_repository.dart';
import '../datasources/cultural_exchange_remote_datasource.dart';
import '../models/country_spotlight_model.dart';
import '../models/cultural_tip_model.dart';

class CulturalExchangeRepositoryImpl implements CulturalExchangeRepository {

  CulturalExchangeRepositoryImpl({required this.remoteDataSource});
  final CulturalExchangeRemoteDataSource remoteDataSource;

  static const String _kSpotlightKey = 'cultural_spotlight_v1';
  static const String _kCountriesKey = 'cultural_countries_v1';

  @override
  Future<CountrySpotlight?> getActiveSpotlight() async {
    try {
      final s = await remoteDataSource.getActiveSpotlight();
      if (s != null) {
        // JSON-safe copy (Timestamp → ISO string; fromJson accepts both).
        unawaited(LastResultCache.saveJson(_kSpotlightKey, {
          ...s.toJson(),
          'id': s.id,
          'weekOf': s.weekOf.toIso8601String(),
        }));
      }
      return s;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<CountrySpotlight?> getCachedActiveSpotlight() async {
    try {
      final v = await LastResultCache.loadJson(_kSpotlightKey);
      if (v is! Map) return null;
      final model =
          CountrySpotlightModel.fromJson(Map<String, dynamic>.from(v));
      return model.isActive ? model : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CountrySpotlight>> getSpotlightHistory() async {
    try {
      return await remoteDataSource.getSpotlightHistory();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<CulturalTip>> getCulturalTips({
    String? country,
    String? category,
    int limit = 50,
  }) async {
    try {
      return await remoteDataSource.getCulturalTips(
        country: country,
        category: category,
        limit: limit,
      );
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> submitCulturalTip(CulturalTip tip) async {
    try {
      final model = CulturalTipModel.fromEntity(tip);
      await remoteDataSource.submitCulturalTip(model);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> likeCulturalTip(String tipId, String userId) async {
    try {
      await remoteDataSource.likeCulturalTip(tipId, userId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<DatingEtiquette?> getDatingEtiquette(String country) async {
    try {
      return await remoteDataSource.getDatingEtiquette(country);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<String>> getAvailableCountries() async {
    try {
      final list = await remoteDataSource.getAvailableCountries();
      // There is no config doc listing the countries, so the list comes from
      // the (admin-seeded, rarely changing) collection — remember it.
      if (list.isNotEmpty) {
        unawaited(LastResultCache.saveJson(_kCountriesKey, list));
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<String>> getCachedAvailableCountries({Duration? maxAge}) async {
    try {
      final v = await LastResultCache.loadJson(_kCountriesKey,
          maxAge: maxAge ?? LastResultCache.defaultMaxAge);
      return v is List ? v.whereType<String>().toList() : const [];
    } catch (_) {
      return const [];
    }
  }

}
