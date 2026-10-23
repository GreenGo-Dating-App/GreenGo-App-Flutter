import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/buddies/domain/buddy_catalog.dart';

import '../../support/arb_loader.dart';

void main() {
  group('Buddy catalogue mirrors the server (functions/src/buddies)', () {
    test('121 topics in 12 groups, same ids and groups as topics.ts', () {
      expect(kBuddyTopics.length, 121);
      expect(kBuddyTopicGroups.length, 12);
      final ts = File('functions/src/buddies/topics.ts').readAsStringSync();
      final server = {
        for (final m in RegExp(r"t\('(\w+)', '(\w+)'").allMatches(ts)) m.group(2)!: m.group(1)!,
      };
      expect(server.length, 121);
      expect({for (final t in kBuddyTopics) t.id: t.group}, server);
      expect(kBuddyTopics.map((t) => t.id).toSet().length, 121, reason: 'unique ids');
    });

    test('roles, tones, levels, languages, CEFR and avatars match model.ts', () {
      final ts = File('functions/src/buddies/model.ts').readAsStringSync();
      List<String> list(String name) => RegExp("'([A-Za-z0-9_]+)'")
          .allMatches(RegExp('export const $name = \\[(.*?)\\]').firstMatch(ts)!.group(1)!)
          .map((m) => m.group(1)!)
          .toList();
      expect(BuddyCatalog.roles, list('ROLES'));
      expect(BuddyCatalog.tones, list('TONES'));
      expect(BuddyCatalog.levels, list('LEVELS'));
      expect(BuddyCatalog.cefrLevels, list('CEFR'));
      expect(BuddyCatalog.languages, list('LANGUAGES'));
      expect(BuddyCatalog.avatars.length, 24);
      expect(BuddyCatalog.avatars.first, 'buddy_01');
      expect(BuddyCatalog.avatars.last, 'buddy_24');
    });

    test('every id has a label in the base ARB', () {
      final en = translationKeys(loadArb(kBaseLocale));
      final missing = <String>[
        for (final t in kBuddyTopics)
          if (!en.contains('buddyTopic_${t.id}')) 'buddyTopic_${t.id}',
        for (final g in kBuddyTopicGroups)
          if (!en.contains('buddyTopicGroup_$g')) 'buddyTopicGroup_$g',
        for (final r in BuddyCatalog.roles) ...[
          if (!en.contains('buddyRole_$r')) 'buddyRole_$r',
          if (!en.contains('buddyRoleDesc_$r')) 'buddyRoleDesc_$r',
        ],
        for (final t in BuddyCatalog.tones)
          if (!en.contains('buddyTone_$t')) 'buddyTone_$t',
        for (final l in BuddyCatalog.levels)
          if (!en.contains('buddyLevel_$l')) 'buddyLevel_$l',
        for (final l in BuddyCatalog.languages)
          if (!en.contains('buddyLang_$l')) 'buddyLang_$l',
      ];
      expect(missing, isEmpty);
    });

    test('suggestions use valid ids', () {
      for (final s in BuddySuggestion.all) {
        expect(BuddyCatalog.isKnownTopic(s.topic), isTrue, reason: s.id);
        expect(BuddyCatalog.roles, contains(s.role));
        expect(BuddyCatalog.tones, contains(s.tone));
        expect(BuddyCatalog.avatars, contains(s.avatar));
        expect(BuddyCatalog.levels, contains(s.level));
        if (s.language != null) expect(BuddyCatalog.languages, contains(s.language));
      }
    });
  });

  test('cleanName follows the server rule (1-24 letters/digits/space . \' -)', () {
    expect(BuddyCatalog.cleanName('  Luca   Rossi '), 'Luca Rossi');
    expect(BuddyCatalog.cleanName("O'Neil-Jr."), "O'Neil-Jr.");
    expect(BuddyCatalog.cleanName('Zoë 2'), 'Zoë 2');
    expect(BuddyCatalog.cleanName(''), isNull);
    expect(BuddyCatalog.cleanName('a' * 25), isNull);
    expect(BuddyCatalog.cleanName('hi!'), isNull);
    expect(BuddyCatalog.cleanName('<b>'), isNull);
  });

  test('language topics and locale mapping', () {
    expect(BuddyCatalog.isLanguageTopic('practice_italian'), isTrue);
    expect(BuddyCatalog.isLanguageTopic('movies'), isFalse);
    expect(BuddyCatalog.practiceLanguage('practice_german'), 'de');
    expect(BuddyCatalog.languageForLocale('pt', 'BR'), 'pt_BR');
    expect(BuddyCatalog.languageForLocale('pt', 'PT'), 'pt');
    expect(BuddyCatalog.languageForLocale('ja'), 'en');
  });
}
