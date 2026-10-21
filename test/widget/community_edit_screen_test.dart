// Owner request 2026-10-21: "who created a community can change the
// community info and featured image".
//
// - The create form opens in EDIT mode prefilled with the community.
// - Save dispatches UpdateCommunity with the new values (everything else
//   carried over) and closes on CommunityInfoUpdated.
// - Removing the cover saves imageUrl = null.
// - Only the CREATOR sees "Edit community" in the detail menu (a community
//   admin or a plain member does not).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/di/injection_container.dart' as di;
import 'package:greengo_chat/core/services/blocked_users_service.dart';
import 'package:greengo_chat/features/communities/domain/entities/community.dart';
import 'package:greengo_chat/features/communities/domain/entities/community_member.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_bloc.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_event.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_state.dart';
import 'package:greengo_chat/features/communities/presentation/screens/community_detail_screen.dart';
import 'package:greengo_chat/features/communities/presentation/screens/create_community_screen.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_state.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';

class _MockCommunitiesBloc extends Mock implements CommunitiesBloc {}

class _MockProfileBloc extends Mock implements ProfileBloc {}

class _FakeBlocked extends Fake implements BlockedUsersService {
  @override
  Future<Set<String>> getBlockedUserIds(String userId) async => <String>{};

  @override
  Stream<String> get onUserBlocked => const Stream.empty();
}

const _creator = 'creator';

final Community _existing = Community(
  id: 'c_edit',
  name: 'Porto Coffee Club',
  description: 'Coffee lovers meeting in Porto',
  type: CommunityType.localGuides,
  imageUrl: 'https://example.test/old-cover.jpg',
  createdByUserId: _creator,
  createdByName: 'Creator',
  createdAt: DateTime(2026, 10, 1),
  memberCount: 12,
  languages: const ['en', 'pt'],
  tags: const ['coffee'],
  city: 'Porto',
  country: 'Portugal',
  rules: 'Be kind',
);

void main() {
  setUpAll(() {
    registerFallbackValue(UpdateCommunity(community: _existing));
  });

  late _MockCommunitiesBloc bloc;
  late _MockProfileBloc profile;
  late StreamController<CommunitiesState> states;

  setUp(() {
    bloc = _MockCommunitiesBloc();
    profile = _MockProfileBloc();
    states = StreamController<CommunitiesState>.broadcast();
    when(() => profile.state).thenReturn(const ProfileInitial());
    when(() => profile.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.stream).thenAnswer((_) => states.stream);
    when(() => bloc.state)
        .thenReturn(CommunityDetailLoaded(community: _existing));
    when(() => bloc.add(any())).thenReturn(null);
    when(() => bloc.close()).thenAnswer((_) async {});
  });

  tearDown(() => states.close());

  Widget host(Widget child) => MultiBlocProvider(
        providers: [
          BlocProvider<CommunitiesBloc>.value(value: bloc),
          BlocProvider<ProfileBloc>.value(value: profile),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );

  /// Opens the edit screen from a launcher page so a pop has somewhere to go.
  Future<List<Community?>> pumpEdit(WidgetTester tester) async {
    final popped = <Community?>[];
    await tester.pumpWidget(host(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async {
            final r = await Navigator.of(context).push<Community>(
              MaterialPageRoute(
                builder: (_) => CreateCommunityScreen(
                  existing: _existing,
                  currentUserId: _creator,
                ),
              ),
            );
            popped.add(r);
          },
          child: const Text('open'),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return popped;
  }

  testWidgets('edit mode is prefilled with the community', (tester) async {
    await mockNetworkImagesFor(() async {
      await pumpEdit(tester);
      final l = AppLocalizations.of(
          tester.element(find.byType(CreateCommunityScreen)))!;
      expect(find.text(l.communitiesEditCommunity), findsOneWidget);
      expect(find.text('Porto Coffee Club'), findsOneWidget);
      expect(find.text('Coffee lovers meeting in Porto'), findsOneWidget);
      expect(find.text('Porto'), findsOneWidget);
      expect(find.text('Portugal'), findsOneWidget);
      expect(find.text('#coffee'), findsOneWidget);
      // The current cover is shown (with its remove button), and the
      // create-only sponsorship / preview steps are gone.
      expect(find.byKey(const Key('communityCoverRemove')), findsOneWidget);
      expect(find.text(l.communitiesSponsorThisCommunity), findsNothing);
      expect(find.byKey(const Key('editCommunitySaveButton')), findsOneWidget);
      expect(find.byKey(const Key('createCommunityAppBarAction')), findsNothing);
    });
  });

  testWidgets('Save dispatches UpdateCommunity with the new values and closes',
      (tester) async {
    await mockNetworkImagesFor(() async {
      final popped = await pumpEdit(tester);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Porto Coffee Club'),
          'Lisbon Coffee Club');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Coffee lovers meeting in Porto'),
          'Coffee lovers meeting in Lisbon');
      await tester.enterText(find.widgetWithText(TextField, 'Porto'), 'Lisbon');
      await tester.tap(find.byKey(const Key('editCommunitySaveAppBarAction')));
      await tester.pump();

      final captured = verify(() => bloc.add(captureAny())).captured;
      final update = captured.whereType<UpdateCommunity>().single;
      final c = update.community;
      expect(c.id, 'c_edit');
      expect(c.name, 'Lisbon Coffee Club');
      expect(c.description, 'Coffee lovers meeting in Lisbon');
      expect(c.city, 'Lisbon');
      expect(c.country, 'Portugal');
      expect(c.type, CommunityType.localGuides);
      expect(c.languages, ['en', 'pt']);
      expect(c.tags, ['coffee']);
      expect(c.imageUrl, 'https://example.test/old-cover.jpg',
          reason: 'cover untouched = kept');
      // Carried over unchanged.
      expect(c.createdByUserId, _creator);
      expect(c.memberCount, 12);
      expect(c.createdAt, _existing.createdAt);
      expect(c.rules, 'Be kind');

      // A second tap while saving does not dispatch again.
      await tester.tap(find.byKey(const Key('editCommunitySaveButton')));
      await tester.pump();
      verifyNever(() => bloc.add(any()));

      states.add(CommunityInfoUpdated(community: c));
      await tester.pumpAndSettle();
      expect(find.byType(CreateCommunityScreen), findsNothing);
      expect(popped.single?.name, 'Lisbon Coffee Club');
    });
  });

  testWidgets('removing the cover saves imageUrl = null', (tester) async {
    await mockNetworkImagesFor(() async {
      await pumpEdit(tester);
      await tester.tap(find.byKey(const Key('communityCoverRemove')));
      await tester.pump();
      expect(find.byKey(const Key('communityCoverRemove')), findsNothing);
      await tester.tap(find.byKey(const Key('editCommunitySaveAppBarAction')));
      await tester.pump();
      final update = verify(() => bloc.add(captureAny()))
          .captured
          .whereType<UpdateCommunity>()
          .single;
      expect(update.community.imageUrl, isNull);
      expect(update.community.name, 'Porto Coffee Club');
    });
  });

  testWidgets('an invalid name blocks the save', (tester) async {
    await mockNetworkImagesFor(() async {
      await pumpEdit(tester);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Porto Coffee Club'), 'ab');
      await tester.tap(find.byKey(const Key('editCommunitySaveAppBarAction')));
      await tester.pump();
      verifyNever(() => bloc.add(any(that: isA<UpdateCommunity>())));
    });
  });

  group('detail menu', () {
    setUp(() async {
      await di.sl.reset();
      di.sl.registerSingleton<BlockedUsersService>(_FakeBlocked());
    });
    tearDown(() => di.sl.reset());

    Future<void> openMenu(WidgetTester tester, String uid, CommunityRole role) async {
      when(() => bloc.state).thenReturn(CommunityDetailLoaded(
        community: _existing,
        membershipLoaded: true,
        myMembership: CommunityMember(
          userId: uid,
          displayName: uid,
          role: role,
          joinedAt: DateTime(2026, 10, 2),
        ),
      ));
      await tester.pumpWidget(host(
          CommunityDetailScreen(community: _existing, currentUserId: uid)));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
    }

    testWidgets('the creator sees Edit community and it opens the edit form',
        (tester) async {
      await mockNetworkImagesFor(() async {
        await openMenu(tester, _creator, CommunityRole.owner);
        expect(find.byKey(const ValueKey('community-menu-edit')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('community-menu-edit')));
        await tester.pumpAndSettle();
        final screen = tester.widget<CreateCommunityScreen>(
            find.byType(CreateCommunityScreen));
        expect(screen.existing?.id, 'c_edit');
      });
    });

    testWidgets('a community admin does not see Edit community', (tester) async {
      await mockNetworkImagesFor(() async {
        await openMenu(tester, 'admin_user', CommunityRole.admin);
        expect(find.byKey(const ValueKey('community-menu-edit')), findsNothing);
      });
    });

    testWidgets('a plain member does not see Edit community', (tester) async {
      await mockNetworkImagesFor(() async {
        await openMenu(tester, 'member_user', CommunityRole.member);
        expect(find.byKey(const ValueKey('community-menu-edit')), findsNothing);
      });
    });
  });
}
