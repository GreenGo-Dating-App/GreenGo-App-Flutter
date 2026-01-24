import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../features/subscription/domain/entities/subscription.dart';
import 'early_access_service.dart';

/// Approval status for user accounts
enum ApprovalStatus {
  pending,
  approved,
  rejected,
}

extension ApprovalStatusExtension on ApprovalStatus {
  String get name {
    switch (this) {
      case ApprovalStatus.pending:
        return 'pending';
      case ApprovalStatus.approved:
        return 'approved';
      case ApprovalStatus.rejected:
        return 'rejected';
    }
  }

  static ApprovalStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      case 'pending':
      default:
        return ApprovalStatus.pending;
    }
  }
}

/// User access control data
class UserAccessData {
  final String userId;
  final ApprovalStatus approvalStatus;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime accessDate;
  final SubscriptionTier membershipTier;
  final bool notificationsEnabled;
  final bool hasEarlyAccess;

  UserAccessData({
    required this.userId,
    required this.approvalStatus,
    this.approvedAt,
    this.approvedBy,
    required this.accessDate,
    required this.membershipTier,
    this.notificationsEnabled = false,
    this.hasEarlyAccess = false,
  });

  factory UserAccessData.fromFirestore(Map<String, dynamic> data, String docId) {
    final tierString = data['membershipTier'] as String? ?? 'basic';
    final tier = SubscriptionTierExtension.fromString(tierString);

    // Determine access date from stored value or default to general access
    DateTime accessDate;
    if (data['accessDate'] != null) {
      accessDate = (data['accessDate'] as Timestamp).toDate();
    } else {
      // Default to general access date (March 16, 2026)
      accessDate = AccessControlService.generalAccessDate;
    }

    return UserAccessData(
      userId: docId,
      approvalStatus: ApprovalStatusExtension.fromString(
        data['approvalStatus'] as String? ?? 'pending',
      ),
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      approvedBy: data['approvedBy'] as String?,
      accessDate: accessDate,
      membershipTier: tier,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? false,
      hasEarlyAccess: data['hasEarlyAccess'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'approvalStatus': approvalStatus.name,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'accessDate': Timestamp.fromDate(accessDate),
      'membershipTier': membershipTier.name.toLowerCase(),
      'notificationsEnabled': notificationsEnabled,
      'hasEarlyAccess': hasEarlyAccess,
    };
  }

  /// Check if this is a Test user (bypasses countdown)
  bool get isTestUser => membershipTier == SubscriptionTier.test;

  /// Check if user can access the app
  /// User can access if:
  /// 1. They are approved by admin, AND
  /// 2. The current date is after their access date OR they are a Test user
  bool get canAccessApp {
    if (approvalStatus != ApprovalStatus.approved) {
      return false;
    }
    // Test users bypass the countdown entirely
    if (isTestUser) {
      return true;
    }
    return DateTime.now().isAfter(accessDate) || DateTime.now().isAtSameMomentAs(accessDate);
  }

  /// Check if countdown is still active (access date not reached yet)
  /// Test users never have an active countdown
  bool get isCountdownActive {
    // Test users bypass countdown
    if (isTestUser) {
      return false;
    }
    final now = DateTime.now();
    return now.isBefore(accessDate);
  }

  /// Check if user should see pending approval screen
  /// Only show when:
  /// 1. Countdown is over (access date has passed), AND
  /// 2. User is still pending approval
  bool get shouldShowPendingApproval {
    return !isCountdownActive && approvalStatus == ApprovalStatus.pending;
  }

  /// Get time remaining until access
  Duration get timeUntilAccess {
    final now = DateTime.now();
    if (now.isAfter(accessDate)) {
      return Duration.zero;
    }
    return accessDate.difference(now);
  }
}

/// Service for managing user access control during MVP release
class AccessControlService {
  final FirebaseFirestore _firestore;
  final auth.FirebaseAuth _auth;
  final EarlyAccessService _earlyAccessService;

  // MVP Release dates
  // Early access (users in CSV list): March 1st, 2026
  // General access (all others): March 16th, 2026
  static final DateTime earlyAccessDate = DateTime(2026, 3, 1);  // March 1st, 2026
  static final DateTime generalAccessDate = DateTime(2026, 3, 16); // March 16th, 2026

  // Legacy aliases for backwards compatibility
  static DateTime get premiumAccessDate => earlyAccessDate;
  static DateTime get basicAccessDate => generalAccessDate;

  AccessControlService({
    FirebaseFirestore? firestore,
    auth.FirebaseAuth? firebaseAuth,
    EarlyAccessService? earlyAccessService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? auth.FirebaseAuth.instance,
        _earlyAccessService = earlyAccessService ?? EarlyAccessService();

  /// Get current user's access data
  Future<UserAccessData?> getCurrentUserAccess() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return UserAccessData.fromFirestore(doc.data()!, user.uid);
    } catch (e) {
      return null;
    }
  }

  /// Stream of current user's access data
  Stream<UserAccessData?> watchCurrentUserAccess() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserAccessData.fromFirestore(doc.data()!, user.uid);
    });
  }

  /// Initialize user access data on registration
  /// Access date is determined by:
  /// 1. Email in early access CSV list -> March 1, 2026
  /// 2. All other users -> March 16, 2026
  Future<void> initializeUserAccess({
    required String userId,
    String? email,
    SubscriptionTier tier = SubscriptionTier.basic,
  }) async {
    // Check if email is in early access list
    bool hasEarlyAccess = false;
    if (email != null) {
      hasEarlyAccess = await _earlyAccessService.isEmailInEarlyAccessList(email);
    }

    // Determine access date based on early access list (not tier anymore)
    final accessDate = hasEarlyAccess ? earlyAccessDate : generalAccessDate;

    await _firestore.collection('users').doc(userId).set({
      'approvalStatus': ApprovalStatus.pending.name,
      'accessDate': Timestamp.fromDate(accessDate),
      'membershipTier': tier.name.toLowerCase(),
      'hasEarlyAccess': hasEarlyAccess,
      'notificationsEnabled': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Check and update user's access date based on early access list
  /// Call this when user logs in to ensure access date is current
  Future<void> refreshUserAccessDate(String userId, String? email) async {
    if (email == null) return;

    final hasEarlyAccess = await _earlyAccessService.isEmailInEarlyAccessList(email);
    final accessDate = hasEarlyAccess ? earlyAccessDate : generalAccessDate;

    await _firestore.collection('users').doc(userId).update({
      'accessDate': Timestamp.fromDate(accessDate),
      'hasEarlyAccess': hasEarlyAccess,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update user's membership tier
  /// Note: Access date is now based on early access list, not tier
  Future<void> updateMembershipTier(String userId, SubscriptionTier tier) async {
    await _firestore.collection('users').doc(userId).update({
      'membershipTier': tier.name.toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Enable notifications for the user
  Future<void> enableNotifications(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'notificationsEnabled': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check if app is in pre-launch mode (before general access date)
  bool get isPreLaunchMode {
    final now = DateTime.now();
    return now.isBefore(generalAccessDate);
  }

  /// Check if early access period has started (March 1, 2026)
  bool get isEarlyAccessPeriod {
    final now = DateTime.now();
    return now.isAfter(earlyAccessDate) && now.isBefore(generalAccessDate);
  }

  /// Get access date for current user based on early access list
  Future<DateTime> getAccessDateForCurrentUser() async {
    return _earlyAccessService.getAccessDateForCurrentUser();
  }

  /// Check if current user has early access
  Future<bool> currentUserHasEarlyAccess() async {
    return _earlyAccessService.currentUserHasEarlyAccess();
  }

  /// Get access date for a given tier (legacy - now based on early access list)
  @Deprecated('Use getAccessDateForCurrentUser() instead. Access is now based on early access list.')
  DateTime getAccessDateForTier(SubscriptionTier tier) {
    return generalAccessDate;
  }

  /// Get early access service for admin operations
  EarlyAccessService get earlyAccessService => _earlyAccessService;

  /// Approve a user (admin function)
  Future<void> approveUser(String userId, String adminId) async {
    await _firestore.collection('users').doc(userId).update({
      'approvalStatus': ApprovalStatus.approved.name,
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': adminId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject a user (admin function)
  Future<void> rejectUser(String userId, String adminId, String reason) async {
    await _firestore.collection('users').doc(userId).update({
      'approvalStatus': ApprovalStatus.rejected.name,
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': adminId,
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get all pending users (admin function)
  Stream<List<UserAccessData>> watchPendingUsers() {
    return _firestore
        .collection('users')
        .where('approvalStatus', isEqualTo: ApprovalStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserAccessData.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}
