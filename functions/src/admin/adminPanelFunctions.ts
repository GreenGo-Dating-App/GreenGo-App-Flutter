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

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const auth = admin.auth();

// =============================================================================
// AUTHENTICATION & AUTHORIZATION HELPERS
// =============================================================================

async function verifyAdmin(context: functions.https.CallableContext): Promise<boolean> {
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
export const send2FACode = functions.https.onCall(
  async (_data: any, context: functions.https.CallableContext) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const uid = context.auth.uid;

    const adminDoc = await db.collection('admin_users').doc(uid).get();
    if (!adminDoc.exists) {
      throw new functions.https.HttpsError('permission-denied', 'Not an admin user');
    }

    const adminData = adminDoc.data();
    const email = adminData?.email || context.auth.token?.email;

    if (!email) {
      throw new functions.https.HttpsError('failed-precondition', 'No email associated with this account');
    }

    try {
      const code = String(Math.floor(100000 + Math.random() * 900000));
      const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

      await db.collection('admin_2fa_codes').doc(uid).set({
        code,
        email,
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        attempts: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const configDoc = await db.doc('app_config/resend_settings').get();
      const resendConfig = configDoc.data();
      const resendApiKey = resendConfig?.apiKey;

      if (!resendApiKey) {
        console.warn('Resend API key not configured. 2FA code stored but email not sent.');
        console.log(`2FA CODE for ${email}: ${code}`);
        return { success: true, emailSent: false, message: 'Code generated (email not configured)' };
      }

      const senderEmail = resendConfig?.senderEmail || 'onboarding@resend.dev';
      const senderName = resendConfig?.senderName || 'GreenGo Admin';

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

      if (!emailResponse.ok) {
        const errText = await emailResponse.text();
        console.error('Resend email error:', errText);
        return { success: true, emailSent: false, message: 'Code generated but email failed to send' };
      }

      await db.collection('security_audit_logs').add({
        action: '2FA_CODE_SENT',
        targetUserId: uid,
        email,
        severity: 'medium',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, emailSent: true };
    } catch (error: any) {
      console.error('Error sending 2FA code:', error);
      throw new functions.https.HttpsError('internal', 'Failed to send verification code');
    }
  }
);

/**
 * Verify a 2FA code entered by the admin user
 */
export const verify2FACode = functions.https.onCall(
  async (data: any, context: functions.https.CallableContext) => {
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

      const codeData = codeDoc.data()!;

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

      const expiresAt = codeData.expiresAt?.toDate ? codeData.expiresAt.toDate() : new Date(codeData.expiresAt);
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
    } catch (error: any) {
      console.error('Error verifying 2FA code:', error);
      throw new functions.https.HttpsError('internal', 'Failed to verify code');
    }
  }
);

// =============================================================================
// PASSWORD MANAGEMENT FUNCTIONS
// =============================================================================

/**
 * Change a user's password directly (admin only)
 */
export const adminChangeUserPassword = functions.https.onCall(
  async (data: any, context: functions.https.CallableContext) => {
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
        performedBy: context.auth!.uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      await db.collection('security_audit_logs').add({
        action: 'CHANGE_USER_PASSWORD',
        targetUserId: userId,
        performedBy: context.auth!.uid,
        severity: 'critical',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, message: 'Password changed successfully' };
    } catch (error: any) {
      console.error('Error changing password:', error);
      throw new functions.https.HttpsError('internal', error.message || 'Failed to change password');
    }
  }
);

/**
 * Send password reset email to user
 */
export const sendPasswordResetEmail = functions.https.onCall(
  async (data: any, context: functions.https.CallableContext) => {
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
        performedBy: context.auth!.uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, message: `Password reset email sent to ${email}`, link };
    } catch (error: any) {
      console.error('Error sending password reset:', error);
      throw new functions.https.HttpsError('internal', error.message || 'Failed to send password reset email');
    }
  }
);

/**
 * Force user to change password on next login
 */
export const forcePasswordChange = functions.https.onCall(
  async (data: any, context: functions.https.CallableContext) => {
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
    } catch (error: any) {
      console.error('Error forcing password change:', error);
      throw new functions.https.HttpsError('internal', error.message || 'Failed to set password change requirement');
    }
  }
);

// =============================================================================
// USER MANAGEMENT FUNCTIONS
// =============================================================================

/**
 * Delete a user completely (auth + firestore)
 */
export const adminDeleteUser = functions.https.onCall(
  async (data: any, context: functions.https.CallableContext) => {
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
      } catch (_e) {
        // User might not exist in auth
      }

      try {
        await auth.deleteUser(userId);
        authDeleted = true;
        console.log(`Firebase Auth user ${userId} (${userEmail}) deleted`);
      } catch (authError: any) {
        if (authError.code === 'auth/user-not-found') {
          console.log(`User ${userId} not found in Auth (already deleted)`);
          authDeleted = true;
        } else {
          console.error(`FAILED to delete user ${userId} from Auth:`, authError);
        }
      }

      try {
        await db.collection('profiles').doc(userId).delete();
        console.log(`Profile ${userId} hard-deleted`);
      } catch (_e) {
        // Profile may not exist
      }

      try {
        await db.collection('users').doc(userId).delete();
      } catch (_e) {
        // May not exist
      }

      await db.collection('admin_actions').add({
        action: 'delete_user',
        userId,
        userEmail,
        reason,
        authDeleted,
        performedBy: context.auth!.uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, authDeleted, message: 'User deleted successfully' };
    } catch (error: any) {
      console.error('Error deleting user:', error);
      throw new functions.https.HttpsError('internal', error.message || 'Failed to delete user');
    }
  }
);

/**
 * Disable/Enable a user account
 */
export const adminSetUserDisabled = functions.https.onCall(
  async (data: any, context: functions.https.CallableContext) => {
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
        suspendedBy: disabled ? context.auth!.uid : null,
        suspensionReason: disabled ? reason : null,
      });

      return { success: true, message: disabled ? 'User suspended' : 'User reactivated' };
    } catch (error: any) {
      console.error('Error setting user disabled:', error);
      throw new functions.https.HttpsError('internal', error.message || 'Failed to update user status');
    }
  }
);

// =============================================================================
// EMAIL FUNCTIONS
// =============================================================================

/**
 * Send test email to verify configuration
 */
export const sendTestEmail = functions.https.onCall(
  async (data: any, context: functions.https.CallableContext) => {
    await verifyAdmin(context);

    const { email } = data;

    if (!email) {
      throw new functions.https.HttpsError('invalid-argument', 'email is required');
    }

    try {
      const configDoc = await db.doc('app_config/email_settings').get();
      const config = configDoc.data();

      if (!config?.enabled) {
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
    } catch (error: any) {
      console.error('Error sending test email:', error);
      throw new functions.https.HttpsError('internal', error.message || 'Failed to send test email');
    }
  }
);

// =============================================================================
// SUPPORT CHAT AI PROCESSING
// =============================================================================

/**
 * Process support message with AI (triggered by new message)
 */
export const processAISupportMessage = functions.firestore
  .document('support_messages/{messageId}')
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot) => {
    const message = snap.data();

    if (message.senderType !== 'user') {
      return null;
    }

    try {
      const configDoc = await db.doc('environment_config/production').get();
      const config = configDoc.data();
      const aiSettings = config?.aiAgent;

      if (!aiSettings?.enabled || !aiSettings?.claudeApiKey) {
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

      if (conversation?.escalatedFromAI || conversation?.assignedTo) {
        console.log('Conversation is escalated or assigned to human');
        return null;
      }

      const messagesSnap = await db.collection('support_messages')
        .where('conversationId', '==', conversationId)
        .orderBy('createdAt', 'asc')
        .limit(20)
        .get();

      const messageHistory = messagesSnap.docs.map((docSnap: admin.firestore.QueryDocumentSnapshot) => {
        const d = docSnap.data();
        return {
          role: d.senderType === 'admin' ? 'assistant' : 'user',
          content: d.content,
        };
      });

      const escalateKeywords = aiSettings.escalateKeywords || [];
      const shouldEscalate = escalateKeywords.some((keyword: string) =>
        message.content.toLowerCase().includes(keyword.toLowerCase())
      );

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

      const userId = conversation?.userId;
      if (userId && aiSettings.includeUserProfile) {
        const profileDoc = await db.collection('profiles').doc(userId).get();
        if (profileDoc.exists) {
          const profile = profileDoc.data();
          systemPrompt += `\n\n## Current User\n- Name: ${profile?.displayName}\n- Tier: ${profile?.membershipTier || 'free'}`;
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
      const aiMessage = aiData.content?.[0]?.text;

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
    } catch (error) {
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
export const onSupportChatCreated = functions.firestore
  .document('support_chats/{chatId}')
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot) => {
    const chat = snap.data();

    const updates: Record<string, any> = {};

    if (!chat.status) updates.status = 'open';
    if (!chat.priority) updates.priority = 'normal';
    if (!chat.createdAt) updates.createdAt = admin.firestore.FieldValue.serverTimestamp();
    if (!chat.updatedAt) updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    if (chat.unreadCount === undefined) updates.unreadCount = 1;
    if (chat.messageCount === undefined) updates.messageCount = 0;

    if (Object.keys(updates).length > 0) {
      await snap.ref.update(updates);
    }

    return null;
  });

/**
 * When a support message is created, update the conversation
 */
export const onSupportMessageCreated = functions.firestore
  .document('support_messages/{messageId}')
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot) => {
    const message = snap.data();
    const conversationId = message.conversationId;

    if (!conversationId) return null;

    const conversationRef = db.collection('support_chats').doc(conversationId);
    const conversationDoc = await conversationRef.get();

    if (!conversationDoc.exists) return null;

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

/**
 * Clean up an orphaned Firebase Auth user (has Auth entry but no Firestore profile).
 * Called during registration when "email-already-in-use" error occurs.
 * Does NOT require authentication (called before user can sign in).
 */
export const cleanupOrphanedAuthUser = functions.https.onCall(
  async (data: any, _context: functions.https.CallableContext) => {
    const { email } = data;

    if (!email || typeof email !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'email is required');
    }

    try {
      // Look up the Auth user by email
      let userRecord;
      try {
        userRecord = await auth.getUserByEmail(email);
      } catch (err: any) {
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
        throw new functions.https.HttpsError(
          'failed-precondition',
          'This email belongs to an active account'
        );
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
    } catch (error: any) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      console.error('Error cleaning up orphaned auth user:', error);
      throw new functions.https.HttpsError('internal', error.message || 'Failed to cleanup');
    }
  }
);
