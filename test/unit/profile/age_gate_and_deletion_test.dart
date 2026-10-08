import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/profile/domain/age_gate.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_state.dart';

class MemAgeStore implements AgeGateLocalStore {
  bool blocked = false;
  @override
  Future<bool> isBlocked() async => blocked;
  @override
  Future<void> block() async => blocked = true;
}

void main() {
  final now = DateTime(2026, 10, 8);

  group('age calculation', () {
    test('18th birthday today counts as 18', () {
      expect(ageOn(DateTime(2008, 10, 8), now), 18);
      expect(isUnderMinimumAge(DateTime(2008, 10, 8), now: now), isFalse);
    });
    test('one day short of 18 is under age', () {
      expect(ageOn(DateTime(2008, 10, 9), now), 17);
      expect(isUnderMinimumAge(DateTime(2008, 10, 9), now: now), isTrue);
    });
    test('leap-day birthdays', () {
      expect(ageOn(DateTime(2008, 2, 29), DateTime(2026, 2, 28)), 17);
      expect(ageOn(DateTime(2008, 2, 29), DateTime(2026, 3, 1)), 18);
    });
    test('dobToIso keeps the calendar date', () {
      expect(dobToIso(DateTime(1999, 1, 5)), '1999-01-05');
    });
  });

  group('AgeGateService', () {
    test('adult: allowed, server told', () async {
      final sent = <String>[];
      final g = AgeGateService(
        declare: (d) async {
          sent.add(d);
          return {'allowed': true};
        },
        store: MemAgeStore(),
        clock: () => now,
      );
      expect(await g.mayContinue(DateTime(1990, 5, 1)), isTrue);
      expect(sent, ['1990-05-01']);
    });

    test('minor: blocked and recorded on server + device; a new date stays blocked', () async {
      final store = MemAgeStore();
      final sent = <String>[];
      final g = AgeGateService(
        declare: (d) async {
          sent.add(d);
          return {'allowed': false, 'reason': 'UNDER_18'};
        },
        store: store,
        clock: () => now,
      );
      expect(await g.mayContinue(DateTime(2012, 1, 1)), isFalse);
      expect(store.blocked, isTrue);
      expect(await g.mayContinue(DateTime(1980, 1, 1)), isFalse);
      expect(sent, ['2012-01-01']); // device block: no second attempt
    });

    test('minor is blocked even when the server is unreachable', () async {
      final store = MemAgeStore();
      final g = AgeGateService(
        declare: (_) async => throw Exception('offline'),
        store: store,
        clock: () => now,
      );
      expect(await g.mayContinue(DateTime(2015, 6, 1)), isFalse);
      expect(store.blocked, isTrue);
    });

    test('adult with server unreachable continues (server trigger re-checks)', () async {
      final g = AgeGateService(
        declare: (_) async => throw Exception('not deployed'),
        store: MemAgeStore(),
        clock: () => now,
      );
      expect(await g.mayContinue(DateTime(1985, 6, 1)), isTrue);
    });

    test('server says the account was blocked before: adult date refused', () async {
      final store = MemAgeStore();
      final g = AgeGateService(
        declare: (_) async => {'allowed': false, 'reason': 'AGE_BLOCKED'},
        store: store,
        clock: () => now,
      );
      expect(await g.mayContinue(DateTime(1985, 6, 1)), isFalse);
      expect(store.blocked, isTrue);
    });
  });

  group('deleteMyAccount error mapping', () {
    test('REQUIRES_RECENT_LOGIN -> re-prompt for the password', () {
      expect(
        ProfileBloc.deleteFailureFor('unauthenticated', {'code': 'REQUIRES_RECENT_LOGIN'}),
        ProfileDeleteFailure.requiresRecentLogin,
      );
    });
    test('network-ish codes', () {
      expect(ProfileBloc.deleteFailureFor('unavailable', null), ProfileDeleteFailure.network);
      expect(ProfileBloc.deleteFailureFor('deadline-exceeded', null), ProfileDeleteFailure.network);
    });
    test('everything else', () {
      expect(ProfileBloc.deleteFailureFor('internal', {'code': 'DELETION_FAILED'}),
          ProfileDeleteFailure.failed);
      expect(ProfileBloc.deleteFailureFor('unauthenticated', null), ProfileDeleteFailure.failed);
    });
  });
}
