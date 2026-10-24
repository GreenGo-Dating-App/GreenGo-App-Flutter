import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_message.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_status.dart';
import 'package:greengo_chat/features/buddies/presentation/buddy_segments.dart';

List<(String, String, int)> pairs(String text, String tr, List<BuddySegment> segs) => [
      for (final m in locateBuddySegments(text, tr, segs))
        (text.substring(m.sStart, m.sEnd), tr.substring(m.tStart, m.tEnd), m.color),
    ];

void main() {
  test('pairs keep their order and colour index', () {
    expect(
      pairs('I love the sea', 'Amo il mare', const [
        BuddySegment(s: 'I love', t: 'Amo'),
        BuddySegment(s: 'the sea', t: 'il mare'),
      ]),
      [('I love', 'Amo', 0), ('the sea', 'il mare', 1)],
    );
  });

  test('repeated words: s advances in order; t takes the first free occurrence', () {
    const text = 'very very good';
    const tr = 'molto molto bene';
    final m = locateBuddySegments(text, tr, const [
      BuddySegment(s: 'very', t: 'molto'),
      BuddySegment(s: 'very', t: 'molto'),
      BuddySegment(s: 'good', t: 'bene'),
    ]);
    expect([for (final x in m) x.sStart], [0, 5, 10]);
    expect([for (final x in m) x.tStart], [0, 6, 12]);
  });

  test('t chunks may be reordered', () {
    expect(
      pairs('red car', 'macchina rossa', const [
        BuddySegment(s: 'red', t: 'rossa'),
        BuddySegment(s: 'car', t: 'macchina'),
      ]),
      [('red', 'rossa', 0), ('car', 'macchina', 1)],
    );
  });

  test('a segment that is not a substring is ignored; the next ones still match', () {
    expect(
      pairs('Good morning friend', 'Buongiorno amico', const [
        BuddySegment(s: 'Good morning', t: 'Buongiorno'),
        BuddySegment(s: 'nowhere', t: 'amico'),
        BuddySegment(s: 'friend', t: 'not in translation'),
        BuddySegment(s: 'friend', t: 'amico'),
      ]),
      [('Good morning', 'Buongiorno', 0), ('friend', 'amico', 1)],
    );
  });

  test('parsing: invalid entries skipped; callable segments aligned with replies', () {
    expect(
        BuddySegment.listFrom([
          {'s': 'a', 't': 'b'},
          {'s': '', 't': 'b'},
          {'s': 'a'},
          'x',
        ]),
        const [BuddySegment(s: 'a', t: 'b')]);
    expect(
      BuddyTranslation.fromMap({
        'text': 'Ciao',
        'lang': 'it',
        'segments': [
          {'s': 'Hi', 't': 'Ciao'}
        ],
      })!
          .segments,
      const [BuddySegment(s: 'Hi', t: 'Ciao')],
    );
    final r = BuddySendResult.fromMap(const {
      'replies': ['A', ' ', 'B'],
      'translations': ['a', null, 'b'],
      'translationSegments': [
        [
          {'s': 'A', 't': 'a'}
        ],
        null,
        [
          {'s': 'B', 't': 'b'}
        ],
      ],
      'userTranslation': 'ciao',
      'userTranslationSegments': [
        {'s': 'hi', 't': 'ciao'}
      ],
    });
    expect([for (final b in r.turnBubbles) b.$3], const [
      [BuddySegment(s: 'A', t: 'a')],
      [BuddySegment(s: 'B', t: 'b')],
    ]);
    expect(r.userTranslationSegments, const [BuddySegment(s: 'hi', t: 'ciao')]);
    // Older server: no segment keys at all.
    final old = BuddySendResult.fromMap(const {
      'replies': ['A'],
      'translations': ['a'],
    });
    expect(old.turnBubbles.single.$3, isEmpty);
    expect(old.userTranslationSegments, isEmpty);
  });
}
