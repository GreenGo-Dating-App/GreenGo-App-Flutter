import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../copyright/data/copyright_service.dart' show isValidCopyrightEmail;
import '../../../copyright/presentation/widgets/copyright_form_widgets.dart';
import '../../data/services/safety_takedown_service.dart';
import '../widgets/report_reasons.dart' show kSafetyEmail;

/// Opens the intimate-image removal form. [prefilledLocations] are added to
/// the request as-is (e.g. `profile:<uid>` from a profile, or a photo URL).
Future<void> openNciiRequestForm(BuildContext context, {List<String> prefilledLocations = const []}) {
  String? email;
  try {
    email = FirebaseAuth.instance.currentUser?.email;
  } catch (_) {
    email = null;
  }
  return Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => NciiRequestScreen(prefilledLocations: prefilledLocations, initialEmail: email),
  ));
}

/// TAKE IT DOWN Act / Decreto 12.976 request: identity + contact, where the
/// content is, the three statements, and a typed signature. The server hides
/// the content as soon as the request arrives (safety/takedowns).
class NciiRequestScreen extends StatefulWidget {
  const NciiRequestScreen({
    super.key,
    this.prefilledLocations = const [],
    this.initialEmail,
    this.service,
  });

  final List<String> prefilledLocations;
  final String? initialEmail;
  final SafetyTakedownService? service;

  @override
  State<NciiRequestScreen> createState() => _NciiRequestScreenState();
}

class _NciiRequestScreenState extends State<NciiRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final TextEditingController _email = TextEditingController(text: widget.initialEmail ?? '');
  final _phone = TextEditingController();
  final _represented = TextEditingController();
  final _locations = TextEditingController();
  final _description = TextEditingController();
  final _signature = TextEditingController();
  bool _depicted = true;
  bool _stDepicted = false;
  bool _stGoodFaith = false;
  bool _stAccurate = false;
  bool _showStatementError = false;
  bool _busy = false;
  String? _reference;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _represented, _locations, _description, _signature]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    final statementsOk = _stDepicted && _stGoodFaith && _stAccurate;
    setState(() => _showStatementError = !statementsOk);
    final valid = _formKey.currentState!.validate();
    if (!valid || !statementsOk) return;
    setState(() => _busy = true);
    final r = await (widget.service ?? SafetyTakedownService()).submitNcii(
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      depictedPerson: _depicted,
      representedPerson: _represented.text.trim(),
      contentLocations: parseNciiLocations(_locations.text, prefilled: widget.prefilledLocations),
      description: _description.text.trim(),
      signature: _signature.text.trim(),
      locale: Localizations.localeOf(context).toString(),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r.outcome == NciiSubmitOutcome.submitted) _reference = r.reference ?? '';
    });
    if (r.outcome != NciiSubmitOutcome.submitted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        key: ValueKey('ncii-error-${r.outcome.name}'),
        content: Text(r.outcome == NciiSubmitOutcome.rateLimited ? l.nciiFormRateLimited : l.nciiFormError),
        backgroundColor: AppColors.errorRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    String? minLen(String? v, int n) => (v == null || v.trim().length < n) ? l.nciiFormRequired : null;
    final hasPrefill = widget.prefilledLocations.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(backgroundColor: AppColors.backgroundDark, elevation: 0, title: Text(l.nciiFormTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _reference != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 56),
                        const SizedBox(height: 16),
                        Text(
                          l.nciiFormSubmitted(_reference!),
                          key: const ValueKey('ncii-submitted'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.4),
                        ),
                      ],
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(l.nciiFormIntro, style: copyrightBodyStyle),
                        const SizedBox(height: 8),
                        // Terms 18.1: safety reports can also be emailed.
                        Text(
                          l.safetyReportEmailNote(kSafetyEmail),
                          key: const ValueKey('ncii-safety-email'),
                          style: copyrightBodyStyle,
                        ),
                        CopyrightSectionTitle(l.nciiFormSectionYou),
                        CopyrightField(fieldKey: 'ncii-name', controller: _name, label: '${l.nciiFormName} *', validator: (v) => minLen(v, 2)),
                        CopyrightField(
                          fieldKey: 'ncii-email',
                          controller: _email,
                          label: '${l.nciiFormEmail} *',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => isValidCopyrightEmail(v ?? '') ? null : l.nciiFormInvalidEmail,
                        ),
                        CopyrightField(fieldKey: 'ncii-phone', controller: _phone, label: l.nciiFormPhone, keyboardType: TextInputType.phone),
                        Text('${l.nciiFormRoleLabel} *', style: copyrightLabelStyle),
                        const SizedBox(height: 6),
                        SegmentedButton<bool>(
                          key: const ValueKey('ncii-role'),
                          segments: [
                            ButtonSegment(value: true, label: Text(l.nciiFormRoleDepicted)),
                            ButtonSegment(value: false, label: Text(l.nciiFormRoleAuthorized)),
                          ],
                          selected: {_depicted},
                          onSelectionChanged: (s) => setState(() => _depicted = s.first),
                        ),
                        const SizedBox(height: 12),
                        if (!_depicted)
                          CopyrightField(
                            fieldKey: 'ncii-represented',
                            controller: _represented,
                            label: '${l.nciiFormRepresented} *',
                            validator: (v) => minLen(v, 2),
                          ),
                        CopyrightSectionTitle(l.nciiFormSectionContent),
                        if (hasPrefill) ...[
                          CopyrightInfoCard(text: l.nciiFormPrefilled),
                          const SizedBox(height: 12),
                        ],
                        Text(l.nciiFormLocationsHint, style: copyrightBodyStyle),
                        const SizedBox(height: 8),
                        CopyrightField(
                          fieldKey: 'ncii-locations',
                          controller: _locations,
                          label: hasPrefill ? l.nciiFormLocations : '${l.nciiFormLocations} *',
                          maxLines: 4,
                          validator: hasPrefill ? null : (v) => parseNciiLocations(v ?? '').isEmpty ? l.nciiFormRequired : null,
                        ),
                        CopyrightField(fieldKey: 'ncii-description', controller: _description, label: l.nciiFormDescription, maxLines: 3),
                        CopyrightSectionTitle(l.nciiFormSectionStatements),
                        CopyrightStatement(fieldKey: 'ncii-st-depicted', text: l.nciiFormStatementDepicted, value: _stDepicted, onChanged: (v) => setState(() => _stDepicted = v)),
                        CopyrightStatement(fieldKey: 'ncii-st-goodfaith', text: l.nciiFormStatementGoodFaith, value: _stGoodFaith, onChanged: (v) => setState(() => _stGoodFaith = v)),
                        CopyrightStatement(fieldKey: 'ncii-st-accurate', text: l.nciiFormStatementAccurate, value: _stAccurate, onChanged: (v) => setState(() => _stAccurate = v)),
                        _showStatementError
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 8),
                                child: Text(
                                  l.nciiFormStatementsRequired,
                                  key: const ValueKey('ncii-statements-error'),
                                  style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                                ),
                              )
                            : const SizedBox.shrink(),
                        const SizedBox(height: 8),
                        CopyrightField(fieldKey: 'ncii-signature', controller: _signature, label: '${l.nciiFormSignature} *', validator: (v) => minLen(v, 2)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          key: const ValueKey('ncii-submit'),
                          onPressed: _busy ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.richGold,
                            foregroundColor: AppColors.deepBlack,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _busy
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(l.nciiFormSubmit),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
