import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/widgets/location_pick_card.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('no place yet: "Choose on the map", tap opens the picker', (tester) async {
    var opened = 0;
    await tester.pumpWidget(_app(LocationPickCard(onPick: () => opened++)));
    expect(find.text('Choose on the map'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('location-pick-card')));
    expect(opened, 1);
  });

  testWidgets('place picked: map preview with "Change on the map"', (tester) async {
    var opened = 0;
    await tester.pumpWidget(_app(LocationPickCard(lat: 41.89, lng: 12.49, onPick: () => opened++)));
    expect(find.text('Change on the map'), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('location-pick-card')));
    expect(opened, 1);
  });
}
