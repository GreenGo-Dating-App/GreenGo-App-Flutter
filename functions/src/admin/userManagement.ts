/**
 * User Management Cloud Functions
 * Points 236-245: Admin user management tools
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

const firestore = admin.firestore();
const auth = admin.auth();

/**
 * Verify Admin Permission Helper
 */
async function verifyAdminPermission(
  context: functions.https.CallableContext,
  requiredPermission: string
): Promise<void> {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const adminDoc = await firestore.collection('admins').doc(context.auth.uid).get();
  if (!adminDoc.exists) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin profile not found'
    );
  }

  const permissions = adminDoc.data()!.permissions || [];
  if (!permissions.includes(requiredPermission)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      `Missing required permission: ${requiredPermission}`
    );
  }
}

/**
 * Log Admin Action Helper
 */
async function logAdminAction(
  adminId: string,
  action: string,
  targetType: string,
  targetId: string,
  details: any
): Promise<void> {
  const adminDoc = await firestore.collection('admins').doc(adminId).get();
  const adminData = adminDoc.data();

  await firestore.collection('admin_audit_log').add({
    adminId,
    adminEmail: adminData?.email || 'unknown',
    adminRole: adminData?.role || 'unknown',
    action,
    targetType,
    targetId,
    details,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Search Users
 * Point 236: Advanced user search
 */
export const searchUsers = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'viewUserProfiles');

  const { query, filters = {}, limit = 50, offset = 0 } = data;

  try {
    let usersQuery: any = firestore.collection('users');

    // Apply filters
    if (filters.accountStatus) {
      usersQuery = usersQuery.where('accountStatus', '==', filters.accountStatus);
    }

    if (filters.subscriptionTier) {
      usersQuery = usersQuery.where('subscriptionTier', '==', filters.subscriptionTier);
    }

    if (filters.isVerified !== undefined) {
      usersQuery = usersQuery.where('isPhotoVerified', '==', filters.isVerified);
    }

    const usersSnapshot = await usersQuery.limit(limit).offset(offset).get();

    // Filter by search query (text search)
    let users = usersSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        userId: doc.id,
        displayName: data.displayName,
        email: data.email,
        age: data.age,
        photoUrl: data.photos?.[0] || null,
        accountStatus: data.accountStatus,
        createdAt: data.createdAt,
        lastActiveAt: data.lastActiveAt,
        subscriptionTier: data.subscriptionTier || null,
        matchScore: 1.0,
      };
    });

    // Apply text search if query provided
    if (query && query.trim()) {
      users = users.filter(user => {
        const searchText = query.toLowerCase();
        return (
          user.displayName.toLowerCase().includes(searchText) ||
          user.email.toLowerCase().includes(searchText) ||
          user.userId.toLowerCase().includes(searchText)
        );
      });

      // Calculate match score
      users = users.map(user => {
        const searchText = query.toLowerCase();
        let score = 0;

        if (user.email.toLowerCase() === searchText) score = 1.0;
        else if (user.displayName.toLowerCase() === searchText) score = 0.9;
        else if (user.email.toLowerCase().includes(searchText)) score = 0.7;
        else if (user.displayName.toLowerCase().includes(searchText)) score = 0.6;
        else score = 0.3;

        return { ...user, matchScore: score };
      });

      // Sort by match score
      users.sort((a, b) => b.matchScore - a.matchScore);
    }

    return {
      users,
      total: users.length,
    };
  } catch (error: any) {
    console.error('Error searching users:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Get Detailed User Profile
 * Point 237: View complete user profile
 */
export const getDetailedUserProfile = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'viewUserProfiles');

  const { userId } = data;

  try {
    const userDoc = await firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      throw new Error('User not found');
    }

    const userData = userDoc.data()!;

    // Get subscription info
    let subscriptionInfo = null;
    const subsSnapshot = await firestore
      .collection('subscriptions')
      .where('userId', '==', userId)
      .where('status', 'in', ['active', 'canceled', 'in_grace_period'])
      .limit(1)
      .get();

    if (!subsSnapshot.empty) {
      const subData = subsSnapshot.docs[0].data();
      subscriptionInfo = {
        subscriptionId: subsSnapshot.docs[0].id,
        tier: subData.tier,
        status: subData.status,
        purchaseDate: subData.purchaseDate,
        expirationDate: subData.expirationDate,
        canceledAt: subData.canceledAt || null,
        autoRenew: subData.autoRenew,
        platform: subData.platform,
        price: subData.price,
        currency: subData.currency,
        renewalCount: subData.renewalCount || 0,
      };
    }

    // Get coin info
    const coinSnapshot = await firestore
      .collection('coin_balances')
      .doc(userId)
      .get();

    const coinData = coinSnapshot.data() || {};
    const coinInfo = {
      totalCoins: coinData.totalCoins || 0,
      lifetimePurchased: coinData.lifetimePurchased || 0,
      lifetimeSpent: coinData.lifetimeSpent || 0,
      lifetimeEarned: coinData.lifetimeEarned || 0,
      lastPurchaseAt: coinData.lastPurchaseAt || null,
      batches: coinData.coinBatches || [],
    };

    // Get activity stats
    const matchesCount = await firestore
      .collection('matches')
      .where('users', 'array-contains', userId)
      .count()
      .get();

    const messagesCount = await firestore
      .collection('messages')
      .where('senderId', '==', userId)
      .count()
      .get();

    const likesCount = await firestore
      .collection('likes')
      .where('likerId', '==', userId)
      .count()
      .get();

    const activityInfo = {
      totalMatches: matchesCount.data().count,
      totalMessages: messagesCount.data().count,
      totalLikes: likesCount.data().count,
      totalSuperLikes: 0,
      totalBoosts: 0,
      lastActiveAt: userData.lastActiveAt || null,
      daysActive: 0,
      avgSessionDuration: 0,
      totalSessions: 0,
    };

    // Get moderation info
    const reportsCount = await firestore
      .collection('user_reports')
      .where('reportedUserId', '==', userId)
      .count()
      .get();

    const warningsCount = await firestore
      .collection('user_warnings')
      .where('userId', '==', userId)
      .count()
      .get();

    const moderationInfo = {
      reportCount: reportsCount.data().count,
      warningCount: warningsCount.data().count,
      suspensionCount: 0,
      lastWarningAt: null,
      lastSuspensionAt: null,
      isShadowBanned: userData.isShadowBanned || false,
      visibilityReduction: userData.visibilityReduction || null,
      appliedRestrictions: [],
    };

    // Get verification info
    const verificationInfo = {
      isPhotoVerified: userData.isPhotoVerified || false,
      isIdVerified: userData.isIdVerified || false,
      photoVerifiedAt: userData.photoVerifiedAt || null,
      idVerifiedAt: userData.idVerifiedAt || null,
      trustScore: userData.trustScore || 0,
      trustLevel: userData.trustLevel || 'veryLow',
    };

    // Build complete profile
    const profile = {
      userId,
      basicInfo: {
        displayName: userData.displayName,
        email: userData.email,
        phoneNumber: userData.phoneNumber || null,
        age: userData.age,
        gender: userData.gender,
        photoUrls: userData.photos || [],
        bio: userData.bio || null,
        location: userData.location || null,
        latitude: userData.latitude || null,
        longitude: userData.longitude || null,
      },
      accountInfo: {
        createdAt: userData.createdAt,
        lastLoginAt: userData.lastLoginAt || null,
        accountStatus: userData.accountStatus,
        suspensionReason: userData.suspensionReason || null,
        suspendedUntil: userData.suspendedUntil || null,
        bannedAt: userData.bannedAt || null,
        banReason: userData.banReason || null,
        isEmailVerified: userData.isEmailVerified || false,
        isPhoneVerified: userData.isPhoneVerified || false,
        devicePlatform: userData.devicePlatform || 'unknown',
        appVersion: userData.appVersion || 'unknown',
      },
      subscriptionInfo,
      coinInfo,
      activityInfo,
      moderationInfo,
      verificationInfo,
      flags: [],
      tags: userData.tags || [],
    };

    // Log admin action
    await logAdminAction(
      context.auth!.uid,
      'viewedUserProfile',
      'user',
      userId,
      { userId }
    );

    return profile;
  } catch (error: any) {
    console.error('Error getting detailed user profile:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Edit User Profile
 * Point 238: Admin can edit user data
 */
export const editUserProfile = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'editUserProfiles');

  const { userId, updates } = data;

  try {
    // Validate and sanitize updates
    const allowedFields = [
      'displayName',
      'bio',
      'age',
      'gender',
      'location',
      'latitude',
      'longitude',
    ];

    const sanitizedUpdates: any = {};
    Object.keys(updates).forEach(key => {
      if (allowedFields.includes(key)) {
        sanitizedUpdates[key] = updates[key];
      }
    });

    await firestore.collection('users').doc(userId).update(sanitizedUpdates);

    // Log admin action
    await logAdminAction(
      context.auth!.uid,
      'editedUserProfile',
      'user',
      userId,
      { updates: sanitizedUpdates }
    );

    return { success: true };
  } catch (error: any) {
    console.error('Error editing user profile:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Suspend User Account
 * Point 239: Temporary account suspension
 */
export const suspendUserAccount = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'suspendUsers');

  const { userId, reason, durationDays = 7 } = data;

  try {
    const suspendedUntil = new Date();
    suspendedUntil.setDate(suspendedUntil.getDate() + durationDays);

    await firestore.collection('users').doc(userId).update({
      accountStatus: 'suspended',
      suspensionReason: reason,
      suspendedUntil: admin.firestore.Timestamp.fromDate(suspendedUntil),
      suspendedBy: context.auth!.uid,
      suspendedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Log admin action
    await logAdminAction(
      context.auth!.uid,
      'suspendedUser',
      'user',
      userId,
      { reason, durationDays }
    );

    return { success: true, suspendedUntil };
  } catch (error: any) {
    console.error('Error suspending user account:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Unsuspend User Account
 * Point 239: Lift suspension
 */
export const unsuspendUserAccount = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'suspendUsers');

  const { userId } = data;

  try {
    await firestore.collection('users').doc(userId).update({
      accountStatus: 'active',
      suspensionReason: null,
      suspendedUntil: null,
      unsuspendedBy: context.auth!.uid,
      unsuspendedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Log admin action
    await logAdminAction(
      context.auth!.uid,
      'unsuspendedUser',
      'user',
      userId,
      { userId }
    );

    return { success: true };
  } catch (error: any) {
    console.error('Error unsuspending user account:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Ban User Account
 * Point 239: Permanent account ban
 */
export const banUserAccount = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'banUsers');

  const { userId, reason } = data;

  try {
    await firestore.collection('users').doc(userId).update({
      accountStatus: 'banned',
      banReason: reason,
      bannedBy: context.auth!.uid,
      bannedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Disable Firebase Auth account
    await auth.updateUser(userId, {
      disabled: true,
    });

    // Log admin action
    await logAdminAction(
      context.auth!.uid,
      'bannedUser',
      'user',
      userId,
      { reason }
    );

    return { success: true };
  } catch (error: any) {
    console.error('Error banning user account:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Unban User Account
 * Point 239: Lift permanent ban
 */
export const unbanUserAccount = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'banUsers');

  const { userId } = data;

  try {
    await firestore.collection('users').doc(userId).update({
      accountStatus: 'active',
      banReason: null,
      unbannedBy: context.auth!.uid,
      unbannedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Re-enable Firebase Auth account
    await auth.updateUser(userId, {
      disabled: false,
    });

    // Log admin action
    await logAdminAction(
      context.auth!.uid,
      'unbannedUser',
      'user',
      userId,
      { userId }
    );

    return { success: true };
  } catch (error: any) {
    console.error('Error unbanning user account:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Delete User Account
 * Point 239: Permanent account deletion
 */
export const deleteUserAccount = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'deleteUsers');

  const { userId, reason } = data;

  try {
    // Mark as deleted (soft delete)
    await firestore.collection('users').doc(userId).update({
      accountStatus: 'deleted',
      deletedBy: context.auth!.uid,
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      deletionReason: reason,
    });

    // Delete Firebase Auth account
    await auth.deleteUser(userId);

    // Log admin action
    await logAdminAction(
      context.auth!.uid,
      'deletedUser',
      'user',
      userId,
      { reason }
    );

    return { success: true };
  } catch (error: any) {
    console.error('Error deleting user account:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Override User Subscription
 * Point 240: Grant or modify subscription
 */
export const overrideUserSubscription = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'overrideSubscriptions');

  const { userId, tier, durationDays } = data;

  try {
    const expirationDate = new Date();
    expirationDate.setDate(expirationDate.getDate() + durationDays);

    // Create or update subscription
    const subscriptionRef = firestore.collection('subscriptions').doc();
    await subscriptionRef.set({
      subscriptionId: subscriptionRef.id,
      userId,
      tier,
      status: 'active',
      purchaseDate: admin.firestore.FieldValue.serverTimestamp(),
      expirationDate: admin.firestore.Timestamp.fromDate(expirationDate),
      autoRenew: false,
      platform: 'admin_override',
      price: 0,
      currency: 'USD',
      renewalCount: 0,
      overriddenBy: context.auth!.uid,
      isOverride: true,
    });

    // Update user tier
    await firestore.collection('users').doc(userId).update({
      subscriptionTier: tier,
    });

    // Log admin action
    await logAdminAction(
      context.auth!.uid,
      'overrodeSubscription',
      'subscription',
      subscriptionRef.id,
      { userId, tier, durationDays }
    );

    return {
      success: true,
      subscriptionId: subscriptionRef.id,
      expirationDate,
    };
  } catch (error: any) {
    console.error('Error overriding user subscription:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Adjust User Coins
 * Point 241: Add or remove coins
 */
export const adjustUserCoins = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'adjustCoins');

  const { userId, amount, reason } = data;

  try {
    const coinBalanceRef = firestore.collection('coin_balances').doc(userId);
    const coinBalanceDoc = await coinBalanceRef.get();

    if (!coinBalanceDoc.exists) {
      // Create new coin balance
      await coinBalanceRef.set({
        userId,
        totalCoins: Math.max(0, amount),
        lifetimePurchased: 0,
        lifetimeSpent: 0,
        lifetimeEarned: amount > 0 ? amount : 0,
        coinBatches: amount > 0 ? [{
          batchId: firestore.collection('coin_batches').doc().id,
          initialCoins: amount,
          remainingCoins: amount,
          source: 'admin_grant',
          acquiredAt: admin.firestore.FieldValue.serverTimestamp(),
          expirationDate: admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
          ),
        }] : [],
      });
    } else {
      const currentBalance = coinBalanceDoc.data()!;
      const newTotal = Math.max(0, currentBalance.totalCoins + amount);

      const updateData: any = {
        totalCoins: newTotal,
      };

      if (amount > 0) {
        // Add new batch
        updateData.coinBatches = admin.firestore.FieldValue.arrayUnion({
          batchId: firestore.collection('coin_batches').doc().id,
          initialCoins: amount,
          remainingCoins: amount,
          source: 'admin_grant',
          acquiredAt: admin.firestore.FieldValue.serverTimestamp(),
          expirationDate: admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
          ),
        });
        updateData.lifetimeEarned = admin.firestore.FieldValue.increment(amount);
      }

      await coinBalanceRef.update(updateData);
    }

    // Create transaction record
    await firestore.collection('coin_transactions').add({
      userId,
      type: amount > 0 ? 'credit' : 'debit',
      amount: Math.abs(amount),
      reason: 'admin_adjustment',
      description: reason,
      transactionDate: admin.firestore.FieldValue.serverTimestamp(),
      adminId: context.auth!.uid,
    });

    // Log admin action
    await logAdminAction(
      context.auth!.uid,
      'adjustedCoins',
      'user',
      userId,
      { amount, reason }
    );

    return { success: true };
  } catch (error: any) {
    console.error('Error adjusting user coins:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Send User Notification
 * Point 243: Direct user communication
 */
export const sendUserNotification = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'sendNotifications');

  const { userId, subject, body, type = 'inAppNotification' } = data;

  try {
    // Create notification
    const notificationRef = firestore.collection('admin_communications').doc();
    await notificationRef.set({
      messageId: notificationRef.id,
      userId,
      subject,
      body,
      type,
      sentBy: context.auth!.uid,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      readAt: null,
    });

    // Send push notification if user has FCM token
    const userDoc = await firestore.collection('users').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (fcmToken && type === 'pushNotification') {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: subject,
          body: body,
        },
        data: {
          type: 'admin_message',
          messageId: notificationRef.id,
        },
      });
    }

    // Log admin action
    await logAdminAction(
      context.auth!.uid,
      'sentNotification',
      'user',
      userId,
      { subject, type }
    );

    return { success: true, messageId: notificationRef.id };
  } catch (error: any) {
    console.error('Error sending user notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Impersonate User
 * Point 245: View app as user (for debugging)
 */
export const impersonateUser = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'impersonateUsers');

  const { userId } = data;

  try {
    // Create custom token for impersonation
    const customToken = await auth.createCustomToken(userId, {
      impersonatedBy: context.auth!.uid,
      isImpersonation: true,
    });

    // Log admin action (critical security event)
    await logAdminAction(
      context.auth!.uid,
      'impersonatedUser',
      'user',
      userId,
      { userId, timestamp: new Date().toISOString() }
    );

    return {
      success: true,
      customToken,
      expiresIn: 3600, // 1 hour
    };
  } catch (error: any) {
    console.error('Error impersonating user:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Mass Action - Execute on multiple users
 * Point 242: Bulk operations
 */
export const executeMassAction = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'viewUserProfiles');

  const { operationType, targetUserIds, parameters } = data;

  try {
    const operationRef = firestore.collection('mass_operations').doc();
    await operationRef.set({
      operationId: operationRef.id,
      type: operationType,
      targetUserIds,
      parameters,
      initiatedBy: context.auth!.uid,
      initiatedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
      totalTargets: targetUserIds.length,
      processedItems: 0,
      successCount: 0,
      failureCount: 0,
      results: [],
    });

    // Process in background (queue for processing)
    // This would typically be handled by a separate function
    // triggered by Pub/Sub or Cloud Tasks

    return {
      operationId: operationRef.id,
      status: 'queued',
    };
  } catch (error: any) {
    console.error('Error executing mass action:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Protected email addresses that cannot be bulk-deleted
const PROTECTED_EMAILS = [
  'admin@greengochat.com',
  'support@greengochat.com',
];

/**
 * Bulk Delete Users
 * Parallelized version using auth.deleteUsers() batch API
 */
export const adminBulkDeleteUsers = functions
  .runWith({ timeoutSeconds: 300, memory: '512MB' })
  .https.onCall(async (data, context) => {
    await verifyAdminPermission(context, 'deleteUsers');

    const { userIds, reason } = data;

    if (!Array.isArray(userIds) || userIds.length === 0) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'userIds must be a non-empty array'
      );
    }

    if (userIds.length > 1000) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Cannot delete more than 1000 users at once'
      );
    }

    try {
      // Step 1: Parallel email protection checks in batches of 50
      const protectedUserIds = new Set<string>();
      const checkBatchSize = 50;

      for (let i = 0; i < userIds.length; i += checkBatchSize) {
        const batch = userIds.slice(i, i + checkBatchSize);
        const checkResults = await Promise.allSettled(
          batch.map(async (uid: string) => {
            try {
              const userRecord = await auth.getUser(uid);
              if (userRecord.email && PROTECTED_EMAILS.includes(userRecord.email)) {
                return { uid, protected: true };
              }
              return { uid, protected: false };
            } catch {
              // User doesn't exist in Auth — skip, not protected
              return { uid, protected: false };
            }
          })
        );

        for (const result of checkResults) {
          if (result.status === 'fulfilled' && result.value.protected) {
            protectedUserIds.add(result.value.uid);
          }
        }
      }

      // Filter out protected users
      const deletableUserIds = userIds.filter(
        (uid: string) => !protectedUserIds.has(uid)
      );

      if (deletableUserIds.length === 0) {
        return {
          success: true,
          totalRequested: userIds.length,
          deletedCount: 0,
          skippedProtected: protectedUserIds.size,
          failedCount: 0,
        };
      }

      // Step 2: Soft-delete in Firestore (batch writes, 500 per batch)
      const firestoreBatchSize = 500;
      for (let i = 0; i < deletableUserIds.length; i += firestoreBatchSize) {
        const batch = firestore.batch();
        const chunk = deletableUserIds.slice(i, i + firestoreBatchSize);
        for (const uid of chunk) {
          batch.update(firestore.collection('users').doc(uid), {
            accountStatus: 'deleted',
            deletedBy: context.auth!.uid,
            deletedAt: admin.firestore.FieldValue.serverTimestamp(),
            deletionReason: reason || 'bulk_delete',
          });
        }
        await batch.commit();
      }

      // Step 3: Batch delete from Firebase Auth (up to 1000 per call)
      let deletedCount = 0;
      let failedCount = 0;
      const authBatchSize = 1000;

      for (let i = 0; i < deletableUserIds.length; i += authBatchSize) {
        const chunk = deletableUserIds.slice(i, i + authBatchSize);
        try {
          const result = await auth.deleteUsers(chunk);
          deletedCount += result.successCount;
          failedCount += result.failureCount;
        } catch (error) {
          console.error('Error in auth.deleteUsers batch:', error);
          failedCount += chunk.length;
        }
      }

      // Step 4: Log admin action
      await logAdminAction(
        context.auth!.uid,
        'bulkDeletedUsers',
        'users',
        `bulk_${deletableUserIds.length}`,
        {
          reason,
          totalRequested: userIds.length,
          deletedCount,
          skippedProtected: protectedUserIds.size,
          failedCount,
        }
      );

      return {
        success: true,
        totalRequested: userIds.length,
        deletedCount,
        skippedProtected: protectedUserIds.size,
        failedCount,
      };
    } catch (error: any) {
      console.error('Error in bulk delete:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });
