/**
 * Admin Role Entity
 * Point 227: Role-based access control (RBAC)
 */

import 'package:equatable/equatable.dart';

/// Admin user with role-based permissions
class AdminUser extends Equatable {
  final String userId;
  final String email;
  final String displayName;
  final AdminRole role;
  final List<Permission> permissions;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  const AdminUser({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.permissions,
    required this.createdAt,
    this.lastLoginAt,
    required this.isActive,
  });

  bool hasPermission(Permission permission) {
    return permissions.contains(permission);
  }

  bool canAccessFeature(AdminFeature feature) {
    return role.features.contains(feature);
  }

  @override
  List<Object?> get props => [
        userId,
        email,
        displayName,
        role,
        permissions,
        createdAt,
        lastLoginAt,
        isActive,
      ];
}

/// Admin roles (Point 227)
enum AdminRole {
  superAdmin,
  moderator,
  support,
  analyst;

  String get displayName {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.moderator:
        return 'Moderator';
      case AdminRole.support:
        return 'Support';
      case AdminRole.analyst:
        return 'Analyst';
    }
  }

  List<AdminFeature> get features {
    switch (this) {
      case AdminRole.superAdmin:
        return AdminFeature.values; // All features
      case AdminRole.moderator:
        return [
          AdminFeature.moderationQueue,
          AdminFeature.userReports,
          AdminFeature.contentReview,
          AdminFeature.userSearch,
          AdminFeature.userProfileView,
        ];
      case AdminRole.support:
        return [
          AdminFeature.userSearch,
          AdminFeature.userProfileView,
          AdminFeature.userCommunication,
          AdminFeature.subscriptionManagement,
        ];
      case AdminRole.analyst:
        return [
          AdminFeature.dashboard,
          AdminFeature.analytics,
          AdminFeature.reports,
        ];
    }
  }

  List<Permission> get defaultPermissions {
    switch (this) {
      case AdminRole.superAdmin:
        return Permission.values; // All permissions
      case AdminRole.moderator:
        return [
          Permission.viewReports,
          Permission.reviewContent,
          Permission.issueWarnings,
          Permission.suspendUsers,
          Permission.banUsers,
          Permission.viewUserProfiles,
        ];
      case AdminRole.support:
        return [
          Permission.viewUserProfiles,
          Permission.editUserProfiles,
          Permission.viewSubscriptions,
          Permission.overrideSubscriptions,
          Permission.adjustCoins,
          Permission.sendNotifications,
        ];
      case AdminRole.analyst:
        return [
          Permission.viewDashboard,
          Permission.viewAnalytics,
          Permission.exportData,
        ];
    }
  }
}

/// Admin features
enum AdminFeature {
  dashboard,
  analytics,
  reports,
  moderationQueue,
  userReports,
  contentReview,
  userSearch,
  userProfileView,
  userManagement,
  userCommunication,
  subscriptionManagement,
  systemSettings,
}

/// Granular permissions (Point 227)
enum Permission {
  // Dashboard
  viewDashboard,
  viewAnalytics,
  exportData,

  // User Management
  viewUserProfiles,
  editUserProfiles,
  suspendUsers,
  banUsers,
  deleteUsers,
  impersonateUsers,

  // Subscription Management
  viewSubscriptions,
  overrideSubscriptions,
  refundSubscriptions,

  // Coin Management
  adjustCoins,
  grantCoins,

  // Moderation
  viewReports,
  reviewContent,
  issueWarnings,
  removeContent,

  // Communication
  sendNotifications,
  sendEmails,
  broadcastMessages,

  // System
  manageAdmins,
  viewAuditLog,
  systemSettings,
}

/// Admin action audit log entry (Point 235)
class AdminAuditLog extends Equatable {
  final String logId;
  final String adminId;
  final String adminEmail;
  final AdminRole adminRole;
  final AdminAction action;
  final String targetType; // user, report, subscription, etc.
  final String targetId;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  final String? ipAddress;

  const AdminAuditLog({
    required this.logId,
    required this.adminId,
    required this.adminEmail,
    required this.adminRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.details,
    required this.timestamp,
    this.ipAddress,
  });

  @override
  List<Object?> get props => [
        logId,
        adminId,
        adminEmail,
        adminRole,
        action,
        targetType,
        targetId,
        details,
        timestamp,
        ipAddress,
      ];
}

/// Admin actions for audit log
enum AdminAction {
  // User actions
  viewedUserProfile,
  editedUserProfile,
  suspendedUser,
  unsuspendedUser,
  bannedUser,
  unbannedUser,
  deletedUser,
  impersonatedUser,

  // Moderation actions
  reviewedReport,
  approvedContent,
  rejectedContent,
  issuedWarning,
  removedContent,

  // Subscription actions
  viewedSubscription,
  overrodeSubscription,
  refundedSubscription,

  // Coin actions
  adjustedCoins,
  grantedCoins,

  // Communication
  sentNotification,
  sentEmail,
  broadcastMessage,

  // System
  createdAdmin,
  modifiedAdmin,
  deletedAdmin,
  changedSettings,
}
