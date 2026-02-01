import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/vibe_tag_model.dart';

/// Vibe Tag Remote Data Source
abstract class VibeTagRemoteDataSource {
  /// Get all available vibe tags
  Future<List<VibeTagModel>> getVibeTags();

  /// Get vibe tags by category
  Future<List<VibeTagModel>> getVibeTagsByCategory(String category);

  /// Get user's selected vibe tags
  Future<UserVibeTagsModel> getUserVibeTags(String userId);

  /// Stream user's vibe tags
  Stream<UserVibeTagsModel> streamUserVibeTags(String userId);

  /// Update user's selected vibe tags
  Future<UserVibeTagsModel> updateUserVibeTags({
    required String userId,
    required List<String> tagIds,
  });

  /// Set a temporary vibe tag
  Future<UserVibeTagsModel> setTemporaryVibeTag({
    required String userId,
    required String tagId,
  });

  /// Remove a vibe tag from user's selection
  Future<UserVibeTagsModel> removeVibeTag({
    required String userId,
    required String tagId,
  });

  /// Search users by vibe tags
  Future<List<String>> searchUsersByVibeTags({
    required List<String> tagIds,
    int limit = 20,
    String? lastUserId,
  });

  /// Get vibe tag by ID
  Future<VibeTagModel> getVibeTagById(String tagId);
}

/// Implementation of Vibe Tag Remote Data Source
class VibeTagRemoteDataSourceImpl implements VibeTagRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  VibeTagRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<List<VibeTagModel>> getVibeTags() async {
    final callable = _functions.httpsCallable('getVibeTags');
    final result = await callable.call<Map<String, dynamic>>();

    final tags = result.data['tags'] as List<dynamic>;
    return tags.map((tag) {
      final tagMap = tag as Map<String, dynamic>;
      return VibeTagModel.fromMap(tagMap, tagMap['id'] as String);
    }).toList();
  }

  @override
  Future<List<VibeTagModel>> getVibeTagsByCategory(String category) async {
    final snapshot = await _firestore
        .collection('vibeTags')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .get();

    return snapshot.docs.map((doc) => VibeTagModel.fromFirestore(doc)).toList();
  }

  @override
  Future<UserVibeTagsModel> getUserVibeTags(String userId) async {
    final callable = _functions.httpsCallable('getUserVibeTags');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
    });

    final data = result.data;
    return UserVibeTagsModel(
      userId: userId,
      selectedTagIds: List<String>.from(data['selectedTagIds'] ?? []),
      temporaryTagId: data['temporaryTagId'] as String?,
      temporaryTagExpiresAt: data['temporaryTagExpiresAt'] != null
          ? DateTime.parse(data['temporaryTagExpiresAt'] as String)
          : null,
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  Stream<UserVibeTagsModel> streamUserVibeTags(String userId) {
    return _firestore
        .collection('userVibeTags')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return UserVibeTagsModel.empty(userId);
      }
      return UserVibeTagsModel.fromFirestore(snapshot);
    });
  }

  @override
  Future<UserVibeTagsModel> updateUserVibeTags({
    required String userId,
    required List<String> tagIds,
  }) async {
    final callable = _functions.httpsCallable('updateUserVibeTags');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'tagIds': tagIds,
    });

    final data = result.data;
    return UserVibeTagsModel(
      userId: userId,
      selectedTagIds: List<String>.from(data['selectedTagIds'] ?? []),
      temporaryTagId: data['temporaryTagId'] as String?,
      temporaryTagExpiresAt: data['temporaryTagExpiresAt'] != null
          ? DateTime.parse(data['temporaryTagExpiresAt'] as String)
          : null,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<UserVibeTagsModel> setTemporaryVibeTag({
    required String userId,
    required String tagId,
  }) async {
    final callable = _functions.httpsCallable('setTemporaryVibeTag');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'tagId': tagId,
    });

    final data = result.data;
    return UserVibeTagsModel(
      userId: userId,
      selectedTagIds: List<String>.from(data['selectedTagIds'] ?? []),
      temporaryTagId: data['temporaryTagId'] as String?,
      temporaryTagExpiresAt: data['temporaryTagExpiresAt'] != null
          ? DateTime.parse(data['temporaryTagExpiresAt'] as String)
          : null,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<UserVibeTagsModel> removeVibeTag({
    required String userId,
    required String tagId,
  }) async {
    final callable = _functions.httpsCallable('removeVibeTag');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'tagId': tagId,
    });

    final data = result.data;
    return UserVibeTagsModel(
      userId: userId,
      selectedTagIds: List<String>.from(data['selectedTagIds'] ?? []),
      temporaryTagId: data['temporaryTagId'] as String?,
      temporaryTagExpiresAt: data['temporaryTagExpiresAt'] != null
          ? DateTime.parse(data['temporaryTagExpiresAt'] as String)
          : null,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<String>> searchUsersByVibeTags({
    required List<String> tagIds,
    int limit = 20,
    String? lastUserId,
  }) async {
    final callable = _functions.httpsCallable('searchByVibeTags');
    final result = await callable.call<Map<String, dynamic>>({
      'tagIds': tagIds,
      'limit': limit,
      if (lastUserId != null) 'lastUserId': lastUserId,
    });

    return List<String>.from(result.data['userIds'] ?? []);
  }

  @override
  Future<VibeTagModel> getVibeTagById(String tagId) async {
    final doc = await _firestore.collection('vibeTags').doc(tagId).get();

    if (!doc.exists) {
      throw Exception('Vibe tag not found');
    }

    return VibeTagModel.fromFirestore(doc);
  }
}
