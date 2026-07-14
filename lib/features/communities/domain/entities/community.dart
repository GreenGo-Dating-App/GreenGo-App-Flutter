import 'package:equatable/equatable.dart';

/// Community Entity
///
/// Represents an interest group, language circle, or local guide community
class Community extends Equatable {

  const Community({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.createdByUserId, required this.createdByName, required this.createdAt, this.imageUrl,
    this.memberCount = 0,
    this.languages = const [],
    this.tags = const [],
    this.isPublic = true,
    this.city,
    this.country,
    this.lastMessagePreview,
    this.lastActivityAt,
    this.sponsorId,
    this.isSponsored = false,
    this.pinnedPromo,
    this.rules,
    this.resourceLinks = const [],
  });
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

  /// UID of the business account that sponsors/owns this community.
  /// Null when the community is a regular community-created group.
  final String? sponsorId;

  /// Whether this community is business-sponsored (shows the gold badge).
  final bool isSponsored;

  /// Optional promo pinned to the top of the community by its sponsor.
  final PinnedPromo? pinnedPromo;

  /// Community rules / guidelines shown in the pinned Rules & Resources header.
  final String? rules;

  /// Pinned resource links (phrase pack, city guide, house rules doc, …) shown
  /// in the Rules & Resources header.
  final List<CommunityLink> resourceLinks;

  /// Whether the community has any pinned rules or resources to show.
  bool get hasRulesOrResources =>
      (rules != null && rules!.trim().isNotEmpty) || resourceLinks.isNotEmpty;

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
    String? sponsorId,
    bool? isSponsored,
    PinnedPromo? pinnedPromo,
    bool clearPinnedPromo = false,
    bool clearSponsorId = false,
    String? rules,
    bool clearRules = false,
    List<CommunityLink>? resourceLinks,
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
      sponsorId: clearSponsorId ? null : (sponsorId ?? this.sponsorId),
      isSponsored: isSponsored ?? this.isSponsored,
      pinnedPromo:
          clearPinnedPromo ? null : (pinnedPromo ?? this.pinnedPromo),
      rules: clearRules ? null : (rules ?? this.rules),
      resourceLinks: resourceLinks ?? this.resourceLinks,
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
        sponsorId,
        isSponsored,
        pinnedPromo,
        rules,
        resourceLinks,
      ];
}

/// A pinned resource link shown in a community's Rules & Resources header —
/// e.g. a phrase pack, a city guide, or the community's house-rules doc.
class CommunityLink extends Equatable {
  const CommunityLink({required this.title, required this.url});

  factory CommunityLink.fromMap(Map<String, dynamic> map) {
    return CommunityLink(
      title: map['title'] as String? ?? '',
      url: map['url'] as String? ?? '',
    );
  }

  final String title;
  final String url;

  bool get isValid => title.trim().isNotEmpty && url.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {'title': title, 'url': url};

  @override
  List<Object?> get props => [title, url];
}

/// Pinned Promo
///
/// A promotional card a sponsoring business pins to the top of a community.
/// Tapping it opens either a linked in-app event ([linkEventId]) or an
/// external link ([linkUrl]).
class PinnedPromo extends Equatable {
  const PinnedPromo({
    required this.title,
    required this.body,
    this.imageUrl,
    this.linkEventId,
    this.linkUrl,
  });

  /// Create from a Firestore/JSON map (backward-compatible; all defaults empty).
  factory PinnedPromo.fromMap(Map<String, dynamic> map) {
    return PinnedPromo(
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      linkEventId: map['linkEventId'] as String?,
      linkUrl: map['linkUrl'] as String?,
    );
  }

  final String title;
  final String body;
  final String? imageUrl;

  /// In-app event id to open when tapped (takes priority over [linkUrl]).
  final String? linkEventId;

  /// External URL to open when tapped (used when [linkEventId] is null).
  final String? linkUrl;

  /// Whether this promo has any usable tap target.
  bool get hasTarget =>
      (linkEventId != null && linkEventId!.isNotEmpty) ||
      (linkUrl != null && linkUrl!.isNotEmpty);

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'linkEventId': linkEventId,
      'linkUrl': linkUrl,
    };
  }

  PinnedPromo copyWith({
    String? title,
    String? body,
    String? imageUrl,
    String? linkEventId,
    String? linkUrl,
  }) {
    return PinnedPromo(
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      linkEventId: linkEventId ?? this.linkEventId,
      linkUrl: linkUrl ?? this.linkUrl,
    );
  }

  @override
  List<Object?> get props => [title, body, imageUrl, linkEventId, linkUrl];
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
