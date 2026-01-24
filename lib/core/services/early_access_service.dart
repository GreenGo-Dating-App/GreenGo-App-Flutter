import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

/// Service for managing early access email list
/// Users in this list get access on March 1, 2026
/// All other users get access on March 16, 2026
class EarlyAccessService {
  final FirebaseFirestore _firestore;
  final auth.FirebaseAuth _auth;

  // Early access list collection name
  static const String _collectionName = 'early_access_list';
  static const String _configDocName = 'config';

  // Access dates
  static final DateTime earlyAccessDate = DateTime(2026, 3, 1);  // March 1, 2026
  static final DateTime generalAccessDate = DateTime(2026, 3, 16); // March 16, 2026

  EarlyAccessService({
    FirebaseFirestore? firestore,
    auth.FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? auth.FirebaseAuth.instance;

  /// Check if email is in early access list
  Future<bool> isEmailInEarlyAccessList(String email) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();
      final doc = await _firestore
          .collection(_collectionName)
          .doc(normalizedEmail.replaceAll('.', '_dot_').replaceAll('@', '_at_'))
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get access date for current user
  Future<DateTime> getAccessDateForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      return generalAccessDate;
    }

    final isEarlyAccess = await isEmailInEarlyAccessList(user.email!);
    return isEarlyAccess ? earlyAccessDate : generalAccessDate;
  }

  /// Get access date for a specific email
  Future<DateTime> getAccessDateForEmail(String email) async {
    final isEarlyAccess = await isEmailInEarlyAccessList(email);
    return isEarlyAccess ? earlyAccessDate : generalAccessDate;
  }

  /// Check if current user has early access
  Future<bool> currentUserHasEarlyAccess() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      return false;
    }
    return isEmailInEarlyAccessList(user.email!);
  }

  /// Add email to early access list (admin function)
  Future<void> addEmailToEarlyAccess(String email, {String? addedBy}) async {
    final normalizedEmail = email.toLowerCase().trim();
    final docId = normalizedEmail.replaceAll('.', '_dot_').replaceAll('@', '_at_');

    await _firestore.collection(_collectionName).doc(docId).set({
      'email': normalizedEmail,
      'addedAt': FieldValue.serverTimestamp(),
      'addedBy': addedBy,
    });
  }

  /// Remove email from early access list (admin function)
  Future<void> removeEmailFromEarlyAccess(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    final docId = normalizedEmail.replaceAll('.', '_dot_').replaceAll('@', '_at_');

    await _firestore.collection(_collectionName).doc(docId).delete();
  }

  /// Add multiple emails from CSV (admin function)
  Future<EarlyAccessImportResult> importEmailsFromCsv(
    List<String> emails, {
    String? addedBy,
  }) async {
    int successCount = 0;
    int duplicateCount = 0;
    int errorCount = 0;
    final List<String> errors = [];

    final batch = _firestore.batch();
    final Set<String> processedEmails = {};

    for (final rawEmail in emails) {
      final email = rawEmail.toLowerCase().trim();

      // Skip empty lines
      if (email.isEmpty) continue;

      // Basic email validation
      if (!_isValidEmail(email)) {
        errorCount++;
        errors.add('Invalid email format: $rawEmail');
        continue;
      }

      // Skip duplicates within this import
      if (processedEmails.contains(email)) {
        duplicateCount++;
        continue;
      }

      processedEmails.add(email);
      final docId = email.replaceAll('.', '_dot_').replaceAll('@', '_at_');
      final docRef = _firestore.collection(_collectionName).doc(docId);

      batch.set(docRef, {
        'email': email,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': addedBy,
      });

      successCount++;
    }

    // Commit batch
    if (successCount > 0) {
      await batch.commit();
    }

    // Update config with import stats
    await _firestore.collection(_collectionName).doc(_configDocName).set({
      'lastImportAt': FieldValue.serverTimestamp(),
      'lastImportBy': addedBy,
      'lastImportCount': successCount,
      'totalImported': FieldValue.increment(successCount),
    }, SetOptions(merge: true));

    return EarlyAccessImportResult(
      successCount: successCount,
      duplicateCount: duplicateCount,
      errorCount: errorCount,
      errors: errors,
    );
  }

  /// Get all emails in early access list (admin function)
  Stream<List<EarlyAccessEmail>> watchEarlyAccessList() {
    return _firestore
        .collection(_collectionName)
        .where(FieldPath.documentId, isNotEqualTo: _configDocName)
        .orderBy(FieldPath.documentId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EarlyAccessEmail.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get early access list count
  Future<int> getEarlyAccessCount() async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Clear all emails from early access list (admin function - use with caution)
  Future<void> clearEarlyAccessList() async {
    final snapshot = await _firestore.collection(_collectionName).get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      if (doc.id != _configDocName) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Result of importing emails from CSV
class EarlyAccessImportResult {
  final int successCount;
  final int duplicateCount;
  final int errorCount;
  final List<String> errors;

  EarlyAccessImportResult({
    required this.successCount,
    required this.duplicateCount,
    required this.errorCount,
    required this.errors,
  });

  int get totalProcessed => successCount + duplicateCount + errorCount;

  bool get hasErrors => errorCount > 0;

  String get summary =>
      'Imported: $successCount | Duplicates: $duplicateCount | Errors: $errorCount';
}

/// Email entry in early access list
class EarlyAccessEmail {
  final String email;
  final DateTime? addedAt;
  final String? addedBy;

  EarlyAccessEmail({
    required this.email,
    this.addedAt,
    this.addedBy,
  });

  factory EarlyAccessEmail.fromFirestore(Map<String, dynamic> data, String docId) {
    return EarlyAccessEmail(
      email: data['email'] as String? ?? docId.replaceAll('_dot_', '.').replaceAll('_at_', '@'),
      addedAt: data['addedAt'] != null
          ? (data['addedAt'] as Timestamp).toDate()
          : null,
      addedBy: data['addedBy'] as String?,
    );
  }
}
