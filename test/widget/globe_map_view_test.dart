import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/config/map_basemap.dart';
import 'package:greengo_chat/core/widgets/map_basemap_layer.dart';
import 'package:greengo_chat/core/widgets/map_controls.dart';
import 'package:greengo_chat/features/globe_explore/domain/entities/globe_user.dart';
import 'package:greengo_chat/features/globe_explore/presentation/widgets/globe_map_view.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:latlong2/latlong.dart';

const _me = GlobeUser(
  userId: 'me',
  displayName: 'Me',
  pinLatitude: 41.9,
  pinLongitude: 12.5,
  country: 'Italy',
  city: 'Rome',
  pinType: GlobePinType.currentUser,
);

GlobeUser _friend(String id, double lat, double lng, String country) =>
    GlobeUser(
      userId: id,
      displayName: id,
      pinLatitude: lat,
      pinLongitude: lng,
      country: country,
      city: 'c',
      pinType: GlobePinType.matched,
      matchId: 'm_$id',
    );

class _Harness extends StatefulWidget {
  const _Harness({required this.data, required this.log});
  final GlobeData data;
  final List<String> log;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String? fly;
  int flyId = 0;

  void flyTo(String country) => setState(() {
        fly = country;
        flyId++;
      });

  @override
  Widget build(BuildContext context) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GlobeMapView(
            data: widget.data,
            flyToCountry: fly,
            flyRequestId: flyId,
            onPinTapped: (id, _) => widget.log.add('pin:$id'),
            onCountryTapped: (c, _, __) => widget.log.add('country:$c'),
            onClusterTapped: (u) => widget.log.add('cluster:${u.length}'),
          ),
        ),
      );
}

void main() {
  setUpAll(() => MapBasemapLayer.debugDisableTiles = true);
  tearDownAll(() => MapBasemapLayer.debugDisableTiles = false);

  final data = GlobeData(
    currentUser: _me,
    matchedUsers: [
      _friend('ana', 41.95, 12.45, 'Italy'),
      _friend('rui', 38.72, -9.14, 'Portugal'),
      _friend('ida', 38.73, -9.15, 'Portugal'),
    ],
    discoveryUsers: const [],
  );

  testWidgets('uses the shared map stack: basemap, credit and controls',
      (tester) async {
    await tester.pumpWidget(_Harness(data: data, log: const []));
    await tester.pump();
    expect(find.byType(MapBasemapLayer), findsOneWidget);
    expect(find.text(MapBasemap.lightAttribution), findsOneWidget);
    expect(find.byType(MapZoomControls), findsOneWidget);
    expect(
        find.byKey(const ValueKey('globe-map-whole-network')), findsOneWidget);
    // Own pin is always drawn, with its "You" tag.
    expect(find.byKey(const ValueKey('globe-pin-self')), findsOneWidget);
  });

  testWidgets('tapping a person reports that person', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(_Harness(data: data, log: log));
    await tester.pump();
    // City zoom on Rome: Ana is her own pin.
    await tester.tap(find.byKey(const ValueKey('globe-pin-ana')));
    expect(log, ['pin:ana']);
  });

  testWidgets('zoomed out, a country with several connections is one bubble',
      (tester) async {
    final log = <String>[];
    await tester.pumpWidget(_Harness(data: data, log: log));
    await tester.pump();
    final controller =
        MapController.maybeOf(tester.element(find.byType(MarkerLayer)))!;
    controller.move(const LatLng(40, 0), 2);
    await tester.pump();
    final bubble = find.byKey(const ValueKey('globe-group-key:Portugal'));
    expect(bubble, findsOneWidget);
    await tester.tap(bubble);
    expect(log, ['country:Portugal']);
  });

  testWidgets('a fly request moves the camera to the country', (tester) async {
    await tester.pumpWidget(_Harness(data: data, log: const []));
    await tester.pump();
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    state.flyTo('Portugal');
    await tester.pump();
    final cam = MapCamera.of(tester.element(find.byType(MarkerLayer)));
    expect(cam.zoom, 5);
    expect(cam.center.latitude, closeTo(39.40, 0.01));
  });
}
