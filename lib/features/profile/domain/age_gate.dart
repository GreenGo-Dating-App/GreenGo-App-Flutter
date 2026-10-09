import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Neutral age gate, interim (audit H-21; COPPA, Brazil ECA Digital, store
/// rules). The date-of-birth picker allows any date up to today. The age is
/// computed ONLY from the date currently selected ([isUnderMinimumAge]); an
/// under-18 pick is refused inline and can be corrected. Anti-circumvention
/// lives on the server: once an account has a recorded under-18 date of birth
/// (`age_gate/{uid}`, `age_gate_emails/{sha256(email)}`, written by the
/// profile trigger or by older app versions through `declareAge`), every
/// later date is refused for that account / email until an admin lifts it.
const int kMinimumAge = 18;

/// Whole years between [dob] and [now], from calendar date parts only (the
/// time of day and time zone are ignored, so a date picked at 23:59 or in
/// another zone gives the same answer). A 29 February birthday turns a year
/// older on 1 March in non-leap years.
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

/// Result of [AgeGateService.check].
enum AgeGateResult {
  /// Adult date, and the server has no earlier under-18 record.
  allowed,

  /// The date currently selected is under [kMinimumAge]. Computed from that
  /// date ONLY: nothing is stored and nothing is sent, so picking a different
  /// (correct) date right after is accepted.
  underAge,

  /// The server already blocked this account / email (an under-18 date of
  /// birth was submitted for it before). Anti-circumvention: stays blocked
  /// whatever date is entered now; an admin has to lift it.
  previouslyBlocked,
}

/// Device flag written by older app versions (<= 4.6.0+194). It made a single
/// under-18 Continue block every later date on this device, even a corrected
/// one. No longer read; removed on the next check.
const String kLegacyAgeGateBlockedPrefKey = 'age_gate_blocked_v1';

typedef DeclareAgeCall = Future<Map<String, dynamic>> Function(String dobIso);

Future<Map<String, dynamic>> _declareOnServer(String dobIso) async {
  final res = await FirebaseFunctions.instance
      .httpsCallable(
        'declareAge',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      )
      // The local calendar date, so the server counts an 18th birthday from
      // local midnight (it accepts it only within real time-zone range).
      .call<Map<String, dynamic>>({
        'dob': dobIso,
        'today': dobToIso(DateTime.now()),
      });
  return Map<String, dynamic>.from(res.data);
}

Future<void> _clearLegacyDeviceFlag() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey(kLegacyAgeGateBlockedPrefKey)) {
    await prefs.remove(kLegacyAgeGateBlockedPrefKey);
  }
}

class AgeGateService {
  AgeGateService({
    DeclareAgeCall? declare,
    DateTime Function()? clock,
    Future<void> Function()? clearLegacyFlag,
  }) : _declare = declare ?? _declareOnServer,
       _clock = clock ?? DateTime.now,
       _clearLegacyFlag = clearLegacyFlag ?? _clearLegacyDeviceFlag;

  final DeclareAgeCall _declare;
  final DateTime Function() _clock;
  final Future<void> Function() _clearLegacyFlag;

  /// Validates the date the user has selected NOW.
  ///
  /// Under 18 -> [AgeGateResult.underAge] without touching the server or the
  /// device, so a wrong pick can be corrected. An adult date is declared to
  /// the server (`declareAge`), which refuses it only when this account /
  /// email was already recorded as under 18. If the server cannot be reached
  /// for an adult date the step continues: the profile trigger
  /// (`applyProfileAgeGate`) re-checks on the server.
  Future<AgeGateResult> check(DateTime dob) async {
    try {
      await _clearLegacyFlag();
    } catch (_) {}
    if (isUnderMinimumAge(dob, now: _clock())) return AgeGateResult.underAge;
    try {
      final r = await _declare(dobToIso(dob));
      if (r['allowed'] == false) return AgeGateResult.previouslyBlocked;
    } catch (e) {
      debugPrint('AgeGateService: declareAge failed: $e');
    }
    return AgeGateResult.allowed;
  }
}
