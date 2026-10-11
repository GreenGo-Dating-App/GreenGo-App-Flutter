import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/copyright_service.dart';
import '../widgets/copyright_form_widgets.dart';

/// DMCA §512(g)(3) counter-notice by the uploader of removed material. The
/// server forwards it IN FULL to the complainant and restores the material
/// after 10 business days unless the complainant reports a court action.
class CopyrightCounterNoticeScreen extends StatefulWidget {
  const CopyrightCounterNoticeScreen({
    required this.notice,
    super.key,
    this.initialEmail,
    this.service,
  });

  final CopyrightNoticeView notice;
  final String? initialEmail;
  final CopyrightService? service;

  static Route<bool> route(CopyrightNoticeView notice) {
    String? email;
    try {
      email = FirebaseAuth.instance.currentUser?.email;
    } catch (_) {
      email = null;
    }
    return MaterialPageRoute<bool>(builder: (_) => CopyrightCounterNoticeScreen(notice: notice, initialEmail: email));
  }

  @override
  State<CopyrightCounterNoticeScreen> createState() => _CopyrightCounterNoticeScreenState();
}

class _CopyrightCounterNoticeScreenState extends State<CopyrightCounterNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final TextEditingController _email = TextEditingController(text: widget.initialEmail ?? '');
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _explanation = TextEditingController();
  final _signature = TextEditingController();
  bool _perjury = false;
  bool _jurisdiction = false;
  bool _showStatementError = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _address, _explanation, _signature]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    final statementsOk = _perjury && _jurisdiction;
    setState(() => _showStatementError = !statementsOk);
    if (!_formKey.currentState!.validate() || !statementsOk) return;
    setState(() => _busy = true);
    final outcome = await (widget.service ?? CopyrightService()).submitCounterNotice({
      'noticeId': widget.notice.id,
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'address': _address.text.trim(),
      'explanation': _explanation.text.trim(),
      'statements': {'perjury': _perjury, 'jurisdiction': _jurisdiction},
      'signature': _signature.text.trim(),
    });
    if (!mounted) return;
    setState(() => _busy = false);
    final messenger = ScaffoldMessenger.of(context);
    if (outcome == CopyrightSubmitOutcome.submitted || outcome == CopyrightSubmitOutcome.alreadySent) {
      messenger.showSnackBar(SnackBar(content: Text(l.copyrightCounterSent), backgroundColor: AppColors.successGreen));
      Navigator.of(context).pop(true);
      return;
    }
    messenger.showSnackBar(SnackBar(
      content: Text(outcome == CopyrightSubmitOutcome.rateLimited ? l.copyrightFormRateLimited : l.copyrightFormError),
      backgroundColor: AppColors.errorRed,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    String? minLen(String? v, int n) => (v == null || v.trim().length < n) ? l.copyrightFormRequired : null;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(backgroundColor: AppColors.backgroundDark, elevation: 0, title: Text(l.copyrightCounterTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(l.copyrightCounterIntro, style: copyrightBodyStyle),
                  const SizedBox(height: 12),
                  CopyrightInfoCard(text: '${l.copyrightFormContentLocation}: ${widget.notice.location}'),
                  CopyrightSectionTitle(l.copyrightFormSectionYou),
                  CopyrightField(fieldKey: 'cn-name', controller: _name, label: '${l.copyrightFormName} *', validator: (v) => minLen(v, 2)),
                  CopyrightField(
                    fieldKey: 'cn-email',
                    controller: _email,
                    label: '${l.copyrightFormEmail} *',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => isValidCopyrightEmail(v ?? '') ? null : l.copyrightFormInvalidEmail,
                  ),
                  CopyrightField(
                    fieldKey: 'cn-phone',
                    controller: _phone,
                    label: '${l.copyrightFormPhone} *',
                    keyboardType: TextInputType.phone,
                    validator: (v) => isValidCopyrightPhone(v ?? '') ? null : l.copyrightFormRequired,
                  ),
                  CopyrightField(fieldKey: 'cn-address', controller: _address, label: '${l.copyrightFormAddress} *', maxLines: 3, validator: (v) => minLen(v, 5)),
                  CopyrightField(fieldKey: 'cn-explanation', controller: _explanation, label: '${l.copyrightCounterExplanation} *', maxLines: 4, validator: (v) => minLen(v, 10)),
                  CopyrightSectionTitle(l.copyrightFormSectionStatements),
                  CopyrightStatement(fieldKey: 'cn-perjury', text: l.copyrightCounterPerjury, value: _perjury, onChanged: (v) => setState(() => _perjury = v)),
                  CopyrightStatement(fieldKey: 'cn-jurisdiction', text: l.copyrightCounterJurisdiction, value: _jurisdiction, onChanged: (v) => setState(() => _jurisdiction = v)),
                  // Always one slot (see the notice form): keeps field error state.
                  _showStatementError
                      ? Text(l.copyrightFormStatementsRequired, style: const TextStyle(color: AppColors.errorRed, fontSize: 13))
                      : const SizedBox.shrink(),
                  const SizedBox(height: 8),
                  CopyrightField(
                    fieldKey: 'cn-signature',
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
                    key: const ValueKey('counter-submit'),
                    onPressed: _busy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l.copyrightCounterSubmit),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
