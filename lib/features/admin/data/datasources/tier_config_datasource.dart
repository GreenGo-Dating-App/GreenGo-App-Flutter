import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tier_config_model.dart';
import '../../domain/entities/tier_config.dart';
import '../../../membership/domain/entities/membership.dart';

/// Tier Config Remote Data Source
abstract class TierConfigRemoteDataSource {
  /// Get all tier configurations
  Future<List<TierConfigModel>> getTierConfigs();

  /// Get config for a specific tier
  Future<TierConfigModel?> getTierConfig(MembershipTier tier);

  /// Update a tier configuration
  Future<void> updateTierConfig(TierConfig config, String adminId);

  /// Reset tier to default configuration
  Future<void> resetTierToDefaults(MembershipTier tier, String adminId);

  /// Initialize default configs if they don't exist
  Future<void> initializeDefaultConfigs();

  /// Stream of tier configs for real-time updates
  Stream<List<TierConfigModel>> watchTierConfigs();
}

/// Implementation of TierConfigRemoteDataSource
class TierConfigRemoteDataSourceImpl implements TierConfigRemoteDataSource {
  final FirebaseFirestore firestore;

  static const String _collection = 'tier_configs';

  TierConfigRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TierConfigModel>> getTierConfigs() async {
    final snapshot = await firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => TierConfigModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<TierConfigModel?> getTierConfig(MembershipTier tier) async {
    final configId = 'tier_${tier.value.toLowerCase()}';
    final doc = await firestore.collection(_collection).doc(configId).get();

    if (!doc.exists) return null;
    return TierConfigModel.fromFirestore(doc);
  }

  @override
  Future<void> updateTierConfig(TierConfig config, String adminId) async {
    final model = TierConfigModel.fromEntity(config.copyWith(
      updatedBy: adminId,
      updatedAt: DateTime.now(),
    ));

    await firestore
        .collection(_collection)
        .doc(config.configId)
        .set(model.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> resetTierToDefaults(MembershipTier tier, String adminId) async {
    final defaultConfig = TierConfig.withDefaults(tier);
    await updateTierConfig(defaultConfig, adminId);
  }

  @override
  Future<void> initializeDefaultConfigs() async {
    final batch = firestore.batch();

    for (final tier in MembershipTier.values) {
      final configId = 'tier_${tier.value.toLowerCase()}';
      final docRef = firestore.collection(_collection).doc(configId);
      final doc = await docRef.get();

      if (!doc.exists) {
        final defaultConfig = TierConfig.withDefaults(tier);
        final model = TierConfigModel.fromEntity(defaultConfig);
        batch.set(docRef, model.toMap());
      }
    }

    await batch.commit();
  }

  @override
  Stream<List<TierConfigModel>> watchTierConfigs() {
    return firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TierConfigModel.fromFirestore(doc))
            .toList());
  }
}
