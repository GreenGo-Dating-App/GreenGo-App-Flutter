import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/map_clustering.dart';
import 'package:greengo_chat/features/globe_explore/data/country_centroids.dart';
import 'package:greengo_chat/features/globe_explore/domain/entities/globe_user.dart';
import 'package:greengo_chat/features/globe_explore/presentation/widgets/globe_pin_layout.dart';

GlobeUser _u(String id, double lat, double lng, {String country = 'Italy'}) =>
    GlobeUser(
      userId: id,
      displayName: id,
      pinLatitude: lat,
      pinLongitude: lng,
      country: country,
      city: 'c',
      pinType: GlobePinType.matched,
    );

void main() {
  group('clusterByGrid', () {
    test('nearby points merge, distant ones do not', () {
      final pts = [(41.90, 12.50), (41.901, 12.501), (48.85, 2.35)];
      final c = clusterByGrid<(double, double)>(
        pts,
        lat: (p) => p.$1,
        lng: (p) => p.$2,
        id: (p) => '${p.$1}',
        zoom: 8,
      );
      expect(c.map((e) => e.items.length).toList()..sort(), [1, 2]);
    });

    test('ids are stable for the same members and band', () {
      List<String> ids() => clusterByGrid<(double, double)>(
            [(41.90, 12.50), (41.901, 12.501)],
            lat: (p) => p.$1,
            lng: (p) => p.$2,
            id: (p) => '${p.$1}',
            zoom: 8,
          ).map((c) => c.id).toList();
      expect(ids(), ids());
    });

    test('ten thousand pins cluster in one linear pass', () {
      final rng = Random(7);
      final pts = [
        for (var i = 0; i < 10000; i++)
          (rng.nextDouble() * 140 - 70, rng.nextDouble() * 360 - 180),
      ];
      final sw = Stopwatch()..start();
      final c = clusterByGrid<(double, double)>(
        pts,
        lat: (p) => p.$1,
        lng: (p) => p.$2,
        id: (p) => '$p',
        zoom: 3,
      );
      sw.stop();
      expect(c.fold<int>(0, (n, e) => n + e.items.length), 10000);
      // Far fewer markers than pins at world zoom.
      expect(c.length, lessThan(2000));
      expect(sw.elapsedMilliseconds, lessThan(500));
    });
  });

  group('layoutGlobePins', () {
    final users = [
      _u('a', 41.90, 12.50),
      _u('b', 45.46, 9.19),
      _u('c', 43.77, 11.25),
      _u('p', 38.72, -9.14, country: 'Portugal'),
      _u('x', 10, 10, country: 'Unknown'),
    ];

    test('zoomed out: one bubble per country at its centroid', () {
      final groups = layoutGlobePins(users, kGlobeCountryZoomBand - 1);
      final italy = groups.singleWhere((g) => g.country == 'Italy');
      expect(italy.cluster.items.length, 3);
      expect(italy.cluster.lat, countryCentroids['Italy']![0]);
      expect(italy.cluster.lng, countryCentroids['Italy']![1]);
      // A country with one connection shows that person at their own pin.
      final p = groups.singleWhere((g) => g.first.userId == 'p');
      expect(p.isSingle, isTrue);
      expect(p.country, isNull);
      expect(p.cluster.lat, 38.72);
      // Unknown country still drawn, as themselves.
      expect(groups.where((g) => g.first.userId == 'x'), hasLength(1));
      expect(groups.fold<int>(0, (n, g) => n + g.cluster.items.length), 5);
    });

    test('zoomed in: grid clusters split cities apart', () {
      final groups = layoutGlobePins(users, 8);
      expect(groups.every((g) => g.country == null), isTrue);
      expect(groups.every((g) => g.isSingle), isTrue);
      expect(groups, hasLength(5));
    });
  });
}
