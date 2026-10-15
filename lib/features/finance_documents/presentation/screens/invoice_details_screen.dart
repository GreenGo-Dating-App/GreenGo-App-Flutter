import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/country_flag_helper.dart';
import '../../../../core/utils/country_names_l10n.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/billing_profile_repository.dart';
import '../../domain/billing_profile.dart';
import '../bloc/billing_profile_cubit.dart';

/// Profile > Business > Invoice details: who GreenGo's fee invoices (and the
/// Brazilian NFS-e) are issued to — a private person or a company, with the
/// country's tax id and a full billing address. The server validates every
/// field (checksums included) and stores the tax id server-only; this screen
/// shows it masked and only sends a new one when the user types it.
class InvoiceDetailsScreen extends StatefulWidget {
  const InvoiceDetailsScreen({this.repository, super.key});

  /// Injectable for tests.
  final BillingProfileRepository? repository;

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  late final BillingProfileCubit _cubit = BillingProfileCubit(widget.repository ?? BillingProfileRepository())..load();

  BillingType _type = BillingType.private;
  String _country = 'BR';
  bool _prefilled = false;
  bool _changingTaxId = false;

  final _legalName = TextEditingController();
  final _tradeName = TextEditingController();
  final _contactPerson = TextEditingController();
  final _taxId = TextEditingController();
  final _im = TextEditingController();
  final _ie = TextEditingController();
  final _street = TextEditingController();
  final _number = TextEditingController();
  final _complement = TextEditingController();
  final _district = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();
  final _postal = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  List<TextEditingController> get _all => [
        _legalName, _tradeName, _contactPerson, _taxId, _im, _ie, _street, _number, _complement, _district, _city,
        _region, _postal, _email, _phone,
      ];

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    _cubit.close();
    super.dispose();
  }

  void _prefill(BillingProfile? p) {
    if (_prefilled) return;
    _prefilled = true;
    if (p == null) return;
    _type = p.type;
    if (p.country.length == 2) _country = p.country;
    _legalName.text = p.legalName;
    _tradeName.text = p.tradeName;
    _contactPerson.text = p.contactPerson;
    _im.text = p.inscricaoMunicipal;
    _ie.text = p.inscricaoEstadual;
    final a = p.address;
    if (a != null) {
      _street.text = a.street;
      _number.text = a.number;
      _complement.text = a.complement;
      _district.text = a.district;
      _city.text = a.city;
      _region.text = a.region;
      _postal.text = a.postalCode;
    }
    _email.text = p.email;
    _phone.text = p.phone;
  }

  /// The saved (masked) tax id still applies: same country and type, and the
  /// user did not ask to replace it.
  bool _keepsSavedTaxId(BillingProfile? p) =>
      p != null && p.hasTaxId && p.country == _country && p.type == _type && !_changingTaxId;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _cubit.save(BillingDraft(
      type: _type,
      country: _country,
      legalName: _legalName.text,
      tradeName: _tradeName.text,
      contactPerson: _contactPerson.text,
      taxId: _keepsSavedTaxId(_cubit.state.data.profile) ? '' : _taxId.text,
      inscricaoMunicipal: _im.text,
      inscricaoEstadual: _ie.text,
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
      email: _email.text,
      phone: _phone.text,
    ));
    if (!mounted) return;
    if (ok) {
      setState(() {
        _changingTaxId = false;
        _taxId.clear();
      });
      messenger.showSnackBar(SnackBar(content: Text(l10n.financeBillingSaved)));
    } else if (_cubit.state.fieldError != null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.financeBillingFixField)));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l10n.financeBillingSaveError)));
    }
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
        title: Text(
          l10n.financeBillingTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: BlocBuilder<BillingProfileCubit, BillingProfileState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state.status == BillingLoadStatus.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.richGold));
          }
          if (state.status == BillingLoadStatus.failed) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, color: AppColors.textTertiary, size: 40),
                  const SizedBox(height: 12),
                  Text(l10n.financeBillingLoadError, style: const TextStyle(color: AppColors.textSecondary)),
                  TextButton(onPressed: _cubit.load, child: Text(l10n.financeDocsRetry)),
                ],
              ),
            );
          }
          _prefill(state.data.profile);
          return _form(context, l10n, state);
        },
      ),
    );
  }

  Widget _form(BuildContext context, AppLocalizations l10n, BillingProfileState state) {
    final company = _type == BillingType.company;
    final profile = state.data.profile;
    final keepTax = _keepsSavedTaxId(profile);
    final label = taxIdLabelFor(_country, _type);
    final postalHint = postalCodeHint(_country);

    String? err(String field) {
      final e = state.fieldError;
      if (e == null || e.field != field) return null;
      switch (e.code) {
        case BillingErrorCode.required:
          return l10n.financeBillingErrorRequired;
        case BillingErrorCode.tooLong:
          return l10n.financeBillingErrorTooLong;
        case BillingErrorCode.invalid:
          if (field == 'taxId') return l10n.financeBillingErrorTaxId;
          if (field == 'email') return l10n.financeBillingErrorEmail;
          if (field == 'address.postalCode' && postalHint != null) return l10n.financeBillingErrorPostal(postalHint);
          return l10n.financeBillingErrorInvalid;
      }
    }

    Widget field(String name, TextEditingController c, String labelText,
        {String? hint, String? helper, TextInputType? keyboard, TextCapitalization caps = TextCapitalization.words, Key? key}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          key: key ?? ValueKey('billing-$name'),
          controller: c,
          keyboardType: keyboard,
          textCapitalization: caps,
          style: const TextStyle(color: AppColors.textPrimary),
          onChanged: (_) => _cubit.clearFieldError(name),
          decoration: _decoration(labelText, hint: hint, helper: helper, error: err(name)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      children: [
        Text(l10n.financeBillingIntro, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
        const SizedBox(height: 16),
        SegmentedButton<BillingType>(
          key: const ValueKey('billing-type'),
          segments: [
            ButtonSegment(value: BillingType.private, label: Text(l10n.financeBillingTypePrivate), icon: const Icon(Icons.person_outline)),
            ButtonSegment(value: BillingType.company, label: Text(l10n.financeBillingTypeCompany), icon: const Icon(Icons.business_outlined)),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() => _type = s.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.richGold.withValues(alpha: 0.2),
            selectedForegroundColor: AppColors.richGold,
            foregroundColor: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _countryPicker(l10n, err('country')),
        const SizedBox(height: 12),
        field('legalName', _legalName, company ? l10n.financeBillingLegalNameCompany : l10n.financeBillingLegalNamePrivate),
        if (company) field('tradeName', _tradeName, l10n.financeBillingTradeName),
        if (keepTax)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              key: const ValueKey('billing-taxid-saved'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: AppColors.backgroundCard, borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_taxIdLabel(l10n, label), style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(l10n.financeBillingTaxIdSaved(profile!.taxIdMasked),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                      ],
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('billing-taxid-change'),
                    onPressed: () => setState(() => _changingTaxId = true),
                    child: Text(l10n.financeBillingTaxIdChange),
                  ),
                ],
              ),
            ),
          )
        else
          field('taxId', _taxId, _taxIdLabel(l10n, label),
              caps: TextCapitalization.characters,
              helper: taxIdOptional(_country, _type)
                  ? l10n.financeBillingSsnNote
                  : (profile != null && profile.hasTaxId && profile.country == _country && profile.type == _type
                      ? l10n.financeBillingTaxIdKeepHint
                      : null)),
        if (company && _country == 'BR') ...[
          field('inscricaoMunicipal', _im, l10n.financeBillingInscricaoMunicipal, keyboard: TextInputType.number),
          field('inscricaoEstadual', _ie, l10n.financeBillingInscricaoEstadual, caps: TextCapitalization.characters),
        ],
        if (company) field('contactPerson', _contactPerson, l10n.financeBillingContactPerson),
        const SizedBox(height: 8),
        _section(l10n.financeBillingAddressSection),
        field('address.street', _street, l10n.financeBillingStreet),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field('address.number', _number, l10n.financeBillingNumber, caps: TextCapitalization.characters)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: field('address.complement', _complement, l10n.financeBillingComplement)),
          ],
        ),
        field('address.district', _district, l10n.financeBillingDistrict),
        field('address.city', _city, l10n.financeBillingCity),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: field('address.region', _region,
                  regionRequired(_country) ? l10n.financeBillingRegionCode : l10n.financeBillingRegion,
                  caps: regionRequired(_country) ? TextCapitalization.characters : TextCapitalization.words),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: field('address.postalCode', _postal, l10n.financeBillingPostalCode,
                  hint: postalHint, caps: TextCapitalization.characters),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _section(l10n.financeBillingContactSection),
        field('email', _email, l10n.financeBillingEmail, keyboard: TextInputType.emailAddress, caps: TextCapitalization.none),
        field('phone', _phone, l10n.financeBillingPhone, keyboard: TextInputType.phone, caps: TextCapitalization.none),
        const SizedBox(height: 8),
        Text(l10n.financeBillingPrivacy, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.4)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const ValueKey('billing-save'),
            onPressed: state.saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
            ),
            child: state.saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text(l10n.financeBillingSave, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.financeBillingFutureOnly,
            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _countryPicker(AppLocalizations l10n, String? error) {
    final others = CountryFlagHelper.allCountries
        .map((c) => c.isoCode)
        .where((c) => !kPriorityBillingCountries.contains(c))
        .toList()
      ..sort((a, b) => localizedCountryName(l10n, a).compareTo(localizedCountryName(l10n, b)));
    final codes = [...kPriorityBillingCountries, ...others];
    return DropdownButtonFormField<String>(
      key: const ValueKey('billing-country'),
      initialValue: codes.contains(_country) ? _country : 'BR',
      isExpanded: true,
      menuMaxHeight: 420,
      dropdownColor: AppColors.backgroundCard,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: _decoration(l10n.financeBillingCountry, error: error),
      items: [
        for (final c in codes)
          DropdownMenuItem(
            value: c,
            child: Text('${CountryFlagHelper.getFlag(c)}  ${localizedCountryName(l10n, c)}', overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        if (v == null) return;
        _cubit.clearFieldError('country');
        setState(() => _country = v);
      },
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title, style: const TextStyle(color: AppColors.richGold, fontSize: 15, fontWeight: FontWeight.w700)),
      );

  InputDecoration _decoration(String label, {String? hint, String? helper, String? error}) => InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 3,
        errorText: error,
        errorMaxLines: 2,
        filled: true,
        fillColor: AppColors.backgroundCard,
        labelStyle: const TextStyle(color: AppColors.textTertiary),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        helperStyle: const TextStyle(color: AppColors.textTertiary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusM), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.richGold),
        ),
      );
}

String _taxIdLabel(AppLocalizations l10n, TaxIdLabel label) => switch (label) {
      TaxIdLabel.cpf => l10n.financeBillingTaxIdCpf,
      TaxIdLabel.cnpj => l10n.financeBillingTaxIdCnpj,
      TaxIdLabel.codiceFiscale => l10n.financeBillingTaxIdCodiceFiscale,
      TaxIdLabel.partitaIva => l10n.financeBillingTaxIdPartitaIva,
      TaxIdLabel.nifPt => l10n.financeBillingTaxIdNifPt,
      TaxIdLabel.nipc => l10n.financeBillingTaxIdNipc,
      TaxIdLabel.nifNie => l10n.financeBillingTaxIdNifNie,
      TaxIdLabel.cifNif => l10n.financeBillingTaxIdCifNif,
      TaxIdLabel.steuerId => l10n.financeBillingTaxIdSteuerId,
      TaxIdLabel.frSpi => l10n.financeBillingTaxIdFrSpi,
      TaxIdLabel.ssnItin => l10n.financeBillingTaxIdSsnItin,
      TaxIdLabel.ein => l10n.financeBillingTaxIdEin,
      TaxIdLabel.vat => l10n.financeBillingTaxIdVat,
      TaxIdLabel.generic => l10n.financeBillingTaxIdGeneric,
      TaxIdLabel.genericCompany => l10n.financeBillingTaxIdGenericCompany,
    };
