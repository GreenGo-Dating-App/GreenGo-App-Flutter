import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../services/translation_service.dart';

/// Dialog to download translation language models
class TranslationDownloadDialog extends StatefulWidget {
  final List<String> languagesToDownload;
  final VoidCallback? onComplete;

  const TranslationDownloadDialog({
    super.key,
    required this.languagesToDownload,
    this.onComplete,
  });

  /// Show the download dialog
  static Future<bool> show(
    BuildContext context, {
    required List<String> languages,
    VoidCallback? onComplete,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TranslationDownloadDialog(
        languagesToDownload: languages,
        onComplete: onComplete,
      ),
    );
    return result ?? false;
  }

  @override
  State<TranslationDownloadDialog> createState() => _TranslationDownloadDialogState();
}

class _TranslationDownloadDialogState extends State<TranslationDownloadDialog> {
  final TranslationService _translationService = TranslationService();
  bool _isDownloading = false;
  int _currentIndex = 0;
  String _currentLanguage = '';
  bool _hasError = false;
  String _failedLanguageName = '';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _hasError = false;
    });

    for (int i = 0; i < widget.languagesToDownload.length; i++) {
      final lang = widget.languagesToDownload[i];

      setState(() {
        _currentIndex = i;
        _currentLanguage = lang;
      });

      final success = await _translationService.downloadModel(lang);

      if (!success) {
        setState(() {
          _hasError = true;
          _failedLanguageName = TranslationService.getLanguageName(lang);
        });
        // Continue with other languages even if one fails
      }
    }

    setState(() {
      _isDownloading = false;
    });

    if (!_hasError) {
      widget.onComplete?.call();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: Text(
        _isDownloading ? l10n.downloadingTranslationData : l10n.enableAutoTranslation,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isDownloading && !_hasError) ...[
            const Icon(
              Icons.translate,
              size: 48,
              color: AppColors.richGold,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translationDownloadExplanation,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.languagesToDownloadLabel,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.languagesToDownload.map((lang) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: AppColors.richGold),
                  const SizedBox(width: 8),
                  Text(
                    TranslationService.getLanguageName(lang),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Text(
              l10n.oneTimeDownloadSize(widget.languagesToDownload.length * 30),
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (_isDownloading) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              color: AppColors.richGold,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.downloadingLanguage(TranslationService.getLanguageName(_currentLanguage)),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.downloadProgress(_currentIndex + 1, widget.languagesToDownload.length),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (_hasError) ...[
            const SizedBox(height: 16),
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.failedToDownloadModel(_failedLanguageName),
              style: const TextStyle(
                color: AppColors.errorRed,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              _hasError ? l10n.close : l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          if (!_hasError)
            ElevatedButton(
              onPressed: _startDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
              ),
              child: Text(l10n.download),
            ),
          if (_hasError)
            ElevatedButton(
              onPressed: _startDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
              ),
              child: Text(l10n.retry),
            ),
        ],
      ],
    );
  }
}
