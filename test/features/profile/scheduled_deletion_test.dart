// Scheduled account deletion (Apple 5.1.1(v), 2026-10-22), app side:
// deletion can always be requested; with paid, unrefunded sales the sheet
// says what happens and "Request deletion" continues; the server answer
// 'scheduled' becomes ProfileDeletionScheduled; the pending screen shows the
// status and withdraws the request (cancelled listings stay cancelled).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/profile/data/deletion_blockers_service.dart';
import 'package:greengo_chat/features/profile/domain/usecases/create_profile.dart';
import 'package:greengo_chat/features/profile/domain/usecases/get_profile.dart';
import 'package:greengo_chat/features/profile/domain/usecases/update_profile.dart';
import 'package:greengo_chat/features/profile/domain/usecases/upload_photo.dart';
import 'package:greengo_chat/features/profile/domain/usecases/verify_photo.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_event.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_state.dart';
import 'package:greengo_chat/features/profile/presentation/screens/pending_deletion_screen.dart';
import 'package:greengo_chat/features/profile/presentation/widgets/deletion_blockers_sheet.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetProfile extends Mock implements GetProfile {}

class _MockCreateProfile extends Mock implements CreateProfile {}

class _MockUpdateProfile extends Mock implements UpdateProfile {}

class _MockUploadPhoto extends Mock implements UploadPhoto {}

class _MockVerifyPhoto extends Mock implements VerifyPhoto {}

/// No Firebase: overrides every call the screens make.
class _FakeService extends DeletionBlockersService {
  _FakeService({this.state = const DeletionState(), this.cancelResult = CancelDeletionResult.cancelled});

  DeletionState state;
  CancelDeletionResult cancelResult;
  int cancelCalls = 0;
  int fetchCalls = 0;

  @override
  Future<DeletionState> fetchState() async {
    fetchCalls++;
    return state;
  }

  @override
  Future<List<DeletionBlocker>> fetch() async => (await fetchState()).blockers;

  @override
  Future<CancelDeletionResult> cancelScheduledDeletion() async {
    cancelCalls++;
    return cancelResult;
  }
}

const _event = DeletionBlocker(kind: 'event', listingId: 'e1', title: 'Rooftop Samba', paidOrders: 3, refundsInProgress: 1);
const _exp = DeletionBlocker(
  kind: 'experience',
  listingId: 'x1',
  title: 'Cooking class',
  paidOrders: 2,
  failedRefunds: 1,
  bookingIds: ['b1'],
  failedOrderIds: ['o9'],
);

Widget _app(Widget home) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  group('parsing + plan', () {
    test('getDeletionBlockers payload: blockers + live scheduled request', () {
      final s = DeletionState.fromMap({
        'blockers': [
          {'kind': 'event', 'listingId': 'e1', 'title': 'A', 'paidOrders': 2},
        ],
        'scheduled': {
          'status': 'waiting_refunds',
          'requestedAt': '2026-10-22T12:00:00.000Z',
          'cancelledEvents': 2,
          'cancelledBookings': 1,
        },
      });
      expect(s.blockers.single.listingId, 'e1');
      expect(s.scheduled!.status, 'waiting_refunds');
      expect(s.scheduled!.requestedAt, DateTime.utc(2026, 10, 22, 12));
      expect(s.scheduled!.cancelledEvents, 2);
      expect(s.scheduled!.cancelledBookings, 1);
    });

    test('no / withdrawn / unknown request = null (older servers send no field)', () {
      expect(DeletionState.fromMap({'blockers': []}).scheduled, isNull);
      expect(ScheduledDeletion.fromMap({'status': 'cancelled'}), isNull);
      expect(ScheduledDeletion.fromMap({'status': 'weird'}), isNull);
      expect(ScheduledDeletion.fromMap(null), isNull);
      expect(ScheduledDeletion.fromMap({'status': 'deleting'})!.isDeleting, isTrue);
      expect(ScheduledDeletion.fromMap({'status': 'failed'})!.isFailed, isTrue);
    });

    test('plan: listings with paid orders, buyers whose refund has not started', () {
      final p = deletionPlan(const [_event, _exp]);
      expect(p.listings, 2);
      // event: 3 paid - 1 in progress = 2; experience: 2 paid - 1 failed = 1.
      expect(p.buyers, 3);
      expect(deletionPlan(const []), (listings: 0, buyers: 0));
    });
  });

  group('ProfileBloc: the server may schedule instead of delete', () {
    ProfileBloc bloc(Map<String, dynamic> answer) => ProfileBloc(
          getProfile: _MockGetProfile(),
          createProfile: _MockCreateProfile(),
          updateProfile: _MockUpdateProfile(),
          uploadPhoto: _MockUploadPhoto(),
          verifyPhoto: _MockVerifyPhoto(),
          deleteAccountCall: () async => answer,
        );

    test("status 'scheduled' -> ProfileDeletionScheduled (no sign-out)", () async {
      final b = bloc({'success': true, 'status': 'scheduled'});
      final states = <ProfileState>[];
      final sub = b.stream.listen(states.add);
      b.add(const ProfileDeleteRequested(userId: 'u1'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(states.last, isA<ProfileDeletionScheduled>());
      expect(states.whereType<ProfileDeleted>(), isEmpty);
      await sub.cancel();
      await b.close();
    });

    test("status 'deleted' (or none, older server) -> ProfileDeleted", () async {
      for (final answer in [
        {'success': true, 'status': 'deleted'},
        {'success': true},
      ]) {
        final b = bloc(answer);
        final states = <ProfileState>[];
        final sub = b.stream.listen(states.add);
        b.add(const ProfileDeleteRequested(userId: 'u1'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(states.last, isA<ProfileDeleted>());
        await sub.cancel();
        await b.close();
      }
    });
  });

  group('DeletionBlockersSheet (request mode)', () {
    testWidgets('lists the items, says what happens, "Request deletion" continues', (tester) async {
      // A phone-sized tall screen: both items fit in the sheet's list.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      final svc = _FakeService(state: const DeletionState(blockers: [_event, _exp]));
      bool? result;
      await tester.pumpWidget(_app(Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                result = await DeletionBlockersSheet.show(context, blockers: const [_event, _exp], service: svc);
              },
              child: const Text('open'),
            ),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(DeletionBlockersSheet)))!;
      expect(find.text(l10n.deletionScheduleBody), findsOneWidget);
      expect(find.byKey(const ValueKey('blocker_event_e1')), findsOneWidget);
      expect(find.byKey(const ValueKey('blocker_experience_x1')), findsOneWidget);
      // "We'll cancel 2 listings ... 3 buyers are refunded automatically."
      expect(find.text(l10n.deletionScheduleListings(2)), findsOneWidget);
      expect(find.text(l10n.deletionScheduleBuyers(3)), findsOneWidget);
      expect(find.text(l10n.deletionScheduleWhen), findsOneWidget);
      // The failed refund still offers the manual proof upload.
      expect(find.text(l10n.deletionBlockedUploadProof), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('deletion-request-button')));
      await tester.tap(find.byKey(const ValueKey('deletion-request-button')));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('pending-screen mode: items only, no summary / request button', (tester) async {
      final svc = _FakeService(state: const DeletionState(blockers: [_exp]));
      await tester.pumpWidget(_app(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => DeletionBlockersSheet.show(context, blockers: const [_exp], service: svc, requestMode: false),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('deletion-request-button')), findsNothing);
      expect(find.byKey(const ValueKey('deletion-plan-summary')), findsNothing);
      expect(find.byKey(const ValueKey('blocker_experience_x1')), findsOneWidget);
    });
  });

  group('PendingDeletionScreen', () {
    final waiting = DeletionState(
      blockers: const [_exp],
      scheduled: ScheduledDeletion(status: 'waiting_refunds', requestedAt: DateTime(2026, 10, 22, 12), cancelledEvents: 1),
    );

    Future<void> pushScreen(WidgetTester tester, _FakeService svc) async {
      await tester.pumpWidget(_app(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => PendingDeletionScreen.open(context, service: svc),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('status, what is hidden, the remaining items, proof upload', (tester) async {
      final svc = _FakeService(state: waiting);
      await pushScreen(tester, svc);
      final l10n = AppLocalizations.of(tester.element(find.byType(PendingDeletionScreen)))!;
      expect(find.text(l10n.deletionPendingTitle), findsWidgets);
      expect(find.text(l10n.deletionPendingBody('October 22, 2026')), findsOneWidget);
      expect(find.text(l10n.deletionPendingHidden), findsOneWidget);
      expect(find.byKey(const ValueKey('pending_blocker_experience_x1')), findsOneWidget);
      expect(find.text(l10n.deletionBlockedFailedCount(1)), findsOneWidget);
      expect(find.byKey(const ValueKey('pending-deletion-upload-proof')), findsOneWidget);
      expect(find.byKey(const ValueKey('pending-deletion-cancel')), findsOneWidget);
    });

    testWidgets('withdraw: the dialog says cancelled listings stay cancelled; confirmed -> service + back', (tester) async {
      final svc = _FakeService(state: waiting);
      await pushScreen(tester, svc);
      final l10n = AppLocalizations.of(tester.element(find.byType(PendingDeletionScreen)))!;

      await tester.tap(find.byKey(const ValueKey('pending-deletion-cancel')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.deletionPendingCancelConfirm), findsOneWidget);
      // Dismiss first: nothing happens.
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(svc.cancelCalls, 0);

      await tester.tap(find.byKey(const ValueKey('pending-deletion-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pending-deletion-keep-account')));
      await tester.pumpAndSettle();
      expect(svc.cancelCalls, 1);
      expect(find.byType(PendingDeletionScreen), findsNothing);
      expect(find.text(l10n.deletionPendingCancelled), findsOneWidget);
    });

    testWidgets('too late while the deletion runs: says so, stays', (tester) async {
      final svc = _FakeService(state: waiting, cancelResult: CancelDeletionResult.tooLate);
      await pushScreen(tester, svc);
      final l10n = AppLocalizations.of(tester.element(find.byType(PendingDeletionScreen)))!;
      await tester.tap(find.byKey(const ValueKey('pending-deletion-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pending-deletion-keep-account')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.deletionPendingTooLate), findsOneWidget);
      expect(find.byType(PendingDeletionScreen), findsOneWidget);
    });

    testWidgets('deleting: no cancel button', (tester) async {
      final svc = _FakeService(
        state: const DeletionState(scheduled: ScheduledDeletion(status: 'deleting')),
      );
      await pushScreen(tester, svc);
      final l10n = AppLocalizations.of(tester.element(find.byType(PendingDeletionScreen)))!;
      expect(find.text(l10n.deletionPendingDeleting), findsOneWidget);
      expect(find.byKey(const ValueKey('pending-deletion-cancel')), findsNothing);
    });
  });
}
