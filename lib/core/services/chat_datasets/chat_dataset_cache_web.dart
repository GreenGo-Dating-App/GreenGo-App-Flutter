import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

/// Web: dataset files kept in the browser's Cache Storage (persists across
/// visits, unlike the in-memory copy), keyed by their versioned Storage path.
/// A new build = new path = new download; files of older builds are removed
/// when a newer manifest is written. Best-effort: any failure (private mode,
/// storage blocked, old browser) means "not cached" and the app downloads.
class ChatDatasetCache {
  static const String _cacheName = 'gg-chat-datasets-v1';
  static const String _prefix = '/__chat_datasets/';

  JSObject? _storage() {
    final c = globalContext.getProperty<JSAny?>('caches'.toJS);
    return c is JSObject ? c : null;
  }

  Future<JSObject?> _open() async {
    final s = _storage();
    if (s == null) return null;
    final p = s.callMethod<JSPromise<JSObject>>('open'.toJS, _cacheName.toJS);
    return p.toDart;
  }

  String _key(String path) => '$_prefix${Uri.encodeComponent(path)}';

  Future<Uint8List?> read(String path) async {
    try {
      final cache = await _open();
      if (cache == null) return null;
      final res = await cache.callMethod<JSPromise<JSAny?>>('match'.toJS, _key(path).toJS).toDart;
      if (res is! JSObject) return null;
      final buf = await res.callMethod<JSPromise<JSArrayBuffer>>('arrayBuffer'.toJS).toDart;
      return buf.toDart.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String path, Uint8List bytes) async {
    try {
      final cache = await _open();
      if (cache == null) return;
      final responseCtor = globalContext.getProperty<JSFunction>('Response'.toJS);
      final res = responseCtor.callAsConstructor<JSObject>(bytes.toJS);
      await cache.callMethod<JSPromise<JSAny?>>('put'.toJS, _key(path).toJS, res).toDart;
    } catch (_) {/* cache is best-effort */}
  }

  Future<Uint8List?> readManifest() => read('manifest.json');

  Future<void> writeManifest(Uint8List bytes) async {
    await write('manifest.json', bytes);
    // Drop files of older builds: keep only paths the new manifest mentions.
    try {
      final text = String.fromCharCodes(bytes);
      final cache = await _open();
      if (cache == null) return;
      final keys = await cache.callMethod<JSPromise<JSArray<JSObject>>>('keys'.toJS).toDart;
      for (final req in keys.toDart) {
        final url = (req.getProperty<JSString>('url'.toJS)).toDart;
        final i = url.indexOf(_prefix);
        if (i < 0) continue;
        final path = Uri.decodeComponent(url.substring(i + _prefix.length));
        if (path == 'manifest.json' || text.contains('"$path"')) continue;
        await cache.callMethod<JSPromise<JSAny?>>('delete'.toJS, req).toDart;
      }
    } catch (_) {}
  }
}
