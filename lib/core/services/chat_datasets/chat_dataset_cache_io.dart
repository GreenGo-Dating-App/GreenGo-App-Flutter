import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Mobile/desktop: dataset files kept in the app support directory, keyed by
/// their versioned Storage path (a new build = new path = new download; old
/// versions are removed when a newer manifest is written).
class ChatDatasetCache {
  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}/chat_datasets');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  String _name(String path) => path.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  Future<Uint8List?> read(String path) async {
    try {
      final f = File('${(await _dir()).path}/${_name(path)}');
      return f.existsSync() ? await f.readAsBytes() : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String path, Uint8List bytes) async {
    try {
      final dir = await _dir();
      await File('${dir.path}/${_name(path)}').writeAsBytes(bytes, flush: true);
    } catch (_) {/* cache is best-effort */}
  }

  Future<Uint8List?> readManifest() => read('manifest.json');

  Future<void> writeManifest(Uint8List bytes) async {
    await write('manifest.json', bytes);
    // Drop files of older builds: keep only names the new manifest mentions.
    try {
      final text = String.fromCharCodes(bytes);
      final dir = await _dir();
      for (final f in dir.listSync().whereType<File>()) {
        final n = f.uri.pathSegments.last;
        if (n == 'manifest.json') continue;
        final versioned = n.replaceFirst('chat_datasets_', '').split('_').first;
        if (!text.contains(versioned)) f.deleteSync();
      }
    } catch (_) {}
  }
}
