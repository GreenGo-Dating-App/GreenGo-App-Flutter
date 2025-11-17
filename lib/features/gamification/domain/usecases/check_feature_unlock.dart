/**
 * Check Feature Unlock Use Case
 * Point 195: Check if level-gated features are unlocked
 */

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_level.dart';
import '../repositories/gamification_repository.dart';

class CheckFeatureUnlock implements UseCase<FeatureUnlockStatus, CheckFeatureUnlockParams> {
  final GamificationRepository repository;

  CheckFeatureUnlock(this.repository);

  @override
  Future<Either<Failure, FeatureUnlockStatus>> call(
    CheckFeatureUnlockParams params,
  ) async {
    // Get user's level
    final levelResult = await repository.getUserLevel(params.userId);

    if (levelResult.isLeft()) {
      return Left(levelResult.fold((l) => l, (r) => throw Exception()));
    }

    final userLevel = levelResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // Check if feature is unlocked
    final isUnlockedResult = await repository.isFeatureUnlocked(
      params.userId,
      params.featureId,
    );

    if (isUnlockedResult.isLeft()) {
      return Left(isUnlockedResult.fold((l) => l, (r) => throw Exception()));
    }

    final isUnlocked = isUnlockedResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // Get feature requirements
    final featureRequirement = _getFeatureRequirement(params.featureId);

    // Calculate progress
    int? levelsRemaining;
    if (!isUnlocked && featureRequirement != null) {
      levelsRemaining = featureRequirement.requiredLevel - userLevel.level;
    }

    return Right(FeatureUnlockStatus(
      featureId: params.featureId,
      isUnlocked: isUnlocked,
      userLevel: userLevel.level,
      requiredLevel: featureRequirement?.requiredLevel,
      levelsRemaining: levelsRemaining,
      featureName: featureRequirement?.featureName ?? params.featureId,
      description: featureRequirement?.description,
    ));
  }

  FeatureRequirement? _getFeatureRequirement(String featureId) {
    // Point 195: Level-gated features
    final requirements = {
      'custom_chat_themes': FeatureRequirement(
        featureId: 'custom_chat_themes',
        featureName: 'Custom Chat Themes',
        requiredLevel: 10,
        description: 'Customize your chat background with exclusive themes',
      ),
      'profile_video': FeatureRequirement(
        featureId: 'profile_video',
        featureName: 'Profile Video',
        requiredLevel: 25,
        description: 'Add a video introduction to your profile',
      ),
      'advanced_filters': FeatureRequirement(
        featureId: 'advanced_filters',
        featureName: 'Advanced Filters',
        requiredLevel: 15,
        description: 'Use advanced search filters to find better matches',
      ),
      'unlimited_rewinds': FeatureRequirement(
        featureId: 'unlimited_rewinds',
        featureName: 'Unlimited Rewinds',
        requiredLevel: 30,
        description: 'Undo as many swipes as you want',
      ),
      'vip_badge': FeatureRequirement(
        featureId: 'vip_badge',
        featureName: 'VIP Badge',
        requiredLevel: 50,
        description: 'Display your VIP status with a gold crown',
      ),
      'priority_likes': FeatureRequirement(
        featureId: 'priority_likes',
        featureName: 'Priority Likes',
        requiredLevel: 40,
        description: 'Your likes appear first in their queue',
      ),
    };

    return requirements[featureId];
  }
}

class CheckFeatureUnlockParams {
  final String userId;
  final String featureId;

  CheckFeatureUnlockParams({
    required this.userId,
    required this.featureId,
  });
}

class FeatureUnlockStatus {
  final String featureId;
  final bool isUnlocked;
  final int userLevel;
  final int? requiredLevel;
  final int? levelsRemaining;
  final String featureName;
  final String? description;

  FeatureUnlockStatus({
    required this.featureId,
    required this.isUnlocked,
    required this.userLevel,
    this.requiredLevel,
    this.levelsRemaining,
    required this.featureName,
    this.description,
  });
}

class FeatureRequirement {
  final String featureId;
  final String featureName;
  final int requiredLevel;
  final String description;

  FeatureRequirement({
    required this.featureId,
    required this.featureName,
    required this.requiredLevel,
    required this.description,
  });
}
