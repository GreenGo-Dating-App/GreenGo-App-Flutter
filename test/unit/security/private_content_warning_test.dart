import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/security/private_content_warning.dart';
import 'package:greengo_chat/features/chat/domain/entities/message.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/message_bubble.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// In-memory stand-in for SharedPreferences.
class _MemStore implements PrivateContentWarningStore {
  final Map<String, bool> values = {};
  @override
  Future<bool> isAccepted(String key) async => values[key] ?? false;
  @override
  Future<void> setAccepted(String key) async => values[key] = true;
}

/// Fake backend: the callable and the owner-readable proof records.
class _FakeServer {
  final List<Map<String, Object?>> calls = [];
  final Set<String> records = {}; // "$uid/$version"
  bool fail = false;
  bool offline = false;

  Future<void> record(String uid, Map<String, Object?> payload) async {
    calls.add(payload);
    if (fail) throw Exception('unavailable');
    records.add('$uid/${payload['warningVersion']}');
  }

  Future<bool> read(String uid, String version) async {
    if (offline) throw Exception('offline');
    return records.contains('$uid/$version');
  }
}

PrivateContentWarning _service(
  _FakeServer server,
  _MemStore store, {
  String uid = 'viewer1',
  String version = kPrivateContentWarningVersion,
}) =>
    PrivateContentWarning(
      store: store,
      recorder: (p) => server.record(uid, p),
      serverReader: server.read,
      currentUid: () => uid,
      appVersion: () async => '4.6.0+190',
      version: version,
    );

/// A screen with a button that opens "private content" through the gate.
class _Opener extends StatelessWidget {
  const _Opener({required this.service, required this.onOpened});
  final PrivateContentWarning service;
  final VoidCallback onOpened;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            key: const ValueKey('open'),
            onPressed: () async {
              if (await service.ensureAccepted(context)) onOpened();
            },
            child: const Text('open'), // i18n-ignore: test fixture
          ),
        ),
      );
}

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

ElevatedButton _acceptButton(WidgetTester t) =>
    t.widget<ElevatedButton>(find.byKey(const ValueKey('pcw-accept')));

void main() {
  late _FakeServer server;
  late _MemStore store;
  late int opened;

  setUp(() {
    server = _FakeServer();
    store = _MemStore();
    opened = 0;
  });

  Future<void> pumpOpener(WidgetTester t, PrivateContentWarning svc,
      {Locale locale = const Locale('en')}) async {
    await t.pumpWidget(_app(
        _Opener(service: svc, onOpened: () => opened++),
        locale: locale));
    await t.tap(find.byKey(const ValueKey('open')));
    await t.pumpAndSettle();
  }

  testWidgets('first open shows the warning; the checkbox is required; accept stores proof and opens; second open asks nothing',
      (t) async {
    final svc = _service(server, store);
    await pumpOpener(t, svc);

    expect(find.byType(PrivateContentWarningDialog), findsOneWidget);
    expect(opened, 0, reason: 'content must not open before acceptance');
    final l10n = AppLocalizations.of(
        t.element(find.byType(PrivateContentWarningDialog)))!;
    expect(find.text(l10n.pcwTitle), findsOneWidget);
    expect(find.text(l10n.pcwUnderstand), findsOneWidget);
    expect(find.text(l10n.cancel), findsOneWidget);

    // "I understand" is disabled until the checkbox is ticked.
    expect(_acceptButton(t).onPressed, isNull);
    await t.tap(find.byKey(const ValueKey('pcw-accept')), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(server.calls, isEmpty);
    expect(opened, 0);

    await t.tap(find.byKey(const ValueKey('pcw-checkbox')));
    await t.pump();
    expect(_acceptButton(t).onPressed, isNotNull);
    await t.tap(find.byKey(const ValueKey('pcw-accept')));
    await t.pumpAndSettle();

    expect(find.byType(PrivateContentWarningDialog), findsNothing);
    expect(opened, 1);
    expect(server.calls, hasLength(1));
    final p = server.calls.single;
    expect(p['warningVersion'], 'pcw-1');
    expect(p['locale'], 'en');
    expect(p['appVersion'], '4.6.0+190');
    expect(p['platform'], isA<String>());
    expect(p['text'], PrivateContentWarningDialog.displayedText(l10n));
    expect(p['text'] as String, contains(l10n.pcwForbidden));
    expect(store.values['private_content_warning_pcw-1_viewer1'], isTrue);

    // Second open: no dialog, no new record.
    await t.tap(find.byKey(const ValueKey('open')));
    await t.pumpAndSettle();
    expect(find.byType(PrivateContentWarningDialog), findsNothing);
    expect(opened, 2);
    expect(server.calls, hasLength(1));
  });

  testWidgets('Cancel does not open the content and records nothing', (t) async {
    final svc = _service(server, store);
    await pumpOpener(t, svc);
    await t.tap(find.byKey(const ValueKey('pcw-checkbox')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('pcw-cancel')));
    await t.pumpAndSettle();
    expect(find.byType(PrivateContentWarningDialog), findsNothing);
    expect(opened, 0);
    expect(server.calls, isEmpty);
    expect(store.values, isEmpty);
    // Asked again next time.
    await t.tap(find.byKey(const ValueKey('open')));
    await t.pumpAndSettle();
    expect(find.byType(PrivateContentWarningDialog), findsOneWidget);
  });

  testWidgets('callable failure: not opened, error shown, retry succeeds', (t) async {
    server.fail = true;
    final svc = _service(server, store);
    await pumpOpener(t, svc);
    await t.tap(find.byKey(const ValueKey('pcw-checkbox')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('pcw-accept')));
    await t.pumpAndSettle();

    expect(find.byType(PrivateContentWarningDialog), findsOneWidget);
    expect(find.byKey(const ValueKey('pcw-error')), findsOneWidget);
    expect(opened, 0);
    expect(store.values, isEmpty, reason: 'no local acceptance without proof');

    server.fail = false;
    await t.tap(find.byKey(const ValueKey('pcw-accept')));
    await t.pumpAndSettle();
    expect(find.byType(PrivateContentWarningDialog), findsNothing);
    expect(opened, 1);
    expect(server.records, contains('viewer1/pcw-1'));
  });

  testWidgets('bumping the warning version shows it again', (t) async {
    store.values['private_content_warning_pcw-1_viewer1'] = true;
    server.records.add('viewer1/pcw-1');

    await pumpOpener(t, _service(server, store));
    expect(find.byType(PrivateContentWarningDialog), findsNothing);
    expect(opened, 1);

    final bumped = _service(server, store, version: 'pcw-2');
    await t.pumpWidget(const SizedBox());
    await pumpOpener(t, bumped);
    expect(find.byType(PrivateContentWarningDialog), findsOneWidget);
    expect(opened, 1);
  });

  testWidgets('new device: a server record skips the warning (once per user, not per install)', (t) async {
    server.records.add('viewer1/pcw-1');
    await pumpOpener(t, _service(server, store));
    expect(find.byType(PrivateContentWarningDialog), findsNothing);
    expect(opened, 1);
    expect(store.values['private_content_warning_pcw-1_viewer1'], isTrue);
  });

  testWidgets('offline with no local record: the warning is shown', (t) async {
    server.offline = true;
    await pumpOpener(t, _service(server, store));
    expect(find.byType(PrivateContentWarningDialog), findsOneWidget);
    expect(opened, 0);
  });

  testWidgets('acceptance is per user', (t) async {
    store.values['private_content_warning_pcw-1_viewer1'] = true;
    await pumpOpener(t, _service(server, store, uid: 'viewer2'));
    expect(find.byType(PrivateContentWarningDialog), findsOneWidget);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('warning is localized ($locale)', (t) async {
      await pumpOpener(t, _service(server, store), locale: locale);
      final l10n = AppLocalizations.of(
          t.element(find.byType(PrivateContentWarningDialog)))!;
      expect(find.text(l10n.pcwCheckbox), findsOneWidget);
      expect(find.text(l10n.pcwIntro), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  group('chat bubble (1:1)', () {
    Message video(String sender) => Message(
          messageId: 'm1',
          matchId: 'c1',
          conversationId: 'c1',
          senderId: sender,
          receiverId: sender == 'viewer1' ? 'other' : 'viewer1',
          content: 'https://example.test/v.mp4',
          type: MessageType.video,
          sentAt: DateTime(2026, 10, 11),
        );

    Future<void> pumpBubble(WidgetTester t, {required bool mine}) async {
      PrivateContentWarning.instance = _service(server, store);
      addTearDown(() => PrivateContentWarning.instance = null);
      final pushed = <Route<dynamic>>[];
      await t.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: [_PushObserver(pushed)],
        home: Scaffold(
          body: MessageBubble(
            message: video(mine ? 'viewer1' : 'other'),
            isCurrentUser: mine,
            currentUserId: 'viewer1',
          ),
        ),
      ));
      await t.pump();
      pushedRoutes = pushed;
    }

    testWidgets('received media asks first; Cancel opens nothing', (t) async {
      await pumpBubble(t, mine: false);
      final before = pushedRoutes.length;
      await t.tap(find.byIcon(Icons.play_arrow));
      await t.pumpAndSettle();
      expect(find.byType(PrivateContentWarningDialog), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('pcw-cancel')));
      await t.pumpAndSettle();
      // Only the dialog route was pushed: the player never opened.
      expect(pushedRoutes.length, before + 1);
      expect(pushedRoutes.last, isA<DialogRoute<dynamic>>());
    });

    testWidgets('own media never triggers the warning', (t) async {
      await pumpBubble(t, mine: true);
      final before = pushedRoutes.length;
      await t.tap(find.byIcon(Icons.play_arrow));
      await t.pump();
      expect(find.byType(PrivateContentWarningDialog), findsNothing);
      expect(pushedRoutes.length, before + 1);
      expect(pushedRoutes.last, isA<MaterialPageRoute<dynamic>>());
      expect(server.calls, isEmpty);
    });
  });
}

List<Route<dynamic>> pushedRoutes = [];

class _PushObserver extends NavigatorObserver {
  _PushObserver(this.routes);
  final List<Route<dynamic>> routes;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      routes.add(route);
}
