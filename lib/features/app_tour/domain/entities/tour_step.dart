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
      id: 'matches',
      titleKey: 'tourMatchesTitle',
      descriptionKey: 'tourMatchesDescription',
      icon: Icons.favorite,
      tabIndex: 1,
      accentColor: Colors.red,
    ),
    TourStep(
      id: 'messages',
      titleKey: 'tourMessagesTitle',
      descriptionKey: 'tourMessagesDescription',
      icon: Icons.chat_bubble,
      tabIndex: 2,
      accentColor: Colors.blue,
    ),
    TourStep(
      id: 'shop',
      titleKey: 'tourShopTitle',
      descriptionKey: 'tourShopDescription',
      icon: Icons.store,
      tabIndex: 3,
      accentColor: Colors.green,
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
