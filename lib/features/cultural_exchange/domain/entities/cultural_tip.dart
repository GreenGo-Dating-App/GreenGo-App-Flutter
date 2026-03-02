import 'package:equatable/equatable.dart';

/// Represents a user-submitted cultural tip
class CulturalTip extends Equatable {
  final String id;
  final String userId;
  final String userDisplayName;
  final String country;
  final String title;
  final String content;
  final TipCategory category;
  final int likes;
  final DateTime createdAt;

  const CulturalTip({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.country,
    required this.title,
    required this.content,
    required this.category,
    this.likes = 0,
    required this.createdAt,
  });

  CulturalTip copyWith({
    String? id,
    String? userId,
    String? userDisplayName,
    String? country,
    String? title,
    String? content,
    TipCategory? category,
    int? likes,
    DateTime? createdAt,
  }) {
    return CulturalTip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      country: country ?? this.country,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userDisplayName,
        country,
        title,
        content,
        category,
        likes,
        createdAt,
      ];
}

enum TipCategory {
  food,
  transportation,
  dating,
  customs,
  language,
  safety,
}

extension TipCategoryExtension on TipCategory {
  String get displayName {
    switch (this) {
      case TipCategory.food:
        return 'Food';
      case TipCategory.transportation:
        return 'Transportation';
      case TipCategory.dating:
        return 'Dating';
      case TipCategory.customs:
        return 'Customs';
      case TipCategory.language:
        return 'Language';
      case TipCategory.safety:
        return 'Safety';
    }
  }

  String get emoji {
    switch (this) {
      case TipCategory.food:
        return '🍽️';
      case TipCategory.transportation:
        return '🚌';
      case TipCategory.dating:
        return '💕';
      case TipCategory.customs:
        return '🎎';
      case TipCategory.language:
        return '🗣️';
      case TipCategory.safety:
        return '🛡️';
    }
  }
}
