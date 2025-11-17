/**
 * Identity Verification Entity
 * Points 221-225: Identity verification and trust score
 */

import 'package:equatable/equatable.dart';

/// Identity verification (Points 221-224)
class IdentityVerification extends Equatable {
  final String verificationId;
  final String userId;
  final VerificationType type;
  final VerificationStatus status;
  final DateTime initiatedAt;
  final DateTime? completedAt;
  final VerificationResult? result;
  final String? rejectionReason;
  final int attemptCount;

  const IdentityVerification({
    required this.verificationId,
    required this.userId,
    required this.type,
    required this.status,
    required this.initiatedAt,
    this.completedAt,
    this.result,
    this.rejectionReason,
    required this.attemptCount,
  });

  bool get isVerified => status == VerificationStatus.verified;
  bool get isPending => status == VerificationStatus.pending;
  bool get isRejected => status == VerificationStatus.rejected;

  @override
  List<Object?> get props => [
        verificationId,
        userId,
        type,
        status,
        initiatedAt,
        completedAt,
        result,
        rejectionReason,
        attemptCount,
      ];
}

/// Verification types
enum VerificationType {
  photoVerification, // Point 221: Selfie matching
  idVerification, // Point 222: Document scanning
  combined, // Both photo and ID
}

/// Verification status
enum VerificationStatus {
  notStarted,
  pending,
  verified,
  rejected,
  expired,
}

/// Verification result
class VerificationResult extends Equatable {
  final PhotoVerificationResult? photoResult;
  final IDVerificationResult? idResult;
  final LivenessDetectionResult? livenessResult;
  final double overallConfidence; // 0-1

  const VerificationResult({
    this.photoResult,
    this.idResult,
    this.livenessResult,
    required this.overallConfidence,
  });

  @override
  List<Object?> get props => [
        photoResult,
        idResult,
        livenessResult,
        overallConfidence,
      ];
}

/// Photo verification result (Point 221)
class PhotoVerificationResult extends Equatable {
  final String selfieUrl;
  final List<String> profilePhotoUrls;
  final double matchScore; // 0-1, how well selfie matches profile
  final FaceMatchAnalysis faceMatch;
  final bool passed;

  const PhotoVerificationResult({
    required this.selfieUrl,
    required this.profilePhotoUrls,
    required this.matchScore,
    required this.faceMatch,
    required this.passed,
  });

  @override
  List<Object?> get props => [
        selfieUrl,
        profilePhotoUrls,
        matchScore,
        faceMatch,
        passed,
      ];
}

/// Face matching analysis
class FaceMatchAnalysis extends Equatable {
  final double similarity; // 0-1
  final bool samePerson;
  final Map<String, double> featureMatches; // eyes, nose, mouth, etc.

  const FaceMatchAnalysis({
    required this.similarity,
    required this.samePerson,
    required this.featureMatches,
  });

  @override
  List<Object?> get props => [similarity, samePerson, featureMatches];
}

/// ID verification result (Point 222)
class IDVerificationResult extends Equatable {
  final String documentType;
  final String documentNumber;
  final String fullName;
  final DateTime? dateOfBirth;
  final String? nationality;
  final DateTime expirationDate;
  final OCRResult ocrResult;
  final DocumentAuthenticity authenticity;
  final bool passed;

  const IDVerificationResult({
    required this.documentType,
    required this.documentNumber,
    required this.fullName,
    this.dateOfBirth,
    this.nationality,
    required this.expirationDate,
    required this.ocrResult,
    required this.authenticity,
    required this.passed,
  });

  @override
  List<Object?> get props => [
        documentType,
        documentNumber,
        fullName,
        dateOfBirth,
        nationality,
        expirationDate,
        ocrResult,
        authenticity,
        passed,
      ];
}

/// OCR extraction result
class OCRResult extends Equatable {
  final Map<String, String> extractedFields;
  final double confidence; // 0-1
  final List<String> missingFields;

  const OCRResult({
    required this.extractedFields,
    required this.confidence,
    required this.missingFields,
  });

  @override
  List<Object?> get props => [extractedFields, confidence, missingFields];
}

/// Document authenticity check
class DocumentAuthenticity extends Equatable {
  final bool isAuthentic;
  final double confidence; // 0-1
  final List<AuthenticityCheck> checks;

  const DocumentAuthenticity({
    required this.isAuthentic,
    required this.confidence,
    required this.checks,
  });

  @override
  List<Object?> get props => [isAuthentic, confidence, checks];
}

/// Individual authenticity check
class AuthenticityCheck extends Equatable {
  final String checkType;
  final bool passed;
  final String description;

  const AuthenticityCheck({
    required this.checkType,
    required this.passed,
    required this.description,
  });

  @override
  List<Object?> get props => [checkType, passed, description];
}

/// Liveness detection result (Point 223)
class LivenessDetectionResult extends Equatable {
  final bool isLive;
  final double confidence; // 0-1
  final List<LivenessCheck> checks;
  final String? failureReason;

  const LivenessDetectionResult({
    required this.isLive,
    required this.confidence,
    required this.checks,
    this.failureReason,
  });

  @override
  List<Object?> get props => [isLive, confidence, checks, failureReason];
}

/// Liveness check
class LivenessCheck extends Equatable {
  final LivenessCheckType type;
  final bool passed;
  final String description;

  const LivenessCheck({
    required this.type,
    required this.passed,
    required this.description,
  });

  @override
  List<Object?> get props => [type, passed, description];
}

/// Types of liveness checks
enum LivenessCheckType {
  blinkDetection,
  headMovement,
  smileDetection,
  depthAnalysis,
  textureAnalysis,
}

/// Verification badge (Point 224)
class VerificationBadge extends Equatable {
  final String userId;
  final BadgeLevel level;
  final DateTime verifiedAt;
  final DateTime expiresAt;
  final List<VerificationType> verificationsMet;

  const VerificationBadge({
    required this.userId,
    required this.level,
    required this.verifiedAt,
    required this.expiresAt,
    required this.verificationsMet,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired;

  @override
  List<Object?> get props => [
        userId,
        level,
        verifiedAt,
        expiresAt,
        verificationsMet,
      ];
}

/// Badge levels
enum BadgeLevel {
  none,
  photoVerified, // Point 221
  idVerified, // Point 222
  fullyVerified, // Both photo and ID
}

/// Trust score (Point 225)
class TrustScore extends Equatable {
  final String userId;
  final double score; // 0-100
  final TrustLevel level;
  final Map<String, double> components;
  final DateTime calculatedAt;
  final List<TrustFactor> factors;

  const TrustScore({
    required this.userId,
    required this.score,
    required this.level,
    required this.components,
    required this.calculatedAt,
    required this.factors,
  });

  @override
  List<Object?> get props => [
        userId,
        score,
        level,
        components,
        calculatedAt,
        factors,
      ];
}

/// Trust level categories
enum TrustLevel {
  veryLow, // 0-20
  low, // 21-40
  medium, // 41-60
  high, // 61-80
  veryHigh, // 81-100
}

/// Trust score factors
class TrustFactor extends Equatable {
  final String factorName;
  final double weight; // Contribution to overall score
  final double value; // 0-100
  final String description;

  const TrustFactor({
    required this.factorName,
    required this.weight,
    required this.value,
    required this.description,
  });

  @override
  List<Object?> get props => [factorName, weight, value, description];
}

/// Trust score components (Point 225)
class TrustScoreComponents {
  // Verification level (40% weight)
  static const TrustFactor noVerification = TrustFactor(
    factorName: 'verification',
    weight: 0.4,
    value: 0,
    description: 'Not verified',
  );

  static const TrustFactor photoVerified = TrustFactor(
    factorName: 'verification',
    weight: 0.4,
    value: 60,
    description: 'Photo verified',
  );

  static const TrustFactor idVerified = TrustFactor(
    factorName: 'verification',
    weight: 0.4,
    value: 100,
    description: 'ID verified',
  );

  // Report count (30% weight) - inverse
  static double calculateReportFactor(int reportCount) {
    if (reportCount == 0) return 100;
    if (reportCount <= 2) return 80;
    if (reportCount <= 5) return 50;
    if (reportCount <= 10) return 20;
    return 0;
  }

  // Account age (20% weight)
  static double calculateAccountAgeFactor(DateTime createdAt) {
    final days = DateTime.now().difference(createdAt).inDays;
    if (days >= 180) return 100;
    if (days >= 90) return 80;
    if (days >= 30) return 60;
    if (days >= 7) return 40;
    return 20;
  }

  // Profile completeness (10% weight)
  static double calculateProfileCompletenessFactor(double completeness) {
    return completeness * 100;
  }
}
