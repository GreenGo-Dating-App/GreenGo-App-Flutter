import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/blocked_users_service.dart';
import 'package:greengo_chat/features/safety/data/services/safety_actions_service.dart';
import 'package:greengo_chat/features/safety/presentation/widgets/content_report_flow.dart';
import 'package:greengo_chat/features/safety/presentation/widgets/report_reasons.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Terms 19.3: every report surface offers the reason "Child sexual
/// exploitation", and it must reach the server's csae P0 path. The client
/// writes language-neutral codes, so each code must be one the server's
/// report pipeline maps exactly.
void main() {
  test('one shared list with underage, CSAE and NCII', () {
    expect(kReportReasons, contains(ReportReason.underage));
    expect(kReportReasons, contains(ReportReason.csae));
    expect(kReportReasons, contains(ReportReason.ncii));
    expect(ReportReason.csae.code, 'csae');
  });

  test('every wire code is mapped by the server report pipeline', () {
    final pipeline =
        File('functions/src/safety/reportPipeline.ts').readAsStringSync();
    final start = pipeline.indexOf('const REASON_STRINGS');
    final end = pipeline.indexOf('};', start);
    expect(start, greaterThan(0));
    final table = pipeline.substring(start, end);
    for (final r in kReportReasons) {
      expect(table.contains("'${r.code}'"), isTrue,
          reason: '${r.code} is not in REASON_STRINGS: it would be triaged '
              'as "other"');
    }
    // csae must be the csae code (P0), not just any entry.
    final csaeBlock = table.substring(
        table.indexOf('  csae: ['), table.indexOf('],', table.indexOf('  csae: [')));
    expect(csaeBlock.contains("'csae'"), isTrue);
  });

  test('the English label is the Terms wording', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(en.safetyReportReasonCsae, 'Child sexual exploitation');
  });

  testWidgets('the picker lists every reason and returns the CSAE code',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    ReportReason? picked;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await showReportReasonDialog(context,
                title: 'Report', prompt: 'Why?');
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    for (final r in kReportReasons) {
      expect(find.byKey(ValueKey('report-reason-${r.code}')), findsOneWidget);
    }
    expect(find.text('Child sexual exploitation'), findsOneWidget);
    expect(find.textContaining(kSafetyEmail), findsOneWidget);
    await tester.tap(find.text('Child sexual exploitation'));
    await tester.pumpAndSettle();
    expect(picked, ReportReason.csae);
  });

  testWidgets('a review report lands in `reports` with the code and label',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = FakeFirebaseFirestore();
    final service = SafetyActionsService(
      firestore: db,
      blockedUsersService: BlockedUsersService(firestore: db),
    );
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showContentReportFlow(
              context,
              reporterId: 'me',
              type: 'spot_review',
              contentPath: 'spots/s1/reviews/r1',
              reportedUserId: 'author',
              title: 'Report review',
              description: 'review text',
              extra: const {'spotId': 's1', 'reviewId': 'r1'},
              service: service,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Child sexual exploitation'));
    await tester.pumpAndSettle();
    final docs = (await db.collection('reports').get()).docs;
    expect(docs, hasLength(1));
    expect(docs.single.data(), containsPair('type', 'spot_review'));
    expect(docs.single.data(), containsPair('reason', 'csae'));
    expect(docs.single.data(),
        containsPair('reasonLabel', 'Child sexual exploitation'));
    expect(docs.single.data(), containsPair('reporterId', 'me'));
    expect(docs.single.data(), containsPair('reportedUserId', 'author'));
    expect(docs.single.data(),
        containsPair('reportedContentId', 'spots/s1/reviews/r1'));
  });
}
