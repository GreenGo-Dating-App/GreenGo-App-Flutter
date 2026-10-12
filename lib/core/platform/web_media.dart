import 'dart:io' show File;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart' show XFile;

/// Platform-safe media helpers so a single codebase uploads/displays picked
/// images on **web** (no `dart:io`) and **mobile** alike.
///
/// Why this exists: `image_picker` works on web and returns an [XFile] backed
/// by a `blob:` URL. But `File(xfile.path)` and `Reference.putFile(File)` are
/// `dart:io` APIs that throw `UnsupportedError` on web. Route every picked-image
/// upload/preview through here instead of constructing a `File` directly.
class WebMedia {
  const WebMedia._();

  /// Uploads a picked [file] to [ref], choosing the platform-correct path:
  /// - web → `putData(await file.readAsBytes())`
  /// - mobile → `putFile(File(file.path))`
  static Future<TaskSnapshot> uploadXFile(
    Reference ref,
    XFile file, {
    String contentType = 'image/jpeg',
    Map<String, String>? customMetadata,
  }) async {
    final task = await startXFileUpload(
      ref,
      file,
      contentType: contentType,
      customMetadata: customMetadata,
    );
    return task;
  }

  /// Like [uploadXFile] but hands back the running [UploadTask] so callers can
  /// listen to `snapshotEvents` for progress. On web the bytes are read first
  /// (a `blob:` URL from image_picker / record works with `readAsBytes`).
  static Future<UploadTask> startXFileUpload(
    Reference ref,
    XFile file, {
    required String contentType,
    Map<String, String>? customMetadata,
  }) async {
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: customMetadata,
    );
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      return ref.putData(bytes, metadata);
    }
    return ref.putFile(File(file.path), metadata);
  }

  /// File extension of a picked video. On mobile it comes from the path (the
  /// historical behaviour); on web the path is a `blob:` URL with no
  /// extension, so it comes from the original file name, then the MIME type.
  static String videoExtension(XFile video) {
    if (!kIsWeb) return video.path.split('.').last;
    final name = video.name;
    final dot = name.lastIndexOf('.');
    if (dot >= 0 && dot < name.length - 1) {
      return name.substring(dot + 1).toLowerCase();
    }
    final mime = video.mimeType;
    if (mime != null && mime.startsWith('video/')) {
      final sub = mime.substring('video/'.length).split(';').first.trim();
      if (sub.isNotEmpty) return sub == 'quicktime' ? 'mov' : sub;
    }
    return 'mp4';
  }

  /// Storage `contentType` for a recorded voice clip. Mobile (and Safari)
  /// record AAC in an MP4 container (`audio/mp4`); browsers without an MP4
  /// recorder record Opus/WebM or WAV, tagged on the [XFile.mimeType] by
  /// `VoiceRecordSendButton`. Always a bare type (no `;codecs=`), as the
  /// storage rules match the whole string.
  static String voiceContentType(XFile file) {
    final mime = file.mimeType?.split(';').first.trim().toLowerCase();
    if (mime == null || mime.isEmpty) return 'audio/mp4';
    return mime;
  }

  /// File extension matching [voiceContentType].
  static String voiceExtension(XFile file) {
    switch (voiceContentType(file)) {
      case 'audio/webm':
        return 'webm';
      case 'audio/wav':
        return 'wav';
      default:
        return 'm4a';
    }
  }

  /// An [ImageProvider] that previews a picked [file] on either platform.
  /// On web the `blob:` URL is loaded via [NetworkImage]; on mobile via
  /// [FileImage]. Use this instead of `FileImage(File(xfile.path))`.
  static ImageProvider imageProviderFor(XFile file) {
    if (kIsWeb) return NetworkImage(file.path);
    return FileImage(File(file.path));
  }
}
