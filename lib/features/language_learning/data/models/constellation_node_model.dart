import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/constellation_node.dart';

class ConstellationNodeModel extends ConstellationNode {
  const ConstellationNodeModel({
    required super.id,
    required super.languageSource,
    required super.languageTarget,
    required super.unit,
    required super.nodeIndex,
    required super.unitTitle,
    required super.nodeType,
    required super.nodeTitle,
    super.xp,
    super.coinCost,
  });

  factory ConstellationNodeModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ConstellationNodeModel(
      id: doc.id,
      languageSource: d['languageSource'] as String? ?? '',
      languageTarget: d['languageTarget'] as String? ?? '',
      unit: d['unit'] as int? ?? 1,
      nodeIndex: d['nodeIndex'] as int? ?? 1,
      unitTitle: d['unitTitle'] as String? ?? '',
      nodeType: d['nodeType'] as String? ?? 'ClassicLesson',
      nodeTitle: d['nodeTitle'] as String? ?? '',
      xp: d['xp'] as int? ?? 15,
      coinCost: d['coinCost'] as int? ?? 0,
    );
  }

  factory ConstellationNodeModel.fromJson(Map<String, dynamic> json) {
    return ConstellationNodeModel(
      id: json['id'] as String? ?? '',
      languageSource: json['languageSource'] as String? ?? '',
      languageTarget: json['languageTarget'] as String? ?? '',
      unit: json['unit'] as int? ?? 1,
      nodeIndex: json['nodeIndex'] as int? ?? 1,
      unitTitle: json['unitTitle'] as String? ?? '',
      nodeType: json['nodeType'] as String? ?? 'ClassicLesson',
      nodeTitle: json['nodeTitle'] as String? ?? '',
      xp: json['xp'] as int? ?? 15,
      coinCost: json['coinCost'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'languageSource': languageSource,
      'languageTarget': languageTarget,
      'unit': unit,
      'nodeIndex': nodeIndex,
      'unitTitle': unitTitle,
      'nodeType': nodeType,
      'nodeTitle': nodeTitle,
      'xp': xp,
      'coinCost': coinCost,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'languageSource': languageSource,
      'languageTarget': languageTarget,
      'unit': unit,
      'nodeIndex': nodeIndex,
      'unitTitle': unitTitle,
      'nodeType': nodeType,
      'nodeTitle': nodeTitle,
      'xp': xp,
      'coinCost': coinCost,
    };
  }
}
