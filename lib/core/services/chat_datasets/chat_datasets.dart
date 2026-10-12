import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'chat_dataset_cache.dart';
import 'difficulty_estimator.dart';
import 'keyword_matcher.dart';

/// A text in the 7 app languages.
class LocalizedText {
  const LocalizedText(this._byLang);
  final Map<String, String> _byLang;

  /// [locale] like 'it', 'pt_BR', 'pt-BR', 'en_US'; falls back to English.
  String of(String locale) {
    final l = locale.replaceAll('-', '_');
    if (l.toLowerCase() == 'pt_br') return _byLang['pt_BR'] ?? _byLang['pt'] ?? _byLang['en'] ?? '';
    final base = l.split('_').first;
    return _byLang[base] ?? _byLang['en'] ?? '';
  }

  static LocalizedText fromJson(Object? m) => LocalizedText({
        if (m is Map)
          for (final e in m.entries) e.key.toString(): e.value.toString(),
      });
}

class DatasetQuote {
  const DatasetQuote({required this.id, required this.author, required this.text, this.died});
  final String id;
  final String author;
  final int? died;
  final LocalizedText text;
}

class DatasetItem {
  const DatasetItem({required this.id, required this.topic, required this.text, this.level});
  final String id;
  final String topic;
  final String? level;
  final LocalizedText text;
}

class CulturalTip {
  const CulturalTip({required this.id, required this.category, required this.text});
  final String id;
  final String category;
  final LocalizedText text;
}

/// The chat's offline datasets (tools/chat_datasets/build_chat_datasets.js):
/// downloaded ONCE from Firebase Storage (`chat_datasets/manifest.json` names
/// immutable, versioned files), cached on the device, then used offline.
///
/// Each file loads lazily on first use ([keywords] / [difficulty] when a chat
/// opens, [quotes] for the phrase of the day, the rest when their sheet
/// opens). Every getter returns null until its file is ready; [changes]
/// notifies when one arrives. Nothing here throws: no dataset = feature hidden.
class ChatDatasets {
  ChatDatasets._();
  static final ChatDatasets instance = ChatDatasets._();

  static const String manifestPath = 'chat_datasets/manifest.json';

  /// Bumped each time a file finishes loading (listen to rebuild).
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  final ChatDatasetCache _cache = ChatDatasetCache();
  Map<String, dynamic>? _manifest;
  Future<Map<String, dynamic>?>? _manifestFuture;
  final Map<String, Future<Object?>> _loading = {};

  KeywordIndex? _keywords;
  DifficultyEstimator? _difficulty;
  List<DatasetQuote>? _quotes;
  List<DatasetItem>? _icebreakers;
  List<DatasetItem>? _sentences;
  Map<String, List<CulturalTip>>? _tips;

  KeywordIndex? get keywords => _keywords;
  DifficultyEstimator? get difficulty => _difficulty;
  List<DatasetQuote>? get quotes => _quotes;
  List<DatasetItem>? get icebreakers => _icebreakers;
  List<DatasetItem>? get sentences => _sentences;
  Map<String, List<CulturalTip>>? get tips => _tips;

  /// Loads what a chat screen needs (keywords + difficulty) in the background.
  void warmUpForChat() {
    unawaited(ensure('keywords'));
    unawaited(ensure('freq'));
  }

  /// Loads dataset [name] (keywords, freq, quotes, icebreakers, sentences,
  /// tips) if not loaded yet. Completes when it is ready or failed.
  Future<void> ensure(String name) async {
    if (_isLoaded(name)) return;
    await (_loading[name] ??= _load(name).whenComplete(() => _loading.remove(name)));
  }

  bool _isLoaded(String name) => switch (name) {
        'keywords' => _keywords != null,
        'freq' => _difficulty != null,
        'quotes' => _quotes != null,
        'icebreakers' => _icebreakers != null,
        'sentences' => _sentences != null,
        'tips' => _tips != null,
        _ => true,
      };

  Future<Object?> _load(String name) async {
    try {
      final manifest = await _readManifest();
      final entry = (manifest?['files'] as Map?)?[name];
      if (entry is! Map || entry['path'] is! String) return null;
      final path = entry['path'] as String;
      var bytes = await _cache.read(path);
      if (bytes == null) {
        final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
        final res = await http.get(Uri.parse(url));
        if (res.statusCode != 200) return null;
        bytes = res.bodyBytes;
        unawaited(_cache.write(path, bytes));
      }
      final parsed = await compute(_decode, bytes);
      _apply(name, parsed);
      changes.value++;
      return parsed;
    } catch (e) {
      debugPrint('[ChatDatasets] $name unavailable: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _readManifest() {
    final m = _manifest;
    if (m != null) return Future.value(m);
    return _manifestFuture ??= () async {
      try {
        final url = await FirebaseStorage.instance.ref(manifestPath).getDownloadURL();
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          _manifest = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          unawaited(_cache.writeManifest(res.bodyBytes));
          return _manifest;
        }
      } catch (e) {
        debugPrint('[ChatDatasets] manifest offline: $e');
      }
      // Offline: the last manifest we saw (its files are cached too).
      final cached = await _cache.readManifest();
      if (cached != null) _manifest = jsonDecode(utf8.decode(cached)) as Map<String, dynamic>;
      return _manifest;
    }().whenComplete(() => _manifestFuture = null);
  }

  void _apply(String name, Object? json) {
    switch (name) {
      case 'keywords':
        if (json is Map<String, dynamic>) _keywords = KeywordIndex.fromJson(json);
      case 'freq':
        if (json is Map) {
          _difficulty = DifficultyEstimator({
            for (final e in json.entries)
              if (e.value is List) e.key.toString(): [for (final w in e.value as List) '$w'],
          });
        }
      case 'quotes':
        if (json is List) {
          _quotes = [
            for (final q in json.whereType<Map>())
              DatasetQuote(
                id: '${q['id']}',
                author: '${q['a'] ?? ''}',
                died: q['d'] is num ? (q['d'] as num).toInt() : null,
                text: LocalizedText.fromJson(q['t']),
              ),
          ];
        }
      case 'icebreakers':
      case 'sentences':
        if (json is List) {
          final items = [
            for (final q in json.whereType<Map>())
              DatasetItem(
                id: '${q['id']}',
                topic: '${q['p'] ?? ''}',
                level: q['l']?.toString(),
                text: LocalizedText.fromJson(q['t']),
              ),
          ];
          if (name == 'icebreakers') {
            _icebreakers = items;
          } else {
            _sentences = items;
          }
        }
      case 'tips':
        if (json is Map) {
          _tips = {
            for (final e in json.entries)
              if (e.value is List)
                e.key.toString(): [
                  for (final t in (e.value as List).whereType<Map>())
                    CulturalTip(
                      id: '${t['id']}',
                      category: '${t['c'] ?? 'general'}',
                      text: LocalizedText.fromJson(t['t']),
                    ),
                ],
          };
        }
    }
  }

  /// The quote for [day] (same for everyone on that date, cycles all 3,000).
  DatasetQuote? quoteOfDay(DateTime day) {
    final q = _quotes;
    if (q == null || q.isEmpty) return null;
    final dayNumber = DateTime.utc(day.year, day.month, day.day)
            .difference(DateTime.utc(2026, 1, 1))
            .inDays;
    return q[dayNumber % q.length];
  }

  @visibleForTesting
  void debugSet({KeywordIndex? keywords, DifficultyEstimator? difficulty}) {
    _keywords = keywords ?? _keywords;
    _difficulty = difficulty ?? _difficulty;
    changes.value++;
  }
}

/// gzip bytes (or plain JSON) -> decoded JSON, off the UI thread.
Object? _decode(Uint8List bytes) {
  final isGzip = bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
  final raw = isGzip ? GZipDecoder().decodeBytes(bytes) : bytes;
  return jsonDecode(utf8.decode(raw));
}
