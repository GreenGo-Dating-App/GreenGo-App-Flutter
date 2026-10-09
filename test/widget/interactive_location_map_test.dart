import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/config/map_basemap.dart';
import 'package:greengo_chat/core/widgets/interactive_location_map.dart';
import 'package:greengo_chat/core/widgets/map_basemap_layer.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/location_message_map.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';
import 'package:greengo_chat/features/events/presentation/widgets/event_location_map.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/user_experience.dart';
import 'package:greengo_chat/features/user_experiences/presentation/widgets/experience_location_map.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Event _event({double? lat, double? lng}) => Event(
      id: 'e1',
      organizerId: 'o1',
      organizerName: 'Org',
      title: 'Meetup',
      description: 'd',
      category: EventCategory.social,
      startDate: DateTime(2026, 10, 10, 18),
      endDate: DateTime(2026, 10, 10, 20),
      locationName: 'Piazza Navona',
      maxAttendees: 10,
      status: EventStatus.published,
      createdAt: DateTime(2026, 10, 1),
      latitude: lat,
      longitude: lng,
    );

UserExperience _experience({double? lat, double? lng}) => UserExperience(
      id: 'x1',
      hostId: 'h1',
      title: 'Food tour',
      description: 'd',
      category: ExperienceCategory.foodDrink,
      mainPhotoUrl: '',
      included: const [],
      locationName: 'Trastevere',
      durationMinutes: 90,
      languages: const ['en'],
      maxGroupSize: 6,
      lat: lat,
      lng: lng,
      meetingPoint: 'Fountain',
    );

void main() {
  setUpAll(() => MapBasemapLayer.debugDisableTiles = true);
  tearDownAll(() => MapBasemapLayer.debugDisableTiles = false);

  group('mapsLaunchUri', () {
    test('Android uses a geo: URI with a labelled pin', () {
      final u = mapsLaunchUri(41.9, 12.47,
          platform: MapsPlatform.android, label: 'Piazza');
      expect(u.scheme, 'geo');
      expect(u.toString(), 'geo:41.9,12.47?q=41.9,12.47(Piazza)');
    });

    test('iOS uses Apple Maps (pin and directions)', () {
      final pin = mapsLaunchUri(41.9, 12.47,
          platform: MapsPlatform.ios, label: 'Piazza');
      expect(pin.host, 'maps.apple.com');
      expect(pin.queryParameters['ll'], '41.9,12.47');
      expect(pin.queryParameters['q'], 'Piazza');
      final dir = mapsLaunchUri(41.9, 12.47,
          platform: MapsPlatform.ios, directions: true);
      expect(dir.queryParameters['daddr'], '41.9,12.47');
    });

    test('web uses the Google Maps web URL', () {
      final u = mapsLaunchUri(41.9, 12.47, platform: MapsPlatform.web);
      expect(u.host, 'www.google.com');
      expect(u.path, '/maps/search/');
      expect(u.queryParameters['query'], '41.9,12.47');
      final d = mapsLaunchUri(41.9, 12.47,
          platform: MapsPlatform.web, directions: true);
      expect(d.path, '/maps/dir/');
      expect(d.queryParameters['destination'], '41.9,12.47');
    });
  });

  test('light basemap is CARTO Positron with the required credit', () {
    expect(MapBasemap.lightTileUrl, contains('basemaps.cartocdn.com/light_all'));
    expect(MapBasemap.lightAttribution, contains('OpenStreetMap'));
    expect(MapBasemap.lightAttribution, contains('CARTO'));
    expect(MapBasemap.lightMaxZoom, 19);
  });

  test('validCoordinates rejects missing, out-of-range and 0,0', () {
    expect(InteractiveLocationMap.validCoordinates(null, 1), isFalse);
    expect(InteractiveLocationMap.validCoordinates(0, 0), isFalse);
    expect(InteractiveLocationMap.validCoordinates(91, 0), isFalse);
    expect(InteractiveLocationMap.validCoordinates(41.9, 12.4), isTrue);
  });

  testWidgets('card shows attribution, gold pin and Open in Maps',
      (tester) async {
    await tester.pumpWidget(_app(const InteractiveLocationMap(
        lat: 41.9, lng: 12.47, label: 'Piazza Navona')));
    await tester.pumpAndSettle();
    expect(find.text(MapBasemap.lightAttribution), findsOneWidget);
    expect(find.byKey(const ValueKey('location-map-pin')), findsOneWidget);
    expect(find.byType(CircleLayer), findsNothing);
    expect(find.byKey(const ValueKey('location-map-open-in-maps')),
        findsOneWidget);
    expect(find.text('Piazza Navona'), findsWidgets);
  });

  testWidgets('approximate mode draws a circle, no pin, no directions',
      (tester) async {
    await tester.pumpWidget(_app(const InteractiveLocationMap(
        lat: 41.9, lng: 12.47, approximateRadiusMeters: 500)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('location-map-pin')), findsNothing);
    expect(find.byType(CircleLayer), findsOneWidget);
    expect(find.text('Approximate area'), findsOneWidget);
    expect(find.byKey(const ValueKey('location-map-open-in-maps')),
        findsNothing);
  });

  testWidgets('tapping the card opens the full-screen map with controls',
      (tester) async {
    await tester.pumpWidget(_app(
        const InteractiveLocationMap(lat: 41.9, lng: 12.47, label: 'Spot')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Expand map'));
    await tester.pumpAndSettle();
    expect(find.byType(LocationMapScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('location-map-zoom-in')), findsOneWidget);
    expect(find.byKey(const ValueKey('location-map-zoom-out')), findsOneWidget);
    expect(find.byKey(const ValueKey('location-map-recenter')), findsOneWidget);
    expect(find.byKey(const ValueKey('location-map-directions')),
        findsOneWidget);
    // Zoom / recenter buttons act on the controller without throwing.
    await tester.tap(find.byKey(const ValueKey('location-map-zoom-in')));
    await tester.tap(find.byKey(const ValueKey('location-map-recenter')));
    await tester.pumpAndSettle();
  });

  testWidgets('chat location bubble renders a static preview and opens the map',
      (tester) async {
    await tester.pumpWidget(_app(const LocationMessageMap(lat: 1.5, lng: 2.5)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-location-map')), findsOneWidget);
    expect(find.byKey(const ValueKey('location-map-pin')), findsOneWidget);
    expect(find.text(MapBasemap.lightAttribution), findsOneWidget);
    // Preview has no zoom controls (static, inside a list).
    expect(find.byKey(const ValueKey('location-map-zoom-in')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('chat-location-map')));
    await tester.pumpAndSettle();
    expect(find.byType(LocationMapScreen), findsOneWidget);
  });

  testWidgets('event detail map only with coordinates', (tester) async {
    await tester.pumpWidget(_app(EventLocationMap(event: _event())));
    expect(find.byType(InteractiveLocationMap), findsNothing);
    await tester.pumpWidget(
        _app(EventLocationMap(event: _event(lat: 41.9, lng: 12.47))));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveLocationMap), findsOneWidget);
  });

  testWidgets('experience detail map only with coordinates, exact pin',
      (tester) async {
    await tester.pumpWidget(
        _app(ExperienceLocationMap(experience: _experience())));
    expect(find.byType(InteractiveLocationMap), findsNothing);
    await tester.pumpWidget(_app(ExperienceLocationMap(
        experience: _experience(lat: 41.88, lng: 12.47))));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveLocationMap), findsOneWidget);
    expect(find.byKey(const ValueKey('location-map-pin')), findsOneWidget);
    expect(find.text('Fountain'), findsWidgets);
  });
}
