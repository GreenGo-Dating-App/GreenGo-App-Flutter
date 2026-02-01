import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/second_chance_model.dart';

/// Remote data source for Second Chance feature
abstract class SecondChanceRemoteDataSource {
  /// Get available second chance profiles
  Future<List<SecondChanceProfileModel>> getSecondChanceProfiles(String userId);

  /// Get usage for today
  Future<SecondChanceUsageModel> getUsage(String userId);

  /// Like a second chance profile
  Future<SecondChanceResultModel> likeSecondChance({
    required String userId,
    required String entryId,
  });

  /// Pass on a second chance profile
  Future<void> passSecondChance({
    required String userId,
    required String entryId,
  });

  /// Purchase unlimited second chances
  Future<SecondChanceUsageModel> purchaseUnlimited(String userId);

  /// Stream second chance profiles
  Stream<List<SecondChanceProfileModel>> streamSecondChances(String userId);
}

/// Implementation of Second Chance remote data source
class SecondChanceRemoteDataSourceImpl implements SecondChanceRemoteDataSource {
  final FirebaseFunctions functions;
  final FirebaseFirestore firestore;

  SecondChanceRemoteDataSourceImpl({
    required this.functions,
    required this.firestore,
  });

  @override
  Future<List<SecondChanceProfileModel>> getSecondChanceProfiles(
    String userId,
  ) async {
    final callable = functions.httpsCallable('getSecondChanceProfiles');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
    });

    final profiles = result.data['profiles'] as List<dynamic>;
    return profiles
        .map((p) => SecondChanceProfileModel.fromMap(p as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SecondChanceUsageModel> getUsage(String userId) async {
    final callable = functions.httpsCallable('getSecondChanceUsage');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
    });

    return SecondChanceUsageModel.fromMap(
      result.data['usage'] as Map<String, dynamic>,
    );
  }

  @override
  Future<SecondChanceResultModel> likeSecondChance({
    required String userId,
    required String entryId,
  }) async {
    final callable = functions.httpsCallable('likeSecondChance');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'entryId': entryId,
    });

    return SecondChanceResultModel.fromMap(result.data);
  }

  @override
  Future<void> passSecondChance({
    required String userId,
    required String entryId,
  }) async {
    final callable = functions.httpsCallable('passSecondChance');
    await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'entryId': entryId,
    });
  }

  @override
  Future<SecondChanceUsageModel> purchaseUnlimited(String userId) async {
    final callable = functions.httpsCallable('purchaseUnlimitedSecondChances');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
    });

    return SecondChanceUsageModel.fromMap(
      result.data['usage'] as Map<String, dynamic>,
    );
  }

  @override
  Stream<List<SecondChanceProfileModel>> streamSecondChances(String userId) {
    // This would typically come from a cloud function that aggregates data
    // For simplicity, we just stream entries and would need to join with profiles
    return firestore
        .collection('secondChancePool')
        .where('userId', isEqualTo: userId)
        .where('isUsed', isEqualTo: false)
        .where('availableUntil', isGreaterThan: Timestamp.now())
        .snapshots()
        .asyncMap((snapshot) async {
      // In a real implementation, you'd fetch the profiles for each entry
      // For now, returning empty list - actual implementation would join data
      return <SecondChanceProfileModel>[];
    });
  }
}
