import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'access_control_service.dart';

/// Pre-sale tier levels
enum PreSaleTier {
  platinum,
  gold,
  silver,
}

extension PreSaleTierExtension on PreSaleTier {
  String get displayName {
    switch (this) {
      case PreSaleTier.platinum:
        return 'Platinum';
      case PreSaleTier.gold:
        return 'Gold';
      case PreSaleTier.silver:
        return 'Silver';
    }
  }

  String get value {
    switch (this) {
      case PreSaleTier.platinum:
        return 'platinum';
      case PreSaleTier.gold:
        return 'gold';
      case PreSaleTier.silver:
        return 'silver';
    }
  }

  static PreSaleTier? fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'platinum':
        return PreSaleTier.platinum;
      case 'gold':
        return PreSaleTier.gold;
      case 'silver':
        return PreSaleTier.silver;
      default:
        return null;
    }
  }
}

/// A pre-sale entry from the Firestore `pre_sale` collection
class PreSaleEntry {
  final String email;
  final PreSaleTier tier;
  final int numberOfDays;
  final DateTime? addedAt;
  final String? addedBy;

  PreSaleEntry({
    required this.email,
    required this.tier,
    required this.numberOfDays,
    this.addedAt,
    this.addedBy,
  });

  factory PreSaleEntry.fromFirestore(Map<String, dynamic> data, String docId) {
    return PreSaleEntry(
      email: data['email'] as String? ??
          docId.replaceAll('_dot_', '.').replaceAll('_at_', '@'),
      tier: PreSaleTierExtension.fromString(data['tier'] as String? ?? '') ??
          PreSaleTier.silver,
      numberOfDays: data['numberOfDays'] as int? ?? 30,
      addedAt: data['addedAt'] != null
          ? (data['addedAt'] as Timestamp).toDate()
          : null,
      addedBy: data['addedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'tier': tier.value,
      'numberOfDays': numberOfDays,
      'addedAt': addedAt != null ? Timestamp.fromDate(addedAt!) : FieldValue.serverTimestamp(),
      'addedBy': addedBy,
    };
  }
}

/// Result of importing pre-sale entries from CSV
class PreSaleImportResult {
  final int successCount;
  final int duplicateCount;
  final int errorCount;
  final List<String> errors;

  PreSaleImportResult({
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

/// Service for managing the pre-sale email/tier list.
///
/// The `pre_sale` Firestore collection stores entries with:
/// - `email`: user email
/// - `tier`: platinum, gold, or silver
/// - `numberOfDays`: subscription duration in days after countdown ends
///
/// When a user registers, the app checks this collection.
/// If the email matches, the user gets:
/// 1. A tier-specific countdown end date
/// 2. A subscription that starts when countdown ends and lasts `numberOfDays`
/// 3. A base membership that expires at the same time as the subscription
class PreSaleService {
  final FirebaseFirestore _firestore;

  static const String collectionName = 'pre_sale';

  PreSaleService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Normalize email to doc ID
  static String emailToDocId(String email) {
    return email.toLowerCase().trim().replaceAll('.', '_dot_').replaceAll('@', '_at_');
  }

  /// Get pre-sale entry for an email
  Future<PreSaleEntry?> getPreSaleEntry(String email) async {
    try {
      final docId = emailToDocId(email);
      final doc = await _firestore.collection(collectionName).doc(docId).get();
      if (!doc.exists) return null;
      return PreSaleEntry.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error fetching pre-sale entry: $e');
      return null;
    }
  }

  /// Get the countdown end date for a pre-sale tier
  static DateTime getCountdownEndDate(PreSaleTier tier) {
    switch (tier) {
      case PreSaleTier.platinum:
        return AccessControlService.platinumAccessDate;
      case PreSaleTier.gold:
        return AccessControlService.goldAccessDate;
      case PreSaleTier.silver:
        return AccessControlService.silverAccessDate;
    }
  }

  /// Calculate subscription expiry date:
  /// countdown end date + numberOfDays
  static DateTime calculateSubscriptionExpiry(PreSaleTier tier, int numberOfDays) {
    final countdownEnd = getCountdownEndDate(tier);
    return countdownEnd.add(Duration(days: numberOfDays));
  }

  /// Base membership expiry = same as subscription expiry
  static DateTime calculateBaseMembershipExpiry(PreSaleTier tier, int numberOfDays) {
    return calculateSubscriptionExpiry(tier, numberOfDays);
  }

  /// Add a single pre-sale entry
  Future<void> addEntry(PreSaleEntry entry, {String? addedBy}) async {
    final docId = emailToDocId(entry.email);
    await _firestore.collection(collectionName).doc(docId).set({
      'email': entry.email.toLowerCase().trim(),
      'tier': entry.tier.value,
      'numberOfDays': entry.numberOfDays,
      'addedAt': FieldValue.serverTimestamp(),
      'addedBy': addedBy,
    });
  }

  /// Remove a pre-sale entry
  Future<void> removeEntry(String email) async {
    final docId = emailToDocId(email);
    await _firestore.collection(collectionName).doc(docId).delete();
  }

  /// Import entries from parsed CSV rows
  /// Each row should have: email, numberOfDays, tier
  Future<PreSaleImportResult> importFromCsv(
    List<Map<String, String>> rows, {
    String? addedBy,
  }) async {
    int successCount = 0;
    int duplicateCount = 0;
    int errorCount = 0;
    final List<String> errors = [];
    final Set<String> processedEmails = {};

    final batch = _firestore.batch();

    for (final row in rows) {
      final email = (row['EMAIL'] ?? row['email'] ?? '').toLowerCase().trim();
      final tierStr = (row['TIER'] ?? row['tier'] ?? '').trim();
      final daysStr = (row['NUMBER_OF_DAYS'] ?? row['number_of_days'] ?? '').trim();

      if (email.isEmpty) continue;

      // Validate email
      if (!_isValidEmail(email)) {
        errorCount++;
        errors.add('Invalid email: $email');
        continue;
      }

      // Validate tier
      final tier = PreSaleTierExtension.fromString(tierStr);
      if (tier == null) {
        errorCount++;
        errors.add('Invalid tier "$tierStr" for $email (use: platinum, gold, silver)');
        continue;
      }

      // Validate numberOfDays
      final numberOfDays = int.tryParse(daysStr);
      if (numberOfDays == null || numberOfDays <= 0) {
        errorCount++;
        errors.add('Invalid NUMBER_OF_DAYS "$daysStr" for $email');
        continue;
      }

      // Skip duplicates within this import
      if (processedEmails.contains(email)) {
        duplicateCount++;
        continue;
      }

      processedEmails.add(email);
      final docId = emailToDocId(email);
      final docRef = _firestore.collection(collectionName).doc(docId);

      batch.set(docRef, {
        'email': email,
        'tier': tier.value,
        'numberOfDays': numberOfDays,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': addedBy,
      });

      successCount++;
    }

    if (successCount > 0) {
      await batch.commit();
    }

    return PreSaleImportResult(
      successCount: successCount,
      duplicateCount: duplicateCount,
      errorCount: errorCount,
      errors: errors,
    );
  }

  /// Watch all pre-sale entries (for admin)
  Stream<List<PreSaleEntry>> watchEntries() {
    return _firestore
        .collection(collectionName)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PreSaleEntry.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get count of pre-sale entries
  Future<int> getEntryCount() async {
    final snapshot = await _firestore.collection(collectionName).count().get();
    return snapshot.count ?? 0;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
  }
}
