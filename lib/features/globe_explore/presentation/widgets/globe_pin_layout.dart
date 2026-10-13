import '../../../../core/utils/map_clustering.dart';
import '../../data/country_centroids.dart';
import '../../domain/entities/globe_user.dart';

/// Below this zoom band the network map shows one bubble per country
/// (continent / world view); from it on, pins cluster on a screen grid.
const int kGlobeCountryZoomBand = 4;

/// Up to (and including) this zoom band a tap on empty map opens the
/// nearest country's sheet. Deeper in, the user is looking at streets and a
/// stray tap must not pop a sheet.
const int kGlobeCountryTapMaxBand = 6;

/// From this zoom band a cluster that is still a cluster opens the list of
/// its people instead of zooming further (they share a building or a
/// privacy cell, so zooming would never split them).
const int kGlobeClusterListBand = 16;

/// One marker on the network map: a single person, a grid cluster, or (when
/// zoomed out) a whole country.
class GlobePinGroup {
  const GlobePinGroup(this.cluster, {this.country});

  final MapCluster<GlobeUser> cluster;

  /// Set for a country aggregate (tap opens that country's sheet).
  final String? country;

  bool get isSingle => cluster.isSingle;
  GlobeUser get first => cluster.items.first;
}

/// Lays out [users] (the current user excluded — that pin is never grouped)
/// for [zoomBand], a whole-number zoom. Pure and O(n): the map caches the
/// result per band, so panning costs nothing and a band change re-groups
/// thousands of pins in about a millisecond.
List<GlobePinGroup> layoutGlobePins(List<GlobeUser> users, int zoomBand) {
  if (zoomBand < kGlobeCountryZoomBand) {
    return [
      for (final c in clusterByKey<GlobeUser>(
        users,
        keyOf: (u) => u.country == 'Unknown' ? '' : u.country,
        lat: (u) => u.pinLatitude,
        lng: (u) => u.pinLongitude,
        anchor: (country) {
          final c = countryCentroids[normalizeCountryName(country)];
          return c == null ? null : (c[0], c[1]);
        },
      ))
        // The only connection in a country shows as themselves, where their
        // own (already privacy-coarsened) pin is.
        if (c.isSingle)
          _single(c.items.first)
        else
          GlobePinGroup(c, country: c.items.first.country),
      // People without a known country still show, as themselves.
      for (final u in users)
        if (u.country == 'Unknown') _single(u),
    ];
  }
  return [
    for (final c in clusterByGrid<GlobeUser>(
      users,
      lat: (u) => u.pinLatitude,
      lng: (u) => u.pinLongitude,
      id: (u) => u.userId,
      zoom: zoomBand.toDouble(),
    ))
      GlobePinGroup(c),
  ];
}

GlobePinGroup _single(GlobeUser u) => GlobePinGroup(MapCluster<GlobeUser>(
      id: u.userId,
      items: [u],
      lat: u.pinLatitude,
      lng: u.pinLongitude,
    ));
