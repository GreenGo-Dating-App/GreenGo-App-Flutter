import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// Error codes for photo validation — mapped to i18n keys in UI
enum PhotoValidationError {
  mainNoFace,
  mainNotForward,
  explicitNudity,
  explicitContent,
  tooMuchSkin,
  tooLarge,
}

/// Photo validation results
class PhotoValidationResult {
  final bool isValid;
  final String? errorMessage;
  final PhotoValidationError? errorCode;
  final bool hasFace;

  const PhotoValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorCode,
    this.hasFace = false,
  });

  factory PhotoValidationResult.valid({bool hasFace = false}) =>
      PhotoValidationResult(isValid: true, hasFace: hasFace);

  factory PhotoValidationResult.invalid(
    String message, {
    PhotoValidationError? code,
  }) =>
      PhotoValidationResult(
        isValid: false,
        errorMessage: message,
        errorCode: code,
      );
}

/// Service for validating profile photos — ALL processing runs locally on-device
///
/// - Main photo (index 0) must have a clearly visible face
/// - All public photos are scanned for explicit/nude content using:
///   1. On-device skin pixel ratio analysis (YCbCr color space)
///   2. Google ML Kit Image Labeling (on-device model)
///   3. Face detection (Google ML Kit on-device)
class PhotoValidationService {
  static final PhotoValidationService _instance = PhotoValidationService._();
  factory PhotoValidationService() => _instance;
  PhotoValidationService._();

  FaceDetector? _faceDetector;
  ImageLabeler? _imageLabeler;

  /// Labels that indicate explicit/nude content
  static const Set<String> _explicitLabels = {
    // Nudity / body exposure
    'nudity',
    'nude',
    'naked',
    'topless',
    'underwear',
    'lingerie',
    'brassiere',
    'bra',
    'bikini',
    'swimwear',
    'swimsuit',
    'bathing suit',
    'thong',
    'panties',
    'briefs',
    'boxers',
    // Body parts (when prominent)
    'chest',
    'breast',
    'buttocks',
    'cleavage',
    'torso',
    'abdomen',
    'navel',
    // Suggestive
    'erotic',
    'sexy',
    'sensual',
    'provocative',
    'seductive',
    'intimate',
    'porn',
    'pornography',
    'adult content',
    'sexual',
  };

  /// Labels that are fine / not explicit
  static const Set<String> _safeLabels = {
    'person',
    'people',
    'face',
    'smile',
    'selfie',
    'portrait',
    'clothing',
    'shirt',
    'dress',
    'suit',
    'jacket',
    'outdoor',
    'nature',
    'building',
    'food',
    'animal',
    'sport',
    'travel',
  };

  /// Skin detection threshold — if skin pixels exceed this ratio, flag the photo
  /// 0.45 = 45% of visible pixels are skin-colored
  static const double _skinRatioThreshold = 0.45;

  /// High skin ratio that is almost certainly explicit
  static const double _skinRatioHigh = 0.60;

  FaceDetector get faceDetector {
    _faceDetector ??= FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15,
      ),
    );
    return _faceDetector!;
  }

  ImageLabeler get imageLabeler {
    _imageLabeler ??= ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.5),
    );
    return _imageLabeler!;
  }

  /// Validate a photo intended to be the main/first profile photo.
  /// Requires a clearly visible face AND no explicit content.
  Future<PhotoValidationResult> validateMainPhoto(File photo) async {
    // First check for explicit content
    final nsfwResult = await _checkExplicitContent(photo);
    if (!nsfwResult.isValid) return nsfwResult;

    // Then check for face
    try {
      final inputImage = InputImage.fromFile(photo);
      final faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return PhotoValidationResult.invalid(
          'mainNoFace',
          code: PhotoValidationError.mainNoFace,
        );
      }

      // Check that at least one face is front-facing enough
      bool hasGoodFace = false;
      for (final face in faces) {
        final yAngle = face.headEulerAngleY ?? 0;
        final zAngle = face.headEulerAngleZ ?? 0;

        if (yAngle.abs() < 45 && zAngle.abs() < 45) {
          hasGoodFace = true;
          break;
        }
      }

      if (!hasGoodFace) {
        return PhotoValidationResult.invalid(
          'mainNotForward',
          code: PhotoValidationError.mainNotForward,
        );
      }

      return PhotoValidationResult.valid(hasFace: true);
    } catch (e) {
      debugPrint('Face detection error: $e');
      return PhotoValidationResult.valid(hasFace: false);
    }
  }

  /// Validate a public profile photo (non-main).
  /// Checks for explicit/nude content. No face requirement.
  Future<PhotoValidationResult> validatePublicPhoto(File photo) async {
    // Check file size
    final fileSize = await photo.length();
    if (fileSize > 10 * 1024 * 1024) {
      return PhotoValidationResult.invalid(
        'tooLarge',
        code: PhotoValidationError.tooLarge,
      );
    }

    // Check for explicit content
    return _checkExplicitContent(photo);
  }

  /// Combined explicit content detection — fully local
  /// Uses skin pixel analysis + ML Kit image labeling
  Future<PhotoValidationResult> _checkExplicitContent(File photo) async {
    try {
      // Run skin analysis and label detection in parallel
      final results = await Future.wait([
        _analyzeSkinRatio(photo),
        _checkLabels(photo),
      ]);

      final skinRatio = results[0] as double;
      final labelResult = results[1] as _LabelCheckResult;

      debugPrint(
        'Photo validation: skinRatio=${skinRatio.toStringAsFixed(2)}, '
        'explicitLabels=${labelResult.explicitLabels}, '
        'safeLabels=${labelResult.safeLabels}',
      );

      // Very high skin ratio — almost certainly explicit
      if (skinRatio >= _skinRatioHigh) {
        return PhotoValidationResult.invalid(
          'explicitNudity',
          code: PhotoValidationError.explicitNudity,
        );
      }

      // Explicit labels detected by ML Kit
      if (labelResult.explicitLabels.isNotEmpty) {
        return PhotoValidationResult.invalid(
          'explicitContent',
          code: PhotoValidationError.explicitContent,
        );
      }

      // Moderate skin ratio without safe context labels
      if (skinRatio >= _skinRatioThreshold && labelResult.safeLabels.isEmpty) {
        return PhotoValidationResult.invalid(
          'tooMuchSkin',
          code: PhotoValidationError.tooMuchSkin,
        );
      }

      return PhotoValidationResult.valid();
    } catch (e) {
      debugPrint('Explicit content check error: $e');
      // On error, allow but could flag for manual review
      return PhotoValidationResult.valid();
    }
  }

  /// Analyze skin-colored pixel ratio using YCbCr color space.
  /// Runs locally — decodes image and samples pixels.
  Future<double> _analyzeSkinRatio(File photo) async {
    try {
      final bytes = await photo.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 200, // Scale down for performance
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return 0.0;

      final pixels = byteData.buffer.asUint8List();
      int skinPixels = 0;
      int totalPixels = 0;

      // Sample every 2nd pixel for speed
      for (int i = 0; i < pixels.length; i += 8) {
        final r = pixels[i];
        final g = pixels[i + 1];
        final b = pixels[i + 2];
        final a = pixels[i + 3];

        // Skip transparent pixels
        if (a < 128) continue;

        totalPixels++;

        if (_isSkinColor(r, g, b)) {
          skinPixels++;
        }
      }

      if (totalPixels == 0) return 0.0;
      return skinPixels / totalPixels;
    } catch (e) {
      debugPrint('Skin analysis error: $e');
      return 0.0;
    }
  }

  /// Detect skin color using YCbCr color space thresholds.
  /// This is a well-established computer vision technique.
  bool _isSkinColor(int r, int g, int b) {
    // Rule 1: Basic RGB range for skin tones
    if (r <= 95 || g <= 40 || b <= 20) return false;
    if ((r - g).abs() <= 15) return false;
    if (r <= g || r <= b) return false;

    // Rule 2: YCbCr color space check (more accurate across skin tones)
    final cb = 128 - 0.169 * r - 0.331 * g + 0.500 * b;
    final cr = 128 + 0.500 * r - 0.419 * g - 0.081 * b;

    // Skin tones in YCbCr space
    return cb >= 77 && cb <= 127 && cr >= 133 && cr <= 173;
  }

  /// Check image labels using on-device ML Kit Image Labeling
  Future<_LabelCheckResult> _checkLabels(File photo) async {
    try {
      final inputImage = InputImage.fromFile(photo);
      final labels = await imageLabeler.processImage(inputImage);

      final explicitLabels = <String>[];
      final safeLabels = <String>[];

      for (final label in labels) {
        final text = label.label.toLowerCase();
        final confidence = label.confidence;

        // Check against explicit label list
        if (_explicitLabels.any((el) => text.contains(el)) &&
            confidence > 0.5) {
          explicitLabels.add('${label.label} (${(confidence * 100).toInt()}%)');
        }

        // Check against safe label list
        if (_safeLabels.any((sl) => text.contains(sl)) && confidence > 0.4) {
          safeLabels.add(label.label);
        }
      }

      return _LabelCheckResult(
        explicitLabels: explicitLabels,
        safeLabels: safeLabels,
      );
    } catch (e) {
      debugPrint('Image labeling error: $e');
      return const _LabelCheckResult(explicitLabels: [], safeLabels: []);
    }
  }

  /// Check if a photo contains a visible face
  Future<bool> containsFace(File photo) async {
    try {
      final inputImage = InputImage.fromFile(photo);
      final faces = await faceDetector.processImage(inputImage);
      return faces.isNotEmpty;
    } catch (e) {
      debugPrint('Face detection error: $e');
      return false;
    }
  }

  void dispose() {
    _faceDetector?.close();
    _faceDetector = null;
    _imageLabeler?.close();
    _imageLabeler = null;
  }
}

class _LabelCheckResult {
  final List<String> explicitLabels;
  final List<String> safeLabels;

  const _LabelCheckResult({
    required this.explicitLabels,
    required this.safeLabels,
  });
}
