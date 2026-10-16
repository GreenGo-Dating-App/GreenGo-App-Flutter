import 'package:intl/intl.dart';

import '../../generated/app_localizations.dart';

/// How far away another user is (security P1-4).
///
/// By default other users' positions are only known approximately
/// (`approxLocation`: a ~4.9 km geohash cell centre plus a stable offset of up
/// to 1.5 km), so the distance is shown as an upper limit ("< 5 km"): an
/// exact "1.3 km away" would be both misleading and a trilateration aid.
///
/// Exception, an explicit opt-in (owner rule 2026-10-16): a user who set
/// globe discoverability to 'exact' publishes `preciseLocation`, their
/// location plus a stable per-user offset of at most 100 m (server:
/// functions/src/profiles/privateProfile.ts). Distances to them are shown
/// with 100 m resolution ([preciseDistanceLabel]: "300 m", "1.2 km",
/// "23 km"). The Settings text tells the user exactly that.
///
/// [kDistanceStepsKm] is the single distance scale of the app: the labels
/// shown on cards AND the steps of the discovery distance filter.
const List<int> kDistanceStepsKm = [
  2, 5, 10, 30, 50, 100, 200, 500, 1000, 2000, 5000,
];

/// The upper limit (km) of the bucket containing [km]: the first step that
/// is greater than [km]. Returns 0 for "beyond the last step" (5000+ km) and
/// null when the distance is unknown (null, NaN, infinite or negative).
int? distanceUpperLimitFor(double? km) {
  if (km == null || km.isNaN || km.isInfinite || km < 0) return null;
  for (final step in kDistanceStepsKm) {
    if (km < step) return step;
  }
  return 0;
}

String _formatKm(AppLocalizations l10n, int km) =>
    NumberFormat.decimalPattern(l10n.localeName).format(km);

/// Localized label for [km]: "< 5 km", …, "5,000+ km"; '' when unknown.
/// With [zeroIsUnknown] a distance of exactly 0 (the "no location" default
/// of the candidate models) is also treated as unknown.
///
/// [precise]: the other user published a ±100 m `preciseLocation`
/// (Profile.hasPreciseLocation / MapUser.hasPreciseLocation) and [km] was
/// computed from it: shown with 100 m resolution ([preciseDistanceLabel]).
String distanceLabel(AppLocalizations l10n, double? km,
    {bool zeroIsUnknown = true, bool precise = false}) {
  if (zeroIsUnknown && km == 0) return '';
  if (precise) return preciseDistanceLabel(l10n, km);
  final limit = distanceUpperLimitFor(km);
  if (limit == null) return '';
  if (limit == 0) {
    return l10n.distanceOverKm(_formatKm(l10n, kDistanceStepsKm.last));
  }
  return l10n.distanceUnderKm(_formatKm(l10n, limit));
}

/// Distance to a user with a ±100 m `preciseLocation`, at the resolution
/// that error allows: under 1 km to the nearest 100 m (never below "100 m"),
/// 1-10 km with one decimal ("1.2 km"), from 10 km in whole km ("23 km").
/// Localized number formatting; '' when unknown.
String preciseDistanceLabel(AppLocalizations l10n, double? km) {
  if (km == null || km.isNaN || km.isInfinite || km < 0) return '';
  // 100 m units = tenths of a km, from whole metres (stable rounding).
  final tenths = ((km * 1000).round() / 100).round();
  if (tenths < 10) {
    final m = tenths < 1 ? 100 : tenths * 100;
    return l10n.distanceMeters(
        NumberFormat.decimalPattern(l10n.localeName).format(m));
  }
  if (tenths < 100) {
    return l10n.distanceKmPrecise(
        NumberFormat('#,##0.0', l10n.localeName).format(tenths / 10));
  }
  return l10n.distanceKmPrecise(_formatKm(l10n, km.round()));
}

/// Discovery filter: index on the distance slider for a saved
/// `maxDistanceKm` (null = no limit = the last position). A saved value that
/// is not a step snaps UP to the next step, so the filter never gets
/// narrower than what the user chose.
int distanceFilterIndexFor(int? maxDistanceKm) {
  if (maxDistanceKm == null) return kDistanceStepsKm.length;
  for (var i = 0; i < kDistanceStepsKm.length; i++) {
    if (maxDistanceKm <= kDistanceStepsKm[i]) return i;
  }
  return kDistanceStepsKm.length;
}

/// Discovery filter: `maxDistanceKm` for a slider index (null = no limit).
int? distanceFilterKmForIndex(int index) =>
    index >= 0 && index < kDistanceStepsKm.length ? kDistanceStepsKm[index] : null;

/// Discovery filter label for a saved `maxDistanceKm`.
String distanceFilterLabel(AppLocalizations l10n, int? maxDistanceKm) {
  final km = distanceFilterKmForIndex(distanceFilterIndexFor(maxDistanceKm));
  return km == null
      ? l10n.distanceOverKm(_formatKm(l10n, kDistanceStepsKm.last))
      : l10n.distanceUnderKm(_formatKm(l10n, km));
}
