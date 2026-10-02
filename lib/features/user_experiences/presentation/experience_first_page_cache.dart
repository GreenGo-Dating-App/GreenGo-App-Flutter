import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/cache/last_result_cache.dart';
import '../../../core/utils/display_image.dart';
import '../data/datasources/user_experiences_remote_datasource.dart';
import '../data/models/user_experience_model.dart';
import '../domain/entities/user_experience.dart';

/// "Paint what was shown last time, then refresh" for experience lists, on
/// top of [LastResultCache] (ids saved after a server load, documents read
/// back by id from the LOCAL Firestore cache only).
///
/// Never throws: any failure (no cache box, signed out, Firebase not ready)
/// is an empty result, so callers simply skip the cached paint.
class ExperienceFirstPageCache {
  const ExperienceFirstPageCache();

  /// The experiences last saved under [key] (public lists: only those still
  /// published). Empty when nothing usable is cached.
  Future<List<UserExperience>> load(String key) async {
    try {
      final ids = await LastResultCache.loadIds(key);
      if (ids.isEmpty) return const [];
      final docs = await LastResultCache.loadDocs(
          key,
          FirebaseFirestore.instance
              .collection(UserExperiencesRemoteDataSource.collection));
      // A host's own list legitimately holds drafts (and anything without a
      // picture); public lists must not resurface a listing unpublished
      // since, nor one the live feed hides for having no picture.
      final own = key.startsWith('uexp_host_');
      return docs
          .map(UserExperienceModel.fromDoc)
          .where((e) =>
              own ||
              (e.status == ExperienceStatus.published &&
                  experienceHasPicture(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(String key, List<UserExperience> page) async {
    try {
      await LastResultCache.saveIds(key, page.map((e) => e.id));
    } catch (_) {/* best-effort */}
  }
}
