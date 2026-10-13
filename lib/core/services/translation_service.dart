import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import 'ai_consent_service.dart';
import 'chat_phrasebook.dart';
import 'shared_translation_contributor.dart';

/// `translatePrivateText` call (overridable in tests).
typedef ServerTranslateCall = Future<Map<String, dynamic>> Function(
    Map<String, dynamic> payload);

/// A stored chat message being translated, with the server-written
/// translation fields it already carries (`tr`, `trHash`, `lang`).
///
/// With a ref, a translation is first looked up on the message itself (the
/// chat stream delivers it with the message: no extra read), and a miss goes
/// to `translatePrivateText` by message id, batched, so the server stores the
/// result on the message for every participant and device.
@immutable
class ChatMessageRef {
  const ChatMessageRef({
    required this.kind,
    required this.parentId,
    required this.messageId,
    this.lang,
    this.tr,
    this.trHash,
  });

  /// `conversations/{parentId}/messages/{messageId}`.
  static const String conversation = 'conversation';

  /// `groups/{parentId}/messages/{messageId}`.
  static const String group = 'group';

  final String kind;
  final String parentId;
  final String messageId;

  /// Source language detected by the server (Cloud Translation).
  final String? lang;

  /// Stored translations by normalized target language (`it`, `pt-BR`).
  final Map<String, String>? tr;

  /// [TranslationService.messageTextHash] of the content [tr] belongs to.
  final String? trHash;

  bool get isValid => parentId.isNotEmpty && messageId.isNotEmpty;

  Map<String, String> toPayload() => {
    'kind': kind,
    'parentId': parentId,
    'messageId': messageId,
  };
}

class _ChatPending {
  _ChatPending(this.ref, this.text);
  final ChatMessageRef ref;
  final String text;
  final Completer<TranslationResult> completer = Completer<TranslationResult>();
}

/// Outcome of one translation, carrying ITS OWN detected language.
///
/// Callers must use [detectedLanguage] from the result rather than the
/// service-wide [TranslationService.lastDetectedLanguage]: the latter is shared
/// by every concurrent translation (and was never updated on a cache hit), so
/// reading it after an await attributed one message's language to another and
/// made the chat throw away correct translations as "same language".
@immutable
class TranslationResult {
  const TranslationResult({
    required this.original,
    required this.text,
    this.detectedLanguage,
    this.failed = false,
    this.consentRequired = false,
    this.layer,
  });

  /// Not translated because the user has not accepted (or declined) the AI
  /// processing notice. Also [failed] (never cached), but it is not an error
  /// to report: callers show the original and, where the user acted, ask for
  /// consent (AiConsentGate).
  const TranslationResult.consentRequired(String original)
      : this(original: original, text: original, failed: true, consentRequired: true);

  /// The text that was asked to be translated.
  final String original;

  /// The translation, or [original] when nothing changed or it [failed].
  final String text;

  /// Source language reported by the endpoint (e.g. `en`, `pt`), if known.
  final String? detectedLanguage;

  /// True when the endpoint could not be reached / answered with an error
  /// after all retries. A failed result is never cached, so asking again
  /// retries.
  final bool failed;

  /// See [TranslationResult.consentRequired].
  final bool consentRequired;

  /// Where the answer came from (`skip`, `memory`, `hive`, `message`, `lang`,
  /// `phrasebook`, server `cache` / `api`, ...). Diagnostics and tests only.
  final String? layer;

  /// True when [text] is a real translation that differs from [original].
  bool get isTranslated => !failed && text.trim() != original.trim();
}

/// Translation Service
///
/// Private text (chat messages) is translated only after the user accepted
/// the AI-processing notice ([AiConsentService]; Apple 5.1.2(i), audit H-17).
/// Backends:
///  - PRIVATE text (chat messages, [requiresConsent] true) ALWAYS goes to the
///    `translatePrivateText` callable: the contracted Google Cloud Translation
///    API, server-side, under a DPA (legal audit EU-05 / BR-06). It is never
///    sent from the device to Google's free endpoint, and there is no
///    fallback to it (the old `serverChatTranslation` flag is gone).
///  - PUBLIC content only ([requiresConsent] false: events, attractions,
///    experiences, public reviews): the shared store first, then Google's free
///    endpoint (`translate.googleapis.com/translate_a/single?client=gtx`) as a
///    device-side last resort.
/// Chat translation is private and never touches the shared
/// `translations/` store. The free endpoint rate-limits bursts (HTTP 429), so
/// requests are de-duplicated, throttled, retried with backoff and cached
/// (memory + Hive on device).
class TranslationService {
  factory TranslationService() => _instance;
  TranslationService._internal({
    http.Client? client,
    bool persistent = true,
    Duration Function(int attempt)? backoff,
    SharedTranslationContributor? contributor,
    bool Function()? consentGranted,
    Future<bool> Function()? useServer,
    ServerTranslateCall? serverCall,
    Future<String> Function()? phrasebookLoader,
    Duration batchWindow = const Duration(milliseconds: 30),
  })  : _client = client,
        _phrasebookLoader = phrasebookLoader ?? _loadPhrasebookAsset,
        _batchWindow = batchWindow,
        _persistent = persistent,
        _consentGranted = consentGranted,
        _useServerOverride = useServer,
        _serverCall = serverCall,
        _backoff = backoff ?? _defaultBackoff,
        _contributor = contributor ??
            SharedTranslationContributor(submit: _submitToServer);
  static final TranslationService _instance = TranslationService._internal();

  /// A separate, non-singleton instance for tests (fake HTTP, no Hive, no
  /// backoff delay unless given).
  @visibleForTesting
  factory TranslationService.test({
    required http.Client client,
    Duration Function(int attempt)? backoff,
    SharedTranslationContributor? contributor,
    bool Function()? consentGranted,
    Future<bool> Function()? useServer,
    ServerTranslateCall? serverCall,
    bool productionRouting = false,
    String? phrasebookJson,
    Duration batchWindow = Duration.zero,
  }) =>
      TranslationService._internal(
        client: client,
        persistent: false,
        backoff: backoff ?? (_) => Duration.zero,
        contributor: contributor,
        consentGranted: consentGranted ?? () => true,
        // productionRouting: no override, i.e. exactly what the app does.
        useServer: productionRouting ? null : (useServer ?? () async => false),
        serverCall: serverCall,
        phrasebookLoader: () async => phrasebookJson ?? '{}',
        batchWindow: batchWindow,
      );

  final bool Function()? _consentGranted;
  final Future<bool> Function()? _useServerOverride;
  final ServerTranslateCall? _serverCall;

  Future<bool> _consentOk() async {
    final f = _consentGranted;
    if (f != null) return f();
    final c = AiConsentService.instance;
    await c.ensureLoaded();
    return c.isGranted;
  }

  /// Private text always uses the server (contracted Cloud Translation). The
  /// override exists only so tests can exercise the device-side retry logic
  /// that public content still uses.
  Future<bool> _useServer() async {
    final o = _useServerOverride;
    if (o != null) return o();
    return true;
  }

  static Future<Map<String, dynamic>> _defaultServerCall(
      Map<String, dynamic> payload) async {
    final res = await FirebaseFunctions.instance
        .httpsCallable('translatePrivateText',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 25)))
        .call<Map<String, dynamic>>(payload);
    return Map<String, dynamic>.from(res.data);
  }

  /// One text through `translatePrivateText` (official Cloud Translation).
  Future<TranslationResult> _fetchViaServer(
      String text, String from, String target) async {
    final call = _serverCall ?? _defaultServerCall;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final data = await call({
          'texts': [text],
          'target': target,
          if (from != 'auto') 'source': from,
        });
        final list = data['translations'] as List?;
        final first = (list != null && list.isNotEmpty) ? list.first as Map : null;
        if (first == null) break;
        final detected = first['detectedLanguage'] as String?;
        final out = first['text'] as String? ?? text;
        return TranslationResult(
          original: text,
          text: first['sameLanguage'] == true ? text : out,
          detectedLanguage: detected,
        );
      } catch (e) {
        if (attempt == 0 && isAiConsentRequiredError(e) &&
            await AiConsentService.instance.resyncAfterServerRejection()) {
          continue;
        }
        debugPrint('translatePrivateText failed: $e');
        break;
      }
    }
    return TranslationResult(original: text, text: text, failed: true);
  }

  final http.Client? _client;
  final bool _persistent;
  final Duration Function(int attempt) _backoff;

  /// Contributes on-device translations of PUBLIC content (see
  /// [translateShared]) to the shared store, by two-user consensus.
  final SharedTranslationContributor _contributor;

  static Future<void> _submitToServer(
      String target, List<Map<String, String>> items) async {
    await FirebaseFunctions.instance
        .httpsCallable('submitSharedTranslations',
            options:
                HttpsCallableOptions(timeout: const Duration(seconds: 30)))
        .call<Map<String, dynamic>>({'target': target, 'items': items});
  }

  static const String freeEndpoint =
      'https://translate.googleapis.com/translate_a/single';

  /// Above this many characters the text goes in a POST body instead of the
  /// URL (URLs over ~2k chars are rejected).
  static const int _postThreshold = 1200;
  static const Duration _requestTimeout = Duration(seconds: 8);
  static const int _maxAttempts = 4;

  /// At most this many requests in flight at once: a long chat renders dozens
  /// of bubbles at the same time and must not fire dozens of parallel calls.
  static const int maxConcurrent = 3;

  /// The free endpoint rate-limits per IP; once it is exhausted it answers
  /// roughly every other request with 429 (measured 2026-10-04: alternating
  /// 200/429 at ~2 req/s). Retrying after ~1s succeeds, so back off 0.6s,
  /// 1.2s, 2.4s and pause the whole queue briefly after a 429.
  static Duration _defaultBackoff(int attempt) =>
      Duration(milliseconds: 600 * (1 << attempt) + (attempt * 137) % 200);

  /// Shared pause after a 429 so queued requests don't hammer the endpoint.
  DateTime _coolDownUntil = DateTime.fromMillisecondsSinceEpoch(0);

  // Cache translations to avoid repeated API calls
  final Map<String, String> _translationCache = {};

  /// Detected source language per (source, target, text) cache key, so a cache
  /// hit reports the right language too.
  final Map<String, String> _detectedCache = {};

  /// One in-flight request per key: identical texts share a single call.
  final Map<String, Future<TranslationResult>> _inFlight = {};

  int _active = 0;
  final List<Completer<void>> _waiters = [];

  // Last detected source language from translation
  String? _lastDetectedLanguage;

  /// The detected source language of the most recent [translate] call.
  ///
  /// Prefer [translateDetailed] and its [TranslationResult.detectedLanguage]:
  /// this field is shared by concurrent translations.
  String? get lastDetectedLanguage => _lastDetectedLanguage;

  /// Map language codes for display
  static final Map<String, String> _languageNames = {
    'en': 'English',
    'it': 'Italiano',
    'es': 'Español',
    'fr': 'Français',
    'pt': 'Português',
    'pt-BR': 'Português (BR)',
    'de': 'Deutsch',
  };

  /// Get language name for display
  static String getLanguageName(String code) {
    return _languageNames[code] ?? code.toUpperCase();
  }

  /// Initialize service (no-op for online translation)
  Future<void> initialize() async {
    debugPrint('TranslationService: Using Google Translate API');
  }

  /// Check if a language model is downloaded (always true for online)
  Future<bool> isModelDownloaded(String languageCode) async {
    return true;
  }

  /// Download a language model (no-op for online translation)
  Future<bool> downloadModel(String languageCode) async {
    return true;
  }

  /// Delete a downloaded language model (no-op for online)
  Future<bool> deleteModel(String languageCode) async {
    return true;
  }

  /// Translate text from source language to target language

  /// Normalizes a language to something the translate endpoint accepts.
  ///
  /// Call sites pass a mixture: BCP-47 codes from the app locale ("en",
  /// "pt_BR") and display names from profile fields ("Portuguese (Brazil)"),
  /// because profiles store languages as names. That matters because the
  /// endpoint ACCEPTS an unrecognised `tl` and returns the text untranslated
  /// instead of failing:
  ///
  ///   tl=Portuguese  "Hello friend" -> "Hello friend"
  ///   tl=pt          "Hello friend" -> "Ola amigo"
  ///
  /// which is indistinguishable from a broken feature. Normalizing here means
  /// no caller can get it wrong.
  static String normalizeLanguage(String language) {
    final raw = language.trim();
    if (raw.isEmpty) return 'en';

    final key = raw.toLowerCase();

    // Brazilian Portuguese first: it must survive as pt-BR, not collapse to pt.
    if (key.contains('brazil') || key.contains('brasil') ||
        key.startsWith('pt_br') || key.startsWith('pt-br')) {
      return 'pt-BR';
    }

    // Already a code such as en, pt, en-GB, zh_CN.
    final code = RegExp(r'^([a-z]{2})([-_]([a-z]{2}))?$', caseSensitive: false)
        .firstMatch(raw);
    if (code != null) {
      final base = code.group(1)!.toLowerCase();
      final region = code.group(3);
      return region == null ? base : '$base-${region.toUpperCase()}';
    }

    const byName = <String, String>{
      'english': 'en', 'german': 'de', 'deutsch': 'de', 'spanish': 'es',
      'espanol': 'es', 'español': 'es', 'french': 'fr', 'francais': 'fr',
      'français': 'fr', 'italian': 'it', 'italiano': 'it',
      'portuguese': 'pt', 'português': 'pt', 'russian': 'ru',
      'chinese': 'zh', 'japanese': 'ja', 'korean': 'ko', 'arabic': 'ar',
      'hindi': 'hi', 'turkish': 'tr', 'dutch': 'nl', 'swedish': 'sv',
      'norwegian': 'no', 'danish': 'da', 'finnish': 'fi', 'polish': 'pl',
      'greek': 'el', 'hebrew': 'he', 'thai': 'th', 'vietnamese': 'vi',
    };
    return byName[key] ?? 'en';
  }

  /// Translates [text] and returns the translation, or [text] itself when it
  /// is already in the target language or translation failed.
  ///
  /// Kept for existing callers; new code should use [translateDetailed], which
  /// tells "failed" apart from "nothing to translate" and carries the detected
  /// language of THIS text.
  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
    bool requiresConsent = true,
  }) async {
    final r = await translateDetailed(
      text: text,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      requiresConsent: requiresConsent,
    );
    if (r.detectedLanguage != null) _lastDetectedLanguage = r.detectedLanguage;
    return r.text;
  }

  /// Translates [text] into [targetLanguage].
  ///
  /// Layers, cheapest first; only a miss in all of them goes to the network:
  ///  - skip: nothing to translate (emoji, numbers, URLs, < 2 letters);
  ///  - memory -> device (Hive) cache;
  ///  - [message] (chat): the translation the server already stored on the
  ///    message (`tr`), or its detected `lang` already is the target;
  ///  - the bundled [ChatPhrasebook] ("hi", "thanks", "how are you?");
  ///  - one request: for a [message], batched by id through
  ///    `translatePrivateText` (server: message -> cross-chat cache -> Cloud
  ///    Translation, and stores the result on the message); otherwise the
  ///    old single-text path.
  /// Never throws: a failure comes back as [TranslationResult.failed] with the
  /// original text, and is not cached.
  ///
  /// [requiresConsent]: true (default) for private / personal text such as
  /// chat messages. Without an accepted AI-processing notice nothing is sent
  /// and a [TranslationResult.consentRequired] result comes back. Only public
  /// content (events, attractions, experiences, public reviews) passes false.
  Future<TranslationResult> translateDetailed({
    required String text,
    String sourceLanguage = 'auto',
    required String targetLanguage,
    bool requiresConsent = true,
    ChatMessageRef? message,
  }) async {
    final sw = kDebugMode ? (Stopwatch()..start()) : null;
    if (text.trim().isEmpty || !needsTranslation(text)) {
      return _trace(
        TranslationResult(original: text, text: text, layer: 'skip'),
        sw,
      );
    }
    // Normalize before anything else, including the equality check and the
    // cache key, so "Portuguese" and "pt" are one entry rather than two.
    final target = normalizeLanguage(targetLanguage);
    final from = sourceLanguage == 'auto'
        ? 'auto'
        : normalizeLanguage(sourceLanguage);
    if (from != 'auto' && from == target) {
      return TranslationResult(
        original: text,
        text: text,
        detectedLanguage: from,
      );
    }

    final cacheKey = '${from}_${target}_$text';
    final hit = _translationCache[cacheKey];
    if (hit != null) {
      return _trace(
        TranslationResult(
          original: text,
          text: hit,
          detectedLanguage: _detectedCache[cacheKey],
          layer: 'memory',
        ),
        sw,
      );
    }

    return _inFlight[cacheKey] ??= () async {
      try {
        // Everything already on this device (or on the message) is shown
        // without any call and needs no consent: nothing leaves the device.
        final stored = await _readPersistent(from, target, text);
        if (stored != null) {
          _remember(cacheKey, stored);
          return _trace(stored, sw);
        }
        await _ensurePhrasebook();
        final local = _localLayers(text, target, message);
        if (local != null) {
          _remember(cacheKey, local);
          return _trace(local, sw);
        }
        if (requiresConsent && !await _consentOk()) {
          return TranslationResult.consentRequired(text);
        }
        final TranslationResult r;
        if (requiresConsent && await _useServer()) {
          r = (message != null && message.isValid)
              ? await _viaChatBatch(text, target, message)
              : await _throttled(() => _fetchViaServer(text, from, target));
        } else {
          r = await _throttled(() => _fetchWithRetry(text, from, target));
        }
        if (!r.failed) {
          _remember(cacheKey, r);
          unawaited(_writePersistent(from, target, r));
        }
        return _trace(r, sw);
      } finally {
        _inFlight.remove(cacheKey);
      }
    }();
  }

  /// The answer when it is available WITHOUT waiting (skip filter, memory,
  /// the translation stored on [message], its `lang`, the phrasebook once
  /// loaded), else null. Lets a chat bubble paint the translation in its
  /// first frame; [translateDetailed] remains the full lookup.
  TranslationResult? translateSync({
    required String text,
    required String targetLanguage,
    // Kept for parity with [translateDetailed]: local answers need no
    // consent (nothing leaves the device).
    bool requiresConsent = true,
    ChatMessageRef? message,
  }) {
    if (text.trim().isEmpty || !needsTranslation(text)) {
      return TranslationResult(original: text, text: text, layer: 'skip');
    }
    final target = normalizeLanguage(targetLanguage);
    final cacheKey = 'auto_${target}_$text';
    final hit = _translationCache[cacheKey];
    if (hit != null) {
      return TranslationResult(
        original: text,
        text: hit,
        detectedLanguage: _detectedCache[cacheKey],
        layer: 'memory',
      );
    }
    if (_phrasebook == null) unawaited(_ensurePhrasebook());
    return _localLayers(text, target, message);
  }

  /// Stored-on-message, same-language and phrasebook answers (no I/O).
  TranslationResult? _localLayers(
    String text,
    String target,
    ChatMessageRef? message,
  ) {
    if (message != null) {
      final stored = message.tr?[target];
      if (stored != null && message.trHash == messageTextHash(text)) {
        return TranslationResult(
          original: text,
          text: stored,
          detectedLanguage: message.lang,
          layer: 'message',
        );
      }
      final lang = message.lang;
      if (lang != null && lang.isNotEmpty && sameBaseLanguage(lang, target)) {
        return TranslationResult(
          original: text,
          text: text,
          detectedLanguage: lang,
          layer: 'lang',
        );
      }
    }
    final p = _phrasebook?.lookup(text, target);
    if (p != null) {
      return TranslationResult(
        original: text,
        text: p.same ? text : p.text,
        detectedLanguage: p.source,
        layer: 'phrasebook',
      );
    }
    return null;
  }

  TranslationResult _trace(TranslationResult r, Stopwatch? sw) {
    if (kDebugMode && sw != null) {
      debugPrint(
        'TranslationService: ${r.layer ?? (r.failed ? 'failed' : 'network')}'
        ' in ${sw.elapsedMicroseconds}us',
      );
    }
    return r;
  }

  // ---------------------------------------------------------------------------
  // Skip filter + phrasebook (local, free).
  // ---------------------------------------------------------------------------

  static final RegExp _urlPattern = RegExp(
    r'(https?://\S+|www\.\S+)',
    caseSensitive: false,
  );
  static final RegExp _letterPattern = RegExp(r'\p{L}', unicode: true);

  /// False for text there is nothing to translate in: emoji only, numbers /
  /// punctuation only, a bare URL, or fewer than 2 letters.
  static bool needsTranslation(String text) =>
      _letterPattern
          .allMatches(text.replaceAll(_urlPattern, ' '))
          .take(2)
          .length >=
      2;

  /// `trHash` the server stores next to a message's `tr` map: the first 16
  /// hex chars of sha256(content). A translation stored for older content
  /// (the message was edited) does not match and is ignored.
  static String messageTextHash(String text) =>
      sha256.convert(utf8.encode(text)).toString().substring(0, 16);

  static const String phrasebookAsset = 'assets/i18n/chat_phrasebook.json';
  static Future<String> _loadPhrasebookAsset() =>
      rootBundle.loadString(phrasebookAsset);

  final Future<String> Function() _phrasebookLoader;
  ChatPhrasebook? _phrasebook;
  Future<void>? _phrasebookLoading;

  Future<void> _ensurePhrasebook() {
    if (_phrasebook != null) return Future.value();
    return _phrasebookLoading ??= () async {
      try {
        _phrasebook = ChatPhrasebook.fromJson(await _phrasebookLoader());
      } catch (e) {
        debugPrint('TranslationService: phrasebook unavailable: $e');
        _phrasebook = ChatPhrasebook.empty();
      }
    }();
  }

  // ---------------------------------------------------------------------------
  // Chat messages by id: misses of one frame go to the server in ONE call.
  // ---------------------------------------------------------------------------

  /// How long misses are collected before one batched call (a screen of
  /// bubbles builds within a frame or two).
  final Duration _batchWindow;
  final Map<String, List<_ChatPending>> _chatQueue = {};
  Timer? _chatTimer;

  Future<TranslationResult> _viaChatBatch(
    String text,
    String target,
    ChatMessageRef ref,
  ) {
    final p = _ChatPending(ref, text);
    (_chatQueue[target] ??= []).add(p);
    _chatTimer ??= Timer(_batchWindow, _flushChatQueue);
    return p.completer.future;
  }

  void _flushChatQueue() {
    _chatTimer = null;
    final queued = Map.of(_chatQueue);
    _chatQueue.clear();
    queued.forEach((target, items) {
      for (var i = 0; i < items.length; i += 25) {
        unawaited(
          _sendChatBatch(
            target,
            items.sublist(i, i + 25 > items.length ? items.length : i + 25),
          ),
        );
      }
    });
  }

  Future<void> _sendChatBatch(String target, List<_ChatPending> items) async {
    List? list;
    try {
      final data = await (_serverCall ?? _defaultServerCall)({
        'target': target,
        'messages': [for (final p in items) p.ref.toPayload()],
      });
      list = data['translations'] as List?;
    } catch (e) {
      // Old server (no message refs yet), consent or quota: every item takes
      // the single-text path below, which also handles the consent resync.
      debugPrint('translatePrivateText (batch) failed: $e');
    }
    for (var k = 0; k < items.length; k++) {
      final p = items[k];
      final m = (list != null && k < list.length && list[k] is Map)
          ? Map<String, dynamic>.from(list[k] as Map)
          : null;
      final out = m?['text'];
      if (m != null && m['error'] == null && out is String) {
        p.completer.complete(
          TranslationResult(
            original: p.text,
            text: m['sameLanguage'] == true ? p.text : out,
            detectedLanguage: m['detectedLanguage'] as String?,
            layer: 'server-${m['layer'] ?? 'api'}',
          ),
        );
      } else {
        // Not stored yet (a just-sent message still in flight), too long,
        // or the call failed: translate the text itself, as before.
        p.completer.complete(
          _throttled(() => _fetchViaServer(p.text, 'auto', target)),
        );
      }
    }
  }

  void _remember(String cacheKey, TranslationResult r) {
    _translationCache[cacheKey] = r.text;
    if (r.detectedLanguage != null) {
      _detectedCache[cacheKey] = r.detectedLanguage!;
    }
    // Limit cache size
    if (_translationCache.length > 500) {
      final keysToRemove = _translationCache.keys.take(100).toList();
      for (final key in keysToRemove) {
        _translationCache.remove(key);
        _detectedCache.remove(key);
      }
    }
  }

  /// Runs [task] when fewer than [maxConcurrent] requests are in flight.
  Future<T> _throttled<T>(Future<T> Function() task) async {
    while (_active >= maxConcurrent) {
      final c = Completer<void>();
      _waiters.add(c);
      await c.future;
    }
    _active++;
    try {
      final wait = _coolDownUntil.difference(DateTime.now());
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      return await task();
    } finally {
      _active--;
      if (_waiters.isNotEmpty) _waiters.removeAt(0).complete();
    }
  }

  Future<TranslationResult> _fetchWithRetry(
      String text, String from, String target) async {
    final client = _client;
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      if (attempt > 0) await Future<void>.delayed(_backoff(attempt - 1));
      try {
        final http.Response response;
        final query = 'client=gtx&sl=${Uri.encodeComponent(from)}'
            '&tl=${Uri.encodeComponent(target)}&dt=t';
        if (text.length > _postThreshold) {
          final uri = Uri.parse('$freeEndpoint?$query');
          response = await (client != null
                  ? client.post(uri, body: {'q': text})
                  : http.post(uri, body: {'q': text}))
              .timeout(_requestTimeout);
        } else {
          final uri =
              Uri.parse('$freeEndpoint?$query&q=${Uri.encodeComponent(text)}');
          response = await (client != null ? client.get(uri) : http.get(uri))
              .timeout(_requestTimeout);
        }

        if (response.statusCode == 200) {
          final parsed = parseFreeResponse(text, target, response.body);
          if (parsed != null) return parsed;
          debugPrint('Translation: unreadable response');
          // A malformed 200 will not improve by retrying.
          break;
        }
        // 429 (rate limited) and 5xx are transient; anything else is not.
        final retryable =
            response.statusCode == 429 || response.statusCode >= 500;
        debugPrint('Translation failed: HTTP ${response.statusCode}');
        if (!retryable) break;
        if (response.statusCode == 429) {
          final pause = _backoff(attempt);
          final until = DateTime.now().add(pause);
          if (until.isAfter(_coolDownUntil)) _coolDownUntil = until;
        }
      } catch (e) {
        // Timeout, offline, DNS, TLS, CORS (web): transient.
        debugPrint('Translation error (attempt ${attempt + 1}): $e');
      }
    }
    return TranslationResult(original: text, text: text, failed: true);
  }

  /// Parses the free endpoint's JSON:
  /// `[[["<translated>","<original>",...], ...one entry per sentence...],
  ///   null, "<detected source>", ...]`.
  ///
  /// Sentences are concatenated in order. When the detected language already
  /// is the [target] (same base language), the original text is returned
  /// untranslated. Returns null for a body that is not in this shape.
  @visibleForTesting
  static TranslationResult? parseFreeResponse(
      String original, String target, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! List || decoded.isEmpty) return null;
      final detected = decoded.length > 2 && decoded[2] is String
          ? decoded[2] as String
          : null;
      final sentences = decoded[0];
      final buffer = StringBuffer();
      if (sentences is List) {
        for (final part in sentences) {
          if (part is List && part.isNotEmpty && part[0] is String) {
            buffer.write(part[0]);
          }
        }
      } else if (sentences != null) {
        return null;
      }
      final translated = buffer.toString();
      if (translated.trim().isEmpty ||
          (detected != null && sameBaseLanguage(detected, target))) {
        return TranslationResult(
            original: original, text: original, detectedLanguage: detected);
      }
      return TranslationResult(
          original: original, text: translated, detectedLanguage: detected);
    } catch (_) {
      return null;
    }
  }

  /// `pt` vs `pt-BR`, `zh-CN` vs `zh` → same base language.
  static bool sameBaseLanguage(String a, String b) {
    String base(String s) =>
        s.trim().toLowerCase().replaceAll('_', '-').split('-').first;
    final x = base(a), y = base(b);
    return x.isNotEmpty && x == y;
  }

  // ---------------------------------------------------------------------------
  // Device cache (Hive). Private chat translations stay on this device; keys
  // are hashes, so no message text is used as a key.
  // ---------------------------------------------------------------------------

  static const String _boxName = 'chat_translations_v1';
  static const int _maxPersistent = 20000;
  Box<String>? _box;
  bool _boxFailed = false;

  Future<Box<String>?> _openBox() async {
    if (!_persistent || _boxFailed) return null;
    if (_box != null) return _box;
    try {
      _box = Hive.isBoxOpen(_boxName)
          ? Hive.box<String>(_boxName)
          : await Hive.openBox<String>(_boxName);
      return _box;
    } catch (e) {
      _boxFailed = true; // Hive not initialised (tests) or storage blocked.
      return null;
    }
  }

  static String _persistentKey(String from, String target, String text) =>
      sha256.convert(utf8.encode('$from\u0000$target\u0000$text')).toString();

  Future<TranslationResult?> _readPersistent(
      String from, String target, String text) async {
    final box = await _openBox();
    if (box == null) return null;
    try {
      final raw = box.get(_persistentKey(from, target, text));
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final t = m['t'] as String?;
      if (t == null) return null;
      return TranslationResult(
          original: text, text: t, detectedLanguage: m['d'] as String?);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writePersistent(
      String from, String target, TranslationResult r) async {
    final box = await _openBox();
    if (box == null) return;
    try {
      if (box.length >= _maxPersistent) {
        await box.deleteAll(box.keys.take(_maxPersistent ~/ 5).toList());
      }
      await box.put(_persistentKey(from, target, r.original),
          jsonEncode({'t': r.text, 'd': r.detectedLanguage}));
    } catch (_) {/* best effort */}
  }

  /// Get list of downloaded models (all supported for online)
  List<String> getDownloadedModels() {
    return _languageNames.keys.toList();
  }

  /// Get list of supported languages
  static List<String> getSupportedLanguages() {
    return _languageNames.keys.toList();
  }

  /// Check if translation is available between two languages
  Future<bool> canTranslate(String sourceLanguage, String targetLanguage) async {
    return true;
  }

  /// Batch translate multiple texts
  Future<Map<String, String>> batchTranslate({
    required List<String> texts,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final results = <String, String>{};
    for (final text in texts) {
      results[text] = await translate(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
    }
    return results;
  }

  // ---------------------------------------------------------------------------
  // Shared, persistent translations (PUBLIC content only: events, attractions,
  // experiences). Each (language, text) is translated ONCE for everyone and
  // stored in `translations/{id}` by the `translateTexts` function; later
  // viewers just read it. Never use this for private chat text.
  // ---------------------------------------------------------------------------

  /// Same id the server computes: sha256("<target> <text>") hex.
  static String sharedTranslationId(String target, String text) =>
      sha256.convert(utf8.encode('$target $text')).toString();

  /// Translates [texts] (same order) into [targetLanguage] through the shared
  /// store: memory -> Firestore -> `translateTexts` for the misses -> the
  /// direct endpoint as a last resort. Returns the original for anything that
  /// could not be translated.
  Future<List<String>> translateShared(
    List<String> texts, {
    required String targetLanguage,
  }) async {
    final target = normalizeLanguage(targetLanguage);
    final out = List<String>.from(texts);
    final pending = <int>[];
    for (var i = 0; i < texts.length; i++) {
      final t = texts[i];
      if (t.trim().isEmpty) continue;
      final hit = _translationCache['shared_${target}_$t'];
      if (hit != null) {
        out[i] = hit;
      } else {
        pending.add(i);
      }
    }
    if (pending.isEmpty) return out;

    void remember(int i, String translated) {
      out[i] = translated;
      _translationCache['shared_${target}_${texts[i]}'] = translated;
    }

    // 1) Stored translations (one small doc each, read in parallel).
    final db = FirebaseFirestore.instance.collection('translations');
    final stillMissing = <int>[];
    await Future.wait(pending.map((i) async {
      try {
        final doc =
            await db.doc(sharedTranslationId(target, texts[i])).get();
        final v = doc.data()?['translated'] as String?;
        if (v != null && v.isNotEmpty) {
          remember(i, v);
          return;
        }
      } catch (_) {/* not readable / offline: fall through */}
      stillMissing.add(i);
    }));
    if (stillMissing.isEmpty) return out;

    // 2) Translate the misses once on the server, which stores them for
    //    everyone (chunks of 50).
    final unresolved = <int>[];
    // Answered '' by translateTexts (server rate-limited): a device
    // translation of these is contributed back to the shared store.
    final notStored = <int>{};
    for (var c = 0; c < stillMissing.length; c += 50) {
      final chunk = stillMissing.sublist(
          c, c + 50 > stillMissing.length ? stillMissing.length : c + 50);
      try {
        final res = await FirebaseFunctions.instance
            .httpsCallable('translateTexts',
                options: HttpsCallableOptions(
                    timeout: const Duration(seconds: 30)))
            .call<Map<String, dynamic>>({
          'texts': [for (final i in chunk) texts[i]],
          'target': target,
        });
        final list = (res.data['translations'] as List?) ?? const [];
        for (var k = 0; k < chunk.length; k++) {
          final v = k < list.length ? list[k] as String? : null;
          if (v != null && v.isNotEmpty) {
            remember(chunk[k], v);
          } else {
            unresolved.add(chunk[k]);
            notStored.add(chunk[k]);
          }
        }
      } catch (e) {
        debugPrint('translateTexts failed: $e');
        unresolved.addAll(chunk);
      }
    }

    // 3) Last resort: the direct endpoint on the device. Successful results
    //    for texts the server could not translate are offered back as votes
    //    (fire-and-forget; shared only once another user agrees).
    for (final i in unresolved) {
      final r = await translateDetailed(
          text: texts[i],
          sourceLanguage: 'auto',
          targetLanguage: target,
          requiresConsent: false); // public content only
      if (r.detectedLanguage != null) _lastDetectedLanguage = r.detectedLanguage;
      out[i] = r.text;
      if (r.isTranslated && notStored.contains(i)) {
        contributeShared(target, texts[i], r.text);
      }
    }
    return out;
  }

  /// Queues a device translation of PUBLIC content for the shared store.
  /// Only [translateShared] calls this; never pass private chat text.
  @visibleForTesting
  void contributeShared(String target, String text, String translation) =>
      _contributor.add(target, text, translation);

  /// Single-text convenience for [translateShared].
  Future<String> translateSharedOne(String text,
          {required String targetLanguage}) async =>
      (await translateShared([text], targetLanguage: targetLanguage)).first;

  /// Clear translation cache
  void clearCache() {
    _translationCache.clear();
    _detectedCache.clear();
  }

  /// Dispose (no-op for online)
  void dispose() {
    _contributor.dispose();
    _translationCache.clear();
    _detectedCache.clear();
  }
}
