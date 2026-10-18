import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/country_flag_helper.dart';
import '../../../../core/utils/country_names_l10n.dart';
import '../../../../core/utils/user_error.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/services/identity_details_service.dart';

/// Manual entry of the details printed on an ID document (no OCR: the
/// text-recognition plugin is not a dependency). Used OPTIONALLY next to
/// every ID-document upload and, pre-filled, by the reviewer.
class IdentityDetailsForm extends StatefulWidget {
  const IdentityDetailsForm({
    required this.onSubmit,
    required this.submitLabel,
    this.initial,
    this.showIntro = true,
    super.key,
  });

  final IdentityDetails? initial;
  final String submitLabel;
  final bool showIntro;

  /// Called with valid details. A thrown error keeps the form open.
  final Future<void> Function(IdentityDetails details) onSubmit;

  @override
  State<IdentityDetailsForm> createState() => IdentityDetailsFormState();
}

class IdentityDetailsFormState extends State<IdentityDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _first;
  late final TextEditingController _surname;
  late final TextEditingController _number;
  DateTime? _dob;
  String? _docType;
  String? _country;
  bool _busy = false;

  static final _docNumber = RegExp(r'^[A-Za-z0-9<\- ]{3,40}$');

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _first = TextEditingController(text: i?.firstName ?? '');
    _surname = TextEditingController(text: i?.surname ?? '');
    _number = TextEditingController(text: i?.docNumber ?? '');
    _dob = i?.dateOfBirth;
    _docType = i?.docType;
    _country = (i?.issuingCountry.isNotEmpty ?? false)
        ? i!.issuingCountry.toUpperCase()
        : null;
  }

  @override
  void dispose() {
    _first.dispose();
    _surname.dispose();
    _number.dispose();
    super.dispose();
  }

  /// The current details when the form is valid, else null (shows errors).
  IdentityDetails? validated() {
    if (!(_formKey.currentState?.validate() ?? false)) return null;
    return IdentityDetails(
      firstName: _first.text,
      surname: _surname.text,
      dateOfBirth: _dob!,
      docType: _docType!,
      issuingCountry: _country!,
      docNumber: _number.text,
    );
  }

  Future<void> _submit() async {
    final d = validated();
    if (d == null) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(d);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _docTypeLabel(AppLocalizations l10n, String t) {
    switch (t) {
      case 'passport':
        return l10n.identityDocTypePassport;
      case 'id_card':
        return l10n.identityDocTypeIdCard;
      case 'driving_licence':
        return l10n.identityDocTypeDrivingLicence;
      case 'residence_permit':
        return l10n.identityDocTypeResidencePermit;
      default:
        return l10n.identityDocTypeOther;
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? l10n.identityFieldRequired : null;
    final countries = [...CountryFlagHelper.allCountries]
      ..sort((a, b) => localizedCountryName(l10n, a.isoCode)
          .compareTo(localizedCountryName(l10n, b.isoCode)));
    final dobText = _dob == null
        ? ''
        : MaterialLocalizations.of(context).formatMediumDate(_dob!);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIntro) ...[
            Text(
              l10n.identityDetailsIntro,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            key: const Key('identity_first_name'),
            controller: _first,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.identityFirstNameLabel),
            validator: required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('identity_surname'),
            controller: _surname,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.identitySurnameLabel),
            validator: required,
          ),
          const SizedBox(height: 12),
          FormField<DateTime>(
            key: const Key('identity_dob'),
            initialValue: _dob,
            validator: (_) => _dob == null ? l10n.identityFieldRequired : null,
            builder: (state) => InkWell(
              onTap: () async {
                await _pickDob();
                state.didChange(_dob);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.identityDobLabel,
                  errorText: state.errorText,
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(dobText),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('identity_doc_type'),
            initialValue: _docType,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.identityDocTypeLabel),
            items: [
              for (final t in kIdentityDocTypes)
                DropdownMenuItem(value: t, child: Text(_docTypeLabel(l10n, t))),
            ],
            onChanged: (v) => setState(() => _docType = v),
            validator: required,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('identity_country'),
            initialValue: _country,
            isExpanded: true,
            decoration:
                InputDecoration(labelText: l10n.identityIssuingCountryLabel),
            items: [
              for (final c in countries)
                DropdownMenuItem(
                  value: c.isoCode,
                  child: Text(
                    '${CountryFlagHelper.getFlag(c.isoCode)}  '
                    '${localizedCountryName(l10n, c.isoCode)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _country = v),
            validator: required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('identity_doc_number'),
            controller: _number,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l10n.identityDocNumberLabel),
            validator: (v) {
              final r = required(v);
              if (r != null) return r;
              return _docNumber.hasMatch(v!.trim())
                  ? null
                  : l10n.identityDocNumberInvalid;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('identity_submit'),
            onPressed: _busy ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: Colors.black,
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}

/// A button opening the OPTIONAL details sheet next to an ID upload.
class IdentityDetailsButton extends StatefulWidget {
  const IdentityDetailsButton({required this.source, this.service, super.key});

  final IdentitySource source;
  final IdentityDetailsService? service;

  @override
  State<IdentityDetailsButton> createState() => _IdentityDetailsButtonState();
}

class _IdentityDetailsButtonState extends State<IdentityDetailsButton> {
  bool _saved = false;

  Future<void> _open() async {
    final ok = await showIdentityDetailsSheet(
      context,
      source: widget.source,
      service: widget.service,
    );
    if (ok && mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      key: const Key('identity_details_button'),
      onPressed: _open,
      icon: Icon(
        _saved ? Icons.check_circle : Icons.badge_outlined,
        color: _saved ? AppColors.successGreen : AppColors.richGold,
        size: 18,
      ),
      label: Text(
        _saved ? l10n.identitySavedMessage : l10n.identityDetailsAddButton,
        style: TextStyle(
          color: _saved ? AppColors.successGreen : AppColors.richGold,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Opens the optional details sheet. True when the details were saved.
Future<bool> showIdentityDetailsSheet(
  BuildContext context, {
  required IdentitySource source,
  IdentityDetailsService? service,
}) async {
  final svc = service ?? IdentityDetailsService();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      return Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.identityDetailsTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              IdentityDetailsForm(
                submitLabel: l10n.identitySubmitButton,
                onSubmit: (d) async {
                  try {
                    await svc.submit(source, d);
                    if (ctx.mounted) Navigator.of(ctx).pop(true);
                  } catch (e) {
                    reportUserError(e);
                    if (ctx.mounted) {
                      showUserErrorMessage(ctx, l10n.identitySaveError);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
  return saved ?? false;
}
