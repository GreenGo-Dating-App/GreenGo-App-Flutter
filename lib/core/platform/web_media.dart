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

  /// An [ImageProvider] that previews a picked [file] on either platform.
  /// On web the `blob:` URL is loaded via [NetworkImage]; on mobile via
  /// [FileImage]. Use this instead of `FileImage(File(xfile.path))`.
  static ImageProvider imageProviderFor(XFile file) {
    if (kIsWeb) return NetworkImage(file.path);
    return FileImage(File(file.path));
  }
}
