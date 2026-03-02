import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/country_spotlight.dart';

class CountrySpotlightModel extends CountrySpotlight {
  const CountrySpotlightModel({
    required super.id,
    required super.country,
    required super.title,
    required super.imageUrl,
    required super.weekOf,
    super.isActive,
    super.sections,
  });

  factory CountrySpotlightModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CountrySpotlightModel.fromJson({...data, 'id': doc.id});
  }

  factory CountrySpotlightModel.fromJson(Map<String, dynamic> json) {
    return CountrySpotlightModel(
      id: json['id'] as String? ?? '',
      country: json['country'] as String? ?? '',
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      weekOf: json['weekOf'] is Timestamp
          ? (json['weekOf'] as Timestamp).toDate()
          : DateTime.tryParse(json['weekOf']?.toString() ?? '') ??
              DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => SpotlightSectionModel.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'title': title,
      'imageUrl': imageUrl,
      'weekOf': Timestamp.fromDate(weekOf),
      'isActive': isActive,
      'sections': sections
          .map((s) => s is SpotlightSectionModel
              ? s.toJson()
              : SpotlightSectionModel.fromEntity(s).toJson())
          .toList(),
    };
  }

  factory CountrySpotlightModel.fromEntity(CountrySpotlight entity) {
    return CountrySpotlightModel(
      id: entity.id,
      country: entity.country,
      title: entity.title,
      imageUrl: entity.imageUrl,
      weekOf: entity.weekOf,
      isActive: entity.isActive,
      sections: entity.sections,
    );
  }
}

class SpotlightSectionModel extends SpotlightSection {
  const SpotlightSectionModel({
    required super.title,
    required super.content,
    super.imageUrl,
    required super.type,
  });

  factory SpotlightSectionModel.fromJson(Map<String, dynamic> json) {
    return SpotlightSectionModel(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      type: SpotlightSectionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SpotlightSectionType.customs,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'type': type.name,
    };
  }

  factory SpotlightSectionModel.fromEntity(SpotlightSection entity) {
    return SpotlightSectionModel(
      title: entity.title,
      content: entity.content,
      imageUrl: entity.imageUrl,
      type: entity.type,
    );
  }
}
