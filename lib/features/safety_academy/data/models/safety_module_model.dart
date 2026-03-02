import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/safety_module.dart';

/// Firestore data model for [SafetyModule]
class SafetyModuleModel extends SafetyModule {
  const SafetyModuleModel({
    required super.id,
    required super.title,
    required super.description,
    required super.iconName,
    required super.lessons,
    required super.order,
    required super.xpReward,
  });

  factory SafetyModuleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SafetyModuleModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      iconName: data['iconName'] as String? ?? 'shield',
      lessons: (data['lessons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      order: data['order'] as int? ?? 0,
      xpReward: data['xpReward'] as int? ?? 0,
    );
  }

  factory SafetyModuleModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return SafetyModuleModel(
      id: id ?? map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'shield',
      lessons: (map['lessons'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      order: map['order'] as int? ?? 0,
      xpReward: map['xpReward'] as int? ?? 0,
    );
  }

  factory SafetyModuleModel.fromEntity(SafetyModule entity) {
    return SafetyModuleModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      iconName: entity.iconName,
      lessons: entity.lessons,
      order: entity.order,
      xpReward: entity.xpReward,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'iconName': iconName,
      'lessons': lessons,
      'order': order,
      'xpReward': xpReward,
    };
  }
}
