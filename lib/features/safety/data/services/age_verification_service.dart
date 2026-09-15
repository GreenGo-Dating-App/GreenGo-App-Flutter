import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
// XFile comes from image_picker's own export rather than depending on
// `cross_file` directly, which is only a transitive dependency here.
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:flutter/foundation.dart';

/// Where a user stands on age assurance.
///
/// Mirrors `AgeVerificationStatus` in `functions/src/safety/ageAssurance.ts`.
/// Kept as a plain enum with a string mapping rather than generated code so
/// an unknown value from an older/newer server degrades to [none] instead of
/// throwing in front of the user.
enum AgeVerificationStatus {
  /// No birth date on file yet.
  none,

  /// The user stated a birth date. Enough to use the app.
  declared,

  /// A document was submitted and is waiting on a decision.
  pending,

  /// Age confirmed. Required to publish in Communities.
  verified,

  /// The document was unreadable or contradicted the declaration.
  rejected;

  static AgeVerificationStatus parse(String? value) {
    switch (value) {
      case 'declared':
        return AgeVerificationStatus.declared;
      case 'pending':
        return AgeVerificationStatus.pending;
      case 'verified':
        return AgeVerificationStatus.verified;
      case 'rejected':
        return AgeVerificationStatus.rejected;
      default:
        return AgeVerificationStatus.none;
    }
  }
}

/// Snapshot of the current user's age-assurance state.
@immutable
class AgeVerificationState {
  const AgeVerificationState({
    required this.status,
    required this.documentRequired,
    required this.canPublishToCommunities,
    this.rejectionReason,
  });

  /// Safe default used when the server cannot be reached: the user keeps full
  /// use of the app, and only the publishing gate (enforced server-side by
  /// Firestore rules anyway) stays closed.
  const AgeVerificationState.unknown()
      : status = AgeVerificationStatus.none,
        documentRequired = false,
        canPublishToCommunities = false,
        rejectionReason = null;

  final AgeVerificationStatus status;

  /// True when this account MUST provide a document — currently phone-only
  /// sign-ins, which carry no identity signal behind the declared birth date.
  final bool documentRequired;

  final bool canPublishToCommunities;
  final String? rejectionReason;
}

/// Client for the age-assurance Cloud Functions.
///
/// The document image is uploaded to a write-only Storage prefix and read by
/// `submitAgeDocument`, which deletes it as soon as OCR has run. Nothing here
/// keeps a local copy, and the upload path is scoped to the signed-in user so
/// Storage rules can enforce ownership.
class AgeVerificationService {
  AgeVerificationService({
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  /// Reads the current state. Never throws — a network blip must not block the
  /// UI, and the authoritative gate lives in Firestore rules regardless.
  Future<AgeVerificationState> loadState() async {
    try {
      final result =
          await _functions.httpsCallable('getAgeVerificationState').call<dynamic>();
      final data = Map<String, dynamic>.from(result.data as Map);
      return AgeVerificationState(
        status: AgeVerificationStatus.parse(data['status'] as String?),
        documentRequired: data['documentRequired'] as bool? ?? false,
        canPublishToCommunities:
            data['canPublishToCommunities'] as bool? ?? false,
        rejectionReason: data['rejectionReason'] as String?,
      );
    } catch (e) {
      debugPrint('[AgeVerification] loadState failed: $e');
      return const AgeVerificationState.unknown();
    }
  }

  /// Uploads [documentFile] and asks the server to decide.
  ///
  /// Returns the resulting status. The image is deleted server-side during the
  /// same call, so it exists in Storage for seconds at most.
  /// [documentFile] is an [XFile] from `image_picker`, not a `dart:io` File:
  /// the same flow ships on Flutter web, where `dart:io` does not exist.
  Future<AgeVerificationStatus> submitDocument({
    required XFile documentFile,
    String documentType = 'id_card',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return AgeVerificationStatus.none;

    final path =
        'age_verification/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      // putData rather than putFile so this works on web too.
      final bytes = await documentFile.readAsBytes();
      await _storage.ref(path).putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );

      final result =
          await _functions.httpsCallable('submitAgeDocument').call<dynamic>({
        'documentPath': path,
        'documentType': documentType,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return AgeVerificationStatus.parse(data['status'] as String?);
    } catch (e) {
      debugPrint('[AgeVerification] submitDocument failed: $e');
      // Best-effort cleanup if the upload landed but the call did not, so a
      // document never lingers because of a dropped connection.
      try {
        await _storage.ref(path).delete();
      } catch (_) {}
      return AgeVerificationStatus.rejected;
    }
  }
}
