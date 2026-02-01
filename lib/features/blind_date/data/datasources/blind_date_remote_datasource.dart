import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/blind_date.dart';
import '../models/blind_date_model.dart';

/// Remote data source for blind date feature
abstract class BlindDateRemoteDataSource {
  /// Create a blind date profile
  Future<BlindDateProfileModel> createBlindProfile(String userId);

  /// Get user's blind date profile
  Future<BlindDateProfileModel?> getBlindProfile(String userId);

  /// Deactivate blind date profile
  Future<void> deactivateBlindProfile(String userId);

  /// Get blind date candidates
  Future<List<BlindProfileViewModel>> getBlindCandidates({
    required String userId,
    int limit = 10,
  });

  /// Like a blind profile
  Future<BlindLikeResult> likeBlindProfile({
    required String userId,
    required String targetUserId,
  });

  /// Pass on a blind profile
  Future<void> passBlindProfile({
    required String userId,
    required String targetUserId,
  });

  /// Get blind matches
  Future<List<BlindMatchModel>> getBlindMatches(String userId);

  /// Stream blind matches
  Stream<List<BlindMatchModel>> streamBlindMatches(String userId);

  /// Instant reveal photos
  Future<BlindMatchModel> instantReveal({
    required String userId,
    required String matchId,
  });

  /// Check reveal status
  Future<bool> checkRevealStatus(String matchId);

  /// Update message count
  Future<BlindMatchModel> updateMessageCount({
    required String matchId,
    required int newCount,
  });

  /// Get revealed profile
  Future<BlindProfileViewModel> getRevealedProfile({
    required String matchId,
    required String userId,
  });
}

/// Implementation of blind date remote data source
class BlindDateRemoteDataSourceImpl implements BlindDateRemoteDataSource {
  final FirebaseFunctions functions;
  final FirebaseFirestore firestore;

  BlindDateRemoteDataSourceImpl({
    required this.functions,
    required this.firestore,
  });

  @override
  Future<BlindDateProfileModel> createBlindProfile(String userId) async {
    final callable = functions.httpsCallable('createBlindProfile');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
    });

    return BlindDateProfileModel.fromJson(
      result.data['profile'] as Map<String, dynamic>,
    );
  }

  @override
  Future<BlindDateProfileModel?> getBlindProfile(String userId) async {
    final callable = functions.httpsCallable('getBlindProfile');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
    });

    if (result.data['profile'] == null) return null;

    return BlindDateProfileModel.fromJson(
      result.data['profile'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deactivateBlindProfile(String userId) async {
    final callable = functions.httpsCallable('deactivateBlindProfile');
    await callable.call<Map<String, dynamic>>({
      'userId': userId,
    });
  }

  @override
  Future<List<BlindProfileViewModel>> getBlindCandidates({
    required String userId,
    int limit = 10,
  }) async {
    final callable = functions.httpsCallable('getBlindCandidates');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'limit': limit,
    });

    final candidates = result.data['candidates'] as List<dynamic>;
    return candidates
        .map((c) => BlindProfileViewModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BlindLikeResult> likeBlindProfile({
    required String userId,
    required String targetUserId,
  }) async {
    final callable = functions.httpsCallable('likeBlindProfile');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'targetUserId': targetUserId,
    });

    final resultType = result.data['result'] as String;
    switch (resultType) {
      case 'matched':
        return BlindLikeResult.matched;
      case 'pending':
        return BlindLikeResult.pending;
      case 'already_actioned':
        return BlindLikeResult.alreadyActioned;
      default:
        return BlindLikeResult.pending;
    }
  }

  @override
  Future<void> passBlindProfile({
    required String userId,
    required String targetUserId,
  }) async {
    final callable = functions.httpsCallable('passBlindProfile');
    await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'targetUserId': targetUserId,
    });
  }

  @override
  Future<List<BlindMatchModel>> getBlindMatches(String userId) async {
    final callable = functions.httpsCallable('getBlindMatches');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
    });

    final matches = result.data['matches'] as List<dynamic>;
    return matches
        .map((m) => BlindMatchModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<BlindMatchModel>> streamBlindMatches(String userId) {
    return firestore
        .collection('blindMatches')
        .where('participants', arrayContains: userId)
        .orderBy('matchedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BlindMatchModel.fromFirestore(doc))
            .toList());
  }

  @override
  Future<BlindMatchModel> instantReveal({
    required String userId,
    required String matchId,
  }) async {
    final callable = functions.httpsCallable('instantReveal');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'matchId': matchId,
    });

    return BlindMatchModel.fromJson(
      result.data['match'] as Map<String, dynamic>,
    );
  }

  @override
  Future<bool> checkRevealStatus(String matchId) async {
    final callable = functions.httpsCallable('checkRevealStatus');
    final result = await callable.call<Map<String, dynamic>>({
      'matchId': matchId,
    });

    return result.data['isRevealed'] as bool;
  }

  @override
  Future<BlindMatchModel> updateMessageCount({
    required String matchId,
    required int newCount,
  }) async {
    final callable = functions.httpsCallable('updateBlindMatchMessageCount');
    final result = await callable.call<Map<String, dynamic>>({
      'matchId': matchId,
      'messageCount': newCount,
    });

    return BlindMatchModel.fromJson(
      result.data['match'] as Map<String, dynamic>,
    );
  }

  @override
  Future<BlindProfileViewModel> getRevealedProfile({
    required String matchId,
    required String userId,
  }) async {
    final callable = functions.httpsCallable('getRevealedProfile');
    final result = await callable.call<Map<String, dynamic>>({
      'matchId': matchId,
      'userId': userId,
    });

    return BlindProfileViewModel.fromJson(
      result.data['profile'] as Map<String, dynamic>,
    );
  }
}
