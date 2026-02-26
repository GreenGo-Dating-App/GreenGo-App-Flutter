import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/membership.dart';

/// Membership Rules Model
/// Firestore serialization for MembershipRules
class MembershipRulesModel extends MembershipRules {
  const MembershipRulesModel({
    super.dailyMessageLimit,
    super.dailySwipeLimit,
    super.dailySuperLikeLimit,
    super.hourlyLikeLimit,
    super.hourlyNopeLimit,
    super.hourlySuperLikeLimit,
    super.canUseAdvancedFilters,
    super.canFilterByLocation,
    super.canFilterByInterests,
    super.canFilterByLanguage,
    super.canFilterByVerification,
    super.canSendMedia,
    super.canSeeReadReceipts,
    super.canUseIncognitoMode,
    super.matchPriority,
    super.canSeeProfileVisitors,
    super.canUseVideoChat,
    super.badgeIcon,
  });

  factory MembershipRulesModel.fromJson(Map<String, dynamic> json) {
    return MembershipRulesModel(
      dailyMessageLimit: json['dailyMessageLimit'] as int? ?? 10,
      dailySwipeLimit: json['dailySwipeLimit'] as int? ?? 20,
      dailySuperLikeLimit: json['dailySuperLikeLimit'] as int? ?? 0,
      hourlyLikeLimit: json['hourlyLikeLimit'] as int? ?? 5,
      hourlyNopeLimit: json['hourlyNopeLimit'] as int? ?? 10,
      hourlySuperLikeLimit: json['hourlySuperLikeLimit'] as int? ?? 0,
      canUseAdvancedFilters: json['canUseAdvancedFilters'] as bool? ?? false,
      canFilterByLocation: json['canFilterByLocation'] as bool? ?? false,
      canFilterByInterests: json['canFilterByInterests'] as bool? ?? false,
      canFilterByLanguage: json['canFilterByLanguage'] as bool? ?? false,
      canFilterByVerification: json['canFilterByVerification'] as bool? ?? false,
      canSendMedia: json['canSendMedia'] as bool? ?? false,
      canSeeReadReceipts: json['canSeeReadReceipts'] as bool? ?? false,
      canUseIncognitoMode: json['canUseIncognitoMode'] as bool? ?? false,
      matchPriority: json['matchPriority'] as int? ?? 0,
      canSeeProfileVisitors: json['canSeeProfileVisitors'] as bool? ?? false,
      canUseVideoChat: json['canUseVideoChat'] as bool? ?? false,
      badgeIcon: json['badgeIcon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyMessageLimit': dailyMessageLimit,
      'dailySwipeLimit': dailySwipeLimit,
      'dailySuperLikeLimit': dailySuperLikeLimit,
      'hourlyLikeLimit': hourlyLikeLimit,
      'hourlyNopeLimit': hourlyNopeLimit,
      'hourlySuperLikeLimit': hourlySuperLikeLimit,
      'canUseAdvancedFilters': canUseAdvancedFilters,
      'canFilterByLocation': canFilterByLocation,
      'canFilterByInterests': canFilterByInterests,
      'canFilterByLanguage': canFilterByLanguage,
      'canFilterByVerification': canFilterByVerification,
      'canSendMedia': canSendMedia,
      'canSeeReadReceipts': canSeeReadReceipts,
      'canUseIncognitoMode': canUseIncognitoMode,
      'matchPriority': matchPriority,
      'canSeeProfileVisitors': canSeeProfileVisitors,
      'canUseVideoChat': canUseVideoChat,
      'badgeIcon': badgeIcon,
    };
  }

  factory MembershipRulesModel.fromEntity(MembershipRules rules) {
    return MembershipRulesModel(
      dailyMessageLimit: rules.dailyMessageLimit,
      dailySwipeLimit: rules.dailySwipeLimit,
      dailySuperLikeLimit: rules.dailySuperLikeLimit,
      hourlyLikeLimit: rules.hourlyLikeLimit,
      hourlyNopeLimit: rules.hourlyNopeLimit,
      hourlySuperLikeLimit: rules.hourlySuperLikeLimit,
      canUseAdvancedFilters: rules.canUseAdvancedFilters,
      canFilterByLocation: rules.canFilterByLocation,
      canFilterByInterests: rules.canFilterByInterests,
      canFilterByLanguage: rules.canFilterByLanguage,
      canFilterByVerification: rules.canFilterByVerification,
      canSendMedia: rules.canSendMedia,
      canSeeReadReceipts: rules.canSeeReadReceipts,
      canUseIncognitoMode: rules.canUseIncognitoMode,
      matchPriority: rules.matchPriority,
      canSeeProfileVisitors: rules.canSeeProfileVisitors,
      canUseVideoChat: rules.canUseVideoChat,
      badgeIcon: rules.badgeIcon,
    );
  }
}

/// Membership Model
/// Firestore serialization for Membership
class MembershipModel extends Membership {
  const MembershipModel({
    required super.membershipId,
    required super.userId,
    required super.tier,
    super.couponCode,
    required super.startDate,
    super.endDate,
    super.customRules,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.activatedBy,
  });

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    return MembershipModel(
      membershipId: json['membershipId'] as String,
      userId: json['userId'] as String,
      tier: MembershipTier.fromString(json['tier'] as String),
      couponCode: json['couponCode'] as String?,
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: json['endDate'] != null
          ? (json['endDate'] as Timestamp).toDate()
          : null,
      customRules: json['customRules'] != null
          ? MembershipRulesModel.fromJson(
              json['customRules'] as Map<String, dynamic>)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      activatedBy: json['activatedBy'] as String?,
    );
  }

  factory MembershipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MembershipModel.fromJson({...data, 'membershipId': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'membershipId': membershipId,
      'userId': userId,
      'tier': tier.value,
      'couponCode': couponCode,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'customRules': customRules != null
          ? MembershipRulesModel.fromEntity(customRules!).toJson()
          : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'activatedBy': activatedBy,
    };
  }

  factory MembershipModel.fromEntity(Membership membership) {
    return MembershipModel(
      membershipId: membership.membershipId,
      userId: membership.userId,
      tier: membership.tier,
      couponCode: membership.couponCode,
      startDate: membership.startDate,
      endDate: membership.endDate,
      customRules: membership.customRules,
      isActive: membership.isActive,
      createdAt: membership.createdAt,
      updatedAt: membership.updatedAt,
      activatedBy: membership.activatedBy,
    );
  }

  /// Create a new FREE membership for a user
  factory MembershipModel.createFreeMembership(String userId) {
    final now = DateTime.now();
    return MembershipModel(
      membershipId: '',
      userId: userId,
      tier: MembershipTier.free,
      startDate: now,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }
}
