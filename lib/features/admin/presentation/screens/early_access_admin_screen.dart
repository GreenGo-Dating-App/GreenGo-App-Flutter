import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
          _errorMessage = 'No valid email addresses found in the file';
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
        _errorMessage = 'Error uploading file: $e';
        _isUploading = false;
      });
    }
  }

  Future<void> _addSingleEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
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
            content: Text('$email added to early access list'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error adding email: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeEmail(String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Remove Email',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove "$email" from the early access list?',
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
            child: const Text('Remove'),
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
            content: Text('$email removed from early access list'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing email: $e'),
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
        title: const Text(
          'Early Access List',
          style: TextStyle(color: AppColors.textPrimary),
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
                const Text(
                  'Early Access Program',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Users in this list get access on March 1, 2026.\n'
                  'All other users get access on March 16, 2026.',
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
          const Row(
            children: [
              Icon(Icons.upload_file, color: AppColors.richGold, size: 24),
              SizedBox(width: AppDimensions.paddingS),
              Text(
                'Upload CSV File',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            'Upload a CSV file containing email addresses (one per line or comma-separated)',
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
              label: Text(_isUploading ? 'Uploading...' : 'Select CSV File'),
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
          const Row(
            children: [
              Icon(Icons.person_add, color: AppColors.successGreen, size: 24),
              SizedBox(width: AppDimensions.paddingS),
              Text(
                'Add Single Email',
                style: TextStyle(
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
                    hintText: 'Enter email address',
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
                    : const Text('Add'),
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
                'Import Result',
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
              'Errors:',
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
                '  ... and ${result.errors.length - 5} more errors',
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
                    const Text(
                      'Email List',
                      style: TextStyle(
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
                            '$count emails',
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
                    hintText: 'Search emails...',
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
                              ? 'No matching emails found'
                              : 'No emails in early access list',
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
                            'Added ${_formatDate(email.addedAt!)}',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.richGold),
            SizedBox(width: 8),
            Text(
              'Early Access Info',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Access Dates:',
              style: TextStyle(
                color: AppColors.richGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.star,
              AppColors.richGold,
              'Early Access (in list)',
              'March 1, 2026',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.people,
              AppColors.textSecondary,
              'General Access',
              'March 16, 2026',
            ),
            const SizedBox(height: 16),
            const Text(
              'CSV Format:',
              style: TextStyle(
                color: AppColors.richGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• One email per line, or\n'
              '• Comma-separated values\n'
              '• Quotes are automatically removed\n'
              '• Invalid emails are skipped',
              style: TextStyle(
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
