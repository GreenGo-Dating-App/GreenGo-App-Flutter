import 'dart:math';
import 'package:equatable/equatable.dart';

/// Lucky Wheel Entity - Daily spin for rewards
class LuckyWheel extends Equatable {
  final String wheelId;
  final String name;
  final List<WheelSegment> segments;
  final int freeSpinsPerDay;
  final int premiumSpinsPerDay;
  final int coinCostPerSpin;
  final bool isActive;

  const LuckyWheel({
    required this.wheelId,
    required this.name,
    required this.segments,
    this.freeSpinsPerDay = 1,
    this.premiumSpinsPerDay = 3,
    this.coinCostPerSpin = 50,
    this.isActive = true,
  });

  /// Spin the wheel and get result
  WheelSegment spin() {
    final random = Random();
    double totalWeight = segments.fold(0, (sum, s) => sum + s.weight);
    double randomValue = random.nextDouble() * totalWeight;

    double cumulativeWeight = 0;
    for (final segment in segments) {
      cumulativeWeight += segment.weight;
      if (randomValue <= cumulativeWeight) {
        return segment;
      }
    }
    return segments.last;
  }

  @override
  List<Object?> get props => [
        wheelId,
        name,
        segments,
        freeSpinsPerDay,
        premiumSpinsPerDay,
        coinCostPerSpin,
        isActive,
      ];
}

/// Wheel Segment - One slice of the wheel
class WheelSegment extends Equatable {
  final String segmentId;
  final String name;
  final String rewardType; // coins, xp, boost, super_like, premium_day, badge, nothing
  final int rewardAmount;
  final String? itemId;
  final double weight; // Probability weight (higher = more likely)
  final int colorValue;
  final String iconName;

  const WheelSegment({
    required this.segmentId,
    required this.name,
    required this.rewardType,
    required this.rewardAmount,
    this.itemId,
    required this.weight,
    required this.colorValue,
    required this.iconName,
  });

  bool get isJackpot => rewardType == 'jackpot';
  bool get isEmpty => rewardType == 'nothing';

  @override
  List<Object?> get props => [
        segmentId,
        name,
        rewardType,
        rewardAmount,
        itemId,
        weight,
        colorValue,
        iconName,
      ];
}

/// User Wheel Spin - Record of a spin
class UserWheelSpin extends Equatable {
  final String spinId;
  final String odId;
  final String wheelId;
  final WheelSegment result;
  final DateTime spunAt;
  final bool wasFree;
  final int? coinsCost;

  const UserWheelSpin({
    required this.spinId,
    required this.odId,
    required this.wheelId,
    required this.result,
    required this.spunAt,
    this.wasFree = true,
    this.coinsCost,
  });

  @override
  List<Object?> get props => [
        spinId,
        odId,
        wheelId,
        result,
        spunAt,
        wasFree,
        coinsCost,
      ];
}

/// User Wheel State - Daily spin tracking
class UserWheelState extends Equatable {
  final String odId;
  final int freeSpinsRemaining;
  final int paidSpinsToday;
  final DateTime lastSpinDate;
  final DateTime? nextFreeSpinAt;
  final int totalLifetimeSpins;
  final int jackpotsWon;

  const UserWheelState({
    required this.odId,
    required this.freeSpinsRemaining,
    this.paidSpinsToday = 0,
    required this.lastSpinDate,
    this.nextFreeSpinAt,
    this.totalLifetimeSpins = 0,
    this.jackpotsWon = 0,
  });

  bool get canSpinFree => freeSpinsRemaining > 0;

  @override
  List<Object?> get props => [
        odId,
        freeSpinsRemaining,
        paidSpinsToday,
        lastSpinDate,
        nextFreeSpinAt,
        totalLifetimeSpins,
        jackpotsWon,
      ];
}

/// Default Lucky Wheel
class DefaultLuckyWheel {
  static LuckyWheel get standard => const LuckyWheel(
        wheelId: 'daily_wheel',
        name: 'Daily Lucky Wheel',
        segments: [
          // Common rewards (high weight)
          WheelSegment(
            segmentId: 'coins_10',
            name: '10 Coins',
            rewardType: 'coins',
            rewardAmount: 10,
            weight: 25.0,
            colorValue: 0xFFFFC107, // Amber
            iconName: 'monetization_on',
          ),
          WheelSegment(
            segmentId: 'xp_25',
            name: '25 XP',
            rewardType: 'xp',
            rewardAmount: 25,
            weight: 25.0,
            colorValue: 0xFF4CAF50, // Green
            iconName: 'stars',
          ),
          WheelSegment(
            segmentId: 'coins_25',
            name: '25 Coins',
            rewardType: 'coins',
            rewardAmount: 25,
            weight: 15.0,
            colorValue: 0xFFFF9800, // Orange
            iconName: 'monetization_on',
          ),
          WheelSegment(
            segmentId: 'xp_50',
            name: '50 XP',
            rewardType: 'xp',
            rewardAmount: 50,
            weight: 12.0,
            colorValue: 0xFF8BC34A, // Light Green
            iconName: 'stars',
          ),
          // Uncommon rewards (medium weight)
          WheelSegment(
            segmentId: 'coins_50',
            name: '50 Coins',
            rewardType: 'coins',
            rewardAmount: 50,
            weight: 8.0,
            colorValue: 0xFF2196F3, // Blue
            iconName: 'monetization_on',
          ),
          WheelSegment(
            segmentId: 'super_like_1',
            name: '1 Super Like',
            rewardType: 'super_like',
            rewardAmount: 1,
            weight: 6.0,
            colorValue: 0xFF00BCD4, // Cyan
            iconName: 'favorite',
          ),
          // Rare rewards (low weight)
          WheelSegment(
            segmentId: 'boost_1',
            name: '1 Boost',
            rewardType: 'boost',
            rewardAmount: 1,
            weight: 4.0,
            colorValue: 0xFF9C27B0, // Purple
            iconName: 'bolt',
          ),
          WheelSegment(
            segmentId: 'coins_100',
            name: '100 Coins',
            rewardType: 'coins',
            rewardAmount: 100,
            weight: 3.0,
            colorValue: 0xFFE91E63, // Pink
            iconName: 'monetization_on',
          ),
          // Epic rewards (very low weight)
          WheelSegment(
            segmentId: 'premium_day',
            name: '1 Day Premium',
            rewardType: 'premium_day',
            rewardAmount: 1,
            weight: 1.5,
            colorValue: 0xFFFFD700, // Gold
            iconName: 'workspace_premium',
          ),
          // Jackpot (extremely rare)
          WheelSegment(
            segmentId: 'jackpot',
            name: 'JACKPOT!',
            rewardType: 'jackpot',
            rewardAmount: 500,
            weight: 0.5,
            colorValue: 0xFFFF4500, // Orange-Red
            iconName: 'casino',
          ),
        ],
      );

  /// Premium wheel with better odds
  static LuckyWheel get premium => const LuckyWheel(
        wheelId: 'premium_wheel',
        name: 'Premium Lucky Wheel',
        freeSpinsPerDay: 0,
        premiumSpinsPerDay: 5,
        coinCostPerSpin: 0,
        segments: [
          WheelSegment(
            segmentId: 'p_coins_50',
            name: '50 Coins',
            rewardType: 'coins',
            rewardAmount: 50,
            weight: 20.0,
            colorValue: 0xFFFFC107,
            iconName: 'monetization_on',
          ),
          WheelSegment(
            segmentId: 'p_xp_75',
            name: '75 XP',
            rewardType: 'xp',
            rewardAmount: 75,
            weight: 20.0,
            colorValue: 0xFF4CAF50,
            iconName: 'stars',
          ),
          WheelSegment(
            segmentId: 'p_coins_100',
            name: '100 Coins',
            rewardType: 'coins',
            rewardAmount: 100,
            weight: 15.0,
            colorValue: 0xFF2196F3,
            iconName: 'monetization_on',
          ),
          WheelSegment(
            segmentId: 'p_super_like_3',
            name: '3 Super Likes',
            rewardType: 'super_like',
            rewardAmount: 3,
            weight: 12.0,
            colorValue: 0xFF00BCD4,
            iconName: 'favorite',
          ),
          WheelSegment(
            segmentId: 'p_boost_2',
            name: '2 Boosts',
            rewardType: 'boost',
            rewardAmount: 2,
            weight: 10.0,
            colorValue: 0xFF9C27B0,
            iconName: 'bolt',
          ),
          WheelSegment(
            segmentId: 'p_coins_250',
            name: '250 Coins',
            rewardType: 'coins',
            rewardAmount: 250,
            weight: 8.0,
            colorValue: 0xFFE91E63,
            iconName: 'monetization_on',
          ),
          WheelSegment(
            segmentId: 'p_premium_3',
            name: '3 Days Premium',
            rewardType: 'premium_day',
            rewardAmount: 3,
            weight: 5.0,
            colorValue: 0xFFFFD700,
            iconName: 'workspace_premium',
          ),
          WheelSegment(
            segmentId: 'p_jackpot',
            name: 'MEGA JACKPOT!',
            rewardType: 'jackpot',
            rewardAmount: 2000,
            weight: 2.0,
            colorValue: 0xFFFF4500,
            iconName: 'casino',
          ),
        ],
      );
}
