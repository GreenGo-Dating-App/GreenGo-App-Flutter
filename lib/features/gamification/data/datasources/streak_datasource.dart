import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/login_streak_model.dart';
import '../../domain/entities/login_streak.dart';

/// Streak Remote Data Source
abstract class StreakRemoteDataSource {
  /// Get user's login streak
  Future<LoginStreakModel?> getStreak(String oderId);

  /// Record daily login and update streak
  Future<LoginStreakModel> recordLogin(String oderId);

  /// Claim a streak milestone reward
  Future<void> claimMilestone(String oderId, String milestoneId);

  /// Get login streak stream for real-time updates
  Stream<LoginStreakModel?> watchStreak(String oderId);
}

/// Implementation of StreakRemoteDataSource
class StreakRemoteDataSourceImpl implements StreakRemoteDataSource {
  final FirebaseFirestore firestore;

  static const String _collection = 'login_streaks';

  StreakRemoteDataSourceImpl({required this.firestore});

  @override
  Future<LoginStreakModel?> getStreak(String oderId) async {
    final doc = await firestore.collection(_collection).doc(oderId).get();

    if (!doc.exists) return null;
    return LoginStreakModel.fromFirestore(doc);
  }

  @override
  Future<LoginStreakModel> recordLogin(String oderId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final docRef = firestore.collection(_collection).doc(oderId);
    final doc = await docRef.get();

    LoginStreakModel streak;

    if (!doc.exists) {
      // First login - create new streak
      streak = LoginStreakModel(
        userId: oderId,
        currentStreak: 1,
        longestStreak: 1,
        lastLoginDate: now,
        totalDaysLoggedIn: 1,
        claimedMilestones: const [],
        createdAt: now,
        updatedAt: now,
      );
    } else {
      final existingStreak = LoginStreakModel.fromFirestore(doc);

      // Check if already logged in today
      if (existingStreak.hasLoggedInToday) {
        return existingStreak;
      }

      // Check if streak continues (logged in yesterday)
      final lastLogin = existingStreak.lastLoginDate;
      int newStreak;

      if (lastLogin != null) {
        final lastLoginDay = DateTime(
          lastLogin.year,
          lastLogin.month,
          lastLogin.day,
        );
        final difference = today.difference(lastLoginDay).inDays;

        if (difference == 1) {
          // Continue streak
          newStreak = existingStreak.currentStreak + 1;
        } else {
          // Streak broken - start fresh
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }

      final newLongestStreak = newStreak > existingStreak.longestStreak
          ? newStreak
          : existingStreak.longestStreak;

      streak = LoginStreakModel(
        userId: oderId,
        currentStreak: newStreak,
        longestStreak: newLongestStreak,
        lastLoginDate: now,
        totalDaysLoggedIn: existingStreak.totalDaysLoggedIn + 1,
        claimedMilestones: existingStreak.claimedMilestones,
        createdAt: existingStreak.createdAt,
        updatedAt: now,
      );
    }

    await docRef.set(streak.toMap());
    return streak;
  }

  @override
  Future<void> claimMilestone(String oderId, String milestoneId) async {
    final milestone = StreakMilestones.getById(milestoneId);
    if (milestone == null) {
      throw Exception('Milestone not found: $milestoneId');
    }

    final docRef = firestore.collection(_collection).doc(oderId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Streak not found for user: $oderId');
    }

    final streak = LoginStreakModel.fromFirestore(doc);

    // Check if milestone is already claimed
    if (streak.claimedMilestones.any((m) => m.id == milestoneId)) {
      throw Exception('Milestone already claimed: $milestoneId');
    }

    // Check if user has achieved this milestone
    if (streak.currentStreak < milestone.daysRequired) {
      throw Exception('Milestone not yet achieved. '
          'Required: ${milestone.daysRequired} days, '
          'Current: ${streak.currentStreak} days');
    }

    // Add milestone to claimed list
    final updatedMilestones = [...streak.claimedMilestones, milestone];

    await docRef.update({
      'claimedMilestones': updatedMilestones
          .map((m) => StreakMilestoneModel.toMap(m))
          .toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Stream<LoginStreakModel?> watchStreak(String oderId) {
    return firestore
        .collection(_collection)
        .doc(oderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return LoginStreakModel.fromFirestore(doc);
    });
  }
}
