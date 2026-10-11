import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/copyright_service.dart';
import '../widgets/copyright_form_widgets.dart';

/// Opens the copyright notice form, optionally about a specific item.
Future<void> openCopyrightNoticeForm(BuildContext context, {CopyrightContentRef? content}) {
  String? email;
  try {
    email = FirebaseAuth.instance.currentUser?.email;
  } catch (_) {
    email = null;
  }
  return Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => CopyrightNoticeFormScreen(content: content, initialEmail: email),
  ));
}

/// DMCA §512(c)(3) notice form (also used for EU DSA art. 16 and Brazil Lei
/// 9.610 notices). Every element the law requires is a required field; the
/// sworn statements are explicit checkboxes and the signature is the typed
/// full legal name. Non-users use the public web form (copyrightNoticeWeb).
class CopyrightNoticeFormScreen extends StatefulWidget {
  const CopyrightNoticeFormScreen({
    super.key,
    this.content,
    this.initialEmail,
    this.service,
  });

  final CopyrightContentRef? content;
  final String? initialEmail;
  final CopyrightService? service;

  @override
  State<CopyrightNoticeFormScreen> createState() => _CopyrightNoticeFormScreenState();
}

class _CopyrightNoticeFormScreenState extends State<CopyrightNoticeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _org = TextEditingController();
  late final TextEditingController _email = TextEditingController(text: widget.initialEmail ?? '');
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _work = TextEditingController();
  final _workUrl = TextEditingController();
  late final TextEditingController _location = TextEditingController(text: widget.content?.path ?? '');
  final _details = TextEditingController();
  final _signature = TextEditingController();
  String _relationship = 'owner';
  bool _goodFaith = false;
  bool _accuracy = false;
  bool _authority = false;
  bool _showStatementError = false;
  bool _busy = false;
  bool _done = false;

  @override
  void dispose() {
    for (final c in [_name, _org, _email, _phone, _address, _work, _workUrl, _location, _details, _signature]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    final statementsOk = _goodFaith && _accuracy && _authority;
    setState(() => _showStatementError = !statementsOk);
    final valid = _formKey.currentState!.validate();
    if (!valid || !statementsOk) return;
    setState(() => _busy = true);
    final outcome = await (widget.service ?? CopyrightService()).submitNotice({
      'complainant': {
        'name': _name.text.trim(),
        'organization': _org.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'relationship': _relationship,
      },
      'work': {'description': _work.text.trim(), 'url': _workUrl.text.trim()},
      'content': {
        'location': _location.text.trim(),
        'details': _details.text.trim(),
        if (widget.content != null) 'label': widget.content!.type,
        if (widget.content != null) 'target': widget.content!.toJson(),
      },
      'statements': {'goodFaith': _goodFaith, 'accuracy': _accuracy, 'authority': _authority},
      'signature': _signature.text.trim(),
      'locale': Localizations.localeOf(context).toString(),
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = outcome == CopyrightSubmitOutcome.submitted;
    });
    if (!_done) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        key: ValueKey('copyright-error-${outcome.name}'),
        content: Text(outcome == CopyrightSubmitOutcome.rateLimited ? l.copyrightFormRateLimited : l.copyrightFormError),
        backgroundColor: AppColors.errorRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    String? required(String? v) => (v == null || v.trim().isEmpty) ? l.copyrightFormRequired : null;
    String? minLen(String? v, int n) => (v == null || v.trim().length < n) ? l.copyrightFormRequired : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(l.copyrightFormTitle),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _done
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 56),
                        const SizedBox(height: 16),
                        Text(
                          l.copyrightFormSubmitted,
                          key: const ValueKey('copyright-submitted'),
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
                        Text(l.copyrightFormIntro, style: copyrightBodyStyle),
                        if (widget.content != null) ...[
                          const SizedBox(height: 12),
                          CopyrightInfoCard(text: l.copyrightFormContentPrefilled(widget.content!.label(l))),
                        ],
                        CopyrightSectionTitle(l.copyrightFormSectionYou),
                        CopyrightField(fieldKey: 'cr-name', controller: _name, label: '${l.copyrightFormName} *', validator: (v) => minLen(v, 2)),
                        CopyrightField(fieldKey: 'cr-org', controller: _org, label: '${l.copyrightFormOrganization} (${l.copyrightFormOptional})'),
                        CopyrightField(
                          fieldKey: 'cr-email',
                          controller: _email,
                          label: '${l.copyrightFormEmail} *',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => isValidCopyrightEmail(v ?? '') ? null : l.copyrightFormInvalidEmail,
                        ),
                        CopyrightField(
                          fieldKey: 'cr-phone',
                          controller: _phone,
                          label: '${l.copyrightFormPhone} *',
                          keyboardType: TextInputType.phone,
                          validator: (v) => isValidCopyrightPhone(v ?? '') ? null : l.copyrightFormRequired,
                        ),
                        CopyrightField(fieldKey: 'cr-address', controller: _address, label: '${l.copyrightFormAddress} *', maxLines: 3, validator: (v) => minLen(v, 5)),
                        const SizedBox(height: 8),
                        Text('${l.copyrightFormRelationship} *', style: copyrightLabelStyle),
                        const SizedBox(height: 6),
                        SegmentedButton<String>(
                          key: const ValueKey('cr-relationship'),
                          segments: [
                            ButtonSegment(value: 'owner', label: Text(l.copyrightFormRelOwner)),
                            ButtonSegment(value: 'agent', label: Text(l.copyrightFormRelAgent)),
                          ],
                          selected: {_relationship},
                          onSelectionChanged: (s) => setState(() => _relationship = s.first),
                        ),
                        CopyrightSectionTitle(l.copyrightFormSectionWork),
                        CopyrightField(fieldKey: 'cr-work', controller: _work, label: '${l.copyrightFormWorkDescription} *', maxLines: 4, validator: (v) => minLen(v, 10)),
                        CopyrightField(fieldKey: 'cr-workUrl', controller: _workUrl, label: '${l.copyrightFormWorkUrl} (${l.copyrightFormOptional})', keyboardType: TextInputType.url),
                        CopyrightSectionTitle(l.copyrightFormSectionContent),
                        CopyrightField(
                          fieldKey: 'cr-location',
                          controller: _location,
                          label: '${l.copyrightFormContentLocation} *',
                          readOnly: widget.content != null,
                          validator: required,
                        ),
                        CopyrightField(
                          fieldKey: 'cr-details',
                          controller: _details,
                          label: widget.content != null
                              ? '${l.copyrightFormContentDetails} (${l.copyrightFormOptional})'
                              : '${l.copyrightFormContentDetails} *',
                          maxLines: 3,
                          validator: widget.content != null ? null : (v) => minLen(v, 3),
                        ),
                        CopyrightSectionTitle(l.copyrightFormSectionStatements),
                        CopyrightStatement(fieldKey: 'cr-goodFaith', text: l.copyrightFormGoodFaith, value: _goodFaith, onChanged: (v) => setState(() => _goodFaith = v)),
                        CopyrightStatement(fieldKey: 'cr-accuracy', text: l.copyrightFormAccuracy, value: _accuracy, onChanged: (v) => setState(() => _accuracy = v)),
                        CopyrightStatement(fieldKey: 'cr-authority', text: l.copyrightFormAuthority, value: _authority, onChanged: (v) => setState(() => _authority = v)),
                        // Always one slot: adding/removing a child here would
                        // shift the fields below and reset their error state.
                        _showStatementError
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 8),
                                child: Text(
                                  l.copyrightFormStatementsRequired,
                                  key: const ValueKey('cr-statements-error'),
                                  style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                                ),
                              )
                            : const SizedBox.shrink(),
                        const SizedBox(height: 8),
                        CopyrightWarning(text: l.copyrightFormMisrepWarning),
                        const SizedBox(height: 8),
                        CopyrightField(
                          fieldKey: 'cr-signature',
                          controller: _signature,
                          label: '${l.copyrightFormSignature} *',
                          validator: (v) {
                            if (v == null || v.trim().length < 2) return l.copyrightFormRequired;
                            return normalizeCopyrightSignature(v) == normalizeCopyrightSignature(_name.text)
                                ? null
                                : l.copyrightFormSignatureMismatch;
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          key: const ValueKey('copyright-submit'),
                          onPressed: _busy ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.richGold,
                            foregroundColor: AppColors.deepBlack,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _busy
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(l.copyrightFormSubmit),
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
