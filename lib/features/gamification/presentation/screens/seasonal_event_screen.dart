/**
 * Seasonal Event Screen
 * Point 200: Full seasonal event details with themed challenges
 */

import 'package:flutter/material.dart';
import '../../domain/entities/daily_challenge.dart';
import '../widgets/challenge_card.dart';

class SeasonalEventScreen extends StatelessWidget {
  final String userId;
  final SeasonalEvent event;

  const SeasonalEventScreen({
    Key? key,
    required this.userId,
    required this.event,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(event.themeConfig['primaryColor'] as int? ??
        Theme.of(context).primaryColor.value);
    final accentColor = Color(event.themeConfig['accentColor'] as int? ??
        Theme.of(context).primaryColor.value);

    return Theme(
      // Apply seasonal theme
      data: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          secondary: accentColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(event.name),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event header
              _buildEventHeader(context, primaryColor, accentColor),

              // Event description
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  event.description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),

              // Event challenges
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'Event Challenges',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),

              // Challenges list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: event.challenges.length,
                itemBuilder: (context, index) {
                  final challenge = event.challenges[index];
                  return ChallengeCard(
                    challenge: challenge,
                    progress: null, // Would need to load progress
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventHeader(
    BuildContext context,
    Color primaryColor,
    Color accentColor,
  ) {
    final now = DateTime.now();
    final daysRemaining = event.endDate.difference(now).inDays;
    final hoursRemaining = event.endDate.difference(now).inHours % 24;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, accentColor],
        ),
      ),
      child: Column(
        children: [
          // Event icon
          Text(
            _getThemeIcon(event.theme),
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 16),

          // Event dates
          Text(
            '${_formatDate(event.startDate)} - ${_formatDate(event.endDate)}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Time remaining
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$daysRemaining days, $hoursRemaining hours remaining',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeIcon(String theme) {
    switch (theme) {
      case 'valentine':
        return '💝';
      case 'summer':
        return '☀️';
      case 'holiday':
        return '🎄';
      case 'halloween':
        return '🎃';
      case 'spring':
        return '🌸';
      default:
        return '🎉';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
