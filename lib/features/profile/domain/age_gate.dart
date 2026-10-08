import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Neutral age gate, interim (audit H-21; COPPA, Brazil ECA Digital, store
/// rules). The date-of-birth picker allows any date up to today; an entered
/// age under [kMinimumAge] blocks registration. The block is remembered on
/// this device and recorded on the server (`declareAge`, `age_gate/{uid}`),
/// so entering another date afterwards does not get past it.
const int kMinimumAge = 18;

/// Whole years between [dob] and [now] (calendar, local date parts).
int ageOn(DateTime dob, DateTime now) {
  var age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age;
}

bool isUnderMinimumAge(DateTime dob, {DateTime? now}) =>
    ageOn(dob, now ?? DateTime.now()) < kMinimumAge;

/// 'YYYY-MM-DD' from the picked calendar date (no time zone shift).
String dobToIso(DateTime dob) =>
    '${dob.year.toString().padLeft(4, '0')}-'
    '${dob.month.toString().padLeft(2, '0')}-'
    '${dob.day.toString().padLeft(2, '0')}';

/// Remembers an under-age block on this device.
abstract class AgeGateLocalStore {
  Future<bool> isBlocked();
  Future<void> block();
}

class SharedPrefsAgeGateStore implements AgeGateLocalStore {
  static const _key = 'age_gate_blocked_v1';

  @override
  Future<bool> isBlocked() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  @override
  Future<void> block() async =>
      (await SharedPreferences.getInstance()).setBool(_key, true);
}

typedef DeclareAgeCall = Future<Map<String, dynamic>> Function(String dobIso);

Future<Map<String, dynamic>> _declareOnServer(String dobIso) async {
  final res = await FirebaseFunctions.instance
      .httpsCallable('declareAge',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 15)))
      .call<Map<String, dynamic>>({'dob': dobIso});
  return Map<String, dynamic>.from(res.data);
}

class AgeGateService {
  AgeGateService({DeclareAgeCall? declare, AgeGateLocalStore? store, DateTime Function()? clock})
      : _declare = declare ?? _declareOnServer,
        _store = store ?? SharedPrefsAgeGateStore(),
        _clock = clock ?? DateTime.now;

  final DeclareAgeCall _declare;
  final AgeGateLocalStore _store;
  final DateTime Function() _clock;

  /// True when registration may continue with [dob].
  ///
  /// Under 18 is blocked even when the server cannot be reached. An adult
  /// date is blocked when this device or the server (account / email) was
  /// blocked before. If the server cannot be reached for an adult date the
  /// step continues: the profile trigger re-checks on the server.
  Future<bool> mayContinue(DateTime dob) async {
    if (await _store.isBlocked()) return false;
    final under = isUnderMinimumAge(dob, now: _clock());
    try {
      final r = await _declare(dobToIso(dob));
      if (r['allowed'] == false) {
        await _store.block();
        return false;
      }
    } catch (e) {
      debugPrint('AgeGateService: declareAge failed: $e');
    }
    if (under) {
      await _store.block();
      return false;
    }
    return true;
  }
}
