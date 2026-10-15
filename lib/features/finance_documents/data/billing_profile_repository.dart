import 'package:cloud_functions/cloud_functions.dart';

import '../domain/billing_profile.dart';

/// A save refused by the server's validation, on one field.
class BillingValidationException implements Exception {
  const BillingValidationException(this.error);

  final BillingFieldError error;

  @override
  String toString() => 'BillingValidationException(${error.field}: ${error.code.name})';
}

/// Client of `getMyBillingProfile` / `saveMyBillingProfile`. The profile is
/// server-only in Firestore (tax ids never in public profile docs), so these
/// callables are the only read / write path.
class BillingProfileRepository {
  BillingProfileRepository({FirebaseFunctions? functions}) : _functions = functions;

  final FirebaseFunctions? _functions;

  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instance;

  Future<BillingStatus> get() async {
    final res = await _fn.httpsCallable('getMyBillingProfile').call<Map<String, dynamic>>(<String, dynamic>{});
    return BillingStatus.fromMap(Map<String, dynamic>.from(res.data));
  }

  /// Throws [BillingValidationException] when a field is rejected.
  Future<BillingStatus> save(BillingDraft draft) async {
    try {
      final res = await _fn.httpsCallable('saveMyBillingProfile').call<Map<String, dynamic>>(draft.toMap());
      return BillingStatus.fromMap(Map<String, dynamic>.from(res.data));
    } on FirebaseFunctionsException catch (e) {
      final field = e.code == 'invalid-argument' ? BillingFieldError.fromDetails(e.details) : null;
      if (field != null) throw BillingValidationException(field);
      rethrow;
    }
  }
}
