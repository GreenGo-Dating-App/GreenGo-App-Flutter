import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/country_flag_helper.dart';
import '../../../../generated/app_localizations.dart';

/// Screen for selecting primary and secondary origin countries.
class EditOriginScreen extends StatefulWidget {
  final String? initialPrimary;
  final String? initialSecondary;
  final void Function(String? primary, String? secondary) onSave;

  const EditOriginScreen({
    super.key,
    this.initialPrimary,
    this.initialSecondary,
    required this.onSave,
  });

  @override
  State<EditOriginScreen> createState() => _EditOriginScreenState();
}

class _EditOriginScreenState extends State<EditOriginScreen> {
  String? _primary;
  String? _secondary;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _primary = widget.initialPrimary;
    _secondary = widget.initialSecondary;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Country> get _filteredCountries {
    if (_searchQuery.isEmpty) return CountryFlagHelper.allCountries;
    final q = _searchQuery.toLowerCase();
    return CountryFlagHelper.allCountries
        .where((c) => c.name.toLowerCase().contains(q))
        .toList();
  }

  void _save() {
    widget.onSave(_primary, _secondary);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Origin',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.richGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Selected origins display
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.backgroundCard,
            child: Row(
              children: [
                Expanded(
                  child: _OriginChip(
                    label: 'Primary Origin',
                    isoCode: _primary,
                    onClear: () => setState(() => _primary = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OriginChip(
                    label: 'Secondary (optional)',
                    isoCode: _secondary,
                    onClear: () => setState(() => _secondary = null),
                  ),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search countries...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // Country list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final flag = CountryFlagHelper.getFlag(country.isoCode);
                final isPrimary = _primary == country.isoCode;
                final isSecondary = _secondary == country.isoCode;

                return ListTile(
                  leading: Text(flag, style: const TextStyle(fontSize: 28)),
                  title: Text(
                    country.name,
                    style: TextStyle(
                      color: isPrimary || isSecondary
                          ? AppColors.richGold
                          : AppColors.textPrimary,
                      fontWeight: isPrimary || isSecondary
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isPrimary
                      ? const Icon(Icons.check_circle, color: AppColors.richGold)
                      : isSecondary
                          ? const Icon(Icons.check_circle_outline, color: AppColors.richGold)
                          : null,
                  onTap: () {
                    setState(() {
                      if (isPrimary) {
                        _primary = null;
                      } else if (isSecondary) {
                        _secondary = null;
                      } else if (_primary == null) {
                        _primary = country.isoCode;
                      } else {
                        _secondary = country.isoCode;
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OriginChip extends StatelessWidget {
  final String label;
  final String? isoCode;
  final VoidCallback onClear;

  const _OriginChip({
    required this.label,
    this.isoCode,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (isoCode == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    final flag = CountryFlagHelper.getFlag(isoCode!);
    final name = CountryFlagHelper.allCountries
        .where((c) => c.isoCode == isoCode)
        .map((c) => c.name)
        .firstOrNull ?? isoCode!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.richGold.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 16, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
