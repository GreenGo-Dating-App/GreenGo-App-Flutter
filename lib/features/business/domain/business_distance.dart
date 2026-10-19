import '../../matching/domain/entities/match_candidate.dart';
import '../../matching/domain/usecases/feature_engineer.dart';
import '../../profile/domain/entities/location.dart';
import '../../profile/domain/entities/profile.dart';

/// Distance to a BUSINESS (owner rule 2026-10-19).
///
/// A business's distance is measured from its PUBLIC storefront address
/// ([Profile.businessAddress], the pin shown on the storefront map) to the
/// viewer's own location, never from the owner's personal (private, offset)
/// location. Because the address is public, the result is shown with 100 m
/// resolution (`preciseDistanceLabel`), like the 'exact' discoverability
/// opt-in. Businesses without an address keep the candidate's existing
/// (owner-location based, bucketed) distance.
class BusinessDistance {
  BusinessDistance._();

  static final FeatureEngineer _fe = FeatureEngineer();

  static bool _usable(double lat, double lng) =>
      lat.isFinite &&
      lng.isFinite &&
      lat.abs() <= 90 &&
      lng.abs() <= 180 &&
      !(lat == 0 && lng == 0);

  /// Km from [viewer] to [business]'s storefront address, or null when the
  /// profile is not a business, has no usable address, or the viewer's
  /// location is unknown.
  static double? kmToAddress(Profile business, Location? viewer) {
    if (!business.isBusiness || viewer == null) return null;
    final a = business.businessAddress;
    if (a == null || !_usable(a.latitude, a.longitude)) return null;
    if (!_usable(viewer.latitude, viewer.longitude)) return null;
    return _fe.calculateDistance(
        viewer.latitude, viewer.longitude, a.latitude, a.longitude);
  }

  /// Re-measures every business in [list] from its address (see
  /// [kmToAddress]) and orders the list nearest-first. Candidates whose
  /// distance is unknown (0 and not address based) go last; ties keep their
  /// incoming order (stable). Returns the new list and the ids whose distance
  /// came from the business address (rendered with 100 m resolution).
  static ({List<MatchCandidate> candidates, Set<String> addressBasedIds})
      nearestFirst(List<MatchCandidate> list, Location? viewer) {
    final addressBased = <String>{};
    final measured = <(int, MatchCandidate, double?)>[];
    for (var i = 0; i < list.length; i++) {
      final c = list[i];
      final km = kmToAddress(c.profile, viewer);
      if (km != null) {
        addressBased.add(c.profile.userId);
        measured.add((
          i,
          MatchCandidate(
            profile: c.profile,
            matchScore: c.matchScore,
            distance: km,
            suggestedAt: c.suggestedAt,
            isSuperLike: c.isSuperLike,
          ),
          km,
        ));
      } else {
        measured.add((i, c, c.distance > 0 ? c.distance : null));
      }
    }
    measured.sort((a, b) {
      final da = a.$3, db = b.$3;
      if (da == null && db == null) return a.$1.compareTo(b.$1);
      if (da == null) return 1;
      if (db == null) return -1;
      final cmp = da.compareTo(db);
      return cmp != 0 ? cmp : a.$1.compareTo(b.$1);
    });
    return (
      candidates: [for (final m in measured) m.$2],
      addressBasedIds: addressBased,
    );
  }
}
