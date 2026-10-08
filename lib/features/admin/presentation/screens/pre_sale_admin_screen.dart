import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/pre_sale_service.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';

/// Admin screen for managing the pre-sale tier list.
/// - Upload CSV files with headers: EMAIL, NUMBER_OF_DAYS, TIER
/// - View and manage existing entries
/// - Filter by tier
/// - Remove entries
class PreSaleAdminScreen extends StatefulWidget {

  const PreSaleAdminScreen({
    required this.adminId, super.key,
  });
  final String adminId;

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
    final l10n = AppLocalizations.of(context)!;
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
          _errorMessage = l10n.adminPreSaleCsvEmpty;
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
          _errorMessage = l10n
              .adminPreSaleCsvMissingHeaders('EMAIL, NUMBER_OF_DAYS, TIER', headers.join(', ')); // i18n-ignore: CSV column names
          _isUploading = false;
        });
        return;
      }

      // Parse data rows
      final rows = <Map<String, String>>[];
      for (var i = 1; i < lines.length; i++) {
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
          _errorMessage = l10n.adminPreSaleCsvNoRows;
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
            content: Text(importResult.localizedSummary(l10n)),
            backgroundColor: importResult.hasErrors
                ? AppColors.warningAmber
                : AppColors.successGreen,
          ),
        );
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      showUserError(context, e, stackTrace: st);
    }
  }

  Future<void> _addSingleEntry() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    final days = int.tryParse(_daysController.text.trim());
    if (days == null || days <= 0) {
      setState(() => _errorMessage = l10n.adminPreSaleInvalidDays);
      return;
    }

    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = l10n.adminPleaseEnterValidEmail);
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
            content: Text(l10n.adminPreSaleEntryAdded(
                email, _tierLabel(l10n, _selectedTier), days)),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e, st) {
      if (mounted) showUserError(context, e, stackTrace: st);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeEntry(String email) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          AppLocalizations.of(context)!.adminPreSaleRemoveEntryTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context)!.adminPreSaleRemoveEntryConfirm(email),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: Text(AppLocalizations.of(context)!.adminRemove),
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
            content: Text(l10n.adminPreSaleEntryRemoved(email)),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showUserError(context, e);
      }
    }
  }

  String _tierLabel(AppLocalizations l10n, PreSaleTier tier) {
    switch (tier) {
      case PreSaleTier.platinum:
        return l10n.platinum;
      case PreSaleTier.gold:
        return l10n.gold;
      case PreSaleTier.silver:
        return l10n.silver;
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(
          l10n.adminPreSaleTitle,
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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
    final l10n = AppLocalizations.of(context)!;
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
                Text(
                  l10n.adminPreSaleProgramTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.adminPreSaleProgramDescription,
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
    final l10n = AppLocalizations.of(context)!;
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
                l10n.adminUploadCsvFile,
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
            l10n.adminPreSaleCsvFormatHint('EMAIL, NUMBER_OF_DAYS, TIER', 'platinum, gold, silver'), // i18n-ignore: CSV column names/values
            style: const TextStyle(
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
              label: Text(_isUploading ? l10n.adminUploading : l10n.adminSelectCsvFile),
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
    final l10n = AppLocalizations.of(context)!;
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
                l10n.adminPreSaleAddSingleEntry,
                style: const TextStyle(
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
              hintText: l10n.adminEnterEmailAddress,
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
                    hintText: l10n.days,
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
                              Text(_tierLabel(l10n, tier)),
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
                    : Text(l10n.adminAdd),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportResultCard() {
    final l10n = AppLocalizations.of(context)!;
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
                l10n.adminImportResult,
                style: TextStyle(
                  color: result.hasErrors ? AppColors.warningAmber : AppColors.successGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(result.localizedSummary(l10n), style: const TextStyle(color: AppColors.textSecondary)),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.paddingS),
            ...result.errors.take(5).map((error) => Text(
                  '  - $error',
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                )),
            if (result.errors.length > 5)
              Text(
                '  ${l10n.adminMoreErrors(result.errors.length - 5)}',
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
    final l10n = AppLocalizations.of(context)!;
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
                      l10n.adminPreSaleEntries,
                      style: const TextStyle(
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
                          items: [
                            DropdownMenuItem(value: 'all', child: Text(l10n.adminPreSaleAllTiers)),
                            DropdownMenuItem(value: 'platinum', child: Text(l10n.platinum)),
                            DropdownMenuItem(value: 'gold', child: Text(l10n.gold)),
                            DropdownMenuItem(value: 'silver', child: Text(l10n.silver)),
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
                    hintText: l10n.adminSearchEmails,
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
                              ? l10n.adminPreSaleNoMatching
                              : l10n.adminPreSaleEmpty,
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
                            _tierLabel(l10n, entry.tier),
                            style: TextStyle(
                              color: _tierColor(entry.tier),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.adminPreSaleDaysCount(entry.numberOfDays),
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
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    String fmt(DateTime d) => DateFormat.yMMMMd(locale).format(d);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.richGold),
            const SizedBox(width: 8),
            Text(l10n.adminPreSaleInfoTitle, style: const TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.adminPreSaleCsvFormatTitle,
              style: const TextStyle(color: AppColors.richGold, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundInput,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'EMAIL,NUMBER_OF_DAYS,TIER\njohn@email.com,365,platinum\njane@email.com,180,gold\nbob@email.com,30,silver', // i18n-ignore: CSV format example
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.adminPreSaleCountdownDates,
              style: const TextStyle(color: AppColors.richGold, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.workspace_premium, AppColors.richGold, l10n.platinum, fmt(DateTime(2026, 3, 14))),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.workspace_premium, Colors.amber, l10n.gold, fmt(DateTime(2026, 3, 28))),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.workspace_premium, Colors.grey, l10n.silver, fmt(DateTime(2026, 4, 7))),
            const SizedBox(height: 16),
            Text(
              l10n.adminPreSaleHowItWorks,
              style: const TextStyle(color: AppColors.richGold, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.adminPreSaleHowItWorksSteps,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
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
