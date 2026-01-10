import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Image Compression Utility
/// Reduces image file sizes before uploading to Firebase Storage
/// This significantly reduces storage costs and bandwidth usage
class ImageCompression {
  // Compression quality settings
  static const int profilePhotoQuality = 80; // High quality for profile pics
  static const int chatImageQuality = 70; // Medium quality for chat images
  static const int thumbnailQuality = 50; // Lower quality for thumbnails

  // Max dimensions
  static const int profilePhotoMaxWidth = 1080;
  static const int profilePhotoMaxHeight = 1080;
  static const int chatImageMaxWidth = 800;
  static const int chatImageMaxHeight = 800;
  static const int thumbnailMaxWidth = 200;
  static const int thumbnailMaxHeight = 200;

  // File size thresholds (in bytes)
  static const int maxProfilePhotoSize = 500 * 1024; // 500KB
  static const int maxChatImageSize = 300 * 1024; // 300KB
  static const int compressionThreshold = 100 * 1024; // Don't compress under 100KB

  /// Compress image for profile photo upload
  /// Returns compressed file or original if already small enough
  static Future<File> compressProfilePhoto(File file) async {
    return _compressImage(
      file: file,
      quality: profilePhotoQuality,
      maxWidth: profilePhotoMaxWidth,
      maxHeight: profilePhotoMaxHeight,
      maxFileSize: maxProfilePhotoSize,
    );
  }

  /// Compress image for chat/message upload
  static Future<File> compressChatImage(File file) async {
    return _compressImage(
      file: file,
      quality: chatImageQuality,
      maxWidth: chatImageMaxWidth,
      maxHeight: chatImageMaxHeight,
      maxFileSize: maxChatImageSize,
    );
  }

  /// Create thumbnail from image
  static Future<File> createThumbnail(File file) async {
    return _compressImage(
      file: file,
      quality: thumbnailQuality,
      maxWidth: thumbnailMaxWidth,
      maxHeight: thumbnailMaxHeight,
      maxFileSize: 50 * 1024, // 50KB max for thumbnails
    );
  }

  /// Compress image from bytes (for web/memory sources)
  static Future<Uint8List?> compressBytes(
    Uint8List bytes, {
    int quality = 80,
    int maxWidth = 1080,
    int maxHeight = 1080,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      debugPrint('Image compression error: $e');
      return bytes; // Return original on error
    }
  }

  /// Main compression method
  static Future<File> _compressImage({
    required File file,
    required int quality,
    required int maxWidth,
    required int maxHeight,
    required int maxFileSize,
  }) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        debugPrint('File does not exist: ${file.path}');
        return file;
      }

      // Check file size - skip if already small
      final fileSize = await file.length();
      if (fileSize < compressionThreshold) {
        debugPrint('Image already small (${_formatSize(fileSize)}), skipping compression');
        return file;
      }

      debugPrint('Original image size: ${_formatSize(fileSize)}');

      // Get temp directory for compressed file
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(file.path);
      final targetPath = path.join(
        tempDir.path,
        '${fileName}_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Compress image
      XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
      );

      if (compressedXFile == null) {
        debugPrint('Compression failed, returning original');
        return file;
      }

      File compressedFile = File(compressedXFile.path);
      int compressedSize = await compressedFile.length();

      // If still too large, compress more aggressively
      if (compressedSize > maxFileSize) {
        int newQuality = quality - 20;
        while (compressedSize > maxFileSize && newQuality > 20) {
          final retryPath = path.join(
            tempDir.path,
            '${fileName}_retry_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

          compressedXFile = await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            retryPath,
            quality: newQuality,
            minWidth: maxWidth,
            minHeight: maxHeight,
            format: CompressFormat.jpeg,
          );

          if (compressedXFile != null) {
            // Delete previous compressed file
            if (await compressedFile.exists()) {
              await compressedFile.delete();
            }
            compressedFile = File(compressedXFile.path);
            compressedSize = await compressedFile.length();
          }

          newQuality -= 10;
        }
      }

      final savings = fileSize - compressedSize;
      final savingsPercent = ((savings / fileSize) * 100).toStringAsFixed(1);

      debugPrint('Compressed: ${_formatSize(fileSize)} → ${_formatSize(compressedSize)} '
          '(saved ${_formatSize(savings)}, $savingsPercent%)');

      return compressedFile;
    } catch (e) {
      debugPrint('Image compression error: $e');
      return file; // Return original on error
    }
  }

  /// Check if image needs compression
  static Future<bool> needsCompression(File file, {int? threshold}) async {
    try {
      final size = await file.length();
      return size > (threshold ?? compressionThreshold);
    } catch (e) {
      return false;
    }
  }

  /// Get image file size info
  static Future<Map<String, dynamic>> getImageInfo(File file) async {
    try {
      final size = await file.length();
      return {
        'path': file.path,
        'size': size,
        'sizeFormatted': _formatSize(size),
        'needsCompression': size > compressionThreshold,
      };
    } catch (e) {
      return {
        'path': file.path,
        'error': e.toString(),
      };
    }
  }

  /// Format file size for display
  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Batch compress multiple images
  static Future<List<File>> compressMultiple(
    List<File> files, {
    int quality = 80,
    int maxWidth = 1080,
    int maxHeight = 1080,
    int maxFileSize = 500 * 1024,
  }) async {
    final List<File> compressed = [];

    for (final file in files) {
      final result = await _compressImage(
        file: file,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        maxFileSize: maxFileSize,
      );
      compressed.add(result);
    }

    return compressed;
  }

  /// Clean up temporary compressed files
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      for (final file in files) {
        if (file is File && file.path.contains('_compressed_')) {
          await file.delete();
        }
      }

      debugPrint('Cleaned up temporary compressed files');
    } catch (e) {
      debugPrint('Cleanup error: $e');
    }
  }
}
