import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Supported language codes
class SupportedLanguage {
  final String code;
  final String name;
  final String flag;

  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.flag,
  });
}

/// List of supported languages
const List<SupportedLanguage> supportedLanguages = [
  SupportedLanguage(code: 'en', name: 'English', flag: ''),
  SupportedLanguage(code: 'pt_BR', name: 'Português (Brasil)', flag: ''),
  SupportedLanguage(code: 'es', name: 'Español', flag: ''),
  SupportedLanguage(code: 'fr', name: 'Français', flag: ''),
  SupportedLanguage(code: 'de', name: 'Deutsch', flag: ''),
  SupportedLanguage(code: 'it', name: 'Italiano', flag: ''),
  SupportedLanguage(code: 'zh', name: '中文', flag: ''),
  SupportedLanguage(code: 'ja', name: '日本語', flag: ''),
  SupportedLanguage(code: 'ko', name: '한국어', flag: ''),
  SupportedLanguage(code: 'ar', name: 'العربية', flag: ''),
];

/// Document types
enum LegalDocumentType {
  termsAndConditions,
  privacyPolicy,
}

extension LegalDocumentTypeExtension on LegalDocumentType {
  String get firestoreKey {
    switch (this) {
      case LegalDocumentType.termsAndConditions:
        return 'terms_and_conditions';
      case LegalDocumentType.privacyPolicy:
        return 'privacy_policy';
    }
  }

  String get displayName {
    switch (this) {
      case LegalDocumentType.termsAndConditions:
        return 'Terms & Conditions';
      case LegalDocumentType.privacyPolicy:
        return 'Privacy Policy';
    }
  }
}

/// Legal document model
class LegalDocument {
  final String id;
  final LegalDocumentType type;
  final String languageCode;
  final String title;
  final String content;
  final String version;
  final bool isActive;
  final DateTime lastUpdated;
  final String updatedBy;
  final DateTime createdAt;

  const LegalDocument({
    required this.id,
    required this.type,
    required this.languageCode,
    required this.title,
    required this.content,
    required this.version,
    required this.isActive,
    required this.lastUpdated,
    required this.updatedBy,
    required this.createdAt,
  });

  factory LegalDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    LegalDocumentType type = LegalDocumentType.termsAndConditions;
    final typeStr = data['type'] as String? ?? 'terms_and_conditions';
    if (typeStr == 'privacy_policy') {
      type = LegalDocumentType.privacyPolicy;
    }

    return LegalDocument(
      id: doc.id,
      type: type,
      languageCode: data['languageCode'] as String? ?? 'en',
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      version: data['version'] as String? ?? '1.0',
      isActive: data['isActive'] as bool? ?? true,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: data['updatedBy'] as String? ?? 'system',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.firestoreKey,
      'languageCode': languageCode,
      'title': title,
      'content': content,
      'version': version,
      'isActive': isActive,
      'lastUpdated': lastUpdated.toIso8601String(),
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Service for fetching legal documents from Firestore
class LegalDocumentsService extends ChangeNotifier {
  static final LegalDocumentsService _instance = LegalDocumentsService._internal();
  factory LegalDocumentsService() => _instance;
  LegalDocumentsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'legal_documents';

  // Cached documents
  final Map<String, LegalDocument> _documentsCache = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get a legal document by type and language code
  /// Falls back to English if the requested language is not available
  Future<LegalDocument?> getDocument(
    LegalDocumentType type,
    String languageCode,
  ) async {
    final docId = '${type.firestoreKey}_$languageCode';

    // Check cache first
    if (_documentsCache.containsKey(docId)) {
      return _documentsCache[docId];
    }

    try {
      _isLoading = true;
      notifyListeners();

      final docRef = _firestore.collection(_collection).doc(docId);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final document = LegalDocument.fromFirestore(docSnap);
        if (document.isActive) {
          _documentsCache[docId] = document;
          _error = null;
          return document;
        }
      }

      // Fall back to English if requested language not found
      if (languageCode != 'en') {
        debugPrint('Legal document not found for $languageCode, falling back to English');
        return getDocument(type, 'en');
      }

      _error = 'Document not found';
      return null;
    } catch (e) {
      debugPrint('Error fetching legal document: $e');
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get Terms & Conditions for a language
  Future<LegalDocument?> getTermsAndConditions(String languageCode) {
    return getDocument(LegalDocumentType.termsAndConditions, languageCode);
  }

  /// Get Privacy Policy for a language
  Future<LegalDocument?> getPrivacyPolicy(String languageCode) {
    return getDocument(LegalDocumentType.privacyPolicy, languageCode);
  }

  /// Listen to real-time updates for a document
  Stream<LegalDocument?> watchDocument(
    LegalDocumentType type,
    String languageCode,
  ) {
    final docId = '${type.firestoreKey}_$languageCode';

    return _firestore
        .collection(_collection)
        .doc(docId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final document = LegalDocument.fromFirestore(snapshot);
        if (document.isActive) {
          _documentsCache[docId] = document;
          return document;
        }
      }
      return null;
    });
  }

  /// Get all available documents for a type (all languages)
  Future<List<LegalDocument>> getAllDocumentsForType(LegalDocumentType type) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.firestoreKey)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => LegalDocument.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all documents for type ${type.firestoreKey}: $e');
      return [];
    }
  }

  /// Check if a document exists for a specific language
  Future<bool> documentExists(LegalDocumentType type, String languageCode) async {
    final docId = '${type.firestoreKey}_$languageCode';

    try {
      final docSnap = await _firestore.collection(_collection).doc(docId).get();
      return docSnap.exists && (docSnap.data()?['isActive'] as bool? ?? false);
    } catch (e) {
      return false;
    }
  }

  /// Get list of available languages for a document type
  Future<List<String>> getAvailableLanguages(LegalDocumentType type) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.firestoreKey)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['languageCode'] as String? ?? 'en')
          .toList();
    } catch (e) {
      debugPrint('Error fetching available languages: $e');
      return ['en'];
    }
  }

  /// Clear the cache
  void clearCache() {
    _documentsCache.clear();
    notifyListeners();
  }

  /// Get cached document if available
  LegalDocument? getCachedDocument(LegalDocumentType type, String languageCode) {
    final docId = '${type.firestoreKey}_$languageCode';
    return _documentsCache[docId];
  }
}

/// Global instance for easy access
final legalDocumentsService = LegalDocumentsService();
