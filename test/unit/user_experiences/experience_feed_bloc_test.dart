import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/user_experience.dart';
import 'package:greengo_chat/features/user_experiences/domain/repositories/user_experiences_repository.dart';
import 'package:greengo_chat/features/user_experiences/presentation/bloc/experience_feed_bloc.dart';

UserExperience _exp(String id) => UserExperience(
      id: id,
      hostId: 'h',
      title: 'Experience $id',
      description: 'd' * 40,
      category: ExperienceCategory.other,
      mainPhotoUrl: 'https://a/$id.jpg',
      included: const ['x'],
      locationName: 'Somewhere',
      durationMinutes: 60,
      languages: const ['English'],
      maxGroupSize: 4,
      status: ExperienceStatus.published,
    );

/// Serves fixed pages; an empty page in the middle mimics a sparse geo ring.
class _Pager implements ExperienceFeedPager {
  _Pager(this._pages);
  final List<List<UserExperience>> _pages;
  int _i = 0;
  @override
  bool get hasMore => _i < _pages.length;
  @override
  Future<List<UserExperience>> next() async => hasMore ? _pages[_i++] : const [];
}

class _Repo extends Fake implements UserExperiencesRepository {
  _Repo(this.pages);
  final List<List<UserExperience>> pages;
  String? lastHost;
  String? lastQuery;

  @override
  ExperienceFeedPager communityFeed({
    double? lat,
    double? lng,
    ExperienceCategory? category,
    String query = '',
    int pageSize = 20,
  }) {
    lastQuery = query;
    return _Pager(pages);
  }

  @override
  ExperienceFeedPager hostFeed(String hostId, {int pageSize = 20}) {
    lastHost = hostId;
    return _Pager(pages);
  }
}

Future<ExperienceFeedState> _settle(ExperienceFeedBloc b) async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
  return b.state;
}

void main() {
  test('loads page 1, skips an empty ring, appends and dedupes on scroll',
      () async {
    final repo = _Repo([
      [_exp('a'), _exp('b')],
      [],
      [_exp('b'), _exp('c')],
    ]);
    final bloc = ExperienceFeedBloc(repository: repo)
      ..add(const ExperienceFeedStarted(query: 'food'));
    var s = await _settle(bloc);
    expect(s.status, ExperienceFeedStatus.ready);
    expect(s.items.map((e) => e.id), ['a', 'b']);
    expect(s.hasMore, isTrue);
    expect(repo.lastQuery, 'food');

    bloc.add(const ExperienceFeedMoreRequested());
    s = await _settle(bloc);
    expect(s.items.map((e) => e.id), ['a', 'b', 'c']);
    expect(s.hasMore, isFalse);
    await bloc.close();
  });

  test('host mode uses the host feed; local upsert / remove', () async {
    final repo = _Repo([
      [_exp('a')],
    ]);
    final bloc = ExperienceFeedBloc(repository: repo)
      ..add(const ExperienceFeedStarted(hostId: 'me'));
    await _settle(bloc);
    expect(repo.lastHost, 'me');

    bloc.add(ExperienceFeedItemUpserted(_exp('new')));
    var s = await _settle(bloc);
    expect(s.items.map((e) => e.id), ['new', 'a']);

    bloc.add(const ExperienceFeedItemRemoved('a'));
    s = await _settle(bloc);
    expect(s.items.map((e) => e.id), ['new']);
    await bloc.close();
  });
}
