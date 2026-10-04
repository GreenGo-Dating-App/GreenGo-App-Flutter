import 'dart:async';

import 'package:flutter/foundation.dart';

/// Sends one batch: `submitSharedTranslations({target, items})`.
typedef SharedTranslationSubmitter = Future<void> Function(
    String target, List<Map<String, String>> items);

/// Queues on-device translations of PUBLIC content (events, attractions,
/// experiences) and contributes them to the shared store in the background.
///
/// The server only shares a translation once TWO different users submitted
/// the same one, so a contribution is a vote, not a write. Fire-and-forget:
/// debounced (~3 s), at most [maxPerCall] items per call, errors swallowed,
/// never awaited by the UI. NEVER feed private chat text into this.
class SharedTranslationContributor {
  SharedTranslationContributor({
    required SharedTranslationSubmitter submit,
    this.debounce = const Duration(seconds: 3),
  }) : _submit = submit;

  final SharedTranslationSubmitter _submit;
  final Duration debounce;

  /// Server caps (functions/src/messaging/submitSharedTranslations.ts).
  static const int maxPerCall = 20;
  static const int maxChars = 5000;

  /// Pending items kept at most; extra ones are dropped (best effort).
  static const int maxQueued = 200;

  /// Items already sent this session (by target + text), bounded.
  static const int _maxSent = 2000;

  /// target -> text -> translation (insertion-ordered).
  final Map<String, Map<String, String>> _queue = {};
  final Set<String> _sent = <String>{};
  Timer? _timer;
  int _queued = 0;

  @visibleForTesting
  int get pendingCount => _queued;

  /// Queues (text -> translation) in [target]. Ignores empty / oversize /
  /// untranslated texts and anything already queued or sent.
  void add(String target, String text, String translation) {
    if (text.trim().isEmpty || translation.trim().isEmpty) return;
    if (text.length > maxChars || translation.length > maxChars) return;
    if (text.trim() == translation.trim()) return;
    final key = '$target\u0001$text';
    if (_sent.contains(key)) return;
    final forTarget = _queue.putIfAbsent(target, () => <String, String>{});
    if (forTarget.containsKey(text)) return;
    if (_queued >= maxQueued) return;
    forTarget[text] = translation;
    _queued++;
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(flush()));
  }

  /// Sends everything queued now (chunks of [maxPerCall]). Never throws.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty) return;
    final batches = <MapEntry<String, List<Map<String, String>>>>[];
    _queue.forEach((target, items) {
      final list = [
        for (final e in items.entries) {'text': e.key, 'translation': e.value},
      ];
      for (var i = 0; i < list.length; i += maxPerCall) {
        batches.add(MapEntry(target,
            list.sublist(i, i + maxPerCall > list.length ? list.length : i + maxPerCall)));
      }
      for (final text in items.keys) {
        if (_sent.length >= _maxSent) _sent.remove(_sent.first);
        _sent.add('$target\u0001$text');
      }
    });
    _queue.clear();
    _queued = 0;
    for (final b in batches) {
      try {
        await _submit(b.key, b.value);
      } catch (e) {
        debugPrint('submitSharedTranslations failed: $e');
      }
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _queue.clear();
    _queued = 0;
  }
}
