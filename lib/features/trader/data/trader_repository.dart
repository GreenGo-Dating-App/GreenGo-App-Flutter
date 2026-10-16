import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../finance_documents/data/billing_profile_repository.dart';
import '../../finance_documents/domain/billing_profile.dart';
import '../domain/trader_declaration.dart';

/// Client of getMyTraderDeclaration / saveMyTraderDeclaration (the full
/// declaration is server-only) and reader of the public part
/// (`trader_public/{uid}`, one document read per seller, cached per session).
class TraderRepository {
  TraderRepository({FirebaseFunctions? functions, FirebaseFirestore? firestore})
      : _functions = functions,
        _firestore = firestore;

  final FirebaseFunctions? _functions;
  final FirebaseFirestore? _firestore;

  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Public info per seller uid, for this app session (null = not declared).
  static final Map<String, Future<TraderPublicInfo?>> _publicCache = {};

  static void clearCache() => _publicCache.clear();

  Future<TraderStatus> get() async {
    final res = await _fn
        .httpsCallable('getMyTraderDeclaration')
        .call<Map<String, dynamic>>(<String, dynamic>{});
    return TraderStatus.fromMap(Map<String, dynamic>.from(res.data));
  }

  /// Throws [BillingValidationException] when a field is rejected.
  Future<TraderDeclaration?> save(TraderDraft draft) async {
    try {
      final res = await _fn
          .httpsCallable('saveMyTraderDeclaration')
          .call<Map<String, dynamic>>(draft.toMap());
      _publicCache.clear();
      return TraderDeclaration.fromMap(
          Map<String, dynamic>.from(res.data)['declaration']);
    } on FirebaseFunctionsException catch (e) {
      final field = e.code == 'invalid-argument'
          ? BillingFieldError.fromDetails(e.details)
          : null;
      if (field != null) throw BillingValidationException(field);
      rethrow;
    }
  }

  /// The seller's public trader info, or null (not declared / unreadable).
  Future<TraderPublicInfo?> publicInfo(String sellerUid) {
    if (sellerUid.isEmpty) return Future.value(null);
    return _publicCache.putIfAbsent(sellerUid, () async {
      try {
        final snap = await _db.collection('trader_public').doc(sellerUid).get();
        return TraderPublicInfo.fromMap(snap.data());
      } catch (_) {
        _publicCache.remove(sellerUid);
        return null;
      }
    });
  }
}
