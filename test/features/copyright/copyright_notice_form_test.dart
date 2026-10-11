import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/copyright/data/copyright_service.dart';
import 'package:greengo_chat/features/copyright/presentation/screens/copyright_counter_notice_screen.dart';
import 'package:greengo_chat/features/copyright/presentation/screens/copyright_notice_form_screen.dart';
import 'package:greengo_chat/features/copyright/presentation/screens/copyright_policy_screen.dart';
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
  Future<void> call(String name, Map<String, dynamic> data) async {
    list.add((name, data));
    if (error != null) throw error!;
  }
}

Future<void> _tall(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 7000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _fillNotice(WidgetTester tester, {String signature = 'Jane Rights', bool statements = true, bool location = true}) async {
  Future<void> type(String key, String text) => tester.enterText(find.byKey(ValueKey(key)), text);
  await type('cr-name', 'Jane Rights');
  await type('cr-email', 'jane@studio.test');
  await type('cr-phone', '+1 555 0100');
  await type('cr-address', '1 Main St, Springfield');
  await type('cr-work', 'My photograph Sunset over the bay');
  if (location) await type('cr-location', 'https://greengo-chat.web.app/e/ev1');
  await type('cr-signature', signature);
  if (statements) {
    for (final k in ['cr-goodFaith', 'cr-accuracy', 'cr-authority']) {
      await tester.tap(find.byKey(ValueKey(k)));
    }
  }
  await tester.pump();
}

void main() {
  test('callable errors map to outcomes; signature normalisation', () {
    expect(CopyrightService.outcomeFor('resource-exhausted'), CopyrightSubmitOutcome.rateLimited);
    expect(CopyrightService.outcomeFor('invalid-argument'), CopyrightSubmitOutcome.invalid);
    expect(CopyrightService.outcomeFor('already-exists'), CopyrightSubmitOutcome.alreadySent);
    expect(CopyrightService.outcomeFor('internal'), CopyrightSubmitOutcome.failed);
    expect(normalizeCopyrightSignature('/s/  JANE   Rights '), 'jane rights');
    expect(isValidCopyrightEmail('a@b.co'), isTrue);
    expect(isValidCopyrightEmail('nope'), isFalse);
    expect(CopyrightContentRef.message('groups', 'g1', 'm1').toJson(), {'type': 'message', 'path': 'groups/g1/messages/m1'});
    expect(CopyrightContentRef.profilePhoto('u1', 'https://x/y.jpg').toJson(),
        {'type': 'profilePhoto', 'path': 'profiles/u1', 'photoUrl': 'https://x/y.jpg'});
  });

  testWidgets('empty form: required fields, statements and nothing sent', (tester) async {
    await _tall(tester);
    final calls = _Calls();
    await tester.pumpWidget(_app(CopyrightNoticeFormScreen(service: CopyrightService(callable: calls.call))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('copyright-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsWidgets);
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.byKey(const ValueKey('cr-statements-error')), findsOneWidget);
    expect(calls.list, isEmpty);
  });

  testWidgets('unchecked sworn statements or a signature that is not the name block submission', (tester) async {
    await _tall(tester);
    final calls = _Calls();
    await tester.pumpWidget(_app(CopyrightNoticeFormScreen(service: CopyrightService(callable: calls.call))));
    await tester.pumpAndSettle();
    await _fillNotice(tester, statements: false);
    await tester.enterText(find.byKey(const ValueKey('cr-details')), 'the event poster');
    await tester.tap(find.byKey(const ValueKey('copyright-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Confirm every statement to continue'), findsOneWidget);
    expect(calls.list, isEmpty);

    await tester.tap(find.byKey(const ValueKey('cr-goodFaith')));
    await tester.tap(find.byKey(const ValueKey('cr-accuracy')));
    await tester.tap(find.byKey(const ValueKey('cr-authority')));
    await tester.enterText(find.byKey(const ValueKey('cr-signature')), 'Someone Else');
    await tester.tap(find.byKey(const ValueKey('copyright-submit')));
    await tester.pumpAndSettle();
    // ignore: avoid_print
    expect(find.text('The signature must match your full legal name'), findsOneWidget);
    expect(calls.list, isEmpty);
  });

  testWidgets('valid notice about a reported item sends every §512(c)(3) element', (tester) async {
    await _tall(tester);
    final calls = _Calls();
    await tester.pumpWidget(_app(CopyrightNoticeFormScreen(
      service: CopyrightService(callable: calls.call),
      content: CopyrightContentRef.message('groups', 'g1', 'm1'),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Reported item: Chat message or media'), findsOneWidget);
    await _fillNotice(tester, signature: '/s/ jane rights', location: false);
    await tester.tap(find.text('Authorized to act for the owner'));
    await tester.tap(find.byKey(const ValueKey('copyright-submit')));
    await tester.pumpAndSettle();

    expect(calls.list, hasLength(1));
    final (name, data) = calls.list.single;
    expect(name, 'submitCopyrightNotice');
    expect(data['complainant'], {
      'name': 'Jane Rights', 'organization': '', 'email': 'jane@studio.test', 'phone': '+1 555 0100',
      'address': '1 Main St, Springfield', 'relationship': 'agent',
    });
    expect(data['content'], {
      'location': 'groups/g1/messages/m1', 'details': '', 'label': 'message',
      'target': {'type': 'message', 'path': 'groups/g1/messages/m1'},
    });
    expect(data['statements'], {'goodFaith': true, 'accuracy': true, 'authority': true});
    expect(data['signature'], '/s/ jane rights');
    expect(data['locale'], 'en');
    expect(find.byKey(const ValueKey('copyright-submitted')), findsOneWidget);
  });

  testWidgets('rate limited: stays on the form with a localized error', (tester) async {
    await _tall(tester);
    final calls = _Calls()..error = FirebaseFunctionsException(code: 'resource-exhausted', message: 'rate_limited');
    await tester.pumpWidget(_app(CopyrightNoticeFormScreen(service: CopyrightService(callable: calls.call)), locale: const Locale('de')));
    await tester.pumpAndSettle();
    await _fillNotice(tester);
    await tester.enterText(find.byKey(const ValueKey('cr-details')), 'the event poster');
    await tester.tap(find.byKey(const ValueKey('copyright-submit')));
    await tester.pumpAndSettle();
    expect(calls.list, hasLength(1));
    expect(find.byKey(const ValueKey('copyright-error-rateLimited')), findsOneWidget);
    expect(find.text('Zu viele Einsendungen. Bitte versuch es später erneut.'), findsOneWidget);
    expect(find.byKey(const ValueKey('copyright-submitted')), findsNothing);
  });

  testWidgets('counter-notice requires both sworn statements and sends the notice id', (tester) async {
    await _tall(tester);
    final calls = _Calls();
    const notice = CopyrightNoticeView(
      id: 'n1', status: 'accepted', complainantName: 'Jane', complainantEmail: 'jane@studio.test',
      work: 'Sunset', location: 'groups/g1/messages/m1',
    );
    await tester.pumpWidget(_app(CopyrightCounterNoticeScreen(notice: notice, service: CopyrightService(callable: calls.call))));
    await tester.pumpAndSettle();
    Future<void> type(String key, String text) => tester.enterText(find.byKey(ValueKey(key)), text);
    await type('cn-name', 'Up Loader');
    await type('cn-email', 'up@example.com');
    await type('cn-phone', '+39 06 1234');
    await type('cn-address', 'Via Roma 1, Roma');
    await type('cn-explanation', 'I took this photo myself.');
    await type('cn-signature', 'Up Loader');
    await tester.tap(find.byKey(const ValueKey('cn-perjury')));
    await tester.tap(find.byKey(const ValueKey('counter-submit')));
    await tester.pumpAndSettle();
    expect(calls.list, isEmpty);
    await tester.tap(find.byKey(const ValueKey('cn-jurisdiction')));
    await tester.tap(find.byKey(const ValueKey('counter-submit')));
    await tester.pumpAndSettle();
    final (name, data) = calls.list.single;
    expect(name, 'submitCopyrightCounterNotice');
    expect(data['noticeId'], 'n1');
    expect(data['statements'], {'perjury': true, 'jurisdiction': true});
  });

  testWidgets('policy screen shows the agent and every section in Portuguese (BR)', (tester) async {
    await _tall(tester);
    await tester.pumpWidget(_app(const CopyrightPolicyScreen(), locale: const Locale('pt', 'BR')));
    await tester.pumpAndSettle();
    expect(find.textContaining('copyright@greengochat.com'), findsOneWidget);
    expect(find.textContaining(kCopyrightAgentPostalAddress), findsOneWidget);
    expect(find.text('Infratores reincidentes'), findsOneWidget);
    expect(find.byKey(const ValueKey('copyright-open-form')), findsOneWidget);
  });
}
