/**
 * Seasonal Event Banner Widget
 * Point 200: Display active seasonal events with themed UI
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_seasonal_event.dart';
import '../bloc/gamification_bloc.dart';
import '../bloc/gamification_event.dart';
import '../bloc/gamification_state.dart';
import '../screens/seasonal_event_screen.dart';

class SeasonalEventBanner extends StatefulWidget {
  final String userId;

  const SeasonalEventBanner({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<SeasonalEventBanner> createState() => _SeasonalEventBannerState();
}

class _SeasonalEventBannerState extends State<SeasonalEventBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    // Load seasonal event
    context.read<GamificationBloc>().add(LoadSeasonalEvent(widget.userId));

    // Shimmer animation for banner
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GamificationBloc, GamificationState>(
      builder: (context, state) {
        if (state.seasonalEventData == null ||
            !state.seasonalEventData!.hasActiveEvent) {
          return const SizedBox.shrink();
        }

        final eventData = state.seasonalEventData!;
        final event = eventData.event!;

        return AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeasonalEventScreen(
                      userId: widget.userId,
                      event: event,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(eventData.primaryColor ??
                          Theme.of(context).primaryColor.value),
                      Color(eventData.accentColor ??
                              Theme.of(context).primaryColor.value)
                          .withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(eventData.primaryColor ??
                              Theme.of(context).primaryColor.value)
                          .withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    if (eventData.backgroundPattern != null)
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.1,
                          child: _buildBackgroundPattern(
                              eventData.backgroundPattern!),
                        ),
                      ),

                    // Content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Event icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getThemeIcon(eventData.iconSet ?? event.theme),
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Event info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    event.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Progress and time remaining
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Progress: ${eventData.completedChallenges}/${eventData.totalChallenges}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '${eventData.daysRemaining} days left',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: eventData.totalChallenges > 0
                                          ? eventData.completedChallenges /
                                              eventData.totalChallenges
                                          : 0,
                                      minHeight: 8,
                                      backgroundColor:
                                          Colors.white.withOpacity(0.3),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // View event button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Event',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(eventData.primaryColor ??
                                          Theme.of(context)
                                              .primaryColor
                                              .value),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: Color(eventData.primaryColor ??
                                        Theme.of(context).primaryColor.value),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBackgroundPattern(String pattern) {
    // Simple pattern rendering
    switch (pattern) {
      case 'hearts_pattern':
        return _buildHeartsPattern();
      case 'snowflakes':
        return _buildSnowflakesPattern();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHeartsPattern() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: 25,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return const Center(
          child: Text('❤️', style: TextStyle(fontSize: 24)),
        );
      },
    );
  }

  Widget _buildSnowflakesPattern() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: 25,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return const Center(
          child: Text('❄️', style: TextStyle(fontSize: 24)),
        );
      },
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
}
