import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';

class Admin2FAScreen extends StatefulWidget {
  /// Optional callback for inline usage (e.g., AuthWrapper).
  /// If provided, called on success instead of Navigator.pop.
  final VoidCallback? onVerified;

  /// Optional sign-out callback shown as a button on the screen.
  final VoidCallback? onSignOut;

  const Admin2FAScreen({super.key, this.onVerified, this.onSignOut});

  /// Session-level cache: once verified, skip 2FA for the rest of the app session.
  static bool _verified = false;
  static bool get isVerified => _verified;
  static void resetVerification() => _verified = false;

  @override
  State<Admin2FAScreen> createState() => _Admin2FAScreenState();
}

class _Admin2FAScreenState extends State<Admin2FAScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isSending = false;
  bool _isVerifying = false;
  String? _maskedEmail;
  String? _errorMessage;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String get _enteredCode =>
      _controllers.map((c) => c.text).join();

  Future<void> _sendCode() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('send2FACode')
          .call();

      final data = result.data as Map<String, dynamic>?;
      if (data != null && data['maskedEmail'] != null) {
        _maskedEmail = data['maskedEmail'] as String;
      }

      _startCooldown();
    } on FirebaseFunctionsException catch (e) {
      _errorMessage = e.message ?? 'Failed to send code';
    } catch (e) {
      _errorMessage = 'Failed to send code';
    }

    if (mounted) setState(() => _isSending = false);
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _verifyCode() async {
    final code = _enteredCode;
    if (code.length != 6) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await FirebaseFunctions.instance
          .httpsCallable('verify2FACode')
          .call({'code': code});

      Admin2FAScreen._verified = true;
      if (mounted) {
        if (widget.onVerified != null) {
          widget.onVerified!();
        } else {
          Navigator.of(context).pop(true);
        }
      }
      return;
    } on FirebaseFunctionsException catch (e) {
      final msg = e.message ?? '';
      if (msg.contains('expired')) {
        _errorMessage = AppLocalizations.of(context)!.admin2faExpired;
      } else if (msg.contains('attempts')) {
        _errorMessage = AppLocalizations.of(context)!.admin2faMaxAttempts;
      } else {
        _errorMessage = AppLocalizations.of(context)!.admin2faInvalidCode;
      }
    } catch (_) {
      _errorMessage = AppLocalizations.of(context)!.admin2faInvalidCode;
    }

    if (mounted) setState(() => _isVerifying = false);
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_enteredCode.length == 6) {
      _verifyCode();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
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
        automaticallyImplyLeading: widget.onVerified == null,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          l10n.admin2faTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          if (widget.onSignOut != null)
            TextButton(
              onPressed: widget.onSignOut,
              child: Text(
                l10n.admin2faSignOut,
                style: const TextStyle(color: AppColors.errorRed),
              ),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.security,
                size: 64,
                color: AppColors.richGold,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.admin2faSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              if (_maskedEmail != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.admin2faCodeSent(_maskedEmail!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ],
              if (_isSending) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.richGold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.admin2faSending,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),

              // 6-digit OTP fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Container(
                    width: 44,
                    margin: EdgeInsets.only(
                      right: index < 5 ? 8 : 0,
                      left: index == 3 ? 8 : 0,
                    ),
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) => _onKeyEvent(index, event),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.richGold, width: 2),
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundCard,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onDigitChanged(index, value),
                      ),
                    ),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Verify button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifying || _enteredCode.length != 6
                      ? null
                      : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.richGold.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.admin2faVerify,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Resend button
              TextButton(
                onPressed: _resendCooldown > 0 || _isSending ? null : _sendCode,
                child: Text(
                  _resendCooldown > 0
                      ? l10n.admin2faResendIn(_resendCooldown.toString())
                      : l10n.admin2faResend,
                  style: TextStyle(
                    color: _resendCooldown > 0
                        ? AppColors.textTertiary
                        : AppColors.richGold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
