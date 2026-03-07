import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/early_access_service.dart';

/// Admin screen for managing the early access email list
/// - Upload CSV files with email addresses
/// - View and manage existing entries
/// - Remove emails from the list
class EarlyAccessAdminScreen extends StatefulWidget {
  final String adminId;

  const EarlyAccessAdminScreen({
    super.key,
    required this.adminId,
  });

  @override
  State<EarlyAccessAdminScreen> createState() => _EarlyAccessAdminScreenState();
}

class _EarlyAccessAdminScreenState extends State<EarlyAccessAdminScreen> {
  final EarlyAccessService _earlyAccessService = EarlyAccessService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  EarlyAccessImportResult? _lastImportResult;
  List<EarlyAccessEmail> _filteredEmails = [];
  List<EarlyAccessEmail> _allEmails = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterEmails);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterEmails() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEmails = _allEmails;
      } else {
        _filteredEmails = _allEmails
            .where((email) => email.email.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _uploadCsvFile() async {
    try {
      setState(() {
        _isUploading = true;
        _errorMessage = null;
        _lastImportResult = null;
      });

      // Pick CSV file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isUploading = false);
        return;
      }

      final file = result.files.first;
      String content;

      if (file.bytes != null) {
        // Web platform
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        // Mobile/Desktop platform
        final fileObj = File(file.path!);
        content = await fileObj.readAsString();
      } else {
        throw Exception('Could not read file');
      }

      // Parse CSV content - extract emails from each line
      final lines = content.split(RegExp(r'[\r\n]+'));
      final emails = <String>[];

      for (final line in lines) {
        // Handle comma-separated values
        final parts = line.split(',');
        for (final part in parts) {
          final trimmed = part.trim();
          // Basic email pattern check
          if (trimmed.contains('@') && trimmed.contains('.')) {
            // Remove quotes if present
            emails.add(trimmed.replaceAll('"', '').replaceAll("'", ''));
          }
        }
      }

      if (emails.isEmpty) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.adminNoValidEmailsFound;
          _isUploading = false;
        });
        return;
      }

      // Import emails
      final importResult = await _earlyAccessService.importEmailsFromCsv(
        emails,
        addedBy: widget.adminId,
      );

      setState(() {
        _lastImportResult = importResult;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(importResult.summary),
            backgroundColor: importResult.hasErrors
                ? AppColors.warningAmber
                : AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.adminErrorUploadingFile(e.toString());
        _isUploading = false;
      });
    }
  }

  Future<void> _addSingleEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.adminPleaseEnterValidEmail);
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _earlyAccessService.addEmailToEarlyAccess(
        email,
        addedBy: widget.adminId,
      );

      _emailController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.adminEmailAddedToEarlyAccess(email)),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = AppLocalizations.of(context)!.adminErrorAddingEmail(e.toString()));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeEmail(String email) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.adminRemoveEmail,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.adminRemoveEmailConfirm(email),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: Text(l10n.adminRemove),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _earlyAccessService.removeEmailFromEarlyAccess(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminEmailRemovedFromEarlyAccess(email)),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminErrorRemovingEmail(e.toString())),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.adminEarlyAccessList,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            _buildInfoCard(),
            const SizedBox(height: AppDimensions.paddingL),

            // Upload Section
            _buildUploadSection(),
            const SizedBox(height: AppDimensions.paddingL),

            // Add Single Email Section
            _buildAddEmailSection(),
            const SizedBox(height: AppDimensions.paddingL),

            // Import Result
            if (_lastImportResult != null) ...[
              _buildImportResultCard(),
              const SizedBox(height: AppDimensions.paddingL),
            ],

            // Error Message
            if (_errorMessage != null) ...[
              _buildErrorCard(),
              const SizedBox(height: AppDimensions.paddingL),
            ],

            // Email List
            _buildEmailList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.richGold.withValues(alpha: 0.2),
            AppColors.charcoal,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star,
              color: AppColors.richGold,
              size: 28,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.adminEarlyAccessProgram,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.adminEarlyAccessDates,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file, color: AppColors.richGold, size: 24),
              const SizedBox(width: AppDimensions.paddingS),
              Text(
                AppLocalizations.of(context)!.adminUploadCsvFile,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            AppLocalizations.of(context)!.adminUploadCsvDescription,
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadCsvFile,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_isUploading ? AppLocalizations.of(context)!.adminUploading : AppLocalizations.of(context)!.adminSelectCsvFile),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddEmailSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add, color: AppColors.successGreen, size: 24),
              const SizedBox(width: AppDimensions.paddingS),
              Text(
                AppLocalizations.of(context)!.adminAddSingleEmail,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.adminEnterEmailAddress,
                    hintStyle: const TextStyle(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.backgroundInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onSubmitted: (_) => _addSingleEmail(),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              ElevatedButton(
                onPressed: _isLoading ? null : _addSingleEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(AppLocalizations.of(context)!.adminAdd),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportResultCard() {
    final result = _lastImportResult!;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: result.hasErrors
            ? AppColors.warningAmber.withValues(alpha: 0.1)
            : AppColors.successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: result.hasErrors
              ? AppColors.warningAmber.withValues(alpha: 0.3)
              : AppColors.successGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.hasErrors ? Icons.warning : Icons.check_circle,
                color: result.hasErrors
                    ? AppColors.warningAmber
                    : AppColors.successGreen,
              ),
              const SizedBox(width: AppDimensions.paddingS),
              Text(
                AppLocalizations.of(context)!.adminImportResult,
                style: TextStyle(
                  color: result.hasErrors
                      ? AppColors.warningAmber
                      : AppColors.successGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            result.summary,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              AppLocalizations.of(context)!.adminErrors,
              style: TextStyle(
                color: AppColors.errorRed,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...result.errors.take(5).map((error) => Text(
                  '  • $error',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                )),
            if (result.errors.length > 5)
              Text(
                AppLocalizations.of(context)!.adminMoreErrors(result.errors.length - 5),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: AppColors.errorRed),
          const SizedBox(width: AppDimensions.paddingS),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.errorRed),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list, color: AppColors.infoBlue, size: 24),
                    const SizedBox(width: AppDimensions.paddingS),
                    Text(
                      AppLocalizations.of(context)!.adminEmailList,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    StreamBuilder<List<EarlyAccessEmail>>(
                      stream: _earlyAccessService.watchEarlyAccessList(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.richGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.adminEmailCount(count),
                            style: const TextStyle(
                              color: AppColors.richGold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingM),
                // Search field
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.adminSearchEmails,
                    hintStyle: const TextStyle(color: AppColors.textTertiary),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          StreamBuilder<List<EarlyAccessEmail>>(
            stream: _earlyAccessService.watchEarlyAccessList(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.richGold),
                  ),
                );
              }

              _allEmails = snapshot.data ?? [];
              _filterEmails();

              if (_filteredEmails.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 48,
                          color: AppColors.textTertiary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        Text(
                          _searchController.text.isNotEmpty
                              ? AppLocalizations.of(context)!.adminNoMatchingEmailsFound
                              : AppLocalizations.of(context)!.adminNoEmailsInEarlyAccessList,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredEmails.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.divider,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final email = _filteredEmails[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.richGold.withValues(alpha: 0.15),
                      child: Text(
                        email.email[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.richGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      email.email,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: email.addedAt != null
                        ? Text(
                            AppLocalizations.of(context)!.adminAddedDate(_formatDate(email.addedAt!)),
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.errorRed,
                      ),
                      onPressed: () => _removeEmail(email.email),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.richGold),
            const SizedBox(width: 8),
            Text(
              l10n.adminEarlyAccessInfo,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.adminAccessDates,
              style: const TextStyle(
                color: AppColors.richGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.star,
              AppColors.richGold,
              l10n.adminEarlyAccessInList,
              l10n.adminEarlyAccessDate,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.people,
              AppColors.textSecondary,
              l10n.adminGeneralAccess,
              l10n.adminGeneralAccessDate,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.adminCsvFormat,
              style: const TextStyle(
                color: AppColors.richGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.adminCsvFormatDescription,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
