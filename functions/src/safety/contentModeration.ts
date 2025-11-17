/**
 * Content Moderation Cloud Functions
 * Points 201-210: AI-based content moderation
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import vision from '@google-cloud/vision';
import { LanguageServiceClient } from '@google-cloud/language';

const firestore = admin.firestore();
const visionClient = new vision.ImageAnnotatorClient();
const languageClient = new LanguageServiceClient();

/**
 * Moderate Photo using Cloud Vision API
 * Point 201: Automatic photo content moderation
 */
export const moderatePhoto = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { photoUrl, photoId, userId } = data;

  try {
    // Perform safe search detection
    const [result] = await visionClient.safeSearchDetection(photoUrl);
    const safeSearch = result.safeSearchAnnotation!;

    // Detect labels
    const [labelResult] = await visionClient.labelDetection(photoUrl);
    const labels = labelResult.labelAnnotations || [];

    // Detect faces
    const [faceResult] = await visionClient.faceDetection(photoUrl);
    const faces = faceResult.faceAnnotations || [];

    // Evaluate safety
    const violations: any[] = [];
    let isApproved = true;

    // Check adult content
    if (safeSearch.adult === 'LIKELY' || safeSearch.adult === 'VERY_LIKELY') {
      violations.push({
        type: 'nudity',
        confidence: safeSearch.adult === 'VERY_LIKELY' ? 0.9 : 0.7,
        reason: 'Adult content detected',
        severity: 'critical',
      });
      isApproved = false;
    }

    // Check violence
    if (
      safeSearch.violence === 'LIKELY' ||
      safeSearch.violence === 'VERY_LIKELY'
    ) {
      violations.push({
        type: 'violence',
        confidence: safeSearch.violence === 'VERY_LIKELY' ? 0.9 : 0.7,
        reason: 'Violent content detected',
        severity: 'high',
      });
      isApproved = false;
    }

    // Check for offensive symbols in labels
    const offensiveLabels = [
      'weapon',
      'gun',
      'knife',
      'blood',
      'hate symbol',
    ];
    labels.forEach((label) => {
      if (
        offensiveLabels.some((offensive) =>
          label.description!.toLowerCase().includes(offensive)
        )
      ) {
        violations.push({
          type: 'offensiveSymbols',
          confidence: label.score || 0.7,
          reason: `Detected: ${label.description}`,
          severity: 'high',
        });
        isApproved = false;
      }
    });

    // Store moderation result
    const moderationResult = {
      moderationId: photoId,
      contentId: photoId,
      contentType: 'photo',
      userId,
      status: isApproved ? 'approved' : 'rejected',
      flags: violations,
      overallScore: isApproved ? 0 : 0.8,
      safeSearch: {
        adult: safeSearch.adult,
        violence: safeSearch.violence,
        racy: safeSearch.racy,
        medical: safeSearch.medical,
        spoof: safeSearch.spoof,
      },
      labels: labels.map((l) => ({
        description: l.description,
        score: l.score,
      })),
      faceCount: faces.length,
      moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await firestore
      .collection('moderation_results')
      .doc(photoId)
      .set(moderationResult);

    // If rejected, create moderation queue entry (Point 209)
    if (!isApproved) {
      await createModerationQueueEntry({
        itemType: 'flaggedContent',
        itemId: photoId,
        userId,
        priority: 'high',
        metadata: {
          contentType: 'photo',
          violations,
        },
      });
    }

    return {
      isApproved,
      violations,
      safeSearch: moderationResult.safeSearch,
    };
  } catch (error: any) {
    console.error('Error moderating photo:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Moderate Text using Perspective API
 * Point 202: AI-based text moderation for toxicity
 */
export const moderateText = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { text, textId, userId } = data;

  try {
    // Use Google Cloud Natural Language API for sentiment and content classification
    const document = {
      content: text,
      type: 'PLAIN_TEXT' as const,
    };

    // Analyze sentiment
    const [sentiment] = await languageClient.analyzeSentiment({ document });
    const sentimentScore = sentiment.documentSentiment?.score || 0;
    const sentimentMagnitude = sentiment.documentSentiment?.magnitude || 0;

    // Classify content
    const [classification] = await languageClient.classifyText({ document });
    const categories = classification.categories || [];

    // Check for profanity (Point 203)
    const profanityList = await checkProfanity(text);

    // Calculate toxicity score (simplified - in production use Perspective API)
    let toxicityScore = 0;
    const violations: any[] = [];

    // Negative sentiment
    if (sentimentScore < -0.5 && sentimentMagnitude > 0.5) {
      toxicityScore += 0.3;
    }

    // Profanity detected
    if (profanityList.length > 0) {
      toxicityScore += 0.4;
      violations.push({
        type: 'profanity',
        confidence: 0.9,
        reason: `Profanity detected: ${profanityList.join(', ')}`,
        severity: 'medium',
      });
    }

    // Check for threatening language
    const threats = ['kill', 'hurt', 'harm', 'attack'];
    const lowerText = text.toLowerCase();
    if (threats.some((threat) => lowerText.includes(threat))) {
      toxicityScore += 0.5;
      violations.push({
        type: 'threat',
        confidence: 0.7,
        reason: 'Threatening language detected',
        severity: 'high',
      });
    }

    const isApproved = toxicityScore < 0.7;

    // Store moderation result
    const moderationResult = {
      moderationId: textId,
      contentId: textId,
      contentType: 'text',
      userId,
      text,
      status: isApproved ? 'approved' : 'rejected',
      flags: violations,
      overallScore: toxicityScore,
      toxicityScore,
      sentimentScore,
      sentimentMagnitude,
      detectedProfanity: profanityList,
      categories: categories.map((c) => c.name),
      moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await firestore
      .collection('moderation_results')
      .doc(textId)
      .set(moderationResult);

    // If rejected, create moderation queue entry
    if (!isApproved) {
      await createModerationQueueEntry({
        itemType: 'flaggedContent',
        itemId: textId,
        userId,
        priority: toxicityScore > 0.9 ? 'critical' : 'high',
        metadata: {
          contentType: 'text',
          violations,
          toxicityScore,
        },
      });
    }

    return {
      isApproved,
      toxicityScore,
      violations,
      detectedProfanity: profanityList,
    };
  } catch (error: any) {
    console.error('Error moderating text:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Check for Profanity
 * Point 203: Profanity filter with multilingual support
 */
async function checkProfanity(text: string): Promise<string[]> {
  const profanityWords = [
    // English profanity (simplified list)
    'fuck',
    'shit',
    'bitch',
    'asshole',
    'damn',
    'crap',
    // Spanish
    'mierda',
    'puta',
    'carajo',
    // French
    'merde',
    'putain',
    // German
    'scheiße',
    // Add more languages as needed
  ];

  const lowerText = text.toLowerCase();
  const detected: string[] = [];

  profanityWords.forEach((word) => {
    if (lowerText.includes(word)) {
      detected.push(word);
    }
  });

  return detected;
}

/**
 * Detect Spam
 * Point 204: Spam detection algorithm
 */
export const detectSpam = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { messageId, message, userId, conversationId } = data;

  try {
    const indicators: string[] = [];
    let spamScore = 0;

    // Check for excessive links
    const urlRegex = /(https?:\/\/[^\s]+)/g;
    const urls = message.match(urlRegex) || [];
    if (urls.length > 2) {
      indicators.push('excessiveLinks');
      spamScore += 0.3;
    }

    // Check for promotional keywords
    const promoKeywords = [
      'click here',
      'buy now',
      'limited time',
      'act now',
      'free money',
      'earn cash',
    ];
    if (promoKeywords.some((keyword) => message.toLowerCase().includes(keyword))) {
      indicators.push('promotional');
      spamScore += 0.3;
    }

    // Check for repetitive text
    const words = message.split(' ');
    const uniqueWords = new Set(words);
    if (words.length > 10 && uniqueWords.size / words.length < 0.5) {
      indicators.push('repetitiveText');
      spamScore += 0.2;
    }

    // Check for mass sending (simplified)
    const recentMessages = await firestore
      .collection('messages')
      .where('senderId', '==', userId)
      .where(
        'timestamp',
        '>',
        admin.firestore.Timestamp.fromDate(
          new Date(Date.now() - 5 * 60 * 1000)
        )
      )
      .get();

    if (recentMessages.size > 10) {
      indicators.push('rapidFire');
      spamScore += 0.4;
    }

    const isSpam = spamScore > 0.6;

    // Store detection result
    await firestore.collection('spam_detections').doc(messageId).set({
      messageId,
      userId,
      conversationId,
      spamScore,
      indicators,
      isSpam,
      detectedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      isSpam,
      spamScore,
      indicators,
    };
  } catch (error: any) {
    console.error('Error detecting spam:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Detect Fake Profile
 * Point 205: Fake profile detection using behavioral analysis
 */
export const detectFakeProfile = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { userId } = data;

    try {
      const indicators: string[] = [];
      let fakeScore = 0;

      // Get user profile
      const userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw new Error('User not found');
      }

      const userData = userDoc.data()!;

      // Check profile completeness
      const completeness = calculateProfileCompleteness(userData);
      if (completeness < 0.3) {
        indicators.push('incompleteProfile');
        fakeScore += 0.2;
      }

      // Check account age
      const accountAge = Date.now() - userData.createdAt?.toDate().getTime();
      const daysSinceCreation = accountAge / (1000 * 60 * 60 * 24);

      if (daysSinceCreation < 1) {
        indicators.push('rapidAccountCreation');
        fakeScore += 0.15;
      }

      // Check for stock photos (simplified - would use reverse image search)
      const photoCount = userData.photos?.length || 0;
      if (photoCount === 0) {
        fakeScore += 0.3;
      } else if (photoCount === 1) {
        indicators.push('stockPhoto');
        fakeScore += 0.2;
      }

      // Check for verification
      if (!userData.isVerified) {
        indicators.push('noVerification');
        fakeScore += 0.15;
      }

      // Check suspicious behavior patterns
      const messagesSent = await firestore
        .collection('messages')
        .where('senderId', '==', userId)
        .limit(50)
        .get();

      // Check for identical messages (copypasta)
      const messageTexts = messagesSent.docs.map(
        (doc) => doc.data().message
      );
      const uniqueMessages = new Set(messageTexts);
      if (messageTexts.length > 10 && uniqueMessages.size / messageTexts.length < 0.3) {
        indicators.push('suspiciousBehavior');
        fakeScore += 0.2;
      }

      const isSuspicious = fakeScore > 0.5;

      // Store detection result
      await firestore.collection('fake_profile_detections').doc(userId).set({
        userId,
        fakeScore,
        indicators,
        isSuspicious,
        detectedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // If suspicious, add to moderation queue
      if (isSuspicious) {
        await createModerationQueueEntry({
          itemType: 'suspiciousProfile',
          itemId: userId,
          userId,
          priority: fakeScore > 0.8 ? 'high' : 'medium',
          metadata: {
            fakeScore,
            indicators,
          },
        });
      }

      return {
        isSuspicious,
        fakeScore,
        indicators,
      };
    } catch (error: any) {
      console.error('Error detecting fake profile:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

/**
 * Detect Scam
 * Point 206: Scam detection system
 */
export const detectScam = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { conversationId, messages } = data;

  try {
    const indicators: string[] = [];
    let scamScore = 0;

    // Check for money-related keywords
    const moneyKeywords = [
      'send money',
      'wire transfer',
      'gift card',
      'cash app',
      'venmo',
      'paypal',
      'bitcoin',
      'loan',
      'investment',
    ];

    // Check for urgency language
    const urgencyKeywords = [
      'urgent',
      'emergency',
      'right now',
      'immediately',
      'asap',
      'hurry',
    ];

    // Check for too-good-to-be-true language
    const tooGoodKeywords = [
      'guaranteed',
      'risk-free',
      'double your money',
      'easy money',
      'get rich',
    ];

    const allText = messages.join(' ').toLowerCase();

    if (moneyKeywords.some((keyword) => allText.includes(keyword))) {
      indicators.push('moneyRequest');
      scamScore += 0.4;
    }

    if (urgencyKeywords.some((keyword) => allText.includes(keyword))) {
      indicators.push('urgencyLanguage');
      scamScore += 0.2;
    }

    if (tooGoodKeywords.some((keyword) => allText.includes(keyword))) {
      indicators.push('tooGoodToBeTrue');
      scamScore += 0.3;
    }

    // Check for external links
    const urlRegex = /(https?:\/\/[^\s]+)/g;
    if (urlRegex.test(allText)) {
      indicators.push('externalLinks');
      scamScore += 0.2;
    }

    // Check for asking for personal info
    const personalInfoKeywords = [
      'social security',
      'ssn',
      'credit card',
      'bank account',
      'password',
    ];

    if (personalInfoKeywords.some((keyword) => allText.includes(keyword))) {
      indicators.push('askingForPersonalInfo');
      scamScore += 0.5;
    }

    const isScam = scamScore > 0.6;

    // Store detection result
    await firestore.collection('scam_detections').doc(conversationId).set({
      conversationId,
      scamScore,
      indicators,
      isScam,
      detectedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      isScam,
      scamScore,
      indicators,
    };
  } catch (error: any) {
    console.error('Error detecting scam:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Create Moderation Queue Entry
 * Point 209: Escalation system routing to moderators
 */
async function createModerationQueueEntry(params: {
  itemType: string;
  itemId: string;
  userId: string;
  priority: string;
  metadata: any;
}): Promise<void> {
  await firestore.collection('moderation_queue').add({
    ...params,
    addedAt: admin.firestore.FieldValue.serverTimestamp(),
    assignedTo: null,
    status: 'pending',
  });
}

/**
 * Helper: Calculate profile completeness
 */
function calculateProfileCompleteness(userData: any): number {
  let score = 0;
  const fields = ['name', 'bio', 'age', 'location', 'interests', 'photos'];

  fields.forEach((field) => {
    if (userData[field]) {
      if (field === 'photos' && Array.isArray(userData[field])) {
        score += userData[field].length > 0 ? 1 : 0;
      } else {
        score += 1;
      }
    }
  });

  return score / fields.length;
}
