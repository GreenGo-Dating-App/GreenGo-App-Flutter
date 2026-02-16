import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/legal_documents_service.dart';
import '../../../../generated/app_localizations.dart';

/// Screen to display legal documents (Terms & Conditions or Privacy Policy)
class LegalDocumentScreen extends StatefulWidget {
  final LegalDocumentType documentType;
  final String? languageCode;

  const LegalDocumentScreen({
    super.key,
    required this.documentType,
    this.languageCode,
  });

  /// Convenience constructor for Terms & Conditions
  const LegalDocumentScreen.termsAndConditions({
    super.key,
    this.languageCode,
  }) : documentType = LegalDocumentType.termsAndConditions;

  /// Convenience constructor for Privacy Policy
  const LegalDocumentScreen.privacyPolicy({
    super.key,
    this.languageCode,
  }) : documentType = LegalDocumentType.privacyPolicy;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  LegalDocument? _document;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocument();
    });
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the language code from the widget or from the current locale
      String languageCode = widget.languageCode ?? 'en';

      // Try to get from locale if mounted
      if (mounted) {
        try {
          final locale = Localizations.localeOf(context);
          languageCode = widget.languageCode ??
              locale.toString().replaceAll('-', '_');
        } catch (_) {
          // Use default if locale is not available
        }
      }

      final document = await legalDocumentsService.getDocument(
        widget.documentType,
        languageCode,
      );

      if (mounted) {
        setState(() {
          _document = document;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.richGold),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _document?.title ?? widget.documentType.displayName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_document != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'v${_document!.version}',
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations? l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.richGold,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.errorRed,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.errorLoadingDocument ?? 'Error loading document',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l10n?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_document == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.description_outlined,
                color: AppColors.textSecondary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.documentNotAvailable ?? 'Document not available',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.documentNotAvailableDescription ??
                    'This document is not available in your language yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Last updated info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: AppColors.backgroundCard,
          child: Row(
            children: [
              const Icon(
                Icons.update,
                color: AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l10n?.lastUpdated ?? 'Last updated'}: ${_formatDate(_document!.lastUpdated)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Document content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              _document!.content,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.7,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Wrapper for navigating to Terms & Conditions
class TermsAndConditionsScreen extends StatelessWidget {
  final String? languageCode;

  const TermsAndConditionsScreen({super.key, this.languageCode});

  @override
  Widget build(BuildContext context) {
    return LegalDocumentScreen.termsAndConditions(languageCode: languageCode);
  }
}

/// Wrapper for navigating to Privacy Policy
class PrivacyPolicyScreen extends StatelessWidget {
  final String? languageCode;

  const PrivacyPolicyScreen({super.key, this.languageCode});

  @override
  Widget build(BuildContext context) {
    return LegalDocumentScreen.privacyPolicy(languageCode: languageCode);
  }
}
