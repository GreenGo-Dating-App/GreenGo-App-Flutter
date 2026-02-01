import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

  String get githubFileName {
    switch (this) {
      case LegalDocumentType.termsAndConditions:
        return 'TERMS_AND_CONDITIONS';
      case LegalDocumentType.privacyPolicy:
        return 'PRIVACY_POLICY';
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

  /// Create from GitHub markdown content
  factory LegalDocument.fromGitHub({
    required LegalDocumentType type,
    required String languageCode,
    required String content,
    String? version,
  }) {
    // Extract title from first line if it's a markdown header
    String title = type.displayName;
    String body = content;

    final lines = content.split('\n');
    if (lines.isNotEmpty && lines[0].startsWith('#')) {
      title = lines[0].replaceAll('#', '').trim();
      body = lines.skip(1).join('\n').trim();
    }

    return LegalDocument(
      id: '${type.firestoreKey}_$languageCode',
      type: type,
      languageCode: languageCode,
      title: title,
      content: body,
      version: version ?? '1.0',
      isActive: true,
      lastUpdated: DateTime.now(),
      updatedBy: 'github',
      createdAt: DateTime.now(),
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

/// Service for fetching legal documents from GitHub repository
class LegalDocumentsService extends ChangeNotifier {
  static final LegalDocumentsService _instance = LegalDocumentsService._internal();
  factory LegalDocumentsService() => _instance;
  LegalDocumentsService._internal();

  // GitHub repository configuration
  // Update these values to match your GitHub repository
  static const String _githubOwner = 'AnarTechnologies';
  static const String _githubRepo = 'GreenGo-App-Flutter';
  static const String _githubBranch = 'main';
  static const String _legalDocsPath = 'legal';

  // Cached documents
  final Map<String, LegalDocument> _documentsCache = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Build GitHub raw content URL
  String _buildGitHubUrl(LegalDocumentType type, String languageCode) {
    final fileName = '${type.githubFileName}_$languageCode.md';
    return 'https://raw.githubusercontent.com/$_githubOwner/$_githubRepo/$_githubBranch/$_legalDocsPath/$fileName';
  }

  /// Get a legal document by type and language code from GitHub
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

      // Normalize language code (e.g., pt-BR -> pt_BR)
      final normalizedLang = languageCode.replaceAll('-', '_');

      // Try fetching from GitHub
      final url = _buildGitHubUrl(type, normalizedLang);
      debugPrint('Fetching legal document from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'text/plain'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes);
        final document = LegalDocument.fromGitHub(
          type: type,
          languageCode: normalizedLang,
          content: content,
        );
        _documentsCache[docId] = document;
        _error = null;
        return document;
      }

      // Try base language (e.g., pt_BR -> pt)
      if (normalizedLang.contains('_')) {
        final baseLang = normalizedLang.split('_')[0];
        debugPrint('Trying base language: $baseLang');

        final baseUrl = _buildGitHubUrl(type, baseLang);
        final baseResponse = await http.get(
          Uri.parse(baseUrl),
          headers: {'Accept': 'text/plain'},
        ).timeout(const Duration(seconds: 10));

        if (baseResponse.statusCode == 200) {
          final content = utf8.decode(baseResponse.bodyBytes);
          final document = LegalDocument.fromGitHub(
            type: type,
            languageCode: baseLang,
            content: content,
          );
          _documentsCache[docId] = document;
          _error = null;
          return document;
        }
      }

      // Fall back to English if requested language not found
      if (normalizedLang != 'en') {
        debugPrint('Legal document not found for $normalizedLang, falling back to English');
        return getDocument(type, 'en');
      }

      _error = 'Document not found';
      return null;
    } catch (e) {
      debugPrint('Error fetching legal document from GitHub: $e');
      _error = e.toString();

      // Return null, the screen will show fallback content
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

  /// Watch document is not supported for GitHub
  /// Returns a stream that fetches once and completes
  Stream<LegalDocument?> watchDocument(
    LegalDocumentType type,
    String languageCode,
  ) async* {
    yield await getDocument(type, languageCode);
  }

  /// Get all available documents for a type
  /// For GitHub, this returns cached documents only
  Future<List<LegalDocument>> getAllDocumentsForType(LegalDocumentType type) async {
    return _documentsCache.values
        .where((doc) => doc.type == type)
        .toList();
  }

  /// Check if a document exists on GitHub
  Future<bool> documentExists(LegalDocumentType type, String languageCode) async {
    try {
      final url = _buildGitHubUrl(type, languageCode.replaceAll('-', '_'));
      final response = await http.head(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get list of available languages for a document type
  /// Returns default supported languages (checking GitHub would be slow)
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
