import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../di/injection_container.dart';

/// Lightweight public profile summary used to render names/avatars for user ids
/// (group members, message senders) without storing duplicated name data.
class UserBrief {
  const UserBrief({required this.name, this.photoUrl, this.language});
  final String name;
  final String? photoUrl;

  /// Primary language (a code like `en`/`pt_BR` or a display name) — used to
  /// show the member's origin flag in group chats. Null when unknown.
  final String? language;
}

/// Resolves user ids → display name + avatar, with a process-wide in-memory
/// cache so repeated lookups (group info, message bubbles) are O(1) after the
/// first fetch. Scales fine: groups are capped small and results are cached.
class UserDirectoryService {
  UserDirectoryService._();
  static final UserDirectoryService instance = UserDirectoryService._();

  final Map<String, UserBrief> _cache = {};

  /// Synchronously returns a cached brief, or null if not yet loaded.
  UserBrief? cached(String uid) => _cache[uid];

  /// Synchronously returns a display name for [uid] (cached, else the raw id).
  String nameFor(String uid) => _cache[uid]?.name ?? uid;

  /// Fetches and caches briefs for [uids] (only the ones not already cached).
  Future<Map<String, UserBrief>> resolve(Iterable<String> uids) async {
    final unique = uids.toSet();
    final missing = unique.where((u) => !_cache.containsKey(u)).toList();
    if (missing.isNotEmpty) {
      final ds = sl<ProfileRemoteDataSource>();
      await Future.wait(missing.map((u) async {
        try {
          final p = await ds.getProfile(u);
          final name = p.displayName.trim().isNotEmpty
              ? p.displayName.trim()
              : (p.nickname != null && p.nickname!.isNotEmpty
                  ? '@${p.nickname}'
                  : u);
          _cache[u] = UserBrief(
            name: name,
            photoUrl: p.photoUrls.isNotEmpty ? p.photoUrls.first : null,
            language: p.languages.isNotEmpty ? p.languages.first : null,
          );
        } catch (_) {
          _cache[u] = UserBrief(name: u);
        }
      }));
    }
    return {for (final u in unique) u: _cache[u] ?? UserBrief(name: u)};
  }
}
