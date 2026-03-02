import '../../domain/entities/entities.dart';
import '../../domain/repositories/cultural_exchange_repository.dart';
import '../datasources/cultural_exchange_remote_datasource.dart';
import '../models/cultural_tip_model.dart';

class CulturalExchangeRepositoryImpl implements CulturalExchangeRepository {
  final CulturalExchangeRemoteDataSource remoteDataSource;

  CulturalExchangeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<CountrySpotlight?> getActiveSpotlight() async {
    try {
      return await remoteDataSource.getActiveSpotlight();
    } catch (e) {
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
  }) async {
    try {
      return await remoteDataSource.getCulturalTips(
        country: country,
        category: category,
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
      return await remoteDataSource.getAvailableCountries();
    } catch (e) {
      return [];
    }
  }
}
