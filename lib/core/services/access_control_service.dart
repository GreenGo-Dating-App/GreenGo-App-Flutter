import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import '../../features/subscription/domain/entities/subscription.dart';
import 'early_access_service.dart';
import 'pre_sale_service.dart';

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
  final bool isAdmin;
  final String? preSaleTier;
  final int? preSaleNumberOfDays;
  final DateTime? subscriptionExpiryDate;
  final DateTime? baseMembershipExpiryDate;

  UserAccessData({
    required this.userId,
    required this.approvalStatus,
    this.approvedAt,
    this.approvedBy,
    required this.accessDate,
    required this.membershipTier,
    this.notificationsEnabled = false,
    this.hasEarlyAccess = false,
    this.isAdmin = false,
    this.preSaleTier,
    this.preSaleNumberOfDays,
    this.subscriptionExpiryDate,
    this.baseMembershipExpiryDate,
  });

  factory UserAccessData.fromFirestore(Map<String, dynamic> data, String docId) {
    final tierString = data['membershipTier'] as String? ?? 'basic';
    final tier = SubscriptionTierExtension.fromString(tierString);

    // Determine access date from stored value or default based on tier
    DateTime accessDate;
    if (data['accessDate'] != null) {
      accessDate = (data['accessDate'] as Timestamp).toDate();
    } else {
      // Default: use tier-based access date, or general access (April 14, 2026)
      accessDate = AccessControlService.getAccessDateForSubscriptionTier(tier);
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
      isAdmin: data['isAdmin'] as bool? ?? false,
      preSaleTier: data['preSaleTier'] as String?,
      preSaleNumberOfDays: data['preSaleNumberOfDays'] as int?,
      subscriptionExpiryDate: data['subscriptionExpiryDate'] != null
          ? (data['subscriptionExpiryDate'] as Timestamp).toDate()
          : null,
      baseMembershipExpiryDate: data['baseMembershipExpiryDate'] != null
          ? (data['baseMembershipExpiryDate'] as Timestamp).toDate()
          : null,
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
      'isAdmin': isAdmin,
      if (preSaleTier != null) 'preSaleTier': preSaleTier,
      if (preSaleNumberOfDays != null) 'preSaleNumberOfDays': preSaleNumberOfDays,
      if (subscriptionExpiryDate != null)
        'subscriptionExpiryDate': Timestamp.fromDate(subscriptionExpiryDate!),
      if (baseMembershipExpiryDate != null)
        'baseMembershipExpiryDate': Timestamp.fromDate(baseMembershipExpiryDate!),
    };
  }

  /// Check if this is a Test user (bypasses countdown)
  bool get isTestUser => membershipTier == SubscriptionTier.test;

  /// Check if user can access the app
  /// User can access if:
  /// 1. They are an admin or test user (bypass all restrictions), OR
  /// 2. They are approved by admin (verified profile = full access), OR
  /// 3. They are pending approval (allowed during trial period)
  /// Only rejected users are blocked.
  bool get canAccessApp {
    // Admin and test users bypass ALL restrictions
    if (isAdmin || isTestUser) {
      return true;
    }
    // Rejected users cannot access — must resubmit verification
    if (approvalStatus == ApprovalStatus.rejected) {
      return false;
    }
    // Pending and approved users can access the app
    return true;
  }

  /// Check if countdown is still active (access date not reached yet)
  /// Admin and test users never have an active countdown
  bool get isCountdownActive {
    // Admin and test users bypass countdown
    if (isAdmin || isTestUser) {
      return false;
    }
    final now = DateTime.now();
    return now.isBefore(accessDate);
  }

  /// Check if user should see pending approval screen
  /// Only show when user has been rejected by admin.
  /// Pending users are allowed to use the app (trial period).
  bool get shouldShowPendingApproval {
    // Admin and test users never see pending approval screen
    if (isAdmin || isTestUser) {
      return false;
    }
    // Only rejected users see the review/resubmission screen
    return approvalStatus == ApprovalStatus.rejected;
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

  // Default fallback dates (used until Firestore config is loaded)
  static DateTime _platinumAccessDate = DateTime(2026, 3, 14);
  static DateTime _goldAccessDate = DateTime(2026, 3, 28);
  static DateTime _silverAccessDate = DateTime(2026, 4, 7);
  static DateTime _generalAccessDate = DateTime(2026, 4, 14);
  // Public getters — always use the latest fetched values
  static DateTime get platinumAccessDate => _platinumAccessDate;
  static DateTime get goldAccessDate => _goldAccessDate;
  static DateTime get silverAccessDate => _silverAccessDate;
  static DateTime get generalAccessDate => _generalAccessDate;

  // Early access list users get the same date as Platinum
  static DateTime get earlyAccessDate => _platinumAccessDate;

  // Legacy aliases for backwards compatibility
  static DateTime get premiumAccessDate => earlyAccessDate;
  static DateTime get basicAccessDate => generalAccessDate;

  /// Fetch countdown dates from Firestore `app_config/countdown` document.
  /// Called on app startup and on every login to pick up admin changes.
  /// Uses server fetch (bypasses cache) to ensure fresh data.
  /// Falls back to defaults if fetch fails.
  static Future<void> loadCountdownDatesFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('countdown')
          .get(const GetOptions(source: Source.server));
      if (doc.exists) {
        final data = doc.data()!;
        if (data['platinumAccessDate'] != null) {
          _platinumAccessDate = (data['platinumAccessDate'] as Timestamp).toDate();
        }
        if (data['goldAccessDate'] != null) {
          _goldAccessDate = (data['goldAccessDate'] as Timestamp).toDate();
        }
        if (data['silverAccessDate'] != null) {
          _silverAccessDate = (data['silverAccessDate'] as Timestamp).toDate();
        }
        if (data['generalAccessDate'] != null) {
          _generalAccessDate = (data['generalAccessDate'] as Timestamp).toDate();
        }
      }
    } catch (e) {
      // On network error, try cache as fallback
      try {
        final doc = await FirebaseFirestore.instance
            .collection('app_config')
            .doc('countdown')
            .get(const GetOptions(source: Source.cache));
        if (doc.exists) {
          final data = doc.data()!;
          if (data['platinumAccessDate'] != null) {
            _platinumAccessDate = (data['platinumAccessDate'] as Timestamp).toDate();
          }
          if (data['goldAccessDate'] != null) {
            _goldAccessDate = (data['goldAccessDate'] as Timestamp).toDate();
          }
          if (data['silverAccessDate'] != null) {
            _silverAccessDate = (data['silverAccessDate'] as Timestamp).toDate();
          }
          if (data['generalAccessDate'] != null) {
            _generalAccessDate = (data['generalAccessDate'] as Timestamp).toDate();
          }
        }
      } catch (_) {
        // Use hardcoded defaults
      }
    }
  }

  /// Get access date for a subscription tier
  static DateTime getAccessDateForSubscriptionTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.test:
        return DateTime.now().subtract(const Duration(days: 1)); // Immediate
      case SubscriptionTier.platinum:
        return _platinumAccessDate;
      case SubscriptionTier.gold:
        return _goldAccessDate;
      case SubscriptionTier.silver:
        return _silverAccessDate;
      case SubscriptionTier.basic:
        return _generalAccessDate;
    }
  }

  final PreSaleService _preSaleService;

  AccessControlService({
    FirebaseFirestore? firestore,
    auth.FirebaseAuth? firebaseAuth,
    EarlyAccessService? earlyAccessService,
    PreSaleService? preSaleService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? auth.FirebaseAuth.instance,
        _earlyAccessService = earlyAccessService ?? EarlyAccessService(),
        _preSaleService = preSaleService ?? PreSaleService();

  /// Get current user's access data
  /// When [forceServer] is true, bypasses Firestore cache to get fresh data.
  Future<UserAccessData?> getCurrentUserAccess({bool forceServer = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Always read from server to avoid stale cached approvalStatus
      final doc = await _firestore.collection('users').doc(user.uid).get(
        const GetOptions(source: Source.server),
      );
      if (!doc.exists) return null;

      final data = doc.data()!;
      final approvalStatus = data['approvalStatus'] as String? ?? 'pending';

      // Always cross-check profiles.verificationStatus on every login
      // to keep users.approvalStatus in sync with the source of truth
      try {
        final profileDoc = await _firestore.collection('profiles').doc(user.uid).get(
          const GetOptions(source: Source.server),
        );
        if (profileDoc.exists) {
          final verificationStatus = profileDoc.data()?['verificationStatus'] as String?;
          debugPrint('🔑 users.approvalStatus=$approvalStatus, profiles.verificationStatus=$verificationStatus');
          final isVerified = verificationStatus == 'approved' || verificationStatus == 'verified';

          if (isVerified && approvalStatus != 'approved') {
            // Profile verified but users collection out of sync — set approved
            debugPrint('🔑 Syncing users.approvalStatus → approved');
            await _firestore.collection('users').doc(user.uid).update({
              'approvalStatus': 'approved',
              'approvedAt': FieldValue.serverTimestamp(),
              'approvedBy': 'system_sync',
              'updatedAt': FieldValue.serverTimestamp(),
            });
            final correctedDoc = await _firestore.collection('users').doc(user.uid).get(
              const GetOptions(source: Source.server),
            );
            if (!correctedDoc.exists) return null;
            return UserAccessData.fromFirestore(correctedDoc.data()!, user.uid);
          } else if (!isVerified && approvalStatus == 'approved') {
            // Profile no longer verified but users collection still says approved — revoke
            debugPrint('🔑 Syncing users.approvalStatus → pending (verification revoked)');
            await _firestore.collection('users').doc(user.uid).update({
              'approvalStatus': 'pending',
              'updatedAt': FieldValue.serverTimestamp(),
            });
            final correctedDoc = await _firestore.collection('users').doc(user.uid).get(
              const GetOptions(source: Source.server),
            );
            if (!correctedDoc.exists) return null;
            return UserAccessData.fromFirestore(correctedDoc.data()!, user.uid);
          }
        }
      } catch (_) {
        // Non-critical — proceed with original data
      }

      return UserAccessData.fromFirestore(data, user.uid);
    } catch (e) {
      // Fallback to cache on network error
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) return null;
        return UserAccessData.fromFirestore(doc.data()!, user.uid);
      } catch (_) {
        return null;
      }
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
  /// 1. Email in pre_sale collection -> tier-specific countdown date
  /// 2. Email in early access CSV list -> March 14, 2026 (same as Platinum)
  /// 3. Subscription tier -> Platinum March 14, Gold March 28, Silver April 7
  /// 4. All other users -> April 14, 2026 (official release)
  Future<void> initializeUserAccess({
    required String userId,
    String? email,
    SubscriptionTier tier = SubscriptionTier.basic,
  }) async {
    // 1. Check pre-sale collection first (highest priority)
    PreSaleEntry? preSaleEntry;
    if (email != null) {
      preSaleEntry = await _preSaleService.getPreSaleEntry(email);
    }

    if (preSaleEntry != null) {
      // Pre-sale user: assign tier, countdown date, and subscription expiry
      final preSaleTier = preSaleEntry.tier;
      final accessDate = PreSaleService.getCountdownEndDate(preSaleTier);
      final subscriptionExpiry = PreSaleService.calculateSubscriptionExpiry(
        preSaleTier, preSaleEntry.numberOfDays,
      );
      final baseMembershipExpiry = subscriptionExpiry; // Same as subscription

      // Map pre-sale tier to subscription tier
      final SubscriptionTier mappedTier;
      switch (preSaleTier) {
        case PreSaleTier.platinum:
          mappedTier = SubscriptionTier.platinum;
        case PreSaleTier.gold:
          mappedTier = SubscriptionTier.gold;
        case PreSaleTier.silver:
          mappedTier = SubscriptionTier.silver;
      }

      await _firestore.collection('users').doc(userId).set({
        'approvalStatus': ApprovalStatus.pending.name,
        'accessDate': Timestamp.fromDate(accessDate),
        'membershipTier': mappedTier.name.toLowerCase(),
        'hasEarlyAccess': true,
        'preSaleTier': preSaleTier.value,
        'preSaleNumberOfDays': preSaleEntry.numberOfDays,
        'subscriptionExpiryDate': Timestamp.fromDate(subscriptionExpiry),
        'baseMembershipExpiryDate': Timestamp.fromDate(baseMembershipExpiry),
        'notificationsEnabled': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Pre-sale user registered: ${preSaleEntry.email} '
          'tier=${preSaleTier.displayName} days=${preSaleEntry.numberOfDays} '
          'access=$accessDate expires=$subscriptionExpiry');
      return;
    }

    // 2. Check early access list
    bool hasEarlyAccess = false;
    if (email != null) {
      hasEarlyAccess = await _earlyAccessService.isEmailInEarlyAccessList(email);
    }

    // 3. Determine access date: early access list takes priority, then tier-based
    final DateTime accessDate;
    if (hasEarlyAccess) {
      accessDate = earlyAccessDate; // Same as Platinum
    } else {
      accessDate = getAccessDateForSubscriptionTier(tier);
    }

    await _firestore.collection('users').doc(userId).set({
      'approvalStatus': ApprovalStatus.pending.name,
      'accessDate': Timestamp.fromDate(accessDate),
      'membershipTier': tier.name.toLowerCase(),
      'hasEarlyAccess': hasEarlyAccess,
      'notificationsEnabled': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Check and update user's access date based on early access list and tier
  /// Call this when user logs in to ensure access date is current
  Future<void> refreshUserAccessDate(String userId, String? email) async {
    // Get current user's tier
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final tierString = userDoc.data()?['membershipTier'] as String? ?? 'basic';
    final tier = SubscriptionTierExtension.fromString(tierString);

    bool hasEarlyAccess = false;
    if (email != null) {
      hasEarlyAccess = await _earlyAccessService.isEmailInEarlyAccessList(email);
    }

    // Use earliest available date (early access or tier-based)
    final DateTime accessDate;
    if (hasEarlyAccess) {
      accessDate = earlyAccessDate;
    } else {
      accessDate = getAccessDateForSubscriptionTier(tier);
    }

    await _firestore.collection('users').doc(userId).update({
      'accessDate': Timestamp.fromDate(accessDate),
      'hasEarlyAccess': hasEarlyAccess,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update user's membership tier and recalculate access date
  Future<void> updateMembershipTier(String userId, SubscriptionTier tier) async {
    // Get current early access status
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final hasEarlyAccess = userDoc.data()?['hasEarlyAccess'] as bool? ?? false;

    // Recalculate access date: early access list takes priority, then tier-based
    final DateTime accessDate;
    if (hasEarlyAccess) {
      accessDate = earlyAccessDate;
    } else {
      accessDate = getAccessDateForSubscriptionTier(tier);
    }

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

  /// Check if app is in pre-launch mode (before general access date)
  bool get isPreLaunchMode {
    final now = DateTime.now();
    return now.isBefore(generalAccessDate);
  }

  /// Check if early access period has started (March 14, 2026 - April 14, 2026)
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

  /// Get access date for a given tier
  @Deprecated('Use getAccessDateForSubscriptionTier() instead.')
  DateTime getAccessDateForTier(SubscriptionTier tier) {
    return getAccessDateForSubscriptionTier(tier);
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
