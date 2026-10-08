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

import * as functions from 'firebase-functions/v1';
import * as crypto from 'crypto';
import { welcomeEmailCopy } from '../emails/welcomeEmailCopy';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import { requireAdmin, adminRoleFromDoc, AdminRole, SUPER_ADMIN_ONLY, SUPPORT_ROLES } from '../shared/adminAuth';
import { setAdmin2faClaim } from './adminClaims';
import { scrubPII, redact } from '../shared/redact';
import { applyProfileAgeGate } from '../auth/ageGate';
import { hasWithdrawnAiConsent } from '../shared/aiConsent';

const db = admin.firestore();
const auth = admin.auth();

// =============================================================================
// AUTHENTICATION & AUTHORIZATION HELPERS
// =============================================================================

/**
 * Thin wrappers over the central requireAdmin() (shared/adminAuth.ts):
 * admin = admin_users doc / adminRole claim; optional role restriction.
 */
async function verifyAdmin(
  context: functions.https.CallableContext,
  allowedRoles?: readonly AdminRole[]
): Promise<boolean> {
  await requireAdmin(context.auth as any, allowedRoles);
  return true;
}

/**
 * Security audit H-07: any `admin_users` member (support, analyst…) could call
 * the most dangerous actions. These now require the superAdmin role.
 */
async function verifySuperAdmin(context: functions.https.CallableContext): Promise<void> {
  await requireAdmin(context.auth as any, SUPER_ADMIN_ONLY);
}

/** True when the target uid is a superAdmin (never a target for other admins' actions). */
async function isSuperAdminUid(uid: string): Promise<boolean> {
  const doc = await db.collection('admin_users').doc(uid).get();
  return doc.exists && doc.data()?.role === 'superAdmin';
}

// =============================================================================
// 2FA (TWO-FACTOR AUTHENTICATION) FUNCTIONS
// =============================================================================

/**
 * Send a 2FA verification code to an admin user's email
 */
export const send2FACode = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("send2FACode", async (_data: any, context: functions.https.CallableContext) => {
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
    const email = adminData?.email || context.auth.token?.email;
    console.log(`send2FACode: admin found, email=${redact(email)}`);

    if (!email) {
      throw new functions.https.HttpsError('failed-precondition', 'No email associated with this account');
    }

    try {
      // Cryptographically secure (Math.random is predictable).
      const code = String(crypto.randomInt(100000, 1000000));
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
      const resendApiKey = resendConfig?.apiKey;

      if (!resendApiKey) {
        // Never log the code itself: anyone with log access could bypass 2FA.
        console.warn('Resend API key not configured. 2FA code stored but email not sent.');
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
    } catch (error: any) {
      console.error('Error sending 2FA code:', error);
      throw new functions.https.HttpsError('internal', 'Failed to send verification code');
    }
  })
);

/**
 * Verify a 2FA code entered by the admin user
 */
export const verify2FACode = functions
  .runWith({ memory: '512MB' })
  .https.onCall(
  monitored("verify2FACode", async (data: any, context: functions.https.CallableContext) => {
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

      // H-07: bind the verification to the server. The `admin2faUntil` claim
      // (8h, bound to this session's auth_time) is what requireAdmin checks for
      // dangerous actions; the panel refreshes its ID token (getIdToken(true))
      // right after this call so the claim is present.
      let admin2faUntil: number | null = null;
      if (await adminRoleFromDoc(uid)) {
        try {
          admin2faUntil = await setAdmin2faClaim(uid, context.auth.token?.auth_time);
        } catch (claimError: any) {
          console.error('verify2FACode: could not set the 2FA claim:', claimError?.message || claimError);
        }
      }

      await db.collection('security_audit_logs').add({
        action: '2FA_VERIFIED',
        targetUserId: uid,
        severity: 'medium',
        claimSet: admin2faUntil !== null,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, admin2faUntil };
    } catch (error: any) {
      console.error('Error verifying 2FA code:', error);
      throw new functions.https.HttpsError('internal', 'Failed to verify code');
    }
  })
);

// =============================================================================
// PASSWORD MANAGEMENT FUNCTIONS
// =============================================================================

/**
 * Change a user's password directly (admin only)
 */
export const adminChangeUserPassword = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("adminChangeUserPassword", async (data: any, context: functions.https.CallableContext) => {
    await verifySuperAdmin(context);

    const { userId, newPassword } = data;

    if (!userId || !newPassword) {
      throw new functions.https.HttpsError('invalid-argument', 'userId and newPassword are required');
    }

    // A superAdmin account is never reset through the panel (account takeover path).
    if (userId !== context.auth!.uid && await isSuperAdminUid(userId)) {
      throw new functions.https.HttpsError('permission-denied', 'Cannot change another superAdmin password');
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
  })
);

/**
 * Send password reset email to user
 */
export const sendPasswordResetEmail = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("sendPasswordResetEmail", async (data: any, context: functions.https.CallableContext) => {
    await verifyAdmin(context, SUPPORT_ROLES);

    const { email } = data;

    if (!email) {
      throw new functions.https.HttpsError('invalid-argument', 'email is required');
    }

    try {
      const actionCodeSettings = {
        url: 'https://greengo-chat.firebaseapp.com',
        handleCodeInApp: false,
      };
      const link = await auth.generatePasswordResetLink(email, actionCodeSettings);

      // Security audit H-07: the link used to be RETURNED to the caller (an
      // admin could take over the account) and no email was ever sent. Now the
      // link goes only to the account owner's inbox.
      const delivery = await deliverResetEmail(email, link);

      await db.collection('admin_actions').add({
        action: 'send_password_reset',
        userEmail: email,
        emailSent: delivery.emailSent,
        performedBy: context.auth!.uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: delivery.emailSent
          ? `Password reset email sent to ${email}`
          : `Password reset email could not be sent to ${email}`,
      };
    } catch (error: any) {
      console.error('Error sending password reset:', error);
      throw new functions.https.HttpsError('internal', error.message || 'Failed to send password reset email');
    }
  })
);

/**
 * Force user to change password on next login
 */
export const forcePasswordChange = functions
  .runWith({ memory: '512MB' })
  .https.onCall(
  monitored("forcePasswordChange", async (data: any, context: functions.https.CallableContext) => {
    await verifySuperAdmin(context);

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
  })
);

// =============================================================================
// USER MANAGEMENT FUNCTIONS
// =============================================================================

/**
 * Delete a user completely (auth + firestore)
 */
export const adminDeleteUser = functions
  .runWith({ memory: '512MB' })
  .https.onCall(
  monitored("adminDeleteUser", async (data: any, context: functions.https.CallableContext) => {
    await verifySuperAdmin(context);

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
        console.log(`Firebase Auth user ${userId} (${redact(userEmail)}) deleted`);
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
  })
);

/**
 * Disable/Enable a user account
 */
export const adminSetUserDisabled = functions
  .runWith({ memory: '512MB' })
  .https.onCall(
  monitored("adminSetUserDisabled", async (data: any, context: functions.https.CallableContext) => {
    await verifySuperAdmin(context);

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
  })
);

// =============================================================================
// EMAIL FUNCTIONS
// =============================================================================

/**
 * Send test email to verify configuration
 */
export const sendTestEmail = functions
  .runWith({ memory: '512MB' })
  .https.onCall(
  monitored("sendTestEmail", async (data: any, context: functions.https.CallableContext) => {
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

      console.log(`Would send test email to ${redact(email)} using ${config.provider}`);

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
  })
);

// =============================================================================
// SUPPORT CHAT AI PROCESSING
// =============================================================================

/**
 * Process support message with AI (triggered by new message)
 */
export const AI_SUPPORT_DAILY_LIMIT = 20;
export const AI_SUPPORT_MIN_INTERVAL_MS = 10_000;

/**
 * H-04: per-user AI reply budget (ai_support_rate/{uid}). Returns false when
 * the user is over 20 replies/day or replied to less than 10s ago; the
 * message is then left for a human agent (no Anthropic call).
 */
async function reserveAISupportReply(uid: string): Promise<boolean> {
  const ref = db.collection('ai_support_rate').doc(uid);
  const now = Date.now();
  const day = new Date(now).toISOString().slice(0, 10);
  return db.runTransaction(async (tx) => {
    const d = (await tx.get(ref)).data() || {};
    const count = d.day === day ? Number(d.count) || 0 : 0;
    const lastAt = Number(d.lastAtMs) || 0;
    if (count >= AI_SUPPORT_DAILY_LIMIT || now - lastAt < AI_SUPPORT_MIN_INTERVAL_MS) return false;
    tx.set(ref, { day, count: count + 1, lastAtMs: now }, { merge: true });
    return true;
  });
}

export const processAISupportMessage = functions
  .runWith({ memory: '512MB' })
  .firestore
  .document('support_messages/{messageId}')
  .onCreate(monitored("processAISupportMessage", async (snap: functions.firestore.QueryDocumentSnapshot) => {
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

      // H-04: only the chat owner's own messages may trigger an AI reply
      // (support_messages is writable by any signed-in user), and each owner
      // has a small AI budget. Over budget -> leave it for a human agent.
      const ownerUid: string | undefined = conversation?.userId;
      if (!ownerUid || (message.senderId && message.senderId !== ownerUid)) {
        console.log('Support message not from the chat owner; no AI reply');
        return null;
      }
      // The owner turned "AI services" OFF (consents/{uid}.ai_processing
      // withdrawn): no AI reply, the chat stays with human agents.
      if (await hasWithdrawnAiConsent(ownerUid)) {
        console.log('Owner turned AI services off; leaving for human agents');
        await db.collection('ai_support_logs').add({
          conversationId,
          status: 'ai_consent_withdrawn',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        return null;
      }
      if (!(await reserveAISupportReply(ownerUid))) {
        console.log('AI support rate limit reached; leaving for human agents');
        await db.collection('ai_support_logs').add({
          conversationId,
          status: 'rate_limited',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
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
          // H-04: no email / phone / exact location / DOB to the model.
          content: scrubPII(d.content),
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
          // H-04: first name + tier only; nothing that identifies or locates.
          const firstName = scrubPII(String(profile?.displayName ?? '').trim().split(/\s+/)[0] ?? '');
          systemPrompt += `\n\n## Current User\n- Name: ${firstName}\n- Tier: ${profile?.membershipTier || 'free'}`;
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
  }));

// =============================================================================
// SUPPORT CHAT TRIGGERS
// =============================================================================

/**
 * When a new support chat is created, set default values
 */
export const onSupportChatCreated = functions
  .runWith({ memory: '512MB' })
  .firestore
  .document('support_chats/{chatId}')
  .onCreate(monitored("onSupportChatCreated", async (snap: functions.firestore.QueryDocumentSnapshot) => {
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
  }));

/**
 * When a support message is created, update the conversation
 * and send push notification to the user if the message is from admin
 */
export const onSupportMessageCreated = functions
  .runWith({ memory: '512MB' })
  .firestore
  .document('support_messages/{messageId}')
  .onCreate(monitored("onSupportMessageCreated", async (snap: functions.firestore.QueryDocumentSnapshot) => {
    const message = snap.data();
    const conversationId = message.conversationId;

    if (!conversationId) return null;

    const conversationRef = db.collection('support_chats').doc(conversationId);
    const conversationDoc = await conversationRef.get();

    if (!conversationDoc.exists) return null;

    const currentData = conversationDoc.data() || {};
    const isFromUser = message.senderType === 'user';
    const isFromAdmin = message.senderType === 'admin';

    await conversationRef.update({
      lastMessage: (message.content || '').substring(0, 100),
      lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
      lastMessageBy: message.senderType,
      messageCount: (currentData.messageCount || 0) + 1,
      unreadCount: isFromUser ? (currentData.unreadCount || 0) + 1 : currentData.unreadCount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send push notification to the user when admin replies
    if (isFromAdmin && currentData.userId) {
      try {
        const userId = currentData.userId;

        // Get user's FCM token (check both 'users' and 'profiles' collections)
        let fcmToken: string | null = null;
        const userDoc = await db.collection('users').doc(userId).get();
        if (userDoc.exists) {
          fcmToken = userDoc.data()?.fcmToken || null;
        }
        if (!fcmToken) {
          const profileDoc = await db.collection('profiles').doc(userId).get();
          if (profileDoc.exists) {
            fcmToken = profileDoc.data()?.fcmToken || null;
          }
        }

        if (fcmToken) {
          const contentPreview = (message.content || '').length > 100
            ? (message.content || '').substring(0, 97) + '...'
            : (message.content || '');

          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: 'GreenGo Support',
              body: contentPreview,
            },
            data: {
              type: 'support_message',
              action: 'support_message',
              conversationId: conversationId,
              senderName: message.senderName || 'Support',
            },
            android: {
              priority: 'high',
              notification: {
                channelId: 'greengo_notifications',
                priority: 'high' as any,
                sound: 'default',
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                },
              },
            },
          });

          console.log(`Support reply push notification sent to user ${userId}`);
        } else {
          console.log(`No FCM token found for user ${userId} — skipping push`);
        }

        // Also create an in-app notification in the notifications collection.
        // The support-reply push was already sent above (when a token exists),
        // so stamp pushSent to skip the onNotificationCreatedPush parity trigger.
        await db.collection('notifications').add({
          userId: userId,
          type: 'new_message',
          title: 'GreenGo Support',
          message: (message.content || '').length > 100
            ? (message.content || '').substring(0, 97) + '...'
            : (message.content || ''),
          body: (message.content || '').length > 100
            ? (message.content || '').substring(0, 97) + '...'
            : (message.content || ''),
          data: {
            action: 'support_message',
            conversationId: conversationId,
            senderName: message.senderName || 'Support',
          },
          isRead: false,
          read: false,
          pushSent: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (notifError) {
        console.error('Failed to send support reply notification:', notifError);
        // Don't throw — notification failure should not block conversation update
      }
    }

    return null;
  }));

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
export const sendWelcomeEmail = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("sendWelcomeEmail", async (data: any, context: functions.https.CallableContext) => {
    const { email, locale } = data;

    if (!email || typeof email !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'email is required');
    }

    // Security audit M-09: this was callable without login for ANY address
    // (mail-bomb / sender-reputation abuse). The app calls it right after
    // account creation, when the new user is already signed in, so it now only
    // sends to the caller's own email. The app ignores the result.
    const tokenEmail = (context.auth?.token?.email || '').toLowerCase().trim();
    if (!context.auth || tokenEmail !== email.toLowerCase().trim()) {
      return { success: true, emailSent: false };
    }

    // The app's active language at registration. Unknown/missing => English.
    const copy = welcomeEmailCopy(locale);

    console.log(`sendWelcomeEmail called for: ${redact(email)} (locale: ${locale ?? 'none'})`);

    try {
      // Read Resend config
      const configDoc = await db.doc('app_config/resend_settings').get();
      const resendConfig = configDoc.data();
      const resendApiKey = resendConfig?.apiKey;

      if (!resendApiKey) {
        console.warn('Resend API key not configured. Welcome email not sent.');
        return { success: true, emailSent: false, message: 'Welcome email not sent (email not configured)' };
      }

      const senderEmail = resendConfig?.senderEmail || 'onboarding@resend.dev';
      const senderName = resendConfig?.senderName || 'GreenGo';

      const emailResponse = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${resendApiKey}`,
        },
        body: JSON.stringify({
          from: `${senderName} <${senderEmail}>`,
          to: [email],
          subject: copy.subject,
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
                  <p style="color: #D4AF37; margin-top: 5px; font-size: 16px;">${copy.tagline}</p>
                </div>
                <div class="content">
                  <p>${copy.intro}</p>
                  <p>${copy.profilePrompt}</p>
                  <hr class="divider">
                  <div class="features">
                    <div class="feature"><span class="feature-icon">&#10024;</span> ${copy.featureProfile}</div>
                    <div class="feature"><span class="feature-icon">&#128154;</span> ${copy.featureDiscover}</div>
                    <div class="feature"><span class="feature-icon">&#128172;</span> ${copy.featureConversations}</div>
                    <div class="feature"><span class="feature-icon">&#127760;</span> ${copy.featureTravel}</div>
                  </div>
                  <hr class="divider">
                  <p style="font-size: 14px; color: rgba(255,255,255,0.5);">${copy.callToAction}</p>
                </div>
                <div class="footer">
                  <p>&copy; ${new Date().getFullYear()} GreenGo. ${copy.rightsReserved}</p>
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
    } catch (error: any) {
      console.error('Error sending welcome email:', error);
      throw new functions.https.HttpsError('internal', 'Failed to send welcome email');
    }
  })
);

// =============================================================================
// ORPHANED AUTH USER CLEANUP
// =============================================================================

// =============================================================================
// PASSWORD RESET VIA RESEND (branded email for regular users)
// =============================================================================


// Rate limit for the password-reset endpoint.
//
// Needed because the endpoint now answers "email-not-found", which makes it a
// way to test whether an address is registered. In-memory, so it is per
// instance rather than exact - enough to stop a list being walked at speed from
// one machine, which is the realistic abuse, without adding a Firestore write
// to every reset attempt.
const RESET_WINDOW_MS = 60_000;
const RESET_MAX = 10;
const resetHits = new Map<string, number[]>();

function resetRateLimited(key: string): boolean {
  const now = Date.now();
  const recent = (resetHits.get(key) || []).filter((t) => now - t < RESET_WINDOW_MS);
  recent.push(now);
  resetHits.set(key, recent);
  if (resetHits.size > 5000) resetHits.clear(); // a cache, not a ledger
  return recent.length > RESET_MAX;
}

/**
 * Send the branded password-reset email (Resend) carrying [resetLink].
 * Shared by the forgot-password flow and the admin panel reset action.
 */
async function deliverResetEmail(email: string, resetLink: string): Promise<{ success: boolean; emailSent: boolean; message?: string }> {
  // Read Resend config
  const configDoc = await db.doc('app_config/resend_settings').get();
  const resendConfig = configDoc.data();
  const resendApiKey = resendConfig?.apiKey;

  if (!resendApiKey) {
    console.warn('Resend API key not configured. Password reset email not sent via Resend.');
    return { success: true, emailSent: false, message: 'Password reset email not sent (email not configured)' };
  }

  const senderEmail = resendConfig?.senderEmail || 'onboarding@resend.dev';
  const senderName = resendConfig?.senderName || 'GreenGo';

  const emailResponse = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${resendApiKey}`,
    },
    body: JSON.stringify({
      from: `${senderName} <${senderEmail}>`,
      to: [email],
      subject: 'Reset Your GreenGo Password',
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
            .reset-btn { display: inline-block; background: linear-gradient(135deg, #D4AF37, #FFD700); color: #0A0A0A; font-weight: bold; font-size: 16px; padding: 14px 40px; border-radius: 12px; text-decoration: none; margin: 20px 0; }
            .link-fallback { color: rgba(255,255,255,0.5); font-size: 12px; word-break: break-all; }
            .warning { color: rgba(255,255,255,0.5); font-size: 13px; margin-top: 20px; }
            .footer { text-align: center; margin-top: 30px; color: rgba(255,255,255,0.4); font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <div class="logo">GreenGo</div>
              <p style="color: #D4AF37; margin-top: 5px; font-size: 16px;">Password Reset</p>
            </div>
            <div class="content">
              <p>We received a request to reset your <span class="highlight">GreenGo</span> password.</p>
              <p>Click the button below to set a new password:</p>
              <hr class="divider">
              <a href="${resetLink}" class="reset-btn">Reset Password</a>
              <hr class="divider">
              <p class="warning">This link will expire in 1 hour for security reasons.</p>
              <p class="warning">If you didn't request a password reset, you can safely ignore this email.</p>
              <p class="link-fallback">If the button doesn't work, copy and paste this link into your browser:<br>${resetLink}</p>
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
  console.log(`Resend password reset email response [${emailResponse.status}]:`, emailResponseText);

  if (!emailResponse.ok) {
    console.error('Resend password reset email error:', emailResponseText);
    return { success: true, emailSent: false, message: 'Password reset email failed to send' };
  }

  return { success: true, emailSent: true };
}

/**
 * Send a branded password reset email via Resend.
 * No admin auth required — called from the forgot password screen.
 */
export const sendPasswordResetViaResend = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("sendPasswordResetViaResend", async (data: any, _context: functions.https.CallableContext) => {
    const { email } = data;

    if (!email || typeof email !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'email is required');
    }

    const caller = (_context.rawRequest as any)?.ip || 'anonymous';
    if (resetRateLimited(caller)) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'Too many attempts, try again shortly',
      );
    }

    console.log(`sendPasswordResetViaResend called for: ${redact(email)}`);

    try {
      // Generate the Firebase password reset link. An explicit, authorized
      // continue URL is required — without ActionCodeSettings the Admin SDK can
      // throw "INTERNAL ASSERT FAILED: Unable to create the email action link".
      const actionCodeSettings = {
        url: 'https://greengo-chat.firebaseapp.com',
        handleCodeInApp: false,
      };
      const resetLink = await auth.generatePasswordResetLink(email, actionCodeSettings);

      return await deliverResetEmail(email, resetLink);
    } catch (error: any) {
      // Our own deliberate answers (e.g. email-not-found) pass straight
      // through; only real failures are interpreted below.
      if (error instanceof functions.https.HttpsError) throw error;
      // Do not reveal whether the account exists — return success for security.
      // For an unregistered email the Admin SDK normally returns
      // auth/user-not-found, but on generatePasswordResetLink it instead
      // surfaces auth/internal-error ("Unable to create the email action link").
      // Treat all of these "no deliverable account" cases as a silent success.
      const code = error?.errorInfo?.code || error?.code || '';
      const message = error?.errorInfo?.message || error?.message || '';

      // No account for this address - say so.
      //
      // This is a deliberate product decision, taken knowing the trade: an
      // endpoint that distinguishes "no such account" from "sent" lets anyone
      // test which addresses are registered here. It was chosen because the
      // silent version was indistinguishable from a wrong address, and people
      // reset passwords far more often than they enumerate accounts.
      //
      // The rate limit below is what keeps that trade bounded.
      if (
        code === 'auth/user-not-found' ||
        code === 'auth/invalid-email' ||
        message.includes('Unable to create the email action link')
      ) {
        console.log(`sendPasswordResetViaResend: no account for ${redact(email)}`);
        throw new functions.https.HttpsError('not-found', 'email-not-found');
      }

      // auth/internal-error used to be lumped in with "no such account". It is
      // not: it is the Admin SDK's catch-all, so a genuine outage or
      // misconfiguration was being logged as a routine missing user and
      // reported to the caller as success. Nobody could tell a broken reset
      // from an unregistered address - which is exactly the confusion this
      // investigation started from.
      //
      // The caller still gets the same answer (enumeration again), but this
      // lands in the log as an ERROR so it is findable.
      if (code === 'auth/internal-error') {
        console.error(
          `sendPasswordResetViaResend: internal error generating the reset link for ${email} - ` +
          'this is NOT a missing account:',
          message,
        );
        return { success: true, emailSent: false };
      }
      console.error('Error sending password reset email:', error);
      throw new functions.https.HttpsError('internal', 'Failed to send password reset email');
    }
  })
);

// =============================================================================
// ORPHANED AUTH USER CLEANUP
// =============================================================================

/** An auth account active more recently than this is never treated as an orphan. */
const ORPHAN_MIN_AGE_MS = 15 * 60 * 1000;

export const cleanupOrphanedAuthUser = functions.runWith({ memory: '512MB' }).https.onCall(
  monitored("cleanupOrphanedAuthUser", async (data: any, _context: functions.https.CallableContext) => {
    const { email } = data;

    if (!email || typeof email !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'email is required');
    }

    // Security audit H-28. Callable without login (the caller's own signup
    // just failed with email-already-in-use), so it must not be usable to
    // delete someone else's account mid-onboarding or to probe which emails
    // are registered:
    //  - every "not cleaned" outcome returns the same answer;
    //  - an account created or signed into within ORPHAN_MIN_AGE_MS is never
    //    deleted (it may be a real user finishing onboarding right now).
    const notCleaned = { success: true, cleaned: false };
    try {
      // Look up the Auth user by email
      let userRecord;
      try {
        userRecord = await auth.getUserByEmail(email);
      } catch (err: any) {
        if (err.code === 'auth/user-not-found') {
          return notCleaned;
        }
        throw err;
      }

      const userId = userRecord.uid;

      const lastActivity = Math.max(
        Date.parse(userRecord.metadata.creationTime) || 0,
        Date.parse(userRecord.metadata.lastSignInTime || '') || 0,
        Date.parse(userRecord.metadata.lastRefreshTime || '') || 0,
      );
      if (Date.now() - lastActivity < ORPHAN_MIN_AGE_MS) {
        return notCleaned;
      }

      // Check if user exists in any Firestore collection (profiles, admin_users, users)
      const [profileDoc, adminDoc, userDoc] = await Promise.all([
        db.collection('profiles').doc(userId).get(),
        db.collection('admin_users').doc(userId).get(),
        db.collection('users').doc(userId).get(),
      ]);

      if (profileDoc.exists || adminDoc.exists || userDoc.exists) {
        // User exists in Firestore — this is NOT an orphan, do not delete.
        return notCleaned;
      }

      // No Firestore data exists — this is an orphaned Auth user, safe to delete
      await auth.deleteUser(userId);
      console.log(`Cleaned up orphaned Auth user: ${userId} (${redact(email)})`);

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
  })
);

// =============================================================================
// SELF-HEALING PROFILE LOCATION (reverse geocode on write)
// =============================================================================

/**
 * When a profile is written with real coordinates but an unknown/empty country
 * (e.g. onboarding geocoding failed), reverse-geocode the coordinates and
 * backfill city / country / countryLower / displayAddress so the profile is
 * discoverable in its real location.
 *
 * Loop-safe: only acts when the country is unknown AND coordinates exist. The
 * resulting write sets a real country, so the re-triggered invocation no-ops.
 * To avoid re-geocoding on unrelated writes (presence, bio, etc.), it only runs
 * on profile creation or when the coordinates/country actually changed.
 */
export const reverseGeocodeProfileLocation = functions
  // 512MB: the shared bundle needs ~200MB just to load.
  .runWith({ memory: '512MB' })
  .firestore
  .document('profiles/{userId}')
  .onWrite(monitored("reverseGeocodeProfileLocation", async (
    change: functions.Change<functions.firestore.DocumentSnapshot>,
    context: functions.EventContext,
  ) => {
    const after = change.after.exists ? change.after.data() : null;
    if (!after) return null; // document deleted

    // H-21 interim age-gate backstop (auth/ageGate.ts). Rides on this existing
    // trigger so the hot profiles collection gets no extra function; it only
    // acts on profile creation or a changed dateOfBirth.
    try {
      const before = change.before.exists ? change.before.data() : null;
      if (await applyProfileAgeGate(context.params.userId, before, after, change.after.ref)) return null;
    } catch (e: any) {
      console.error('age gate check failed:', e?.message || e);
    }

    const loc = after.location || {};
    const country = (loc.country || '').toString().trim().toLowerCase();
    const lat = Number(loc.latitude) || 0;
    const lng = Number(loc.longitude) || 0;

    const countryUnknown = country === '' || country === 'unknown';
    const hasCoords = lat !== 0 && lng !== 0;
    // Skip already-located profiles AND the function's own follow-up write.
    if (!countryUnknown || !hasCoords) return null;

    // Only run on creation or when location actually changed — avoids
    // re-geocoding on every unrelated profile update.
    const before = change.before.exists ? change.before.data() : null;
    const bLoc = before?.location || {};
    const bLat = Number(bLoc.latitude) || 0;
    const bLng = Number(bLoc.longitude) || 0;
    const bCountry = (bLoc.country || '').toString().trim().toLowerCase();
    const coordsChanged = bLat !== lat || bLng !== lng;
    const countryChanged = bCountry !== country;
    if (before && !coordsChanged && !countryChanged) return null;

    try {
      const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&accept-language=en&zoom=10`;
      const resp = await fetch(url, {
        headers: { 'User-Agent': 'GreenGo-App/1.0 (location backfill; support@greengochat.com)' },
      });
      if (!resp.ok) {
        console.warn(`reverseGeocodeProfileLocation: HTTP ${resp.status} for ${context.params.userId}`);
        return null;
      }
      const data: any = await resp.json();
      const a = data.address || {};
      const resolvedCountry = a.country || '';
      const resolvedCity =
        a.city || a.town || a.village || a.municipality || a.county || a.state_district || a.state || '';
      if (!resolvedCountry) {
        console.warn(`reverseGeocodeProfileLocation: no country resolved for ${context.params.userId}`);
        return null;
      }
      const city = resolvedCity || resolvedCountry;
      await change.after.ref.update({
        'location.city': city,
        'location.country': resolvedCountry,
        'location.countryLower': resolvedCountry.toLowerCase(),
        'location.displayAddress': `${city}, ${resolvedCountry}`,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`reverseGeocodeProfileLocation: ${context.params.userId} -> ${city}, ${resolvedCountry}`);
      return null;
    } catch (error: any) {
      console.error('reverseGeocodeProfileLocation error:', error?.message || error);
      return null;
    }
  }));
