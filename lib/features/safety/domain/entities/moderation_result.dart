/**
 * Moderation Result Entity
 * Points 201-210: Content moderation results
 */

import 'package:equatable/equatable.dart';

/// Moderation result for content (text, image, etc.)
class ModerationResult extends Equatable {
  final String moderationId;
  final String contentId;
  final ContentType contentType;
  final ModerationStatus status;
  final List<ModerationFlag> flags;
  final double overallScore; // 0-1, higher = more problematic
  final DateTime moderatedAt;
  final String? moderatorId; // Null if automated
  final String? reviewNotes;

  const ModerationResult({
    required this.moderationId,
    required this.contentId,
    required this.contentType,
    required this.status,
    required this.flags,
    required this.overallScore,
    required this.moderatedAt,
    this.moderatorId,
    this.reviewNotes,
  });

  bool get isApproved => status == ModerationStatus.approved;
  bool get isRejected => status == ModerationStatus.rejected;
  bool get requiresReview => status == ModerationStatus.pending;

  @override
  List<Object?> get props => [
        moderationId,
        contentId,
        contentType,
        status,
        flags,
        overallScore,
        moderatedAt,
        moderatorId,
        reviewNotes,
      ];
}

/// Individual moderation flag
class ModerationFlag extends Equatable {
  final FlagType type;
  final double confidence; // 0-1
  final String reason;
  final FlagSeverity severity;

  const ModerationFlag({
    required this.type,
    required this.confidence,
    required this.reason,
    required this.severity,
  });

  @override
  List<Object?> get props => [type, confidence, reason, severity];
}

/// Content moderation status
enum ModerationStatus {
  pending,
  approved,
  rejected,
  appealed,
  reviewRequired,
}

/// Content type being moderated
enum ContentType {
  photo,
  text,
  profile,
  message,
  bio,
}

/// Flag types (Points 201-207)
enum FlagType {
  // Point 201: Image moderation
  nudity,
  violence,
  offensiveSymbols,
  gore,
  drugs,

  // Point 202: Text toxicity
  toxicity,
  severeToxicity,
  profanity,
  threat,
  insult,
  identityAttack,

  // Point 204: Spam
  spam,
  promotional,
  repetitive,

  // Point 205: Fake profile
  fakeProfile,
  stockPhoto,
  celebrityPhoto,
  inconsistentPhotos,

  // Point 206: Scam
  scam,
  moneyRequest,
  phishing,
  externalLinks,

  // Point 207: Catfish
  catfish,
  photoshopped,
  ageInconsistent,
}

/// Flag severity levels
enum FlagSeverity {
  low,
  medium,
  high,
  critical,
}

/// Photo moderation result (Point 201)
class PhotoModerationResult extends Equatable {
  final String photoId;
  final SafeSearchAnnotation safeSearch;
  final List<Label> labels;
  final FaceDetectionResult? faces;
  final bool isApproved;
  final List<ModerationFlag> violations;

  const PhotoModerationResult({
    required this.photoId,
    required this.safeSearch,
    required this.labels,
    this.faces,
    required this.isApproved,
    required this.violations,
  });

  @override
  List<Object?> get props => [
        photoId,
        safeSearch,
        labels,
        faces,
        isApproved,
        violations,
      ];
}

/// Safe search annotation from Cloud Vision API
class SafeSearchAnnotation extends Equatable {
  final Likelihood adult;
  final Likelihood violence;
  final Likelihood racy;
  final Likelihood medical;
  final Likelihood spoof;

  const SafeSearchAnnotation({
    required this.adult,
    required this.violence,
    required this.racy,
    required this.medical,
    required this.spoof,
  });

  /// Strict safety check: blocks all nudity and racy content
  bool get isSafe =>
      adult.index <= Likelihood.veryUnlikely.index &&
      violence.index <= Likelihood.unlikely.index &&
      racy.index <= Likelihood.unlikely.index;

  @override
  List<Object?> get props => [adult, violence, racy, medical, spoof];
}

/// Likelihood levels from Cloud Vision API
enum Likelihood {
  unknown,
  veryUnlikely,
  unlikely,
  possible,
  likely,
  veryLikely,
}

/// Label detected in image
class Label extends Equatable {
  final String description;
  final double score;

  const Label({
    required this.description,
    required this.score,
  });

  @override
  List<Object?> get props => [description, score];
}

/// Face detection result
class FaceDetectionResult extends Equatable {
  final int faceCount;
  final List<FaceAnnotation> faces;

  const FaceDetectionResult({
    required this.faceCount,
    required this.faces,
  });

  @override
  List<Object?> get props => [faceCount, faces];
}

/// Individual face annotation
class FaceAnnotation extends Equatable {
  final double joyLikelihood;
  final double sorrowLikelihood;
  final double angerLikelihood;
  final double surpriseLikelihood;

  const FaceAnnotation({
    required this.joyLikelihood,
    required this.sorrowLikelihood,
    required this.angerLikelihood,
    required this.surpriseLikelihood,
  });

  @override
  List<Object?> get props => [
        joyLikelihood,
        sorrowLikelihood,
        angerLikelihood,
        surpriseLikelihood,
      ];
}

/// Text moderation result (Point 202)
class TextModerationResult extends Equatable {
  final String textId;
  final String text;
  final double toxicityScore; // 0-1
  final Map<String, double> attributeScores; // toxicity, profanity, etc.
  final List<String> detectedProfanity;
  final bool isApproved;
  final List<ModerationFlag> violations;

  const TextModerationResult({
    required this.textId,
    required this.text,
    required this.toxicityScore,
    required this.attributeScores,
    required this.detectedProfanity,
    required this.isApproved,
    required this.violations,
  });

  bool get isToxic => toxicityScore > 0.7;
  bool get hasProfanity => detectedProfanity.isNotEmpty;

  @override
  List<Object?> get props => [
        textId,
        text,
        toxicityScore,
        attributeScores,
        detectedProfanity,
        isApproved,
        violations,
      ];
}

/// Spam detection result (Point 204)
class SpamDetectionResult extends Equatable {
  final String messageId;
  final double spamScore; // 0-1
  final List<SpamIndicator> indicators;
  final bool isSpam;

  const SpamDetectionResult({
    required this.messageId,
    required this.spamScore,
    required this.indicators,
    required this.isSpam,
  });

  @override
  List<Object?> get props => [messageId, spamScore, indicators, isSpam];
}

/// Spam indicators
enum SpamIndicator {
  repetitiveText,
  excessiveLinks,
  promotional,
  massSent,
  rapidFire,
  copiedMessage,
}

/// Fake profile detection result (Point 205)
class FakeProfileDetectionResult extends Equatable {
  final String userId;
  final double fakeScore; // 0-1
  final List<FakeProfileIndicator> indicators;
  final bool isSuspicious;

  const FakeProfileDetectionResult({
    required this.userId,
    required this.fakeScore,
    required this.indicators,
    required this.isSuspicious,
  });

  @override
  List<Object?> get props => [userId, fakeScore, indicators, isSuspicious];
}

/// Fake profile indicators
enum FakeProfileIndicator {
  stockPhoto,
  celebrityPhoto,
  reverseImageMatch,
  incompleteProfile,
  rapidAccountCreation,
  suspiciousBehavior,
  noVerification,
}

/// Scam detection result (Point 206)
class ScamDetectionResult extends Equatable {
  final String conversationId;
  final double scamScore; // 0-1
  final List<ScamIndicator> indicators;
  final bool isScam;

  const ScamDetectionResult({
    required this.conversationId,
    required this.scamScore,
    required this.indicators,
    required this.isScam,
  });

  @override
  List<Object?> get props => [conversationId, scamScore, indicators, isScam];
}

/// Scam indicators
enum ScamIndicator {
  moneyRequest,
  externalLinks,
  urgencyLanguage,
  tooGoodToBeTrue,
  askingForPersonalInfo,
  movingOffPlatform,
}

/// Catfish detection result (Point 207)
class CatfishDetectionResult extends Equatable {
  final String userId;
  final double catfishScore; // 0-1
  final List<CatfishIndicator> indicators;
  final FaceConsistencyAnalysis? faceConsistency;
  final bool isSuspicious;

  const CatfishDetectionResult({
    required this.userId,
    required this.catfishScore,
    required this.indicators,
    this.faceConsistency,
    required this.isSuspicious,
  });

  @override
  List<Object?> get props => [
        userId,
        catfishScore,
        indicators,
        faceConsistency,
        isSuspicious,
      ];
}

/// Catfish indicators
enum CatfishIndicator {
  inconsistentFaces,
  modelPhotos,
  heavilyEdited,
  ageInconsistent,
  onlyGroupPhotos,
  refusesVideoCall,
}

/// Face consistency analysis
class FaceConsistencyAnalysis extends Equatable {
  final double consistencyScore; // 0-1, higher = more consistent
  final int photosAnalyzed;
  final List<String> inconsistentPhotoIds;

  const FaceConsistencyAnalysis({
    required this.consistencyScore,
    required this.photosAnalyzed,
    required this.inconsistentPhotoIds,
  });

  bool get isConsistent => consistencyScore > 0.7;

  @override
  List<Object?> get props => [
        consistencyScore,
        photosAnalyzed,
        inconsistentPhotoIds,
      ];
}
