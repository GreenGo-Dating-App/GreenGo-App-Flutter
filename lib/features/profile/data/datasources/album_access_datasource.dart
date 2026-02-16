import 'package:cloud_firestore/cloud_firestore.dart';

/// Album Access Datasource
///
/// Manages private album access grants between users
class AlbumAccessDatasource {
  final FirebaseFirestore firestore;

  AlbumAccessDatasource({required this.firestore});

  /// Grant access to private album
  Future<void> grantAccess({
    required String ownerId,
    required String grantedToId,
  }) async {
    try {
      // Check if access already exists
      final existing = await firestore
          .collection('album_access')
          .where('ownerId', isEqualTo: ownerId)
          .where('grantedToId', isEqualTo: grantedToId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) return;

      await firestore.collection('album_access').add({
        'ownerId': ownerId,
        'grantedToId': grantedToId,
        'grantedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to grant album access: $e');
    }
  }

  /// Revoke access to private album
  Future<void> revokeAccess({
    required String ownerId,
    required String grantedToId,
  }) async {
    try {
      final query = await firestore
          .collection('album_access')
          .where('ownerId', isEqualTo: ownerId)
          .where('grantedToId', isEqualTo: grantedToId)
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to revoke album access: $e');
    }
  }

  /// Check if a user has access to another user's private album
  Future<bool> hasAccess({
    required String ownerId,
    required String viewerId,
  }) async {
    try {
      final query = await firestore
          .collection('album_access')
          .where('ownerId', isEqualTo: ownerId)
          .where('grantedToId', isEqualTo: viewerId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get all users who have been granted access to an album
  Future<List<String>> getGrantedUsers(String ownerId) async {
    try {
      final query = await firestore
          .collection('album_access')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      return query.docs
          .map((doc) => doc.data()['grantedToId'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all albums a user has been granted access to
  Future<List<String>> getAccessibleAlbums(String viewerId) async {
    try {
      final query = await firestore
          .collection('album_access')
          .where('grantedToId', isEqualTo: viewerId)
          .get();

      return query.docs
          .map((doc) => doc.data()['ownerId'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
