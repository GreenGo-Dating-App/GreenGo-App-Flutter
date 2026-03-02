import 'package:equatable/equatable.dart';

/// Safety Academy Module Entity
///
/// Represents a learning module in the Safety Academy.
/// Each module contains multiple lessons covering a specific safety topic.
class SafetyModule extends Equatable {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final List<String> lessons;
  final int order;
  final int xpReward;

  const SafetyModule({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.lessons,
    required this.order,
    required this.xpReward,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        iconName,
        lessons,
        order,
        xpReward,
      ];
}
