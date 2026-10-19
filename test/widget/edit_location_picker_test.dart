import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/place_search_service.dart';
import 'package:greengo_chat/core/widgets/location_picker.dart';
import 'package:greengo_chat/core/widgets/map_basemap_layer.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_event.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_state.dart';
import 'package:greengo_chat/features/profile/presentation/screens/edit_location_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../support/profile_fixtures.dart';

class _MockProfileBloc extends Mock implements ProfileBloc {}

class _FakeRepo implements PlaceSearchRepository {
  @override
  Future<List<PlaceSuggestion>> search(String query,
          {required String lang,
          PlaceSearchMode mode = PlaceSearchMode.address,
          double? biasLat,
          double? biasLng,
          String? sessionToken}) async =>
      const [];

  @override
  Future<PickedPlace?> resolve(String placeId, {String? sessionToken}) async => null;

  @override
  Future<PickedPlace?> reverse(double lat, double lng, {required String lang}) async => null;
}

void main() {
  setUpAll(() => MapBasemapLayer.debugDisableTiles = true);
  tearDownAll(() => MapBasemapLayer.debugDisableTiles = false);

  testWidgets('location field opens the map picker; the picked place is shown and saved', (t) async {
    final profile = buildProfile();
    registerFallbackValue(ProfileUpdateRequested(profile: profile));
    final bloc = _MockProfileBloc();
    when(() => bloc.state).thenReturn(const ProfileInitial());
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await t.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<ProfileBloc>.value(
        value: bloc,
        child: EditLocationScreen(profile: profile, placeSearchRepository: _FakeRepo()),
      ),
    ));
    await t.pump();

    final field = find.byKey(const ValueKey('edit-location-search-field'));
    expect(find.text('Search address or pick on map'), findsOneWidget);
    await t.tap(field);
    await t.pumpAndSettle();
    expect(find.byType(LocationPickerScreen), findsOneWidget);

    // Confirming in the picker pops a PickedPlace.
    Navigator.of(t.element(find.byType(LocationPickerScreen))).pop(const PickedPlace(
      address: 'Piazza Navona, 00186 Rome, Italy',
      lat: 41.8992,
      lng: 12.4731,
      city: 'Rome',
      country: 'Italy',
    ));
    await t.pumpAndSettle();
    expect(find.byType(LocationPickerScreen), findsNothing);
    // City-level label (never the street address).
    expect(find.text('Rome, Italy'), findsOneWidget);
    expect(find.textContaining('Piazza Navona'), findsNothing);

    final l = AppLocalizations.of(t.element(find.byType(EditLocationScreen)))!;
    await t.tap(find.widgetWithText(TextButton, l.save));
    await t.pump();
    final ev = verify(() => bloc.add(captureAny())).captured.single as ProfileUpdateRequested;
    expect(ev.profile.location.latitude, 41.8992);
    expect(ev.profile.location.longitude, 12.4731);
    expect(ev.profile.location.city, 'Rome');
    expect(ev.profile.location.country, 'Italy');
    expect(ev.profile.location.displayAddress, 'Rome, Italy');
  });
}
