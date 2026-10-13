import 'dart:convert';

import 'package:flutter/foundation.dart';

/// A phrasebook hit: [text] in the target language (or the original when it
/// already is in that language, [same]) and the source language when it is
/// unambiguous.
@immutable
class PhrasebookMatch {
  const PhrasebookMatch({required this.text, this.same = false, this.source});
  final String text;
  final bool same;
  final String? source;
}

/// Bundled translations of very common short chat phrases
/// (`assets/i18n/chat_phrasebook.json`): "hi", "thanks", "how are you?" are
/// translated on the device, with zero API cost and no network.
///
/// Matching is exact after [normalize] (lowercase, punctuation and emoji
/// dropped, accents kept: "já" is not "ja"). A text that matches entries with
/// different outputs ("ciao" = hi / bye) is left to the API, and a text that
/// already is a variant in the target's base language is returned as is.
class ChatPhrasebook {
  ChatPhrasebook._(this._entries, this._index);

  /// Empty book (asset missing or unreadable).
  ChatPhrasebook.empty() : this._(const [], const {});

  factory ChatPhrasebook.fromJson(String json) {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final entries = <Map<String, List<String>>>[];
    final index = <String, List<(int, String)>>{};
    for (final raw in (decoded['entries'] as List? ?? const [])) {
      final entry = <String, List<String>>{};
      (raw as Map).forEach((lang, variants) {
        final list = [for (final v in variants as List) v as String];
        if (list.isNotEmpty) entry[lang as String] = list;
      });
      final i = entries.length;
      entries.add(entry);
      entry.forEach((lang, variants) {
        for (final v in variants) {
          final key = normalize(v);
          if (key.isEmpty) continue;
          final hits = index.putIfAbsent(key, () => []);
          if (!hits.contains((i, lang))) hits.add((i, lang));
        }
      });
    }
    return ChatPhrasebook._(entries, index);
  }

  final List<Map<String, List<String>>> _entries;
  final Map<String, List<(int, String)>> _index;

  bool get isEmpty => _entries.isEmpty;

  /// Longer texts are never phrasebook material (skip the work).
  static const int maxChars = 60;

  static final RegExp _dash = RegExp(r'[-_]');
  static final RegExp _notWord = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);
  static final RegExp _spaces = RegExp(r'\s+');
  static final RegExp _trailing = RegExp(r'[^\p{L}\p{N}]+$', unicode: true);

  /// Lowercase, dashes as spaces, every other non letter / digit removed
  /// (punctuation, emoji, apostrophes, ¿ ¡), whitespace collapsed.
  static String normalize(String s) => s
      .toLowerCase()
      .replaceAll(_dash, ' ')
      .replaceAll(_notWord, '')
      .replaceAll(_spaces, ' ')
      .trim();

  /// Phrasebook column for a normalized target (`pt-BR` -> `pt_BR`), or null
  /// for a language the book does not cover.
  static String? languageKey(String target) {
    final t = target.toLowerCase().replaceAll('_', '-');
    if (t == 'pt-br') return 'pt_BR';
    final base = t.split('-').first;
    return const {'en', 'de', 'es', 'fr', 'it', 'pt'}.contains(base)
        ? base
        : null;
  }

  static String _base(String lang) => lang.split('_').first.toLowerCase();

  /// [text] in [target] (a normalized code such as `it` or `pt-BR`), or null
  /// when the book has no single answer for it.
  PhrasebookMatch? lookup(String text, String target) {
    if (_entries.isEmpty) return null;
    final key = languageKey(target);
    if (key == null) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > maxChars) return null;
    final hits = _index[normalize(trimmed)];
    if (hits == null || hits.isEmpty) return null;

    final sources = {for (final h in hits) _base(h.$2)};
    final source = sources.length == 1 ? sources.single : null;
    // Already a phrase of the target's base language (pt and pt-BR alike, as
    // everywhere else in chat translation): nothing to translate.
    if (sources.contains(_base(key))) {
      return PhrasebookMatch(text: text, same: true, source: _base(key));
    }
    final outputs = <String>{};
    for (final h in hits) {
      final out = _entries[h.$1][key];
      if (out == null) return null;
      outputs.add(out.first);
    }
    if (outputs.length != 1) return null; // ambiguous ("ciao")

    // Keep the sender's trailing punctuation / emoji ("thanks!! 😊").
    final suffix = _trailing.firstMatch(trimmed)?.group(0) ?? '';
    var out = outputs.single;
    // Spanish opening marks follow the sender's closing ones.
    if (key == 'es') {
      if (!suffix.contains('?')) {
        out = out.replaceAll('¿', '');
      } else if (!out.contains('¿')) {
        out = '¿$out';
      }
      if (suffix.contains('!') && !out.contains('¡')) out = '¡$out';
    }
    return PhrasebookMatch(text: '$out$suffix', source: source);
  }
}
