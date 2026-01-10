import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../features/subscription/domain/entities/subscription.dart';

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

  UserAccessData({
    required this.userId,
    required this.approvalStatus,
    this.approvedAt,
    this.approvedBy,
    required this.accessDate,
    required this.membershipTier,
    this.notificationsEnabled = false,
  });

  factory UserAccessData.fromFirestore(Map<String, dynamic> data, String docId) {
    final tierString = data['membershipTier'] as String? ?? 'basic';
    final tier = SubscriptionTierExtension.fromString(tierString);

    // Determine access date based on tier
    DateTime accessDate;
    if (data['accessDate'] != null) {
      accessDate = (data['accessDate'] as Timestamp).toDate();
    } else {
      accessDate = tier.accessDate;
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
    };
  }

  /// Check if user can access the app
  bool get canAccessApp {
    if (approvalStatus != ApprovalStatus.approved) {
      return false;
    }
    return DateTime.now().isAfter(accessDate) || DateTime.now().isAtSameMomentAs(accessDate);
  }

  /// Get time remaining until access
  Duration get timeUntilAccess {
    final now = DateTime.now();
    if (now.isAfter(accessDate)) {
      return Duration.zero;
    }
    return accessDate.difference(now);
  }

  /// Check if user has early access (Platinum, Gold, Silver)
  bool get hasEarlyAccess => membershipTier.hasEarlyAccess;
}

/// Service for managing user access control during MVP release
class AccessControlService {
  final FirebaseFirestore _firestore;
  final auth.FirebaseAuth _auth;

  // MVP Release dates
  static final DateTime premiumAccessDate = DateTime(2026, 3, 1); // March 1st, 2026
  static final DateTime basicAccessDate = DateTime(2026, 3, 15); // March 15th, 2026

  AccessControlService({
    FirebaseFirestore? firestore,
    auth.FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? auth.FirebaseAuth.instance;

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
  Future<void> initializeUserAccess({
    required String userId,
    SubscriptionTier tier = SubscriptionTier.basic,
  }) async {
    final accessDate = tier.hasEarlyAccess ? premiumAccessDate : basicAccessDate;

    await _firestore.collection('users').doc(userId).set({
      'approvalStatus': ApprovalStatus.pending.name,
      'accessDate': Timestamp.fromDate(accessDate),
      'membershipTier': tier.name.toLowerCase(),
      'notificationsEnabled': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update user's membership tier and recalculate access date
  Future<void> updateMembershipTier(String userId, SubscriptionTier tier) async {
    final accessDate = tier.hasEarlyAccess ? premiumAccessDate : basicAccessDate;

    await _firestore.collection('users').doc(userId).update({
      'membershipTier': tier.name.toLowerCase(),
      'accessDate': Timestamp.fromDate(accessDate),
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

  /// Check if app is in pre-launch mode
  bool get isPreLaunchMode {
    final now = DateTime.now();
    return now.isBefore(basicAccessDate);
  }

  /// Get access date for a given tier
  DateTime getAccessDateForTier(SubscriptionTier tier) {
    return tier.hasEarlyAccess ? premiumAccessDate : basicAccessDate;
  }

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
