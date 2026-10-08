import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'private_profile.dart';

/// Private-album photo URLs (security P1-4: `privatePhotoUrls` moved to the
/// owner-only `profiles_private`).
class PrivateAlbum {
  const PrivateAlbum._();

  /// The signed-in user's OWN private album: profiles_private first, the
  /// legacy public field (profiles written by old app versions) as fallback.
  static Future<List<String>> own(String uid,
      {FirebaseFirestore? firestore}) async {
    final fs = firestore ?? FirebaseFirestore.instance;
    try {
      final priv = (await privateProfileRef(fs, uid).get()).data();
      final list = priv?['privatePhotoUrls'];
      if (list is List && list.isNotEmpty) return list.cast<String>();
    } catch (e) {
      debugPrint('[PrivateAlbum] private read failed: $e');
    }
    final pub = (await fs.collection('profiles').doc(uid).get()).data();
    return (pub?['privatePhotoUrls'] as List<dynamic>? ?? const [])
        .cast<String>();
  }

  /// Another user's album the viewer was granted: through the
  /// `getSharedAlbum` callable, which checks the album_access grant on the
  /// server. Falls back to the legacy public field while the callable is not
  /// deployed yet.
  static Future<List<String>> sharedBy(String ownerId,
      {FirebaseFunctions? functions, FirebaseFirestore? firestore}) async {
    try {
      final res = await (functions ?? FirebaseFunctions.instance)
          .httpsCallable('getSharedAlbum')
          .call<Object?>({'ownerId': ownerId});
      final data = res.data;
      final urls = data is Map ? data['photoUrls'] : null;
      if (urls is List) return urls.cast<String>();
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied') return const [];
      debugPrint('[PrivateAlbum] getSharedAlbum failed: ${e.code}');
    } catch (e) {
      debugPrint('[PrivateAlbum] getSharedAlbum failed: $e');
    }
    final pub = (await (firestore ?? FirebaseFirestore.instance)
            .collection('profiles')
            .doc(ownerId)
            .get())
        .data();
    return (pub?['privatePhotoUrls'] as List<dynamic>? ?? const [])
        .cast<String>();
  }
}
