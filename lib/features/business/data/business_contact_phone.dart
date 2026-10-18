import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/phone_verification_countries.dart' show toE164;
import '../../profile/data/private_profile.dart' show kPrivateProfilesCollection;

/// Optional business contact number (owner rule 2026-10-17).
///
/// * Any country, landlines allowed, NOT SMS-verified - it is a contact
///   number, never the account's verified phone (which is never shown).
/// * PRIVATE by default: the number lives in
///   `profiles_private/{uid}.businessContactPhone` (owner + admins only).
/// * "Show on my storefront" (`profiles/{uid}.showBusinessPhone`) publishes a
///   mirror `profiles/{uid}.businessContactPhone`, which the storefront shows
///   with tap-to-call / WhatsApp. Switching it off removes the mirror.
///
/// Rules (firestore.additive.rules + firestore.rules, businessContactPhoneOk /
/// privateProfileShapeOk) enforce the E.164 format and that the public mirror
/// exists only while showBusinessPhone == true.
const String kBusinessContactPhoneField = 'businessContactPhone';
const String kShowBusinessPhoneField = 'showBusinessPhone';

final RegExp _e164 = RegExp(r'^\+[1-9][0-9]{6,14}$');

/// True when [phone] is a storable E.164 contact number.
bool isValidBusinessContactPhone(String? phone) =>
    phone != null && phone.length <= 16 && _e164.hasMatch(phone);

/// E.164 from the picker's dial code and what the user typed; null when the
/// result is not a valid number. An empty input means "no number" ('').
String? normalizeBusinessContactPhone(String dialCode, String typed) {
  if (typed.trim().isEmpty) return '';
  final e164 = toE164(dialCode, typed);
  return isValidBusinessContactPhone(e164) ? e164 : null;
}

/// The two merge-writes for saving [phone] (null/empty = remove) with the
/// storefront switch [show]. The public mirror is written only when shown.
({Map<String, dynamic> public, Map<String, dynamic> private})
    businessContactPhoneWrites({required String? phone, required bool show}) {
  final value = (phone == null || phone.isEmpty) ? null : phone;
  if (value != null && !isValidBusinessContactPhone(value)) {
    throw ArgumentError.value(phone, 'phone', 'not E.164');
  }
  final visible = show && value != null;
  return (
    public: <String, dynamic>{
      kShowBusinessPhoneField: visible,
      kBusinessContactPhoneField: visible ? value : null,
    },
    private: <String, dynamic>{kBusinessContactPhoneField: value},
  );
}

/// The number a storefront may show, from a raw public `profiles/{uid}` map.
String? publicBusinessContactPhone(Map<String, dynamic>? profile) {
  if (profile == null || profile[kShowBusinessPhoneField] != true) return null;
  final v = profile[kBusinessContactPhoneField];
  return v is String && isValidBusinessContactPhone(v) ? v : null;
}

class BusinessContactPhoneRepository {
  BusinessContactPhoneRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  /// The owner's saved number and switch state.
  Future<({String? phone, bool show})> load(String uid) async {
    final results = await Future.wait([
      _db.collection(kPrivateProfilesCollection).doc(uid).get(),
      _db.collection('profiles').doc(uid).get(),
    ]);
    final p = results[0].data()?[kBusinessContactPhoneField];
    return (
      phone: p is String && p.isNotEmpty ? p : null,
      show: results[1].data()?[kShowBusinessPhoneField] == true,
    );
  }

  /// Saves both docs in one batch.
  Future<void> save(String uid, {required String? phone, required bool show}) {
    final w = businessContactPhoneWrites(phone: phone, show: show);
    final batch = _db.batch()
      ..set(_db.collection(kPrivateProfilesCollection).doc(uid), w.private,
          SetOptions(merge: true))
      ..set(_db.collection('profiles').doc(uid), w.public,
          SetOptions(merge: true));
    return batch.commit();
  }

  /// The public number of [businessId] for its storefront (null = hidden).
  Future<String?> publicPhone(String businessId) async {
    final snap = await _db.collection('profiles').doc(businessId).get();
    return publicBusinessContactPhone(snap.data());
  }
}
