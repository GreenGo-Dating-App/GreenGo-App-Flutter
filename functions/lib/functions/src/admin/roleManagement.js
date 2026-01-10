"use strict";
/**
 * Role-Based Access Control (RBAC) Cloud Functions
 * Point 227: Admin role and permission management
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.recordAdminLogin = exports.getAdminUsers = exports.deactivateAdminUser = exports.updateAdminPermissions = exports.updateAdminRole = exports.createAdminUser = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const auth = admin.auth();
const firestore = admin.firestore();
/**
 * Create Admin User
 * Point 227: Create new admin with role assignment
 */
exports.createAdminUser = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    // Only super admins can create admin users
    const customClaims = context.auth.token;
    if (!customClaims.superAdmin && !customClaims.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Only super admins can create admin users');
    }
    const { email, displayName, role } = data;
    try {
        // Validate role
        const validRoles = ['superAdmin', 'moderator', 'support', 'analyst'];
        if (!validRoles.includes(role)) {
            throw new Error('Invalid admin role');
        }
        // Create user account
        const userRecord = await auth.createUser({
            email,
            displayName,
            emailVerified: true,
        });
        // Set custom claims based on role
        const customClaims = {};
        customClaims[role] = true;
        if (role === 'superAdmin') {
            customClaims.admin = true;
            customClaims.moderator = true;
            customClaims.support = true;
            customClaims.analyst = true;
        }
        await auth.setCustomUserClaims(userRecord.uid, customClaims);
        // Get default permissions for role
        const permissions = getDefaultPermissions(role);
        // Create admin profile
        await firestore.collection('admins').doc(userRecord.uid).set({
            userId: userRecord.uid,
            email,
            displayName,
            role,
            permissions,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastLoginAt: null,
            isActive: true,
        });
        // Log admin action
        await firestore.collection('admin_audit_log').add({
            adminId: context.auth.uid,
            action: 'createdAdmin',
            targetType: 'admin',
            targetId: userRecord.uid,
            details: { email, displayName, role },
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        return {
            userId: userRecord.uid,
            email,
            displayName,
            role,
            success: true,
        };
    }
    catch (error) {
        console.error('Error creating admin user:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Get default permissions for a role
 */
function getDefaultPermissions(role) {
    switch (role) {
        case 'superAdmin':
            return [
                'viewDashboard',
                'viewAnalytics',
                'exportData',
                'viewUserProfiles',
                'editUserProfiles',
                'suspendUsers',
                'banUsers',
                'deleteUsers',
                'impersonateUsers',
                'viewSubscriptions',
                'overrideSubscriptions',
                'refundSubscriptions',
                'adjustCoins',
                'grantCoins',
                'viewReports',
                'reviewContent',
                'issueWarnings',
                'removeContent',
                'sendNotifications',
                'sendEmails',
                'broadcastMessages',
                'manageAdmins',
                'viewAuditLog',
                'systemSettings',
            ];
        case 'moderator':
            return [
                'viewReports',
                'reviewContent',
                'issueWarnings',
                'suspendUsers',
                'banUsers',
                'viewUserProfiles',
            ];
        case 'support':
            return [
                'viewUserProfiles',
                'editUserProfiles',
                'viewSubscriptions',
                'overrideSubscriptions',
                'adjustCoins',
                'sendNotifications',
            ];
        case 'analyst':
            return ['viewDashboard', 'viewAnalytics', 'exportData'];
        default:
            return [];
    }
}
/**
 * Update Admin Role
 * Point 227: Change admin role and permissions
 */
exports.updateAdminRole = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    // Only super admins can update roles
    const customClaims = context.auth.token;
    if (!customClaims.superAdmin) {
        throw new functions.https.HttpsError('permission-denied', 'Only super admins can update admin roles');
    }
    const { adminId, newRole } = data;
    try {
        // Validate role
        const validRoles = ['superAdmin', 'moderator', 'support', 'analyst'];
        if (!validRoles.includes(newRole)) {
            throw new Error('Invalid admin role');
        }
        // Don't allow changing own role
        if (adminId === context.auth.uid) {
            throw new Error('Cannot change your own role');
        }
        // Set new custom claims
        const newCustomClaims = {};
        newCustomClaims[newRole] = true;
        if (newRole === 'superAdmin') {
            newCustomClaims.admin = true;
            newCustomClaims.moderator = true;
            newCustomClaims.support = true;
            newCustomClaims.analyst = true;
        }
        await auth.setCustomUserClaims(adminId, newCustomClaims);
        // Update admin profile
        const newPermissions = getDefaultPermissions(newRole);
        await firestore.collection('admins').doc(adminId).update({
            role: newRole,
            permissions: newPermissions,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Log admin action
        await firestore.collection('admin_audit_log').add({
            adminId: context.auth.uid,
            action: 'modifiedAdmin',
            targetType: 'admin',
            targetId: adminId,
            details: { newRole, newPermissions },
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        console.error('Error updating admin role:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Update Admin Permissions
 * Point 227: Grant or revoke specific permissions
 */
exports.updateAdminPermissions = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    // Only super admins can update permissions
    const customClaims = context.auth.token;
    if (!customClaims.superAdmin) {
        throw new functions.https.HttpsError('permission-denied', 'Only super admins can update permissions');
    }
    const { adminId, permissions } = data;
    try {
        await firestore.collection('admins').doc(adminId).update({
            permissions,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Log admin action
        await firestore.collection('admin_audit_log').add({
            adminId: context.auth.uid,
            action: 'modifiedAdmin',
            targetType: 'admin',
            targetId: adminId,
            details: { permissions },
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        console.error('Error updating admin permissions:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Deactivate Admin User
 * Point 227: Disable admin access
 */
exports.deactivateAdminUser = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    // Only super admins can deactivate admins
    const customClaims = context.auth.token;
    if (!customClaims.superAdmin) {
        throw new functions.https.HttpsError('permission-denied', 'Only super admins can deactivate admin users');
    }
    const { adminId } = data;
    try {
        // Don't allow deactivating self
        if (adminId === context.auth.uid) {
            throw new Error('Cannot deactivate your own account');
        }
        // Disable the user account
        await auth.updateUser(adminId, {
            disabled: true,
        });
        // Update admin profile
        await firestore.collection('admins').doc(adminId).update({
            isActive: false,
            deactivatedAt: admin.firestore.FieldValue.serverTimestamp(),
            deactivatedBy: context.auth.uid,
        });
        // Log admin action
        await firestore.collection('admin_audit_log').add({
            adminId: context.auth.uid,
            action: 'deletedAdmin',
            targetType: 'admin',
            targetId: adminId,
            details: { reason: 'Deactivated by admin' },
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        console.error('Error deactivating admin user:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Get Admin Users List
 * Point 227: View all admin users
 */
exports.getAdminUsers = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    // Check if user has admin access
    const customClaims = context.auth.token;
    if (!customClaims.admin && !customClaims.superAdmin) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can view admin users');
    }
    try {
        const adminsSnapshot = await firestore
            .collection('admins')
            .orderBy('createdAt', 'desc')
            .get();
        const admins = adminsSnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                userId: data.userId,
                email: data.email,
                displayName: data.displayName,
                role: data.role,
                permissions: data.permissions,
                createdAt: data.createdAt,
                lastLoginAt: data.lastLoginAt,
                isActive: data.isActive,
            };
        });
        return { admins };
    }
    catch (error) {
        console.error('Error getting admin users:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Record Admin Login
 * Trigger function to track admin logins
 */
exports.recordAdminLogin = functions.auth.user().onCreate(async (user) => {
    // Check if user has admin custom claims
    const userRecord = await auth.getUser(user.uid);
    const customClaims = userRecord.customClaims || {};
    if (customClaims.admin ||
        customClaims.superAdmin ||
        customClaims.moderator ||
        customClaims.support ||
        customClaims.analyst) {
        const adminDoc = await firestore.collection('admins').doc(user.uid).get();
        if (adminDoc.exists) {
            await firestore.collection('admins').doc(user.uid).update({
                lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    }
});
//# sourceMappingURL=roleManagement.js.map