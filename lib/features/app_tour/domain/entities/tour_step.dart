import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Represents a step in the app tour
class TourStep {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final int tabIndex;
  final Color accentColor;

  const TourStep({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.tabIndex,
    this.accentColor = AppColors.gold,
  });

  /// All tour steps for the app
  /// Tab order: Exchange(0), Messages(1), Learn(2), Play(3), Profile(4)
  static const List<TourStep> allSteps = [
    TourStep(
      id: 'discovery',
      titleKey: 'tourDiscoveryTitle',
      descriptionKey: 'tourDiscoveryDescription',
      icon: Icons.explore,
      tabIndex: 0,
      accentColor: Colors.pink,
    ),
    TourStep(
      id: 'messages',
      titleKey: 'tourMessagesTitle',
      descriptionKey: 'tourMessagesDescription',
      icon: Icons.chat_bubble,
      tabIndex: 1,
      accentColor: Colors.blue,
    ),
    TourStep(
      id: 'learn',
      titleKey: 'tourLearnTitle',
      descriptionKey: 'tourLearnDescription',
      icon: Icons.school,
      tabIndex: 2,
      accentColor: Colors.green,
    ),
    TourStep(
      id: 'play',
      titleKey: 'tourPlayTitle',
      descriptionKey: 'tourPlayDescription',
      icon: Icons.sports_esports,
      tabIndex: 3,
      accentColor: Colors.orange,
    ),
    TourStep(
      id: 'profile',
      titleKey: 'tourProfileTitle',
      descriptionKey: 'tourProfileDescription',
      icon: Icons.person,
      tabIndex: 4,
      accentColor: Colors.purple,
    ),
  ];
}
