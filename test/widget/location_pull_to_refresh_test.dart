import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/location_change.dart';
import 'package:greengo_chat/core/widgets/location_pull_to_refresh.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Swipe down in Explore = update the location, then reload (owner
/// 2026-10-21).
void main() {
  late List<bool?> refreshCalls;
  late int reloads;
  late List<LocationSkipReason> resolved;

  setUp(() {
    refreshCalls = [];
    reloads = 0;
    resolved = [];
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required PullLocationResult result,
    bool traveler = false,
    bool resolverGrants = false,
    int items = 0,
  }) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: LocationPullToRefresh(
          userId: 'u1',
          isTravelerActive: () => traveler,
          refresher: (uid, {bool? isTravelerActive}) async {
            refreshCalls.add(isTravelerActive);
            return result;
          },
          accessResolver: (reason) async {
            resolved.add(reason);
            return resolverGrants;
          },
          onReload: (_) async => reloads++,
          // Short / empty content: the pull must still work.
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < items; i++) ListTile(title: Text('Row $i')),
            ],
          ),
        ),
      ),
    ));
  }

  Future<void> pull(WidgetTester tester) async {
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
  }

  String snackText(WidgetTester tester) {
    final bar =
        tester.widget<SnackBar>(find.byKey(LocationPullToRefresh.snackBarKey));
    return (bar.content as Text).data!;
  }

  testWidgets('pull fetches + saves the location, reloads and confirms',
      (tester) async {
    await pumpPage(tester,
        items: 2,
        result: const PullLocationResult(
          outcome: LocationRefreshOutcome.changed,
          written: true,
          city: 'Porto',
        ));
    await pull(tester);
    expect(refreshCalls, [false]);
    expect(reloads, 1);
    expect(snackText(tester), 'Location updated: Porto');
  });

  testWidgets('works on an empty page too; a throttled pull still reloads',
      (tester) async {
    await pumpPage(tester,
        result: const PullLocationResult(
          outcome: LocationRefreshOutcome.unchanged,
          city: 'Lisbon',
        ));
    await pull(tester);
    expect(refreshCalls, hasLength(1));
    expect(reloads, 1);
    expect(snackText(tester), 'Location up to date');
  });

  testWidgets('permission denied: message + Allow action, content reloaded',
      (tester) async {
    await pumpPage(tester,
        resolverGrants: true,
        result: const PullLocationResult.skipped(
            LocationSkipReason.permissionDenied));
    await pull(tester);
    expect(reloads, 1, reason: 'the content reloads without a location');
    expect(snackText(tester), contains('Location access is off'));

    // Allow -> permission granted -> the location update + reload run again.
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(resolved, [LocationSkipReason.permissionDenied]);
    expect(refreshCalls, hasLength(2));
    expect(reloads, 2);
  });

  testWidgets('permanently denied: Settings action opens the settings',
      (tester) async {
    await pumpPage(tester,
        result: const PullLocationResult.skipped(
            LocationSkipReason.permissionDeniedForever));
    await pull(tester);
    expect(reloads, 1);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(resolved, [LocationSkipReason.permissionDeniedForever]);
    expect(refreshCalls, hasLength(1), reason: 'not usable yet: no re-run');
  });

  testWidgets('location services off: message, still reloads',
      (tester) async {
    await pumpPage(tester,
        result: const PullLocationResult.skipped(
            LocationSkipReason.serviceDisabled));
    await pull(tester);
    expect(reloads, 1);
    expect(snackText(tester), contains('Location services are off'));
  });

  testWidgets('traveler mode: travel location kept, content still reloads',
      (tester) async {
    await pumpPage(tester,
        traveler: true,
        result:
            const PullLocationResult.skipped(LocationSkipReason.traveler));
    await pull(tester);
    expect(refreshCalls, [true],
        reason: 'the service is told traveler mode is on (no GPS write)');
    expect(reloads, 1);
    expect(snackText(tester), contains('travel location is kept'));
  });

  testWidgets('a hanging location fix never blocks the reload',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: LocationPullToRefresh(
          userId: 'u1',
          locationTimeout: const Duration(seconds: 2),
          refresher: (uid, {bool? isTravelerActive}) =>
              Future<PullLocationResult>.delayed(const Duration(minutes: 1),
                  () => const PullLocationResult.skipped(
                      LocationSkipReason.unavailable)),
          onReload: (_) async => reloads++,
          child: ListView(
              physics: const AlwaysScrollableScrollPhysics(), children: const []),
        ),
      ),
    ));
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pump(const Duration(seconds: 1));
    expect(reloads, 0);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(reloads, 1);
    expect(snackText(tester), contains("Couldn't get your location"));
    // Let the abandoned fix complete so no timer is left pending.
    await tester.pump(const Duration(minutes: 1));
  });

  test('Explore and its Network Discovery list use the location pull', () {
    for (final path in [
      'lib/features/explore/presentation/screens/explore_screen.dart',
      'lib/features/explore/presentation/screens/network_discovery_screen.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(src, contains('LocationPullToRefresh('), reason: path);
      expect(src, isNot(contains('RefreshIndicator(')), reason: path);
    }
  });
}
