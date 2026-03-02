import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/cultural_tip.dart';

class CulturalTipModel extends CulturalTip {
  const CulturalTipModel({
    required super.id,
    required super.userId,
    required super.userDisplayName,
    required super.country,
    required super.title,
    required super.content,
    required super.category,
    super.likes,
    required super.createdAt,
  });

  factory CulturalTipModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CulturalTipModel.fromJson({...data, 'id': doc.id});
  }

  factory CulturalTipModel.fromJson(Map<String, dynamic> json) {
    return CulturalTipModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userDisplayName: json['userDisplayName'] as String? ?? 'Anonymous',
      country: json['country'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: TipCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TipCategory.customs,
      ),
      likes: json['likes'] as int? ?? 0,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userDisplayName': userDisplayName,
      'country': country,
      'title': title,
      'content': content,
      'category': category.name,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CulturalTipModel.fromEntity(CulturalTip entity) {
    return CulturalTipModel(
      id: entity.id,
      userId: entity.userId,
      userDisplayName: entity.userDisplayName,
      country: entity.country,
      title: entity.title,
      content: entity.content,
      category: entity.category,
      likes: entity.likes,
      createdAt: entity.createdAt,
    );
  }
}
