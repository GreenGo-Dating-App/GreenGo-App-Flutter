import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/domain/entities/community.dart';
import 'package:greengo_chat/features/communities/presentation/widgets/community_linked_experiences_tab.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/user_experience.dart';
import 'package:greengo_chat/features/user_experiences/domain/repositories/user_experiences_repository.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Community Experiences tab: empty state (also what a still-building index
/// yields), create button only for owner/admins (same rule as Events), and
/// the host-only drafts read only for them.
class _EmptyPager implements ExperienceFeedPager {
  @override
  bool get hasMore => false;
  @override
  Future<List<UserExperience>> next() async => const [];
}

class _Repo extends Fake implements UserExperiencesRepository {
  final List<String> calls = [];

  @override
  ExperienceFeedPager communityExperiences(String communityId,
      {int pageSize = 20}) {
    calls.add('feed:$communityId:$pageSize');
    return _EmptyPager();
  }

  @override
  Future<List<UserExperience>> hostCommunityDrafts(
      String communityId, String hostId) async {
    calls.add('drafts:$communityId:$hostId');
    return const [];
  }
}

final _community = Community(
  id: 'c1',
  name: 'Lisbon Foodies',
  description: 'desc',
  type: CommunityType.localGuides,
  createdByUserId: 'owner',
  createdByName: 'Owner',
  createdAt: DateTime(2026, 1, 1),
);

Future<void> _pump(WidgetTester tester, _Repo repo,
    {required bool canManage}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CommunityLinkedExperiencesTab(
        community: _community,
        canManage: canManage,
        currentUserId: 'u1',
        repository: repo,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('member: empty state, no create button, no drafts read',
      (tester) async {
    final repo = _Repo();
    await _pump(tester, repo, canManage: false);
    expect(find.text('No experiences yet'), findsOneWidget);
    expect(find.byKey(const Key('communityCreateExperience')), findsNothing);
    expect(repo.calls, ['feed:c1:20']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('owner/admin: create button + own drafts loaded',
      (tester) async {
    final repo = _Repo();
    await _pump(tester, repo, canManage: true);
    expect(find.byKey(const Key('communityCreateExperience')), findsOneWidget);
    expect(find.text('Create experience'), findsOneWidget);
    expect(repo.calls, containsAll(['feed:c1:20', 'drafts:c1:u1']));
    expect(tester.takeException(), isNull);
  });
}
