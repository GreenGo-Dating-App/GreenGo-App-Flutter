import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/user_experiences/domain/mention_parser.dart';

void main() {
  const ana = MentionCandidate(uid: 'u-ana', name: 'Ana');
  const anaMaria = MentionCandidate(uid: 'u-am', name: 'Ana Maria');
  const bob = MentionCandidate(uid: 'u-bob', name: 'Bob Stone');
  const all = [ana, anaMaria, bob];

  group('activeQuery', () {
    test('returns the text after an @ at the caret', () {
      expect(MentionParser.activeQuery('Hi @An', 6), 'An');
      expect(MentionParser.activeQuery('@', 1), '');
      expect(MentionParser.activeQuery('Thanks @Bob St', 14), 'Bob St');
    });

    test('null when not in a mention', () {
      expect(MentionParser.activeQuery('Hi there', 8), isNull);
      // An email is not a mention.
      expect(MentionParser.activeQuery('mail me a@b', 11), isNull);
      // A newline ends the mention.
      expect(MentionParser.activeQuery('@Ana\nnext', 9), isNull);
      expect(MentionParser.activeQuery('@${'x' * 31}', 32), isNull);
      expect(MentionParser.activeQuery('abc', 99), isNull);
    });
  });

  group('suggestions', () {
    test('prefix of the name or of any word, excluding the viewer', () {
      expect(MentionParser.suggestions(all, 'an').map((c) => c.uid),
          ['u-ana', 'u-am']);
      expect(MentionParser.suggestions(all, 'sto').map((c) => c.uid),
          ['u-bob']);
      expect(
          MentionParser.suggestions(all, '', excludeUid: 'u-ana')
              .map((c) => c.uid),
          ['u-am', 'u-bob']);
    });

    test('skips nameless and duplicate candidates', () {
      const nameless = MentionCandidate(uid: 'x', name: ' ');
      expect(
          MentionParser.suggestions([nameless, ana, ana], '')
              .map((c) => c.uid),
          ['u-ana']);
    });
  });

  group('insert', () {
    test('replaces the active @query with @Name and a space', () {
      final r = MentionParser.insert('Thanks @an', 10, 'Ana Maria');
      expect(r.text, 'Thanks @Ana Maria ');
      expect(r.cursor, r.text.length);
    });

    test('keeps the text after the caret', () {
      final r = MentionParser.insert('@b great tour', 2, 'Bob Stone');
      expect(r.text, '@Bob Stone  great tour');
      expect(r.cursor, '@Bob Stone '.length);
    });

    test('no-op without an active mention', () {
      final r = MentionParser.insert('hello', 5, 'Ana');
      expect(r.text, 'hello');
      expect(r.cursor, 5);
    });
  });

  group('resolveMentions', () {
    test('longest name wins and shorter names are not double-counted', () {
      expect(MentionParser.resolveMentions('@Ana Maria loved it', all),
          ['u-am']);
      expect(
          MentionParser.resolveMentions('@Ana and @Ana Maria, thanks!', all),
          unorderedEquals(['u-am', 'u-ana']));
    });

    test('needs a word boundary and is case-insensitive', () {
      expect(MentionParser.resolveMentions('@anabel hi', all), isEmpty);
      expect(MentionParser.resolveMentions('email@Ana.com', all), isEmpty);
      expect(MentionParser.resolveMentions('@bob stone!', all), ['u-bob']);
    });

    test('deduplicated and capped', () {
      expect(MentionParser.resolveMentions('@Ana @Ana', all), ['u-ana']);
      final many = [
        for (var i = 0; i < 15; i++) MentionCandidate(uid: 'u$i', name: 'P$i'),
      ];
      final text = many.map((c) => '@${c.name}').join(' ');
      expect(MentionParser.resolveMentions(text, many, max: 10), hasLength(10));
    });
  });

  group('segments', () {
    test('splits text into plain and mention runs', () {
      final segs = MentionParser.segments(
          'Thanks @Ana Maria and @Bob Stone!', {'u-am': 'Ana Maria', 'u-bob': 'Bob Stone'});
      expect(segs.map((s) => s.text).toList(),
          ['Thanks ', '@Ana Maria', ' and ', '@Bob Stone', '!']);
      expect(segs.where((s) => s.isMention).map((s) => s.uid),
          ['u-am', 'u-bob']);
    });

    test('plain text when nothing matches', () {
      final segs = MentionParser.segments('no mentions', {'u': 'Ana'});
      expect(segs, hasLength(1));
      expect(segs.single.isMention, isFalse);
    });
  });
}
