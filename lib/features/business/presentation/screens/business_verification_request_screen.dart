import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/platform/web_media.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/domain/entities/profile.dart';

/// Business verification request — collects everything an admin needs to
/// verify a business, then writes it to `business_verification_requests/{uid}`.
///
/// Required: phone-number OTP identification, business name, the owner's ID
/// document (uploaded to Storage), and the owner's full name (as printed on the
/// ID). Optional: a website URL and free-text notes. Submission is blocked
/// until the phone is OTP-verified and the required fields + document are
/// present.
class BusinessVerificationRequestScreen extends StatefulWidget {
  const BusinessVerificationRequestScreen({required this.profile, super.key});

  final Profile profile;

  @override
  State<BusinessVerificationRequestScreen> createState() =>
      _BusinessVerificationRequestScreenState();
}

class _BusinessVerificationRequestScreenState
    extends State<BusinessVerificationRequestScreen> {
  final _businessNameController = TextEditingController();
  // The OWNER's full name, exactly as printed on the uploaded ID document.
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  // Owner ID document.
  String? _documentUrl;
  bool _uploadingDocument = false;

  // Phone OTP state.
  String? _verificationId;
  int? _resendToken;
  bool _codeSent = false;
  bool _phoneVerified = false;
  bool _sendingCode = false;
  bool _verifyingCode = false;
  String? _phoneError;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _businessNameController.text = widget.profile.businessName ??
        widget.profile.displayName;
    // NOTE: no per-keystroke setState here. Typing in the name fields used to
    // rebuild the WHOLE form (this screen), which tore down the sibling text
    // fields' IME connection — that's why the phone field couldn't be typed
    // into. Instead, ONLY the submit button reacts to the name controllers via
    // an AnimatedBuilder (see build), so keystrokes never rebuild any field.
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _phoneVerified &&
      _documentUrl != null &&
      _businessNameController.text.trim().isNotEmpty &&
      _ownerNameController.text.trim().isNotEmpty;

  // ── Owner document upload ────────────────────────────────────────────────

  Future<void> _pickDocument() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _uploadingDocument = true);
      final ref = FirebaseStorage.instance.ref().child(
            'business_verification/${widget.profile.userId}/owner_document.jpg',
          );
      await WebMedia.uploadXFile(ref, picked);
      final url = await ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        _documentUrl = url;
        _uploadingDocument = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingDocument = false);
      final l10n = AppLocalizations.of(context)!;
      _snack(l10n.verifyDocumentUploadError, isError: true);
    }
  }

  // ── Phone OTP ────────────────────────────────────────────────────────────

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || _sendingCode) return;
    // Firebase requires E.164 (+countrycode…). Without it the SDK throws an
    // opaque "invalid/null length" error, so validate up-front with a clear msg.
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!phone.startsWith('+') || digits.length < 8) {
      setState(() {
        _phoneError = AppLocalizations.of(context)!.verifyPhoneFormatError;
      });
      return;
    }
    setState(() {
      _sendingCode = true;
      _phoneError = null;
    });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) {
          if (mounted) {
            setState(() {
              _phoneVerified = true;
              _sendingCode = false;
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() {
              _sendingCode = false;
              _phoneError = e.message ?? e.code;
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;
              _codeSent = true;
              _sendingCode = false;
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _sendingCode = false;
          _phoneError = e.toString();
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    final vid = _verificationId;
    if (code.length != 6 || vid == null || _verifyingCode) return;
    setState(() {
      _verifyingCode = true;
      _phoneError = null;
    });
    try {
      final credential =
          PhoneAuthProvider.credential(verificationId: vid, smsCode: code);
      // Link to the current (already signed-in) user to prove ownership.
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.linkWithCredential(credential);
      }
      if (mounted) {
        setState(() {
          _phoneVerified = true;
          _verifyingCode = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      // A correct SMS code that is already linked (to this or another account)
      // still PROVES the user controls the number — accept it as verified.
      if (e.code == 'provider-already-linked' ||
          e.code == 'credential-already-in-use') {
        if (mounted) {
          setState(() {
            _phoneVerified = true;
            _verifyingCode = false;
          });
        }
        return;
      }
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _verifyingCode = false;
          _phoneError = e.code == 'invalid-verification-code'
              ? l10n.verificationInvalidCode
              : (e.message ?? l10n.verificationPhoneError);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verifyingCode = false;
          _phoneError = e.toString();
        });
      }
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canSubmit) {
      _snack(l10n.verifyMissingFields, isError: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance
          .collection('business_verification_requests')
          .doc(widget.profile.userId)
          .set({
        'status': 'pending',
        'businessName': _businessNameController.text.trim(),
        // Owner's full name (as on the ID). `legalName` kept as a mirror for
        // back-compat with any admin reader that still reads the old key.
        'ownerName': _ownerNameController.text.trim(),
        'legalName': _ownerNameController.text.trim(),
        'ownerDocumentUrl': _documentUrl,
        'phoneNumber': _phoneController.text.trim(),
        'phoneVerified': true,
        'website': _websiteController.text.trim(),
        'note': _notesController.text.trim(),
        'submittedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _snack(l10n.requestVerificationSubmitted);
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(l10n.requestVerificationError, isError: true);
    }
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : null,
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────

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
          l10n.requestVerificationTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.requestVerificationMessage,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Business name (required)
            _label(l10n.verifyBusinessNameLabel, required: true),
            _field(_businessNameController,
                icon: Icons.storefront, fieldKey: 'businessName'),
            const SizedBox(height: 20),

            // Owner's full name — must match the uploaded ID document (required)
            _label(l10n.verifyOwnerNameLabel, required: true),
            _field(_ownerNameController,
                icon: Icons.person_outline,
                fieldKey: 'ownerName',
                hint: l10n.verifyOwnerNameHint),
            const SizedBox(height: 20),

            // Phone + OTP (required)
            _label(l10n.verifyPhoneLabel, required: true),
            _buildPhoneSection(l10n),
            const SizedBox(height: 20),

            // Owner document (required)
            _label(l10n.verifyOwnerDocumentLabel, required: true),
            _buildDocumentSection(l10n),
            const SizedBox(height: 20),

            // Website (optional)
            _label(l10n.verifyWebsiteLabel),
            _field(_websiteController,
                icon: Icons.link,
                fieldKey: 'website',
                hint: l10n.verifyWebsiteHint,
                keyboardType: TextInputType.url),
            const SizedBox(height: 20),

            // Notes (optional)
            _label(l10n.verifyNotesLabel),
            _field(_notesController,
                icon: Icons.notes,
                fieldKey: 'notes',
                hint: l10n.requestVerificationNoteHint,
                maxLines: 3),
            const SizedBox(height: 32),

            // Only the submit button reacts to the name-field text (via the
            // controllers) — NOT the whole form — so typing never rebuilds any
            // TextField and the IME stays connected.
            SizedBox(
              width: double.infinity,
              child: AnimatedBuilder(
                animation: Listenable.merge(
                    [_businessNameController, _ownerNameController]),
                builder: (context, _) => ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    disabledBackgroundColor:
                        AppColors.richGold.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.deepBlack),
                          ),
                        )
                      : Text(
                          l10n.submit,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _field(
                _phoneController,
                icon: Icons.phone_outlined,
                fieldKey: 'phone',
                hint: l10n.verifyPhoneHint,
                keyboardType: TextInputType.phone,
                enabled: !_phoneVerified,
              ),
            ),
            const SizedBox(width: 8),
            if (_phoneVerified)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.verified, color: AppColors.richGold),
              )
            else
              OutlinedButton(
                onPressed: _sendingCode ? null : _sendCode,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.richGold,
                  side: const BorderSide(color: AppColors.richGold),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
                child: _sendingCode
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.richGold),
                        ),
                      )
                    : Text(_codeSent ? l10n.verifyResendCode : l10n.verifySendCode),
              ),
          ],
        ),
        if (_codeSent && !_phoneVerified) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _field(
                  _codeController,
                  icon: Icons.sms_outlined,
                  fieldKey: 'code',
                  hint: l10n.verifyEnterCodeLabel,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _verifyingCode ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                child: _verifyingCode
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.deepBlack),
                        ),
                      )
                    : Text(l10n.verifyConfirmCode),
              ),
            ],
          ),
        ],
        if (_phoneVerified)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.verifyPhoneVerified,
              style: const TextStyle(color: AppColors.richGold, fontSize: 12),
            ),
          ),
        if (_phoneError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _phoneError!,
              style: const TextStyle(color: AppColors.errorRed, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentSection(AppLocalizations l10n) {
    final uploaded = _documentUrl != null;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _uploadingDocument ? null : _pickDocument,
        style: OutlinedButton.styleFrom(
          foregroundColor: uploaded ? AppColors.richGold : AppColors.textPrimary,
          side: BorderSide(
            color: uploaded ? AppColors.richGold : AppColors.divider,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: _uploadingDocument
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
                ),
              )
            : Icon(uploaded ? Icons.check_circle : Icons.upload_file, size: 18),
        label: Text(
          uploaded ? l10n.verifyDocumentUploaded : l10n.verifyUploadDocument,
        ),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.richGold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller, {
    required IconData icon,
    required String fieldKey,
    String? hint,
    int maxLines = 1,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextField(
      // A distinct, STABLE key per field so Flutter never re-maps one field's
      // IME connection onto another (which dropped keystrokes).
      key: ValueKey('verify_field_$fieldKey'),
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.richGold, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.richGold, width: 2),
        ),
      ),
    );
  }
}
