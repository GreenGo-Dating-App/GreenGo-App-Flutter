import 'package:equatable/equatable.dart';

/// Represents dating etiquette guidelines for a specific country
class DatingEtiquette extends Equatable {
  final String country;
  final List<EtiquetteSection> sections;
  final DateTime lastUpdated;

  const DatingEtiquette({
    required this.country,
    required this.sections,
    required this.lastUpdated,
  });

  DatingEtiquette copyWith({
    String? country,
    List<EtiquetteSection>? sections,
    DateTime? lastUpdated,
  }) {
    return DatingEtiquette(
      country: country ?? this.country,
      sections: sections ?? this.sections,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [country, sections, lastUpdated];
}

/// A section within dating etiquette content
class EtiquetteSection extends Equatable {
  final String title;
  final String content;
  final List<String> doList;
  final List<String> dontList;

  const EtiquetteSection({
    required this.title,
    required this.content,
    this.doList = const [],
    this.dontList = const [],
  });

  @override
  List<Object?> get props => [title, content, doList, dontList];
}
