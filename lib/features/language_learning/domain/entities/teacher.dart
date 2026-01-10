import 'package:equatable/equatable.dart';

/// Teacher entity - users who can create and manage lessons
class Teacher extends Equatable {
  final String id;
  final String odUserId; // Link to main user account
  final String email;
  final String displayName;
  final String? profilePhotoUrl;
  final String bio;
  final List<String> teachingLanguages; // Language codes they can teach
  final List<String> nativeLanguages; // Their native language codes
  final TeacherStatus status;
  final TeacherTier tier;
  final List<TeacherCertification> certifications;
  final TeacherStats stats;
  final TeacherPaymentInfo? paymentInfo;
  final DateTime applicationDate;
  final DateTime? approvalDate;
  final String? approvedBy; // Admin who approved
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  const Teacher({
    required this.id,
    required this.odUserId,
    required this.email,
    required this.displayName,
    this.profilePhotoUrl,
    required this.bio,
    required this.teachingLanguages,
    required this.nativeLanguages,
    required this.status,
    required this.tier,
    this.certifications = const [],
    required this.stats,
    this.paymentInfo,
    required this.applicationDate,
    this.approvalDate,
    this.approvedBy,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.metadata,
  });

  bool get isApproved => status == TeacherStatus.approved;
  bool get canCreateLessons => isApproved && isActive;

  /// Revenue share percentage based on tier
  double get revenueSharePercent {
    switch (tier) {
      case TeacherTier.starter:
        return 0.50; // 50%
      case TeacherTier.professional:
        return 0.60; // 60%
      case TeacherTier.expert:
        return 0.70; // 70%
      case TeacherTier.master:
        return 0.80; // 80%
    }
  }

  @override
  List<Object?> get props => [
        id,
        odUserId,
        email,
        displayName,
        status,
        tier,
        teachingLanguages,
        isActive,
      ];
}

/// Teacher approval status
enum TeacherStatus {
  pending,
  under_review,
  approved,
  rejected,
  suspended;

  String get displayName {
    switch (this) {
      case TeacherStatus.pending:
        return 'Pending Review';
      case TeacherStatus.under_review:
        return 'Under Review';
      case TeacherStatus.approved:
        return 'Approved';
      case TeacherStatus.rejected:
        return 'Rejected';
      case TeacherStatus.suspended:
        return 'Suspended';
    }
  }

  String get color {
    switch (this) {
      case TeacherStatus.pending:
        return '#FFA500'; // Orange
      case TeacherStatus.under_review:
        return '#3B82F6'; // Blue
      case TeacherStatus.approved:
        return '#10B981'; // Green
      case TeacherStatus.rejected:
        return '#DC2626'; // Red
      case TeacherStatus.suspended:
        return '#6B7280'; // Gray
    }
  }
}

/// Teacher tier levels with different benefits
enum TeacherTier {
  starter,
  professional,
  expert,
  master;

  String get displayName {
    switch (this) {
      case TeacherTier.starter:
        return 'Starter';
      case TeacherTier.professional:
        return 'Professional';
      case TeacherTier.expert:
        return 'Expert';
      case TeacherTier.master:
        return 'Master';
    }
  }

  String get emoji {
    switch (this) {
      case TeacherTier.starter:
        return '🌟';
      case TeacherTier.professional:
        return '⭐';
      case TeacherTier.expert:
        return '💫';
      case TeacherTier.master:
        return '👑';
    }
  }

  /// Requirements to reach this tier
  Map<String, int> get requirements {
    switch (this) {
      case TeacherTier.starter:
        return {'lessons': 0, 'students': 0, 'rating': 0};
      case TeacherTier.professional:
        return {'lessons': 10, 'students': 50, 'rating': 4};
      case TeacherTier.expert:
        return {'lessons': 50, 'students': 500, 'rating': 45};
      case TeacherTier.master:
        return {'lessons': 100, 'students': 2000, 'rating': 48};
    }
  }

  /// Maximum lessons allowed at this tier
  int get maxLessonsPerMonth {
    switch (this) {
      case TeacherTier.starter:
        return 10;
      case TeacherTier.professional:
        return 30;
      case TeacherTier.expert:
        return 100;
      case TeacherTier.master:
        return -1; // Unlimited
    }
  }
}

/// Teacher certification/credential
class TeacherCertification extends Equatable {
  final String id;
  final String name;
  final String issuingOrganization;
  final String? certificateUrl;
  final DateTime? issuedDate;
  final DateTime? expiryDate;
  final bool isVerified;
  final String? verifiedBy;
  final DateTime? verifiedAt;

  const TeacherCertification({
    required this.id,
    required this.name,
    required this.issuingOrganization,
    this.certificateUrl,
    this.issuedDate,
    this.expiryDate,
    this.isVerified = false,
    this.verifiedBy,
    this.verifiedAt,
  });

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  @override
  List<Object?> get props => [id, name, issuingOrganization, isVerified];
}

/// Teacher performance statistics
class TeacherStats extends Equatable {
  final int totalLessons;
  final int publishedLessons;
  final int totalStudents;
  final int activeStudents;
  final double averageRating;
  final int totalRatings;
  final int totalCompletions;
  final int totalCoinsEarned;
  final int totalXpAwarded;
  final Map<String, int> lessonsByLanguage;
  final Map<String, double> ratingsByLanguage;
  final DateTime? lastLessonCreated;
  final int lessonsThisMonth;

  const TeacherStats({
    this.totalLessons = 0,
    this.publishedLessons = 0,
    this.totalStudents = 0,
    this.activeStudents = 0,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalCompletions = 0,
    this.totalCoinsEarned = 0,
    this.totalXpAwarded = 0,
    this.lessonsByLanguage = const {},
    this.ratingsByLanguage = const {},
    this.lastLessonCreated,
    this.lessonsThisMonth = 0,
  });

  @override
  List<Object?> get props => [
        totalLessons,
        publishedLessons,
        totalStudents,
        averageRating,
        totalCoinsEarned,
      ];
}

/// Teacher payment/payout information
class TeacherPaymentInfo extends Equatable {
  final String? paypalEmail;
  final String? stripeAccountId;
  final String? bankAccountNumber;
  final String? bankRoutingNumber;
  final String? bankName;
  final String? accountHolderName;
  final String preferredPaymentMethod;
  final String? taxId;
  final String? country;
  final double pendingBalance;
  final double totalEarnings;
  final DateTime? lastPayoutDate;
  final double lastPayoutAmount;

  const TeacherPaymentInfo({
    this.paypalEmail,
    this.stripeAccountId,
    this.bankAccountNumber,
    this.bankRoutingNumber,
    this.bankName,
    this.accountHolderName,
    this.preferredPaymentMethod = 'paypal',
    this.taxId,
    this.country,
    this.pendingBalance = 0.0,
    this.totalEarnings = 0.0,
    this.lastPayoutDate,
    this.lastPayoutAmount = 0.0,
  });

  bool get hasPaymentMethod =>
      paypalEmail != null ||
      stripeAccountId != null ||
      bankAccountNumber != null;

  @override
  List<Object?> get props => [
        paypalEmail,
        stripeAccountId,
        preferredPaymentMethod,
        pendingBalance,
        totalEarnings,
      ];
}

/// Teacher application for becoming a teacher
class TeacherApplication extends Equatable {
  final String id;
  final String odUserId;
  final String email;
  final String fullName;
  final String bio;
  final List<String> teachingLanguages;
  final List<String> nativeLanguages;
  final String teachingExperience; // Description
  final int yearsExperience;
  final List<String> certificationUrls;
  final String? portfolioUrl;
  final String? linkedinUrl;
  final String? videoIntroUrl;
  final String motivation; // Why they want to teach
  final String sampleLessonIdea; // Brief lesson idea
  final TeacherStatus status;
  final DateTime submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final String? rejectionReason;

  const TeacherApplication({
    required this.id,
    required this.odUserId,
    required this.email,
    required this.fullName,
    required this.bio,
    required this.teachingLanguages,
    required this.nativeLanguages,
    required this.teachingExperience,
    required this.yearsExperience,
    this.certificationUrls = const [],
    this.portfolioUrl,
    this.linkedinUrl,
    this.videoIntroUrl,
    required this.motivation,
    required this.sampleLessonIdea,
    this.status = TeacherStatus.pending,
    required this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [id, odUserId, email, status, submittedAt];
}

/// Lesson rating/review from a student
class LessonRating extends Equatable {
  final String id;
  final String lessonId;
  final String odUserId;
  final String? userDisplayName;
  final int rating; // 1-5 stars
  final String? review;
  final DateTime createdAt;
  final bool isVerifiedPurchase;
  final int helpfulCount;
  final bool isHidden;

  const LessonRating({
    required this.id,
    required this.lessonId,
    required this.odUserId,
    this.userDisplayName,
    required this.rating,
    this.review,
    required this.createdAt,
    this.isVerifiedPurchase = true,
    this.helpfulCount = 0,
    this.isHidden = false,
  });

  @override
  List<Object?> get props => [id, lessonId, odUserId, rating];
}

/// Teacher earnings record
class TeacherEarning extends Equatable {
  final String id;
  final String teacherId;
  final String lessonId;
  final String lessonTitle;
  final String purchasedByUserId;
  final int coinAmount; // Total coins paid
  final double teacherShare; // Teacher's percentage
  final int teacherCoins; // Coins earned by teacher
  final double usdEquivalent; // Approximate USD value
  final DateTime earnedAt;
  final bool isPaidOut;
  final String? payoutId;
  final DateTime? paidOutAt;

  const TeacherEarning({
    required this.id,
    required this.teacherId,
    required this.lessonId,
    required this.lessonTitle,
    required this.purchasedByUserId,
    required this.coinAmount,
    required this.teacherShare,
    required this.teacherCoins,
    this.usdEquivalent = 0.0,
    required this.earnedAt,
    this.isPaidOut = false,
    this.payoutId,
    this.paidOutAt,
  });

  @override
  List<Object?> get props => [id, teacherId, lessonId, teacherCoins, earnedAt];
}
