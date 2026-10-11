import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/safety/data/services/safety_takedown_service.dart';
import 'package:greengo_chat/features/safety/presentation/screens/ncii_request_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

class _Calls {
  final list = <(String, Map<String, dynamic>)>[];
  Object? error;
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data) async {
    list.add((name, data));
    if (error != null) throw error!;
    return {'ok': true, 'reference': 'abcd1234', 'caseId': 'abcd1234xyz'};
  }
}

Future<void> _tall(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _fill(WidgetTester tester, {bool statements = true, bool locations = true}) async {
  Future<void> type(String key, String text) => tester.enterText(find.byKey(ValueKey(key)), text);
  await type('ncii-name', 'Maria Silva');
  await type('ncii-email', 'maria@example.test');
  if (locations) await type('ncii-locations', 'https://greengo-chat.web.app/u/abc123\n\n  profile:xyz789 ');
  await type('ncii-signature', 'Maria Silva');
  if (statements) {
    for (final k in ['ncii-st-depicted', 'ncii-st-goodfaith', 'ncii-st-accurate']) {
      await tester.tap(find.byKey(ValueKey(k)));
    }
  }
  await tester.pump();
}

void main() {
  test('locations: one per line, prefilled first, de-duplicated, max 10', () {
    expect(parseNciiLocations(' a1b \n\nprofile:x1\r\nprofile:x1', prefilled: ['profile:p1']),
        ['profile:p1', 'a1b', 'profile:x1']);
    expect(parseNciiLocations(List.generate(15, (i) => 'loc$i').join('\n')).length, 10);
    expect(parseNciiLocations('ab'), isEmpty);
    expect(nciiProfileLocation('u1'), 'profile:u1');
  });

  testWidgets('nothing is sent until the required fields and all three statements are given', (tester) async {
    await _tall(tester);
    final calls = _Calls();
    await tester.pumpWidget(_app(NciiRequestScreen(service: SafetyTakedownService(call: calls.call))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ncii-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsWidgets);
    expect(find.byKey(const ValueKey('ncii-statements-error')), findsOneWidget);
    expect(calls.list, isEmpty);

    await _fill(tester, statements: false);
    await tester.tap(find.byKey(const ValueKey('ncii-submit')));
    await tester.pumpAndSettle();
    expect(calls.list, isEmpty);
  });

  testWidgets('valid request calls submitSafetyRequest with the TAKE IT DOWN elements', (tester) async {
    await _tall(tester);
    final calls = _Calls();
    await tester.pumpWidget(_app(NciiRequestScreen(
      prefilledLocations: const ['profile:reported1'],
      service: SafetyTakedownService(call: calls.call),
    )));
    await tester.pumpAndSettle();
    expect(find.text('The item you were viewing is already included.'), findsOneWidget);
    await _fill(tester);
    await tester.tap(find.byKey(const ValueKey('ncii-submit')));
    await tester.pumpAndSettle();

    expect(calls.list, hasLength(1));
    final (name, data) = calls.list.single;
    expect(name, 'submitSafetyRequest');
    expect(data['role'], 'depicted_person');
    expect(data['contentLocations'], ['profile:reported1', 'https://greengo-chat.web.app/u/abc123', 'profile:xyz789']);
    expect(data['statements'], {'depictedOrAuthorized': true, 'goodFaith': true, 'accurate': true});
    expect(data['signature'], 'Maria Silva');
    expect(find.byKey(const ValueKey('ncii-submitted')), findsOneWidget);
    expect(find.textContaining('abcd1234'), findsOneWidget);
  });

  testWidgets('acting for someone requires their name; rate limit is reported', (tester) async {
    await _tall(tester);
    final calls = _Calls()..error = FirebaseFunctionsException(code: 'resource-exhausted', message: 'x');
    await tester.pumpWidget(_app(NciiRequestScreen(service: SafetyTakedownService(call: calls.call))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acting for them'));
    await tester.pumpAndSettle();
    await _fill(tester);
    await tester.tap(find.byKey(const ValueKey('ncii-submit')));
    await tester.pumpAndSettle();
    expect(calls.list, isEmpty); // represented person missing
    await tester.enterText(find.byKey(const ValueKey('ncii-represented')), 'Ana Lima');
    await tester.tap(find.byKey(const ValueKey('ncii-submit')));
    await tester.pumpAndSettle();
    expect(calls.list.single.$2['role'], 'authorized_representative');
    expect(calls.list.single.$2['representedPerson'], 'Ana Lima');
    expect(find.byKey(const ValueKey('ncii-error-rateLimited')), findsOneWidget);
  });

  testWidgets('renders in Brazilian Portuguese', (tester) async {
    await _tall(tester);
    await tester.pumpWidget(_app(NciiRequestScreen(service: SafetyTakedownService(call: _Calls().call)), locale: const Locale('pt', 'BR')));
    await tester.pumpAndSettle();
    expect(find.text('Remoção de imagem íntima'), findsOneWidget);
  });
}
