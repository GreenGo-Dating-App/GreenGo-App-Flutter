import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
  SupportedLanguage(code: 'pt', name: 'Português', flag: ''),
  SupportedLanguage(code: 'es', name: 'Español', flag: ''),
  SupportedLanguage(code: 'fr', name: 'Français', flag: ''),
  SupportedLanguage(code: 'de', name: 'Deutsch', flag: ''),
  SupportedLanguage(code: 'it', name: 'Italiano', flag: ''),
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

  /// Asset file prefix (matches file naming in assets/legal/)
  String get assetPrefix {
    switch (this) {
      case LegalDocumentType.termsAndConditions:
        return 'terms-and-conditions';
      case LegalDocumentType.privacyPolicy:
        return 'privacy-policy';
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

  /// Create from bundled asset content
  factory LegalDocument.fromAsset({
    required LegalDocumentType type,
    required String languageCode,
    required String content,
    String? version,
  }) {
    // Extract title from first line if it looks like a header
    String title = type.displayName;
    String body = content;

    final lines = content.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines[0].trim();
      if (firstLine.startsWith('#')) {
        title = firstLine.replaceAll('#', '').trim();
        body = lines.skip(1).join('\n').trim();
      } else if (firstLine.isNotEmpty &&
          !firstLine.startsWith('=') &&
          firstLine.length < 100) {
        title = firstLine;
      }
    }

    return LegalDocument(
      id: '${type.firestoreKey}_$languageCode',
      type: type,
      languageCode: languageCode,
      title: title,
      content: body,
      version: version ?? '1.0',
      isActive: true,
      lastUpdated: DateTime(2026, 1, 26),
      updatedBy: 'bundled',
      createdAt: DateTime(2026, 1, 26),
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

/// Service for loading legal documents from bundled assets
class LegalDocumentsService extends ChangeNotifier {
  static final LegalDocumentsService _instance = LegalDocumentsService._internal();
  factory LegalDocumentsService() => _instance;
  LegalDocumentsService._internal();

  // Cached documents
  final Map<String, LegalDocument> _documentsCache = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Build asset path for a document type and language
  String _buildAssetPath(LegalDocumentType type, String languageCode) {
    return 'assets/legal/${type.assetPrefix}-$languageCode.txt';
  }

  /// Get a legal document by type and language code from bundled assets
  /// Falls back: specific locale → base language → English
  Future<LegalDocument?> getDocument(
    LegalDocumentType type,
    String languageCode,
  ) async {
    final normalizedLang = languageCode.replaceAll('-', '_');
    final docId = '${type.firestoreKey}_$normalizedLang';

    // Check cache first
    if (_documentsCache.containsKey(docId)) {
      return _documentsCache[docId];
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Try loading the exact language
      String? content = await _tryLoadAsset(type, normalizedLang);

      // Try base language (e.g., pt_BR -> pt)
      if (content == null && normalizedLang.contains('_')) {
        final baseLang = normalizedLang.split('_')[0];
        content = await _tryLoadAsset(type, baseLang);
      }

      // Fall back to English
      if (content == null && normalizedLang != 'en') {
        content = await _tryLoadAsset(type, 'en');
      }

      if (content != null) {
        final document = LegalDocument.fromAsset(
          type: type,
          languageCode: normalizedLang,
          content: content,
        );
        _documentsCache[docId] = document;
        _error = null;
        return document;
      }

      _error = 'Document not found';
      return null;
    } catch (e) {
      debugPrint('Error loading legal document: $e');
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Try to load an asset file, return null if not found
  Future<String?> _tryLoadAsset(LegalDocumentType type, String languageCode) async {
    try {
      final path = _buildAssetPath(type, languageCode);
      return await rootBundle.loadString(path);
    } catch (_) {
      return null;
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

  /// Watch document - returns a stream that loads once from assets
  Stream<LegalDocument?> watchDocument(
    LegalDocumentType type,
    String languageCode,
  ) async* {
    yield await getDocument(type, languageCode);
  }

  /// Get all available documents for a type (cached only)
  Future<List<LegalDocument>> getAllDocumentsForType(LegalDocumentType type) async {
    return _documentsCache.values
        .where((doc) => doc.type == type)
        .toList();
  }

  /// Check if a document exists for a language
  Future<bool> documentExists(LegalDocumentType type, String languageCode) async {
    final content = await _tryLoadAsset(type, languageCode.replaceAll('-', '_'));
    return content != null;
  }

  /// Get list of available languages
  Future<List<String>> getAvailableLanguages(LegalDocumentType type) async {
    return supportedLanguages.map((l) => l.code).toList();
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

  /// Preload documents for common languages
  Future<void> preloadDocuments() async {
    const commonLanguages = ['en', 'pt_BR', 'es', 'fr', 'de', 'it'];

    for (final lang in commonLanguages) {
      await getDocument(LegalDocumentType.termsAndConditions, lang);
      await getDocument(LegalDocumentType.privacyPolicy, lang);
    }
  }
}

/// Global instance for easy access
final legalDocumentsService = LegalDocumentsService();
