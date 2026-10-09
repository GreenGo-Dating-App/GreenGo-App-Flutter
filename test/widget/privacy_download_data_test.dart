// P3-2: "Download my data" entry in Settings > Privacy & data (GDPR Art.
// 15/20, LGPD Art. 18): confirm, call exportMyData, re-authenticate on
// REQUIRES_RECENT_LOGIN and retry once, show the link, map rate limits.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/analytics_consent_service.dart';
import 'package:greengo_chat/core/services/consent_recorder.dart';
import 'package:greengo_chat/core/services/data_export_service.dart';
import 'package:greengo_chat/features/settings/presentation/screens/privacy_data_settings_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApplier implements AnalyticsCollectionApplier {
  @override
  Future<void> apply({required bool enabled, required bool everEnabled}) async {}
}

class _FakeExport extends DataExportService {
  _FakeExport(this.results);
  final List<DataExportResult> results;
  int calls = 0;

  @override
  Future<DataExportResult> requestExport() async => results[calls++];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AppLocalizations> pump(
    WidgetTester tester, {
    required DataExportService export,
    Future<bool> Function(BuildContext)? reauth,
    Future<bool> Function(Uri)? openUrl,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PrivacyDataSettingsScreen(
        analytics: AnalyticsConsentService(
            applier: _FakeApplier(), deviceCountryCode: () => 'BR'),
        recorder: ConsentRecorder(callable: (_) async {}, currentUid: () => 'u1'),
        dataExport: export,
        reauthenticate: reauth ?? (_) async => false,
        openUrl: openUrl ?? (_) async => true,
      ),
    ));
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(PrivacyDataSettingsScreen)))!;
  }

  Future<void> startExport(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('privacyDownloadDataTile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('privacyDownloadDataConfirm')));
    await tester.pumpAndSettle();
  }

  testWidgets('entry is shown; success shows the link and opens it', (tester) async {
    final export = _FakeExport([
      const DataExportResult.success(url: 'https://example.test/x.zip', emailSent: true),
    ]);
    Uri? opened;
    final l10n = await pump(tester, export: export, openUrl: (u) async {
      opened = u;
      return true;
    });
    expect(find.text(l10n.privacyDownloadDataTitle), findsOneWidget);

    await startExport(tester);
    expect(export.calls, 1);
    expect(find.text(l10n.privacyDownloadDataReadyTitle), findsOneWidget);
    expect(find.textContaining(l10n.privacyDownloadDataReadyEmailed), findsOneWidget);
    await tester.tap(find.byKey(const Key('privacyDownloadDataOpen')));
    await tester.pumpAndSettle();
    expect(opened.toString(), 'https://example.test/x.zip');
  });

  testWidgets('cancelling the confirmation does not call the server', (tester) async {
    final export = _FakeExport([]);
    final l10n = await pump(tester, export: export);
    await tester.tap(find.byKey(const Key('privacyDownloadDataTile')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(export.calls, 0);
  });

  testWidgets('stale sign-in: re-authenticates, then retries once', (tester) async {
    final export = _FakeExport([
      const DataExportResult.failed(DataExportFailure.requiresRecentLogin),
      const DataExportResult.success(url: 'https://example.test/y.zip'),
    ]);
    var reauths = 0;
    final l10n = await pump(tester, export: export, reauth: (_) async {
      reauths++;
      return true;
    });
    await startExport(tester);
    expect(reauths, 1);
    expect(export.calls, 2);
    expect(find.text(l10n.privacyDownloadDataReadyTitle), findsOneWidget);
  });

  testWidgets('re-authentication cancelled: no retry', (tester) async {
    final export = _FakeExport([
      const DataExportResult.failed(DataExportFailure.requiresRecentLogin),
    ]);
    final l10n = await pump(tester, export: export, reauth: (_) async => false);
    await startExport(tester);
    expect(export.calls, 1);
    expect(find.text(l10n.reauthSignInAgain), findsOneWidget);
  });

  testWidgets('rate limited: explains the once-a-day rule', (tester) async {
    final export = _FakeExport([const DataExportResult.failed(DataExportFailure.rateLimited)]);
    final l10n = await pump(tester, export: export);
    await startExport(tester);
    expect(find.text(l10n.privacyDownloadDataRateLimited), findsOneWidget);
  });

  testWidgets('localized (pt_BR)', (tester) async {
    await pump(tester, export: _FakeExport([]), locale: const Locale('pt', 'BR'));
    expect(find.text('Baixar meus dados'), findsOneWidget);
  });

  testWidgets('open-source licenses entry opens the licenses page', (tester) async {
    final l10n = await pump(tester, export: _FakeExport([]));
    expect(find.text(l10n.openSourceLicensesTitle), findsOneWidget);
    await tester.tap(find.byKey(const Key('openSourceLicensesTile')));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  test('server error codes map to failures', () {
    expect(DataExportService.failureFor('unauthenticated', {'code': 'REQUIRES_RECENT_LOGIN'}),
        DataExportFailure.requiresRecentLogin);
    expect(DataExportService.failureFor('resource-exhausted', {'code': 'RATE_LIMITED'}),
        DataExportFailure.rateLimited);
    expect(DataExportService.failureFor('resource-exhausted', {'code': 'EXPORT_IN_PROGRESS'}),
        DataExportFailure.inProgress);
    expect(DataExportService.failureFor('unavailable', null), DataExportFailure.network);
    expect(DataExportService.failureFor('internal', {'code': 'EXPORT_FAILED'}), DataExportFailure.failed);
  });

  test('a callable response becomes a result', () async {
    final ok = await DataExportService(call: () async => {
          'success': true,
          'url': 'https://example.test/z.zip',
          'expiresAt': '2026-10-09T10:00:00.000Z',
          'emailSent': true,
        }).requestExport();
    expect(ok.ok, isTrue);
    expect(ok.emailSent, isTrue);
    expect(ok.expiresAt, DateTime.utc(2026, 10, 9, 10));
    final bad = await DataExportService(call: () async => {'success': false}).requestExport();
    expect(bad.failure, DataExportFailure.failed);
  });
}
