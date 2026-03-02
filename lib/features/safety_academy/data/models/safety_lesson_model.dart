import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/safety_lesson.dart';
import 'safety_quiz_model.dart';

/// Firestore data model for [SafetyLesson]
class SafetyLessonModel extends SafetyLesson {
  const SafetyLessonModel({
    required super.id,
    required super.moduleId,
    required super.title,
    required super.contentSections,
    super.quiz,
    required super.xpReward,
    required super.order,
  });

  factory SafetyLessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SafetyLessonModel(
      id: doc.id,
      moduleId: data['moduleId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      contentSections: _parseContentSections(data['contentSections']),
      quiz: data['quiz'] != null
          ? SafetyQuizModel.fromMap(data['quiz'] as Map<String, dynamic>)
          : null,
      xpReward: data['xpReward'] as int? ?? 0,
      order: data['order'] as int? ?? 0,
    );
  }

  factory SafetyLessonModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return SafetyLessonModel(
      id: id ?? map['id'] as String? ?? '',
      moduleId: map['moduleId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      contentSections: _parseContentSections(map['contentSections']),
      quiz: map['quiz'] != null
          ? SafetyQuizModel.fromMap(map['quiz'] as Map<String, dynamic>)
          : null,
      xpReward: map['xpReward'] as int? ?? 0,
      order: map['order'] as int? ?? 0,
    );
  }

  factory SafetyLessonModel.fromEntity(SafetyLesson entity) {
    return SafetyLessonModel(
      id: entity.id,
      moduleId: entity.moduleId,
      title: entity.title,
      contentSections: entity.contentSections,
      quiz: entity.quiz,
      xpReward: entity.xpReward,
      order: entity.order,
    );
  }

  static List<LessonContent> _parseContentSections(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List) return [];

    return raw.map((section) {
      final map = section as Map<String, dynamic>;
      return LessonContent(
        type: _parseContentType(map['type'] as String? ?? 'text'),
        content: map['content'] as String? ?? '',
        items: (map['items'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
    }).toList();
  }

  static LessonContentType _parseContentType(String type) {
    switch (type) {
      case 'tip':
        return LessonContentType.tip;
      case 'warning':
        return LessonContentType.warning;
      case 'checklist':
        return LessonContentType.checklist;
      case 'text':
      default:
        return LessonContentType.text;
    }
  }

  static String _contentTypeToString(LessonContentType type) {
    switch (type) {
      case LessonContentType.text:
        return 'text';
      case LessonContentType.tip:
        return 'tip';
      case LessonContentType.warning:
        return 'warning';
      case LessonContentType.checklist:
        return 'checklist';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'title': title,
      'contentSections': contentSections
          .map((section) => {
                'type': _contentTypeToString(section.type),
                'content': section.content,
                'items': section.items,
              })
          .toList(),
      'quiz': quiz != null ? SafetyQuizModel.fromEntity(quiz!).toJson() : null,
      'xpReward': xpReward,
      'order': order,
    };
  }
}
