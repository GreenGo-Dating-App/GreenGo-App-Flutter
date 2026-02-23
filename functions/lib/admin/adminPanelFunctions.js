"use strict";
/**
 * Admin Panel Cloud Functions
 *
 * Functions required by the GreenGo Admin Panel web app:
 * - 2FA authentication (send/verify codes)
 * - Password management
 * - User management (delete, disable)
 * - Email testing
 * - AI Support processing
 * - Support chat triggers
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
exports.cleanupOrphanedAuthUser = exports.sendWelcomeEmail = exports.onSupportMessageCreated = exports.onSupportChatCreated = exports.processAISupportMessage = exports.sendTestEmail = exports.adminSetUserDisabled = exports.adminDeleteUser = exports.forcePasswordChange = exports.sendPasswordResetEmail = exports.adminChangeUserPassword = exports.verify2FACode = exports.send2FACode = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
const auth = admin.auth();
// =============================================================================
// AUTHENTICATION & AUTHORIZATION HELPERS
// =============================================================================
async function verifyAdmin(context) {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const adminDoc = await db.collection('admin_users').doc(context.auth.uid).get();
    if (!adminDoc.exists) {
        throw new functions.https.HttpsError('permission-denied', 'Must be an admin');
    }
    return true;
}
// =============================================================================
// 2FA (TWO-FACTOR AUTHENTICATION) FUNCTIONS
// =============================================================================
/**
 * Send a 2FA verification code to an admin user's email
 */
exports.send2FACode = functions.https.onCall(async (_data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const uid = context.auth.uid;
    console.log(`send2FACode called by uid: ${uid}`);
    const adminDoc = await db.collection('admin_users').doc(uid).get();
    if (!adminDoc.exists) {
        console.error(`send2FACode: uid ${uid} not found in admin_users`);
        throw new functions.https.HttpsError('permission-denied', 'Not an admin user');
    }
    const adminData = adminDoc.data();
    const email = (adminData === null || adminData === void 0 ? void 0 : adminData.email) || ((_a = context.auth.token) === null || _a === void 0 ? void 0 : _a.email);
    console.log(`send2FACode: admin found, email=${email}`);
    if (!email) {
        throw new functions.https.HttpsError('failed-precondition', 'No email associated with this account');
    }
    try {
        const code = String(Math.floor(100000 + Math.random() * 900000));
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000);
        console.log(`send2FACode: writing code to admin_2fa_codes/${uid}`);
        await db.collection('admin_2fa_codes').doc(uid).set({
            code,
            email,
            expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
            attempts: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`send2FACode: code written successfully`);
        const configDoc = await db.doc('app_config/resend_settings').get();
        const resendConfig = configDoc.data();
        const resendApiKey = resendConfig === null || resendConfig === void 0 ? void 0 : resendConfig.apiKey;
        if (!resendApiKey) {
            console.warn('Resend API key not configured. 2FA code stored but email not sent.');
            console.log(`2FA CODE for ${email}: ${code}`);
            return { success: true, emailSent: false, message: 'Code generated (email not configured)' };
        }
        const senderEmail = (resendConfig === null || resendConfig === void 0 ? void 0 : resendConfig.senderEmail) || 'onboarding@resend.dev';
        const senderName = (resendConfig === null || resendConfig === void 0 ? void 0 : resendConfig.senderName) || 'GreenGo Admin';
        const emailResponse = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${resendApiKey}`,
            },
            body: JSON.stringify({
                from: `${senderName} <${senderEmail}>`,
                to: [email],
                subject: 'GreenGo Admin - Verification Code',
                html: `
            <!DOCTYPE html>
            <html>
            <head>
              <style>
                body { font-family: 'Helvetica Neue', Arial, sans-serif; background: #0A0A0A; color: #FFFFFF; padding: 40px; margin: 0; }
                .container { max-width: 500px; margin: 0 auto; background: #1A1A1A; border-radius: 16px; padding: 40px; border: 1px solid #2A2A2A; }
                .header { text-align: center; margin-bottom: 30px; }
                .logo { font-size: 28px; font-weight: bold; background: linear-gradient(135deg, #D4AF37, #FFD700); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
                .code-box { background: #2A2A2A; border-radius: 12px; padding: 30px; margin: 25px 0; text-align: center; border: 2px solid #D4AF37; }
                .code { font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #FFD700; font-family: 'Courier New', monospace; }
                .content { color: rgba(255,255,255,0.8); line-height: 1.6; text-align: center; }
                .warning { color: #FF6B6B; font-size: 13px; margin-top: 20px; }
                .footer { text-align: center; margin-top: 30px; color: rgba(255,255,255,0.4); font-size: 12px; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <div class="logo">GreenGo Admin</div>
                  <p style="color: #D4AF37; margin-top: 5px;">Security Verification</p>
                </div>
                <div class="content">
                  <p>Your verification code is:</p>
                  <div class="code-box">
                    <div class="code">${code}</div>
                  </div>
                  <p>This code expires in <strong>5 minutes</strong>.</p>
                  <p class="warning">If you did not request this code, please change your password immediately.</p>
                </div>
                <div class="footer">
                  <p>&copy; ${new Date().getFullYear()} GreenGo. Unauthorized access is prohibited.</p>
                </div>
              </div>
            </body>
            </html>
          `,
            }),
        });
        const emailResponseText = await emailResponse.text();
        console.log(`Resend response [${emailResponse.status}]:`, emailResponseText);
        if (!emailResponse.ok) {
            console.error('Resend email error:', emailResponseText);
            // Return masked email so user sees the code was generated
            const masked = email.replace(/(.{2})(.*)(@.*)/, '$1***$3');
            return { success: true, emailSent: false, maskedEmail: masked, message: 'Code generated but email failed to send' };
        }
        await db.collection('security_audit_logs').add({
            action: '2FA_CODE_SENT',
            targetUserId: uid,
            email,
            severity: 'medium',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, emailSent: true };
    }
    catch (error) {
        console.error('Error sending 2FA code:', error);
        throw new functions.https.HttpsError('internal', 'Failed to send verification code');
    }
});
/**
 * Verify a 2FA code entered by the admin user
 */
exports.verify2FACode = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const uid = context.auth.uid;
    const { code } = data;
    if (!code) {
        throw new functions.https.HttpsError('invalid-argument', 'Verification code is required');
    }
    try {
        const codeDocRef = db.collection('admin_2fa_codes').doc(uid);
        const codeDoc = await codeDocRef.get();
        if (!codeDoc.exists) {
            return { success: false, error: 'no_code', message: 'No verification code found. Please request a new one.' };
        }
        const codeData = codeDoc.data();
        if (codeData.attempts >= 5) {
            await codeDocRef.delete();
            await db.collection('security_audit_logs').add({
                action: '2FA_MAX_ATTEMPTS',
                targetUserId: uid,
                severity: 'high',
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
            return { success: false, error: 'max_attempts', message: 'Too many attempts. Please request a new code.' };
        }
        const expiresAt = ((_a = codeData.expiresAt) === null || _a === void 0 ? void 0 : _a.toDate) ? codeData.expiresAt.toDate() : new Date(codeData.expiresAt);
        if (new Date() > expiresAt) {
            await codeDocRef.delete();
            return { success: false, error: 'expired', message: 'Code has expired. Please request a new one.' };
        }
        await codeDocRef.update({ attempts: (codeData.attempts || 0) + 1 });
        if (codeData.code !== code.trim()) {
            return { success: false, error: 'invalid_code', message: 'Invalid verification code.' };
        }
        await codeDocRef.delete();
        await db.collection('security_audit_logs').add({
            action: '2FA_VERIFIED',
            targetUserId: uid,
            severity: 'medium',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        console.error('Error verifying 2FA code:', error);
        throw new functions.https.HttpsError('internal', 'Failed to verify code');
    }
});
// =============================================================================
// PASSWORD MANAGEMENT FUNCTIONS
// =============================================================================
/**
 * Change a user's password directly (admin only)
 */
exports.adminChangeUserPassword = functions.https.onCall(async (data, context) => {
    await verifyAdmin(context);
    const { userId, newPassword } = data;
    if (!userId || !newPassword) {
        throw new functions.https.HttpsError('invalid-argument', 'userId and newPassword are required');
    }
    if (newPassword.length < 8) {
        throw new functions.https.HttpsError('invalid-argument', 'Password must be at least 8 characters');
    }
    try {
        await auth.updateUser(userId, { password: newPassword });
        await db.collection('admin_actions').add({
            action: 'change_user_password',
            userId,
            performedBy: context.auth.uid,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        await db.collection('security_audit_logs').add({
            action: 'CHANGE_USER_PASSWORD',
            targetUserId: userId,
            performedBy: context.auth.uid,
            severity: 'critical',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, message: 'Password changed successfully' };
    }
    catch (error) {
        console.error('Error changing password:', error);
        throw new functions.https.HttpsError('internal', error.message || 'Failed to change password');
    }
});
/**
 * Send password reset email to user
 */
exports.sendPasswordResetEmail = functions.https.onCall(async (data, context) => {
    await verifyAdmin(context);
    const { email } = data;
    if (!email) {
        throw new functions.https.HttpsError('invalid-argument', 'email is required');
    }
    try {
        const link = await auth.generatePasswordResetLink(email);
        await db.collection('admin_actions').add({
            action: 'send_password_reset',
            userEmail: email,
            performedBy: context.auth.uid,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, message: `Password reset email sent to ${email}`, link };
    }
    catch (error) {
        console.error('Error sending password reset:', error);
        throw new functions.https.HttpsError('internal', error.message || 'Failed to send password reset email');
    }
});
/**
 * Force user to change password on next login
 */
exports.forcePasswordChange = functions.https.onCall(async (data, context) => {
    await verifyAdmin(context);
    const { userId } = data;
    if (!userId) {
        throw new functions.https.HttpsError('invalid-argument', 'userId is required');
    }
    try {
        await db.collection('profiles').doc(userId).update({
            requirePasswordChange: true,
            passwordChangeRequiredAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, message: 'User will be required to change password on next login' };
    }
    catch (error) {
        console.error('Error forcing password change:', error);
        throw new functions.https.HttpsError('internal', error.message || 'Failed to set password change requirement');
    }
});
// =============================================================================
// USER MANAGEMENT FUNCTIONS
// =============================================================================
/**
 * Delete a user completely (auth + firestore)
 */
exports.adminDeleteUser = functions.https.onCall(async (data, context) => {
    await verifyAdmin(context);
    const { userId, reason } = data;
    if (!userId) {
        throw new functions.https.HttpsError('invalid-argument', 'userId is required');
    }
    try {
        let userEmail = '';
        let authDeleted = false;
        try {
            const userRecord = await auth.getUser(userId);
            userEmail = userRecord.email || '';
        }
        catch (_e) {
            // User might not exist in auth
        }
        try {
            await auth.deleteUser(userId);
            authDeleted = true;
            console.log(`Firebase Auth user ${userId} (${userEmail}) deleted`);
        }
        catch (authError) {
            if (authError.code === 'auth/user-not-found') {
                console.log(`User ${userId} not found in Auth (already deleted)`);
                authDeleted = true;
            }
            else {
                console.error(`FAILED to delete user ${userId} from Auth:`, authError);
            }
        }
        try {
            await db.collection('profiles').doc(userId).delete();
            console.log(`Profile ${userId} hard-deleted`);
        }
        catch (_e) {
            // Profile may not exist
        }
        try {
            await db.collection('users').doc(userId).delete();
        }
        catch (_e) {
            // May not exist
        }
        await db.collection('admin_actions').add({
            action: 'delete_user',
            userId,
            userEmail,
            reason,
            authDeleted,
            performedBy: context.auth.uid,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, authDeleted, message: 'User deleted successfully' };
    }
    catch (error) {
        console.error('Error deleting user:', error);
        throw new functions.https.HttpsError('internal', error.message || 'Failed to delete user');
    }
});
/**
 * Disable/Enable a user account
 */
exports.adminSetUserDisabled = functions.https.onCall(async (data, context) => {
    await verifyAdmin(context);
    const { userId, disabled, reason } = data;
    if (!userId || typeof disabled !== 'boolean') {
        throw new functions.https.HttpsError('invalid-argument', 'userId and disabled are required');
    }
    try {
        await auth.updateUser(userId, { disabled });
        await db.collection('profiles').doc(userId).update({
            status: disabled ? 'suspended' : 'active',
            suspendedAt: disabled ? admin.firestore.FieldValue.serverTimestamp() : null,
            suspendedBy: disabled ? context.auth.uid : null,
            suspensionReason: disabled ? reason : null,
        });
        return { success: true, message: disabled ? 'User suspended' : 'User reactivated' };
    }
    catch (error) {
        console.error('Error setting user disabled:', error);
        throw new functions.https.HttpsError('internal', error.message || 'Failed to update user status');
    }
});
// =============================================================================
// EMAIL FUNCTIONS
// =============================================================================
/**
 * Send test email to verify configuration
 */
exports.sendTestEmail = functions.https.onCall(async (data, context) => {
    await verifyAdmin(context);
    const { email } = data;
    if (!email) {
        throw new functions.https.HttpsError('invalid-argument', 'email is required');
    }
    try {
        const configDoc = await db.doc('app_config/email_settings').get();
        const config = configDoc.data();
        if (!(config === null || config === void 0 ? void 0 : config.enabled)) {
            throw new functions.https.HttpsError('failed-precondition', 'Email is not configured');
        }
        console.log(`Would send test email to ${email} using ${config.provider}`);
        await db.doc('app_config/email_settings').update({
            testEmailSent: admin.firestore.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            message: `Test email would be sent to ${email}. Configure email provider for actual sending.`
        };
    }
    catch (error) {
        console.error('Error sending test email:', error);
        throw new functions.https.HttpsError('internal', error.message || 'Failed to send test email');
    }
});
// =============================================================================
// SUPPORT CHAT AI PROCESSING
// =============================================================================
/**
 * Process support message with AI (triggered by new message)
 */
exports.processAISupportMessage = functions.firestore
    .document('support_messages/{messageId}')
    .onCreate(async (snap) => {
    var _a, _b;
    const message = snap.data();
    if (message.senderType !== 'user') {
        return null;
    }
    try {
        const configDoc = await db.doc('environment_config/production').get();
        const config = configDoc.data();
        const aiSettings = config === null || config === void 0 ? void 0 : config.aiAgent;
        if (!(aiSettings === null || aiSettings === void 0 ? void 0 : aiSettings.enabled) || !(aiSettings === null || aiSettings === void 0 ? void 0 : aiSettings.claudeApiKey)) {
            console.log('AI support is not enabled or configured');
            return null;
        }
        const conversationId = message.conversationId;
        const conversationRef = db.collection('support_chats').doc(conversationId);
        const conversationDoc = await conversationRef.get();
        if (!conversationDoc.exists) {
            console.log('Conversation not found');
            return null;
        }
        const conversation = conversationDoc.data();
        if ((conversation === null || conversation === void 0 ? void 0 : conversation.escalatedFromAI) || (conversation === null || conversation === void 0 ? void 0 : conversation.assignedTo)) {
            console.log('Conversation is escalated or assigned to human');
            return null;
        }
        const messagesSnap = await db.collection('support_messages')
            .where('conversationId', '==', conversationId)
            .orderBy('createdAt', 'asc')
            .limit(20)
            .get();
        const messageHistory = messagesSnap.docs.map((docSnap) => {
            const d = docSnap.data();
            return {
                role: d.senderType === 'admin' ? 'assistant' : 'user',
                content: d.content,
            };
        });
        const escalateKeywords = aiSettings.escalateKeywords || [];
        const shouldEscalate = escalateKeywords.some((keyword) => message.content.toLowerCase().includes(keyword.toLowerCase()));
        if (shouldEscalate) {
            await conversationRef.update({
                status: 'open',
                priority: 'high',
                escalatedFromAI: true,
                escalationReason: 'User requested human support',
                escalatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            await db.collection('support_messages').add({
                conversationId,
                senderId: 'ai-agent',
                senderType: 'admin',
                senderName: aiSettings.agentName || 'Support Assistant',
                content: "I understand you'd like to speak with a human agent. I'm connecting you now. A support team member will respond shortly.",
                messageType: 'text',
                readByAdmin: true,
                readByUser: false,
                isAIGenerated: true,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            return null;
        }
        if (messageHistory.length >= (aiSettings.escalateAfterMessages || 5)) {
            await conversationRef.update({
                status: 'open',
                priority: 'high',
                escalatedFromAI: true,
                escalationReason: 'Maximum AI messages reached',
                escalatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            return null;
        }
        let systemPrompt = aiSettings.agentPersonality || '';
        if (aiSettings.appDescription) {
            systemPrompt += `\n\n## About the App\n${aiSettings.appDescription}`;
        }
        if (aiSettings.faqContent) {
            systemPrompt += `\n\n## FAQ\n${aiSettings.faqContent}`;
        }
        const userId = conversation === null || conversation === void 0 ? void 0 : conversation.userId;
        if (userId && aiSettings.includeUserProfile) {
            const profileDoc = await db.collection('profiles').doc(userId).get();
            if (profileDoc.exists) {
                const profile = profileDoc.data();
                systemPrompt += `\n\n## Current User\n- Name: ${profile === null || profile === void 0 ? void 0 : profile.displayName}\n- Tier: ${(profile === null || profile === void 0 ? void 0 : profile.membershipTier) || 'free'}`;
            }
        }
        const response = await fetch('https://api.anthropic.com/v1/messages', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'x-api-key': aiSettings.claudeApiKey,
                'anthropic-version': '2023-06-01',
            },
            body: JSON.stringify({
                model: aiSettings.claudeModel || 'claude-sonnet-4-20250514',
                max_tokens: aiSettings.maxTokensPerResponse || 500,
                system: systemPrompt,
                messages: messageHistory,
            }),
        });
        if (!response.ok) {
            console.error('Claude API error:', await response.text());
            return null;
        }
        const aiData = await response.json();
        const aiMessage = (_b = (_a = aiData.content) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.text;
        if (!aiMessage) {
            console.error('No response from AI');
            return null;
        }
        await db.collection('support_messages').add({
            conversationId,
            senderId: 'ai-agent',
            senderType: 'admin',
            senderName: aiSettings.agentName || 'Support Assistant',
            content: aiMessage,
            messageType: 'text',
            readByAdmin: true,
            readByUser: false,
            isAIGenerated: true,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await conversationRef.update({
            lastMessage: aiMessage.substring(0, 100),
            lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
            lastMessageBy: 'admin',
            handledByAI: true,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await db.collection('ai_support_logs').add({
            conversationId,
            userMessage: message.content.substring(0, 500),
            aiResponse: aiMessage.substring(0, 500),
            status: 'success',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        return null;
    }
    catch (error) {
        console.error('Error processing AI support message:', error);
        return null;
    }
});
// =============================================================================
// SUPPORT CHAT TRIGGERS
// =============================================================================
/**
 * When a new support chat is created, set default values
 */
exports.onSupportChatCreated = functions.firestore
    .document('support_chats/{chatId}')
    .onCreate(async (snap) => {
    const chat = snap.data();
    const updates = {};
    if (!chat.status)
        updates.status = 'open';
    if (!chat.priority)
        updates.priority = 'normal';
    if (!chat.createdAt)
        updates.createdAt = admin.firestore.FieldValue.serverTimestamp();
    if (!chat.updatedAt)
        updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    if (chat.unreadCount === undefined)
        updates.unreadCount = 1;
    if (chat.messageCount === undefined)
        updates.messageCount = 0;
    if (Object.keys(updates).length > 0) {
        await snap.ref.update(updates);
    }
    return null;
});
/**
 * When a support message is created, update the conversation
 */
exports.onSupportMessageCreated = functions.firestore
    .document('support_messages/{messageId}')
    .onCreate(async (snap) => {
    const message = snap.data();
    const conversationId = message.conversationId;
    if (!conversationId)
        return null;
    const conversationRef = db.collection('support_chats').doc(conversationId);
    const conversationDoc = await conversationRef.get();
    if (!conversationDoc.exists)
        return null;
    const currentData = conversationDoc.data() || {};
    const isFromUser = message.senderType === 'user';
    await conversationRef.update({
        lastMessage: (message.content || '').substring(0, 100),
        lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
        lastMessageBy: message.senderType,
        messageCount: (currentData.messageCount || 0) + 1,
        unreadCount: isFromUser ? (currentData.unreadCount || 0) + 1 : currentData.unreadCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return null;
});
// =============================================================================
// ORPHANED AUTH USER CLEANUP
// =============================================================================
// =============================================================================
// WELCOME EMAIL (via Resend)
// =============================================================================
/**
 * Send a branded welcome email via Resend after user registration.
 * No auth required — called right after registration.
 */
exports.sendWelcomeEmail = functions.https.onCall(async (data, _context) => {
    const { email } = data;
    if (!email || typeof email !== 'string') {
        throw new functions.https.HttpsError('invalid-argument', 'email is required');
    }
    console.log(`sendWelcomeEmail called for: ${email}`);
    try {
        // Read Resend config
        const configDoc = await db.doc('app_config/resend_settings').get();
        const resendConfig = configDoc.data();
        const resendApiKey = resendConfig === null || resendConfig === void 0 ? void 0 : resendConfig.apiKey;
        if (!resendApiKey) {
            console.warn('Resend API key not configured. Welcome email not sent.');
            return { success: true, emailSent: false, message: 'Welcome email not sent (email not configured)' };
        }
        const senderEmail = (resendConfig === null || resendConfig === void 0 ? void 0 : resendConfig.senderEmail) || 'onboarding@resend.dev';
        const senderName = (resendConfig === null || resendConfig === void 0 ? void 0 : resendConfig.senderName) || 'GreenGo';
        const emailResponse = await fetch('https://api.resend.com/emails', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${resendApiKey}`,
            },
            body: JSON.stringify({
                from: `${senderName} <${senderEmail}>`,
                to: [email],
                subject: 'Welcome to GreenGo!',
                html: `
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <style>
                body { font-family: 'Helvetica Neue', Arial, sans-serif; background: #0A0A0A; color: #FFFFFF; padding: 40px; margin: 0; }
                .container { max-width: 500px; margin: 0 auto; background: #1A1A1A; border-radius: 16px; padding: 40px; border: 1px solid #2A2A2A; }
                .header { text-align: center; margin-bottom: 30px; }
                .logo { font-size: 32px; font-weight: bold; background: linear-gradient(135deg, #D4AF37, #FFD700); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
                .content { color: rgba(255,255,255,0.8); line-height: 1.8; text-align: center; }
                .highlight { color: #FFD700; font-weight: bold; }
                .divider { border: none; border-top: 1px solid #2A2A2A; margin: 25px 0; }
                .features { text-align: left; padding: 0 20px; }
                .feature { margin: 12px 0; color: rgba(255,255,255,0.7); }
                .feature-icon { color: #D4AF37; margin-right: 8px; }
                .footer { text-align: center; margin-top: 30px; color: rgba(255,255,255,0.4); font-size: 12px; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <div class="logo">GreenGo</div>
                  <p style="color: #D4AF37; margin-top: 5px; font-size: 16px;">Welcome aboard!</p>
                </div>
                <div class="content">
                  <p>We're thrilled to have you join the <span class="highlight">GreenGo</span> community!</p>
                  <p>Your account has been created successfully. Complete your profile to start connecting with amazing people.</p>
                  <hr class="divider">
                  <div class="features">
                    <div class="feature"><span class="feature-icon">&#10024;</span> Create your unique profile</div>
                    <div class="feature"><span class="feature-icon">&#128154;</span> Discover people near you</div>
                    <div class="feature"><span class="feature-icon">&#128172;</span> Start meaningful conversations</div>
                    <div class="feature"><span class="feature-icon">&#127760;</span> Travel mode to meet people worldwide</div>
                  </div>
                  <hr class="divider">
                  <p style="font-size: 14px; color: rgba(255,255,255,0.5);">Open the app and complete your profile to get started!</p>
                </div>
                <div class="footer">
                  <p>&copy; ${new Date().getFullYear()} GreenGo. All rights reserved.</p>
                </div>
              </div>
            </body>
            </html>
          `,
            }),
        });
        const emailResponseText = await emailResponse.text();
        console.log(`Resend welcome email response [${emailResponse.status}]:`, emailResponseText);
        if (!emailResponse.ok) {
            console.error('Resend welcome email error:', emailResponseText);
            return { success: true, emailSent: false, message: 'Welcome email failed to send' };
        }
        return { success: true, emailSent: true };
    }
    catch (error) {
        console.error('Error sending welcome email:', error);
        throw new functions.https.HttpsError('internal', 'Failed to send welcome email');
    }
});
// =============================================================================
// ORPHANED AUTH USER CLEANUP
// =============================================================================
exports.cleanupOrphanedAuthUser = functions.https.onCall(async (data, _context) => {
    const { email } = data;
    if (!email || typeof email !== 'string') {
        throw new functions.https.HttpsError('invalid-argument', 'email is required');
    }
    try {
        // Look up the Auth user by email
        let userRecord;
        try {
            userRecord = await auth.getUserByEmail(email);
        }
        catch (err) {
            if (err.code === 'auth/user-not-found') {
                return { success: true, cleaned: false, reason: 'no-auth-user' };
            }
            throw err;
        }
        const userId = userRecord.uid;
        // Check if user exists in any Firestore collection (profiles, admin_users, users)
        const [profileDoc, adminDoc, userDoc] = await Promise.all([
            db.collection('profiles').doc(userId).get(),
            db.collection('admin_users').doc(userId).get(),
            db.collection('users').doc(userId).get(),
        ]);
        if (profileDoc.exists || adminDoc.exists || userDoc.exists) {
            // User exists in Firestore — this is NOT an orphan, do not delete
            throw new functions.https.HttpsError('failed-precondition', 'This email belongs to an active account');
        }
        // No Firestore data exists — this is an orphaned Auth user, safe to delete
        await auth.deleteUser(userId);
        console.log(`Cleaned up orphaned Auth user: ${userId} (${email})`);
        // Log the cleanup action
        await db.collection('admin_actions').add({
            action: 'cleanup_orphaned_auth',
            userId,
            userEmail: email,
            reason: 'No profile found during registration attempt',
            performedBy: 'system',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, cleaned: true };
    }
    catch (error) {
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        console.error('Error cleaning up orphaned auth user:', error);
        throw new functions.https.HttpsError('internal', error.message || 'Failed to cleanup');
    }
});
//# sourceMappingURL=adminPanelFunctions.js.map