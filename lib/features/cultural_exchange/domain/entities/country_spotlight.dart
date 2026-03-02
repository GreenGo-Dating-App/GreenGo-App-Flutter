import 'package:equatable/equatable.dart';

/// Represents a weekly country spotlight feature
class CountrySpotlight extends Equatable {
  final String id;
  final String country;
  final String title;
  final String imageUrl;
  final DateTime weekOf;
  final bool isActive;
  final List<SpotlightSection> sections;

  const CountrySpotlight({
    required this.id,
    required this.country,
    required this.title,
    required this.imageUrl,
    required this.weekOf,
    this.isActive = true,
    this.sections = const [],
  });

  /// Get the cuisine section if it exists
  SpotlightSection? get cuisine => sections.firstWhereOrNull(
        (s) => s.type == SpotlightSectionType.cuisine,
      );

  /// Get the customs section if it exists
  SpotlightSection? get customs => sections.firstWhereOrNull(
        (s) => s.type == SpotlightSectionType.customs,
      );

  /// Get the dating etiquette section if it exists
  SpotlightSection? get datingEtiquette => sections.firstWhereOrNull(
        (s) => s.type == SpotlightSectionType.datingEtiquette,
      );

  /// Get the key phrases section if it exists
  SpotlightSection? get keyPhrases => sections.firstWhereOrNull(
        (s) => s.type == SpotlightSectionType.keyPhrases,
      );

  CountrySpotlight copyWith({
    String? id,
    String? country,
    String? title,
    String? imageUrl,
    DateTime? weekOf,
    bool? isActive,
    List<SpotlightSection>? sections,
  }) {
    return CountrySpotlight(
      id: id ?? this.id,
      country: country ?? this.country,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      weekOf: weekOf ?? this.weekOf,
      isActive: isActive ?? this.isActive,
      sections: sections ?? this.sections,
    );
  }

  @override
  List<Object?> get props => [
        id,
        country,
        title,
        imageUrl,
        weekOf,
        isActive,
        sections,
      ];
}

enum SpotlightSectionType {
  cuisine,
  customs,
  datingEtiquette,
  keyPhrases,
}

class SpotlightSection extends Equatable {
  final String title;
  final String content;
  final String? imageUrl;
  final SpotlightSectionType type;

  const SpotlightSection({
    required this.title,
    required this.content,
    this.imageUrl,
    required this.type,
  });

  @override
  List<Object?> get props => [title, content, imageUrl, type];
}

/// Extension to add firstWhereOrNull since it's not in Equatable
extension _ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
