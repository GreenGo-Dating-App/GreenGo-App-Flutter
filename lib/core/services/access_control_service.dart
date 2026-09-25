import 'dart:async';

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

  UserAccessData({
    required this.userId,
    required this.approvalStatus,
    required this.accessDate, required this.membershipTier, this.approvedAt,
    this.approvedBy,
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

  UserAccessData copyWith({
    ApprovalStatus? approvalStatus,
    DateTime? accessDate,
    bool? hasEarlyAccess,
  }) {
    return UserAccessData(
      userId: userId,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedAt: approvedAt,
      approvedBy: approvedBy,
      accessDate: accessDate ?? this.accessDate,
      membershipTier: membershipTier,
      notificationsEnabled: notificationsEnabled,
      hasEarlyAccess: hasEarlyAccess ?? this.hasEarlyAccess,
      isAdmin: isAdmin,
      preSaleTier: preSaleTier,
      preSaleNumberOfDays: preSaleNumberOfDays,
      subscriptionExpiryDate: subscriptionExpiryDate,
      baseMembershipExpiryDate: baseMembershipExpiryDate,
    );
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

  AccessControlService({
    FirebaseFirestore? firestore,
    auth.FirebaseAuth? firebaseAuth,
    EarlyAccessService? earlyAccessService,
    PreSaleService? preSaleService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? auth.FirebaseAuth.instance,
        _earlyAccessService = earlyAccessService ?? EarlyAccessService(),
        _preSaleService = preSaleService ?? PreSaleService();
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

  static Future<void>? _countdownLoad;
  static DateTime? _countdownLoadStartedAt;
  static const Duration _countdownTtl = Duration(minutes: 1);

  /// Fetch countdown dates from Firestore `app_config/countdown` document.
  /// Called on app startup and on every login to pick up admin changes.
  /// Uses server fetch (bypasses cache) to ensure fresh data.
  /// Falls back to defaults if fetch fails.
  ///
  /// Startup, the auth bloc and the main screen all ask for this within the
  /// same second, so calls within [_countdownTtl] share one read.
  static Future<void> loadCountdownDatesFromFirestore() {
    final startedAt = _countdownLoadStartedAt;
    final inFlight = _countdownLoad;
    if (inFlight != null &&
        startedAt != null &&
        DateTime.now().difference(startedAt) < _countdownTtl) {
      return inFlight;
    }
    _countdownLoadStartedAt = DateTime.now();
    return _countdownLoad = _fetchCountdownDates();
  }

  static Future<void> _fetchCountdownDates() async {
    try {
      // Bounded: a server read has no deadline of its own, and callers wait
      // on this before resolving the user's countdown.
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('countdown')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
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

  /// Recent SERVER reads of the signed-in user's own `users` / `profiles`
  /// docs, shared by AuthWrapper, MainNavigationScreen and the auth bloc so a
  /// launch reads each doc from the server once instead of 3-4 times. Holds
  /// the in-flight future too, so concurrent callers share one round trip.
  static final Map<String,
          ({DateTime at, Future<DocumentSnapshot<Map<String, dynamic>>> read})>
      _ownDocReads = {};
  static const Duration _ownDocTtl = Duration(seconds: 30);

  /// Server read of `collection/uid`, shared with any other caller within
  /// [_ownDocTtl]. Callers add their own timeout.
  Future<DocumentSnapshot<Map<String, dynamic>>> serverDoc(
      String collection, String uid) {
    final key = '$collection/$uid';
    final hit = _ownDocReads[key];
    if (hit != null && DateTime.now().difference(hit.at) < _ownDocTtl) {
      return hit.read;
    }
    final read = _firestore
        .collection(collection)
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    _ownDocReads[key] = (at: DateTime.now(), read: read);
    // A failed read is not replayed to the next caller.
    read.then((_) {}, onError: (Object _) {
      if (identical(_ownDocReads[key]?.read, read)) _ownDocReads.remove(key);
    });
    return read;
  }

  /// Drop the shared read of `collection/uid` (call after writing it).
  static void invalidateOwnDoc(String collection, String uid) =>
      _ownDocReads.remove('$collection/$uid');

  /// Forget every shared read (sign-out).
  static void clearSessionCache() {
    _ownDocReads.clear();
    _countdownLoad = null;
    _countdownLoadStartedAt = null;
  }

  /// The current user's access data from the LOCAL Firestore cache only (no
  /// network), or null when it isn't cached. Used to paint the shell on a
  /// returning launch; the server check always follows.
  Future<UserAccessData?> getCachedUserAccess() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.cache));
      if (!doc.exists) return null;
      return UserAccessData.fromFirestore(doc.data()!, user.uid);
    } catch (_) {
      return null; // not in the local cache
    }
  }

  /// Get current user's access data
  /// When [forceServer] is true, bypasses Firestore cache to get fresh data.
  /// [profileData] is the caller's fresh server copy of `profiles/{uid}`, if
  /// it already has one, so the cross-check below doesn't read it again.
  ///
  /// Null normally means "no access doc OR it couldn't be read". With
  /// [throwIfServerUnavailable] a failed server read throws instead of
  /// falling back to the cache, so null means the doc positively does not
  /// exist on the server (the only case where it is safe to create it).
  Future<UserAccessData?> getCurrentUserAccess({
    bool forceServer = false,
    Map<String, dynamic>? profileData,
    bool throwIfServerUnavailable = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Always read from server to avoid stale cached approvalStatus. Both
      // docs are requested together (one round trip instead of two).
      final profileRead =
          profileData == null ? serverDoc('profiles', user.uid) : null;
      final doc = await serverDoc('users', user.uid);
      if (!doc.exists) return null;

      final data = doc.data()!;
      final approvalStatus = data['approvalStatus'] as String? ?? 'pending';

      // Always cross-check profiles.verificationStatus on every login
      // to keep users.approvalStatus in sync with the source of truth
      try {
        final profile = profileData ?? (await profileRead!).data();
        if (profile != null) {
          final verificationStatus = profile['verificationStatus'] as String?;
          debugPrint('🔑 users.approvalStatus=$approvalStatus, profiles.verificationStatus=$verificationStatus');
          final isVerified = verificationStatus == 'approved' || verificationStatus == 'verified';

          // The sync write is not awaited: the corrected value is returned
          // straight away and the write lands in the background.
          if (isVerified && approvalStatus != 'approved') {
            // Profile verified but users collection out of sync — set approved
            debugPrint('🔑 Syncing users.approvalStatus → approved');
            _syncUsersDoc(user.uid, {
              'approvalStatus': 'approved',
              'approvedAt': FieldValue.serverTimestamp(),
              'approvedBy': 'system_sync',
              'updatedAt': FieldValue.serverTimestamp(),
            });
            return UserAccessData.fromFirestore({
              ...data,
              'approvalStatus': 'approved',
              'approvedAt': Timestamp.now(),
              'approvedBy': 'system_sync',
            }, user.uid);
          } else if (!isVerified && approvalStatus == 'approved') {
            // Profile no longer verified but users collection still says approved — revoke
            debugPrint('🔑 Syncing users.approvalStatus → pending (verification revoked)');
            _syncUsersDoc(user.uid, {
              'approvalStatus': 'pending',
              'updatedAt': FieldValue.serverTimestamp(),
            });
            return UserAccessData.fromFirestore(
                {...data, 'approvalStatus': 'pending'}, user.uid);
          }
        }
      } catch (_) {
        // Non-critical — proceed with original data
      }

      return UserAccessData.fromFirestore(data, user.uid);
    } catch (e) {
      if (throwIfServerUnavailable) rethrow;
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
      invalidateOwnDoc('users', userId);

      debugPrint('Pre-sale user registered: ${preSaleEntry.email} '
          'tier=${preSaleTier.displayName} days=${preSaleEntry.numberOfDays} '
          'access=$accessDate expires=$subscriptionExpiry');
      return;
    }

    // 2. Check early access list
    var hasEarlyAccess = false;
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
    invalidateOwnDoc('users', userId);
  }

  /// Check and update user's access date based on early access list and tier
  /// Call this when user logs in to ensure access date is current
  Future<void> refreshUserAccessDate(String userId, String? email) async {
    // Get current user's tier
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data();
    if (data == null) return;
    final (:accessDate, :hasEarlyAccess) = await _expectedAccessDate(
      SubscriptionTierExtension.fromString(
          data['membershipTier'] as String? ?? 'basic'),
      email,
    );
    // Written only when it changed, instead of on every login.
    final stored = (data['accessDate'] as Timestamp?)?.toDate();
    if (stored == accessDate && data['hasEarlyAccess'] == hasEarlyAccess) {
      return;
    }
    await _writeAccessDate(userId, accessDate, hasEarlyAccess);
  }

  /// Returns [access] with the access date recalculated from the user's tier,
  /// the early-access list and the latest countdown dates. A changed value is
  /// persisted in the background, so callers never wait on the write.
  Future<UserAccessData> reconcileAccessDate(
      UserAccessData access, String? email) async {
    final (:accessDate, :hasEarlyAccess) =
        await _expectedAccessDate(access.membershipTier, email);
    if (access.accessDate == accessDate &&
        access.hasEarlyAccess == hasEarlyAccess) {
      return access;
    }
    unawaited(
      _writeAccessDate(access.userId, accessDate, hasEarlyAccess)
          .catchError((Object e) {
        debugPrint('⚠ Access date sync failed for ${access.userId}: $e');
      }),
    );
    return access.copyWith(
        accessDate: accessDate, hasEarlyAccess: hasEarlyAccess);
  }

  Future<({DateTime accessDate, bool hasEarlyAccess})> _expectedAccessDate(
      SubscriptionTier tier, String? email) async {
    var hasEarlyAccess = false;
    if (email != null) {
      hasEarlyAccess = await _earlyAccessService.isEmailInEarlyAccessList(email);
    }
    // Use earliest available date (early access or tier-based)
    return (
      accessDate: hasEarlyAccess
          ? earlyAccessDate
          : getAccessDateForSubscriptionTier(tier),
      hasEarlyAccess: hasEarlyAccess,
    );
  }

  Future<void> _writeAccessDate(
      String userId, DateTime accessDate, bool hasEarlyAccess) async {
    await _firestore.collection('users').doc(userId).update({
      'accessDate': Timestamp.fromDate(accessDate),
      'hasEarlyAccess': hasEarlyAccess,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    invalidateOwnDoc('users', userId);
  }

  /// Fire-and-forget correction of `users/{uid}`; failures are only logged.
  void _syncUsersDoc(String userId, Map<String, Object?> fields) {
    invalidateOwnDoc('users', userId);
    unawaited(
      _firestore.collection('users').doc(userId).update(fields).catchError(
        (Object e) => debugPrint('⚠ users/$userId sync failed: $e'),
      ),
    );
  }

  // `updateMembershipTier` (a client write of the `users/{uid}.membershipTier`
  // mirror) was removed: nothing called it, and `users.*` tier fields are an
  // untrusted mirror. `users.membershipTier` here is only the PRE-LAUNCH access
  // tier (countdown date / tester flag) written at registration — paid
  // features are gated on the profile's effective tier (effective_tier.dart).

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
    invalidateOwnDoc('users', userId);
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
