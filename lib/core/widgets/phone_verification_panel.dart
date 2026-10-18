import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../generated/app_localizations.dart';
import '../constants/phone_verification_countries.dart';
import '../services/phone_verification_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../utils/country_flag_helper.dart';
import '../utils/country_names_l10n.dart';

/// Country picker (supported SMS countries only) + number + SMS code.
/// Used by the onboarding verification step and [PhoneVerificationGate].
/// Calls [onVerified] with the E.164 number once the phone is linked.
class PhoneVerificationPanel extends StatefulWidget {
  const PhoneVerificationPanel({
    required this.onVerified,
    this.initialCountry,
    this.service,
    super.key,
  });

  final ValueChanged<String> onVerified;

  /// ISO code to preselect (profile origin / device region). An unsupported
  /// one shows the "not yet available in your country" notice.
  final String? initialCountry;
  final PhoneVerificationService? service;

  @override
  State<PhoneVerificationPanel> createState() => _PhoneVerificationPanelState();
}

class _PhoneVerificationPanelState extends State<PhoneVerificationPanel> {
  late final PhoneVerificationService _service =
      widget.service ?? PhoneVerificationService();
  final _numberController = TextEditingController();
  final _codeController = TextEditingController();

  late String _country;
  late final bool _homeCountryUnsupported;
  String? _e164;
  bool _codeSent = false;
  bool _busy = false;
  bool _verified = false;
  String? _error;
  Timer? _timer;
  int _resendIn = 0;

  @override
  void initState() {
    super.initState();
    final home = (widget.initialCountry ?? _deviceRegion())?.toUpperCase();
    _homeCountryUnsupported = home != null && home.length == 2 && !isPhoneCountrySupported(home);
    _country = isPhoneCountrySupported(home) ? home! : 'US';
    final existing = _service.currentPhone;
    if (existing != null) _verified = true;
  }

  static String? _deviceRegion() {
    try {
      return PlatformDispatcher.instance.locale.countryCode;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _numberController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _dialCode => phoneCountryFor(_country)!.dialCode;

  Future<void> _send() async {
    if (_busy) return;
    final e164 = toE164(_dialCode, _numberController.text);
    if (e164 == null) {
      setState(() => _error = PhoneVerificationError.invalidNumber);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final refused = await _service.checkAllowed(e164);
    if (!mounted) return;
    if (refused != null) {
      setState(() {
        _busy = false;
        _error = refused;
      });
      return;
    }
    _e164 = e164;
    await _service.sendCode(
      e164,
      onCodeSent: () {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _codeSent = true;
          _resendIn = 60;
        });
        _startTimer();
      },
      onAutoVerified: _done,
      onError: (code) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = code;
        });
      },
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _resendIn <= 0) {
        t.cancel();
        return;
      }
      setState(() => _resendIn--);
    });
  }

  Future<void> _confirm() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await _service.confirmCode(code);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    _done();
  }

  void _done() {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _verified = true;
    });
    widget.onVerified(_service.currentPhone ?? _e164 ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_verified) {
      return Container(
        key: const ValueKey('phone-verify-success'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.successGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified, color: AppColors.successGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.phoneVerifySuccess,
                style: const TextStyle(
                    color: AppColors.successGreen, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_homeCountryUnsupported) ...[
          _Notice(
            key: const ValueKey('phone-verify-unsupported-home'),
            text: l10n.phoneVerifyUnsupportedCountry(kPhoneVerificationSupportEmail),
          ),
          const SizedBox(height: 12),
        ],
        if (!_codeSent) ..._numberStep(l10n) else ..._codeStep(l10n),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            phoneVerificationErrorText(l10n, _error!),
            key: const ValueKey('phone-verify-error'),
            style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
          ),
        ],
      ],
    );
  }

  List<Widget> _numberStep(AppLocalizations l10n) => [
        DropdownButtonFormField<String>(
          key: const ValueKey('phone-verify-country'),
          initialValue: _country,
          isExpanded: true,
          dropdownColor: AppColors.backgroundCard,
          decoration: _decoration(l10n.phoneVerifyCountryLabel),
          items: [
            for (final c in kPhoneVerificationCountries)
              DropdownMenuItem(
                value: c.isoCode,
                child: Text(
                  '${CountryFlagHelper.getFlag(c.isoCode)}  '
                  '${localizedCountryName(l10n, c.isoCode)}  ${c.dialCode}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
          ],
          onChanged: _busy ? null : (v) => setState(() => _country = v ?? _country),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.phoneVerifyCountryNotListed(kPhoneVerificationSupportEmail),
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('phone-verify-number'),
          controller: _numberController,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          decoration: _decoration(l10n.phoneVerifyNumberLabel).copyWith(
            prefixText: '$_dialCode ',
            prefixStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.phoneVerifySmsNotice,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        _PrimaryButton(
          key: const ValueKey('phone-verify-send'),
          label: l10n.phoneVerifySendCode,
          busy: _busy,
          onPressed: _send,
        ),
      ];

  List<Widget> _codeStep(AppLocalizations l10n) => [
        Text(
          l10n.phoneVerifyCodeSentTo(_e164 ?? ''),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('phone-verify-code'),
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 20, letterSpacing: 8),
          decoration: _decoration(l10n.phoneVerifyCodeLabel).copyWith(counterText: ''),
        ),
        const SizedBox(height: 12),
        _PrimaryButton(
          key: const ValueKey('phone-verify-confirm'),
          label: l10n.phoneVerifyConfirm,
          busy: _busy,
          onPressed: _confirm,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _codeSent = false;
                        _codeController.clear();
                        _error = null;
                      }),
              child: Text(l10n.phoneVerifyChangeNumber,
                  style: const TextStyle(color: AppColors.textTertiary)),
            ),
            TextButton(
              onPressed: (_resendIn > 0 || _busy) ? null : _send,
              child: Text(
                _resendIn > 0 ? l10n.phoneVerifyResendIn(_resendIn) : l10n.phoneVerifyResend,
                style: TextStyle(
                    color: _resendIn > 0 ? AppColors.textTertiary : AppColors.richGold),
              ),
            ),
          ],
        ),
      ];

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.backgroundCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.richGold, width: 1.5),
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warningAmber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.warningAmber.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.public_off, color: AppColors.warningAmber, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
          ],
        ),
      );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(
      {required this.label, required this.busy, required this.onPressed, super.key});
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.richGold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
}
