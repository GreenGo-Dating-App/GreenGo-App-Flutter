import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_status.dart';
import 'package:greengo_chat/features/buddies/presentation/bloc/buddies_list_bloc.dart';

import '../../support/buddies_fakes.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('buddyListItems (locks like the server activeBuddyIds)', () {
    final a = fakeBuddy('a', createdAt: DateTime(2026, 1, 1), lastMessageAt: DateTime(2026, 10, 1));
    final b = fakeBuddy('b', createdAt: DateTime(2026, 2, 1), lastMessageAt: DateTime(2026, 10, 5));
    final c = fakeBuddy('c', createdAt: DateTime(2026, 3, 1));

    test('the NEWEST Buddies beyond the limit are locked', () {
      final items = buddyListItems([c, a, b], 1);
      final locked = {for (final i in items) i.buddy.id: i.locked};
      expect(locked, {'a': false, 'b': true, 'c': true});
    });

    test('unknown limit (status not loaded) locks nothing', () {
      expect(buddyListItems([a, b, c], null).any((i) => i.locked), isFalse);
    });

    test('sorted by last activity, most recent first (creation when no message)', () {
      expect(buddyListItems([a, b, c], 10).map((i) => i.buddy.id).toList(), ['b', 'a', 'c']);
    });
  });

  group('BuddiesListBloc', () {
    late FakeBuddiesRepository repo;
    late BuddiesListBloc bloc;

    setUp(() {
      repo = FakeBuddiesRepository();
      bloc = BuddiesListBloc(repository: repo);
    });

    tearDown(() async {
      await bloc.close();
      await repo.dispose();
    });

    test('loads Buddies + status, then applies the plan limit', () async {
      repo.status = const BuddyStatus(
          tier: 'SILVER', buddyLimit: 1, buddyCount: 2, freeRepliesPerDay: 30, freeRepliesLeft: 12, coinsPerReply: 1);
      bloc.add(const BuddiesListStarted('u1'));
      await _settle();
      repo.buddies.add([
        fakeBuddy('old', createdAt: DateTime(2026, 1, 1)),
        fakeBuddy('new', createdAt: DateTime(2026, 5, 1)),
      ]);
      await _settle();
      await _settle();
      final s = bloc.state;
      expect(s.loading, isFalse);
      expect(s.status?.freeRepliesLeft, 12);
      expect(s.buddyCount, 2);
      expect(s.canCreateMore, isFalse);
      expect({for (final i in s.items) i.buddy.id: i.locked}, {'old': false, 'new': true});
    });

    test('empty list -> isEmpty, can create', () async {
      bloc.add(const BuddiesListStarted('u1'));
      await _settle();
      repo.buddies.add(const []);
      await _settle();
      await _settle();
      expect(bloc.state.isEmpty, isTrue);
      expect(bloc.state.canCreateMore, isTrue);
    });

    test('stream error is kept for the error view', () async {
      bloc.add(const BuddiesListStarted('u1'));
      await _settle();
      repo.buddies.addError(StateError('offline'));
      await _settle();
      expect(bloc.state.loading, isFalse);
      expect(bloc.state.error, isA<StateError>());
    });
  });
}
