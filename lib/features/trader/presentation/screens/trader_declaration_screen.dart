import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/country_flag_helper.dart';
import '../../../../core/utils/country_names_l10n.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../generated/app_localizations.dart';
import '../../../finance_documents/data/billing_profile_repository.dart';
import '../../../finance_documents/domain/billing_profile.dart';
import '../../data/trader_repository.dart';
import '../../domain/trader_declaration.dart';

/// Business Center > Settings > Trader status (Terms 12.4, DSA art. 30):
/// "Do you sell as a trader?" Traders give name, address, phone, email, an
/// ID / registration number, the trade register (if any) and self-certify
/// that they offer only compliant products and services. Invoice details,
/// when filled in, prefill everything (the tax id stays on the server).
class TraderDeclarationScreen extends StatefulWidget {
  const TraderDeclarationScreen({this.repository, super.key});

  /// Injectable for tests.
  final TraderRepository? repository;

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const TraderDeclarationScreen()));

  @override
  State<TraderDeclarationScreen> createState() => _TraderDeclarationScreenState();
}

class _TraderDeclarationScreenState extends State<TraderDeclarationScreen> {
  late final TraderRepository _repo = widget.repository ?? TraderRepository();

  TraderStatus? _status;
  bool _loading = true;
  bool _loadFailed = false;
  bool _saving = false;
  BillingFieldError? _error;

  bool? _isTrader;
  bool _selfCertified = false;
  String _country = 'BR';

  final _name = TextEditingController();
  final _street = TextEditingController();
  final _number = TextEditingController();
  final _complement = TextEditingController();
  final _district = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();
  final _postal = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _idNumber = TextEditingController();
  final _register = TextEditingController();
  final _registerNumber = TextEditingController();

  List<TextEditingController> get _all => [
        _name, _street, _number, _complement, _district, _city, _region, _postal, _phone, _email,
        _idNumber, _register, _registerNumber,
      ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final s = await _repo.get();
      if (!mounted) return;
      _prefill(s);
      setState(() {
        _status = s;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _fillAddress(BillingAddress? a) {
    if (a == null) return;
    _street.text = a.street;
    _number.text = a.number;
    _complement.text = a.complement;
    _district.text = a.district;
    _city.text = a.city;
    _region.text = a.region;
    _postal.text = a.postalCode;
    if (a.country.length == 2) _country = a.country;
  }

  void _prefill(TraderStatus s) {
    final d = s.declaration;
    if (d != null) {
      _isTrader = d.isTrader;
      _selfCertified = d.selfCertified;
      _name.text = d.name;
      _fillAddress(d.address);
      _phone.text = d.phone;
      _email.text = d.email;
      _register.text = d.tradeRegister;
      _registerNumber.text = d.tradeRegisterNumber;
      return;
    }
    _useBilling(s.billing);
  }

  void _useBilling(TraderBillingPrefill? b) {
    if (b == null) return;
    if (b.legalName.isNotEmpty) _name.text = b.legalName;
    _fillAddress(b.address);
    if (b.email.isNotEmpty) _email.text = b.email;
    if (b.phone.isNotEmpty) _phone.text = b.phone;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final isTrader = _isTrader;
    if (isTrader == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repo.save(TraderDraft(
        isTrader: isTrader,
        name: _name.text,
        address: BillingAddress(
          street: _street.text,
          number: _number.text,
          complement: _complement.text,
          district: _district.text,
          city: _city.text,
          region: _region.text,
          postalCode: _postal.text,
          country: _country,
        ),
        phone: _phone.text,
        email: _email.text,
        idNumber: _idNumber.text,
        tradeRegister: _register.text,
        tradeRegisterNumber: _registerNumber.text,
        selfCertified: _selfCertified,
      ));
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.traderSaved)));
      SafeNavigation.pop(context);
    } on BillingValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.error;
      });
      messenger.showSnackBar(SnackBar(content: Text(l10n.financeBillingFixField)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.financeBillingSaveError)));
    }
  }

  String? _err(AppLocalizations l10n, String field) {
    final e = _error;
    if (e == null || e.field != field) return null;
    return switch (e.code) {
      BillingErrorCode.required => l10n.financeBillingErrorRequired,
      BillingErrorCode.tooLong => l10n.financeBillingErrorTooLong,
      BillingErrorCode.invalid =>
        field == 'email' ? l10n.financeBillingErrorEmail : l10n.financeBillingErrorInvalid,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => SafeNavigation.pop(context),
        ),
        title: Text(l10n.traderTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.richGold))
          : _loadFailed
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off, color: AppColors.textTertiary, size: 40),
                    const SizedBox(height: 12),
                    Text(l10n.financeBillingLoadError, style: const TextStyle(color: AppColors.textSecondary)),
                    TextButton(onPressed: _load, child: Text(l10n.financeDocsRetry)),
                  ]),
                )
              : _form(l10n),
    );
  }

  Widget _field(AppLocalizations l10n, String name, TextEditingController c, String label,
          {String? helper, TextInputType? keyboard, TextCapitalization caps = TextCapitalization.words}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          key: ValueKey('trader-$name'),
          controller: c,
          keyboardType: keyboard,
          textCapitalization: caps,
          style: const TextStyle(color: AppColors.textPrimary),
          onChanged: (_) {
            if (_error?.field == name) setState(() => _error = null);
          },
          decoration: _decoration(label, helper: helper, error: _err(l10n, name)),
        ),
      );

  Widget _form(AppLocalizations l10n) {
    final billing = _status?.billing;
    final trader = _isTrader == true;
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      children: [
        Text(l10n.traderIntro, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
        const SizedBox(height: 16),
        Text(l10n.traderQuestion,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        RadioListTile<bool>(
          key: const ValueKey('trader-yes'),
          value: true,
          groupValue: _isTrader,
          activeColor: AppColors.richGold,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.traderYes, style: const TextStyle(color: AppColors.textPrimary)),
          onChanged: (v) => setState(() => _isTrader = v),
        ),
        RadioListTile<bool>(
          key: const ValueKey('trader-no'),
          value: false,
          groupValue: _isTrader,
          activeColor: AppColors.richGold,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.traderNo, style: const TextStyle(color: AppColors.textPrimary)),
          subtitle: Text(l10n.traderNoHint, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          onChanged: (v) => setState(() => _isTrader = v),
        ),
        if (trader) ...[
          if (billing != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('trader-use-billing'),
                onPressed: () => setState(() => _useBilling(billing)),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: Text(l10n.traderUseBilling),
              ),
            ),
          const SizedBox(height: 8),
          _field(l10n, 'name', _name, l10n.traderName),
          _countryPicker(l10n),
          const SizedBox(height: 12),
          _field(l10n, 'address.street', _street, l10n.financeBillingStreet),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: _field(l10n, 'address.number', _number, l10n.financeBillingNumber,
                    caps: TextCapitalization.characters)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _field(l10n, 'address.complement', _complement, l10n.financeBillingComplement)),
          ]),
          _field(l10n, 'address.district', _district, l10n.financeBillingDistrict),
          _field(l10n, 'address.city', _city, l10n.financeBillingCity),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _field(l10n, 'address.region', _region, l10n.financeBillingRegion)),
            const SizedBox(width: 12),
            Expanded(
                child: _field(l10n, 'address.postalCode', _postal, l10n.financeBillingPostalCode,
                    caps: TextCapitalization.characters)),
          ]),
          _field(l10n, 'phone', _phone, l10n.financeBillingPhone,
              keyboard: TextInputType.phone, caps: TextCapitalization.none),
          _field(l10n, 'email', _email, l10n.financeBillingEmail,
              keyboard: TextInputType.emailAddress, caps: TextCapitalization.none),
          _field(l10n, 'idNumber', _idNumber, l10n.traderIdNumber,
              caps: TextCapitalization.characters,
              helper: [
                if ((_status?.declaration?.idNumberMasked ?? '').isNotEmpty)
                  l10n.financeBillingTaxIdSaved(_status!.declaration!.idNumberMasked),
                if (billing?.hasTaxId == true) l10n.traderIdNumberBillingHint else l10n.traderIdNumberHint,
              ].join('\n')),
          _field(l10n, 'tradeRegister', _register, l10n.traderRegister),
          _field(l10n, 'tradeRegisterNumber', _registerNumber, l10n.traderRegisterNumber,
              caps: TextCapitalization.characters),
          CheckboxListTile(
            key: const ValueKey('trader-self-certify'),
            value: _selfCertified,
            activeColor: AppColors.richGold,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(l10n.traderSelfCertify, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            subtitle: _err(l10n, 'selfCertified') == null
                ? null
                : Text(_err(l10n, 'selfCertified')!, style: const TextStyle(color: AppColors.errorRed, fontSize: 12)),
            onChanged: (v) => setState(() => _selfCertified = v ?? false),
          ),
          const SizedBox(height: 4),
          Text(l10n.traderPublicNote, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.4)),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const ValueKey('trader-save'),
            onPressed: _saving || _isTrader == null || (trader && !_selfCertified) ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text(l10n.financeBillingSave, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _countryPicker(AppLocalizations l10n) {
    final others = CountryFlagHelper.allCountries
        .map((c) => c.isoCode)
        .where((c) => !kPriorityBillingCountries.contains(c))
        .toList()
      ..sort((a, b) => localizedCountryName(l10n, a).compareTo(localizedCountryName(l10n, b)));
    final codes = [...kPriorityBillingCountries, ...others];
    return DropdownButtonFormField<String>(
      key: const ValueKey('trader-country'),
      initialValue: codes.contains(_country) ? _country : 'BR',
      isExpanded: true,
      menuMaxHeight: 420,
      dropdownColor: AppColors.backgroundCard,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: _decoration(l10n.financeBillingCountry, error: _err(l10n, 'address.country')),
      items: [
        for (final c in codes)
          DropdownMenuItem(
            value: c,
            child: Text('${CountryFlagHelper.getFlag(c)}  ${localizedCountryName(l10n, c)}',
                overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _country = v);
      },
    );
  }

  InputDecoration _decoration(String label, {String? helper, String? error}) => InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 4,
        errorText: error,
        errorMaxLines: 2,
        filled: true,
        fillColor: AppColors.backgroundCard,
        labelStyle: const TextStyle(color: AppColors.textTertiary),
        helperStyle: const TextStyle(color: AppColors.textTertiary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusM), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.richGold),
        ),
      );
}
