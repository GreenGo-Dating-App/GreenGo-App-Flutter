/**
 * Brevo Email Service for Cloud Functions
 * Comprehensive email notification system using Brevo (formerly Sendinblue)
 *
 * This service handles all transactional emails for:
 * - Account events (verification, password reset, profile updates)
 * - Subscription events (purchases, renewals, cancellations)
 * - Moderation events (approvals, denials, warnings)
 * - Purchase events (shop items, gifts, coins)
 * - Gamification events (achievements, badges, levels)
 * - Social events (matches, messages, likes)
 * - Engagement events (weekly digests, re-engagement)
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { verifyAuth, handleError, logInfo, logError, db } from '../shared/utils';

// Brevo API configuration
const BREVO_API_URL = 'https://api.brevo.com/v3';
const BREVO_API_KEY = process.env.BREVO_API_KEY || '';
const BREVO_SENDER_EMAIL = process.env.BREVO_SENDER_EMAIL || 'noreply@greengo.app';
const BREVO_SENDER_NAME = process.env.BREVO_SENDER_NAME || 'GreenGo';

// ============================================================================
// TYPES & INTERFACES
// ============================================================================

export type EmailCategory =
  | 'account'
  | 'subscription'
  | 'moderation'
  | 'purchase'
  | 'gamification'
  | 'social'
  | 'engagement';

export type EmailTrigger =
  // Account
  | 'welcome' | 'email_verification' | 'email_verified' | 'password_reset_request'
  | 'password_reset_success' | 'profile_updated' | 'profile_photo_approved'
  | 'profile_photo_rejected' | 'account_suspended' | 'account_reactivated'
  | 'account_deleted' | 'login_new_device' | 'two_factor_enabled'
  | 'two_factor_disabled' | 'phone_verified'
  // Subscription
  | 'subscription_started' | 'subscription_renewed' | 'subscription_upgraded'
  | 'subscription_downgraded' | 'subscription_cancelled' | 'subscription_expired'
  | 'subscription_payment_failed' | 'subscription_payment_retry'
  | 'subscription_grace_period_start' | 'subscription_grace_period_end'
  | 'subscription_trial_started' | 'subscription_trial_ending'
  | 'subscription_trial_ended' | 'subscription_refund_processed'
  | 'subscription_price_change' | 'subscription_features_updated'
  | 'subscription_auto_renewal_off'
  // Moderation
  | 'photo_approved' | 'photo_rejected' | 'bio_approved' | 'bio_rejected'
  | 'message_flagged' | 'report_received' | 'report_resolved'
  | 'warning_issued' | 'temporary_ban_start' | 'temporary_ban_end'
  | 'permanent_ban' | 'appeal_received' | 'appeal_approved'
  | 'appeal_rejected' | 'content_removed' | 'shadowban_activated'
  | 'verification_approved'
  // Purchase
  | 'coins_purchased' | 'coins_gifted_sent' | 'coins_gifted_received'
  | 'shop_item_purchased' | 'gift_sent' | 'gift_received'
  | 'boost_purchased' | 'boost_activated' | 'boost_expired'
  | 'super_like_purchased' | 'spotlight_purchased' | 'spotlight_activated'
  | 'spotlight_expired' | 'bundle_purchased' | 'purchase_refunded'
  | 'invoice_generated' | 'payment_receipt' | 'payment_failed'
  // Gamification
  | 'achievement_unlocked' | 'badge_earned' | 'level_up'
  | 'daily_streak_milestone' | 'streak_at_risk' | 'streak_lost'
  | 'leaderboard_rank_up' | 'leaderboard_top_10' | 'weekly_challenge_started'
  | 'weekly_challenge_completed' | 'milestone_reached' | 'reward_unlocked'
  | 'xp_bonus_earned' | 'seasonal_event_started' | 'seasonal_reward_earned'
  // Social
  | 'new_match' | 'super_like_received' | 'message_received'
  | 'profile_viewed' | 'mutual_interest' | 'match_about_to_expire'
  | 'match_expired' | 'icebreaker_received' | 'video_call_missed'
  | 'video_call_scheduled' | 'compatibility_score_high' | 'date_suggestion'
  // Engagement
  | 'welcome_series_day_1' | 'welcome_series_day_3' | 'welcome_series_day_7'
  | 'weekly_digest' | 'monthly_recap' | 'profile_incomplete_reminder'
  | 'inactive_7_days' | 'inactive_14_days' | 'inactive_30_days'
  | 'new_feature_announcement' | 'special_offer' | 'feedback_request'
  | 'birthday_greeting' | 'anniversary_reminder' | 'tips_and_suggestions'
  | 're_engagement';

export interface EmailRecipient {
  email: string;
  name?: string;
}

export interface EmailTemplate {
  id: string;
  trigger: EmailTrigger;
  category: EmailCategory;
  name: string;
  subject: string;
  htmlContent: string;
  textContent?: string;
  isActive: boolean;
  variables: string[];
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  brevoTemplateId?: number;
}

export interface EmailLog {
  id: string;
  userId: string;
  recipientEmail: string;
  recipientName?: string;
  trigger: EmailTrigger;
  category: EmailCategory;
  subject: string;
  templateId?: string;
  brevoMessageId?: string;
  status: 'pending' | 'sent' | 'delivered' | 'opened' | 'clicked' | 'bounced' | 'failed';
  variables: Record<string, any>;
  sentAt?: admin.firestore.Timestamp;
  deliveredAt?: admin.firestore.Timestamp;
  openedAt?: admin.firestore.Timestamp;
  clickedAt?: admin.firestore.Timestamp;
  error?: string;
  createdAt: admin.firestore.Timestamp;
}

export interface SendEmailParams {
  userId: string;
  trigger: EmailTrigger;
  variables?: Record<string, any>;
  overrideEmail?: string;
}

// ============================================================================
// BREVO API HELPER
// ============================================================================

async function brevoApiRequest<T>(
  endpoint: string,
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' = 'GET',
  body?: object
): Promise<T> {
  if (!BREVO_API_KEY) {
    throw new Error('Brevo API key is not configured');
  }

  const response = await fetch(`${BREVO_API_URL}${endpoint}`, {
    method,
    headers: {
      'accept': 'application/json',
      'content-type': 'application/json',
      'api-key': BREVO_API_KEY,
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.message || `Brevo API error: ${response.statusText}`);
  }

  if (response.status === 204) {
    return {} as T;
  }

  return response.json();
}

// ============================================================================
// EMAIL TEMPLATE FUNCTIONS
// ============================================================================

const EMAIL_CATEGORY_MAP: Record<EmailTrigger, EmailCategory> = {
  // Account
  welcome: 'account',
  email_verification: 'account',
  email_verified: 'account',
  password_reset_request: 'account',
  password_reset_success: 'account',
  profile_updated: 'account',
  profile_photo_approved: 'account',
  profile_photo_rejected: 'account',
  account_suspended: 'account',
  account_reactivated: 'account',
  account_deleted: 'account',
  login_new_device: 'account',
  two_factor_enabled: 'account',
  two_factor_disabled: 'account',
  phone_verified: 'account',
  // Subscription
  subscription_started: 'subscription',
  subscription_renewed: 'subscription',
  subscription_upgraded: 'subscription',
  subscription_downgraded: 'subscription',
  subscription_cancelled: 'subscription',
  subscription_expired: 'subscription',
  subscription_payment_failed: 'subscription',
  subscription_payment_retry: 'subscription',
  subscription_grace_period_start: 'subscription',
  subscription_grace_period_end: 'subscription',
  subscription_trial_started: 'subscription',
  subscription_trial_ending: 'subscription',
  subscription_trial_ended: 'subscription',
  subscription_refund_processed: 'subscription',
  subscription_price_change: 'subscription',
  subscription_features_updated: 'subscription',
  subscription_auto_renewal_off: 'subscription',
  // Moderation
  photo_approved: 'moderation',
  photo_rejected: 'moderation',
  bio_approved: 'moderation',
  bio_rejected: 'moderation',
  message_flagged: 'moderation',
  report_received: 'moderation',
  report_resolved: 'moderation',
  warning_issued: 'moderation',
  temporary_ban_start: 'moderation',
  temporary_ban_end: 'moderation',
  permanent_ban: 'moderation',
  appeal_received: 'moderation',
  appeal_approved: 'moderation',
  appeal_rejected: 'moderation',
  content_removed: 'moderation',
  shadowban_activated: 'moderation',
  verification_approved: 'moderation',
  // Purchase
  coins_purchased: 'purchase',
  coins_gifted_sent: 'purchase',
  coins_gifted_received: 'purchase',
  shop_item_purchased: 'purchase',
  gift_sent: 'purchase',
  gift_received: 'purchase',
  boost_purchased: 'purchase',
  boost_activated: 'purchase',
  boost_expired: 'purchase',
  super_like_purchased: 'purchase',
  spotlight_purchased: 'purchase',
  spotlight_activated: 'purchase',
  spotlight_expired: 'purchase',
  bundle_purchased: 'purchase',
  purchase_refunded: 'purchase',
  invoice_generated: 'purchase',
  payment_receipt: 'purchase',
  payment_failed: 'purchase',
  // Gamification
  achievement_unlocked: 'gamification',
  badge_earned: 'gamification',
  level_up: 'gamification',
  daily_streak_milestone: 'gamification',
  streak_at_risk: 'gamification',
  streak_lost: 'gamification',
  leaderboard_rank_up: 'gamification',
  leaderboard_top_10: 'gamification',
  weekly_challenge_started: 'gamification',
  weekly_challenge_completed: 'gamification',
  milestone_reached: 'gamification',
  reward_unlocked: 'gamification',
  xp_bonus_earned: 'gamification',
  seasonal_event_started: 'gamification',
  seasonal_reward_earned: 'gamification',
  // Social
  new_match: 'social',
  super_like_received: 'social',
  message_received: 'social',
  profile_viewed: 'social',
  mutual_interest: 'social',
  match_about_to_expire: 'social',
  match_expired: 'social',
  icebreaker_received: 'social',
  video_call_missed: 'social',
  video_call_scheduled: 'social',
  compatibility_score_high: 'social',
  date_suggestion: 'social',
  // Engagement
  welcome_series_day_1: 'engagement',
  welcome_series_day_3: 'engagement',
  welcome_series_day_7: 'engagement',
  weekly_digest: 'engagement',
  monthly_recap: 'engagement',
  profile_incomplete_reminder: 'engagement',
  inactive_7_days: 'engagement',
  inactive_14_days: 'engagement',
  inactive_30_days: 'engagement',
  new_feature_announcement: 'engagement',
  special_offer: 'engagement',
  feedback_request: 'engagement',
  birthday_greeting: 'engagement',
  anniversary_reminder: 'engagement',
  tips_and_suggestions: 'engagement',
  re_engagement: 'engagement',
};

function getEmailCategory(trigger: EmailTrigger): EmailCategory {
  return EMAIL_CATEGORY_MAP[trigger] || 'engagement';
}

function getDefaultTemplate(trigger: EmailTrigger, variables: Record<string, any>): { subject: string; htmlContent: string } {
  const userName = variables.userName || 'there';

  const branding = {
    backgroundColor: '#0A0A0A',
    cardColor: '#1A1A1A',
    borderColor: '#2A2A2A',
    primaryColor: '#D4AF37',
    goldGradient: 'linear-gradient(135deg, #D4AF37, #FFD700)',
    textColor: '#FFFFFF',
    mutedColor: 'rgba(255,255,255,0.7)',
  };

  const baseTemplate = (title: string, content: string, ctaUrl?: string, ctaText?: string) => `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>${title}</title>
    </head>
    <body style="margin: 0; padding: 0; font-family: 'Helvetica Neue', Arial, sans-serif; background-color: ${branding.backgroundColor}; color: ${branding.textColor};">
      <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background-color: ${branding.backgroundColor};">
        <tr>
          <td style="padding: 40px 20px;">
            <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" style="margin: 0 auto; background-color: ${branding.cardColor}; border-radius: 16px; border: 1px solid ${branding.borderColor};">
              <!-- Header -->
              <tr>
                <td style="padding: 40px 40px 20px 40px; text-align: center;">
                  <h1 style="margin: 0; font-size: 32px; font-weight: bold; background: ${branding.goldGradient}; -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;">GreenGo</h1>
                  <p style="margin: 10px 0 0 0; color: ${branding.primaryColor}; font-size: 14px;">Your Premium Dating Experience</p>
                </td>
              </tr>
              <!-- Content -->
              <tr>
                <td style="padding: 20px 40px 40px 40px;">
                  <h2 style="margin: 0 0 20px 0; color: ${branding.primaryColor}; font-size: 24px;">${title}</h2>
                  <p style="margin: 0 0 20px 0; color: ${branding.mutedColor}; line-height: 1.6;">Hi ${userName},</p>
                  ${content}
                  ${ctaUrl && ctaText ? `
                  <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin: 30px 0;">
                    <tr>
                      <td style="background: ${branding.goldGradient}; border-radius: 8px;">
                        <a href="${ctaUrl}" style="display: inline-block; padding: 14px 30px; color: #0A0A0A; text-decoration: none; font-weight: bold; font-size: 16px;">${ctaText}</a>
                      </td>
                    </tr>
                  </table>
                  ` : ''}
                </td>
              </tr>
              <!-- Footer -->
              <tr>
                <td style="padding: 20px 40px; border-top: 1px solid ${branding.borderColor};">
                  <p style="margin: 0; color: ${branding.mutedColor}; font-size: 12px; text-align: center;">
                    &copy; ${new Date().getFullYear()} GreenGo. All rights reserved.<br>
                    <a href="https://greengo.app/unsubscribe" style="color: ${branding.primaryColor}; text-decoration: none;">Unsubscribe</a> |
                    <a href="https://greengo.app/privacy" style="color: ${branding.primaryColor}; text-decoration: none;">Privacy Policy</a>
                  </p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `;

  const templates: Record<EmailTrigger, { subject: string; htmlContent: string }> = {
    // Account
    welcome: {
      subject: `Welcome to GreenGo, ${userName}!`,
      htmlContent: baseTemplate(
        'Welcome to GreenGo!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">We're excited to have you join our premium dating community! GreenGo is designed for meaningful connections.</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; margin: 20px 0; border-left: 4px solid ${branding.primaryColor};">
          <p style="color: ${branding.textColor}; margin: 0;"><strong>Get started:</strong></p>
          <ul style="color: ${branding.mutedColor}; margin: 10px 0 0 0; padding-left: 20px;">
            <li>Complete your profile</li>
            <li>Upload your best photos</li>
            <li>Start discovering matches</li>
          </ul>
        </div>`,
        'https://greengo.app/profile',
        'Complete Your Profile'
      ),
    },
    email_verification: {
      subject: 'Verify your GreenGo email',
      htmlContent: baseTemplate(
        'Verify Your Email',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Please verify your email address to complete your registration and unlock all features.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Your verification code is:</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; text-align: center; margin: 20px 0;">
          <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: ${branding.primaryColor};">${variables.verificationCode || '000000'}</span>
        </div>`,
        variables.verificationUrl || 'https://greengo.app/verify',
        'Verify Email'
      ),
    },
    email_verified: {
      subject: 'Email verified successfully!',
      htmlContent: baseTemplate(
        'Email Verified!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your email has been verified successfully. You now have full access to all GreenGo features.</p>`,
        'https://greengo.app',
        'Start Exploring'
      ),
    },
    password_reset_request: {
      subject: 'Reset your GreenGo password',
      htmlContent: baseTemplate(
        'Password Reset Request',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">We received a request to reset your password. Click the button below to create a new password.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">This link will expire in 1 hour.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6; font-size: 12px;">If you didn't request this, you can safely ignore this email.</p>`,
        variables.resetUrl || 'https://greengo.app/reset-password',
        'Reset Password'
      ),
    },
    password_reset_success: {
      subject: 'Your password has been changed',
      htmlContent: baseTemplate(
        'Password Changed',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your password has been successfully changed.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6; font-size: 12px;">If you didn't make this change, please contact our support team immediately.</p>`,
        'https://greengo.app/support',
        'Contact Support'
      ),
    },
    profile_updated: {
      subject: 'Profile updated successfully',
      htmlContent: baseTemplate(
        'Profile Updated',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your profile has been updated successfully. Your changes are now visible to other users.</p>`,
        'https://greengo.app/profile',
        'View Profile'
      ),
    },
    profile_photo_approved: {
      subject: 'Your photo has been approved!',
      htmlContent: baseTemplate(
        'Photo Approved!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Great news! Your photo has been reviewed and approved. It's now visible on your profile.</p>`,
        'https://greengo.app/profile',
        'View Your Profile'
      ),
    },
    profile_photo_rejected: {
      subject: 'Photo review update',
      htmlContent: baseTemplate(
        'Photo Not Approved',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Unfortunately, your photo couldn't be approved because it doesn't meet our community guidelines.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;"><strong>Reason:</strong> ${variables.rejectionReason || 'Does not meet community guidelines'}</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Please upload a new photo that follows our guidelines.</p>`,
        'https://greengo.app/profile/photos',
        'Upload New Photo'
      ),
    },
    account_suspended: {
      subject: 'Your GreenGo account has been suspended',
      htmlContent: baseTemplate(
        'Account Suspended',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your account has been temporarily suspended due to a violation of our community guidelines.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;"><strong>Reason:</strong> ${variables.suspensionReason || 'Community guidelines violation'}</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">If you believe this is a mistake, you can appeal this decision.</p>`,
        'https://greengo.app/appeal',
        'Submit Appeal'
      ),
    },
    account_reactivated: {
      subject: 'Your GreenGo account has been reactivated',
      htmlContent: baseTemplate(
        'Account Reactivated!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Great news! Your account has been reactivated. You can now use GreenGo again.</p>`,
        'https://greengo.app',
        'Return to GreenGo'
      ),
    },
    account_deleted: {
      subject: 'Your GreenGo account has been deleted',
      htmlContent: baseTemplate(
        'Account Deleted',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your account has been permanently deleted as requested. We're sorry to see you go.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">If you change your mind, you're always welcome to create a new account.</p>`,
        'https://greengo.app',
        'Create New Account'
      ),
    },
    login_new_device: {
      subject: 'New login detected on your account',
      htmlContent: baseTemplate(
        'New Login Detected',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">A new login was detected on your GreenGo account.</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; margin: 20px 0;">
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Device:</strong> ${variables.deviceInfo || 'Unknown device'}</p>
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Location:</strong> ${variables.location || 'Unknown'}</p>
          <p style="color: ${branding.textColor}; margin: 0;"><strong>Time:</strong> ${variables.loginTime || new Date().toISOString()}</p>
        </div>
        <p style="color: ${branding.mutedColor}; line-height: 1.6; font-size: 12px;">If this wasn't you, please secure your account immediately.</p>`,
        'https://greengo.app/security',
        'Review Security'
      ),
    },
    two_factor_enabled: {
      subject: 'Two-factor authentication enabled',
      htmlContent: baseTemplate(
        '2FA Enabled',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Two-factor authentication has been enabled on your account. Your account is now more secure!</p>`,
        'https://greengo.app/security',
        'Security Settings'
      ),
    },
    two_factor_disabled: {
      subject: 'Two-factor authentication disabled',
      htmlContent: baseTemplate(
        '2FA Disabled',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Two-factor authentication has been disabled on your account.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6; font-size: 12px;">If you didn't make this change, please secure your account immediately.</p>`,
        'https://greengo.app/security',
        'Review Security'
      ),
    },
    phone_verified: {
      subject: 'Phone number verified',
      htmlContent: baseTemplate(
        'Phone Verified!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your phone number has been verified successfully. You now have access to additional features.</p>`,
        'https://greengo.app/profile',
        'View Profile'
      ),
    },
    // Subscription
    subscription_started: {
      subject: `Welcome to ${variables.planName || 'Premium'}!`,
      htmlContent: baseTemplate(
        'Subscription Activated!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Congratulations! Your ${variables.planName || 'Premium'} subscription is now active.</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; margin: 20px 0; border-left: 4px solid ${branding.primaryColor};">
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Plan:</strong> ${variables.planName || 'Premium'}</p>
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Amount:</strong> ${variables.amount || '$0.00'}</p>
          <p style="color: ${branding.textColor}; margin: 0;"><strong>Next billing:</strong> ${variables.nextBillingDate || 'N/A'}</p>
        </div>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Enjoy unlimited swipes, see who likes you, and much more!</p>`,
        'https://greengo.app',
        'Start Exploring'
      ),
    },
    subscription_renewed: {
      subject: 'Your subscription has been renewed',
      htmlContent: baseTemplate(
        'Subscription Renewed',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your ${variables.planName || 'Premium'} subscription has been renewed successfully.</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; margin: 20px 0;">
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Amount charged:</strong> ${variables.amount || '$0.00'}</p>
          <p style="color: ${branding.textColor}; margin: 0;"><strong>Next renewal:</strong> ${variables.nextBillingDate || 'N/A'}</p>
        </div>`,
        'https://greengo.app/subscription',
        'Manage Subscription'
      ),
    },
    subscription_upgraded: {
      subject: 'Subscription upgraded successfully!',
      htmlContent: baseTemplate(
        'Subscription Upgraded!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your subscription has been upgraded to ${variables.newPlanName || 'Premium Plus'}!</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">You now have access to additional features:</p>
        <ul style="color: ${branding.mutedColor}; line-height: 1.8;">
          <li>Priority profile visibility</li>
          <li>Unlimited rewinds</li>
          <li>Advanced filters</li>
        </ul>`,
        'https://greengo.app',
        'Explore New Features'
      ),
    },
    subscription_downgraded: {
      subject: 'Subscription plan changed',
      htmlContent: baseTemplate(
        'Plan Changed',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your subscription has been changed to ${variables.newPlanName || 'Basic'}.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">This change will take effect at your next billing cycle.</p>`,
        'https://greengo.app/subscription',
        'View Subscription'
      ),
    },
    subscription_cancelled: {
      subject: 'Subscription cancelled',
      htmlContent: baseTemplate(
        'Subscription Cancelled',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your ${variables.planName || 'Premium'} subscription has been cancelled.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">You'll continue to have access until ${variables.endDate || 'the end of your billing period'}.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">We'd love to have you back! You can resubscribe anytime.</p>`,
        'https://greengo.app/subscription',
        'Resubscribe'
      ),
    },
    subscription_expired: {
      subject: 'Your premium access has ended',
      htmlContent: baseTemplate(
        'Subscription Expired',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your ${variables.planName || 'Premium'} subscription has expired.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Renew now to continue enjoying premium features like unlimited swipes and seeing who likes you!</p>`,
        'https://greengo.app/subscription',
        'Renew Subscription'
      ),
    },
    subscription_payment_failed: {
      subject: 'Payment failed - Action required',
      htmlContent: baseTemplate(
        'Payment Failed',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">We couldn't process your payment for ${variables.planName || 'Premium'}.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Please update your payment method to continue your subscription.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6; font-size: 12px;">Reason: ${variables.failureReason || 'Payment declined'}</p>`,
        'https://greengo.app/payment-methods',
        'Update Payment Method'
      ),
    },
    subscription_payment_retry: {
      subject: 'We\'ll retry your payment',
      htmlContent: baseTemplate(
        'Payment Retry Scheduled',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">We'll retry your payment on ${variables.retryDate || 'soon'}.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Please ensure your payment method is up to date.</p>`,
        'https://greengo.app/payment-methods',
        'Check Payment Method'
      ),
    },
    subscription_grace_period_start: {
      subject: 'Grace period started',
      htmlContent: baseTemplate(
        'Grace Period',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your payment is overdue, but we've started a grace period to give you time to update your payment method.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Grace period ends: ${variables.gracePeriodEnd || 'in 7 days'}</p>`,
        'https://greengo.app/payment-methods',
        'Update Payment'
      ),
    },
    subscription_grace_period_end: {
      subject: 'Grace period ending soon',
      htmlContent: baseTemplate(
        'Grace Period Ending',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your grace period is about to end. Please update your payment method to keep your premium features.</p>`,
        'https://greengo.app/payment-methods',
        'Update Now'
      ),
    },
    subscription_trial_started: {
      subject: 'Your free trial has started!',
      htmlContent: baseTemplate(
        'Trial Started!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Welcome to your ${variables.trialDays || '7'}-day free trial of ${variables.planName || 'Premium'}!</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Explore all premium features without any commitment.</p>`,
        'https://greengo.app',
        'Start Exploring'
      ),
    },
    subscription_trial_ending: {
      subject: 'Your trial ends in ${variables.daysRemaining || "3"} days',
      htmlContent: baseTemplate(
        'Trial Ending Soon',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your free trial ends in ${variables.daysRemaining || '3'} days. Subscribe now to keep your premium features!</p>`,
        'https://greengo.app/subscription',
        'Subscribe Now'
      ),
    },
    subscription_trial_ended: {
      subject: 'Your trial has ended',
      htmlContent: baseTemplate(
        'Trial Ended',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your free trial has ended. Subscribe now to continue enjoying premium features!</p>`,
        'https://greengo.app/subscription',
        'Get Premium'
      ),
    },
    subscription_refund_processed: {
      subject: 'Refund processed',
      htmlContent: baseTemplate(
        'Refund Processed',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your refund of ${variables.amount || '$0.00'} has been processed.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">It may take 5-10 business days to appear in your account.</p>`,
        'https://greengo.app/support',
        'Contact Support'
      ),
    },
    subscription_price_change: {
      subject: 'Important: Subscription price update',
      htmlContent: baseTemplate(
        'Price Update',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">We wanted to let you know that the price for ${variables.planName || 'Premium'} will change from ${variables.oldPrice || '$0.00'} to ${variables.newPrice || '$0.00'} starting ${variables.effectiveDate || 'next month'}.</p>`,
        'https://greengo.app/subscription',
        'View Details'
      ),
    },
    subscription_features_updated: {
      subject: 'New features added to your plan!',
      htmlContent: baseTemplate(
        'New Features!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">We've added new features to your ${variables.planName || 'Premium'} subscription!</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Check out what's new:</p>`,
        'https://greengo.app/features',
        'See New Features'
      ),
    },
    subscription_auto_renewal_off: {
      subject: 'Auto-renewal turned off',
      htmlContent: baseTemplate(
        'Auto-Renewal Off',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Auto-renewal has been turned off for your subscription.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Your access will end on ${variables.endDate || 'your next billing date'}.</p>`,
        'https://greengo.app/subscription',
        'Manage Subscription'
      ),
    },
    // Moderation
    photo_approved: {
      subject: 'Photo approved!',
      htmlContent: baseTemplate(
        'Photo Approved',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your photo has been reviewed and approved! It's now visible to other users.</p>`,
        'https://greengo.app/profile',
        'View Profile'
      ),
    },
    photo_rejected: {
      subject: 'Photo not approved',
      htmlContent: baseTemplate(
        'Photo Not Approved',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Unfortunately, your photo couldn't be approved.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;"><strong>Reason:</strong> ${variables.reason || 'Does not meet guidelines'}</p>`,
        'https://greengo.app/guidelines',
        'View Guidelines'
      ),
    },
    bio_approved: {
      subject: 'Bio approved!',
      htmlContent: baseTemplate(
        'Bio Approved',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your bio has been approved and is now visible to other users!</p>`,
        'https://greengo.app/profile',
        'View Profile'
      ),
    },
    bio_rejected: {
      subject: 'Bio needs revision',
      htmlContent: baseTemplate(
        'Bio Not Approved',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your bio needs some changes before it can be published.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;"><strong>Reason:</strong> ${variables.reason || 'Does not meet guidelines'}</p>`,
        'https://greengo.app/profile/edit',
        'Edit Bio'
      ),
    },
    message_flagged: {
      subject: 'Message flagged for review',
      htmlContent: baseTemplate(
        'Message Under Review',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">One of your messages has been flagged for review by our moderation team.</p>`,
        'https://greengo.app/guidelines',
        'View Guidelines'
      ),
    },
    report_received: {
      subject: 'We received your report',
      htmlContent: baseTemplate(
        'Report Received',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Thank you for your report. Our team will review it and take appropriate action.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Report ID: ${variables.reportId || 'N/A'}</p>`,
        'https://greengo.app/safety',
        'Safety Center'
      ),
    },
    report_resolved: {
      subject: 'Your report has been resolved',
      htmlContent: baseTemplate(
        'Report Resolved',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your report has been reviewed and resolved. Thank you for helping keep our community safe.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;"><strong>Outcome:</strong> ${variables.outcome || 'Action taken'}</p>`,
        'https://greengo.app/safety',
        'Safety Center'
      ),
    },
    warning_issued: {
      subject: 'Important: Community guidelines warning',
      htmlContent: baseTemplate(
        'Warning Issued',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">We've issued a warning to your account for the following reason:</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;"><strong>${variables.reason || 'Community guidelines violation'}</strong></p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Please review our guidelines to avoid further action.</p>`,
        'https://greengo.app/guidelines',
        'Review Guidelines'
      ),
    },
    temporary_ban_start: {
      subject: 'Account temporarily restricted',
      htmlContent: baseTemplate(
        'Temporary Restriction',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your account has been temporarily restricted due to a community guidelines violation.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;"><strong>Duration:</strong> ${variables.duration || '24 hours'}</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;"><strong>Reason:</strong> ${variables.reason || 'Violation'}</p>`,
        'https://greengo.app/appeal',
        'Submit Appeal'
      ),
    },
    temporary_ban_end: {
      subject: 'Your account restriction has been lifted',
      htmlContent: baseTemplate(
        'Restriction Lifted',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your temporary restriction has ended. You can now use GreenGo again.</p>`,
        'https://greengo.app',
        'Return to GreenGo'
      ),
    },
    permanent_ban: {
      subject: 'Account permanently suspended',
      htmlContent: baseTemplate(
        'Account Suspended',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your account has been permanently suspended due to repeated or severe violations of our community guidelines.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;"><strong>Reason:</strong> ${variables.reason || 'Severe violation'}</p>`,
        'https://greengo.app/appeal',
        'Submit Appeal'
      ),
    },
    appeal_received: {
      subject: 'Appeal received',
      htmlContent: baseTemplate(
        'Appeal Received',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">We've received your appeal and will review it within 48 hours.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Appeal ID: ${variables.appealId || 'N/A'}</p>`,
        'https://greengo.app/support',
        'Contact Support'
      ),
    },
    appeal_approved: {
      subject: 'Appeal approved!',
      htmlContent: baseTemplate(
        'Appeal Approved',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Good news! Your appeal has been approved. Your account restrictions have been lifted.</p>`,
        'https://greengo.app',
        'Return to GreenGo'
      ),
    },
    appeal_rejected: {
      subject: 'Appeal decision',
      htmlContent: baseTemplate(
        'Appeal Rejected',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">After careful review, we were unable to approve your appeal.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;"><strong>Reason:</strong> ${variables.reason || 'Original decision upheld'}</p>`,
        'https://greengo.app/support',
        'Contact Support'
      ),
    },
    content_removed: {
      subject: 'Content removed from your profile',
      htmlContent: baseTemplate(
        'Content Removed',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Some content has been removed from your profile as it violated our guidelines.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;"><strong>Content type:</strong> ${variables.contentType || 'Photo/Bio'}</p>`,
        'https://greengo.app/guidelines',
        'View Guidelines'
      ),
    },
    shadowban_activated: {
      subject: 'Account visibility update',
      htmlContent: baseTemplate(
        'Visibility Update',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your account visibility has been limited. Please review our community guidelines.</p>`,
        'https://greengo.app/guidelines',
        'Review Guidelines'
      ),
    },
    verification_approved: {
      subject: 'You\'re verified!',
      htmlContent: baseTemplate(
        'Verification Complete!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Congratulations! Your profile is now verified. A blue checkmark will appear on your profile.</p>`,
        'https://greengo.app/profile',
        'View Profile'
      ),
    },
    // Purchase
    coins_purchased: {
      subject: 'Coins purchased successfully!',
      htmlContent: baseTemplate(
        'Coins Added!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your coin purchase was successful!</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; margin: 20px 0;">
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Coins added:</strong> ${variables.coinsAmount || '0'}</p>
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Amount paid:</strong> ${variables.amount || '$0.00'}</p>
          <p style="color: ${branding.textColor}; margin: 0;"><strong>New balance:</strong> ${variables.newBalance || '0'} coins</p>
        </div>`,
        'https://greengo.app/shop',
        'Visit Shop'
      ),
    },
    coins_gifted_sent: {
      subject: 'Gift sent successfully!',
      htmlContent: baseTemplate(
        'Gift Sent!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your gift of ${variables.coinsAmount || '0'} coins has been sent to ${variables.recipientName || 'your match'}!</p>`,
        'https://greengo.app/messages',
        'Send a Message'
      ),
    },
    coins_gifted_received: {
      subject: 'You received a gift!',
      htmlContent: baseTemplate(
        'You Got a Gift!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">${variables.senderName || 'Someone'} sent you ${variables.coinsAmount || '0'} coins!</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Your new balance: ${variables.newBalance || '0'} coins</p>`,
        'https://greengo.app/shop',
        'Use Your Coins'
      ),
    },
    shop_item_purchased: {
      subject: 'Purchase confirmed!',
      htmlContent: baseTemplate(
        'Purchase Confirmed',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your purchase of ${variables.itemName || 'item'} was successful!</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; margin: 20px 0;">
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Item:</strong> ${variables.itemName || 'Item'}</p>
          <p style="color: ${branding.textColor}; margin: 0;"><strong>Cost:</strong> ${variables.cost || '0'} coins</p>
        </div>`,
        'https://greengo.app/inventory',
        'View Inventory'
      ),
    },
    gift_sent: {
      subject: 'Your gift is on its way!',
      htmlContent: baseTemplate(
        'Gift Sent!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your gift of ${variables.giftName || 'a special item'} has been sent to ${variables.recipientName || 'your match'}!</p>`,
        'https://greengo.app/messages',
        'Send a Message'
      ),
    },
    gift_received: {
      subject: 'You received a gift!',
      htmlContent: baseTemplate(
        'New Gift!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">${variables.senderName || 'Someone special'} sent you ${variables.giftName || 'a gift'}!</p>`,
        'https://greengo.app/messages',
        'Thank Them'
      ),
    },
    boost_purchased: {
      subject: 'Boost purchased!',
      htmlContent: baseTemplate(
        'Boost Ready!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your profile boost is ready to use! Activate it when you're ready to get more visibility.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Duration: ${variables.duration || '30 minutes'}</p>`,
        'https://greengo.app/boost',
        'Activate Boost'
      ),
    },
    boost_activated: {
      subject: 'Boost activated!',
      htmlContent: baseTemplate(
        'Boost Active!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your profile boost is now active! You'll get up to 10x more visibility for the next ${variables.duration || '30 minutes'}.</p>`,
        'https://greengo.app',
        'Start Swiping'
      ),
    },
    boost_expired: {
      subject: 'Your boost has ended',
      htmlContent: baseTemplate(
        'Boost Ended',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your profile boost has ended. Here's how you did:</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; margin: 20px 0;">
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Profile views:</strong> ${variables.views || '0'}</p>
          <p style="color: ${branding.textColor}; margin: 0;"><strong>New likes:</strong> ${variables.likes || '0'}</p>
        </div>`,
        'https://greengo.app/boost',
        'Get Another Boost'
      ),
    },
    super_like_purchased: {
      subject: 'Super Likes added!',
      htmlContent: baseTemplate(
        'Super Likes Ready!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">${variables.amount || '5'} Super Likes have been added to your account!</p>`,
        'https://greengo.app',
        'Use Super Like'
      ),
    },
    spotlight_purchased: {
      subject: 'Spotlight ready to use!',
      htmlContent: baseTemplate(
        'Spotlight Ready!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your Spotlight is ready! Get featured on the Discover page and get more matches.</p>`,
        'https://greengo.app/spotlight',
        'Activate Spotlight'
      ),
    },
    spotlight_activated: {
      subject: 'You\'re in the Spotlight!',
      htmlContent: baseTemplate(
        'Spotlight Active!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">You're now featured on the Discover page! Expect more profile views and matches.</p>`,
        'https://greengo.app',
        'Check Your Profile'
      ),
    },
    spotlight_expired: {
      subject: 'Spotlight ended',
      htmlContent: baseTemplate(
        'Spotlight Results',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your Spotlight has ended. Here are your results:</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; margin: 20px 0;">
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Profile views:</strong> ${variables.views || '0'}</p>
          <p style="color: ${branding.textColor}; margin: 0;"><strong>New matches:</strong> ${variables.matches || '0'}</p>
        </div>`,
        'https://greengo.app/spotlight',
        'Get Another Spotlight'
      ),
    },
    bundle_purchased: {
      subject: 'Bundle unlocked!',
      htmlContent: baseTemplate(
        'Bundle Activated!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your ${variables.bundleName || 'bundle'} has been activated!</p>`,
        'https://greengo.app',
        'Use Your Items'
      ),
    },
    purchase_refunded: {
      subject: 'Refund processed',
      htmlContent: baseTemplate(
        'Refund Complete',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your refund of ${variables.amount || '$0.00'} has been processed.</p>`,
        'https://greengo.app/support',
        'Contact Support'
      ),
    },
    invoice_generated: {
      subject: `Invoice #${variables.invoiceNumber || ''}`,
      htmlContent: baseTemplate(
        'Your Invoice',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your invoice is ready. Please find the details below.</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; margin: 20px 0;">
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Invoice #:</strong> ${variables.invoiceNumber || 'N/A'}</p>
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Amount:</strong> ${variables.amount || '$0.00'}</p>
          <p style="color: ${branding.textColor}; margin: 0;"><strong>Date:</strong> ${variables.date || new Date().toLocaleDateString()}</p>
        </div>`,
        variables.invoiceUrl || 'https://greengo.app/invoices',
        'Download Invoice'
      ),
    },
    payment_receipt: {
      subject: 'Payment receipt',
      htmlContent: baseTemplate(
        'Payment Received',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Thank you for your payment!</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; margin: 20px 0;">
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Amount:</strong> ${variables.amount || '$0.00'}</p>
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Description:</strong> ${variables.description || 'Purchase'}</p>
          <p style="color: ${branding.textColor}; margin: 0;"><strong>Transaction ID:</strong> ${variables.transactionId || 'N/A'}</p>
        </div>`,
        'https://greengo.app/billing',
        'View Billing History'
      ),
    },
    payment_failed: {
      subject: 'Payment failed',
      htmlContent: baseTemplate(
        'Payment Failed',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">We couldn't process your payment. Please try again or use a different payment method.</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6; font-size: 12px;">Reason: ${variables.reason || 'Payment declined'}</p>`,
        'https://greengo.app/payment-methods',
        'Update Payment'
      ),
    },
    // Gamification
    achievement_unlocked: {
      subject: `Achievement Unlocked: ${variables.achievementName || 'New Achievement'}!`,
      htmlContent: baseTemplate(
        'Achievement Unlocked!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Congratulations! You've unlocked a new achievement!</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; text-align: center; margin: 20px 0;">
          <p style="font-size: 48px; margin: 0;">${variables.achievementIcon || '🏆'}</p>
          <h3 style="color: ${branding.primaryColor}; margin: 10px 0;">${variables.achievementName || 'Achievement'}</h3>
          <p style="color: ${branding.mutedColor}; margin: 0;">${variables.achievementDescription || ''}</p>
        </div>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Reward: +${variables.xpReward || '0'} XP</p>`,
        'https://greengo.app/achievements',
        'View Achievements'
      ),
    },
    badge_earned: {
      subject: `New Badge: ${variables.badgeName || 'Badge'}!`,
      htmlContent: baseTemplate(
        'Badge Earned!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">You've earned a new badge!</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; text-align: center; margin: 20px 0;">
          <p style="font-size: 48px; margin: 0;">${variables.badgeIcon || '🎖️'}</p>
          <h3 style="color: ${branding.primaryColor}; margin: 10px 0;">${variables.badgeName || 'Badge'}</h3>
        </div>`,
        'https://greengo.app/badges',
        'View Badges'
      ),
    },
    level_up: {
      subject: `Level Up! You're now Level ${variables.newLevel || '?'}!`,
      htmlContent: baseTemplate(
        'Level Up!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Congratulations! You've reached Level ${variables.newLevel || '?'}!</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">New perks unlocked!</p>`,
        'https://greengo.app/profile',
        'View Profile'
      ),
    },
    daily_streak_milestone: {
      subject: `${variables.streakDays || '0'} Day Streak!`,
      htmlContent: baseTemplate(
        'Streak Milestone!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Amazing! You've maintained a ${variables.streakDays || '0'}-day login streak!</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Bonus: +${variables.bonusCoins || '0'} coins!</p>`,
        'https://greengo.app',
        'Keep it Going'
      ),
    },
    streak_at_risk: {
      subject: 'Don\'t lose your streak!',
      htmlContent: baseTemplate(
        'Streak at Risk!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your ${variables.streakDays || '0'}-day streak is at risk! Log in before midnight to keep it going.</p>`,
        'https://greengo.app',
        'Save Your Streak'
      ),
    },
    streak_lost: {
      subject: 'Streak lost',
      htmlContent: baseTemplate(
        'Streak Ended',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your ${variables.previousStreak || '0'}-day streak has ended. Start a new one today!</p>`,
        'https://greengo.app',
        'Start New Streak'
      ),
    },
    leaderboard_rank_up: {
      subject: `You moved up to #${variables.newRank || '?'}!`,
      htmlContent: baseTemplate(
        'Rank Up!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">You've climbed to #${variables.newRank || '?'} on the leaderboard!</p>`,
        'https://greengo.app/leaderboard',
        'View Leaderboard'
      ),
    },
    leaderboard_top_10: {
      subject: 'You\'re in the Top 10!',
      htmlContent: baseTemplate(
        'Top 10!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Incredible! You've made it to the Top 10 on the leaderboard!</p>`,
        'https://greengo.app/leaderboard',
        'View Leaderboard'
      ),
    },
    weekly_challenge_started: {
      subject: 'New Weekly Challenge!',
      htmlContent: baseTemplate(
        'New Challenge!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">A new weekly challenge has started: ${variables.challengeName || 'Challenge'}!</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Reward: ${variables.reward || 'Special prize'}</p>`,
        'https://greengo.app/challenges',
        'Start Challenge'
      ),
    },
    weekly_challenge_completed: {
      subject: 'Challenge Completed!',
      htmlContent: baseTemplate(
        'Challenge Complete!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">You've completed the ${variables.challengeName || 'weekly'} challenge!</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Reward: ${variables.reward || 'Claimed!'}</p>`,
        'https://greengo.app/challenges',
        'View Challenges'
      ),
    },
    milestone_reached: {
      subject: 'Milestone Reached!',
      htmlContent: baseTemplate(
        'Milestone!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">You've reached a new milestone: ${variables.milestoneName || 'Milestone'}!</p>`,
        'https://greengo.app/milestones',
        'View Milestones'
      ),
    },
    reward_unlocked: {
      subject: 'Reward Unlocked!',
      htmlContent: baseTemplate(
        'New Reward!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">You've unlocked a new reward: ${variables.rewardName || 'Reward'}!</p>`,
        'https://greengo.app/rewards',
        'Claim Reward'
      ),
    },
    xp_bonus_earned: {
      subject: `+${variables.xpAmount || '0'} XP Bonus!`,
      htmlContent: baseTemplate(
        'XP Bonus!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">You earned a bonus of ${variables.xpAmount || '0'} XP!</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Reason: ${variables.reason || 'Bonus activity'}</p>`,
        'https://greengo.app/profile',
        'View Progress'
      ),
    },
    seasonal_event_started: {
      subject: `${variables.eventName || 'Seasonal Event'} is here!`,
      htmlContent: baseTemplate(
        'Seasonal Event!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">The ${variables.eventName || 'seasonal event'} has started! Participate for exclusive rewards.</p>`,
        'https://greengo.app/events',
        'Join Event'
      ),
    },
    seasonal_reward_earned: {
      subject: 'Seasonal Reward Earned!',
      htmlContent: baseTemplate(
        'Seasonal Reward!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">You've earned a seasonal reward: ${variables.rewardName || 'Exclusive item'}!</p>`,
        'https://greengo.app/inventory',
        'View Inventory'
      ),
    },
    // Social
    new_match: {
      subject: 'You have a new match!',
      htmlContent: baseTemplate(
        'It\'s a Match!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">You and ${variables.matchName || 'someone special'} have matched!</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Don't keep them waiting - say hello!</p>`,
        'https://greengo.app/matches',
        'Send a Message'
      ),
    },
    super_like_received: {
      subject: 'Someone Super Liked you!',
      htmlContent: baseTemplate(
        'Super Like!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">${variables.fromName || 'Someone'} Super Liked you! This means they really want to connect with you.</p>`,
        'https://greengo.app/likes',
        'See Who'
      ),
    },
    message_received: {
      subject: `New message from ${variables.fromName || 'your match'}`,
      htmlContent: baseTemplate(
        'New Message',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">You have a new message from ${variables.fromName || 'your match'}!</p>`,
        'https://greengo.app/messages',
        'Read Message'
      ),
    },
    profile_viewed: {
      subject: 'Someone viewed your profile',
      htmlContent: baseTemplate(
        'Profile View',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">${variables.viewerName || 'Someone'} checked out your profile!</p>`,
        'https://greengo.app/views',
        'See Who'
      ),
    },
    mutual_interest: {
      subject: 'Mutual interest detected!',
      htmlContent: baseTemplate(
        'Mutual Interest!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">You and ${variables.userName || 'someone'} have mutual interest! Match potential is high.</p>`,
        'https://greengo.app/discover',
        'View Profile'
      ),
    },
    match_about_to_expire: {
      subject: 'Your match is about to expire!',
      htmlContent: baseTemplate(
        'Match Expiring',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your match with ${variables.matchName || 'someone special'} expires in ${variables.hoursLeft || '24'} hours. Send a message before it's too late!</p>`,
        'https://greengo.app/matches',
        'Send Message Now'
      ),
    },
    match_expired: {
      subject: 'Match expired',
      htmlContent: baseTemplate(
        'Match Expired',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your match with ${variables.matchName || 'someone'} has expired. Keep swiping to find more connections!</p>`,
        'https://greengo.app/discover',
        'Keep Discovering'
      ),
    },
    icebreaker_received: {
      subject: 'You got an icebreaker!',
      htmlContent: baseTemplate(
        'Icebreaker!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">${variables.fromName || 'Someone'} sent you an icebreaker: "${variables.icebreaker || 'Hey there!'}"</p>`,
        'https://greengo.app/messages',
        'Respond'
      ),
    },
    video_call_missed: {
      subject: 'Missed video call',
      htmlContent: baseTemplate(
        'Missed Call',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">You missed a video call from ${variables.callerName || 'your match'}.</p>`,
        'https://greengo.app/messages',
        'Call Back'
      ),
    },
    video_call_scheduled: {
      subject: 'Video date scheduled!',
      htmlContent: baseTemplate(
        'Date Scheduled',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your video date with ${variables.matchName || 'your match'} is scheduled for ${variables.dateTime || 'soon'}!</p>`,
        'https://greengo.app/dates',
        'View Details'
      ),
    },
    compatibility_score_high: {
      subject: 'High compatibility match found!',
      htmlContent: baseTemplate(
        'High Compatibility!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">We found someone with ${variables.score || '90'}% compatibility with you!</p>`,
        'https://greengo.app/discover',
        'Check Them Out'
      ),
    },
    date_suggestion: {
      subject: 'Date idea for you!',
      htmlContent: baseTemplate(
        'Date Suggestion',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Based on your interests, we suggest: ${variables.suggestion || 'a coffee date'}!</p>`,
        'https://greengo.app/dates',
        'View Suggestions'
      ),
    },
    // Engagement
    welcome_series_day_1: {
      subject: 'Tips to get more matches',
      htmlContent: baseTemplate(
        'Day 1: Get More Matches',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Here are some tips to improve your profile and get more matches:</p>
        <ul style="color: ${branding.mutedColor}; line-height: 1.8;">
          <li>Add at least 4 photos</li>
          <li>Write a bio that shows your personality</li>
          <li>Be specific about your interests</li>
        </ul>`,
        'https://greengo.app/profile/edit',
        'Improve Profile'
      ),
    },
    welcome_series_day_3: {
      subject: 'How to start great conversations',
      htmlContent: baseTemplate(
        'Day 3: Conversation Tips',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Ready to make connections? Here's how to start great conversations:</p>
        <ul style="color: ${branding.mutedColor}; line-height: 1.8;">
          <li>Reference something from their profile</li>
          <li>Ask open-ended questions</li>
          <li>Be genuine and authentic</li>
        </ul>`,
        'https://greengo.app/matches',
        'View Matches'
      ),
    },
    welcome_series_day_7: {
      subject: 'Your first week recap',
      htmlContent: baseTemplate(
        'Your First Week',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Here's what happened in your first week:</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; margin: 20px 0;">
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Profile views:</strong> ${variables.views || '0'}</p>
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Likes received:</strong> ${variables.likes || '0'}</p>
          <p style="color: ${branding.textColor}; margin: 0;"><strong>Matches:</strong> ${variables.matches || '0'}</p>
        </div>`,
        'https://greengo.app',
        'Keep Going'
      ),
    },
    weekly_digest: {
      subject: 'Your week on GreenGo',
      htmlContent: baseTemplate(
        'Weekly Digest',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Here's your weekly recap:</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; margin: 20px 0;">
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>New matches:</strong> ${variables.newMatches || '0'}</p>
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Messages:</strong> ${variables.messages || '0'}</p>
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Profile views:</strong> ${variables.views || '0'}</p>
          <p style="color: ${branding.textColor}; margin: 0;"><strong>Likes received:</strong> ${variables.likes || '0'}</p>
        </div>`,
        'https://greengo.app',
        'View Details'
      ),
    },
    monthly_recap: {
      subject: 'Your month in review',
      htmlContent: baseTemplate(
        'Monthly Recap',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Here's your monthly summary:</p>
        <div style="background: ${branding.backgroundColor}; border-radius: 12px; padding: 20px; margin: 20px 0;">
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Total matches:</strong> ${variables.totalMatches || '0'}</p>
          <p style="color: ${branding.textColor}; margin: 0 0 10px 0;"><strong>Conversations:</strong> ${variables.conversations || '0'}</p>
          <p style="color: ${branding.textColor}; margin: 0;"><strong>Time on app:</strong> ${variables.timeOnApp || '0 hours'}</p>
        </div>`,
        'https://greengo.app',
        'Keep Going'
      ),
    },
    profile_incomplete_reminder: {
      subject: 'Complete your profile to get more matches',
      htmlContent: baseTemplate(
        'Complete Your Profile',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Your profile is ${variables.completeness || '50'}% complete. Add more details to increase your chances of matching!</p>`,
        'https://greengo.app/profile/edit',
        'Complete Profile'
      ),
    },
    inactive_7_days: {
      subject: 'We miss you!',
      htmlContent: baseTemplate(
        'We Miss You',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">It's been a week since your last visit. ${variables.newLikes || 'Several people'} have liked your profile!</p>`,
        'https://greengo.app',
        'Come Back'
      ),
    },
    inactive_14_days: {
      subject: `${variables.likesCount || 'People'} are waiting for you!`,
      htmlContent: baseTemplate(
        'People Are Waiting',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">${variables.likesCount || 'Several people'} have liked your profile while you were away!</p>`,
        'https://greengo.app/likes',
        'See Who Likes You'
      ),
    },
    inactive_30_days: {
      subject: 'Special offer to come back',
      htmlContent: baseTemplate(
        'Welcome Back Offer',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">We want you back! Here's a special offer: ${variables.offer || '50% off Premium for your first month'}!</p>`,
        'https://greengo.app/subscription',
        'Claim Offer'
      ),
    },
    new_feature_announcement: {
      subject: `New feature: ${variables.featureName || 'Something exciting'}!`,
      htmlContent: baseTemplate(
        'New Feature!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">We just launched ${variables.featureName || 'an exciting new feature'}!</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">${variables.featureDescription || 'Check it out!'}</p>`,
        'https://greengo.app',
        'Try It Now'
      ),
    },
    special_offer: {
      subject: 'Special offer for you!',
      htmlContent: baseTemplate(
        'Special Offer',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">${variables.offerDescription || 'We have a special offer just for you!'}</p>`,
        variables.offerUrl || 'https://greengo.app/offers',
        'Claim Offer'
      ),
    },
    feedback_request: {
      subject: 'How are we doing?',
      htmlContent: baseTemplate(
        'We Value Your Feedback',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">We'd love to hear about your GreenGo experience. Your feedback helps us improve!</p>`,
        'https://greengo.app/feedback',
        'Share Feedback'
      ),
    },
    birthday_greeting: {
      subject: 'Happy Birthday!',
      htmlContent: baseTemplate(
        'Happy Birthday!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">The GreenGo team wishes you a wonderful birthday!</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Here's a special gift: ${variables.gift || '5 free Super Likes'}!</p>`,
        'https://greengo.app',
        'Claim Gift'
      ),
    },
    anniversary_reminder: {
      subject: `${variables.years || '1'} year on GreenGo!`,
      htmlContent: baseTemplate(
        'Anniversary!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Congratulations! You've been on GreenGo for ${variables.years || '1'} year${variables.years > 1 ? 's' : ''}!</p>`,
        'https://greengo.app',
        'Celebrate'
      ),
    },
    tips_and_suggestions: {
      subject: 'Tips to improve your experience',
      htmlContent: baseTemplate(
        'Tips & Suggestions',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">Here are some personalized tips to improve your GreenGo experience:</p>
        <ul style="color: ${branding.mutedColor}; line-height: 1.8;">
          ${(variables.tips || ['Be active daily', 'Update your photos']).map((tip: string) => `<li>${tip}</li>`).join('')}
        </ul>`,
        'https://greengo.app',
        'Apply Tips'
      ),
    },
    re_engagement: {
      subject: 'We miss you! Come back to GreenGo',
      htmlContent: baseTemplate(
        'Come Back!',
        `<p style="color: ${branding.mutedColor}; line-height: 1.6;">It's been a while since we've seen you. ${variables.newLikes || 'People'} have liked your profile!</p>
        <p style="color: ${branding.mutedColor}; line-height: 1.6;">Don't miss out on potential connections.</p>`,
        'https://greengo.app',
        'Return to GreenGo'
      ),
    },
  };

  return templates[trigger] || templates.welcome;
}

// ============================================================================
// CORE EMAIL SENDING FUNCTION
// ============================================================================

async function sendBrevoEmail(params: SendEmailParams): Promise<{ messageId: string; emailLogId: string }> {
  const { userId, trigger, variables = {}, overrideEmail } = params;

  // Get user data
  const userDoc = await db.collection('users').doc(userId).get();
  if (!userDoc.exists) {
    throw new Error(`User ${userId} not found`);
  }

  const userData = userDoc.data()!;
  const recipientEmail = overrideEmail || userData.email;
  const recipientName = userData.displayName || userData.firstName || 'User';

  if (!recipientEmail) {
    throw new Error(`No email address for user ${userId}`);
  }

  // Check email preferences
  const category = getEmailCategory(trigger);
  const emailPrefs = userData.emailPreferences || {};

  // Check if user has disabled this email category
  if (emailPrefs[category] === false) {
    logInfo(`Email ${trigger} skipped for user ${userId} - category ${category} disabled`);
    throw new Error(`Email category ${category} disabled by user`);
  }

  // Get custom template from Firestore or use default
  let emailContent: { subject: string; htmlContent: string };
  const templateDoc = await db.collection('email_templates').doc(trigger).get();

  if (templateDoc.exists && templateDoc.data()?.isActive) {
    const template = templateDoc.data()!;
    emailContent = {
      subject: renderTemplateString(template.subject, { ...variables, userName: recipientName }),
      htmlContent: renderTemplateString(template.htmlContent, { ...variables, userName: recipientName }),
    };
  } else {
    emailContent = getDefaultTemplate(trigger, { ...variables, userName: recipientName });
  }

  // Create email log entry
  const emailLogRef = db.collection('email_logs').doc();
  const emailLog: Omit<EmailLog, 'id'> = {
    userId,
    recipientEmail,
    recipientName,
    trigger,
    category,
    subject: emailContent.subject,
    templateId: templateDoc.exists ? trigger : undefined,
    status: 'pending',
    variables,
    createdAt: admin.firestore.FieldValue.serverTimestamp() as admin.firestore.Timestamp,
  };

  await emailLogRef.set(emailLog);

  try {
    // Send via Brevo API
    const payload = {
      sender: {
        email: BREVO_SENDER_EMAIL,
        name: BREVO_SENDER_NAME,
      },
      to: [
        {
          email: recipientEmail,
          name: recipientName,
        },
      ],
      subject: emailContent.subject,
      htmlContent: emailContent.htmlContent,
      tags: [category, trigger],
    };

    const response = await brevoApiRequest<{ messageId: string }>('/smtp/email', 'POST', payload);

    // Update email log
    await emailLogRef.update({
      status: 'sent',
      brevoMessageId: response.messageId,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logInfo(`Email ${trigger} sent to ${recipientEmail} (user: ${userId})`);

    // Update email analytics
    await updateEmailAnalytics(category, trigger, 'sent');

    return { messageId: response.messageId, emailLogId: emailLogRef.id };
  } catch (error: any) {
    // Update email log with error
    await emailLogRef.update({
      status: 'failed',
      error: error.message || 'Unknown error',
    });

    logError(`Failed to send email ${trigger} to ${recipientEmail}:`, error);
    throw error;
  }
}

function renderTemplateString(template: string, variables: Record<string, any>): string {
  let rendered = template;
  Object.entries(variables).forEach(([key, value]) => {
    const regex = new RegExp(`\\{\\{${key}\\}\\}|\\$\\{variables\\.${key}\\}`, 'g');
    rendered = rendered.replace(regex, String(value ?? ''));
  });
  return rendered;
}

async function updateEmailAnalytics(category: EmailCategory, trigger: EmailTrigger, action: 'sent' | 'delivered' | 'opened' | 'clicked' | 'bounced'): Promise<void> {
  const today = new Date().toISOString().split('T')[0];
  const analyticsRef = db.collection('email_analytics').doc(today);

  await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(analyticsRef);

    if (!doc.exists) {
      transaction.set(analyticsRef, {
        date: today,
        total: { sent: 0, delivered: 0, opened: 0, clicked: 0, bounced: 0 },
        byCategory: {},
        byTrigger: {},
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    transaction.update(analyticsRef, {
      [`total.${action}`]: admin.firestore.FieldValue.increment(1),
      [`byCategory.${category}.${action}`]: admin.firestore.FieldValue.increment(1),
      [`byTrigger.${trigger}.${action}`]: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

// ============================================================================
// CLOUD FUNCTIONS
// ============================================================================

// 1. Send Email (HTTP Callable)
interface SendBrevoEmailRequest {
  userId: string;
  trigger: EmailTrigger;
  variables?: Record<string, any>;
  overrideEmail?: string;
}

export const sendBrevoEmailFunction = onCall<SendBrevoEmailRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAuth(request.auth);
      const { userId, trigger, variables, overrideEmail } = request.data;

      if (!userId || !trigger) {
        throw new HttpsError('invalid-argument', 'userId and trigger are required');
      }

      const result = await sendBrevoEmail({ userId, trigger, variables, overrideEmail });

      return {
        success: true,
        messageId: result.messageId,
        emailLogId: result.emailLogId,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// 2. Get Email Templates (HTTP Callable)
export const getBrevoEmailTemplates = onCall(
  {
    memory: '128MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      await verifyAuth(request.auth);

      const snapshot = await db.collection('email_templates').get();
      const templates: EmailTemplate[] = [];

      snapshot.forEach((doc) => {
        templates.push({ id: doc.id, ...doc.data() } as EmailTemplate);
      });

      return {
        success: true,
        templates,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// 3. Update Email Template (HTTP Callable)
interface UpdateTemplateRequest {
  trigger: EmailTrigger;
  name: string;
  subject: string;
  htmlContent: string;
  textContent?: string;
  isActive: boolean;
  variables: string[];
}

export const updateBrevoEmailTemplate = onCall<UpdateTemplateRequest>(
  {
    memory: '128MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      await verifyAuth(request.auth);
      const { trigger, name, subject, htmlContent, textContent, isActive, variables } = request.data;

      if (!trigger || !name || !subject || !htmlContent) {
        throw new HttpsError('invalid-argument', 'trigger, name, subject, and htmlContent are required');
      }

      const templateRef = db.collection('email_templates').doc(trigger);
      const templateDoc = await templateRef.get();

      const templateData: Partial<EmailTemplate> = {
        trigger,
        category: getEmailCategory(trigger),
        name,
        subject,
        htmlContent,
        textContent,
        isActive,
        variables,
        updatedAt: admin.firestore.FieldValue.serverTimestamp() as admin.firestore.Timestamp,
      };

      if (!templateDoc.exists) {
        templateData.createdAt = admin.firestore.FieldValue.serverTimestamp() as admin.firestore.Timestamp;
      }

      await templateRef.set(templateData, { merge: true });

      return {
        success: true,
        message: `Template ${trigger} updated`,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// 4. Get Email Logs (HTTP Callable)
interface GetEmailLogsRequest {
  userId?: string;
  category?: EmailCategory;
  trigger?: EmailTrigger;
  status?: string;
  limit?: number;
  offset?: number;
}

export const getBrevoEmailLogs = onCall<GetEmailLogsRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAuth(request.auth);
      const { userId, category, trigger, status, limit = 50, offset = 0 } = request.data;

      let query: admin.firestore.Query = db.collection('email_logs');

      if (userId) query = query.where('userId', '==', userId);
      if (category) query = query.where('category', '==', category);
      if (trigger) query = query.where('trigger', '==', trigger);
      if (status) query = query.where('status', '==', status);

      query = query.orderBy('createdAt', 'desc').limit(limit).offset(offset);

      const snapshot = await query.get();
      const logs: EmailLog[] = [];

      snapshot.forEach((doc) => {
        logs.push({ id: doc.id, ...doc.data() } as EmailLog);
      });

      return {
        success: true,
        logs,
        count: logs.length,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// 5. Get Email Analytics (HTTP Callable)
interface GetEmailAnalyticsRequest {
  startDate?: string;
  endDate?: string;
}

export const getBrevoEmailAnalytics = onCall<GetEmailAnalyticsRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAuth(request.auth);
      const { startDate, endDate } = request.data;

      const start = startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
      const end = endDate || new Date().toISOString().split('T')[0];

      const snapshot = await db
        .collection('email_analytics')
        .where('date', '>=', start)
        .where('date', '<=', end)
        .orderBy('date', 'asc')
        .get();

      const analytics: any[] = [];
      const totals = { sent: 0, delivered: 0, opened: 0, clicked: 0, bounced: 0 };

      snapshot.forEach((doc) => {
        const data = doc.data();
        analytics.push(data);

        if (data.total) {
          totals.sent += data.total.sent || 0;
          totals.delivered += data.total.delivered || 0;
          totals.opened += data.total.opened || 0;
          totals.clicked += data.total.clicked || 0;
          totals.bounced += data.total.bounced || 0;
        }
      });

      const openRate = totals.delivered > 0 ? (totals.opened / totals.delivered) * 100 : 0;
      const clickRate = totals.opened > 0 ? (totals.clicked / totals.opened) * 100 : 0;
      const bounceRate = totals.sent > 0 ? (totals.bounced / totals.sent) * 100 : 0;

      return {
        success: true,
        startDate: start,
        endDate: end,
        totals,
        rates: { openRate, clickRate, bounceRate },
        dailyData: analytics,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// 6. Process Brevo Webhooks (HTTP endpoint)
// Note: This would need an HTTP trigger for Brevo webhook callbacks
// export const brevoWebhook = onRequest(...)

// ============================================================================
// TRIGGER-BASED EMAIL FUNCTIONS
// ============================================================================

// User Created - Send Welcome Email
export const onUserCreatedSendWelcome = onDocumentCreated(
  'users/{userId}',
  async (event) => {
    const userId = event.params.userId;
    const userData = event.data?.data();

    if (!userData?.email) {
      logInfo(`No email for new user ${userId}, skipping welcome email`);
      return;
    }

    try {
      await sendBrevoEmail({
        userId,
        trigger: 'welcome',
        variables: {
          userName: userData.displayName || userData.firstName || 'there',
        },
      });
    } catch (error) {
      logError(`Failed to send welcome email to ${userId}:`, error);
    }
  }
);

// Subscription Updated - Send Appropriate Email
export const onSubscriptionUpdated = onDocumentUpdated(
  'subscriptions/{subscriptionId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;

    const userId = after.userId;

    try {
      // Subscription started
      if (!before.isActive && after.isActive && !before.startDate) {
        await sendBrevoEmail({
          userId,
          trigger: 'subscription_started',
          variables: {
            planName: after.planName,
            amount: after.amount,
            nextBillingDate: after.nextBillingDate,
          },
        });
      }
      // Subscription renewed
      else if (before.endDate !== after.endDate && after.isActive) {
        await sendBrevoEmail({
          userId,
          trigger: 'subscription_renewed',
          variables: {
            planName: after.planName,
            amount: after.amount,
            nextBillingDate: after.nextBillingDate,
          },
        });
      }
      // Subscription cancelled
      else if (before.isActive && !after.isActive && after.cancelledAt) {
        await sendBrevoEmail({
          userId,
          trigger: 'subscription_cancelled',
          variables: {
            planName: after.planName,
            endDate: after.endDate,
          },
        });
      }
      // Subscription expired
      else if (before.isActive && !after.isActive && !after.cancelledAt) {
        await sendBrevoEmail({
          userId,
          trigger: 'subscription_expired',
          variables: {
            planName: after.planName,
          },
        });
      }
      // Payment failed
      else if (after.paymentStatus === 'failed' && before.paymentStatus !== 'failed') {
        await sendBrevoEmail({
          userId,
          trigger: 'subscription_payment_failed',
          variables: {
            planName: after.planName,
            failureReason: after.failureReason,
          },
        });
      }
    } catch (error) {
      logError(`Failed to send subscription email for ${userId}:`, error);
    }
  }
);

// Photo Moderation - Send Approval/Rejection Email
export const onPhotoModerationUpdated = onDocumentUpdated(
  'photo_moderation/{moderationId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;
    if (before.status === after.status) return; // No status change

    const userId = after.userId;

    try {
      if (after.status === 'approved') {
        await sendBrevoEmail({
          userId,
          trigger: 'photo_approved',
        });
      } else if (after.status === 'rejected') {
        await sendBrevoEmail({
          userId,
          trigger: 'photo_rejected',
          variables: {
            reason: after.rejectionReason,
          },
        });
      }
    } catch (error) {
      logError(`Failed to send photo moderation email for ${userId}:`, error);
    }
  }
);

// Achievement Unlocked - Send Email
export const onAchievementUnlocked = onDocumentCreated(
  'user_achievements/{achievementId}',
  async (event) => {
    const achievementData = event.data?.data();
    if (!achievementData) return;

    const userId = achievementData.userId;

    try {
      await sendBrevoEmail({
        userId,
        trigger: 'achievement_unlocked',
        variables: {
          achievementName: achievementData.name,
          achievementDescription: achievementData.description,
          achievementIcon: achievementData.icon,
          xpReward: achievementData.xpReward,
        },
      });
    } catch (error) {
      logError(`Failed to send achievement email for ${userId}:`, error);
    }
  }
);

// New Match - Send Email
export const onNewMatch = onDocumentCreated(
  'matches/{matchId}',
  async (event) => {
    const matchData = event.data?.data();
    if (!matchData) return;

    const [userId1, userId2] = matchData.participants || [];

    try {
      // Get both users' names
      const [user1Doc, user2Doc] = await Promise.all([
        db.collection('users').doc(userId1).get(),
        db.collection('users').doc(userId2).get(),
      ]);

      const user1Name = user1Doc.data()?.displayName || 'Someone';
      const user2Name = user2Doc.data()?.displayName || 'Someone';

      // Send to both users
      await Promise.all([
        sendBrevoEmail({
          userId: userId1,
          trigger: 'new_match',
          variables: { matchName: user2Name },
        }),
        sendBrevoEmail({
          userId: userId2,
          trigger: 'new_match',
          variables: { matchName: user1Name },
        }),
      ]);
    } catch (error) {
      logError('Failed to send match emails:', error);
    }
  }
);

// Purchase Created - Send Email
export const onPurchaseCreated = onDocumentCreated(
  'purchases/{purchaseId}',
  async (event) => {
    const purchaseData = event.data?.data();
    if (!purchaseData) return;

    const userId = purchaseData.userId;
    const purchaseType = purchaseData.type;

    try {
      let trigger: EmailTrigger;
      const variables: Record<string, any> = {};

      switch (purchaseType) {
        case 'coins':
          trigger = 'coins_purchased';
          variables.coinsAmount = purchaseData.coinsAmount;
          variables.amount = purchaseData.amount;
          variables.newBalance = purchaseData.newBalance;
          break;
        case 'boost':
          trigger = 'boost_purchased';
          variables.duration = purchaseData.duration;
          break;
        case 'super_like':
          trigger = 'super_like_purchased';
          variables.amount = purchaseData.quantity;
          break;
        case 'spotlight':
          trigger = 'spotlight_purchased';
          break;
        case 'shop_item':
          trigger = 'shop_item_purchased';
          variables.itemName = purchaseData.itemName;
          variables.cost = purchaseData.cost;
          break;
        default:
          trigger = 'payment_receipt';
          variables.amount = purchaseData.amount;
          variables.description = purchaseData.description;
          variables.transactionId = purchaseData.transactionId;
      }

      await sendBrevoEmail({
        userId,
        trigger,
        variables,
      });
    } catch (error) {
      logError(`Failed to send purchase email for ${userId}:`, error);
    }
  }
);

// ============================================================================
// SCHEDULED FUNCTIONS
// ============================================================================

// Send Weekly Digest - Every Monday at 9 AM
export const sendBrevoWeeklyDigest = onSchedule(
  {
    schedule: '0 9 * * 1',
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
  },
  async () => {
    logInfo('Starting weekly digest email job');

    try {
      const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

      // Get active users
      const usersSnapshot = await db
        .collection('users')
        .where('accountStatus', '==', 'active')
        .where('lastActiveAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
        .limit(1000)
        .get();

      let sent = 0;
      let skipped = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();

        // Check email preferences
        if (userData.emailPreferences?.engagement === false) {
          skipped++;
          continue;
        }

        try {
          // Get weekly stats
          const [matchesSnap, messagesSnap, viewsSnap, likesSnap] = await Promise.all([
            db.collection('matches')
              .where('participants', 'array-contains', userId)
              .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
              .count().get(),
            db.collection('messages')
              .where('receiverId', '==', userId)
              .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
              .count().get(),
            db.collection('profile_views')
              .where('profileId', '==', userId)
              .where('viewedAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
              .count().get(),
            db.collection('likes')
              .where('likedUserId', '==', userId)
              .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
              .count().get(),
          ]);

          const newMatches = matchesSnap.data().count;
          const messages = messagesSnap.data().count;
          const views = viewsSnap.data().count;
          const likes = likesSnap.data().count;

          // Only send if there's activity
          if (newMatches > 0 || messages > 0 || views > 0 || likes > 0) {
            await sendBrevoEmail({
              userId,
              trigger: 'weekly_digest',
              variables: { newMatches, messages, views, likes },
            });
            sent++;
          } else {
            skipped++;
          }
        } catch (error) {
          logError(`Failed to send weekly digest to ${userId}:`, error);
        }
      }

      logInfo(`Weekly digest complete: ${sent} sent, ${skipped} skipped`);
    } catch (error) {
      logError('Failed to run weekly digest job:', error);
    }
  }
);

// Send Re-engagement Emails - Daily at 10 AM
export const sendBrevoReEngagement = onSchedule(
  {
    schedule: '0 10 * * *',
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
  },
  async () => {
    logInfo('Starting re-engagement email job');

    try {
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      const fourteenDaysAgo = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000);
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

      // 7 days inactive
      const inactive7Days = await db.collection('users')
        .where('accountStatus', '==', 'active')
        .where('lastActiveAt', '<', admin.firestore.Timestamp.fromDate(sevenDaysAgo))
        .where('lastActiveAt', '>=', admin.firestore.Timestamp.fromDate(fourteenDaysAgo))
        .limit(200)
        .get();

      for (const userDoc of inactive7Days.docs) {
        try {
          // Check if we already sent this email recently
          const recentEmail = await db.collection('email_logs')
            .where('userId', '==', userDoc.id)
            .where('trigger', '==', 'inactive_7_days')
            .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(sevenDaysAgo))
            .limit(1)
            .get();

          if (recentEmail.empty) {
            await sendBrevoEmail({
              userId: userDoc.id,
              trigger: 'inactive_7_days',
            });
          }
        } catch (error) {
          logError(`Failed to send 7-day re-engagement to ${userDoc.id}:`, error);
        }
      }

      // 14 days inactive
      const inactive14Days = await db.collection('users')
        .where('accountStatus', '==', 'active')
        .where('lastActiveAt', '<', admin.firestore.Timestamp.fromDate(fourteenDaysAgo))
        .where('lastActiveAt', '>=', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .limit(200)
        .get();

      for (const userDoc of inactive14Days.docs) {
        try {
          const recentEmail = await db.collection('email_logs')
            .where('userId', '==', userDoc.id)
            .where('trigger', '==', 'inactive_14_days')
            .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(sevenDaysAgo))
            .limit(1)
            .get();

          if (recentEmail.empty) {
            // Get likes count
            const likesSnap = await db.collection('likes')
              .where('likedUserId', '==', userDoc.id)
              .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(fourteenDaysAgo))
              .count().get();

            await sendBrevoEmail({
              userId: userDoc.id,
              trigger: 'inactive_14_days',
              variables: { likesCount: likesSnap.data().count },
            });
          }
        } catch (error) {
          logError(`Failed to send 14-day re-engagement to ${userDoc.id}:`, error);
        }
      }

      // 30 days inactive
      const inactive30Days = await db.collection('users')
        .where('accountStatus', '==', 'active')
        .where('lastActiveAt', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .limit(100)
        .get();

      for (const userDoc of inactive30Days.docs) {
        try {
          const recentEmail = await db.collection('email_logs')
            .where('userId', '==', userDoc.id)
            .where('trigger', '==', 'inactive_30_days')
            .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(fourteenDaysAgo))
            .limit(1)
            .get();

          if (recentEmail.empty) {
            await sendBrevoEmail({
              userId: userDoc.id,
              trigger: 'inactive_30_days',
              variables: { offer: '50% off Premium for your first month' },
            });
          }
        } catch (error) {
          logError(`Failed to send 30-day re-engagement to ${userDoc.id}:`, error);
        }
      }

      logInfo('Re-engagement email job complete');
    } catch (error) {
      logError('Failed to run re-engagement job:', error);
    }
  }
);

// Check Streak At Risk - Daily at 8 PM
export const sendBrevoStreakReminder = onSchedule(
  {
    schedule: '0 20 * * *',
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 300,
  },
  async () => {
    logInfo('Starting streak reminder job');

    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      // Get users with active streaks who haven't logged in today
      const usersWithStreaks = await db.collection('user_streaks')
        .where('currentStreak', '>', 3) // Only for streaks > 3 days
        .where('lastActivityDate', '<', admin.firestore.Timestamp.fromDate(today))
        .limit(500)
        .get();

      for (const doc of usersWithStreaks.docs) {
        const streakData = doc.data();

        try {
          await sendBrevoEmail({
            userId: streakData.userId,
            trigger: 'streak_at_risk',
            variables: { streakDays: streakData.currentStreak },
          });
        } catch (error) {
          logError(`Failed to send streak reminder to ${streakData.userId}:`, error);
        }
      }

      logInfo('Streak reminder job complete');
    } catch (error) {
      logError('Failed to run streak reminder job:', error);
    }
  }
);

// Export helper for use in other functions
export { sendBrevoEmail, getEmailCategory };
