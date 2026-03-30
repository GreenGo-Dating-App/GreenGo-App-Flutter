import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/pre_sale_service.dart';

/// Admin screen for managing the pre-sale tier list.
/// - Upload CSV files with headers: EMAIL, NUMBER_OF_DAYS, TIER
/// - View and manage existing entries
/// - Filter by tier
/// - Remove entries
class PreSaleAdminScreen extends StatefulWidget {
  final String adminId;

  const PreSaleAdminScreen({
    super.key,
    required this.adminId,
  });

  @override
  State<PreSaleAdminScreen> createState() => _PreSaleAdminScreenState();
}

class _PreSaleAdminScreenState extends State<PreSaleAdminScreen> {
  final PreSaleService _preSaleService = PreSaleService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _daysController = TextEditingController(text: '30');
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  PreSaleImportResult? _lastImportResult;
  List<PreSaleEntry> _filteredEntries = [];
  List<PreSaleEntry> _allEntries = [];
  PreSaleTier _selectedTier = PreSaleTier.silver;
  String _filterTier = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterEntries);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _daysController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterEntries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEntries = _allEntries.where((entry) {
        final matchesSearch = query.isEmpty || entry.email.toLowerCase().contains(query);
        final matchesTier = _filterTier == 'all' || entry.tier.value == _filterTier;
        return matchesSearch && matchesTier;
      }).toList();
    });
  }

  Future<void> _uploadCsvFile() async {
    try {
      setState(() {
        _isUploading = true;
        _errorMessage = null;
        _lastImportResult = null;
      });

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
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        final fileObj = File(file.path!);
        content = await fileObj.readAsString();
      } else {
        throw Exception('Could not read file');
      }

      // Parse CSV
      final lines = content.split(RegExp(r'[\r\n]+'));
      if (lines.isEmpty) {
        setState(() {
          _errorMessage = 'CSV file is empty';
          _isUploading = false;
        });
        return;
      }

      // Find header line
      final headerLine = lines.first.trim();
      final headers = headerLine.split(',').map((h) => h.trim().toUpperCase().replaceAll('"', '')).toList();

      final emailIdx = headers.indexOf('EMAIL');
      final daysIdx = headers.indexOf('NUMBER_OF_DAYS');
      final tierIdx = headers.indexOf('TIER');

      if (emailIdx == -1 || daysIdx == -1 || tierIdx == -1) {
        setState(() {
          _errorMessage = 'CSV must have headers: EMAIL, NUMBER_OF_DAYS, TIER\nFound: ${headers.join(', ')}';
          _isUploading = false;
        });
        return;
      }

      // Parse data rows
      final rows = <Map<String, String>>[];
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(',').map((p) => p.trim().replaceAll('"', '').replaceAll("'", '')).toList();
        if (parts.length > tierIdx && parts.length > daysIdx && parts.length > emailIdx) {
          rows.add({
            'EMAIL': parts[emailIdx],
            'NUMBER_OF_DAYS': parts[daysIdx],
            'TIER': parts[tierIdx],
          });
        }
      }

      if (rows.isEmpty) {
        setState(() {
          _errorMessage = 'No valid data rows found in CSV';
          _isUploading = false;
        });
        return;
      }

      final importResult = await _preSaleService.importFromCsv(
        rows,
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

  Future<void> _addSingleEntry() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    final days = int.tryParse(_daysController.text.trim());
    if (days == null || days <= 0) {
      setState(() => _errorMessage = 'Please enter a valid number of days');
      return;
    }

    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _preSaleService.addEntry(
        PreSaleEntry(
          email: email,
          tier: _selectedTier,
          numberOfDays: days,
        ),
        addedBy: widget.adminId,
      );

      _emailController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$email added as ${_selectedTier.displayName} ($days days)'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error adding entry: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeEntry(String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Remove Entry',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove $email from the pre-sale list?',
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
      await _preSaleService.removeEntry(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$email removed from pre-sale list'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing entry: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Color _tierColor(PreSaleTier tier) {
    switch (tier) {
      case PreSaleTier.platinum:
        return AppColors.richGold;
      case PreSaleTier.gold:
        return Colors.amber;
      case PreSaleTier.silver:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'Pre-Sale Management',
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
            _buildInfoCard(),
            const SizedBox(height: AppDimensions.paddingL),
            _buildUploadSection(),
            const SizedBox(height: AppDimensions.paddingL),
            _buildAddEntrySection(),
            const SizedBox(height: AppDimensions.paddingL),
            if (_lastImportResult != null) ...[
              _buildImportResultCard(),
              const SizedBox(height: AppDimensions.paddingL),
            ],
            if (_errorMessage != null) ...[
              _buildErrorCard(),
              const SizedBox(height: AppDimensions.paddingL),
            ],
            _buildEntryList(),
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
              Icons.shopping_bag,
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
                  'Pre-Sale Tier Program',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage pre-sale users with tier-based countdown and subscription duration.',
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
            'CSV format: EMAIL, NUMBER_OF_DAYS, TIER\nTier values: platinum, gold, silver',
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

  Widget _buildAddEntrySection() {
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
                'Add Single Entry',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
          // Email
          TextField(
            controller: _emailController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Email address',
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.backgroundInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppDimensions.paddingS),
          // Days + Tier row
          Row(
            children: [
              // Number of days
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _daysController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Days',
                    hintStyle: const TextStyle(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.backgroundInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              // Tier dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundInput,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PreSaleTier>(
                      value: _selectedTier,
                      dropdownColor: AppColors.backgroundCard,
                      style: const TextStyle(color: AppColors.textPrimary),
                      isExpanded: true,
                      items: PreSaleTier.values.map((tier) {
                        return DropdownMenuItem(
                          value: tier,
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: _tierColor(tier), size: 12),
                              const SizedBox(width: 8),
                              Text(tier.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (tier) {
                        if (tier != null) setState(() => _selectedTier = tier);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              // Add button
              ElevatedButton(
                onPressed: _isLoading ? null : _addSingleEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
                color: result.hasErrors ? AppColors.warningAmber : AppColors.successGreen,
              ),
              const SizedBox(width: AppDimensions.paddingS),
              Text(
                'Import Result',
                style: TextStyle(
                  color: result.hasErrors ? AppColors.warningAmber : AppColors.successGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(result.summary, style: const TextStyle(color: AppColors.textSecondary)),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.paddingS),
            ...result.errors.take(5).map((error) => Text(
                  '  - $error',
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                )),
            if (result.errors.length > 5)
              Text(
                '  ...and ${result.errors.length - 5} more errors',
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, fontStyle: FontStyle.italic),
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
            child: Text(_errorMessage!, style: const TextStyle(color: AppColors.errorRed)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.errorRed),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryList() {
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
                      'Pre-Sale Entries',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Tier filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundInput,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterTier,
                          dropdownColor: AppColors.backgroundCard,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Tiers')),
                            DropdownMenuItem(value: 'platinum', child: Text('Platinum')),
                            DropdownMenuItem(value: 'gold', child: Text('Gold')),
                            DropdownMenuItem(value: 'silver', child: Text('Silver')),
                          ],
                          onChanged: (v) {
                            setState(() => _filterTier = v ?? 'all');
                            _filterEntries();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingM),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search emails...',
                    hintStyle: const TextStyle(color: AppColors.textTertiary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.backgroundInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          StreamBuilder<List<PreSaleEntry>>(
            stream: _preSaleService.watchEntries(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: AppColors.richGold)),
                );
              }

              _allEntries = snapshot.data ?? [];
              // Apply filter
              final query = _searchController.text.toLowerCase();
              _filteredEntries = _allEntries.where((entry) {
                final matchesSearch = query.isEmpty || entry.email.toLowerCase().contains(query);
                final matchesTier = _filterTier == 'all' || entry.tier.value == _filterTier;
                return matchesSearch && matchesTier;
              }).toList();

              if (_filteredEntries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 48, color: AppColors.textTertiary.withValues(alpha: 0.5)),
                        const SizedBox(height: AppDimensions.paddingM),
                        Text(
                          _searchController.text.isNotEmpty || _filterTier != 'all'
                              ? 'No matching entries found'
                              : 'No pre-sale entries yet.\nUpload a CSV to get started.',
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredEntries.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                itemBuilder: (context, index) {
                  final entry = _filteredEntries[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _tierColor(entry.tier).withValues(alpha: 0.15),
                      child: Icon(
                        Icons.workspace_premium,
                        color: _tierColor(entry.tier),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      entry.email,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _tierColor(entry.tier).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            entry.tier.displayName,
                            style: TextStyle(
                              color: _tierColor(entry.tier),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.numberOfDays} days',
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                      onPressed: () => _removeEntry(entry.email),
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
            Text('Pre-Sale Info', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CSV Format',
              style: TextStyle(color: AppColors.richGold, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundInput,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'EMAIL,NUMBER_OF_DAYS,TIER\njohn@email.com,365,platinum\njane@email.com,180,gold\nbob@email.com,30,silver',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tier Countdown Dates',
              style: TextStyle(color: AppColors.richGold, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.workspace_premium, AppColors.richGold, 'Platinum', 'March 14, 2026'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.workspace_premium, Colors.amber, 'Gold', 'March 28, 2026'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.workspace_premium, Colors.grey, 'Silver', 'April 7, 2026'),
            const SizedBox(height: 16),
            const Text(
              'How it works',
              style: TextStyle(color: AppColors.richGold, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. User registers with email\n'
              '2. App checks pre-sale list\n'
              '3. Countdown shows tier date\n'
              '4. After countdown: subscription activates\n'
              '5. Duration = NUMBER_OF_DAYS from list\n'
              '6. Base membership = same expiry',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
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
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
