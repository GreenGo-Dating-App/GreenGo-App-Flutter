import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/place_search_service.dart';
import 'package:greengo_chat/core/widgets/location_picker.dart';
import 'package:greengo_chat/core/widgets/map_basemap_layer.dart';
import 'package:greengo_chat/features/events/data/services/event_geocoder.dart';
import 'package:greengo_chat/features/notifications/presentation/screens/city_picker_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:latlong2/latlong.dart';

class _Call {
  _Call(this.query, this.lang, this.mode, this.biasLat, this.sessionToken);
  final String query;
  final String lang;
  final PlaceSearchMode mode;
  final double? biasLat;
  final String? sessionToken;
}

class FakeRepo implements PlaceSearchRepository {
  final List<_Call> searches = [];
  final List<String> resolves = [];
  final List<LatLng> reverses = [];
  final Map<String, Completer<List<PlaceSuggestion>>> pending = {};

  /// When true, each search waits for [pending][query] to complete.
  bool manual = false;
  Object? searchError;
  List<PlaceSuggestion> results = const [];
  PickedPlace? reverseResult;
  Object? reverseError;
  PickedPlace? resolveResult;

  @override
  Future<List<PlaceSuggestion>> search(String query,
      {required String lang,
      PlaceSearchMode mode = PlaceSearchMode.address,
      double? biasLat,
      double? biasLng,
      String? sessionToken}) {
    searches.add(_Call(query, lang, mode, biasLat, sessionToken));
    if (searchError != null) return Future.error(searchError!);
    if (manual) {
      return (pending[query] = Completer<List<PlaceSuggestion>>()).future;
    }
    return Future.value(results);
  }

  @override
  Future<PickedPlace?> resolve(String placeId, {String? sessionToken}) async {
    resolves.add('$placeId|$sessionToken');
    return resolveResult;
  }

  @override
  Future<PickedPlace?> reverse(double lat, double lng,
      {required String lang}) async {
    reverses.add(LatLng(lat, lng));
    if (reverseError != null) throw reverseError!;
    return reverseResult;
  }
}

const _navona = PlaceSuggestion(
  id: 'osm:W1',
  primary: 'Piazza Navona',
  secondary: '00186 Rome, Lazio, Italy',
  lat: 41.8992,
  lng: 12.4731,
  city: 'Rome',
  country: 'Italy',
);
const _corso = PlaceSuggestion(
  id: 'osm:W2',
  primary: 'Via del Corso',
  secondary: 'Rome, Italy',
  lat: 41.9,
  lng: 12.48,
  city: 'Rome',
  country: 'Italy',
);

/// Opens the picker from a home button so the popped value can be read.
class _Host extends StatefulWidget {
  const _Host(this.picker);
  final Widget picker;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  Object? result;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          ElevatedButton(
            key: const ValueKey('open'),
            onPressed: () async {
              final r = await Navigator.of(context)
                  .push<Object>(MaterialPageRoute(builder: (_) => widget.picker));
              setState(() => result = r);
            },
            child: const Text('open'),
          ),
          Text('result:${result is PickedPlace ? (result as PickedPlace).address : result}',
              key: const ValueKey('result')),
        ]),
      );
}

Widget _app(Widget picker, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _Host(picker),
    );

Future<void> _open(WidgetTester tester, Widget picker,
    {Locale locale = const Locale('en'), Size size = const Size(400, 800)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(picker, locale: locale));
  await tester.tap(find.byKey(const ValueKey('open')));
  await tester.pumpAndSettle();
}

final _search = find.byKey(const ValueKey('location-picker-search'));
final _confirm = find.byKey(const ValueKey('location-picker-confirm'));
final _status = find.byKey(const ValueKey('location-picker-status'));

/// flutter_map reports a tap only after its 250 ms double-tap window.
Future<void> _tapMap(WidgetTester tester, [Offset offset = Offset.zero]) async {
  await tester.tapAt(tester.getCenter(find.byType(FlutterMap)) + offset);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

String _statusText(WidgetTester tester) =>
    tester.widget<Text>(_status).data ?? '';

void main() {
  setUpAll(() => MapBasemapLayer.debugDisableTiles = true);
  tearDownAll(() => MapBasemapLayer.debugDisableTiles = false);
  setUp(LocationPickerScreen.debugClearRecents);

  testWidgets('debounces typing and needs 3 characters', (tester) async {
    final repo = FakeRepo()..results = const [_navona, _corso];
    await _open(tester, LocationPickerScreen(repository: repo));

    await tester.enterText(_search, 'pi');
    await tester.pump(const Duration(milliseconds: 500));
    expect(repo.searches, isEmpty);

    await tester.enterText(_search, 'pia');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(_search, 'piaz');
    await tester.pump(const Duration(milliseconds: 200));
    expect(repo.searches, isEmpty, reason: 'still inside the 350 ms window');
    await tester.pump(const Duration(milliseconds: 200));
    expect(repo.searches.map((c) => c.query), ['piaz']);
    expect(repo.searches.single.lang, 'en');
    expect(repo.searches.single.sessionToken, isNotNull);
    await tester.pumpAndSettle();

    expect(find.text('Piazza Navona'), findsOneWidget);
    expect(find.text('00186 Rome, Lazio, Italy'), findsOneWidget);
    expect(find.text('Via del Corso'), findsOneWidget);
  });

  testWidgets('shows at most 6 suggestions', (tester) async {
    final repo = FakeRepo()
      ..results = [
        for (var i = 0; i < 9; i++)
          PlaceSuggestion(
              id: 'p$i', primary: 'Place $i', secondary: 'City', lat: 1, lng: 1),
      ];
    await _open(tester, LocationPickerScreen(repository: repo));
    await tester.enterText(_search, 'place');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(find.textContaining('Place '), findsNWidgets(6));
  });

  testWidgets('drops a stale answer that arrives after a newer one',
      (tester) async {
    final repo = FakeRepo()..manual = true;
    await _open(tester, LocationPickerScreen(repository: repo));

    await tester.enterText(_search, 'via');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(_search, 'piazza');
    await tester.pump(const Duration(milliseconds: 400));
    expect(repo.pending.keys, ['via', 'piazza']);

    repo.pending['piazza']!.complete(const [_navona]);
    await tester.pumpAndSettle();
    repo.pending['via']!.complete(const [_corso]);
    await tester.pumpAndSettle();

    expect(find.text('Piazza Navona'), findsOneWidget);
    expect(find.text('Via del Corso'), findsNothing);
  });

  testWidgets('selecting a suggestion moves the camera and drops the pin',
      (tester) async {
    final repo = FakeRepo()..results = const [_navona];
    await _open(tester, LocationPickerScreen(repository: repo));
    expect(find.byKey(const ValueKey('location-picker-pin')), findsNothing);
    expect(tester.widget<FilledButton>(_confirm).onPressed, isNull);

    await tester.enterText(_search, 'navona');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    await tester.tap(find.text('Piazza Navona'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('location-picker-pin')), findsOneWidget);
    final marker = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(marker.markers.single.point, const LatLng(41.8992, 12.4731));
    final camera = MapCamera.of(tester.element(find.byType(MarkerLayer)));
    expect(camera.center.latitude, closeTo(41.8992, 1e-4));
    expect(camera.center.longitude, closeTo(12.4731, 1e-4));
    expect(camera.zoom, closeTo(16, 1e-6));
    expect(_statusText(tester), 'Piazza Navona, 00186 Rome, Lazio, Italy');
    expect(repo.reverses, isEmpty, reason: 'a suggestion already has an address');

    await tester.tap(_confirm);
    await tester.pumpAndSettle();
    expect(find.text('result:Piazza Navona, 00186 Rome, Lazio, Italy'),
        findsOneWidget);
  });

  testWidgets('a suggestion without coordinates is resolved with the session token',
      (tester) async {
    final repo = FakeRepo()
      ..results = const [
        PlaceSuggestion(
            id: 'g:abc', primary: 'Colosseum', secondary: 'Rome', placeId: 'abc'),
      ]
      ..resolveResult = const PickedPlace(
          address: 'Piazza del Colosseo, Rome', lat: 41.89, lng: 12.49, city: 'Rome');
    await _open(tester, LocationPickerScreen(repository: repo));
    await tester.enterText(_search, 'colos');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    final token = repo.searches.single.sessionToken;
    await tester.tap(find.text('Colosseum'));
    await tester.pumpAndSettle();

    expect(repo.resolves, ['abc|$token']);
    expect(_statusText(tester), 'Piazza del Colosseo, Rome');

    // The next typing session gets a fresh token.
    await tester.enterText(_search, 'trevi');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(repo.searches.last.sessionToken, isNot(token));
  });

  testWidgets('tapping the map drops the pin and reverse-geocodes it',
      (tester) async {
    final repo = FakeRepo()
      ..reverseResult = const PickedPlace(
          address: 'Via Giulia 1, Rome', lat: 0, lng: 0, city: 'Rome');
    await _open(tester, LocationPickerScreen(repository: repo));

    await _tapMap(tester);

    expect(repo.reverses, hasLength(1));
    expect(find.byKey(const ValueKey('location-picker-pin')), findsOneWidget);
    expect(_statusText(tester), 'Via Giulia 1, Rome');
    expect(tester.widget<TextField>(_search).controller!.text,
        'Via Giulia 1, Rome');
    expect(tester.widget<FilledButton>(_confirm).onPressed, isNotNull);
  });

  testWidgets('dragging the pin moves it and reverse-geocodes the new spot',
      (tester) async {
    final repo = FakeRepo()
      ..reverseResult =
          const PickedPlace(address: 'Somewhere new', lat: 0, lng: 0);
    await _open(
        tester,
        LocationPickerScreen(
            repository: repo,
            initialLat: 41.9,
            initialLng: 12.5,
            initialAddress: 'Start'));
    expect(_statusText(tester), 'Start');
    expect(repo.reverses, isEmpty);

    final pin = find.byKey(const ValueKey('location-picker-pin'));
    await tester.drag(pin, const Offset(60, 40));
    await tester.pumpAndSettle();

    final point =
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.single.point;
    expect(point.longitude, greaterThan(12.5), reason: 'dragged east');
    expect(point.latitude, lessThan(41.9), reason: 'dragged south');
    expect(repo.reverses.single.latitude, closeTo(point.latitude, 1e-9));
    expect(_statusText(tester), 'Somewhere new');
  });

  testWidgets('a failed reverse lookup keeps the pin usable', (tester) async {
    final repo = FakeRepo()..reverseError = Exception('offline');
    await _open(tester, LocationPickerScreen(repository: repo));
    await _tapMap(tester);
    expect(_statusText(tester), 'Pinned spot (no address found)');
    expect(tester.widget<FilledButton>(_confirm).onPressed, isNotNull);
  });

  testWidgets('shows offline, rate-limit and no-result states', (tester) async {
    final repo = FakeRepo()
      ..searchError = const PlaceSearchException(PlaceSearchFailure.offline);
    await _open(tester, LocationPickerScreen(repository: repo));
    await tester.enterText(_search, 'rome');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(find.textContaining('offline'), findsOneWidget);

    repo.searchError = const PlaceSearchException(PlaceSearchFailure.rateLimited);
    await tester.enterText(_search, 'romes');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(find.textContaining('Too many searches'), findsOneWidget);

    repo
      ..searchError = null
      ..results = const [];
    await tester.enterText(_search, 'zzzzq');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('location-picker-no-results')),
        findsOneWidget);
  });

  testWidgets('use my current location: pin + reverse, or a message when denied',
      (tester) async {
    final repo = FakeRepo()
      ..reverseResult = const PickedPlace(address: 'Here', lat: 0, lng: 0);
    LatLng? here;
    await _open(
        tester, LocationPickerScreen(repository: repo, locateMe: () async => here));

    await tester.tap(find.byKey(const ValueKey('location-picker-my-location')));
    await tester.pumpAndSettle();
    expect(find.textContaining("Couldn't get your location"), findsOneWidget);
    expect(repo.reverses, isEmpty);

    here = const LatLng(45.46, 9.19);
    await tester.tap(find.byKey(const ValueKey('location-picker-my-location')));
    await tester.pumpAndSettle();
    expect(repo.reverses.single, const LatLng(45.46, 9.19));
    expect(_statusText(tester), 'Here');
  });

  testWidgets('autoLocate (chat): opens on the profile position, then moves to the device position',
      (tester) async {
    final repo = FakeRepo()
      ..reverseResult = const PickedPlace(address: 'Here', lat: 0, lng: 0);
    await _open(
        tester,
        LocationPickerScreen(
          repository: repo,
          initialLat: 41.9,
          initialLng: 12.5,
          autoLocate: true,
          locateMe: () async => const LatLng(45.46, 9.19),
        ));
    await tester.pumpAndSettle();
    // Profile position reverse-geocoded first, then the device position.
    expect(repo.reverses.first, const LatLng(41.9, 12.5));
    expect(repo.reverses.last, const LatLng(45.46, 9.19));
    expect(_statusText(tester), 'Here');
  });

  testWidgets('autoLocate: device position unavailable keeps the profile pin, no error',
      (tester) async {
    final repo = FakeRepo()
      ..reverseResult = const PickedPlace(address: 'Rome', lat: 0, lng: 0);
    await _open(
        tester,
        LocationPickerScreen(
          repository: repo,
          initialLat: 41.9,
          initialLng: 12.5,
          autoLocate: true,
          locateMe: () async => null,
        ));
    await tester.pumpAndSettle();
    expect(repo.reverses.single, const LatLng(41.9, 12.5));
    expect(find.textContaining("Couldn't get your location"), findsNothing);
  });

  testWidgets('recent places show on an empty focused field', (tester) async {
    final repo = FakeRepo()..results = const [_navona];
    await _open(tester, LocationPickerScreen(repository: repo));
    await tester.enterText(_search, 'navona');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    await tester.tap(find.text('Piazza Navona'));
    await tester.pumpAndSettle();
    await tester.tap(_confirm);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
    await tester.tap(_search);
    await tester.pumpAndSettle();
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Piazza Navona, 00186 Rome, Lazio, Italy'), findsOneWidget);
  });

  testWidgets('city picker searches cities, sends ~1 km pins, pops the city',
      (tester) async {
    final repo = FakeRepo()
      ..results = const [
        PlaceSuggestion(
            id: 'c1',
            primary: 'Ulm',
            secondary: 'Germany',
            lat: 48.39,
            lng: 9.99,
            city: 'Ulm',
            country: 'Germany'),
      ]
      ..reverseResult = const PickedPlace(
          address: 'x', lat: 0, lng: 0, city: 'Neu-Ulm', country: 'Germany');
    await _open(tester, CityPickerScreen(repository: repo));
    expect(find.text('Search a city…'), findsOneWidget);

    await tester.enterText(_search, 'ulm');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(repo.searches.single.mode, PlaceSearchMode.city);
    await tester.tap(find.text('Ulm'));
    await tester.pumpAndSettle();
    expect(_statusText(tester), 'Ulm, Germany');

    await _tapMap(tester, const Offset(30, 30));
    final sent = repo.reverses.single;
    expect(sent.latitude, (sent.latitude * 100).roundToDouble() / 100);
    expect(_statusText(tester), 'Neu-Ulm, Germany');

    await tester.tap(_confirm);
    await tester.pumpAndSettle();
    expect(find.text('result:Neu-Ulm'), findsOneWidget);
  });

  testWidgets('fits a 320 px wide screen', (tester) async {
    final repo = FakeRepo()..results = const [_navona, _corso];
    await _open(tester, LocationPickerScreen(repository: repo),
        size: const Size(320, 568));
    await tester.enterText(_search, 'piazza');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.text('Piazza Navona'), findsOneWidget);
  });

  for (final locale in const [
    Locale('en'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
    Locale('pt', 'BR'),
  ]) {
    testWidgets('renders localized in $locale and sends that language',
        (tester) async {
      final repo = FakeRepo()..results = const [_navona];
      await _open(tester, LocationPickerScreen(repository: repo), locale: locale);
      final l10n = lookupAppLocalizations(locale);
      expect(find.text(l10n.locPickerTitle), findsOneWidget);
      expect(find.text(l10n.locPickerConfirm), findsOneWidget);
      expect(_statusText(tester), l10n.locPickerHint);
      await tester.enterText(_search, 'navona');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(repo.searches.single.lang, locale.toLanguageTag());
    });
  }

  group('EventGeocoder (typed location on save)', () {
    test('uses the top server suggestion and keeps the typed text', () async {
      final repo = FakeRepo()..results = const [_navona, _corso];
      final loc = await EventGeocoder.geocode('  Navona  ',
          lang: 'it', repository: repo);
      expect(loc!.latitude, 41.8992);
      expect(loc.city, 'Rome');
      expect(loc.displayAddress, 'Navona');
      expect(repo.searches.single.lang, 'it');
    });

    test('resolves a Google suggestion, null on no match or failure', () async {
      final repo = FakeRepo()
        ..results = const [
          PlaceSuggestion(id: 'g', primary: 'X', secondary: '', placeId: 'pid1')
        ]
        ..resolveResult =
            const PickedPlace(address: 'X st', lat: 1.5, lng: 2.5, city: 'C');
      expect((await EventGeocoder.geocode('xyz', repository: repo))!.longitude,
          2.5);
      expect(await EventGeocoder.geocode('xyz', repository: FakeRepo()), isNull);
      final failing = FakeRepo()
        ..searchError = const PlaceSearchException(PlaceSearchFailure.offline);
      expect(await EventGeocoder.geocode('xyz', repository: failing), isNull);
      expect(await EventGeocoder.geocode(' ', repository: repo), isNull);
    });
  });
}
