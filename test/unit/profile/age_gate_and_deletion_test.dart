import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/profile/domain/age_gate.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_state.dart';

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

  group(
    'age calculation boundaries (computed from the selected date only)',
    () {
      test('17 years 364 days is blocked, exactly 18 allowed, 35 allowed', () {
        expect(isUnderMinimumAge(DateTime(2008, 10, 9), now: now), isTrue);
        expect(isUnderMinimumAge(DateTime(2008, 10, 8), now: now), isFalse);
        expect(isUnderMinimumAge(DateTime(1991, 10, 8), now: now), isFalse);
        expect(ageOn(DateTime(1991, 10, 8), now), 35);
      });
      test('time of day / zone of either value does not move the boundary', () {
        expect(
          ageOn(DateTime(2008, 10, 8, 23, 59), DateTime(2026, 10, 8, 0, 1)),
          18,
        );
        expect(
          ageOn(DateTime.utc(2008, 10, 9), DateTime(2026, 10, 8, 23, 59)),
          17,
        );
      });
      test('leap-day birthday turns 18 on 1 March of a non-leap year', () {
        expect(
          isUnderMinimumAge(DateTime(2008, 2, 29), now: DateTime(2026, 2, 28)),
          isTrue,
        );
        expect(
          isUnderMinimumAge(DateTime(2008, 2, 29), now: DateTime(2026, 3, 1)),
          isFalse,
        );
        expect(
          isUnderMinimumAge(DateTime(2004, 2, 29), now: DateTime(2022, 2, 28)),
          isTrue,
        );
        expect(
          isUnderMinimumAge(DateTime(2004, 2, 29), now: DateTime(2022, 3, 1)),
          isFalse,
        );
      });
    },
  );

  group('AgeGateService', () {
    AgeGateService gate(
      List<String> sent, {
      Map<String, dynamic>? reply,
      bool offline = false,
    }) => AgeGateService(
      declare: (d) async {
        sent.add(d);
        if (offline) throw Exception('offline');
        return reply ?? {'allowed': true};
      },
      clock: () => now,
      clearLegacyFlag: () async {},
    );

    test('adult: allowed, server told', () async {
      final sent = <String>[];
      expect(
        await gate(sent).check(DateTime(1990, 5, 1)),
        AgeGateResult.allowed,
      );
      expect(sent, ['1990-05-01']);
    });

    test('under 18: refused locally, nothing sent or stored', () async {
      final sent = <String>[];
      expect(
        await gate(sent).check(DateTime(2012, 1, 1)),
        AgeGateResult.underAge,
      );
      expect(sent, isEmpty);
    });

    test(
      'a mistaken 17 pick followed by 35 is allowed (no sticky flag)',
      () async {
        final sent = <String>[];
        final g = gate(sent);
        expect(await g.check(DateTime(2009, 10, 8)), AgeGateResult.underAge);
        expect(await g.check(DateTime(1991, 10, 8)), AgeGateResult.allowed);
        expect(sent, ['1991-10-08']);
      },
    );

    test('under 18 is refused even when the server is unreachable', () async {
      expect(
        await gate([], offline: true).check(DateTime(2015, 6, 1)),
        AgeGateResult.underAge,
      );
    });

    test(
      'adult with server unreachable continues (server trigger re-checks)',
      () async {
        expect(
          await gate([], offline: true).check(DateTime(1985, 6, 1)),
          AgeGateResult.allowed,
        );
      },
    );

    test(
      'server already blocked this account/email: adult date refused',
      () async {
        final r = await gate(
          [],
          reply: {'allowed': false, 'reason': 'AGE_BLOCKED'},
        ).check(DateTime(1985, 6, 1));
        expect(r, AgeGateResult.previouslyBlocked);
      },
    );

    test('the legacy device flag is cleared and never consulted', () async {
      var cleared = 0;
      final g = AgeGateService(
        declare: (_) async => {'allowed': true},
        clock: () => now,
        clearLegacyFlag: () async => cleared++,
      );
      expect(await g.check(DateTime(1985, 6, 1)), AgeGateResult.allowed);
      expect(cleared, 1);
    });
  });

  group('deleteMyAccount error mapping', () {
    test('REQUIRES_RECENT_LOGIN -> re-prompt for the password', () {
      expect(
        ProfileBloc.deleteFailureFor('unauthenticated', {
          'code': 'REQUIRES_RECENT_LOGIN',
        }),
        ProfileDeleteFailure.requiresRecentLogin,
      );
    });
    test('network-ish codes', () {
      expect(
        ProfileBloc.deleteFailureFor('unavailable', null),
        ProfileDeleteFailure.network,
      );
      expect(
        ProfileBloc.deleteFailureFor('deadline-exceeded', null),
        ProfileDeleteFailure.network,
      );
    });
    test('everything else', () {
      expect(
        ProfileBloc.deleteFailureFor('internal', {'code': 'DELETION_FAILED'}),
        ProfileDeleteFailure.failed,
      );
      expect(
        ProfileBloc.deleteFailureFor('unauthenticated', null),
        ProfileDeleteFailure.failed,
      );
    });
  });
}
