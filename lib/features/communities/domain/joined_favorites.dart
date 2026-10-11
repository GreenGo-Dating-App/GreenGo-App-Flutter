import 'entities/community.dart';

/// The Joined tab's two sections: starred favorites pinned on top, then the
/// rest of the joined communities in their existing order.
class JoinedArrangement {
  const JoinedArrangement({required this.favorites, required this.others});

  final List<Community> favorites;
  final List<Community> others;

  bool get isEmpty => favorites.isEmpty && others.isEmpty;
}

/// Pins favorites on top of the Joined list.
///
///  * [favoriteIds] is the stored starring order (oldest first); favorites
///    are shown NEWEST-STARRED FIRST.
///  * A favorite's document comes from [joined] when present (freshest),
///    else from [favoriteDocs] (loaded separately, so favorites paint even
///    when they are not in the part of the joined list loaded so far).
///  * Once [joinedLoaded], a favorite the user is no longer a member of is
///    hidden (left on another device, removed by a moderator...).
///  * [query] filters both sections by name / description.
JoinedArrangement arrangeJoinedCommunities({
  required List<Community> joined,
  required List<String> favoriteIds,
  Map<String, Community> favoriteDocs = const {},
  bool joinedLoaded = true,
  String query = '',
}) {
  final q = query.trim().toLowerCase();
  bool matches(Community c) =>
      q.isEmpty ||
      c.name.toLowerCase().contains(q) ||
      c.description.toLowerCase().contains(q);

  final joinedById = {for (final c in joined) c.id: c};
  final favSet = favoriteIds.toSet();
  final favorites = <Community>[];
  for (final id in favoriteIds.reversed) {
    if (joinedLoaded && !joinedById.containsKey(id)) continue;
    final c = joinedById[id] ?? favoriteDocs[id];
    if (c != null && matches(c)) favorites.add(c);
  }
  final others = [
    for (final c in joined)
      if (!favSet.contains(c.id) && matches(c)) c,
  ];
  return JoinedArrangement(favorites: favorites, others: others);
}
