import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/ai_consent_service.dart';
import 'package:greengo_chat/features/profile/presentation/widgets/ai_services_settings_card.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

class _MemStore implements AiConsentStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
}

class _Server {
  /// The server record: true = accepted, false = withdrawn, null = none.
  bool? record;
  final List<bool> recorded = [];
  bool offline = false;

  Future<void> recorder({required bool accepted, required int version}) async {
    if (offline) throw Exception('offline');
    recorded.add(accepted);
    record = accepted;
  }

  Future<bool?> reader(String uid) async {
    if (offline) throw Exception('offline');
    return record;
  }
}

AiConsentService _svc(_Server server, {_MemStore? store}) => AiConsentService(
      store: store ?? _MemStore(),
      recorder: server.recorder,
      serverReader: server.reader,
      currentUid: () => 'u1',
    );

Future<void> _pump(WidgetTester tester, AiConsentService svc) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(child: AiServicesSettingsCard(service: svc)),
    ),
  ));
  await tester.pumpAndSettle();
}

bool _switchValue(WidgetTester tester) => tester
    .widget<SwitchListTile>(find.byKey(const Key('aiServicesSwitch')))
    .value;

void main() {
  testWidgets('shows the server state: ON when the user accepted', (tester) async {
    final server = _Server()..record = true;
    await _pump(tester, _svc(server));
    expect(find.text('AI services'), findsOneWidget);
    expect(_switchValue(tester), isTrue);
    expect(find.textContaining('On:'), findsOneWidget);
  });

  testWidgets('turning OFF records the withdrawal at once (no confirmation step)',
      (tester) async {
    final server = _Server()..record = true;
    final svc = _svc(server);
    await _pump(tester, svc);

    await tester.tap(find.byKey(const Key('aiServicesSwitch')));
    await tester.pumpAndSettle();

    expect(server.recorded, [false]);
    expect(server.record, isFalse);
    expect(svc.status, AiConsentStatus.declined);
    expect(_switchValue(tester), isFalse);
    expect(find.textContaining('Off:'), findsOneWidget);
    expect(find.text('AI services turned off. Your choice has been recorded.'),
        findsOneWidget);
  });

  testWidgets('turning ON shows the AI notice; only "Allow" records consent',
      (tester) async {
    final server = _Server()..record = false;
    final svc = _svc(server);
    await _pump(tester, svc);
    expect(_switchValue(tester), isFalse);

    // Backing out with "Decline" changes nothing and records nothing.
    await tester.tap(find.byKey(const Key('aiServicesSwitch')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Google Gemini'), findsOneWidget);
    await tester.tap(find.byKey(const Key('aiConsentDecline')));
    await tester.pumpAndSettle();
    expect(server.recorded, isEmpty);
    expect(_switchValue(tester), isFalse);

    // "Allow" records consent and turns the switch on.
    await tester.tap(find.byKey(const Key('aiServicesSwitch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('aiConsentAccept')));
    await tester.pumpAndSettle();
    expect(server.recorded, [true]);
    expect(svc.status, AiConsentStatus.granted);
    expect(_switchValue(tester), isTrue);
  });

  testWidgets('a choice made on another device wins over this device', (tester) async {
    final server = _Server();
    final store = _MemStore();
    final svc = _svc(server, store: store);
    await svc.setDecision(accepted: true); // this device: ON (synced)
    server.record = false; // later turned OFF on the web

    await _pump(tester, _svc(server, store: store));
    expect(_switchValue(tester), isFalse);
  });

  testWidgets('offline: OFF applies locally and says it will sync', (tester) async {
    final server = _Server()..record = true;
    final svc = _svc(server);
    await _pump(tester, svc);
    server.offline = true;

    await tester.tap(find.byKey(const Key('aiServicesSwitch')));
    await tester.pumpAndSettle();
    expect(svc.status, AiConsentStatus.declined);
    expect(svc.hasUnsyncedDecision, isTrue);
    expect(find.textContaining('Saved on this device'), findsOneWidget);
  });

  testWidgets('lists the features and says safety screening stays on', (tester) async {
    await _pump(tester, _svc(_Server()));
    await tester.tap(find.byKey(const Key('aiServicesDetails')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Translating chat messages'), findsOneWidget);
    expect(find.textContaining('support assistant'), findsOneWidget);
    expect(find.textContaining('cannot be turned off'), findsOneWidget);
  });

  group('AiConsentService server reconciliation', () {
    test('a rejected AI call does not re-grant a withdrawal made elsewhere', () async {
      final server = _Server();
      final svc = _svc(server);
      await svc.setDecision(accepted: true);
      server.record = false; // withdrawn on another device
      expect(await svc.resyncAfterServerRejection(), isFalse);
      expect(svc.status, AiConsentStatus.declined);
      expect(server.recorded, [true]); // nothing re-sent
    });

    test('a local decision not yet sent is kept over the server copy', () async {
      final server = _Server()..record = true..offline = true;
      final svc = _svc(server);
      await svc.setDecision(accepted: false);
      server.offline = false;
      expect(await svc.refreshFromServer(), AiConsentStatus.declined);
    });
  });
}
