import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/buddies/domain/buddy_exception.dart';
import 'package:greengo_chat/features/buddies/presentation/bloc/buddy_builder_cubit.dart';

import '../../support/buddies_fakes.dart';

void main() {
  late FakeBuddiesRepository repo;
  late BuddyBuilderCubit cubit;

  setUp(() {
    repo = FakeBuddiesRepository();
    cubit = BuddyBuilderCubit(repository: repo, language: 'it');
  });

  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });

  test('starts on step 1 with the app language and a warm tone', () {
    expect(cubit.state.step, 0);
    expect(cubit.state.language, 'it');
    expect(cubit.state.tone, 'warm');
    expect(cubit.state.canNext, isFalse, reason: 'a category is required');
    expect(BuddyBuilderState.steps, 3);
  });

  test('unknown app language falls back to English', () async {
    final c = BuddyBuilderCubit(repository: repo, language: 'ja');
    expect(c.state.language, 'en');
    await c.close();
  });

  test('step 1 -> 2 -> 3: category, then tone (always valid), then name + picture', () {
    cubit.next();
    expect(cubit.state.step, 0, reason: 'no category yet');
    cubit.selectTopic('guitar');
    expect(cubit.state.canNext, isTrue);
    cubit.next();
    expect(cubit.state.step, 1);
    // Regression (owner 2026-10-24): step 2 must always be able to continue.
    expect(cubit.state.canNext, isTrue);
    cubit.selectTone('calm');
    cubit.next();
    expect(cubit.state.step, 2);
    expect(cubit.state.isLastStep, isTrue);
    expect(cubit.state.canNext, isFalse);
    cubit.setName('Bad!');
    expect(cubit.state.showNameError, isTrue);
    cubit.setName(' Giulia ');
    expect(cubit.state.canNext, isFalse, reason: 'no picture yet');
    cubit.defaultAvatar('av_fox');
    expect(cubit.state.canNext, isTrue);
    cubit.defaultAvatar('av_owl');
    expect(cubit.state.avatar, 'av_fox', reason: 'default never overrides a choice');
    cubit.selectAvatar('av_owl');
    expect(cubit.state.avatar, 'av_owl');
    cubit.next();
    expect(cubit.state.step, 2, reason: 'next() never goes past the last step');
  });

  test('practice topic sets the Buddy language; others keep it', () {
    cubit.selectTopic('practice_german');
    expect(cubit.state.language, 'de');
    cubit.selectTopic('movies');
    expect(cubit.state.language, 'de');
    cubit.selectLanguage('pt_BR');
    expect(cubit.state.language, 'pt_BR');
    cubit.selectLanguage('xx');
    expect(cubit.state.language, 'pt_BR');
    cubit.selectTopic('not_a_topic');
    expect(cubit.state.topic, 'movies');
  });

  test('back() walks back and is false on the first step', () {
    cubit.selectTopic('movies');
    cubit.next();
    expect(cubit.back(), isTrue);
    expect(cubit.state.step, 0);
    expect(cubit.back(), isFalse);
  });

  test('create sends only category, language, tone, name and picture', () async {
    cubit
      ..selectTopic('practice_italian')
      ..selectTone('playful')
      ..setName('  Luca  Rossi ')
      ..selectAvatar('av_cat');
    final id = await cubit.create();
    expect(id, 'new-buddy');
    final s = repo.created.single;
    expect(s.toMap(), {
      'name': 'Luca Rossi',
      'avatar': 'av_cat',
      'topic': 'practice_italian',
      'tone': 'playful',
      'language': 'it',
      'checkInsEnabled': true,
    });
  });

  test('create on an incomplete form returns null and shows the name error', () async {
    cubit.selectTopic('movies');
    expect(await cubit.create(), isNull);
    expect(repo.created, isEmpty);
    expect(cubit.state.nameTouched, isTrue);
  });

  test('create failure is a BuddyException and re-enables the button', () async {
    repo.createError = FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'tier-required: x',
        details: const {'reason': 'tier-required', 'limit': 1});
    cubit
      ..selectTopic('movies')
      ..setName('Max')
      ..selectAvatar('av_fox');
    await expectLater(cubit.create(),
        throwsA(isA<BuddyException>().having((e) => e.kind, 'kind', BuddyErrorKind.tierRequired)));
    expect(cubit.state.saving, isFalse);
    expect(cubit.state.canNext, isTrue);
  });
}
