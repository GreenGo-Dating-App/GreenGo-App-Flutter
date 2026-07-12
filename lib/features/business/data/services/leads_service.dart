import 'package:cloud_firestore/cloud_firestore.dart';

/// Business Leads service.
///
/// Logs lightweight "lead" events a business can later see in their CRM/leads
/// list. Each lead is a per-user document under the business:
///   `business_leads/{businessId}/leads/{uid}`
///
/// Keyed by the acting user's uid so a user counts as ONE lead per business
/// (re-contacting merges onto the same doc rather than exploding the
/// collection). Optional per-type history could later be added as a
/// subcollection if needed; the top doc keeps the most-recent interaction for
/// a cheap, index-free read of "my leads".
///
/// Scales to millions: writes are single-doc `set(merge)` — no fan-out, no
/// composite index. The business reads its own `leads` subcollection ordered by
/// `updatedAt` (single-field index) with pagination.
class LeadsService {
  LeadsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _leadDoc(
    String businessId,
    String uid,
  ) =>
      _firestore
          .collection('business_leads')
          .doc(businessId)
          .collection('leads')
          .doc(uid);

  /// Log a "contact" lead — the user opened a chat with the business.
  Future<void> logContactLead({
    required String businessId,
    required String uid,
  }) async {
    if (businessId == uid) return; // ignore self
    await _leadDoc(businessId, uid).set({
      'type': 'contact',
      'lastType': 'contact',
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Log a "saved_event" lead — the user saved/RSVP'd to one of the business's
  /// events. Exposed for the events feature to call later.
  ///
  /// TODO(lead-wiring): call this from the event save/RSVP flow when the
  /// event's organizer is a business account, passing the organizer's uid as
  /// [businessId]. Do NOT edit the event screens from the business feature —
  /// this method is the integration point they will import.
  Future<void> logSavedEventLead({
    required String businessId,
    required String uid,
    required String eventId,
  }) async {
    if (businessId == uid) return; // ignore self
    await _leadDoc(businessId, uid).set({
      'type': 'saved_event',
      'lastType': 'saved_event',
      'uid': uid,
      'eventId': eventId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
