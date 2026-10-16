import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/safety/presentation/screens/moderation_decision_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

Future<void> _tall(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Map<String, dynamic> _payload([Map<String, dynamic> extra = const {}]) => {
      'action': 'moderation_decision',
      'decisionId': 'q1',
      'moderationAction': 'removeContent',
      'reasonCode': 'harassment',
      'explanation': 'Insults in a group chat.',
      'appealable': 'true',
      'appealDeadline':
          DateTime.now().add(const Duration(days: 100)).toIso8601String(),
      'contentType': 'message',
      'contentId': 'm1',
      'contentExcerpt': 'you are terrible',
      'automated': 'true',
      'automatedDecision': 'false',
      ...extra,
    };

void main() {
  test('payload routing: decisions and appealable reporter notices only', () {
    expect(isModerationDecisionPayload(_payload()), isTrue);
    expect(
        isModerationDecisionPayload(
            {'action': 'report_reviewed', 'decisionId': 'nr__q1'}),
        isTrue);
    expect(
        isModerationDecisionPayload(
            {'action': 'report_reviewed', 'outcome': 'action_taken'}),
        isFalse);
    expect(isModerationDecisionPayload({'action': 'support_message'}), isFalse);
  });

  test('parses the Terms 18.3 fields (FCM string payload)', () {
    final d = ModerationDecision.fromData(_payload())!;
    expect(d.contentType, 'message');
    expect(d.contentExcerpt, 'you are terrible');
    expect(d.automated, isTrue);
    expect(d.automatedDecision, isFalse);
    expect(d.isReporterDecision, isFalse);
    expect(d.appealWindowOpen, isTrue);
    // Old payloads (before these fields) still parse.
    final old = ModerationDecision.fromData(
        {'decisionId': 'x', 'moderationAction': 'banUser'})!;
    expect(old.role, 'affected');
    expect(old.automated, isFalse);
    expect(old.contentType, '');
  });

  testWidgets('shows content concerned, automated tools and the appeal button',
      (tester) async {
    await _tall(tester);
    await tester.pumpWidget(_app(ModerationDecisionScreen(
        decision: ModerationDecision.fromData(_payload())!)));
    await tester.pumpAndSettle();
    expect(find.text('Content removed'), findsOneWidget);
    expect(find.text('Message: "you are terrible"'), findsOneWidget);
    expect(
        find.text(
            'Automated tools flagged this content. A person took this decision.'),
        findsOneWidget);
    expect(find.byKey(const Key('appealButton')), findsOneWidget);
    expect(find.byKey(const Key('moderationOtherOptions')), findsOneWidget);
  });

  testWidgets('reporter: "no action on your report" can be appealed',
      (tester) async {
    await _tall(tester);
    final d = ModerationDecision.fromData({
      'action': 'report_reviewed',
      'decisionId': 'nr__q1',
      'moderationAction': 'noAction',
      'reasonCode': 'no_violation',
      'role': 'reporter',
      'appealable': 'true',
      'contentType': 'report',
      'appealDeadline':
          DateTime.now().add(const Duration(days: 180)).toIso8601String(),
    })!;
    final sent = <String>[];
    await tester.pumpWidget(_app(ModerationDecisionScreen(
      decision: d,
      submitter: ({required decisionId, required appealReason}) async =>
          sent.add('$decisionId|$appealReason'),
    )));
    await tester.pumpAndSettle();
    expect(find.text('No action taken on your report'), findsOneWidget);
    expect(find.text('Your report'), findsOneWidget);
    expect(
        find.textContaining('We reviewed your report and decided not to act'),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('appealButton')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('appealReasonField')),
        'The message clearly threatened me.');
    await tester.tap(find.byKey(const Key('appealSubmit')));
    await tester.pumpAndSettle();
    expect(sent, ['nr__q1|The message clearly threatened me.']);
    expect(
        find.text(
            'Your appeal is being reviewed by a person who did not take the original decision.'),
        findsOneWidget);
  });

  testWidgets('appeal outcome replaces the appeal button', (tester) async {
    await _tall(tester);
    await tester.pumpWidget(_app(ModerationDecisionScreen(
        decision: ModerationDecision.fromData(_payload({
      'appealable': 'false',
      'appealOutcome': 'overturned',
      'appealExplanation': 'The message was a quote, not an insult.',
      'automatedDecision': 'true',
    }))!)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appealButton')), findsNothing);
    expect(find.text('Decision overturned: we reversed it.'), findsOneWidget);
    expect(find.text('The message was a quote, not an insult.'), findsOneWidget);
    expect(
        find.text(
            'Automated tools detected this content and held it back until a person reviews it.'),
        findsOneWidget);
  });

  testWidgets('translated (pt_BR)', (tester) async {
    await _tall(tester);
    await tester.pumpWidget(_app(
        ModerationDecisionScreen(
            decision: ModerationDecision.fromData(_payload())!),
        locale: const Locale('pt', 'BR')));
    await tester.pumpAndSettle();
    expect(find.text('Mensagem: "you are terrible"'), findsOneWidget);
  });
}
