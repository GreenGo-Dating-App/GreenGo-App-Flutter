// Owner request 2026-10-21: "for a community, I need to be able to transfer
// the community to another user; need password to certify that".
//
// - Only the CREATOR sees "Transfer ownership" in the detail menu.
// - The picker lists members only (not me, not banned, not blocked), is
//   searchable, warns before confirming (and about the sponsorship), asks for
//   the password (re-authentication) EVERY time, then sends the offer.
// - The target sees Accept / Decline (community banner + notification), the
//   owner sees the pending offer with Cancel.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/di/injection_container.dart' as di;
import 'package:greengo_chat/core/services/blocked_users_service.dart';
import 'package:greengo_chat/features/communities/data/services/community_transfer_service.dart';
import 'package:greengo_chat/features/communities/domain/entities/community.dart';
import 'package:greengo_chat/features/communities/domain/entities/community_member.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_bloc.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_event.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_state.dart';
import 'package:greengo_chat/features/communities/presentation/screens/community_detail_screen.dart';
import 'package:greengo_chat/features/communities/presentation/widgets/community_transfer.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_state.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';

class _MockCommunitiesBloc extends Mock implements CommunitiesBloc {}

class _MockProfileBloc extends Mock implements ProfileBloc {}

class _FakeEvent extends Fake implements CommunitiesEvent {}

class _FakeBlocked extends Fake implements BlockedUsersService {
  @override
  Future<Set<String>> getBlockedUserIds(String userId) async => <String>{};

  @override
  Stream<String> get onUserBlocked => const Stream.empty();
}

/// Records calls; never touches Firebase.
class _FakeTransferService extends CommunityTransferService {
  final offers = StreamController<CommunityTransferOffer?>.broadcast();
  final requests = <String>[];
  final responses = <bool>[];
  int cancels = 0;
  CommunityTransferFailure? failWith;

  @override
  Stream<CommunityTransferOffer?> watchOffer({
    required String communityId,
    required String userId,
    required bool asOwner,
  }) =>
      offers.stream;

  @override
  Future<void> request(
      {required String communityId, required String toUserId}) async {
    if (failWith != null) throw CommunityTransferException(failWith!);
    requests.add('$communityId->$toUserId');
  }

  @override
  Future<void> respond(
      {required String communityId, required bool accept}) async {
    if (failWith != null) throw CommunityTransferException(failWith!);
    responses.add(accept);
  }

  @override
  Future<void> cancel({required String communityId}) async => cancels++;
}

const _creator = 'creator';

Community _community({bool sponsored = false}) => Community(
      id: 'c1',
      name: 'Porto Coffee Club',
      description: 'Coffee lovers meeting in Porto',
      type: CommunityType.general,
      createdByUserId: _creator,
      createdByName: 'Creator',
      createdAt: DateTime(2026, 10, 1),
      memberCount: 5,
      isSponsored: sponsored,
      sponsorId: sponsored ? _creator : null,
    );

CommunityMember _m(String id, String name, {bool banned = false, int day = 2}) =>
    CommunityMember(
      userId: id,
      displayName: name,
      joinedAt: DateTime(2026, 10, day),
      isBanned: banned,
    );

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  setUpAll(() => registerFallbackValue(_FakeEvent()));

  late _FakeTransferService service;
  final saved = CommunityTransferService.instance;

  setUp(() {
    service = _FakeTransferService();
    CommunityTransferService.instance = service;
  });
  tearDown(() async {
    CommunityTransferService.instance = saved;
    await service.offers.close();
  });

  group('detail menu', () {
    late _MockCommunitiesBloc bloc;
    late _MockProfileBloc profile;

    setUp(() async {
      await di.sl.reset();
      di.sl.registerSingleton<BlockedUsersService>(_FakeBlocked());
      bloc = _MockCommunitiesBloc();
      profile = _MockProfileBloc();
      when(() => profile.state).thenReturn(const ProfileInitial());
      when(() => profile.stream).thenAnswer((_) => const Stream.empty());
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => bloc.add(any())).thenReturn(null);
      when(() => bloc.close()).thenAnswer((_) async {});
    });
    tearDown(() => di.sl.reset());

    Future<void> openMenu(
        WidgetTester tester, String uid, CommunityRole role) async {
      when(() => bloc.state).thenReturn(CommunityDetailLoaded(
        community: _community(),
        membershipLoaded: true,
        myMembership: CommunityMember(
            userId: uid, displayName: uid, role: role, joinedAt: DateTime(2026)),
      ));
      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider<CommunitiesBloc>.value(value: bloc),
          BlocProvider<ProfileBloc>.value(value: profile),
        ],
        child: _app(
            CommunityDetailScreen(community: _community(), currentUserId: uid)),
      ));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
    }

    testWidgets('the creator sees Transfer ownership', (tester) async {
      await mockNetworkImagesFor(() async {
        await openMenu(tester, _creator, CommunityRole.owner);
        expect(find.byKey(const ValueKey('community-menu-transfer')),
            findsOneWidget);
      });
    });

    testWidgets('an admin, an owner-role member and a member do not',
        (tester) async {
      await mockNetworkImagesFor(() async {
        for (final r in [
          ('admin_user', CommunityRole.admin),
          ('owner_role_user', CommunityRole.owner),
          ('member_user', CommunityRole.member),
        ]) {
          await openMenu(tester, r.$1, r.$2);
          expect(find.byKey(const ValueKey('community-menu-transfer')),
              findsNothing,
              reason: r.$1);
          await tester.tapAt(const Offset(5, 5)); // close the menu
          await tester.pumpAndSettle();
        }
      });
    });
  });

  group('picker', () {
    final members = [
      _m(_creator, 'Creator', day: 1),
      _m('u_ana', 'Ana'),
      _m('u_bob', 'Bob'),
      _m('u_banned', 'Banned Ben', banned: true),
      _m('u_blocked', 'Blocked Bea'),
    ];
    var reauths = 0;
    var reauthResult = true;

    Future<void> pumpPicker(WidgetTester tester, {bool sponsored = false}) async {
      reauths = 0;
      await tester.pumpWidget(_app(CommunityTransferScreen(
        community: _community(sponsored: sponsored),
        currentUserId: _creator,
        blockedIds: const {'u_blocked'},
        service: service,
        loadMembers: (id, {after, required limit}) async =>
            after == null ? members : const <CommunityMember>[],
        reauthenticate: (_) async {
          reauths++;
          return reauthResult;
        },
      )));
      await tester.pumpAndSettle();
    }

    Finder member(String id) =>
        find.byKey(ValueKey('communityTransferMember-$id'));

    testWidgets('lists members only: not me, not banned, not blocked',
        (tester) async {
      await pumpPicker(tester);
      expect(member('u_ana'), findsOneWidget);
      expect(member('u_bob'), findsOneWidget);
      expect(member(_creator), findsNothing);
      expect(member('u_banned'), findsNothing);
      expect(member('u_blocked'), findsNothing);
    });

    testWidgets('search filters by name', (tester) async {
      await pumpPicker(tester);
      await tester.enterText(
          find.byKey(const Key('communityTransferSearch')), 'bo');
      await tester.pump();
      expect(member('u_bob'), findsOneWidget);
      expect(member('u_ana'), findsNothing);
    });

    testWidgets('warning, password, then the offer is sent', (tester) async {
      reauthResult = true;
      await pumpPicker(tester);
      await tester.tap(member('u_ana'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('communityTransferWarning')), findsOneWidget);
      expect(find.byKey(const Key('communityTransferSponsorshipWarning')),
          findsNothing);
      expect(reauths, 0);
      await tester.tap(find.byKey(const Key('communityTransferConfirm')));
      await tester.pumpAndSettle();
      expect(reauths, 1);
      expect(service.requests, ['c1->u_ana']);
    });

    testWidgets('no password confirmation = no offer', (tester) async {
      reauthResult = false;
      await pumpPicker(tester);
      await tester.tap(member('u_bob'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('communityTransferConfirm')));
      await tester.pumpAndSettle();
      expect(reauths, 1);
      expect(service.requests, isEmpty);
      reauthResult = true;
    });

    testWidgets('a sponsored community warns that the sponsorship ends',
        (tester) async {
      await pumpPicker(tester, sponsored: true);
      await tester.tap(member('u_ana'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('communityTransferSponsorshipWarning')),
          findsOneWidget);
    });

    testWidgets('a server refusal is shown and nothing is sent',
        (tester) async {
      service.failWith = CommunityTransferFailure.notMember;
      await pumpPicker(tester);
      await tester.tap(member('u_ana'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('communityTransferConfirm')));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
          tester.element(find.byType(CommunityTransferScreen)))!;
      expect(find.text(l.communityTransferErrorNotMember), findsOneWidget);
      expect(find.byType(CommunityTransferScreen), findsOneWidget);
    });
  });

  group('banner + notification', () {
    const offer = CommunityTransferOffer(
      communityId: 'c1',
      communityName: 'Porto Coffee Club',
      fromUserId: _creator,
      fromName: 'Creator',
      toUserId: 'u_ana',
      toName: 'Ana',
      expiresAt: null,
    );

    testWidgets('the target sees the invitation and accepts', (tester) async {
      var resolved = 0;
      await tester.pumpWidget(_app(Scaffold(
        body: CommunityTransferBanner(
          communityId: 'c1',
          currentUserId: 'u_ana',
          isCreator: false,
          service: service,
          onResolved: () => resolved++,
        ),
      )));
      expect(find.byKey(const Key('communityTransferInvite')), findsNothing);
      service.offers.add(offer);
      await tester.pump();
      expect(find.byKey(const Key('communityTransferInvite')), findsOneWidget);
      expect(find.textContaining('Creator'), findsOneWidget);
      await tester.tap(find.byKey(const Key('communityTransferAccept')));
      await tester.pumpAndSettle();
      expect(service.responses, [true]);
      expect(resolved, 1);
      expect(find.byKey(const Key('communityTransferInvite')), findsNothing);
    });

    testWidgets('the target can decline', (tester) async {
      await tester.pumpWidget(_app(Scaffold(
        body: CommunityTransferBanner(
            communityId: 'c1',
            currentUserId: 'u_ana',
            isCreator: false,
            service: service),
      )));
      service.offers.add(offer);
      await tester.pump();
      await tester.tap(find.byKey(const Key('communityTransferDecline')));
      await tester.pumpAndSettle();
      expect(service.responses, [false]);
    });

    testWidgets('the owner sees the pending offer and can cancel it',
        (tester) async {
      await tester.pumpWidget(_app(Scaffold(
        body: CommunityTransferBanner(
            communityId: 'c1',
            currentUserId: _creator,
            isCreator: true,
            service: service),
      )));
      service.offers.add(offer);
      await tester.pump();
      expect(find.byKey(const Key('communityTransferPending')), findsOneWidget);
      expect(find.byKey(const Key('communityTransferAccept')), findsNothing);
      await tester.tap(find.byKey(const Key('communityTransferCancel')));
      await tester.pumpAndSettle();
      expect(service.cancels, 1);
    });

    testWidgets('anyone else sees nothing', (tester) async {
      await tester.pumpWidget(_app(Scaffold(
        body: CommunityTransferBanner(
            communityId: 'c1',
            currentUserId: 'u_other',
            isCreator: false,
            service: service),
      )));
      service.offers.add(offer);
      await tester.pump();
      expect(find.byKey(const Key('communityTransferInvite')), findsNothing);
      expect(find.byKey(const Key('communityTransferPending')), findsNothing);
    });

    testWidgets('notification Accept answers the offer', (tester) async {
      await tester.pumpWidget(_app(Scaffold(
        body: CommunityTransferNotificationActions(
            communityId: 'c1', service: service),
      )));
      await tester.tap(find.byKey(const Key('notifCommunityTransferAccept')));
      await tester.pumpAndSettle();
      expect(service.responses, [true]);
      expect(find.byKey(const Key('notifCommunityTransferAccept')),
          findsNothing);
    });

    testWidgets('notification on a gone offer explains and hides the buttons',
        (tester) async {
      service.failWith = CommunityTransferFailure.gone;
      await tester.pumpWidget(_app(Scaffold(
        body: CommunityTransferNotificationActions(
            communityId: 'c1', service: service),
      )));
      await tester.tap(find.byKey(const Key('notifCommunityTransferDecline')));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
          tester.element(find.byType(CommunityTransferNotificationActions)))!;
      expect(find.text(l.communityTransferErrorGone), findsOneWidget);
      expect(find.byKey(const Key('notifCommunityTransferDecline')),
          findsNothing);
    });
  });

  test('failure mapping', () {
    CommunityTransferFailure f(String c) =>
        CommunityTransferService.failureFor('failed-precondition', {'code': c});
    expect(f('requires_recent_login'),
        CommunityTransferFailure.requiresRecentLogin);
    expect(f('target_not_member'), CommunityTransferFailure.notMember);
    expect(f('owner_limit_reached'), CommunityTransferFailure.limit);
    expect(f('transfer_pending'), CommunityTransferFailure.pending);
    expect(f('transfer_expired'), CommunityTransferFailure.gone);
    expect(f('whatever'), CommunityTransferFailure.failed);
  });
}
