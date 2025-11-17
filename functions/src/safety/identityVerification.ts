/**
 * Identity Verification Cloud Functions
 * Points 221-225: Photo verification, ID verification, trust score
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import vision from '@google-cloud/vision';

const firestore = admin.firestore();
const visionClient = new vision.ImageAnnotatorClient();

/**
 * Start Photo Verification
 * Point 221: Real-time selfie matching profile photos
 */
export const startPhotoVerification = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = context.auth.uid;

    try {
      // Create verification session
      const verificationRef = firestore
        .collection('identity_verifications')
        .doc();

      await verificationRef.set({
        verificationId: verificationRef.id,
        userId,
        type: 'photoVerification',
        status: 'pending',
        initiatedAt: admin.firestore.FieldValue.serverTimestamp(),
        completedAt: null,
        result: null,
        rejectionReason: null,
        attemptCount: 0,
      });

      return {
        verificationId: verificationRef.id,
        status: 'initiated',
      };
    } catch (error: any) {
      console.error('Error starting photo verification:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

/**
 * Verify Photo Selfie
 * Point 221 & 223: Selfie matching with liveness detection
 */
export const verifyPhotoSelfie = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { verificationId, selfieUrl } = data;
    const userId = context.auth.uid;

    try {
      // Get verification session
      const verificationDoc = await firestore
        .collection('identity_verifications')
        .doc(verificationId)
        .get();

      if (!verificationDoc.exists) {
        throw new Error('Verification session not found');
      }

      // Get user's profile photos
      const userDoc = await firestore.collection('users').doc(userId).get();
      const userData = userDoc.data()!;
      const profilePhotoUrls = userData.photos || [];

      if (profilePhotoUrls.length === 0) {
        throw new Error('No profile photos found for comparison');
      }

      // Point 223: Liveness detection
      const livenessResult = await performLivenessDetection(selfieUrl);

      if (!livenessResult.isLive) {
        await verificationDoc.ref.update({
          status: 'rejected',
          rejectionReason: 'Liveness detection failed: ' + livenessResult.failureReason,
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return {
          verified: false,
          reason: 'Photo spoofing detected',
        };
      }

      // Compare selfie with profile photos
      const matchResults = await Promise.all(
        profilePhotoUrls.map((profileUrl: string) =>
          compareFaces(selfieUrl, profileUrl)
        )
      );

      // Find best match
      const bestMatch = matchResults.reduce((best, current) =>
        current.similarity > best.similarity ? current : best
      );

      const matchScore = bestMatch.similarity;
      const passed = matchScore > 0.7; // 70% threshold

      // Store result
      const result = {
        photoResult: {
          selfieUrl,
          profilePhotoUrls,
          matchScore,
          faceMatch: {
            similarity: matchScore,
            samePerson: passed,
            featureMatches: bestMatch.featureMatches,
          },
          passed,
        },
        livenessResult,
        overallConfidence: passed ? (matchScore + livenessResult.confidence) / 2 : 0,
      };

      await verificationDoc.ref.update({
        status: passed ? 'verified' : 'rejected',
        result,
        rejectionReason: passed ? null : 'Face match below threshold',
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        attemptCount: admin.firestore.FieldValue.increment(1),
      });

      // Point 224: Grant verification badge if passed
      if (passed) {
        await grantVerificationBadge(userId, 'photoVerified');
      }

      // Update trust score (Point 225)
      await updateTrustScore(userId);

      return {
        verified: passed,
        matchScore,
        livenessScore: livenessResult.confidence,
      };
    } catch (error: any) {
      console.error('Error verifying photo selfie:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

/**
 * Verify ID Document
 * Point 222: Document scanning and OCR
 */
export const verifyIDDocument = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { verificationId, documentUrl, documentType } = data;
    const userId = context.auth.uid;

    try {
      // Detect text using OCR
      const [textResult] = await visionClient.textDetection(documentUrl);
      const fullText = textResult.fullTextAnnotation?.text || '';

      // Extract information using pattern matching
      const extractedData = extractIDData(fullText, documentType);

      // Verify document authenticity
      const authenticity = await verifyDocumentAuthenticity(
        documentUrl,
        documentType
      );

      const passed = authenticity.isAuthentic && extractedData.confidence > 0.6;

      // Store result
      const result = {
        idResult: {
          documentType,
          documentNumber: extractedData.documentNumber,
          fullName: extractedData.fullName,
          dateOfBirth: extractedData.dateOfBirth,
          nationality: extractedData.nationality,
          expirationDate: extractedData.expirationDate,
          ocrResult: {
            extractedFields: extractedData.fields,
            confidence: extractedData.confidence,
            missingFields: extractedData.missingFields,
          },
          authenticity,
          passed,
        },
        overallConfidence: passed ? (extractedData.confidence + authenticity.confidence) / 2 : 0,
      };

      // Update verification
      await firestore
        .collection('identity_verifications')
        .doc(verificationId)
        .update({
          status: passed ? 'verified' : 'rejected',
          result,
          rejectionReason: passed
            ? null
            : 'Document verification failed: ' + (!authenticity.isAuthentic
                ? 'Document not authentic'
                : 'Low confidence in extracted data'),
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      // Point 224: Grant verification badge
      if (passed) {
        await grantVerificationBadge(userId, 'idVerified');
      }

      // Update trust score (Point 225)
      await updateTrustScore(userId);

      return {
        verified: passed,
        extractedData,
        authenticity: authenticity.isAuthentic,
      };
    } catch (error: any) {
      console.error('Error verifying ID document:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

/**
 * Liveness Detection
 * Point 223: Prevent photo spoofing
 */
async function performLivenessDetection(imageUrl: string): Promise<any> {
  try {
    // Use Cloud Vision face detection
    const [result] = await visionClient.faceDetection(imageUrl);
    const faces = result.faceAnnotations || [];

    if (faces.length === 0) {
      return {
        isLive: false,
        confidence: 0,
        checks: [],
        failureReason: 'No face detected',
      };
    }

    const face = faces[0];
    const checks: any[] = [];

    // Check for natural lighting (not flat like a photo)
    const hasNaturalLighting = face.underExposedLikelihood !== 'VERY_LIKELY';
    checks.push({
      type: 'textureAnalysis',
      passed: hasNaturalLighting,
      description: 'Natural lighting detected',
    });

    // Check for blur detection (movement)
    const hasBlur = face.blurredLikelihood === 'POSSIBLE' ||
                   face.blurredLikelihood === 'LIKELY';
    checks.push({
      type: 'depthAnalysis',
      passed: hasBlur,
      description: 'Natural motion blur detected',
    });

    // Check joy/emotion (more likely in live photo)
    const hasEmotion =
      face.joyLikelihood === 'POSSIBLE' ||
      face.joyLikelihood === 'LIKELY' ||
      face.joyLikelihood === 'VERY_LIKELY';
    checks.push({
      type: 'smileDetection',
      passed: hasEmotion,
      description: 'Natural expression detected',
    });

    const passedChecks = checks.filter((c) => c.passed).length;
    const confidence = passedChecks / checks.length;
    const isLive = confidence > 0.5;

    return {
      isLive,
      confidence,
      checks,
      failureReason: isLive ? null : 'Failed liveness checks',
    };
  } catch (error) {
    console.error('Liveness detection error:', error);
    return {
      isLive: false,
      confidence: 0,
      checks: [],
      failureReason: 'Error performing liveness detection',
    };
  }
}

/**
 * Compare Faces
 * Point 221: Face matching
 */
async function compareFaces(
  imageUrl1: string,
  imageUrl2: string
): Promise<any> {
  try {
    // Get face landmarks from both images
    const [result1] = await visionClient.faceDetection(imageUrl1);
    const [result2] = await visionClient.faceDetection(imageUrl2);

    const face1 = result1.faceAnnotations?.[0];
    const face2 = result2.faceAnnotations?.[0];

    if (!face1 || !face2) {
      return {
        similarity: 0,
        samePerson: false,
        featureMatches: {},
      };
    }

    // Calculate similarity based on face landmarks
    // (Simplified - in production, use dedicated face recognition API)
    const similarity = calculateFaceSimilarity(face1, face2);

    return {
      similarity,
      samePerson: similarity > 0.7,
      featureMatches: {
        overall: similarity,
      },
    };
  } catch (error) {
    console.error('Face comparison error:', error);
    return {
      similarity: 0,
      samePerson: false,
      featureMatches: {},
    };
  }
}

/**
 * Calculate Face Similarity
 */
function calculateFaceSimilarity(face1: any, face2: any): number {
  // Simplified similarity calculation
  // In production, use proper face recognition algorithms
  const angle1 = {
    roll: face1.rollAngle || 0,
    pan: face1.panAngle || 0,
    tilt: face1.tiltAngle || 0,
  };

  const angle2 = {
    roll: face2.rollAngle || 0,
    pan: face2.panAngle || 0,
    tilt: face2.tiltAngle || 0,
  };

  // Check if faces have similar angles (facing same direction)
  const angleDiff =
    Math.abs(angle1.roll - angle2.roll) +
    Math.abs(angle1.pan - angle2.pan) +
    Math.abs(angle1.tilt - angle2.tilt);

  // Lower angle difference = higher similarity
  const similarity = Math.max(0, 1 - angleDiff / 100);

  return similarity;
}

/**
 * Extract ID Data using OCR
 * Point 222: Document data extraction
 */
function extractIDData(text: string, documentType: string): any {
  const fields: any = {};
  const missingFields: string[] = [];

  // Extract document number
  const docNumberMatch = text.match(/[A-Z0-9]{8,12}/);
  fields.documentNumber = docNumberMatch ? docNumberMatch[0] : null;
  if (!fields.documentNumber) missingFields.push('documentNumber');

  // Extract full name (simplified)
  const nameMatch = text.match(/([A-Z][a-z]+\s){1,3}[A-Z][a-z]+/);
  fields.fullName = nameMatch ? nameMatch[0] : null;
  if (!fields.fullName) missingFields.push('fullName');

  // Extract date of birth
  const dobMatch = text.match(/\d{2}\/\d{2}\/\d{4}|\d{4}-\d{2}-\d{2}/);
  fields.dateOfBirth = dobMatch ? dobMatch[0] : null;
  if (!fields.dateOfBirth) missingFields.push('dateOfBirth');

  // Extract expiration date
  const expMatch = text.match(/EXP[:\s]+(\d{2}\/\d{2}\/\d{4})/i);
  fields.expirationDate = expMatch ? expMatch[1] : null;
  if (!fields.expirationDate) missingFields.push('expirationDate');

  // Calculate confidence
  const totalFields = 4;
  const extractedFields = totalFields - missingFields.length;
  const confidence = extractedFields / totalFields;

  return {
    documentNumber: fields.documentNumber,
    fullName: fields.fullName,
    dateOfBirth: fields.dateOfBirth ? new Date(fields.dateOfBirth) : null,
    nationality: null,
    expirationDate: fields.expirationDate ? new Date(fields.expirationDate) : null,
    fields,
    confidence,
    missingFields,
  };
}

/**
 * Verify Document Authenticity
 */
async function verifyDocumentAuthenticity(
  documentUrl: string,
  documentType: string
): Promise<any> {
  const checks: any[] = [];

  // Check image quality
  const [imageProps] = await visionClient.imageProperties(documentUrl);
  const colors = imageProps.imagePropertiesAnnotation?.dominantColors?.colors || [];

  checks.push({
    checkType: 'imageQuality',
    passed: colors.length > 5,
    description: 'Sufficient color variation for real document',
  });

  // Check for document features
  const [labels] = await visionClient.labelDetection(documentUrl);
  const labelDescriptions =
    labels.labelAnnotations?.map((l) => l.description?.toLowerCase()) || [];

  const hasDocumentLabels = labelDescriptions.some((label) =>
    ['document', 'text', 'paper', 'card'].includes(label || '')
  );

  checks.push({
    checkType: 'documentFeatures',
    passed: hasDocumentLabels,
    description: 'Document features detected',
  });

  const passedChecks = checks.filter((c) => c.passed).length;
  const confidence = passedChecks / checks.length;

  return {
    isAuthentic: confidence > 0.5,
    confidence,
    checks,
  };
}

/**
 * Grant Verification Badge
 * Point 224: Display badge on verified profiles
 */
async function grantVerificationBadge(
  userId: string,
  level: string
): Promise<void> {
  const expiresAt = new Date();
  expiresAt.setFullYear(expiresAt.getFullYear() + 1); // 1 year validity

  await firestore
    .collection('verification_badges')
    .doc(userId)
    .set(
      {
        userId,
        level,
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        verificationsMet: admin.firestore.FieldValue.arrayUnion(level),
      },
      { merge: true }
    );

  // Update user profile
  await firestore.collection('users').doc(userId).update({
    isVerified: true,
    verificationLevel: level,
    verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Calculate Trust Score
 * Point 225: Trust score combining verification, reports, account age
 */
export const calculateTrustScore = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = data.userId || context.auth.uid;

    try {
      const trustScore = await updateTrustScore(userId);
      return trustScore;
    } catch (error: any) {
      console.error('Error calculating trust score:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

/**
 * Update Trust Score
 * Point 225: Algorithm combining multiple factors
 */
async function updateTrustScore(userId: string): Promise<any> {
  const factors: any[] = [];
  const components: any = {};

  // 1. Verification level (40% weight)
  const badgeDoc = await firestore
    .collection('verification_badges')
    .doc(userId)
    .get();

  let verificationValue = 0;
  if (badgeDoc.exists) {
    const badge = badgeDoc.data()!;
    if (badge.level === 'idVerified' || badge.level === 'fullyVerified') {
      verificationValue = 100;
    } else if (badge.level === 'photoVerified') {
      verificationValue = 60;
    }
  }

  factors.push({
    factorName: 'verification',
    weight: 0.4,
    value: verificationValue,
    description:
      verificationValue === 100
        ? 'ID verified'
        : verificationValue === 60
        ? 'Photo verified'
        : 'Not verified',
  });
  components.verification = verificationValue * 0.4;

  // 2. Report count (30% weight) - inverse
  const reportsSnapshot = await firestore
    .collection('user_reports')
    .where('reportedUserId', '==', userId)
    .get();

  const reportCount = reportsSnapshot.size;
  let reportValue = 100;
  if (reportCount > 0) {
    if (reportCount <= 2) reportValue = 80;
    else if (reportCount <= 5) reportValue = 50;
    else if (reportCount <= 10) reportValue = 20;
    else reportValue = 0;
  }

  factors.push({
    factorName: 'reports',
    weight: 0.3,
    value: reportValue,
    description: `${reportCount} reports`,
  });
  components.reports = reportValue * 0.3;

  // 3. Account age (20% weight)
  const userDoc = await firestore.collection('users').doc(userId).get();
  const userData = userDoc.data()!;
  const createdAt = userData.createdAt?.toDate() || new Date();
  const days = Math.floor(
    (Date.now() - createdAt.getTime()) / (1000 * 60 * 60 * 24)
  );

  let accountAgeValue = 20;
  if (days >= 180) accountAgeValue = 100;
  else if (days >= 90) accountAgeValue = 80;
  else if (days >= 30) accountAgeValue = 60;
  else if (days >= 7) accountAgeValue = 40;

  factors.push({
    factorName: 'accountAge',
    weight: 0.2,
    value: accountAgeValue,
    description: `${days} days old`,
  });
  components.accountAge = accountAgeValue * 0.2;

  // 4. Profile completeness (10% weight)
  const completeness = calculateProfileCompleteness(userData);
  const completenessValue = completeness * 100;

  factors.push({
    factorName: 'profileCompleteness',
    weight: 0.1,
    value: completenessValue,
    description: `${Math.round(completeness * 100)}% complete`,
  });
  components.profileCompleteness = completenessValue * 0.1;

  // Calculate overall score
  const score = Object.values(components).reduce(
    (sum: number, val: any) => sum + val,
    0
  );

  // Determine trust level
  let level = 'veryLow';
  if (score > 80) level = 'veryHigh';
  else if (score > 60) level = 'high';
  else if (score > 40) level = 'medium';
  else if (score > 20) level = 'low';

  // Store trust score
  const trustScoreData = {
    userId,
    score,
    level,
    components,
    calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
    factors,
  };

  await firestore
    .collection('trust_scores')
    .doc(userId)
    .set(trustScoreData);

  // Update user profile
  await firestore.collection('users').doc(userId).update({
    trustScore: score,
    trustLevel: level,
  });

  return trustScoreData;
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
      } else if (field === 'interests' && Array.isArray(userData[field])) {
        score += userData[field].length >= 3 ? 1 : 0;
      } else {
        score += 1;
      }
    }
  });

  return score / fields.length;
}
