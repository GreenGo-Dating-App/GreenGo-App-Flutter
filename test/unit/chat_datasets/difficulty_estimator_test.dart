import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/chat_datasets/difficulty_estimator.dart';

void main() {
  final common = ['i', 'you', 'the', 'a', 'is', 'it', 'to', 'like', 'want', 'go', 'and',
      'we', 'can', 'eat', 'pizza', 'today', 'tomorrow', 'in', 'my', 'city', 'very', 'good'];
  final est = DifficultyEstimator({
    'en': [...common, for (var i = 0; i < 20000; i++) 'filler$i'],
    'pt_BR': ['eu', 'voce'],
  });

  test('common words are A1', () {
    expect(est.estimate('I want to eat pizza today', 'en'), 'A1');
  });

  test('rare words raise the level', () {
    final level = est.estimate(
        'The ineffable perspicacity of quotidian epistemology bewilders me', 'en');
    expect(DifficultyEstimator.levels.indexOf(level!), greaterThanOrEqualTo(4));
  });

  test('short messages are capped at B1', () {
    expect(est.estimate('Ineffable perspicacity', 'en'), 'B1');
  });

  test('skipped ranges (names) do not count', () {
    const t = 'I like Kolosseum';
    expect(est.estimate(t, 'en', skip: [(7, 16)]), 'A1');
  });

  test('language keys: pt-BR, en_US; unknown -> null', () {
    expect(est.supports('pt-BR'), isTrue);
    expect(est.supports('en_US'), isTrue);
    expect(est.estimate('ciao', 'xx'), isNull);
    expect(est.estimate('123 !!', 'en'), isNull);
  });
}
