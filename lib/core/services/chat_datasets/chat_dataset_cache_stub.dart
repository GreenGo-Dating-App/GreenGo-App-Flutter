import 'dart:typed_data';

/// Web: no file system. The dataset files are immutable and served with a
/// one-year Cache-Control, so the browser's HTTP cache keeps them instead.
class ChatDatasetCache {
  Future<Uint8List?> read(String path) async => null;
  Future<void> write(String path, Uint8List bytes) async {}
  Future<Uint8List?> readManifest() async => null;
  Future<void> writeManifest(Uint8List bytes) async {}
}
