import 'package:equatable/equatable.dart';

/// Community Entity
///
/// Represents an interest group, language circle, or local guide community
class Community extends Equatable {
  final String id;
  final String name;
  final String description;
  final CommunityType type;
  final String? imageUrl;
  final String createdByUserId;
  final String createdByName;
  final DateTime createdAt;
  final int memberCount;
  final List<String> languages;
  final List<String> tags;
  final bool isPublic;
  final String? city;
  final String? country;
  final String? lastMessagePreview;
  final DateTime? lastActivityAt;

  const Community({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.imageUrl,
    required this.createdByUserId,
    required this.createdByName,
    required this.createdAt,
    this.memberCount = 0,
    this.languages = const [],
    this.tags = const [],
    this.isPublic = true,
    this.city,
    this.country,
    this.lastMessagePreview,
    this.lastActivityAt,
  });

  /// Check if community is a language circle
  bool get isLanguageCircle => type == CommunityType.languageCircle;

  /// Check if community is a local guide community
  bool get isLocalGuide => type == CommunityType.localGuides;

  /// Get display subtitle based on type
  String get subtitle {
    if (isLanguageCircle && languages.isNotEmpty) {
      return languages.join(' / ');
    }
    if (isLocalGuide && city != null) {
      return city!;
    }
    if (tags.isNotEmpty) {
      return tags.take(3).join(', ');
    }
    return type.displayName;
  }

  /// Get time since last activity as display text
  String get lastActivityText {
    if (lastActivityAt == null) return 'No activity yet';
    final now = DateTime.now();
    final difference = now.difference(lastActivityAt!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastActivityAt!.month}/${lastActivityAt!.day}/${lastActivityAt!.year}';
    }
  }

  /// Copy with updated fields
  Community copyWith({
    String? id,
    String? name,
    String? description,
    CommunityType? type,
    String? imageUrl,
    String? createdByUserId,
    String? createdByName,
    DateTime? createdAt,
    int? memberCount,
    List<String>? languages,
    List<String>? tags,
    bool? isPublic,
    String? city,
    String? country,
    String? lastMessagePreview,
    DateTime? lastActivityAt,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      memberCount: memberCount ?? this.memberCount,
      languages: languages ?? this.languages,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      city: city ?? this.city,
      country: country ?? this.country,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        imageUrl,
        createdByUserId,
        createdByName,
        createdAt,
        memberCount,
        languages,
        tags,
        isPublic,
        city,
        country,
        lastMessagePreview,
        lastActivityAt,
      ];
}

/// Community Type
enum CommunityType {
  languageCircle('Language Circle'),
  culturalInterest('Cultural Interest'),
  travelGroup('Travel Group'),
  localGuides('Local Guides'),
  studyGroup('Study Group'),
  general('General');

  final String displayName;
  const CommunityType(this.displayName);

  /// Get icon data for this community type
  String get emoji {
    switch (this) {
      case CommunityType.languageCircle:
        return 'language';
      case CommunityType.culturalInterest:
        return 'public';
      case CommunityType.travelGroup:
        return 'flight';
      case CommunityType.localGuides:
        return 'location_on';
      case CommunityType.studyGroup:
        return 'menu_book';
      case CommunityType.general:
        return 'chat';
    }
  }
}

/// Extension for CommunityType serialization
extension CommunityTypeExtension on CommunityType {
  String get value {
    switch (this) {
      case CommunityType.languageCircle:
        return 'language_circle';
      case CommunityType.culturalInterest:
        return 'cultural_interest';
      case CommunityType.travelGroup:
        return 'travel_group';
      case CommunityType.localGuides:
        return 'local_guides';
      case CommunityType.studyGroup:
        return 'study_group';
      case CommunityType.general:
        return 'general';
    }
  }

  static CommunityType fromString(String value) {
    switch (value) {
      case 'language_circle':
        return CommunityType.languageCircle;
      case 'cultural_interest':
        return CommunityType.culturalInterest;
      case 'travel_group':
        return CommunityType.travelGroup;
      case 'local_guides':
        return CommunityType.localGuides;
      case 'study_group':
        return CommunityType.studyGroup;
      case 'general':
        return CommunityType.general;
      default:
        return CommunityType.general;
    }
  }
}
