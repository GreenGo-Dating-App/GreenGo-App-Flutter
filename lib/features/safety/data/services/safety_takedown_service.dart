import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Result of an intimate-image (NCII) removal request.
enum NciiSubmitOutcome { submitted, rateLimited, invalid, failed }

@immutable
class NciiSubmitResult {
  const NciiSubmitResult(this.outcome, [this.reference]);
  final NciiSubmitOutcome outcome;

  /// Short case reference shown to the requester (first 8 chars of the case id).
  final String? reference;
}

/// Calls a callable and returns its data. Abstracted so widget tests need no Firebase.
typedef SafetyCallable = Future<Map<String, dynamic>> Function(String name, Map<String, dynamic> data);

Future<Map<String, dynamic>> _callFunction(String name, Map<String, dynamic> data) async {
  final r = await FirebaseFunctions.instance
      .httpsCallable(name, options: HttpsCallableOptions(timeout: const Duration(seconds: 90)))
      .call<dynamic>(data);
  final d = r.data;
  return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
}

/// Content the request is about, pre-filled from a report entry point. The
/// server understands `profile:<uid>`, Firebase Storage URLs and chat message
/// paths (`conversations/<id>/messages/<id>`, groups, communities, events).
String nciiProfileLocation(String userId) => 'profile:$userId';

/// Splits the free-text locations field: one per line, trimmed, max 10.
List<String> parseNciiLocations(String text, {List<String> prefilled = const []}) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in [...prefilled, ...text.split(RegExp(r'[\r\n]+'))]) {
    final v = raw.trim();
    if (v.length >= 3 && seen.add(v)) out.add(v);
    if (out.length == 10) break;
  }
  return out;
}

/// Intimate-image removal requests (TAKE IT DOWN Act / Brazil Decreto
/// 12.976/2026). The server hides the content at once, alerts the on-call
/// moderator and blocks re-uploads by image hash (functions:
/// safety/takedowns). Non-users use the public form on greengochat.com.
class SafetyTakedownService {
  SafetyTakedownService({SafetyCallable? call}) : _call = call ?? _callFunction;

  final SafetyCallable _call;

  Future<NciiSubmitResult> submitNcii({
    required String fullName,
    required String email,
    required String phone,
    required bool depictedPerson,
    required String representedPerson,
    required List<String> contentLocations,
    required String description,
    required String signature,
    required String locale,
  }) async {
    try {
      final r = await _call('submitSafetyRequest', {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': depictedPerson ? 'depicted_person' : 'authorized_representative',
        'representedPerson': depictedPerson ? '' : representedPerson,
        'contentLocations': contentLocations,
        'description': description,
        'statements': {'depictedOrAuthorized': true, 'goodFaith': true, 'accurate': true},
        'signature': signature,
        'locale': locale,
      });
      return NciiSubmitResult(NciiSubmitOutcome.submitted, r['reference'] as String?);
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'resource-exhausted':
          return const NciiSubmitResult(NciiSubmitOutcome.rateLimited);
        case 'invalid-argument':
          return const NciiSubmitResult(NciiSubmitOutcome.invalid);
        default:
          return const NciiSubmitResult(NciiSubmitOutcome.failed);
      }
    } catch (_) {
      return const NciiSubmitResult(NciiSubmitOutcome.failed);
    }
  }
}
