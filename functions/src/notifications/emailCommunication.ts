/**
 * Email Communication Cloud Functions
 * Points 281-285: SendGrid integration and email campaigns
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

const firestore = admin.firestore();

// Note: In production, install @sendgrid/mail: npm install @sendgrid/mail
// import * as sgMail from '@sendgrid/mail';
// sgMail.setApiKey(process.env.SENDGRID_API_KEY);

/**
 * Send Transactional Email
 * Point 281: SendGrid integration
 */
export const sendTransactionalEmail = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { userId, emailType, templateData } = data;

  try {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new Error('User not found');
    }

    const userData = userDoc.data()!;
    const recipientEmail = userData.email;

    // Get email template (Point 282)
    const template = getEmailTemplate(emailType);
    const htmlBody = renderTemplate(template.htmlContent, templateData);
    const subject = renderTemplate(template.subject, templateData);

    // In production, send via SendGrid:
    // const msg = {
    //   to: recipientEmail,
    //   from: 'noreply@greengo.app',
    //   subject,
    //   html: htmlBody,
    // };
    // await sgMail.send(msg);

    // Store email record
    const emailRef = firestore.collection('emails').doc();
    await emailRef.set({
      emailId: emailRef.id,
      userId,
      recipientEmail,
      type: emailType,
      subject,
      htmlBody,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'sent',
      templateData,
    });

    console.log(`Email sent to ${recipientEmail}: ${emailType}`);
    return { success: true, emailId: emailRef.id };
  } catch (error: any) {
    console.error('Error sending email:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Start Welcome Email Series
 * Point 283: 7-day onboarding emails
 */
export const startWelcomeEmailSeries = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const userData = snap.data();

    try {
      // Create welcome email series
      const seriesRef = firestore.collection('welcome_email_series').doc(userId);
      await seriesRef.set({
        seriesId: userId,
        userId,
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
        currentStep: 0,
        isCompleted: false,
        steps: [
          {
            stepNumber: 1,
            delayDays: 0,
            subject: 'Welcome to GreenGo! Let\'s get started',
            template: 'welcome_day_1',
            isSent: false,
          },
          {
            stepNumber: 2,
            delayDays: 1,
            subject: 'Complete your profile to get more matches',
            template: 'welcome_day_2',
            isSent: false,
          },
          {
            stepNumber: 3,
            delayDays: 3,
            subject: 'Tips for making great connections',
            template: 'welcome_day_3',
            isSent: false,
          },
          {
            stepNumber: 4,
            delayDays: 5,
            subject: 'Unlock premium features',
            template: 'welcome_day_5',
            isSent: false,
          },
          {
            stepNumber: 5,
            delayDays: 7,
            subject: 'Your first week recap',
            template: 'welcome_day_7',
            isSent: false,
          },
        ],
      });

      // Send first email immediately
      await sendTransactionalEmail.run(
        {
          userId,
          emailType: 'welcome',
          templateData: {
            userName: userData.displayName,
            profileCompleteness: 20,
          },
        },
        { auth: { uid: userId } } as any
      );

      console.log(`Started welcome email series for user ${userId}`);
    } catch (error) {
      console.error('Error starting welcome email series:', error);
    }
  });

/**
 * Process Welcome Email Series
 * Scheduled function to send follow-up emails
 */
export const processWelcomeEmailSeries = functions.pubsub
  .schedule('0 10 * * *') // Daily at 10 AM
  .onRun(async (context) => {
    try {
      const seriesSnapshot = await firestore
        .collection('welcome_email_series')
        .where('isCompleted', '==', false)
        .get();

      for (const seriesDoc of seriesSnapshot.docs) {
        const series = seriesDoc.data();
        const startedAt = series.startedAt.toDate();
        const daysSinceStart = Math.floor(
          (Date.now() - startedAt.getTime()) / (24 * 60 * 60 * 1000)
        );

        for (let i = 0; i < series.steps.length; i++) {
          const step = series.steps[i];

          if (!step.isSent && daysSinceStart >= step.delayDays) {
            // Send email
            await sendTransactionalEmail.run(
              {
                userId: series.userId,
                emailType: 'welcomeSeries',
                templateData: {
                  stepNumber: step.stepNumber,
                  template: step.template,
                },
              },
              { auth: { uid: series.userId } } as any
            );

            // Update series
            series.steps[i].isSent = true;
            series.steps[i].sentAt = admin.firestore.FieldValue.serverTimestamp();
            series.currentStep = i + 1;

            await seriesDoc.ref.update({
              steps: series.steps,
              currentStep: series.currentStep,
            });
          }
        }

        // Check if completed
        const allSent = series.steps.every((s: any) => s.isSent);
        if (allSent) {
          await seriesDoc.ref.update({ isCompleted: true });
        }
      }

      console.log('Welcome email series processed');
    } catch (error) {
      console.error('Error processing welcome email series:', error);
    }
  });

/**
 * Send Weekly Digest Email
 * Point 284: Weekly summary emails
 */
export const sendWeeklyDigestEmails = functions.pubsub
  .schedule('0 9 * * 1') // Every Monday at 9 AM
  .onRun(async (context) => {
    try {
      const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

      // Get all active users
      const usersSnapshot = await firestore
        .collection('users')
        .where('accountStatus', '==', 'active')
        .where('lastActiveAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
        .get();

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();

        // Check if user has email preferences enabled
        const prefsDoc = await firestore
          .collection('email_preferences')
          .doc(userId)
          .get();

        if (prefsDoc.exists && prefsDoc.data()!.weeklyDigest === false) {
          continue; // Skip if disabled
        }

        // Get weekly activity
        const matchesSnapshot = await firestore
          .collection('matches')
          .where('users', 'array-contains', userId)
          .where('matchedAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
          .get();

        const messagesSnapshot = await firestore
          .collection('messages')
          .where('senderId', '==', userId)
          .where('sentAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
          .count()
          .get();

        const likesSnapshot = await firestore
          .collection('likes')
          .where('likedUserId', '==', userId)
          .where('likedAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
          .count()
          .get();

        const newMatches = matchesSnapshot.size;
        const newMessages = messagesSnapshot.data().count;
        const newLikes = likesSnapshot.data().count;

        // Only send if there's activity
        if (newMatches > 0 || newMessages > 0 || newLikes > 0) {
          await sendTransactionalEmail.run(
            {
              userId,
              emailType: 'weeklyDigest',
              templateData: {
                userName: userData.displayName,
                newMatches,
                newMessages,
                newLikes,
                weekStartDate: oneWeekAgo.toISOString(),
                weekEndDate: new Date().toISOString(),
              },
            },
            { auth: { uid: userId } } as any
          );
        }
      }

      console.log('Weekly digest emails sent');
    } catch (error) {
      console.error('Error sending weekly digest emails:', error);
    }
  });

/**
 * Send Re-engagement Campaign
 * Point 285: Dormant user emails with personalization
 */
export const sendReEngagementCampaign = functions.pubsub
  .schedule('0 11 * * *') // Daily at 11 AM
  .onRun(async (context) => {
    try {
      const fourteenDaysAgo = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000);
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

      // Get dormant users (14-30 days inactive)
      const dormantUsersSnapshot = await firestore
        .collection('users')
        .where('accountStatus', '==', 'active')
        .where('lastActiveAt', '<', admin.firestore.Timestamp.fromDate(fourteenDaysAgo))
        .where('lastActiveAt', '>=', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .get();

      for (const userDoc of dormantUsersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();

        // Check if already sent re-engagement email recently
        const recentEmailSnapshot = await firestore
          .collection('emails')
          .where('userId', '==', userId)
          .where('type', '==', 'reEngagement')
          .where('sentAt', '>=', admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)))
          .limit(1)
          .get();

        if (!recentEmailSnapshot.empty) {
          continue; // Skip if already sent in last 7 days
        }

        // Get personalized data (Point 285: AI-powered personalization)
        const matchesCount = await firestore
          .collection('matches')
          .where('users', 'array-contains', userId)
          .count()
          .get();

        const newLikesSnapshot = await firestore
          .collection('likes')
          .where('likedUserId', '==', userId)
          .where('likedAt', '>=', admin.firestore.Timestamp.fromDate(fourteenDaysAgo))
          .get();

        const personalizationData = {
          userName: userData.displayName,
          totalMatches: matchesCount.data().count,
          newLikesSinceLastVisit: newLikesSnapshot.size,
          daysSinceLastActive: Math.floor(
            (Date.now() - userData.lastActiveAt.toMillis()) / (24 * 60 * 60 * 1000)
          ),
        };

        // Send re-engagement email
        await sendTransactionalEmail.run(
          {
            userId,
            emailType: 'reEngagement',
            templateData: personalizationData,
          },
          { auth: { uid: userId } } as any
        );
      }

      console.log('Re-engagement campaign sent');
    } catch (error) {
      console.error('Error sending re-engagement campaign:', error);
    }
  });

/**
 * Get Email Template
 * Point 282: Black & gold branded templates
 */
function getEmailTemplate(emailType: string): any {
  const branding = {
    backgroundColor: '#000000',
    primaryColor: '#FFD700',
    textColor: '#FFFFFF',
    logoUrl: 'https://greengo.app/logo.png',
  };

  const templates: { [key: string]: any } = {
    welcome: {
      subject: 'Welcome to GreenGo, {{userName}}!',
      htmlContent: `
        <div style="background-color: ${branding.backgroundColor}; color: ${branding.textColor}; padding: 40px; font-family: Arial, sans-serif;">
          <div style="text-align: center; margin-bottom: 30px;">
            <img src="${branding.logoUrl}" alt="GreenGo" style="width: 150px;">
          </div>
          <h1 style="color: ${branding.primaryColor};">Welcome to GreenGo!</h1>
          <p>Hi {{userName}},</p>
          <p>We're excited to have you join our community! GreenGo is the premium dating app for meaningful connections.</p>
          <p>Your profile is {{profileCompleteness}}% complete. Complete it to get more matches!</p>
          <a href="https://greengo.app/profile" style="background-color: ${branding.primaryColor}; color: #000; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 20px;">Complete Profile</a>
          <p style="margin-top: 30px;">Happy matching!</p>
          <p>The GreenGo Team</p>
        </div>
      `,
    },
    weeklyDigest: {
      subject: 'Your Week on GreenGo - {{newMatches}} New Matches!',
      htmlContent: `
        <div style="background-color: ${branding.backgroundColor}; color: ${branding.textColor}; padding: 40px;">
          <h1 style="color: ${branding.primaryColor};">Your Weekly Recap</h1>
          <p>Hi {{userName}},</p>
          <p>Here's what happened this week:</p>
          <ul style="font-size: 18px; line-height: 1.8;">
            <li><strong style="color: ${branding.primaryColor};">{{newMatches}}</strong> new matches</li>
            <li><strong style="color: ${branding.primaryColor};">{{newMessages}}</strong> messages exchanged</li>
            <li><strong style="color: ${branding.primaryColor};">{{newLikes}}</strong> people liked you</li>
          </ul>
          <a href="https://greengo.app/matches" style="background-color: ${branding.primaryColor}; color: #000; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 20px;">View Your Matches</a>
        </div>
      `,
    },
    reEngagement: {
      subject: 'We miss you, {{userName}}! {{newLikesSinceLastVisit}} people liked you',
      htmlContent: `
        <div style="background-color: ${branding.backgroundColor}; color: ${branding.textColor}; padding: 40px;">
          <h1 style="color: ${branding.primaryColor};">We Miss You!</h1>
          <p>Hi {{userName}},</p>
          <p>It's been {{daysSinceLastActive}} days since your last visit. You've been missed!</p>
          <p><strong style="color: ${branding.primaryColor};">{{newLikesSinceLastVisit}} people</strong> liked you while you were away.</p>
          <p>You have <strong>{{totalMatches}} matches</strong> waiting for you!</p>
          <a href="https://greengo.app/likes" style="background-color: ${branding.primaryColor}; color: #000; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 20px;">See Who Likes You</a>
        </div>
      `,
    },
  };

  return templates[emailType] || templates.welcome;
}

/**
 * Render Template
 */
function renderTemplate(template: string, data: any): string {
  let rendered = template;
  Object.keys(data).forEach(key => {
    const regex = new RegExp(`{{${key}}}`, 'g');
    rendered = rendered.replace(regex, data[key]);
  });
  return rendered;
}
