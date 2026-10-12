import 'dart:typed_data';

/// Fallback for platforms with neither dart:io nor JS (tests use the io one).
class ChatDatasetCache {
  Future<Uint8List?> read(String path) async => null;
  Future<void> write(String path, Uint8List bytes) async {}
  Future<Uint8List?> readManifest() async => null;
  Future<void> writeManifest(Uint8List bytes) async {}
}
