/**
 * Level Display Widget
 * Point 194: Display user level on profile cards
 */

import 'package:flutter/material.dart';
import '../../domain/entities/user_level.dart';

class LevelDisplayWidget extends StatelessWidget {
  final UserLevel userLevel;
  final bool showProgress;
  final bool showVIPBadge;
  final double size;

  const LevelDisplayWidget({
    Key? key,
    required this.userLevel,
    this.showProgress = false,
    this.showVIPBadge = true,
    this.size = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Level circle with progress ring
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                children: [
                  // Progress ring
                  if (showProgress)
                    CircularProgressIndicator(
                      value: userLevel.progressToNextLevel,
                      strokeWidth: 4,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        userLevel.isVIP
                            ? const Color(0xFFFFD700)
                            : Colors.blue,
                      ),
                    ),

                  // Level circle
                  Center(
                    child: Container(
                      width: size - 8,
                      height: size - 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: userLevel.isVIP
                              ? [
                                  const Color(0xFFFFD700),
                                  const Color(0xFFFFA500),
                                ]
                              : [
                                  Colors.blue.shade400,
                                  Colors.blue.shade600,
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: userLevel.isVIP
                                ? const Color(0xFFFFD700).withOpacity(0.5)
                                : Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${userLevel.level}',
                          style: TextStyle(
                            fontSize: size * 0.4,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // VIP crown badge (Point 193)
            if (showVIPBadge && userLevel.isVIP)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Text(
                    '👑',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),

        if (showProgress) ...[
          const SizedBox(height: 8),
          Text(
            '${userLevel.currentXP} / ${userLevel.xpForNextLevel} XP',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact level badge for use in lists
class LevelBadge extends StatelessWidget {
  final int level;
  final bool isVIP;
  final double size;

  const LevelBadge({
    Key? key,
    required this.level,
    this.isVIP = false,
    this.size = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isVIP
              ? [
                  const Color(0xFFFFD700),
                  const Color(0xFFFFA500),
                ]
              : [
                  Colors.blue.shade400,
                  Colors.blue.shade600,
                ],
        ),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '$level',
              style: TextStyle(
                fontSize: size * 0.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (isVIP)
            const Positioned(
              top: 0,
              right: 0,
              child: Text(
                '👑',
                style: TextStyle(fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}

/// XP Progress Bar
class XPProgressBar extends StatelessWidget {
  final UserLevel userLevel;
  final bool showLabel;

  const XPProgressBar({
    Key? key,
    required this.userLevel,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level ${userLevel.level}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: userLevel.isVIP
                      ? const Color(0xFFFFD700)
                      : Colors.blue.shade700,
                ),
              ),
              Text(
                '${userLevel.currentXP}/${userLevel.xpForNextLevel} XP',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        if (showLabel) const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: userLevel.progressToNextLevel,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              userLevel.isVIP
                  ? const Color(0xFFFFD700)
                  : Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}
