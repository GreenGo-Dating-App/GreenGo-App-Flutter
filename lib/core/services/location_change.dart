import 'dart:async';
import 'dart:math' as math;

/// THE single rule for "the user's location changed" — shared by the
/// post-login / app-open location refresh (LocationRefreshService), Explore's
/// pull-to-refresh and Explore's live profile listener, so they can never
/// disagree about whether data must be reloaded.
///
/// A location counts as changed when:
///  * there was no usable previous position (first fix), or
///  * the new position is more than [kLocationChangeThresholdKm] away, or
///  * both cities (or both countries) are known and differ (case-insensitive).
///
/// Moves below the threshold inside the same city are noise (GPS/Wi-Fi
/// jitter): no Firestore write and no reload.
const double kLocationChangeThresholdKm = 1.0;

/// A position + the place names it resolved to (any part may be unknown).
class LocationPoint {
  const LocationPoint({this.lat, this.lng, this.city, this.country});

  final double? lat;
  final double? lng;
  final String? city;
  final String? country;

  /// Coordinates usable for a distance check: finite, in range and not the
  /// (0, 0) "unset" placeholder the app writes for unknown locations.
  bool get hasCoords =>
      lat != null &&
      lng != null &&
      lat!.isFinite &&
      lng!.isFinite &&
      lat!.abs() <= 90 &&
      lng!.abs() <= 180 &&
      !(lat == 0 && lng == 0);

  /// Reads `{latitude, longitude, city, country}` (a profile `location` /
  /// `travelerLocation` map). Null-safe.
  factory LocationPoint.fromMap(Map<dynamic, dynamic>? map) => LocationPoint(
        lat: (map?['latitude'] as num?)?.toDouble(),
        lng: (map?['longitude'] as num?)?.toDouble(),
        city: (map?['city'] as String?)?.trim(),
        country: (map?['country'] as String?)?.trim(),
      );

  @override
  String toString() => 'LocationPoint($lat, $lng, $city, $country)';
}

/// Great-circle distance in km (haversine).
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

bool _namesDiffer(String? a, String? b) {
  final x = a?.trim().toLowerCase() ?? '';
  final y = b?.trim().toLowerCase() ?? '';
  return x.isNotEmpty && y.isNotEmpty && x != y;
}

/// Whether moving from [from] to [to] is a meaningful location change (see
/// the rule at the top of this file). A [to] without usable coordinates is
/// only a change when its city/country differ from [from]'s.
bool isMeaningfulLocationChange(LocationPoint? from, LocationPoint to) {
  if (_namesDiffer(from?.city, to.city) ||
      _namesDiffer(from?.country, to.country)) {
    return true;
  }
  if (!to.hasCoords) return false;
  if (from == null || !from.hasCoords) return true;
  return distanceKm(from.lat!, from.lng!, to.lat!, to.lng!) >
      kLocationChangeThresholdKm;
}

/// Result of one location refresh attempt.
enum LocationRefreshOutcome {
  /// A meaningfully different position was written to the profile.
  changed,

  /// A fix was obtained but it is the same place: nothing written.
  unchanged,

  /// No fix (traveler mode, no permission, GPS off, timeout, error).
  skipped,
}

/// Pull-to-refresh "reload if and only if the location changed".
///
/// Runs [refreshLocation] (bounded by [timeout]) and then [reload] ONLY when
/// it reports [LocationRefreshOutcome.changed]. Returns whether [reload] ran.
/// A timeout returns false at once (the refresh keeps running; a late change
/// is picked up by the caller's profile listener instead).
Future<bool> reloadIfLocationChanged({
  required Future<LocationRefreshOutcome> Function() refreshLocation,
  required Future<void> Function() reload,
  Duration timeout = const Duration(seconds: 8),
}) async {
  LocationRefreshOutcome outcome;
  try {
    outcome = await refreshLocation()
        .timeout(timeout, onTimeout: () => LocationRefreshOutcome.skipped);
  } catch (_) {
    outcome = LocationRefreshOutcome.skipped;
  }
  if (outcome != LocationRefreshOutcome.changed) return false;
  await reload();
  return true;
}

// ── Pull-to-refresh location update (owner 2026-10-21) ─────────────────────
// "When the user is in Explore and swipes down, the location is updated."

/// A pull writes the fresh position when it moved at least this far from the
/// last saved one...
const double kPullRefreshMinMoveKm = 0.2;

/// ...or when the saved position is at least this old. Otherwise the write is
/// skipped (repeated pulls in the same spot cost no Firestore write); the
/// content is reloaded either way.
const Duration kPullRefreshMinInterval = Duration(minutes: 10);

/// The pull-to-refresh write throttle: whether a pulled [fix] should be saved
/// over the [stored] position last saved at [storedAt].
///
/// Skips the write only when the user moved less than [kPullRefreshMinMoveKm]
/// AND the saved position is younger than [kPullRefreshMinInterval]. A fix
/// without usable coordinates is never written; an unknown previous position
/// or save time always is.
bool shouldWritePulledLocation({
  required LocationPoint? stored,
  required DateTime? storedAt,
  required LocationPoint fix,
  required DateTime now,
}) {
  if (!fix.hasCoords) return false;
  if (stored == null || !stored.hasCoords) return true;
  final movedKm = distanceKm(stored.lat!, stored.lng!, fix.lat!, fix.lng!);
  if (movedKm >= kPullRefreshMinMoveKm) return true;
  if (storedAt == null) return true;
  return now.difference(storedAt) >= kPullRefreshMinInterval;
}

/// Why a pull-to-refresh did not obtain / save a position.
enum LocationSkipReason {
  /// Traveler mode is on: the travel location is kept, GPS is not read.
  traveler,

  /// Device / browser location services are off.
  serviceDisabled,

  /// Permission not granted yet (it can still be asked for).
  permissionDenied,

  /// Permission permanently denied (device settings / browser site settings).
  permissionDeniedForever,

  /// No fix in time (weak signal, timeout) or an unexpected error.
  unavailable,
}

/// Result of a pull-to-refresh location update.
class PullLocationResult {
  const PullLocationResult({
    required this.outcome,
    this.written = false,
    this.skipReason,
    this.city,
  });

  const PullLocationResult.skipped(LocationSkipReason reason)
      : this(outcome: LocationRefreshOutcome.skipped, skipReason: reason);

  /// [LocationRefreshOutcome.changed] only for a meaningful move (the shared
  /// rule above); a throttled refresh of the same place is `unchanged`.
  final LocationRefreshOutcome outcome;

  /// Whether the fresh position was saved to the profile.
  final bool written;

  /// Set when [outcome] is [LocationRefreshOutcome.skipped].
  final LocationSkipReason? skipReason;

  /// The city of the (new or saved) position, when known - for the
  /// confirmation message.
  final String? city;

  bool get hasFix => outcome != LocationRefreshOutcome.skipped;
}
