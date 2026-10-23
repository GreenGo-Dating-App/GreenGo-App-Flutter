import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/dial_codes.dart';
import '../../../../core/utils/country_flag_helper.dart';
import '../../../../core/utils/country_names_l10n.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/business_contact_phone.dart';
import '../../../../core/services/sound_feedback.dart';

/// Business Center: the optional business contact number (any country,
/// landline allowed, not SMS-verified) + "Show on my storefront" switch.
/// Private unless the switch is on. Saved by its own button.
class BusinessContactPhoneSection extends StatefulWidget {
  const BusinessContactPhoneSection({
    required this.userId,
    this.defaultCountry,
    this.repository,
    super.key,
  });

  final String userId;

  /// ISO code preselected when no number is saved yet (e.g. the profile's
  /// origin country).
  final String? defaultCountry;
  final BusinessContactPhoneRepository? repository;

  @override
  State<BusinessContactPhoneSection> createState() =>
      _BusinessContactPhoneSectionState();
}

class _BusinessContactPhoneSectionState
    extends State<BusinessContactPhoneSection> {
  late final BusinessContactPhoneRepository _repo =
      widget.repository ?? BusinessContactPhoneRepository();
  final TextEditingController _number = TextEditingController();
  String _country = 'US';
  bool _show = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.defaultCountry?.toUpperCase();
    if (d != null && kDialCodes.containsKey(d)) _country = d;
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = await _repo.load(widget.userId);
      if (!mounted) return;
      setState(() {
        final phone = saved.phone;
        if (phone != null) {
          final iso = isoForE164(phone, preferred: _country);
          if (iso != null) {
            _country = iso;
            _number.text = phone.substring(kDialCodes[iso]!.length);
          } else {
            _number.text = phone;
          }
        }
        _show = saved.show;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final phone =
        normalizeBusinessContactPhone(kDialCodes[_country]!, _number.text);
    if (phone == null) {
      setState(() => _error = l10n.businessContactPhoneInvalid);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await _repo.save(widget.userId,
          phone: phone.isEmpty ? null : phone, show: _show && phone.isNotEmpty);
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (phone.isEmpty) _show = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.businessContactPhoneSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showUserErrorMessage(context, l10n.businessContactPhoneSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.richGold),
          ),
        ),
      );
    }
    final countries = kDialCodes.keys.toList()
      ..sort((a, b) => localizedCountryName(l10n, a)
          .compareTo(localizedCountryName(l10n, b)));
    return Column(
      key: const ValueKey('business-contact-phone-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.businessContactPhoneLabel,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.businessContactPhoneHelper,
          style: const TextStyle(
              color: AppColors.textTertiary, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundInput,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const ValueKey('business-contact-phone-country'),
                  value: _country,
                  isDense: true,
                  dropdownColor: AppColors.backgroundCard,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  selectedItemBuilder: (_) => countries
                      .map((c) => Center(
                            child: Text(
                              '${CountryFlagHelper.getFlag(c)} ${kDialCodes[c]}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 15),
                            ),
                          ))
                      .toList(),
                  items: countries
                      .map((c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              '${CountryFlagHelper.getFlag(c)}  '
                              '${localizedCountryName(l10n, c)}  ${kDialCodes[c]}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 14),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _country = v);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const ValueKey('business-contact-phone-number'),
                controller: _number,
                keyboardType: TextInputType.phone,
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: l10n.businessContactPhoneHint,
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  errorText: _error,
                  filled: true,
                  fillColor: AppColors.backgroundInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
            ),
          ],
        ),
        SwitchListTile(
          key: const ValueKey('business-contact-phone-show'),
          contentPadding: EdgeInsets.zero,
          value: _show,
          activeColor: AppColors.deepBlack,
          activeTrackColor: AppColors.richGold,
          title: Text(
            l10n.businessContactPhoneShowOnStorefront,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
          subtitle: Text(
            l10n.businessContactPhoneShowHint,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
          onChanged: withToggleSound((v) => setState(() => _show = v)),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const ValueKey('business-contact-phone-save'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.richGold),
                  )
                : Text(
                    l10n.businessContactPhoneSave,
                    style: const TextStyle(
                        color: AppColors.richGold,
                        fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}
