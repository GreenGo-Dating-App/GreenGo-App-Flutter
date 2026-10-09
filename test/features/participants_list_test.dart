import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/participants_list_service.dart';
import 'package:greengo_chat/core/widgets/organizer_share_notice.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

class _FakeService extends ParticipantsListService {
  _FakeService(this.outcome);
  final ParticipantsListOutcome outcome;
  final calls = <Map<String, Object?>>[];

  @override
  Future<ParticipantsListOutcome> send({
    required String kind,
    required String id,
    DateTime? slotStart,
  }) async {
    calls.add({'kind': kind, 'id': id, 'slotStart': slotStart});
    return outcome;
  }
}

void main() {
  test('callable errors map to outcomes', () {
    expect(ParticipantsListService.outcomeFor('resource-exhausted', 'rate_limited'),
        ParticipantsListOutcome.rateLimited);
    expect(ParticipantsListService.outcomeFor('failed-precondition', 'no_email'),
        ParticipantsListOutcome.noEmail);
    expect(ParticipantsListService.outcomeFor('permission-denied', 'not_organizer'),
        ParticipantsListOutcome.failed);
    expect(ParticipantsListService.outcomeFor('unavailable', 'email_failed'),
        ParticipantsListOutcome.failed);
  });

  testWidgets('sharing notice is localized', (tester) async {
    await tester.pumpWidget(_app(const OrganizerShareNotice(), locale: const Locale('it')));
    await tester.pumpAndSettle();
    expect(find.textContaining('organizzatore'), findsOneWidget);
  });

  for (final o in ParticipantsListOutcome.values) {
    testWidgets('button sends and confirms with a snackbar (${o.name})', (tester) async {
      final svc = _FakeService(o);
      await tester.pumpWidget(_app(EmailParticipantsButton(kind: 'event', id: 'ev1', service: svc)));
      await tester.pumpAndSettle();
      expect(find.text('Email me the participants list'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('email-participants-list')));
      await tester.pumpAndSettle();
      expect(svc.calls, [
        {'kind': 'event', 'id': 'ev1', 'slotStart': null},
      ]);
      expect(find.byKey(ValueKey('participants-email-${o.name}')), findsOneWidget);
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.text(participantsListMessage(l, o)), findsOneWidget);
    });
  }
}
