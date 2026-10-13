import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/chat/domain/chat_places.dart';
import 'package:greengo_chat/features/chat/presentation/screens/chat_trip_screen.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/chat_places_bar.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

final _messages = <ChatPlaceSource>[
  (
    id: 'm1',
    text: 'I live in Portugal',
    metadata: {
      'entities': [
        {'s': 10, 'e': 18, 'k': 'k', 'r': ['PT']},
      ],
    },
    sentAt: DateTime(2026, 10, 13, 10, 1),
    fromPartner: true,
  ),
];

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('partner names a place: questions insert into the input, close hides them', (tester) async {
    final places = ChatPlaces.collect(_messages);
    String? inserted;
    await tester.pumpWidget(_app(Column(children: [
      const Spacer(),
      ChatPlacesBar(
        places: places,
        partnerPlaces: ChatPlaces.latestFromPartner(places, _messages),
        onInsert: (t) => inserted = t,
      ),
    ])));

    // No list of places on the chat page: only the questions.
    expect(find.byKey(const ValueKey('chat-places-strip')), findsNothing);
    expect(find.text('Portugal came up - ask about it'), findsOneWidget);
    await tester.tap(find.text('Have you been to Portugal?'));
    expect(inserted, 'Have you been to Portugal?');
    await tester.dragUntilVisible(
      find.text('Portugal: cultural tips'),
      find.descendant(of: find.byKey(const ValueKey('chat-place-suggestions')), matching: find.byType(ListView)),
      const Offset(-200, 0),
    );
    expect(find.text('Portugal: cultural tips'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.byKey(const ValueKey('chat-place-suggestions')), findsNothing);
  });

  testWidgets('map icon opens the places list + map', (tester) async {
    await tester.pumpWidget(_app(ChatPlacesButton(places: ChatPlaces.collect(_messages))));
    await tester.tap(find.byKey(const ValueKey('chat-places-trip')));
    await tester.pumpAndSettle();
    expect(find.text('Places from this chat'), findsOneWidget);
    expect(find.text('Portugal'), findsOneWidget);
  });

  testWidgets('partner named no place: nothing is shown', (tester) async {
    await tester.pumpWidget(_app(ChatPlacesBar(places: const [], partnerPlaces: const [], onInsert: (_) {})));
    expect(find.byKey(const ValueKey('chat-place-suggestions')), findsNothing);
  });

  testWidgets('trip screen lists the places by kind', (tester) async {
    await tester.pumpWidget(_app(ChatTripScreen(places: ChatPlaces.collect(_messages))));
    await tester.pumpAndSettle();
    expect(find.text('Places from this chat'), findsOneWidget);
    expect(find.text('COUNTRIES'), findsOneWidget);
    expect(find.text('Portugal'), findsOneWidget);
  });

  testWidgets('trip list: the red bin removes a false positive (list, map, metadata)', (tester) async {
    final removed = <String>[];
    await tester.pumpWidget(_app(ChatTripScreen(
      places: ChatPlaces.collect(_messages),
      onRemove: (p) async => removed.add(p.key),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Portugal'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('chat-trip-remove-k:PT')));
    await tester.pumpAndSettle();
    expect(removed, ['k:PT']);
    expect(find.text('Portugal'), findsNothing);
    expect(find.textContaining("removed from this chat's places"), findsOneWidget);
  });
}
