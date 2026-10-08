import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';

import '../../domain/availability_rules.dart';

/// A bookable time from getExperienceAvailability (server-computed).
class AvailableTime extends Equatable {
  const AvailableTime({
    required this.key,
    required this.start,
    required this.end,
    required this.date,
    required this.time,
    required this.remaining,
    required this.unitAmount,
    this.currency,
    this.priceRule = 'base',
  });

  final String key;

  /// UTC instants (shown in the buyer's local time when it differs).
  final DateTime start;
  final DateTime end;

  /// Host-local date / time.
  final String date;
  final String time;

  /// Seats (per person) or groups (per group) left.
  final int remaining;

  /// Price of one unit (person or group) in minor units on that date.
  final int unitAmount;
  final String? currency;

  /// 'base' | 'weekend' | 'day'.
  final String priceRule;

  factory AvailableTime.fromMap(Map<String, dynamic> m) => AvailableTime(
        key: m['key'] as String,
        start: DateTime.parse(m['start'] as String).toUtc(),
        end: DateTime.parse(m['end'] as String).toUtc(),
        date: m['date'] as String,
        time: m['time'] as String,
        remaining: (m['remaining'] as num?)?.toInt() ?? 0,
        unitAmount: (m['unitAmount'] as num?)?.toInt() ?? 0,
        currency: m['currency'] as String?,
        priceRule: m['priceRule'] as String? ?? 'base',
      );

  @override
  List<Object?> get props => [key, remaining, unitAmount];
}

class AvailabilityPage {
  const AvailabilityPage({required this.timezone, required this.times, this.perGroup = false});
  final String? timezone;
  final List<AvailableTime> times;
  final bool perGroup;
}

/// Result of a schedule save: when booked times would disappear the server
/// asks for confirmation first (affected = number of booked times).
class AvailabilitySaveResult {
  const AvailabilitySaveResult({required this.needsConfirm, required this.affected, this.cancelled = 0});
  final bool needsConfirm;
  final int affected;
  final int cancelled;
}

/// The host's schedule as stored on the experience doc.
class HostSchedule {
  const HostSchedule({
    required this.rules,
    required this.overrides,
    this.weekendPrice,
    this.weekendDays = const [6, 7],
    this.basePrice,
    this.currency,
    this.perGroup = false,
  });

  /// per_group listings store group prices (and day / weekend overrides) in
  /// MINOR units; per_person in major units.
  final bool perGroup;
  final AvailabilityRules? rules;
  final AvailabilityOverrides overrides;
  final double? weekendPrice;
  final List<int> weekendDays;
  final double? basePrice;
  final String? currency;
}

class ExperienceAvailabilityService {
  ExperienceAvailabilityService({FirebaseFunctions? functions, FirebaseFirestore? firestore})
      : _fn = functions,
        _db = firestore;

  final FirebaseFunctions? _fn;
  final FirebaseFirestore? _db;
  FirebaseFunctions get _functions => _fn ?? FirebaseFunctions.instance;
  FirebaseFirestore get _firestore => _db ?? FirebaseFirestore.instance;

  Future<HostSchedule> load(String experienceId) async {
    final d = (await _firestore.collection('user_experiences').doc(experienceId).get()).data() ?? {};
    final r = d['availabilityRules'];
    final o = d['availabilityOverrides'];
    final group = d['pricingMode'] == 'per_group';
    return HostSchedule(
      rules: r is Map ? AvailabilityRules.fromMap(Map<String, dynamic>.from(r)) : null,
      overrides: AvailabilityOverrides.fromMap(o is Map ? Map<String, dynamic>.from(o) : null),
      weekendPrice: (d['weekendPrice'] as num?)?.toDouble(),
      weekendDays: (d['weekendDays'] as List?)?.whereType<num>().map((e) => e.toInt()).toList() ?? const [6, 7],
      basePrice: group
          ? ((d['groupPrice'] as num?)?.toDouble() == null ? null : (d['groupPrice'] as num).toDouble() / 100)
          : (d['price'] as num?)?.toDouble(),
      currency: d['currency'] as String?,
      perGroup: group,
    );
  }

  Future<AvailabilitySaveResult> save(String experienceId, AvailabilityRules rules,
      AvailabilityOverrides overrides, {bool confirm = false}) async {
    final r = await _functions.httpsCallable('updateExperienceAvailability').call<Object?>({
      'experienceId': experienceId,
      'rules': rules.toMap(),
      'overrides': overrides.toMap(),
      if (confirm) 'confirm': true,
    });
    final m = r.data is Map ? Map<String, dynamic>.from(r.data as Map) : const <String, dynamic>{};
    return AvailabilitySaveResult(
      needsConfirm: m['needsConfirm'] == true,
      affected: (m['affected'] as num?)?.toInt() ?? 0,
      cancelled: (m['cancelledBookings'] as num?)?.toInt() ?? 0,
    );
  }

  /// Bookable times between [from] and [to] (<= 62 days per call).
  Future<AvailabilityPage> times(String experienceId, DateTime from, DateTime to) async {
    final r = await _functions.httpsCallable('getExperienceAvailability').call<Object?>({
      'experienceId': experienceId,
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
    });
    final m = r.data is Map ? Map<String, dynamic>.from(r.data as Map) : const <String, dynamic>{};
    final list = (m['slots'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => AvailableTime.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return AvailabilityPage(timezone: m['timezone'] as String?, times: list, perGroup: m['pricingMode'] == 'per_group');
  }
}
