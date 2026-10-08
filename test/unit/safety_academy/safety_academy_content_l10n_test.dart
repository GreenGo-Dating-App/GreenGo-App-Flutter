import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/safety_academy/data/seed/safety_academy_seed_data.dart';
import 'package:greengo_chat/features/safety_academy/domain/entities/safety_lesson.dart';
import 'package:greengo_chat/features/safety_academy/domain/entities/safety_module.dart';
import 'package:greengo_chat/features/safety_academy/presentation/l10n/safety_academy_content_l10n.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  test('English lookup matches the bundled seed text exactly (keys in sync)',
      () {
    for (final m in SafetyAcademySeedData.modules) {
      expect(localizedSafetyModule(en, m), m, reason: m.id);
    }
    for (final l in SafetyAcademySeedData.allLessons) {
      expect(localizedSafetyLesson(en, l), l, reason: l.id);
    }
  });

  test('every seed string is translated in every supported locale', () {
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == 'en') continue;
      final l10n = lookupAppLocalizations(locale);
      for (final m in SafetyAcademySeedData.modules) {
        final lm = localizedSafetyModule(l10n, m);
        expect(lm.title, isNot(m.title), reason: '$locale ${m.id}');
        expect(lm.id, m.id);
      }
      for (final l in SafetyAcademySeedData.allLessons) {
        final ll = localizedSafetyLesson(l10n, l);
        expect(ll.id, l.id);
        expect(ll.contentSections.length, l.contentSections.length);
        expect(ll.contentSections.first.content,
            isNot(l.contentSections.first.content),
            reason: '$locale ${l.id}');
        expect(ll.quiz?.questions.length, l.quiz?.questions.length);
        for (var i = 0; i < (l.quiz?.questions.length ?? 0); i++) {
          expect(ll.quiz!.questions[i].correctIndex,
              l.quiz!.questions[i].correctIndex);
          expect(ll.quiz!.questions[i].question,
              isNot(l.quiz!.questions[i].question),
              reason: '$locale ${l.id} q$i');
        }
      }
    }
  });

  test('unknown ids (e.g. server-only content) fall back to stored text', () {
    const module = SafetyModule(
      id: 'module_server_only',
      title: 'Server title',
      description: 'Server description',
      iconName: 'shield',
      lessons: [],
      order: 9,
      xpReward: 10,
    );
    expect(localizedSafetyModule(en, module), module);

    const lesson = SafetyLesson(
      id: 'lesson_server_only',
      moduleId: 'module_server_only',
      title: 'Server lesson',
      contentSections: [
        LessonContent(type: LessonContentType.text, content: 'Body'),
      ],
      xpReward: 5,
      order: 1,
    );
    expect(localizedSafetyLesson(en, lesson), lesson);
  });
}
