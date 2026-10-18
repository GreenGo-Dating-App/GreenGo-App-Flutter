import 'package:cloud_functions/cloud_functions.dart';

/// Where the optional ID details were entered.
enum IdentitySource { registration, age, business }

/// Document types accepted by `submitIdentityDetails` (server DOC_TYPES).
const List<String> kIdentityDocTypes = [
  'passport',
  'id_card',
  'driving_licence',
  'residence_permit',
  'other',
];

/// The six details a user types next to an ID-document photo.
class IdentityDetails {
  const IdentityDetails({
    required this.firstName,
    required this.surname,
    required this.dateOfBirth,
    required this.docType,
    required this.issuingCountry,
    required this.docNumber,
  });

  factory IdentityDetails.fromMap(Map<dynamic, dynamic> m) => IdentityDetails(
        firstName: '${m['firstName'] ?? ''}',
        surname: '${m['surname'] ?? ''}',
        dateOfBirth: DateTime.tryParse('${m['dateOfBirth'] ?? ''}') ??
            DateTime(1990),
        docType: '${m['docType'] ?? 'id_card'}',
        issuingCountry: '${m['issuingCountry'] ?? ''}',
        docNumber: '${m['docNumber'] ?? ''}',
      );

  final String firstName;
  final String surname;
  final DateTime dateOfBirth;
  final String docType;
  final String issuingCountry;
  final String docNumber;

  String get dateOfBirthIso =>
      '${dateOfBirth.year.toString().padLeft(4, '0')}-'
      '${dateOfBirth.month.toString().padLeft(2, '0')}-'
      '${dateOfBirth.day.toString().padLeft(2, '0')}';

  Map<String, String> toMap() => {
        'firstName': firstName.trim(),
        'surname': surname.trim(),
        'dateOfBirth': dateOfBirthIso,
        'docType': docType,
        'issuingCountry': issuingCountry.toUpperCase(),
        'docNumber': docNumber.trim().toUpperCase(),
      };
}

/// Client of the identity-record callables (functions/src/safety/
/// identityRecords.ts). The details are stored encrypted, server-only; the
/// app never reads them back (only reviewers do, through the admin callables).
class IdentityDetailsService {
  IdentityDetailsService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<void> submit(IdentitySource source, IdentityDetails details) async {
    await _functions.httpsCallable('submitIdentityDetails').call<dynamic>({
      'source': source.name,
      'fields': details.toMap(),
    });
  }

  /// Reviewer: the details the user typed (or the confirmed ones), or null.
  Future<IdentityDetails?> getForReview(String uid) async {
    final r = await _functions
        .httpsCallable('adminGetIdentityDetailsForReview')
        .call<dynamic>({'uid': uid});
    final data = r.data;
    if (data is! Map || data['found'] != true || data['fields'] is! Map) {
      return null;
    }
    return IdentityDetails.fromMap(data['fields'] as Map);
  }

  /// Reviewer decision. [fields] = the corrected details (approve only).
  Future<void> confirm(
    String uid, {
    required bool approve,
    IdentityDetails? fields,
  }) async {
    await _functions.httpsCallable('adminConfirmIdentityDetails').call<dynamic>({
      'uid': uid,
      'decision': approve ? 'approve' : 'reject',
      if (approve && fields != null) 'fields': fields.toMap(),
    });
  }
}
