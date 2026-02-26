import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/tier_config.dart';
import '../../../membership/domain/entities/membership.dart';

/// Tier Config Model for Firestore serialization
class TierConfigModel extends TierConfig {
  const TierConfigModel({
    required super.configId,
    required super.tier,
    required super.rules,
    super.updatedBy,
    required super.updatedAt,
    required super.createdAt,
    super.isActive,
  });

  /// Create from Firestore document
  factory TierConfigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TierConfigModel.fromMap(data, doc.id);
  }

  /// Create from Map
  factory TierConfigModel.fromMap(Map<String, dynamic> map, String id) {
    return TierConfigModel(
      configId: id,
      tier: MembershipTier.fromString(map['tier'] ?? 'FREE'),
      rules: MembershipRulesModel.fromMap(
        map['rules'] as Map<String, dynamic>? ?? {},
      ),
      updatedBy: map['updatedBy'] as String?,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  /// Create from entity
  factory TierConfigModel.fromEntity(TierConfig entity) {
    return TierConfigModel(
      configId: entity.configId,
      tier: entity.tier,
      rules: entity.rules,
      updatedBy: entity.updatedBy,
      updatedAt: entity.updatedAt,
      createdAt: entity.createdAt,
      isActive: entity.isActive,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'tier': tier.value,
      'rules': MembershipRulesModel.toMap(rules),
      'updatedBy': updatedBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  /// Convert to entity
  TierConfig toEntity() {
    return TierConfig(
      configId: configId,
      tier: tier,
      rules: rules,
      updatedBy: updatedBy,
      updatedAt: updatedAt,
      createdAt: createdAt,
      isActive: isActive,
    );
  }
}

/// Membership Rules Model for serialization
class MembershipRulesModel {
  /// Create MembershipRules from Map
  static MembershipRules fromMap(Map<String, dynamic> map) {
    return MembershipRules(
      dailyMessageLimit: map['dailyMessageLimit'] as int? ?? 10,
      dailySwipeLimit: map['dailySwipeLimit'] as int? ?? 20,
      dailySuperLikeLimit: map['dailySuperLikeLimit'] as int? ?? 0,
      canUseAdvancedFilters: map['canUseAdvancedFilters'] as bool? ?? false,
      canFilterByLocation: map['canFilterByLocation'] as bool? ?? false,
      canFilterByInterests: map['canFilterByInterests'] as bool? ?? false,
      canFilterByLanguage: map['canFilterByLanguage'] as bool? ?? false,
      canFilterByVerification: map['canFilterByVerification'] as bool? ?? false,
      canSendMedia: map['canSendMedia'] as bool? ?? false,
      canSeeReadReceipts: map['canSeeReadReceipts'] as bool? ?? false,
      canUseIncognitoMode: map['canUseIncognitoMode'] as bool? ?? false,
      matchPriority: map['matchPriority'] as int? ?? 0,
      canSeeProfileVisitors: map['canSeeProfileVisitors'] as bool? ?? false,
      canUseVideoChat: map['canUseVideoChat'] as bool? ?? false,
      badgeIcon: map['badgeIcon'] as String?,
    );
  }

  /// Convert MembershipRules to Map
  static Map<String, dynamic> toMap(MembershipRules rules) {
    return {
      'dailyMessageLimit': rules.dailyMessageLimit,
      'dailySwipeLimit': rules.dailySwipeLimit,
      'dailySuperLikeLimit': rules.dailySuperLikeLimit,
      'canUseAdvancedFilters': rules.canUseAdvancedFilters,
      'canFilterByLocation': rules.canFilterByLocation,
      'canFilterByInterests': rules.canFilterByInterests,
      'canFilterByLanguage': rules.canFilterByLanguage,
      'canFilterByVerification': rules.canFilterByVerification,
      'canSendMedia': rules.canSendMedia,
      'canSeeReadReceipts': rules.canSeeReadReceipts,
      'canUseIncognitoMode': rules.canUseIncognitoMode,
      'matchPriority': rules.matchPriority,
      'canSeeProfileVisitors': rules.canSeeProfileVisitors,
      'canUseVideoChat': rules.canUseVideoChat,
      'badgeIcon': rules.badgeIcon,
    };
  }
}

/// Tier Reward Config Model
class TierRewardConfigModel extends TierRewardConfig {
  const TierRewardConfigModel({
    required super.tier,
    super.monthlyCoins,
    super.dailyLoginCoins,
    super.dailyLoginXP,
    super.xpMultiplier,
    super.referralBonus,
  });

  factory TierRewardConfigModel.fromMap(Map<String, dynamic> map) {
    return TierRewardConfigModel(
      tier: MembershipTier.fromString(map['tier'] ?? 'FREE'),
      monthlyCoins: map['monthlyCoins'] as int? ?? 0,
      dailyLoginCoins: map['dailyLoginCoins'] as int? ?? 10,
      dailyLoginXP: map['dailyLoginXP'] as int? ?? 5,
      xpMultiplier: (map['xpMultiplier'] as num?)?.toDouble() ?? 1.0,
      referralBonus: map['referralBonus'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tier': tier.value,
      'monthlyCoins': monthlyCoins,
      'dailyLoginCoins': dailyLoginCoins,
      'dailyLoginXP': dailyLoginXP,
      'xpMultiplier': xpMultiplier,
      'referralBonus': referralBonus,
    };
  }
}
