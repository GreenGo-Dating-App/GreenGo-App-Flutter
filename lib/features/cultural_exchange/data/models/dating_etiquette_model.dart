import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dating_etiquette.dart';

class DatingEtiquetteModel extends DatingEtiquette {
  const DatingEtiquetteModel({
    required super.country,
    required super.sections,
    required super.lastUpdated,
  });

  factory DatingEtiquetteModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return DatingEtiquetteModel.fromJson({...data, 'country': doc.id});
  }

  factory DatingEtiquetteModel.fromJson(Map<String, dynamic> json) {
    return DatingEtiquetteModel(
      country: json['country'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => EtiquetteSectionModel.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: json['lastUpdated'] is Timestamp
          ? (json['lastUpdated'] as Timestamp).toDate()
          : DateTime.tryParse(json['lastUpdated']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'sections': sections
          .map((s) => s is EtiquetteSectionModel
              ? s.toJson()
              : EtiquetteSectionModel.fromEntity(s).toJson())
          .toList(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory DatingEtiquetteModel.fromEntity(DatingEtiquette entity) {
    return DatingEtiquetteModel(
      country: entity.country,
      sections: entity.sections,
      lastUpdated: entity.lastUpdated,
    );
  }
}

class EtiquetteSectionModel extends EtiquetteSection {
  const EtiquetteSectionModel({
    required super.title,
    required super.content,
    super.doList,
    super.dontList,
  });

  factory EtiquetteSectionModel.fromJson(Map<String, dynamic> json) {
    return EtiquetteSectionModel(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      doList: (json['doList'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      dontList: (json['dontList'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'doList': doList,
      'dontList': dontList,
    };
  }

  factory EtiquetteSectionModel.fromEntity(EtiquetteSection entity) {
    return EtiquetteSectionModel(
      title: entity.title,
      content: entity.content,
      doList: entity.doList,
      dontList: entity.dontList,
    );
  }
}
